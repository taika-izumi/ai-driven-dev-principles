# 提案作成（仕様02「提案作成」「提案書式と回収」「ProposalResultV3」）。提案用VMの起動・依頼・固定エクスポーターによる回収・未信頼Envelopeの検査・accepted の生成・停止を行う。
# VM の操作は SbxRuntime の公開操作だけを使う。子の出力（実行イベント・最終応答・Envelope）は未信頼データとして扱い、ホストで import・実行しない。
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'RequestCopy.psm1')                          # 正規化JSON・ハッシュ・新規作成書込・UTC時刻・パス検査を共用する
Import-Module (Join-Path $PSScriptRoot 'SbxRuntime.psm1') -DisableNameChecking      # VM の作成・搬入・実行・停止（Acquire- は仕様02の公開操作名）

$script:Utf8=[Text.UTF8Encoding]::new($false)
# VM 内の固定パス（外側で定め、子から受け取らない）。
$script:SourceDestination='/home/agent/workspace/source'
$script:ProposalDirectory='/home/agent/workspace/proposal'
$script:ExporterDestination='/home/agent/proposal-exporter'
$script:ExporterName='proposal-export.py'
# 回収（proposal-export.py の exec）と搬入の時間上限（秒）。計画「時間上限の全域表」の作成・搬入・回収の値。limits に連動させない。
$script:ExportSeconds=240
$script:StrictUtf8=[Text.UTF8Encoding]::new($false,$true)
# Envelope の構造上の最大の深さ（ルート=1、findings=2、finding=3、sourcePaths=4）。これを超える入れ子は書式外として拒否する。
$script:MaxEnvelopeDepth=4
$script:EnvelopeKeys=@{root=@('schemaVersion','runId','summary','findings','files','truncated');finding=@('description','sourcePaths');file=@('kind','path','contentBase64')}
# 書き込まない制御パスの成分（仕様02 と、原本で予約済みの .verification-*）。大小文字を区別しない。
$script:ProtectedComponents=@('.git','.codex','.claude','.agents','.mcp.json','.verification-tests','.verification-control')
$script:ReservedNames=@('CON','PRN','AUX','NUL','CONIN$','CONOUT$')+@(foreach($n in 1..9){"COM$n";"LPT$n"})+@(foreach($c in @([char]0xB9,[char]0xB2,[char]0xB3)){"COM$c";"LPT$c"})

# ---- 共通補助 ----
function Throw-VerificationEnvelopeRejection([string]$Step,[string]$Message) {
    # 最初の違反で全体を拒否する。Envelope の違反は子の提案の不備なので failed。
    Invoke-VerificationFailure "proposal envelope rejected ($Step): $Message" 'failed' "envelope-$Step"
}
function Read-ProposalBaselineManifest([hashtable]$PreparedRun) {
    # 基準版の一覧（replacement の存在確認と、proposal-input 搬入の ExpectedManifest の両方に使う）。
    # 検査済み JSON の1回読み（期待hash・厳格UTF-8・重複キー・runId・一覧要素）は RequestCopy の共通補助を使う（Replay と同じ手順）。
    Read-VerificationVerifiedJson ([string]$PreparedRun.baselineManifestPath) ([string]$PreparedRun.baselineManifestHash) ([string]$PreparedRun.runId) 'files' 'blocked' 'baseline-manifest'
}
function Get-ProposalManifestPaths([hashtable]$Manifest,[string]$ListKey) {
    $paths=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach($item in @($Manifest[$ListKey])){[void]$paths.Add([string]$item.path)}
    ,$paths
}

# ---- 未信頼 Envelope の検査 ----
function New-ProposalJsonDocument([string]$Text,[int]$MaxDepth,[bool]$AllowDuplicateProperties) {
    # 重複キー・深さは System.Text.Json の解析時の検査に任せる（.NET 10 の AllowDuplicateProperties と MaxDepth）。
    # PowerShell で全要素を走査すると 16MiB の病的な wire で数分かかったため（実測 約209秒）、解析を段ごとに分けて順序を保つ。
    $options=[Text.Json.JsonDocumentOptions]::new()
    $options.CommentHandling=[Text.Json.JsonCommentHandling]::Disallow;$options.AllowTrailingCommas=$false
    $options.MaxDepth=$MaxDepth;$options.AllowDuplicateProperties=$AllowDuplicateProperties
    [Text.Json.JsonDocument]::Parse($Text,$options)
}
function Get-ProposalElementString([Text.Json.JsonElement]$Element) {
    try{@{ok=$true;value=$Element.GetString()}}catch{@{ok=$false;value=$null}}
}
function Get-ProposalPathViolation([string]$Path) {
    # UTF-8 の POSIX 相対表記だけを受ける。Windows 上で別名・別ストリーム・予約デバイスになる表記も拒否する。
    if([string]::IsNullOrEmpty($Path)){return 'empty path'}
    try{[void]$script:StrictUtf8.GetBytes($Path)}catch{return 'path is not valid UTF-8 (unpaired surrogate)'}
    if($Path.StartsWith('/')){return 'absolute or UNC path'}
    foreach($ch in $Path.ToCharArray()){
        $code=[int]$ch
        if($code -eq 0){return 'NUL character'}
        if($code -eq 0x5C){return 'backslash'}
        if($code -eq 0x3A){return 'colon (drive letter or alternate data stream)'}
        if($code -lt 0x20 -or $code -eq 0x7F){return 'control character'}
        if('<>"|?*'.IndexOf($ch) -ge 0){return "character not allowed in Windows file names: $ch"}
    }
    foreach($part in $Path.Split('/')){
        if($part.Length -eq 0){return 'empty path component'}
        if($part -ceq '.' -or $part -ceq '..'){return "dot component: $part"}
        if($part.EndsWith(' ') -or $part.EndsWith('.')){return "component ends with a space or dot: $part"}
        $stem=$part.Split('.')[0].TrimEnd(' ').ToUpperInvariant()
        if($script:ReservedNames -ccontains $stem){return "Windows reserved name: $part"}
        if($script:ProtectedComponents -ccontains $part.ToLowerInvariant()){return "protected path component: $part"}
    }
    $null
}
function Get-ProposalKindDirectory([string]$Kind) { if($Kind -ceq 'test'){'tests'}else{'replacements'} }
function Test-VerificationProposalEnvelope([byte[]]$Wire,[hashtable]$PreparedRun) {
    # 未信頼の wire を次の順に検査し、最初の違反で全体を拒否する（例外。Data status=failed・reason=envelope-<段>）:
    # wire容量 → JSON 1行 → 重複キー → 深さ → 未知キー → 型（proposal.schema.json）→ truncated → runId → 件数 → path規則 → kind → test 0件 → base64正規性 → 復号後サイズ → UTF-8テキスト。
    # 戻り値は検査済み一覧 {runId, summary, findings[{description,sourcePaths}], files[{kind,path,size,sha256,bytes}]}。子のJSONをそのまま返さない。
    if($null -eq $PreparedRun -or $PreparedRun.schemaVersion -ne 3){throw 'PreparedRunV3 required'}
    $runId=[string]$PreparedRun.runId
    $maxWire=Get-VerificationLimit $PreparedRun 'maxWireBytes';$maxFiles=Get-VerificationLimit $PreparedRun 'maxProposalFiles'
    $maxFileBytes=Get-VerificationLimit $PreparedRun 'maxFileBytes';$maxProposalBytes=Get-VerificationLimit $PreparedRun 'maxProposalBytes'
    # 1. wire 容量（base64 復号・JSON 解析の前）
    if($null -eq $Wire -or $Wire.Length -eq 0){Throw-VerificationEnvelopeRejection 'wire' 'wire is empty'}
    if($Wire.Length -gt $maxWire){Throw-VerificationEnvelopeRejection 'wire' "wire is $($Wire.Length) bytes (limit $maxWire)"}
    # 2. JSON 1行（途中切断・複数行・非UTF-8 はここで拒否）
    try{$text=$script:StrictUtf8.GetString($Wire)}catch{Throw-VerificationEnvelopeRejection 'json' 'wire is not valid UTF-8'}
    if($text.EndsWith("`n")){$text=$text.Substring(0,$text.Length-1)}
    if($text.IndexOf("`n") -ge 0 -or $text.IndexOf("`r") -ge 0){Throw-VerificationEnvelopeRejection 'json' 'wire must be a single JSON line'}
    # 深さの上限は wire の長さ（それ以上の入れ子は書けない）。ここでは JSON として完結しているかだけを見る。
    $unbounded=[int][Math]::Min([int]::MaxValue,[long]$Wire.Length+1)
    try{(New-ProposalJsonDocument $text $unbounded $true).Dispose()}catch{Throw-VerificationEnvelopeRejection 'json' ('wire is not one complete JSON value: '+$_.Exception.Message)}
    # 3. 重複キー（同一オブジェクト内。入れ子を含む）
    try{(New-ProposalJsonDocument $text $unbounded $false).Dispose()}catch{Throw-VerificationEnvelopeRejection 'duplicate-key' 'an object has duplicate keys'}
    # 4. 深さ（ルート=1。以後の検査はこの文書で行う）
    try{$document=New-ProposalJsonDocument $text $script:MaxEnvelopeDepth $true}catch{Throw-VerificationEnvelopeRejection 'depth' "nesting depth exceeds $($script:MaxEnvelopeDepth)"}
    try{
        $root=$document.RootElement
        if($root.ValueKind -ne [Text.Json.JsonValueKind]::Object){Throw-VerificationEnvelopeRejection 'type' 'envelope must be a JSON object'}
        # 5. 未知キー（ルート・findings の要素・files の要素）。要素がオブジェクトでなければ未知キーは無いので、型の段で拒否する印だけ残す。
        $unknown=$null;$nonObjectItem=$false
        foreach($property in $root.EnumerateObject()){if($script:EnvelopeKeys.root -cnotcontains $property.Name){$unknown="envelope has unknown key: $($property.Name)";break}}
        foreach($pair in @(@('findings','finding'),@('files','file'))){
            if($null -ne $unknown){break}
            $list=[Text.Json.JsonElement]::new();if(-not$root.TryGetProperty($pair[0],[ref]$list) -or $list.ValueKind -ne [Text.Json.JsonValueKind]::Array){continue}
            $allowed=$script:EnvelopeKeys[$pair[1]]
            foreach($item in $list.EnumerateArray()){
                if($item.ValueKind -ne [Text.Json.JsonValueKind]::Object){$nonObjectItem=$true;continue}
                foreach($property in $item.EnumerateObject()){if($allowed -cnotcontains $property.Name){$unknown="$($pair[1]) has unknown key: $($property.Name)";break}}
                if($null -ne $unknown){break}
            }
        }
        if($null -ne $unknown){Throw-VerificationEnvelopeRejection 'unknown-key' $unknown}
        # 6. 型（schema。schemaVersion は整数表記の 3 だけ）。オブジェクトでない要素は schema を待たずに拒否する（大量の要素で schema 検査が遅くなるため）。
        if($nonObjectItem){Throw-VerificationEnvelopeRejection 'type' 'findings and files items must be objects'}
        $errors=$null
        if(-not(Test-Json -Json $text -SchemaFile (Join-Path $PSScriptRoot 'proposal.schema.json') -ErrorAction SilentlyContinue -ErrorVariable errors)){
            $detail=$(if($errors -and $errors.Count -gt 0){$errors[0].Exception.Message}else{'schema violation'})
            Throw-VerificationEnvelopeRejection 'type' $detail
        }
        if($root.GetProperty('schemaVersion').GetRawText() -cne '3'){Throw-VerificationEnvelopeRejection 'type' 'schemaVersion must be the integer 3'}
        # 文字列は対のないサロゲートを含むと取り出せない（GetString が例外）。summary・findings は型の段で拒否し、path は path 規則、contentBase64 は base64 の段で拒否する。
        $summary=Get-ProposalElementString $root.GetProperty('summary')
        if(-not$summary.ok){Throw-VerificationEnvelopeRejection 'type' 'summary is not valid Unicode text'}
        $findings=[Collections.Generic.List[object]]::new()
        foreach($element in $root.GetProperty('findings').EnumerateArray()){
            $description=Get-ProposalElementString $element.GetProperty('description')
            $sourcePaths=@(foreach($p in $element.GetProperty('sourcePaths').EnumerateArray()){Get-ProposalElementString $p})
            if(-not$description.ok -or @($sourcePaths | Where-Object {-not$_.ok}).Count -gt 0){Throw-VerificationEnvelopeRejection 'type' 'findings contain text that is not valid Unicode'}
            $findings.Add(@{description=$description.value;sourcePaths=[string[]]@($sourcePaths | ForEach-Object {$_.value})})
        }
        # 7. エクスポーターが上限超過・リンク等でファイルを含めなかった印（切り詰めた提案を成功にしない）
        $truncated=[Text.Json.JsonElement]::new()
        if($root.TryGetProperty('truncated',[ref]$truncated) -and $truncated.ValueKind -eq [Text.Json.JsonValueKind]::True){Throw-VerificationEnvelopeRejection 'truncated' 'exporter omitted files (limit exceeded or not a regular file)'}
        # 8. runId
        $claimedRunId=Get-ProposalElementString $root.GetProperty('runId')
        if(-not$claimedRunId.ok -or $claimedRunId.value -cne $runId){Throw-VerificationEnvelopeRejection 'run-id' 'runId does not match this run'}
        # 9. 件数
        $fileElements=@($root.GetProperty('files').EnumerateArray())
        if($fileElements.Count -gt $maxFiles){Throw-VerificationEnvelopeRejection 'file-count' "$($fileElements.Count) files (limit $maxFiles)"}
        $files=@(foreach($element in $fileElements){
            $path=Get-ProposalElementString $element.GetProperty('path')
            @{kind=$element.GetProperty('kind').GetString();path=$path.value;pathValid=$path.ok;contentBase64=(Get-ProposalElementString $element.GetProperty('contentBase64')).value}
        })
    }finally{$document.Dispose()}
    # 10. path 規則（各path → 大小文字を無視した重複・ディレクトリ名の大小文字違い → 親子衝突）。test と replacement は accepted 内の別ディレクトリ。
    foreach($file in $files){
        $violation=$(if(-not$file.pathValid){'path is not valid UTF-8 (unpaired surrogate)'}else{Get-ProposalPathViolation $file.path})
        if($null -ne $violation){Throw-VerificationEnvelopeRejection 'path' "$violation ($($file.kind): $($file.path))"}
    }
    $fileKeys=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    $directoryKeys=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    foreach($file in $files){
        $key=(Get-ProposalKindDirectory $file.kind)+'/'+$file.path
        if($fileKeys.ContainsKey($key.ToUpperInvariant())){Throw-VerificationEnvelopeRejection 'path' "duplicate path ignoring case: $key"}
        $fileKeys[$key.ToUpperInvariant()]=$key
        $parts=$key.Split('/')
        for($i=1;$i -lt $parts.Count;$i++){
            $prefix=[string]::Join('/',$parts,0,$i)
            $upper=$prefix.ToUpperInvariant()
            if($directoryKeys.ContainsKey($upper)){if($directoryKeys[$upper] -cne $prefix){Throw-VerificationEnvelopeRejection 'path' "directory names differ only in case: $($directoryKeys[$upper]) / $prefix"}}
            else{$directoryKeys[$upper]=$prefix}
        }
    }
    foreach($upper in $fileKeys.Keys){if($directoryKeys.ContainsKey($upper)){Throw-VerificationEnvelopeRejection 'path' "a file and a directory share a path: $($fileKeys[$upper])"}}
    # 11. kind（test は tests/ 接頭辞なしの test_*.py / __init__.py、replacement は基準版にある .py 通常ファイル）→ test 0件
    $baseline=$null
    foreach($file in $files){
        $parts=$file.path.Split('/');$name=$parts[-1]
        if($file.kind -ceq 'test'){
            if($parts[0].ToUpperInvariant() -ceq 'TESTS'){Throw-VerificationEnvelopeRejection 'kind' "test path must be relative to accepted/tests without a tests/ prefix: $($file.path)"}
            # test は accepted/tests 直下の名前だけ（ブリーフ「tests/test_*.py・tests/__init__.py」。サブディレクトリは受けない）。
            if($parts.Count -ne 1){Throw-VerificationEnvelopeRejection 'kind' "test must be a file name directly under accepted/tests (no subdirectories): $($file.path)"}
            if(-not($name -ceq '__init__.py' -or ($name.StartsWith('test_',[StringComparison]::Ordinal) -and $name.EndsWith('.py',[StringComparison]::Ordinal)))){Throw-VerificationEnvelopeRejection 'kind' "test file must be test_*.py or __init__.py: $($file.path)"}
        }else{
            if(-not$name.EndsWith('.py',[StringComparison]::Ordinal)){Throw-VerificationEnvelopeRejection 'kind' "replacement must be a .py file: $($file.path)"}
            if($null -eq $baseline){$baseline=Get-ProposalManifestPaths (Read-ProposalBaselineManifest $PreparedRun) 'files'}
            if(-not$baseline.Contains($file.path)){Throw-VerificationEnvelopeRejection 'kind' "replacement is not a file in the baseline: $($file.path)"}
        }
    }
    if(@($files | Where-Object {$_.kind -ceq 'test'}).Count -eq 0){Throw-VerificationEnvelopeRejection 'no-test' 'at least one test file is required'}
    # 12. base64 の正規性（標準アルファベット・パディング込み・空白なし・再符号化で一致）
    foreach($file in $files){
        $encoded=$file.contentBase64
        if($null -eq $encoded -or $encoded.Length % 4 -ne 0 -or -not[regex]::IsMatch($encoded,'\A[A-Za-z0-9+/]*={0,2}\z')){Throw-VerificationEnvelopeRejection 'base64' "contentBase64 is not canonical base64: $($file.path)"}
        try{$bytes=[Convert]::FromBase64String($encoded)}catch{Throw-VerificationEnvelopeRejection 'base64' "contentBase64 cannot be decoded: $($file.path)"}
        if([Convert]::ToBase64String($bytes) -cne $encoded){Throw-VerificationEnvelopeRejection 'base64' "contentBase64 is not canonical base64: $($file.path)"}
        $file.bytes=$bytes
    }
    # 13. 復号後サイズ（1ファイル・合計）
    $total=0L
    foreach($file in $files){
        if($file.bytes.Length -gt $maxFileBytes){Throw-VerificationEnvelopeRejection 'size' "$($file.path) is $($file.bytes.Length) bytes (limit $maxFileBytes)"}
        $total+=$file.bytes.Length
    }
    if($total -gt $maxProposalBytes){Throw-VerificationEnvelopeRejection 'size' "proposal is $total bytes (limit $maxProposalBytes)"}
    # 14. UTF-8 の Python テキスト（不正なバイト列・NUL を拒否。内容が無害である保証はしない）
    foreach($file in $files){
        try{$content=$script:StrictUtf8.GetString($file.bytes)}catch{Throw-VerificationEnvelopeRejection 'text' "$($file.path) is not valid UTF-8"}
        if($content.IndexOf([char]0) -ge 0){Throw-VerificationEnvelopeRejection 'text' "$($file.path) contains NUL"}
    }
    @{
        runId=$runId;summary=$summary.value;findings=[object[]]$findings.ToArray()
        files=@(foreach($file in $files){@{kind=$file.kind;path=$file.path;size=[long]$file.bytes.Length;sha256=(Get-VerificationBytesHash $file.bytes);bytes=$file.bytes}})
    }
}

# ---- accepted の生成と manifest ----
function Throw-VerificationAcceptedUnsafe([string]$Message) { Invoke-VerificationFailure "accepted rejected: $Message" 'blocked' 'accepted-unsafe' }
function New-ProposalAcceptedDirectory([string]$Path) {
    # 1段ずつ作る。既存ならリンク・再解析ポイント・ファイルでないことを確かめる（リンクの先はたどらない）。
    $attributes=$null
    try{$attributes=[IO.File]::GetAttributes($Path)}catch [IO.FileNotFoundException],[IO.DirectoryNotFoundException]{$attributes=$null}
    if($null -eq $attributes){[void][IO.Directory]::CreateDirectory($Path);$attributes=[IO.File]::GetAttributes($Path)}
    if($attributes -band [IO.FileAttributes]::ReparsePoint){Throw-VerificationAcceptedUnsafe "link or reparse point: $Path"}
    if(-not($attributes -band [IO.FileAttributes]::Directory)){Throw-VerificationAcceptedUnsafe "existing file where a directory is needed: $Path"}
}
function Write-VerificationAcceptedFiles([hashtable]$PreparedRun,[hashtable]$Envelope) {
    # 検査済み一覧だけから accepted/tests/<path>・accepted/replacements/<path> を CreateNew の通常ファイルとして作る。
    # accepted 自身と祖先にリンク・再解析ポイント・既存ファイルがあれば拒否する。サイズと SHA256 は書いた実体から外側で計算する。
    if($null -eq $Envelope -or -not$Envelope.ContainsKey('files')){throw 'checked envelope required'}
    try{$accepted=[IO.Path]::TrimEndingDirectorySeparator((Resolve-VerificationPath ([string]$PreparedRun.acceptedRoot)))}catch{Throw-VerificationAcceptedUnsafe $_.Exception.Message}
    New-ProposalAcceptedDirectory $accepted
    if([IO.Directory]::GetFileSystemEntries($accepted).Length -gt 0){Throw-VerificationAcceptedUnsafe "accepted is not empty: $accepted"}
    $artifacts=[Collections.Generic.List[object]]::new()
    foreach($file in @($Envelope.files)){
        if($null -ne (Get-ProposalPathViolation $file.path) -or $file.kind -notin @('test','replacement')){throw "unchecked file entry: $($file.path)"}
        $directory=Get-ProposalKindDirectory $file.kind
        $parts=@($directory)+@($file.path.Split('/'))
        $current=$accepted
        for($i=0;$i -lt $parts.Count-1;$i++){$current=[IO.Path]::Combine($current,$parts[$i]);New-ProposalAcceptedDirectory $current}
        $target=[IO.Path]::Combine($current,$parts[-1])
        if(-not[IO.Path]::GetFullPath($target).Equals($target,[StringComparison]::Ordinal) -or -not(Test-VerificationContainment $accepted $target)){Throw-VerificationAcceptedUnsafe "path does not stay as written inside accepted: $($file.path)"}
        try{$stream=[IO.File]::Open($target,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)}catch{Throw-VerificationAcceptedUnsafe "cannot create a new file (existing entry?): $target"}
        try{$stream.Write($file.bytes,0,$file.bytes.Length)}finally{$stream.Dispose()}
        $info=[IO.FileInfo]::new($target)
        if($info.Attributes -band [IO.FileAttributes]::ReparsePoint){Throw-VerificationAcceptedUnsafe "created file is a reparse point: $target"}
        $hash=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
        if($info.Length -ne $file.bytes.Length -or $hash -cne (Get-VerificationBytesHash $file.bytes)){Invoke-VerificationFailure "accepted file does not match the received bytes: $target" 'incomplete' 'accepted-mismatch'}
        $artifacts.Add(@{kind=$file.kind;path="$directory/$($file.path)";size=[long]$info.Length;sha256=$hash})
    }
    Get-ProposalSortedArtifacts $artifacts.ToArray()   # 呼出し側は @() で受ける
}
function Get-ProposalSortedArtifacts([object[]]$Artifacts) {
    # accepted からの相対パスの序数順。項目は kind・path・size・sha256 だけにする。
    $list=[Collections.Generic.List[object]]::new()
    foreach($artifact in @($Artifacts)){$list.Add(@{kind=[string]$artifact.kind;path=[string]$artifact.path;size=[long]$artifact.size;sha256=([string]$artifact.sha256).ToUpperInvariant()})}
    $list.Sort([Comparison[object]]{param($left,$right) [string]::CompareOrdinal([string]$left.path,[string]$right.path)})
    $list.ToArray()   # 呼出し側は @() で受ける
}
function Get-ProposalTestsManifestHash([object[]]$Artifacts) {
    # test の accepted 相対パス・サイズ・SHA256 をパス順に並べた配列の正規化JSONの SHA256。ホストの絶対パスや保存日時を含めない。
    # 計算は RequestCopy の Get-VerificationTestsManifestHash（Replay・Result と共有する約束）。ここでは test だけを選ぶ。
    Get-VerificationTestsManifestHash ([object[]]@(foreach($artifact in @($Artifacts)){if($artifact.kind -ceq 'test'){$artifact}}))
}
function Save-VerificationProposalManifest([hashtable]$PreparedRun,[string]$Origin,[object[]]$Artifacts) {
    $sorted=@(Get-ProposalSortedArtifacts $Artifacts)
    $testsHash=Get-ProposalTestsManifestHash $sorted
    $path=Join-Path ([string]$PreparedRun.controlRoot) 'proposal/manifest.json'
    Write-VerificationNewFile $path (ConvertTo-VerificationCanonicalJson @{schemaVersion=3;runId=[string]$PreparedRun.runId;origin=$Origin;artifacts=[object[]]$sorted;testsManifestHash=$testsHash})
    @{manifestPath=$path;manifestHash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash;testsManifestHash=$testsHash;artifacts=[object[]]$sorted}
}

# ---- ProposalResultV3 ----
function New-ProposalResult([hashtable]$PreparedRun,[string]$Origin) {
    # 外側が生成する結果。子の JSON をそのまま返さない。manifest は未確定なら null、sandbox は未作成なら null。
    @{schemaVersion=3;runId=[string]$PreparedRun.runId;status=$null;origin=$Origin;sandbox=$null;summary=$null;findings=$null;artifacts=[object[]]@();manifestPath=$null;manifestHash=$null;testsManifestHash=$null;stopState='not-created';failure=$null}
}

# ---- recheck（VM・モデルを起動しない） ----
function Get-ProposalAcceptedFileMap([string]$AcceptedRoot) {
    $root=[IO.Path]::TrimEndingDirectorySeparator((Resolve-VerificationPath $AcceptedRoot))
    $map=@{}
    foreach($info in [IO.DirectoryInfo]::new($root).EnumerateFileSystemInfos('*',[IO.SearchOption]::AllDirectories)){
        if($info.Attributes -band [IO.FileAttributes]::ReparsePoint){Invoke-VerificationFailure "reparse point inside accepted: $($info.FullName)" 'blocked' 'recheck-tests-changed'}
        if($info -is [IO.FileInfo]){$map[[IO.Path]::GetRelativePath($root,$info.FullName).Replace('\','/')]=@{size=[long]$info.Length;sha256=(Get-FileHash -LiteralPath $info.FullName -Algorithm SHA256).Hash}}
    }
    $map
}
function Invoke-VerificationProposalRecheck([hashtable]$PreparedRun) {
    # 前回選択した固定テストだけから ready を外側で作る。追加・欠落・改変は拒否する。生成した提案や停止成功を装わない（origin=reused-tests・sandbox=null・stopState=not-created）。
    $result=New-ProposalResult $PreparedRun 'reused-tests'
    try{
        $expected=@($PreparedRun.recheckArtifacts)
        $manifest=Read-VerificationVerifiedJson ([string]$PreparedRun.recheckManifestPath) ([string]$PreparedRun.recheckManifestHash) ([string]$PreparedRun.runId) 'tests' 'blocked' 'recheck-manifest'
        $recorded=@{}
        foreach($test in @($manifest.tests)){$recorded[[string]$test.path]=$test}
        $expectedMap=@{}
        foreach($artifact in $expected){
            $path=[string]$artifact.path
            if($artifact.kind -cne 'test' -or -not$path.StartsWith('tests/',[StringComparison]::Ordinal) -or $expectedMap.ContainsKey($path)){Invoke-VerificationFailure "recheck artifact must be a unique test under tests/: $path" 'blocked' 'recheck-manifest'}
            $expectedMap[$path]=$artifact
            if(-not$recorded.ContainsKey($path) -or [long]$recorded[$path].size -ne [long]$artifact.size -or [string]$recorded[$path].sha256 -ine [string]$artifact.sha256){Invoke-VerificationFailure "recheck manifest does not list the prepared test: $path" 'blocked' 'recheck-manifest'}
        }
        if($recorded.Count -ne $expectedMap.Count){Invoke-VerificationFailure 'recheck manifest lists tests that were not prepared' 'blocked' 'recheck-manifest'}
        $actual=Get-ProposalAcceptedFileMap ([string]$PreparedRun.acceptedRoot)
        $missing=@($expectedMap.Keys | Where-Object {-not$actual.ContainsKey($_)} | Sort-Object)
        $extra=@($actual.Keys | Where-Object {-not$expectedMap.ContainsKey($_)} | Sort-Object)
        $changed=@($expectedMap.Keys | Where-Object {$actual.ContainsKey($_) -and ($actual[$_].size -ne [long]$expectedMap[$_].size -or $actual[$_].sha256 -ine [string]$expectedMap[$_].sha256)} | Sort-Object)
        if($missing.Count+$extra.Count+$changed.Count -gt 0){Invoke-VerificationFailure ("recheck tests differ from the previous selection (missing: $($missing -join ', '); added: $($extra -join ', '); changed: $($changed -join ', '))") 'blocked' 'recheck-tests-changed'}
        $saved=Save-VerificationProposalManifest $PreparedRun 'reused-tests' $expected
        $result.artifacts=$saved.artifacts;$result.manifestPath=$saved.manifestPath;$result.manifestHash=$saved.manifestHash;$result.testsManifestHash=$saved.testsManifestHash
        $result.status='ready'
    }catch{
        $result.status=Get-VerificationExceptionValue $_.Exception 'status' 'blocked'
        $result.failure=@{stage='recheck';reason=(Get-VerificationExceptionValue $_.Exception 'reason' 'recheck-failed')}
        Write-VerificationStageError 'proposal' 'recheck' $result.failure.reason $_.Exception
        $result.artifacts=[object[]]@();$result.manifestPath=$null;$result.manifestHash=$null;$result.testsManifestHash=$null
    }
    $result
}

# ---- 提案（VM 内の Codex） ----
function New-VerificationProposalRequest([hashtable]$PreparedRun) {
    # 目的・合格条件・作業先・書式・禁止事項・残り時間の短い依頼。残り時間は助言で、強制は外側の上限で行う。本文資料は子がコピーから探索する。
    $request=$PreparedRun.request
    $criteria=@(Get-VerificationValue $request 'acceptanceCriteria')
    $remaining=[Math]::Min([double](Get-VerificationLimit $PreparedRun 'proposalSeconds'),([DateTimeOffset]::Parse([string]$PreparedRun.deadlineAt,[Globalization.CultureInfo]::InvariantCulture).UtcDateTime-[DateTime]::UtcNow).TotalSeconds)
    $monotonic=Get-VerificationRunRemainingSeconds ([string]$PreparedRun.runId)   # run 単位の単調時計があれば、その残りとの小さい方
    if($null -ne $monotonic){$remaining=[Math]::Min($remaining,[double]$monotonic)}
    $remaining=[Math]::Max(0,[Math]::Floor($remaining))
    $lines=[Collections.Generic.List[string]]::new()
    $lines.Add('あなたは隔離された検証用VMの中で、不具合の再現テストと修正候補を提案する担当です。')
    $lines.Add('目的: '+[string](Get-VerificationValue $request 'objective'))
    $lines.Add('合格条件:');foreach($criterion in $criteria){$lines.Add('- '+[string]$criterion)}
    $lines.Add("資料: $($script:SourceDestination)（原本の独立コピー。読んで調べてよい。ここへの変更は提案として扱わない）")
    $lines.Add("作業先: $($script:ProposalDirectory)（提案はここにだけ置く）")
    $lines.Add('書式:')
    $lines.Add('- proposal.json: {"summary": "要約", "findings": [{"description": "所見", "sourcePaths": ["資料内の相対パス"]}]}')
    $lines.Add('- tests/: 不具合を再現する unittest。ファイル名は test_*.py（必要なら __init__.py）。少なくとも1件。')
    $lines.Add('- replacements/: 修正候補（任意）。資料に既にある .py ファイルと同じ相対パスに、置き換え後の全文を置く。')
    $lines.Add("- 上限: ファイル $(Get-VerificationLimit $PreparedRun 'maxProposalFiles') 件、1ファイル $(Get-VerificationLimit $PreparedRun 'maxFileBytes') バイト、合計 $(Get-VerificationLimit $PreparedRun 'maxProposalBytes') バイト。超えた提案は全体が不採用になる。")
    $lines.Add('禁止事項: ファイルの削除・改名の提案、.py 以外の置き換え、実行コマンドの提案、.git・.codex・.claude・.agents・.mcp.json 配下への書き込み、認証情報や外部接続の探索。')
    $lines.Add("残り時間の目安: 約 $remaining 秒（目安であり、上限は外側で強制する）")
    [string]::Join("`n",$lines)+"`n"
}
function New-ProposalBudget([hashtable]$PreparedRun,[long]$CommandSeconds,[long]$MaxOutputBytes) {
    # runId は run 単位の単調時計の鍵（Execution が壁時計と単調時計の残りの小さい方で打ち切る）。
    @{deadlineAt=[string]$PreparedRun.deadlineAt;cleanupDeadlineAt=$null;limits=@{maxOutputBytes=[long]$MaxOutputBytes;commandSeconds=[int]$CommandSeconds};phase='work';runId=[string]$PreparedRun.runId}
}
function Initialize-ProposalExporter([hashtable]$PreparedRun) {
    # 固定エクスポーターを外側の control へ複製し、搬入元（検査済みの通常ファイル1件）とその期待一覧を作る。
    $source=Join-Path $PSScriptRoot $script:ExporterName
    $root=Join-Path ([string]$PreparedRun.controlRoot) 'proposal/exporter'
    [void][IO.Directory]::CreateDirectory($root)
    $target=Join-Path $root $script:ExporterName
    [IO.File]::Copy($source,$target,$false)
    $hash=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
    if($hash -cne (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash){Invoke-VerificationFailure 'exporter copy does not match the fixed exporter' 'incomplete' 'exporter-copy'}
    @{root=$root;manifest=@{files=@(@{path=$script:ExporterName;size=[long]([IO.FileInfo]::new($target)).Length;sha256=$hash})}}
}
function Get-ProposalCommandProblem([hashtable]$Record,[string]$Stage,[bool]$RequireSignature) {
    # CommandRecord の外側の観測だけで判定する（子の自己申告・終了文字列を成功の証拠にしない）。
    if(-not$Record.started){
        if($Record.refusedReason -ceq 'deadline-reached'){return @{status='timed_out';stage=$Stage;reason="$Stage-deadline-reached"}}
        return @{status='failed';stage=$Stage;reason="$Stage-not-started"}
    }
    if($Record.outputExceeded){return @{status='failed';stage=$Stage;reason="$Stage-output-exceeded"}}
    if($Record.timedOut){return @{status='timed_out';stage=$Stage;reason="$Stage-timed-out"}}
    if($Record.exitCode -ne 0){return @{status='failed';stage=$Stage;reason="$Stage-failed"}}
    if($RequireSignature -and $Record.transportVerified -ne $true){return @{status='failed';stage=$Stage;reason="$Stage-unverified"}}
    $null
}
function Complete-VerificationProposalCreationFailure([hashtable]$Result,[hashtable]$PreparedRun,[Exception]$Failure) {
    # New-VerificationSandbox の runtimeFailure を捕捉する。created なら確定済み handle を sandbox に残し、停止済みでも起動失敗を成功にしない。
    # unknown・停止未確認は incomplete（時間超過なら timed_out）。runtimeFailure の欠落・不正は作成済みの可能性があるので creation-unresolved の incomplete。
    $status=Get-VerificationExceptionValue $Failure 'status' ''
    $timedOut=($status -ceq 'timed_out') -or (Test-VerificationDeadlineReached ([string]$PreparedRun.deadlineAt) ([string]$PreparedRun.runId))
    # 解析と値域の検査は RequestCopy の共通補助（Replay と同じ判定）。不正・欠落は $null。
    $record=ConvertFrom-VerificationRuntimeFailure $Failure
    $recordReason=$(if($null -ne $record -and -not[string]::IsNullOrEmpty([string](Get-VerificationValue $record 'reason'))){[string](Get-VerificationValue $record 'reason')}else{'creation-unresolved'})
    Write-VerificationStageError 'proposal' 'sandbox' $recordReason $Failure
    if($null -eq $record){
        # 作成済みの可能性があるので未作成へ戻さない。期限到達なら時間超過を優先する（Replay の Resolve-ReplayCreationFailure と同じ）。
        $Result.status=$(if($timedOut){'timed_out'}else{'incomplete'});$Result.stopState='unverified';$Result.failure=@{stage='sandbox';reason='creation-unresolved'}
        return $Result
    }
    $reason=[string](Get-VerificationValue $record 'reason')
    $Result.failure=@{stage='sandbox';reason=$(if([string]::IsNullOrEmpty($reason)){'runtime-failure'}else{$reason})}
    switch($record.creationState){
        'not-created'{$Result.stopState='not-created';$Result.status=$(if($status){$status}else{'blocked'})}
        'created'{
            $Result.sandbox=$record.handle;$Result.stopState=[string]$record.stopState
            $Result.status=$(if($record.stopState -ceq 'stopped'){if($status -and $status -cne 'incomplete'){$status}else{'blocked'}}elseif($timedOut){'timed_out'}else{'incomplete'})
        }
        'unknown'{$Result.stopState='unverified';$Result.status=$(if($timedOut){'timed_out'}else{'incomplete'})}
    }
    $Result
}
function Invoke-VerificationProposal([hashtable]$PreparedRun,[hashtable]$Profile,[hashtable]$Lease) {
    # recheck なら VM・モデルを起動しない。提案では: New-VerificationSandbox proposal → proposal-input を source へ搬入・照合 → 依頼を stdin で Codex へ
    # （出力は quarantine/、transportVerified=null）→ 固定エクスポーターを搬入して python3 で実行（stdout 上限 maxWireBytes、JSON 1行の署名）→ 停止 → Envelope 検査 → accepted・manifest。
    # ready は停止確認後だけ。停止未確認は受信済みでも incomplete（時間超過なら timed_out）。
    if($null -eq $PreparedRun -or $PreparedRun.schemaVersion -ne 3 -or -not$PreparedRun.ContainsKey('runId')){throw 'PreparedRunV3 required'}
    $recheckCount=$(if($PreparedRun.ContainsKey('recheckArtifacts') -and $null -ne $PreparedRun.recheckArtifacts){@($PreparedRun.recheckArtifacts).Count}else{0})
    if($recheckCount -gt 0){return Invoke-VerificationProposalRecheck $PreparedRun}
    $result=New-ProposalResult $PreparedRun 'generated'
    # 全体期限の後に呼ばれたら VM を作らず時間超過の型付き結果を返す（Lease を取れなかった呼出し側からも照合へ渡せるよう、Lease の検査より先に判定する）。
    if(Test-VerificationDeadlineReached ([string]$PreparedRun.deadlineAt) ([string]$PreparedRun.runId)){
        $result.status='timed_out';$result.failure=@{stage='sandbox';reason='deadline-reached'}
        return $result
    }
    try{$handle=New-VerificationSandbox $PreparedRun 'proposal' $Profile $Lease}
    catch{return Complete-VerificationProposalCreationFailure $result $PreparedRun $_.Exception}
    $result.sandbox=$handle;$result.stopState='unverified'
    $problem=$null;$wire=$null;$stage='input';$stopAttempted=$false
    try{
        try{
            $maxOutput=Get-VerificationLimit $PreparedRun 'maxOutputBytes'
            # 1. proposal-input だけを source へ搬入し、所有者調整後のハッシュを基準版の一覧と照合する。
            # 期待hash・重複キー・runId・必須キー（path の重複なし）を確かめた1回の読込みの戻り値だけから ExpectedManifest を作る。
            $baselineManifest=Read-ProposalBaselineManifest $PreparedRun
            $expected=@{files=@(foreach($file in @($baselineManifest.files)){@{path=[string]$file.path;size=[long]$file.size;sha256=[string]$file.sha256}})}
            $setup=New-ProposalBudget $PreparedRun $script:ExportSeconds $maxOutput
            [void](Copy-VerificationSandboxInput $handle ([string]$PreparedRun.proposalInputRoot) $script:SourceDestination $expected $setup)
            [void](Confirm-VerificationSandboxInput $handle $script:SourceDestination $expected $setup)
            # 2. 依頼を stdin で startupArgv の Codex へ渡す。出力（実行イベント・最終応答）は未信頼データとして quarantine/ に置く。
            $stage='agent'
            $requestBytes=$script:Utf8.GetBytes((New-VerificationProposalRequest $PreparedRun))
            $agent=Invoke-VerificationSandboxCommand $handle ([string[]]@($Profile.startupArgv)) $requestBytes $script:SourceDestination @{} (New-ProposalBudget $PreparedRun (Get-VerificationLimit $PreparedRun 'proposalSeconds') $maxOutput) $null
            Write-VerificationNewFile (Join-Path ([string]$PreparedRun.runRoot) 'quarantine/proposal-agent-command.json') (ConvertTo-VerificationCanonicalJson $agent)
            $agentProblem=Get-ProposalCommandProblem $agent 'agent' $false
            if($null -ne $agentProblem){$problem=Select-VerificationProblem $problem $agentProblem.status $agentProblem.stage $agentProblem.reason}
            # 3. 子の終了または時間超過の後に受信へ進む（出力超過で VM を止めた場合と、起動しなかった場合は受信できない）。失敗・時間超過では正常提案を確定しない。
            if($agent.started -and -not$agent.outputExceeded){
                $stage='export'
                $exporter=Initialize-ProposalExporter $PreparedRun
                [void](Copy-VerificationSandboxInput $handle $exporter.root $script:ExporterDestination $exporter.manifest $setup)
                $argv=[string[]]@('python3',"$($script:ExporterDestination)/$($script:ExporterName)",'--run-id',[string]$PreparedRun.runId,'--max-files',[string](Get-VerificationLimit $PreparedRun 'maxProposalFiles'),'--max-file-bytes',[string](Get-VerificationLimit $PreparedRun 'maxFileBytes'),'--max-proposal-bytes',[string](Get-VerificationLimit $PreparedRun 'maxProposalBytes'))
                $export=Invoke-VerificationSandboxCommand $handle $argv $null $script:ExporterDestination @{} (New-ProposalBudget $PreparedRun $script:ExportSeconds (Get-VerificationLimit $PreparedRun 'maxWireBytes')) @{pattern='\A\{.*\}\n?\z';stream='stdout'}
                $exportProblem=Get-ProposalCommandProblem $export 'export' $true
                if($null -ne $exportProblem){$problem=Select-VerificationProblem $problem $exportProblem.status $exportProblem.stage $exportProblem.reason}
                elseif($null -eq $problem){$wire=[IO.File]::ReadAllBytes($export.stdoutPath)}
            }
        }catch{
            $reason=Get-VerificationExceptionValue $_.Exception 'reason' "$stage-error"
            Write-VerificationStageError 'proposal' $stage $reason $_.Exception
            $problem=Select-VerificationProblem $problem (Get-VerificationExceptionValue $_.Exception 'status' 'failed') $stage $reason
        }
        # 4. 停止（受信の後、検査の前）。一覧の同一 id・stopped で確認する。停止後に exec しない。
        $stopAttempted=$true
        try{$stop=Stop-VerificationSandbox $handle (New-VerificationCleanupBudget $PreparedRun 1);$result.stopState=[string]$stop.stopState}
        catch{$result.stopState='unverified';Write-VerificationStageError 'proposal' 'stop' 'stop-unverified' $_.Exception}
    }finally{
        # 途中で呼出しが打ち切られた場合も停止を試みる（結果は返せないが、VM を残さない）。
        if(-not$stopAttempted){try{[void](Stop-VerificationSandbox $handle (New-VerificationCleanupBudget $PreparedRun 1))}catch{Write-VerificationStageError 'proposal' 'stop' 'stop-unverified' $_.Exception}}
    }
    if($result.stopState -cne 'stopped'){
        $result.status=$(if($null -ne $problem -and $problem.status -ceq 'timed_out'){'timed_out'}else{'incomplete'})
        $result.failure=$(if($null -ne $problem){@{stage=$problem.stage;reason=$problem.reason}}else{@{stage='stop';reason='stop-unverified'}})
        return $result
    }
    if($null -ne $problem){
        $result.status=$problem.status;$result.failure=@{stage=$problem.stage;reason=$problem.reason}
        return $result
    }
    # 5. 停止確認後に Envelope を検査し、accepted と manifest を外側で作る。
    $stage='envelope'
    try{
        $checked=Test-VerificationProposalEnvelope $wire $PreparedRun
        $stage='accepted'
        $artifacts=@(Write-VerificationAcceptedFiles $PreparedRun $checked)
        $saved=Save-VerificationProposalManifest $PreparedRun 'generated' $artifacts
    }catch{
        $result.status=Get-VerificationExceptionValue $_.Exception 'status' 'failed'
        $result.failure=@{stage=$stage;reason=(Get-VerificationExceptionValue $_.Exception 'reason' "$stage-error")}
        Write-VerificationStageError 'proposal' $stage $result.failure.reason $_.Exception
        return $result
    }
    $result.summary=$checked.summary
    $result.findings=[object[]]@(foreach($finding in @($checked.findings)){@{description=$finding.description;sourcePaths=[string[]]@($finding.sourcePaths)}})
    $result.artifacts=$saved.artifacts;$result.manifestPath=$saved.manifestPath;$result.manifestHash=$saved.manifestHash;$result.testsManifestHash=$saved.testsManifestHash
    $result.status='ready'
    $result
}

Export-ModuleMember -Function Invoke-VerificationProposal,Test-VerificationProposalEnvelope,Write-VerificationAcceptedFiles
