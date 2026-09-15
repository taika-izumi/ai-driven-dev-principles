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
function Get-VerificationCanonicalHash($Object) {
    $bytes=[Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-VerificationCanonicalJson $Object))
    [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
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
function New-VerificationRun([hashtable]$Request,[hashtable]$Settings,[string]$StartedAt='') {
    return New-LegacyVerificationRun $Request $Settings
}
Export-ModuleMember -Function New-VerificationRun,Get-VerificationSourceManifest,Test-VerificationManifestEqual,Resolve-VerificationPath,Test-VerificationContainment,ConvertTo-VerificationCanonicalJson,Get-VerificationCanonicalHash,Write-VerificationNewFile,Get-VerificationUtcNow,Test-VerificationJsonDuplicateKeys
