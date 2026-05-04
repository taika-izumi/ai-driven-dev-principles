<#
.SYNOPSIS
    本リポジトリを Copilot CLI のインストール済みプラグインディレクトリへ junction で接続し、
    開発時の `skills/` 編集を即時反映可能にする。

.DESCRIPTION
    Copilot CLI は ~/.copilot/installed-plugins/<marketplace>/<plugin>/skills/ に配置された
    SKILL.md のみを `skill:` ツール経由で認識する。
    通常のインストール（/plugin install）ではリポジトリのスナップショットがコピーされるため、
    開発中の skills/ 編集が即時反映されない。

    本スクリプトは installed-plugins 配下に "local" 仮想マーケットプレイスを作り、
    本リポジトリへの junction を張ることで開発体験を改善する。

    注意: 本スクリプトはファイルシステム junction を作成するのみ。
    settings.json の enabledPlugins への追記は手動で行う必要がある（README 参照）。

.PARAMETER Force
    既存 junction/ディレクトリがある場合、確認なしで上書きする。

.EXAMPLE
    pwsh -File scripts/dev-link.ps1
#>
[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$marketplaceName = 'local'
$pluginName = 'ai-driven-dev-principles'
$copilotPluginsDir = Join-Path $HOME '.copilot/installed-plugins'
$marketplaceDir = Join-Path $copilotPluginsDir $marketplaceName
$linkPath = Join-Path $marketplaceDir $pluginName

Write-Host "リポジトリルート: $repoRoot"
Write-Host "リンク先: $linkPath"

if (-not (Test-Path (Join-Path $repoRoot '.claude-plugin/plugin.json'))) {
    Write-Error "リポジトリルートに .claude-plugin/plugin.json が見つかりません。本スクリプトはリポジトリ内から実行してください。"
    exit 1
}

if (-not (Test-Path $marketplaceDir)) {
    New-Item -ItemType Directory -Path $marketplaceDir -Force | Out-Null
    Write-Host "マーケットプレイスディレクトリを作成しました: $marketplaceDir"
}

if (Test-Path $linkPath) {
    $item = Get-Item $linkPath -Force
    $isJunction = $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint
    if (-not $Force) {
        $msg = if ($isJunction) { "既存の junction が見つかりました。再作成しますか? (y/N): " } else { "既存ディレクトリ（junction ではない）が見つかりました。削除して junction を作成しますか? (y/N): " }
        $ans = Read-Host -Prompt $msg
        if ($ans -notmatch '^[Yy]') {
            Write-Host "中止しました。"
            exit 0
        }
    }
    if ($isJunction) {
        Remove-Item $linkPath -Force -Recurse
    } else {
        Remove-Item $linkPath -Force -Recurse
    }
}

New-Item -ItemType Junction -Path $linkPath -Target $repoRoot | Out-Null
Write-Host "junction を作成しました: $linkPath -> $repoRoot"

Write-Host ""
Write-Host "次のステップ:"
Write-Host "  1. ~/.copilot/settings.json を開き、enabledPlugins に以下を追加:"
Write-Host "       `"$pluginName@$marketplaceName`": true"
Write-Host "  2. Copilot CLI を再起動して /env で skills が認識されているか確認"
