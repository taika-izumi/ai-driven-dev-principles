# Issue-0156: 独立試験のSbxRuntimeV3群の所要時間が約11分から約77分に延びた

- **Status**: open
- **Opened**: 2026-09-18
- **起票元**: `docs/records/retrospectives/system/2026-09-18-isolated-verification.md` 課題#2
- **関連**: `scripts/verification/tests/SbxRuntimeV3.Tests.ps1` / `scripts/verification/README.md`「部品の独立試験」（所要の記載）/ `tests/fixtures/FakeSbx.ps1`

## 課題内容

2026-09-18の実行でSbxRuntimeV3群が4593秒かかり、READMEに記載した2026-09-16実測（約11分）の約7倍になった。原因は未調査（実行したセッションの違い、偽sbxの起動時間、ホストの負荷などが候補）。独立試験1回が約1時間40分になり、再実行の費用が増える。詳細は起票元を参照。

## 検討状況

- 2026-09-18: 起票。対策の採否は次サイクル以降の利用者判断
- 2026-09-20: ADR-0206により隔離検証は試作で止め、追加投資をしない。本課題は保留とし、隔離検証を再開するとき（ADR-0205の再検討条件、開始は利用者の指示）に扱う

## 結論

（open）
