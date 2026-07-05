# 振り返り課題×issue管理統合 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 振り返り課題を全件 issue 起票する統合ルールと issues の system/flow フォルダ分割を導入し、既存課題を移行する（ADR-0028）。

**Architecture:** ドキュメント・スキル定義のみの変更（コードは sync-template.ps1 の実行のみで、スクリプト自体は変更しない）。規約定義（folder-structure.md）→ 起票側（retrospective スキル）→ 参照側（decision-log / CONTRIBUTING / 各 README / 旧 spec）→ 移行・同期の順に適用する。

**Tech Stack:** Markdown、PowerShell（sync-template.ps1 実行のみ）、Git。自動テストはないため、各タスクの検証は grep と目視で行う。

**Spec:** `docs/current/specs/2026-07-05-retrospective-issue-integration/`（00〜04。編集内容の根拠はすべてここにある）

**共通の注意:**

- 振り返り記録（`docs/records/retrospectives/system|flow/*.md`）は**絶対に書き換えない**（ADR-0011）
- コミットメッセージ末尾に `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>` を付ける
- 日付はすべて 2026-07-05

---

### Task 1: folder-structure.md を新構造に更新（ブロック01）

**Files:**
- Modify: `docs/overview/folder-structure.md`（§5 ツリー、§6 配置表、§7 全面書き換え、§8 パス表記、§11 関連 ADR）

- [ ] **Step 1: §5 標準フォルダレイアウトのツリーを更新**

`issues/` の行（39行目付近）を以下に置換:

```
    issues/        #    課題（system/ flow/ の2フォルダに分類。個別ファイル＋インデックス）
```

- [ ] **Step 2: §6 配置表の課題行を更新**

`| 課題・未決事項 | \`docs/working/issues/\` |` を以下に置換:

```markdown
| 課題・未決事項 | `docs/working/issues/system|flow/` |
```

- [ ] **Step 3: §7 を全面書き換え**

「## 7. 課題（issue）管理」の見出しから「## 8.」直前までを以下に置換:

````markdown
## 7. 課題（issue）管理

### 7.1 フォルダ構造と分類

課題は「対象システム固有」「開発フロー/ガイドライン関連」のいずれかに分類し、対応するフォルダに配置する:

```
docs/working/issues/
  README.md          # インデックス（唯一）。system / flow の2セクション
  system/            # 対象システム固有の課題
    NNNN-<slug>.md
    NNNN-<slug>/     # フォルダ昇格時
  flow/              # 開発フロー/ガイドライン課題
    NNNN-<slug>.md
    NNNN-<slug>/
```

- フォルダ名は振り返り記録の2フォルダ（`docs/records/retrospectives/system|flow/`）と対応する
- `flow/` の課題は、ガイドライン配布先のシステム開発プロジェクトでは「ガイドライン repo への申し送り対象」を表す
- 課題ファイルに分類フィールドは設けない（フォルダが分類を表す）。分類を変える場合はファイル移動とインデックスの行移動で行う

### 7.2 起票と採番

- 課題は1件ごとに `docs/working/issues/system|flow/NNNN-<slug>.md`（NNNN は4桁ゼロ埋め連番、slug は英語ケバブケース）で起票し、インデックス `docs/working/issues/README.md` の対応セクションに1行追加する
- **採番は両フォルダ通しの連番** — インデックス全体（両セクション）の最大番号+1。Issue-NNNN の参照がプロジェクト内で一意になる
- 起票経路は2つ:
  - **振り返り由来** — retrospective スキルが抽出・分類した課題は、その場で全件起票される。課題内容は要約のみを書き、事象/原因/影響の詳細は「起票元」の振り返りファイルを正とする
  - **議論由来** — 仕様検討中の未決事項など（ADR 記述規律による分離）。課題内容を本文に直接書く

### 7.3 ライフサイクル

- **Status は open → closed** — 対策方針が決定したら ADR を作成し、課題の「結論」に ADR 番号を記載して close する（進行中の作業 → 追跡型の記録への遷移）
- **配布先プロジェクトの `flow/` 課題**は「ガイドライン repo へ申し送り済み（または対応済み）」で close する
- **クローズ済み課題はその場に残す** — アーカイブは独立した分類ではなく、この分類内の状態として扱う
- **フォルダ昇格** — 検討が長期化・多観点化したら `NNNN-<slug>/` フォルダに昇格できる（各分類フォルダ内で行う）。課題ファイルをフォルダ内 `README.md` とし、分析・比較・叩き台のファイルを並置する
- **TBD を積極的に使う** — 不確定な情報を確定した事実のように書かない。未確定箇所は「TBD」と明示する

### 7.4 課題ファイルのフォーマット

```markdown
# Issue-NNNN: <タイトル>

- **Status**: open | closed
- **Opened**: YYYY-MM-DD
- **Closed**: YYYY-MM-DD（closed 時のみ）
- **起票元**: <起票のきっかけへの参照>（任意。振り返り由来なら「retrospectives/flow/YYYY-MM-DD-<topic>.md 課題#N」の形式）
- **関連**: ADR-NNNN 等（あれば）

## 課題内容

（振り返り由来: 要約のみ。詳細は起票元の振り返りファイルが正。
　議論由来: 何が問題か・なぜケアが必要かを直接書く。TBD を積極的に使ってよい）

## 検討状況

（対策検討の経過。長期化したらフォルダ昇格を検討）

## 結論

（closed 時: 下した決定への参照。決定内容自体は ADR に書く）
```

### 7.5 インデックスの形式

`docs/working/issues/README.md` はフォルダに対応する2セクション構成。各セクションは1課題1行のテーブル（# / タイトル / Status / Opened）で、リンク先は `system/NNNN-<slug>.md` 形式。採番規則（通し連番）を冒頭に明記する。
````

- [ ] **Step 4: §8 運用例の起票パスを更新**

`1. **発端** — 「技術的負債が溜まっている」→ 課題を起票（\`working/issues/\`, open。` の部分を `1. **発端** — 「技術的負債が溜まっている」→ 課題を起票（\`working/issues/system/\`, open。` に置換（技術的負債は対象システム固有の課題のため）。

- [ ] **Step 5: §11 関連 ADR に追記**

`- ADR-0026: inbox と organize-inbox スキル` の直後に追加:

```markdown
- ADR-0028: 振り返り課題の全件起票と issues の system/flow フォルダ分割
```

- [ ] **Step 6: 検証**

Run: `grep -n "issues/NNNN" docs/overview/folder-structure.md`
Expected: `system|flow/NNNN` 形式のみヒット（`issues/NNNN-<slug>` 直下形式が残っていない。§7.3 のフォルダ昇格 `NNNN-<slug>/` は分類フォルダ内なので OK）

- [ ] **Step 7: コミット**

```bash
git add docs/overview/folder-structure.md
git commit -m "docs: 課題管理を system/flow フォルダ分割・全件起票規約に改定（ADR-0028）"
```

---

### Task 2: 既存課題の移行と7件の起票（ブロック04 §3）

**Files:**
- Move: `docs/working/issues/0001-template-sync-asymmetry.md` → `docs/working/issues/system/0001-template-sync-asymmetry.md`
- Create: `docs/working/issues/system/0002-sync-template-line-endings.md` / `system/0003-conversation-log-classification.md` / `system/0008-legacy-single-file-spec-policy.md` / `flow/0004-question-tool-display-norm.md` / `flow/0005-selection-ui-misclick-confirmation.md` / `flow/0006-cross-cutting-change-plan-coverage.md` / `flow/0007-retrospective-issue-integration.md`
- Rewrite: `docs/working/issues/README.md`

- [ ] **Step 1: Issue-0001 を移動**

```bash
git mv docs/working/issues/0001-template-sync-asymmetry.md docs/working/issues/system/0001-template-sync-asymmetry.md
```

- [ ] **Step 2: system/ の3件を作成**

`docs/working/issues/system/0002-sync-template-line-endings.md`:

```markdown
# Issue-0002: sync-template.ps1 の改行コード非決定性

- **Status**: open
- **Opened**: 2026-07-05
- **起票元**: retrospectives/system/2026-07-05-project-folder-structure.md 課題#2
- **関連**: ADR-0027

## 課題内容

sync-template.ps1 が WriteAllLines で CRLF 書き出しを行い、LF 正規化されたコミット内容と食い違うため、実行のたびに template/ 配下が変更扱いになる（要約。事象/原因/影響の詳細は起票元参照）。

## 検討状況

（未着手）

## 結論

（open）
```

`docs/working/issues/system/0003-conversation-log-classification.md`:

```markdown
# Issue-0003: docs/conversation_log.md の分類・扱いが未定

- **Status**: open
- **Opened**: 2026-07-05
- **起票元**: retrospectives/system/2026-07-05-project-folder-structure.md 課題#1

## 課題内容

ユーザーの記録ファイル `docs/conversation_log.md` が untracked のまま docs/ 直下に残置されており、5分類体系上の扱いが未定（要約。詳細は起票元参照）。ユーザー判断待ち。

## 検討状況

（未着手）

## 結論

（open）
```

`docs/working/issues/system/0008-legacy-single-file-spec-policy.md`:

```markdown
# Issue-0008: 旧型式の単一ファイル spec の維持・アーカイブ方針が未定義

- **Status**: open
- **Opened**: 2026-07-05
- **起票元**: 2026-07-05 サイクル（振り返り課題×issue管理統合）の brainstorming 中に検出

## 課題内容

`docs/current/specs/` には旧型式の単一ファイル spec が8本残っている（2026-04-12〜2026-06-16）。「仕様書は現時点のシステム全容が分かるスナップショットとして維持する」規約に対し、これらは後続 ADR の改定が反映されず古びている（例: `2026-05-01-retrospective-design.md` は ADR-0021 のスコープ縮小・出力先2フォルダ化が未反映）。維持（書き換え更新）するのか、アーカイブ扱いにするのかの方針が未定義。

## 検討状況

（未着手）

## 結論

（open）
```

- [ ] **Step 3: flow/ の4件を作成**

`docs/working/issues/flow/0004-question-tool-display-norm.md`:

```markdown
# Issue-0004: 質問ツールの表示特性が選択肢提示規範に織り込まれていない

- **Status**: open
- **Opened**: 2026-07-05
- **起票元**: retrospectives/flow/2026-07-05-project-folder-structure.md 課題#1
- **関連**: ADR-0024

## 課題内容

構造化質問ツール（AskUserQuestion 等）と同一ターンに書いた説明テキストがユーザーに表示されず、説明の欠落した状態で選択を求める形になる。選択肢提示規範（ADR-0024）にツールの表示特性への対処が定められていない（要約。詳細は起票元参照）。

## 検討状況

2026-07-05 の本サイクル brainstorming 中にも再発を確認（設計相談の前置き説明が非表示のまま質問された）。

## 結論

（open）
```

`docs/working/issues/flow/0005-selection-ui-misclick-confirmation.md`:

```markdown
# Issue-0005: 選択UIの誤操作が即「方針確定」として扱われる

- **Status**: open
- **Opened**: 2026-07-05
- **起票元**: retrospectives/flow/2026-07-05-project-folder-structure.md 課題#2
- **関連**: ADR-0006、ADR-0024

## 課題内容

選択UIの誤クリックが確認ステップなしに意思決定として確定し、意思決定の継続検出ルール（ADR-0006）により即座に ADR 作業へ増幅される（要約。詳細は起票元参照）。

## 検討状況

（未着手）

## 結論

（open）
```

`docs/working/issues/flow/0006-cross-cutting-change-plan-coverage.md`:

```markdown
# Issue-0006: 横断的なパス変更で実装計画に網羅漏れが出る

- **Status**: open
- **Opened**: 2026-07-05
- **起票元**: retrospectives/flow/2026-07-05-project-folder-structure.md 課題#3

## 課題内容

横断的な変更（パス変更等）の際、計画時の変更対象リストが仕様書で明示したファイルに偏り、リポジトリ全体の旧参照の洗い出しがタスク末尾の検証に寄って網羅漏れが出る（要約。詳細は起票元参照）。writing-plans 時の横断洗い出し手順の問題。

## 検討状況

（未着手）

## 結論

（open）
```

`docs/working/issues/flow/0007-retrospective-issue-integration.md`:

```markdown
# Issue-0007: retrospective の課題バックログと issue 管理の関係が未定義

- **Status**: open
- **Opened**: 2026-07-05
- **起票元**: retrospectives/flow/2026-07-05-project-folder-structure.md 課題#4
- **関連**: ADR-0028

## 課題内容

課題の置き場が振り返り記録と docs/working/issues/ の2系統になり、起票基準・分類表現・相互参照の方法が未定義。振り返り由来の課題に open/closed のライフサイクル管理が適用されない（要約。詳細は起票元参照）。

## 検討状況

2026-07-05 サイクル（feature/retrospective-issue-integration）で対策中。対策方針は ADR-0028 として起票済み（Proposed）。

## 結論

（open。実装完了・検証後に ADR-0028 を結論として close する）
```

- [ ] **Step 4: インデックスを2セクション形式に書き換え**

`docs/working/issues/README.md` 全体を以下に置換:

```markdown
# 課題（Issues）

進行中・クローズ済みの課題のインデックス。運用ルールは `../../overview/folder-structure.md` の「課題（issue）管理」を参照。
採番は両セクション通しの連番（インデックス全体の最大番号+1）。

## 対象システム固有の課題（system/）

| # | タイトル | Status | Opened |
|---|---------|--------|--------|
| [0001](system/0001-template-sync-asymmetry.md) | template 同期の非対称性 | closed | 2026-06-15 |
| [0002](system/0002-sync-template-line-endings.md) | sync-template.ps1 の改行コード非決定性 | open | 2026-07-05 |
| [0003](system/0003-conversation-log-classification.md) | docs/conversation_log.md の分類・扱いが未定 | open | 2026-07-05 |
| [0008](system/0008-legacy-single-file-spec-policy.md) | 旧型式の単一ファイル spec の維持・アーカイブ方針が未定義 | open | 2026-07-05 |

## 開発フロー/ガイドライン課題（flow/）

配布先のシステム開発 repo では、このセクションの open 課題がガイドライン repo への申し送り対象になる。

| # | タイトル | Status | Opened |
|---|---------|--------|--------|
| [0004](flow/0004-question-tool-display-norm.md) | 質問ツールの表示特性が選択肢提示規範に織り込まれていない | open | 2026-07-05 |
| [0005](flow/0005-selection-ui-misclick-confirmation.md) | 選択UIの誤操作が即「方針確定」として扱われる | open | 2026-07-05 |
| [0006](flow/0006-cross-cutting-change-plan-coverage.md) | 横断的なパス変更で実装計画に網羅漏れが出る | open | 2026-07-05 |
| [0007](flow/0007-retrospective-issue-integration.md) | retrospective の課題バックログと issue 管理の関係が未定義 | open | 2026-07-05 |
```

- [ ] **Step 5: 検証**

Run: `ls docs/working/issues/ docs/working/issues/system/ docs/working/issues/flow/`
Expected: ルートは README.md のみ。system/ に 0001,0002,0003,0008。flow/ に 0004,0005,0006,0007

- [ ] **Step 6: コミット**

```bash
git add docs/working/issues
git commit -m "docs: 既存課題を system/ へ移行し、振り返りバックログ6件+旧spec方針1件を起票（ADR-0028）"
```

---

### Task 3: retrospective スキルへの起票統合（ブロック02）

**Files:**
- Modify: `skills/retrospective/SKILL.md`（frontmatter、スコープ節、Phase 2、Phase 4、出力ファイル節、関連節）
- Modify: `skills/retrospective/template.md`（Issues セクション、Handoff Forward）
- Modify: `skills/retrospective/flow-template.md`（課題項目）

- [ ] **Step 1: SKILL.md frontmatter の description を更新**

description 末尾の「（採否判断・対策設計・ADR化は行わず次サイクルへ委ねる。ADR-0021）。」を以下に置換:

```
（採否判断・対策設計・ADR化は行わず次サイクルへ委ねる。ADR-0021）。抽出した課題は分類を問わず全件 docs/working/issues/system|flow/ へその場で起票する（ADR-0028）。
```

- [ ] **Step 2: スコープ節（ADR-0021）に起票の位置づけを追記**

「## スコープ（ADR-0021）」の第2段落末尾（「…通常フロー（`start-work` →（規模に応じ brainstorming）→ 対策決定で ADR 起票）を開始する。」の後）に追加:

```markdown

抽出した課題の issue 起票（Phase 2）は**記録行為であり、対策の設計・採否判断ではない**。起票によって課題に open/closed のライフサイクル管理が付くだけで、本スキルのスコープは「抽出と分類まで」のまま変わらない（ADR-0028）。
```

- [ ] **Step 3: Phase 2 に起票手順を追加**

「### Phase 2: ドラフト保存（メイン実行）」の「書き出し後、ユーザーへ提示し軽く確認する。」の**直前**に追加:

```markdown
書き出しと同時に、抽出した課題を**分類を問わず全件** `docs/working/issues/` へ起票する（ADR-0028）:

1. 課題ごとに、インデックス `docs/working/issues/README.md` 全体（両セクション）の最大番号+1 で採番する
2. 分類に応じて `docs/working/issues/system|flow/NNNN-<slug>.md` を起票する（Status: open）。課題内容は**要約のみ**とし、「起票元」フィールドに `retrospectives/system|flow/YYYY-MM-DD-<topic>.md 課題#N` を記載する（事象/原因/影響の詳細は振り返りファイルが正）
3. インデックスの対応セクションに1行追加する
4. 振り返りファイル側の各課題項目に「**起票**: Issue-NNNN」行を含めて書き出す（初回書き込みで記載するため、上書き禁止規約 ADR-0011 と衝突しない）

Phase 3（rubber-duck レビュー）で課題の分類が変わった場合は、issue ファイルの移動とインデックスの行移動で追随する。
```

- [ ] **Step 4: Phase 4 の課題バックログ記述を更新**

「- 「次セッション開始時のアクション」に「抽出した課題はバックログとして記録済み（着手はユーザー判断。必ず次サイクルではない）」旨を記す。対策が必要と判断された課題があれば、その起点（`system/` または `flow/` のファイルパス）を明記する」を以下に置換:

```markdown
- 「次セッション開始時のアクション」に「抽出した課題は issues に起票済み（Issue-NNNN〜。着手はユーザー判断。必ず次サイクルではない）」旨を記す。対策が必要と判断された課題があれば、その issue 番号と起票元（振り返りファイルパス）を明記する
```

- [ ] **Step 5: 出力ファイル節を更新**

「## 出力ファイル」のリストの「- インデックス更新: …」の前に追加:

```markdown
- 課題起票: `docs/working/issues/system|flow/NNNN-<slug>.md`（抽出課題の件数分）+ `docs/working/issues/README.md` への行追加
```

- [ ] **Step 6: 関連節に ADR-0028 を追加**

「## 関連」の先頭行の前に追加:

```markdown
- ADR-0028: 振り返り課題の全件起票と issues の system/flow フォルダ分割
```

- [ ] **Step 7: template.md の Issues セクションを更新**

課題項目の例を以下に置換（「**影響**」行の後に「**起票**」行を追加）:

```markdown
- **課題 #N**（分類: 対象システム固有）: <一文タイトル>
  - **事象**: <何が起きたか>
  - **原因**: <分析>
  - **影響**: <時間損失・スコープ影響など>
  - **起票**: Issue-NNNN（`../../working/issues/system/NNNN-<slug>.md`）
```

また Handoff Forward の「- **課題バックログ**: <抽出した課題は本ファイル（system 固有）と flow/<同名>.md（フロー課題）に記録済み。着手の要否・時期はユーザー判断>」を以下に置換:

```markdown
- **課題バックログ**: <抽出した課題は全件 issues に起票済み（Issue-NNNN〜NNNN）。詳細は本ファイルと flow/<同名>.md。着手の要否・時期はユーザー判断>
```

- [ ] **Step 8: flow-template.md の課題項目を更新**

「  - **関連**: <該当スキル / 原則 / ADR / ガイドライン箇所（あれば）>」の後に追加:

```markdown
  - **起票**: Issue-NNNN（`../../working/issues/flow/NNNN-<slug>.md`）
```

- [ ] **Step 9: 検証**

Run: `grep -n "起票" skills/retrospective/SKILL.md skills/retrospective/template.md skills/retrospective/flow-template.md`
Expected: SKILL.md に Phase 2 起票手順・スコープ節・description、両テンプレートに「起票: Issue-NNNN」行がヒット

- [ ] **Step 10: コミット**

```bash
git add skills/retrospective
git commit -m "feat: retrospective スキルに課題の全件 issue 起票を統合（ADR-0028）"
```

---

### Task 4: 周辺文書の整合（ブロック03）

**Files:**
- Modify: `skills/decision-log/SKILL.md`（未決事項の起票手順）
- Modify: `CONTRIBUTING.md`（3シナリオ）
- Modify: `docs/records/retrospectives/README.md`（運用規約）
- Modify: `docs/current/specs/2026-07-04-project-folder-structure/01-folder-structure-definition.md`（§3 項目7・§5 データモデル・§7 関連 ADR）

- [ ] **Step 1: decision-log SKILL.md の起票手順を更新**

「### 起票」の手順1・2を以下に置換:

```markdown
1. 未決事項を検出したら `docs/working/issues/system|flow/NNNN-<slug>.md` を起票する（Status: open）。分類は、対象システム固有の課題なら `system/`、開発の進め方・スキル・原則・ガイドラインに関する課題なら `flow/`（議論由来の未決事項は大半が `system/`）。連番はインデックス `docs/working/issues/README.md` 全体（両セクション）の最大番号+1。フォーマットは `docs/overview/folder-structure.md` の「課題（issue）管理」を参照
2. インデックス `docs/working/issues/README.md` の対応セクションに1行追加する
```

- [ ] **Step 2: CONTRIBUTING.md「未決事項・課題を記録するとき」を更新**

手順1を以下に置換:

```markdown
1. `docs/working/issues/system|flow/NNNN-<slug>.md` を起票し（Status: open。対象システム固有なら `system/`、開発フロー/ガイドライン関連なら `flow/`）、インデックス `docs/working/issues/README.md` の対応セクションに1行追加する。採番は両セクション通しの連番。フォーマットは `docs/overview/folder-structure.md` の「課題（issue）管理」を参照
```

- [ ] **Step 3: CONTRIBUTING.md「振り返りで抽出された課題に対策するとき」を更新**

背景の第1文「`retrospective` スキルは課題の抽出と分類までを行い、`docs/records/retrospectives/system/`（対象システム固有の課題）と `docs/records/retrospectives/flow/`（開発フロー/ガイドライン課題）に記録する。」を以下に置換:

```markdown
`retrospective` スキルは課題の抽出と分類までを行い、`docs/records/retrospectives/system/`（対象システム固有の課題）と `docs/records/retrospectives/flow/`（開発フロー/ガイドライン課題）に記録し、全件を `docs/working/issues/system|flow/` へ issue として起票する（ADR-0028。詳細は振り返りファイルが正、issue はライフサイクル管理を担う）。
```

手順1・2を以下に置換:

```markdown
1. `docs/working/issues/README.md` の open 課題（または `docs/records/retrospectives/system|flow/` の該当ファイル）から未対策の課題を確認する。開発フロー/ガイドライン課題（`flow/`）の場合、対策はこのメタ・ガイドラインrepo（ai-driven-dev-principles）側で行う
2. ユーザーと、どの課題（Issue-NNNN）に対策するか・着手するかを確認する（着手の決定はユーザー）
```

手順6の後に追加:

```markdown
7. 対策サイクル完了時（ADR の Accepted 昇格時）に、対象 issue を close する（Status を closed に変更し「結論」に ADR 番号を記載。インデックスも更新）
```

チェックリストに追加:

```markdown
- 対策した課題（Issue-NNNN）を close し、インデックスを更新したか
```

- [ ] **Step 4: CONTRIBUTING.md「振り返りスキル（retrospective）を変更するとき」を更新**

背景の第1段落末尾（「…後者は `docs/records/retrospectives/flow/` に per-cycle で記録する。」の後）に追加:

```markdown
抽出した課題は分類を問わず全件 `docs/working/issues/system|flow/` へ起票される（ADR-0028。起票は記録行為であり、抽出限定スコープは変わらない）。
```

チェックリスト末尾に追加:

```markdown
- 課題の全件起票（要約＋起票元参照・振り返りファイルへの Issue 番号記載）が手順内で維持されているか（ADR-0028）
```

- [ ] **Step 5: docs/records/retrospectives/README.md の運用規約に追記**

「- **インデックス（本ファイル）**: **行追加のみ**、過去行の編集は禁止」の後に追加:

```markdown
- **課題の起票**: 抽出した課題は retrospective 実行時に全件 `docs/working/issues/system|flow/` へ起票される（ADR-0028）。振り返りファイルの課題詳細が正であり、issue は open/closed のライフサイクル管理を担う
```

- [ ] **Step 6: 旧 spec（2026-07-04 ブロック01）の課題管理記述を書き換え**

`docs/current/specs/2026-07-04-project-folder-structure/01-folder-structure-definition.md` を以下のとおり更新（スナップショット規約: 現在形で書き換え、差分節を作らない）:

§3 の項目7を以下に置換:

```markdown
7. **課題（issue）管理** — 詳細は下記「5. データモデル」の課題ファイル規約を記載:
   - `docs/working/issues/system|flow/NNNN-<slug>.md`（system=対象システム固有、flow=開発フロー/ガイドライン関連。4桁ゼロ埋め通し連番）＋ルートのインデックス `README.md`（2セクション）
   - 起票経路は「振り返り由来（retrospective が全件起票、要約＋起票元参照）」と「議論由来（未決事項の分離、本文直接記述）」の2つ（ADR-0028）
   - Status: open → closed。対策方針決定時に ADR を作成して close する。配布先プロジェクトの flow 課題は「ガイドライン repo へ申し送り済み」で close
   - 検討の長期化・多観点化時は各分類フォルダ内で `NNNN-<slug>/` フォルダへ昇格できる（課題ファイルをフォルダ内 `README.md` とし、分析ファイルを並置する）
   - クローズ済みはその場に残す（アーカイブは分類ではなく状態）
   - 不確定情報には「TBD」を積極的に使う（確定事実との混同を防ぐ）
```

§5 のフォーマットブロック内、メタ情報リストの「- **Closed**: YYYY-MM-DD（closed 時のみ）」の後に追加:

```markdown
- **起票元**: <起票のきっかけへの参照>（任意。振り返り由来なら「retrospectives/flow/YYYY-MM-DD-<topic>.md 課題#N」の形式）
```

§5 の末尾「インデックス `docs/working/issues/README.md` は1課題1行のテーブル（# / タイトル / Status / Opened）。」を以下に置換:

```markdown
課題ファイルは `docs/working/issues/system|flow/` に分類配置する。インデックス `docs/working/issues/README.md` はフォルダ対応の2セクション構成で、各セクションは1課題1行のテーブル（# / タイトル / Status / Opened）。採番は両セクション通しの連番。
```

§7 関連 ADR に追加:

```markdown
- ADR-0028（振り返り課題の全件起票・issues の system/flow 分割）
```

- [ ] **Step 7: 検証**

Run: `grep -rn "issues/NNNN-<slug>" --include="*.md" . | grep -v "system|flow" | grep -v "template/" | grep -v "NNNN-<slug>/"`
Expected: ヒットなし（すべて `system|flow/NNNN-<slug>` 形式か、フォルダ昇格の `NNNN-<slug>/` 表記）

- [ ] **Step 8: コミット**

```bash
git add skills/decision-log/SKILL.md CONTRIBUTING.md docs/records/retrospectives/README.md docs/current/specs/2026-07-04-project-folder-structure/01-folder-structure-definition.md
git commit -m "docs: 課題管理の参照文書を system/flow 分割・全件起票に整合（ADR-0028）"
```

---

### Task 5: template 同期と全体検証（ブロック04 §4）

**Files:**
- Modify: `template/` 配下（sync-template.ps1 の実行結果）

- [ ] **Step 1: sync-template.ps1 を実行**

Run: `pwsh scripts/sync-template.ps1`
Expected: `[sync-template] Done. N files synced to template/`（警告なし）

- [ ] **Step 2: 生成された空インデックスを確認**

Run: `cat template/docs/working/issues/README.md`
Expected: 2セクション（system/ と flow/）の見出しとテーブルヘッダーが残り、データ行（0001〜0008）が除去されている

- [ ] **Step 3: リポジトリ全体の旧参照を最終確認**

Run: `grep -rn "docs/working/issues/" --include="*.md" CLAUDE.md skills/ docs/overview/ CONTRIBUTING.md | grep -v "system" | grep -v "flow" | grep -v "README.md"`
Expected: ルートパス（`docs/working/issues/` 全体を指す総称参照）のみ。個別課題ファイルの直下配置を前提とする記述はゼロ

- [ ] **Step 4: 差分を確認してコミット**

改行コードのみの差分（Issue-0002 の既知事象）と内容差分を区別して確認したうえで:

```bash
git add template
git commit -m "chore: template を同期（課題管理の system/flow 分割を反映）"
```

- [ ] **Step 5: ユーザーへプラグイン更新を案内**

skills/ の変更は `/plugin marketplace update ai-driven-dev-principles` をユーザーが実行するまで実行環境に反映されない旨を伝える（エージェントからは実行できない）。

---

### Task 6: クローズ処理（ADR 昇格・Issue-0007 close・ハンドオフ更新）

**Files:**
- Modify: `docs/records/decisions/0028-retrospective-issue-ticketing-integration.md`（Status）
- Modify: `docs/records/decisions/README.md`（Status）
- Modify: `docs/working/issues/flow/0007-retrospective-issue-integration.md`（close）
- Modify: `docs/working/issues/README.md`（0007 の行）
- Modify: `docs/working/handoff/feature_retrospective-issue-integration.md`

- [ ] **Step 1: 実装完了をユーザーに報告し、ADR-0028 の Accepted 昇格の確認を取る**

- [ ] **Step 2: ADR-0028 を Accepted に昇格**

`0028-retrospective-issue-ticketing-integration.md` の `- **Status**: Proposed` を `- **Status**: Accepted` に、`docs/records/decisions/README.md` の 0028 行の `Proposed` を `Accepted` に変更。

- [ ] **Step 3: Issue-0007 を close**

`flow/0007-retrospective-issue-integration.md` を更新:
- `- **Status**: open` → `- **Status**: closed`
- `- **Opened**: 2026-07-05` の次行に `- **Closed**: 2026-07-05` を追加
- 「## 結論」の本文を `ADR-0028（振り返り課題の全件起票・issues の system/flow フォルダ分割）として決定し、本サイクルで実装した。` に置換

`docs/working/issues/README.md` の 0007 行の Status を `closed` に変更。

- [ ] **Step 4: ハンドオフを更新**

`docs/working/handoff/feature_retrospective-issue-integration.md` の完了済み/進行中/未着手タスクと Current Phase を実装完了状態に更新。

- [ ] **Step 5: コミット**

```bash
git add docs/records/decisions docs/working/issues docs/working/handoff/feature_retrospective-issue-integration.md
git commit -m "docs: ADR-0028 を Accepted に昇格し Issue-0007 を close（実装完了）"
```

---

## 完了後（plan のスコープ外、ユーザー判断）

- master への merge（superpowers:finishing-a-development-branch）
- merge 後の retrospective スキル起動（新起票フローの初回ドッグフーディング）
- プラグイン更新の実行（ユーザー操作）
