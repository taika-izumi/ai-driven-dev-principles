# 偽sbx（試験専用）。記録済みの固定応答を返す。実VMもデーモンも動かさない。
# 同ディレクトリの scenario.json（配列）から「argv の各要素に対する正規表現パターン列の全一致」で先頭の一致項目を選び、
# その stdout/stderr/exitCode/delaySeconds を返す。任意の scriptblock・接続先は受け付けない。
# 状態遷移（create の後で ls の内容が変わる、stop の後で daemon.log に行が増える等）は項目の requires/sets/appendFile/writeFile で表し、
# 状態は同ディレクトリの state.json（平らな文字列辞書）に持つ。テキスト中の {{now}} は現在時刻（ISO 8601・ローカルオフセット付き）、
# {{state:キー|既定値}} は state.json の値（無ければ既定値）へ置き換える。
# 呼び出しごとに calls.jsonl へ1行追記する: argv・作業ディレクトリ・受け取った環境変数のキー一覧（値は記録しない）・時刻。
# 未定義の argv は終了3で stderr に unexpected sbx call を返す。
$ErrorActionPreference='Stop'
$argv=@($args | ForEach-Object {[string]$_})
$dir=$PSScriptRoot
$utf8=[Text.UTF8Encoding]::new($false)
$call=@{argv=$argv;cwd=(Get-Location).Path;envKeys=@(Get-ChildItem env: | Select-Object -ExpandProperty Name | Sort-Object);time=[DateTime]::UtcNow.ToString('o')}
$line=($call | ConvertTo-Json -Compress -Depth 5)+"`n"
# 背景の保持 exec と前面の呼び出しが同時に追記しうる。書き手どうしは共有 Read で排他し（同時追記で行が混ざらないように）、共有違反は短時間だけ開き直す。
# 読み手（FakeSbxScenario の Read-FakeSbxCalls）は共有 ReadWrite で開くので書き手を妨げない。
$callsDeadline=[DateTime]::UtcNow.AddSeconds(10)
while($true){
    try{$stream=[IO.File]::Open((Join-Path $dir 'calls.jsonl'),[IO.FileMode]::Append,[IO.FileAccess]::Write,[IO.FileShare]::Read);break}
    catch [IO.IOException]{if([DateTime]::UtcNow -ge $callsDeadline){throw};Start-Sleep -Milliseconds 20}
}
try{$bytes=$utf8.GetBytes($line);$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
$scenario=@(Get-Content -LiteralPath (Join-Path $dir 'scenario.json') -Raw | ConvertFrom-Json -AsHashtable -Depth 10)
$statePath=Join-Path $dir 'state.json'
$state=@{}
if(Test-Path -LiteralPath $statePath){$loaded=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json -AsHashtable;foreach($key in $loaded.Keys){$state[$key]=[string]$loaded[$key]}}
function Expand-FakeText([string]$Text){
    $expanded=$Text.Replace('{{now}}',[DateTimeOffset]::Now.ToString('o'))
    [regex]::Replace($expanded,'\{\{state:([^}|]+)(?:\|([^}]*))?\}\}',{param($m) $key=$m.Groups[1].Value;if($state.ContainsKey($key)){$state[$key]}else{$m.Groups[2].Value}})
}
function Get-FakeValue([hashtable]$Entry,[string]$Key,$Default){if($Entry.ContainsKey($Key) -and $null -ne $Entry[$Key]){$Entry[$Key]}else{$Default}}
$match=$null
foreach($entry in $scenario){
    $patterns=@(Get-FakeValue $entry 'argv' @())
    if($patterns.Count -ne $argv.Count){continue}
    $ok=$true
    for($i=0;$i -lt $argv.Count;$i++){if(-not[regex]::IsMatch($argv[$i],'^(?:'+$patterns[$i]+')$')){$ok=$false;break}}
    if(-not$ok){continue}
    $requires=Get-FakeValue $entry 'requires' $null
    if($null -ne $requires){
        foreach($key in $requires.Keys){
            $current=$(if($state.ContainsKey($key)){$state[$key]}else{''})
            if($current -cne [string]$requires[$key]){$ok=$false;break}
        }
    }
    if($ok){$match=$entry;break}
}
if($null -eq $match){[Console]::Error.WriteLine('unexpected sbx call: '+($argv -join ' '));exit 3}
# 状態の副作用（sets・appendFile・writeFile）を先に適用してから遅延する。遅延は「デーモン側の処理は済んだがクライアントが戻らない」状況を表す
# （時間超過で外側がクライアントを止めた後に VM が一覧に現れる経路の試験。遅延のある既定応答は副作用を持たない）。
$delay=[double](Get-FakeValue $match 'delaySeconds' 0)
$sets=Get-FakeValue $match 'sets' $null
if($null -ne $sets){foreach($key in $sets.Keys){$state[$key]=[string]$sets[$key]};[IO.File]::WriteAllText($statePath,($state | ConvertTo-Json -Compress),$utf8)}
foreach($effect in @(Get-FakeValue $match 'appendFile' @())){
    if($null -eq $effect){continue}
    $target=[IO.File]::Open([string]$effect.path,[IO.FileMode]::Append,[IO.FileAccess]::Write,[IO.FileShare]::ReadWrite)
    try{$bytes=$utf8.GetBytes((Expand-FakeText ([string]$effect.text)));$target.Write($bytes,0,$bytes.Length)}finally{$target.Dispose()}
}
foreach($effect in @(Get-FakeValue $match 'writeFile' @())){
    if($null -eq $effect){continue}
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName([string]$effect.path))
    [IO.File]::WriteAllText([string]$effect.path,(Expand-FakeText ([string]$effect.text)),$utf8)
}
if($delay -gt 0){Start-Sleep -Seconds $delay}
$stdout=Expand-FakeText ([string](Get-FakeValue $match 'stdout' ''))
$stderr=Expand-FakeText ([string](Get-FakeValue $match 'stderr' ''))
if($stdout.Length -gt 0){$out=[Console]::OpenStandardOutput();$bytes=$utf8.GetBytes($stdout);$out.Write($bytes,0,$bytes.Length);$out.Flush()}
if($stderr.Length -gt 0){$err=[Console]::OpenStandardError();$bytes=$utf8.GetBytes($stderr);$err.Write($bytes,0,$bytes.Length);$err.Flush()}
exit ([int](Get-FakeValue $match 'exitCode' 0))
