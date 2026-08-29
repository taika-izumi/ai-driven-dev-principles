# Retrospective: 前提実在観点の新設と前提検査規範の追加（LoopForAlpha Issue-0125 還流）

- **Subject**: 確定前レビューへの前提実在観点の常設と、指摘採否・提示・設計記述への前提と実在の検査の追加（ADR-0117）
- **Branch**: feature/premise-existence-review（取り込み方式: マージコミット 52551b3）
- **Period**: 2026-08-29 〜 2026-08-30
- **Plan**: docs/working/plans/2026-08-29-premise-existence-review-implementation.md
- **Spec**: なし（spec 確定点 (c) 型。ADR-0117 が設計文書を兼ねる）
- **Related ADRs**: ADR-0117（新規・Accepted）、ADR-0080/0107（部分修正注記）、ADR-0063/0067（注記）
- **Facilitator**: メインエージェント (claude-fable-5)

## 1. 達成サマリ

- LoopForAlpha の flow 課題（`LoopForAlpha#Issue-0125`）が実測した設計ミス 2 種（実証つき指摘の前提検査なし採用・実体を読まない設計記述）を塞ぐ改修 4 点（提案 2-1〜2-4）を採用し、ADR-0117 として設計確定（`0f4b5f5`。提案 2-5〈レイヤ第 3 分類〉は見送り・振り分け指針 1 文で代替）
- ADR-0117 の確定前レビュー: フル巡 2〈4 観点・claude-opus-5 各 4 体〉→ 設計縮小（採否記録義務の撤回・delta 基準化）→ 差分確認巡 1 で実質収束。plan 確定点はフル巡 1＋差分確認巡 1 で実質収束（`f8f09e8`）
- 実装: `pre-finalization-review`（4 観点化・手順 5 前提検査・3-2 (b) 探索先併記・適用例節新設ほか 12 編集）/ `subagent-dispatch`（手順 6 受け取り時義務）/ `feature-block-design`（Phase 2〜4 実体読み直し）＋ README・現行 spec 3 件・ADR 注記 5 件・plugin 0.1.14・dist 再生成を同一コミットへ（`6cfa1b5`。検証 grep 13 本・両 -Check・配布物目視すべて合格）
- worklog 中央ストア台帳へ `LoopForAlpha-2026-08-29-01`〜`-03` = adopted→merged・`-04`/`-05` = deferred の 8 行を記入（冪等ガードつき）
- ADR-0117 Accepted 昇格（`1c5e66f`。サイクル全体整合検査 5 観点 指摘なし）→ master へ --no-ff マージ（`52551b3`）

## 2. 課題（対象システム固有）

（新規課題なし。実装は plan の忠実実行で欠陥・手戻りの観測なし）

> 開発フロー課題 0 件（flow/ ファイルは作成しない）。worklog 送りとした delta 型候補 0 件（全マイルストーンで delta なし・消化記録と整合）。

## 3. 既存課題の再発・進展

- Issue-0103: ADR-0117 が 4 観点化のコスト材料を記録（4 観点目 1 体あたり概算 20〜25 万トークン/巡・3 観点並走比で 1 巡 +30% 程度の見積り。4 体構成の実測は無い）。予算基準の不在は未解決のまま観点数が増えた
- Issue-0105: `pre-finalization-review/SKILL.md` が 30.4KB → 34.2KB（+3.8KB）。前サイクルで分割した start-work の分割前サイズ（34.7KB）とほぼ同水準に到達
