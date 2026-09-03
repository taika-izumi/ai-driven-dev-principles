# create — 新規ハンドオフ作成

`session-handoff` の create 操作の正本。

呼ばれるタイミング: `start-work` の Phase 1（handoff 不在で新規作業開始時）

手順:
1. SKILL.md「ハンドオフファイルのフォーマット」節に沿って新規ファイルを作成する
2. 最低限以下を埋める:
   - Branch, Last Updated, Status (in_progress), Current Phase
   - 作業の目的・背景（ヒアリング結果）
   - 関連ドキュメント（あれば）
3. 完了/進行中/未着手のタスクは空でも可（更新で埋める）
4. ファイルを git に add するが、コミットは update（`op-update.md`）/ finalize（`op-finalize.md`）にゆだねる
