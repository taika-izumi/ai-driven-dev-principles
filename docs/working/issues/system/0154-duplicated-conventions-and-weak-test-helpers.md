# Issue-0154: 同じ約束事の写しと試験補助の重複・弱い assert が残る

- **Status**: open
- **Opened**: 2026-09-18
- **起票元**: 隔離検証v3の最終レビューで繰り延べた指摘（`.superpowers/sdd/2026-09-14-isolated-verification-v3-implementation/final-fix-findings.md`「繰り延べ」3・4項目め）。統合前に利用者が3件への分割起票を選択（2026-09-18）
- **関連**: `scripts/verification/*.psm1`・`Invoke-IsolatedVerification.ps1` / `scripts/verification/tests/`（SbxRuntimeV3・ProposalV3・ResultV3 と `fixtures/V3TestContext.psm1`）

## 課題内容

製品側では、同じ約束事が複数か所に写されている。

- 受け入れ済み制限の定数、停止証拠の読み取り、JSON 読み込み、ツリー列挙、テストのパス対応、mode と役割の対応表
- 固定入力記録の読み方の厳格さがモジュール間で異なる
- 準備失敗で結果の保存に失敗した場合、stdout の runRoot が null になる
- v1 の照合経路でも SbxRuntime を読み込む

試験側では次が残る。

- 試験の組み立て補助の重複（SbxRuntimeV3・ProposalV3 と V3TestContext で約120行）
- status だけを確かめる assert、Assert-NoLeftover のラベルと実際の検査の違い、keepAlive の弱い確認、schema 違反の原因を区別しない assert
- ResultV3 の9文字のケース名、未使用変数、3MiB の出力洪水（所要時間）、synthetic 応答の出所の記載

写しは、将来の変更で片方だけが直されてずれる危険がある（タスク6で実際にずれが起き、一部を統合した前例がある）。

## 対策候補（未採用）

- 写しを RequestCopy.psm1 の公開関数などへ集約し、各モジュールから参照する
- 試験補助を fixtures へ移し、弱い assert を理由・原因まで確かめる形にする

## 検討状況

- 2026-09-18: 起票。動作と保護には影響せず、集約にはランナー再実行と再レビューが伴うため、今回の統合では変更しない。対策の採否は次サイクル以降の利用者判断

## 結論

（open）
