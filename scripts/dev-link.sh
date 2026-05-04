#!/usr/bin/env bash
# 本リポジトリを Copilot CLI のインストール済みプラグインディレクトリへ symlink で接続し、
# 開発時の skills/ 編集を即時反映可能にする（macOS / Linux 用）。
# Windows 開発者は scripts/dev-link.ps1 を使用すること。
#
# 注意: 本スクリプトはファイルシステム symlink を作成するのみ。
# settings.json の enabledPlugins への追記は手動で行う必要がある（README 参照）。

set -euo pipefail

FORCE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --force|-f) FORCE=1; shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
MARKETPLACE_NAME="local"
PLUGIN_NAME="ai-driven-dev-principles"
COPILOT_PLUGINS_DIR="$HOME/.copilot/installed-plugins"
MARKETPLACE_DIR="$COPILOT_PLUGINS_DIR/$MARKETPLACE_NAME"
LINK_PATH="$MARKETPLACE_DIR/$PLUGIN_NAME"

echo "リポジトリルート: $REPO_ROOT"
echo "リンク先: $LINK_PATH"

if [[ ! -f "$REPO_ROOT/.claude-plugin/plugin.json" ]]; then
    echo "ERROR: リポジトリルートに .claude-plugin/plugin.json が見つかりません。" >&2
    exit 1
fi

mkdir -p "$MARKETPLACE_DIR"

if [[ -e "$LINK_PATH" || -L "$LINK_PATH" ]]; then
    if [[ "$FORCE" -ne 1 ]]; then
        read -r -p "既存のリンク/ディレクトリが見つかりました。再作成しますか? (y/N): " ans
        if [[ ! "$ans" =~ ^[Yy]$ ]]; then
            echo "中止しました。"
            exit 0
        fi
    fi
    rm -rf "$LINK_PATH"
fi

ln -s "$REPO_ROOT" "$LINK_PATH"
echo "symlink を作成しました: $LINK_PATH -> $REPO_ROOT"

cat <<EOF

次のステップ:
  1. ~/.copilot/settings.json を開き、enabledPlugins に以下を追加:
       "$PLUGIN_NAME@$MARKETPLACE_NAME": true
  2. Copilot CLI を再起動して /env で skills が認識されているか確認
EOF
