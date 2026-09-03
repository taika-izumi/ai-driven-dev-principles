# Handoff: session-handoff / decision-log の発火単位分割

- **Branch**: feature/issue-0115-0116-skill-split（master から分岐。マージ未実施）
- **Last Updated**: 2026-09-03 (Asia/Tokyo)
- **Status**: completed
- **Current Phase**: 完了（master へ `--no-ff` で取り込み済み。マージコミット `2295f07`）

## 作業の目的・背景

Issue-0115 / Issue-0116 の対策サイクル。ADR-0121 が導入した SKILL.md のサイズ警告（目安 20KB）に対し、`skills/session-handoff/SKILL.md` が 31,169B、`skills/decision-log/SKILL.md` が 26,837B で超過している。ADR-0121 決定 5 は張り替え規模を理由に両件を次サイクルへ送り、`scripts/build-dist.ps1` の例外テーブルへ暫定登録した。本サイクルはその残余を処理する。

分割方針は ADR-0122（起票済み・Proposed）で確定させる。両スキルとも呼び出し時点で操作・用途が確定しているため、条件発火の単位を「操作・用途」と「横断規範」の 2 系統とし、両方を `references/` へ出して SKILL.md 本文を共通部＋ディスパッチ表に絞る。

## 関連ドキュメント

- 本サイクルの決定: ADR-0122（`docs/records/decisions/0122-split-session-handoff-and-decision-log-by-firing-unit.md`。コミット済み a6991f9。設計文書兼用のため設計 spec は作らない）
- 対象課題: `docs/working/issues/flow/0115-session-handoff-size-split-candidate.md` / `docs/working/issues/flow/0116-decision-log-size-split-candidate.md`
- 上流規範: ADR-0121（サイズ警告と分割判断の型）/ ADR-0116（責務帰属型・references 型の移設の先例）/ `CONTRIBUTING.md`「全シナリオ共通: SKILL.md のサイズと分割」
- 本サイクルの実装計画: `docs/working/plans/2026-09-03-adr-0122-skill-split-implementation.md`（8 タスク・61 Step。決定 6 (f)(g) の全数走査結果・張り替え判定規則 R1〜R7・確定前レビュー 4 巡の記録を同ファイルに保持）
- 前サイクルの実装計画（張り替え取りこぼしのレビュー実測が 1404 行にある）: `docs/working/plans/2026-08-31-adr-0121-skill-size-norm-implementation.md`
- master の申し送り（本ブランチでも有効）: `docs/working/handoff/master.md`

## 完了済みタスク

- [x] brainstorming: 成功基準・①責務帰属型の判定・分割の軸の 3 決定（2026-09-01）
- [x] ADR-0122 ドラフト作成と決定インデックスへの行追加（2026-09-01）
- [x] 確定前レビュー 第 1〜6 巡（フル巡 3・差分確認巡 3・計 15 体・claude-sonnet-5）と設計縮小 1 回（2026-09-01〜09-02）
- [x] ADR-0122 の設計確定とコミット（spec 確定点 (c) 通過。a6991f9・2026-09-02）
- [x] 実装計画の作成（writing-plans。plan 確定点 通過。2026-09-03）
- [x] 実装計画の確定前レビュー 4 巡（フル 3・差分確認 1・claude-opus-5・**実質収束**で確定。2026-09-03）
- [x] 前提の確認 Step 0-1〜0-4（未追跡 5 件・サイズ・節行番号・既定の版・母数 32 の 4 件すべて Expected 一致。2026-09-03）
- [x] 計画 Task 1: decision-log を references 4 ファイルへ分割（09dbbbe。逸脱 1 件の訂正が 52a88a1。2026-09-03）
- [x] 計画 Task 2: session-handoff を references 9 ファイルへ分割・張り替え 29 項目（6bbe1c9。逸脱ゼロ。2026-09-03）
- [x] 計画 Task 3: 外部参照の張り替え 18 箇所と所在注記 5 ブロック（0180dac。旧形式参照の grep が 18→0 件。2026-09-03）
- [x] 計画 Task 4: Accepted 済み ADR 22 件へ部分修正注記（28c51f2。全件 Consequences 内・Status 維持・削除行ゼロ。2026-09-03）
- [x] 計画 Task 5: 例外テーブルの暫定行 2 件削除と spec 02 の件数追従（fdad078。2026-09-03）
- [x] 計画 Task 6: ADR-0122 決定 6 の判明分を全数走査の実測へ更新（c507697。(g) の適用縮小の理由も本文へ記録。2026-09-03）
- [x] 計画 Task 7: version 0.1.18 と執行点 4 手順（6fdc776。両生成器の -Check が exit=0。2026-09-03）
- [x] 計画 Task 8: 昇格ガード評価・Issue close・整合検査・ADR-0122 Accepted 昇格（db565f2。2026-09-03）

## 進行中のタスク

- [ ] **現在の作業**: feature ブランチの完了処理（master への取り込み）
  - 状態: 計画 Task 1〜8 をすべて消化し ADR-0122 は Accepted。Issue-0115 / 0116 は closed。plugin version は 0.1.18。全 8 タスクで逸脱突合: 一致
  - 状態（続き）: 逸脱は 4 件。Task 1・3・4 が型「事実誤り・期待値の陳腐化の訂正」、Task 8 が型「設計の変更」（採用基準は当該サイクル自身が持ち込んだ後退）。いずれも帰結は採用で、計画の各タスク末尾へ記録済み
  - 状態（続き 2）: 完了条件の最終実測。(a) decision-log 4,073B・session-handoff 8,308B（いずれも 20,000B 未満）／(b) 12,823B ≤ 13,400B・12,744B ≤ 15,600B
  - 状態（続き 3）: 確定済み計画の Expected が実体とずれた場合、**計画本文は書き換えず逸脱記録行へ読み替えを書く**方針で統一した（Task 1・3・4 の 3 件で適用）
  - 残り: `superpowers:finishing-a-development-branch`（実行直前に `skills/start-work/references/merge-practice.md` を読む。master handoff の慣行は `--no-ff`）→ マージ後に `retrospective` → cycle-reset → push（配布 0.1.18 の反映）

## 未着手のタスク

- [ ] master へのマージ（`--no-ff`）と `retrospective`・cycle-reset・push

## 既知のブロッカー・懸念

- **反復コストが積み上がった**: spec 確定点 6 巡（約 242 万トークン・実質収束せず）に続き、plan 確定点も 4 巡（約 355 万トークン・実質収束）を要した。**通算巡数の分布外検知は plan 側で発火**（規範改定型の迷い判定→通常型 4 巡の閾値）。予算指針の不在は Issue-0103
- **「前巡の是正に混入した誤り」が毎巡の主要な収穫になる型が、spec 側に続き plan 側でも再発した**（plan 第 2 巡 19 件中 14 件・第 4 巡 12 件全件）。plan 側は設計縮小で断ち切った。詳細は worklog `MakeAiInstructions-2026-09-02-02` と `-2026-09-03-02`
- **完了条件 (b) は一部経路で未達を明示的に受容している**（ADR-0122 決定 1）。**実測見込みは受容値より悪化**（移設判定込み 18,985B＝61%・移設実行込み 21,797B＝70%。受容値は 54%・62%）。**Task 8 Step 8-0 のガード (ii) が発火する前提**で、受容値の更新可否をユーザーへ提示してから昇格する
- master の handoff（`docs/working/handoff/master.md`）の申し送りは本ブランチでも全件有効。とくに配布経路・執行点 4 手順・記法規約・退避領域の扱い。**ただし「この環境に Python は無い（実測: exit 49）」は `python3` についてのみ正しく、`python` は 3.12.1 が動作する**（本サイクルの確定前レビューで実測。master の handoff は次に master で作業するとき訂正する）
- **未追跡 4 件（`docs/conversation_log.md`・`docs/inbox/` 3 件）は本サイクルで触らない**（Issue-0020）。実装計画ファイルは Task 1 のコミット 09dbbbe で追跡下へ入り、この懸念は解消済み

## Post ラッパー消化記録

- 2026-09-01 brainstorming 完了・ADR-0122 起票（設計方針 3 決定）: ADR=0122（Proposed・未コミット） / worklog=棄却（delta なし。選択肢比較は既存スキルの手順内）
- 2026-09-02 確定前レビュー第 1〜3 巡と設計縮小の完了（詳細は ADR-0122）: ADR=0122 改訂（Proposed 維持） / worklog=`MakeAiInstructions-2026-09-02-01`
- 2026-09-02 ADR-0122 の設計確定（spec 確定点 (c)）: ADR=0122（Proposed・a6991f9） / worklog=`MakeAiInstructions-2026-09-02-02` / review=フル実施（claude-sonnet-5・3 巡）＋差分再確認（claude-sonnet-5・3 巡・提示後確定（実質収束せず））
- 2026-09-02 セッション終了処理: ADR=なし（新規の意思決定なし。ADR-0122 の Accepted 昇格は実装完了後） / worklog=`MakeAiInstructions-2026-09-02-03`
- 2026-09-03 実装計画の作成完了（plan 確定点）: ADR=0122（Proposed 本文の書き直しで (g) の適用縮小を記録。実施は Task 6） / worklog=`MakeAiInstructions-2026-09-03-01`・`-02` / review=フル実施（claude-opus-5・3 巡）＋差分再確認（claude-opus-5・1 巡・実質収束）
- 2026-09-03 セッション終了処理: ADR=なし（新規の意思決定なし。ADR-0122 の本文書き直しは Task 6・Accepted 昇格は Task 8） / worklog=棄却（delta なし。Post ラッパーの消し込みと handoff 整理のみで記録ゲート (a)(b) とも不成立）
- 2026-09-03 計画 Task 1 完了（decision-log の references 4 分割・09dbbbe・52a88a1）: ADR=なし（逸脱の裁定は計画 Task 2 Step 2-2 の既存規則の適用であり新規の意思決定なし） / worklog=`MakeAiInstructions-2026-09-03-03`
- 2026-09-03 計画 Task 2 完了（session-handoff の references 9 分割・6bbe1c9）: ADR=なし（無改変移設と列挙どおりの張り替えのみで意思決定なし） / worklog=棄却（delta なし。全 Expected 一致・逸脱ゼロで記録ゲート (a)(b) とも不成立）
- 2026-09-03 計画 Task 3 完了（外部参照の張り替え 18・注記 5・0180dac）: ADR=なし（張り替え判定規則 R2/R3/R6 の適用であり新規の意思決定なし） / worklog=`MakeAiInstructions-2026-09-03-04`
- 2026-09-03 計画 Task 4 完了（ADR 22 件へ部分修正注記・28c51f2）: ADR=なし（R7 の適用であり新規の意思決定なし。既存 ADR は Status 維持で本文不変） / worklog=`MakeAiInstructions-2026-09-03-05`
- 2026-09-03 計画 Task 5 完了（例外テーブル 2 行削除・spec 02 追従・fdad078）: ADR=なし（決定 7 の実施であり新規の意思決定なし） / worklog=棄却（delta なし。全 Expected 一致・逸脱ゼロ）
- 2026-09-03 計画 Task 6 完了（ADR-0122 決定 6 を実測へ更新・c507697）: ADR=0122（Proposed 本文の書き直し。(g) の適用縮小の理由を記録） / worklog=棄却（delta なし）
- 2026-09-03 計画 Task 7 完了（version 0.1.18・執行点 4 手順・6fdc776）: ADR=なし（ADR-0090 の適用） / worklog=棄却（delta なし）
- 2026-09-03 計画 Task 8 完了・**ADR-0122 Accepted 昇格**（Issue-0115/0116 close・db565f2）: ADR=0122（Accepted へ昇格。受容値の実測更新はユーザー承認済み） / worklog=`MakeAiInstructions-2026-09-03-06` / cyclecheck=実施（修正: db565f2）

## 次セッション開始時のアクション

1. **最初に確認**: 実装計画 `docs/working/plans/2026-09-03-adr-0122-skill-split-implementation.md` の「完了後の次手」（3 項目）と、各タスク末尾の `逸脱記録:` 4 行
2. **最初に実行**: `start-work`（Phase 0 で本ハンドオフを read）。再開点は**完了処理**——`superpowers:finishing-a-development-branch` の実行直前に `skills/start-work/references/merge-practice.md` を読む（マージ方式確認の正本。慣行は `--no-ff`）
3. **留意点**: マージ後に `retrospective` → `session-handoff` cycle-reset → push の順。push は配布 0.1.18 の反映を兼ねる。未追跡 4 件（`docs/conversation_log.md`・`docs/inbox/` 3 件）は本サイクルで触っていない

## 重要な意思決定の履歴

- ADR-0122: session-handoff と decision-log は発火単位で references へ分割し、SKILL.md 本文を共通部とディスパッチ表に絞る（2026-09-01 起票・2026-09-02 設計確定 a6991f9・2026-09-03 Accepted 昇格 db565f2）
- （ADR-0001〜0121 は `docs/records/decisions/README.md` 参照）
