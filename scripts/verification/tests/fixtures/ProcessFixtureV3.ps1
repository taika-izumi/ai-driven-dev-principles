# v3 プロセス実行の試験対象。stdin の反響・stdin 未読の非0終了・出力洪水・指定秒の待機を提供する（存在しない実行ファイルは StartInfo 側で指定する）。
param([ValidateSet('echo','ignore','flood','sleep')][string]$Mode,[int]$Seconds=1,[string]$Tag='')
if($Mode -eq 'echo'){
    # stdin をバイト列のまま stdout へ反響する。-Tag（引数の転送確認用）は UTF-8 で stderr へ書く。
    $in=[Console]::OpenStandardInput();$out=[Console]::OpenStandardOutput();$in.CopyTo($out);$out.Flush()
    if($Tag){$bytes=[Text.UTF8Encoding]::new($false).GetBytes($Tag);$err=[Console]::OpenStandardError();$err.Write($bytes,0,$bytes.Length);$err.Flush()}
    exit 0
}
if($Mode -eq 'ignore'){[Console]::Error.WriteLine('fixture ignores stdin');exit 7}
if($Mode -eq 'flood'){
    $out=[Console]::OpenStandardOutput();$err=[Console]::OpenStandardError()
    $chunkOut=[byte[]]::new(65536);[Array]::Fill($chunkOut,[byte]111);$chunkErr=[byte[]]::new(65536);[Array]::Fill($chunkErr,[byte]101)
    while($true){$out.Write($chunkOut,0,$chunkOut.Length);$err.Write($chunkErr,0,$chunkErr.Length)}
}
if($Mode -eq 'sleep'){Start-Sleep -Seconds $Seconds;exit 0}
