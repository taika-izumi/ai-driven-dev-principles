# Handoff: レビュー方式の推奨と指摘採否の費用評価の見直し

- **Branch**: codex/issue-0107-0124-review-judgment
- **Last Updated**: 2026-09-05 22:17 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: ガイドライン拡張 / 設計・実装計画確定済み、実装前にセッション中断

## 作業の目的・背景

ユーザーの指示により Issue-0107 と Issue-0124 の同時対策に着手した。レビュー方式の推奨を状況に即したものにし、指摘対応で追加する仕組みの導入・運用・保守費用も採否の判断材料に含めることを検討する。

## 関連ドキュメント

- 課題: `docs/working/issues/flow/0107-iterative-review-recommendation-divergence/0107-iterative-review-recommendation-divergence.md`
- 課題: `docs/working/issues/flow/0124-review-driven-mechanism-growth-lacks-cost-side-evaluation.md`
- 現行規範: `skills/pre-finalization-review/SKILL.md` と同ディレクトリの `references/iteration-norms.md`
- 拡張手順: `CONTRIBUTING.md`
- 前回の引き継ぎ: `docs/working/handoff/master.md`
- 関連ADR: `docs/records/decisions/0124-review-minimum-as-recommendation-with-user-discretion.md`（Proposed）
- 関連ADR: `docs/records/decisions/0125-evaluate-cost-of-review-driven-additions.md`（Proposed）
- Spec: `docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md`
- レビュー記録: `docs/working/issues/flow/0107-iterative-review-recommendation-divergence/0107-2026-09-05-spec-review-r1.md`
- 差分再確認: `docs/working/issues/flow/0107-iterative-review-recommendation-divergence/0107-2026-09-05-spec-review-r2.md`
- Plan: `docs/working/plans/2026-09-05-review-judgment-and-cost-evaluation.md`
- 計画レビュー: `docs/working/issues/flow/0107-iterative-review-recommendation-divergence/0107-2026-09-05-plan-review-r1.md`

## 完了済みタスク

- [x] start-work の継続確認と旧見出しの更新（2026-09-05）。master.md の確認記録の見出しと説明文を現行語彙へ更新し、差分を確認した。
- [x] 専用ブランチの作成と課題本体・現行推奨規範の初期確認（2026-09-05）。
- [x] 独立レビューを最低1回強く推奨し、見送りはユーザー判断に残す方針の承認・ADR-0124 ドラフト作成（2026-09-05）。
- [x] 具体策の承認、ADR-0124の詳細化・ADR-0125の起票、既存設計書の更新・自己点検（2026-09-05）。
- [x] spec 確定点のフル実施第1回（2体4観点）の受領・前提検査・修正案反映（2026-09-05）。
- [x] 新規1体の差分再確認（gpt-5.6-sol / high）。4件すべてOK、新規指摘0件で実質的な収束（2026-09-05）。
- [x] plan 確定点: 1体4観点レビューの指摘2件を反映し、ユーザー判断で追加レビューなしに確定（2026-09-05）。確定理由は計画末尾を参照。

## 進行中のタスク

- [ ] **現在の作業**: 確定計画に基づく実装の開始待ち。
  - 状態: 設計・計画は確定済み。追加の計画レビューはユーザーが見送り、作業品質と費用の観点で新しいセッションへ切り替える。実装タスク1〜4はすべて未着手。
  - 残り: 計画の準備確認と、タスク1の改定前の判断例確認から始める。スキルソース・配布物・版数はまだ変更していない（0.1.19）。
  - 留意点: ADR-0124・0125は実装検証までProposed。計画修正後の独立レビューを通過したとは扱わない。計画の確定記録とレビュー記録が正本。

## 未着手のタスク

- [ ] 確定計画のタスク1〜4（判断例検証、スキル・手引きの改定、旧ADR注記、配布・整合検証）。
- [ ] 実装時に旧ADRへの部分修正注記を追加する（ADR-0080・0107・0120は0124、ADR-0102・0117は0125による部分修正）。旧ADRはAcceptedを維持する。
- [ ] 規範の改定、配布物生成・検証、完了処理。

## 既知のブロッカー・懸念

- `.claude/`、`docs/conversation_log.md`、inbox 3件は既存の未追跡ファイル。inbox はユーザーが手動整理予定のため対象へ含めない。
- Git は実行ユーザーと所有者が異なるため、対象リポジトリだけの `-c safe.directory=...` を使用。ブランチ作成はサンドボックス外で実行し成功した。
- 改定対象自身の新しい運用はまだ採用していない。現行の確定前レビュー規範を適用する。

## 節目ごとの確認記録

- 2026-09-05 start-work 継続確認・旧見出し更新: ADR=なし（ADR-0123 に従う語彙更新） / worklog=棄却（既存スキルに従う更新）
- 2026-09-05 専用ブランチ作成・初期確認: ADR=なし（引き継ぎの候補への着手。対策方針は未決） / worklog=棄却（権限制約は既存の権限手順で解消）
- 2026-09-05 レビュー実施判断の方針承認: ADR=0124（Proposed、設計検討中） / worklog=棄却（既存手順による方針確認・記録）
- 2026-09-05 具体策承認・設計書更新と自己点検: ADR=0124・0125（Proposed） / worklog=棄却（既存の設計・確認手順で実施）
- 2026-09-05 spec 確定点・第1回と差分再確認終了: ADR=0124・0125 / worklog=棄却（既存手順による差分確認） / review=フル実施（gpt-5.6-sol・1 回）＋差分再確認（gpt-5.6-sol・1 回・実質的な収束）
- 2026-09-05 実装計画草稿と自己点検: ADR=なし（承認済み設計と既存スキルの手順を具体化） / worklog=棄却（既存の計画照合・生成検査で実施）
- 2026-09-05 plan 確定点・ユーザー判断で確定: ADR=なし（追加レビューの実施判断） / worklog=MakeAiInstructions-2026-09-05-08 / review=フル実施（gpt-5.6-sol・1 回・提示後確定（実質的な収束に至らず））

## 次セッション開始時のアクション

1. 本ファイル、関連ドキュメントの確定計画・設計書・ADR-0124/0125を読む。計画の確定は承認済みで、追加レビューを再提案する必要はない。
2. start-workの継続確認後、plan-deviation-defaults.mdを読み、executing-plansで計画の準備確認とタスク1から実装する。判断例検証を含め全タスク未着手。
3. ブランチはcodex/issue-0107-0124-review-judgmentを継続。未追跡の.claude/・会話ログ・inbox3件は対象外。実装検証後にADR昇格・課題closeを行う。push・マージは未実施。

## 重要な意思決定の履歴

- ADR-0124: 確定前レビューの方式と人数は状況から推奨し、実施・見送りはユーザー判断に残す（2026-09-05、Proposed）。
- ADR-0125: レビュー対応で追加する仕組みは、失敗の根拠と導入・維持費用を既存の採否手順で比較する（2026-09-05、Proposed）。
