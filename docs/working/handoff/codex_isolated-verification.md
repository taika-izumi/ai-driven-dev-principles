# Handoff: 隔離検証の共通起動処理の実装

- **Branch**: codex/isolated-verification
- **Last Updated**: 2026-09-09 11:02 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 実装 / タスク0の通信拒否不成立・次手判断待ち

## 作業の目的・背景

Claude CodeとCodexの主担当から共通CLIを呼び、隔離されたコピー内で追加テストを作成・実行する。仕様確定後の計画草案を再開し、ユーザーが主担当の順次実装と計画レビュー見送りを選択した。

## 関連ドキュメント

- Spec: `docs/current/specs/2026-09-09-isolated-verification/00-overview.md` と詳細3件（確定コミット`1e63e8a`）。
- Plan: `docs/working/plans/2026-09-09-isolated-verification.md`（本セッションの3択への「１で」で確定）。
- 関連ADR: ADR-0145〜0148（Accepted）。包括的な判断の委任は未合意。
- 前回の引き継ぎ: `docs/working/handoff/master.md`。
- 実測: `docs/working/issues/flow/0136-inspection-delegation-does-not-fire-destructive-verification-row/0136-note-common-cli-runtime.md`。

## 完了済みタスク

- [x] 計画確定、独立レビュー見送り、主担当の順次実装をユーザーが選択。
- [x] 専用worktreeを作成。既存のbuild-distとsync-templateのCheckが成功。

## 進行中のタスク

- **現在の作業**: タスク0の起動・保護試験。
  - 状態: 通常ユーザー側で親子の書き込み保護と新規junctionの拒否を観測。通信禁止の指定でもループバックTCPが成功し、タスク0は未完了。
  - 残り: WFP診断で接続直前の遮断フィルターとトークン条件を確認したが原因は未特定。既存イベント取得の管理者起動はWindows側で取消となり未実行。詳細は`0136-note-wfp-loopback-diagnostic.md`。タスク1へ進まない。

## 未着手のタスク

- [ ] タスク1〜4: コピー準備、制限付き実行、結果回収、両主担当からの実証。

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

## 次セッション開始時のアクション

1. 本handoffと実装計画、`0136-note-common-cli-runtime.md`を確認する。計画確定・主担当実装・レビュー見送りは承認済み。
2. 既存イベント取得の管理者起動が取り消されたことを確認し、再実行の判断を待つ。セッション97586は終了。取得コードは`Invoke-WfpDiagnostic.ps1`。
3. 保護条件が不成立なら後続実装へ進まず、根拠と必要な準備を示す。公開・導入は別判断。

## 重要な意思決定の履歴

- ADR-0145〜0148: 自律テスト作成、両主担当からCodex検証、共通CLI、独立Git管理領域（2026-09-09）。
