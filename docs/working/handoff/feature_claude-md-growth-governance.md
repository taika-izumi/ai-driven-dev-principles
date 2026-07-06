# Handoff: Issue-0018 対策サイクル（CLAUDE.md 常時指示の肥大化ガバナンス）

- **Branch**: feature/claude-md-growth-governance
- **Last Updated**: 2026-07-06 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 課題対策サイクル/実装完了（ADR-0040 Accepted・Issue-0018 close 済み）・master マージ前

## 作業の目的・背景

Issue-0018「CLAUDE.md 常時指示の肥大化を監視・棚卸しする仕組みがない」への対策サイクル。CLAUDE.md はエージェントが毎セッション読み込む常時指示であり、template 経由で配布先全プロジェクトへ展開されるが、規範が単調増加する一方で（1）肥大化の監視、（2）効かない・古びた規範の棚卸し、（3）追加時に累積コストと放置リスクを突合する事前判定、のいずれも仕組みが存在しない。事前判定・事後棚卸しの両面を扱う（retrospective 2026-07-06 の申し送り）。

## 関連ドキュメント

- 課題: `docs/working/issues/flow/0018-claude-md-norm-growth-monitoring.md`
- 起票元の振り返り: `docs/records/retrospectives/system/2026-07-06-process-check-norms.md`（Tech Notes に「ゲートの有無」「ガードレール配置」「実測してから議論」の関連知見あり）
- 手順: `CONTRIBUTING.md`「振り返りで抽出された課題に対策するとき」「CLAUDE.md を更新するとき」
- 関連ADR: ADR-0038, ADR-0039（前サイクル）、ADR-0032（判定条件は観測可能な事実）

## 完了済みタスク

- [x] feature ブランチ作成、Issue-0018・CONTRIBUTING.md 手順・起票元 retrospective の読み込み（2026-07-06）
- [x] 構造的解決の先行調査（CONTRIBUTING.md 手順4）: CLAUDE.md 実測 114行/11,180バイト/箇条書き38件（template と同一、実測 約3.8kトークン）。既存の自動機構は `scripts/sync-template.ps1` のみ（git hooks 未導入・hooksPath 未設定・共有 .claude/settings.json なし）。監視（サイズ・箇条数の計測と閾値警告)は sync-template.ps1 組み込みまたは独立スクリプトで自動化可能。棚卸し・事前判定は判断業務のため手順/スキル側の領分（2026-07-06）
- [x] brainstorming: 3案比較から案1（独立計測スクリプト＋sync-template 連動）採用、閾値は保守的な 12,000 バイト / 45 件（研究データ IFScale・Context Rot を参照しつつ安全マージン付きトリップワイヤーと位置づけ）、設計3セクション承認。ADR-0040 起票（8a0f0a7）（2026-07-06）
- [x] 実装計画作成（`docs/working/plans/2026-07-06-claude-md-growth-governance.md`、816f16a。ADR-0034 突合で期待値3件を修正）（2026-07-06）
- [x] 実装（全5タスク）: `scripts/check-claude-md-size.ps1` 新設（警告分岐の実機検証込み。7cc817f）、sync-template.ps1 連動（template 差分なし確認。dcdd04f）、CONTRIBUTING.md 事前判定小節（6399fbb）、同棚卸しシナリオ（eeeb35b）、全体 read-back 検証・ADR-0040 Accepted 昇格・Issue-0018 close（5003cb2）（2026-07-06）

## 進行中のタスク

- [ ] **現在の作業**: master へのマージと retrospective
  - 状態: 全5タスクの実装・検証・コミット完了（7cc817f, dcdd04f, 6399fbb, eeeb35b, 5003cb2）。ADR-0040 Accepted 昇格・Issue-0018 close 済み
  - 残り: master へ `--no-ff` マージ（`git merge --no-ff -F <file>`）→ retrospective スキル起動 → handoff finalize

## 未着手のタスク

なし（実装は完了。残りはマージとセッション終了処理のみ）

## 既知のブロッカー・懸念

- CLAUDE.md への規範追加は抑制方針そのものが本課題のテーマ。対策自体が CLAUDE.md を肥大化させる自己矛盾に注意
- 下り方向の配布（template 更新の既存配布先への反映）は手動運用中。本課題の対策設計時に一体で扱うかを再検討する（Issue-0018 検討状況 2026-07-06）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ファイル、`docs/working/issues/flow/0018-claude-md-norm-growth-monitoring.md`
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）→ brainstorming から再開
3. 留意点: 構造化質問ツール使用前に `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` を確認（ADR-0036）。マルチライン文字列は `git commit -F` で渡す（Issue-0015）

## 重要な意思決定の履歴

- ADR-0040: CLAUDE.md 肥大化ガバナンスを計測スクリプト連動と CONTRIBUTING.md 手順で導入する（2026-07-06, Accepted）
