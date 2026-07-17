# Issue-0024: プラグイン更新後の新規スキル availability 確認手順が start-work Phase -1 に未組み込み

- **Status**: open
- **Opened**: 2026-07-17
- **起票元**: `docs/records/retrospectives/flow/2026-07-17-worklog-skill-pipeline.md` 課題#2
- **関連**: `skills/start-work/SKILL.md`（Phase -1 依存検出）、ADR-0047

## 課題内容

本サイクルでプラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）を実施した後、Claude Code の `/skills` UI 一覧には本セッション内で新規追加スキル（`worklog-*` 3 スキル）が反映されなかったが、AI エージェント側の Skill ツール availability（system-reminder に含まれる available-skills 一覧）にはセッション内で反映済みだった。UI/API 間で経路差がある。

現行 `start-work` の Phase -1（依存検出）は superpowers スキルの有無を確認するが、**「本セッションで新規追加された ai-driven-dev-principles スキルの availability 判定手順」は明示されていない**。私は最初「UI /skills 表示の有無」でユーザーに確認依頼したが、system-reminder の available-skills を先に見れば一往復のやりとりを省けた。

プラグイン更新→スキル追加のたびに、この確認往復が発生する運用オーバーヘッドが積み上がる。start-work Phase -1 に「新規追加スキルは AI 側 availability（system-reminder / Skill ツール呼び出し可否）で判定する」規範を組み込めば、堅牢になる。

詳細（事象/原因/影響）は起票元の振り返りファイルが正。

## 検討状況

（未着手）

## 結論

（open）
