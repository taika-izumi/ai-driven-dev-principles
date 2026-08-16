# Handoff: Issue-0092 確率的逸脱前提のガイドライン全体棚卸し

- **Branch**: feature/issue-0092-guideline-audit
- **Last Updated**: 2026-08-16 20:55 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 監査完了（Task 1〜10 全完了・ADR-0100/0101 Accepted）。残りは master への --no-ff マージと retrospective

## 作業の目的・背景

Issue-0092 の対応サイクル。「AI の出力は確率的に決定されるため、逸脱・矛盾は必ず残る」という前提（ADR-0099 Context で初明文化）を持たずに積まれたガイドラインの蓄積分に、期待検出量に見合わない過剰な手順が含まれていないかを、規範ごとの台帳（発火頻度・検出実績）を作って実測で監査する。監査は 1 回限りの調査として実施し、常設工程は増やさない。

判定は検出実績の絶対数ではなく**発火機会数に対する比**で行い、配布先実運用に晒されていない規範は保留側へ倒す（起票時のユーザー指摘。Issue-0092 の留意節が正）。あわせて今後の増設への歯止め（ADR-0099 の複雑化抑制制約の一般規範化）も検討対象。

## 関連ドキュメント

- 監査方法の決定（設計文書を兼ねる）: ADR-0100（コミット `3a044ff`）
- 課題の正本: `docs/working/issues/flow/0092-stochastic-deviation-premise-audit-of-procedures.md`
- 関連ADR: ADR-0099（複雑化抑制制約）、ADR-0079（過剰適合点検）、ADR-0092（サイクル全体整合検査）、ADR-0080（確定前レビュー提示規則）、ADR-0057（消化記録）、ADR-0073（退役条項の定義元。本監査が初回行使）
- 隣接課題: Issue-0045 / Issue-0042（検出力実証の根拠）/ Issue-0048（退役検出の機械化。本監査は手動行使）
- 検出実績の材料: `docs/records/retrospectives/README.md`、消化記録の git 履歴、worklog 中央ストア、各 ADR の検出実績記述
- 重なる課題: Issue-0045（open 課題の実行可能性点検）

## 完了済みタスク

- [x] 監査方法の設計と確定（brainstorming → ADR-0100。3 観点フルレビュー 37 件反映。2026-08-16 完了）
- [x] 実装計画の作成（`docs/working/plans/2026-08-16-issue-0092-guideline-audit-plan.md`。plan 確定点はレビュー見送り。2026-08-16 完了）
- [x] 監査の実行 Phase A（Task 1〜6: 台帳 155 レコード・被覆 18/18・中間確認承認。2026-08-16 完了）
- [x] 監査の実行 Phase B（Task 7〜10: 分類 keep 72/統合 22/保留 44/簡素化 3/退役 0 を ADR-0101 で確定。Issue-0093〜0097 起票・Issue-0092 close・ADR-0100/0101 Accepted。2026-08-16 完了）

## 進行中のタスク

- [ ] **現在の作業**: サイクルの完了処理
  - 状態: 全成果物コミット済み（先端 `9038f87`）。handoff のみ未コミット
  - 残り: master への --no-ff マージ（Issue-0084 の手動適用・6 サイクル連続）→ retrospective → cycle-reset → finalize

## 未着手のタスク

- [ ] 対象規範のインベントリ作成（発火頻度・コスト）
- [ ] 規範ごとの検出実績集計（発火機会数との比）
- [ ] keep / 簡素化 / 統合 / 退役候補の分類とユーザー判断
- [ ] 増設への歯止め（複雑化抑制制約の一般規範化）の検討

## 既知のブロッカー・懸念

- 配布元は `dist/`（ADR-0082）。スキル改定に至る場合は執行点 4 手順＋version bump（ADR-0090）
- inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定。organize-inbox 提案不要。`git add` で巻き込まないこと（Issue-0020）

## Post ラッパー消化記録

- 2026-08-16 ADR-0100 監査方法設計確定（spec 確定点 (c)）: ADR=0100 / worklog=`MakeAiInstructions-2026-08-16-03` / review=フル実施（claude-opus-5）
- 2026-08-16 実装計画作成完了（plan 確定点）: ADR=なし（ADR-0100 の写像のみ） / worklog=棄却（写像欠落 3 件の自己検出は writing-plans の既存セルフレビュー工程で実施） / review=見送り
- 2026-08-16 監査 Phase A 実行完了（plan Task 1〜5）: ADR=なし（露出閾値等は中間確認のユーザー判断待ち） / worklog=`MakeAiInstructions-2026-08-16-04`
- 2026-08-16 Task 6 中間確認通過（台帳・閾値 30・155 行を承認）: ADR=なし（ADR-0100 既定の手続き内の確定。記録は ledger と Phase B の結果 ADR） / worklog=棄却（delta なし）
- 2026-08-16 監査 Phase B 集計・分類完了（plan Task 7〜8）: ADR=なし（分類は Task 9 のユーザー判断待ち） / worklog=棄却（I-18 誤判定の教訓は report 3-3 が正本。引用元を当たらない同型 delta は `MakeAiInstructions-2026-08-16-03` 記録済み）
- 2026-08-16 監査結果確定・ADR-0100/0101 Accepted 昇格（Task 9〜10）: ADR=0101（記録のみの決定のため spec 確定点 (c) 非該当・review 不要） / worklog=棄却（判断と結果は ADR-0101/report が正本） / cyclecheck=非該当（対象文書の変更なし）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本 handoff と `docs/working/issues/flow/0092-stochastic-deviation-premise-audit-of-procedures.md`（特に留意節）
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）
3. 留意点: 監査は 1 回限りの調査。常設工程を新設しない。判定は発火機会数との比で行う

## 重要な意思決定の履歴

- ADR-0100: 全体棚卸しは常時発火規範の全数台帳と二トラック判定による一回限りの監査として実施する（2026-08-16 Accepted）
- ADR-0101: 監査の判定を keep 72・統合 22・保留 44・簡素化 3・退役 0 で確定し、増設の歯止めは評価可能性の義務化（弱い形）とする（2026-08-16 Accepted）
