# v3 試験の共通文脈（PreparedRunV3 と同じ形の文脈と、証拠つきの runtime profile）を組み立てる試験補助。
# SbxRuntimeV3・ProposalV3 の試験にある同種の組み立て（New-Profile・New-ProposalProfile・New-Case・New-Ctx）を3つ目の複製にしないため、ReplayV3 からここへ置いた。
# 既存2試験の置き換えは再実行費用（約13分）のため後続タスクへ繰り延べた。実VM・実デーモンは動かさない（偽sbx は FakeSbxScenario.psm1）。
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'FakeSbxScenario.psm1')
Import-Module (Join-Path $PSScriptRoot '../../RequestCopy.psm1')
$script:Utf8=[Text.UTF8Encoding]::new($false)
$script:EvidenceTemplate=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'activation-evidence.json'),$script:Utf8)
$script:Limitations=@('clipboard-text-write-possible','pid-count-unbounded','daemon-disconnect-unverified')

function Get-V3TestHash([string]$Path){(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash}
function Write-V3TestText([string]$Path,[string]$Text){[void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path));[IO.File]::WriteAllText($Path,$Text,$script:Utf8)}
function Get-V3TestTreeManifest([string]$Root){
    # ディレクトリ内の全通常ファイル（.git を含む）を序数順の {path,size,sha256} で返す（RequestCopy の baseline manifest と同じ形）。
    $entries=[Collections.Generic.SortedDictionary[string,object]]::new([StringComparer]::Ordinal)
    foreach($info in [IO.DirectoryInfo]::new($Root).EnumerateFiles('*',[IO.SearchOption]::AllDirectories)){
        $relative=[IO.Path]::GetRelativePath($Root,$info.FullName).Replace('\','/')
        $entries.Add($relative,@{path=$relative;size=[long]$info.Length;sha256=(Get-V3TestHash $info.FullName)})
    }
    [object[]]@($entries.Values)
}
function New-V3TestProfile([hashtable]$Ctx,[string]$Role,[hashtable]$Overrides=@{},[scriptblock]$EvidenceEdit=$null){
    # 試験用 runtime profile。evidence は fixture の雛形へ profileHash（evidence の2項目を除く正規化JSONの SHA256）と証拠パス/ハッシュを埋めて Ctx.prof へ書く。
    $profile=@{
        schemaVersion=3;role=$Role;sbxVersion='v0.42.1';templateDigest=(Get-FakeSbxTemplateDigest);agent=$(if($Role -eq 'proposal'){'codex'}else{'shell'});model=$(if($Role -eq 'proposal'){'unit-model'}else{$null})
        startupArgv=[string[]]$(if($Role -eq 'proposal'){@('codex','exec','--json')}else{@('sh')});executableInVm=$(if($Role -eq 'proposal'){'/usr/local/bin/codex'}else{'/usr/bin/python3'})
        policyExpectation=@{networkPolicy=$(if($Role -eq 'proposal'){'allow auth.openai.com:443 chatgpt.com:443 only'}else{'deny *'})};mountExpectation=@{workspace='none';shareSkills=$false;sshAgentForwarding=$false}
        scope='synthetic-pilot';acceptedLimitations=$script:Limitations
        stdlibModulesPath='stdlib-modules.txt';stdlibModulesHash=(Get-V3TestHash (Join-Path $Ctx.prof 'stdlib-modules.txt'))
        activationEvidencePath=$null;activationEvidenceHash=$null
    }
    foreach($key in $Overrides.Keys){$profile[$key]=$Overrides[$key]}
    $subset=@{};foreach($key in $profile.Keys){if($key -notin @('activationEvidencePath','activationEvidenceHash')){$subset[$key]=$profile[$key]}}
    $json=$script:EvidenceTemplate.Replace('{{profileHash}}',(Get-VerificationCanonicalHash $subset)).Replace('{{evidencePath}}','evidence-note.txt').Replace('{{evidenceHash}}',(Get-V3TestHash (Join-Path $Ctx.prof 'evidence-note.txt')))
    $evidence=$json | ConvertFrom-Json -AsHashtable -Depth 10 -DateKind String
    $evidence.Remove('_comment')
    if($null -ne $EvidenceEdit){& $EvidenceEdit $evidence}
    $Ctx.evidenceSeq++
    $name="ev-$Role-$($Ctx.evidenceSeq).json"
    Write-V3TestText (Join-Path $Ctx.prof $name) (ConvertTo-VerificationCanonicalJson $evidence)
    $profile.activationEvidencePath=$name;$profile.activationEvidenceHash=Get-V3TestHash (Join-Path $Ctx.prof $name)
    $profile
}
function New-V3TestContext([string]$Root,[System.Collections.IDictionary]$BaselineFiles,[hashtable]$Limits=@{},[int]$CleanupSeconds=5,[int]$DeadlineIn=900,[string]$StdlibModulesPath=''){
    # PreparedRunV3 と同じ形の文脈。run の配置は RequestCopy の v3 と同じ（baseline・proposal-input・quarantine・accepted・replay-inputs・temp・control の各下位）。
    # baseline と proposal-input は同じファイル群（BaselineFiles: 相対パス → 本文。.git/ 配下も書ける）。baseline manifest は baseline の実体から作る。
    # Root は短い名前にする（Windows の MAX_PATH。Issue-0146）。偽sbx一式は Root/sbx、偽の状態ディレクトリは Root/state。
    $case=New-FakeSbxCase $Root
    $runId=[guid]::NewGuid().ToString()
    $runRoot=Join-Path $Root 'run';$control=Join-Path $runRoot 'control';$prof=Join-Path $Root 'prof';$source=Join-Path $Root 'src'
    foreach($part in @('baseline','proposal-input','quarantine','accepted','replay-inputs','temp','control','control/runtime','control/proposal','control/replay')){[void][IO.Directory]::CreateDirectory((Join-Path $runRoot $part))}
    foreach($dir in @($prof,$source)){[void][IO.Directory]::CreateDirectory($dir)}
    foreach($rel in $BaselineFiles.Keys){foreach($tree in @('baseline','proposal-input')){Write-V3TestText (Join-Path $runRoot "$tree/$rel") ([string]$BaselineFiles[$rel])}}
    $baselineRoot=Join-Path $runRoot 'baseline'
    $files=Get-V3TestTreeManifest $baselineRoot
    $baselineManifestPath=Join-Path $control 'baseline-manifest.json'
    Write-VerificationNewFile $baselineManifestPath (ConvertTo-VerificationCanonicalJson @{schemaVersion=3;runId=$runId;files=$files})
    Write-V3TestText (Join-Path $prof 'evidence-note.txt') "fixture evidence note`n"
    if([string]::IsNullOrEmpty($StdlibModulesPath)){Write-V3TestText (Join-Path $prof 'stdlib-modules.txt') "os`nsys`nunittest`n"}
    else{[IO.File]::Copy($StdlibModulesPath,(Join-Path $prof 'stdlib-modules.txt'),$true)}
    Write-V3TestText (Join-Path $prof 'replay.json') '{}';Write-V3TestText (Join-Path $prof 'proposal.json') '{}'
    $sourceManifestPath=Join-Path $control 'source-manifest.json'
    Write-VerificationNewFile $sourceManifestPath (ConvertTo-VerificationCanonicalJson @{schemaVersion=3;files=@(@{path='tracked.txt';size=8;sha256=('A'*64)})})
    $pilot=@{schemaVersion=3;inputId='pilot-fixture';scope='synthetic-pilot';sourceRoot=$source;sourceManifestHash=(Get-V3TestHash $sourceManifestPath);approvalReference=@{path='docs/records/reviews/fixture.md';version='0000000'}}
    $pilotPath=Join-Path $control 'pilot-input.json'
    Write-VerificationNewFile $pilotPath (ConvertTo-VerificationCanonicalJson $pilot)
    $limitValues=@{totalSeconds=1800;proposalSeconds=600;replaySeconds=120;cleanupSeconds=$CleanupSeconds;cpus=2;memoryMiB=2048;maxProposalFiles=100;maxFileBytes=1MB;maxProposalBytes=8MB;maxWireBytes=16MB;maxOutputBytes=16MB}
    foreach($key in $Limits.Keys){$limitValues[$key]=$Limits[$key]}
    $settings=@{
        schemaVersion=3;sbxPath=$case.sbxPath;pwshPath=(Get-Command pwsh).Source;runsRoot=(Join-Path $Root 'runs');model='unit-model'
        proposalProfilePath=(Join-Path $prof 'proposal.json');replayProfilePath=(Join-Path $prof 'replay.json');pilotInputPath=$pilotPath;limits=$limitValues
    }
    $now=[DateTime]::UtcNow
    $prepared=@{
        schemaVersion=3;runId=$runId;sourceRoot=$source;runRoot=$runRoot;baselineRoot=$baselineRoot;proposalInputRoot=(Join-Path $runRoot 'proposal-input');acceptedRoot=(Join-Path $runRoot 'accepted');controlRoot=$control
        request=@{schemaVersion=3;caller='codex';sourceRoot=$source;objective='合成題材の不具合を再現し修正候補を示す';acceptanceCriteria=@('add(1, 2) が 3 を返す');extraInputPaths=@()}
        settings=$settings
        sourceManifestPath=$sourceManifestPath;sourceManifestHash=(Get-V3TestHash $sourceManifestPath);baselineManifestPath=$baselineManifestPath;baselineManifestHash=(Get-V3TestHash $baselineManifestPath)
        recheckManifestPath=$null;recheckManifestHash=$null;recheckArtifacts=@()
        startedAt=$now.ToString('o');deadlineAt=$now.AddSeconds($DeadlineIn).ToString('o');cleanupSeconds=$CleanupSeconds
        pilotInputId='pilot-fixture';pilotInputPath=$pilotPath;pilotInputHash=(Get-V3TestHash $pilotPath)
    }
    $names=@{}
    foreach($pair in @(@('proposal','proposal'),@('replay-before','before'),@('replay-after','after'))){$names[$pair[0]]='iv-'+$runId.Substring(0,8)+'-'+$pair[1]}
    $ctx=@{case=$case;root=$Root;runId=$runId;runRoot=$runRoot;controlRoot=$control;prof=$prof;settings=$settings;prepared=$prepared;baselineFiles=$files;evidenceSeq=0;names=$names}
    $ctx.replayProfile=New-V3TestProfile $ctx 'replay'
    $ctx
}
Export-ModuleMember -Function Get-V3TestHash,Write-V3TestText,Get-V3TestTreeManifest,New-V3TestProfile,New-V3TestContext
