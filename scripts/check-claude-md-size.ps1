# check-claude-md-size.ps1
# CLAUDE.md（常時指示）の規模を計測し、閾値超過時に棚卸しを促す警告を出す（ADR-0040）
# 使い方: pwsh scripts/check-claude-md-size.ps1 (PowerShell 5.1でも動作可)
#         sync-template.ps1 の末尾からも自動で呼ばれる
# 終了コードは常に 0（警告のみ。規範の追加や同期をブロックしない）

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# 閾値（ADR-0040）。データから導出した危険水域ではなく、既知の劣化域から
# 安全マージンを取った管理上のトリップワイヤー。棚卸ししても閾値内へ
# 戻せない場合は、引き上げをユーザーへ提起する（CONTRIBUTING.md 棚卸し手順）
$maxBytes = 12000
$maxBullets = 45

$repoRoot = Split-Path -Parent $PSScriptRoot
$targetPath = Join-Path $repoRoot "CLAUDE.md"

if (-not (Test-Path $targetPath)) {
    Write-Warning "[check-claude-md-size] CLAUDE.md not found at $targetPath"
    exit 0
}

$bytes = (Get-Item $targetPath).Length
$lines = @(Get-Content $targetPath)
$lineCount = $lines.Count
$bulletCount = @($lines | Where-Object { $_ -match '^- ' }).Count

Write-Host "[check-claude-md-size] CLAUDE.md: $bytes bytes (threshold $maxBytes), $bulletCount bullets (threshold $maxBullets), $lineCount lines"

$overBytes = $bytes -gt $maxBytes
$overBullets = $bulletCount -gt $maxBullets

if ($overBytes -or $overBullets) {
    Write-Warning "[check-claude-md-size] 閾値を超過しています。CONTRIBUTING.md「CLAUDE.md を棚卸しするとき」の実施を検討してください。"
    if ($overBytes) {
        Write-Warning "  - バイト数: $bytes > $maxBytes"
    }
    if ($overBullets) {
        Write-Warning "  - 箇条書き件数: $bulletCount > $maxBullets"
    }
}

exit 0
