# Handoff: 隔離検証の共通起動処理

- **Branch**: codex/isolated-verification
- **Last Updated**: 2026-09-17 11:47 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: ADR-0201のCodex収録済み固定テンプレートで、能力/起動/復旧の再確認とproposal profile生成、Codex主担当の候補比較・修正反映・recheckが完了。candidate-supported/current-pass。Issue-0151 closed、全15台stopped、元の9台不変。Task9はClaude Code主担当の往復と全体整合検査・最終レビューを残す。

## 作業の目的・背景

Claude CodeまたはCodexの主担当から共通CLIで検証を依頼する。スクリプトで原本のファイル・Git履歴を独立コピーし、sbx内Codexが調査・提案する。採否用のテストは別の通信なし環境で再実行し、外側の記録で照合する。資料本文の手動転記は不要にする。

既存worktreeは`D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification`。保存点はv3仕様確定`b7941f3`、試作条件改訂確定`5259d22`、SSH設定操作記録`cf853d2`、能力試験の取得元特定とADR-0192`e02c32c`。masterへ未統合。2026-09-14にユーザーが本作業の再開を選択し（masterのhandoffで「2で」）、残る能力試験を実施した。

## 関連ドキュメント

- **最新の完了記録**: docs/records/experiments/2026-09-17-task9-codex-roundtrip.mdと同名ディレクトリの結果JSON。能力証拠は2026-09-17-task9-codex-template-evidence.md（profileからハッシュ固定、追記禁止）、設定はscripts/verification/profiles/proposal/。過去の「Codex未収録で停止」「新画像/6台は未承認」は解消済み。

- **最新の停止理由と変更案**: docs/records/experiments/2026-09-17-task9-startup-image-mismatch.md、Issue-0151、docs/working/plans/2026-09-17-task9-codex-template-amendment.md。画像metadataは同日のtask9-image-metadata.json。旧最大5台の承認は取得済みだが、新しい画像/最大6台は未承認。

- **次の操作案**: `docs/working/plans/2026-09-17-task9-model-roundtrip-approval.md`。ADR-0200 Proposed。利用者の「進めてください」で準備を開始したが、モデル/送信範囲/新規最大5VMの具体的な承認は未取得。sourceは`.tmp/m9/source`、準備物は`.tmp/m9/cfg`。

- 訂正実装の検証状況: `docs/records/reviews/2026-09-17-task9-443-validation.md`。独立レビューの具体的送信対象: `docs/records/reviews/2026-09-17-task9-443-review-export-request.md`。11群はセッション52556で実行継続中、再実行せず結果を回収する。

- **最新の実測と訂正**: `docs/records/experiments/2026-09-17-v3-task9-proposal-probe-first-attempt.md`。下記の過去記載にあるIssue-0150解決済み・全ポート許可成立・OAuth未登録・既存VM5台は現在地ではない。実測でIssueを再開した。コードは5fc8a80のままで、実機に適合する修正は未着手。

- 最新の検証結果: docs/records/reviews/2026-09-17-task9a2-implementation-validation.md。レビュー送信の対象: docs/records/reviews/2026-09-16-task9a2-review-export-request.md。

- 今回の採用判断: Issue-0150は選択肢2の明示承認によりclosed。ADR-0199は2ホスト・全ポートへ改訂済みで未コミット。最新状態は進行中タスクと検証記録を参照。

- 能力試験の取得元・方式と実施結果: `docs/records/experiments/2026-09-14-v3-capability-test-methods.md`。試験A（SSH転送拒否）・B（CPU/メモリ実効値）・C（有限負荷中の外側停止）・D（起動世代）はすべて合格。原文は `.tmp/sbx-capability-20260914/`（番号付きファイル）。個別承認はADR-0192（Proposed）。
- 継続調査・操作記録: `docs/records/experiments/2026-09-10-v3-capability-followup.md`。SSH設定false保存・停止・通常起動後の設定と既存VM照合まで完了。ADR-0162は次の全体整合チェックポイントで昇格するProposed。
- 現行仕様: `docs/current/specs/2026-09-09-isolated-verification/00-overview.md`と01〜04。schemaVersion=3、4責務。試作条件は`5259d22`に、2026-09-15のADR-0196（acceptedLimitations 3件目）を作業ツリーで追記（未コミット）。実装は未着手。
- 方針と分担: ADR-0157（提案と再実行の分離）、ADR-0158（4責務と補助設計の委任）。両方Accepted。保護の追加変更・新基盤・利用者作業・認証/費用/送信・削除/公開は相談。
- 試作条件: ADR-0160（厳密pids128を外してVM割当・外側停止へ）、ADR-0161（clipboard文字列書込の限定例外）。両方Accepted。再検討のADR-0159もAccepted。
- v3レビュー確定: `docs/records/reviews/2026-09-09-proposal-replay-spec-r3.md`。条件改訂レビュー確定: `docs/records/reviews/2026-09-10-synthetic-pilot-scope-r2.md`。
- v3全体の実装計画: `docs/working/plans/2026-09-14-isolated-verification-v3-implementation.md`（草案bd3beca、第1回反映47109dc、第2〜9回反映と確定は本handoffと同じコミット）。レビューの採否と相談事項4〜7は同計画「確定前の確認状況」節が正本。sbxの実測挙動の整理は `docs/reference/sbx-sandbox-runtime-facts.md`（67923c6）。
- 先行計画: `docs/working/plans/2026-09-09-isolated-verification-v3-preflight.md`。タスク3の実機試験案の項目は2026-09-14に完了へ更新。
- 能力確認: `docs/records/experiments/2026-09-09-v3-runtime-preflight.md`。条件見直しと承認: Issue-0136の`0136-note-v3-capability-gaps.md`。
- sbx導入・起動とAIなし実証: `docs/records/experiments/2026-09-09-sbx-preflight.md`、`2026-09-09-sbx-smoke.md`。固定試験の承認範囲: Issue-0136の`0136-note-sbx-smoke-proposal.md`。
- コピー先行部品: ADR-0150、`scripts/verification/README.md`、`docs/records/reviews/2026-09-09-history-copy.md`。v1部品とv3全体を区別する。
- 課題の入口: `docs/working/issues/flow/0136-inspection-delegation-does-not-fire-destructive-verification-row/0136-inspection-delegation-does-not-fire-destructive-verification-row.md`。master側の結論（61ddef3）で、本案件の再開経路をIssue-0136が担うと明記されている。本branchには未取り込み。
- 元チェックアウトの保全指示: `docs/working/handoff/master.md`。他worktree・stash・未追跡物・inboxの扱いを維持する。
- 旧構成の履歴: ADR-0152は0157によりSuperseded。旧v2計画`docs/working/plans/2026-09-09-isolated-verification-v2.md`と旧Linuxレビューは参照資料だけで、実装再開しない。
- プロジェクトの目的・方針: `docs/overview/project-purpose.md`（対象ルートD:/Dev/002_AiDev/MakeAiInstructions、参照内容はmaster 5350b9fの同パス。本branchには未取り込み）。判断根拠はADR-0130・0183。
- 判断の分担: ADR-0158の補助設計委任（`docs/current/specs/2026-09-09-isolated-verification/00-overview.md`「判断の分担と参照」、承認時点b7941f3）。実機・設定・モデル操作は個別承認（ADR-0162、ADR-0192）。

## 完了済みタスク

- [x] 2026-09-17 新Codex固定テンプレートでの能力/起動/復旧、proposal profile生成、Codex主担当からの候補比較・合成原本への採用・同一テストrecheck。6台すべて停止。結果はcandidate-supported/current-pass。Issue-0151 closed。

- [x] 2026-09-17 443番限定への訂正と提案用VM2台の証拠取得。正本: docs/records/experiments/2026-09-17-v3-task9-proposal-probes.md。af00b8c5は通信・認証・資源・外側停止、7b8f20ebは異常終了・自動停止・復旧を確認。全8台stopped。

- [x] タスク9(a-2)の選択肢2実装・11群検証・独立レビューと修正差分再確認（2026-09-17）。正本は同日のtask9a2-implementation-validation.mdとtask9a2-independent-review.md。

- [x] タスク9(a) の読み取り調査（sbx 0.42.1 の資格情報の渡し方と通信許可の設定方法）。センチネル置換方式・グローバル既定は暗黙拒否・codexキット既定13ドメイン・`policy check network --sandbox --json` が読み取り専用で認可器を評価、を実測。構成の決定は ADR-0199（Proposed）。停滞検出の欠落は Issue-0148 へ起票（2026-09-16 完了）。
- [x] v3全体の実装計画の草案作成（bd3beca）と第1回確定前レビュー反映。相談事項1〜3をADR-0193〜0195（Proposed）に記録（47109dc、2026-09-15 完了）。
- [x] 実装計画の確定前レビュー反復（フル4回＋差分5回、いずれも新規 claude-opus-5）と相談事項4〜7の確定（ADR-0193改訂・0196・0197）。第9回反映後に「このまま確定」で plan 確定点を通過。不採用は第5回 m-F の1件（2026-09-15 完了）。
- [x] 残る能力試験の未特定事項を読み取りで特定（SSH転送の実体・資源割当の外側記録・起動世代の取得元・非自動起動の代替手順）。記録は2026-09-14-v3-capability-test-methods.md、コミットe02c32c（2026-09-14 完了）。
- [x] 試験A〜Dを新規VM `iv-sbx-capability-20260914-01`（ID 0baac92d-251c-4f34-9d8f-6f14a9c238c6）で実施し全件合格。VMは停止したまま保持、削除なし。ADR-0192で個別承認を保存（2026-09-14 完了）。
- [x] SSH転送falseの保存、daemon停止、利用者の通常起動後の設定・既存VM照合を完了。`cf853d2`、ADR-0162、継続調査記録を参照。
- [x] v1のコピー・履歴・プロセス管理・結果照合を先行実装し4群の試験成功。詳細はhistory-copyレビューとscripts/verification/README.md。
- [x] sbx 0.42.1のユーザー導入・Dockerログイン・global deny-all設定。導入・smoke記録に個別承認を保存。
- [x] sbx内部socket障害を切り分け、通常PowerShell起動で回避。合成ファイルと履歴の搬入、通常ユーザーで出力、終了7、回収、原本保全、VM停止を確認。smoke記録20:21節参照。
- [x] v3の4責務・5仕様を独立レビュー3回で確定し、ADR-0157/0158を設計としてAccepted。保存点b7941f3。
- [x] 資源条件とclipboard例外を試作限定で承認・反映し、差分レビュー2回で確定。ADR-0159〜0161をAccepted。保存点5259d22。

## 進行中のタスク

- [ ] **最新の残作業**: Task9のClaude Code主担当からの同じ往復（実際に共通CLIを起動させる。caller値の変更で代用しない）、サイクル全体整合検査・最終レビュー。Anthropic送信/追加VMは前回承認の対象外なので、具体的な送信内容・起動経路と台数を用意して個別承認を得る。Codex側の試験やOAuth登録を繰り返す必要はない。

- [ ] **Task9の残作業**: 訂正実装・11群・独立レビュー・実機2台は完了。model、startupArgv、executableInVmの確定とproposal profile生成、Claude Code/Codex双方の最小モデル往復・recheckが残る。モデル往復・追加VMの操作案はまだ未承認。

- [ ] **2026-09-17の停止点**: proposal probeの1台目を実施し、実効allowが`:443`であることと、policy checkの正常拒否が終了1を返すことを確認。旧実装は両方に非対応。2台目・モデル往復・profile生成は未実施。修正案は最新実験記録の末尾。追加allow・専用キットは不要という提案であり、方針再確定前にコードを変更しない。既存6台を起動・削除しない。

- [ ] **タスク9の実機確認**: 選択肢2（auth.openai.com/chatgpt.comの全ポート）は承認済み。タスク9(a-2)の実装とレビューは完了し、次は操作承認後のOAuth登録と提案用VM2台の証拠取得。
  - 実装・検証: `docs/records/reviews/2026-09-17-task9a2-implementation-validation.md`。全11群合格後、レビュー修正3ファイルの対象試験も合格。実機での成立とは区別する。
  - 独立レビュー: `docs/records/reviews/2026-09-17-task9a2-independent-review.md`。Readのみのclaude-sonnet-5、全体1回＋差分1回。F1/F2解消・新規指摘なし。レビューと試験の実行セッションはすべて終了。
  - 次の操作案: `docs/working/plans/2026-09-17-task9-proposal-probe-approval.md`。CPU2/2GiB・各3600秒の足場、2ホスト全ポート許可、その他11ホスト拒否。設定は `.tmp/task9-probe-approval/proposal-probe-settings.json`。
  - 読取り確認（2026-09-17）: daemonはrunning、既存5VMはstopped、secret登録0件。更新通知はあったがsbxは0.42.1のまま。設定変更・認証・新VM作成・モデル往復はまだ行っていない。
- [ ] **現在の作業**: 実装計画のタスク1〜7は完了（2026-09-15〜16、`subagent-driven-development`。主担当は master 側の作業ディレクトリから絶対パスと `git -C` で本worktreeを扱った。利用者がスマホから Remote Control 中で承認プロンプトに応答できないため）。ブランチ全体の最終レビュー（3分割、いずれも With fixes・Critical なし）と最終修正（22件、7dc261f〜7450e74）も完了し、差分再確認は3分割とも解消。最終修正後の独立試験ランナーは11群合格・1577秒。
  - 記録の正本: `docs/records/reviews/2026-09-16-v3-implementation-tasks1-7.md`（結果・レビュー経過・主担当が下した判断のうち確認を勧めるもの・未対応で残したもの・タスク8a の確認事項）。計画の各タスク末尾の `逸脱記録:` 26行。台帳（未追跡）は `.superpowers/sdd/2026-09-14-isolated-verification-v3-implementation/progress.md`。
  - タスク8完了（2026-09-16、利用者が「1で」で個別承認、利用者がデーモンを起動）: 8a はVM `iv-48830e99-probe`（f0272f46-49bb-4d67-99ba-12468c153c6b）1台で証拠を取得（python3 3.14.4・標準ライブラリ297件、unittest 要約は stderr、対照5種、出力上限の打ち切り、1800秒の連続保持、probe 強制終了→約35秒で自動停止→復旧操作が停止済みを確認）。コミット d124a35・0bc5524・231fad6。8b はVM `iv-420e848c-before`（29d60f42-49e5-45e0-bbf2-8d1567401407）と `iv-420e848c-after`（70b37670-a291-4444-83d0-2012c9905e59）で公開操作を実証（before 終了1・after 終了0、transportVerified 両方 true、activationRecord 8条件、停止確認）。コミット dc8c847・2706cdb・825f991。記録は `docs/records/experiments/2026-09-16-v3-task8a-probe.md` と `…-task8b-public-operations.md`。作成した3台は stopped で保全、既存2台は不変。ランナーは 8a 後 1684秒・8b 後 1822秒でいずれも11群合格・件数不変。
  - 残件は解決済み: 復旧操作は Lease 取得後の照会失敗でも保存した recovery-result を返す（`9f4ce11`。利用者の 2026-09-16「1で」の指示。差分再確認で要件5件を確認）。修正後のランナーは11群合格・1705秒。
  - 経過の詳細（タスクごと）: タスク1完了（コミット 8e345a5・06fef83・9aea7bf、RequestCopyV3 61ケース成功、既存4群不変、レビュー承認・Minor 8件は台帳へ繰り延べ）。タスク2完了（コミット 9ab6a8a・22069d7・1f12d66・修正 d544821、ExecutionV3 12ケース成功、Execution 7不変、修正1回で再レビュー承認・Minor 7件は台帳へ繰り延べ）。タスク3完了（コミット f56176e〜bcb66e2・修正 1fb668a・f04fdd2、SbxRuntimeV3 18ケース成功〈約9分〉、レビューは差分が大きくツール上限に達したため本体側・試験側の2体に分割、Important 7件＋引き上げ2件を修正1回で解消）。途中で Issue-0147（MSIX 版 pwsh の ProcessHost で非パッケージの子がジョブに入らず停止が sbx.exe に届かない）を検出し、統合採用して 1ab11c6・2187ff3 で修正（ExecutionV3 17ケース、差分再レビュー承認）。Issue-0147 は実機 sbx.exe の子プロセス生成の観測（タスク8a）まで open。2026-09-15 に利用者がトークン消費を理由に主担当を Opus へ切替え、以後の実装担当は Opus・タスクレビューは Opus・差分再レビューは Sonnet。タスク4完了（コミット 366dc92・4e5582c・0e01f4f・修正 7126c72、ProposalV3 14ケース成功〈約4分〉、Important 1件＋ブリーフ整合2件を修正1回で解消）。タスク5完了（コミット ae7f552・91306b3・e955935・修正 6b2816a・014019b、ReplayV3 15ケース成功〈約6分〉、Proposal と Replay の重複した共通処理を RequestCopy の公開補助へ集約、daemonInstance の照合と import 検出の漏れを修正1回で解消）。タスク6完了（コミット a6638d9・a97fdf3・55cbddd・修正 7c4d6c6・895a2bf・0d478a3・d7a14a2、ResultV3 18ケース成功〈約30秒〉、再実行記録と VM の役割・id の対応、PreparedRunV3.settings の profile による能力証拠の照合、提案・再実行・照合で重複していた補助の RequestCopy への集約を修正1回で解消）。タスク7完了（コミット bd74ef6・dfc4aef・7afc53f・修正 36e93ce・3962738、CliV3 15ケース成功〈約3.5分〉、ランナーは11群〈約24分〉。全体期限に達した実行も型付き結果として照合を通す形に修正し、期限後のデーモン照会拒否を blocked と誤表示していた SbxRuntime の既存欠陥を統合修正。期限到達で Lease を取得できない場合の扱いを ADR-0198〈Proposed〉に記録）。実装タスク1〜7はすべて完了し、次はブランチ全体の最終レビュー。逸脱記録3行を計画のタスク1末尾に記録。台帳は `.superpowers/sdd/2026-09-14-isolated-verification-v3-implementation/progress.md`（未追跡。判断の一覧・繰り延べ Minor・各タスクの BASE/HEAD を持つ。セッション再開時はこの台帳と git log を正とする）。
  - タスク9(a) 完了（2026-09-16、主担当が自ら実施。実行を伴う調査の委譲は、セッション実行中に制限付きエージェント定義を追加できず保護条件を満たせないため見送った〈`subagent-dispatch` の `references/inspection-isolation.md`〉）。決定は ADR-0199（OAuth のセンチネル方式・許可は `auth.openai.com:443` と `chatgpt.com:443` の2件・残る11ドメインは作成時に明示拒否・`policyExpectation` の役割別化・両条件の観測方法・不足時は `policy log` で特定して利用者に諮る）。
  - ADR-0199 の確定前レビューは終了（2026-09-16、フル実施1回＋差分再確認1回、いずれも claude-sonnet-5）。指摘は初回8件・差分再確認3件で全件採用し、ADR へ反映済み。記録は `docs/records/reviews/2026-09-16-adr-0199-pre-finalization-review.md`。差分再確認の指摘#3（`task-9-brief.md` に決定6(c) の検査項目が無い）は ADR の対象外として、**決定3の実装変更に着手する時点で `.superpowers/sdd/2026-09-14-isolated-verification-v3-implementation/task-9-brief.md` と実装計画のタスク9行へ反映する**（未反映）。
  - 次の実装変更（ADR-0199 決定3・4）: `SbxRuntime.psm1` の作成 argv（`--deny-network '*'` の役割別化）、`runtime-profile.schema.json` の `policyExpectation.networkPolicy` 定数、`New-VerificationActivationRecord` の policy 検査、`tests/Invoke-SbxPilotProbe.ps1` の proposal 対応（role と固定argv の引数化）、`tests/fixtures/proposal-probe-settings.json`。いずれも最終レビュー済みの箇所のため試験追加と再レビュー、ランナー再実行（約30分）が要る。
  - 残り: 上記の実装変更 → タスク9の承認区切り（計画「実行承認を求める具体的な区切り」表のタスク9行）を提示し個別承認を得る（利用者の `sbx secret set openai --oauth` の実行を含む）→ 証拠取得VM 2台 → `pilot-source` で1往復 → サイクル全体整合検査（ADR-0162・0192〜0198 の昇格判定を含む）。試験の実行時は PATH 調整（Codex の junction をサンドボックスが拒否するため代替 codex.cmd を前置）と、試験の run 名 8 文字以下（Issue-0146）を維持する。
  - 判断の分担: ADR-0158の補助設計委任は有効。実機・設定・モデル操作の承認はADR-0162・0192の範囲に限り、計画のタスク8・9は個別承認を別に得る。逸脱の型判定と計画への逸脱記録は主担当が行う（plan-deviation-defaults 0.1.29）。

## 未着手のタスク

- [ ] v3全体の実装計画のタスク9（個別承認後。認証方式と通信許可リストの実測が前提。デーモンは 2026-09-16 に利用者が起動済み〈PID 25888〉だが、次セッションでは状態を再確認する）。
- [ ] タスク9で残る実証: `Invoke-VerificationReplay` の統合、提案側一式（profile・証拠取得2台）、失敗経路の実機実証、稼働中の他VMの非停止、デーモン切断の注入、負荷試験の取り直し、`executableInVm` の絶対パス。
- [ ] 最終レビューで繰り延べた Minor（`.superpowers/sdd/2026-09-14-isolated-verification-v3-implementation/final-fix-findings.md`「繰り延べ」節。試験の組み立て補助の約120行の重複、profile 拒否が照合を通らない経路など）の扱い。
- [ ] Issue-0146（run 配下のパックファイルパスが 260 文字に達すると git bundle unbundle が失敗）の対策採否。本サイクルは試験側の回避のみ。
- [ ] Issue-0148（打ち切り条件が全体期限と出力量上限だけで、出力が止まっても停滞を検出できない）の対策採否。2026-09-16 の利用者判断で本サイクルは `Execution.psm1` を変更しない。タスク9は全体上限に余裕を持たせて進める。
- [ ] Issue-0149（提案の受け渡し契約に未解決の前提・質問の欄が無く、中の担当が主担当へ問い返せない）の対策採否。2026-09-16 の利用者判断で本サイクルは `proposal.schema.json` を変更しない。
- [ ] Issue-0147 の残る確認: 実機 sbx.exe が起動から割当までの一瞬（0.03〜0.7 ミリ秒）に子を生むか、SSH 転送ログ行が `"runtime":"<名前>"` を持つか（いずれもタスク8a で観測）。
- [ ] 残る未実証: daemon停止を伴う切断・自動起動競合の注入、実行中の保護変更検知、通信・共有・その他ホスト経路（試験Aのdeny-all拒否は転送ポートの対照に限る）、認証・最小モデル試験。いずれも別承認。
- [ ] 実装完了時のサイクル全体整合検査と最終レビュー。ADR-0162・0192のAccepted昇格を含む。masterへのマージ・振り返りはまだ対象段階ではない。

## 既知のブロッカー・懸念

- **解消した停止理由**: 初回の規則不一致は443番限定への訂正承認・実装・対象試験で解消した。具体的なレビュー送信承認も取得し、独立レビュー完了。失敗run f107bb84は停止保全してResumeしない。検証完了後に、再承認済みの新規2台を別runIdで順次実行する。

- Issue-0150は選択肢2の採用で解決済み。37ファイルの外部レビュー送信も利用者の明示承認後に実施・完了。次の個別承認対象はOAuth登録と新規proposal VM2台。

- ADR-0199 の OAuth 保存はグローバル（全サンドボックス共有）で、単一VMへ限定できない。本サイクルで新規作成するのは提案用の証拠取得2台と往復用に限り、既存5台は停止したまま操作しない。保存した秘密の後片付けはサイクル終了時に扱う。許可2件で codex が起動できない場合は `sbx policy log` の拒否記録で不足ホストを特定し、利用者に諮ってから再実行する（AIの判断で許可を広げない）。
- 実装中に起票した Issue-0146・0147 が課題索引 `docs/working/issues/README.md` に未追加だった（2026-09-16 に Issue-0148 の採番で検出し、3件分の行を補った）。Issue-0147 の Status は「open（本サイクルで統合採用・修正中）」のままで、タスク8a の観測を受けた更新が未反映の可能性がある。
- sbx daemonは2026-09-16 08:59:47に利用者が通常PowerShellで起動した世代（PID 25888、v0.42.1 cc6e400）で、セッション終了時点も稼働中。次セッションでは `daemon status --json` で状態を再確認する。停止・再起動・resetはAIから行わない。利用者が止める場合は通常の端末から `& 'C:/Users/d12an/AppData/Local/DockerSandboxes/bin/sbx.exe' daemon stop`（未確認の手順なので、止める必要が生じたときに改めて確認する）。
- 作成した試験VMは5台（`iv-420e848c-before`・`iv-420e848c-after`・`iv-48830e99-probe`・`iv-sbx-capability-20260914-01`・`iv-sbx-smoke-20260909-01`）で、いずれもstopped。削除・再作成しない。観測原文は `.tmp/probe-8a/48830e99/` と 8b の作業領域（タスク8b報告に記載）。
- （旧）sbx daemonは2026-09-14 23:00:28に利用者起動の新世代（PID 29352、v0.42.1）で稼働していたが、2026-09-15のPC強制再起動後の状態は未確認だった。停止・再起動・resetはAIから行わない。停止中に自動起動しうる`ls`/`inspect`/`settings`は、`daemon status`（自動起動しない。今回3回確認）でrunningを確認した後だけ呼ぶ。
- 試験VM `iv-sbx-capability-20260914-01` と旧smoke VM `iv-sbx-smoke-20260909-01` はいずれもstoppedで保全。削除・再作成しない。`.tmp/sbx-capability-20260914/` の原文とスクリプト（guest-probe.sh、bounded-load.py、agent-protocol-probe.py）も保全。
- 利用者はリモート操作中の場合があり、通常PowerShellでの起動を求める手順が即時に実行できないことがある。今回は利用者側で起動が行われたが、AIから起動する案（ツール経由・タスクスケジューラ）は採用していない。
- masterの最新記録（61ddef3、13cbe7a）とADR-0163〜0191は本branchに未取り込み。ADR採番は全ブランチの最大値に合わせて0192とした。索引は0162の次に0192が並ぶ。
- 過去のsbx導入・smokeの個別節目行がhandoffにない。実験記録は存在するが今回の実施扱いで埋めない。
- sbx実体はC:/Users/d12an/AppData/Local/DockerSandboxes/bin/sbx.exe。状態ディレクトリは同AppData配下のsandboxes/state/sandboxd（runtimeファイル・daemon.log・PIDファイル）。旧退避sandboxd-preserved-20260909-02/03は保全。
- .tmpの試験・コピー・ログ・junctionを保全。既存試験VM・取得イメージ・returned.txtも削除しない。原本や他worktreeへ試験変更を加えない。
- 外部仕様退避はC:/Users/d12an/.ai-dev-review-snapshots/MakeAiInstructions/配下。レビューはすべて完了済み。過去の送信承認を別資料の送信へ流用しない。
- LoopForAlphaのDocker Desktopは別接続。設定・コンテナは保全。旧Windowsのホスト上子構成は自由な実検証へ使わない。
- 元チェックアウトの他worktree、stash 6e959892b6e00600006456172237f27d7957fa01、.claude/agents、docs/conversation_log.md、inbox3件は操作しない。詳細はmaster handoff。
- プラグイン導入版は0.1.29（本セッションのスキル一覧で確認）。仕様コミットをプラグインの更新・公開と扱わない。

## 節目ごとの確認記録

- 2026-09-17 Codex側モデル往復完了・Issue-0151 close: ADR=0201（利用者の「1で」による固定テンプレート変更） / worklog=棄却（既存の承認・実機検証手順内）

- 2026-09-17 起動前確認でshell画像の流用を検出・停止: ADR=0200（元の操作承認記録。変更案は未承認） / worklog=棄却（既存の実機停止・診断手順で捕捉）

- 2026-09-17 最小モデル往復の準備: ADR=0200（操作案・個別承認待ち） / worklog=棄却（既存の承認前準備とスキーマ検査の範囲）

- 2026-09-17 proposal新規2台の再試験完了・Issue-0150 close: ADR=0199（承認済み条件の成立確認） / worklog=棄却（既存の修正・検証・承認手順内）

- 2026-09-17 443番限定の訂正 spec 確定点・修正検証: ADR=0199 / worklog=棄却（既存手順内） / review=フル実施（gpt-5.6-sol・1回）＋差分再確認（gpt-5.6-sol・1回・実質的な収束）

- 2026-09-17 443番限定への訂正承認・実装と回帰試験: ADR=0199（利用者の「1で」を記録） / worklog=棄却（既存の不一致訂正・検証・送信承認手順の範囲）

- 2026-09-17 タスク9の初回proposal試験中断・実効通信規則の訂正: ADR=0199（事実の訂正注記のみ、方針変更は未承認） / worklog=棄却（未実測前提の不一致は既存の実機停止・診断手順で捕捉）

- 2026-09-17 タスク9(a-2)完了・改訂ADR-0199のspec 確定点: ADR=0199 / worklog=棄却（既存の検証・修正・承認手順） / review=フル実施（claude-sonnet-5・1回）＋差分再確認（claude-sonnet-5・1回・実質的な収束）

- 2026-09-17 タスク9(a-2)の実装・11群検証と送信承認待ち: ADR=0199（承認済み方針の実装、独立レビューは未実施） / worklog=棄却（既存の検証・修正・承認手順の範囲）

- 2026-09-16 選択肢2の明示承認と実装再開: ADR=0199（利用者回答により2ホスト・全ポートへ改訂、Issue-0150 close） / worklog=棄却（既存の判断記録・再開手順の範囲）

- 2026-09-16 タスク9(a-2)の前提不足検出と判断待ち: ADR=なし（実現方法は未決、Issue-0150へ分離） / worklog=MakeAiInstructions-2026-09-16-06

- 2026-09-16 タスク9(a-2)の再開と計画への引き継ぎ反映: ADR=0199（確定済み決定に従う、追加決定なし） / worklog=棄却（既存の再開・引き継ぎ手順の範囲）

- 2026-09-16 セッション区切りの引き継ぎ確定（タスク9(a) 確定・実装変更の着手前）: ADR=なし（利用者の区切り指示、方針変更なし） / worklog=`MakeAiInstructions-2026-09-16-05`
- 2026-09-16 タスク9(a) の構成確定と ADR-0199 コミット・spec 確定点: ADR=0199（Proposed。昇格はサイクル全体整合検査で） / worklog=`MakeAiInstructions-2026-09-16-04` / review=フル実施（claude-sonnet-5・1 回）＋差分再確認（claude-sonnet-5・1 回・提示後確定（実質的な収束に至らず））
- 2026-09-16 タスク9(a) の読み取り調査完了と構成の決定（認証方式・送信範囲・policyExpectation の役割別化）: ADR=0199（Proposed。昇格はサイクル全体整合検査で） / worklog=`MakeAiInstructions-2026-09-16-02`・`MakeAiInstructions-2026-09-16-03`
- 2026-09-10 作業中断の引き継ぎ確定: ADR=なし（ユーザーの中断指示、方針変更なし） / worklog=棄却（既存の中断・保全手順内）
- 2026-09-09 spec 確定点: ADR=0151・0152 / worklog=棄却（既存の機械検証と確定手順） / review=フル実施（claude-sonnet-5・1回）＋差分再確認（claude-sonnet-5・1回）＋機械検証（1回・提示後確定（実質的な収束に至らず））
- 2026-09-09 ADR-0151・0152 Accepted 昇格: ADR=0151・0152 / worklog=棄却（既存の昇格手順） / cyclecheck=非該当（実装前昇格）
- 2026-09-09 履歴レビュー完了・ADR-0150 Accepted 昇格: ADR=0150 / worklog=棄却（既存のレビュー照合・修正・検証手順の範囲） / cyclecheck=実施（修正: Issue-0136）
- 2026-09-09 plan 確定点: ADR=なし（既存仕様と工程の選択、設計変更なし） / worklog=棄却（deltaなし） / review=見送り
- 2026-09-09 先行範囲の確認・ADR-0149 Accepted 昇格: ADR=0149 / worklog=棄却（既存の確認手順内） / cyclecheck=実施（修正: Issue-0136）
- 2026-09-09 v2 plan 確定点: ADR=なし（既存計画の主担当実行を選択） / worklog=棄却（deltaなし） / review=見送り
- 2026-09-09 v3 spec 確定点: ADR=0157・0158 / worklog=棄却（既存の独立レビュー・指摘照合手順内） / review=フル実施（gpt-5.6-sol・1回）＋差分再確認（gpt-5.6-sol・2回・実質的な収束）
- 2026-09-09 ADR-0157/0158 Accepted 昇格: ADR=0157・0158 / worklog=棄却（既存の設計確定手順内） / cyclecheck=非該当（実装前昇格）
- 2026-09-10 試作条件改訂 spec 確定点: ADR=0160・0161 / worklog=棄却（既存の独立照合・修正手順内） / review=差分再確認（gpt-5.6-sol・2回・実質的な収束）
- 2026-09-10 ADR-0159〜0161 Accepted 昇格: ADR=0159〜0161 / worklog=棄却（既存の設計確定手順内） / cyclecheck=非該当（実装前昇格）
- 2026-09-10 セッション切替の引き継ぎ確定: ADR=なし（合意済み工程の中断、方針変更なし） / worklog=棄却（既存の中断・正本参照整理手順内）
- 2026-09-14 能力試験の取得元特定と実機試験A〜Dの完了: ADR=0192（実機試験の個別承認、Proposed） / worklog=`MakeAiInstructions-2026-09-14-02`
- 2026-09-15 実装計画の草案とレビュー2回の反映・再起動からの復旧: ADR=0193〜0195（相談1〜3、Proposed） / worklog=`MakeAiInstructions-2026-09-15-01`
- 2026-09-15 v3実装計画の plan 確定点: ADR=0193改訂・0196・0197（Proposed。昇格は実装完了時のサイクル全体整合検査で） / worklog=`MakeAiInstructions-2026-09-15-02` / review=フル実施（claude-opus-5・4 回）＋差分再確認（claude-opus-5・5 回・提示後確定（実質的な収束に至らず））
- 2026-09-15 セッション区切りの引き継ぎ確定（実装着手前）: ADR=なし（利用者の区切り指示、方針変更なし） / worklog=棄却（同日02に記録済みの差分以外なし）
- 2026-09-15 タスク1完了（v3の依頼・設定・固定入力の検査と基準版準備、レビュー承認）: ADR=なし（逸脱は実体に合わせる調整のみ、既存欠陥は Issue-0146 へ起票し設計変更なし） / worklog=`MakeAiInstructions-2026-09-15-04`
- 2026-09-15 タスク2完了（stdin転送・合算出力上限・背景起動のプロセス実行、修正1回でレビュー承認）: ADR=なし（逸脱は実体に合わせる調整のみ、Important 2件はコード修正で解消） / worklog=棄却（レビュー指摘と修正は既存の実装時レビュー工程の範囲内で新規の差分なし）
- 2026-09-16 セッション区切りの引き継ぎ確定（タスク8完了・タスク9着手前）: ADR=なし（利用者の区切り指示、方針変更なし） / worklog=棄却（同日01に記録済みの差分以外なし）
- 2026-09-16 タスク8完了（8a の証拠取得と 8b の公開操作の実証、実VM 3台を作成し stopped で保全）: ADR=なし（実機の観測は計画の前提どおりか安全側で、保護条件の変更なし。実測で判明した2点は参照知識と Issue-0147 へ追記） / worklog=`MakeAiInstructions-2026-09-16-01`
- 2026-09-16 ブランチ全体の最終レビュー（3分割）と最終修正（22件、差分再確認3分割で解消、ランナー11群合格）: ADR=なし（修正は最終レビューの指摘への対応と実体に合わせる調整で、新たな設計判断なし。復旧操作の残件は記録して利用者の判断へ） / worklog=棄却（既存の最終レビュー工程の範囲内で新規の差分なし）
- 2026-09-16 タスク7完了（共通CLI・11群ランナー・README、修正1回でレビュー承認）: ADR=0198（期限到達で Lease を取得できない場合も CLI は VM を作らない型付き結果を照合へ渡す。ADR-0158 の委任に基づくAI判断、Proposed） / worklog=棄却（既存の実装時レビュー工程の範囲内で新規の差分なし）
- 2026-09-16 タスク6完了（3入力の照合と結果、修正1回・分割再レビューで承認）: ADR=なし（逸脱は実体に合わせる調整と、試験の停止猶予の期待値の訂正のみ。共通補助の集約は計画の調整 (a) の適用） / worklog=棄却（既存の実装時レビュー工程の範囲内で新規の差分なし）
- 2026-09-15 タスク5完了（通信なしVMでの修正前後の再実行と外側記録、修正1回でレビュー承認）: ADR=なし（逸脱は実体に合わせる調整と、計画内の Environment 参照の食い違いの訂正のみ） / worklog=棄却（既存の実装時レビュー工程の範囲内で新規の差分なし）
- 2026-09-15 タスク4完了（提案VMの起動・回収・未信頼Envelopeの検査、修正1回でレビュー承認）: ADR=なし（逸脱は実体に合わせる調整と、エクスポーターを標準入力で渡す設計変更案の不採用のみ） / worklog=棄却（既存の実装時レビュー工程の範囲内で新規の差分なし）
- 2026-09-15 タスク3完了（sbx実行基盤、分割レビュー・修正1回）と Issue-0147 の統合修正: ADR=なし（Issue-0147 は計画逸脱判断の既定の「範囲外の既存欠陥」の統合採用で、不在の根拠は同 Issue に記録、保護の設計は不変） / worklog=`MakeAiInstructions-2026-09-15-05`

## 次セッション開始時のアクション

1. 最新実験記録2026-09-17-task9-codex-roundtrip.mdを読む。Codex側の公開CLI実行・採用・recheckは成功、profileも生成済み。実行中のVM/モデル/レビュー/テストはない。旧shell画像の流用問題とその承認待ちは解消済み。
2. Claude Code主担当からの同じ往復の実行方法を具体化する。ホスト側Claudeに無制限の実行権限を渡さず、既存のsubagent-dispatchの実行経路保護を満たす方法を確認する。必要な合成題材・依頼・結果のAnthropic送信と新規VMを具体化して個別承認を得る。現在の.tmp/m9/sourceは採用後の正しい加算に変わっているので、バグ再現用に流用せず、元fixtureから別の合成原本を作る。
3. 全15台はstoppedで保全し、起動/削除しない。sbx照会前にdaemon statusを確認。OAuthの後片付けはサイクル終了時に別扱い。profileの証拠ファイルはハッシュ固定されているので追記しない。
4. 両主担当の実証後、全体整合検査・ADR昇格判定・最終レビューと統合工程へ進む。Task9全体とmaster統合は未完了。
## 重要な意思決定の履歴

- ADR-0199: 提案用VMはOAuthのセンチネル方式で認証し、通信許可を `auth.openai.com:443`・`chatgpt.com:443` の2件に限る。2026-09-16 の利用者の個別回答、Proposed（昇格はサイクル全体整合検査で）。`policyExpectation.networkPolicy` の `"deny *"` 固定を役割別へ改める設計変更を含む。
- ADR-0198: 全体期限の後に pilot 排他を取得できない場合も、CLI は VM を作らない型付き結果を照合へ渡す。2026-09-16 の実装時レビューを受けた ADR-0158 の委任に基づくAI判断、Proposed（昇格は実装完了時のサイクル全体整合検査で）。
- ADR-0193〜0195: 実行中はセッション保持でsbxの自動停止を避ける／CLI異常終了後に記録済みVMを停止する／登録MCPサーバー0件を「MCPなし」の条件とする。2026-09-15のユーザー選択、Proposed。0193は同日に停止順序を改訂（改訂記録あり）。
- ADR-0196: 試作の間はデーモン切断の検知を未確認の制限として認める（acceptedLimitations 3件目）。2026-09-15のユーザー選択、Proposed。仕様02・03を更新済み。
- ADR-0197: 提案用実行設定の証拠は提案用VMで取り直し、負荷中の外側停止だけ既存記録を使う。2026-09-15のユーザー選択（案1の懸念を説明のうえ案3）、Proposed。
- ADR-0192: 残るsbx能力試験を新規VM1台で順に実施する。個別承認、試験A〜D合格。全体整合チェックポイントで昇格するProposed。
- ADR-0162: ローカルsbxのSSH転送を無効化する操作を個別承認。保存・停止・通常起動後照合済み。全体整合チェックポイントで昇格するProposed。
- ADR-0145〜0150: 検証担当の追加テスト作成、主担当2種・検証担当Codex、共通CLI、独立コピー、Git履歴提供。
- ADR-0151: Linux先行。ADR-0152のホスト上子と専用MCP構成は0157により置換済み。
- ADR-0153〜0156: 子本体隔離の再検討、既存基盤比較、deny-all設定、状態保全による起動復旧。根拠は各ADRとsmoke記録。
- ADR-0157/0158: 提案と採否用再実行の分離、準備・提案・再実行・照合の4責務と補助設計の分担。Accepted。
- ADR-0159〜0161: 保護目的の再検討、試作限定のVM資源保護とclipboard文字列書込例外。Accepted。通常運用・モデル起動の承認ではない。
