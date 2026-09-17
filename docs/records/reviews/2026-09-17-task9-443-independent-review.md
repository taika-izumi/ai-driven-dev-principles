# タスク9: 443番限定への訂正の独立レビュー

## 対象と方法

基点5fc8a80からの、2ホスト443番限定とpolicy check正常拒否の判定処理、その仕様・回帰試験を確認した。18資料の具体的内容・OpenAI宛先・差分再確認1回までを利用者へ提示し、2026-09-17の「1で」により送信承認を得た（`2026-09-17-task9-443-review-export-request.md`）。

独立したCodex CLI 0.154.0-alpha.6.2、gpt-5.6-sol/highで、1体が目的・要求、根拠・設計、動作・検証と反例探索を兼務。添付本文だけの静的レビューであり、独立した試験再実行や分離された反証担当を設けたものではない。read-only、承認昇格なし、設定/rules読込みなし、シェル・apps・plugins・hooks・ブラウザー・MCP・再委譲を無効化した。

## 実行と保全

| 回 | 対象 | 終了 | 所要 | 原文 |
|---|---|---:|---:|---|
| 初回 | 18資料 | 0 | 80秒 | `.tmp/443-review/review-result.txt`、review-events.jsonl、review-stderr.txt、review-execution.json |
| 差分再確認 | 修正2ファイル・対象試験の出力・新規4ファイルの追跡確認 | 0 | 21秒 | 同ディレクトリのr2-result.txt、r2-events.jsonl、r2-execution.json |

初回入力SHA256: `774E06BA079C1D4B07E034848A2EFAA77CDC4E75A569C702FA6BCC507C9CBB27`。
差分入力SHA256: `C9A550F00397D36DA15572E906A5F18563D891F0FC234ECAC741ADDC2EF9C101`。

初回レビュー前のguard.txtへのapply_patch試行は、stderrの`writing is blocked by read-only sandbox; rejected by user approval settings`で拒否された。主担当はguardの内容がoriginalのまま、18資料の全コピーがmanifestのSHA256と一致していることを実体から照合した。レビュー担当が原本や実VMを変更した結果はない。

## 指摘と採否

| 指摘 | 重要度 | 主担当の照合・対応 |
|---|---|---|
| allowのscopeを確認しておらず、global/別VMの同じ13接続先で代用できる | Important | 実測fixtureのscopeだけを変える試験で旧コードの受理を再現。対象VMの規則であることを検査する既存の意図に沿い、allowにもscope一致を1行追加。global/他VMの両方を拒否する回帰試験を追加しGREEN。外向き許可の追加や別の保護方針は導入していない |
| 新規回帰試験がchange.diffにないため、成果物への収録を確認できない | Minor | 未追跡ファイルの本文は初回入力に含めていたがgit diffに未収録だった。新規試験と実測fixture3件を個別にgit addし、indexの4件を実体で確認して再提示。コミット対象への収録を確定した |

実行証拠: `.tmp/task9-probe-approval/443-review-scope-red.log`（想定した受理漏れで失敗）、`443-review-scope-green.log`（全焦点項目が成功）。差分再確認は両指摘の解消・新規指摘なし。fixtureのindex内容そのものの再確認と、進行中の11群・実機再試験の結果は主担当の確認として残す。

## 限界と残作業

このレビューは今回の訂正差分だけを対象とし、ブランチ全体の最終レビューの代わりではない。設計本文の現行値との整合は確認したが、過去の全ADR版の差分監査は行っていない。既存11群の結果は別の検証記録へ集約し、実機2台はその完了後に承認済み範囲で実施する。
