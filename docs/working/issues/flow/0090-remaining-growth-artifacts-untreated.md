# Issue-0090: 棚卸しで確認した残りの成長型成果物（インデックス 3 種・plans 残置・worklog 台帳）に抑制機構がない

- **Status**: open
- **Opened**: 2026-08-15
- **起票元**: Issue-0088 対策サイクルの棚卸し処分（ADR-0094 の Consequences）
- **関連**: Issue-0088（本体。Issue 部分は ADR-0095〜0097 で対処）、Issue-0045（open 課題の棚卸し工程）、Issue-0087（表の統廃合契機）

## 課題内容

Issue-0088 の棚卸し（2026-08-15 実測）で確認された成長型成果物のうち、Issue 関連以外は本サイクルで対処せず見送った。対象と実測:

- インデックス 3 種（件数増加型）: `docs/working/issues/README.md` 16.8KB / `docs/records/decisions/README.md` 18.4KB / `docs/records/retrospectives/README.md` 24.5KB（Issue ファイル最大値の 2.4 倍）
- plans 残置（件数増加型・完了後も残る）: 31 件・合計 847KB。完了 plan の扱いが未定義
- worklog 台帳: worklog-extract という消費装置はあるが、サイズ・件数を抑制する規約はない

## 対策の方向（採否は未定）

- 再検討の条件は「実害の観測」（読み込み困難・検索性劣化・誤参照などが実際に起きた時）。それまで対策設計に入らない（実測なき規範追加を避ける）
- 対処する場合、handoff / Issue で確立した部品（移設・サイズ実測トリガー・分割）の流用可否から検討する

## 検討状況

- 2026-08-15: 起票（ADR-0094 の棚卸し処分として見送りを記録）
