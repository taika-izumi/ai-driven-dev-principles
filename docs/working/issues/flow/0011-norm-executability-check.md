# Issue-0011: 規範・ADR のエージェント実行可能性を確認する観点が定式化されていない

- **Status**: closed
- **Opened**: 2026-07-05
- **Closed**: 2026-07-05
- **起票元**: retrospectives/flow/2026-07-05-question-tool-display-norm.md 課題#1
- **関連**: ADR-0029、decision-log スキル、CONTRIBUTING.md

## 課題内容

規範・ルール・ADR を起草する際に「その判定条件・動作をエージェントが実際に観測・実行できるか」をチェックする観点がガイドライン（decision-log スキル / CONTRIBUTING のチェックリスト）に定式化されておらず、実行不能な規範の混入がユーザーレビュー頼みになっている（要約。詳細は起票元参照）。

## 検討状況

2026-07-05: 対策サイクル feature/record-process-norms で対策を設計・実装

## 結論

ADR-0032（規範・ADR の判定条件はエージェントが観測・実行可能な事実で書く）として規範化し、decision-log / CONTRIBUTING に反映済み。
