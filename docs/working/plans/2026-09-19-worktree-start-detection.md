# worktree 開始時検出 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 作業の開始・再開時に、他の worktree で進行中・中断中の作業（handoff）を見落とさないよう、session-handoff の read 操作に検出の節を足し、start-work Phase 0 に1句を足して配布する。

**Architecture:** 検出は `skills/session-handoff/references/op-read.md` に独立した節「他の worktree の検出」として置き、既存の手順番号は変えない（`op-finalize.md` が「`op-read.md` 手順 4」を参照しているため）。手順 2 の直後に節を呼び、手順 3（ハンドオフなし）と手順 5（要約）に検出結果を添える。start-work Phase 0 には両分岐に共通の1句だけを足す。

**Tech Stack:** Markdown のスキル文書、git（`git worktree list --porcelain` / `git show`）、PowerShell 7 の生成器（`scripts/build-dist.ps1` / `scripts/sync-template.ps1`）。

**Spec:** `docs/records/decisions/0202-handle-worktrees-by-agreement-and-start-time-detection.md`（ADR-0202。設計文書を兼ねる。fd29346 で設計確定）

## Global Constraints

- 配布対象ソース（`skills/` 配下）は CONTRIBUTING.md「全シナリオ共通: 配布対象ソースの記法規約」に従う。出所識別子（ADR 番号等）は全角括弧 `（ADR-0202）` の内側に参照番号だけを書く。実在のプロジェクト名・絶対パスを書式例に使わない。`本リポジトリ` と書かない。
- 置き換え表 `docs/overview/wording-replacements.md` の置き換え前の語（突合・射程・退役・識別子〈出所識別子などを除く〉ほか）を使わない。
- 版の更新（0.1.29 → 0.1.30）は、配布する変更の実装・レビュー・検証が済んでから行う（CONTRIBUTING.md「配布プラグインの版更新」）。`.claude-plugin/plugin.json` と `.claude-plugin/marketplace.json` の値を揃える。
- 配布対象ソースを変えたコミットの前に、`scripts/build-dist.ps1` を実行し、`build-dist.ps1 -Check` と `sync-template.ps1 -Check` の両方を通し、生成物（`dist/`・`.agents/plugins/marketplace.json`）を同じコミットに含める（CONTRIBUTING.md「執行点」）。
- push は外部への書き込みであり、実行ごとに宛先・ブランチ・送信内容を示して利用者の承認を得る。本計画の完了条件に push は含めない。
- 作業は master で直接行う（worktree を作らない）。実行スキル（executing-plans / subagent-driven-development）が `superpowers:using-git-worktrees` を呼び、作成の同意を求めたら「作らない」を選ぶ（ADR-0202 決定1の適用。同スキルは同意が無ければ今の場所で作業する）。
- Git Bash では `git show <ref>:<.で始まるパス>` の引数がパスとして書き換えられて失敗するため、そのコマンドは PowerShell で実行する（2026-09-19 に実測）。

## 逸脱判断の既定

- 既定どおり: `skills/start-work/references/plan-deviation-defaults.md`（plugin 0.1.29）。判断の分担の合意は無く、採否はその都度利用者に確認する。
- 確定前レビューからの引き継ぎ一覧: なし（spec 確定点の指摘は全件、採用・不採用が確定済み。不採用は Minor-3〈本体フォルダ自身の扱い〉と Minor-6 のコマンド例で、実装時レビューへの引き継ぎ対象としない）。
- spec 確定点の確定前レビューは1体4観点兼務だった（フル実施2回・差分再確認1回、claude-opus-5）。
- plan 確定点の確定前レビューも1体4観点兼務だった（フル実施1回、claude-opus-5）。

## ファイル構成

| ファイル | 変更 | 責務 |
|---|---|---|
| `skills/session-handoff/references/op-read.md` | 修正 | 検出の節の追加、手順 2・3・5 への接続 |
| `skills/session-handoff/SKILL.md` | 修正（1語句） | 操作一覧の read 行に「他の worktree の検出」を追加 |
| `skills/start-work/SKILL.md` | 修正（1行） | Phase 0 の両分岐に共通の1句 |
| `dist/`・`.agents/plugins/marketplace.json` | 生成 | build-dist.ps1 の出力 |
| `.claude-plugin/plugin.json`・`.claude-plugin/marketplace.json` | 修正（Task 4） | 版 0.1.30 |
| `docs/records/decisions/0202-*.md`・`docs/records/decisions/README.md` | 修正（Task 5） | Accepted 昇格 |

---

### Task 1: 検出の文面を配布対象ソースへ追記し、生成・検査する

**Files:**
- Modify: `skills/session-handoff/references/op-read.md`（手順 2・3・5 と、手順の後ろに新節）
- Modify: `skills/session-handoff/SKILL.md:117`（操作一覧の read 行）
- Modify: `skills/start-work/SKILL.md:43`（Phase 0 の手順 2 の行）
- Generate: `dist/`、`.agents/plugins/marketplace.json`

**Interfaces:**
- Produces: op-read の節名「他の worktree の検出」（Task 2 の写経がこの節の文面を実行する）。start-work Phase 0 の1句（read が返す「検出結果」を受ける）。

- [ ] **Step 1: 追記前の状態を記録する**

Run: `git diff --quiet HEAD -- skills/ && echo clean; grep -c 'worktree' skills/session-handoff/references/op-read.md skills/start-work/SKILL.md skills/session-handoff/SKILL.md`
Expected: `clean` と、3ファイルとも `0`

- [ ] **Step 2: op-read.md の手順 2 に節の呼び出しを足す**

置き換え前:
```
2. ブランチ名のスラッシュを `_` に置換し、ファイルパス `docs/working/handoff/<branch>.md` を組み立てる
```
置き換え後:
```
2. ブランチ名のスラッシュを `_` に置換し、ファイルパス `docs/working/handoff/<branch>.md` を組み立てる。続けて下記「他の worktree の検出」を行う（手順 3 でファイルが無い場合も検出結果を返すため、手順 3 より前に行う）
```

- [ ] **Step 3: op-read.md の手順 3 に検出結果の返却を足す**

置き換え前:
```
3. ファイルが存在しなければ「ハンドオフなし」と呼び出し側に返す
```
置き換え後:
```
3. ファイルが存在しなければ「ハンドオフなし」と呼び出し側に返す。「他の worktree の検出」の結果があれば添える
```

- [ ] **Step 4: op-read.md の手順 5 の要約に検出結果を添える文を足す**

置き換え前:
```
   - 次セッション開始時のアクション
```
置き換え後（箇条ではなく、箇条の後ろに字下げした1文を置く。handoff の欄と読まれないようにするため）:
```
   - 次セッション開始時のアクション

   要約には「他の worktree の検出」の結果（あれば）も添える
```

- [ ] **Step 5: op-read.md の末尾（手順 7 の後）に節を追加する**

ファイル末尾へ次を追記する（手順 7 の行との間に空行を1行）:
```
## 他の worktree の検出

`git worktree list --porcelain` を1回実行し、worktree が1つだけならこの節を終える。2つ以上なら、今の worktree 以外の各 worktree について次を行う。以下は1回のシェルコマンドにまとめてよい（ADR-0202）。

1. その worktree のブランチ名から `refs/heads/` を除き、手順 2 と同じ規則（スラッシュを `_` に置換する）で handoff のパスを組み立てる。読むのはその worktree のフォルダにある handoff（`<worktreeのパス>/docs/working/handoff/<ブランチ>.md`）で、今のフォルダにある同名の写しではない。冒頭の `Last Updated` と `Status` の欄だけを読み、本文は読まない
2. プロジェクトの外にある worktree の handoff を読めない場合（読み取りの拒否・エラー）は、`git show <ブランチ>:<handoffのパス>` でコミット済みの版を読み、未コミットの更新は見えないことを添える。直接読める場合は、未コミットの最新状態を含むファイルを優先する
3. `Status` が `in_progress` または `paused` のものを候補とする。候補についてだけ、既定ブランチにある同名の handoff の冒頭を `git show <既定ブランチ>:<handoffのパス>` で読み、その `Status` が `completed` で、`Last Updated` が worktree 側と同じか新しければ、取り込み済みとして除外する。取り込みの判定に `git merge-base --is-ancestor` は使わない（コミットの無い新しいブランチも取り込み済みと判定するため）
   - 既定ブランチは、`origin/HEAD` が指すブランチの手元の名前（`origin/` を除いた名前）とする。設定が無ければ `git worktree list` の先頭（本体の作業フォルダ）のブランチとし、推定である旨を添える
4. 残った候補を更新日時の新しい順に挙げ、再開先の選択肢に加える。今のブランチの handoff との新旧では絞り込まない（今のブランチを後から更新すると、中断中の worktree が古く見えて漏れるため）
5. handoff を特定できない worktree（ブランチを持たないもの、handoff が無いもの）は、パスとブランチの有無を1行で挙げる
6. 別の worktree が再開先に選ばれたら、今のセッションでは続けず、その worktree のフォルダでセッションを開き直して start-work を行うよう利用者に促す（今のセッションから別の worktree へ書き込む混入を避けるため）
```

- [ ] **Step 6: session-handoff/SKILL.md の操作一覧の read 行を更新する**

置き換え前:
```
| read | `references/op-read.md` | ファイル特定・サイズ実測・要約提示・確認の記録の欠落検査・継続確認 |
```
置き換え後:
```
| read | `references/op-read.md` | ファイル特定・他の worktree の検出・サイズ実測・要約提示・確認の記録の欠落検査・継続確認 |
```

- [ ] **Step 7: start-work/SKILL.md の Phase 0 に1句を足す**

置き換え前:
```
2. 結果に応じて分岐:
```
置き換え後（分岐より先に読ませるため、分岐の前に置く）:
```
2. read が他の worktree の検出結果を返したら、ハンドオフの有無にかかわらず再開先の選択肢として提示し、別の worktree へ移ると決まったら開き直しを促して終え、Phase 1 へ進まない（ADR-0202）。それ以外は結果に応じて分岐:
```

- [ ] **Step 8: 追記を実体で確かめる**

Run: `grep -c '他の worktree の検出' skills/session-handoff/references/op-read.md skills/session-handoff/SKILL.md; grep -c 'Phase 1 へ進まない（ADR-0202）。それ以外は結果に応じて分岐:' skills/start-work/SKILL.md; grep -cE '突合|射程|退役|本リポジトリ' skills/session-handoff/references/op-read.md`
Expected: op-read.md は `4`（手順 2・3、手順 5 の後ろの1文、節見出し）、session-handoff/SKILL.md は `1`、start-work/SKILL.md は `1`、最後は `0`

- [ ] **Step 9: 生成器と両 Check を実行する**

Run: `pwsh -NoProfile -File scripts/build-dist.ps1 && pwsh -NoProfile -File scripts/build-dist.ps1 -Check && pwsh -NoProfile -File scripts/sync-template.ps1 -Check && echo ALL-OK`
Expected: 末尾に `ALL-OK`（3つとも終了コード 0。途中で止まれば非ゼロの箇所を報告する）

- [ ] **Step 10: 配布物を通読で確かめる**

Run: `grep -n 'worktree' dist/skills/session-handoff/references/op-read.md dist/skills/start-work/SKILL.md dist/skills/session-handoff/SKILL.md | head -20; grep -c 'ADR-0202' dist/skills/session-handoff/references/op-read.md dist/skills/start-work/SKILL.md`
Expected: 追記した文が配布物にあり、`ADR-0202` は `0` 件（生成器が除去）。除去後に空の括弧・`（の…）` のような残骸が無いことを、該当行を読んで確かめる（CONTRIBUTING.md「機械判定が届かない領域」の5項目）

- [ ] **Step 11: コミットする**

```bash
git add skills/session-handoff/references/op-read.md skills/session-handoff/SKILL.md skills/start-work/SKILL.md dist/ .agents/plugins/marketplace.json
git commit -m "feat(skills): 開始時に他のworktreeの進行中handoffを検出する（ADR-0202）"
```

### Task 2: 検出の文面を写経し、場面ごとに動作を確かめる

**Files:**
- Create（使い捨て。リポジトリに入れない）: セッションの scratchpad 配下 `worktree-detect/`（試験用の git リポジトリと写経スクリプト）

**Interfaces:**
- Consumes: Task 1 で追記した op-read.md「他の worktree の検出」の文面（写経元。文面に書かれていない処理を足さない）

- [ ] **Step 1: 写経スクリプトを書く**

scratchpad に `worktree-detect/detect.sh` を作り、op-read.md の節の前置きと 1〜5 項目を文面どおりに実装する（入力: 実行するフォルダ。出力: 候補・除外・特定不可・既定ブランチの推定の各行）。文面から実装を決められない箇所があれば、それ自体を Task 1 への指摘として記録する。

- [ ] **Step 2: 場面を持つ試験用リポジトリを作る**

scratchpad の `worktree-detect/repo` に試験用リポジトリを作り（`origin/HEAD` は設定しない）、既定ブランチ `main` の handoff（`main.md`、Status は `in_progress`）と、次の worktree を用意する:

| 場面 | 状態 | 期待される扱い |
|---|---|---|
| A | 取り込み済み。worktree 側は `in_progress`、既定ブランチ側の写しは `completed` で、`Last Updated` は worktree 側と同時刻（「同じか新しい」の境界） | 除外 |
| B | 未取り込みで `in_progress` | 候補 |
| C | 取り込み後に同じブランチで再開し、worktree 側の `Last Updated` が写しより新しい `in_progress` | 候補 |
| D | `paused`、既定ブランチ側に写しが無い | 候補 |
| E | detached HEAD の worktree | 特定不可の1行 |
| F | handoff の無いブランチの worktree | 特定不可の1行 |
| G | `ready-for-next-cycle` | 対象外（挙げない） |

- [ ] **Step 3: 本体フォルダから写経スクリプトを実行する**

Expected: 候補は B・C・D（更新日時の新しい順）、除外は A、特定不可は E・F、G は出ない。既定ブランチが推定である旨（`origin/HEAD` 無し）が出る。

- [ ] **Step 4: handoff の無い worktree（場面 F）から実行する**

目的: 今の worktree の handoff の有無に関係なく検出が働くこと（op-read の手順 2・3 の順序は写経スクリプトでは確かめられないため、Task 3 の照合で確かめる）。
Expected: 候補は B・C・D と本体フォルダの `main`（`in_progress`）、除外は A、特定不可は E（F は今の worktree なので挙げない）、G は出ない。

- [ ] **Step 5: worktree が1つだけのリポジトリで実行する**

Expected: `git worktree list --porcelain` の1回だけで、候補・特定不可の出力が無い。

- [ ] **Step 6: このリポジトリの実環境で実行する（読み取りのみ）**

Run: 写経スクリプトを本リポジトリの本体フォルダで実行する
Expected: 取り込み済みの5件がすべて除外され、候補は0件。プロジェクト外の worktree（Codex 側）は直接読むか、読めなければ `git show` の経路で読まれる。既定ブランチは推定（`origin/HEAD` 無し）として `master` になる。

- [ ] **Step 7: 結果を記録する**

期待と異なった場面があれば、原因が文面か写経かを切り分け、文面の欠陥なら Task 1 へ戻って直す（逸脱判断の既定に従い、計画のこのタスク末尾へ逸脱記録行を残す）。すべて期待どおりなら、各場面の結果を1行ずつこの計画の本 Step の下へ記録する。試験用リポジトリは scratchpad に残し、リポジトリへはコミットしない。

### Task 3: 設計と文面を照合する（サイクル全体整合検査）

**Files:**
- 読み直す: `docs/records/decisions/0202-handle-worktrees-by-agreement-and-start-time-detection.md`、Task 1 で変更した3ファイル

- [ ] **Step 1: サイクル全体整合検査を行う**

decision-log の `references/cycle-consistency-check.md` の固定5観点で、ADR-0202 と Task 1 の文面（op-read.md・start-work/SKILL.md・session-handoff/SKILL.md）を読み直して照合する。とくに ADR の Decision 3 の各項目が op-read.md の節の前置きと 1〜6 項目に一致するか、Phase 0 の1句が ADR の文言と一致するか（Task 1 で分岐の前へ移した位置を含む）、op-read の手順 2→節→手順 3 の順序で「ハンドオフなし」の場合も検出が返るか。

- [ ] **Step 2: 食い違いを直す**

文面（skills 側）を直した場合は、Task 1 Step 8〜11 を再実行する（版はまだ 0.1.29 のまま）。ADR 側を直す場合は、決定内容を変えない改訂に限り、Proposed のまま書き直してコミットする。食い違いが無ければ「照合: 食い違いなし」とこの Step の下に記録する。

### Task 4: 版を 0.1.30 に上げて生成・検査する

**Files:**
- Modify: `.claude-plugin/plugin.json`（`"version": "0.1.29"` → `"0.1.30"`）
- Modify: `.claude-plugin/marketplace.json`（同じ値）
- Generate: `dist/`、`.agents/plugins/marketplace.json`

**Interfaces:**
- Consumes: Task 1〜3 が完了し、配布する変更の実装・整合検査・検証が済んでいること（配布本文の確認は Task 1 Step 10 で済んでおり、本タスクは版の値だけを変える）

- [ ] **Step 1: 直前の公開版を確かめる**

Run（PowerShell）: `git show 'origin/master:.claude-plugin/plugin.json' | Select-String '"version"'`
Expected: `"version": "0.1.29"`（予定版 0.1.30 がこれより進んでいる。2026-09-19 時点の値）

- [ ] **Step 2: 2つの版を更新する**

`.claude-plugin/plugin.json` と `.claude-plugin/marketplace.json` の `0.1.29` を `0.1.30` にする。

Run: `grep -c '"0.1.30"' .claude-plugin/plugin.json .claude-plugin/marketplace.json; grep -c '"0.1.29"' .claude-plugin/plugin.json .claude-plugin/marketplace.json`
Expected: 前者はそれぞれ `1` 以上、後者はそれぞれ `0`

- [ ] **Step 3: 生成器と両 Check を実行する**

Run: `pwsh -NoProfile -File scripts/build-dist.ps1 && pwsh -NoProfile -File scripts/build-dist.ps1 -Check && pwsh -NoProfile -File scripts/sync-template.ps1 -Check && echo ALL-OK`
Expected: 末尾に `ALL-OK`

- [ ] **Step 4: コミットする**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json dist/ .agents/plugins/marketplace.json
git commit -m "chore: 配布プラグインを0.1.30へ更新する（ADR-0202）"
```

### Task 5: ADR-0202 を Accepted に昇格する

**Files:**
- Modify: `docs/records/decisions/0202-handle-worktrees-by-agreement-and-start-time-detection.md`（Status）
- Modify: `docs/records/decisions/README.md`（0202 の行）

- [ ] **Step 1: 整合検査の結果を確かめる**

Task 3 の整合検査が済み、以後に仕様・規範文書の差分が無いことを確かめる（`git diff --stat <起点>..HEAD -- skills/ docs/current/`。起点は Task 3 完了時点の HEAD とし、Task 3 でコミットが無ければ Task 1 Step 11 のコミットとする。版の値の変更だけなら差分なしとみなす）。

- [ ] **Step 2: 粒度を点検する**

ADR-0202 のタイトルが本文の決定1〜3に答えているかを確かめる。

- [ ] **Step 3: Status とインデックスを更新してコミットする**

Run: `grep -c 'Status\*\*: Accepted' docs/records/decisions/0202-*.md; grep -c '| \[0202\].*| Accepted |' docs/records/decisions/README.md`
Expected: 更新後にどちらも `1`

```bash
git add docs/records/decisions/0202-handle-worktrees-by-agreement-and-start-time-detection.md docs/records/decisions/README.md
git commit -m "docs: ADR-0202をAcceptedへ昇格する"
```

### Task 6: 応急処置のメモリの扱いを利用者と決める

**Files:**
- 対象（リポジトリ外）: Claude Code のメモリ `check-worktree-handoffs-at-start`（MEMORY.md の索引行を含む）

- [ ] **Step 1: 扱いを利用者に確認する**

選択肢を示して決める: (1) 0.1.30 を導入して検出が働くのを確かめた後に削除する、(2) 今すぐ削除する、(3) 残す。導入（`/plugin marketplace update` など）は利用者の操作であり、push による公開が前提になる。

- [ ] **Step 2: 決めた扱いを実行し、handoff に記録する**

---

## 完了条件

- Task 1〜5 のコミットが master にあり、`build-dist.ps1 -Check`・`sync-template.ps1 -Check` が通る
- Task 2 の7場面と実環境の結果が期待どおりで、本計画に記録されている
- ADR-0202 が Accepted
- Task 6 の扱いが決まり、handoff に記録されている
- push（公開）は完了条件に含めない。別途、利用者の承認を得て行う
