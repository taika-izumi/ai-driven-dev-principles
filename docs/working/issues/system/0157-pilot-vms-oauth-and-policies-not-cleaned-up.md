# Issue-0157: 試作で作った停止VM・全体保存のOAuth・VMごとの通信規則の後片付けが未実施

- **Status**: open
- **Opened**: 2026-09-18
- **起票元**: `docs/records/retrospectives/system/2026-09-18-isolated-verification.md` 課題#3
- **関連**: ADR-0199（Consequences: 後片付けは本サイクルの終了時に扱う）/ `docs/records/experiments/2026-09-18-task9-claude-code-roundtrip.md`（全19台の一覧）/ `scripts/verification/README.md`「既知の制約」（`sbx rm` は利用者の承認後）

## 課題内容

統合時点で、停止中のVM19台、`sbx secret` に全体保存したOpenAIのOAuth、VMごとの通信規則が残っている。OAuthは同じデーモン上の全サンドボックスで使える状態のまま。削除は利用者の個別承認を要するため未実施。詳細は起票元を参照。

## 検討状況

- 2026-09-18: 起票。証跡として残す対象と削除する対象の区別、実施の時期は利用者判断

## 結論

（open）
