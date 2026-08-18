# Issue-0106: 改訂前退避領域の命名規約・掃除規定が無い

- **Status**: open
- **Opened**: 2026-08-18
- **起票元**: `docs/records/retrospectives/flow/2026-08-18-issue-0098-iterative-review-criteria.md` 課題#3
- **関連**: ADR-0107 決定 3、`skills/pre-finalization-review/SKILL.md`「反復の実施」（改訂前退避）

## 課題内容

確定前レビュー反復の改訂前退避は恒久領域（`<home>/.ai-dev-review-snapshots/`）を第一選択とするが、規約が定めるのは場所のみで、ディレクトリ・ファイルの命名規約と保持期間・削除時期の定めが無い。2026-08-18 のサイクルで 5 世代（計約 250KB）が残置し、領域は単調増加する。同名 basename（複数ブランチの SKILL.md 等）の衝突リスクもある。ライフサイクル規約の設計は次サイクル以降のユーザー判断。

## 検討状況

- 2026-08-18: 起票。

## 結論

（open）
