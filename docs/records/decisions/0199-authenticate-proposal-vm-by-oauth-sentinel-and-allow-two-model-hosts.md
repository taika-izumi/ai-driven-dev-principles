# ADR-0199: 提案用VMはOAuthのセンチネル方式で認証し、通信許可をモデル接続先2件に限る

- **Status**: Proposed
- **Date**: 2026-09-16

> 2026-09-17の訂正・改訂承認: 初回proposal VMの実効allowは2ホストとも`:443`で、8443番は暗黙拒否だった。静的なキット宣言を全ポートの実効許可と同一視した従来の説明は誤り。実験記録`docs/records/experiments/2026-09-17-v3-task9-proposal-probe-first-attempt.md`の修正案を提示し、利用者が「1で」と回答した。これにより、既定キットを維持して2ホストの443番限定へ設計・判定処理を訂正し、修正・検証後に新規2台で再試験することを個別承認済み。資源・時間上限は従来どおり、既存6台は保全、モデル往復は別承認。

## Context

v3実装計画のタスク9は、提案用VM（agent=codex）から実モデルへ1往復する。ここで初めて「raw の認証値を子へ渡さない認証方式」（条件名 `credentialMethod`）と「承認されたモデル接続先だけを許す通信設定」（条件名 `modelEndpointAllowOnly`）の観測が必要になる。両条件は `profiles/evidence-checks.md` でタスク9まで evidence を作れないものとして保留されていた。

2026-09-16 に sbx 0.42.1（デーモン稼働中）へ読み取りだけの調査を行い、次を確認した。**実測で確定した事実と、実行ファイル内の宣言から読み取っただけの事項を区別して記す。**

確定した実測:

- 通信のグローバル既定は暗黙の拒否である（`policy check network --json https://api.anthropic.com/v1` が `allowed=false` / `deny_kind=implicit` / `reason="No matching allow rule (default deny)"`）。
- 許可の追加は `sbx policy allow network [--sandbox <VM名>] <ホスト列>`（作成時の `--allow-network` はクラウド専用）、拒否の追加は作成時の `--deny-network`（絞る方向のみ）で、拒否が許可に優先する（`policy allow --help`）。
- `policy check network --sandbox <VM名> <対象> --json` は読み取り専用で、実際の通信施行と同じ認可器を評価する（`policy check --help`）。
- ホストに保存済みの秘密は調査時点で0件（`secret ls`）。per-sandbox の通信規則はVMを停止しても残る（`policy ls` に既存5台分の deny 規則が残存）。

宣言から読み取った事項（実行時の挙動としては未確認）:

- 認証はセンチネル置換方式である。`sbx secret set <サービス>` で保存した秘密はホスト側に留まり、VM 内にはプロキシ管理を示すダミー値が入り、外向きプロキシが宣言ドメインへの要求時に実値へ差し替える（`secret --help` の「The secret is never exposed directly」、キット定義の `inject: [{domain, header, format}]`、実行ファイル内の動作文字列 `proxy: removing x-api-key proxy-managed sentinel`。この文字列と `proxyManaged: true` 属性は anthropic キットの宣言に由来し、codex/openai のセンチネルは `oai-oat01-proxy-managed` / `oai-ort01-proxy-managed` である）。
- codex キットの認証は2通り宣言されている。APIキー方式（`OPENAI_API_KEY` を `Authorization: Bearer %s` として api.openai.com・openai.com へ注入。`--sandbox` で単一VMへ限定保存できる）と、OAuth方式（センチネル2種、トークン取得先 auth.openai.com/oauth/token、モデル呼び出し先 chatgpt.com/backend-api/codex、`skipIfEnv: OPENAI_API_KEY`）。モードは VM 内の `SBX_CRED_OPENAI_MODE` に現れる。
- codex キットは `permissions.network.allow` に13ドメインを宣言している（api.openai.com / openai.com / auth.openai.com / chatgpt.com / files.openai.com / registry.npmjs.org / api.github.com / github.com / codeload.github.com / archive.ubuntu.com:80 / security.ubuntu.com:80 / ports.ubuntu.com:80 / download.docker.com）。**この宣言が `policy ls <VM名> --json` の allow 規則として現れるかは未確認である**（既存の停止中VM5台はいずれも shell 相当で、観測できていない）。再実行用の shell キットは既定許可0件で、こちらは実行ファイル内の試験コード `TestShellNoDefaultNetworkAllow` が裏付けとなる。これが再実行用で `deny *` を前提にできた理由である。

一方、現行実装は役割を問わず通信を全面拒否に固定している。`SbxRuntime.psm1` の作成 argv は `--deny-network '*'` を常に渡し、`runtime-profile.schema.json` は `policyExpectation.networkPolicy` を `"deny *"` の定数に固定し、`New-VerificationActivationRecord` の policy 検査は拒否規則 `*` の存在を `verified` の要件にしている。拒否が許可に優先する以上、提案用VMをこの構成のままモデルへ接続させることはできない。

さらに同じ関数の `credentialExposure` 検査は、`inspect --json` の secrets に `mcpgateway` 以外が無いことを `verified` の要件にしており、役割で分岐していない（`SbxRuntime.psm1` の当該行と `activation-record.schema.json` が全役割で必須としている）。いずれかの check が `failed` になると VM 作成は `blocked` で止まる。製品が常設する `mcpgateway` の秘密が secrets に現れる前例（ADR-0195）がある以上、**グローバル保存したモデル資格情報が提案用VMの secrets に現れる可能性があり、その場合この検査が提案用VMの作成を毎回止める**。


2026-09-16の実装時にIssue-0150を検出し、静的なキット宣言から「他の11ドメインを拒否するだけでは443番限定にならない」と誤って判断した。利用者は選択肢のメリット・デメリットと、全ポート許可が外向き通信に関する変更であることを確認したうえで、同日の「分かりました。一旦選択肢2で進めましょう。」により2ホスト・全ポートを選択した。今回の承認を本サイクルのsynthetic-pilotへ適用し、認証保存・実機作成・モデル操作の個別承認は別に維持する。
## Considered Alternatives

- **APIキー方式＋単一VMへの限定保存**: 秘密の有効範囲を提案用VM 1台に閉じられ、隔離の主張は最も強い。ただし利用者がOpenAIのAPIキーを用意・投入する必要があり、従量課金が発生する。
- **codexキット宣言の13ドメインをそのまま使う**: 追加の拒否指定が不要で最も失敗しにくい。GitHub・npm・aptへの送信も許すことになり、`modelEndpointAllowOnly` の主張が弱くなる。
- **最小2件に `files.openai.com:443` を加えた3件**: キット注記が起動時に触る可能性を挙げているため初回の失敗が減る。送信範囲はその分広がる。
- **タスク9のモデル往復を見送る**: 新たな送信も認証も不要だが、隔離の実証が未完のまま残り、`Invoke-VerificationReplay` の統合が実機で成立しない。

- **443番限定の専用キット**: 当初は必要と考えたが、既定キットの実効規則が443番限定と分かったため不要。追加保守を増やさず既定キットを使う。
- **2ホスト・全ポートと既定キット**: 不要なポートへの接続も通信規則上は許可されるが、専用キットの保守を増やさず既存構成を活用できる。2026-09-16に選択したが、翌日の実測を受けて撤回した。

## Decision

利用者の個別回答（2026-09-16、および実測訂正後の2026-09-17「1で」）により次の構成を採用する。今回の操作承認は新規2台の証拠取得までで、モデル往復は別承認。

1. **認証はOAuth方式を使う**（`sbx secret set openai --oauth`）。利用者のChatGPTサブスクリプションをそのまま使え、APIキーの文字列を扱わずに済むことを理由とする。保存はグローバル（同一デーモン上の全サンドボックスで共有）となり、単一VMへの限定はできない。
2. **本サイクルの実効通信許可は `auth.openai.com:443` と `chatgpt.com:443` の2件に限る**。sbx 0.42.1の既定codexキットを維持し、専用キットや追加allowは作らない。実測のキットallowはHTTPS系10件が`:443`、Ubuntu系3件が`:80`である。残る11ホストは従来どおりポート番号なしの `--deny-network` を反復指定して全ポート拒否する。受信ポートの公開は追加しない。
3. **`policyExpectation.networkPolicy` の `"deny *"` 固定を役割別の表現へ改める**。再実行用（shell）は従来どおり全面拒否、提案用（codex）は上記2ホストの443番だけが有効な許可であることを表す。あわせて `New-VerificationActivationRecord` の **`policy` 検査と `credentialExposure` 検査の両方**を役割別にする。提案用では、拒否規則 `*` の存在ではなく「有効な許可が承認した2ホスト・443番に一致し、それ以外が拒否される」ことを `policy` の `verified` 要件とする。規則一覧も照合して、未知の追加allow・ワイルドカード許可や拒否漏れを受理せず、有限個の接続先への対照だけで全体一致を認定しない。`credentialExposure` は「secrets に現れてよいのは `mcpgateway` と、本決定で使うモデル資格情報のサービス名だけであり、それ以外が無いこと」を要件とする。スキーマを役割別に緩めるため、役割と値の組合せの整合は `Test-VerificationRuntimeProfile` で命令的に検査する（既存の `agent`・`model` の役割整合検査と同じ形にする）。
4. **`modelEndpointAllowOnly` の観測は、承認した2ホストが443番で `allowed=true`、8443番・残る11宣言先・外部対照で `allowed=false` となる認可器の評価とする**。規則一覧のallowが実測の13件（HTTPS系は`:443`、Ubuntu系は`:80`）に一致し、残る11ホストのポートなしdenyがあることを全体照合する。代表ポートの対照を全ポートの実通信試験とは称さない。policy check専用経路で終了0/trueと終了1/falseを正常として受け取り、応答の対象VM・接続先・型を照合する。一般照会の非ゼロ終了を成功扱いにしない。`credentialMethod` の観測は、VM内の認証値がセンチネルであること（`SBX_CRED_OPENAI_MODE=oauth`、VM内 `/home/agent/.codex/config.toml` の `model_providers.sandboxd.experimental_bearer_token` が `oai-oat01-proxy-managed`、同providerの `base_url` が `https://chatgpt.com/backend-api/codex`、`requires_openai_auth=false`、`/home/agent/.codex/auth.json` の `OPENAI_API_KEY` が `proxy-managed`。比較結果の真偽だけを外へ返し、認証値・設定全文を出力しない）と、`inspect --json` の secrets に決定3で許した2種以外が無いことの組み合わせとする。secrets の判定は決定3の実行設定記録の検査と同じ集合を見るが、役割が異なるため両方を残す——決定3はVMを作るたびに条件を満たさなければ停止させるゲートであり、決定4はタスク9の実行設定として保存する証拠である。許す集合の定義は決定3に一本化し、決定4はそれを参照する。
5. **許可2件で起動できなかった場合は、`sbx policy log` の拒否記録で不足ホストを特定し、追加の可否を利用者に諮ってから再実行する**。AIの判断で許可を広げない。ただし `policy log` はネットワーク層の可否だけを記録するため、許可済みホストへの接続が成立したうえで認証・認可の層で失敗する種別（トークン失効・権限不足など）はこの経路で診断できない。拒否記録が無いことを「許可は足りている」の証拠にせず、その場合はVM内の出力と終了コードを根拠に切り分ける。
6. **実機の最初の提案用VMで、設計が依拠する未確認の前提を確認し、想定と異なれば停止して利用者に諮る**。確認するのは、(a) キット宣言の13ドメインが `policy ls <VM名> --json` に allow 規則として現れ、作成時の拒否で実効許可が2件に絞れていること（決定4の対照で同時に取れる）、(b) secrets に現れる項目（決定3の要件どおりか）、(c) `sbx create` の時点でエージェント本体が起動するかどうかと、それが仕様02の「搬入 → 標準入力で依頼 → 作業」の順序と両立すること。(a)(b) が想定と異なる場合、決定2・3の実現手段が成立しないため、実装の修正か構成の再選択を利用者に諮る。

## Consequences

- 提案用VMの送信範囲は、承認した2件の観測記録として残る。`modelEndpointAllowOnly` は許可側・拒否側の両方向を読み取り専用の認可器評価で示せるため、VMを動かさずに承認前後で照合できる。
- OAuthトークンはグローバル保存となり、共有範囲は**同一デーモン上の全サンドボックス**である。本プロジェクトが作るVMに限らず、利用者が別用途で openai を宣言するキットのサンドボックスを作れば、そこからも使われうる。本サイクルで新規に作るVMは提案用の証拠取得2台と往復用に限り、既存5台（いずれも shell 相当で `credentials` を宣言しない）は停止したまま操作しないが、**保存中はこの残存リスクが残る**。後片付けは本サイクルの終了時に扱う。
- キット宣言のうち files.openai.com・GitHub系・npm・apt を拒否するため、codex の起動時処理や更新確認が失敗する可能性がある。加えて、拒否されたホストへの接続はTCP接続が成立したうえでデータが返らない形になる実測があり（`docs/reference/sbx-sandbox-runtime-facts.md`）、Issue-0148（出力が止まっても全体期限まで停滞を検出できない）と重なると、失敗が「無反応のまま全体期限まで」現れることがある。本サイクルでは停滞検知を実装しない判断のため、全体上限に余裕を持たせたうえで、1回の試行を消費しうることを受け入れる。
- 変更は実装3か所（profileスキーマ・実行設定記録の検査2種・作成argv）に加えて、役割非依存に `policyExpectation` と作成argvを組み立てている共有の試験フィクスチャ（`tests/SbxRuntimeV3.Tests.ps1` の `New-Profile`、`tests/fixtures/V3TestContext.psm1` の `New-V3TestProfile`、`tests/ProposalV3.Tests.ps1` の提案用profile生成、`tests/fixtures/FakeSbxScenario.psm1` の作成argv照合）にも及ぶ。提案役割を使う既存試験は、偽sbxの応答照合が一致しなくなるため修正が要る。試験の追加だけでは済まず、既存フィクスチャの変更と再レビュー、ランナー再実行（約30分）を見込む。再実行用の profile（`profiles/replay/profile.json`）の既存値は `"deny *"` のままで有効である。
- per-sandbox の通信規則はVMを削除しても policy に残る（既存5台分の拒否規則が残存している実例がある）。提案用VMの許可・拒否規則も後片付けの対象に加わる。
- 決定6の確認は、決定4の証拠取得と同じ操作（`policy ls` と `policy check` の対照、`inspect --json`）で取れるため、新しい工程は増えない。想定と異なった場合に停止する動作も、既存の実行設定記録の検査（不一致なら `blocked`）が担う。

## 改訂記録

- 2026-09-16: Issue-0150と利用者の選択肢2の明示回答により、決定2〜4の443番限定を2ホスト・全ポートへ修正。未知の追加allowの拒否と規則一覧の照合を明記し、既存の「他の接続先を許可しない」要件の検査を具体化した。認証のダミー値の観測先は埋め込みキット宣言に合わせて補足した。以前の設計はコミット0675154で参照できる。実機での成立はまだ未確認であり、この改訂を実機操作の承認と扱わない。

- 2026-09-17: 初回実VMのポート付きallowと正常拒否の終了1を受けて前提を訂正。利用者の「1で」により、既定キットのまま2ホスト・443番限定へ決定2〜4を改訂し、判定処理修正・検証後の新規2台再試験を承認。今回を含む既存6台は停止保全、資源CPU2/2GiB・各3600秒、モデル往復・daemon変更・削除は含めない。元の全ポート判断は5fc8a80で参照できる。
