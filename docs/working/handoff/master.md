# Handoff: モデル裁量と既存手順の比較準備

- **Branch**: master
- **Last Updated**: 2026-09-11 01:12 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 既存sbx実証を再発見 / 初期設定案を撤回し既存成功経路を照合

## 作業の目的・背景

ユーザーの依頼に基づき、独自手順を詳細化する前にモデルに進め方を任せる比較をロードマップへ反映した。比較条件・代表2モデル・2題材・採点・結果による進路は同文書4.0節が正本。実験は未実施。Issue-0140・0124と0.1.26公開・このPCへの導入は完了済みで、運用効果は未評価。

## 関連ドキュメント

- 実行方法の候補と訂正: `docs/records/experiments/2026-09-11-model-discretion-execution-options.md` 末尾。別worktreeのsbx導入・VM試験成功を再発見。Windows機能有効化から始める提案を撤回。既存成功経路と現状の照合が次手。

- 事前確認結果: docs/records/experiments/2026-09-10-model-discretion-preflight-results.md。最新は起動経路補正後のWrite確認結果。古い候補や承認済みパケットを再実行しない。

- 起動操作: docs/records/experiments/2026-09-10-model-discretion-preflight-launch.md。引数・依頼文はcontrol/launch-packet/launch.jsonと関連ファイル。事前確認は実施済み・現在保留。

- 比較準備: `docs/reference/model-discretion-comparison-preparation.md`。CLI・認証・日時処理の再現。利用方式と比較設計はADR-0167・0168（Accepted）。
- 確定した比較仕様: `docs/current/specs/2026-09-10-model-discretion-comparison/00-overview.md` と3ブロック。実行計画: `docs/working/plans/2026-09-10-model-discretion-comparison.md`（ユーザーが追加レビューを見送り確定済み）。
- レビュー準備と停止理由: `docs/records/reviews/2026-09-10-model-discretion-spec-r1-preparation.md`。スナップショット22件、固定検査の結果、資料送信に対する自動承認拒否を記録。
- 初回レビューと指摘対応: `docs/records/reviews/2026-09-10-model-discretion-spec-r1.md`、原報告は同名JSON。6件採用・4件部分採用、手順・採点・検査を修正済み。モデル・題材・上限は維持。
- 差分再確認: `docs/records/reviews/2026-09-10-model-discretion-spec-r2.md`、原報告は同名JSON。前回10件の対応は妥当。追加5件を照合し、環境移設の増設案を採らず既存制約と記述の整合を修正。
- 仕様確定と機械検証: `docs/records/reviews/2026-09-10-model-discretion-spec-finalization.md` と同名JSON。13項目成功、実質的な収束として仕様レビューを終了。
- 準備の実施記録: `docs/records/experiments/2026-09-10-model-discretion-preparation.md`。資材・固定検査・境界プローブ・時間使用と未確認を記録。実体は `D:/Dev/002_AiDev/WorkflowTrials/model-discretion-20260910/`。
- 直近の振り返り: `docs/records/retrospectives/system/2026-09-10-issue-0124-cost-comparison.md`。外部送信承認の追加確認を作業ログMakeAiInstructions-2026-09-10-02に記録済み。
- 直近の実装・検証: `docs/records/reviews/2026-09-10-issue-0124-implementation.md`。設計と承認履歴はADR-0165、計画、設計レビュー記録を参照。完了した作業の許可を次作業へ流用しない。
- ロードマップ: `docs/current/development-roadmap.md`。以前のInsights・CodeQuest評価の内容を保ち、今回4.0節と関連する順序を更新。0140・0124の完了も反映済み。
- 判断の分担: 比較仕様00の同名節とADR-0168 Context。人工ログ・検査・配置・記録・起動手順の詳細化は委任済み。モデル・題材・上限・通常環境等の変更と比較起動は個別判断。ロードマップ更新時の旧委任はADR-0166 Contextを参照。
- 公開・利用側導入確認: `docs/records/experiments/2026-09-10-codex-plugin-0.1.26-installation.json`。公開時点f5229a8、導入スキル38ファイルが配布物と一致。このPCのCodexは0.1.26を導入・有効化済み。
- 隔離検証の最新状態: `.worktrees/isolated-verification/docs/working/handoff/codex_isolated-verification.md`。中断を維持し、明示再開時だけ専用worktreeの記録から続ける。
- 隔離検証の仕様: `docs/current/specs/2026-09-09-isolated-verification/00-overview.md`。ADR-0145〜0148の承認履歴、Issue-0136と専用worktreeの最新計画を参照。masterの旧計画から実装を重ねない。

## 完了済みタスク

- [x] Task 1の非モデル準備を完了（2026-09-10）。ADR-0171の依存別配置と保護・既存テストを検証し、起動資料を作成。実モデルの検証はTask 4へ。

過去サイクルは `docs/records/retrospectives/` とgit履歴を参照。

- [x] モデル裁量との比較案をロードマップへ反映し、関連ADR・リンク・配布同期を自己確認（2026-09-10）。ロードマップ・関連ADR・本ファイルを終了時コミットに保存。
- [x] 比較仕様4文書をフル1回・差分1回・機械検証1回で確定し、ADR-0167・0168をAcceptedへ昇格（2026-09-10）。実行計画も作成・対応確認済み。
- [x] 実行計画を追加レビュー見送りで確定し、Task 2の入力資材とTask 3の固定検査を作成。原版の不合格・正常例の合格・誤実装5例の検出を確認（2026-09-10）。

## 進行中のタスク

- 最新指示（2026-09-11）: 昨日頃の子セッション隔離検討にsbx知見がないか探索を依頼。専用worktreeの最新handoff・実験記録・保存済み証拠から導入/ログイン/VM試験/通常起動の成功を確認。先の初期設定案を撤回し、実行方法の調査記録を訂正。
- 最新到達点: 外側sandbox付きでは拒否、通常ユーザー権限では固定プラグイン2件込みで成功。元の実行制約との相互作用が候補。settings.json・対象・固定プラグイン・保護マーカーは不変、.claude.jsonは9項目で変化。親と捕捉子孫は終了。
- 残件: Claudeの編集成立と本比較の保護を両立する実行方法、Codexモデル裁量の保護先試行、補正後Codex一覧の実モデル確認、停止時の部分利用量回収。control/preflight.jsonはready_for_comparison=false。通常起動成功だけで比較開始しない。
- 状態: モデル診断の親CLI累計17回、init-only3回、本比較0回。Windows起動前失敗2回は別計数。最新証拠はcontrol/launch-packet/diagnostic-normal-user-20260911/verification.json。controlの状態・予算を更新済み。
- 判断の分担: 比較仕様00とADR-0168 Contextを維持。ADR-0174〜0179の限定起動は実施済み。再開だけで既存方針を再承認しないが、新たなモデル起動・保護縮小・通常設定変更・本比較起動は具体的な範囲で個別判断する。
- 継続条件: 再開後もADR-0169の必要性・進捗条件を適用。完了した資材・検査・フック準備を理由なく繰り返さず、同じ証拠しか増えない場合は停止。比較本体の各30分・計240分は維持する。
- 時間の記録: control/budget.json。初期区間や後半の調査・記録時間に未計測があるため累計は下限値。回答待ちは加算せず、新しい固定枠を仮定しない。
- 退避: r1・r2改訂前資料はC:/Users/d12an/.ai-dev-review-snapshots/model-discretion-spec-r1-20260910/とmodel-discretion-spec-r2-20260910/に保持。詳細は各レビュー記録。
## 未着手のタスク

- 他PC・他ツールへの0.1.26導入は依頼時に実施。
- Task 4は再開後の限定診断まで実施済み、本比較への移行条件未達。残件と次の進め方を確認する。Task 2・3を重ねて作成しない。Issue-0141・0142・0139は未対処。Issue-0135は触る際のフォルダ昇格の提案対象。
- Issue-0136の残る未確認（別OS・版、外向き・状態変更系ツール、子だけへの固定検査公開）は同Issueと専用worktreeを参照。通信・機密性・リンク・両主担当からの実起動の成立は未確認。

## 既知のブロッカー・懸念

- 今回のHypervisorPlatform=2と、9月9日のWHvGetCapability成功・実VM起動成功がある。有効化・再起動必須という先の提案は撤回。現在の利用可否を先に照合し、観測差だけでWindows設定を変えない。
- sbxデーモンは通常PowerShell起動で内部socket障害を回避した記録がある。AIからstart/restart/resetしない。停止中のsettings/ls/exec自動起動にも注意。SSH転送false・global deny-all・既存停止VMと退避領域を保全。詳細は専用worktreeの最新handoff。

- ADR-0179の通常起動で.claude.jsonの9項目が変化し、指定session-envが作成された。値の転記・自動復元なし。詳細は事前確認結果の最終節。通常領域全体の不変や本比較の保護成立とは扱わない。

- ClaudeのWriteはフック正常でもsensitive file拒否。プラグインなしの同内容Writeは成功したが、個別プラグイン・内部パス判定の原因は未特定。実測条件と限界は事前確認結果を参照。
- Windows直接起動の引数一式では1783。同じsandbox内のPython中継で同じ引数・本文を渡すと起動成功。内部原因は未特定。試験資材runtime-temp/argv-relayと起動失敗証拠を保持する。
- C:/Users/d12an/.claude/session-env/298b62c9-3d37-48aa-8a04-420b5d049e60はADR-0176で作成した試験用領域。勝手に削除・一般化せず、固定セッションIDや承認済みパケットを無条件で再利用しない。
- 元.venvの拒否は解除していない。ADR-0171の別配置とPython本体の明示readで試験経路は解消。公式サンドボックスのACL適用と手動ACL編集の不実施を区別する。詳細は準備記録。

- 隔離検証の既存資料照合・Git対照試験を、通信拒否や実環境の保護成立へ読み替えない。再開時は専用worktreeの再利用検討ノートを読む。
- Claude標準の子の制限・検索範囲の実測は `docs/records/retrospectives/system/2026-09-09-claude-native-subagent-interactive.md` とIssue-0136を参照。過去のレビュー経路は同記録を参照。
- 開始時スキル一覧は0.1.24の旧パスだったが、ディスクの0.1.26を発見して読み込み使用した。開始時の一覧だけで導入版を推定しない。
- `.tmp/`、`.claude/agents/`の試験定義、`docs/conversation_log.md`、inbox3件を保全。一括ステージ・削除しない。inboxは手動整理待ち。
- Issue-0136・0140の退避とレビュー証跡は対応レビュー記録を参照して保全。統合済みの `.worktrees/issue-0140-review-cost` とブランチも未追跡証跡のため残存。
- Issue-0135の起動・操作承認の制約を確認してから実機検証を組む。子の書き込みで承認プロンプトが出ない場合があり、許可を保護成立の証拠にしない。
- 他のissue-0122 worktreeとstash `6e959892b6e00600006456172237f27d7957fa01` は操作しない。古い草案を適用しない。
- ADR-0139・0140・0163はProposed、0166は比較先行の方針としてAccepted。0139・0140・0163には今回の比較先行の部分修正注記を追加。ロードマップ全体の実装・公開は未承認。保留事項はADR-0135／Issue-0131、ADR-0138／Issue-0132を参照。
- ロードマップと既存ADRの更新は前回コミットda136faに保存済み。今回の比較仕様作成では変更していない。旧編集前コピー `.tmp/model-discretion-roadmap/development-roadmap.before.md` は保全する。
- Issue-0124統合前の草稿・混在索引5ファイルはstash `0253b7cd8367fc09782674fdbe130102f0677eba`に保全。退避コピーは `.tmp/issue-0124-merge/manifest.json`。旧草稿を一括適用しない。
- `.worktrees/issue-0124-cost-comparison`とブランチは統合済み。未追跡のレビュー証跡のため保持。最新の完了状態はmaster側handoffを正とする。

## 節目ごとの確認記録

- 2026-09-11 別worktreeのsbx既存知見を照合・初期設定案訂正: ADR=なし（未採用案の前提訂正） / worklog=MakeAiInstructions-2026-09-11-01

- 2026-09-11 編集と原本保護を両立する実行方法の調査: ADR=なし（未採用候補の比較・具体化） / worklog=棄却（既存の前提調査・公式資料照合・導入負担提示を適用）

- 2026-09-11 通常ユーザー権限の対照診断完了・ADR-0179 Accepted 昇格: ADR=0179 / worklog=棄却（既存の対照・実体照合・影響範囲確認を適用） / cyclecheck=実施（指摘なし）

- 2026-09-11 通常ユーザー権限の対照診断候補を具体化: ADR=0179（Proposed、起動未承認） / worklog=棄却（既存の対照条件具体化・入力照合・保護差分提示を適用）

- 2026-09-11 個別プラグイン診断2回完了・ADR-0178 Accepted 昇格: ADR=0178 / worklog=棄却（既存の同一入力照合・限定診断・承認境界を適用） / cyclecheck=実施（指摘なし）

- 2026-09-11 再開後の静的調査・個別診断候補の具体化: ADR=なし（原因調査と未採用候補の提示） / worklog=棄却（既存の証拠照合・原因切り分け・承認境界の適用）

- 2026-09-11 ユーザー指示による中断・引き継ぎ確定: ADR=なし（中断状態の記録のみ） / worklog=棄却（既存の終了手順を適用、追加deltaなし）

- 2026-09-11 起動経路補正・Write診断完了: ADR=0177（実装補正の改訂記録） / worklog=棄却（既存の原因切り分け・同一入力照合を適用）

- 2026-09-11 Write診断の起動失敗・ADR-0177 Accepted 昇格: ADR=0177 / worklog=棄却（既存の実ログ照合・同一失敗時停止を適用） / cyclecheck=実施（指摘なし）

- 2026-09-11 通常認証先の起動準備・ADR-0176 Accepted 昇格: ADR=0176 / worklog=棄却（既存の原因別補正・実体照合を適用） / cyclecheck=実施（指摘なし）

- 2026-09-11 認証先照合・限定起動案準備: ADR=なし（調査と未採用候補の具体化） / worklog=棄却（既存の認証状態確認・承認境界の適用）

- 2026-09-10 init-only確認完了・ADR-0175 Accepted 昇格: ADR=0175 / worklog=棄却（既存の限定実行・実体照合を適用） / cyclecheck=実施（指摘なし）

- 2026-09-10 起動フック失敗の静的調査: ADR=なし（既存証拠の原因調査、対処候補は未採用） / worklog=棄却（既存のコード・ログ・仕様照合を適用）

- 2026-09-10 公式資料・既存フックログの再調査: ADR=なし（原因調査と未採用候補の提示） / worklog=棄却（既存の一次証拠照合・不明点の区別を適用）

- 2026-09-10 診断2回完了・ADR-0174 Accepted 昇格: ADR=0174 / worklog=棄却（既存の対照診断・実体照合・承認範囲を適用） / cyclecheck=実施（指摘なし）

- 2026-09-10 比較準備再開・診断候補の説明整合: ADR=なし（既存案の範囲内で承認状態・回数・概算の説明を訂正） / worklog=棄却（既存の実体照合と承認境界確認を適用）

- 2026-09-10 利用者指示による中断・引き継ぎ確定: ADR=なし（中断状態の記録のみ） / worklog=棄却（新しいdeltaなし）

- 2026-09-10 プラグイン有無の診断案準備: ADR=なし（起動前の候補具体化、採否待ち） / worklog=棄却（既存の対照比較・引数照合手順を適用）

- 2026-09-10 sensitive file判定の非モデル調査: ADR=なし（原因調査のみ、設定・方針変更なし） / worklog=棄却（既存の原因調査・証拠限定・非進捗時停止を適用）

- 2026-09-10 限定再試行の結果確認・ADR-0173 Accepted 昇格: ADR=0173 / worklog=棄却（既存の実体照合・失敗時停止手順を適用） / cyclecheck=実施（指摘なし）

- 2026-09-10 準備再開・更新後の登録先と既存起動案の差分確認: ADR=なし（既存未適用案の実体照合、採用判断前） / worklog=棄却（既存の原因調査・実体照合の範囲内）

- 2026-09-10 利用者更新予定と次セッション再開依頼の引き継ぎ: ADR=なし（作業状態と環境更新予定の記録） / worklog=棄却（追加実作業なし）

- 2026-09-10 ユーザー指示で保留・引き継ぎ確定: ADR=なし（作業状態の保留のみ） / worklog=棄却（追加deltaなし）

- 2026-09-10 事前確認実施・ADR-0172 Accepted 昇格: ADR=0172 / worklog=MakeAiInstructions-2026-09-10-03 / cyclecheck=実施（指摘なし）

- 2026-09-10 Task 1非モデル準備完了・ADR-0171 Accepted 昇格: ADR=0171 / worklog=棄却（既存の実体照合・原因調査を適用） / cyclecheck=実施（指摘なし）

- 2026-09-10 ADR-0170 Accepted 昇格・起動候補検証: ADR=0170 / worklog=棄却（既存の実体照合・原因調査を適用） / cyclecheck=実施（指摘なし）

- 2026-09-10 読み込み元候補の照合: ADR=0170（Proposed） / worklog=棄却（既存の実体照合・承認境界の適用）

- 2026-09-10 条件付き継続許可の反映・ADR-0169 Accepted 昇格・終了引き継ぎ: ADR=0169 / worklog=棄却（既存の必要性・進捗確認を適用） / cyclecheck=実施（指摘なし）。時間の扱いを仕様・計画・引き継ぎへ反映し、比較本体の制約は維持。タイトルと本文は残準備の継続条件という単一の決定に対応する。
- 同検査の経路: 必要な残件は既存記録を読んで次回続行し、実施後に進捗を記録。新しい証拠が増えない反復は停止して原因を報告。比較起動はTask 4で確認・承認後。セッション終了はpausedを維持。各経路の条件はADR-0169・仕様02・計画・本引き継ぎで一致し、再承認の二重要求は設けない。
- 同検査の引用: ADR-0169 Contextのユーザー発言→案1・Decisionは必要性と進捗の条件を維持、案2は許可済み続行の再確認になるため不採用。59.9分は準備記録と一致。旧60分上限の記録は過去の事実として保持し、最新許可の追記で区別する。各30分・計240分は仕様・計画・ADRで一致。
- 2026-09-10 セッション終了・引き継ぎ確定: ADR=なし（中断、上限変更未決） / worklog=棄却（既存の用語説明・中断手順を適用）
- 2026-09-10 比較実行計画 plan 確定点: ADR=なし（ADR-0168に基づく計画） / worklog=棄却（追加deltaなし） / review=見送り
- 2026-09-10 Task 2・3の資材と固定検査: ADR=なし（確定計画の実行） / worklog=棄却（既存の前提確認・検査手順内）
- 2026-09-10 比較詳細仕様 spec 確定点: ADR=0167・0168 / worklog=棄却（追加deltaなし） / review=フル実施（claude-opus-5・1 回）＋差分再確認（claude-opus-5・1 回）＋機械検証（1 回・実質的な収束）
- 2026-09-10 ADR-0167・0168 Accepted 昇格: ADR=0167・0168 / worklog=棄却（既存の確定手順内） / cyclecheck=非該当（実装前昇格）
- 2026-09-10 既存契約枠の選択・比較設計案の具体化: ADR=0167 / worklog=棄却（既存の環境確認・原因調査手順内、追加deltaなし）
- 2026-09-10 比較準備の再開・現環境と題材候補の確認: ADR=なし（ADR-0166に従う調査、候補は未採用） / worklog=棄却（既存の前提確認手順内、追加deltaなし）
- 2026-09-10 ロードマップへの比較案反映・自己確認: ADR=0166 / worklog=棄却（方針検討をADRへ記録、追加の作業deltaなし）
- 2026-09-10 利用予定モデルを含む比較条件の補足: ADR=0166 / worklog=棄却（既存のモデル過剰適合点検で扱う要件補足）

- 2026-09-10 最終自己点検・ADR-0166 Accepted 昇格・終了引き継ぎ: ADR=0166 / worklog=棄却（既存の検証・終了手順内、追加deltaなし） / cyclecheck=実施（指摘なし）

## 次セッション開始時のアクション

1. docs/records/experiments/2026-09-11-model-discretion-execution-options.mdの訂正節と、.worktrees/isolated-verification/docs/working/handoff/codex_isolated-verification.mdを読む。初期設定案は撤回済み。
2. 既存成功経路を再利用するため、通常ユーザー側で起動副作用のないdaemon statusから現状を照合。停止時は自動起動する照会をしない。設定・既存VM・退避領域を保全し、必要なら利用者の通常PowerShell起動を依頼する。隔離検証自体は再開しない。
3. 本比較・非公開コード送信・通常設定変更は未承認。時間下限値・未追跡証跡・stash・試験資材を保持する。中断中の隔離検証は再開対象外。

## 重要な意思決定の履歴

- ADR-0179: 通常ユーザー権限の対照診断1回を個別承認（Accepted、2026-09-11）。Read/Write成功、通常.claude.jsonの変化を記録。追加起動なし。

- ADR-0178: 固定プラグインを1つずつ読み込む2回を個別承認（Accepted、2026-09-11）。両方Write拒否、追加起動なし。

- ADR-0177: フック準備後のWrite1回を個別承認（Accepted、2026-09-11）。同一sandbox内の中継で実行済み。フック成功・Write拒否。

- ADR-0176: 通常認証先で指定session-env1件だけwriteとし起動準備を確認（Accepted、2026-09-11）。管理側での事前作成後にフック成功、モデルWrite未確認。

- ADR-0175: フック起動準備を通信禁止・空の試験設定領域で確認（Accepted、2026-09-10）。init-only1回成功、モデルWrite未検証。

- ADR-0174: 同じ作業場所でプラグイン有無を2回診断（Accepted、2026-09-10、個別承認）。実施済み、追加起動なし。

- ADR-0173: Claudeの限定事前確認で親子acceptEditsを採用（Accepted、2026-09-10、個別承認）。1回実施済み、編集失敗のため追加起動停止。

- ADR-0172: Codexの共通補助スキルを明示（Accepted、2026-09-10、起動詳細化の委任範囲内）。

- ADR-0171: 検査依存を試験専用フォルダへコピー（Accepted、2026-09-10、ユーザーの個別承認）。

- ADR-0170: Codexの導入済みキャッシュを内容一致条件で使用（Accepted、2026-09-10、ユーザーの個別承認）。

- ADR-0169: 比較準備の残作業を必要性と進捗を条件に次セッションで継続する（2026-09-10、ユーザーの明示許可）。ADR-0168の準備時間による停止の扱いを部分修正。
- ADR-0168: ログ解析2題材・代表2モデルでの段階比較（Accepted、2026-09-10）。
- ADR-0167: 初期比較に既存契約枠を使う（Accepted、2026-09-10）。
- ADR-0166: 独自手順の詳細化に先立つモデル裁量との比較方針（Accepted、2026-09-10）。今回の文書更新の委任は同ADRのContextを参照。
- ADR-0165: 前回のレビュー指摘採否への費用比較適用。Accepted、対策・公開済み。
