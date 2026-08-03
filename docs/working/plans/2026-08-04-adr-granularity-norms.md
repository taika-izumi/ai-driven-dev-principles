# ADR 粒度・文章量の規範整備 実装計画（Issue-0022 対処）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ADR の粒度判定を「後から探しに来るときの問い」の単位で規範化し、起票時・追記時・昇格前の3箇所で点検が働くようにする。

**Architecture:** 規範の置き場所は `skills/decision-log/SKILL.md` に一本化する。`skills/start-work/SKILL.md` は Post ラッパー項目1から「承認の昇格」手順を参照するに留め、点検内容を重複記述しない。文章量の閾値・計測スクリプトは導入しない（実測により指標として棄却済み。ADR-0059）。

**Tech Stack:** Markdown（スキル定義・仕様書）。検証は grep による受入チェックと read-back。実行コードはない。

**根拠 ADR:** ADR-0059（粒度の基準）/ ADR-0060（点検の契機）。いずれも Proposed、コミット `9ec6682`。

---

## 変更対象ファイル

| ファイル | 責務 | 変更内容 |
|---|---|---|
| `skills/decision-log/SKILL.md` | ADR 記録規範の唯一の置き場所 | 起票時の粒度規範（blockquote）／追記時の手順（新設節）／承認の昇格への突合ステップ |
| `skills/start-work/SKILL.md` | ワークフローのオーケストレーション | Post ラッパー項目1に「承認の昇格」手順への参照を1文追加 |
| `docs/current/specs/2026-04-25-record-strengthening-design.md` | 記録強化サブプロジェクトのスナップショット仕様 | §7 に 7.4 を新設／§5.3.1 に昇格前点検の位置づけを追記 |
| `docs/records/decisions/0059-*.md` / `0060-*.md` ＋ 索引 | 決定の記録 | 実装完了後に Proposed → Accepted |
| `docs/working/issues/flow/0022-adr-granularity-check.md` ＋ 索引 | 課題のライフサイクル管理 | close（結論に ADR 番号） |

**テンプレート同期は不要**（`template.manifest` の対象は CLAUDE.md / principles.md / folder-structure.md / docs/inbox/README.md の4件。skills は ADR-0016 で除外）。**CLAUDE.md は変更しない**（規範は Layer 3 に置く。ADR-0040 の配置優先順位）。

---

### Task 1: 起票時の粒度規範を `decision-log` に追加

**Files:**
- Modify: `skills/decision-log/SKILL.md`（「### 2. ADRファイルを作成する」内、実行可能性チェックの blockquote 直後）

- [x] **Step 1: 挿入位置を確認する**

Run: `grep -n "実行可能性チェック（ADR-0032）" skills/decision-log/SKILL.md`
Expected: 1件ヒット（現状 91 行目付近）。この blockquote 段落の直後に挿入する。

- [x] **Step 2: blockquote を追加する**

`> **実行可能性チェック（ADR-0032）**: ...` で始まる段落の直後（次の `### 3. インデックスを更新する` の前）に、空行を1行はさんで以下を挿入する:

```markdown
> **粒度（ADR-0059）**: 1つの ADR は「後から探しに来るときの問い」1つに答えるものとする。起票する決定が2つ以上の問いに割れるなら ADR を分ける。タイトルはその問いへの答えとして読めるように書き、タイトルが答えていない決定を本文に含めない。**文章量（文字数・行数）は粒度の基準にしない**（長いことは分割の理由にならず、分割しても総文章量はむしろ増える）。
```

- [x] **Step 3: 受入チェック**

Run: `grep -c "粒度（ADR-0059）" skills/decision-log/SKILL.md`
Expected: `1`

Run: `grep -c "文章量（文字数・行数）は粒度の基準にしない" skills/decision-log/SKILL.md`
Expected: `1`

Run: `grep -n "実行可能性チェック（ADR-0032）\|粒度（ADR-0059）\|### 3. インデックスを更新する" skills/decision-log/SKILL.md`
Expected: 3件が「実行可能性チェック → 粒度 → ### 3.」の行番号順に並ぶ

- [x] **Step 4: コミット**

```bash
git add skills/decision-log/SKILL.md
git commit -m "skill: decision-log の起票手順に粒度の判定規範を追加（ADR-0059）"
```

---

### Task 2: 追記時の手順を `decision-log` に新設

**Files:**
- Modify: `skills/decision-log/SKILL.md`（「### 4. コミットのタイミング（ADR-0030）」の節末、`## 未決事項（open questions）の扱い` の直前）

- [x] **Step 1: 挿入位置を確認する**

Run: `grep -n "^## 未決事項（open questions）の扱い" skills/decision-log/SKILL.md`
Expected: 1件ヒット（現状 118 行目付近）。この見出しの直前に挿入する。

- [x] **Step 2: 新しい節を挿入する**

`## 未決事項（open questions）の扱い` の直前に、以下をそのまま挿入する:

```markdown
## Proposed の ADR へ決定を追記するとき（ADR-0060）

未コミット・Proposed のドラフトは書き直し自由だが（ADR-0030）、議論の往復で決定を追記し続けると主題がずれて肥大する経路がある。**決定を追記する手順の一部として**次を行う（独立した消し込み項目としては設けない）:

1. 追記する決定に対し、**既存のタイトルがその決定にも答えているか**を突合する
2. 答えているなら、そのまま追記して終了する
3. 答えていないなら、その決定は別の問いに属する。**AI 側から分割をユーザーへ提案する**（提案には、分割後の各 ADR が答える問いと採番案を含める）
4. 分割する場合、各 ADR が単独で成立するよう Context・Considered Alternatives・Decision・Consequences をそれぞれ持たせ、相互参照を張る
5. 参照元を更新する。**決定の序数（`ADR-NNNN Decision N` / `決定 N`）で参照している箇所がある場合は、置換の適用順序を先に設計してから実行する**（順序を誤ると、番号が振り直された項目に後続の置換が当たって二重置換が起きる）

タイトルを書き換えれば追記した決定も同じ問いに収まる場合は、タイトルの更新で足りる（分割は不要）。
```

- [x] **Step 3: 受入チェック**

Run: `grep -c "^## Proposed の ADR へ決定を追記するとき（ADR-0060）" skills/decision-log/SKILL.md`
Expected: `1`

Run: `grep -c "置換の適用順序を先に設計してから実行する" skills/decision-log/SKILL.md`
Expected: `1`

Run: `grep -n "^## " skills/decision-log/SKILL.md`
Expected: `## Proposed の ADR へ決定を追記するとき（ADR-0060）` が `## ADR作成手順` の後、`## 未決事項（open questions）の扱い` の前に現れる

- [x] **Step 4: コミット**

```bash
git add skills/decision-log/SKILL.md
git commit -m "skill: decision-log に Proposed ADR への追記手順（タイトル突合と分割提案）を新設（ADR-0060）"
```

---

### Task 3: 「承認の昇格」手順に突合ステップを追加

**Files:**
- Modify: `skills/decision-log/SKILL.md`（「### 承認の昇格（Proposed → Accepted、ADR-0019）」内の「昇格手順:」リスト）

- [x] **Step 1: 現在の手順を確認する**

Run: `grep -n -A 5 "^昇格手順:" skills/decision-log/SKILL.md`
Expected: 3ステップ（Status 更新 / インデックス更新 / コミット）が表示される

- [x] **Step 2: 手順を4ステップへ置き換える**

以下の既存ブロックを

```markdown
昇格手順:

1. 該当ADRファイルの `Status` を `Accepted` に更新する
2. `docs/records/decisions/README.md` のテーブルのステータスも更新する
3. コミットする
```

次で置き換える:

```markdown
昇格手順:

1. **粒度を点検する（ADR-0059 / ADR-0060）**: 昇格対象 ADR のタイトルが本文の全決定に答えているかを突合する。答えていない決定があれば分割を提案し、分割してから昇格する
2. 該当ADRファイルの `Status` を `Accepted` に更新する
3. `docs/records/decisions/README.md` のテーブルのステータスも更新する
4. コミットする
```

- [x] **Step 3: 受入チェック**

Run: `grep -c "粒度を点検する（ADR-0059 / ADR-0060）" skills/decision-log/SKILL.md`
Expected: `1`

Run: `grep -n -A 6 "^昇格手順:" skills/decision-log/SKILL.md`
Expected: 番号付きリストが 1〜4 の4ステップになっており、1 が粒度点検、4 がコミット

- [x] **Step 4: コミット**

```bash
git add skills/decision-log/SKILL.md
git commit -m "skill: decision-log の承認の昇格に粒度点検ステップを追加（ADR-0060）"
```

---

### Task 4: `start-work` の Post ラッパーから参照を張る

**Files:**
- Modify: `skills/start-work/SKILL.md`（「Post（実行後）」の項目1「ADR候補検出」内）

- [x] **Step 1: 対象文を確認する**

Run: `grep -n "承認の昇格」「ステータス変更」に従う" skills/start-work/SKILL.md`
Expected: 1件ヒット

- [x] **Step 2: 参照を1文追加する**

以下の既存文の末尾（`。あわせて、未コミットの ADR ドラフト...` の直前）に1文を挿入する。

置換前:

```markdown
   また、設計承認・実装完了などのチェックポイントを通過した場合、Proposed のまま据え置かれているADRのうち決定が確定したものを Accepted へ昇格させ、議論の結果不採用が確定したものを Rejected へ更新する（`decision-log` の「承認の昇格」「ステータス変更」に従う。ADR-0041）。あわせて、未コミットの ADR ドラフトのうち関連論点が収束したものをコミットする（ADR-0030）。
```

置換後:

```markdown
   また、設計承認・実装完了などのチェックポイントを通過した場合、Proposed のまま据え置かれているADRのうち決定が確定したものを Accepted へ昇格させ、議論の結果不採用が確定したものを Rejected へ更新する（`decision-log` の「承認の昇格」「ステータス変更」に従う。ADR-0041）。昇格の手順には粒度の点検が含まれる（`decision-log` の「承認の昇格」第1ステップ。ADR-0059 / ADR-0060。点検の規範は `decision-log` 側にあり、ここには重複して書かない）。あわせて、未コミットの ADR ドラフトのうち関連論点が収束したものをコミットする（ADR-0030）。
```

- [x] **Step 3: 受入チェック**

Run: `grep -c "「承認の昇格」第1ステップ" skills/start-work/SKILL.md`
Expected: `1`

Run: `grep -c "後から探しに来るときの問い" skills/start-work/SKILL.md`
Expected: `0`（規範本体を start-work 側へ複写していないことの確認）

- [x] **Step 4: コミット**

```bash
git add skills/start-work/SKILL.md
git commit -m "skill: start-work の Post ラッパーから decision-log の粒度点検へ参照を張る（ADR-0060）"
```

---

### Task 5: 仕様書を改定内容へ同期

**Files:**
- Modify: `docs/current/specs/2026-04-25-record-strengthening-design.md`（§5.3.1 の末尾、および §7 の末尾に 7.4 を新設）

この仕様書には現行スキル本文より古い記述（§7.2 のドラフト承認フロー等）が残っているが、**変更箇所のみを訂正**し、全面訂正は Issue-0008 の方針決定に委ねる（前サイクルの前例）。

- [x] **Step 1: §5.3.1 に1段落追記する**

`### 5.3.1 Post ラッパーの消し込み規律（ADR-0057）` 節の最終段落（`Post ラッパーに完全に入らなかった場合は...` で始まる段落）の直後に、以下を挿入する:

```markdown
Post ラッパー項目1で据え置き ADR を Accepted へ昇格させるときは、`decision-log` の「承認の昇格」手順に含まれる粒度点検が先に走る（ADR-0059 / ADR-0060）。点検の規範は `decision-log` 側に一本化されており、Post ラッパー側および セッション終了処理には重複して記述しない。
```

- [x] **Step 2: §7 に 7.4 を新設する**

`### 7.3 description フィールドの強化` のコードブロック終端（ファイル 318 行目付近の ` ``` `）の直後、`## 8. .github/copilot-instructions.md の更新` の直前に、以下を挿入する:

```markdown
### 7.4 粒度の判定と追記時の点検（ADR-0059 / ADR-0060）

ADR の粒度は「後から探しに来るときの問い」1つを単位とする。1つの ADR は将来その決定を探しに来る人が立てる問い1つに答えるものとし、問いが2つ以上に割れるなら分割する。**文章量は粒度の基準にしない**（LoopForAlpha の実測で、肥大 ADR 5,545文字に対し分割後4本の合計が 13,918文字へ増え、かつ正常な ADR に 7,558文字が存在したため、閾値では見逃しと誤検出が同時に起きる）。

判定は3箇所へ配置する:

| 契機 | 配置先 | 内容 |
|------|--------|------|
| 起票時 | ADR ファイル作成手順の blockquote | 起票する決定が2つ以上の問いに割れないか |
| 追記時 | 「Proposed の ADR へ決定を追記するとき」節 | タイトルが追記する決定にも答えているかを突合し、ずれていれば AI 側から分割を提案する |
| 昇格前 | 「承認の昇格」手順の第1ステップ | タイトルが本文の全決定に答えているかを突合する |

追記時の点検を一次経路、昇格前の点検を受け皿とする。追記時に検出すると分割の影響面が最小で済むため（LoopForAlpha では起草直後10ファイル対 昇格時24ファイル）。いずれも**独立した消し込み項目としては設けない**（追記操作および既存の昇格ステップに内包させ、Post ラッパーの項目数を増やさない）。

規範の置き場所は `decision-log` に一本化し、昇格を促す側（`start-work` の Post ラッパー項目1、セッション終了処理）は手順を参照するに留める。
```

- [x] **Step 3: 受入チェック**

Run: `grep -c "### 7.4 粒度の判定と追記時の点検" docs/current/specs/2026-04-25-record-strengthening-design.md`
Expected: `1`

Run: `grep -n "^### 7.3\|^### 7.4\|^## 8." docs/current/specs/2026-04-25-record-strengthening-design.md`
Expected: 行番号順に 7.3 → 7.4 → 8.

Run: `grep -c "承認の昇格」手順に含まれる粒度点検" docs/current/specs/2026-04-25-record-strengthening-design.md`
Expected: `1`

- [x] **Step 4: 読み直しによる整合確認（ADR-0038）**

`skills/decision-log/SKILL.md` の粒度関連3箇所と §7.4 の表を読み比べ、契機・配置先・内容が一致することを確認する。不一致があれば仕様書側を実装に合わせる。

- [x] **Step 5: コミット**

```bash
git add docs/current/specs/2026-04-25-record-strengthening-design.md
git commit -m "spec: 記録強化仕様へ ADR 粒度点検の3契機を反映（ADR-0059/0060）"
```

---

### Task 6: ADR の Accepted 昇格と Issue-0022 の close

**Files:**
- Modify: `docs/records/decisions/0059-adr-granularity-by-question-not-length.md`
- Modify: `docs/records/decisions/0060-adr-granularity-check-on-append.md`
- Modify: `docs/records/decisions/README.md`
- Modify: `docs/working/issues/flow/0022-adr-granularity-check.md`
- Modify: `docs/working/issues/README.md`

- [x] **Step 1: 昇格前の粒度点検を実施する（新規範のドッグフーディング）**

ADR-0059 / ADR-0060 それぞれについて、タイトルが本文の全決定に答えているかを突合する。結果をユーザーへ報告する（分割不要と判断した場合もその旨を述べる）。

- [x] **Step 2: 両 ADR の Status を Accepted にする**

各ファイルの `- **Status**: Proposed` を `- **Status**: Accepted` に置き換える。

- [x] **Step 3: ADR 索引を更新する**

`docs/records/decisions/README.md` の 0059 / 0060 の行の `Proposed` を `Accepted` に置き換える。

- [x] **Step 4: Issue-0022 を close する**

`docs/working/issues/flow/0022-adr-granularity-check.md` を次のように更新する:

- `- **Status**: open` → `- **Status**: closed`
- `- **Opened**: 2026-07-07` の直後に `- **Closed**: 2026-08-04` を追加
- 「## 結論」セクションの `（open）` を次で置き換える:

```markdown
ADR-0059（粒度の基準）と ADR-0060（点検の契機）で決着した。

- 粒度の単位は「後から探しに来るときの問い」1つ。決定の件数は数えない
- **文章量は基準にしない**。実測により、分割は総文章量を増やし（5,545文字 → 4本合計 13,918文字）、肥大 ADR より大きい正常な ADR が存在するため、閾値は見逃しと誤検出を同時に生む
- 点検は起票時・追記時・昇格前の3箇所。規範は `decision-log` に一本化し、`start-work` は参照のみ
```

- [x] **Step 5: Issue 索引を更新する**

`docs/working/issues/README.md` の 0022 の行の `open` を `closed` に置き換える。

- [x] **Step 6: 受入チェック**

Run: `grep -c "^- \*\*Status\*\*: Accepted" docs/records/decisions/0059-adr-granularity-by-question-not-length.md docs/records/decisions/0060-adr-granularity-check-on-append.md`
Expected: 両ファイルとも `1`

Run: `grep -n "0059\|0060" docs/records/decisions/README.md`
Expected: 2行とも `Accepted`

Run: `grep -n "Status\|Closed" docs/working/issues/flow/0022-adr-granularity-check.md`
Expected: `closed` と `2026-08-04` が表示される

Run: `grep -n "0022" docs/working/issues/README.md`
Expected: 行の Status が `closed`

- [x] **Step 7: コミット**

```bash
git add docs/records/decisions docs/working/issues
git commit -m "adr+issues: 0059/0060 を Accepted へ昇格し、Issue-0022 を close"
```

---

### Task 7: 完了処理

- [x] **Step 1: 全体の受入チェックを一括実行する**

Run:
```bash
grep -c "粒度（ADR-0059）" skills/decision-log/SKILL.md
grep -c "^## Proposed の ADR へ決定を追記するとき（ADR-0060）" skills/decision-log/SKILL.md
grep -c "粒度を点検する（ADR-0059 / ADR-0060）" skills/decision-log/SKILL.md
grep -c "「承認の昇格」第1ステップ" skills/start-work/SKILL.md
grep -c "### 7.4 粒度の判定と追記時の点検" docs/current/specs/2026-04-25-record-strengthening-design.md
```
Expected: すべて `1`

- [x] **Step 2: handoff を更新する**

`session-handoff` の update 操作を呼び、完了済みタスクと Post ラッパー消化記録を更新する。

- [x] **Step 3: master へのマージ方針を決める**

`superpowers:finishing-a-development-branch` スキルを呼び、マージ方式をユーザーと決める。

- [x] **Step 4: マージ後に retrospective を実施する**

master への merge 直後に `retrospective` スキルを起動する（CLAUDE.md の検証節）。

- [x] **Step 5: プラグイン更新をユーザーへ依頼する**

`skills/decision-log/SKILL.md` と `skills/start-work/SKILL.md` を変更したため、`/plugin marketplace update ai-driven-dev-principles` の実行をユーザーへ依頼する（AI からは実行不可。ADR-0055）。反映は available-skills 一覧の記述で確認する。
