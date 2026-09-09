# Handoff: 隔離検証の共通起動処理の実装

- **Branch**: codex/isolated-verification
- **Last Updated**: 2026-09-09 14:21 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: Git履歴コピーの実装・レビュー完了 / 隔離方式の検討へ復帰

## 作業の目的・背景

Claude CodeとCodexの主担当から共通CLIを呼び、隔離されたコピー内で追加テストを作成・実行する。仕様確定後の計画草案を再開し、ユーザーが主担当の順次実装と計画レビュー見送りを選択した。

作業場所は`D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification`。実装は専用ブランチにあり、masterへ未統合。通常チェックアウト側の古い計画状態から再実装しない。

## 関連ドキュメント

- Spec: `docs/current/specs/2026-09-09-isolated-verification/00-overview.md` と詳細3件（確定コミット`1e63e8a`）。
- Plan: `docs/working/plans/2026-09-09-isolated-verification.md`（本セッションの3択への「１で」で確定）。
- 関連ADR: ADR-0145〜0148（Accepted）。包括的な判断の委任は未合意。
- 進行順序変更: ADR-0149（Accepted）。ユーザーが「リスク評価＋独立した検証を進める」を「1で」で承認。通信受容・通常利用は未承認。
- 前回の引き継ぎ: `docs/working/handoff/master.md`。
- 実測: `docs/working/issues/flow/0136-inspection-delegation-does-not-fire-destructive-verification-row/0136-note-common-cli-runtime.md`。
- リスク評価: 同Issueフォルダの`0136-note-network-risk-assessment.md`。
- 再利用の比較材料: 同Issueフォルダの`0136-note-loopforalpha-sandbox-reuse.md`。LoopForAlpha側の参照パスと、未決定の差分を記載。
- 履歴参照の要求・実装・検証: ADR-0150（Accepted）、同Issueフォルダの`0136-note-history-transfer.md`、`docs/records/reviews/2026-09-09-history-copy.md`。履歴提供と固定資料のClaude送信はユーザーが個別承認。

## 完了済みタスク

- [x] 計画確定、独立レビュー見送り、主担当の順次実装をユーザーが選択。
- [x] 専用worktreeを作成。既存のbuild-distとsync-templateのCheckが成功。
- [x] コピー準備26件、プロセス管理7ケース、結果照合15ケースの3テスト群が成功。詳細は実装計画の先行実装結果。
- [x] 合成データによるリスク評価。ローカルの1バイト往復とコピー外マーカー読取は成功。example.com:443の直接接続は制限側で拒否、通常側の前後は成功。
- [x] 限定利用条件を確認。認証保存先auth.jsonの読み取りハンドルを取得できた（内容未読）。ChromeDriver等のローカル待受が存在。詳細はリスク評価ノート。
- [x] 再利用差分と役割間の成果物の往復を調査。既存関数の3モードの引数生成を確認。Docker・AIの実起動は行っていない。詳細は`0136-note-loopforalpha-sandbox-reuse.md`。
- [x] Git履歴の独立コピーを追加。未コミット内容を保持してlog/show/blameを参照し、worktree入力・空のHEAD・不完全な履歴を検査。実行記録は`0136-note-history-transfer.md`。
- [x] 履歴変更の独立レビューを完了。2指摘を実測し、ブランチ名保持を修正。履歴23項目を含む4群が成功。実リポジトリのコピー、SHA256形式と参照更新も確認。詳細は上記レビュー記録。

## 進行中のタスク

- **現在の作業**: 履歴コピーの先行変更を確定し、未決の隔離方式へ戻る。
  - 状態: 履歴の提供・独立レビューと主担当の修正後検証は完了。ADR-0150を確定。追加の外部レビューは行っていない。隔離方式の比較材料は再利用ノート。
  - 残り: Linux試作を先行させるかWindows対応を維持するかを判断する。Docker採用・共通化・LoopForAlpha変更・既存試作撤去・実エージェント起動・通信受容・公開は未承認。

## 未着手のタスク

- [ ] 制限付きCodex起動設定、共通CLI結合、両主担当からの実証、全体レビュー。先行部品は実装計画の進捗を参照。

## 既知のブロッカー・懸念

- 公開・通常導入・既存物の削除は未承認。原本側の未追跡物、他worktreeとstashは`docs/working/handoff/master.md`の保全指示を維持。
- 導入済みプラグインは0.1.24、リポジトリの予定版は0.1.25。変更内容を自動で導入済みと扱わない。
- sandboxの通信拒否が未成立。詳細と2実行の証拠パスは`0136-note-common-cli-runtime.md`に保存。保護代用品6件のハッシュは不変。
- Claudeへの固定10ファイルの送信はユーザーの「1で」で承認され実行済み。原本・証拠は`.tmp/history-review/`に保存。別対象への送信や通常の検証担当の起動へ承認を拡張しない。
- `.tmp/`の試験・ログ・junctionと他作業の未追跡物を保全する。LoopForAlphaの既存コンテナの起動・停止・再ビルドは行っていない。

## 節目ごとの確認記録

- 2026-09-09 履歴レビュー完了・ADR-0150 Accepted 昇格: ADR=0150 / worklog=棄却（既存のレビュー照合・修正・検証手順の範囲） / cyclecheck=実施（修正: Issue-0136）

- 2026-09-09 レビュー準備とローカル再検証: ADR=なし（送信承認待ち、方式の採用なし） / worklog=棄却（既存の承認拒否対応・確認手順の範囲）

- 2026-09-09 Git履歴コピーの先行実装: ADR=0150 / worklog=棄却（既存の要求反映・実体照合・テスト修正の範囲）
- 2026-09-09 再利用差分と連携経路の調査: ADR=なし（方式・対応OSの変更は未選択） / worklog=棄却（既存の前提照合による調査で新たなdeltaなし）
- 2026-09-09 plan 確定点: ADR=なし（既存仕様と工程の選択、設計変更なし） / worklog=棄却（既存手順内でdeltaなし） / review=見送り
- 2026-09-09 worktree準備と基準検査: ADR=なし（承認済み計画に従う） / worklog=棄却（既存手順内でdeltaなし）
- 2026-09-09 タスク0の実測と停止: ADR=なし（計画の停止条件に従う、変更案未選択） / worklog=棄却（計画で要求された正負対照と停止）
- 2026-09-09 通信経路の追加調査: ADR=なし（比較実測のみ、方式未採用） / worklog=棄却（既存の実体照合・前提検査手順内）
- 2026-09-09 WFPの状態採取とトークン条件診断: ADR=なし（実測のみ、構成変更なし） / worklog=棄却（既存の実証手順内）
- 2026-09-09 管理者再試行と直後イベント照会: ADR=なし（同じ保護条件での観測） / worklog=棄却（既存の実証手順内）
- 2026-09-09 リスク評価と先行検証の方針承認: ADR=0149 / worklog=MakeAiInstructions-2026-09-09-06
- 2026-09-09 AIなし部品の先行検証: ADR=0149 / worklog=棄却（既存TDD手順による修正と検証）
- 2026-09-09 先行範囲の確認・ADR-0149 Accepted 昇格: ADR=0149 / worklog=棄却（既存の確認手順内） / cyclecheck=実施（修正: Issue-0136）
- 2026-09-09 限定利用条件の実測: ADR=なし（観測のみ、利用許容・方式変更は未決定） / worklog=棄却（既存の限定的な実証手順内）
- 2026-09-09 セッション中断と再利用材料の保存: ADR=なし（再利用案は未採用） / worklog=MakeAiInstructions-2026-09-09-07

## 次セッション開始時のアクション

1. start-workで本handoffを読み、専用worktreeとブランチを確認する。実装計画・リスク評価・ADR-0149が最新の正本。master側の古い計画選択から戻らない。
2. 履歴変更は`docs/records/reviews/2026-09-09-history-copy.md`で完了確認済み。隔離方式の比較は`0136-note-loopforalpha-sandbox-reuse.md`へ戻り、Linux試作先行かWindows対応維持かの判断を続ける。
3. 全体レビュー・CLI結合・V1〜V7は未完了。先行4群の再検証は`Run-IndependentTests.ps1`。履歴レビューの完了を隔離成功へ読み替えず、採用・導入・削除等の承認を拡張しない。

## 重要な意思決定の履歴

- ADR-0150: リポジトリのファイルとGit履歴をスクリプトで独立コピーへ渡す（2026-09-09、Accepted）。
- ADR-0145〜0148: 自律テスト作成、両主担当からCodex検証、共通CLI、独立Git管理領域（2026-09-09）。
