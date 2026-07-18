# worklog 実運用堅牢化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** worklog パイプラインの中央ストアと start-work Phase -1 を実運用向けに堅牢化する（model 定義の訂正・エンコーディング契約・スキル availability 判定規範の 3 件）。

**Architecture:** 既存ドキュメント/スキルの**書き換え更新**のみ。新規コードなし。「なぜ」は ADR（0048 改定・0054・0055）に、「今どうなっているか」は各スキル/リファレンス/spec に記録する。

**Tech Stack:** Markdown（スキル定義・リファレンス・ADR・spec・issue）。検証は grep / Read。

**前提（既に作成済み・未コミット）:**
- `docs/records/decisions/0054-worklog-store-encoding-eol-contract.md`（Proposed）
- `docs/records/decisions/0055-start-work-skill-availability-ai-side-check.md`（Proposed）
- `docs/records/decisions/README.md` に 0054/0055 の Proposed 行を追記済み
- これらは Task 2 / Task 3 / Task 5 でコミット・昇格する

**スコープ外（触らない）:**
- `docs/working/plans/2026-07-17-worklog-v1.1.md`（完了済み過去 plan＝当時のスナップショット。歴史的記録として不変）
- `docs/inbox/*`（ユーザーが手動移動予定。かつ該当の「記録時」は scope/頻度の記述で model 無関係）
- Issue-0031 本文の「記録時」記述（旧状態を正しく説明している。close 処理のみ）
- `scripts/sync-template.ps1` は実行不要（CLAUDE.md / principles.md / folder-structure.md / inbox/README.md のいずれも変更しないため）

---

### Task 1: Issue-0031 — model 定義を「記録時」→「delta 発生元」へ訂正

**Files:**
- Modify: `skills/worklog-record/references/store-format.md:44`
- Modify: `skills/worklog-record/SKILL.md:51`
- Modify: `docs/current/specs/2026-07-17-worklog-skill-pipeline/01-worklog-store.md:52`
- Modify: `docs/current/specs/2026-07-17-worklog-skill-pipeline/02-skill1-record.md:28`
- Modify: `docs/records/decisions/0048-worklog-entry-model-field-required.md`（title / Status / Decision / Consequences）
- Modify: `docs/records/decisions/README.md:56`（ADR-0048 のタイトル）

- [ ] **Step 1: store-format.md の model 行を訂正**

`skills/worklog-record/references/store-format.md` の 44 行目。

old:
```
| `model` | string | 記録時の AI モデル ID（例 `"claude-fable-5"`）。モデル固有か全モデル共通かの判別材料（ADR-0048） |
```
new:
```
| `model` | string | delta 発生元の AI モデル ID（例 `"claude-fable-5"`。記録時と異なる場合は発生元を優先）。モデル固有か全モデル共通かの判別材料（ADR-0048） |
```

- [ ] **Step 2: worklog-record SKILL.md の必須フィールド説明を訂正**

`skills/worklog-record/SKILL.md` の 51 行目。

old:
```
   - 必須フィールド（`v`＝現行 `2` / `id` / `date` / `project` / `model`＝記録時の AI モデル ID / `scope` / `title` / `context` / `procedure`）を埋める
```
new:
```
   - 必須フィールド（`v`＝現行 `2` / `id` / `date` / `project` / `model`＝delta 発生元の AI モデル ID / `scope` / `title` / `context` / `procedure`）を埋める
```

- [ ] **Step 3: spec 01-worklog-store.md の model 行を訂正**

`docs/current/specs/2026-07-17-worklog-skill-pipeline/01-worklog-store.md` の 52 行目。

old:
```
| `model` | string | 記録時の AI モデル ID（例 `"claude-fable-5"`）。モデル固有か全モデル共通かの判別材料（ADR-0048） |
```
new:
```
| `model` | string | delta 発生元の AI モデル ID（例 `"claude-fable-5"`。記録時と異なる場合は発生元を優先）。モデル固有か全モデル共通かの判別材料（ADR-0048） |
```

- [ ] **Step 4: spec 02-skill1-record.md の model 記述を訂正**

`docs/current/specs/2026-07-17-worklog-skill-pipeline/02-skill1-record.md` の 28 行目。文中の `` `model`＝記録時の AI モデル ID `` を `` `model`＝delta 発生元の AI モデル ID `` に置換する。

old:
```
7. **エントリ構築と検証**: 01 の必須フィールド（`v`＝現行 `2`・`model`＝記録時の AI モデル ID を含む）を埋め、delta 必須（friction または corrections）を検証してから追記
```
new:
```
7. **エントリ構築と検証**: 01 の必須フィールド（`v`＝現行 `2`・`model`＝delta 発生元の AI モデル ID を含む）を埋め、delta 必須（friction または corrections）を検証してから追記
```

- [ ] **Step 5: ADR-0048 のタイトルを訂正**

`docs/records/decisions/0048-worklog-entry-model-field-required.md` の 1 行目。

old:
```
# ADR-0048: worklog エントリに記録時モデル ID の必須フィールド model を追加する
```
new:
```
# ADR-0048: worklog エントリに delta 発生元モデル ID の必須フィールド model を追加する
```

- [ ] **Step 6: ADR-0048 の Status に改定注記を追加**

同ファイル 3 行目。

old:
```
- **Status**: Accepted
```
new:
```
- **Status**: Accepted（Issue-0031 で model の定義を「記録時のモデル」→「delta 発生元のモデル」へ訂正: 2026-07-18）
```

- [ ] **Step 7: ADR-0048 の Decision 本文を訂正**

同ファイル 17 行目。

old:
```
エントリスキーマに `model`（string、**必須**）を追加する。値は記録時の AI モデル ID（例: `"claude-fable-5"`）。欠落はエントリ検証で弾く。既存の v1 エントリ（model なし）は書き換えず、読み側が旧スキーマとして許容する（ADR-0049 の版数規約に従う）。
```
new:
```
エントリスキーマに `model`（string、**必須**）を追加する。値は delta 発生元の AI モデル ID（例: `"claude-fable-5"`。記録時と発生元が異なる場合は発生元を優先）。欠落はエントリ検証で弾く。既存の v1 エントリ（model なし）は書き換えず、読み側が旧スキーマとして許容する（ADR-0049 の版数規約に従う）。
```

- [ ] **Step 8: ADR-0048 の Consequences にモデルまたぎ注記を追加**

同ファイルの Consequences セクション。`- Issue-0025 は本 ADR で close する` の直前に 1 行追加する。

old:
```
- Issue-0025 は本 ADR で close する
```
new:
```
- モデルまたぎ運用（主作業＝高性能モデル / 事後処理＝安価モデル）では記録時と発生元が食い違う。1 エントリが複数モデルの delta にまたがる場合は ADR-0053 の記録単位（同一 context の delta 束）に従いテーマ分割し、各エントリを単一の発生元モデルに収める（Issue-0031）
- Issue-0025 は本 ADR で close する
```

- [ ] **Step 9: ADR インデックスの 0048 タイトルを訂正**

`docs/records/decisions/README.md` の 56 行目。

old:
```
| [0048](0048-worklog-entry-model-field-required.md) | worklog エントリに記録時モデル ID の必須フィールド model を追加する | Accepted | 2026-07-17 |
```
new:
```
| [0048](0048-worklog-entry-model-field-required.md) | worklog エントリに delta 発生元モデル ID の必須フィールド model を追加する | Accepted | 2026-07-17 |
```

- [ ] **Step 10: 訂正の実体確認（grep）**

Run: `grep -rn "記録時の AI モデル\|記録時モデル ID" skills/ docs/records/decisions/ docs/current/specs/`
Expected: **0 件**（canonical・ADR・spec すべて訂正済み。過去 plan と inbox・Issue 本文は対象外なのでこの検索パスには含めない）

- [ ] **Step 11: コミット**

```bash
git add skills/worklog-record/references/store-format.md skills/worklog-record/SKILL.md docs/current/specs/2026-07-17-worklog-skill-pipeline/01-worklog-store.md docs/current/specs/2026-07-17-worklog-skill-pipeline/02-skill1-record.md docs/records/decisions/0048-worklog-entry-model-field-required.md docs/records/decisions/README.md
git commit -m "worklog: ADR-0048 の model 定義を delta 発生元へ訂正（Issue-0031）"
```

---

### Task 2: Issue-0030 — エンコーディング契約＋書き側手段＋読み側検証

**Files:**
- Modify: `skills/worklog-record/references/store-format.md`（契約セクション追加）
- Modify: `skills/worklog-record/SKILL.md:54`（追記手段注記）
- Modify: `skills/worklog-extract/SKILL.md`（走査直前の健全性検証＋関連 ADR）
- Commit: `docs/records/decisions/0054-worklog-store-encoding-eol-contract.md`（作成済み Proposed）

- [ ] **Step 1: store-format.md にエンコーディング契約セクションを追加**

`skills/worklog-record/references/store-format.md` の 12 行目（`このストアはリポジトリ外・中央集約であり、...（records と混同しないこと）。`）の直後に、新セクションを挿入する。

old:
```
このストアはリポジトリ外・中央集約であり、`docs/overview/folder-structure.md` の5分類の**管轄外**である（records と混同しないこと）。

## projects.json
```
new:
```
このストアはリポジトリ外・中央集約であり、`docs/overview/folder-structure.md` の5分類の**管轄外**である（records と混同しないこと）。

## エンコーディング・改行コード（全ストアファイル共通契約）

すべてのストアファイル（`log.jsonl` / `processed.jsonl` / `projects.json`）は **UTF-8（BOM なし）・改行 LF 固定**とする（ADR-0054）。

- このストアはリポジトリ外にあり、`.gitattributes` による改行正規化（ADR-0037）の管轄外。契約は各スキルの読み書き手順で守る
- 全プラットフォーム・全ツール共有のため、別 OS・別ツールの既定追記（BOM 付き・CRLF・UTF-16 等）が混ざると連結1パス走査が壊れる
- **書き側手段**: PowerShell は `Add-Content -Encoding utf8NoBOM`（改行は LF を明示）、POSIX シェルは `>>` リダイレクト。`projects.json` の全体書き換え（upsert）も同エンコーディングで保存する
- **読み側検証**: `worklog-extract` は走査直前に BOM・CRLF・非 UTF-8 を検出し、あれば報告して停止する（silent tolerance はしない。既存行の正規化は内容不変のバイト正規化に限り、ユーザーの明示 opt-in でのみ実行）

## projects.json
```

- [ ] **Step 2: worklog-record SKILL.md の append ステップに手段を注記**

`skills/worklog-record/SKILL.md` の 54 行目。

old:
```
   - `<folderName>/log.jsonl` へ1行 append
```
new:
```
   - `<folderName>/log.jsonl` へ1行 append（UTF-8・BOM なし・LF 固定。PowerShell は `Add-Content -Encoding utf8NoBOM`、POSIX は `>>`。ADR-0054 / `references/store-format.md` のエンコーディング契約に従う）
```

- [ ] **Step 3: worklog-extract SKILL.md の走査ステップに健全性検証を組み込む**

`skills/worklog-extract/SKILL.md` の手順 step 2。

old:
```
2. **サブエージェント走査**: 全 `log.jsonl` を1パスで読み、類似エントリをクラスタリングする（メインコンテキストに載せない。原則3の関心分離）。読み込み時はスキーマ版数の互換規約に従う: **`v` なし行 = v1 と解釈し、v1 の `friction`（string）は 1 要素配列として読み替える**（ADR-0049/0051）
```
new:
```
2. **ストア健全性検証 → サブエージェント走査**: 走査に先立ち、全 `log.jsonl` / `processed.jsonl` のエンコーディング健全性（UTF-8・BOM なし・LF）を検証する。BOM・CRLF・非 UTF-8 を検出したら**報告して停止**し、既存行の正規化（BOM 除去・CRLF→LF、内容は不変）は**ユーザーの明示 opt-in でのみ**実行する（ADR-0054。silent tolerance はしない）。健全性を確認後、全 `log.jsonl` を1パスで読み、類似エントリをクラスタリングする（メインコンテキストに載せない。原則3の関心分離）。読み込み時はスキーマ版数の互換規約に従う: **`v` なし行 = v1 と解釈し、v1 の `friction`（string）は 1 要素配列として読み替える**（ADR-0049/0051）
```

- [ ] **Step 4: worklog-extract SKILL.md の関連 ADR に 0054 を追加**

同ファイル末尾の「## 関連 ADR」リスト。

old:
```
- ADR-0048/0049/0051（読み側互換: model 材料・v 版数判別・friction 読み替え）
```
new:
```
- ADR-0048/0049/0051（読み側互換: model 材料・v 版数判別・friction 読み替え）
- ADR-0054（走査直前のストア健全性検証: エンコーディング/EOL の loud validation）
```

- [ ] **Step 5: 追加の実体確認（grep）**

Run: `grep -n "BOM なし・改行 LF 固定\|utf8NoBOM" skills/worklog-record/references/store-format.md && grep -n "ストア健全性検証" skills/worklog-extract/SKILL.md && grep -n "utf8NoBOM" skills/worklog-record/SKILL.md`
Expected: 契約セクション・extract 検証・record 注記がそれぞれ 1 件以上マッチ

- [ ] **Step 6: コミット（ADR-0054 Proposed を同梱）**

```bash
git add skills/worklog-record/references/store-format.md skills/worklog-record/SKILL.md skills/worklog-extract/SKILL.md docs/records/decisions/0054-worklog-store-encoding-eol-contract.md
git commit -m "worklog: 中央ストアのエンコーディング契約と読み側検証を追加（Issue-0030, ADR-0054）"
```

---

### Task 3: Issue-0024 — start-work Phase -1 に availability 判定規範を追加

**Files:**
- Modify: `skills/start-work/SKILL.md`（Phase -1 に step 4 追加）
- Commit: `docs/records/decisions/0055-start-work-skill-availability-ai-side-check.md`（作成済み Proposed）＋ `docs/records/decisions/README.md`（0054/0055 の Proposed 行）

- [ ] **Step 1: start-work Phase -1 に availability 判定ステップを追加**

`skills/start-work/SKILL.md` の Phase -1。step 3 の直後に step 4 を追加する。

old:
```
3. 不足があればユーザーに報告する:
   「superpowers の <スキル名> が見つかりません。該当フェーズではインライン簡易フローへフォールバックします。」

### Phase 0: セッション継続チェック
```
new:
```
3. 不足があればユーザーに報告する:
   「superpowers の <スキル名> が見つかりません。該当フェーズではインライン簡易フローへフォールバックします。」
4. 本セッションで新規追加/改定した `ai-driven-dev-principles` スキルの availability は、AI 側の system-reminder（available-skills 一覧）または Skill ツール呼び出し可否で判定する（UI の `/skills` 表示には依存しない）。反映が確認できない場合はユーザーへ `/plugin marketplace update ai-driven-dev-principles` の実行を依頼する（AI からは実行不可。ADR-0055）

### Phase 0: セッション継続チェック
```

- [ ] **Step 2: 追加の実体確認（grep）**

Run: `grep -n "available-skills\|ADR-0055" skills/start-work/SKILL.md`
Expected: Phase -1 の新 step 4 が 1 件マッチ

- [ ] **Step 3: コミット（ADR-0055 Proposed ＋ ADR インデックスを同梱）**

```bash
git add skills/start-work/SKILL.md docs/records/decisions/0055-start-work-skill-availability-ai-side-check.md docs/records/decisions/README.md
git commit -m "start-work: Phase -1 にスキル availability の AI 側判定規範を追加（Issue-0024, ADR-0055）"
```

---

### Task 4: 3 課題を close ＋ issue インデックス更新

**Files:**
- Modify: `docs/working/issues/system/0030-worklog-store-encoding-eol-contract.md`
- Modify: `docs/working/issues/system/0031-worklog-model-field-delta-origin-vs-record-time.md`
- Modify: `docs/working/issues/flow/0024-plugin-skill-availability-check-in-start-work.md`
- Modify: `docs/working/issues/README.md`（3 行の Status）

- [ ] **Step 1: Issue-0030 を close**

`docs/working/issues/system/0030-worklog-store-encoding-eol-contract.md`。

Status 行 `- **Status**: open` → `- **Status**: closed`。`- **Opened**: 2026-07-18` の直後に `- **Closed**: 2026-07-18` を追加。末尾の結論を差し替え:

old:
```
## 結論

（open）
```
new:
```
## 結論

ADR-0054 で対処。ストアファイルを UTF-8/BOM なし/LF 固定の契約とし、書き側手段（PowerShell utf8NoBOM / POSIX >>）を注記、読み側 worklog-extract に走査直前の loud validation を追加した（silent tolerance は不採用）。
```

- [ ] **Step 2: Issue-0031 を close**

`docs/working/issues/system/0031-worklog-model-field-delta-origin-vs-record-time.md`。

Status 行 → `closed`。`- **Opened**: 2026-07-18` の直後に `- **Closed**: 2026-07-18` を追加。末尾の結論を差し替え:

old:
```
## 結論

（open）
```
new:
```
## 結論

ADR-0048 を in-place 改定して対処。model 定義を「記録時の AI モデル ID」→「delta 発生元の AI モデル ID（記録時と異なる場合は発生元を優先）」へ訂正し、store-format.md / worklog-record SKILL.md / spec 01・02 の文言も揃えた。複数モデルまたぎの 1 エントリは ADR-0053 の記録単位でテーマ分割する。
```

- [ ] **Step 3: Issue-0024 を close**

`docs/working/issues/flow/0024-plugin-skill-availability-check-in-start-work.md`。

Status 行 → `closed`。`- **Opened**: 2026-07-17` の直後に `- **Closed**: 2026-07-18` を追加。末尾の結論を差し替え:

old:
```
## 結論

（open）
```
new:
```
## 結論

ADR-0055 で対処。start-work Phase -1 に「新規/改定スキルの availability は AI 側 system-reminder / Skill ツール呼び出し可否で判定（UI 非依存）、未反映ならユーザーへプラグイン更新を依頼」する step を追加した。
```

- [ ] **Step 4: issue インデックスの 3 行を closed に更新**

`docs/working/issues/README.md`。以下 3 行の Status セル `open` → `closed`。

- 0030 行（system）: `... 中央ストアの文字コード・改行コード規約と追記手段が未定義 | open | 2026-07-18 |` → `... | closed | 2026-07-18 |`
- 0031 行（system）: `... worklog の model フィールドが「記録時」定義でモデルまたぎセッションで delta を誤帰属 | open | 2026-07-18 |` → `... | closed | 2026-07-18 |`
- 0024 行（flow）: `... プラグイン更新後の新規スキル availability 確認手順が start-work Phase -1 に未組み込み | open | 2026-07-17 |` → `... | closed | 2026-07-17 |`

- [ ] **Step 5: close の実体確認（grep）**

Run: `grep -rn "Status.*: closed" docs/working/issues/system/0030-worklog-store-encoding-eol-contract.md docs/working/issues/system/0031-worklog-model-field-delta-origin-vs-record-time.md docs/working/issues/flow/0024-plugin-skill-availability-check-in-start-work.md`
Expected: 3 件マッチ

- [ ] **Step 6: コミット**

```bash
git add docs/working/issues/system/0030-worklog-store-encoding-eol-contract.md docs/working/issues/system/0031-worklog-model-field-delta-origin-vs-record-time.md docs/working/issues/flow/0024-plugin-skill-availability-check-in-start-work.md docs/working/issues/README.md
git commit -m "issues: 0030/0031/0024 を close（worklog 実運用堅牢化サイクルで対処）"
```

---

### Task 5: 最終検証 ＋ ADR-0054/0055 を Accepted へ昇格

**Files:**
- Modify: `docs/records/decisions/0054-worklog-store-encoding-eol-contract.md`（Status）
- Modify: `docs/records/decisions/0055-start-work-skill-availability-ai-side-check.md`（Status）
- Modify: `docs/records/decisions/README.md`（0054/0055 の Status セル）

- [ ] **Step 1: 全体の実体確認（grep）**

Run: `grep -rn "記録時の AI モデル\|記録時モデル ID" skills/ docs/records/decisions/ docs/current/specs/`
Expected: **0 件**

Run: `grep -nE "\| open \|" docs/working/issues/README.md | grep -E "0030|0031|0024"`
Expected: **0 件**（3 課題は closed。`open` を含む他課題行は残ってよい）

- [ ] **Step 2: ADR-0054 を Accepted へ昇格**

`docs/records/decisions/0054-worklog-store-encoding-eol-contract.md` の Status 行 `- **Status**: Proposed` → `- **Status**: Accepted`。

- [ ] **Step 3: ADR-0055 を Accepted へ昇格**

`docs/records/decisions/0055-start-work-skill-availability-ai-side-check.md` の Status 行 `- **Status**: Proposed` → `- **Status**: Accepted`。

- [ ] **Step 4: ADR インデックスの 0054/0055 を Accepted に更新**

`docs/records/decisions/README.md` の 0054 行・0055 行の Status セル `Proposed` → `Accepted`。

- [ ] **Step 5: 昇格の実体確認（grep）**

Run: `grep -nE "005[45]" docs/records/decisions/README.md`
Expected: 0054・0055 とも `Accepted`

Run: `grep -n "Status" docs/records/decisions/0054-worklog-store-encoding-eol-contract.md docs/records/decisions/0055-start-work-skill-availability-ai-side-check.md`
Expected: 両ファイルとも `Accepted`

- [ ] **Step 6: コミット**

```bash
git add docs/records/decisions/0054-worklog-store-encoding-eol-contract.md docs/records/decisions/0055-start-work-skill-availability-ai-side-check.md docs/records/decisions/README.md
git commit -m "adr: 0054/0055 を Accepted へ昇格（worklog 実運用堅牢化 実装完了）"
```

---

## 実装後のフォロー（この plan のスコープ外・start-work セッション終了処理で実施）

1. `finishing-a-development-branch` で master へ merge（`--no-ff`）
2. merge 直後に `retrospective` スキルを起動（CLAUDE.md 検証節）
3. **プラグイン更新の依頼**: 本サイクルは skills/（start-work / worklog-record / worklog-extract）を改定したため、反映にはユーザーの `/plugin marketplace update ai-driven-dev-principles` が必要（AI 実行不可）
4. handoff finalize

## Self-Review メモ（作成者チェック済み）

- **spec coverage**: 3 課題すべてにタスクを割当（Task1=0031 / Task2=0030 / Task3=0024）、close は Task4、ADR 昇格は Task5。設計の 3 変更を網羅
- **検証整合**: Task1 Step10 の grep 期待値「0 件」は、訂正対象（canonical 2・ADR・spec 2）と検索パス（skills/・docs/records/decisions/・docs/current/specs/）が一致。過去 plan/inbox/Issue 本文を検索パスから除外しているため矛盾しない
- **型/文言整合**: model 訂正後の表現「delta 発生元の AI モデル ID」を store-format / SKILL / spec / ADR で統一
