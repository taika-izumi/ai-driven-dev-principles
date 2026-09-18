param([Parameter(Mandatory)][string]$ProbeRoot)
# 指定された既知の保存先についてOSの読み取り許可だけを確認する。
# ファイルを開いたら直ちに閉じ、Read/ReadAllText/Copy/ハッシュ計算は行わない。
$ErrorActionPreference='Stop'
$targets=Get-Content -LiteralPath (Join-Path $ProbeRoot 'control/read-targets.json') -Raw | ConvertFrom-Json
$results=@(foreach($target in $targets){
    $entry=@{id=$target.id;presentAtHost=$target.presentAtHost;readHandleGranted=$false;errorType=$null;bytesRead=0}
    if($target.presentAtHost){
        $handle=$null
        try{
            $handle=[IO.File]::Open($target.path,[IO.FileMode]::Open,[IO.FileAccess]::Read,([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
            $entry.readHandleGranted=$true
        }catch{$entry.errorType=$_.Exception.GetBaseException().GetType().FullName}
        finally{if($handle){$handle.Dispose()}}
    }
    $entry
})
@{userSid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value;results=$results} | ConvertTo-Json -Depth 8 -Compress
