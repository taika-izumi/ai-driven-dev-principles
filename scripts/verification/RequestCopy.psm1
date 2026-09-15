# 原本を変更せず、選択対象版を固定して独立Gitのコピーを準備する。
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Throw-VerificationFailure([string]$Message,[string]$Status='blocked') {
    $ex=[InvalidOperationException]::new($Message);$ex.Data['status']=$Status;throw $ex
}
function Test-VerificationContainment([string]$Root,[string]$Path) {
    $r=[IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath($Root))
    $p=[IO.Path]::GetFullPath($Path)
    $p.Equals($r,[StringComparison]::OrdinalIgnoreCase) -or $p.StartsWith($r+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)
}
function Resolve-VerificationPath([string]$Path) {
    if(-not[IO.Path]::IsPathFullyQualified($Path)){Throw-VerificationFailure 'absolute path required'}
    $resolved=[IO.Path]::GetFullPath($Path)
    $part=$resolved
    while($part){
        if(Test-Path -LiteralPath $part){
            $item=Get-Item -LiteralPath $part -Force
            if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){Throw-VerificationFailure "reparse point rejected: $part"}
        }
        $part=[IO.Path]::GetDirectoryName($part)
    }
    return $resolved
}
function Invoke-VerificationGit([string]$Root,[string[]]$Arguments) {
    $start=[Diagnostics.ProcessStartInfo]::new((Get-Command git -ErrorAction Stop).Source)
    $start.UseShellExecute=$false;$start.CreateNoWindow=$true
    $start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
    $start.StandardOutputEncoding=[Text.UTF8Encoding]::new($false)
    # 親シェルのGit探索先を継承しない。対象Gitの設定・フックは書き換えない。
    foreach($key in @($start.Environment.Keys)){if($key -like 'GIT_*'){[void]$start.Environment.Remove($key)}}
    $start.Environment['GIT_CONFIG_GLOBAL']=$(if($IsWindows){'NUL'}else{'/dev/null'})
    $start.Environment['GIT_CONFIG_NOSYSTEM']='1'
    $start.Environment['GIT_TERMINAL_PROMPT']='0'
    $start.Environment['GIT_NO_LAZY_FETCH']='1'
    $start.Environment['GIT_NO_REPLACE_OBJECTS']='1'
    foreach($a in (@('-c',"safe.directory=$($Root.Replace('\','/'))",'-c','core.fsmonitor=false','-C',$Root)+$Arguments)){$start.ArgumentList.Add($a)}
    $p=[Diagnostics.Process]::new();$p.StartInfo=$start
    try{
        [void]$p.Start();$o=$p.StandardOutput.ReadToEndAsync();$e=$p.StandardError.ReadToEndAsync()
        if(-not$p.WaitForExit(30000)){$p.Kill($true);Throw-VerificationFailure 'git timed out'}
        @{exitCode=$p.ExitCode;stdout=$o.GetAwaiter().GetResult();stderr=$e.GetAwaiter().GetResult()}
    }finally{$p.Dispose()}
}
function Get-VerificationExclusion([string]$Relative,[string]$Full,[string]$RunsRoot) {
    if(Test-VerificationContainment $RunsRoot $Full){return 'run_output'}
    $first=($Relative.Replace('\','/').Split('/'))[0]
    if($first -eq '.git'){return 'git_metadata'}
    if($first -in @('.codex','.claude','.agents','.mcp.json')){return 'startup_config'}
    return $null
}
function Get-VerificationSourceManifest([hashtable]$Request,[hashtable]$Settings) {
    $root=Resolve-VerificationPath $Request.sourceRoot
    $runs=Resolve-VerificationPath $Settings.runsRoot
    $list=Invoke-VerificationGit $root @('ls-files','-z','--cached','--others','--exclude-standard')
    if($list.exitCode -ne 0){Throw-VerificationFailure ('git input enumeration failed: '+$list.stderr)}
    $names=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach($name in $list.stdout.Split([char]0,[StringSplitOptions]::RemoveEmptyEntries)){[void]$names.Add($name.Replace('\','/'))}
    foreach($extra in $Request.extraInputPaths){
        if($extra -isnot [string] -or [string]::IsNullOrWhiteSpace($extra) -or [IO.Path]::IsPathRooted($extra) -or $extra.Contains(':') -or ($extra.Replace('\','/').Split('/') -contains '..')){Throw-VerificationFailure 'extra input must be a source-relative path'}
        $full=Resolve-VerificationPath (Join-Path $root $extra)
        if(-not(Test-VerificationContainment $root $full)){Throw-VerificationFailure 'extra input outside source'}
        if(-not(Test-Path -LiteralPath $full)){Throw-VerificationFailure 'extra input missing'}
        $pending=[Collections.Generic.Queue[string]]::new();$pending.Enqueue($full)
        while($pending.Count){
            $itemPath=Resolve-VerificationPath $pending.Dequeue()
            $relative=[IO.Path]::GetRelativePath($root,$itemPath).Replace('\','/')
            if(Get-VerificationExclusion $relative $itemPath $runs){[void]$names.Add($relative);continue}
            $item=Get-Item -LiteralPath $itemPath -Force
            if($item.PSIsContainer){foreach($child in [IO.Directory]::EnumerateFileSystemEntries($itemPath)){$pending.Enqueue($child)}}else{[void]$names.Add($relative)}
        }
    }
    $ordered=[string[]]@($names);[Array]::Sort($ordered,[StringComparer]::Ordinal)
    $files=[Collections.Generic.List[object]]::new();$excluded=[Collections.Generic.List[object]]::new()
    foreach($name in $ordered){
        if([IO.Path]::IsPathRooted($name) -or $name.Contains(':') -or ($name.Split('/') -contains '..')){Throw-VerificationFailure 'invalid enumerated path'}
        $full=[IO.Path]::GetFullPath((Join-Path $root $name))
        if(-not(Test-VerificationContainment $root $full)){Throw-VerificationFailure 'enumerated path outside source'}
        # 入力のリンクは除外規則より先に検出する。
        $null=Resolve-VerificationPath $full
        $reason=Get-VerificationExclusion $name $full $runs
        if($reason){$excluded.Add(@{path=$name;reason=$reason});continue}
        if([IO.Directory]::Exists($full)){Throw-VerificationFailure "directory input unsupported (including submodule): $name"}
        if([IO.File]::Exists($full)){
            $hash=(Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
            $files.Add(@{path=$name;size=(Get-Item -LiteralPath $full).Length;sha256=$hash;deleted=$false})
        }else{$files.Add(@{path=$name;size=0;sha256=$null;deleted=$true})}
    }
    $head=Invoke-VerificationGit $root @('rev-parse','--verify','HEAD')
    $headRef=Invoke-VerificationGit $root @('symbolic-ref','--quiet','HEAD')
    if($headRef.exitCode -notin @(0,1)){Throw-VerificationFailure 'source HEAD reference unreadable'}
    $refs=Invoke-VerificationGit $root @('for-each-ref','--sort=refname','--format=%(objectname) %(refname)')
    if($refs.exitCode -ne 0){Throw-VerificationFailure 'source history references unreadable'}
    @{files=@($files.ToArray());head=$(if($head.exitCode -eq 0){$head.stdout.Trim()}else{$null});headRef=$(if($headRef.exitCode -eq 0){$headRef.stdout.Trim()}else{$null});historyRefs=$refs.stdout.Trim();total=$files.Count;exclusions=@($excluded.ToArray())}
}
function Test-VerificationManifestEqual($Left,$Right) {
    if($Left.head -cne $Right.head -or $Left.headRef -cne $Right.headRef -or $Left.files.Count -ne $Right.files.Count){return $false}
    if($Left.historyRefs -cne $Right.historyRefs){return $false}
    for($i=0;$i -lt $Left.files.Count;$i++){
        foreach($key in @('path','size','sha256','deleted')){if($Left.files[$i][$key] -cne $Right.files[$i][$key]){return $false}}
    }
    return $true
}
function Copy-VerificationFile([string]$Source,[string]$Destination) {
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Destination))
    [IO.File]::Copy($Source,$Destination,$false)
}
function Initialize-VerificationHistory([string]$Source,[string]$Work,[string]$Control,$Manifest) {
    # bundleで履歴データだけを移す。原本のconfig/hooks/alternatesや共有管理領域は持ち込まない。
    $shallow=Invoke-VerificationGit $Source @('rev-parse','--is-shallow-repository')
    $partial=Invoke-VerificationGit $Source @('config','--local','--get-regexp','^(extensions\.partialclone|remote\..*\.promisor)$')
    if($shallow.exitCode -ne 0 -or $shallow.stdout.Trim() -ne 'false' -or $partial.exitCode -ne 1){Throw-VerificationFailure 'complete local Git history required; shallow/partial repository unsupported'}
    $format=Invoke-VerificationGit $Source @('rev-parse','--show-object-format')
    if($format.exitCode -ne 0 -or $format.stdout.Trim() -notin @('sha1','sha256')){Throw-VerificationFailure 'unsupported Git object format'}
    $init=Invoke-VerificationGit $Work @('init','--quiet',('--object-format='+$format.stdout.Trim()),('--template='+(Join-Path $Control 'empty-template')))
    if($init.exitCode -ne 0){Throw-VerificationFailure 'copy Git initialization failed'}
    if(-not$Manifest.head){
        # コミット前のブランチ名を保持し、他ブランチの取り込みでHEADを作らない。
        if(-not$Manifest.headRef){Throw-VerificationFailure 'source HEAD has neither commit nor symbolic reference'}
        $unborn=Invoke-VerificationGit $Work @('symbolic-ref','HEAD',$Manifest.headRef)
        if($unborn.exitCode -ne 0){Throw-VerificationFailure 'unborn history initialization failed'}
    }
    if(-not$Manifest.head -and -not$Manifest.historyRefs){return}
    $bundle=Join-Path $Control 'history.bundle'
    # --allだけだと他worktreeのHEADまで列挙される。入力worktreeのHEADと共有refsに限定する。
    $args=@('bundle','create',$bundle,'--single-worktree','--all')
    if($Manifest.head){$args+='HEAD'}
    $create=Invoke-VerificationGit $Source $args
    if($create.exitCode -ne 0){Throw-VerificationFailure 'history bundle creation failed'}
    $verify=Invoke-VerificationGit $Work @('bundle','verify',$bundle)
    if($verify.exitCode -ne 0){Throw-VerificationFailure 'history bundle is incomplete or invalid'}
    $unpack=Invoke-VerificationGit $Work @('bundle','unbundle',$bundle)
    if($unpack.exitCode -ne 0){Throw-VerificationFailure 'history import failed'}
    foreach($line in $unpack.stdout.Trim().Split("`n")){
        $parts=$line.Trim().Split(' ',2)
        if($parts.Count -ne 2 -or $parts[0] -notmatch '^(?:[0-9a-f]{40}|[0-9a-f]{64})$' -or ($parts[1] -ne 'HEAD' -and -not$parts[1].StartsWith('refs/'))){Throw-VerificationFailure 'invalid history reference'}
        $set=Invoke-VerificationGit $Work @('update-ref','--no-deref',$parts[1],$parts[0])
        if($set.exitCode -ne 0){Throw-VerificationFailure 'history reference import failed'}
    }
    $refs=Invoke-VerificationGit $Work @('for-each-ref','--sort=refname','--format=%(objectname) %(refname)')
    if($refs.exitCode -ne 0 -or $refs.stdout.Trim() -cne $Manifest.historyRefs){Throw-VerificationFailure 'history references changed during copy' 'source_changed'}
    if($Manifest.headRef){
        # bundleのHEAD項目はコミットIDなので、元のブランチとの対応を別に復元する。
        $attach=Invoke-VerificationGit $Work @('symbolic-ref','HEAD',$Manifest.headRef)
        if($attach.exitCode -ne 0){Throw-VerificationFailure 'HEAD symbolic reference import failed'}
    }
    if($Manifest.head){
        $head=Invoke-VerificationGit $Work @('rev-parse','HEAD')
        if($head.exitCode -ne 0 -or $head.stdout.Trim() -cne $Manifest.head){Throw-VerificationFailure 'history HEAD changed during copy' 'source_changed'}
        # 作業ファイルはcheckoutしない。履歴の基準だけをindexへ入れ、未コミット内容を守る。
        $index=Invoke-VerificationGit $Work @('read-tree',$Manifest.head)
        if($index.exitCode -ne 0){Throw-VerificationFailure 'history index initialization failed'}
    }
    $valid=Invoke-VerificationGit $Work @('fsck','--full','--no-reflogs')
    if($valid.exitCode -ne 0){Throw-VerificationFailure 'copied history validation failed'}
}
# v1（schemaVersion=1）の準備本体。公開契約と挙動を変えないため本文は抽出前のまま置く。
function New-LegacyVerificationRun([hashtable]$Request,[hashtable]$Settings) {
    $runRoot=$null
    try{
        foreach($key in $Request.Keys){if($key -notin @('schemaVersion','caller','sourceRoot','objective','acceptanceCriteria','extraInputPaths')){Throw-VerificationFailure "unknown request key: $key"}}
        $json=$Request | ConvertTo-Json -Depth 15
        if(-not(Test-Json -Json $json -SchemaFile (Join-Path $PSScriptRoot 'request.schema.json') -ErrorAction SilentlyContinue)){Throw-VerificationFailure 'invalid request schema'}
        if($Request.schemaVersion -is [string]){Throw-VerificationFailure 'schemaVersion must be integer'}
        foreach($key in $Settings.Keys){if($key -notin @('codexPath','pwshPath','runsRoot','model','timeoutSeconds')){Throw-VerificationFailure "unknown settings key: $key"}}
        foreach($key in @('codexPath','pwshPath','runsRoot','model','timeoutSeconds')){if(-not$Settings.ContainsKey($key)){Throw-VerificationFailure "missing settings key: $key"}}
        if($Settings.model -isnot [string] -or [string]::IsNullOrWhiteSpace($Settings.model)){Throw-VerificationFailure 'model required'}
        if($Settings.timeoutSeconds -isnot [int] -and $Settings.timeoutSeconds -isnot [long]){Throw-VerificationFailure 'timeoutSeconds must be integer'}
        if($Settings.timeoutSeconds -le 0){Throw-VerificationFailure 'positive timeout required'}
        foreach($key in @('codexPath','pwshPath')){if($Settings[$key] -isnot [string]){Throw-VerificationFailure 'executable path must be string'};$path=Resolve-VerificationPath $Settings[$key];if(-not[IO.File]::Exists($path)){Throw-VerificationFailure 'executable missing'}}
        $source=Resolve-VerificationPath $Request.sourceRoot
        $runs=Resolve-VerificationPath $Settings.runsRoot
        if(-not[IO.Directory]::Exists($source)){Throw-VerificationFailure 'source missing'}
        if(Test-VerificationContainment $runs $source){Throw-VerificationFailure 'runsRoot must not contain sourceRoot'}
        $top=Invoke-VerificationGit $source @('rev-parse','--show-toplevel')
        if($top.exitCode -ne 0 -or -not([IO.Path]::GetFullPath($top.stdout.Trim()).Equals($source,[StringComparison]::OrdinalIgnoreCase))){Throw-VerificationFailure 'sourceRoot must be Git worktree root'}
        $before=Get-VerificationSourceManifest $Request $Settings
        $runId=[guid]::NewGuid().ToString();$runRoot=Join-Path $runs $runId
        if(Test-Path -LiteralPath $runRoot){Throw-VerificationFailure 'run already exists'}
        [void][IO.Directory]::CreateDirectory($runs)
        New-Item -ItemType Directory -Path $runRoot -ErrorAction Stop | Out-Null
        foreach($part in @('work','temp','control','control/empty-template')){[void][IO.Directory]::CreateDirectory((Join-Path $runRoot $part))}
        $work=Join-Path $runRoot 'work';$control=Join-Path $runRoot 'control'
        foreach($file in $before.files){
            if($file.deleted){continue}
            $src=Resolve-VerificationPath (Join-Path $source $file.path)
            $dst=Join-Path $work $file.path
            try{Copy-VerificationFile $src $dst}catch{Throw-VerificationFailure "copy failed: $($file.path)" 'source_changed'}
            if((Get-FileHash -LiteralPath $dst).Hash -cne $file.sha256){Throw-VerificationFailure 'input changed during copy' 'source_changed'}
        }
        Initialize-VerificationHistory $source $work $control $before
        $after=Get-VerificationSourceManifest $Request $Settings
        if(-not(Test-VerificationManifestEqual $before $after)){Throw-VerificationFailure 'source changed during copy' 'source_changed'}
        foreach($check in @(@{args=@('rev-parse','--show-toplevel');expected=$work},@{args=@('rev-parse','--absolute-git-dir');expected=(Join-Path $work '.git')})){
            $actual=Invoke-VerificationGit $work $check.args
            if($actual.exitCode -ne 0 -or -not([IO.Path]::GetFullPath($actual.stdout.Trim()).Equals($check.expected,[StringComparison]::OrdinalIgnoreCase))){Throw-VerificationFailure 'copy Git points outside copy'}
        }
        $prepared=@{runId=$runId;sourceRoot=$source;runRoot=$runRoot;workRoot=$work;tempRoot=(Join-Path $runRoot 'temp');controlRoot=$control;request=$Request;settings=$Settings;sourceManifest=$before}
        [IO.File]::WriteAllText((Join-Path $control 'source-manifest.json'),($before | ConvertTo-Json -Depth 15),[Text.UTF8Encoding]::new($false))
        return $prepared
    }catch{
        if(-not$_.Exception.Data.Contains('status')){$_.Exception.Data['status']='blocked'}
        if($runRoot){$_.Exception.Data['runRoot']=$runRoot}
        throw
    }
}
# ---- v3 共通補助。正規化JSON・ハッシュ・新規作成書込・UTC時刻・重複キー検査を後続ブロックへ公開する（新モジュールは増やさない）。 ----
function Add-VerificationCanonicalString([Text.StringBuilder]$Builder,[string]$Value) {
    [void]$Builder.Append('"')
    foreach($ch in $Value.ToCharArray()){
        $code=[int]$ch
        if($ch -eq '"'){[void]$Builder.Append('\"')}
        elseif($ch -eq '\'){[void]$Builder.Append('\\')}
        elseif($code -eq 10){[void]$Builder.Append('\n')}
        elseif($code -eq 13){[void]$Builder.Append('\r')}
        elseif($code -eq 9){[void]$Builder.Append('\t')}
        elseif($code -lt 0x20){[void]$Builder.Append('\u'+$code.ToString('x4'))}
        else{[void]$Builder.Append($ch)}
    }
    [void]$Builder.Append('"')
}
function Add-VerificationCanonicalValue([Text.StringBuilder]$Builder,$Value) {
    if($null -eq $Value){[void]$Builder.Append('null');return}
    if($Value -is [bool]){[void]$Builder.Append($(if($Value){'true'}else{'false'}));return}
    if($Value -is [string]){Add-VerificationCanonicalString $Builder $Value;return}
    if($Value -is [char]){Add-VerificationCanonicalString $Builder ([string]$Value);return}
    if($Value -is [byte] -or $Value -is [sbyte] -or $Value -is [int16] -or $Value -is [uint16] -or $Value -is [int] -or $Value -is [uint32] -or $Value -is [long] -or $Value -is [uint64] -or $Value -is [bigint] -or $Value -is [decimal]){[void]$Builder.Append($Value.ToString([Globalization.CultureInfo]::InvariantCulture));return}
    if($Value -is [double] -or $Value -is [single]){
        if([double]::IsNaN($Value) -or [double]::IsInfinity($Value)){throw 'canonical JSON does not accept NaN or infinity'}
        [void]$Builder.Append(([double]$Value).ToString('R',[Globalization.CultureInfo]::InvariantCulture));return
    }
    if($Value -is [Collections.IDictionary]){
        $keys=[string[]]@(foreach($key in $Value.Keys){if($key -isnot [string]){throw 'canonical JSON requires string keys'};$key})
        [Array]::Sort($keys,[StringComparer]::Ordinal)
        [void]$Builder.Append('{');$first=$true
        foreach($key in $keys){
            if(-not$first){[void]$Builder.Append(',')};$first=$false
            Add-VerificationCanonicalString $Builder $key;[void]$Builder.Append(':');Add-VerificationCanonicalValue $Builder $Value[$key]
        }
        [void]$Builder.Append('}');return
    }
    if($Value -is [Management.Automation.PSCustomObject]){
        $properties=@{};foreach($property in $Value.PSObject.Properties){$properties[$property.Name]=$property.Value}
        Add-VerificationCanonicalValue $Builder $properties;return
    }
    if($Value -is [Collections.IEnumerable]){
        [void]$Builder.Append('[');$first=$true
        foreach($item in $Value){if(-not$first){[void]$Builder.Append(',')};$first=$false;Add-VerificationCanonicalValue $Builder $item}
        [void]$Builder.Append(']');return
    }
    throw "canonical JSON does not accept type $($Value.GetType().FullName)"
}
function ConvertTo-VerificationCanonicalJson($Object) {
    # キー辞書順（序数）・空白なし。ハッシュの入力と保存形式を一致させる。
    $builder=[Text.StringBuilder]::new()
    Add-VerificationCanonicalValue $builder $Object
    $builder.ToString()
}
function Get-VerificationTextHash([string]$Text) {
    [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes($Text)))
}
function Get-VerificationCanonicalHash($Object) {
    Get-VerificationTextHash (ConvertTo-VerificationCanonicalJson $Object)
}
function Write-VerificationNewFile([string]$Path,[string]$Content) {
    # CreateNewで既存物を上書きしない。BOMなしUTF-8・LF。
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path))
    $stream=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes($Content.Replace("`r`n","`n"));$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
}
function Get-VerificationUtcNow() {
    [DateTime]::UtcNow.ToString('o',[Globalization.CultureInfo]::InvariantCulture)
}
function Test-VerificationJsonElementDuplicate([Text.Json.JsonElement]$Element) {
    if($Element.ValueKind -eq [Text.Json.JsonValueKind]::Object){
        $names=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach($property in $Element.EnumerateObject()){
            if(-not$names.Add($property.Name)){return $true}
            if(Test-VerificationJsonElementDuplicate $property.Value){return $true}
        }
        return $false
    }
    if($Element.ValueKind -eq [Text.Json.JsonValueKind]::Array){
        foreach($item in $Element.EnumerateArray()){if(Test-VerificationJsonElementDuplicate $item){return $true}}
    }
    return $false
}
function Test-VerificationJsonDuplicateKeys([string]$Json) {
    # ConvertFrom-Jsonは重複キーを黙って上書きするため、重複を保持したまま走査できるJsonDocumentで同一オブジェクト内の重複を検出する。
    $options=[Text.Json.JsonDocumentOptions]::new()
    $options.CommentHandling=[Text.Json.JsonCommentHandling]::Disallow;$options.AllowTrailingCommas=$false;$options.MaxDepth=64
    try{$document=[Text.Json.JsonDocument]::Parse($Json,$options)}catch{Throw-VerificationFailure ('invalid JSON text: '+$_.Exception.Message)}
    try{return [bool](Test-VerificationJsonElementDuplicate $document.RootElement)}finally{$document.Dispose()}
}
# ---- v3（schemaVersion=3）の準備。v1の起動検査（codexPath）は流用せず、列挙・履歴コピーの下位処理だけを共有する。 ----
function Test-VerificationInteger($Value) { ($Value -is [int]) -or ($Value -is [long]) }
function Test-VerificationIsoUtc([string]$Value) { $Value -match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,7})?Z$' }
function Test-VerificationRelativePath([string]$Value) {
    # POSIX相対表記の通常ファイルパスだけを受ける（絶対・ドライブ・バックスラッシュ・空成分・.・..を拒否）。
    if([string]::IsNullOrWhiteSpace($Value) -or [IO.Path]::IsPathRooted($Value) -or $Value.Contains(':') -or $Value.Contains('\') -or $Value.Contains([char]0)){return $false}
    foreach($part in $Value.Split('/')){if($part -in @('','.','..')){return $false}}
    return $true
}
function Test-VerificationSchema([hashtable]$Object,[string]$SchemaName,[string]$Label) {
    $json=$Object | ConvertTo-Json -Depth 15
    $errors=$null
    if(-not(Test-Json -Json $json -SchemaFile (Join-Path $PSScriptRoot $SchemaName) -ErrorAction SilentlyContinue -ErrorVariable errors)){
        $detail=$(if($errors -and $errors.Count -gt 0){$errors[0].Exception.Message}else{'schema violation'})
        Throw-VerificationFailure "invalid $Label schema: $detail"
    }
}
function Test-VerificationSettingsV3([hashtable]$Settings,[bool]$Recheck) {
    Test-VerificationSchema $Settings 'settings.schema.json' 'settings'
    if(-not(Test-VerificationInteger $Settings.schemaVersion) -or $Settings.schemaVersion -ne 3){Throw-VerificationFailure 'settings schemaVersion must be integer 3'}
    $limits=$Settings.limits
    foreach($key in @($limits.Keys)){if(-not(Test-VerificationInteger $limits[$key]) -or $limits[$key] -le 0){Throw-VerificationFailure "limits.$key must be a positive integer"}}
    if($limits.proposalSeconds -gt $limits.totalSeconds -or $limits.replaySeconds -gt $limits.totalSeconds){Throw-VerificationFailure 'proposalSeconds and replaySeconds must not exceed totalSeconds'}
    # recheckのときだけ提案段階の設定をnullにできる。replayProfilePathは常に必須（schemaでnullを拒否）。
    if(-not$Recheck -and ($null -eq $Settings.model -or $null -eq $Settings.proposalProfilePath)){Throw-VerificationFailure 'model and proposalProfilePath are required unless recheck'}
    foreach($key in @('sbxPath','pwshPath')){$path=Resolve-VerificationPath $Settings[$key];if(-not[IO.File]::Exists($path)){Throw-VerificationFailure "executable missing: $key"}}
    foreach($key in @('runsRoot','replayProfilePath','pilotInputPath')){$null=Resolve-VerificationPath $Settings[$key]}
    if($null -ne $Settings.proposalProfilePath){$null=Resolve-VerificationPath $Settings.proposalProfilePath}
}
function Get-VerificationPilotInput([string]$Path,[string]$SourceRoot,[string]$SourceManifestHash) {
    # 名指しで承認した合成題材の固定入力記録。scopeの文字列ではなく正規化パスと現物manifestのhashで照合する。
    $resolved=Resolve-VerificationPath $Path
    if(-not[IO.File]::Exists($resolved)){Throw-VerificationFailure 'pilot input record missing'}
    $json=[IO.File]::ReadAllText($resolved,[Text.UTF8Encoding]::new($false))
    if(Test-VerificationJsonDuplicateKeys $json){Throw-VerificationFailure 'pilot input record has duplicate keys'}
    $record=$json | ConvertFrom-Json -AsHashtable -Depth 15
    if($record -isnot [hashtable]){Throw-VerificationFailure 'pilot input record must be a JSON object'}
    Test-VerificationSchema $record 'pilot-input.schema.json' 'pilot input'
    $recordRoot=[IO.Path]::TrimEndingDirectorySeparator((Resolve-VerificationPath $record.sourceRoot))
    if(-not$recordRoot.Equals($SourceRoot,[StringComparison]::OrdinalIgnoreCase)){Throw-VerificationFailure 'pilot input record does not match sourceRoot'}
    if($record.sourceManifestHash -ine $SourceManifestHash){Throw-VerificationFailure 'pilot input record does not match source manifest hash'}
    @{id=$record.inputId;path=$resolved}
}
function Get-VerificationTreeManifest([string]$Root) {
    # コピー内の全通常ファイル（.git含む）。リンクは自分の領域内でも受理しない。
    # 序数順の辞書で並べる（[Array]::Sort(keys,items) はPowerShell経由だとitems側が並び替わらない）。
    $entries=[Collections.Generic.SortedDictionary[string,object]]::new([StringComparer]::Ordinal)
    foreach($info in [IO.DirectoryInfo]::new($Root).EnumerateFileSystemInfos('*',[IO.SearchOption]::AllDirectories)){
        if($info.Attributes -band [IO.FileAttributes]::ReparsePoint){Throw-VerificationFailure "reparse point inside copy: $($info.FullName)" 'incomplete'}
        if($info -is [IO.FileInfo]){
            $relative=[IO.Path]::GetRelativePath($Root,$info.FullName).Replace('\','/')
            $entries.Add($relative,@{path=$relative;size=$info.Length;sha256=(Get-FileHash -LiteralPath $info.FullName -Algorithm SHA256).Hash})
        }
    }
    return @($entries.Values)
}
function Test-VerificationCopyGit([string]$Root) {
    foreach($check in @(@{args=@('rev-parse','--show-toplevel');expected=$Root},@{args=@('rev-parse','--absolute-git-dir');expected=(Join-Path $Root '.git')})){
        $actual=Invoke-VerificationGit $Root $check.args
        if($actual.exitCode -ne 0 -or -not([IO.Path]::GetFullPath($actual.stdout.Trim()).Equals($check.expected,[StringComparison]::OrdinalIgnoreCase))){Throw-VerificationFailure "copy Git points outside copy: $Root"}
    }
}
function Copy-VerificationRecheckTests([hashtable]$Recheck,[string]$RunsRoot,[string]$AcceptedRoot) {
    # 前回のホスト確定結果から、掲載済みのテストだけをハッシュ照合のうえ通常ファイルとして複製する。
    $previousPath=Resolve-VerificationPath $Recheck.previousResultPath
    if(-not(Test-VerificationContainment $RunsRoot $previousPath)){Throw-VerificationFailure 'previousResultPath must be inside runsRoot'}
    if(-not[IO.File]::Exists($previousPath)){Throw-VerificationFailure 'previous result missing'}
    $previousJson=[IO.File]::ReadAllText($previousPath,[Text.UTF8Encoding]::new($false))
    if(Test-VerificationJsonDuplicateKeys $previousJson){Throw-VerificationFailure 'previous result has duplicate keys'}
    $previous=$previousJson | ConvertFrom-Json -AsHashtable -Depth 25
    if($previous -isnot [hashtable] -or -not(Test-VerificationInteger $previous.schemaVersion) -or $previous.schemaVersion -ne 3){Throw-VerificationFailure 'previous result must be schemaVersion 3'}
    if($previous.runId -isnot [string] -or [string]::IsNullOrWhiteSpace($previous.runId)){Throw-VerificationFailure 'previous result runId missing'}
    $previousRunRoot=Join-Path $RunsRoot $previous.runId
    if(-not$previousPath.Equals([IO.Path]::GetFullPath((Join-Path $previousRunRoot 'control/result.json')),[StringComparison]::OrdinalIgnoreCase)){Throw-VerificationFailure 'previous result location does not match its runId'}
    if($previous.status -eq 'timed_out'){Throw-VerificationFailure 'previous result timed out; its tests are not reusable'}
    $execution=$previous.execution
    if($execution -isnot [hashtable] -or $execution.replayAllStopped -isnot [bool] -or -not$execution.replayAllStopped){Throw-VerificationFailure 'previous replay stop unverified; its tests are not reusable'}
    if($execution.ContainsKey('proposalStopped') -and $execution.proposalStopped -is [bool] -and -not$execution.proposalStopped){Throw-VerificationFailure 'previous proposal stop unverified; its tests are not reusable'}
    $listed=@($previous.artifacts | Where-Object {$_ -is [hashtable] -and $_.kind -eq 'test'})
    $previousAccepted=Join-Path $previousRunRoot 'accepted'
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $artifacts=[Collections.Generic.List[object]]::new()
    foreach($path in $Recheck.testPaths){
        if($path -isnot [string] -or -not(Test-VerificationRelativePath $path) -or -not$path.StartsWith('tests/')){Throw-VerificationFailure "recheck test path must be a relative path under tests/: $path"}
        if(-not$seen.Add($path)){Throw-VerificationFailure "duplicate recheck test path: $path"}
        $found=@($listed | Where-Object {$_.path -ceq $path})
        if($found.Count -ne 1){Throw-VerificationFailure "test not listed in previous result: $path"}
        $artifact=$found[0]
        $src=Resolve-VerificationPath (Join-Path $previousAccepted $path)
        if(-not(Test-VerificationContainment $previousAccepted $src) -or -not[IO.File]::Exists($src)){Throw-VerificationFailure "previous test missing: $path"}
        $item=Get-Item -LiteralPath $src -Force
        $hash=(Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
        if($artifact.sha256 -isnot [string] -or $hash -ine $artifact.sha256 -or $item.Length -ne $artifact.size){Throw-VerificationFailure "previous test changed since its result: $path"}
        $dst=Join-Path $AcceptedRoot $path
        Copy-VerificationFile $src $dst
        if((Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash -cne $hash){Throw-VerificationFailure "recheck test copy mismatch: $path" 'incomplete'}
        $artifacts.Add(@{kind='test';path=$path;size=$item.Length;sha256=$hash;previousRunId=$previous.runId})
    }
    @{previousRunId=$previous.runId;previousResultPath=$previousPath;previousResultHash=(Get-FileHash -LiteralPath $previousPath -Algorithm SHA256).Hash;artifacts=@($artifacts.ToArray())}
}
function New-ProposalReplayRun([hashtable]$Request,[hashtable]$Settings,[string]$StartedAt) {
    $runRoot=$null;$stage='request'
    try{
        Test-VerificationSchema $Request 'request.schema.json' 'request'
        $recheck=$Request.ContainsKey('recheck')
        if(-not(Test-VerificationIsoUtc $StartedAt)){Throw-VerificationFailure 'startedAt must be ISO8601 UTC'}
        $stage='settings'
        Test-VerificationSettingsV3 $Settings $recheck
        $stage='source'
        $source=[IO.Path]::TrimEndingDirectorySeparator((Resolve-VerificationPath $Request.sourceRoot))
        $runs=[IO.Path]::TrimEndingDirectorySeparator((Resolve-VerificationPath $Settings.runsRoot))
        if(-not[IO.Directory]::Exists($source)){Throw-VerificationFailure 'source missing'}
        if(Test-VerificationContainment $runs $source){Throw-VerificationFailure 'runsRoot must not contain sourceRoot'}
        $top=Invoke-VerificationGit $source @('rev-parse','--show-toplevel')
        if($top.exitCode -ne 0 -or -not([IO.Path]::GetFullPath($top.stdout.Trim()).Equals($source,[StringComparison]::OrdinalIgnoreCase))){Throw-VerificationFailure 'sourceRoot must be Git worktree root'}
        foreach($reserved in @('.verification-tests','.verification-control')){if(Test-Path -LiteralPath (Join-Path $source $reserved)){Throw-VerificationFailure "reserved path exists in source: $reserved"}}
        $before=Get-VerificationSourceManifest $Request $Settings
        $sourceManifestJson=ConvertTo-VerificationCanonicalJson $before
        $sourceManifestHash=Get-VerificationTextHash $sourceManifestJson
        $stage='pilot-input'
        $pilot=Get-VerificationPilotInput $Settings.pilotInputPath $source $sourceManifestHash
        $stage='run-layout'
        $runId=[guid]::NewGuid().ToString();$runRoot=Join-Path $runs $runId
        if(Test-Path -LiteralPath $runRoot){Throw-VerificationFailure 'run already exists'}
        [void][IO.Directory]::CreateDirectory($runs)
        New-Item -ItemType Directory -Path $runRoot -ErrorAction Stop | Out-Null
        foreach($part in @('baseline','proposal-input','quarantine','accepted','replay-inputs','temp','control','control/empty-template','control/runtime','control/proposal','control/replay')){[void][IO.Directory]::CreateDirectory((Join-Path $runRoot $part))}
        $baseline=Join-Path $runRoot 'baseline';$proposalInput=Join-Path $runRoot 'proposal-input';$accepted=Join-Path $runRoot 'accepted';$control=Join-Path $runRoot 'control'
        Write-VerificationNewFile (Join-Path $control 'request.json') (ConvertTo-VerificationCanonicalJson $Request)
        $sourceManifestPath=Join-Path $control 'source-manifest.json'
        Write-VerificationNewFile $sourceManifestPath $sourceManifestJson
        $pilotInputPath=Join-Path $control 'pilot-input.json'
        [IO.File]::Copy($pilot.path,$pilotInputPath,$false)
        $stage='baseline'
        foreach($file in $before.files){
            if($file.deleted){continue}
            $src=Resolve-VerificationPath (Join-Path $source $file.path)
            $dst=Join-Path $baseline $file.path
            try{Copy-VerificationFile $src $dst}catch{Throw-VerificationFailure "copy failed: $($file.path)" 'source_changed'}
            if((Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash -cne $file.sha256){Throw-VerificationFailure 'input changed during copy' 'source_changed'}
        }
        Initialize-VerificationHistory $source $baseline $control $before
        Test-VerificationCopyGit $baseline
        $baselineFiles=Get-VerificationTreeManifest $baseline
        $baselineManifestPath=Join-Path $control 'baseline-manifest.json'
        Write-VerificationNewFile $baselineManifestPath (ConvertTo-VerificationCanonicalJson @{schemaVersion=3;runId=$runId;files=$baselineFiles})
        $stage='proposal-input'
        # 子へ搬入する提案用コピーは baseline のファイル単位の独立コピー。baseline 自体は子に渡さない。
        foreach($file in $baselineFiles){
            $dst=Join-Path $proposalInput $file.path
            Copy-VerificationFile (Join-Path $baseline $file.path) $dst
            if((Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash -cne $file.sha256){Throw-VerificationFailure "baseline changed during proposal-input copy: $($file.path)" 'incomplete'}
        }
        Test-VerificationCopyGit $proposalInput
        $stage='recheck'
        $recheckManifestPath=$null;$recheckArtifacts=@()
        if($recheck){
            $copied=Copy-VerificationRecheckTests $Request.recheck $runs $accepted
            $recheckArtifacts=$copied.artifacts
            $recheckManifestPath=Join-Path $control 'recheck-manifest.json'
            Write-VerificationNewFile $recheckManifestPath (ConvertTo-VerificationCanonicalJson @{schemaVersion=3;runId=$runId;previousRunId=$copied.previousRunId;previousResultPath=$copied.previousResultPath;previousResultHash=$copied.previousResultHash;tests=$recheckArtifacts})
        }
        $stage='source-recheck'
        $after=Get-VerificationSourceManifest $Request $Settings
        if(-not(Test-VerificationManifestEqual $before $after)){Throw-VerificationFailure 'source changed during copy' 'source_changed'}
        # 期限はCLI受付時刻を単一起点にし、準備時間も含める。停止猶予は停止時に別枠で計算する。
        $deadlineAt=[DateTimeOffset]::Parse($StartedAt,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::RoundtripKind).AddSeconds($Settings.limits.totalSeconds).UtcDateTime.ToString('o',[Globalization.CultureInfo]::InvariantCulture)
        return @{
            schemaVersion=3;runId=$runId;sourceRoot=$source;runRoot=$runRoot;baselineRoot=$baseline;proposalInputRoot=$proposalInput;acceptedRoot=$accepted;controlRoot=$control
            request=$Request;settings=$Settings
            sourceManifestPath=$sourceManifestPath;sourceManifestHash=(Get-FileHash -LiteralPath $sourceManifestPath -Algorithm SHA256).Hash
            baselineManifestPath=$baselineManifestPath;baselineManifestHash=(Get-FileHash -LiteralPath $baselineManifestPath -Algorithm SHA256).Hash
            recheckManifestPath=$recheckManifestPath;recheckManifestHash=$(if($recheckManifestPath){(Get-FileHash -LiteralPath $recheckManifestPath -Algorithm SHA256).Hash}else{$null});recheckArtifacts=$recheckArtifacts
            startedAt=$StartedAt;deadlineAt=$deadlineAt;cleanupSeconds=$Settings.limits.cleanupSeconds
            pilotInputId=$pilot.id;pilotInputPath=$pilotInputPath;pilotInputHash=(Get-FileHash -LiteralPath $pilotInputPath -Algorithm SHA256).Hash
        }
    }catch{
        if(-not$_.Exception.Data.Contains('status')){$_.Exception.Data['status']='blocked'}
        if(-not$_.Exception.Data.Contains('stage')){$_.Exception.Data['stage']=$stage}
        if($runRoot){$_.Exception.Data['runRoot']=$runRoot}
        throw
    }
}
# ---- v3 のブロック間で共有する補助（計画の調整 (a)。Proposal・Replay が同じ約束を別々に実装しないため） ----
function Get-VerificationBytesHash([byte[]]$Bytes) { [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)) }
function Get-VerificationExceptionValue([Exception]$Failure,[string]$Key,[string]$Default) {
    # 例外の Data[Key] が空でない文字列ならその値、無ければ既定値。
    if($null -ne $Failure -and $Failure.Data.Contains($Key) -and -not[string]::IsNullOrEmpty([string]$Failure.Data[$Key])){return [string]$Failure.Data[$Key]}
    $Default
}
function Test-VerificationDeadlineReached([string]$DeadlineAt) {
    # 期限（ISO 8601）に達したか。解釈できない期限は「達していない」と見なさず、到達側に倒す（時間超過を失敗より優先する判定を取りこぼさない）。
    $parsed=[DateTimeOffset]::MinValue
    if([string]::IsNullOrWhiteSpace($DeadlineAt) -or -not[DateTimeOffset]::TryParse($DeadlineAt,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal,[ref]$parsed)){return $true}
    [DateTime]::UtcNow -ge $parsed.UtcDateTime
}
function Read-VerificationVerifiedJson([string]$Path,[string]$ExpectedHash,[string]$RunId,[string]$ListKey,[string]$Status,[string]$Reason) {
    # 外側の control の記録を1回だけ読み、そのバイト列で 期待hash → 厳格 UTF-8 → 重複キー → 解析（オブジェクト）→ runId を確かめてから解析結果を返す。検査したデータと使うデータを同じ読込みにする。
    # ListKey を指定したときは、その配列の各要素が path（空でない文字列・重複なし）・size（整数）・sha256（16進64桁）を持つことも確かめる。違反は Data status/reason 付きの例外。
    $fail={param($message) $ex=[InvalidOperationException]::new("$message`: $Path");$ex.Data['status']=$Status;$ex.Data['reason']=$Reason;throw $ex}
    if([string]::IsNullOrEmpty($Path) -or [string]::IsNullOrEmpty($ExpectedHash) -or -not[IO.File]::Exists($Path)){& $fail 'control record is missing'}
    $bytes=[IO.File]::ReadAllBytes($Path)
    if((Get-VerificationBytesHash $bytes) -ine $ExpectedHash){& $fail 'control record does not match its expected hash'}
    try{$json=[Text.UTF8Encoding]::new($false,$true).GetString($bytes)}catch{& $fail 'control record is not valid UTF-8'}
    $duplicate=$true
    try{$duplicate=Test-VerificationJsonDuplicateKeys $json}catch{& $fail 'control record is not JSON'}
    if($duplicate){& $fail 'control record has duplicate keys'}
    $value=$json | ConvertFrom-Json -AsHashtable -Depth 20 -DateKind String
    if($value -isnot [hashtable] -or -not$value.ContainsKey('runId') -or $value.runId -cne $RunId){& $fail 'control record does not belong to this run'}
    if(-not[string]::IsNullOrEmpty($ListKey)){
        if(-not$value.ContainsKey($ListKey) -or $value[$ListKey] -isnot [Collections.IList]){& $fail "control record lacks the $ListKey list"}
        $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach($item in @($value[$ListKey])){
            $complete=($item -is [hashtable]) -and $item.ContainsKey('path') -and $item.ContainsKey('size') -and $item.ContainsKey('sha256') -and ($item.path -is [string]) -and -not[string]::IsNullOrEmpty($item.path) -and (Test-VerificationInteger $item.size) -and ($item.sha256 -is [string]) -and $item.sha256 -match '^[A-Fa-f0-9]{64}$'
            if(-not$complete){& $fail 'control record entries need path, size and sha256'}
            if(-not$seen.Add($item.path)){& $fail "control record lists a path twice ($($item.path))"}
        }
    }
    $value
}
function Get-VerificationTestsManifestHash([object[]]$Tests) {
    # 仕様02の testsManifestHash: test の {path(accepted 相対の tests/<名前>), size, sha256(大文字)} をパスの序数順に並べた配列の正規化JSONの SHA256。
    # 提案（Proposal）が作り、再実行（Replay）と照合（Result）が照合する値なので、計算はこの1か所だけにする。
    $list=[Collections.Generic.List[object]]::new()
    foreach($test in @($Tests)){if($null -ne $test){$list.Add(@{path=[string]$test.path;size=[long]$test.size;sha256=([string]$test.sha256).ToUpperInvariant()})}}
    $list.Sort([Comparison[object]]{param($left,$right) [string]::CompareOrdinal([string]$left.path,[string]$right.path)})
    Get-VerificationCanonicalHash -Object ([object[]]$list.ToArray())
}
function ConvertFrom-VerificationRuntimeFailure([Exception]$Failure) {
    # SbxRuntime の New-VerificationSandbox が例外の Data['runtimeFailure'] に載せる正規化JSONを解析し、値域を確かめて返す。
    # 欠落・解析不能・creationState/stopState の値域外・created なのに handle が無い場合は $null（呼出し側は作成成否不明として扱う）。
    if($null -eq $Failure -or -not$Failure.Data.Contains('runtimeFailure')){return $null}
    try{$record=[string]$Failure.Data['runtimeFailure'] | ConvertFrom-Json -AsHashtable -Depth 10 -DateKind String}catch{return $null}
    if($record -isnot [hashtable]){return $null}
    if(-not$record.ContainsKey('creationState') -or $record.creationState -notin @('not-created','created','unknown')){return $null}
    if(-not$record.ContainsKey('stopState') -or $record.stopState -notin @('not-created','stopped','unverified')){return $null}
    if($record.creationState -ceq 'created' -and (-not$record.ContainsKey('handle') -or $record.handle -isnot [hashtable])){return $null}
    $record
}
function New-VerificationRun([hashtable]$Request,[hashtable]$Settings,[string]$StartedAt='') {
    # 整数3のときだけv3。それ以外（1・数字の文字列表現・未実装v2）は既存v1の検査に渡し、v1は1以外を拒否する。
    if($null -ne $Request -and $Request.ContainsKey('schemaVersion') -and (Test-VerificationInteger $Request.schemaVersion) -and $Request.schemaVersion -eq 3){return New-ProposalReplayRun $Request $Settings $StartedAt}
    return New-LegacyVerificationRun $Request $Settings
}
Export-ModuleMember -Function New-VerificationRun,Get-VerificationSourceManifest,Test-VerificationManifestEqual,Resolve-VerificationPath,Test-VerificationContainment,ConvertTo-VerificationCanonicalJson,Get-VerificationCanonicalHash,Write-VerificationNewFile,Get-VerificationUtcNow,Test-VerificationJsonDuplicateKeys,Get-VerificationBytesHash,Get-VerificationExceptionValue,Test-VerificationDeadlineReached,Read-VerificationVerifiedJson,Get-VerificationTestsManifestHash,ConvertFrom-VerificationRuntimeFailure
