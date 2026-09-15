# 通信なし環境での修正前後の再実行（仕様04）。検査済みの提案（accepted）と基準版（baseline）から replay-inputs/before・after を外側で作り、
# 差分と標準ライブラリを VM なしで検査してから、役割ごとに新規VMで固定 argv の unittest を実行し、外側の記録を control/replay/ へ残す。
# VM の作成・搬入・実行・停止は SbxRuntime の公開操作だけを呼ぶ。テスト・修正候補・その出力は未信頼データで、ホストで import・実行しない。
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'RequestCopy.psm1')                          # 正規化JSON・ハッシュ・新規作成書込・重複キー検査・パス検査を共用する
Import-Module (Join-Path $PSScriptRoot 'SbxRuntime.psm1') -DisableNameChecking      # VM の作成・搬入・実行・停止（Acquire- は仕様02の公開操作名）

$script:StrictUtf8=[Text.UTF8Encoding]::new($false,$true)
# VM 内の固定値（外側で定め、子から受け取らない）。
$script:SourceDestination='/home/agent/workspace/source'
$script:TestsDirectory='.verification-tests'
$script:ReplayArgv=[string[]]@('python3','-m','unittest','discover','-s','.verification-tests','-p','test_*.py','-v')
# unittest の要約行（TextTestRunner の既定は stderr）を transportVerified の出力署名にする。stdout にだけある場合は署名とみなさない。
$script:OutputSignature=@{pattern='Ran \d+ tests? in';stream='stderr'}
# 実行時の明示変数。runtime profile の schema に環境辞書の項目が無いため、VM 既定の環境に何も足さない空の辞書で固定する（ホストの環境変数は SbxRuntime が渡さない）。
$script:ReplayEnvironment=@{}
$script:RoleNames=[ordered]@{before='replay-before';after='replay-after'}

# ---- 共通補助 ----
function Throw-VerificationReplayFailure([string]$Message,[string]$Status,[string]$Reason) {
    $failure=[InvalidOperationException]::new($Message);$failure.Data['status']=$Status;$failure.Data['reason']=$Reason
    throw $failure
}
function Get-ReplayValue($Object,[string]$Name) {
    # PreparedRun・Settings・limits・ProposalResult は hashtable と PSCustomObject のどちらでも来うる。
    if($null -eq $Object){return $null}
    if($Object -is [Collections.IDictionary]){if($Object.Contains($Name)){return $Object[$Name]};return $null}
    $property=$Object.PSObject.Properties[$Name]
    if($null -eq $property){return $null}
    $property.Value
}
function Get-ReplayLimit([hashtable]$PreparedRun,[string]$Name) {
    $value=Get-ReplayValue (Get-ReplayValue $PreparedRun.settings 'limits') $Name
    if(-not(($value -is [int]) -or ($value -is [long])) -or $value -le 0){Throw-VerificationReplayFailure "settings.limits.$Name must be a positive integer" 'blocked' 'limits'}
    [long]$value
}
function Get-ReplayBytesHash([byte[]]$Bytes) { [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)) }
function Get-ReplayExceptionValue([Exception]$Failure,[string]$Key,[string]$Default) {
    if($null -ne $Failure -and $Failure.Data.Contains($Key) -and -not[string]::IsNullOrEmpty([string]$Failure.Data[$Key])){return [string]$Failure.Data[$Key]}
    $Default
}
function Test-ReplayRecheck([hashtable]$PreparedRun) {
    $artifacts=Get-ReplayValue $PreparedRun 'recheckArtifacts'
    ($null -ne $artifacts) -and @($artifacts).Count -gt 0
}
function New-ReplayResult([hashtable]$PreparedRun,$Mode) {
    # 外側が生成する ReplayResultV3。sandboxes は作成を確認した handle、before/after は記録の参照（未実施は null）、allStopped は作成0台なら null。
    @{schemaVersion=3;runId=[string]$PreparedRun.runId;status=$null;mode=$Mode;sandboxes=[object[]]@();before=$null;after=$null;allStopped=$null;failure=$null}
}
function Assert-ReplayPreparedRun([hashtable]$PreparedRun) {
    if($null -eq $PreparedRun -or $PreparedRun.schemaVersion -ne 3 -or -not$PreparedRun.ContainsKey('runId') -or [string]::IsNullOrEmpty([string]$PreparedRun.runId)){throw 'PreparedRunV3 required'}
}

# ---- 外側の記録と実体の読取り ----
function Read-ReplayVerifiedJson([hashtable]$PreparedRun,[string]$Path,[string]$ExpectedHash,[string]$Reason) {
    # control の記録（proposal manifest・baseline manifest）を1回だけ読み、そのバイト列で期待hash・UTF-8・重複キー・runId を確かめてから解析結果を返す。
    # Proposal.psm1 の Read-ProposalVerifiedManifest と同じ手順（同関数は公開されていないため、ここに局所の同等物を置く）。
    if([string]::IsNullOrEmpty($Path) -or [string]::IsNullOrEmpty($ExpectedHash) -or -not[IO.File]::Exists($Path)){Throw-VerificationReplayFailure "control record is missing: $Path" 'blocked' $Reason}
    $bytes=[IO.File]::ReadAllBytes($Path)
    if((Get-ReplayBytesHash $bytes) -ine $ExpectedHash){Throw-VerificationReplayFailure "control record does not match its expected hash: $Path" 'blocked' $Reason}
    try{$json=$script:StrictUtf8.GetString($bytes)}catch{Throw-VerificationReplayFailure "control record is not valid UTF-8: $Path" 'blocked' $Reason}
    $duplicate=$true
    try{$duplicate=Test-VerificationJsonDuplicateKeys $json}catch{Throw-VerificationReplayFailure "control record is not JSON: $Path" 'blocked' $Reason}
    if($duplicate){Throw-VerificationReplayFailure "control record has duplicate keys: $Path" 'blocked' $Reason}
    $value=$json | ConvertFrom-Json -AsHashtable -Depth 20 -DateKind String
    if($value -isnot [hashtable] -or -not$value.ContainsKey('runId') -or $value.runId -cne [string]$PreparedRun.runId){Throw-VerificationReplayFailure "control record does not belong to this run: $Path" 'blocked' $Reason}
    $value
}
function New-ReplayPathMap() { ,[Collections.Generic.SortedDictionary[string,object]]::new([StringComparer]::Ordinal) }
function Get-ReplayFileList($Items,[string]$Reason,[bool]$WithKind=$false) {
    # {path,size,sha256}（WithKind なら kind も）の一覧を検査し、path → 項目の序数順辞書で返す。sha256 は大文字にそろえる。
    $map=New-ReplayPathMap
    if($Items -isnot [Collections.IList]){Throw-VerificationReplayFailure 'file list must be an array' 'blocked' $Reason}
    foreach($item in @($Items)){
        $valid=($item -is [Collections.IDictionary]) -and $item.Contains('path') -and $item.Contains('size') -and $item.Contains('sha256') -and ($item.path -is [string]) -and -not[string]::IsNullOrEmpty($item.path) -and (($item.size -is [int]) -or ($item.size -is [long])) -and ($item.sha256 -is [string]) -and $item.sha256 -match '^[A-Fa-f0-9]{64}$'
        if($valid -and $WithKind){$valid=$item.Contains('kind') -and $item.kind -in @('test','replacement')}
        if(-not$valid){Throw-VerificationReplayFailure 'file list entries need path, size and sha256' 'blocked' $Reason}
        if($map.ContainsKey($item.path)){Throw-VerificationReplayFailure "file list names a path twice: $($item.path)" 'blocked' $Reason}
        $entry=@{path=[string]$item.path;size=[long]$item.size;sha256=([string]$item.sha256).ToUpperInvariant()}
        if($WithKind){$entry.kind=[string]$item.kind}
        $map.Add($entry.path,$entry)
    }
    ,$map
}
function Get-ReplayTreeFiles([string]$Root,[string]$Status,[string]$Reason) {
    # ディレクトリ内の全通常ファイルを path → {path,size,sha256} の序数順辞書で返す。リンク・再解析ポイントは受けない（たどらない）。
    $rootFull=[IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath($Root))
    if(-not[IO.Directory]::Exists($rootFull)){Throw-VerificationReplayFailure "directory is missing: $rootFull" $Status $Reason}
    if(([IO.DirectoryInfo]::new($rootFull)).Attributes -band [IO.FileAttributes]::ReparsePoint){Throw-VerificationReplayFailure "link or reparse point: $rootFull" $Status $Reason}
    $map=New-ReplayPathMap
    foreach($info in [IO.DirectoryInfo]::new($rootFull).EnumerateFileSystemInfos('*',[IO.SearchOption]::AllDirectories)){
        if($info.Attributes -band [IO.FileAttributes]::ReparsePoint){Throw-VerificationReplayFailure "link or reparse point: $($info.FullName)" $Status $Reason}
        if($info -is [IO.FileInfo]){
            $relative=[IO.Path]::GetRelativePath($rootFull,$info.FullName).Replace('\','/')
            $map.Add($relative,@{path=$relative;size=[long]$info.Length;sha256=(Get-FileHash -LiteralPath $info.FullName -Algorithm SHA256).Hash})
        }
    }
    ,$map
}
function Get-ReplayMapDifference($Expected,$Actual) {
    # 欠落・予定外・内容相違（size か sha256）を1行で返す。一致なら空文字列。
    $missing=@($Expected.Keys | Where-Object {-not$Actual.ContainsKey($_)})
    $unexpected=@($Actual.Keys | Where-Object {-not$Expected.ContainsKey($_)})
    $changed=@($Expected.Keys | Where-Object {$Actual.ContainsKey($_) -and ($Actual[$_].size -ne $Expected[$_].size -or $Actual[$_].sha256 -ine $Expected[$_].sha256)})
    $parts=@()
    if($missing.Count -gt 0){$parts+='missing: '+($missing -join ', ')}
    if($unexpected.Count -gt 0){$parts+='unexpected: '+($unexpected -join ', ')}
    if($changed.Count -gt 0){$parts+='changed: '+($changed -join ', ')}
    $parts -join '; '
}
function Test-ReplayGitPath([string]$Path) { @($Path.Split('/') | Where-Object {$_ -ieq '.git'}).Count -gt 0 }
function Get-ReplayTestsManifestHash([object[]]$Tests) {
    # 02 の定義: test の accepted 相対パス（tests/<名前>）・size・sha256 をパスの序数順に並べた配列の正規化JSONの SHA256。
    $list=[Collections.Generic.List[object]]::new()
    foreach($test in @($Tests)){$list.Add(@{path=[string]$test.path;size=[long]$test.size;sha256=([string]$test.sha256).ToUpperInvariant()})}
    $list.Sort([Comparison[object]]{param($left,$right) [string]::CompareOrdinal([string]$left.path,[string]$right.path)})
    Get-VerificationCanonicalHash -Object ([object[]]$list.ToArray())
}

# ---- 入力と基準版の検査（VM なし。不成立は blocked） ----
function Test-ReplayProposal([hashtable]$PreparedRun,[hashtable]$ProposalResult) {
    # 仕様04「入力と基準版」: ready・runId・origin ごとの sandbox/stopState・manifestHash と accepted 現物・baseline の全ファイル manifest と期待hash。
    # 戻り値は検査済みの tests・replacements・基準版一覧と mode。子の作業ディレクトリ（proposal-input 等）は使わない。
    if($null -eq $ProposalResult -or $ProposalResult.schemaVersion -ne 3){Throw-VerificationReplayFailure 'ProposalResultV3 required' 'blocked' 'proposal-not-ready'}
    if($ProposalResult.status -cne 'ready'){Throw-VerificationReplayFailure "proposal is not ready: $($ProposalResult.status)" 'blocked' 'proposal-not-ready'}
    if($ProposalResult.runId -cne [string]$PreparedRun.runId){Throw-VerificationReplayFailure 'proposal belongs to another run' 'blocked' 'run-id'}
    $recheck=Test-ReplayRecheck $PreparedRun
    switch -CaseSensitive ([string]$ProposalResult.origin){
        'generated'{if($recheck -or $ProposalResult.stopState -cne 'stopped' -or $ProposalResult.sandbox -isnot [Collections.IDictionary]){Throw-VerificationReplayFailure 'generated proposal requires a stopped proposal sandbox (and no recheck)' 'blocked' 'proposal-origin'}}
        'reused-tests'{if(-not$recheck -or $null -ne $ProposalResult.sandbox -or $ProposalResult.stopState -cne 'not-created'){Throw-VerificationReplayFailure 'reused tests require recheck, sandbox=null and stopState=not-created' 'blocked' 'proposal-origin'}}
        default{Throw-VerificationReplayFailure "unknown proposal origin: $($ProposalResult.origin)" 'blocked' 'proposal-origin'}
    }
    # manifest は当該 run の control/proposal/manifest.json だけを受け、期待hashで読んだ内容と ProposalResult の artifacts・testsManifestHash を照合する。
    $manifestPath=Join-Path ([string]$PreparedRun.controlRoot) 'proposal/manifest.json'
    if([string]::IsNullOrEmpty([string]$ProposalResult.manifestPath) -or -not[IO.Path]::GetFullPath([string]$ProposalResult.manifestPath).Equals([IO.Path]::GetFullPath($manifestPath),[StringComparison]::OrdinalIgnoreCase)){Throw-VerificationReplayFailure 'proposal manifest must be control/proposal/manifest.json of this run' 'blocked' 'proposal-manifest'}
    $manifest=Read-ReplayVerifiedJson $PreparedRun $manifestPath ([string]$ProposalResult.manifestHash) 'proposal-manifest'
    if($manifest.schemaVersion -ne 3 -or $manifest.origin -cne $ProposalResult.origin -or [string]$manifest.testsManifestHash -cne [string]$ProposalResult.testsManifestHash){Throw-VerificationReplayFailure 'proposal manifest does not match the proposal result' 'blocked' 'proposal-manifest'}
    $listed=Get-ReplayFileList $manifest.artifacts 'proposal-manifest' $true
    $claimed=Get-ReplayFileList ([object[]]@($ProposalResult.artifacts)) 'proposal-manifest' $true
    if((ConvertTo-VerificationCanonicalJson ([object[]]@($listed.Values))) -cne (ConvertTo-VerificationCanonicalJson ([object[]]@($claimed.Values)))){Throw-VerificationReplayFailure 'proposal result artifacts differ from the proposal manifest' 'blocked' 'proposal-manifest'}
    # 基準版: 期待hashで読んだ全ファイル manifest（.git を含む）と baseline の現物。
    $baselineManifest=Read-ReplayVerifiedJson $PreparedRun ([string]$PreparedRun.baselineManifestPath) ([string]$PreparedRun.baselineManifestHash) 'baseline-manifest'
    $baselineFiles=Get-ReplayFileList $baselineManifest.files 'baseline-manifest'
    $workFiles=New-ReplayPathMap
    foreach($file in $baselineFiles.Values){
        if(Test-ReplayGitPath $file.path){continue}
        if($file.path.StartsWith("$($script:TestsDirectory)/",[StringComparison]::OrdinalIgnoreCase)){Throw-VerificationReplayFailure "baseline uses the reserved $($script:TestsDirectory) directory" 'blocked' 'baseline-manifest'}
        $workFiles.Add($file.path,$file)
    }
    # 一覧の区分: test は accepted/tests 直下の名前だけ、replacement は基準版の作業ファイルにある .py。recheck は tests だけ。
    $tests=[Collections.Generic.List[object]]::new();$replacements=[Collections.Generic.List[object]]::new()
    foreach($artifact in $listed.Values){
        if($artifact.kind -ceq 'test'){
            if($artifact.path -notmatch '^tests/([^/]+)$'){Throw-VerificationReplayFailure "test must be directly under accepted/tests: $($artifact.path)" 'blocked' 'proposal-artifacts'}
            $tests.Add(@{path=$artifact.path;name=$Matches[1];size=$artifact.size;sha256=$artifact.sha256})
        }else{
            if($artifact.path -notmatch '^replacements/(.+\.py)$' -or -not$workFiles.ContainsKey($Matches[1])){Throw-VerificationReplayFailure "replacement must replace a .py work file of the baseline: $($artifact.path)" 'blocked' 'proposal-artifacts'}
            $replacements.Add(@{path=$artifact.path;target=$Matches[1];size=$artifact.size;sha256=$artifact.sha256})
        }
    }
    if($tests.Count -eq 0){Throw-VerificationReplayFailure 'at least one test is required' 'blocked' 'proposal-artifacts'}
    if($recheck -and $replacements.Count -gt 0){Throw-VerificationReplayFailure 'recheck does not take replacements' 'blocked' 'proposal-artifacts'}
    $testsHash=Get-ReplayTestsManifestHash $tests.ToArray()
    if($testsHash -cne [string]$ProposalResult.testsManifestHash){Throw-VerificationReplayFailure 'testsManifestHash does not match the listed tests' 'blocked' 'proposal-manifest'}
    # 現物の再照合（一覧にないファイル・ハッシュの変化・リンクは拒否）。
    $acceptedDifference=Get-ReplayMapDifference $listed (Get-ReplayTreeFiles ([string]$PreparedRun.acceptedRoot) 'blocked' 'accepted-changed')
    if($acceptedDifference){Throw-VerificationReplayFailure "accepted differs from the proposal manifest ($acceptedDifference)" 'blocked' 'accepted-changed'}
    $baselineDifference=Get-ReplayMapDifference $baselineFiles (Get-ReplayTreeFiles ([string]$PreparedRun.baselineRoot) 'blocked' 'baseline-changed')
    if($baselineDifference){Throw-VerificationReplayFailure "baseline differs from its manifest ($baselineDifference)" 'blocked' 'baseline-changed'}
    $mode=$(if($ProposalResult.origin -ceq 'reused-tests'){'recheck'}elseif($replacements.Count -gt 0){'candidate-comparison'}else{'reproduction-only'})
    @{mode=$mode;tests=[object[]]$tests.ToArray();replacements=[object[]]$replacements.ToArray();testsManifestHash=$testsHash;workFiles=$workFiles}
}

# ---- 標準ライブラリ検査（VM なし。外にあるモジュールは VM 未作成の blocked） ----
function Get-ReplayImportedModules([string]$Text) {
    # import 文を静的に列挙し、最上位のモジュール名を返す（import a.b, c as d / from x.y import z）。相対 import（from . / from .x）は題材内として数えない。
    # 動的 import（__import__・importlib）は検出しない。行頭が import/from の行は文字列の中でも数える（過剰側に倒れて blocked になる）。
    $modules=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach($line in $Text.Split("`n")){
        foreach($segment in $line.Split(';')){
            $statement=$segment.Trim()
            $comment=$statement.IndexOf('#');if($comment -ge 0){$statement=$statement.Substring(0,$comment).Trim()}
            $from=[regex]::Match($statement,'^from\s+(\.*)([A-Za-z_][\w.]*)?\s+import\b')
            if($from.Success){
                if($from.Groups[1].Value.Length -eq 0 -and $from.Groups[2].Success){[void]$modules.Add($from.Groups[2].Value.Split('.')[0])}
                continue
            }
            $import=[regex]::Match($statement,'^import\s+(.+)$')
            if(-not$import.Success){continue}
            foreach($part in $import.Groups[1].Value.Split(',')){
                $name=(($part.Trim() -split '\s+')[0]).Trim('(',')','\')
                if($name -match '^[A-Za-z_]\w*(\.\w+)*$'){[void]$modules.Add($name.Split('.')[0])}
            }
        }
    }
    ,$modules
}
function Test-ReplayStdlibImports([hashtable]$PreparedRun,[hashtable]$Profile,[hashtable]$Checked) {
    # accepted の tests と replacements の import 対象を、replay profile の標準ライブラリ一覧（stdlibModulesPath。profileHash の対象）と題材内モジュールの集合に照合する。
    # 一覧は profile の stdlibModulesHash と照合した同じバイト列から読む。実行中に依存を取得しない。
    $settingsPath=[string](Get-ReplayValue $PreparedRun.settings 'replayProfilePath')
    $value=[string]$Profile.stdlibModulesPath
    try{
        $listPath=$(if([IO.Path]::IsPathFullyQualified($value)){$value}else{[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetDirectoryName((Resolve-VerificationPath $settingsPath))) $value))})
        $listPath=Resolve-VerificationPath $listPath
        $bytes=[IO.File]::ReadAllBytes($listPath)
    }catch{Throw-VerificationReplayFailure ('stdlib module list is unreadable: '+$_.Exception.Message) 'blocked' 'stdlib-list'}
    if((Get-ReplayBytesHash $bytes) -ine [string]$Profile.stdlibModulesHash){Throw-VerificationReplayFailure 'stdlib module list does not match stdlibModulesHash' 'blocked' 'stdlib-list'}
    $allowed=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    try{$listText=$script:StrictUtf8.GetString($bytes)}catch{Throw-VerificationReplayFailure 'stdlib module list is not valid UTF-8' 'blocked' 'stdlib-list'}
    foreach($line in $listText.Split("`n")){$name=$line.Trim();if($name.Length -gt 0){[void]$allowed.Add($name)}}
    # 題材内: 作業ディレクトリ（source）の最上位のディレクトリ名と .py の名前、tests の名前（unittest discover は開始ディレクトリを sys.path に足す）。
    foreach($path in $Checked.workFiles.Keys){
        $parts=$path.Split('/')
        if($parts.Count -gt 1){[void]$allowed.Add($parts[0])}elseif($path.EndsWith('.py',[StringComparison]::Ordinal)){[void]$allowed.Add($path.Substring(0,$path.Length-3))}
    }
    foreach($test in @($Checked.tests)){if($test.name.EndsWith('.py',[StringComparison]::Ordinal)){[void]$allowed.Add($test.name.Substring(0,$test.name.Length-3))}}
    $outside=[Collections.Generic.SortedSet[string]]::new([StringComparer]::Ordinal)
    foreach($item in @($Checked.tests)+@($Checked.replacements)){
        $bytes=[IO.File]::ReadAllBytes((Join-Path ([string]$PreparedRun.acceptedRoot) $item.path))
        if((Get-ReplayBytesHash $bytes) -ine $item.sha256){Throw-VerificationReplayFailure "accepted file changed during the stdlib check: $($item.path)" 'blocked' 'accepted-changed'}
        try{$text=$script:StrictUtf8.GetString($bytes)}catch{Throw-VerificationReplayFailure "accepted file is not valid UTF-8: $($item.path)" 'blocked' 'accepted-changed'}
        foreach($module in (Get-ReplayImportedModules $text)){if(-not$allowed.Contains($module)){[void]$outside.Add("$module ($($item.path))")}}
    }
    if($outside.Count -gt 0){Throw-VerificationReplayFailure ('imports outside the standard library and the source: '+(@($outside) -join ', ')) 'blocked' 'stdlib-outside'}
}

# ---- replay-inputs の生成と差分照合（VM なし。不成立は incomplete） ----
function Copy-ReplayFile([string]$Source,[string]$Destination,[string]$ExpectedHash,[bool]$Overwrite) {
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Destination))
    [IO.File]::Copy($Source,$Destination,$Overwrite)
    if((Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash -ine $ExpectedHash){Throw-VerificationReplayFailure "replay input copy does not match the checked content: $Destination" 'incomplete' 'replay-input-copy'}
}
function New-ReplayInput([hashtable]$PreparedRun,[hashtable]$Checked,[string]$Role,[bool]$ApplyReplacements) {
    # replay-inputs/<role> を新規に作る（既存なら拒否）。基準版の作業ファイル（.git を除く）→ .verification-tests/ 直下へ tests → 必要なら replacement で上書き。
    # 複製ごとに検査済みの sha256 と照合する（検査の後で基準版・accepted が変わっていれば incomplete）。
    $root=Join-Path ([string]$PreparedRun.runRoot) "replay-inputs/$Role"
    if(Test-Path -LiteralPath $root){Throw-VerificationReplayFailure "replay input already exists: $root" 'incomplete' 'replay-input-exists'}
    [void][IO.Directory]::CreateDirectory($root)
    foreach($file in $Checked.workFiles.Values){Copy-ReplayFile (Join-Path ([string]$PreparedRun.baselineRoot) $file.path) (Join-Path $root $file.path) $file.sha256 $false}
    foreach($test in @($Checked.tests)){Copy-ReplayFile (Join-Path ([string]$PreparedRun.acceptedRoot) $test.path) (Join-Path $root "$($script:TestsDirectory)/$($test.name)") $test.sha256 $false}
    if($ApplyReplacements){foreach($replacement in @($Checked.replacements)){Copy-ReplayFile (Join-Path ([string]$PreparedRun.acceptedRoot) $replacement.path) (Join-Path $root $replacement.target) $replacement.sha256 $true}}
    $root
}
function Read-ReplayInput([string]$Root,[string]$Role,[string]$ExpectedTestsHash) {
    # 生成後の実体を読み直し、.verification-tests（tests/<名前> に対応付けた testsManifestHash）と作業ファイルに分ける。
    $files=Get-ReplayTreeFiles $Root 'incomplete' 'replay-input-link'
    $tests=[Collections.Generic.List[object]]::new();$work=New-ReplayPathMap
    $prefix="$($script:TestsDirectory)/"
    foreach($file in $files.Values){
        if($file.path.StartsWith($prefix,[StringComparison]::Ordinal)){$tests.Add(@{path='tests/'+$file.path.Substring($prefix.Length);size=$file.size;sha256=$file.sha256})}
        else{$work.Add($file.path,$file)}
    }
    $testsHash=Get-ReplayTestsManifestHash $tests.ToArray()
    if($testsHash -cne $ExpectedTestsHash){Throw-VerificationReplayFailure "tests in replay-inputs/$Role differ from the accepted tests" 'incomplete' 'replay-tests-differ'}
    @{role=$Role;root=$Root;files=$files;work=$work;testsManifestHash=$testsHash}
}
function Test-ReplayInputs([hashtable]$Checked,[string]$Mode,[string]$BeforeRoot,[string]$AfterRoot) {
    # mode ごとの照合。candidate-comparison だけ before/after の全ファイル差分を取り、(i) 差分のパス集合が replacement 一覧に含まれ、(ii) 各 replacement の after 側が accepted のバイトと一致することを確かめる
    # （内容が基準版と同じ replacement は差分に現れなくてよい）。recheck は差分照合を行わず、testsManifestHash と基準版の照合だけ。
    $expectedRoles=@{'candidate-comparison'=@('before','after');'reproduction-only'=@('before');recheck=@('after')}
    if(-not$expectedRoles.ContainsKey($Mode)){throw "unknown replay mode: $Mode"}
    $roots=@{before=$BeforeRoot;after=$AfterRoot}
    $inputs=[ordered]@{}
    foreach($role in @('before','after')){
        $present=-not[string]::IsNullOrEmpty($roots[$role])
        if($present -ne ($expectedRoles[$Mode] -contains $role)){throw "replay input $role does not fit mode $Mode"}
        if($present){$inputs[$role]=Read-ReplayInput $roots[$role] $role $Checked.testsManifestHash}
    }
    # 基準版そのものであるべき入力（candidate-comparison・reproduction-only の before、recheck の after）。
    $baseRole=$(if($Mode -ceq 'recheck'){'after'}else{'before'})
    $difference=Get-ReplayMapDifference $Checked.workFiles $inputs[$baseRole].work
    if($difference){Throw-VerificationReplayFailure "replay-inputs/$baseRole differs from the baseline work files ($difference)" 'incomplete' 'replay-input-baseline'}
    $diffChecked=$false
    if($Mode -ceq 'candidate-comparison'){
        $before=$inputs.before.work;$after=$inputs.after.work
        $targets=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach($replacement in @($Checked.replacements)){[void]$targets.Add($replacement.target)}
        $changed=[Collections.Generic.SortedSet[string]]::new([StringComparer]::Ordinal)
        foreach($path in @($before.Keys)+@($after.Keys)){
            if(-not$before.ContainsKey($path) -or -not$after.ContainsKey($path) -or $before[$path].sha256 -ine $after[$path].sha256 -or $before[$path].size -ne $after[$path].size){[void]$changed.Add($path)}
        }
        $outside=@($changed | Where-Object {-not$targets.Contains($_)})
        if($outside.Count -gt 0){Throw-VerificationReplayFailure ('after differs from before outside the replacement list: '+($outside -join ', ')) 'incomplete' 'replay-diff-outside-replacements'}
        foreach($replacement in @($Checked.replacements)){
            $actual=$(if($after.ContainsKey($replacement.target)){$after[$replacement.target]}else{$null})
            if($null -eq $actual -or $actual.sha256 -ine $replacement.sha256 -or $actual.size -ne $replacement.size){Throw-VerificationReplayFailure "replacement is not applied in replay-inputs/after: $($replacement.target)" 'incomplete' 'replacement-not-applied'}
        }
        $diffChecked=$true
    }
    @{inputs=$inputs;diffChecked=$diffChecked}
}
function Save-ReplayInputManifest([hashtable]$PreparedRun,[string]$Mode,[hashtable]$ReplayInput) {
    # 外側で作った全搬入ファイル（.verification-tests を含む）のパス・サイズ・SHA256 を control/replay/<role>-input-manifest.json へ CreateNew で保存する。
    $role=$script:RoleNames[$ReplayInput.role]
    $path=Join-Path ([string]$PreparedRun.controlRoot) "replay/$role-input-manifest.json"
    $files=[object[]]@(foreach($file in $ReplayInput.files.Values){@{path=$file.path;size=$file.size;sha256=$file.sha256}})
    Write-VerificationNewFile $path (ConvertTo-VerificationCanonicalJson @{schemaVersion=3;runId=[string]$PreparedRun.runId;role=$role;mode=$Mode;files=$files;testsManifestHash=$ReplayInput.testsManifestHash})
    @{path=$path;hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash;root=$ReplayInput.root;testsManifestHash=$ReplayInput.testsManifestHash;expected=@{files=$files}}
}

# ---- 新規VMでの再実行と外側記録 ----
$script:LimitKeys=@('totalSeconds','proposalSeconds','replaySeconds','cleanupSeconds','cpus','memoryMiB','maxProposalFiles','maxFileBytes','maxProposalBytes','maxWireBytes','maxOutputBytes')
function Test-ReplayDeadlineReached([hashtable]$PreparedRun) {
    try{[DateTime]::UtcNow -ge [DateTimeOffset]::Parse([string]$PreparedRun.deadlineAt,[Globalization.CultureInfo]::InvariantCulture).UtcDateTime}catch{$false}
}
function Add-ReplayProblem($Current,[string]$Status,[string]$Stage,[string]$Reason) {
    # 最初の問題を残す。ただし時間超過は他の問題より優先する。
    $new=@{status=$Status;stage=$Stage;reason=$Reason}
    if($null -eq $Current){return $new}
    if($Status -ceq 'timed_out' -and $Current.status -cne 'timed_out'){return $new}
    $Current
}
function Get-ReplayCommandProblem([hashtable]$Record,[string]$Stage) {
    # CommandRecord の外側の観測だけで判定する。終了コードは観測値で、0 以外を失敗にしない。stdout の成功宣言は読まない。
    # 開始未確認・transportVerified=false・出力超過は incomplete、時間超過は timed_out。
    if(-not$Record.started){
        if($Record.refusedReason -ceq 'deadline-reached'){return @{status='timed_out';stage=$Stage;reason='command-deadline-reached'}}
        return @{status='incomplete';stage=$Stage;reason='command-not-started'}
    }
    if($Record.timedOut){return @{status='timed_out';stage=$Stage;reason='command-timed-out'}}
    if($Record.outputExceeded){return @{status='incomplete';stage=$Stage;reason='command-output-exceeded'}}
    if($Record.transportVerified -ne $true){return @{status='incomplete';stage=$Stage;reason='command-transport-unverified'}}
    $null
}
function Save-ReplayRecord([hashtable]$PreparedRun,[hashtable]$Profile,[hashtable]$Handle,[hashtable]$Command,[hashtable]$InputManifest,[bool]$StopVerified) {
    # control/replay/<role>/<commandId>.json を replay-record.schema.json に照らしてから CreateNew で保存する。得られなかった時刻・終了コードは null。
    $limitsSource=Get-ReplayValue $PreparedRun.settings 'limits'
    $limits=@{};foreach($key in $script:LimitKeys){$limits[$key]=Get-ReplayValue $limitsSource $key}
    $started=[bool]$Command.started
    $record=@{
        schemaVersion=3;commandId=[string]$Command.commandId;runId=[string]$PreparedRun.runId;role=[string]$Handle.role;sandboxId=[string]$Handle.id
        profileHash=[string]$Handle.profileHash;effectiveSettingsHash=[string]$Handle.effectiveSettingsHash;templateDigest=[string]$Profile.templateDigest
        sourceManifestHash=[string]$PreparedRun.sourceManifestHash;inputManifestHash=[string]$InputManifest.hash;testsManifestHash=[string]$InputManifest.testsManifestHash
        argv=$script:ReplayArgv;workingDirectory=[string]$Command.workingDirectory
        startedAt=$(if($started){[string]$Command.startedAt}else{$null});finishedAt=$(if($started -and $null -ne $Command.finishedAt){[string]$Command.finishedAt}else{$null});exitCode=$Command.exitCode
        stdoutPath=[string]$Command.stdoutPath;stdoutHash=$Command.stdoutHash;stderrPath=[string]$Command.stderrPath;stderrHash=$Command.stderrHash
        timedOut=[bool]$Command.timedOut;outputExceeded=[bool]$Command.outputExceeded;stopVerified=$StopVerified;transportVerified=($Command.transportVerified -eq $true)
        activationRecordPath=[string]$Handle.activationRecordPath;activationRecordHash=[string]$Handle.activationRecordHash;limits=$limits
    }
    $json=ConvertTo-VerificationCanonicalJson $record
    $errors=$null
    if(-not(Test-Json -Json $json -SchemaFile (Join-Path $PSScriptRoot 'replay-record.schema.json') -ErrorAction SilentlyContinue -ErrorVariable errors)){
        $detail=$(if($errors -and $errors.Count -gt 0){$errors[0].Exception.Message}else{'schema violation'})
        Throw-VerificationReplayFailure "replay record does not match its schema: $detail" 'incomplete' 'replay-record'
    }
    $path=Join-Path ([string]$PreparedRun.controlRoot) "replay/$($Handle.role)/$($Command.commandId).json"
    Write-VerificationNewFile $path $json
    @{path=$path;hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
}
function Resolve-ReplayCreationFailure([hashtable]$PreparedRun,[hashtable]$State,[string]$Stage,[Exception]$Failure) {
    # New-VerificationSandbox の runtimeFailure を creationState・stopState・status で分岐する（reason の符号では分岐しない）。
    # created は部分 handle を sandboxes に残して停止状態を引き継ぐ。unknown と runtimeFailure の欠落・不正は creation-unresolved（未作成・not_run へ丸めない）。
    $status=Get-ReplayExceptionValue $Failure 'status' ''
    $timedOut=($status -ceq 'timed_out') -or (Test-ReplayDeadlineReached $PreparedRun)
    $record=$null
    if($null -ne $Failure -and $Failure.Data.Contains('runtimeFailure')){try{$record=[string]$Failure.Data['runtimeFailure'] | ConvertFrom-Json -AsHashtable -Depth 10 -DateKind String}catch{$record=$null}}
    $valid=($record -is [hashtable]) -and $record.ContainsKey('creationState') -and $record.creationState -in @('not-created','created','unknown') -and $record.ContainsKey('stopState') -and $record.stopState -in @('not-created','stopped','unverified')
    if($valid -and $record.creationState -ceq 'created' -and (Get-ReplayValue $record 'handle') -isnot [hashtable]){$valid=$false}
    if(-not$valid -or $record.creationState -ceq 'unknown'){
        $State.unresolved=$true
        return @{status=$(if($timedOut){'timed_out'}else{'incomplete'});stage=$Stage;reason='creation-unresolved'}
    }
    $reason=[string](Get-ReplayValue $record 'reason')
    if([string]::IsNullOrEmpty($reason)){$reason='runtime-failure'}
    if($record.creationState -ceq 'not-created'){return @{status=$(if($status){$status}else{'blocked'});stage=$Stage;reason=$reason}}
    $State.sandboxes.Add($record.handle);$State.stopStates.Add([string]$record.stopState)
    if($record.stopState -ceq 'stopped'){return @{status=$(if($status -and $status -cne 'incomplete'){$status}else{'blocked'});stage=$Stage;reason=$reason}}
    @{status=$(if($timedOut){'timed_out'}else{'incomplete'});stage=$Stage;reason=$reason}
}
function Test-ReplayActivationRecord([hashtable]$PreparedRun,[hashtable]$Handle) {
    # 搬入の前に、新規VMの activationRecord（当該 run の control/runtime 内）を handle の記録hashで1回読み、runId・sandboxId・名前・役割・profileHash・effectiveSettingsHash が
    # 現在の handle と対応することを確かめる（仕様04。能力試験の古い証拠だけで現在の実行を承認しない）。実効値の各 check は SbxRuntime が作成時に判定済み。
    $path=[string]$Handle.activationRecordPath
    if([string]::IsNullOrEmpty($path) -or -not(Test-VerificationContainment (Join-Path ([string]$PreparedRun.controlRoot) 'runtime') $path)){Throw-VerificationReplayFailure "activation record must be inside control/runtime of this run: $path" 'blocked' 'activation-record'}
    $record=Read-ReplayVerifiedJson $PreparedRun $path ([string]$Handle.activationRecordHash) 'activation-record'
    foreach($pair in @(@('sandboxId','id'),@('sandboxName','name'),@('role','role'),@('profileHash','profileHash'),@('effectiveSettingsHash','effectiveSettingsHash'))){
        if([string]$record[$pair[0]] -cne [string]$Handle[$pair[1]]){Throw-VerificationReplayFailure "activation record $($pair[0]) does not match the sandbox handle" 'blocked' 'activation-record'}
    }
}
function Invoke-ReplayRole([hashtable]$PreparedRun,[hashtable]$Profile,[hashtable]$Lease,[hashtable]$State,[string]$Role,[hashtable]$InputManifest) {
    # 1役割 = 新規VMの作成 → activationRecord の対応確認 → 搬入（Copy）・実体照合（Confirm）→ 固定 argv の unittest（replaySeconds・stderr の要約署名）→ 停止確認 → 外側記録。
    # 停止は work 相の打ち切り後も必ず cleanup 相の予算（現在時刻起点の1台分）で名指しで行う（時間超過時に SbxRuntime は止めない）。停止済み VM へは exec しない。
    $stage=[string]$script:RoleNames[$Role]
    try{$handle=New-VerificationSandbox $PreparedRun $stage $Profile $Lease}
    catch{return @{problem=(Resolve-ReplayCreationFailure $PreparedRun $State $stage $_.Exception);reference=$null}}
    $State.sandboxes.Add($handle);$index=$State.stopStates.Count;$State.stopStates.Add('unverified')
    $problem=$null;$command=$null;$stopState='unverified';$stopAttempted=$false
    try{
        # 各役割の実行環境が新規であることを id で照合する（提案VM・前の役割のVMと別 id）。
        if(-not$State.knownIds.Add([string]$handle.id)){$problem=@{status='incomplete';stage=$stage;reason='sandbox-reused'}}
        else{
            try{
                $budget=@{deadlineAt=[string]$PreparedRun.deadlineAt;cleanupDeadlineAt=$null;limits=@{maxOutputBytes=[long](Get-ReplayLimit $PreparedRun 'maxOutputBytes');commandSeconds=[int](Get-ReplayLimit $PreparedRun 'replaySeconds')};phase='work'}
                Test-ReplayActivationRecord $PreparedRun $handle
                [void](Copy-VerificationSandboxInput $handle ([string]$InputManifest.root) $script:SourceDestination $InputManifest.expected $budget)
                [void](Confirm-VerificationSandboxInput $handle $script:SourceDestination $InputManifest.expected $budget)
                $command=Invoke-VerificationSandboxCommand $handle $script:ReplayArgv $null $script:SourceDestination $script:ReplayEnvironment $budget $script:OutputSignature
                $problem=Get-ReplayCommandProblem $command $stage
            }catch{
                $problem=@{status=(Get-ReplayExceptionValue $_.Exception 'status' 'incomplete');stage=$stage;reason=(Get-ReplayExceptionValue $_.Exception 'reason' 'replay-error')}
            }
        }
        $stopAttempted=$true
        try{$stopState=[string](Stop-VerificationSandbox $handle (New-VerificationCleanupBudget $PreparedRun 1)).stopState}catch{$stopState='unverified'}
    }finally{
        # 途中で呼出しが打ち切られた場合も停止を試みる（結果は返せないが、VM を残さない）。
        if(-not$stopAttempted){try{[void](Stop-VerificationSandbox $handle (New-VerificationCleanupBudget $PreparedRun 1))}catch{}}
    }
    $State.stopStates[$index]=$stopState
    $reference=$null
    if($null -ne $command){
        try{
            $saved=Save-ReplayRecord $PreparedRun $Profile $handle $command $InputManifest ($stopState -ceq 'stopped')
            $reference=@{role=$stage;commandId=[string]$command.commandId;recordPath=$saved.path;recordHash=$saved.hash;sandbox=$handle;inputManifestPath=$InputManifest.path;inputManifestHash=$InputManifest.hash}
        }catch{$problem=Add-ReplayProblem $problem (Get-ReplayExceptionValue $_.Exception 'status' 'incomplete') $stage (Get-ReplayExceptionValue $_.Exception 'reason' 'replay-record')}
    }
    if($stopState -cne 'stopped'){$problem=Add-ReplayProblem $problem 'incomplete' $stage 'stop-unverified'}
    @{problem=$problem;reference=$reference}
}
function Invoke-VerificationReplay([hashtable]$PreparedRun,[hashtable]$ProposalResult,[hashtable]$Profile,[hashtable]$Lease) {
    # VM なしの検査（入力と基準版 → replay profile → 標準ライブラリ → replay-inputs の生成と照合・input manifest）を済ませてから、mode の順に役割ごとの新規VMを使う。
    # candidate-comparison は before → after、reproduction-only は before のみ、recheck は after のみ。前の役割に問題（停止未確認を含む）があれば次の VM を作らずに返す。
    # completed は必要な実行・外側記録・停止を確認したという意味で、合否を表さない。
    Assert-ReplayPreparedRun $PreparedRun
    $result=New-ReplayResult $PreparedRun $null
    $stage='proposal-input';$manifests=[ordered]@{}
    try{
        $checked=Test-ReplayProposal $PreparedRun $ProposalResult
        $result.mode=$checked.mode
        $stage='profile'
        [void](Test-VerificationRuntimeProfile $Profile 'replay-before' $PreparedRun.settings)
        $stage='stdlib'
        Test-ReplayStdlibImports $PreparedRun $Profile $checked
        $stage='replay-input'
        $beforeRoot=$(if($checked.mode -cne 'recheck'){New-ReplayInput $PreparedRun $checked 'before' $false}else{$null})
        $afterRoot=$(if($checked.mode -cne 'reproduction-only'){New-ReplayInput $PreparedRun $checked 'after' ($checked.mode -ceq 'candidate-comparison')}else{$null})
        $verified=Test-ReplayInputs $checked $checked.mode $beforeRoot $afterRoot
        foreach($role in @($verified.inputs.Keys)){$manifests[$role]=Save-ReplayInputManifest $PreparedRun $checked.mode $verified.inputs[$role]}
    }catch{
        $result.status=Get-ReplayExceptionValue $_.Exception 'status' $(if($stage -ceq 'replay-input'){'incomplete'}else{'blocked'})
        $result.failure=@{stage=$stage;reason=(Get-ReplayExceptionValue $_.Exception 'reason' "$stage-error")}
        return $result
    }
    $state=@{sandboxes=[Collections.Generic.List[object]]::new();stopStates=[Collections.Generic.List[string]]::new();knownIds=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal);unresolved=$false}
    $proposalId=Get-ReplayValue $ProposalResult.sandbox 'id'
    if(-not[string]::IsNullOrEmpty([string]$proposalId)){[void]$state.knownIds.Add([string]$proposalId)}
    $problem=$null
    foreach($role in @($manifests.Keys)){
        $outcome=Invoke-ReplayRole $PreparedRun $Profile $Lease $state $role $manifests[$role]
        if($null -ne $outcome.reference){$result[$role]=$outcome.reference}
        if($null -ne $outcome.problem){$problem=Add-ReplayProblem $problem $outcome.problem.status $outcome.problem.stage $outcome.problem.reason;break}
    }
    $result.sandboxes=[object[]]$state.sandboxes.ToArray()
    $result.allStopped=$(if($state.unresolved){$false}elseif($state.stopStates.Count -eq 0){$null}else{@($state.stopStates | Where-Object {$_ -cne 'stopped'}).Count -eq 0})
    if($null -ne $problem){$result.status=$problem.status;$result.failure=@{stage=$problem.stage;reason=$problem.reason}}
    else{$result.status='completed'}
    $result
}

# ---- 未実行結果 ----
function New-VerificationReplayNotRun([hashtable]$PreparedRun,[hashtable]$Failure) {
    # 提案が ready でない場合に CLI が呼ぶ。VM・モデルを起動しない。status=not_run、sandboxes=[]、before/after/allStopped=null、failure に上流の失敗段階。
    # 作成成否・ID が不明な上流失敗（reason=creation-unresolved、または creationState=unknown）は not_run へ丸めず incomplete にする。
    Assert-ReplayPreparedRun $PreparedRun
    $stage=[string](Get-ReplayValue $Failure 'stage');$reason=[string](Get-ReplayValue $Failure 'reason')
    if([string]::IsNullOrEmpty($stage) -or [string]::IsNullOrEmpty($reason)){throw 'Failure with stage and reason required'}
    $unresolved=($reason -ceq 'creation-unresolved') -or ([string](Get-ReplayValue $Failure 'creationState') -ceq 'unknown')
    # mode は提案結果を受け取らないので recheck 以外は決められない（null）。
    $result=New-ReplayResult $PreparedRun $(if(Test-ReplayRecheck $PreparedRun){'recheck'}else{$null})
    $result.status=$(if($unresolved){'incomplete'}else{'not_run'})
    $result.failure=@{stage=$stage;reason=$(if($unresolved){'creation-unresolved'}else{$reason})}
    $result
}

Export-ModuleMember -Function Invoke-VerificationReplay,New-VerificationReplayNotRun
