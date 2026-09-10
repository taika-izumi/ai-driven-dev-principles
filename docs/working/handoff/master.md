# Handoff: モデル裁量と既存手順の比較準備

- **Branch**: master
- **Last Updated**: 2026-09-10 20:00 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: Task 4 / 事前確認実施済み・移行条件未達、編集許可設定の変更案への判断待ち

## 作業の目的・背景

ユーザーの依頼に基づき、独自手順を詳細化する前にモデルに進め方を任せる比較をロードマップへ反映した。比較条件・代表2モデル・2題材・採点・結果による進路は同文書4.0節が正本。実験は未実施。Issue-0140・0124と0.1.26公開・このPCへの導入は完了済みで、運用効果は未評価。

## 関連ドキュメント

- 事前確認結果: docs/records/experiments/2026-09-10-model-discretion-preflight-results.md。未適用の編集モード案はcontrol/launch-packet/launch-edit-permission-candidate.json。


- 起動操作: docs/records/experiments/2026-09-10-model-discretion-preflight-launch.md。引数・依頼文はcontrol/launch-packet/launch.jsonと関連ファイル。起動承認待ち。


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

- ADR-0170・0171は採用反映済み。Task 1の非モデル準備完了。依存630ファイルの別配置、4条件の既存23テスト成功と書き込み拒否を確認。事前確認は通常4条件・補正2回・停止4条件を実施済み。Claude既存手順の親子Write拒否などで移行条件未達。本比較は未承認・未実施。


- 2026-09-10、ユーザーが「1で」と比較実行案の具体化からの再開を選択。既存方針の再承認は不要。実験起動・設定変更・公開は未承認。
- 状態: 親CLI10回を実行し追加起動は停止済み。実行プロセス群は終了。結果はdocs/records/experiments/2026-09-10-model-discretion-preflight-results.mdとcontrol/launch-packet/summary.json。
- 前回の中断: コンテキスト肥大化を理由に前セッションを終了した。その後、ユーザーは本当に必要な作業であり、ループや進捗のない過剰検証でなければ次セッションで続行してよいと許可した（ADR-0169）。前セッションでは記録更新のみ。今回は再開済み。
- 継続条件: 比較開始・評価に必要な残件から進み、完了済みの準備・検査は新たな変更・失敗・懸念がなければ繰り返さない。同じ試行で新しい証拠が増えない、検証だけが増えて比較へ近づかない場合は止める。60分到達だけを理由に続行許可を取り直さない。90分・330分という数値案への承認とは扱わず、新たな固定枠は設定しない。比較本体の各30分・計240分と起動前の確認・操作承認は維持する。
- 時間の記録: control/budget.json。旧60分上限はADR-0169により無効、既存の経過時間へ稼働区間を加算する。初回再開の初期区間が未計測のため累計は下限値。回答待ちは加算しない。
- 退避: r1・r2の改訂前資料は `C:/Users/d12an/.ai-dev-review-snapshots/model-discretion-spec-r1-20260910/` と `model-discretion-spec-r2-20260910/` に保持。詳細は各レビュー記録を参照。
- レビューの実行: Readと固定検査だけが公開された開始イベントを確認済み。原版の日時不具合とコピーの正常例を固定検査で確認。既存テストは同梱Pythonではpytest不足、通常ユーザー権限の既存仮想環境では23件成功。詳細はレビュー準備記録。
- 実行状態: CodexはChatGPT認証、Claudeは保護下でもMax認証を確認。比較実験は未実施。control/preflight.jsonのready_for_comparisonはfalse。判別検査はpassだが、モデル経路の確認はunknownを維持。

## 未着手のタスク

- 他PC・他ツールへの0.1.26導入は依頼時に実施。
- 次はTask 4の事前確認への起動承認に従って進む。Task 2・3を重ねて作成しない。Issue-0141・0142・0139は未対処。Issue-0135は目安10KB超過（前回17.1KB）で、触る際のフォルダ昇格の提案対象。
- Issue-0136の残る未確認（別OS・版、外向き・状態変更系ツール、子だけへの固定検査公開）は同Issueと専用worktreeを参照。通信・機密性・リンク・両主担当からの実起動の成立は未確認。

## 既知のブロッカー・懸念

- Claude既存手順は親子のWriteがdontAskで拒否。子の旧版参照は登録情報の探索であり実ロード未確認。acceptEditsへの変更案は未適用。Codex裁量の保護先試行と補正後の実モデル入力も未確認。結果資料を参照。


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

1. 事前確認結果の「次の提案」とユーザー回答から続ける。Claude親子のacceptEdits案は未承認。固定版の子継承はSkill実応答で確認する。成功済み検査の全面再実行をしない。本比較は未承認。保存済み時間は下限値として保持。
2. Issue-0140・0124の実装・レビュー・マージ・振り返り、0.1.26の公開とこのPCのCodex導入は完了済み。重ねて実施しない。
3. 隔離検証は明示再開時のみ専用worktreeへ進む。未コミット変更・stash・レビュー証跡を保全する。

## 重要な意思決定の履歴

- ADR-0172: Codexの共通補助スキルを明示（Accepted、2026-09-10、起動詳細化の委任範囲内）。


- ADR-0171: 検査依存を試験専用フォルダへコピー（Accepted、2026-09-10、ユーザーの個別承認）。


- ADR-0170: Codexの導入済みキャッシュを内容一致条件で使用（Accepted、2026-09-10、ユーザーの個別承認）。


- ADR-0169: 比較準備の残作業を必要性と進捗を条件に次セッションで継続する（2026-09-10、ユーザーの明示許可）。ADR-0168の準備時間による停止の扱いを部分修正。
- ADR-0168: ログ解析2題材・代表2モデルでの段階比較（Accepted、2026-09-10）。
- ADR-0167: 初期比較に既存契約枠を使う（Accepted、2026-09-10）。
- ADR-0166: 独自手順の詳細化に先立つモデル裁量との比較方針（Accepted、2026-09-10）。今回の文書更新の委任は同ADRのContextを参照。
- ADR-0165: 前回のレビュー指摘採否への費用比較適用。Accepted、対策・公開済み。
