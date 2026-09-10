# Handoff: AstraとSolでモデルごとのガイドラインの効果を比較する

- **Branch**: master
- **Last Updated**: 2026-09-11 07:48 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 本比較 / Astra日時2条件終了、Sol/low日時実行中

## 作業の目的・背景

モデルに進め方を任せる条件と現行手順の便益・負担を比較し、過剰な指示の見直しを優先する。2026-09-11、ユーザーは環境構築の負担を理由にOpenAIモデルで検証する方針へ変更し、Astraだけへの縮小を訂正してSolとの2モデル比較を指示した（ADR-0180）。既存の2題材・固定検査を再利用し、日時の対比較から始める。Claudeと今回比較のためのsbx整備は保留。他モデルへの一般化と共通指示の一括削減は行わない。
## 関連ドキュメント

- 本比較の実行記録: docs/records/experiments/2026-09-11-openai-comparison-execution.md。Sol/lowへの変更はADR-0181。

- 現在の起動手順と証拠: docs/records/experiments/2026-09-11-openai-comparison-preparation-complete.md。以下の過去診断の次手は本比較の次手にしない。

- 最新方針: ADR-0180。AstraとSolの仕様00〜03と実行計画を現行正本とする。以下のClaude・sbx記録は過去の知見であり今回の次手ではない。

- 実行方法の候補と訂正: `docs/records/experiments/2026-09-11-model-discretion-execution-options.md` 末尾。別worktreeのsbx導入・VM試験成功を再発見。Windows機能有効化から始める提案を撤回。既存成功経路と現状の照合が次手。

- 事前確認結果: docs/records/experiments/2026-09-10-model-discretion-preflight-results.md。最新は通常ユーザー権限でのClaude Read/Write成功（ADR-0179）。sbx内の成功ではない。実施済みパケットを再実行しない。

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

- [x] Astra＋Solの比較準備完了（2026-09-11）。8項目pass・8実行12段階・本比較0回。準備完了記録を参照。

- [x] Task 1の非モデル準備を完了（2026-09-10）。ADR-0171の依存別配置と保護・既存テストを検証し、起動資料を作成。実モデルの検証はTask 4へ。

過去サイクルは `docs/records/retrospectives/` とgit履歴を参照。

- [x] モデル裁量との比較案をロードマップへ反映し、関連ADR・リンク・配布同期を自己確認（2026-09-10）。ロードマップ・関連ADR・本ファイルを終了時コミットに保存。
- [x] 比較仕様4文書をフル1回・差分1回・機械検証1回で確定し、ADR-0167・0168をAcceptedへ昇格（2026-09-10）。実行計画も作成・対応確認済み。
- [x] 実行計画を追加レビュー見送りで確定し、Task 2の入力資材とTask 3の固定検査を作成。原版の不合格・正常例の合格・誤実装5例の検出を確認（2026-09-10）。

## 進行中のタスク

- **現在の作業**: 2026-09-11「引き継ぎに従って検証を開始してください」により起動許可を記録。Astra日時2条件は固定7検査・既存23テスト合格。Solは追加指示でlowに変更し、sol-bug-discretionは固定検査合格、sol-bug-guidelineを実行中。詳細は実行記録。最新利用枠は83%使用済み。
- **実行順序と利用枠**: 仕様02の8実行を必ず1件ずつ開始する。前の実行の親子停止・結果回収を確認してから次へ進み、一斉起動・比較実行同士の並列化は禁止。小機能は同じ1実行のfirst→resumeを終えてから次の実行へ進む。
- 開始前と各実行後に取得可能な利用状況・警告を確認する。利用枠到達や続行困難が判明したら次を起動せず、完了分・中断位置・残時間・次のrun_idを保存する。利用量不明を残量十分と解釈せず、追加購入・リセット・別モデル代替はしない。
- 実行対象: Astra/mediumとSol/low（ADR-0181）、2題材・2条件・8実行、各30分・計240分。小機能は新規セッション再開を含むため起動段階は12。
- 準備の正本: `docs/records/experiments/2026-09-11-openai-comparison-preparation-complete.md`。8確認項目pass、両モデルの親子実起動、8コピーの入力分離、採点の正負対照、外側停止・部分利用量回収を確認済み。
- 起動資料: 試験ルートの `control/launch-packet/openai-comparison-20260911.json` と `control/runtime/`。`control/preflight.json` はready_for_comparison=true、launch_approved=true。古いAstra単独・Claude診断パケットを実行しない。
- 残り: 最初のAstra対比較は成立。Sol/low日時と両モデルの小機能を順に実施する。実行開始前の状態照合は行うが、同じ方針への許可を取り直さない。
- 判断の分担: 仕様00とADR-0180。入力・記録・起動詳細化は委任範囲内。保護縮小・通常設定変更・追加課金・モデル変更・外部公開は含まない。Claudeとsbx整備、Issue-0136は保留を維持。
## 未着手のタスク

- 他PC・他ツールへの0.1.26導入は依頼時に実施。
- Task 4の準備は完了。本比較は新しいセッションで逐次実施する。Task 2・3を重ねて作成しない。Issue-0141・0142・0139は未対処。Issue-0135は触る際のフォルダ昇格の提案対象。
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

- 2026-09-11 Sol/low実起動確認・ADR-0181 Accepted 昇格: ADR=0181 / worklog=棄却（ユーザー指定の設定変更と既存の実モデル照合） / cyclecheck=実施（指摘なし）

- 2026-09-11 Astra日時対比較成立・Sol/low変更反映: ADR=0181（ユーザー個別指示） / worklog=MakeAiInstructions-2026-09-11-05

- 2026-09-11 本比較開始: ADR=なし（ADR-0180の実行指示を適用） / worklog=棄却（既存の固定入力照合・逐次起動手順を適用）

- 2026-09-11 新セッション向け引き継ぎ確定: ADR=なし（仕様02の逐次実行を再確認） / worklog=棄却（既存の逐次実行・利用枠停止・引き継ぎ手順を適用）

- 2026-09-11 比較準備完了・ADR-0180 Accepted 昇格: ADR=0180 / worklog=MakeAiInstructions-2026-09-11-04 / cyclecheck=実施（指摘なし）

- 2026-09-11 モデル性能別の比較目的を回復: ADR=0180（未コミットドラフト訂正） / worklog=MakeAiInstructions-2026-09-11-03

- 2026-09-11 Astra比較への方針転換反映: ADR=0180 / worklog=MakeAiInstructions-2026-09-11-02

- 2026-09-11 先行検証の範囲確認・ユーザー指示による中断: ADR=なし（既存仕様の確認と中断記録） / worklog=棄却（既存の範囲照合・中断手順を適用、見落としは01に記録済み）

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

- 2026-09-10 診断2回完了・ADR-0174 Accepted 昇格: ADR=0174 / worklog=棄却（既存の対照診断・実体照合・承認範囲を適用） / cyclecheck=実施（指摘なし）

- 2026-09-10 限定再試行の結果確認・ADR-0173 Accepted 昇格: ADR=0173 / worklog=棄却（既存の実体照合・失敗時停止手順を適用） / cyclecheck=実施（指摘なし）

- 2026-09-10 事前確認実施・ADR-0172 Accepted 昇格: ADR=0172 / worklog=MakeAiInstructions-2026-09-10-03 / cyclecheck=実施（指摘なし）

- 2026-09-10 Task 1非モデル準備完了・ADR-0171 Accepted 昇格: ADR=0171 / worklog=棄却（既存の実体照合・原因調査を適用） / cyclecheck=実施（指摘なし）

- 2026-09-10 ADR-0170 Accepted 昇格・起動候補検証: ADR=0170 / worklog=棄却（既存の実体照合・原因調査を適用） / cyclecheck=実施（指摘なし）

- 2026-09-10 条件付き継続許可の反映・ADR-0169 Accepted 昇格・終了引き継ぎ: ADR=0169 / worklog=棄却（既存の必要性・進捗確認を適用） / cyclecheck=実施（指摘なし）。時間の扱いを仕様・計画・引き継ぎへ反映し、比較本体の制約は維持。タイトルと本文は残準備の継続条件という単一の決定に対応する。
- 2026-09-10 比較実行計画 plan 確定点: ADR=なし（ADR-0168に基づく計画） / worklog=棄却（追加deltaなし） / review=見送り
- 2026-09-10 比較詳細仕様 spec 確定点: ADR=0167・0168 / worklog=棄却（追加deltaなし） / review=フル実施（claude-opus-5・1 回）＋差分再確認（claude-opus-5・1 回）＋機械検証（1 回・実質的な収束）
- 2026-09-10 ADR-0167・0168 Accepted 昇格: ADR=0167・0168 / worklog=棄却（既存の確定手順内） / cyclecheck=非該当（実装前昇格）

- 2026-09-10 最終自己点検・ADR-0166 Accepted 昇格・終了引き継ぎ: ADR=0166 / worklog=棄却（既存の検証・終了手順内、追加deltaなし） / cyclecheck=実施（指摘なし）

## 次セッション開始時のアクション

1. 本handoffと`docs/records/experiments/2026-09-11-openai-comparison-execution.md`、試験管理側のrun.json・budget.jsonを読む。Astra日時2条件とSol/low裁量は採点合格。実行中の状態を実体で確認し、重複起動しない。
2. sol-bug-guidelineの停止・回収・採点後、codex-feature-guideline-firstから仕様02順に逐次実施する。小機能はfirst→resumeの停止・保存を確認して同一30分枠を引き継ぐ。Astra/medium、Sol/low（ADR-0181）。
3. 各実行後に利用枠を確認。枠到達・続行困難なら次を起動せず、次run_id・段階・残時間を保存する。固定資材と原本・他worktree・未追跡資料を保全し、Claude・sbx整備へ移行しない。
## 重要な意思決定の履歴

- ADR-0180: 初期比較をAstraとSolへ変更しClaudeの環境整備を保留（2026-09-11、ユーザーの個別指示）。

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
