# Handoff: スキル群の Copilot CLI プラグイン化 + template ワークフロー再設計

- **Branch**: feature/plugin-distribution（merge 済み: `a92dc81` → master push 済み）
- **Last Updated**: 2026-05-05 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: 完了（retrospective 実施済、ADR-0018 起票）

## 作業の目的・背景

本リポジトリの `skills/` 配下に置かれた独自スキルが Copilot CLI の `skill:` ツールから認識されない問題を、リポジトリ自体をプラグイン化することで解決する（ADR-0015）。さらに template から skills/ を除外しプラグイン一本化（ADR-0016）。本セッションで dev-link 方式の誤りが判明し、`copilot plugin marketplace add <local-path>` 経由の正規手順へ修正（ADR-0017）。最終的に master マージ後、private リポでの GitHub source インストール（方式 A）も動作実証した。

## 関連ドキュメント

- ADR-0015: スキル群を Copilot CLI プラグインとして配布（Accepted, amended by ADR-0017）
- ADR-0016: template ワークフローの再設計（Accepted）
- ADR-0017: ローカル開発時のプラグイン登録方式を `copilot plugin marketplace add <path>` に修正（Accepted）
- ADR-0018: 中規模以上 / 複数解決策の作業着手前に brainstorming skill 必須化（Proposed, retrospective 由来）
- Retrospective: `docs/retrospectives/2026-05-05-plugin-distribution.md`
- ハンドオフ前段: `docs/handoff/master.md`

## 完了済みタスク

- [x] ADR-0015 起票・承認・コミット（`610b2b1`, `ed06ff3`）
- [x] `.claude-plugin/{plugin,marketplace}.json` 作成
- [x] README に「Copilot CLI へのインストール」節追加
- [x] ADR-0016 起票・承認・コミット（`577c029`, `95eb4c2`）
- [x] `template.manifest` から skills/ エントリを除外、template/ 再生成
- [x] ルート `.github/copilot-instructions.md` に「前提条件」節を追加
- [x] CONTRIBUTING.md のスキル変更手順を更新
- [x] **ADR-0017 起票・承認・コミット（`6dc9da8`, `72db1ac`）**: dev-link 方式が CLI に認識されない原因（`Marketplace "local" not found`）を特定、`copilot plugin marketplace add <local-path>` を正規手順に
- [x] dev-link.{ps1,sh} 削除、README 改訂（A: GitHub / B: ローカル directory 両方式）、ADR-0015 を amended に更新
- [x] 環境後始末: `~/.copilot/settings.json` の `ai-driven-dev-principles@local` エントリ削除、`local/ai-driven-dev-principles` junction 削除
- [x] **master へ `--no-ff` マージ + push 完了**（merge: `a92dc81`）
- [x] **方式 A への切替実証**: `marketplace remove --force` → `marketplace add taika-izumi/ai-driven-dev-principles` → `install` を実行し、private リポでの GitHub source インストールが動作することを確認
- [x] **retrospective 実施**: `docs/retrospectives/2026-05-05-plugin-distribution.md` 作成、rubber-duck レビュー反映
- [x] **ADR-0018 起票（Proposed）**: retrospective 採用提案 #1（brainstorming 必須化）を ADR 化

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`
2. **最初に着手すべきタスク**: **ADR-0018 の実装**（中規模以上 / 複数解決策の作業着手前に brainstorming skill 必須化）
   - 影響範囲: `.github/copilot-instructions.md`（メタ・ガイドライン「要求の深堀り」追加）+ `skills/start-work/SKILL.md`（Phase 2 マッピング表更新）
   - 「中規模以上」の定義: `feature-block-design` skill の閾値（主要機能2つ以上、または想定モジュール3つ以上）を流用
3. **副次タスク**:
   - **ADR-0017 補足セクション更新**: 「方式 A は未検証」の記述を、本サイクルで動作実証済みである旨に書き換える
   - retrospective 提案 #2（セッション跨ぎ検証チェックリスト）— 継続観察、再発時に採用昇格
   - retrospective 提案 #3（pre-action-review への組み込み妥当性検討）— バックログ。brainstorming 導入後に統合検討
   - retrospective 提案 #4（ADR ステータス語彙に Amended 追加）— 次回 ADR amend 発生時に再検討
4. **留意点**:
   - master 直接作業禁止
   - skills 編集後は `copilot plugin update ai-driven-dev-principles` を忘れない（CLI install はコピー方式のため）
   - GitHub source 経由 install に切替済のため、ソースフォルダ移動・削除しても install 済み skill は動く

## 重要な意思決定の履歴

- ADR-0015: スキル群を Copilot CLI プラグインとして配布（2026-05-04, Accepted, amended by ADR-0017）
- ADR-0016: template ワークフローの再設計（2026-05-04, Accepted）
- ADR-0017: ローカル開発時のプラグイン登録方式を `copilot plugin marketplace add <path>` に修正（2026-05-04, Accepted）
- ADR-0018: 中規模以上 / 複数解決策の作業着手前に brainstorming skill 必須化（2026-05-05, Proposed）

