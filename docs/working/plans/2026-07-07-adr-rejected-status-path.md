# ADR Rejected 経路と台帳監査の実装計画（Issue-0019 / ADR-0041 / ADR-0042）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** コミット済み Proposed ADR の不採用経路（Rejected）と Superseded の置換対象特定手順・台帳監査を定義し、初回監査と据え置き Proposed 3件の処遇判断まで実施する。

**Architecture:** ドキュメント定義のみ（新規スクリプトなし）。手順は Layer 3 スキル（decision-log / start-work）と CONTRIBUTING.md に配置し、CLAUDE.md は変更しない（ADR-0040）。設計記録は ADR-0041 / ADR-0042 が兼ねる（spec なし）。

**Tech Stack:** Markdown 編集のみ。検証は grep による read-back（ADR-0034 / ADR-0038）。

**前提事実（計画時に確認済み）:**

- template.manifest の対象は `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` のみ。今回の変更ファイルはすべて対象外のため **sync-template.ps1 の実行は不要**
- skills/ の変更はプラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）まで実行環境に反映されない（リポジトリ上の編集が本サイクルの成果物）
- コミットメッセージは Bash ツール（POSIX sh）から `printf ... > file && git commit -F file` で渡す（Issue-0015: PowerShell here-string 不可）
- Task 4・5 はユーザーとの対話（境界例判定・処遇判断）を含むため、サブエージェントへ委任せずメインセッションで実行すること

---

### Task 1: decision-log スキルに Rejected 経路と置換対象特定を追加

**Files:**
- Modify: `skills/decision-log/SKILL.md`

- [ ] **Step 1: 終端ステータスの意味境界表を追加し、ステータス変更手順に Rejected を織り込む**

以下の既存ブロックを:

```markdown
## ADR更新手順

### ステータス変更

ADRのステータスを変更する場合（Deprecated、Superseded、いったん Accepted にした決定の見直しなど）:

1. 該当ADRファイルの `Status` を更新する（Deprecated, Superseded by ADR-XXXX 等）
2. `docs/records/decisions/README.md` のテーブルのステータスも更新する
3. 変更理由をADRのConsequencesセクションに追記する
4. コミットする
```

次に置き換える:

```markdown
## ADR更新手順

### 終端ステータスの意味境界（ADR-0041）

| ステータス | 意味 | 遷移元 |
|-----------|------|--------|
| Accepted | 承認され現役 | Proposed |
| Rejected | 承認前に不採用が確定 | Proposed |
| Deprecated | 承認後に廃止（置換先なし） | Accepted |
| Superseded by ADR-XXXX | 承認後に新 ADR で置換 | Accepted |

いずれの遷移でもファイルは削除しない（削除してよいのは未コミットのドラフトのみ。「ユーザーへの確認」参照）。

### ステータス変更

ADRのステータスを変更する場合（Rejected、Deprecated、Superseded、いったん Accepted にした決定の見直しなど）:

1. 該当ADRファイルの `Status` を更新する（Rejected, Deprecated, Superseded by ADR-XXXX 等）
2. `docs/records/decisions/README.md` のテーブルのステータスも更新する
3. 変更理由（Rejected の場合は不採用の理由）をADRのConsequencesセクションに追記する
4. コミットする
```

- [ ] **Step 2: 採番ステップに置換対象の特定を追加する**

以下の既存ブロックを:

```markdown
### 1. 次の連番を決定する

`docs/records/decisions/README.md` のテーブルを確認し、最大番号+1を採番する。
テーブルが空なら `0001` から開始する。
```

次に置き換える:

```markdown
### 1. 次の連番を決定し、置換対象の既存 ADR を特定する

`docs/records/decisions/README.md` のテーブルを確認し、最大番号+1を採番する。
テーブルが空なら `0001` から開始する。

あわせて、この決定が既存の決定を変更・置換していないかを確認する（ADR-0042。既存 ADR の全件調査は不要）:

- 一次経路: 変更対象ファイルが引用している ADR 番号を確認する
- 二次経路: 開いているインデックスのタイトルを同一トピックで走査する

置換対象が見つかったら、新 ADR の作成と同時に旧 ADR を `Superseded by ADR-XXXX` へ更新する（「ステータス変更」の手順に従う）。ここでの特定は網羅保証を追わない（取りこぼしは台帳監査で回収する。`CONTRIBUTING.md`「ADRを記録するとき」の台帳監査を参照）。
```

- [ ] **Step 3: ユーザーへの確認の却下分岐を2つに分割する**

以下の既存ブロックを:

```markdown
- 却下 → ファイルとインデックスエントリを削除します」
```

次に置き換える:

```markdown
- 却下 → 未コミットのドラフトならファイルとインデックスエントリを削除します。コミット済みなら Status を Rejected に変更して残します」
```

さらに以下の既存ブロックを:

```markdown
- 却下: ADRファイル削除 → インデックスエントリ削除 → コミット（理由を commit message に残す）
```

次に置き換える:

```markdown
- 却下（未コミットのドラフト）: ADRファイル削除 → インデックスエントリ削除 → コミット（理由を commit message に残す）
- 却下（コミット済み）: 「ステータス変更」の手順で Status を `Rejected` へ → 不採用の理由を Consequences に追記 → インデックスも更新 → コミット。ファイルは削除しない（ADR-0041）
```

- [ ] **Step 4: read-back 検証**

Run: `grep -c "Rejected" skills/decision-log/SKILL.md`
Expected: `6`（意味境界表1・ステータス変更節3・却下分岐2）

Run: `grep -c "ADR-0041" skills/decision-log/SKILL.md`
Expected: `2`（意味境界表見出し・却下コミット済み分岐）

Run: `grep -c "ADR-0042" skills/decision-log/SKILL.md`
Expected: `1`（置換対象特定ステップ）

Run: `grep -c "削除します」" skills/decision-log/SKILL.md`
Expected: `0`（旧文言の残存なし。新文言は「〜削除します。コミット済みなら〜残します」）

- [ ] **Step 5: コミット**

```bash
MSGFILE="<scratchpad>/commit-msg-task1.txt"
printf 'feat: decision-log に Rejected 経路と置換対象特定ステップを追加（ADR-0041/0042）\n\nCo-Authored-By: Claude Fable 5 <noreply@anthropic.com>\n' > "$MSGFILE"
git add skills/decision-log/SKILL.md
git commit -F "$MSGFILE" -- skills/decision-log/SKILL.md
```

---

### Task 2: start-work スキルの Post チェックを不採用方向へ対称化

**Files:**
- Modify: `skills/start-work/SKILL.md`

- [ ] **Step 1: Post チェックの昇格確認を対称化する**

以下の既存文を:

```markdown
   また、設計承認・実装完了などのチェックポイントを通過した場合、Proposed のまま据え置かれているADRのうち決定が確定したものを Accepted へ昇格させる（`decision-log` の「承認の昇格」に従う）。あわせて、未コミットの ADR ドラフトのうち関連論点が収束したものをコミットする（ADR-0030）。
```

次に置き換える:

```markdown
   また、設計承認・実装完了などのチェックポイントを通過した場合、Proposed のまま据え置かれているADRのうち決定が確定したものを Accepted へ昇格させ、議論の結果不採用が確定したものを Rejected へ更新する（`decision-log` の「承認の昇格」「ステータス変更」に従う。ADR-0041）。あわせて、未コミットの ADR ドラフトのうち関連論点が収束したものをコミットする（ADR-0030）。
```

- [ ] **Step 2: セッション終了処理の確認文言も対称化する**

以下の既存文を:

```markdown
2. 未コミットの ADR ドラフトがないか確認し、関連論点が収束済みのものはコミットする（Accepted 昇格漏れの確認と合わせて行う。ADR-0030 / ADR-0019）
```

次に置き換える:

```markdown
2. 未コミットの ADR ドラフトがないか確認し、関連論点が収束済みのものはコミットする（Accepted 昇格漏れ・不採用確定分の Rejected 更新漏れの確認と合わせて行う。ADR-0030 / ADR-0019 / ADR-0041）
```

- [ ] **Step 3: read-back 検証**

Run: `grep -c "Rejected" skills/start-work/SKILL.md`
Expected: `2`（Post チェック1・セッション終了処理1）

Run: `grep -c "ADR-0041" skills/start-work/SKILL.md`
Expected: `2`

- [ ] **Step 4: コミット**

```bash
MSGFILE="<scratchpad>/commit-msg-task2.txt"
printf 'feat: start-work の Post チェックとセッション終了処理を不採用方向へ対称化（ADR-0041）\n\nCo-Authored-By: Claude Fable 5 <noreply@anthropic.com>\n' > "$MSGFILE"
git add skills/start-work/SKILL.md
git commit -F "$MSGFILE" -- skills/start-work/SKILL.md
```

---

### Task 3: CONTRIBUTING.md に台帳監査の小節を追加

**Files:**
- Modify: `CONTRIBUTING.md`

- [ ] **Step 1: 「シナリオ: ADRを記録するとき」の記述規律小節の直後に台帳監査小節を追加する**

以下の既存ブロック（記述規律小節の末尾と次シナリオ見出し）を:

```markdown
- 撤去基準・発動条件・適用条件などの判定条件は、実行主体であるエージェントが**観測・実行できる事実**で書く。エージェントが判定できない条件は「ユーザーが判断し指示した時点」のように判断主体をユーザーへ明示的に移す（ADR-0032）。

## シナリオ: 未決事項・課題を記録するとき
```

次に置き換える:

```markdown
- 撤去基準・発動条件・適用条件などの判定条件は、実行主体であるエージェントが**観測・実行できる事実**で書く。エージェントが判定できない条件は「ユーザーが判断し指示した時点」のように判断主体をユーザーへ明示的に移す（ADR-0032）。

### 台帳監査（ADR-0042）

ADR インデックス全体のステータス正確性を確認する保険的な監査。新規 ADR 起票時の置換対象特定（`decision-log` の採番ステップ）は網羅保証を持たないため、その取りこぼしをここで回収する。以下のいずれかで発動する:

- ユーザーが監査を指示した時点
- エージェントが作業中に台帳の矛盾（引用先 ADR と実態の不一致等）を具体的に発見し、監査を提案してユーザーが承認した時点

手順: 全 ADR を「現役 / 部分修正あり（本体現役・状態変更なし）/ 実質置換（Superseded 化）/ 廃止（Deprecated 化）」で判定し、状態変更は `decision-log` の「ステータス変更」手順で記録する。境界例の判定はユーザーと確認しながら行う。

定期実行は定義しない。取りこぼしが実際に累積した場合は、滞留検出の機械化を課題として起票する。

## シナリオ: 未決事項・課題を記録するとき
```

- [ ] **Step 2: read-back 検証**

Run: `grep -c "台帳監査" CONTRIBUTING.md`
Expected: `1`（小節見出し）

Run: `grep -c "ADR-0042" CONTRIBUTING.md`
Expected: `1`

- [ ] **Step 3: コミット**

```bash
MSGFILE="<scratchpad>/commit-msg-task3.txt"
printf 'docs: CONTRIBUTING.md の ADR 記録シナリオに台帳監査の小節を追加（ADR-0042）\n\nCo-Authored-By: Claude Fable 5 <noreply@anthropic.com>\n' > "$MSGFILE"
git add CONTRIBUTING.md
git commit -F "$MSGFILE" -- CONTRIBUTING.md
```

---

### Task 4: 初回台帳監査（ADR-0001〜0040 全件）※ユーザー対話必須・メインセッションで実行

**Files:**
- Read: `docs/records/decisions/0001-*.md` 〜 `docs/records/decisions/0040-*.md`（全40件）
- Modify: 判定結果に応じて該当 ADR ファイルと `docs/records/decisions/README.md`

- [ ] **Step 1: 全40件を読み、4分類の判定表を作る**

各 ADR を「現役 / 部分修正あり（状態変更なし）/ 実質置換（Superseded 化）/ 廃止（Deprecated 化）」で仮判定し、根拠（後続 ADR 番号・変更内容）を1行ずつ添えた表を作成する。既知の境界例（ADR-0015/0017、ADR-0016/0023、ADR-0003/0027、ADR-0010/0021）は根拠を厚めに書く。

- [ ] **Step 2: 判定表をユーザーに提示し、境界例の判定を確認する**

「現役」以外の判定はすべてユーザーの承認を得る。承認前に状態変更を適用しないこと。

- [ ] **Step 3: 承認された状態変更を適用する**

Task 1 で更新した `decision-log` の「ステータス変更」手順に従う: 該当 ADR の Status 更新 → 変更理由を Consequences に追記 → `README.md` テーブルの Status 更新。

- [ ] **Step 4: read-back 検証**

Run: `grep -c "Superseded" docs/records/decisions/README.md`
Expected: Step 3 で Superseded 化した件数と一致（0件なら 0）

Run: `grep -c "Deprecated" docs/records/decisions/README.md`
Expected: Step 3 で Deprecated 化した件数と一致（0件なら 0）

- [ ] **Step 5: コミット**

```bash
MSGFILE="<scratchpad>/commit-msg-task4.txt"
printf 'docs: 初回の ADR 台帳監査を実施（ADR-0042 の適用）\n\n判定結果の内訳をここに記載する\n\nCo-Authored-By: Claude Fable 5 <noreply@anthropic.com>\n' > "$MSGFILE"
git add docs/records/decisions/
git commit -F "$MSGFILE" -- docs/records/decisions/
```

---

### Task 5: 据え置き Proposed 3件（ADR-0013 / 0014 / 0018）の処遇判断 ※ユーザー対話必須・メインセッションで実行

**Files:**
- Modify: 判断結果に応じて `docs/records/decisions/0013-*.md` / `0014-*.md` / `0018-*.md` と `README.md`

- [ ] **Step 1: 3件それぞれの現状分析をユーザーに提示する**

各 ADR について「決定内容 / 未実装である事実 / 現行ガイドラインとの重複・矛盾の有無」を提示し、処遇（採用継続 / Rejected / 据え置き継続）の推奨を添える。事前確認済みの事実: 3件とも未実装（knowledge-distillation スキル不在、親ディレクトリ確認規範・brainstorming 必須化規範とも CLAUDE.md に不在）。

- [ ] **Step 2: ユーザーの処遇判断を1件ずつ確認する**

- [ ] **Step 3: 判断を適用する**

- Rejected → Task 1 で定義した手順（Status 更新・不採用理由を Consequences へ・インデックス更新）
- 採用継続 → Proposed のまま。実装サイクルの計画が必要なら課題（`docs/working/issues/`）に起票する
- 据え置き継続 → 変更なし（据え置き理由を handoff に記録）

- [ ] **Step 4: read-back 検証**

Run: `grep -c "Proposed" docs/records/decisions/README.md`
Expected: 判断結果と一致（例: 3件すべて Rejected なら、残る Proposed は ADR-0041/0042 の2件のみ → `2`）

- [ ] **Step 5: コミット**

```bash
MSGFILE="<scratchpad>/commit-msg-task5.txt"
printf 'docs: 据え置き Proposed ADR 3件（0013/0014/0018）の処遇を確定\n\n判断結果の内訳をここに記載する\n\nCo-Authored-By: Claude Fable 5 <noreply@anthropic.com>\n' > "$MSGFILE"
git add docs/records/decisions/ docs/working/issues/
git commit -F "$MSGFILE" -- docs/records/decisions/ docs/working/issues/
```

---

### Task 6: Issue-0019 close と ADR-0041/0042 の Accepted 昇格

**Files:**
- Modify: `docs/working/issues/flow/0019-adr-rejected-status-path.md`
- Modify: `docs/working/issues/README.md`
- Modify: `docs/records/decisions/0041-adr-rejected-status-and-ledger-audit.md`
- Modify: `docs/records/decisions/0042-superseded-identification-and-ledger-audit.md`
- Modify: `docs/records/decisions/README.md`

- [ ] **Step 1: ADR-0041 / 0042 の Status を Accepted へ昇格する**

実装（Task 1〜3）と適用（Task 4〜5）の完了を確認したうえで、両 ADR ファイルの `- **Status**: Proposed` を `- **Status**: Accepted` に変更し、`docs/records/decisions/README.md` の両行の Status も `Accepted` に更新する。

- [ ] **Step 2: Issue-0019 を close する**

`docs/working/issues/flow/0019-adr-rejected-status-path.md` の Status を `closed` に変更し、Closed 日付を記入し、「検討状況」に対策サイクルの要約を、「結論」に `ADR-0041 / ADR-0042` を記載する。`docs/working/issues/README.md` の 0019 行の Status を `closed` に更新する。

- [ ] **Step 3: read-back 検証**

Run: `grep -c "Accepted | 2026-07-07" docs/records/decisions/README.md`
Expected: `2`（ADR-0041/0042 の2行）

Run: `grep -c "closed" docs/working/issues/flow/0019-adr-rejected-status-path.md`
Expected: `1`以上（Status 行）

- [ ] **Step 4: コミット**

```bash
MSGFILE="<scratchpad>/commit-msg-task6.txt"
printf 'docs: Issue-0019 close と ADR-0041/0042 の Accepted 昇格（対策実装完了）\n\nCo-Authored-By: Claude Fable 5 <noreply@anthropic.com>\n' > "$MSGFILE"
git add docs/working/issues/ docs/records/decisions/
git commit -F "$MSGFILE" -- docs/working/issues/ docs/records/decisions/
```

---

## 完了後（plan 外・セッションフローで実施）

- ハンドオフ更新 → master へのマージ（finishing-a-development-branch）→ retrospective → handoff finalize
- プラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）はユーザー操作
