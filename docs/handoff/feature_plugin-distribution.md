# Handoff: スキル群の Copilot CLI プラグイン化

- **Branch**: feature/plugin-distribution
- **Last Updated**: 2026-05-04 12:50 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 実装/プラグイン manifest + dev-link スクリプト追加完了、検証フェーズへ

## 作業の目的・背景

本リポジトリの `skills/` 配下に置かれた独自スキル（start-work, decision-log 等）が Copilot CLI の `skill:` ツールから認識されない問題を解決する。Copilot CLI は `~/.copilot/installed-plugins/<marketplace>/<plugin>/skills/` のみを自動認識するため、リポジトリをプラグインとして配信できる構造にする必要があった。

ADR-0015 で「公式プラグイン化 + dev-link スクリプト」のハイブリッド方式を採用。本リポジトリ自体を Copilot CLI プラグインとして配信可能にしつつ、開発者は junction/symlink 経由で `skills/` への変更を即時反映できるようにする。

## 関連ドキュメント

- ADR: ADR-0015（スキル群を Copilot CLI プラグインとして配布）
- ハンドオフ前段: `docs/handoff/master.md`（master ブランチ側、サブプロジェクトA/B/C のクローズ状況）

## 完了済みタスク

- [x] ADR-0015 ドラフト作成・承認・コミット（`610b2b1`）
- [x] `.claude-plugin/plugin.json` 作成
- [x] `.claude-plugin/marketplace.json` 作成
- [x] `scripts/dev-link.ps1`（Windows 用 junction）作成
- [x] `scripts/dev-link.sh`（macOS/Linux 用 symlink）作成
- [x] README.md に「Copilot CLI へのインストール」節を追加
- [x] dev-link.ps1 をローカル実行 → junction 作成成功
- [x] `~/.copilot/settings.json` の enabledPlugins に `ai-driven-dev-principles@local: true` を追記

## 進行中のタスク

- [ ] **現在の作業**: 変更のコミットと動作検証
  - 状態: ファイル作成完了、未コミット
  - 残り: feature ブランチへコミット → Copilot CLI 再起動して `/env` または `skill: "start-work"` 試行で認識確認

## 未着手のタスク

- [ ] master へのマージ（PR 作成または直接マージ判断）
- [ ] サブプロジェクト完了直後の retrospective 実施（マージ後）
- [ ] `template.manifest` への `.claude-plugin/` 取り込み判断（ADR-0015 で Out of Scope と明記、別 ADR 候補）
- [ ] プラグインバージョニング規約の策定（ADR-0015 派生候補）

## 既知のブロッカー・懸念

- 本セッション内では Copilot CLI 再起動できないため、`skill: "decision-log"` 等の認識確認は次セッションで実施する必要がある
- dev-link.ps1 は確認プロンプトを使うため、CI/自動実行用途には改修が必要（`-Force` パラメータは実装済）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（再起動後 `skill: "start-work"` がローカルプラグインから呼べるか確認）
2. **最初に確認すべきファイル**:
   - 本ファイル `docs/handoff/feature_plugin-distribution.md`
   - `docs/decisions/0015-distribute-skills-as-copilot-cli-plugin.md`
3. **最初に実行すべきコマンド**:
   - `/env` で `ai-driven-dev-principles` プラグインのスキルが認識されているか確認
   - 認識されていれば `skill: "start-work"` を試行
4. **次に進める作業**:
   - 認識成功 → feature ブランチを master へマージ → retrospective 実施
   - 認識失敗 → 失敗ログを基に systematic-debugging で原因調査（plugin.json のスキーマ齟齬等）
5. **留意点**:
   - dev-link 経由の認識は実体が本リポジトリなので、`skills/` への編集はその場で反映される
   - 公開ルート（`extraKnownMarketplaces` + `/plugin install`）の検証は別マシンか別セッションで実施推奨

## 重要な意思決定の履歴

- ADR-0015: スキル群を Copilot CLI プラグインとして配布（公式プラグイン化 + dev-link ハイブリッド）（2026-05-04, Accepted）
