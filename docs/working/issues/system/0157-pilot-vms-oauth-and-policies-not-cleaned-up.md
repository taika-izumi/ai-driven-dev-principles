# Issue-0157: 試作で作った停止VM・全体保存のOAuth・VMごとの通信規則の後片付けが未実施

- **Status**: closed
- **Closed**: 2026-09-20
- **Opened**: 2026-09-18
- **起票元**: `docs/records/retrospectives/system/2026-09-18-isolated-verification.md` 課題#3
- **関連**: ADR-0199（Consequences: 後片付けは本サイクルの終了時に扱う）/ `docs/records/experiments/2026-09-18-task9-claude-code-roundtrip.md`（全19台の一覧）/ `scripts/verification/README.md`「既知の制約」（`sbx rm` は利用者の承認後）

## 課題内容

統合時点で、停止中のVM19台、`sbx secret` に全体保存したOpenAIのOAuth、VMごとの通信規則が残っている。OAuthは同じデーモン上の全サンドボックスで使える状態のまま。削除は利用者の個別承認を要するため未実施。詳細は起票元を参照。

## 検討状況

- 2026-09-18: 起票。証跡として残す対象と削除する対象の区別、実施の時期は利用者判断
- 2026-09-18: 現状を読取りで確認（停止VM19台、全体保存のOAuth 1件、VMごとの通信規則27件〈kit許可8・local拒否19〉、DockerSandboxes全体約3.1GB）。OAuthは利用者判断で、隔離検証の今後の方針を決めるまで残す。VMと通信規則も利用者判断で、同じく方針決定まで保留（片付け方が方針次第で変わりうるため）
- 2026-09-20: ADR-0206（隔離検証は試作で止める）を受け、利用者が「3種類とも削除する」を選択（「1で」）。実験の結果は `docs/records/experiments/` にコミット済みで、VMを証跡として残す必要はないと判断した。削除は利用者が帰宅後に通常の端末で行う（AIからは実行しない）。手順は下記「削除の手順」
- 2026-09-20: 利用者が実行して完了。実行前の読取りでVM19台（全stopped・全て `iv-` 接頭辞）、秘密は `(global) service openai (oauth configured)` 1件、通信規則109件を確認した。規則の件数が起票時の記録（27件）と違ったのは数え方の差で、内訳はキット許可8件（提案用VM 8台に各1）、VMごとの拒否101件（提案用VMに各11、他11台に各1）、製品既定の全体2件（filesystem read/write allow）。新しい規則が増えたのではない。
- 2026-09-20: 利用者が `sbx secret rm openai` と `sbx rm --all` を実行（--force なし、確認つき）。実行後の読取りで、秘密0件（No secrets found）、VM 0台（No sandboxes found）、通信規則3件（global の filesystem read/write allow と `default-deny-all` の network deny）を確認した。VMごとの規則107件は `sbx rm` がVMとともに削除した（`sbx rm --help` の「deletes sandbox state, and deletes secrets scoped to each removed sandbox」の記載と整合）。
- 2026-09-20: 実行前に全体の network deny-all が一覧で見当たらなかった件は、VMごとの規則107件に埋もれていたためで、削除後に `default-deny-all` として確認できた。ADR-0155 の初期化状態は保たれており、別課題としない。

## 結論

2026-09-20 クローズ。ADR-0206（隔離検証は試作で止める）を受け、利用者が3種類とも削除した。全体保存のOpenAI OAuth 1件、停止中のVM 19台、VMごとの通信規則107件を削除し、削除後の読取りで0件・0台・全体規則3件のみを確認した。全体の既定（filesystem read/write allow と network deny-all）は変更していない。実験の結果は `docs/records/experiments/` にコミット済みで、VMを証跡として残す必要はないと判断した（利用者「1で」）。

`.worktrees/isolated-verification` の未追跡の試験証跡とブランチは本課題の対象外（保全を継続）。

