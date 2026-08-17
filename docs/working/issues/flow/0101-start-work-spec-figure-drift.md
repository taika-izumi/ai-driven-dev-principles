# Issue-0101: start-work 旧設計仕様書の図示が現行 SKILL.md から乖離している

- **Status**: open
- **Opened**: 2026-08-17
- **起票元**: ADR-0106 実装サイクル（確定前レビューの実装整合性観点が乖離を実測）
- **関連**: `docs/current/specs/2026-04-25-record-strengthening-design.md`、`skills/start-work/SKILL.md`

## 課題内容

`docs/current/specs/2026-04-25-record-strengthening-design.md` の Phase 2 マッピング表・横断的ラッパーの図示が現行 `skills/start-work/SKILL.md` と乖離している（表は 7 行のみで現行 13 行＋完了処理行に未追従。Pre の subagent-dispatch 条項・完了処理条項も未反映）。仕様書のスナップショット規約に照らし、書き換え更新か、図示の削除（SKILL.md への参照化）かの判断が要る。ADR-0106 実装では意図的に同期対象へ含めなかった（既存乖離が大きく、部分同期はかえって不整合を生むため）。

## 検討状況

- 2026-08-17: 起票。対策の採否・設計は次サイクル（ユーザー判断）

## 結論

（open）
