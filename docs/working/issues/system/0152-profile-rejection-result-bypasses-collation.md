# Issue-0152: 実行設定（profile）の拒否が照合を通らない失敗結果になり、仕様03と食い違う

- **Status**: open
- **Opened**: 2026-09-18
- **起票元**: 隔離検証v3の最終レビューで繰り延べた指摘（`.superpowers/sdd/2026-09-14-isolated-verification-v3-implementation/final-fix-findings.md`「繰り延べ」2項目め）。統合前に利用者が3件への分割起票を選択（2026-09-18）
- **関連**: `scripts/verification/Invoke-IsolatedVerification.ps1` の profile 検査段（`error: profile:` を出して `New-VerificationFailureResult` を返す箇所）/ 仕様03「対象と責務」（準備が正常なら失敗も3入力照合へ渡す）・「結果の契約」（scope付与前の固定入力記録の再照合）/ ADR-0198（期限到達時の照合経路）

## 課題内容

CLI は準備（PreparedRunV3 の作成）に成功した後、replay/proposal の profile を `Test-VerificationRuntimeProfile` で検査する。ここで拒否されると、`New-VerificationFailureResult` による失敗結果（status=blocked、stage=profile）を直接返し、`Complete-VerificationRun` の照合を通らない。

仕様03は「PreparedRunV3が正常なら、Proposalの失敗も通常の3入力照合へ渡す」と定め、New-VerificationFailureResult を使うのは正常な PreparedRunV3 を作れない場合としている。現状の経路は、準備が正常なのに照合を省く形で、固定入力記録の再照合や scope の付与を経ない結果が保存される。VM は作らないため、同時1台や停止の保護には影響しない。

## 対策候補（未採用）

- profile 拒否を Proposal の blocked（VM 未作成）として扱い、Replay の not_run → 照合へ渡す（ADR-0198 と同じ形）
- 仕様03を改め、profile 検査を「準備の一部」と定義して現在の実装に合わせる

## 検討状況

- 2026-09-18: 起票。試作の範囲では VM 未作成の blocked で実害がなく、修正にはランナー再実行（約26分）と再レビューが伴うため、今回の統合では変更しない。対策の採否は次サイクル以降の利用者判断
- 2026-09-20: ADR-0206により隔離検証は試作で止め、追加投資をしない。本課題は保留とし、隔離検証を再開するとき（ADR-0205の再検討条件、開始は利用者の指示）に扱う

## 結論

（open）
