# ADR-0106 マージコミット規範の 2 層配線 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ADR-0106 の決定（予防配線・検出配線・本リポジトリ git 設定・ff やり直し手順）を配布スキル 2 件＋現行仕様書＋関連記録へ実装する。

**Architecture:** 設計の正本は `docs/records/decisions/0106-two-layer-wiring-for-merge-mode-norm.md`（以下「ADR-0106」）。本 plan の編集文はすべて同 ADR の Decision から写像している。編集対象は配布対象ソース（`skills/` 配下）を含むため、コミットは「skills＋dist＋version を同一コミット」（執行点 4 手順）の制約に従う。タスク間で編集→検証→コミットの順序を分離してある。

**Tech Stack:** Markdown（スキル・仕様書）/ git config / PowerShell（`scripts/build-dist.ps1`・`scripts/sync-template.ps1 -Check`）/ 一時 git リポジトリでのスモーク検証。

**遂行上の注意（全タスク共通）:**
- 編集は Edit ツールで行い、old_string は本 plan 記載のものを使う前に**必ず実ファイルで一致を確認**する（指示と実態が食い違ったら実態を優先し報告する）
- `skills/` 配下の新規文言には出所識別子（ADR-NNNN / Issue-NNNN 等）を裸で書かない。本 plan の文言はこの規約に適合済みなので**一字一句そのまま**使う
- Task 1〜3 の編集後、Task 7〜9 の完了まで**コミットしない**（dist と同一コミットにするため）

---

### Task 1: `skills/start-work/SKILL.md` の予防配線

**Files:**
- Modify: `skills/start-work/SKILL.md`

- [ ] **Step 1-1: Phase -1 依存検出リストへ完了処理スキルを追加**

old_string:
```
2. 主要スキル（brainstorming, writing-plans, executing-plans, subagent-driven-development, systematic-debugging, requesting-code-review, receiving-code-review, verification-before-completion）の利用可否を内部マッピング表に記録する
```
new_string:
```
2. 主要スキル（brainstorming, writing-plans, executing-plans, subagent-driven-development, systematic-debugging, requesting-code-review, receiving-code-review, verification-before-completion, finishing-a-development-branch）の利用可否を内部マッピング表に記録する
```

- [ ] **Step 1-2: Phase 2 マッピング表へ完了処理の行を追加**

old_string:
```
| 完了前検証 | superpowers:verification-before-completion | インラインチェックリスト確認 |
```
new_string:
```
| 完了前検証 | superpowers:verification-before-completion | インラインチェックリスト確認 |
| feature ブランチの完了処理（既定ブランチへの取り込み） | superpowers:finishing-a-development-branch（実行直前に下記「完了処理のマージ方式確認」を適用） | インラインで慣行確認＋マージ手順を案内 |
```

- [ ] **Step 1-3: 独立小節「完了処理のマージ方式確認」を新設**

「### 確定前レビューの提示規則（ADR-0080）」の見出しの**直前**に以下の節全体を挿入する（old_string は `### 確定前レビューの提示規則（ADR-0080）` の行、new_string はその行の前に下記を置いた形）:

```
### 完了処理のマージ方式確認

feature ブランチを既定ブランチへ取り込む完了処理の実行直前に、以下の慣行判定を行い、判定結果に応じてマージ方式を確認する。**本節が慣行判定の正本である**（他スキルからは節の主題によるポインタで参照される。条件文の複写はしない）。

**既定ブランチの解決**: まず `git config --get ai-dev.defaultbranch` を読み、値があり当該ブランチが実在すればそれを採用する。未設定なら `git symbolic-ref refs/remotes/origin/HEAD` で解決し、不能なら `git rev-parse --verify` で `master` / `main` の実在を確認する（一意に定まる場合のみ採用）。それでも不定ならユーザーへ確認する。結果は `git config ai-dev.defaultbranch` へ永続化し、以後の照会を省く。永続化値のブランチが実在しなくなっていたら値を破棄して再解決する。`ai-dev.` で始まる設定キーの書き込みは可逆かつ git の挙動に影響しないため低リスク（ログのみ）として扱う。

**慣行判定（3 値: 慣行あり / マージコミットを残さない運用 / 未定義）**:

1. 設定を見る。第一に `git config --get ai-dev.mergepractice`: 値が `merge-commit` なら**慣行あり**、`none` なら**残さない運用**、これら以外の値は解釈せずユーザーへ照会する。未設定なら `git config --get-all branch.<既定ブランチ>.mergeoptions` と `git config --get merge.ff` を見る: `--no-ff` / `false` を含めば**慣行あり**、`--ff-only` / `only` なら**残さない運用**、これら以外の値が設定されていれば解釈せずユーザーへ照会する
2. 手順 1 がすべて未設定なら、per-cycle 振り返り記録（`docs/records/retrospectives/system/` 直下の `YYYY-MM-DD-*.md` に一致するファイルのみ。ファイル名降順で直近 5 件。5 件未満なら存在する全件）の Branch 行を読む。**まず除外行を落とし、残った有効行で判定する。** 除外行 = 「fast-forward」の記載を含む行・Branch 行の欠落・未知の方式値・選択肢が未削除の行・方式欄も merge SHA も持たない行。有効行の判定: 取り込み方式欄に「マージコミット」の行が 1 件でもあれば**慣行あり**。「squash」等マージコミットを残さない方式の行のみなら**残さない運用**。方式欄が無く merge SHA の記載のみの旧様式の行は、有効行がすべて旧様式の場合に限りマージコミット方式とみなす（新旧混在時は新様式の行のみで判定する）。有効行が 0 件なら**未定義**
3. **未定義**の場合はユーザーへ 1 問で確認し、回答を肯定なら `merge-commit`、否定なら `none` として直ちに `git config ai-dev.mergepractice` へ書いて永続化する（照会は同一サイクルで決定経路を通じて 1 回。振り返り記録の方式欄への反映は当該サイクルの記録作成時に行う）

**判定結果の適用**: **慣行あり**なら `--no-ff` を適用する。**未定義**ならマージコミットを残す方式（`--no-ff`）を推奨する（常時 `--no-ff` の無条件規範ではない）。**残さない運用**なら方式確認を行わず完了フローの既定に委ねる。慣行あり・または未定義でユーザーが `--no-ff` を選択したとき、branch 設定が未検出なら `git config branch.<既定ブランチ>.mergeoptions "--no-ff"` と `git config pull.ff true` の適用を当該サイクルから提案する（後者は、完了フローの手順が pull を含み、mergeoptions 単独では pull が余分なマージコミットを作ってサイクル境界の可読性を損なうための併設）。実行そのものの承認取得は横断的ラッパー Pre の pre-action-review 条項が担い、本節は方式の確認のみを担う（役割が異なり重複しない）。同一セッション内の同一完了処理につき確認は 1 回とする（マッピング表経由で確認済みなら Pre 条項経由の再確認は省略する）。

### 確定前レビューの提示規則（ADR-0080）
```

- [ ] **Step 1-4: 横断的ラッパー Pre へ配線条項を追加**

old_string:
```
**Pre（実行前）:**
- 不可逆操作・大規模変更の可能性があれば `pre-action-review` スキルを呼ぶ
- サブエージェントへ作業を委譲する場合は `subagent-dispatch` スキルを呼び、委譲プロンプトの制約ブロック（A 群＋B 群判定行）を組み立てる（ADR-0066 / ADR-0071）
```
new_string:
```
**Pre（実行前）:**
- 不可逆操作・大規模変更の可能性があれば `pre-action-review` スキルを呼ぶ
- サブエージェントへ作業を委譲する場合は `subagent-dispatch` スキルを呼び、委譲プロンプトの制約ブロック（A 群＋B 群判定行）を組み立てる（ADR-0066 / ADR-0071）
- 完了処理〈既定ブランチへの取り込み〉を行うスキル・手順の実行直前は、Phase 2 の「完了処理のマージ方式確認」を適用する。本条項は冒頭の適用範囲文（「delegate する前後」）の例外として、delegate 済みスキルが内部で呼ぶ必須サブスキルの実行直前にも適用される（Post ラッパーの発火粒度は現行のまま変わらない）
```

- [ ] **Step 1-5: セッション終了処理へ役割差の注記**

old_string:
```
1. 直近のサブプロジェクトが master へ merge 済みかを確認する
```
new_string:
```
1. 直近のサブプロジェクトが master へ merge 済みかを確認する（これは事後確認であり、マージ実行前の方式確認は Phase 2 の「完了処理のマージ方式確認」が担う）
```

- [ ] **Step 1-6: 検証**

Run: `grep -c "完了処理のマージ方式確認" skills/start-work/SKILL.md`
Expected: `4`（節見出し 1＋Phase 2 表内 1＋Pre 条項 1＋セッション終了処理 1。4 未満なら挿入漏れ、5 以上なら重複挿入を疑う）
Run: `grep -n "finishing-a-development-branch" skills/start-work/SKILL.md`
Expected: Phase -1 の行と Phase 2 表の行の 2 箇所

### Task 2: `skills/retrospective/SKILL.md` の検出配線

**Files:**
- Modify: `skills/retrospective/SKILL.md`

- [ ] **Step 2-1: 「いつ使うか」前提文をゲート付き表現へ**

old_string:
```
サブプロジェクトの feature ブランチを master へ `--no-ff` マージし、対応 handoff を completed 状態へ遷移させる**直前**。
```
new_string:
```
サブプロジェクトの feature ブランチを master へ取り込み（マージコミットを残す運用の場合はマージコミットを残す方式で取り込み）、対応 handoff を completed 状態へ遷移させる**直前**。
```

- [ ] **Step 2-2: 「スキル内ではコミットしない」前提へ明示例外を追記**

old_string:
```
- スキル内ではコミットしない。コミットはユーザーまたは通常フローに委ねる
```
new_string:
```
- スキル内ではコミットしない。コミットはユーザーまたは通常フローに委ねる。例外: Phase 0 の fast-forward 検出時のやり直し（当該サイクルの完了処理の訂正）に限り、ユーザー承認のうえ再マージのコミットを作成してよい
```

- [ ] **Step 2-3: Phase 0 の収集対象追加と検証工程の挿入**

old_string:
```
   - 該当期間に追加・変更された ADR
3. 既存 `docs/records/retrospectives/` に同一トピックの既存ファイルが無いことを確認する。あれば中止し、扱いをユーザーに確認する
```
new_string:
```
   - 該当期間に追加・変更された ADR
   - 直近の per-cycle 振り返り記録（`system/` 直下。取り込み方式の慣行判定の入力）
3. **取り込み方式の検証（fast-forward 検出）**: マージ方式の慣行判定を行う（判定手続きの正本は `start-work` の「完了処理のマージ方式確認」節。条件文はここに複写しない）。**慣行あり**の場合のみ以下を実施する。**未定義**なら判定を出さず慣行を 1 問確認するに留める（回答が「マージコミットを残す」なら当該サイクルから実施し、branch 設定が未検出なら設定適用を提案する）。**残さない運用**なら実施しない
   - 判定: 対象 feature ブランチの先端 SHA が、まず `git merge-base --is-ancestor` で既定ブランチの祖先であることを確認する（祖先でなければ未マージまたは squash であり、fast-forward とは判定せず報告のみ）。祖先である場合、`git rev-list --parents <既定ブランチ>` を走査し、いずれかのマージコミットの第 2 親以降に現れなければ fast-forward と判定する。対象ブランチ名はユーザー入力を第一とする（fast-forward 時は merge コミットからの推定が機能しない）
   - 先端 SHA の取得: ブランチが現存すれば `git rev-parse <ブランチ名>`。削除済みなら `git reflog show <既定ブランチ>` を新しい順に走査し、**ブランチ名で限定された 2 パターンのみ**を判定材料にする——`merge <ブランチ名>: … Fast-forward` の行はその SHA が先端（fast-forward 確定）、`merge <ブランチ名>: Merge made by` の行は fast-forward でないことが確定するため検証を終了する（この行の SHA はマージコミットであり先端ではない）。`pull` で始まる行（引数を含む形も）と `commit (merge):` の行は判定材料にしない。該当行が無ければ判定不能として報告する（`HEAD` や既定ブランチ先端で代用しない）。fast-forward 検出時の手順 2 の git log 範囲は分岐点 SHA から先端までを用いる
   - fast-forward 検出時のやり直し提案: 次の 5 条件をすべて満たす場合に限り提案する——未 push / 既定ブランチへの追加コミットなし / feature 先端が参照可能 / 分岐点が既定ブランチの reflog から SHA として確定できる（当該 fast-forward エントリの直前のエントリの SHA を分岐点とする）/ 作業ツリーの追跡ファイルに未コミット変更が無いか、対象パス限定の `git stash push` で退避した（既定ブランチへの先行コミットは用いない）。手順: 分岐点 SHA を先に確定・提示し、以後は確定 SHA のみを使う（相対参照は再実行で元へ戻るため。`git merge-base` は fast-forward 後に先端を返すため用いない）。リスク段階の判定によらず本手順は承認必須とし、承認後に (1) `git branch <一時名> <先端 SHA>` で一時 ref を張る（名前は日付と先端短縮 SHA を含め、衝突時は既存を消さず別名を採る）、(2) 退避を実施し `git status --porcelain --untracked-files=no` の出力が空であることを確認する（空でなければ中止）、(3) `git reset --hard <分岐点 SHA>`、(4) `git merge --no-ff <一時 ref 名>`（コミットメッセージはプロジェクトの慣行に従う）、(5) 退避の復元と一時 ref の削除。以上を **Phase 0 の検証直後・Phase 1 の前に完了させる**（記録が先に既定ブランチへ載るとやり直し条件を自ら失効させ、Branch 行に書く SHA も確定しないため）
   - 5 条件を満たさない場合はやり直しを提案せず、記録の Branch 行へ取り込み方式 fast-forward（先端 SHA）を明記する扱いをユーザーへ提示するに留める
4. 既存 `docs/records/retrospectives/` に同一トピックの既存ファイルが無いことを確認する。あれば中止し、扱いをユーザーに確認する
```

- [ ] **Step 2-4: Phase 2 手順 4 へインデックス列書式の 1 句**

old_string:
```
4. **`docs/records/retrospectives/README.md` の一覧へ行追加する（省略不可）**
```
new_string:
```
4. **`docs/records/retrospectives/README.md` の一覧へ行追加する（省略不可）**。Branch 列は per-cycle 記録の Branch 行と同形（取り込み方式の明記を含む）で書く
```

- [ ] **Step 2-5: 関連節へ出所行を追加**

old_string:
```
- ADR-0010: 振り返りフェーズ導入
```
new_string:
```
- ADR-0010: 振り返りフェーズ導入
- ADR-0106: 取り込み方式の慣行判定・fast-forward 検出とやり直し・完了フローへの 2 層配線
```

- [ ] **Step 2-6: 検証**

Run: `grep -n "取り込み方式の検証" skills/retrospective/SKILL.md && grep -c "merge-base --is-ancestor" skills/retrospective/SKILL.md`
Expected: Phase 0 に見出しが 1 箇所、`--is-ancestor` が 1 箇所
Run: `grep -n -- "--no-ff" skills/retrospective/SKILL.md`
Expected: やり直し手順 (4) の 1 箇所のみ（「いつ使うか」から消えていること）

### Task 3: `skills/retrospective/template.md` の方式欄改定

**Files:**
- Modify: `skills/retrospective/template.md`

- [ ] **Step 3-1: Branch 欄を取り込み方式欄へ**

old_string:
```
- **Branch**: feature/<name>（merge済み: <merge-commit-sha>）
```
new_string:
```
- **Branch**: feature/<name>（取り込み方式: マージコミット <merge-commit-sha>）
  <!-- 取り込み方式は「マージコミット / squash / fast-forward」から該当する 1 つだけを書く（選択肢の列挙を残さない）。fast-forward の場合は「fast-forward〈先端 <sha>〉」と書く -->
```

- [ ] **Step 3-2: 検証**

Run: `grep -n "取り込み方式" skills/retrospective/template.md`
Expected: 2 行（欄と記入指示）。`grep -c "merge済み" skills/retrospective/template.md` → `0`

### Task 4: 現行仕様書 `docs/current/specs/2026-05-01-retrospective-design.md` の同期

**Files:**
- Modify: `docs/current/specs/2026-05-01-retrospective-design.md`

ADR-0106 の同期指定は 4 箇所（Phase 0 節・記録様式 Branch 欄・Phase 2 の行追加手順・末尾のコミット非実施行）。スナップショットとして SKILL.md の新内容を要約形で反映する。

- [ ] **Step 4-1: Phase 0 節へ収集対象と検証工程を追記**

old_string:
```
2. 対応 plan / spec / merge コミット範囲の git log / handoff 現行版 / 期間中に追加・変更された ADR を読み込む
3. `docs/records/retrospectives/` に同一トピックの既存ファイルが無いことを確認する
```
new_string:
```
2. 対応 plan / spec / merge コミット範囲の git log / handoff 現行版 / 期間中に追加・変更された ADR / 直近の per-cycle 振り返り記録（慣行判定の入力）を読み込む
3. 取り込み方式の検証（fast-forward 検出。ADR-0106）: 慣行判定（正本は start-work「完了処理のマージ方式確認」）で慣行ありの場合のみ、feature 先端の祖先判定＋親走査で fast-forward を検出する。検出時、5 条件（未 push / 追加コミットなし / 先端参照可 / 分岐点確定可 / 作業ツリー退避済み）を満たす場合に限り、承認必須でやり直し（一時 ref → 退避確認 → reset → `--no-ff` 再マージ → 復元）を Phase 1 の前に完了させる。満たさない場合は Branch 行へ fast-forward を明記する代替記録を提示するに留める
4. `docs/records/retrospectives/` に同一トピックの既存ファイルが無いことを確認する
```

- [ ] **Step 4-2: Phase 2 手順 4 へ書式句**

old_string:
```
4. **`docs/records/retrospectives/README.md` の一覧へ行追加する（省略不可）**
```
new_string:
```
4. **`docs/records/retrospectives/README.md` の一覧へ行追加する（省略不可）**。Branch 列は per-cycle 記録の Branch 行と同形（取り込み方式の明記を含む）で書く
```

- [ ] **Step 4-3: コミット非実施行へ例外句**

old_string:
```
コミットはスキル内では行わない（ユーザーまたは通常フローに委ねる）。
```
new_string:
```
コミットはスキル内では行わない（ユーザーまたは通常フローに委ねる）。例外: Phase 0 の fast-forward 検出時のやり直し（完了処理の訂正）に限り、ユーザー承認のうえ再マージのコミットを作成してよい（ADR-0106）。
```

- [ ] **Step 4-4: §4.1 の Branch 様式行を更新**

old_string:
```
- **Branch**: feature/<name>（merge済み: <sha>）
```
new_string:
```
- **Branch**: feature/<name>（取り込み方式: マージコミット <sha>）
```

- [ ] **Step 4-5: 検証と commit**

Run: `grep -c "取り込み方式" docs/current/specs/2026-05-01-retrospective-design.md`
Expected: `3` 以上（Phase 0・Phase 2・§4.1）

```bash
git add docs/current/specs/2026-05-01-retrospective-design.md
git commit -m "docs: retrospective 現行仕様書へ ADR-0106 の検証工程・方式欄を同期" -- docs/current/specs/2026-05-01-retrospective-design.md
```

### Task 5: 関連記録の更新（ADR-0056 注記・Issue-0084 補正・課題起票）

**Files:**
- Modify: `docs/records/decisions/0056-retrospective-issue-extraction-core-worklog-delegation.md`
- Modify: `docs/working/issues/flow/0084-merge-mode-norm-not-wired-into-finishing-flow.md`
- Create: `docs/working/issues/flow/0101-start-work-spec-figure-drift.md`
- Modify: `docs/working/issues/README.md`

- [ ] **Step 5-1: ADR-0056 へ部分修正注記**

ADR-0056 の Consequences 末尾（既存の部分修正注記の並びがあればその末尾）へ追加:
```
- **部分修正（ADR-0106）**: メイン記録テンプレートの Branch 欄は「merge済み: <sha>」から取り込み方式の明示欄（マージコミット / squash / fast-forward）へ改定された。最小サイクル文脈の骨格は現役のため、Status は Accepted のまま維持する
```

- [ ] **Step 5-2: Issue-0084 検討状況へ faa9187 の記載漏れ補正**

検討状況の末尾（2026-08-17 の再発行の後）へ追加:
```
- 2026-08-17: 検討状況の記載漏れ補正 — 2026-08-15 の Issue-0076 対応サイクルでも手動適用していた（`faa9187`）。当時の行が漏れていたため本行で補う（連番表現「4 サイクル連続」等は当時から faa9187 を数えており計数は正）
```

- [ ] **Step 5-3: start-work 旧仕様書乖離の flow 課題を起票**

Create `docs/working/issues/flow/0101-start-work-spec-figure-drift.md`:
```markdown
# Issue-0101: start-work 旧設計仕様書の図示が現行 SKILL.md から乖離している

- **Status**: open
- **Opened**: 2026-08-17
- **起票元**: ADR-0106 実装サイクル（確定前レビューの実装整合性観点が乖離を実測）
- **関連**: `docs/current/specs/2026-04-25-record-strengthening-design.md`、`skills/start-work/SKILL.md`

## 課題内容

`docs/current/specs/2026-04-25-record-strengthening-design.md` の Phase 2 マッピング表・横断的ラッパーの図示が現行 `skills/start-work/SKILL.md` と乖離している（表は 7 行のみで現行 13 行＋完了処理行に未追従。Pre の subagent-dispatch 条項・完了処理条項も未反映）。仕様書のスナップショット規約に照らし、書き換え更新か、図示の削除（SKILL.md への参照化）かの判断が要る。ADR-0106 実装では意図的に同期対象へ含めなかった（既存乖離が大きく、部分同期はかえって不整合を生むため）。

## 検討状況

- 2026-08-17: 起票。対策の採否・設計は次サイクル（ユーザー判断）

## 結論

（open）
```

- [ ] **Step 5-4: 課題インデックスへ行追加**

`docs/working/issues/README.md` の flow セクション末尾（0100 の行の後）へ:
```
| [0101](flow/0101-start-work-spec-figure-drift.md) | start-work 旧設計仕様書の図示が現行 SKILL.md から乖離している | open | 2026-08-17 |
```
（表の列構成が上と異なる場合は既存行の形式に合わせる。挿入位置は表の終端を実体確認してから）

- [ ] **Step 5-5: 検証と commit**

Run: `grep -c "0101" docs/working/issues/README.md`
Expected: `1` 以上

```bash
git add docs/records/decisions/0056-retrospective-issue-extraction-core-worklog-delegation.md docs/working/issues/flow/0084-merge-mode-norm-not-wired-into-finishing-flow.md docs/working/issues/flow/0101-start-work-spec-figure-drift.md docs/working/issues/README.md
git commit -m "docs: ADR-0056 部分修正注記・Issue-0084 補正・Issue-0101 起票（ADR-0106 付帯）" -- docs/records/decisions/0056-retrospective-issue-extraction-core-worklog-delegation.md docs/working/issues/flow/0084-merge-mode-norm-not-wired-into-finishing-flow.md docs/working/issues/flow/0101-start-work-spec-figure-drift.md docs/working/issues/README.md
```

### Task 6: 本リポジトリの git 設定（ADR-0106 決定 3）

- [ ] **Step 6-1: 設定適用**

Run:
```bash
git config branch.master.mergeoptions "--no-ff"
git config pull.ff true
```

- [ ] **Step 6-2: 実体読み直しで確認**

Run: `git config --get-all branch.master.mergeoptions && git config --get pull.ff`
Expected: `--no-ff` と `true` の 2 行

### Task 7: plugin version bump

**Files:**
- Modify: `.claude-plugin/plugin.json`（`"version": "0.1.8"` → `"0.1.9"`）
- Modify: `.claude-plugin/marketplace.json`（`"version": "0.1.8"` → `"0.1.9"`）

- [ ] **Step 7-1: 両ファイルの version を 0.1.9 へ**（`dist/.claude-plugin/plugin.json` は直接編集しない。build-dist.ps1 が複写する）

- [ ] **Step 7-2: 検証**

Run: `grep '"version"' .claude-plugin/plugin.json .claude-plugin/marketplace.json`
Expected: 両方 `0.1.9`

### Task 8: 配布物生成と執行点検査

- [ ] **Step 8-1: 生成器実行**

Run: `pwsh -File scripts/build-dist.ps1`
Expected: exit 0（非ゼロなら記法規約違反。違反箇所を修正して再実行）

- [ ] **Step 8-2: 両生成器の -Check**

Run: `pwsh -File scripts/build-dist.ps1 -Check; pwsh -File scripts/sync-template.ps1 -Check`
Expected: 両方 exit 0

- [ ] **Step 8-3: 配布物の目視（機械判定が届かない 5 型）**

`dist/skills/start-work/SKILL.md` と `dist/skills/retrospective/SKILL.md`・`dist/skills/retrospective/template.md` の**今回変更した節を通読**し、次の 5 型を確認する: 括弧内に識別子以外の語が同居した行 / 半角括弧 / 書式例の実在の固有名 / 自己参照（「本リポジトリ」等）/ 利用者へ表示する文字列内の識別子。とくに Task 1〜3 の新設文言に ADR 番号の裸参照が**無い**こと、および既定ブランチ解決手続きの記述（`master` / `main` の実在確認。設計どおりの文言）を**除いて** `master` の直書きが無いこと（コマンド例は `<既定ブランチ>` プレースホルダのままであること）。

Run: `grep -n "本リポジトリ\|本 repo" dist/skills/start-work/SKILL.md dist/skills/retrospective/SKILL.md dist/skills/retrospective/template.md`
Expected: 出力なし

### Task 9: スモーク検証（ADR-0106 決定 2 の完了基準）

scratchpad 配下に一時 git リポジトリを作成して実施する。実リポジトリでは実行しない。

- [ ] **Step 9-1: 慣行判定の入力側（(a) 固定の前に実施）**

一時ディレクトリに `docs/records/retrospectives/system/` を作り、ダミー記録 6 構成——(1) マージコミット行あり、(2) squash 行のみ、(3) fast-forward 行のみ、(4) 旧様式（`merge済み: <sha>` 形）のみ、(5) 新旧混在、(6) 0 件——をそれぞれ用意し、Task 1 Step 1-3 の慣行判定 手順 2 を文言どおり手動評価して、期待判定（1→慣行あり、2→残さない運用、3→未定義、4→慣行あり、5→新様式のみで判定、6→未定義）と一致することを確認する。(6) では手順 3 の確認 1 問→`git config ai-dev.mergepractice` 書き込み→再評価で (a) が短絡すること（再質問が起きないこと）を通す。

- [ ] **Step 9-2: 判定経路（(a) を慣行ありに固定して実施）**

一時 git リポジトリで `git config ai-dev.mergepractice merge-commit` を設定後、次の 5 状態を作り、Task 2 Step 2-3 の判定を文言どおり実行して期待どおりになることを確認する:
1. ff マージ → fast-forward 判定
2. `--no-ff` マージ → fast-forward でない
3. 競合解決マージ（`commit (merge):` 行）→ 判定材料にしない（ブランチ現存なら rev-parse 経路で正しく判定）
4. squash → 祖先判定で「未マージまたは squash」（fast-forward と判定しない）
5. ブランチ削除済み ff → reflog の `merge <名>: Fast-forward` 行から先端を取得して fast-forward 判定
やり直し手順は状態 1 で承認ステップを省いた dry-run（一時 ref → stash → `-uno` 空確認 → reset → `--no-ff` 再マージ → 復元）を 1 度通す。「分岐点不能」は判定不能報告の確認で足りる。さらに発動ゲートの 3 値分岐も確認する: `ai-dev.mergepractice` を `none` に変えて検出が発動しないこと、未設定に戻して 1 問確認のみに留まる（ff 判定を出さない）こと。承認要件（リスク段階によらず承認必須の文言）は dry-run では検証できないため、Task 2 Step 2-3 の実装文言の目視レビューで確認する。

- [ ] **Step 9-3: 結果の記録**

スモーク結果（6＋5 状態の合否一覧）をこの plan ファイルの末尾へ追記する。

### Task 10: skills＋dist＋version の同一コミットと最終突合

- [ ] **Step 10-1: ステージ確認とコミット**

Run: `git status --short` で対象を確認（inbox・conversation_log を巻き込まない。pathspec 指定）

```bash
git add skills/start-work/SKILL.md skills/retrospective/SKILL.md skills/retrospective/template.md .claude-plugin/plugin.json .claude-plugin/marketplace.json dist/
git commit -m "feat: ADR-0106 マージ方式確認と ff 検出の 2 層配線（plugin 0.1.9）" -- skills/start-work/SKILL.md skills/retrospective/SKILL.md skills/retrospective/template.md .claude-plugin/plugin.json .claude-plugin/marketplace.json dist/
```

- [ ] **Step 10-2: ADR-0106 との最終突合（実体読み直し）**

ADR-0106 の Decision の各箇条（慣行判定・決定 1 の 4 箇条・決定 2 の 7 箇条・決定 3）を上から読み、実装先ファイルの該当箇所を Read で開いて 1 対 1 対応を確認する。対応漏れがあれば当該 Task へ戻る。

- [ ] **Step 10-3: 検証（配布物と規約）**

Run: `pwsh -File scripts/build-dist.ps1 -Check; pwsh -File scripts/sync-template.ps1 -Check`
Expected: 両方 exit 0（コミット後の再確認）

---

## 完了基準（サイクル全体）

1. Task 1〜10 の全 Step 完了（スモーク 11 状態すべて合格）
2. `git config --get-all branch.master.mergeoptions` = `--no-ff`、`git config --get pull.ff` = `true`
3. `dist/` と `.claude-plugin/` の version が 0.1.9 で一致
4. ADR-0106 Accepted 昇格（サイクル全体整合検査つき）と Issue-0084 close（結論に ADR-0106・インデックス更新）は plan 外の通常フロー（Post ラッパー）で実施

## スモーク検証結果（Task 9-3 で追記）

（未実施）
