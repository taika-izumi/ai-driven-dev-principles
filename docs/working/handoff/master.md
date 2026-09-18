# Handoff: worktree使用を踏まえた開始時の検出（ADR-0202）

- **Branch**: master
- **Last Updated**: 2026-09-19 02:25 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 改修/実装 Task 1〜5 完了（ADR-0202・0203 Accepted、0.1.30 生成済み・未push）→ Task 6（メモリの扱い）と公開の判断

## 作業の目的・背景

直近サイクルでは、隔離検証の共通起動処理（v3、synthetic-pilot）を実装・実機検証し、Codex主担当（2026-09-17）とClaude Code主担当（2026-09-18）の両方から、候補比較→採用→recheckの往復を実証した。サイクル全体整合検査（1a0c4f5）のうえでADR-0162・0192〜0201をAcceptedへ昇格し、`codex/isolated-verification` を `--no-ff` でmasterへ統合した（f8bce07）。振り返りは `docs/records/retrospectives/system/2026-09-18-isolated-verification.md`。masterは2026-09-18にoriginへpush済み。次サイクルの作業は未決定。

## 関連ドキュメント

- 目的・方針の正本: docs/overview/project-purpose.md。対象ルートD:/Dev/002_AiDev/MakeAiInstructions、参照内容は5350b9fの同パス（2026-09-18の開始時に読取りと版照合が成立）。判断根拠はADR-0130・0183・0190。
- 直近サイクル: 振り返り `docs/records/retrospectives/system/2026-09-18-isolated-verification.md`、仕様 `docs/current/specs/2026-09-09-isolated-verification/`、実装計画 `docs/working/plans/2026-09-14-isolated-verification-v3-implementation.md`、実証 `docs/records/experiments/2026-09-18-task9-claude-code-roundtrip.md`・`2026-09-17-task9-codex-roundtrip.md`、整合検査 `docs/records/reviews/2026-09-18-cycle-consistency-check.md`。
- 課題の一覧: docs/working/issues/README.md。
- 継続判断の検討材料: docs/reference/stage-three-preparation-and-delegation.md「2026-09-12の再照合」。ADR-0184の旧案は中断・未採用。原因切り分けの過去承認は新しい検討・実装の許可へ流用しない。
- 初期比較と終了判断: docs/current/development-roadmap.md、ADR-0183、docs/records/experiments/2026-09-10-model-discretion-comparison.md。長期保守・ADRの便益は未評価。追加比較は自動再開しない。

## 完了済みタスク

過去サイクルは docs/records/retrospectives/ と git 履歴を参照。

## 進行中のタスク

- [ ] **現在の作業**: worktree使用を踏まえた開始時の検出（ADR-0202、Proposed。設計はfd29346で確定）
  - 状態: brainstormingで範囲・方針を合意し、ADR-0202が設計文書を兼ねる（仕様書ファイルなし、feature-block-designは非適用）。確定前レビューはフル2回・差分再確認1回・機械検証で実質的な収束。レビュー対応の退避は `~/.ai-dev-review-snapshots/2026-09-18-adr-0202-r0`〜`r3`。
  - 状態: 計画 `docs/working/plans/2026-09-19-worktree-start-detection.md` の Task 1〜5 を完了。検出の追記とサイズ警告への対応（1447345、ADR-0203でインラインフォールバックの内容を `skills/start-work/references/inline-fallbacks.md` へ移動）、7場面と実環境の写経試験・整合検査（6564c49、いずれも期待どおり・指摘なし）、版0.1.30（7d86b81）、ADR-0202・0203 Accepted（4e3a9f7）。
  - 残り: 0.1.30は公開済み（5adfecc、利用者承認）。Task 6は「導入して検出が働くのを確かめてから削除」と決定（2026-09-19）。次セッションで、利用者が `/plugin marketplace update ai-driven-dev-principles` を実行した後にstart-workを行い、read操作の「他の worktree の検出」が働く（取り込み済み5件が除外され候補0件になる）ことを確かめ、メモリ `check-worktree-handoffs-at-start` とMEMORY.mdの索引行を削除する。
  - 未着手の宿題: 隔離検証の今後の方針（次セッション開始時のアクション4）を1問決める。

## 未着手のタスク

- [ ] 隔離検証の後片付け（Issue-0157）、独立試験の環境差（Issue-0155）・所要時間（Issue-0156）、繰り延べ指摘（Issue-0152〜0154）。着手は利用者判断。
- [ ] Issue-0158（セッション継続/切替の判断基準）の対策設計・着手は未承認。
- [ ] Issue-0145の対策設計・着手は未承認。正本: docs/working/issues/flow/0145-redesign-history-investigation-sufficiency-unverified.md。
- [ ] Issue-0075は実際の初見利用、0144は履歴アクセス・書き込み要求の実行時拒否等が未確認。ADR-0189の実装後3件の運用評価と4体分担の効果も未評価。
- 目的参照の実運用評価は、2026-09-14・09-15・09-18の開始で3件とも正本の読取りと版照合が成立した（予定件数に到達）。評価のまとめ方は未定。

## 既知のブロッカー・懸念

- `.worktrees/isolated-verification` とブランチ `codex/isolated-verification` は統合済みだが、未追跡の試験証跡（`.tmp/m9/`・`.tmp/c9/`・`.superpowers/sdd/` 等）を保持するため残している。削除しない。
- sbx: 停止中のVM19台・全体保存のOAuth・VMごとの通信規則27件が残存（Issue-0157、2026-09-18に読取りで再確認）。OAuthは利用者判断で隔離検証の今後の方針（次セッション開始時のアクション4）を決めるまで残す。VM・通信規則も同じく方針決定まで保留（利用者判断）。daemonのstart/restart/reset、sbx・画像の更新、VM/画像の削除はAIから行わない。停止中のdaemonへls等を打たず、`daemon status` から確認する。停止VMへのexec/cpは再起動を伴うため発行しない。詳細は `docs/reference/sbx-sandbox-runtime-facts.md`。
- 今回のHypervisorPlatform=2と、9月9日のWHvGetCapability成功・実VM起動成功がある。現在の利用可否を先に照合し、観測差だけでWindows設定を変えない。
- 独立試験をClaude Codeから回すときは、PATH上のcodexがジャンクションで失敗する（Issue-0155）。実体パス `C:\Users\d12an\.codex\packages\standalone\releases\0.153.4-x86_64-pc-windows-msvc\bin` をPATHの先頭に足すと通る。
- .worktrees/issue-0143-review-questions・issue-0140-review-cost・issue-0124-cost-comparison と各ブランチは統合済みだが、未追跡のレビュー証跡のため保全する。各.tmp/issue-0143-*の資材を再起動・削除しない。
- 他のissue-0122 worktreeとstash `6e959892b6e00600006456172237f27d7957fa01`、stash `0253b7cd8367fc09782674fdbe130102f0677eba`（Issue-0124統合前の草稿、退避コピーは `.tmp/issue-0124-merge/manifest.json`）は操作しない。古い草案を一括適用しない。
- ADR-0179の通常起動で.claude.jsonの9項目が変化し、指定session-envが作成された。値の転記・自動復元なし。通常領域全体の不変や比較の保護成立とは扱わない（詳細は docs/records/experiments/2026-09-10-model-discretion-preflight-results.md 最終節）。
- C:/Users/d12an/.claude/session-env/298b62c9-3d37-48aa-8a04-420b5d049e60はADR-0176で作成した試験用領域。勝手に削除・一般化せず、固定セッションIDや承認済みパケットを無条件で再利用しない。
- ClaudeのWriteはフック正常でもsensitive file拒否の事例あり（原因未特定）。Windows直接起動の引数一式で1783、Python中継では成功（原因未特定、試験資材runtime-temp/argv-relay保持）。元.venvの拒否は未解除（ADR-0171の別配置で回避）。いずれも事前確認結果を参照。
- Issue-0135の起動・操作承認の制約を確認してから実機検証を組む。子の書き込みで承認プロンプトが出ない場合があり、許可を保護成立の証拠にしない。
- 過去の比較では開始時一覧が0.1.24でもディスクの0.1.26を読み込んだ例がある。開始時の一覧だけで導入版を推定しない。
- ADR-0139・0140・0163はProposed、0166は比較先行の方針としてAccepted。ロードマップ全体の実装・公開は未承認。保留事項はADR-0135／Issue-0131、ADR-0138／Issue-0132を参照。旧編集前コピー `.tmp/model-discretion-roadmap/development-roadmap.before.md` は保全する。
- `.tmp/`（issue-0136-interactive-20260914、issue-0136-claude-native-20260908 等を含む）、`.claude/agents/`の試験定義、`docs/conversation_log.md`を保全。一括ステージ・削除しない。

## 節目ごとの確認記録

- 2026-09-18 セッション終了・次サイクルの進め方の合意: ADR=なし（次セッションの作業順の合意で、決定は次セッションで行う） / worklog=MakeAiInstructions-2026-09-18-03
- 2026-09-18 masterのpush（6ce0db0..39f7ed5、利用者承認）: ADR=なし（承認済み操作の実行） / worklog=棄却（delta なし）
- 2026-09-18 ADR-0153〜0156 Accepted 昇格（利用者「1で」）: ADR=0153・0154・0155・0156 / worklog=棄却（delta なし） / cyclecheck=非該当（対象文書の変更なし）
- 2026-09-18 Issue-0136クローズ（利用者「1で」）: ADR=なし（課題の状態判断で、方針の選択ではない） / worklog=棄却（delta なし）
- 2026-09-18 inbox整理（organize-inbox完了）: ADR=なし（配置と起票の判断で、方針の選択ではない） / worklog=MakeAiInstructions-2026-09-18-04
- 2026-09-18 worklog形式の解説メモ削除とIssue-0157の現状確認: ADR=なし（配置の訂正とOAuth保留の判断。方針の選択ではない） / worklog=MakeAiInstructions-2026-09-18-05
- 2026-09-18 ADR-0202 spec 確定点（worktree検出の設計、fd29346）: ADR=0202 / worklog=MakeAiInstructions-2026-09-18-06 / review=フル実施（claude-opus-5・2 回）＋差分再確認（claude-opus-5・1 回）＋機械検証（1 回・実質的な収束）
- 2026-09-19 worktree検出 plan 確定点（実装計画の確定）: ADR=なし（ADR-0202の実装計画で新たな決定なし） / worklog=MakeAiInstructions-2026-09-19-01 / review=フル実施（claude-opus-5・1 回）＋機械検証（2 回・提示後確定（実質的な収束に至らず））
- 2026-09-19 worktree検出の実装 Task 1〜4（サイズ警告への対応を含む）: ADR=0203 / worklog=MakeAiInstructions-2026-09-19-02
- 2026-09-19 ADR-0202・0203 Accepted 昇格: ADR=0202・0203 / worklog=棄却（delta なし） / cyclecheck=実施（指摘なし）

## 次セッション開始時のアクション

1. 利用者に `/plugin marketplace update ai-driven-dev-principles` の実行（0.1.30の導入）を確認してから、start-workを実行する。read操作の「他の worktree の検出」が働くこと（`git worktree list` を1回実行し、取り込み済みの5件を除外して候補0件）を確かめる。導入版はディスク上の版で確かめる（開始時の一覧だけで判断しない）。
2. 確かめられたら、メモリ `check-worktree-handoffs-at-start` とMEMORY.mdの索引行を削除し、計画 `docs/working/plans/2026-09-19-worktree-start-detection.md` のTask 6に記録する。働かなければ原因を調べ、メモリは残す。
3. 残る宿題: 隔離検証の今後の方針（(i) レビュー用へ広げる、(ii) 開発用にも広げる、(iii) 試作で止め標準サブエージェントのツール制限で足りるとする）を1問決める。Issue-0157（停止VM・OAuth・通信規則）はこの方針決定まで保留。Issue-0158（セッション継続/切替の判断基準）は未着手。
4. 留意点: 独立試験をClaude Codeから回すときはIssue-0155の回避（PATHの先頭に実体パス）が必要。sbxの停止VMへexec/cpしない。Git Bashでは `git show <ref>:<.で始まるパス>` が失敗するためPowerShellで実行する。

## 重要な意思決定の履歴

- ADR-0162・0192〜0201: 隔離検証の試作条件と実現手段。2026-09-18 Accepted、f8bce07で統合。
- ADR-0202: worktreeは禁止も全面標準化もせず、作成の合意はsuperpowersに任せ、開始時に読む側で検出する。2026-09-19 Accepted（4e3a9f7）。
- ADR-0203: start-workのインラインフォールバックの内容をreferencesへ移す（サイズ警告への対応）。2026-09-19 Accepted。
- ADR-0153〜0156: 隔離検証の再検討方向・既存基盤比較・sbx通信deny-all初期化・sbx状態退避。2026-09-18 Accepted。
- ADR-0190: 目的の正本を開始・再開・委譲へ届ける。Accepted。
- ADR-0189: レビュー観点再編。正本: docs/records/decisions/0189-organize-review-questions-and-independent-challenge.md。
- ADR-0183: 初期比較と終了判断。正本: docs/records/decisions/0183-place-targeted-evaluation-before-stage-three-adoption.md。
