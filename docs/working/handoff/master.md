# Handoff: レビュー観点再編の完了と次の作業候補

- **Branch**: master
- **Last Updated**: 2026-09-12 14:21 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: 0.1.28統合・検証、Issue-0145起票、振り返り完了 / セッション終了

## 作業の目的・背景

ADR-0189のレビュー観点再編を0.1.28へ反映し、7dec143でmasterへ統合した。ユーザーが問題とした「履歴を一部読んだだけで調査十分と扱い、追加探索がユーザー介入に依存した」事象をIssue-0145へ詳しく記録した。対策は未決。次の作業はユーザー判断。

## 関連ドキュメント

- 次の課題候補: docs/working/issues/flow/0145-redesign-history-investigation-sufficiency-unverified.md。探索指示の追加だけで解決としない。読込件数・全ADR読破・旧判断維持・対応表・新工程のいずれも採用していない。
- 振り返り: docs/records/retrospectives/system/2026-09-12-review-questions.md、同flow記録。Issue-0145本文が課題詳細の正本。
- 実装: docs/working/plans/2026-09-12-review-questions-reframe.md、docs/records/reviews/2026-09-12-review-questions-implementation.md。比較・独立レビュー・全体整合確認は同日review-questions記録へ。
- 設計: ADR-0189、補足反映はdocs/records/reviews/2026-09-12-adr-0189-revision-applied.md。設計フル1回＋差分1回は提示後確定（実質的な収束に至らず）。実装時の別レビュー・15題比較を同じ回数へ混ぜない。
- 根拠探索: docs/records/experiments/2026-09-12-review-evidence-access-result.md、ADR-0188、Issue-0144。1回の成立を他環境の保証へ広げない。
- 初期比較と終了判断: docs/current/development-roadmap.md、ADR-0183、docs/records/experiments/2026-09-10-model-discretion-comparison.md。8実行・14段階は完了。長期保守・ADRの便益は未評価。追加比較は自動再開しない。
- 通常起動の診断・制約: docs/records/experiments/2026-09-10-model-discretion-preflight-results.md、同日model-discretion-preparation.md、docs/reference/model-discretion-comparison-preparation.md。過去結果と現環境の成立を区別する。
- 隔離検証の中断正本: .worktrees/isolated-verification/docs/working/handoff/codex_isolated-verification.md。仕様はdocs/current/specs/2026-09-09-isolated-verification/。Issue-0136とともに保留。

## 完了済みタスク

過去サイクルは上記振り返り・計画・ADR・git履歴参照。実装31cf340、マージ7dec143、Issue-0145起票4268e89。

## 現在の状態と次の作業

- ユーザーが本セッション終了とorigin/masterへのpushを明示承認。公開対象は0.1.28のスキル・配布物、設計・試験・レビュー記録、課題、振り返り・handoff。次回はgit ls-remote origin refs/heads/masterとローカルHEADで公開先端を照合する。公開確認のためにモデル試験を再実行しない。
- ユーザーの追加指示で、このPCのCodexを0.1.28へ更新・有効化済み。全39ファイルが配布物とSHA256一致。記録はdocs/records/experiments/2026-09-12-codex-plugin-0.1.28-installation.json。長いパス対応は更新プロセス限定。現在の会話へのスキル一覧の再読込は未確認。
- Issue-0145の対策設計・着手は未承認。起票だけを実施した。Issue-0075は実際の初見利用、0144は履歴アクセス・書き込み要求の実行時拒否等が未確認。ADR-0189の実装後3件の運用評価と4体分担の効果も未評価。
- .worktrees/issue-0143-review-questionsと同branchは未追跡証跡のため保全。主担当の正本はmaster側。本件の旧・新15題と実装レビューは3実行とも完了済み。各.tmp/issue-0143-*の資材を再起動・削除しない。

## 次セッション開始時のアクション

1. 本handoff、Issue-0145、最新ロードマップを読む。git statusとリモート先端を確認し、次の対象をユーザーの指示から決める。
2. Issue-0145を扱う場合は、経緯・単純な探索指示では再発する理由・未確定の原因・関連課題との境界を読む。会話の対策候補を採用済みと解釈しない。
3. 初期比較・Claude/sbx・Issue-0136は自動再開しない。新しいモデル実行・環境変更・利用側更新はそれぞれの指示に従う。完了作業の許可を次作業へ流用しない。
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
