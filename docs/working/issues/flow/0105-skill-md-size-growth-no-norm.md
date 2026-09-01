# Issue-0105: SKILL.md のサイズ・分割規範が無い

- **Status**: closed
- **Opened**: 2026-08-18
- **Closed**: 2026-09-01
- **起票元**: `docs/records/retrospectives/flow/2026-08-18-issue-0098-iterative-review-criteria.md` 課題#2
- **関連**: ADR-0087（handoff 側のサイズトリガー）、`skills/` 全域

## 課題内容

スキルファイルにはサイズの目安値・分割/移設の規約が無く、規範追加が常に既存スキルへの追記になる。2026-08-18 のサイクルで start-work +43%（34.9KB）・session-handoff +27%（30.6KB）・pre-finalization-review +84%（13.8KB）と伸び、上位 3 スキルが 26KB 超。session-handoff は Post ラッパーで毎マイルストーン読まれるため、肥大はセッションのコンテキスト費用へ反復的に効く。start-work では 1 節（確定前レビューの提示規則）がファイルの約半分を占める偏りも観察された。目安値の設定・分割単位の設計は次サイクル以降のユーザー判断。

## 検討状況

- 2026-08-18: 起票。
- 2026-08-28: start-work を分割（ADR-0115/0116）。提示規則 16,771B を pre-finalization-review へ、マージ方式確認 4,270B を references/merge-practice.md へ移設。分割前 34,676B → 分割後 14,456B（確定点到達セッションの合計は 44,850B）。一般規範の設計は本サイクルでも見送り（分割の実例 1 件を判断材料として追加）。Status は open のまま。
- 2026-08-30: ADR-0117 実装で pre-finalization-review が 30,393B → 34,193B（+3.8KB。4 観点化・前提検査・適用例節ほか 12 編集）。start-work の分割前サイズ（34,676B）とほぼ同水準に到達し、次に同スキルへ追記するサイクルで分割判断が発生しうる。
- 2026-08-31: ADR-0120 実装で pre-finalization-review が 34,193B → 42,643B（+24.7%。2 型分類・分布外検知・体数型別既定ほか 8 編集）。start-work の分割前サイズ（34,676B）を超過した。分割判断の発生条件（前行）が成立した状態。
- 2026-09-01: ADR-0121 でサイズ・分割の一般規範を導入（build-dist のサイズ警告＋目安値 20KB＋例外テーブル、CONTRIBUTING の全シナリオ共通節、pre-finalization-review の references 型分割）。残余（session-handoff / decision-log の分割）は Issue-0115 / Issue-0116 で追跡する

## 結論

ADR-0121。残余の分割候補は Issue-0115 / Issue-0116 へ分離した。
