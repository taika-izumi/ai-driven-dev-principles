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
        policyExpectation=@{networkPolicy='deny *'};mountExpectation=@{workspace='none';shareSkills=$false;sshAgentForwarding=$false}
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
function New-Ctx([hashtable]$Limits=@{},[int]$CleanupSeconds=5,[int]$DeadlineIn=900){
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
$nested=New-Envelope $ctx;$nested.files=@($nested.files)+@((New-FileEntry 'test' 'unit/test_more.py' $testText),(New-FileEntry 'test' 'unit/__init__.py' ''))
Assert-True (@((Test-VerificationProposalEnvelope (ConvertTo-Wire $nested) $ctx.prepared).files).Count -eq 5) '正常: tests 配下のサブディレクトリ'
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

# 5. kind: test は tests/ 接頭辞なしの test_*.py / __init__.py、replacement は基準版にある .py。test 0件は拒否。
Assert-EditRejected $ctx {param($e) $e.files[0].path='tests/test_add.py'} 'envelope-kind' 'test に tests/ 接頭辞'
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

}finally{
    if($allCases.Count -gt 0){try{Stop-CaseFakeProcesses $allCases.ToArray()}catch{}}
}
"ProposalV3: $count cases passed"
