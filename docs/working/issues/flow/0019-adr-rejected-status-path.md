# Issue-0019: コミット済み Proposed ADR を不採用で終える経路（Rejected）が未定義

- **Status**: closed
- **Opened**: 2026-07-06
- **Closed**: 2026-07-07
- **起票元**: 2026-07-06 セッション終了時のユーザー質問（ADR 破棄運用の確認）
- **関連**: `skills/decision-log/SKILL.md`、ADR-0019（記述規律）、原則1（追跡可能性）、handoff 未着手タスク「ADR-0013/0014/0018 の Proposed 据え置き解消」

## 課題内容

`decision-log` スキルには Accepted 後の破棄・置換手順（`Deprecated` / `Superseded by ADR-XXXX`、理由を Consequences へ追記）が定義されている一方、**コミット済みの Proposed ADR を「不採用」で終える経路が未定義**。現行の「却下」手順はファイルとインデックスエントリの削除を指示しており、これはコミット前のドラフトにのみ適切で、コミット済み ADR に適用すると「なぜ採用しなかったか」の記録が消え、原則1（追跡可能性）と矛盾する。

一般的な ADR 運用（MADR 等の標準テンプレート）では、不採用の提案は削除せず `Rejected` ステータスで残すのが通例（同じ案が再浮上したときの再検討コストを下げる）。本ガイドラインにはこの語彙と手順がない。

あわせて、`start-work` の Post チェックは Proposed の「昇格漏れ」のみを見ており、**不採用方向の見直しを促すトリガーがない**。据え置き中の ADR-0013/0014/0018 の棚卸しで「不採用」と判断された場合、現行手順では着地できない。

なお台帳の現状（2026-07-06 実測）: Accepted 36件 / Proposed 3件。Deprecated / Superseded / Rejected の適用実績はゼロ（Accepted 後の破棄手順は定義済みだが未運用）。

## 検討状況

- 2026-07-07: 対策サイクル（feature/adr-rejected-status-path）で対応。Rejected 経路と終端ステータスの意味境界を `decision-log` に定義、`start-work` の Post チェックを不採用方向へ対称化、Superseded の置換対象特定手順（変更箇所起点の2経路）と台帳監査を定義。初回台帳監査（全40件: 実質置換・廃止0件、部分修正注記7件）と据え置き Proposed 3件の処遇確定（0013/0014/0018 いずれも Rejected、0013 のテーマは Issue-0021 へ再起票）まで実施

## 結論

ADR-0041（Rejected 経路の定義）/ ADR-0042（Superseded の変更箇所起点特定と台帳監査）として規範化し、初回適用まで完了（closed）
