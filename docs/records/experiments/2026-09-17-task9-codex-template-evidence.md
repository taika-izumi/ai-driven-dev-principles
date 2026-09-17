# タスク9: Codex収録済み固定テンプレートの能力証拠

2026-09-17、利用者がテンプレート変更案へ「1で」と回答した承認とADR-0201に基づき、新規2台で条件を取得した。旧shell画像での提案用記録はこの証拠へ流用していない。

## 固定版と役割

- templateDigest: docker.io/docker/sandbox-templates@sha256:b387e913db629ca4370970076162d5bc06d1073059940f2f6326448c47143183
- sbx: v0.42.1 cc6e400a4a3ce3ce5e0b2b77b8ee352aac854c64。daemon PID 25888、世代 09/15/2026 23:59:47。両runの世代は同じ。
- Codex: codex-cli 0.149.1。実行パス /usr/local/share/npm-global/bin/codex、実体 /usr/local/share/npm-global/lib/node_modules/@openai/codex/bin/codex.js。実体ハッシュ: 134063e133f0b4244fa3b251acf973d4fe4b4aeeacbdc135211bf480f59f1477  /usr/local/share/npm-global/lib/node_modules/@openai/codex/bin/codex.js。
- Python: Python 3.14.4、標準ライブラリ 297 件、一覧SHA256 3FEAAF08C67C2F492EE697B05673E39ADF71C0A3EAECD6B5A8BD0A6172CE275B。
- 1台目: iv-0fa7ef20-proposal / c0e1648d-0dc5-4ba4-9651-71074e5229c2 / runId 0fa7ef20-9ba9-4008-aee3-b9ce065f98e1。
- 2台目: iv-da12b0e8-proposal / 29fd1a6e-4430-4c91-8dc9-3ac72d6b197c / runId da12b0e8-1077-4843-9110-6fa0add50047。

## 条件と観測

| 条件 | 観測 |
|---|---|
| daemonHealthAndTemplate | daemon running、固定digestとinspect/runtime一致、sbx 0.42.1 |
| noWorkspaceNoSkillsNoMcp | WorkspaceDir空、ShareSkills=false、登録MCP servers=0 |
| hostPathIsolation | SSHAgentSocketPath空、SSH転送開始ログ0、clipboard.imagePaste=false、ssh.agentForwardingEnabled=false。ゲストSSHソケットなし・3129要求は0バイト。HTTP対照は403、policy logに当該VMのexample.com拒否 |
| resourceAndOutsideStop | runtime CPU2/2g、nproc=2、MemTotal=2036100KiB。1台目を外側stopし同一IDのstoppedを確認。負荷中の外側停止だけはADR-0197に基づき2026-09-14試験Cを参照（下記ハッシュ） |
| credentialMethod | OAuth・アクセス用センチネル・モデル接続先・requires_openai_auth=false・auth placeholderの真偽5件がtrue。inspectに許可外secret名なし。秘密値は出力しない |
| modelEndpointAllowOnly | 当該VMのポート付きallow13件と他11ホストdenyを全体照合。16対照でauth.openai.com/chatgpt.comの443だけ許可、8443と残る11宣言先・外部対照は拒否 |
| limitsAndTransport | 下記5対照、120秒の時間超過とクライアント強制終了、16MiB閾値で出力打切り、終了コードnull、同一IDで外側停止 |
| abnormalExitRecovery | 2台目の保持exec→probe自己強制終了→両プロセス消失→自動停止ログ→記録済みID1件の復旧。停止後のexec/cpなし。元の9台不変、終了時11台すべてstopped |
| daemonDisconnect | unverified。受容済み制限ADR-0196を維持。補償機構の試験は2026-09-17-task9-443-validation.mdの11群結果。実切断は注入していない |

## 起動argvとモデル実行

["/usr/local/share/npm-global/bin/codex","--ask-for-approval","never","exec","--json","--sandbox","workspace-write","--cd","/home/agent/workspace","--skip-git-repo-check","--model","gpt-5.6-sol","-c","model_reasoning_effort=\"medium\"","-"]

model=gpt-5.6-sol、reasoning=medium。画像内の--version/--help/exec --helpを先に確認し、上記argvで承認済み短文をstdinへ渡した。終了0、最終応答SBX_CODEX_STARTUP_OKと指定マーカーの正確な内容を外側で確認した。Codexの内部sandboxはworkspace-write、承認はnever。sbx execの-i有無の両方で固定stdinが到達し、製品の現行経路でも成立した。

この1セッションの成功は最小起動確認であり、候補比較やrecheck全体の成功ではない。

## transport対照

{"clientKilled":{"exitCode":null,"stderrKind":"none-client-killed-by-outside"},"exit0":{"exitCode":0,"stderrKind":"empty"},"exit127":{"exitCode":127,"stderrKind":"shell-not-found"},"exit7":{"exitCode":7,"stderrKind":"empty"},"timeout":{"exitCode":null,"stderrKind":"none-client-killed-by-outside"}}

## 証拠の出所と固定

- 1台目原文: .tmp/m9/c/0fa7ef20/ のobs、cli、calls.jsonl、probe-state.json。
- 2台目原文: .tmp/m9/c/da12b0e8/ の同ファイルと復旧記録。
- 起動・復旧足場は .tmp/m9/Invoke-CodexTemplateStartup.ps1 とInvoke-CodexTemplateRecovery.ps1。既存probe関数を読込み、固定digestと承認済み操作順を指定した。
- 負荷中停止の既存記録: docs/records/experiments/2026-09-14-v3-capability-test-methods.md、SHA256 049EBC16FD82B3B8A3E397737C5CEEB67C188F326118ACBCDC004526D0232EFF。流用は試験Cだけ。

本記録をprofileの証拠としてハッシュ固定する。追記が必要なら別記録にし、既存の証拠を書き換えない。モデル往復の結果は別の実験記録へ残す。
