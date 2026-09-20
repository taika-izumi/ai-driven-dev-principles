# Issue-0157: 試作で作った停止VM・全体保存のOAuth・VMごとの通信規則の後片付けが未実施

- **Status**: open
- **Opened**: 2026-09-18
- **起票元**: `docs/records/retrospectives/system/2026-09-18-isolated-verification.md` 課題#3
- **関連**: ADR-0199（Consequences: 後片付けは本サイクルの終了時に扱う）/ `docs/records/experiments/2026-09-18-task9-claude-code-roundtrip.md`（全19台の一覧）/ `scripts/verification/README.md`「既知の制約」（`sbx rm` は利用者の承認後）

## 課題内容

統合時点で、停止中のVM19台、`sbx secret` に全体保存したOpenAIのOAuth、VMごとの通信規則が残っている。OAuthは同じデーモン上の全サンドボックスで使える状態のまま。削除は利用者の個別承認を要するため未実施。詳細は起票元を参照。

## 検討状況

- 2026-09-18: 起票。証跡として残す対象と削除する対象の区別、実施の時期は利用者判断
- 2026-09-18: 現状を読取りで確認（停止VM19台、全体保存のOAuth 1件、VMごとの通信規則27件〈kit許可8・local拒否19〉、DockerSandboxes全体約3.1GB）。OAuthは利用者判断で、隔離検証の今後の方針を決めるまで残す。VMと通信規則も利用者判断で、同じく方針決定まで保留（片付け方が方針次第で変わりうるため）
- 2026-09-20: ADR-0206（隔離検証は試作で止める）を受け、利用者が「3種類とも削除する」を選択（「1で」）。実験の結果は `docs/records/experiments/` にコミット済みで、VMを証跡として残す必要はないと判断した。削除は利用者が帰宅後に通常の端末で行う（AIからは実行しない）。手順は下記「削除の手順」

## 削除の手順（利用者の操作。2026-09-20作成）

削除のコマンドの正確な書式は本リポジトリの記録に無い（記録にあるのは `sbx rm`・`sbx secret set openai --oauth`・`sbx policy ls --json` まで）。推測の書式を実行せず、各段で `--help` を先に確認する。sbx・画像の更新、`sbx policy init`、daemonのresetは行わない。

1. 通常の端末でdaemonを起動し、`sbx daemon status` で稼働を確認する。
2. 現状を控える: `sbx ls --json`（19台・すべて停止中のはず）、`sbx policy ls --json`（27件のはず）、`sbx secret --help` で一覧の書式を確認して保存中の秘密を一覧する（OpenAIのOAuth 1件のはず）。件数が違えば削除に進まず、差分を確認する。隔離検証と無関係のVM・秘密・規則があれば対象から外す。
3. OAuthを削除する: `sbx secret --help` で削除の書式を確認して実行し、一覧から消えたことを確認する。必要ならOpenAI側でも当該セッションの無効化を検討する。
4. VMを削除する: `sbx rm --help` を確認し、手順2で控えた19台を削除する。`sbx ls --json` で0台（または無関係のVMだけ）になったことを確認する。
5. 通信規則を確認する: `sbx policy ls --json` を再実行する。VMの削除で当該VMの規則が消えるかは未確認のため、残っていれば `sbx policy --help` で削除の書式を確認して削除する。全体の既定（deny-allで初期化した設定。ADR-0155）は変更しない。
6. 結果（削除した件数、残したもの、想定と違った点）をAIへ伝える。AIが本課題へ記録し、問題がなければクローズを提案する。

`.worktrees/isolated-verification` の未追跡の試験証跡（`.tmp/m9/`・`.tmp/c9/` 等）とブランチは本手順の対象外（別の保全対象）。

## 結論

（open）
