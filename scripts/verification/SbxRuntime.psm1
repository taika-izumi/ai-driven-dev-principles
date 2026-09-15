# sbx 実行基盤を外側の記録で管理する。実行設定（runtime profile）の検査、pilot 排他、VM の作成・搬入・照合・実行・停止、
# activationRecord、デーモン起動世代、記録済み ID の復旧停止（ADR-0194）。VM を扱う操作はこのモジュールに閉じ、他ブロックは公開操作だけを呼ぶ。
# sbx CLI は常に外側で固定 argv を組み立て、最小の環境辞書（SSH_AUTH_SOCK を含めない）で起動する。子からホストコマンド・フラグ・接続先を受け取らない。
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'RequestCopy.psm1')   # 正規化JSON・ハッシュ・新規作成書込・UTC時刻・重複キー検査を共用する
Import-Module (Join-Path $PSScriptRoot 'Execution.psm1')     # 上限付きプロセス実行と背景起動
# exec 以外のコマンドの時間上限（秒）。計画「時間上限の全域表」の定数。limits・CLI 入力・子からは変えず、試験だけが script スコープで小さい値へ差し替える。
$script:QuerySeconds=60      # 照会（daemon status・ls・inspect・policy・settings・mcp）と stop
$script:SetupSeconds=240     # 作成・搬入・所有者調整・搬入照合（create・cp・chown・Confirm の exec）
$script:KeepAliveStopGraceSeconds=5
$script:RequiredChecks=@{
    common=@('daemonHealthAndTemplate','noWorkspaceNoSkillsNoMcp','hostPathIsolation','resourceAndOutsideStop','limitsAndTransport','abnormalExitRecovery','daemonDisconnect')
    proposal=@('credentialMethod','modelEndpointAllowOnly');replay=@('replayNetworkDeny')
}
$script:TransportContrastKeys=@('exit0','exit7','exit127','timeout','clientKilled')
$script:AcceptedLimitations=@('clipboard-text-write-possible','pid-count-unbounded','daemon-disconnect-unverified')
$script:RoleSuffix=@{proposal='proposal';'replay-before'='before';'replay-after'='after';probe='probe'}
$script:CreatableRoles=@('proposal','replay-before','replay-after')

# ---- 共通補助 ----
function Throw-VerificationRuntimeFailure([string]$Message,[string]$Status='blocked',[string]$Reason='') {
    $failure=[InvalidOperationException]::new($Message);$failure.Data['status']=$Status
    if($Reason){$failure.Data['reason']=$Reason}
    throw $failure
}
function Test-VerificationRuntimeSchema([hashtable]$Object,[string]$SchemaName,[string]$Label) {
    $json=$Object | ConvertTo-Json -Depth 20
    $errors=$null
    if(-not(Test-Json -Json $json -SchemaFile (Join-Path $PSScriptRoot $SchemaName) -ErrorAction SilentlyContinue -ErrorVariable errors)){
        $detail=$(if($errors -and $errors.Count -gt 0){$errors[0].Exception.Message}else{'schema violation'})
        Throw-VerificationRuntimeFailure "invalid $Label schema: $detail" 'blocked' 'schema'
    }
}
function Read-VerificationJsonFile([string]$Path,[string]$Label) {
    if(-not[IO.File]::Exists($Path)){Throw-VerificationRuntimeFailure "$Label missing: $Path"}
    $json=[IO.File]::ReadAllText($Path,[Text.UTF8Encoding]::new($false))
    if(Test-VerificationJsonDuplicateKeys $json){Throw-VerificationRuntimeFailure "$Label has duplicate keys"}
    $value=$json | ConvertFrom-Json -AsHashtable -Depth 20
    if($value -isnot [hashtable]){Throw-VerificationRuntimeFailure "$Label must be a JSON object"}
    $value
}
function Get-VerificationFileHash([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
function Resolve-VerificationRelativePath([string]$Value,[string]$BaseDir) {
    # 絶対パスはそのまま、相対パスは基準ディレクトリ（profile や evidence のあるディレクトリ）から解決する。再解析ポイントは拒否する。
    if([string]::IsNullOrWhiteSpace($Value)){Throw-VerificationRuntimeFailure 'path required'}
    if([IO.Path]::IsPathFullyQualified($Value)){return Resolve-VerificationPath $Value}
    Resolve-VerificationPath ([IO.Path]::GetFullPath((Join-Path $BaseDir $Value)))
}

# ---- 実行設定（runtime profile）の検査 ----
function Get-VerificationProfileRole([string]$Role) {
    # replay-before/replay-after は検査時だけ profile.role=replay へ対応付ける（記録上の役割は統合しない）。probe は profile 検査を通らない足場なので受けない。
    switch($Role){
        'proposal'{return 'proposal'}
        'replay-before'{return 'replay'}
        'replay-after'{return 'replay'}
        default{Throw-VerificationRuntimeFailure "unsupported role: $Role"}
    }
}
function Get-VerificationProfileHash([hashtable]$Profile) {
    # activationEvidencePath/Hash を除いた正規化JSONの SHA256（証拠への相互参照でハッシュが循環しないため）。
    $subset=@{}
    foreach($key in $Profile.Keys){if($key -notin @('activationEvidencePath','activationEvidenceHash')){$subset[$key]=$Profile[$key]}}
    Get-VerificationCanonicalHash $subset
}
function Test-VerificationRuntimeProfile([hashtable]$Profile,[string]$Role,[hashtable]$Settings) {
    # 1つでも欠ければ blocked。返り値は profileHash。
    $profileRole=Get-VerificationProfileRole $Role
    if($null -eq $Profile){Throw-VerificationRuntimeFailure 'runtime profile required'}
    if($null -eq $Settings -or -not$Settings.ContainsKey('limits')){Throw-VerificationRuntimeFailure 'settings with limits required'}
    Test-VerificationRuntimeSchema $Profile 'runtime-profile.schema.json' 'runtime profile'
    if($Profile.role -cne $profileRole){Throw-VerificationRuntimeFailure "profile role '$($Profile.role)' does not match requested role '$Role'"}
    $expectedAgent=$(if($profileRole -eq 'proposal'){'codex'}else{'shell'})
    if($Profile.agent -cne $expectedAgent){Throw-VerificationRuntimeFailure "profile agent must be $expectedAgent for $profileRole"}
    if($profileRole -eq 'proposal'){
        if($null -eq $Profile.model -or -not$Settings.ContainsKey('model') -or $null -eq $Settings.model -or $Profile.model -cne $Settings.model){Throw-VerificationRuntimeFailure 'profile model does not match settings model'}
    }elseif($null -ne $Profile.model){Throw-VerificationRuntimeFailure 'replay profile must not name a model'}
    if((ConvertTo-VerificationCanonicalJson @($Profile.acceptedLimitations)) -cne (ConvertTo-VerificationCanonicalJson $script:AcceptedLimitations)){Throw-VerificationRuntimeFailure 'acceptedLimitations must be the fixed synthetic-pilot list'}
    # 相対パスは Settings の当該役割の profile パスのディレクトリから解決する。
    $profilePathKey=$(if($profileRole -eq 'proposal'){'proposalProfilePath'}else{'replayProfilePath'})
    if(-not$Settings.ContainsKey($profilePathKey) -or $Settings[$profilePathKey] -isnot [string]){Throw-VerificationRuntimeFailure "settings.$profilePathKey required"}
    $baseDir=[IO.Path]::GetDirectoryName((Resolve-VerificationPath $Settings[$profilePathKey]))
    $stdlibPath=Resolve-VerificationRelativePath $Profile.stdlibModulesPath $baseDir
    if(-not[IO.File]::Exists($stdlibPath)){Throw-VerificationRuntimeFailure 'stdlib modules file missing'}
    if((Get-VerificationFileHash $stdlibPath) -ine $Profile.stdlibModulesHash){Throw-VerificationRuntimeFailure 'stdlib modules hash mismatch'}
    $evidencePath=Resolve-VerificationRelativePath $Profile.activationEvidencePath $baseDir
    if(-not[IO.File]::Exists($evidencePath)){Throw-VerificationRuntimeFailure 'activation evidence missing'}
    if((Get-VerificationFileHash $evidencePath) -ine $Profile.activationEvidenceHash){Throw-VerificationRuntimeFailure 'activation evidence hash mismatch'}
    $evidence=Read-VerificationJsonFile $evidencePath 'activation evidence'
    Test-VerificationRuntimeSchema $evidence 'activation-evidence.schema.json' 'activation evidence'
    $profileHash=Get-VerificationProfileHash $Profile
    if($evidence.profileHash -ine $profileHash){Throw-VerificationRuntimeFailure 'activation evidence profileHash does not match profile'}
    # 必須条件名がすべて存在し、daemonDisconnect 以外は verified（ADR-0196）。各条件の証拠ファイルの hash も一致すること（profiles/evidence-checks.md）。
    $evidenceDir=[IO.Path]::GetDirectoryName($evidencePath)
    foreach($name in @($script:RequiredChecks.common)+@($script:RequiredChecks[$profileRole])){
        if(-not$evidence.checks.ContainsKey($name)){Throw-VerificationRuntimeFailure "activation evidence lacks required check: $name"}
        $check=$evidence.checks[$name]
        if($name -eq 'daemonDisconnect'){
            if($check.verdict -notin @('verified','unverified')){Throw-VerificationRuntimeFailure "activation check $name must be verified or unverified"}
        }elseif($check.verdict -cne 'verified'){Throw-VerificationRuntimeFailure "activation check not verified: $name ($($check.verdict))"}
        $checkPath=Resolve-VerificationRelativePath $check.evidencePath $evidenceDir
        if(-not[IO.File]::Exists($checkPath)){Throw-VerificationRuntimeFailure "evidence file missing for check $name"}
        if((Get-VerificationFileHash $checkPath) -ine $check.evidenceHash){Throw-VerificationRuntimeFailure "evidence hash mismatch for check $name"}
    }
    foreach($key in $script:TransportContrastKeys){if(-not$evidence.transportContrast.ContainsKey($key)){Throw-VerificationRuntimeFailure "transportContrast lacks $key"}}
    $profileHash
}
function Get-VerificationEffectiveSettingsHash([hashtable]$Profile,[hashtable]$Settings) {
    # 意図した実行条件のラベル（role を含めない。before/after で一致すべき値）。実効値の証拠は activationRecord の checks が担う。
    $limits=@{};foreach($key in $Settings.limits.Keys){$limits[$key]=$Settings.limits[$key]}
    Get-VerificationCanonicalHash @{agent=$Profile.agent;templateDigest=$Profile.templateDigest;cpus=$Settings.limits.cpus;memoryMiB=$Settings.limits.memoryMiB;networkPolicy=$Profile.policyExpectation.networkPolicy;shareSkills=$false;workspace='none';limits=$limits}
}
Export-ModuleMember -Function Test-VerificationRuntimeProfile,Get-VerificationEffectiveSettingsHash
