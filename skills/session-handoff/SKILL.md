---
name: session-handoff
description: "セッション間で作業を継続するためのハンドオフファイル（docs/working/handoff/<branch>.md）を読む・作成する・更新する・確定する。マイルストーン到達時とセッション終了時に呼ばれる。"
---

# session-handoff

セッション間の作業引き継ぎファイルを管理するスキル。

## ファイル配置

```
docs/working/handoff/<branch-name>.md
```

- ブランチ名のスラッシュは `_` に置換する（例: `feature/auth-flow` → `feature_auth-flow.md`）
- main/master ブランチでも作成可能
- git管理対象（コミットして履歴を残す）

## ハンドオフファイルのフォーマット

```markdown
# Handoff: <作業タイトル>

- **Branch**: <branch-name>
- **Last Updated**: YYYY-MM-DD HH:MM (Asia/Tokyo)
- **Status**: in_progress | paused | completed
- **Current Phase**: <作業タイプ>/<現在のスキル or 段階>

## 作業の目的・背景

（このブランチで何を達成しようとしているかの要約。1-3段落）

## 関連ドキュメント

- Spec: `docs/specs/...`
- Plan: `docs/plans/...`
- 関連ADR: ADR-NNNN, ADR-NNNN

## 完了済みタスク

- [x] タスクA（YYYY-MM-DD 完了）

## 進行中のタスク

- [ ] **現在の作業**: タスクC
  - 状態: <どこまでやったか>
  - 残り: <次に何をすべきか>

## 未着手のタスク

- [ ] タスクD

## 既知のブロッカー・懸念

（なし、または箇条書き）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: ...
2. 最初に実行すべきコマンド/スキル: ...
3. 留意点: ...

## 重要な意思決定の履歴

- ADR-NNNN: <タイトル>（YYYY-MM-DD）
```

## 操作

このスキルは4つの操作を提供する。呼び出し側は操作を明示すること。

### 1. read — ハンドオフ読み込み

呼ばれるタイミング: `start-work` の Phase 0（セッション継続チェック）

手順:
1. 現在のブランチ名を取得する: `git branch --show-current`
2. ブランチ名のスラッシュを `_` に置換し、ファイルパス `docs/working/handoff/<branch>.md` を組み立てる
3. ファイルが存在しなければ「ハンドオフなし」と呼び出し側に返す
4. 存在すれば内容を読み込み、以下の要素を抽出して要約をユーザーに提示する:
   - 作業の目的
   - 進行中タスク（状態と残り）
   - 次セッション開始時のアクション
5. ユーザーに「前回の続きから始めますか?」と確認する

### 2. create — 新規ハンドオフ作成

呼ばれるタイミング: `start-work` の Phase 1（handoff 不在で新規作業開始時）

手順:
1. 上記フォーマットに沿って新規ファイルを作成する
2. 最低限以下を埋める:
   - Branch, Last Updated, Status (in_progress), Current Phase
   - 作業の目的・背景（ヒアリング結果）
   - 関連ドキュメント（あれば）
3. 完了/進行中/未着手のタスクは空でも可（更新で埋める）
4. ファイルを git に add するが、コミットは update/finalize にゆだねる

### 3. update — マイルストーン更新

呼ばれるタイミング: 各スキル完了後、plan の 1 タスク完了時、その他マイルストーン到達時

手順:
1. 既存ファイルを読み込む
2. Last Updated を現在時刻（Asia/Tokyo）に更新する
3. Current Phase を最新の状態に更新する
4. 完了したタスクを「完了済みタスク」セクションに移動する
5. 進行中のタスクの「状態」「残り」を最新化する
6. 重要な意思決定があれば「重要な意思決定の履歴」に ADR 番号を追記する
7. 既知のブロッカーがあれば追記する
8. ファイルを上書き保存する（コミットはセッション終了時、または明示的なコミットタイミングで実施）

### 4. finalize — セッション終了確定

呼ばれるタイミング: ユーザーが「ここまで」「続きは別セッションで」と明示した時、または明らかなセッション終了サイン時

手順:
1. update と同様の更新を実施
2. **「次セッション開始時のアクション」セクションを必ず埋める**:
   - 最初に確認すべきファイル
   - 最初に実行すべきコマンド/スキル
   - 留意点
3. Status を更新する（作業継続なら `paused`、完了なら `completed`、まだ進行中なら `in_progress`）
4. ファイルを git に add してコミットする:

   ```powershell
   git add docs/working/handoff/<branch>.md
   git commit -m "chore: update handoff for <branch>"
   ```

## 完了済みハンドオフの扱い

PR マージなどで作業完了した handoff は `Status: completed` のまま `docs/working/handoff/` に残す。アーカイブ機構（`docs/working/handoff/archive/` への移動）は本スキルでは未実装。将来必要になれば追加する。

## 対応する原則

- 原則1（追跡可能性）: 作業状態と次のステップを記録に残し、後続の作業者が継続可能にする
- 原則3（コンテキスト管理）: セッション間でコンテキストを明示的に引き継ぐ
