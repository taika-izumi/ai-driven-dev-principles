# Handoff: Issue-0098 確定前レビュー反復の発動基準設計

- **Branch**: feature/issue-0098-iterative-review-criteria
- **Last Updated**: 2026-08-18 17:40 (Asia/Tokyo)
- **Status**: completed
- **Current Phase**: サイクル完了（master へ --no-ff マージ `976b45c`・retrospective 実施済み。cycle-reset は master.md へ適用——Issue-0102 の応急規範どおり本ファイルは completed で閉鎖）

## 作業の目的・背景

Issue-0098（確定前レビューの反復〈指摘反映後の再レビュー〉の発動基準が未定義）の対策サイクル。brainstorming で設計承認（Q1〜Q5: 核心 3 点拘束＋運用型は適用例・継続レビュアーは役割限定・2 段型推奨・Accepted 後改訂は 2 分岐・4 スキル分散配置）。ADR-0107（反復基準・設計文書兼用）と ADR-0108（Accepted 後改訂のステータス運用。第 1 巡の粒度指摘で分離）を Proposed 起票し、本 ADR 群自身に新規範を先行適用して確定前レビューを反復した。

## 関連ドキュメント

- Plan: `docs/working/plans/2026-08-18-issue-0098-adr-0107-0108-implementation.md`（Task 1〜8。実装の作業指示の正本）
- 課題正本: `docs/working/issues/flow/0098-iterative-review-trigger-criteria/0098-iterative-review-trigger-criteria.md`
- 実測の一次記録: 同フォルダ `0098-log.md`（末尾行に本サイクル 9 巡の巡実測。確定時に最終巡数へ更新）
- ADR: `docs/records/decisions/0107-iterative-review-recommendation-by-revision-nature.md` / `0108-accepted-adr-revision-status-handling.md`（Proposed・コミット済み。決定インデックス行も同コミット）
- 現行規範の正本: `start-work`「確定前レビューの提示規則」/ ADR-0080。関連: ADR-0067/0072/0088/0092/0102/0106
- worklog: `MakeAiInstructions-2026-08-18-01`（反復の限界効用低下の議題化は人間側から行われた delta）

## 完了済みタスク

- [x] Issue-0098 フォルダ昇格＋昇格後フォーマット適合（2026-08-18、`1fa42e3`）
- [x] brainstorming 設計承認（Q1〜Q5）・ADR-0107/0108 Proposed 起票・決定インデックス行追加
- [x] 確定前レビュー フル 9 巡（各巡 3 観点・新規レビュアー claude-opus-5）＋設計縮小 3 回（ユーザー承認）。第 9 巡指摘まで全反映済み。C/M 推移 = 3/15→4/12→2/13→1/11→2/10→4/5→1/8→2/8→1/7・全指摘採用・実証なし指摘ゼロ
- [x] 反復の現状分析（第 9 巡後・ユーザー指示）: 停止しない構造の特定と改善提案の整理（下記）
- [x] 案 A 採択・設計フィードバックを ADR-0107 へ反映（締めモード・採否・修正既定・継続レビュアー窓）＋第 10 巡フル（3 観点 2 体兼務・claude-opus-5）で C6/M9/m6 検出・全採用・第 4 次設計縮小（状態機械→推奨規則）を適用（2026-08-18。0098-log へ分析行を追記）
- [x] 第 11 巡フル（3 観点 2 体兼務・claude-opus-5）で名寄せ後 C2/M8/m9 検出・全採用・反映（2026-08-18。主対応: 採否確定を反復提示への回答へ一元化・骨格安定の証拠非対称規則・第 2 経路の残指摘条件・骨格定義に削除を明記・述語形への語統一・実装対象へ pre-finalization-review (6) 追加）
- [x] 第 12 巡フル（3 観点 2 体兼務・claude-opus-5）で名寄せ後 C4/M15/m10 検出・全採用・前置 1 発火で**第 5 次設計縮小**を適用（2026-08-18。骨格安定を規範的述語から判断材料＋推奨ヒューリスティックへ降格し派生機構〈非対称規則・初回起点・陳腐化規定・委譲項目の判定材料〉を削除。終了状態の定義を簡素化〈`実質収束` の反復巡条件削除＝9 巡安定本文の潜在バグ解消・`改訂なし確定`＝指摘なしのみ〉。締めの機構 3 案比較を Considered Alternatives へ追記・再点検 3 箇所・spec 骨子 5 同期・退役条件拡張）
- [x] 第 13 巡差分確認巡（1 体・claude-opus-5・対応表 24 行検証＝解消 21・骨格 Critical 0）＋骨格 Major 3・機械/表現 7 を採用修正・精度型 2 件を 0098-log 経由で実装時レビューへ委譲＋機械検証（齟齬ゼロ）で反復終了。Issue-0103（反復コスト予算）起票。**spec 確定点 (c) 通過**＝ADR-0107/0108・決定インデックス・0098-log・Issue-0103・handoff を同一コミット（2026-08-18）

## 進行中のタスク

- [ ] **現在の作業**: feature ブランチの完了処理（superpowers:finishing-a-development-branch。実行直前に start-work「完了処理のマージ方式確認」を適用）
  - 状態: 未着手。実装は Task 1〜8 全消化（T1: `8e4dbad`+`683e705`+`27dbb1e` / T2: `88b9bbf`+`37539c6`+`940ea04` / T3: `97cf14f`+`5dde4c8`+`ea7a2dc` / T4: `e0cfaf6`+`f8706ed` / T5: `2f17a04`+`cbb2c27` / T6: `a3bf0ba`+`b7370eb` / T7: `9ceffc9` / T8: `e7dd482`）。全タスク仕様準拠 ✅・品質指摘全採用・横断検証 51/51 箇条対応・委譲精度型 2 件解消
  - 残り: マージ方式確認 → master へ取り込み → retrospective → cycle-reset

## 未着手のタスク

- [ ] feature ブランチの完了処理（master への取り込み）→ retrospective → cycle-reset

## 既知のブロッカー・懸念

- 第 13 巡で不採用とし実装時レビューへ委ねた精度型 2 件（0098-log 末尾行）を、実装時レビューの委譲プロンプトから参照させること（ADR-0107 決定 2 の委譲運用の初適用）
- 配布対象ソース変更時は執行点 4 手順＋version bump（現行 0.1.9）。ガイドライン拡張の過剰適合点検・評価可能性は ADR に記載済み（反映変更時は再点検）
- inbox 残置 3 件＋ conversation_log.md はユーザー手動移動予定。organize-inbox 提案不要。`git add` で巻き込まない（Issue-0020）

## Post ラッパー消化記録

- 2026-08-18 Issue-0098 フォルダ昇格完了: ADR=なし（課題管理定義 §4 の既定運用の適用のみ） / worklog=棄却（delta なし・既定手順の適用のみ）
- 2026-08-18 ADR-0107/0108 Proposed 起票・確定前レビュー反復開始: ADR=0107/0108（Proposed） / worklog=（spec 確定点 (c) 通過時に判定。反復の途中状態は「進行中のタスク」節が正本）
- 2026-08-18 反復 9 巡・現状分析・セッション中断: ADR=なし（設計フィードバックは提案のみ・未承認） / worklog=`MakeAiInstructions-2026-08-18-01`
- 2026-08-18 案 A 反映・第 10 巡フル・指摘反映（第 4 次設計縮小）: ADR=なし（ADR-0107 本文の改訂として記録・独立論点なし） / worklog=棄却（ADR-0107 と 0098-log に記録済み・delta なし）
- 2026-08-18 第 11 巡フル・指摘 19 件反映: ADR=なし（ADR-0107 本文の改訂として記録・独立論点なし） / worklog=棄却（ADR-0107 に記録済み・delta なし）
- 2026-08-18 第 12 巡フル・第 5 次設計縮小適用: ADR=なし（ADR-0107 本文の改訂〈Considered Alternatives 追記含む〉として記録） / worklog=棄却（ADR-0107 に記録済み・delta なし）
- 2026-08-18 spec 確定点 (c) 通過（ADR-0107/0108 確定・コミット）: ADR=0107/0108（Proposed 維持） / worklog=棄却（正本〈ADR・0098-log〉に記録済み・delta なし） / review=フル実施（claude-opus-5・12 巡）＋差分再確認（claude-opus-5・1 巡）＋機械検証（1 回・提示後確定（実質収束せず））
- 2026-08-18 実装 plan 作成・plan 確定点 通過: ADR=なし（写像 plan・新規決定なし。ADR-0107 の誤記 1 件〈決定 1 (5) 実装先〉を同時修正） / worklog=棄却（期待値と編集内容の矛盾は Issue-0095 の既知型・delta なし） / review=差分再確認（claude-opus-5・1 巡・提示後確定（実質収束せず））
- 2026-08-18 plan Task 1 完了（start-work 改定）: ADR=なし（写像実装。3-2 (a) 読み替え句の一般化は委譲精度型の解消として ADR-0107 と同期） / worklog=棄却（実装ループ内で解決・delta なし）
- 2026-08-18 plan Task 2 完了（pre-finalization-review 改定）: ADR=なし（写像実装。継続対象体明記・退避のディレクトリ対応を ADR-0107 決定 3 へ同期） / worklog=棄却（実装ループ内で解決・delta なし）
- 2026-08-18 plan Task 3 完了（session-handoff 改定）: ADR=なし（写像実装。品質レビューの記録シナリオ検査で出た明確化 8 件を ADR-0107 決定 4 へ同期） / worklog=棄却（実装ループ内で解決・delta なし）
- 2026-08-18 plan Task 4 完了（decision-log 改定）: ADR=なし（写像実装。回数スロット・契機混在の明確化を ADR-0108 へ同期） / worklog=棄却（実装ループ内で解決・delta なし）
- 2026-08-18 plan Task 5・6 完了（ADR 注記 4 件・spec 4 件同期）: ADR=なし（写像実装。委譲精度型 2 件は Task 1/6 で解消済み） / worklog=棄却（実装ループ内で解決・delta なし）
- 2026-08-18 plan Task 7・8 完了・Issue-0098 close・ADR-0107/0108 Accepted 昇格: ADR=0107/0108（Accepted 昇格） / worklog=棄却（配布破損 3 件は CONTRIBUTING の目視工程が設計どおり検出・delta なし） / cyclecheck=実施（指摘なし。実体は Task 1〜8 の 2 段レビュー群＋Task 8 横断検証〈51/51 対応・dist -Check exit 0〉＋昇格前の数値・引用スポット確認）

## 次セッション開始時のアクション

1. **最初に確認**: 本 handoff →「進行中のタスク」（実装は完了済み・残るは完了処理のみ）
2. **最初に実行**: superpowers:finishing-a-development-branch（実行直前に start-work「完了処理のマージ方式確認」を適用）→ マージ後に retrospective → cycle-reset
3. **留意点**: マージ後の cycle-reset の適用先はマージ先ブランチの handoff（Issue-0102 の実測に注意）。inbox 残置はユーザー手動移動予定（git add で巻き込まない・Issue-0020）

## 重要な意思決定の履歴

- ADR-0107: 指摘反映後の再レビューは改訂の性質で推奨を切り替え、収束は指摘の分類で判定する（2026-08-18 Accepted）
- ADR-0108: Accepted 昇格後の ADR 本文改訂は決定内容の変更有無でステータス運用を分ける（2026-08-18 Accepted。ADR-0107 から粒度分離）
