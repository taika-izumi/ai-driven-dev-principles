# 配布先 flow 課題の取り込みと worklog パイプライン疎通 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 配布先 LoopForAlpha の flow 課題を取り込む経路を規範として成立させ、その主経路である worklog パイプライン（record → extract → skillify）を疎通させる。

**Architecture:** 3 層で進む。(1) 規範層 — 課題管理規範に「配布先からの申し送り」経路とクロスリポジトリ参照形式、close トリガーを追加する。(2) 契約層 — 中央ストアの書き側手段を契約（LF 固定）に合う形へ是正し、読み側の健全性検査を実行可能なスクリプトとして具体化する。検査自体には正負の対照を同梱し、検出力を実測で示す。(3) 流通層 — 再走査 → スキル化 → 配布先の close までを一巡させる。

**Tech Stack:** Markdown（規範・スキル文書）、Python 3（中央ストアのバイト検査。`newline="\n"` で LF を明示できるため PowerShell の `Add-Content` を使わない）、PowerShell（`scripts/sync-template.ps1`）、git。

**関連決定:** ADR-0061（取り込み経路）/ ADR-0062（スコープと順序）/ ADR-0054（ストア契約）/ ADR-0016（skills は template 対象外）

> **計画中のコードについて:** Task 4 のスクリプトは**未実行の下書き**である。写経して走らせるまで構文・挙動は一度も評価されていない（LoopForAlpha-0054）。各タスクの Step は「先に自己テストを走らせて落ちることを確認してから実装する」順序になっているので、順序を飛ばさないこと。

---

## ADR-0062 のフェーズとの対応

| ADR-0062 | 本計画の Task |
|---|---|
| Task 0（申し送り経路の規範化） | Task 1, 2 |
| Task 1（ストアの契約是正と健全性検査） | Task 3, 4, 5 |
| Task 2（`worklog-extract` 再走査） | Task 6 |
| Task 3（`worklog-skillify`） | Task 7 |
| Task 4（配布先 close） | Task 8 |

## File Structure

**変更するファイル**

| パス | 責務 | 変更内容 |
|---|---|---|
| `CONTRIBUTING.md` | 拡張手順書 | 同期指示を実挙動に合わせる（3 箇所）＋全シナリオ点検 |
| `docs/overview/folder-structure.md` | 情報分類と課題管理の規範（**template 同期対象**） | 7.2 に起票経路 2 件追加、7.3 に close トリガー、7.4 にクロス repo 参照形式 |
| `skills/worklog-record/SKILL.md` | 記録スキル | 書き側手段の記述を是正（L57） |
| `skills/worklog-record/references/store-format.md` | ストア契約の正典 | 書き側手段（L20）と読み側検証（L21）を是正・具体化 |
| `skills/worklog-extract/SKILL.md` | 走査スキル | 手順 2 を、実行可能な検査スクリプトの呼び出しへ差し替え |

**新規作成するファイル**

| パス | 責務 |
|---|---|
| `skills/worklog-extract/scripts/check-store-health.py` | 中央ストアのバイト健全性検査。正負の対照を `--self-test` として同梱 |
| `docs/records/decisions/0063-*.md` | 申し送り経路の規範化（Task 2 で採番） |
| `docs/records/decisions/0064-*.md` | ストア契約の是正と検査の具体化（Task 5 で採番） |

**変更しないもの**

- `template/` 配下は直接編集しない（`scripts/sync-template.ps1` の生成物）
- 中央ストアの既存 v1 行は書き換えない（追記専用。ADR-0049）。例外は Task 5 の CRLF 正規化のみで、これは内容不変のバイト正規化かつユーザーの明示 opt-in を要する（ADR-0054）

---

### Task 1: CONTRIBUTING.md の同期指示を実挙動に合わせる

Issue-0040 への対処。`template.manifest` の対象は 4 ファイルのみで、`skills/` は ADR-0016 により除外されている。にもかかわらず、スキルだけを変更する 3 シナリオが「テンプレート対象なので実行する」と指示している。

**Files:**
- Modify: `CONTRIBUTING.md:216`（start-work シナリオ 手順4）
- Modify: `CONTRIBUTING.md:246`（feature-block-design シナリオ 手順4）
- Modify: `CONTRIBUTING.md:281`（retrospective シナリオ 手順6）

- [ ] **Step 1: 現状を確認する**

Run:
```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions" && grep -n "テンプレート対象なので" CONTRIBUTING.md
```

Expected: 3 行が出る（216 / 246 / 281）。件数が 3 でなければ以降の期待値を見直すこと。

- [ ] **Step 2: 3 箇所を条件付きの記述へ置き換える**

`CONTRIBUTING.md:216` の該当行を次へ置き換える:

```markdown
4. **`scripts/sync-template.ps1` は実行しない**（`skills/` は ADR-0016 により template 対象外）。同一サイクルで `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` のいずれか、または空インデックス生成対象（`docs/records/decisions/README.md` / `docs/records/retrospectives/README.md` / `docs/working/issues/README.md`）を変更した場合のみ実行する
```

`CONTRIBUTING.md:246` の該当行を、上と同一文で置き換える（番号 `4.` のまま）。

`CONTRIBUTING.md:281` の該当行を、上と同一文の番号 `6.` 版で置き換える。

- [ ] **Step 3: 置換結果を実体で確認する**

Run:
```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions" && grep -c "テンプレート対象なので" CONTRIBUTING.md; grep -c "ADR-0016 により template 対象外" CONTRIBUTING.md
```

Expected: 1 行目が `0`、2 行目が `3`。

- [ ] **Step 4: 他シナリオの追従漏れを点検する**

Issue-0040 は「同種の追従漏れが他シナリオにも潜在する可能性」を指摘している。全 11 シナリオの手順を読み、`template` / `sync-template` / `template.manifest` への言及が実挙動と一致するか確認する。

Run:
```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions" && grep -n "template" CONTRIBUTING.md
```

判定基準:
- 「`template.manifest` には skills/ を追加しない」（L128 / L139 付近）→ 正しい。変更不要
- 「`docs/records/retrospectives/README.md`（template対象）」（L280 付近）→ 正しい（空インデックス生成対象）。変更不要
- 上記以外で「skills/ の変更だけで同期が要る」と読める記述があれば Step 2 と同じ形へ直す

点検結果は、見つかった件数（0 件でも）を Step 6 のコミットメッセージに書く。

- [ ] **Step 5: Issue-0040 を close する**

`docs/working/issues/flow/0040-contributing-template-sync-instruction-stale.md` の Status を `closed` に変更し、`- **Closed**: 2026-08-05` を追加、「検討状況」に実施内容を 1 行追記し、「結論」に Task 2 で作成する ADR 番号を記載する。

> **注意**: ADR 番号は Task 2 で採番する。本 Step の時点では確定していないため、Issue-0040 の close は **Task 2 の Step 5 とまとめて行う**。ここでは close しない。

- [ ] **Step 6: コミット**

```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions"
git add CONTRIBUTING.md
git commit -m "docs: CONTRIBUTING.md の同期指示を template.manifest の実態に合わせる（Issue-0040）"
```

---

### Task 2: 課題管理規範へ申し送り経路・クロス repo 参照形式・close トリガーを追加する

Issue-0041 への対処。`docs/overview/folder-structure.md` は **template 同期対象**であるため、Task 1 の完了後に着手する。

**Files:**
- Modify: `docs/overview/folder-structure.md` 7.2「起票と採番」（起票経路の列挙）
- Modify: `docs/overview/folder-structure.md` 7.3「ライフサイクル」（close トリガー）
- Modify: `docs/overview/folder-structure.md` 7.4「課題ファイルのフォーマット」（クロス repo 参照）
- Create: `docs/records/decisions/0063-distributed-issue-handover-path.md`
- Modify: `docs/records/decisions/README.md`
- Modify: `docs/working/issues/flow/0040-contributing-template-sync-instruction-stale.md`
- Modify: `docs/working/issues/flow/0041-distributed-issue-handover-path-and-cross-repo-reference.md`
- Modify: `docs/working/issues/README.md`

- [ ] **Step 1: 7.2 の起票経路に 2 件追加する**

`docs/overview/folder-structure.md` 7.2 の「起票経路は2つ:」以下のリストを、次の 4 経路へ差し替える（既存 2 経路の文言は変えない）:

```markdown
- 起票経路は4つ:
  - **振り返り由来** — retrospective スキルが抽出・分類した課題は、その場で全件起票される。課題内容は要約のみを書き、事象/原因/影響の詳細は「起票元」の振り返りファイルを正とする
  - **議論由来** — 仕様検討中の未決事項など（ADR 記述規律による分離）。課題内容を本文に直接書く
  - **worklog-extract 走査由来** — 中央ストアの横断走査で採用（`adopted`）された候補。根拠エントリ id と再発回数を本文に書き、台帳の `ref` に起票先を記録する
  - **配布先からの申し送り由来** — ガイドライン配布先の `flow/` 課題のうち、構造観察型のもの（delta 型は worklog 経路へ委ねる。ADR-0061）。起票元に配布先リポジトリ名と課題番号を明記する
```

続けて、同じ 7.2 の末尾へ次を追加する:

```markdown
- **新規起票と既存課題への追記の使い分け** — 取り込もうとする課題の一般形が既存課題に含まれている場合は、新規起票せず、その課題の「検討状況」へ 1 行追記する（形式は 7.3 の再発・進展記録に準じる）。一般形が存在しない場合のみ新規起票する。判断は起票前にインデックス（`docs/working/issues/README.md`）と中央ストアの在庫を突合して行う
```

- [ ] **Step 2: 7.3 に close トリガーを追加する**

`docs/overview/folder-structure.md` 7.3 の既存行:

```markdown
- **配布先プロジェクトの `flow/` 課題**は「ガイドライン repo へ申し送り済み（または対応済み）」で close する
```

を、次へ置き換える:

```markdown
- **配布先プロジェクトの `flow/` 課題**は「ガイドライン repo へ申し送り済み（または対応済み）」で close する。close の条件は「解決済み」ではなく「申し送り済み」である（ガイドライン側の修正はプラグイン更新で配布先へ届くため、配布先で追跡を続ける必要はない）
- **申し送りの close トリガー** — 配布先の課題を close するのは、ガイドライン repo 側に受け皿（新規課題、または既存課題への追記行）が**実在することを確認した時点**である。順序を逆にすると申し送りが蒸発する。worklog 経路（配布先の delta → 中央ストア → `worklog-extract` の採用 → ガイドライン repo での起票）で申し送られた場合も同じで、起票が済んだ時点で配布先の対応課題を close する
```

- [ ] **Step 3: 7.4 にクロスリポジトリ参照形式を追加する**

`docs/overview/folder-structure.md` 7.4 のフォーマット例の直後へ次を追加する:

```markdown
### 7.4.1 クロスリポジトリの課題参照

課題番号はリポジトリ内で一意に採番されるため、`Issue-NNNN` という無修飾の表記はリポジトリをまたぐと別の課題を指す。**他リポジトリの課題を参照するときは必ずリポジトリ名で修飾する**:

- 書式: `<repo>#Issue-NNNN`（例: `LoopForAlpha#Issue-0069`）
- 同一リポジトリ内の参照は従来どおり `Issue-NNNN` でよい
- worklog 台帳（`processed.jsonl`）の `ref` フィールドも同様に、リポジトリ名を含む形で記録する（例: `MakeAiInstructions:docs/working/issues/flow/0034-....md`）

無修飾の表記が実際に衝突した例: LoopForAlpha の `flow/0034`（編集ツールが不可視文字のエスケープ表記を正規化する）と、本リポジトリの `flow/0034`（非コード成果物の確定前レビュー工程がない）は、番号が同じで内容の異なる別課題である。
```

- [ ] **Step 4: ADR-0063 を作成する**

`docs/records/decisions/0063-distributed-issue-handover-path.md` を作成する。粒度（ADR-0059）の観点で、本 ADR が答える問いは「配布先から申し送られた課題を、ガイドライン repo はどう起票し、配布先はいつ close するか」の 1 つとする。

```markdown
# ADR-0063: 配布先からの申し送りを起票経路として定義し、受け皿の実在確認を close トリガーとする

- **Status**: Proposed
- **Date**: 2026-08-05

## Context

`docs/overview/folder-structure.md` 7.3 は「配布先プロジェクトの `flow/` 課題は、ガイドライン repo へ申し送り済み（または対応済み）で close する」と定めており、この規範は本リポジトリと配布先の両方に同一文で存在する。しかし一度も適用されておらず、LoopForAlpha の flow 課題は 21 件すべてが open のまま（最古 2026-07-11）だった。原因は規律違反ではなく、3 点の未定義である（Issue-0041）。

(a) 7.2 が定める起票経路は「振り返り由来」「議論由来」の 2 つのみで、実運用にある「worklog-extract 走査由来」「配布先からの申し送り由来」が無い。取り込み時に新規起票するか既存課題へ追記するかの基準も無い。
(b) 課題番号はリポジトリ内で一意のため、無修飾の `Issue-NNNN` はリポジトリをまたぐと別の課題を指す。LoopForAlpha `flow/0034` と本リポジトリ `flow/0034` は既に別内容で衝突している。worklog 台帳の `ref` も無修飾の相対パスで記録されている。
(c) 7.3 は「課題 → 課題」の申し送りを想定しているが、実際に起きたのは「worklog エントリ → ガイドライン repo の課題」であり、この経路には配布先を close する契機が誰にも割り当てられていない。ADR-0061 で delta 型を worklog 経路へ委ねると決めたため、これが主経路になる。

## Considered Alternatives

1. **close を「ガイドライン側で解決済み」に変える** — 追跡は厳密になるが、配布先が解決を待って open を保持することになり、プラグイン更新で修正が自動的に届く実態と合わない。かつ配布先が増えるほど追跡コストが増える
2. **配布先の課題番号をガイドライン repo でも引き継ぐ** — 参照の衝突は解決するが、採番規則（リポジトリ内通し連番）を壊し、配布先が 2 つ以上になると成立しない
3. **起票経路を 4 つに拡張し、参照はリポジトリ名で修飾し、受け皿の実在確認を close トリガーとする** — 採用

## Decision

- 7.2 の起票経路を 4 つとする（振り返り由来 / 議論由来 / worklog-extract 走査由来 / 配布先からの申し送り由来）。取り込み時、一般形が既存課題に含まれるなら新規起票せず「検討状況」へ追記し、無い場合のみ新規起票する
- 他リポジトリの課題参照は `<repo>#Issue-NNNN` で修飾する。worklog 台帳の `ref` にもリポジトリ名を含める
- 配布先の close トリガーは「ガイドライン repo 側の受け皿が実在することを確認した時点」とする。worklog 経路で申し送られた場合も、起票が済んだ時点で配布先の対応課題を close する

## Consequences

- 配布先の `flow/` セクションがバックログとして機能するようになる。現状は恒久的な駐車場になっている
- worklog 経路で申し送られた課題にも close の契機が生まれる。ADR-0061 が定める主経路が閉じる
- 取り込み前にインデックスと中央ストアの在庫を突合する手順が加わるため、取り込みの初動コストが増える。ただし重複起票の手戻りより小さい（2026-08-05 の検討では、突合を後回しにしたため配布先 21 件を精読する無駄が発生した）
- `<repo>#Issue-NNNN` 形式は既存の記述には遡及適用しない。過去の無修飾参照は残るため、読み手は文脈で判断する必要がある
```

- [ ] **Step 5: インデックスと課題ファイルを更新する**

`docs/records/decisions/README.md` の末尾へ追加:

```markdown
| [0063](0063-distributed-issue-handover-path.md) | 配布先からの申し送りを起票経路として定義し、受け皿の実在確認を close トリガーとする | Proposed | 2026-08-05 |
```

`docs/working/issues/flow/0040-contributing-template-sync-instruction-stale.md`:
- Status を `closed` へ、`- **Closed**: 2026-08-05` を追加
- 「検討状況」へ: `- 2026-08-05: 3 シナリオ（start-work / feature-block-design / retrospective）の「テンプレート対象なので実行する」を、template.manifest の実態に合わせた条件付き記述へ置換。他シナリオの追従漏れも点検した`
- 「結論」へ: `Task 1 で対処済み。関連する規範整備は ADR-0063。`

`docs/working/issues/flow/0041-distributed-issue-handover-path-and-cross-repo-reference.md`:
- Status を `closed` へ、`- **Closed**: 2026-08-05` を追加
- 「結論」へ: `ADR-0063`

`docs/working/issues/README.md` の 0040 / 0041 の行の Status を `closed` へ更新する。

- [ ] **Step 6: template を同期する**

`docs/overview/folder-structure.md` を変更したため、今回は同期対象である。

Run:
```powershell
cd "D:/Dev/002_AiDev/MakeAiInstructions"; pwsh scripts/sync-template.ps1
```

Expected: `[sync-template] Done. 7 files synced to template/` と表示され、`✓ docs/overview/folder-structure.md` の行が含まれる。

- [ ] **Step 7: 同期結果を実体で確認する**

Run:
```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions" && grep -c "申し送りの close トリガー" template/docs/overview/folder-structure.md && grep -c "7.4.1" template/docs/overview/folder-structure.md
```

Expected: 両方 `1`。

- [ ] **Step 8: コミット**

```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions"
git add docs/overview/folder-structure.md template/ docs/records/decisions/0063-distributed-issue-handover-path.md docs/records/decisions/README.md docs/working/issues/
git commit -m "adr: 0063 - 配布先からの申し送り経路とクロス repo 参照形式を規範化する（Issue-0040/0041 close）"
```

---

### Task 3: 中央ストアの書き側手段を契約に合う形へ是正する

LoopForAlpha#Issue-0050 への対処。契約は「LF 固定」だが、契約を満たす手段として示された `Add-Content -Encoding utf8NoBOM` は Windows で CRLF を書く。同じ罠は本リポジトリの `scripts/sync-template.ps1:156-159` で既に解決済みで（ADR-0033、`[System.IO.File]::WriteAllText` を使用）、その解法を持ち込む。

**Files:**
- Modify: `skills/worklog-record/references/store-format.md:20`
- Modify: `skills/worklog-record/SKILL.md:57`

- [ ] **Step 1: 現状の記述を確認する**

Run:
```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions" && grep -n "Add-Content" skills/worklog-record/SKILL.md skills/worklog-record/references/store-format.md
```

Expected: 2 行（`SKILL.md:57` と `store-format.md:20`）。

- [ ] **Step 2: store-format.md の書き側手段を差し替える**

`skills/worklog-record/references/store-format.md:20` の行:

```markdown
- **書き側手段**: PowerShell は `Add-Content -Encoding utf8NoBOM`（改行は LF を明示）、POSIX シェルは `>>` リダイレクト。`projects.json` の全体書き換え（upsert）も同エンコーディングで保存する
```

を、次へ置き換える:

```markdown
- **書き側手段**: 行終端を明示できる API を使う。`Add-Content` は使わないこと — `-Encoding` はエンコーディングだけを制御し行終端子は制御しないため、Windows では CRLF を書き、契約に違反する（実測。同じ罠は `scripts/sync-template.ps1` が ADR-0033 で解決済み）
  - Python（推奨。バイト単位で確実）: `open(path, "a", encoding="utf-8", newline="\n")`
  - PowerShell: `[System.IO.File]::AppendAllText($path, $line + "`n", [System.Text.UTF8Encoding]::new($false))`
  - POSIX シェル: `>>` リダイレクト
  - `projects.json` の全体書き換え（upsert）も同じ規律で保存する（Python なら `open(path, "w", encoding="utf-8", newline="\n")`）
```

- [ ] **Step 3: SKILL.md の記述を差し替える**

`skills/worklog-record/SKILL.md:57` の行:

```markdown
   - `<folderName>/log.jsonl` へ1行 append（UTF-8・BOM なし・LF 固定。PowerShell は `Add-Content -Encoding utf8NoBOM`、POSIX は `>>`。ADR-0054 / `references/store-format.md` のエンコーディング契約に従う）
```

を、次へ置き換える:

```markdown
   - `<folderName>/log.jsonl` へ1行 append（UTF-8・BOM なし・LF 固定）。**`Add-Content` は使わない**（Windows で CRLF を書き契約に違反する）。Python は `open(path, "a", encoding="utf-8", newline="\n")`、POSIX シェルは `>>`。手段の一覧と根拠は `references/store-format.md` の「エンコーディング・改行コード」を参照（ADR-0054）
```

- [ ] **Step 4: 置換結果を実体で確認する**

Run:
```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions" && grep -c "Add-Content -Encoding utf8NoBOM" skills/worklog-record/SKILL.md skills/worklog-record/references/store-format.md; grep -c "newline=" skills/worklog-record/SKILL.md skills/worklog-record/references/store-format.md
```

Expected: 前半 2 行がいずれも `0`、後半 2 行がいずれも `1` 以上。

- [ ] **Step 5: コミット**

```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions"
git add skills/worklog-record/
git commit -m "fix: 中央ストアの書き側手段を行終端を明示できる API へ是正する（LoopForAlpha#Issue-0050）"
```

---

### Task 4: 読み側健全性検査を実行可能なスクリプトにし、正負の対照で検出力を実測する

Issue-0032 への対処。現行の `worklog-extract` 手順 2 は「BOM・CRLF・非 UTF-8 を検出して停止する」と規定するだけで検出手段が無く、実際に CRLF 5 行を素通りさせている。あわせて LoopForAlpha#Issue-0084（検出器自身の検出力が確かめられない）への先行対処として、**正の対照（既知の欠陥で発火する）と負の対照（正常を誤検出しない）を検査へ同梱する**。

**Files:**
- Create: `skills/worklog-extract/scripts/check-store-health.py`
- Modify: `skills/worklog-extract/SKILL.md`（手順 2）
- Modify: `skills/worklog-record/references/store-format.md:21`（読み側検証）

- [ ] **Step 1: 自己テスト（正負の対照）を先に走らせて落ちることを確認する**

スクリプトはまだ存在しない。落ちることを確認してから実装する。

Run:
```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions" && python skills/worklog-extract/scripts/check-store-health.py --self-test
```

Expected: FAIL。`can't open file ... check-store-health.py: [Errno 2] No such file or directory`

- [ ] **Step 2: スクリプトを実装する**

`skills/worklog-extract/scripts/check-store-health.py` を作成する:

```python
#!/usr/bin/env python3
"""中央ストアのバイト健全性を検査する（ADR-0054 の契約: UTF-8 / BOM なし / LF 固定 / 全行 JSON パース可能）。

grep 系では検出できないため、バイト列を直接数える。
--self-test は検出器自身の検出力を確かめる（正の対照 = 既知の欠陥で発火するか、
負の対照 = 正常な入力を誤検出しないか）。検査が緑であることの意味を保つために必須。
"""
import argparse
import json
import os
import sys
import tempfile

TARGET_SUFFIXES = (".jsonl", ".json")


def check_file(path):
    """1 ファイルを検査し、違反メッセージのリストを返す（空なら健全）。"""
    violations = []
    with open(path, "rb") as f:
        raw = f.read()

    if raw[:3] == b"\xef\xbb\xbf":
        violations.append("BOM が付いている")

    cr = raw.count(b"\r")
    if cr:
        violations.append(f"CR を {cr} 個含む（LF 固定契約に違反）")

    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as e:
        violations.append(f"UTF-8 として復号できない: {e}")
        return violations

    if path.endswith(".jsonl"):
        for i, line in enumerate(text.split("\n"), 1):
            if not line.strip():
                continue
            try:
                json.loads(line)
            except json.JSONDecodeError as e:
                violations.append(f"{i} 行目が JSON としてパースできない: {e}")
    else:
        try:
            json.loads(text)
        except json.JSONDecodeError as e:
            violations.append(f"JSON としてパースできない: {e}")

    return violations


def collect_targets(root):
    targets = []
    for dirpath, _dirnames, filenames in os.walk(root):
        for name in sorted(filenames):
            if name.endswith(TARGET_SUFFIXES):
                targets.append(os.path.join(dirpath, name))
    return sorted(targets)


def run_check(root):
    """ストア全体を検査する。違反があれば 1、無ければ 0 を返す。"""
    targets = collect_targets(root)
    if not targets:
        print(f"[check-store-health] 対象ファイルが見つからない: {root}")
        return 1

    total = 0
    for path in targets:
        violations = check_file(path)
        rel = os.path.relpath(path, root)
        if violations:
            total += len(violations)
            for v in violations:
                print(f"  NG {rel}: {v}")
        else:
            print(f"  OK {rel}")

    if total:
        print(f"[check-store-health] 違反 {total} 件。走査を中止する（ADR-0054: silent tolerance はしない）")
        return 1
    print(f"[check-store-health] {len(targets)} ファイルすべて健全")
    return 0


def self_test():
    """検出器の検出力を確かめる。正の対照 4 件と負の対照 1 件。"""
    cases = [
        ("CRLF", b'{"a":1}\r\n{"a":2}\n', "CR を"),
        ("BOM", b'\xef\xbb\xbf{"a":1}\n', "BOM"),
        ("非 UTF-8", b'{"a":"\xff\xfe"}\n', "UTF-8 として復号できない"),
        ("壊れた JSON", b'{"a":1}\n{"a":\n', "JSON としてパースできない"),
    ]
    failures = []

    with tempfile.TemporaryDirectory() as d:
        # 正の対照: 既知の欠陥それぞれで発火するか
        for label, payload, expected_fragment in cases:
            p = os.path.join(d, f"positive_{label}.jsonl")
            with open(p, "wb") as f:
                f.write(payload)
            got = check_file(p)
            hit = any(expected_fragment in v for v in got)
            print(f"  正の対照 [{label}]: {'発火' if hit else '未発火'} -> {got}")
            if not hit:
                failures.append(f"正の対照 [{label}] が発火しなかった")

        # 負の対照: 正常な入力を誤検出しないか
        p = os.path.join(d, "negative_clean.jsonl")
        with open(p, "w", encoding="utf-8", newline="\n") as f:
            f.write(json.dumps({"v": 2, "id": "X-2026-01-01-01"}, ensure_ascii=False) + "\n")
            f.write(json.dumps({"v": 2, "id": "X-2026-01-01-02", "t": "日本語"}, ensure_ascii=False) + "\n")
        got = check_file(p)
        print(f"  負の対照 [clean]: {'誤検出なし' if not got else '誤検出'} -> {got}")
        if got:
            failures.append(f"負の対照が誤検出した: {got}")

    if failures:
        print("[self-test] FAIL")
        for f_ in failures:
            print(f"  - {f_}")
        return 1
    print("[self-test] PASS（正の対照 4 件が発火、負の対照 1 件は誤検出なし）")
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=os.path.join(os.path.expanduser("~"), ".ai-dev-worklog"))
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        return self_test()
    return run_check(args.root)


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 3: 自己テストを走らせて通ることを確認する**

Run:
```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions" && python skills/worklog-extract/scripts/check-store-health.py --self-test
```

Expected: 正の対照 4 件がすべて「発火」、負の対照が「誤検出なし」、最終行が `[self-test] PASS（正の対照 4 件が発火、負の対照 1 件は誤検出なし）`。終了コード 0。

- [ ] **Step 4: 実ストアに当て、既知の欠陥を検出することを確認する**

これが検出器の実測である。現在の中央ストアには `LoopForAlpha/log.jsonl` に CR が 5 個ある。

Run:
```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions" && python skills/worklog-extract/scripts/check-store-health.py; echo "exit=$?"
```

Expected: `NG LoopForAlpha/log.jsonl: CR を 5 個含む（LF 固定契約に違反）` が出力され、`MakeAiInstructions/log.jsonl` / `processed.jsonl` / `projects.json` は `OK`。最終行が `[check-store-health] 違反 1 件。走査を中止する（...）`、`exit=1`。

> 期待値が合わない場合、CR の個数が Task 3 以降の追記で変わっている可能性がある。個数だけが違う場合は実測値を正とし、Task 5 の期待値も合わせて更新すること。

- [ ] **Step 5: worklog-extract の手順 2 を、スクリプト呼び出しへ差し替える**

`skills/worklog-extract/SKILL.md` の手順 2 冒頭「走査に先立ち、全 `log.jsonl` / `processed.jsonl` のエンコーディング健全性（UTF-8・BOM なし・LF）を検証する。」を、次へ置き換える:

```markdown
走査に先立ち、`scripts/check-store-health.py` を実行してストアのバイト健全性（UTF-8・BOM なし・LF 固定・全行 JSON パース可能）を検証する。実行は `python <skill-dir>/scripts/check-store-health.py` で、終了コード 0 が健全、1 が違反あり。grep 系では CR を検出できないためスクリプトを使うこと。
```

同じ手順 2 の末尾へ次を追加する:

```markdown
   検査スクリプト自体を変更したときは `--self-test` を実行し、正の対照 4 件が発火し負の対照が誤検出しないことを確認してから使うこと（検査が緑であることの意味を保つため。LoopForAlpha#Issue-0084）
```

- [ ] **Step 6: store-format.md の読み側検証を具体化する**

`skills/worklog-record/references/store-format.md:21` の行:

```markdown
- **読み側検証**: `worklog-extract` は走査直前に BOM・CRLF・非 UTF-8 を検出し、あれば報告して停止する（silent tolerance はしない。既存行の正規化は内容不変のバイト正規化に限り、ユーザーの明示 opt-in でのみ実行）
```

を、次へ置き換える:

```markdown
- **読み側検証**: `worklog-extract` は走査直前に `skills/worklog-extract/scripts/check-store-health.py` を実行し、BOM・CR・非 UTF-8・JSON パース不能行を検出する。1 件でもあれば報告して停止する（silent tolerance はしない）。既存行の正規化は内容不変のバイト正規化に限り、ユーザーの明示 opt-in でのみ実行する。検査スクリプトは正負の対照を `--self-test` として同梱しており、スクリプトを変更したら対照を走らせてから使う（LoopForAlpha#Issue-0084）
```

- [ ] **Step 7: Issue-0032 を close する**

`docs/working/issues/system/0032-worklog-extract-store-validation-detection-means.md` の Status を `closed`、`- **Closed**: 2026-08-05` を追加、「結論」に `ADR-0064`（Task 5 で作成）を記載する。

> **注意**: ADR-0064 は Task 5 で採番・作成する。本 Step は **Task 5 の Step 4 とまとめて行う**。ここでは close しない。

- [ ] **Step 8: コミット**

```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions"
git add skills/worklog-extract/ skills/worklog-record/references/store-format.md
git commit -m "feat: 中央ストアの健全性検査を実行可能にし、正負の対照を同梱する（Issue-0032 / LoopForAlpha#Issue-0084）"
```

---

### Task 5: 既存の CRLF 混入を正規化し、ADR-0064 を作成する

ADR-0054 は「既存行の正規化は内容不変のバイト正規化に限り、ユーザーの明示 opt-in でのみ実行」と定める。**このタスクはユーザーの承認を得てから実行すること。**

**Files:**
- Modify: `~/.ai-dev-worklog/LoopForAlpha/log.jsonl`（リポジトリ外・git 管理外）
- Create: `docs/records/decisions/0064-worklog-store-write-api-and-health-check.md`
- Modify: `docs/records/decisions/README.md`
- Modify: `docs/working/issues/system/0032-worklog-extract-store-validation-detection-means.md`
- Modify: `docs/working/issues/README.md`

- [ ] **Step 1: ユーザーへ opt-in を求める**

正規化の内容（対象ファイル・CR の個数・内容が不変であること・バックアップ先）を提示し、実行の可否を確認する。**承認が得られるまで Step 2 へ進まないこと。**

- [ ] **Step 2: バックアップを取り、CR を除去する**

```bash
cd ~/.ai-dev-worklog && cp LoopForAlpha/log.jsonl LoopForAlpha/log.jsonl.bak-before-crlf-normalize && python -c "
import json
p='LoopForAlpha/log.jsonl'
raw=open(p,'rb').read()
before=[json.loads(l) for l in raw.split(b'\n') if l.strip()]
fixed=raw.replace(b'\r\n', b'\n').replace(b'\r', b'\n')
open(p,'wb').write(fixed)
after=[json.loads(l) for l in fixed.split(b'\n') if l.strip()]
print('CR before:', raw.count(b'\r'), '-> after:', fixed.count(b'\r'))
print('entries before:', len(before), '-> after:', len(after))
print('内容不変:', before == after)
"
```

Expected: `CR before: 5 -> after: 0`、`entries before: 106 -> after: 106`（Task 3 以降の追記があれば増えている）、`内容不変: True`。**`内容不変: False` なら直ちに中止し、バックアップから復元してユーザーへ報告すること。**

- [ ] **Step 3: 検査スクリプトで健全化を確認する**

Run:
```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions" && python skills/worklog-extract/scripts/check-store-health.py; echo "exit=$?"
```

Expected: すべて `OK`、`[check-store-health] 4 ファイルすべて健全`、`exit=0`。

> `.bak-before-crlf-normalize` は `.jsonl` / `.json` で終わらないため検査対象に入らない。もし対象に入って NG になる場合は、バックアップを `~/.ai-dev-worklog` の外へ移すこと。

- [ ] **Step 4: ADR-0064 を作成し、Issue-0032 を close する**

`docs/records/decisions/0064-worklog-store-write-api-and-health-check.md` を作成する。本 ADR が答える問いは「中央ストアの LF 固定契約を、どの手段で守り、どう検証するか」の 1 つとする。

```markdown
# ADR-0064: 中央ストアの書き込みは行終端を明示できる API に限定し、健全性検査は正負の対照を同梱する

- **Status**: Proposed
- **Date**: 2026-08-05

## Context

中央ストアは ADR-0054 で「UTF-8・BOM なし・LF 固定」と契約されている。しかし契約を満たす手段として示されていた `Add-Content -Encoding utf8NoBOM` は、`-Encoding` がエンコーディングのみを制御し行終端子を制御しないため、Windows では CRLF を書く。**契約と、契約を満たすために示された手段が矛盾していた**（LoopForAlpha#Issue-0050）。

実測では `LoopForAlpha/log.jsonl` に CR が混入しており、その数は起票時（2026-07-27）の 3 行から 2026-08-05 時点で 5 行へ増えていた。累積している。

読み側については `worklog-extract` 手順 2 が「BOM・CRLF・非 UTF-8 を検出して報告・停止する」と規定していたが、**具体的な検出手段が定義されていなかった**（Issue-0032）。結果としてこの検査は 2026-07-31 の走査で CR を素通りさせている。規範として書かれた検査が、一度も発火を確かめられていない状態だった。これは LoopForAlpha#Issue-0084（検出器自身の検出力が確かめられず「常に 0 件を返す検査」が生まれる）が主張する事象そのものである。

## Considered Alternatives

1. **契約側を緩め、行終端を問わないことにする** — 安価だが、`references/store-format.md` の「LF 固定」を信じて素朴な行分割を実装した後続が静かに壊れる。読み側を universal newlines に統一する規律も別途要る
2. **書き側手段だけを直す** — 入口は塞がるが、既存の混入と将来の別経路（別ツール・別 OS）を拾えない
3. **書き側の手段を限定し、読み側に実行可能な検査を置き、その検査に正負の対照を同梱する** — 採用

## Decision

- **書き側**: 行終端を明示できる API に限定する。`Add-Content` は使わない。Python は `open(path, "a", encoding="utf-8", newline="\n")`、PowerShell は `[System.IO.File]::AppendAllText` と `UTF8Encoding($false)`、POSIX シェルは `>>`
- **読み側**: `skills/worklog-extract/scripts/check-store-health.py` を実行可能な検査として置く。BOM・CR・非 UTF-8・JSON パース不能行を検出し、1 件でもあれば終了コード 1 で走査を止める。バイト列を直接数える（grep 系では CR を検出できない）
- **検出器の検出力**: 検査へ `--self-test` を同梱する。既知の欠陥を含む入力 4 種で発火すること（正の対照）と、正常な入力を誤検出しないこと（負の対照）を確かめる。検査スクリプトを変更したら対照を走らせてから使う
- 既存の CR 混入は、内容不変のバイト正規化としてユーザーの明示 opt-in のもとで除去する（ADR-0054 の規定どおり）

## Consequences

- 契約と手段が一致し、以後の混入が止まる。既存の混入も 1 度だけの正規化で解消する
- **検査が緑であることに意味が戻る。** 正負の対照が無い間、`worklog-extract` の健全性検査は「実行され、緑を返し、しかし何も固定していない検査」だった
- 検査スクリプトが Python に依存する。PowerShell を主とする本リポジトリの慣行から外れるが、バイト単位の読み書きと行終端の明示が確実である点を優先した
- 対照の同梱は検査を書くコストを上げる。この規律を他の検査へどこまで一般化するかは本 ADR では決めていない（LoopForAlpha#Issue-0084 として `worklog-extract` の再走査経由で上がる見込み）
```

`docs/records/decisions/README.md` の末尾へ追加:

```markdown
| [0064](0064-worklog-store-write-api-and-health-check.md) | 中央ストアの書き込みは行終端を明示できる API に限定し、健全性検査は正負の対照を同梱する | Proposed | 2026-08-05 |
```

`docs/working/issues/system/0032-worklog-extract-store-validation-detection-means.md` の Status を `closed`、`- **Closed**: 2026-08-05` を追加、「結論」に `ADR-0064` を記載。`docs/working/issues/README.md` の 0032 行の Status も `closed` へ。

- [ ] **Step 5: コミット**

```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions"
git add docs/records/decisions/ docs/working/issues/
git commit -m "adr: 0064 - 中央ストアの書き込み API を限定し健全性検査に正負の対照を同梱する（Issue-0032 close）"
```

---

### Task 6: worklog-extract を再走査する

**Files:** なし（スキル実行。台帳 `~/.ai-dev-worklog/processed.jsonl` が更新される）

- [ ] **Step 1: 前提を確認する**

Run:
```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions" && python skills/worklog-extract/scripts/check-store-health.py; echo "exit=$?"
```

Expected: `exit=0`。1 なら Task 5 が未完了なので戻ること。

- [ ] **Step 2: `worklog-extract` スキルを起動する**

`Skill` ツールで `ai-driven-dev-principles:worklog-extract` を呼び、スキルの手順に従う。走査対象は未処理エントリ（前回走査 2026-07-31 以降の分）と `deferred` 14 件の再浮上判定。

- [ ] **Step 3: 候補提示とユーザー採否**

スキルの手順 7〜8 に従い、ランク付き候補をユーザーへ提示し、採否を台帳へ反映する。

**確認すること**: LoopForAlpha#Issue-0084 の一般核（`LoopForAlpha-2026-08-04-07`、`scope: general-candidate`、title「検出器の検出力を対照で確かめる」）が候補に上がること。上がらない場合、その理由（既存スキル重複排除で除外された等）を記録する。Task 4 で対照の規律を `worklog-extract` へ限定的に入れているため、重複判定が働く可能性がある。

- [ ] **Step 4: 台帳の健全性を確認する**

Run:
```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions" && python skills/worklog-extract/scripts/check-store-health.py; echo "exit=$?"
```

Expected: `exit=0`。台帳追記が Task 3 の規律どおり LF で書かれたことの確認になる。

---

### Task 7: worklog-skillify で採用済み候補を成果物化する

2026-07-31 走査で `adopted` となったまま 3 サイクル滞留している Issue-0033 / 0034 を成果物化する。

**Files:**
- Modify: `skills/` 配下（`worklog-skillify` が `writing-skills` へ委譲して決定する。スコープにより配置先が変わる）
- Modify: `docs/working/issues/flow/0033-subagent-dispatch-prompt-boilerplate.md`
- Modify: `docs/working/issues/flow/0034-independent-review-with-proof-for-non-code-artifacts.md`
- Modify: `docs/working/issues/README.md`

- [ ] **Step 1: 取り込む配布先の証拠を、既存課題へ追記する**

ADR-0063 が定める「一般形が既存課題に含まれるなら追記」に従う。新規起票はしない。

`docs/working/issues/flow/0033-subagent-dispatch-prompt-boilerplate.md` の「検討状況」へ追記:

```markdown
- 2026-08-05: 配布先からの申し送り（ADR-0061 / ADR-0063）。`LoopForAlpha#Issue-0069`（独立レビューを同一ワーキングツリーで並列に走らせるとミューテーションが相互汚染し測定の意味が失われる）が本課題の定型項目リスト項目 8 に該当。3 観点すべてが独立に事象を報告し、2026-08-05 に再発条件を再現している（汚染の不在を事後に証明する手段が無い）。同じく `LoopForAlpha#Issue-0063`（検証用の足場がプロセス名で子プロセスを一括停止しエージェント自身を落とした）は項目 7 と隣接する
```

`docs/working/issues/flow/0034-independent-review-with-proof-for-non-code-artifacts.md` の「検討状況」へ追記:

```markdown
- 2026-08-05: 配布先からの申し送り（ADR-0061 / ADR-0063）。`LoopForAlpha#Issue-0054`（実装計画の成果物に足場コードを含めるべきかが未定義）は本課題の代表エントリ `LoopForAlpha-2026-07-28-11` と同一事象であり、独立レビューが計画中のテストコードを写経して実行し 1 件も動かないことを検出した回のフォールアウトである。誤りの種類による計画の効き目の反転（局所的・機械的な誤りは直接実装のほうが安い / 構造的な誤りは計画でしか拾えない）の分析が配布先の課題本文にある
```

- [ ] **Step 2: 追記結果を実体で確認する**

Run:
```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions" && grep -c "LoopForAlpha#Issue-0069" docs/working/issues/flow/0033-subagent-dispatch-prompt-boilerplate.md; grep -c "LoopForAlpha#Issue-0054" docs/working/issues/flow/0034-independent-review-with-proof-for-non-code-artifacts.md
```

Expected: 両方 `1`。

- [ ] **Step 3: `worklog-skillify` を起動する**

`Skill` ツールで `ai-driven-dev-principles:worklog-skillify` を呼ぶ。対象は Issue-0033（サブエージェント委譲の起動プロンプト定型項目）と Issue-0034（非コード成果物の確定前の実証を課した独立レビュー）。スキルの手順に従い、スコープ（汎用 / プロジェクト固有 / 固有ルール）で配置先を振り分ける。

**入力として渡すもと**: Issue-0033 の定型項目 10 件（本文に列挙済み）、Issue-0034 の運用ヒント（独立レビューの観点は最低 3 つ、モデルは前工程と変える）、および Step 1 で追記した配布先の証拠。

- [ ] **Step 4: 課題を close する**

成果物が作成できたら、Issue-0033 / 0034 の Status を `closed` にし、`- **Closed**: 2026-08-05` を追加、「結論」に成果物への参照と ADR 番号を記載する。台帳へ `skillified` レコードを追記する（`ref` は ADR-0063 に従いリポジトリ名を含む形式）。`docs/working/issues/README.md` の該当行も更新する。

- [ ] **Step 5: コミット**

```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions"
git add skills/ docs/working/issues/
git commit -m "feat: 採用済み worklog 候補を成果物化する（Issue-0033/0034 close）"
```

---

### Task 8: LoopForAlpha 側 flow 課題の close 判定と一括処理

ADR-0061 / ADR-0063 の初回適用。**受け皿が実在することを確認してから close する。**

**Files:**
- Modify: `D:/Dev/001_Trade/LoopForAlpha/docs/working/issues/flow/*.md`（close 対象のみ）
- Modify: `D:/Dev/001_Trade/LoopForAlpha/docs/working/issues/README.md`

- [ ] **Step 1: 21 件を振り分ける**

各課題の「振り分け判定」フィールドを読み、delta 型 / 構造観察型 / 判定なし に分類する。判定なしのものはその場で判定する。

Run:
```bash
cd "D:/Dev/001_Trade/LoopForAlpha/docs/working/issues/flow" && grep -l "振り分け判定" *.md | wc -l && grep -H "振り分け判定" *.md
```

Expected: 判定フィールドを持つのは 2026-08-05 起票の 4 件（0084 / 0085 / 0086 / 0087）。残り 17 件は判定なしで、取り込み時に判定する。

- [ ] **Step 2: 受け皿の実在を確認する**

close 候補ごとに、本リポジトリ側の受け皿を突合する。

| 配布先 | 受け皿 | 種別 |
|---|---|---|
| `LoopForAlpha#Issue-0069` | 本 repo Issue-0033（Task 7 Step 1 で追記済み） | 既存課題への追記 |
| `LoopForAlpha#Issue-0063` | 本 repo Issue-0033（同上） | 既存課題への追記 |
| `LoopForAlpha#Issue-0054` | 本 repo Issue-0034（Task 7 Step 1 で追記済み） | 既存課題への追記 |
| `LoopForAlpha#Issue-0050` | ADR-0064 / 本 repo Issue-0032（Task 5 で close） | 対応済み |
| `LoopForAlpha#Issue-0084` | Task 6 の走査結果（採用されれば起票、されなければ据え置き） | 走査由来 |

Run:
```bash
cd "D:/Dev/002_AiDev/MakeAiInstructions" && grep -c "LoopForAlpha#Issue-0069" docs/working/issues/flow/0033-subagent-dispatch-prompt-boilerplate.md && grep -c "LoopForAlpha#Issue-0054" docs/working/issues/flow/0034-independent-review-with-proof-for-non-code-artifacts.md && grep -n "0032" docs/working/issues/README.md
```

Expected: 前 2 つが `1`、Issue-0032 の行の Status が `closed`。**いずれかが満たされない受け皿については、対応する配布先課題を close しない。**

- [ ] **Step 3: 受け皿が確認できたものを close する**

各対象ファイルについて:
- Status を `closed` へ、`- **Closed**: 2026-08-05` を追加
- 「検討状況」へ 1 行追記: `- 2026-08-05: ガイドライン repo へ申し送り済み（受け皿: <repo>#Issue-NNNN または ADR-NNNN）。close の条件は解決済みではなく申し送り済み（folder-structure.md 7.3 / ai-driven-dev-principles#ADR-0063）`
- 「結論」に受け皿への参照を記載

`D:/Dev/001_Trade/LoopForAlpha/docs/working/issues/README.md` の flow セクションの該当行の Status を `closed` へ更新する。

- [ ] **Step 4: close しなかったものの理由を残す**

構造観察型で本サイクルでは取り込まないもの（`LoopForAlpha#Issue-0085` / `0086` / `0087` / `0042` / `0008` / `0013` など）は **open のまま残す**。ADR-0062 が次サイクルへ送ると決めているため、各課題の「検討状況」へ 1 行だけ追記する:

```markdown
- 2026-08-05: ガイドライン repo（ai-driven-dev-principles）で構造観察型として分類。次サイクルで取り込み予定（ai-driven-dev-principles#ADR-0061 / #ADR-0062）。本サイクルでは申し送っていないため open のまま
```

- [ ] **Step 5: close 件数と残件を実体で確認する**

Run:
```bash
cd "D:/Dev/001_Trade/LoopForAlpha" && grep -c "| open |" docs/working/issues/README.md && grep -c "| closed |" docs/working/issues/README.md
```

Expected: flow セクションの open 件数が 21 から減っていること。実際の数は Step 2 の受け皿確認結果に依存するため、**Step 3 で close した件数と一致することを目視で突合する**（両セクション合計のカウントである点に注意。system セクションの数は変わらない）。

- [ ] **Step 6: コミット**

```bash
cd "D:/Dev/001_Trade/LoopForAlpha"
git add docs/working/issues/
git commit -m "chore: ガイドライン repo へ申し送り済みの flow 課題を close する"
```

---

## 完了後の処理

- [ ] ADR-0063 / ADR-0064 を Accepted へ昇格する（`decision-log` の「承認の昇格」。第 1 ステップの粒度点検を行うこと）
- [ ] `superpowers:finishing-a-development-branch` で master への統合方法を決める
- [ ] master マージ直後に `retrospective` を起動する（CLAUDE.md の必須手順）
- [ ] `session-handoff` の update / finalize を Post ラッパーの手順どおり消し込む

## Self-Review 結果

**1. スコープ被覆**: ADR-0062 が定めた Task 0〜4 のすべてに対応する Task がある（上の対応表）。Issue-0040 / 0041 / 0032 / 0033 / 0034 と `LoopForAlpha#Issue-0050` に着手する Task がそれぞれ存在する。

**2. プレースホルダ走査**: 「TBD」「後で」「適切に」「Task N と同様」は使っていない。Task 4 のスクリプトは全文を記載した。Task 7 の成果物は `worklog-skillify` が `writing-skills` へ委譲して決めるため本計画では確定できないが、これは委譲先スキルの責務であり、入力（Issue-0033 の定型項目 10 件・Issue-0034 の運用ヒント）は明示した。

**3. 期待値と編集内容の突合**（CLAUDE.md の検証規範）:
- Task 1 Step 3 の期待値 `0` / `3` は、Step 2 が 3 箇所すべてを同一文で置換することと整合する
- Task 2 Step 6 の期待値「7 files synced」は、`template.manifest` の 4 件 + 空インデックス生成 3 件 = 7 と整合する
- Task 3 Step 4 の期待値は、Step 2 / Step 3 が `Add-Content` を含む行を両ファイルから除去し `newline=` を導入することと整合する
- Task 4 Step 4 の期待値 `CR を 5 個` は 2026-08-05 時点の実測値。Task 3 の完了後に追記が発生していれば変わるため、Step 4 に注記を置いた
- Task 5 Step 3 の期待値「4 ファイル」は、ストアの `.jsonl` / `.json` が `LoopForAlpha/log.jsonl` / `MakeAiInstructions/log.jsonl` / `processed.jsonl` / `projects.json` の 4 件であることと整合する。バックアップファイルが対象に入らないことも注記した
- Task 8 Step 5 は、close 件数が Step 2 の受け皿確認結果に依存して確定しないため、固定の期待値を置かず目視突合とした（誤った期待値を書くより正確）
