# Handoff: スキル群の Copilot CLI プラグイン化 + template ワークフロー再設計

- **Branch**: feature/plugin-distribution
- **Last Updated**: 2026-05-04 23:30 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: ADR-0017 適用済、次セッションで skill 認識検証 → マージ → push

## 作業の目的・背景

本リポジトリの `skills/` 配下に置かれた独自スキルが Copilot CLI の `skill:` ツールから認識されない問題を、リポジトリ自体をプラグイン化することで解決する（ADR-0015）。さらに template から skills/ を除外しプラグイン一本化（ADR-0016）。本セッションで dev-link 方式の誤りが判明し、`copilot plugin marketplace add <local-path>` 経由の正規手順へ修正（ADR-0017）。

## 関連ドキュメント

- ADR-0015: スキル群を Copilot CLI プラグインとして配布（Accepted, amended by ADR-0017）
- ADR-0016: template ワークフローの再設計（Accepted）
- ADR-0017: ローカル開発時のプラグイン登録方式を `copilot plugin marketplace add <path>` に修正（Accepted）
- ハンドオフ前段: `docs/handoff/master.md`

## 完了済みタスク

- [x] ADR-0015 起票・承認・コミット（`610b2b1`）
- [x] `.claude-plugin/{plugin,marketplace}.json` 作成（`ed06ff3`）
- [x] README に「Copilot CLI へのインストール」節追加（`ed06ff3`）
- [x] ADR-0016 起票・承認・コミット（`577c029`）
- [x] `template.manifest` から skills/ エントリを除外、template/ 再生成（`95eb4c2`）
- [x] ルート `.github/copilot-instructions.md` に「前提条件」節を追加
- [x] CONTRIBUTING.md のスキル新規作成手順を更新
- [x] **ADR-0017 起票・承認・コミット（`6dc9da8`）**: dev-link 方式が CLI に認識されない原因（`Marketplace "local" not found`）を特定、`copilot plugin marketplace add <local-path>` を正規手順に
- [x] **dev-link.{ps1,sh} 削除、README 改訂、ADR-0015 を amended に更新（`72db1ac`）**
- [x] `~/.copilot/settings.json` の `ai-driven-dev-principles@local` エントリ削除、`local/ai-driven-dev-principles` junction 削除
- [x] `copilot plugin marketplace add D:\Dev\Playground\Playground_MakeAiInstructions` 実行 → 登録成功（source: directory）
- [x] `copilot plugin install ai-driven-dev-principles@ai-driven-dev-principles` 実行 → 7 skills installed

## 進行中のタスク

なし

## 未着手のタスク

- [ ] **検証**: 次セッション開始時に `/env` で `ai-driven-dev-principles` プラグインのスキル群が認識されているか確認。`skill: "start-work"` 等が呼べるか試行
- [ ] **マージ + push**: 検証 OK なら feature/plugin-distribution を master へマージし、GitHub に push
- [ ] **公開後の設定切替**（任意）: GitHub 公開後、ローカル directory ソースから GitHub ソースへ切り替えたい場合は `copilot plugin marketplace remove ai-driven-dev-principles` → `copilot plugin marketplace add taika-izumi/ai-driven-dev-principles` → `copilot plugin update`
- [ ] **retrospective 実施**: master マージ後、本サブプロジェクト（plugin 化）の振り返りを `docs/retrospectives/YYYY-MM-DD-plugin-distribution.md` に記録（dev-link 失敗の教訓を Improvement Drafts へ）
- [ ] **既存テンプレ利用先への移行ガイド**（必要なら）

## 既知のブロッカー・懸念

- 本セッション内では skill 認識を検証不可（available_skills は session 開始時に固定）。次セッションで確認
- repository URL: README で `taika-izumi/ai-driven-dev-principles` を使ったが、実 push 先 remote 名要確認
- `docs/conversation_log.md` および `docs/images/` が untracked のまま残存（master 由来の作業外ファイル）
- 編集即時反映が失われた（dev-link 廃止のトレードオフ）。skills 編集時は `copilot plugin update ai-driven-dev-principles` を実行する必要

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（今回は認識成功するはず）
2. **最初に確認すべきファイル**:
   - 本ファイル
   - `docs/decisions/0017-correct-local-marketplace-registration.md`
3. **最初に実行すべきコマンド**:
   - `/env` でプラグイン認識状態を確認
   - `git --no-pager log --oneline -10` でコミット履歴確認
4. **次に進める作業の判断分岐**:
   - 認識 OK → master へマージ → push → retrospective
   - 認識 NG → 再度 systematic-debugging
5. **留意点**:
   - master 直接作業禁止
   - skills 編集後は `copilot plugin update ai-driven-dev-principles` を忘れない
   - 前回サブプロジェクトの retrospective Improvement Drafts #3〜#5 の継続観察も並行

## 重要な意思決定の履歴

- ADR-0015: スキル群を Copilot CLI プラグインとして配布（2026-05-04, Accepted, amended by ADR-0017）
- ADR-0016: template ワークフローの再設計（2026-05-04, Accepted）
- ADR-0017: ローカル開発時のプラグイン登録方式を `copilot plugin marketplace add <path>` に修正（2026-05-04, Accepted）
