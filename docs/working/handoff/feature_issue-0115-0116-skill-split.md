# Handoff: session-handoff / decision-log の発火単位分割

- **Branch**: feature/issue-0115-0116-skill-split（master から分岐。マージ未実施）
- **Last Updated**: 2026-09-02 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: 設計/確定前レビューの反復中（ADR-0122 は Proposed・未コミット。第 3 巡完了、第 4 巡の方式をユーザー回答待ち）

## 作業の目的・背景

Issue-0115 / Issue-0116 の対策サイクル。ADR-0121 が導入した SKILL.md のサイズ警告（目安 20KB）に対し、`skills/session-handoff/SKILL.md` が 31,169B、`skills/decision-log/SKILL.md` が 26,837B で超過している。ADR-0121 決定 5 は張り替え規模を理由に両件を次サイクルへ送り、`scripts/build-dist.ps1` の例外テーブルへ暫定登録した。本サイクルはその残余を処理する。

分割方針は ADR-0122（起票済み・Proposed）で確定させる。両スキルとも呼び出し時点で操作・用途が確定しているため、条件発火の単位を「操作・用途」と「横断規範」の 2 系統とし、両方を `references/` へ出して SKILL.md 本文を共通部＋ディスパッチ表に絞る。

## 関連ドキュメント

- 本サイクルの決定: ADR-0122（`docs/records/decisions/0122-split-session-handoff-and-decision-log-by-firing-unit.md`。**未コミット・未追跡**。設計文書兼用のため設計 spec は作らない）
- 対象課題: `docs/working/issues/flow/0115-session-handoff-size-split-candidate.md` / `docs/working/issues/flow/0116-decision-log-size-split-candidate.md`
- 上流規範: ADR-0121（サイズ警告と分割判断の型）/ ADR-0116（責務帰属型・references 型の移設の先例）/ `CONTRIBUTING.md`「全シナリオ共通: SKILL.md のサイズと分割」
- 前サイクルの実装計画（張り替え取りこぼしのレビュー実測が 1404 行にある）: `docs/working/plans/2026-08-31-adr-0121-skill-size-norm-implementation.md`
- master の申し送り（本ブランチでも有効）: `docs/working/handoff/master.md`

## 完了済みタスク

- [x] brainstorming: 成功基準・①責務帰属型の判定・分割の軸の 3 決定（2026-09-01）
- [x] ADR-0122 ドラフト作成と決定インデックスへの行追加（2026-09-01）
- [x] 確定前レビュー 第 1〜3 巡（フル巡・各 4 観点 4 体・claude-sonnet-5）と設計縮小 1 回（2026-09-01〜09-02）

## 進行中のタスク

- [ ] **現在の作業**: ADR-0122 の確定前レビューの反復（spec 確定点 (c) は未通過。通過はドラフトのコミット時）
  - 状態（反復継続記載）: 対象確定点の型＝spec 確定点 (c) / 成果物の型＝**規範改定型（迷い判定・閾値は通常型の値＝4 巡）** / 実施済み＝フル巡 3 巡（claude-sonnet-5・各 4 観点 4 体）＋設計縮小 1 回（巡は立てない） / 保留中の選択＝第 4 巡の方式（フル巡／差分確認巡／機械検証／このまま確定）のユーザー回答待ち
  - 状態（続き）: 骨格安定＝**No**（第 3 巡でも設計骨格への新規指摘 3 件）/ Accepted 済み ADR 本文の改訂＝なし（ADR-0122 は Proposed のため改訂記録規定の対象外）/ 通算 3 巡のため**次の巡で分布外検知の閾値 4 巡に到達**し、以後の反復提示で毎回発火する
  - 改訂前退避: `~/.ai-dev-review-snapshots/MakeAiInstructions/2026-09-01-adr-0122-spec/` の `r1`〜`r4`（各改訂の直前版）と `r5-current`（第 3 巡反映後の最新版。セッション跨ぎ保護のため取得）
  - 残り: 第 4 巡の方式を選ぶ → 実施 → 確定（ADR とインデックスを同時コミット。ここが spec 確定点 (c)）→ writing-plans へ

## 未着手のタスク

- [ ] 実装計画の作成（writing-plans）→ plan 確定点。ADR-0122 決定 6 の (a)〜(g) の全数走査をタスク化する
- [ ] 実装: references 13 ファイルの新設・参照の張り替え・例外テーブル 2 行の削除
- [ ] 執行点 4 手順（`CONTRIBUTING.md`）と plugin version bump（0.1.17 → 0.1.18）
- [ ] 現用 spec `docs/current/specs/2026-08-07-distributed-artifact-generation/02-distribution-generator.md` の件数系数値の追従
- [ ] ADR-0122 の Accepted 昇格（サイクル全体整合検査を含む）と Issue-0115 / Issue-0116 の close

## 既知のブロッカー・懸念

- **ADR-0122 は未追跡ファイルのまま**。`docs/records/decisions/README.md` は 0122 行を追加した modified 状態で、**両者は同時コミットする**（インデックスだけ先に入れると存在しないファイルを指す）。反復が収束するまでコミットしない
- **反復コストが積み上がっている**: 3 巡で約 195 万トークン（第 1 巡 62 万・第 2 巡 67 万・第 3 巡 66 万）。反復コストの予算指針の不在は Issue-0103
- **完了条件 (b) は一部経路で未達を明示的に受容している**（ADR-0122 決定 1）。update の移設判定込み 54%・移設実行込み 62%。ユーザー承認済み（2026-09-02）
- master の handoff（`docs/working/handoff/master.md`）の申し送りは本ブランチでも全件有効。とくに配布経路・執行点 4 手順・記法規約・退避領域の扱い

## Post ラッパー消化記録

- 2026-09-01 brainstorming 完了・ADR-0122 起票（設計方針 3 決定）: ADR=0122（Proposed・未コミット） / worklog=棄却（delta なし。選択肢比較は既存スキルの手順内）
- 2026-09-02 確定前レビュー第 1〜3 巡と設計縮小の完了（反復継続中。詳細は ADR-0122 と「進行中のタスク」）: ADR=0122 改訂（Proposed 維持） / worklog=`MakeAiInstructions-2026-09-02-01`

## 次セッション開始時のアクション

1. **最初に確認**: 本ハンドオフの「進行中のタスク」の反復継続記載と `docs/records/decisions/0122-split-session-handoff-and-decision-log-by-firing-unit.md`（未追跡）。退避は `~/.ai-dev-review-snapshots/MakeAiInstructions/2026-09-01-adr-0122-spec/`
2. **最初に実行**: `start-work`（Phase 0 で本ハンドオフを read）。再開点は `pre-finalization-review` の反復提示——第 4 巡の方式選択から。前回提示の選択肢はフル巡／差分確認巡／機械検証／このまま確定の 4 択
3. **留意点**: 反復が収束するまで ADR-0122 とインデックスをコミットしない。通算 3 巡のため次の巡から分布外検知が毎回発火する。骨格安定は No のまま。骨格（決定 3・4・5・7）は 3 巡・12 体で一度も動いていない

## 重要な意思決定の履歴

- ADR-0122: session-handoff と decision-log は発火単位で references へ分割し、SKILL.md 本文を共通部とディスパッチ表に絞る（2026-09-01 Proposed・未コミット）
- （ADR-0001〜0121 は `docs/records/decisions/README.md` 参照）
