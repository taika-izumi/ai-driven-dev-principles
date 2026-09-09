# Handoff: 隔離検証の共通起動処理の実装

- **Branch**: codex/isolated-verification
- **Last Updated**: 2026-09-09 12:15 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: リスク評価とAIなし部品の先行検証 / 利用条件の判断待ち

## 作業の目的・背景

Claude CodeとCodexの主担当から共通CLIを呼び、隔離されたコピー内で追加テストを作成・実行する。仕様確定後の計画草案を再開し、ユーザーが主担当の順次実装と計画レビュー見送りを選択した。

## 関連ドキュメント

- Spec: `docs/current/specs/2026-09-09-isolated-verification/00-overview.md` と詳細3件（確定コミット`1e63e8a`）。
- Plan: `docs/working/plans/2026-09-09-isolated-verification.md`（本セッションの3択への「１で」で確定）。
- 関連ADR: ADR-0145〜0148（Accepted）。包括的な判断の委任は未合意。
- 進行順序変更: ADR-0149（Accepted）。ユーザーが「リスク評価＋独立した検証を進める」を「1で」で承認。通信受容・通常利用は未承認。
- 前回の引き継ぎ: `docs/working/handoff/master.md`。
- 実測: `docs/working/issues/flow/0136-inspection-delegation-does-not-fire-destructive-verification-row/0136-note-common-cli-runtime.md`。
- リスク評価: 同Issueフォルダの`0136-note-network-risk-assessment.md`。

## 完了済みタスク

- [x] 計画確定、独立レビュー見送り、主担当の順次実装をユーザーが選択。
- [x] 専用worktreeを作成。既存のbuild-distとsync-templateのCheckが成功。
- [x] コピー準備26件、プロセス管理7ケース、結果照合15ケースの3テスト群が成功。詳細は実装計画の先行実装結果。
- [x] 合成データによるリスク評価。ローカルの1バイト往復とコピー外マーカー読取は成功。example.com:443の直接接続は制限側で拒否、通常側の前後は成功。

## 進行中のタスク

- **現在の作業**: 限定利用の条件確認か別環境の判断。
  - 状態: 通信の内部原因追跡を区切り、先行部品の検証を完了。外部直接接続の拒否は確認した1宛先に限定。書込制限を機密性の保護にはできない。
  - 残り: 読める情報とローカルサービス経由のリスクを管理できるか判断する。実エージェント起動・公開は保留。コードの独立レビューと全体の結合検証は未実施。

## 未着手のタスク

- [ ] 制限付きCodex起動設定、共通CLI結合、両主担当からの実証、全体レビュー。先行部品は実装計画の進捗を参照。

## 既知のブロッカー・懸念

- 公開・通常導入・既存物の削除は未承認。原本側の未追跡物、他worktreeとstashは`docs/working/handoff/master.md`の保全指示を維持。
- 導入済みプラグインは0.1.24、リポジトリの予定版は0.1.25。変更内容を自動で導入済みと扱わない。
- sandboxの通信拒否が未成立。詳細と2実行の証拠パスは`0136-note-common-cli-runtime.md`に保存。保護代用品6件のハッシュは不変。

## 節目ごとの確認記録

- 2026-09-09 plan 確定点: ADR=なし（既存仕様と工程の選択、設計変更なし） / worklog=棄却（既存手順内でdeltaなし） / review=見送り
- 2026-09-09 worktree準備と基準検査: ADR=なし（承認済み計画に従う） / worklog=棄却（既存手順内でdeltaなし）
- 2026-09-09 タスク0の実測と停止: ADR=なし（計画の停止条件に従う、変更案未選択） / worklog=棄却（計画で要求された正負対照と停止）
- 2026-09-09 通信経路の追加調査: ADR=なし（比較実測のみ、方式未採用） / worklog=棄却（既存の実体照合・前提検査手順内）
- 2026-09-09 WFPの状態採取とトークン条件診断: ADR=なし（実測のみ、構成変更なし） / worklog=棄却（既存の実証手順内）
- 2026-09-09 管理者再試行と直後イベント照会: ADR=なし（同じ保護条件での観測） / worklog=棄却（既存の実証手順内）
- 2026-09-09 リスク評価と先行検証の方針承認: ADR=0149 / worklog=MakeAiInstructions-2026-09-09-06
- 2026-09-09 AIなし部品の先行検証: ADR=0149 / worklog=棄却（既存TDD手順による修正と検証）
- 2026-09-09 先行範囲の確認・ADR-0149 Accepted 昇格: ADR=0149 / worklog=棄却（既存の確認手順内） / cyclecheck=実施（修正: Issue-0136）

## 次セッション開始時のアクション

1. 本handoff、実装計画、`0136-note-network-risk-assessment.md`とADR-0149を確認する。
2. 限定利用の条件確認か別環境の比較を判断する。原因追跡へ自動で戻らず、通常利用・実エージェント起動の承認を推定しない。
3. 先行3群の再検証は`Run-IndependentTests.ps1`。全体の独立レビュー・CLI結合・V1〜V7の認定は未完了。

## 重要な意思決定の履歴

- ADR-0145〜0148: 自律テスト作成、両主担当からCodex検証、共通CLI、独立Git管理領域（2026-09-09）。
