# Issue-0022: ADR 起票時に粒度（1決定=1ADR）を確認する観点がない

- **Status**: open
- **Opened**: 2026-07-07
- **起票元**: `docs/records/retrospectives/flow/2026-07-07-adr-rejected-status-path.md` 課題#1
- **関連**: `skills/decision-log/SKILL.md`（ADR作成手順）、ADR-0019（記述規律）、ADR-0041/0042（レビュー指摘により1決定=1ADRへ分割した実例）

## 課題内容

ADR-0041 の初版に複数の独立した決定（Rejected 経路の定義 / Superseded の置換特定と台帳監査）と実行計画を束ねて起票し、ユーザーレビューで分割となった。`decision-log` の作成手順には「1つの ADR に収める決定の単位」を確認する観点がなく、「1サイクル=1ADR」の慣性で束ねやすい。束ねた大型 ADR は将来の部分修正（一部だけ置換される状態）を増やし、台帳のステータス管理を悪化させる。

詳細（事象/原因/影響）は起票元の振り返りファイルが正。

## 検討状況

（未着手）

## 結論

（open）
