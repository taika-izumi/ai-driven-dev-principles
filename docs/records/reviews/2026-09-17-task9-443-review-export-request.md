# タスク9: 443番限定への修正差分レビューの送信確認

- 状態: 2026-09-17、利用者が一覧の18資料・OpenAI宛先・差分再確認1回までを示した確認に「1で」と回答し、送信を承認済み。先の自動承認レビューの拒否を受け、具体的内容を提示して得た承認である。
- 宛先: OpenAI Codex（Codex CLI 0.154.0-alpha.6.2、gpt-5.6-sol/high）。Anthropicへの送信ではない。
- 送信する内容: 下記18ファイル相当の本文（合計 448,193 バイト）と、.tmp/443-review/review-instructions.txtにあるレビュー依頼文。レビュー用コピーは .tmp/443-review/input/。完全な入力は .tmp/443-review/review-prompt.txt。
- 対象: 5fc8a80からの443番限定とpolicy check正常拒否処理の修正、およびその設計根拠・回帰試験。
- 含まれるもの: 内部コード・設計・プロジェクト目的、非秘密の通信規則、試験VM名/ID、資料内のローカルパス。
- 含めないもの: OAuthの秘密値、ホスト認証ファイル、会話全文、今回と無関係なリポジトリ。
- 権限: read-only、承認昇格なし、ユーザー設定・rules読込みなし、apps/plugins/hooks/MCP/browser/multi_agentを無効。shell/unified_execも無効とし、添付本文だけを静的確認する。代用guard.txtへのapply_patchが利用可能なら拒否を確認してからレビュー、書込みが通れば中断。実VM操作は渡さない。
- 上限と反復: 初回1回、900秒以内。指摘修正が出た場合は同じ対象ファイル群の修正差分と対応試験結果のみで差分再確認を1回まで含める案。追加資料・別サービスへの送信は含めない。
- 今回の承認を求める範囲はレビュー送信だけ。新規VM2台の再試験はすでに利用者の「1で」で承認済み。

| 送信対象 | バイト数 |
|---|---:|
| project-purpose.md | 3245 |
| change.diff | 34736 |
| scripts/verification/SbxRuntime.psm1 | 94625 |
| scripts/verification/runtime-profile.schema.json | 2165 |
| scripts/verification/tests/Invoke-SbxPilotProbe.ps1 | 57511 |
| scripts/verification/tests/SbxRuntimeV3.Tests.ps1 | 99113 |
| scripts/verification/tests/fixtures/NetworkPolicyAssertions.ps1 | 6018 |
| scripts/verification/tests/fixtures/ProbeV3Assertions.ps1 | 9205 |
| scripts/verification/tests/fixtures/FakeSbxScenario.psm1 | 19122 |
| scripts/verification/tests/fixtures/V3TestContext.psm1 | 8989 |
| scripts/verification/tests/ProposalV3.Tests.ps1 | 54954 |
| scripts/verification/profiles/evidence-checks.md | 8705 |
| docs/current/specs/2026-09-09-isolated-verification/02-isolated-execution.md | 18105 |
| docs/records/decisions/0199-authenticate-proposal-vm-by-oauth-sentinel-and-allow-two-model-hosts.md | 17066 |
| docs/records/experiments/2026-09-17-v3-task9-proposal-probe-first-attempt.md | 6385 |
| scripts/verification/tests/fixtures/fake-sbx-responses/proposal-policy-real.json | 7620 |
| scripts/verification/tests/fixtures/fake-sbx-responses/proposal-policy-allowed-real.json | 273 |
| scripts/verification/tests/fixtures/fake-sbx-responses/proposal-policy-denied-real.json | 356 |
