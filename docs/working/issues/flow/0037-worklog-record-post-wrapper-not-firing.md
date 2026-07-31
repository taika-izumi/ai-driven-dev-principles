# Issue-0037: start-work Post ラッパーの worklog-record 発火が実運用で起きない

- **Status**: open
- **Opened**: 2026-07-31
- **起票元**: `retrospectives/flow/2026-07-31-retrospective-mode-review.md` 課題#1
- **関連**: ADR-0047（worklog-record を start-work Post ラッパーへ配線し全プロジェクトへ伝播）、ADR-0044（記録ゲート）、`skills/start-work/SKILL.md`（Phase 2 横断的ラッパー Post）、`skills/session-handoff/SKILL.md`（update 操作。同一契機で同様に漏れる）、Issue-0036（worklog-extract の単発エントリ扱い。材料が痩せる影響先）

## 課題内容

ADR-0047 は worklog-record を `start-work` の Post ラッパーから、`session-handoff` update と同じマイルストーン契機（スキル完了 / plan の1タスク完了 / 重要な分岐通過）で発火させると定めている。しかし retrospective 再定義サイクル（2026-07-31）では該当契機が最低3回（brainstorming 完了・writing-plans 完了・executing-plans 完了）あったにもかかわらず、発火は 0 回だった。session-handoff update も同じ契機で未実施だった。

原因は、Post ラッパーの規定が `start-work` の SKILL.md にしか存在せず、他スキル（brainstorming 等）へ delegate している間、メインエージェントが「start-work の Phase 2 Post に戻る」契機を持たないこと。delegate 先のスキルは自身の終了条件（次スキルへの遷移など）で完結するため、呼び出し元の横断的ラッパーが素通りされる。

影響として、サイクル中に発生した delta が記録されず worklog-extract の材料が痩せる。本リポジトリ由来の中央ストアエントリは 6 件にとどまっており、パイプラインの入口が実質機能していない。

## 検討状況

- 2026-07-31: retrospective で検出・起票。対策の方向として (a) 各スキルの完了時に呼び出し元へ戻る契機を明示する (b) worklog-record / session-handoff の発火をスキル側の終了ステップに埋め込む (c) 環境側の仕組み（フック等）で発火させる、の案がある。採否・設計は次サイクル（ADR-0021）

## 結論

（open）
