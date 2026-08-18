# Issue-0105: SKILL.md のサイズ・分割規範が無い

- **Status**: open
- **Opened**: 2026-08-18
- **起票元**: `docs/records/retrospectives/flow/2026-08-18-issue-0098-iterative-review-criteria.md` 課題#2
- **関連**: ADR-0087（handoff 側のサイズトリガー）、`skills/` 全域

## 課題内容

スキルファイルにはサイズの目安値・分割/移設の規約が無く、規範追加が常に既存スキルへの追記になる。2026-08-18 のサイクルで start-work +43%（34.9KB）・session-handoff +27%（30.6KB）・pre-finalization-review +84%（13.8KB）と伸び、上位 3 スキルが 26KB 超。session-handoff は Post ラッパーで毎マイルストーン読まれるため、肥大はセッションのコンテキスト費用へ反復的に効く。start-work では 1 節（確定前レビューの提示規則）がファイルの約半分を占める偏りも観察された。目安値の設定・分割単位の設計は次サイクル以降のユーザー判断。

## 検討状況

- 2026-08-18: 起票。

## 結論

（open）
