# Issue-0009: ADR ドラフトの起票タイミングが「即時」ルールと議論の収束度で緊張する

- **Status**: closed
- **Opened**: 2026-07-05
- **Closed**: 2026-07-05
- **起票元**: retrospectives/flow/2026-07-05-retrospective-issue-integration.md 課題#1
- **関連**: ADR-0006、ADR-0019

## 課題内容

「検出→即ドラフト」（ADR-0006）が、brainstorming 中の関連論点が未収束の段階でも ADR の起票・コミットまで促し、コミット中断・書き直しの手戻りが生じた（要約。事象/原因/影響の詳細は起票元参照）。

## 検討状況

2026-07-05: 対策サイクル feature/record-process-norms で対策を設計・実装

## 結論

ADR-0030（ADR ドラフトは即時作成・コミットは論点収束チェックポイントまで遅延可能とする）として規範化し、decision-log / CLAUDE.md / start-work に反映済み。
