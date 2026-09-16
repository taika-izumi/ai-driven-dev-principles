# Handoff: Issue-0136 残り実測と隔離系の整理

- **Branch**: master
- **Last Updated**: 2026-09-16 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: 調査・実測/Issue-0136 の残り実測と記録のコミット完了。隔離検証（codex/isolated-verification）はタスク1〜8を完了し、次はタスク9（実モデル往復、個別承認が前提）。作業は専用 worktree 側で続く

## 作業の目的・背景

利用者が隔離系（Issue-0136 と codex/isolated-verification）を選び、Issue-0136 の残り未確認事項のうち「固定検査1操作だけの子の対話セッション実行」を Claude Code 2.1.270 で実測した。結果は既存規範（ADR-0143・0144）どおりで、ガイドライン本文の変更はない。状態変更系ツール3件は測定せず記録で閉じ、規範本文は版更新規約に従い変更しない。Issue-0136 は、専用 Issue を持たない中断中の共通起動処理（codex/isolated-verification）の再開経路を担うため open を維持する（いずれも 2026-09-14 の利用者判断）。

前サイクル（ADR-0190・0191 の統合、0.1.29 の公開・Codex 導入）は完了済み。目的参照の実運用評価は 2026-09-14 の開始が1件目、2026-09-15 の開始が2件目にあたる（いずれも正本の読取りと版照合が成立）。

2026-09-15 の master セッションは開始処理のみで、master 側の成果物変更はない。master の handoff だけを読んで「進行中なし」と要約し、利用者の指摘で判明した（worklog `MakeAiInstructions-2026-09-15-03`）。

2026-09-15〜16 の作業は `.worktrees/isolated-verification` 側で行われた（利用者がリモート操作中で worktree へ切り替えられないため、master の作業ディレクトリから絶対パスと `git -C` で扱った）。v3 実装計画のタスク1〜7の実装とブランチ全体の最終レビュー・最終修正、タスク8の実VM実証（VM 3台を作成、いずれも stopped で保全）まで完了し、当該branchの最新は 1fbd84d。master 側の成果物は変更していない。詳細は `.worktrees/isolated-verification/docs/working/handoff/codex_isolated-verification.md` と同worktreeの `docs/records/reviews/2026-09-16-v3-implementation-tasks1-7.md`。

## 関連ドキュメント

- 今回の実測: docs/records/experiments/2026-09-14-claude-native-subagent-interactive-fixed-inspection.json。退避・照合・子の報告は .tmp/issue-0136-interactive-20260914/records/。Issue-0136 本文「現在地の要約」「結論」と 0136-log.md の 2026-09-14 行、docs/reference/inspection-isolation-costs.md 第10節「固定検査の対話セッション実行（2026-09-14）」へ反映済み。

- 公開・導入確認: docs/records/experiments/2026-09-13-codex-plugin-0.1.29-installation.json。配布コミット004f87c、導入先0.1.29の全42ファイルがdistとSHA256一致。CLI表示はinstalled, enabled。この会話の開始時スキル一覧は0.1.28のため、実行中セッションへの再読み込みは未確認。
- 後処理の正本: docs/records/retrospectives/system/2026-09-13-project-purpose-context.md。Issue-0118はdocs/working/issues/flow/0118-information-reachability-mechanism-undesigned/0118-information-reachability-mechanism-undesigned.md（open）。

- 目的・方針の正本: docs/overview/project-purpose.md。対象ルートD:/Dev/002_AiDev/MakeAiInstructions、参照内容は5350b9fの同パス。判断根拠はADR-0130・0183。
- 統合済み作業: docs/working/handoff/codex_project-purpose-context.md、docs/working/plans/2026-09-13-project-purpose-context.md、ADR-0190。
- 実装・検証: docs/records/reviews/2026-09-13-project-purpose-implementation.md、同日project-purpose-cycle-check.md、docs/records/experiments/2026-09-13-project-purpose-validation.md。
- 継続判断の検討材料: docs/reference/stage-three-preparation-and-delegation.md「2026-09-12の再照合」。ADR-0184の旧案は中断・未採用。原因切り分けの過去承認は新しい検討・実装の許可へ流用しない。
- 次の課題候補: docs/working/issues/flow/0145-redesign-history-investigation-sufficiency-unverified.md。探索指示の追加だけで解決としない。読込件数・全ADR読破・旧判断維持・対応表・新工程のいずれも採用していない。
- 振り返り: docs/records/retrospectives/system/2026-09-12-review-questions.md、同flow記録。Issue-0145本文が課題詳細の正本。
- 実装: docs/working/plans/2026-09-12-review-questions-reframe.md、docs/records/reviews/2026-09-12-review-questions-implementation.md。比較・独立レビュー・全体整合確認は同日review-questions記録へ。
- 設計: ADR-0189、補足反映はdocs/records/reviews/2026-09-12-adr-0189-revision-applied.md。設計フル1回＋差分1回は提示後確定（実質的な収束に至らず）。実装時の別レビュー・15題比較を同じ回数へ混ぜない。
- 根拠探索: docs/records/experiments/2026-09-12-review-evidence-access-result.md、ADR-0188、Issue-0144。1回の成立を他環境の保証へ広げない。
- 初期比較と終了判断: docs/current/development-roadmap.md、ADR-0183、docs/records/experiments/2026-09-10-model-discretion-comparison.md。8実行・14段階は完了。長期保守・ADRの便益は未評価。追加比較は自動再開しない。
- 通常起動の診断・制約: docs/records/experiments/2026-09-10-model-discretion-preflight-results.md、同日model-discretion-preparation.md、docs/reference/model-discretion-comparison-preparation.md。過去結果と現環境の成立を区別する。
- 隔離検証の中断正本: .worktrees/isolated-verification/docs/working/handoff/codex_isolated-verification.md。仕様はdocs/current/specs/2026-09-09-isolated-verification/。Issue-0136とともに保留。

## 完了済みタスク

- [x] Issue-0136 残り実測: 固定検査の子の対話セッション実行（2.1.270）、Write・Bash の実呼び出し拒否、保護対象9件のハッシュ照合（2026-09-14 完了）。
- [x] 記録更新: 実験記録・Issue-0136 本文とログ・参照知識第10節（2026-09-14 完了）。規範本文は変更しない判断。
- [x] コミット: master 61ddef3（記録5ファイル）。codex/isolated-verification の handoff へ master 61ddef3 を先に読む案内を追加し同branchで e2e28c0（2026-09-14 完了）。

過去サイクルはdocs/records/retrospectives/system/2026-09-13-project-purpose-context.md、同日purpose-maintenance-candidate.mdとgit履歴参照。

## 進行中のタスク

なし。今回の範囲（Issue-0136 の残り実測・記録・コミット）は完了。

## 未着手のタスク

- [ ] 目的参照の実運用評価（残り1件。1件目は 2026-09-14、2件目は 2026-09-15 の開始で成立）。
- [ ] codex/isolated-verification のタスク9（実モデル往復。認証方式と通信許可の実測、送信範囲の利用者判断、個別承認が前提）。その後にサイクル全体整合検査と ADR-0162・0192〜0198 の昇格判定、masterへの統合と振り返り。
- [ ] （完了）codex/isolated-verification の実装着手。正本は .worktrees/isolated-verification/docs/working/handoff/codex_isolated-verification.md（2d0db67）、計画は同 worktree の docs/working/plans/2026-09-14-isolated-verification-v3-implementation.md（plan 確定点通過・285f315）。利用者は 2026-09-15 に「専用 worktree で新セッションを起動して start-work する」経路を選択済み。専用 Issue は無く、Issue-0136 が再開経路。
- [ ] worktree 使用を踏まえた作業フローの定義（利用者の 2026-09-15 の示唆。「メモリに残すのではなく作業フローを定義したほうがよい」）。master で start-work すると他 worktree の新しい handoff を読まず最新状態を誤る問題が起点。課題起票・設計は未着手・未承認。worklog `MakeAiInstructions-2026-09-15-03` を参照。

- [ ] Issue-0145の対策設計・着手は未承認。起票だけを実施した。正本: docs/working/issues/flow/0145-redesign-history-investigation-sufficiency-unverified.md。
- [ ] Issue-0075は実際の初見利用、0144は履歴アクセス・書き込み要求の実行時拒否等が未確認。ADR-0189の実装後3件の運用評価と4体分担の効果も未評価。

## 既知のブロッカー・懸念

- .worktrees/issue-0143-review-questionsと同branchは未追跡証跡のため保全。主担当の正本はmaster側。本件の旧・新15題と実装レビューは3実行とも完了済み。各.tmp/issue-0143-*の資材を再起動・削除しない。
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
- `.tmp/`、`.claude/agents/`の試験定義、`docs/conversation_log.md`、inbox3件を保全。一括ステージ・削除しない。inboxは手動整理待ち（2026-09-14 も後回し、3件滞留）。
- 2026-09-14 の実測で `.tmp/issue-0136-claude-native-20260908/run/attempt-c14f2654b5e4499084717101f2974138/` が追加され、同 controller/last-result.json は上書き（実行前の複製は `.tmp/issue-0136-interactive-20260914/records/last-result-before-20260914.json`）。いずれも削除・復元していない。今回の記録領域 `.tmp/issue-0136-interactive-20260914/` も保全。
- Bash ツールの引用ヒアドキュメントで Windows パスのバックスラッシュが欠落した（JSON 記録が2回パース失敗）。バックスラッシュを含む本文は専用 Write ツールで書く。
- Issue-0136・0140の退避とレビュー証跡は対応レビュー記録を参照して保全。統合済みの `.worktrees/issue-0140-review-cost` とブランチも未追跡証跡のため残存。
- Issue-0135の起動・操作承認の制約を確認してから実機検証を組む。子の書き込みで承認プロンプトが出ない場合があり、許可を保護成立の証拠にしない。
- 他のissue-0122 worktreeとstash `6e959892b6e00600006456172237f27d7957fa01` は操作しない。古い草案を適用しない。
- ADR-0139・0140・0163はProposed、0166は比較先行の方針としてAccepted。0139・0140・0163には今回の比較先行の部分修正注記を追加。ロードマップ全体の実装・公開は未承認。保留事項はADR-0135／Issue-0131、ADR-0138／Issue-0132を参照。
- ロードマップと既存ADRの更新は前回コミットda136faに保存済み。今回の比較仕様作成では変更していない。旧編集前コピー `.tmp/model-discretion-roadmap/development-roadmap.before.md` は保全する。
- Issue-0124統合前の草稿・混在索引5ファイルはstash `0253b7cd8367fc09782674fdbe130102f0677eba`に保全。退避コピーは `.tmp/issue-0124-merge/manifest.json`。旧草稿を一括適用しない。
- `.worktrees/issue-0124-cost-comparison`とブランチは統合済み。未追跡のレビュー証跡のため保持。最新の完了状態はmaster側handoffを正とする。

## 節目ごとの確認記録

- 2026-09-14 Issue-0136 残り実測と記録更新の完了: ADR=なし（既存規範ADR-0143・0144の確認に留まり、試験手順・版更新・課題の追跡経路は既存規約に従う運用判断） / worklog=`MakeAiInstructions-2026-09-14-01`
- 2026-09-14 セッション終了の引き継ぎ確定: ADR=なし（同日の運用判断のみ、方針変更なし） / worklog=棄却（同日01に記録済みの差分以外なし）
- 2026-09-16 隔離検証のタスク1〜8を worktree 側で完了しセッション区切り（master 側の成果物変更なし）: ADR=なし（判断と決定はすべて worktree 側の計画・ADR-0198・レビュー記録に記録済み） / worklog=`MakeAiInstructions-2026-09-16-01`
- 2026-09-15 開始処理のみでセッション区切り（隔離検証は worktree の新セッションへ）: ADR=なし（再開経路の選択は既存 handoff の案内どおりで方針変更なし。作業フロー定義は示唆のみで未決定） / worklog=`MakeAiInstructions-2026-09-15-03`

## 次セッション開始時のアクション

1. docs/overview/project-purpose.md、masterのhandoffを読む。あわせて `git worktree list` と `git branch --sort=-committerdate` で master より新しいコミットを持つ branch を確認し、あればその worktree の handoff を読んでから要約する（2026-09-16 時点の最新は codex/isolated-verification の 1fbd84d）。**隔離検証を再開する場合、利用者がリモート操作中なら worktree へ切り替えず、master の作業ディレクトリのまま `.worktrees/isolated-verification` の絶対パスと `git -C` で扱う**（切替えの承認プロンプトは利用者の画面に届かない。2026-09-15〜16 のタスク1〜8はこの方法で実施）。読むのは同worktreeの handoff（1fbd84d）で、そこにタスク9の進め方が書いてある。
2. 次の利用者の依頼を確認する。候補は codex/isolated-verification のタスク9（専用 worktree 側。認証方式の実測から始め、送信範囲の判断と個別承認を経る）、worktree 使用を踏まえた作業フローの定義（課題起票から）、ADR-0184に関連する継続判断の規範検討、Issue-0118・0145。新セッションではスキル一覧・実体の版を確認する。sbx デーモンは 2026-09-16 に利用者が起動した世代（PID 25888）が稼働中の可能性があるため、隔離検証を再開するときは `daemon status --json` で確認する。
3. 完了作業の許可を次作業へ流用せず、初期比較・Claude/sbx・隔離検証を自動再開しない。既存の証跡・stashを保全する。

## 重要な意思決定の履歴

- ADR-0190: 目的の正本を開始・再開・委譲へ届ける。Accepted、0.1.29をローカルmasterへ統合済み。

- ADR-0189: レビュー観点再編。正本: docs/records/decisions/0189-organize-review-questions-and-independent-challenge.md。補足反映・レビューの終了状態は関連ドキュメントを参照。
- ADR-0188: 根拠探索。正本: docs/records/decisions/0188-develop-read-glob-grep-evidence-access.md。
- ADR-0183: 初期比較と終了判断。正本: docs/records/decisions/0183-place-targeted-evaluation-before-stage-three-adoption.md。
