# Handoff: スキル群の Copilot CLI プラグイン化 + template ワークフロー再設計

- **Branch**: feature/plugin-distribution
- **Last Updated**: 2026-05-04 13:15 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 実装完了、次セッションで検証 → マージ → 設定切替の流れ

## 作業の目的・背景

本リポジトリの `skills/` 配下に置かれた独自スキルが Copilot CLI の `skill:` ツールから認識されない問題を、リポジトリ自体をプラグイン化することで解決する（ADR-0015）。さらに、プラグイン経由でスキルが配信されるなら template/ に skills/ を含める意味は薄く、二重管理コストを削減するため template ワークフローを再設計する（ADR-0016: skills/ を template から除外し、プラグイン一本化）。

## 関連ドキュメント

- ADR-0015: スキル群を Copilot CLI プラグインとして配布（公式プラグイン化 + dev-link ハイブリッド）
- ADR-0016: template ワークフローの再設計（skills/ を除外し、プラグイン一本化）
- ハンドオフ前段: `docs/handoff/master.md`

## 完了済みタスク

- [x] ADR-0015 起票・承認・コミット（`610b2b1`）
- [x] `.claude-plugin/{plugin,marketplace}.json` 作成（`ed06ff3`）
- [x] `scripts/dev-link.{ps1,sh}` 作成（`ed06ff3`）
- [x] README に「Copilot CLI へのインストール」節追加（`ed06ff3`）
- [x] dev-link.ps1 ローカル実行 → junction 作成成功
- [x] `~/.copilot/settings.json` の enabledPlugins に `ai-driven-dev-principles@local: true` を追記
- [x] ADR-0016 起票・承認・コミット（`577c029`）
- [x] `template.manifest` から skills/ エントリを除外（`95eb4c2`）
- [x] `template/` を再生成（skills/ 削除、3ファイル + ADR索引のみ）
- [x] ルート `.github/copilot-instructions.md` に「前提条件」節を追加
- [x] CONTRIBUTING.md のスキル新規作成手順を更新（template.manifest に追加しない方針へ）

## 進行中のタスク

なし（feature ブランチでの実装作業は一段落）

## 未着手のタスク

- [ ] **検証**: Copilot CLI 再起動後、`/env` で `ai-driven-dev-principles` プラグインのスキル群が認識されているか確認。`skill: "start-work"` 等が呼べるか試行
- [ ] **マージ + push**: 検証 OK なら feature/plugin-distribution を master へマージし、GitHub に push
- [ ] **設定切替**（ユーザー希望）: push 完了後、`~/.copilot/settings.json` を以下に変更
  - 削除: `"ai-driven-dev-principles@local": true`
  - 追加: `extraKnownMarketplaces.ai-driven-dev-principles = { source: { source: "github", repo: "taika-izumi/ai-driven-dev-principles" } }`
  - 追加: `"ai-driven-dev-principles@ai-driven-dev-principles": true`
  - その後 `/plugin install` で公開スナップショットをダウンロード
- [ ] **dev-link 後始末**: `~/.copilot/installed-plugins/local/ai-driven-dev-principles` junction の扱い（残しておけば本リポ開発時に再有効化可能、削除なら `Remove-Item -Recurse -Force`）
- [ ] **retrospective 実施**: master マージ後、本サブプロジェクト（plugin 化）の振り返りを `docs/retrospectives/YYYY-MM-DD-plugin-distribution.md` に記録
- [ ] **既存テンプレ利用先への移行ガイド**（必要なら）: 過去に template/ を copy 済のプロジェクトで `skills/` ディレクトリの扱い

## 既知のブロッカー・懸念

- 本セッション内では Copilot CLI 再起動できないため、`skill:` ツールでの認識は次セッションで確認
- `extraKnownMarketplaces` から GitHub install 経路は本リポジトリが GitHub に push されていないと使えない。順序: マージ → push → 設定切替
- repository URL: README で `taika-izumi/ai-driven-dev-principles` を使ったが、実 push 先 remote 名が異なる場合は要修正
- `docs/conversation_log.md` および `docs/images/` が untracked のまま残存（master 由来の作業外ファイル）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`
   - 認識成功なら `skill: "start-work"` で起動
   - 認識失敗（依然として "not found"）なら、SKILL.md を view で読んで手動適用しつつ原因調査
2. **最初に確認すべきファイル**:
   - 本ファイル `docs/handoff/feature_plugin-distribution.md`
   - `docs/decisions/0015-distribute-skills-as-copilot-cli-plugin.md`
   - `docs/decisions/0016-redesign-template-workflow-plugin-only.md`
3. **最初に実行すべきコマンド**:
   - `/env` でプラグイン認識状態を確認
   - `git --no-pager log --oneline -10` で feature ブランチのコミット履歴を確認
4. **次に進める作業の判断分岐**:
   - 認識 OK → master へマージ → push → ユーザーに「設定切替へ進むか」確認 → retrospective
   - 認識 NG → systematic-debugging で原因調査（plugin.json スキーマ、ディレクトリ構造、settings.json typo 等）
5. **留意点**:
   - master 直接作業禁止
   - dev-link junction は残しておくと開発時に便利（削除は任意）
   - 前回（サブプロジェクトC）の retrospective で出た Improvement Drafts #3〜#5 の継続観察も並行して継続

## 重要な意思決定の履歴

- ADR-0015: スキル群を Copilot CLI プラグインとして配布（公式プラグイン化 + dev-link ハイブリッド）（2026-05-04, Accepted）
- ADR-0016: template ワークフローの再設計（skills/ を除外し、プラグイン一本化）（2026-05-04, Accepted）

