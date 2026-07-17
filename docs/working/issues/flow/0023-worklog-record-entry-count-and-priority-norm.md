# Issue-0023: worklog-record の記録件数規範と複数 delta 候補時の優先順位付けが未明示

- **Status**: open
- **Opened**: 2026-07-17
- **起票元**: `docs/records/retrospectives/flow/2026-07-17-worklog-skill-pipeline.md` 課題#1
- **関連**: `skills/worklog-record/SKILL.md`、`docs/current/specs/2026-07-17-worklog-skill-pipeline/02-skill1-record.md`、ADR-0044、ADR-0045

## 課題内容

`worklog-record` スキルは「1 呼び出し = 1 エントリ記録」を前提と読める記述だが、明示的な「1 件のみ」or「複数記録可」の規範がなく、複数 delta 候補時の優先順位付け（どの候補を選ぶか）も未明示。本サイクルのスモークテスト実施時、本セッションの delta 候補が複数（ADR 追補判断・grep 検証整合順序・プラグイン availability 経路差など）あり、記録する 1 件を絞る判断に一瞬迷った。

実運用開始で節目ごとに複数 delta が発生し、毎回この判断が必要になる。記録の粒度がブレる（節目 A では 1 件、節目 B では別基準で 1 件、など）と、後段の `worklog-extract` のクラスタリング入力の粒度が揃わず、抽出精度に影響する可能性がある。

詳細（事象/原因/影響）は起票元の振り返りファイルが正。

## 検討状況

（未着手）

## 結論

（open）
