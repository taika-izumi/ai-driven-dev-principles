# 提案作成（仕様02「提案作成」「提案書式と回収」「ProposalResultV3」）。提案用VMの起動・依頼・固定エクスポーターによる回収・未信頼Envelopeの検査・accepted の生成・停止を行う。
# VM の操作は SbxRuntime の公開操作だけを使う。子の出力（実行イベント・最終応答・Envelope）は未信頼データとして扱い、ホストで import・実行しない。
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'RequestCopy.psm1')                          # 正規化JSON・ハッシュ・新規作成書込・UTC時刻・パス検査を共用する
Import-Module (Join-Path $PSScriptRoot 'SbxRuntime.psm1') -DisableNameChecking      # VM の作成・搬入・実行・停止（Acquire- は仕様02の公開操作名）

$script:Utf8=[Text.UTF8Encoding]::new($false)
$script:StrictUtf8=[Text.UTF8Encoding]::new($false,$true)
# Envelope の構造上の最大の深さ（ルート=1、findings=2、finding=3、sourcePaths=4）。これを超える入れ子は書式外として拒否する。
$script:MaxEnvelopeDepth=4
$script:EnvelopeKeys=@{root=@('schemaVersion','runId','summary','findings','files','truncated');finding=@('description','sourcePaths');file=@('kind','path','contentBase64')}
# 書き込まない制御パスの成分（仕様02 と、原本で予約済みの .verification-*）。大小文字を区別しない。
$script:ProtectedComponents=@('.git','.codex','.claude','.agents','.mcp.json','.verification-tests','.verification-control')
$script:ReservedNames=@('CON','PRN','AUX','NUL','CONIN$','CONOUT$')+@(foreach($n in 1..9){"COM$n";"LPT$n"})+@(foreach($c in @([char]0xB9,[char]0xB2,[char]0xB3)){"COM$c";"LPT$c"})

# ---- 共通補助 ----
function Throw-VerificationProposalFailure([string]$Message,[string]$Status,[string]$Reason) {
    $failure=[InvalidOperationException]::new($Message);$failure.Data['status']=$Status;$failure.Data['reason']=$Reason
    throw $failure
}
function Throw-VerificationEnvelopeRejection([string]$Step,[string]$Message) {
    # 最初の違反で全体を拒否する。Envelope の違反は子の提案の不備なので failed。
    Throw-VerificationProposalFailure "proposal envelope rejected ($Step): $Message" 'failed' "envelope-$Step"
}
function Get-ProposalValue($Object,[string]$Name) {
    # Settings・limits は hashtable と PSCustomObject のどちらでも来うる。
    if($null -eq $Object){return $null}
    if($Object -is [Collections.IDictionary]){if($Object.Contains($Name)){return $Object[$Name]};return $null}
    $property=$Object.PSObject.Properties[$Name]
    if($null -eq $property){return $null}
    $property.Value
}
function Get-ProposalLimit([hashtable]$PreparedRun,[string]$Name) {
    $value=Get-ProposalValue (Get-ProposalValue $PreparedRun.settings 'limits') $Name
    if(-not(($value -is [int]) -or ($value -is [long])) -or $value -le 0){Throw-VerificationProposalFailure "settings.limits.$Name must be a positive integer" 'blocked' 'limits'}
    [long]$value
}
function Get-ProposalBytesHash([byte[]]$Bytes) { [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)) }
function Read-ProposalBaselinePaths([hashtable]$PreparedRun) {
    # replacement の存在確認に使う基準版の一覧。PreparedRun の期待hashと一致する記録だけを使う。
    $path=[string]$PreparedRun.baselineManifestPath
    if([string]::IsNullOrEmpty($path) -or -not[IO.File]::Exists($path) -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ine [string]$PreparedRun.baselineManifestHash){Throw-VerificationProposalFailure 'control/baseline-manifest.json is missing or does not match PreparedRun.baselineManifestHash' 'blocked' 'baseline-manifest'}
    $json=[IO.File]::ReadAllText($path,$script:Utf8)
    if(Test-VerificationJsonDuplicateKeys $json){Throw-VerificationProposalFailure 'baseline manifest has duplicate keys' 'blocked' 'baseline-manifest'}
    $manifest=$json | ConvertFrom-Json -AsHashtable -Depth 10 -DateKind String
    if($manifest -isnot [hashtable] -or $manifest.runId -cne [string]$PreparedRun.runId -or -not$manifest.ContainsKey('files')){Throw-VerificationProposalFailure 'baseline manifest does not belong to this run' 'blocked' 'baseline-manifest'}
    $paths=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach($file in @($manifest.files)){[void]$paths.Add([string]$file.path)}
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
    $maxWire=Get-ProposalLimit $PreparedRun 'maxWireBytes';$maxFiles=Get-ProposalLimit $PreparedRun 'maxProposalFiles'
    $maxFileBytes=Get-ProposalLimit $PreparedRun 'maxFileBytes';$maxProposalBytes=Get-ProposalLimit $PreparedRun 'maxProposalBytes'
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
            if(-not($name -ceq '__init__.py' -or ($name.StartsWith('test_',[StringComparison]::Ordinal) -and $name.EndsWith('.py',[StringComparison]::Ordinal)))){Throw-VerificationEnvelopeRejection 'kind' "test file must be test_*.py or __init__.py: $($file.path)"}
        }else{
            if(-not$name.EndsWith('.py',[StringComparison]::Ordinal)){Throw-VerificationEnvelopeRejection 'kind' "replacement must be a .py file: $($file.path)"}
            if($null -eq $baseline){$baseline=Read-ProposalBaselinePaths $PreparedRun}
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
        files=@(foreach($file in $files){@{kind=$file.kind;path=$file.path;size=[long]$file.bytes.Length;sha256=(Get-ProposalBytesHash $file.bytes);bytes=$file.bytes}})
    }
}

# ---- accepted の生成と manifest ----
function Throw-VerificationAcceptedUnsafe([string]$Message) { Throw-VerificationProposalFailure "accepted rejected: $Message" 'blocked' 'accepted-unsafe' }
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
        if($info.Length -ne $file.bytes.Length -or $hash -cne (Get-ProposalBytesHash $file.bytes)){Throw-VerificationProposalFailure "accepted file does not match the received bytes: $target" 'incomplete' 'accepted-mismatch'}
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
    $tests=[object[]]@(foreach($artifact in @(Get-ProposalSortedArtifacts $Artifacts)){if($artifact.kind -ceq 'test'){@{path=$artifact.path;size=$artifact.size;sha256=$artifact.sha256}}})
    Get-VerificationCanonicalHash -Object $tests
}
function Save-VerificationProposalManifest([hashtable]$PreparedRun,[string]$Origin,[object[]]$Artifacts) {
    $sorted=@(Get-ProposalSortedArtifacts $Artifacts)
    $testsHash=Get-ProposalTestsManifestHash $sorted
    $path=Join-Path ([string]$PreparedRun.controlRoot) 'proposal/manifest.json'
    Write-VerificationNewFile $path (ConvertTo-VerificationCanonicalJson @{schemaVersion=3;runId=[string]$PreparedRun.runId;origin=$Origin;artifacts=[object[]]$sorted;testsManifestHash=$testsHash})
    @{manifestPath=$path;manifestHash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash;testsManifestHash=$testsHash;artifacts=[object[]]$sorted}
}

Export-ModuleMember -Function Test-VerificationProposalEnvelope,Write-VerificationAcceptedFiles
