# Handoff: session-handoff / decision-log の発火単位分割

- **Branch**: feature/issue-0115-0116-skill-split（master から分岐。マージ未実施）
- **Last Updated**: 2026-09-02 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: 設計確定済み／実装計画の作成前（ADR-0122 は Proposed でコミット済み。次は writing-plans）

## 作業の目的・背景

Issue-0115 / Issue-0116 の対策サイクル。ADR-0121 が導入した SKILL.md のサイズ警告（目安 20KB）に対し、`skills/session-handoff/SKILL.md` が 31,169B、`skills/decision-log/SKILL.md` が 26,837B で超過している。ADR-0121 決定 5 は張り替え規模を理由に両件を次サイクルへ送り、`scripts/build-dist.ps1` の例外テーブルへ暫定登録した。本サイクルはその残余を処理する。

分割方針は ADR-0122（起票済み・Proposed）で確定させる。両スキルとも呼び出し時点で操作・用途が確定しているため、条件発火の単位を「操作・用途」と「横断規範」の 2 系統とし、両方を `references/` へ出して SKILL.md 本文を共通部＋ディスパッチ表に絞る。

## 関連ドキュメント

- 本サイクルの決定: ADR-0122（`docs/records/decisions/0122-split-session-handoff-and-decision-log-by-firing-unit.md`。コミット済み a6991f9。設計文書兼用のため設計 spec は作らない）
- 対象課題: `docs/working/issues/flow/0115-session-handoff-size-split-candidate.md` / `docs/working/issues/flow/0116-decision-log-size-split-candidate.md`
- 上流規範: ADR-0121（サイズ警告と分割判断の型）/ ADR-0116（責務帰属型・references 型の移設の先例）/ `CONTRIBUTING.md`「全シナリオ共通: SKILL.md のサイズと分割」
- 前サイクルの実装計画（張り替え取りこぼしのレビュー実測が 1404 行にある）: `docs/working/plans/2026-08-31-adr-0121-skill-size-norm-implementation.md`
- master の申し送り（本ブランチでも有効）: `docs/working/handoff/master.md`

## 完了済みタスク

- [x] brainstorming: 成功基準・①責務帰属型の判定・分割の軸の 3 決定（2026-09-01）
- [x] ADR-0122 ドラフト作成と決定インデックスへの行追加（2026-09-01）
- [x] 確定前レビュー 第 1〜6 巡（フル巡 3・差分確認巡 3・計 15 体・claude-sonnet-5）と設計縮小 1 回（2026-09-01〜09-02）
- [x] ADR-0122 の設計確定とコミット（spec 確定点 (c) 通過。a6991f9・2026-09-02）

## 進行中のタスク

- [ ] **現在の作業**: 実装計画の作成（writing-plans）
  - 状態: 未着手。ADR-0122 決定 6 の (a)〜(g) の全数走査をタスク化する。(f) は「分割後 13 ファイルの単独では意味が確定しない語・手順・数値の列挙を空を含め 1 行ずつ書き出す」が完了基準
  - 残り: plan を作成 → plan 確定点で `pre-finalization-review` の提示操作を呼ぶ

## 未着手のタスク

- [ ] 実装: references 13 ファイルの新設・参照の張り替え・例外テーブル 2 行の削除
- [ ] 執行点 4 手順（`CONTRIBUTING.md`）と plugin version bump（0.1.17 → 0.1.18）
- [ ] 現用 spec `docs/current/specs/2026-08-07-distributed-artifact-generation/02-distribution-generator.md` の件数系数値の追従
- [ ] ADR-0122 の Accepted 昇格（サイクル全体整合検査を含む）と Issue-0115 / Issue-0116 の close

## 既知のブロッカー・懸念

- **反復コストが積み上がった**: 6 巡で約 242 万トークン。反復コストの予算指針の不在は Issue-0103。実質収束は成立せず、最終巡でも骨格指摘 1 件が出たままユーザー判断で確定した
- **確定前レビューの反復で、指摘に応えて書いた説明文が次巡の欠陥を生む閉ループが 2 巡続いた**。設計縮小で断ち切ったが、縮小時に結論を支える論証まで削って再度の復元を要した。詳細は worklog `MakeAiInstructions-2026-09-02-02`
- **完了条件 (b) は一部経路で未達を明示的に受容している**（ADR-0122 決定 1）。update の移設判定込み 54%・移設実行込み 62%。ユーザー承認済み（2026-09-02）
- master の handoff（`docs/working/handoff/master.md`）の申し送りは本ブランチでも全件有効。とくに配布経路・執行点 4 手順・記法規約・退避領域の扱い

## Post ラッパー消化記録

- 2026-09-01 brainstorming 完了・ADR-0122 起票（設計方針 3 決定）: ADR=0122（Proposed・未コミット） / worklog=棄却（delta なし。選択肢比較は既存スキルの手順内）
- 2026-09-02 確定前レビュー第 1〜3 巡と設計縮小の完了（詳細は ADR-0122）: ADR=0122 改訂（Proposed 維持） / worklog=`MakeAiInstructions-2026-09-02-01`
- 2026-09-02 ADR-0122 の設計確定（spec 確定点 (c)）: ADR=0122（Proposed・a6991f9） / worklog=`MakeAiInstructions-2026-09-02-02` / review=フル実施（claude-sonnet-5・3 巡）＋差分再確認（claude-sonnet-5・3 巡・提示後確定（実質収束せず））
- 2026-09-02 セッション終了処理: ADR=なし（新規の意思決定なし。ADR-0122 の Accepted 昇格は実装完了後） / worklog=`MakeAiInstructions-2026-09-02-03`

## 次セッション開始時のアクション

1. **最初に確認**: ADR-0122（コミット済み a6991f9）の決定 6 (a)〜(g)。退避は `~/.ai-dev-review-snapshots/MakeAiInstructions/2026-09-01-adr-0122-spec/`（r1〜r9）
2. **最初に実行**: `start-work`（Phase 0 で本ハンドオフを read）。再開点は `superpowers:writing-plans` による実装計画の作成。出力先は `docs/working/plans/`
3. **留意点**: plan 確定点では `pre-finalization-review` の提示が必要。ADR-0122 の設計骨格は 6 巡・15 体で不動のため、plan 側は写像の欠落検出に重点を置く

## 重要な意思決定の履歴

- ADR-0122: session-handoff と decision-log は発火単位で references へ分割し、SKILL.md 本文を共通部とディスパッチ表に絞る（2026-09-01 起票・2026-09-02 確定してコミット a6991f9。Status は Proposed のまま）
- （ADR-0001〜0121 は `docs/records/decisions/README.md` 参照）
