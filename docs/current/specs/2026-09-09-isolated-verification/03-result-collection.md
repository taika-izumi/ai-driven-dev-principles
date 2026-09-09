# 原本・再実行記録・提案の照合と結果返却

## 対象と責務

scripts/verification/Result.psm1、result.schema.jsonを所有する。Complete-VerificationRun(PreparedRunV3, ProposalResultV3, ReplayResultV3) -> VerificationResultV3を提供する。既存v1の2引数呼出しは維持して内部のComplete-LegacyVerificationRunへ分岐し、v3は3引数を必須とする。版の混在と未実装v2を拒否する。

正常なPreparedRunV3を作れない場合は、同モジュールのNew-VerificationFailureResult(RequestContext, Failure)をCLIが呼ぶ。RequestContextは確定したrunId/runRoot/sourceRootまたは各null、Failureはstatus/stage/reason。無効な準備結果を通常の照合関数へ渡さない。

PreparedRunV3が正常なら、Proposalの失敗も通常の3入力照合へ渡す。CLIはProposalの非ready結果を保持し、04のNew-VerificationReplayNotRunで未実行結果を作る。例外は該当ブロックが作成済みVMと停止状態を含む型付き失敗結果へ変換する。準備後に結果を組み立てられない例外はNew-VerificationFailureResultへ判明済みのVM/停止情報を追加したRequestContextを渡し、未起動扱いに戻さない。

VM作成後のactivation失敗は02のruntimeFailureにある確定済みIDと停止状態を照合対象に含める。activationRecordがnullであることを未作成の根拠にしない。停止できた起動失敗はblocked、作成不明・停止未確認はincompleteとし、時間超過は既定の優先順位を適用する。

## 結果の契約

VerificationResultV3はschemaVersion=3、runId、status、summary、sourceState、baselineState、proposalVerdict、replayVerdict、checks、findings、artifacts、unverified、execution、previousRunId、runRoot、sourceManifestPathを持つ。未知キーを禁止し、子の応答へ外側のstatusを設定させない。

scopeとlimitationsも必須とし、synthetic-pilot、["clipboard-text-write-possible","pid-count-unbounded"]を外側の実行設定から付与する。これらは承認した既知の制約なのでunverifiedに混ぜて無条件にincompleteとせず、成功時も表示を省略しない。入力検査前の失敗ではscope=null、limitations=[]を許す。CLI開始時にも同じ制約を診断表示し、clipboardの自動操作は行わない。

scopeを付与する前にPreparedRunV3のpilotInputHashと記録現物、sourceRoot/sourceManifestHashの一致を再照合する。未照合・不一致でsynthetic-pilotの正常結果を作らない。executionにpilotInputIdと固定入力記録のパス/hashを載せる。対象版の変更は既存のsource_changedまたはincompleteへ写像し、例外の承認範囲を拡張しない。

- sourceStateはunchanged/changed/unreadable。誰が原本を変更したかを推測しない。
- baselineStateはunchanged/changed/unreadable。基準版とmanifestの両方を照合する。
- proposalVerdictはreference-only（正常な提案）またはnull。子のpass宣言を採否に使わない。
- replayVerdictはcandidate-supported/not-reproduced/still-failing/reproduced/current-pass/current-fail/undetermined。意味は下表。
- checksは外側のrole/commandId/sandboxId/記録パス・SHA256/終了値の配列。架空の子内部commandIdを作らない。
- findingsは未信頼の子の説明、artifactsはkind/path/size/sha256の検査済み一覧。再検証では前回からのテストも由来を明記する。
- executionはproposalCreated、replayCreatedCount、proposalStopped、replayAllStoppedと失敗段階。未作成の停止値はnull、作成した対象はtrue/false。作成不明は失敗理由として保持してincomplete。previousRunIdは再検証時だけ値を持ち、それ以外null。

| status | 意味 | CLI終了 |
|---|---|---|
| completed | 必要な証拠と停止を照合できた | 下記判定により0または1 |
| blocked | 依頼・準備・起動前条件が成立しない | 2 |
| timed_out | 全体または実行上限に到達 | 2 |
| source_changed | 原本が対象版から変わった | 2 |
| incomplete | 基準版改変、証拠不正、出力超過、停止未確認、その他の未完 | 2 |

優先順位はtimed_out→incomplete（作成不明・作成済み対象の停止未確認または基準版改変）→blocked→source_changed→incomplete（その他）→completed。未作成のnull停止値を事故扱いしない。Proposal/Replayのfailedはincomplete、blockedはblocked、timed_outはtimed_outに写像する。not_runは原因となる上流結果に従い、単独でcompletedにしない。複数問題はすべてunverifiedへ残す。CLIはJSON1件をstdoutへ、診断をstderrへ返す。

## 観測からの判定

| modeと観測 | replayVerdict | completed時のCLI終了 |
|---|---|---|
| candidate-comparison: before非0、after0 | candidate-supported | 0 |
| candidate-comparison: before0 | not-reproduced | 1 |
| candidate-comparison: before非0、after非0 | still-failing | 1 |
| reproduction-only: before非0 | reproduced | 1 |
| reproduction-only: before0 | not-reproduced | 1 |
| recheck: 現在版after0 | current-pass | 0 |
| recheck: 現在版after非0 | current-fail | 1 |
| transport・停止・記録等が不成立 | undetermined | statusに応じ2 |

これらは終了値の観測分類であり、期待する欠陥に由来する失敗か、テストが十分かを自動認定しない。import失敗や悪意あるテストも非0になりうる。主担当が目的・合格条件・テスト内容・診断を照合して採否を判断する。検証器自身の異常をreproducedにしない。

## 照合手順

1. 3入力のschemaVersion/runIdと外側で保存した元データを一致確認する。非ready/not_runなら未実施の証拠を要求せず、成立している段階の記録と失敗理由から上記優先順位で返す。proposal.ready、replay.completedでも単独で信頼しない。実行設定の能力証拠と当該VMのactivationRecordをprofileHash/runId/sandboxId/起動世代で照合する。
2. PreparedRunV3の各manifest期待hashを現物と先に照合し、sourceManifestを用いて原本files/head/headRef/historyRefsを再取得・比較。baseline全体とmanifest自身のハッシュも比較。期待hashを現物から作り直さない。不読も記録し、更新された原本へ古い結果を適用しない。
3. Proposalのmanifest、accepted現物、各replay input、実行開始前の入力照合、testsManifestHashを照合する。beforeとafterのテスト集合・バイトが同じであること、afterの変更がreplacement一覧に限られることを確認する。
4. 外側記録のrunId/role/VM id/profile/template/argv/対象版/時刻/出力パス・ハッシュ/transportVerified/停止状態を確認する。証拠パスは当該control内だけ。複数回の実行は別commandIdとし、過去の同一コマンドを流用しない。
5. 作成したproposalとすべての再実行VMの停止記録を必要とする。reused-testsのproposalは未作成として区別し、停止を架空に記録しない。結果照合からexecを呼んで停止VMを起動しない。作成済み対象の停止未確認の提案やテストを次回recheckへ渡さない。
6. 上表の観測分類を作り、自己申告と外側の観測、未確認事項を別々に返す。原本への自動適用は行わない。
7. control/result.jsonをCreateNewで一度だけ保存。既存結果へ上書きしない。失敗でも保存先がある場合は記録する。

準備前失敗はrunId/runRoot/sourceManifestPath/previousRunId=null、sourceState/baselineState=unreadable、proposalVerdict=null、replayVerdict=undetermined、checks/findings/artifactsは空配列、executionはproposalCreated=false、replayCreatedCount=0、停止値nullと未起動理由を持つ。作成済みのrunRootだけ存在パスとして返す。未起動は停止未確認事故と区別し、blockedの優先順位を不当に上げ下げしない。

## 主担当の修正と再検証

主担当は検証されたテストを採用するか判断し、原本への修正を通常の権限で行う。次回RequestV3.recheckで前回結果とtestPathsを指定する。ファイル本文を手で転記せず、準備処理がハッシュを確認して搬入する。前回がreproduced/still-failingでも実行・停止・テスト保存が完全なら再利用できる。タイムアウト・停止未確認・証拠欠落の結果からは再利用しない。

再検証では同じテストの改変を拒否する。子が別のテストを提案した場合は当該recheckの成功へ混ぜず、別の依頼・runIdにする。新しい原本版のcurrent-passと前回の再現結果を並べて提示する。過去のテスト結果を今回の実測として表示しない。

## 検証

V6/V7を担当。架空の記録、自己申告pass、別VM/版/runId、基準Git改変、出力欠落、同一テストでない比較、開始不明、停止未確認、原本更新、失敗時null書式、既存結果保全をfixtureで検査する。Claude CodeとCodex双方からの実往復は別承認の最小題材で検証する。

関連ADR: 0157、0158。入力は01、提案は02、再実行は04。
