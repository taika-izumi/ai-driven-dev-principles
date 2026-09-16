# 実行設定の条件名と観測の対応表（verified の意味の正本）

`activation-evidence.schema.json` の `checks` に置く条件名ごとに、どの観測が揃えば `verified` と書けるかを役割（replay / proposal）別に定める。`Test-VerificationRuntimeProfile` は条件名の存在・verdict・証拠ファイルの hash 一致を機械的に検査するが、「その verdict を書いてよいか」を決めるのは本表である。**verified の意味は「本表に書いた観測がすべて揃い、証拠ファイルの hash が一致する」に限る。表に無い観測で verified にしない。**

## 証拠の出所（3種）

| 記号 | 出所 | 証拠ファイル |
|---|---|---|
| (既存) | 2026-09-14 の試験A〜D（追跡済み記録） | `docs/records/experiments/2026-09-14-v3-capability-test-methods.md` を `evidencePath` とし、そのファイルの SHA256 を `evidenceHash` に固定する。`.tmp/sbx-capability-20260914/` の原文は追跡外なので `evidencePath` にしない。evidence に使った記録は以後追記しない（追記が必要なら profile を再生成する。README の既知の制約） |
| (8a) | タスク8a で probe VM に対して固定 argv で取得する観測 | タスク8a が `docs/records/experiments/` に残す記録 |
| (9) | タスク9で proposal VM を作る際に (8a) と同じ手順で取り直す観測 | タスク9が `docs/records/experiments/` に残す記録 |

試験A〜C（否定試験・負荷試験）の再実施は実装計画の承認に含めない。再実施を望む場合は承認区切りの拡大として利用者が指示する。

## 条件 × 役割

「同記録の節」は (既存) の記録 `2026-09-14-v3-capability-test-methods.md` 内の節名。

| 条件名 | replay（agent=shell、`deny *`） | proposal（agent=codex、`auth.openai.com`・`chatgpt.com` の全ポートだけを許可） |
|---|---|---|
| `daemonHealthAndTemplate` | (8a) `daemon status --json` が running。`inspect --json` の `image_digest` が profile の `templateDigest` と一致。daemon.log の最後の `starting sandboxd` 行の `version`（例 `v0.42.1 <commit>`）が profile の `sbxVersion` と一致（先頭の `v` と commit 部分は除いて比べる。`New-VerificationSandbox` も VM 作成前に同じ照合を行い、不一致なら blocked） | (9) 同じ観測を proposal VM で取る |
| `noWorkspaceNoSkillsNoMcp` | (8a) 状態ディレクトリの `runtimes/<VM名>.json` で `WorkspaceDir=""`・`ShareSkills=false`。`mcp ls --json` の `servers` が空（製品が常設する MCP ゲートウェイと `mcpgateway` secret は製品挙動として記録する。ADR-0195） | (9) 同じ観測を proposal VM で取る |
| `hostPathIsolation`（SSH転送・ホームなど例外以外の追加ホスト経路の拒否。clipboard 画像読取無効を含む） | (8a) daemon.log の当該 runtime 行に `started SSH agent forwarder` が無い・`SSHAgentSocketPath=""`・`settings get --json clipboard.imagePaste` の `value` が false。(既存) 「2026-09-14 23:00以降: 試験A〜Dの実施結果」の試験A（ゲスト側の SSH ソケット不在・エージェント要求への応答0バイト・policy log の拒否） | (9) 上記 (8a) 相当の観測を proposal VM で取り、さらに試験Aのゲスト側の否定確認（SSH エージェントのソケット不在・透過プロキシの中継ポートへの応答・policy log）を数秒のコマンドで取り直す。(既存) の流用はしない |
| `resourceAndOutsideStop` | (既存) 試験B（`Spec.CPUs`=2・`Spec.Memory`="2g"・daemon.log の `vcpu_count: 2`・`total_mb: 2048`・ゲスト `nproc`=2）と試験C（負荷中の外側 `stop` で同一 ID が stopped）。(8a) `runtimes/<VM名>.json` の `CPUs=2`・`Memory="2g"` | (9) `runtimes/<VM名>.json` の `CPUs=2`・`Memory="2g"` と、試験Bのゲスト側の実効値（`nproc`・メモリ量）を数秒のコマンドで取る。負荷なしの外側停止は proposal VM 自体の停止で観測する。**負荷中の外側停止だけは (既存) の試験Cを流用する**（ADR-0197。仕様00「保護条件を共用済みにしない」の例外はこの1点に限る） |
| `credentialMethod` | 不要（replay はモデル認証を一切供給しない） | (9) `SBX_CRED_OPENAI_MODE=oauth`、VM 内 `/home/agent/.codex/config.toml` の `[model_providers.sandboxd].experimental_bearer_token` が `oai-oat01-proxy-managed`、同 provider の `base_url` が `https://chatgpt.com/backend-api/codex`、`requires_openai_auth=false`、`/home/agent/.codex/auth.json` の `OPENAI_API_KEY` が `proxy-managed` であることを、値を出力せず真偽5件だけ記録する。`inspect --json` の secrets は `mcpgateway` と `openai` 以外が無いことを記録する。静的なキット宣言から分かった配置を実VMで照合して初めて verified とする |
| `modelEndpointAllowOnly` | 不要 | (9) `policy ls <VM名> --json` の有効なallowがキット宣言の13件に限られ、残る11ホストへのポート番号なしdenyがあり、未知の追加allow・ワイルドカード・拒否漏れが無いことを確認する。`policy check network --sandbox <VM名> --json` で承認2ホストそれぞれの443番と8443番が許可、残る11宣言先と外部対照1件が拒否されることを確認する。これは規則一覧と代表ポートの対照であり、全ポートの実通信試験ではない |
| `replayNetworkDeny` | (8a) `policy ls <VM名> --json` に `resource_type=network`・`decision=deny`・`resources=["*"]` の規則がある。(既存) 試験Aの方式による拒否応答（HTTP プロキシの 403・policy log の拒否記録） | 不要（proposal は通信許可側の条件 `modelEndpointAllowOnly` で扱う） |
| `limitsAndTransport`（時間・出力上限、transport 対照、対象VMの停止確認） | (8a) transport 対照5種（終了0・7・127・時間超過・sbx クライアント子プロセスの外側からの強制終了）で外側が観測する終了コードと stderr の型を `transportContrast` に記録。出力洪水の exec 1本が上限で打ち切られること。(既存) 試験Cの外側 `stop` による停止確認（同一固定 argv・同一 digest・sbx 0.42.1） | (9) 同じ観測を proposal VM で取る（transport 対照5種・出力洪水・停止確認） |
| `abnormalExitRecovery`（外側 CLI 異常後の自動停止と復旧操作、他VMの非停止、停止中の自動再起動防止） | (8a) 保持セッション開始 → probe プロセス（CLI 相当）の強制終了 → 保持プロセスの消失と daemon.log の自動停止行 → 復旧操作 `Stop-VerificationRecordedSandboxes` による記録済み ID だけの停止 → 他VM（停止中の試験VM2台）の `ls --json` 上の不変 → 停止後に当該名への `exec`/`cp` を発行しないこと（`calls` 相当の記録） | (9) proposal VM で同じ手順（保持 → 強制終了 → 保持消失 → 自動停止 → 復旧操作 → 他VM不変 → 停止後の未発行）を1回取る。役割非依存とはみなさず、replay 側の (8a) の記録を流用しない |
| `daemonDisconnect` | `unverified` だけを受理する条件（ADR-0196。`verified` と書ける観測は本表に無く、`verified` を付けた証拠は `Test-VerificationRuntimeProfile` が拒否する）。証拠は補償機構（各実コマンド直前の世代確認と自動停止痕跡の検知）の偽 fixture 試験 `tests/SbxRuntimeV3.Tests.ps1` の結果を指す | 同左 |

## 読み方の注意

- `checks` の各値は `{verdict, evidencePath, evidenceHash}`。`evidencePath` は絶対パス、または evidence ファイルのあるディレクトリからの相対パス。`evidenceHash` はそのファイルの SHA256（大文字16進）。
- `transportContrast` は仕様04が求める実機対照の完備性の証拠であり、実行時の比較対象ではない。`Invoke-VerificationSandboxCommand` の `transportVerified` は出力署名の有無で決め、stderr の型との比較は行わない。
- `profileHash` は profile から `activationEvidencePath`・`activationEvidenceHash` を除いた正規化 JSON の SHA256。evidence の `profileHash` はこれと一致しなければならない。
- 偽sbx（`tests/fixtures/`）での試験成功は実機の保護実証に数えない。
