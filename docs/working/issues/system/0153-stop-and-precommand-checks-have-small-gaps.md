# Issue-0153: 停止確認と実行直前の検査に細かな抜けが残る

- **Status**: open
- **Opened**: 2026-09-18
- **起票元**: 隔離検証v3の最終レビューで繰り延べた指摘（`.superpowers/sdd/2026-09-14-isolated-verification-v3-implementation/final-fix-findings.md`「繰り延べ」1項目め）。統合前に利用者が3件への分割起票を選択（2026-09-18）
- **関連**: `scripts/verification/SbxRuntime.psm1`（`Stop-VerificationSandboxEntry`・`Assert-VerificationSandboxUnchanged`・VM作成時のID確定・所有者調整）/ `scripts/verification/proposal-export.py` / 仕様02「実行設定と起動前確認」「提案書式と回収」/ ADR-0193

## 課題内容

最終レビュー時点で次の4点が指摘され、保護条件を崩さない細部として繰り延べた。

1. 停止確認のループで、`ls --json` を照会するたびに当該VMが running に戻っていないかを再確認していない（stopped の観測で確認を終えるため、途中の再起動を区別しない）。
2. 搬入したファイルの所有者調整（chown）の直前に、VM の同一性・デーモン世代の維持確認（`Assert-VerificationSandboxUnchanged`）を呼んでいない。
3. VM 作成後の ID 確定の `ls` が、停止用ではなく作業相の予算で動く（期限間際では ID 確定が作業の残時間に縛られる）。
4. エクスポーターが辿らないリンクに出会った場合も truncated を立てる（拒否の理由が「切り詰め」と区別されない）。

どれも実機試験（タスク8・9）では問題になっておらず、各経路には別の検査（停止記録の照合、実行直前の世代確認、全体期限）がある。

## 対策候補（未採用）

- 1〜3 を各関数で個別に直し、偽sbxに対応する試験を足す
- 4 はエクスポーターの出力にリンク拒否の理由を別に持たせる

## 検討状況

- 2026-09-18: 起票。試作の範囲では他の検査が補っており、修正にはランナー再実行と再レビューが伴うため、今回の統合では変更しない。対策の採否は次サイクル以降の利用者判断

## 結論

（open）
