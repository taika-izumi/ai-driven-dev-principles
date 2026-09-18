$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'TestSupport.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'fixtures/FakeSbxScenario.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../RequestCopy.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../SbxRuntime.psm1') -Force -DisableNameChecking   # Acquire- は仕様02の公開操作名（未承認動詞の警告を抑止）
Import-Module (Join-Path $PSScriptRoot '../Proposal.psm1') -Force
# 提案（仕様02）の VM なし試験。Envelope の検査は byte 配列を直接渡し、VM を要する経路（ready・停止未確認・quarantine・時間超過・起動失敗）だけ偽sbxを使う。
# 実 Codex・実 VM・実デーモンは起動しない。proposal-export.py はホストで実行しない（VM 内でだけ動く固定エクスポーター）。偽sbxの成功を実機の実証に数えない。
# ケース領域は短い名前にする（Windows の MAX_PATH。Issue-0146）。
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$base=Join-Path $repo '.tmp/verification-tests'
$utf8=[Text.UTF8Encoding]::new($false)
$digest=Get-FakeSbxTemplateDigest
$evidenceTemplate=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'fixtures/activation-evidence.json'),$utf8)
$proposalModule=Get-Module Proposal
$count=0
$allCases=[Collections.Generic.List[hashtable]]::new()
function Get-Hash([string]$Path){(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash}
function Get-BytesHash([byte[]]$Bytes){[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes))}
function Write-Text([string]$Path,[string]$Text){[void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path));[IO.File]::WriteAllText($Path,$Text,$utf8)}
function New-ProposalProfile([hashtable]$Ctx){
    # 試験用の proposal profile（SbxRuntimeV3.Tests.ps1 の New-Profile の proposal 部分と同じ組み立て）。evidence は fixture の雛形へ profileHash と証拠を埋める。
    $profile=@{
        schemaVersion=3;role='proposal';sbxVersion='v0.42.1';templateDigest=$digest;agent='codex';model='unit-model'
        startupArgv=[string[]]@('codex','exec','--json');executableInVm='/usr/local/bin/codex'
        policyExpectation=@{networkPolicy='allow auth.openai.com:443 chatgpt.com:443 only'};mountExpectation=@{workspace='none';shareSkills=$false;sshAgentForwarding=$false}
        scope='synthetic-pilot';acceptedLimitations=@('clipboard-text-write-possible','pid-count-unbounded','daemon-disconnect-unverified')
        stdlibModulesPath='stdlib-modules.txt';stdlibModulesHash=(Get-Hash (Join-Path $Ctx.prof 'stdlib-modules.txt'))
        activationEvidencePath=$null;activationEvidenceHash=$null
    }
    $subset=@{};foreach($key in $profile.Keys){if($key -notin @('activationEvidencePath','activationEvidenceHash')){$subset[$key]=$profile[$key]}}
    $json=$evidenceTemplate.Replace('{{profileHash}}',(Get-VerificationCanonicalHash $subset)).Replace('{{evidencePath}}','evidence-note.txt').Replace('{{evidenceHash}}',(Get-Hash (Join-Path $Ctx.prof 'evidence-note.txt')))
    $evidence=$json | ConvertFrom-Json -AsHashtable -Depth 10 -DateKind String
    $evidence.Remove('_comment')
    Write-Text (Join-Path $Ctx.prof 'ev-proposal.json') (ConvertTo-VerificationCanonicalJson $evidence)
    $profile.activationEvidencePath='ev-proposal.json';$profile.activationEvidenceHash=Get-Hash (Join-Path $Ctx.prof 'ev-proposal.json')
    $profile
}
# 停止猶予の既定は30秒（計画の初期値）。5秒では停止後の世代照会が偽sbxの所要（1呼び出し約1.2秒）で cleanupDeadlineAt を越え、ready のケースが停止未確認になった（実測。ReplayV3 と同じ）。
# 停止未確認を意図して作るケース12は -CleanupSeconds 5 を明示して従来の値を保つ。
function New-Ctx([hashtable]$Limits=@{},[int]$CleanupSeconds=30,[int]$DeadlineIn=900){
    # PreparedRunV3 と同じ形の文脈。baseline と proposal-input は同じファイル群（RequestCopy のファイル単位コピーと同じ）。
    $root=Join-Path $base ('p4'+[guid]::NewGuid().ToString('N').Substring(0,6))
    $case=New-FakeSbxCase $root
    $runId=[guid]::NewGuid().ToString()
    $runRoot=Join-Path $root 'run';$control=Join-Path $runRoot 'control';$prof=Join-Path $root 'prof';$source=Join-Path $root 'src'
    foreach($dir in @((Join-Path $control 'runtime'),(Join-Path $control 'proposal'),(Join-Path $runRoot 'quarantine'),(Join-Path $runRoot 'accepted'),$prof,$source)){[void][IO.Directory]::CreateDirectory($dir)}
    $baselineFiles=[ordered]@{'README.md'="# fixture`n";'pkg/__init__.py'='';'pkg/mod.py'="def add(a, b):`n    return a - b`n"}
    $files=@(foreach($rel in $baselineFiles.Keys){
        foreach($tree in @('baseline','proposal-input')){Write-Text (Join-Path $runRoot "$tree/$rel") $baselineFiles[$rel]}
        $path=Join-Path $runRoot "baseline/$rel";@{path=$rel;size=([IO.FileInfo]::new($path)).Length;sha256=(Get-Hash $path)}
    })
    $baselineManifestPath=Join-Path $control 'baseline-manifest.json'
    Write-VerificationNewFile $baselineManifestPath (ConvertTo-VerificationCanonicalJson @{schemaVersion=3;runId=$runId;files=$files})
    Write-Text (Join-Path $prof 'evidence-note.txt') "fixture evidence note`n"
    Write-Text (Join-Path $prof 'stdlib-modules.txt') "os`nsys`nunittest`n"
    Write-Text (Join-Path $prof 'replay.json') '{}';Write-Text (Join-Path $prof 'proposal.json') '{}'
    $sourceManifestPath=Join-Path $control 'source-manifest.json'
    Write-VerificationNewFile $sourceManifestPath (ConvertTo-VerificationCanonicalJson @{schemaVersion=3;files=@(@{path='tracked.txt';size=8;sha256=('A'*64)})})
    $pilot=@{schemaVersion=3;inputId='pilot-fixture';scope='synthetic-pilot';sourceRoot=$source;sourceManifestHash=(Get-Hash $sourceManifestPath);approvalReference=@{path='docs/records/reviews/fixture.md';version='0000000'}}
    $pilotPath=Join-Path $control 'pilot-input.json'
    Write-VerificationNewFile $pilotPath (ConvertTo-VerificationCanonicalJson $pilot)
    $limitValues=@{totalSeconds=1800;proposalSeconds=600;replaySeconds=120;cleanupSeconds=$CleanupSeconds;cpus=2;memoryMiB=2048;maxProposalFiles=100;maxFileBytes=1MB;maxProposalBytes=8MB;maxWireBytes=16MB;maxOutputBytes=16MB}
    foreach($key in $Limits.Keys){$limitValues[$key]=$Limits[$key]}
    $settings=@{
        schemaVersion=3;sbxPath=$case.sbxPath;pwshPath=(Get-Command pwsh).Source;runsRoot=(Join-Path $root 'runs');model='unit-model'
        proposalProfilePath=(Join-Path $prof 'proposal.json');replayProfilePath=(Join-Path $prof 'replay.json');pilotInputPath=$pilotPath;limits=$limitValues
    }
    $now=[DateTime]::UtcNow
    $prepared=@{
        schemaVersion=3;runId=$runId;sourceRoot=$source;runRoot=$runRoot;baselineRoot=(Join-Path $runRoot 'baseline');proposalInputRoot=(Join-Path $runRoot 'proposal-input');acceptedRoot=(Join-Path $runRoot 'accepted');controlRoot=$control
        request=@{schemaVersion=3;caller='codex';sourceRoot=$source;objective='pkg.mod.add の不具合を再現し修正候補を示す';acceptanceCriteria=@('add(1, 2) が 3 を返す','既存の公開関数名を変えない');extraInputPaths=@()}
        settings=$settings
        sourceManifestPath=$sourceManifestPath;sourceManifestHash=(Get-Hash $sourceManifestPath);baselineManifestPath=$baselineManifestPath;baselineManifestHash=(Get-Hash $baselineManifestPath)
        recheckManifestPath=$null;recheckManifestHash=$null;recheckArtifacts=@()
        startedAt=$now.ToString('o');deadlineAt=$now.AddSeconds($DeadlineIn).ToString('o');cleanupSeconds=$CleanupSeconds
        pilotInputId='pilot-fixture';pilotInputPath=$pilotPath;pilotInputHash=(Get-Hash $pilotPath)
    }
    $ctx=@{case=$case;root=$root;runId=$runId;runRoot=$runRoot;controlRoot=$control;prof=$prof;prepared=$prepared;baselineFiles=$files;name=('iv-'+$runId.Substring(0,8)+'-proposal')}
    $ctx.profile=New-ProposalProfile $ctx
    $script:allCases.Add($ctx)
    $ctx
}
function New-FileEntry([string]$Kind,[string]$Path,[string]$Text){[ordered]@{kind=$Kind;path=$Path;contentBase64=[Convert]::ToBase64String($utf8.GetBytes($Text))}}
$testText="import unittest`n`nfrom pkg.mod import add`n`n`nclass AddTest(unittest.TestCase):`n    def test_add(self):`n        self.assertEqual(add(1, 2), 3)`n"
$replacementText="def add(a, b):`n    return a + b`n"
function New-Envelope([hashtable]$Ctx){
    # proposal-export.py の出力と同じ形（キー順・truncated を含む）。
    [ordered]@{
        schemaVersion=3;runId=$Ctx.runId;summary='add が引き算になっている';findings=@([ordered]@{description='pkg/mod.py の add が a - b を返す';sourcePaths=@('pkg/mod.py')})
        files=@((New-FileEntry 'test' 'test_add.py' $testText),(New-FileEntry 'test' '__init__.py' ''),(New-FileEntry 'replacement' 'pkg/mod.py' $replacementText));truncated=$false
    }
}
function ConvertTo-WireText($Envelope){ConvertTo-Json -InputObject $Envelope -Depth 10 -Compress}
function ConvertTo-Wire($Envelope){$utf8.GetBytes((ConvertTo-WireText $Envelope)+"`n")}
function Get-EnvelopeFailure([hashtable]$Ctx,[byte[]]$Wire){
    try{[void](Test-VerificationProposalEnvelope $Wire $Ctx.prepared)}catch{return $_.Exception}
    $null
}
function Assert-Rejected([hashtable]$Ctx,[byte[]]$Wire,[string]$Reason,[string]$Label){
    $failure=Get-EnvelopeFailure $Ctx $Wire
    Assert-True ($null -ne $failure) "${Label}: 拒否される"
    Assert-True ($failure.Data['reason'] -ceq $Reason -and $failure.Data['status'] -ceq 'failed') "${Label}: 理由 $Reason（実際 $($failure.Data['reason']): $($failure.Message)）"
}
function Assert-EditRejected([hashtable]$Ctx,[scriptblock]$Edit,[string]$Reason,[string]$Label){
    $e=New-Envelope $Ctx
    & $Edit $e
    Assert-Rejected $Ctx (ConvertTo-Wire $e) $Reason $Label
}
function Assert-TextRejected([hashtable]$Ctx,[string]$Find,[string]$Replace,[string]$Reason,[string]$Label){
    $text=ConvertTo-WireText (New-Envelope $Ctx)
    Assert-True ($text.Contains($Find)) "${Label}: 置換元が wire にある"
    Assert-Rejected $Ctx ($utf8.GetBytes($text.Replace($Find,$Replace)+"`n")) $Reason $Label
}
function Get-Failure([scriptblock]$Action){try{& $Action | Out-Null}catch{return $_.Exception};throw "ASSERT: expected an exception (line $($MyInvocation.ScriptLineNumber))"}

try{
# 1. 正常 Envelope: 検査済み一覧（kind・path・size・sha256・bytes）と summary/findings を外側で組み直して返す。proposal.schema.json にも適合する。
$ctx=New-Ctx
$wire=ConvertTo-Wire (New-Envelope $ctx)
$checked=Test-VerificationProposalEnvelope $wire $ctx.prepared
Assert-Equal (@($checked.Keys | Sort-Object) -join ',') 'files,findings,runId,summary' '正常: 戻りの項目'
Assert-True ($checked.runId -ceq $ctx.runId -and $checked.summary -ceq 'add が引き算になっている' -and $checked.findings.Count -eq 1 -and $checked.findings[0].sourcePaths[0] -ceq 'pkg/mod.py') '正常: runId・summary・findings'
Assert-Equal (@($checked.files | ForEach-Object {"$($_.kind):$($_.path)"}) -join ',') 'test:test_add.py,test:__init__.py,replacement:pkg/mod.py' '正常: files の kind と path'
$testFile=@($checked.files)[0]
Assert-True ($testFile.sha256 -ceq (Get-BytesHash $utf8.GetBytes($testText)) -and $testFile.size -eq $utf8.GetByteCount($testText) -and $utf8.GetString($testFile.bytes) -ceq $testText) '正常: 復号後の内容・size・sha256 を外側で計算'
Assert-True (@($checked.files)[1].size -eq 0) '正常: 空の __init__.py'
Assert-True (Test-Json -Json (ConvertTo-WireText (New-Envelope $ctx)) -SchemaFile (Join-Path $PSScriptRoot '../proposal.schema.json')) '正常: proposal.schema.json に適合'
$withoutTruncated=New-Envelope $ctx;$withoutTruncated.Remove('truncated')
Assert-True ((Test-VerificationProposalEnvelope (ConvertTo-Wire $withoutTruncated) $ctx.prepared).files.Count -eq 3) '正常: truncated は省略可'
$reproOnly=New-Envelope $ctx;$reproOnly.files=@($reproOnly.files[0])
Assert-True (@((Test-VerificationProposalEnvelope (ConvertTo-Wire $reproOnly) $ctx.prepared).files).Count -eq 1) '正常: replacement 0件は再現のみとして受ける'
$count++

# 2. wire 容量・途中切断・1行でない・非 UTF-8: JSON として読む前に拒否。
$small=New-Ctx -Limits @{maxWireBytes=200}
$big=ConvertTo-Wire (New-Envelope $small)
Assert-True ($big.Length -gt 200) '過大wire: 前提（wire が上限を超える）'
Assert-Rejected $small $big 'envelope-wire' '過大wire'
Assert-Rejected $small ([byte[]]@()) 'envelope-wire' '空の wire'
Assert-Rejected $small ([byte[]]$big[0..200]) 'envelope-wire' '過大wire と途中切断が重なれば wire 容量が先'
Assert-Rejected $ctx ([byte[]]$wire[0..([int]($wire.Length/2))]) 'envelope-json' '途中切断（不完全JSON）'
Assert-Rejected $ctx ([byte[]]$wire[0..($wire.Length-3)]) 'envelope-json' '途中切断（末尾の閉じ括弧なし）'
Assert-TextRejected $ctx ',"runId"' ",`n`"runId`"" 'envelope-json' '複数行'
Assert-Rejected $ctx ($utf8.GetBytes((ConvertTo-WireText (New-Envelope $ctx))+(ConvertTo-WireText (New-Envelope $ctx)))) 'envelope-json' 'JSON 値が2つ'
Assert-Rejected $ctx ([byte[]]@(0xFF)+$wire) 'envelope-json' '非 UTF-8'
$count++

# 3. 重複キー・深さ・未知キー・型・truncated・runId・件数（この順）。
Assert-TextRejected $ctx '{"schemaVersion":3,' '{"schemaVersion":3,"schemaVersion":3,' 'envelope-duplicate-key' '重複キー（ルート）'
Assert-TextRejected $ctx '"kind":"test","path":"test_add.py"' '"kind":"test","kind":"test","path":"test_add.py"' 'envelope-duplicate-key' '重複キー（files の要素）'
Assert-EditRejected $ctx {param($e) $e.findings[0].sourcePaths=@(,@('pkg/mod.py'))} 'envelope-depth' '深さ超過'
Assert-TextRejected $ctx '"summary":"add が引き算になっている"' ('"summary":'+('['*10000)+(']'*10000)) 'envelope-depth' '深さ超過（1万段。JSON 解析の既定上限 64 を超えても json ではなく depth）'
Assert-TextRejected $ctx '"summary":"add が引き算になっている"' ('"summary":'+('['*10000)+'{"a":1,"a":2}'+(']'*10000)) 'envelope-duplicate-key' '重複キー（1万段の奥。深さより先）'
Assert-EditRejected $ctx {param($e) $e.extra='x'} 'envelope-unknown-key' '未知キー（ルート）'
Assert-EditRejected $ctx {param($e) $e.files[0].mode='0755'} 'envelope-unknown-key' '未知キー（files の要素。実行属性の申告）'
Assert-EditRejected $ctx {param($e) $e.findings[0].severity='high'} 'envelope-unknown-key' '未知キー（findings の要素）'
Assert-EditRejected $ctx {param($e) $e.summary=5} 'envelope-type' '型（summary が数値）'
Assert-EditRejected $ctx {param($e) $e.Remove('summary')} 'envelope-type' '型（summary 欠落）'
Assert-EditRejected $ctx {param($e) $e.files[0].kind='delete'} 'envelope-type' '型（kind が test/replacement 以外。削除の提案）'
Assert-EditRejected $ctx {param($e) $e.files[0].path=7} 'envelope-type' '型（path が数値）'
Assert-EditRejected $ctx {param($e) $e.findings='none'} 'envelope-type' '型（findings が配列でない）'
Assert-TextRejected $ctx '{"schemaVersion":3,' '{"schemaVersion":3.0,' 'envelope-type' '型（schemaVersion が 3.0）'
Assert-Rejected $ctx ($utf8.GetBytes("[1,2]`n")) 'envelope-type' '型（ルートが配列）'
Assert-TextRejected $ctx '"summary":"' '"summary":"\udc00' 'envelope-type' '型（summary に対のないサロゲート）'
Assert-EditRejected $ctx {param($e) $e.truncated=$true} 'envelope-truncated' 'エクスポーターの切り詰め印'
Assert-EditRejected $ctx {param($e) $e.runId=[guid]::NewGuid().ToString()} 'envelope-run-id' '架空 runId'
$fewFiles=New-Ctx -Limits @{maxProposalFiles=2}
Assert-Rejected $fewFiles (ConvertTo-Wire (New-Envelope $fewFiles)) 'envelope-file-count' '件数（maxProposalFiles 超過）'
$count++

# 4. path 規則: 絶対・ドライブ・UNC・空成分・.・..・バックスラッシュ・コロン（別ストリーム＝リンク相当の別名）・NUL・末尾空白/ドット・予約名・保護パス・大小文字無視の重複・親子衝突。
$badPaths=[ordered]@{
    '..'='../test_add.py';'途中の ..'='unit/../../test_add.py';'.'='./test_add.py';'絶対'='/etc/test_add.py';'UNC'='//server/share/test_add.py';'ドライブ'='C:/x/test_add.py'
    'バックスラッシュ'='unit\test_add.py';'コロン（別データストリーム）'='test_add.py:hidden';'空成分'='unit//test_add.py';'末尾スラッシュ'='unit/';'末尾ドット'='unit./test_add.py';'末尾空白'='unit /test_add.py'
    '予約名 CON'='con/test_add.py';'予約名 AUX.py'='aux.py';'予約名 COM1'='COM1.txt/test_add.py';'予約名 LPT9'='lpt9/test_add.py';'予約名 CONIN$'='CONIN$/test_add.py'
    '.git 配下'='.git/hooks/test_add.py';'.codex 配下（大小文字）'='.CODEX/test_add.py';'.claude 配下'='.claude/test_add.py';'.agents 配下'='.agents/test_add.py';'.mcp.json'='.mcp.json/test_add.py'
    '予約制御パス'='.verification-tests/test_add.py';'制御文字'="unit`t/test_add.py";'Windows 禁止文字'='unit*/test_add.py';'空'=''
}
foreach($label in $badPaths.Keys){$value=$badPaths[$label];Assert-EditRejected $ctx {param($e) $e.files[0].path=$value} 'envelope-path' "path: $label"}
Assert-EditRejected $ctx {param($e) $e.files[0].path="test_add`0.py"} 'envelope-path' 'path: NUL'
Assert-TextRejected $ctx '"path":"test_add.py"' '"path":"test_\ud800.py"' 'envelope-path' 'path: 対のないサロゲート（UTF-8 にならない）'
Assert-EditRejected $ctx {param($e) $e.files=@($e.files)+@(New-FileEntry 'test' 'TEST_ADD.py' $testText)} 'envelope-path' '大小文字を無視した重複'
Assert-EditRejected $ctx {param($e) $e.files=@($e.files)+@((New-FileEntry 'test' 'Unit/test_a.py' $testText),(New-FileEntry 'test' 'unit/test_b.py' $testText))} 'envelope-path' 'ディレクトリ名の大小文字違い'
Assert-EditRejected $ctx {param($e) $e.files=@($e.files)+@(New-FileEntry 'test' 'test_add.py/test_b.py' $testText)} 'envelope-path' '親子衝突（ファイルの下にファイル）'
Assert-EditRejected $ctx {param($e) $e.files=@($e.files)+@(New-FileEntry 'replacement' 'pkg/mod.py' $replacementText)} 'envelope-path' '同一パスの重複'
$count++

# 5. kind: test は tests/ 直下の test_*.py / __init__.py（接頭辞なし・サブディレクトリなし）、replacement は基準版にある .py（サブディレクトリ可）。test 0件は拒否。
Assert-EditRejected $ctx {param($e) $e.files[0].path='tests/test_add.py'} 'envelope-kind' 'test に tests/ 接頭辞'
Assert-EditRejected $ctx {param($e) $e.files=@($e.files)+@((New-FileEntry 'test' 'unit/test_more.py' $testText),(New-FileEntry 'test' 'unit/__init__.py' ''))} 'envelope-kind' 'サブディレクトリ付きの test は拒否'
Assert-EditRejected $ctx {param($e) $e.files[1].path='unit/__init__.py'} 'envelope-kind' 'サブディレクトリ付きの __init__.py は拒否'
# 基準版の一覧は PreparedRun の期待hash・重複キー・runId・必須キーを確かめた1回の読込みだけを使う（改変・形式違反は blocked で、Envelope の拒否理由にしない）。
$tampered=New-Ctx
$manifestText=[IO.File]::ReadAllText($tampered.prepared.baselineManifestPath,$utf8)
[IO.File]::WriteAllText($tampered.prepared.baselineManifestPath,$manifestText.Replace('pkg/mod.py','pkg/other.py'),$utf8)
$failure=Get-EnvelopeFailure $tampered (ConvertTo-Wire (New-Envelope $tampered))
Assert-True ($null -ne $failure -and $failure.Data['reason'] -ceq 'baseline-manifest' -and $failure.Data['status'] -ceq 'blocked' -and $failure.Message -like '*expected hash*') "baseline manifest の改変（hash 不一致）: blocked（$($failure.Message)）"
foreach($variant in @(
    @{label='重複キー';edit={param($t) $t.Replace('{"files":','{"files":[],"files":')};message='*duplicate keys*'},
    @{label='path の重複';edit={param($t) $t.Replace('{"path":"README.md"','{"path":"pkg/mod.py"')};message='*lists a path twice*'},
    @{label='別 runId';edit={param($t) [regex]::Replace($t,'"runId":"[^"]+"','"runId":"00000000-0000-0000-0000-000000000000"')};message='*does not belong to this run*'},
    @{label='sha256 欠落';edit={param($t) [regex]::Replace($t,',"sha256":"[0-9A-F]{64}"','',[Text.RegularExpressions.RegexOptions]::None)};message='*need path, size and sha256*'}
)){
    $broken=New-Ctx
    $text=[IO.File]::ReadAllText($broken.prepared.baselineManifestPath,$utf8)
    $edited=& $variant.edit $text
    Assert-True ($edited -cne $text) "baseline manifest（$($variant.label)）: 前提（内容が変わる）"
    [IO.File]::WriteAllText($broken.prepared.baselineManifestPath,$edited,$utf8)
    $broken.prepared.baselineManifestHash=Get-Hash $broken.prepared.baselineManifestPath   # 期待hashは一致させ、hash 以外の検査で拒否されることを確かめる
    $failure=Get-EnvelopeFailure $broken (ConvertTo-Wire (New-Envelope $broken))
    Assert-True ($null -ne $failure -and $failure.Data['reason'] -ceq 'baseline-manifest' -and $failure.Data['status'] -ceq 'blocked' -and $failure.Message -like $variant.message) "baseline manifest（$($variant.label)）: blocked（$($failure.Message)）"
}
Assert-EditRejected $ctx {param($e) $e.files[0].path='helper.py'} 'envelope-kind' 'test が test_*.py でない'
Assert-EditRejected $ctx {param($e) $e.files[0].path='Test_add.py'} 'envelope-kind' 'test 名の大小文字違い（Linux の unittest は拾わない）'
Assert-EditRejected $ctx {param($e) $e.files[2].path='pkg/missing.py'} 'envelope-kind' 'replacement が baseline に無い'
Assert-EditRejected $ctx {param($e) $e.files[2].path='README.md'} 'envelope-kind' 'replacement が非 .py（baseline にはある）'
Assert-EditRejected $ctx {param($e) $e.files[2].path='PKG/mod.py'} 'envelope-kind' 'replacement の大小文字違い（baseline と序数一致しない）'
Assert-EditRejected $ctx {param($e) $e.files=@($e.files[2])} 'envelope-no-test' 'test 0件'
Assert-EditRejected $ctx {param($e) $e.files=@()} 'envelope-no-test' '提案なし'
$count++

# 6. base64 の正規性・復号後サイズ・UTF-8 テキスト。
foreach($pair in @(@('パディングなし','YQ'),@('非正規のパディングビット','YR=='),@('空白','YQ= '),@('URL 用アルファベット','-_8='),@('パディング過多','Y==='))){
    $value=$pair[1];Assert-EditRejected $ctx {param($e) $e.files[0].contentBase64=$value} 'envelope-base64' "base64: $($pair[0])"
}
$tinyFile=New-Ctx -Limits @{maxFileBytes=40}
Assert-Rejected $tinyFile (ConvertTo-Wire (New-Envelope $tinyFile)) 'envelope-size' '復号後超過（1ファイル）'
$tinyTotal=New-Ctx -Limits @{maxProposalBytes=($utf8.GetByteCount($testText)+10)}
Assert-Rejected $tinyTotal (ConvertTo-Wire (New-Envelope $tinyTotal)) 'envelope-size' '復号後超過（合計）'
Assert-EditRejected $ctx {param($e) $e.files[0].contentBase64=[Convert]::ToBase64String([byte[]]@(0x70,0xFF,0xFE))} 'envelope-text' '非 UTF-8 の内容'
Assert-EditRejected $ctx {param($e) $e.files[0].contentBase64=[Convert]::ToBase64String([byte[]]@(0x61,0x00,0x62))} 'envelope-text' 'NUL を含む内容'
$count++

# 7. 最初の違反で全体を拒否する（後段の違反を同時に持つ wire は前段の理由になる）。
Assert-EditRejected $ctx {param($e) $e.extra='x';$e.runId='other'} 'envelope-unknown-key' '順序: 未知キー → runId'
Assert-EditRejected $ctx {param($e) $e.summary=1;$e.truncated=$true} 'envelope-type' '順序: 型 → truncated'
Assert-EditRejected $ctx {param($e) $e.truncated=$true;$e.runId='other'} 'envelope-truncated' '順序: truncated → runId'
Assert-EditRejected $ctx {param($e) $e.runId='other';$e.files[0].path='../x.py'} 'envelope-run-id' '順序: runId → path'
Assert-EditRejected $ctx {param($e) $e.files[0].path='../x.py';$e.files[2].path='README.md'} 'envelope-path' '順序: path → kind'
Assert-EditRejected $ctx {param($e) $e.files=@($e.files[2]);$e.files[0].contentBase64='YQ'} 'envelope-no-test' '順序: test 0件 → base64'
Assert-EditRejected $ctx {param($e) $e.files[0].contentBase64='YQ';$e.files[2].contentBase64=[Convert]::ToBase64String([byte[]]@(0xFF))} 'envelope-base64' '順序: base64 → UTF-8'
Assert-Rejected $tinyFile ($utf8.GetBytes((ConvertTo-WireText (New-Envelope $tinyFile)).Replace('"summary":','"summary":"x","summary":')+"`n")) 'envelope-duplicate-key' '順序: 重複キー → 復号後サイズ'
Assert-TextRejected $ctx '{"schemaVersion":3,' '{"schemaVersion":3,"schemaVersion":3,"extra":[[[[1]]]],' 'envelope-duplicate-key' '順序: 重複キー → 深さ → 未知キー'
$count++

# 8. accepted の生成: 検査済み一覧だけから CreateNew の通常ファイルを作り、size・sha256 を実体から計算する。祖先・自身のリンクや既存物は拒否し、リンク先へ書かない。
$ctx=New-Ctx
$checked=Test-VerificationProposalEnvelope (ConvertTo-Wire (New-Envelope $ctx)) $ctx.prepared
$artifacts=@(Write-VerificationAcceptedFiles $ctx.prepared $checked)
Assert-Equal (@($artifacts | ForEach-Object {"$($_.kind):$($_.path)"}) -join ',') 'replacement:replacements/pkg/mod.py,test:tests/__init__.py,test:tests/test_add.py' 'accepted: accepted 相対パスの序数順'
foreach($artifact in $artifacts){
    $path=Join-Path $ctx.prepared.acceptedRoot $artifact.path
    Assert-True ([IO.File]::Exists($path) -and $artifact.sha256 -ceq (Get-Hash $path) -and $artifact.size -eq ([IO.FileInfo]::new($path)).Length -and @($artifact.Keys).Count -eq 4) "accepted: $($artifact.path) の size・sha256 は実体と一致"
}
Assert-Equal ([IO.File]::ReadAllText((Join-Path $ctx.prepared.acceptedRoot 'tests/test_add.py'),$utf8)) $testText 'accepted: 受信したバイト列のまま'
$again=Get-Failure {Write-VerificationAcceptedFiles $ctx.prepared $checked}
Assert-True ($again.Data['reason'] -ceq 'accepted-unsafe' -and $again.Message -like '*not empty*') "accepted: 既存物があれば拒否（$($again.Message)）"
# リンク相当: accepted 自身がジャンクション（リンク先は run の外）。
$ctx=New-Ctx
$checked=Test-VerificationProposalEnvelope (ConvertTo-Wire (New-Envelope $ctx)) $ctx.prepared
$outside=Join-Path $ctx.root 'outside';[void][IO.Directory]::CreateDirectory($outside)
$linked=Join-Path $ctx.runRoot 'accepted-link'
New-Item -ItemType Junction -Path $linked -Target $outside | Out-Null
$ctx.prepared.acceptedRoot=$linked
$failure=Get-Failure {Write-VerificationAcceptedFiles $ctx.prepared $checked}
Assert-True ($failure.Data['reason'] -ceq 'accepted-unsafe' -and $failure.Message -like '*reparse point*') "リンク相当: accepted 自身のリンクを拒否（$($failure.Message)）"
Assert-Equal ([IO.Directory]::GetFileSystemEntries($outside).Length) 0 'リンク相当: リンク先に何も書かない'
# リンク相当: accepted の祖先がジャンクション。
$linkedRun=Join-Path $ctx.root 'run-link'
New-Item -ItemType Junction -Path $linkedRun -Target $ctx.runRoot | Out-Null
$ctx.prepared.acceptedRoot=Join-Path $linkedRun 'accepted'
$failure=Get-Failure {Write-VerificationAcceptedFiles $ctx.prepared $checked}
Assert-True ($failure.Data['reason'] -ceq 'accepted-unsafe' -and $failure.Message -like '*reparse point*') "リンク相当: accepted の祖先のリンクを拒否（$($failure.Message)）"
Assert-Equal ([IO.Directory]::GetFileSystemEntries((Join-Path $ctx.runRoot 'accepted')).Length) 0 'リンク相当: 祖先のリンク経由でも書かない'
# リンク相当: accepted 内に子ディレクトリ名のジャンクションが既にある（空でないとして拒否し、リンク先へ書かない）。
$ctx.prepared.acceptedRoot=Join-Path $ctx.runRoot 'accepted'
New-Item -ItemType Junction -Path (Join-Path $ctx.prepared.acceptedRoot 'tests') -Target $outside | Out-Null
$failure=Get-Failure {Write-VerificationAcceptedFiles $ctx.prepared $checked}
Assert-True ($failure.Data['reason'] -ceq 'accepted-unsafe') "リンク相当: accepted/tests のリンクを拒否（$($failure.Message)）"
Assert-Equal ([IO.Directory]::GetFileSystemEntries($outside).Length) 0 'リンク相当: accepted/tests のリンク先に書かない'
$count++

# 9. recheck: VM・モデルを起動せず（sbx 呼び出し0回、profile・Lease なし）、前回の固定テストから ready。origin=reused-tests・sandbox=null・stopState=not-created、
#    artifacts は前回 hash のまま、control/proposal/manifest.json を新規作成。追加・欠落・改変は拒否。
function New-RecheckCtx(){
    $ctx=New-Ctx
    $path=Join-Path $ctx.prepared.acceptedRoot 'tests/test_add.py';Write-Text $path $testText
    $artifact=@{kind='test';path='tests/test_add.py';size=([IO.FileInfo]::new($path)).Length;sha256=(Get-Hash $path);previousRunId=[guid]::NewGuid().ToString()}
    $manifestPath=Join-Path $ctx.controlRoot 'recheck-manifest.json'
    Write-VerificationNewFile $manifestPath (ConvertTo-VerificationCanonicalJson @{schemaVersion=3;runId=$ctx.runId;previousRunId=$artifact.previousRunId;previousResultPath='C:\fixture\result.json';previousResultHash=('A'*64);tests=@($artifact)})
    $ctx.prepared.recheckArtifacts=@($artifact);$ctx.prepared.recheckManifestPath=$manifestPath;$ctx.prepared.recheckManifestHash=Get-Hash $manifestPath
    $ctx.artifact=$artifact
    $ctx
}
$ctx=New-RecheckCtx
$result=Invoke-VerificationProposal $ctx.prepared $null $null
Assert-Equal (@($result.Keys | Sort-Object) -join ',') 'artifacts,failure,findings,manifestHash,manifestPath,origin,runId,sandbox,schemaVersion,status,stopState,summary,testsManifestHash' 'ProposalResultV3: 項目'
Assert-True ($result.status -ceq 'ready' -and $result.origin -ceq 'reused-tests' -and $null -eq $result.sandbox -and $result.stopState -ceq 'not-created' -and $null -eq $result.failure) "recheck: ready・reused-tests・sandbox=null・not-created（$($result.status) $(ConvertTo-VerificationCanonicalJson $result.failure)）"
Assert-True ($null -eq $result.summary -and $null -eq $result.findings) 'recheck: 生成した提案を装わない（summary・findings なし）'
Assert-Equal @(Read-FakeSbxCalls $ctx.case).Count 0 'recheck: sbx 呼び出し0回（VM・モデルを起動しない）'
Assert-True (@($result.artifacts).Count -eq 1 -and $result.artifacts[0].path -ceq 'tests/test_add.py' -and $result.artifacts[0].sha256 -ceq $ctx.artifact.sha256 -and $result.artifacts[0].size -eq $ctx.artifact.size -and $result.artifacts[0].kind -ceq 'test') 'recheck: artifacts は前回 hash のまま'
Assert-True ($result.manifestPath -ceq (Join-Path $ctx.controlRoot 'proposal/manifest.json') -and $result.manifestHash -ceq (Get-Hash $result.manifestPath)) 'recheck: control/proposal/manifest.json を作り manifestHash を返す'
$expectedTestsHash=Get-VerificationCanonicalHash -Object ([object[]]@(@{path='tests/test_add.py';size=$ctx.artifact.size;sha256=$ctx.artifact.sha256}))
Assert-Equal $result.testsManifestHash $expectedTestsHash 'recheck: testsManifestHash（相対パス・サイズ・SHA256 のパス順の正規化）'
$manifest=Get-Content -LiteralPath $result.manifestPath -Raw | ConvertFrom-Json -AsHashtable
Assert-True ($manifest.origin -ceq 'reused-tests' -and $manifest.runId -ceq $ctx.runId -and $manifest.testsManifestHash -ceq $expectedTestsHash -and @($manifest.artifacts).Count -eq 1) 'recheck: manifest の内容'
$again=Invoke-VerificationProposal $ctx.prepared $null $null
Assert-True ($again.status -ceq 'blocked' -and $null -eq $again.manifestPath) 'recheck: manifest が既にあれば上書きしない（CreateNew）'
foreach($variant in @('changed','added','missing')){
    $ctx=New-RecheckCtx
    switch($variant){
        'changed'{Write-Text (Join-Path $ctx.prepared.acceptedRoot 'tests/test_add.py') ($testText+"# edited`n")}
        'added'{Write-Text (Join-Path $ctx.prepared.acceptedRoot 'tests/test_extra.py') $testText}
        'missing'{[IO.File]::Move((Join-Path $ctx.prepared.acceptedRoot 'tests/test_add.py'),(Join-Path $ctx.root 'moved-test_add.py'))}
    }
    $result=Invoke-VerificationProposal $ctx.prepared $null $null
    Assert-True ($result.status -ceq 'blocked' -and $result.failure.reason -ceq 'recheck-tests-changed' -and $null -eq $result.manifestPath -and @($result.artifacts).Count -eq 0 -and -not(Test-Path -LiteralPath (Join-Path $ctx.controlRoot 'proposal/manifest.json'))) "recheck($variant): 拒否し manifest を作らない（$($result.status) $(ConvertTo-VerificationCanonicalJson $result.failure)）"
    Assert-Equal @(Read-FakeSbxCalls $ctx.case).Count 0 "recheck($variant): sbx 呼び出し0回"
}
# recheck manifest も同じ検査つきの1回の読込み: 期待hash の不一致、期待hash は一致するが重複キーを含む記録は blocked（recheck-manifest）。
foreach($variant in @('hash','duplicate-key')){
    $ctx=New-RecheckCtx
    $text=[IO.File]::ReadAllText($ctx.prepared.recheckManifestPath,$utf8)
    [IO.File]::WriteAllText($ctx.prepared.recheckManifestPath,$text.Replace('{"previousResultHash":','{"previousResultHash":"x","previousResultHash":'),$utf8)
    if($variant -eq 'duplicate-key'){$ctx.prepared.recheckManifestHash=Get-Hash $ctx.prepared.recheckManifestPath}
    $result=Invoke-VerificationProposal $ctx.prepared $null $null
    Assert-True ($result.status -ceq 'blocked' -and $result.failure.reason -ceq 'recheck-manifest' -and $null -eq $result.manifestPath) "recheck manifest（$variant）: blocked（$($result.status) $(ConvertTo-VerificationCanonicalJson $result.failure)）"
}
$count++

# 10. runtimeFailure の捕捉（VM なし。モジュール内の完了処理へ例外を直接渡す）: created は確定済み handle を sandbox に残し、停止済みでも起動失敗を成功にしない。
#     unknown・停止未確認は incomplete（期限到達なら timed_out）、runtimeFailure の欠落・不正は creation-unresolved の incomplete。
function New-RuntimeException([string]$Status,$Record){
    $failure=[InvalidOperationException]::new('sandbox creation failed (fixture)');$failure.Data['status']=$Status
    if($null -ne $Record){$failure.Data['runtimeFailure']=$(if($Record -is [string]){$Record}else{ConvertTo-VerificationCanonicalJson $Record})}
    $failure
}
function Complete-Creation([hashtable]$Ctx,[Exception]$Failure){& $proposalModule {param($p,$f) Complete-VerificationProposalCreationFailure (New-ProposalResult $p 'generated') $p $f} $Ctx.prepared $Failure}
$ctx=New-Ctx
$handleRecord=@{schemaVersion=3;runId=$ctx.runId;role='proposal';name=$ctx.name;id='11111111-2222-3333-4444-555555555555';createdAt='2026-09-15T00:00:00.0000000Z';profileHash=('A'*64);effectiveSettingsHash=('B'*64);activationRecordPath=$null;activationRecordHash=$null}
$failureBase=@{schemaVersion=3;runId=$ctx.runId;role='proposal';stage='activation';reason='activation-mismatch';message='x';handle=$handleRecord}
$r=Complete-Creation $ctx (New-RuntimeException 'blocked' ($failureBase+@{creationState='created';stopState='stopped'}))
Assert-True ($r.status -ceq 'blocked' -and $r.sandbox.id -ceq $handleRecord.id -and $r.sandbox.createdAt -ceq '2026-09-15T00:00:00.0000000Z' -and $r.stopState -ceq 'stopped' -and $r.failure.stage -ceq 'sandbox' -and $r.failure.reason -ceq 'activation-mismatch') "created・stopped: blocked で handle を残す（$($r.status)）"
$r=Complete-Creation $ctx (New-RuntimeException 'incomplete' ($failureBase+@{creationState='created';stopState='unverified'}))
Assert-True ($r.status -ceq 'incomplete' -and $r.sandbox.id -ceq $handleRecord.id -and $r.stopState -ceq 'unverified') 'created・unverified: incomplete'
$r=Complete-Creation $ctx (New-RuntimeException 'incomplete' (@{schemaVersion=3;runId=$ctx.runId;role='proposal';stage='create';reason='create-timed-out';message='x';handle=$null;creationState='unknown';stopState='unverified'}))
Assert-True ($r.status -ceq 'incomplete' -and $null -eq $r.sandbox -and $r.stopState -ceq 'unverified') 'unknown: incomplete（未作成へ推定しない）'
$r=Complete-Creation $ctx (New-RuntimeException 'blocked' (@{schemaVersion=3;runId=$ctx.runId;role='proposal';stage='daemon-settings';reason='daemon-settings';message='x';handle=$null;creationState='not-created';stopState='not-created'}))
Assert-True ($r.status -ceq 'blocked' -and $null -eq $r.sandbox -and $r.stopState -ceq 'not-created' -and $r.failure.reason -ceq 'daemon-settings') 'not-created: blocked'
foreach($broken in @($null,'{not json','{"creationState":"created","stopState":"stopped"}','{"creationState":"maybe","stopState":"stopped"}')){
    $r=Complete-Creation $ctx (New-RuntimeException 'blocked' $broken)
    Assert-True ($r.status -ceq 'incomplete' -and $r.failure.reason -ceq 'creation-unresolved' -and $r.stopState -ceq 'unverified' -and $null -eq $r.sandbox) "runtimeFailure 欠落・不正（$broken）: creation-unresolved の incomplete"
}
$late=New-Ctx -DeadlineIn -1
$r=Complete-Creation $late (New-RuntimeException 'incomplete' (@{schemaVersion=3;runId=$late.runId;role='proposal';stage='create';reason='create-timed-out';message='x';handle=$null;creationState='unknown';stopState='unverified'}))
Assert-True ($r.status -ceq 'timed_out' -and $r.stopState -ceq 'unverified') 'unknown で期限到達: timed_out を優先'
foreach($broken in @($null,'{not json')){
    $r=Complete-Creation $late (New-RuntimeException 'blocked' $broken)
    Assert-True ($r.status -ceq 'timed_out' -and $r.failure.reason -ceq 'creation-unresolved' -and $r.stopState -ceq 'unverified' -and $null -eq $r.sandbox) "runtimeFailure 欠落・不正で期限到達（$broken）: timed_out を優先（Replay と同じ。$($r.status)）"
}
$count++

# ---- ここから偽sbx の VM を使う経路 ----
$agentEvents='{"type":"thread.started"}'+"`n"+'{"type":"item.completed","item":{"type":"agent_message","text":"proposal written"}}'+"`n"
function Add-ProposalVm([hashtable]$Ctx,[string]$WireText,[double]$AgentDelaySeconds=0){
    $id=[guid]::NewGuid().ToString()
    Add-FakeSbxSandboxScenario $Ctx.case $Ctx.name $id -Agent 'codex' -ConfirmFiles $Ctx.baselineFiles
    $name=[regex]::Escape($Ctx.name)
    # Codex 本体の exec（出力は Codex の実行イベント風の創作）と固定エクスポーターの exec（wire は試験が組んだ Envelope）。どちらも実測が無い創作応答。
    Add-FakeSbxResponse $Ctx.case @('exec','-w','/home/agent/workspace/source',$name,'codex','exec','--json') -Stdout $agentEvents -DelaySeconds $AgentDelaySeconds -Synthetic $true -Source 'Codex の実行イベントは未観測（タスク9で実測する）' | Out-Null
    $limits=$Ctx.prepared.settings.limits
    Add-FakeSbxResponse $Ctx.case @('exec','-w','/home/agent/proposal-exporter',$name,'python3','/home/agent/proposal-exporter/proposal-export\.py','--run-id',[regex]::Escape($Ctx.runId),'--max-files',[string]$limits.maxProposalFiles,'--max-file-bytes',[string]$limits.maxFileBytes,'--max-proposal-bytes',[string]$limits.maxProposalBytes) -Stdout $WireText -Synthetic $true -Source 'proposal-export.py の出力形式（タスク4で確定）に合わせて試験が組んだ Envelope。実機の出力は未観測' | Out-Null
    @{name=$Ctx.name;id=$id}
}
function Get-CallIndex([object[]]$Calls,[scriptblock]$Predicate){for($i=0;$i -lt $Calls.Count;$i++){if(& $Predicate $Calls[$i]){return $i}};-1}
function Assert-NoLeftover([hashtable]$Ctx,[string]$Label){
    Stop-CaseFakeProcesses @($Ctx)
    Assert-Equal @(Get-CaseFakeProcesses @($Ctx)).Count 0 "${Label}: 当該ケースの偽sbxプロセスが残っていない"
}

# 11. 正常な提案: 搬入・照合 → Codex（stdin で依頼、出力は quarantine/）→ 固定エクスポーター → 停止確認 → Envelope 検査 → accepted・manifest → ready。
$ctx=New-Ctx
$vm=Add-ProposalVm $ctx ((ConvertTo-WireText (New-Envelope $ctx))+"`n")
Write-FakeSbxScenario $ctx.case
$lease=Acquire-VerificationPilotLease $ctx.prepared
try{$result=Invoke-VerificationProposal $ctx.prepared $ctx.profile $lease}finally{Release-VerificationPilotLease $lease}
Assert-True ($result.status -ceq 'ready' -and $result.origin -ceq 'generated' -and $result.stopState -ceq 'stopped' -and $null -eq $result.failure) "ready: 状態（$($result.status) $(ConvertTo-VerificationCanonicalJson $result.failure)）"
Assert-True ($result.sandbox.name -ceq $vm.name -and $result.sandbox.id -ceq $vm.id -and $result.sandbox.role -ceq 'proposal') 'ready: sandbox は確定済み handle'
Assert-Equal (@($result.artifacts | ForEach-Object {"$($_.kind):$($_.path)"}) -join ',') 'replacement:replacements/pkg/mod.py,test:tests/__init__.py,test:tests/test_add.py' 'ready: artifacts'
foreach($artifact in $result.artifacts){Assert-Equal $artifact.sha256 (Get-Hash (Join-Path $ctx.prepared.acceptedRoot $artifact.path)) "ready: $($artifact.path) の sha256 は accepted の実体"}
Assert-Equal ([IO.File]::ReadAllText((Join-Path $ctx.prepared.acceptedRoot 'replacements/pkg/mod.py'),$utf8)) $replacementText 'ready: replacement の内容'
Assert-True ($result.manifestPath -ceq (Join-Path $ctx.controlRoot 'proposal/manifest.json') -and $result.manifestHash -ceq (Get-Hash $result.manifestPath)) 'ready: manifestPath・manifestHash'
$testsOnly=[object[]]@(foreach($path in @('tests/__init__.py','tests/test_add.py')){$full=Join-Path $ctx.prepared.acceptedRoot $path;@{path=$path;size=([IO.FileInfo]::new($full)).Length;sha256=(Get-Hash $full)}})
Assert-Equal $result.testsManifestHash (Get-VerificationCanonicalHash -Object $testsOnly) 'ready: testsManifestHash を独立計算と照合'
$manifest=Get-Content -LiteralPath $result.manifestPath -Raw | ConvertFrom-Json -AsHashtable
Assert-True ($manifest.origin -ceq 'generated' -and $manifest.testsManifestHash -ceq $result.testsManifestHash -and @($manifest.artifacts).Count -eq 3) 'ready: manifest の内容'
Assert-True ($result.summary -ceq 'add が引き算になっている' -and $result.findings[0].description -ceq 'pkg/mod.py の add が a - b を返す' -and (@($result.findings[0].Keys | Sort-Object) -join ',') -ceq 'description,sourcePaths') 'ready: summary・findings（外側で組み直した参考情報）'
# quarantine: Codex の出力（実行イベント・最終応答）と CommandRecord は未信頼データとして quarantine/ に置き、transportVerified=null。
$agentRecord=Get-Content -LiteralPath (Join-Path $ctx.runRoot 'quarantine/proposal-agent-command.json') -Raw | ConvertFrom-Json -AsHashtable
Assert-True ($null -eq $agentRecord.transportVerified -and $agentRecord.exitCode -eq 0 -and $agentRecord.stdoutPath -like '*\run\quarantine\commands\*') "quarantine: CommandRecord（transportVerified=null、出力は quarantine/commands）"
Assert-Equal ([IO.File]::ReadAllText($agentRecord.stdoutPath,$utf8)) $agentEvents 'quarantine: 実行イベントと最終応答をそのまま保存'
Assert-Equal ($agentRecord.argv -join ' ') "exec -w /home/agent/workspace/source $($vm.name) codex exec --json" 'Codex: startupArgv を固定 argv で起動'
$calls=@(Read-FakeSbxCalls $ctx.case)
$cpSource=Get-CallIndex $calls {param($c) $c.argv[0] -eq 'cp' -and $c.argv[2] -ceq "$($vm.name):/home/agent/workspace/source"}
$confirm=Get-CallIndex $calls {param($c) ($c.argv -join ' ') -like '*sha256sum*'}
$agentCall=Get-CallIndex $calls {param($c) ($c.argv -join ' ') -ceq "exec -w /home/agent/workspace/source $($vm.name) codex exec --json"}
$cpExporter=Get-CallIndex $calls {param($c) $c.argv[0] -eq 'cp' -and $c.argv[2] -ceq "$($vm.name):/home/agent/proposal-exporter"}
$limits=$ctx.prepared.settings.limits
$exportArgv="exec -w /home/agent/proposal-exporter $($vm.name) python3 /home/agent/proposal-exporter/proposal-export.py --run-id $($ctx.runId) --max-files $($limits.maxProposalFiles) --max-file-bytes $($limits.maxFileBytes) --max-proposal-bytes $($limits.maxProposalBytes)"
$exportCall=Get-CallIndex $calls {param($c) ($c.argv -join ' ') -ceq $exportArgv}
$stopCall=Get-CallIndex $calls {param($c) $c.argv[0] -eq 'stop'}
Assert-True ($cpSource -ge 0 -and $cpSource -lt $confirm -and $confirm -lt $agentCall -and $agentCall -lt $cpExporter -and $cpExporter -lt $exportCall -and $exportCall -lt $stopCall) "順序: 搬入 → 照合 → Codex → エクスポーター搬入 → 回収 → 停止（$cpSource,$confirm,$agentCall,$cpExporter,$exportCall,$stopCall）"
Assert-True ($calls[$cpSource].argv[1] -ceq $ctx.prepared.proposalInputRoot -and $calls[$cpExporter].argv[1] -ceq (Join-Path $ctx.controlRoot 'proposal/exporter')) '搬入元: proposal-input と外側に複製した固定エクスポーターだけ（baseline・control 本体を渡さない）'
Assert-Equal (Get-Hash (Join-Path $ctx.controlRoot 'proposal/exporter/proposal-export.py')) (Get-Hash (Join-Path $PSScriptRoot '../proposal-export.py')) '搬入元: 固定エクスポーターの複製は原本と一致'
Assert-Equal @($calls | Select-Object -Skip ($stopCall+1) | Where-Object {$_.argv[0] -in @('exec','cp')}).Count 0 '停止後に exec・cp を発行しない'
Assert-Equal @($calls | Where-Object {$_.argv[0] -eq 'stop'}).Count 1 '停止: 当該VMへ stop 1回'
Assert-Equal @($calls | Where-Object {($_.argv -join ' ') -like '*sha256sum*'}).Count 1 '照合: source の Confirm 1回'
foreach($call in $calls){Assert-True ($call.envKeys -notcontains 'SSH_AUTH_SOCK') '環境辞書: SSH_AUTH_SOCK を渡さない'}
$requestText=& $proposalModule {param($p) New-VerificationProposalRequest $p} $ctx.prepared
Assert-True ($requestText.Contains($ctx.prepared.request.objective) -and $requestText.Contains('add(1, 2) が 3 を返す') -and $requestText.Contains('/home/agent/workspace/proposal') -and $requestText.Contains('test_*.py') -and $requestText.Contains('禁止事項') -and $requestText -match '残り時間の目安: 約 (\d+) 秒' -and [int]$Matches[1] -le 600 -and [int]$Matches[1] -ge 500) "依頼: 目的・合格条件・作業先・書式・禁止事項・残り時間（proposalSeconds 以下）"
Assert-NoLeftover $ctx 'ready'
$count++

# 12. 停止未確認: 受信・検査に進める提案でも incomplete（stopState=unverified）。accepted・manifest を確定しない。
$ctx=New-Ctx -CleanupSeconds 5
$vm=Add-ProposalVm $ctx ((ConvertTo-WireText (New-Envelope $ctx))+"`n")
$stopText=(Get-FakeSbxResponse 'stop' @{name=$vm.name}).text
Add-FakeSbxResponse $ctx.case @('stop',[regex]::Escape($vm.name)) -Stdout $stopText -Synthetic $true -Source '一覧が stopped にならない状態遷移は未観測の創作' -First | Out-Null
Write-FakeSbxScenario $ctx.case
$lease=Acquire-VerificationPilotLease $ctx.prepared
try{$result=Invoke-VerificationProposal $ctx.prepared $ctx.profile $lease}finally{Release-VerificationPilotLease $lease}
Assert-True ($result.status -ceq 'incomplete' -and $result.stopState -ceq 'unverified' -and $result.failure.stage -ceq 'stop' -and $result.failure.reason -ceq 'stop-unverified') "停止未確認: incomplete（$($result.status) $(ConvertTo-VerificationCanonicalJson $result.failure)）"
Assert-True ($null -eq $result.manifestPath -and $null -eq $result.manifestHash -and $null -eq $result.testsManifestHash -and @($result.artifacts).Count -eq 0 -and [IO.Directory]::GetFileSystemEntries($ctx.prepared.acceptedRoot).Length -eq 0) '停止未確認: accepted・manifest を確定しない'
Assert-True ($result.sandbox.id -ceq $vm.id) '停止未確認: sandbox に handle を残す'
$calls=@(Read-FakeSbxCalls $ctx.case)
Assert-True (@($calls | Where-Object {$_.argv -contains 'python3'}).Count -eq 1) '停止未確認: 受信（エクスポーター）までは済んでいる'
Assert-NoLeftover $ctx '停止未確認'
$count++

# 13. 時間超過: Codex が proposalSeconds を超えれば timed_out。受信には進むが正常提案を確定せず、停止する。
$ctx=New-Ctx -Limits @{proposalSeconds=3}
$vm=Add-ProposalVm $ctx ((ConvertTo-WireText (New-Envelope $ctx))+"`n") -AgentDelaySeconds 8
Write-FakeSbxScenario $ctx.case
$lease=Acquire-VerificationPilotLease $ctx.prepared
$watch=[Diagnostics.Stopwatch]::StartNew()
try{$result=Invoke-VerificationProposal $ctx.prepared $ctx.profile $lease}finally{Release-VerificationPilotLease $lease}
$watch.Stop()
Assert-True ($result.status -ceq 'timed_out' -and $result.failure.stage -ceq 'agent' -and $result.failure.reason -ceq 'agent-timed-out' -and $result.stopState -ceq 'stopped') "時間超過: timed_out・停止済み（$($result.status) $(ConvertTo-VerificationCanonicalJson $result.failure) $($result.stopState)）"
Assert-True ($null -eq $result.manifestPath -and @($result.artifacts).Count -eq 0 -and [IO.Directory]::GetFileSystemEntries($ctx.prepared.acceptedRoot).Length -eq 0) '時間超過: accepted・manifest を確定しない'
$agentRecord=Get-Content -LiteralPath (Join-Path $ctx.runRoot 'quarantine/proposal-agent-command.json') -Raw | ConvertFrom-Json -AsHashtable
Assert-True ($agentRecord.timedOut -eq $true -and $null -eq $agentRecord.transportVerified) '時間超過: quarantine の CommandRecord に timedOut'
$calls=@(Read-FakeSbxCalls $ctx.case)
Assert-True (@($calls | Where-Object {$_.argv -contains 'python3'}).Count -eq 1 -and @($calls | Where-Object {$_.argv[0] -eq 'stop'}).Count -eq 1) '時間超過: 受信へ進み、停止する'
Assert-NoLeftover $ctx '時間超過'
$count++

# 14. VM 作成の失敗（偽sbx）: 作成後の inspect 失敗は created・停止済みで blocked、handle を sandbox に残し Codex を起動しない。作成前の拒否（MCP 登録あり）は sandbox=null・not-created。
$ctx=New-Ctx
$vm=Add-ProposalVm $ctx '{}'
Add-FakeSbxResponse $ctx.case @('inspect',[regex]::Escape($vm.name),'--json') -Stderr "Error: inspect failed`n" -ExitCode 1 -Synthetic $true -Source 'inspect 失敗の応答は未観測の創作' -First | Out-Null
Write-FakeSbxScenario $ctx.case
$lease=Acquire-VerificationPilotLease $ctx.prepared
try{$result=Invoke-VerificationProposal $ctx.prepared $ctx.profile $lease}finally{Release-VerificationPilotLease $lease}
Assert-True ($result.status -ceq 'blocked' -and $result.sandbox.id -ceq $vm.id -and $result.stopState -ceq 'stopped' -and $result.failure.stage -ceq 'sandbox' -and $null -eq $result.manifestPath) "作成後の失敗: blocked・handle を残す（$($result.status) $(ConvertTo-VerificationCanonicalJson $result.failure)）"
Assert-Equal @(Read-FakeSbxCalls $ctx.case | Where-Object {$_.argv[0] -eq 'exec' -and $_.argv -contains 'codex'}).Count 0 '作成後の失敗: Codex を起動しない（exec 0回）'
Assert-NoLeftover $ctx '作成後の失敗'
$ctx=New-Ctx
$vm=Add-ProposalVm $ctx '{}'
Add-FakeSbxResponse $ctx.case @('mcp','ls','--json') -Stdout (Get-FakeSbxResponse 'mcpLsOne').text -Synthetic $true -First | Out-Null
Write-FakeSbxScenario $ctx.case
$lease=Acquire-VerificationPilotLease $ctx.prepared
try{$result=Invoke-VerificationProposal $ctx.prepared $ctx.profile $lease}finally{Release-VerificationPilotLease $lease}
Assert-True ($result.status -ceq 'blocked' -and $null -eq $result.sandbox -and $result.stopState -ceq 'not-created' -and $result.failure.reason -ceq 'daemon-settings') "作成前の拒否: sandbox=null・not-created（$($result.status) $(ConvertTo-VerificationCanonicalJson $result.failure)）"
Assert-Equal @(Read-FakeSbxCalls $ctx.case | Where-Object {$_.argv[0] -eq 'create'}).Count 0 '作成前の拒否: create 0回'
Assert-NoLeftover $ctx '作成前の拒否'
$count++

# 15. 全体期限の後に呼ぶ（VM なし）: VM を作らず timed_out の型付き結果（sandbox=null・not-created・sandbox:deadline-reached）。Lease を取れなかった呼出し（null）でも lease-invalid にしない。sbx 呼び出し0回。
$ctx=New-Ctx -DeadlineIn -1
Write-FakeSbxScenario $ctx.case
$result=Invoke-VerificationProposal $ctx.prepared $ctx.profile $null
Assert-True ($result.status -ceq 'timed_out' -and $null -eq $result.sandbox -and $result.stopState -ceq 'not-created' -and $result.failure.stage -ceq 'sandbox' -and $result.failure.reason -ceq 'deadline-reached' -and $result.origin -ceq 'generated') "期限後: timed_out・VM なし（$($result.status) $(ConvertTo-VerificationCanonicalJson $result.failure)）"
Assert-True ($null -eq $result.manifestPath -and @($result.artifacts).Count -eq 0 -and [IO.Directory]::GetFileSystemEntries($ctx.prepared.acceptedRoot).Length -eq 0) '期限後: accepted・manifest を作らない'
Assert-True (-not(Test-Path -LiteralPath $ctx.case.callsPath)) '期限後: sbx を1回も呼ばない'
$count++

# 16. 単調時計での全体期限（仕様01）: 壁時計の deadlineAt は未来のまま、run 単位の単調時計の totalSeconds を超えた状態で呼ぶと、VM を作らず timed_out（sbx 呼び出し0回）。
#     時計は Proposal が使う RequestCopy のインスタンスの script スコープへ試験だけが登録する（totalSeconds=0 の Stopwatch）。
$ctx=New-Ctx -DeadlineIn 900
Write-FakeSbxScenario $ctx.case
& $proposalModule {param($id) & (Get-Command Test-VerificationDeadlineReached).Module {param($runId) $script:RunClocks[$runId]=@{watch=[Diagnostics.Stopwatch]::StartNew();totalSeconds=0}} $id} $ctx.runId
Assert-True ([DateTimeOffset]::Parse($ctx.prepared.deadlineAt).UtcDateTime -gt [DateTime]::UtcNow.AddSeconds(600)) '単調時計: 前提（壁時計の期限は未来）'
Assert-True (Test-VerificationDeadlineReached $ctx.prepared.deadlineAt $ctx.runId) '単調時計: 壁時計が未来でも単調時計の到達で期限到達'
Assert-True (-not(Test-VerificationDeadlineReached $ctx.prepared.deadlineAt ([guid]::NewGuid().ToString()))) '単調時計: 時計の無い run は壁時計だけで判定（未到達）'
$result=Invoke-VerificationProposal $ctx.prepared $ctx.profile $null
Assert-True ($result.status -ceq 'timed_out' -and $null -eq $result.sandbox -and $result.stopState -ceq 'not-created' -and $result.failure.reason -ceq 'deadline-reached') "単調時計の到達: timed_out・VM なし（$($result.status) $(ConvertTo-VerificationCanonicalJson $result.failure)）"
# SbxRuntime を直接呼んでも、当該 run の単調時計の到達で照会の起動が拒否される（Execution の残時間が壁時計と単調時計の小さい方）。
$failure=Get-Failure {Acquire-VerificationPilotLease $ctx.prepared}
Assert-True ($failure.Data['status'] -ceq 'timed_out' -and $failure.Data['reason'] -ceq 'deadline-reached') "単調時計の到達: 照会の起動も拒否（$($failure.Data['status']) $($failure.Data['reason'])）"
Assert-True (-not(Test-Path -LiteralPath $ctx.case.callsPath)) '単調時計の到達: sbx を1回も呼ばない（照会も起動しない）'
$count++

}finally{
    if($allCases.Count -gt 0){try{Stop-CaseFakeProcesses $allCases.ToArray()}catch{}}
}
Assert-Equal @(Get-CaseFakeProcesses $allCases.ToArray()).Count 0 '全ケース: 試験が起動した偽sbxプロセスが残っていない'
"ProposalV3: $count cases passed"
