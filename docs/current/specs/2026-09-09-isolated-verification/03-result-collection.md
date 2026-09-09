# 検証結果・実行証拠・再現テストの回収

## 対象と責務

- `scripts/verification/Result.psm1`: v2の応答・実行記録・原本状態・成果物の照合。
- `result.schema.json`: v1先行部品とv2の結果を識別する。

`Complete-VerificationRun(PreparedRunV2, ExecutionResultV2) -> VerificationResultV2`。既存v1の原本・パス・ハッシュ照合を再利用する。現在のcommand_execution専用処理へMCPの記録を偽装して流し込まない。

Result.psm1が版の振り分けを所有する。既存v1処理は内部関数Complete-LegacyVerificationRunとして保持し、v2はComplete-LinuxVerificationRunへ分岐する。PreparedRunV2とExecutionResultV2の片方だけがv2の場合は拒否する。v2の成果物には新しいGet-LinuxWorkArtifactを使用し、workRoot内の相対パスとして解決する。既存Get-VerificationArtifactはv1のrunRoot相対パスと証拠ファイル用なので、包含先だけを変えて共用しない。

## 出力契約

VerificationResultV2は`schemaVersion=2, runId, status, summary, sourceState, agentVerdict, checks, findings, artifacts, unverified, execution, runRoot, sourceManifestPath, recheckManifestPath`を持つ。sourceStateはunchanged/changed/unreadable。schemaVersionの混在・未知キー・不正な型を受理しない。

準備未成立の場合はResult.psm1の失敗応答生成処理をCLIが呼び、無効なPreparedRunを通常の照合関数へ渡さない。未確定のrunId・runRoot・manifestパス・execution・agentVerdictはnull、checks/artifactsは空配列とし、statusとunverifiedに失敗段階を残す。実行領域が存在すれば失敗結果をcontrolへ保存し、保存自体が失敗した場合はその旨も標準出力のJSONへ記載する。存在しない保存先を返さない。

| status | 意味 | CLI終了コード |
|---|---|---|
| completed | 応答・実行・停止・対象版・成果物を照合できた | agentVerdict=passは0、failは1 |
| incomplete | 証拠欠落、応答不正、一部未検証、停止未確認等 | 2 |
| blocked | 依頼・設定・権限・起動・準備が成立しない | 2 |
| source_changed | 準備後の原本ファイル・HEAD・headRef・全参照が更新された | 2 |
| timed_out | 全体またはコマンドの時間上限に達した | 2 |

複数の問題はunverifiedとexecutionへすべて残す。優先するstatusはtimed_out、blocked（未起動、または作業解放前の確認不成立）、source_changed、incompleteの順とし、completedは他の未解決条件が無い場合だけ。completed自体はテスト合格を意味しない。

## 回収の条件

1. effectiveConfigPathが当該control/execution/activation.jsonを指すことと、その存在・schemaVersion・runId・verified判定・証拠ハッシュを検査する。実行側が保存した設定・実行体・実効ツール一覧との一致も確認する。作業解放前の不成立を示す`execution.failure.stage=activation`ならblocked。作業解放後の回収で初めて欠落・不一致・verdict=blocked/unverifiedが判明した場合はincompleteとし、起動時に止められたことにはしない。続いてagent・MCP・コンテナの実行ID、開始・終了、processTreeStoppedとcontainerStoppedを確認する。停止未確認なら作業コピーを安定した成果物として採用しない。
2. Codexの開始・終了・失敗イベントと最終応答のschemaVersion・runIdを照合する。終了コード0だけでは完了としない。
3. checksの各commandIdを、ホストが保存したCommandRecordとMCPの実呼び出しへ一意に対応付ける。実MCPイベントのツール名・入力command・出力commandId、Docker側execIdと実終了コードを照合する。同じコマンドの反復でも別commandIdとして扱い、内容一致だけで過去の実行を流用しない。
4. MCPイベントの具体的なフィールド名は、対象CLI版の実記録から抽出器とfixtureへ固定する。現時点では未取得。イベントを取得できない版や実際の呼び出しへ対応できない記録はincomplete。read_outputは検査の実行回数に数えない。
5. CommandRecordの出力パスは当該control/execution内のホストが生成したものだけを解決し、ファイル・ハッシュ・出力保存完了・exec開始と終了を確認する。中断や出力上限を検査成功へ読み替えない。checksは少なくとも1件の実行が必要。
6. artifactsはworkRoot内の相対パスに限定し、存在・再解析ポイント・範囲外参照・サイズ・SHA256を検査する。`.git`と予約制御領域は成果物に含めない。成功した回収結果には`path, size, sha256`を載せる。検証担当の文字列をホストで実行・importしない。
7. 原本をコピー準備と同じ選択規則で再列挙・再計算し、ファイル・HEAD・headRef・historyRefsを比較する。更新があれば、その旧版についての結果と明記する。誰が変更したかを根拠なく断定しない。失敗・未起動でも可能な範囲で保全状態を返す。
8. `control/result.json`を一度だけ作成する。既存の結果を上書きせず、再試行は新しいrunId。CLIはJSON1件と終了コードを返し、診断を標準出力へ混ぜない。

各checkの回収結果にはcommandId・MCPイベント参照・execId・実コマンド・終了コード・出力の相対パスとハッシュを含める。機械照合が証明するのは実行と対象の対応であり、任意の出力の意味やテストの十分性ではない。意図した欠陥を拒否する検査は、依頼の合格条件に照らして評価する。

## 修正と再検証の往復

主担当は指摘・未検証・実行証拠を読み、再現テストの採否を判断する。採用するテストは前回のartifactsに掲載されたパスで指定し、修正は通常の作業工程で原本側へ行う。元の合格条件を都合よく変更しない。

次回のRequestV2へrecheckを付ける。準備側が前回resultと現物のハッシュ・停止状態を確認し、修正版のコピーへ再現テストを追加する。子はそのテストをコンテナ内で再実行する。結果には前回runIdと原本の新しいmanifestを保持し、再現テストの未実行・改変・入力不足を成功にしない。初回試作ではこの往復を主担当2種から確認する。

利用者には指摘・採否・結果と必要な判断を提示する。依頼JSON・結果JSON・ファイル本文の通常の受け渡しを手動転記させない。既存物の削除・導入・公開はこの往復に含めない。

## 検証

V5・V6・V7の回収側を担当する。AIなしのfixtureで、応答欠落・不正JSON・別runId・架空commandId・MCPとの入力不一致・Docker実行未開始・重複対応・出力欠落・停止未確認・範囲外成果物・原本更新・既存結果の保全を検査する。activationの欠落・古い設定・改変された証拠、v2成果物への`.git`・`../control`等の参照、準備失敗時のnull項目も含める。正常と既知の不合格の対照を含める。

関連ADR: 0145〜0147、0150〜0152。実行側のCommandRecordとExecutionResultV2は`02-isolated-execution.md`、再検証入力とPreparedRunV2は`01-request-and-copy.md`を正とする。
