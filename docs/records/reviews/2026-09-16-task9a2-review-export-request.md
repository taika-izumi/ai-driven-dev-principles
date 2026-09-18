# タスク9(a-2)の独立レビュー用コード送信の承認対象

- 更新日: 2026-09-17
- 状態: 2026-09-17に利用者が直前の37ファイル・宛先を示した承認質問へ「1」と回答し、送信を承認。独立レビューと修正後の差分再確認を完了。
- 送信先: Claude Codeが利用するAnthropicのモデルサービス（claude-sonnet-5、effort high）。
- 目的: 選択肢2へ変更した設計と実装の仕様適合・品質を、読取り専用の1担当で確認する。
- 対象: 下記一覧の固定コピー37ファイルと、レビュー依頼文・ファイル一覧。差分、関連実装、仕様、試験結果を含む。未公開の作業差分を含むため、公開済み資料としては扱わない。
- コピー: D:\Dev\002_AiDev\MakeAiInstructions\.worktrees\isolated-verification\.tmp\review9a2-export-8805dbfe
- 実行時の操作: 固定したシステム指示とReadのみ。コマンド・編集・追加MCPを渡さず、許可されたコピー内に限定する。レビュー結果は同コピーの新規出力ファイルへ起動側が保存する。
- 承認範囲外: 通常ホームの認証ファイル、元リポジトリ全体、他worktree、任意の追加資料、実VM・モデル往復試験。
- 自動承認レビューの拒否: 先の起動要求は、機密性未確認の内部コードを外部Claudeへ送る具体的なペイロード・宛先について明示承認がない、との理由で拒否された。拒否後は起動を再試行していない。
- 次の操作: 利用者の明示承認後にこの対象でレビューを起動する。修正が生じた場合も今回の実装・同じ対象ファイルに限り、必要な対象試験と差分再確認を行う。別資料の追加や実機操作の承認には流用しない。

## 対象一覧

| パス | バイト数 |
|---|---:|
| docs/current/specs/2026-09-09-isolated-verification/00-overview.md | 10622 |
| docs/current/specs/2026-09-09-isolated-verification/02-isolated-execution.md | 17898 |
| docs/overview/project-purpose.md | 3245 |
| docs/records/decisions/0158-divide-proposal-replay-verification-into-four-blocks.md | 2544 |
| docs/records/decisions/0199-authenticate-proposal-vm-by-oauth-sentinel-and-allow-two-model-hosts.md | 15956 |
| scripts/verification/activation-evidence.schema.json | 2563 |
| scripts/verification/activation-record.schema.json | 2284 |
| scripts/verification/Execution.psm1 | 32662 |
| scripts/verification/ProcessHost.ps1 | 7562 |
| scripts/verification/profiles/evidence-checks.md | 8530 |
| scripts/verification/recovery-input.schema.json | 1385 |
| scripts/verification/recovery-result.schema.json | 1410 |
| scripts/verification/RequestCopy.psm1 | 59065 |
| scripts/verification/runtime-profile.schema.json | 2167 |
| scripts/verification/SbxRuntime.psm1 | 92114 |
| scripts/verification/tests/fixtures/FakeSbx.ps1 | 5499 |
| scripts/verification/tests/fixtures/FakeSbxScenario.psm1 | 18807 |
| scripts/verification/tests/fixtures/ProbeV3Assertions.ps1 | 7742 |
| scripts/verification/tests/fixtures/proposal-probe-settings.json | 615 |
| scripts/verification/tests/fixtures/V3TestContext.psm1 | 8991 |
| scripts/verification/tests/Invoke-SbxPilotProbe.ps1 | 56702 |
| scripts/verification/tests/ProposalV3.Tests.ps1 | 54956 |
| scripts/verification/tests/SbxRuntimeV3.Tests.ps1 | 97805 |
| scripts/verification/tests/TestSupport.psm1 | 2309 |
| task-9-brief.md | 6506 |
| task-9a2-focus.log | 26 |
| task-9a2-implementation-brief.md | 3637 |
| task-9a2-option2-amendment.md | 3044 |
| task-9a2-probe-active-agent.log | 1172 |
| task-9a2-probe-focus.log | 131 |
| task-9a2-probe-integration.log | 1514 |
| task-9a2-report.md | 18140 |
| task-9a2-review-instructions.md | 6063 |
| task-9a2-tracked-probe.log | 3001 |
| review.diff | 139480 |
| docs/records/reviews/2026-09-17-task9a2-implementation-validation.md | 4838 |
| task-9a2-verification-evidence.log | 8465 |

各ファイルのSHA256はコピー内のmanifest.jsonへ記録。レビュー依頼文はreview-prompt.md。

## 起動記録

2026-09-17: 承認済み37ファイルのSHA256を照合してから起動。Claude Codeの開始イベントで利用可能ツールがReadだけ、モデルがclaude-sonnet-5であることを確認。実行セッション17157、プロセスID24252。コピー外の追加資料や実機操作は承認範囲へ加えていない。
