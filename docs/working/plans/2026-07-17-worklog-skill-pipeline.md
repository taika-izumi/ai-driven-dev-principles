# 作業記録→候補抽出→スキル化 3スキルパイプライン 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** メインエージェントの作業 delta を継続記録し、横断抽出してスキル/ルールへ昇華する3スキル（worklog-record / worklog-extract / worklog-skillify）を本リポジトリのプラグインへ追加する。

**Architecture:** 3スキルは中央ストア（`<home>/.ai-dev-worklog/`）を共有データ契約として読み書きする。worklog-record は start-work の Post ラッパーに配線して全プロジェクトのマイルストーンで発火。worklog-extract はオンデマンド走査→クラスタリング→人間採否→Issue 草案化。worklog-skillify は writing-skills 委譲＋スコープ3分岐＋実行環境ガード。

**Tech Stack:** Markdown スキル（frontmatter `name`/`description` ＋ 本文）。プラグイン `ai-driven-dev-principles`（`skills/` 自動検出）。中央ストアは素の JSON/JSONL ファイル（v1 は実行コードなし）。

**参照 spec:** `docs/current/specs/2026-07-17-worklog-skill-pipeline/`（00-overview ＋ 01〜04）。各タスクは対応する spec ブロックを正典とする。
**参照 ADR:** 0044（集約アーキ）/ 0045（スキーマ・ライフサイクル）/ 0046（skill3 エンジン・借用・ガード）/ 0047（start-work 配線）。

**検証の方針:** スキルは Markdown 指示文でありコード自動テストの対象外。各タスクは「受入チェック（grep / ls で観測可能な条件）を定義 → 現状未達を確認 → authoring → 達成を確認 → commit」のサイクルで進める。最後に実プラグイン更新＋スモークテスト（実記録1件を通す）で end-to-end を確認する。

**共通ルール:**
- master 直接作業は禁止。本作業は feature ブランチ `feature/worklog-skill-pipeline` 上で行う
- コミットのマルチライン文字列は `git commit -F <file>`。未追跡ファイルは先に `git add`
- skills/ 編集はプラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）まで反映されない。sync-template は不要（template は skills/ を含まない）

---

## Task 1: 共有ストア契約 store-format.md

**Files:**
- Create: `skills/worklog-record/references/store-format.md`

正典（single source of truth）。spec `01-worklog-store.md` の内容をスキル参照ドキュメントとして固定する。skill2/skill3 doc はこのファイルを参照する。

- [ ] **Step 1: 受入チェックを定義し現状未達を確認**

Run: `ls skills/worklog-record/references/store-format.md`
Expected: `No such file or directory`（未作成）

- [ ] **Step 2: store-format.md を作成**

以下の内容で作成する（spec 01 の「データモデル」「制約・前提」を正典として転記・確定）:

````markdown
# 中央ストア フォーマット（worklog パイプライン共有契約）

3スキル（worklog-record / worklog-extract / worklog-skillify）が共通で読み書きする中央ストアの契約。これを変更すると3スキルすべてに影響する。

## 配置

- ルート: `<home>/.ai-dev-worklog/`（`$HOME` / `%USERPROFILE%` で解決。ツール中立名）
- `<home>/.ai-dev-worklog/projects.json` — プロジェクト識別子リスト
- `<home>/.ai-dev-worklog/<folderName>/log.jsonl` — プロジェクトごとの作業ログ（追記専用）
- `<home>/.ai-dev-worklog/processed.jsonl` — 処理済み台帳（追記専用）

このストアはリポジトリ外・中央集約であり、`docs/overview/folder-structure.md` の5分類の**管轄外**である（records と混同しないこと）。

## projects.json

```json
{
  "MakeAiInstructions": { "path": "D:/Dev/002_AiDev/MakeAiInstructions", "lastSeen": "2026-07-17" }
}
```

- キー = プロジェクトのルートフォルダ名（実パスは使わない）
- 値 = 現在の絶対パス＋最終更新日（YYYY-MM-DD）

### 識別子解決の規則

- **upsert（自己修復）**: 記録のたび、フォルダ名をキーに実パスを最新へ更新。フォルダ名が同じならプロジェクトを移動しても次回自動修正される
- **衝突判定**: フォルダ名がリストにあり実パスが違う場合 —
  - 旧パスがまだ存在 → 別プロジェクトの同名（フォルダ名にサフィックスを付けて別エントリを追加）
  - 旧パスが消失 → 同一プロジェクトの移動（パスを更新）

## エントリ（log.jsonl、1行1エントリ、追記専用）

必須（いずれか空なら記録を弾く）: `id` / `date` / `project` / `scope` / `title` / `context` / `procedure`
delta ペア（`friction` または `corrections` の少なくとも一方が必須）: `friction` / `corrections`
任意: `skillification_hint` / `outcome`（success/partial/failed＝作業結果）/ `tools` / `applied_rules`（逸脱注記可）/ `refs`

| フィールド | 型 | 説明 |
|---|---|---|
| `id` | string | `<project>-<date>-<NN>`。台帳との突合キー |
| `date` | string | YYYY-MM-DD |
| `project` | string | 出所プロジェクト名（連結後も行内で出所が分かる） |
| `scope` | enum | `project-specific` / `general-candidate`（record 時は暫定） |
| `title` | string | 動詞句15文字程度 |
| `context` | string | 何をしていてなぜ発生したか |
| `procedure` | string[] | 実際に踏んだ手順 |
| `friction` | string | 躓き型 delta |
| `corrections` | string[] | 注入型 delta（人間の指示・修正を発言に近い形で） |

### id 採番アルゴリズム

1. `date` = 今日（YYYY-MM-DD）、`project` = フォルダ名
2. `<folderName>/log.jsonl` を読む（無ければ NN=01）
3. 同一 `project` かつ同一 `date` のエントリ数を数え、その数+1 を2桁ゼロ埋めして NN とする
4. `id = "<project>-<date>-<NN>"`

## 台帳レコード（processed.jsonl、1行1レコード、追記専用）

```jsonl
{"id":"MakeAiInstructions-2026-07-16-01","outcome":"skillified","ref":"skills/xxx","date":"2026-07-20"}
{"id":"LoopForAlpha-2026-07-18-03","outcome":"deferred","evidence_count":2,"date":"2026-07-20"}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `id` | string | 対象エントリまたはクラスタ代表の id |
| `outcome` | enum | `skillified` / `rejected` / `merged` / `deferred`（**採否結果**。エントリ側 outcome とは別物） |
| `evidence_count` | number | `deferred` のときのみ。保留時点のクラスタ根拠数 |
| `ref` | string | 任意。skillified/merged 時の作成先 |
| `date` | string | 台帳追記日 |

すべて追記専用で in-place 書き換えを避ける（projects.json のみ全体読み書きの upsert）。git 管理は v1 ではオプション。
````

- [ ] **Step 3: 受入チェックで達成を確認**

Run: `grep -c "id 採番アルゴリズム\|processed.jsonl\|deferred\|evidence_count" skills/worklog-record/references/store-format.md`
Expected: `4` 以上（各キーワードが存在）

- [ ] **Step 4: Commit**

```bash
git add skills/worklog-record/references/store-format.md
git commit -F <msgfile>
# msg: "feat(worklog): 共有ストア契約 store-format.md を追加（ADR-0044/0045）"
```

---

## Task 2: worklog-record スキル本体

**Files:**
- Create: `skills/worklog-record/SKILL.md`

spec `02-skill1-record.md` を正典とする。

- [ ] **Step 1: 受入チェックを定義し現状未達を確認**

Run: `ls skills/worklog-record/SKILL.md`
Expected: `No such file or directory`

- [ ] **Step 2: SKILL.md を作成**

frontmatter は以下を厳守（description はトリガー明確化のため「作業の節目で delta を記録」を核にする）:

```markdown
---
name: worklog-record
description: "作業の節目（スキル完了・plan タスク完了・重要な分岐通過）で、AI のデフォルト挙動と実際に必要だったことの差分（delta）を中央ストアへ1件記録する。start-work の Post ラッパーから発火。記録ゲート（既存スキルで実施済みでない かつ AI 自律で毎回再現できない）を満たす場合のみ追記する。"
---
```

本文に以下のセクションを必ず含める:

1. `## いつ使うか` — start-work の Post ラッパーから、handoff update と同じマイルストーン契機で呼ばれる。手動起動も可
2. `## 記録ゲート判定` — spec 02 のサブ機能1・2。(a) 既存スキルで実施済みでない かつ (b) AI 自律で毎回再現できない、を満たさなければ記録しない。判定の実効ルール＝**delta（friction または corrections）が少なくとも一方存在するか**。両方空なら記録しない（純粋判断型は弾く）
3. `## 手順` — 以下の順:
   1. 記録ゲート判定（delta の有無）。不成立なら「記録なし」で終了
   2. delta 抽出（friction＝躓き・手戻り・非自明な試行錯誤 / corrections＝人間が注入した指示・修正を発言に近い形で1〜2行）
   3. 識別子解決: `references/store-format.md` の upsert 規則で projects.json を更新
   4. id 採番: `references/store-format.md` の採番アルゴリズム
   5. scope 暫定タグ付け（project-specific / general-candidate）
   6. 必須フィールドを埋め、delta 必須を検証してから `<folderName>/log.jsonl` へ1行 append
4. `## ストア仕様` — `references/store-format.md` を参照するよう明記
5. `## 対応する原則` — 原則1（追跡可能性）・原則2（関心の分離: 重い横断分析は worklog-extract へ遅延）

具体例（本文に含める）: spec 02 と store-format の JSONL 例を1件掲載。

- [ ] **Step 3: 受入チェックで達成を確認**

Run: `grep -l "^name: worklog-record" skills/worklog-record/SKILL.md && grep -c "記録ゲート\|delta\|id 採番\|store-format" skills/worklog-record/SKILL.md`
Expected: ファイルパスが出力され、カウントが `4` 以上

- [ ] **Step 4: Commit**

```bash
git add skills/worklog-record/SKILL.md
git commit -F <msgfile>
# msg: "feat(worklog): worklog-record スキルを追加（ADR-0044/0045）"
```

---

## Task 3: start-work の Post ラッパーへ worklog-record を配線

**Files:**
- Modify: `skills/start-work/SKILL.md`（「横断的ラッパー」→「Post（実行後）」節）

ADR-0047 を正典とする。既存の「2. ハンドオフ更新」の隣に worklog-record 実行判定を追加する。

- [ ] **Step 1: 追加前の状態を確認**

Run: `grep -n "ハンドオフ更新\|worklog-record" skills/start-work/SKILL.md`
Expected: `ハンドオフ更新` の行が1件、`worklog-record` は0件

- [ ] **Step 2: Post ラッパーへステップを追加**

`**Post（実行後）:**` の「2. ハンドオフ更新」の直後に、新ステップとして以下を挿入する（番号は繰り下げ）:

```markdown
3. **作業記録の追記**: マイルストーン到達時、`worklog-record` スキルを呼ぶ。worklog-record が記録ゲート（既存スキルで実施済みでない かつ AI 自律で毎回再現できない＝delta が存在する）を自己判定し、満たさなければ記録しない。session-handoff update と同じ契機（スキル完了 / plan の1タスク完了 / 重要な分岐通過）で発火する（ADR-0047）
```

既存の「3. 次手ナビゲーションへ復帰」は「4.」へ繰り下げる。

- [ ] **Step 3: 追加後の状態を確認**

Run: `grep -n "worklog-record\|次手ナビゲーションへ復帰" skills/start-work/SKILL.md`
Expected: `worklog-record` の行が1件以上、`次手ナビゲーションへ復帰` が残っている

- [ ] **Step 4: Commit**

```bash
git add skills/start-work/SKILL.md
git commit -F <msgfile>
# msg: "feat(worklog): start-work Post に worklog-record 配線を追加（ADR-0047）"
```

---

## Task 4: worklog-extract スキル本体

**Files:**
- Create: `skills/worklog-extract/SKILL.md`

spec `03-skill2-extract.md` を正典とする。

- [ ] **Step 1: 受入チェックを定義し現状未達を確認**

Run: `ls skills/worklog-extract/SKILL.md`
Expected: `No such file or directory`

- [ ] **Step 2: SKILL.md を作成**

frontmatter:

```markdown
---
name: worklog-extract
description: "中央ストアに蓄積された作業ログをオンデマンドで走査し、スキル化・ルール化する価値のある候補をクラスタリング・評価してランク付き候補リストとして人間に提示する。処理済み台帳で既処理を除外し、人間の採否を Issue 草案と台帳へ反映する。ユーザーが明示的に実行するスキル。"
---
```

本文セクション（spec 03 のサブ機能を手順化）:

1. `## いつ使うか` — ユーザーのオンデマンド実行（自動起動しない）
2. `## 入力` — `references` として worklog-record の `store-format.md` を参照（`skills/worklog-record/references/store-format.md`）。入力＝projects.json ＋ 全 log.jsonl ＋ processed.jsonl
3. `## 手順`:
   1. 台帳前処理: processed.jsonl を読み、処理済み id（skillified/rejected/merged）を除外。deferred は evidence_count とともに保持
   2. サブエージェント走査: 全 log.jsonl を1パスで読み、類似エントリをクラスタリング（メインコンテキストに載せない）
   3. クラスタ評価: 横断再発回数・出所プロジェクト数・friction/corrections 重みを集計
   4. scope 再判定: ≥2プロジェクト再発→general-candidate 格上げ、単一・ドメイン依存→project-specific
   5. 既存スキル重複排除: superpowers ＋ ai-driven-dev-principles ＋ プロジェクトローカルの description と突合
   6. deferred 再浮上判定: 現クラスタ根拠数 > 台帳 evidence_count のときのみ再提示
   7. 候補提示: ランク付き候補リスト（再発数・scope・重複有無・根拠エントリ参照）。頻度はソフト判断材料（ハード閾値なし）
   8. 人間採否 → rejected/deferred は即 processed.jsonl へ追記（deferred は evidence_count に現根拠数）／採用は Issue 草案化して worklog-skillify へ受け渡し
4. `## 出力` — ランク付き候補リスト、Issue 草案（`docs/working/issues/`）、台帳追記（rejected/deferred）
5. `## 再提案防止（二層）` — ①台帳（厳密）②既存スキル重複排除（あいまい）
6. `## スコープ外` — 出力3（既存ルール改訂候補発見）は v1 では作らない（逸脱注記データは貯めるが提示しない）
7. `## 対応する原則` — 原則3（サブエージェント委譲）・原則4（人間採否）

- [ ] **Step 3: 受入チェックで達成を確認**

Run: `grep -l "^name: worklog-extract" skills/worklog-extract/SKILL.md && grep -c "クラスタ\|処理済み\|deferred\|Issue 草案\|重複排除" skills/worklog-extract/SKILL.md`
Expected: ファイルパスが出力され、カウントが `5` 以上

- [ ] **Step 4: Commit**

```bash
git add skills/worklog-extract/SKILL.md
git commit -F <msgfile>
# msg: "feat(worklog): worklog-extract スキルを追加（ADR-0044/0045）"
```

---

## Task 5: worklog-skillify の借用技術リファレンス

**Files:**
- Create: `skills/worklog-skillify/references/skill-authoring-techniques.md`

ADR-0046（設計時借用）を正典とする。Skill Creator の2技術（description 自動最適化・定量 eval ループ）を**自前の言葉で蒸留**したリファレンス。実行時に Skill Creator をロードしないための内包。

> 実装メモ: Anthropic Skill Creator スキルがこの環境で参照可能なら、まず一読して手法を精緻化する。参照不可でも下記の蒸留内容で v1 は成立する（手法は安定）。

- [ ] **Step 1: 現状未達を確認**

Run: `ls skills/worklog-skillify/references/skill-authoring-techniques.md`
Expected: `No such file or directory`

- [ ] **Step 2: リファレンスを作成**

以下の内容で作成:

````markdown
# スキル authoring 技術（Skill Creator からの設計時借用）

worklog-skillify が writing-skills 委譲時に併用する2技術。実行時に Skill Creator はロードせず、本リファレンスを参照する（ADR-0046）。

## 技術1: description 自動最適化

スキルの `description` はトリガー評価に使われる。以下を満たすよう最適化する:
- **いつ使うか**を先頭に置く（「〜する時に使う」）。抽象的な機能説明より発火条件を優先
- トリガーとなる**具体語・同義語**を含める（ユーザーが使いそうな語彙）
- 「〜でない場合は使わない」の**除外条件**を1つ添えて誤爆を減らす
- 1〜3文、能動的・具体的に。曖昧語（「様々な」「適切に」）を避ける

チェック: 作成した description を読み、「どんな入力でこのスキルが呼ばれるべきか」が第三者に一意に伝わるか自己評価する。

## 技術2: 定量 eval ループ

スキルが意図どおり発火・機能するかを小さな eval で確認する:
1. **eval ケースを3〜5件用意**（発火すべき入力・発火すべきでない入力の両方）
2. 各ケースでスキルの description/手順に照らし、期待どおりか判定
3. 誤発火・不発火があれば description か手順を修正
4. 全ケース通過まで反復

v1 は手動 eval（人間 or サブエージェントが判定）。自動 eval ハーネスは作らない（YAGNI）。
````

- [ ] **Step 3: 達成を確認**

Run: `grep -c "description 自動最適化\|eval ループ\|誤爆\|eval ケース" skills/worklog-skillify/references/skill-authoring-techniques.md`
Expected: `3` 以上

- [ ] **Step 4: Commit**

```bash
git add skills/worklog-skillify/references/skill-authoring-techniques.md
git commit -F <msgfile>
# msg: "feat(worklog): skill authoring 借用技術リファレンスを追加（ADR-0046）"
```

---

## Task 6: worklog-skillify スキル本体

**Files:**
- Create: `skills/worklog-skillify/SKILL.md`

spec `04-skill3-skillify.md` を正典とする。

- [ ] **Step 1: 現状未達を確認**

Run: `ls skills/worklog-skillify/SKILL.md`
Expected: `No such file or directory`

- [ ] **Step 2: SKILL.md を作成**

frontmatter:

```markdown
---
name: worklog-skillify
description: "worklog-extract で採用された候補から、writing-skills 委譲で新規スキル作成または既存スキル拡張を行う。スコープ（汎用/プロジェクト固有/固有ルール）で成果物の配置先を振り分け、汎用パスを本 repo 以外で実行しようとした場合は警告する。ユーザーまたは worklog-extract から起動。"
---
```

本文セクション:

1. `## いつ使うか` — worklog-extract の採用候補を受けて起動（手動も可）
2. `## 実行環境ガード` — スキル冒頭で本 repo（ai-driven-dev-principles）かを判定する。判定＝`git remote -v` の URL に `ai-driven-dev-principles` を含む、または `.claude-plugin/plugin.json` の `name` が `ai-driven-dev-principles`。**汎用（プラグイン配信）パス かつ 本 repo でない**場合は警告＋ユーザー確認（①この場のプロジェクトローカルスキルとして作成 ②配信元 repo へ移動して実行 ③中止）。固有パスはガード不要
3. `## スコープ3分岐（振り分け）`:
   - 汎用 → 本 repo のプラグイン配信スキル（`skills/`）
   - プロジェクト固有だが価値あり → そのプロジェクトのローカルスキル（`.claude/skills/`）
   - 固有ルールでスキル化不要 → そのプロジェクトの CLAUDE.md
4. `## 手順`:
   1. 実行環境ガード判定 → 必要なら警告＋確認
   2. スコープで振り分け先決定
   3. writing-skills へ委譲。`references/skill-authoring-techniques.md` の description 最適化・eval ループを併用（Skill Creator は実行時ロードしない）
   4. 汎用パスは既存「Issue → extend-guidelines → スキル作成」フローへ橋渡し
   5. 作成/拡張完了後、`processed.jsonl` へ結果を追記（skillified＝新規 / merged＝既存へ統合）
5. `## 対応する原則` — 原則2（薄いオーケストレーション層）・原則4（環境ガードの人間確認）

- [ ] **Step 3: 達成を確認**

Run: `grep -l "^name: worklog-skillify" skills/worklog-skillify/SKILL.md && grep -c "実行環境ガード\|スコープ\|writing-skills\|processed.jsonl\|skill-authoring-techniques" skills/worklog-skillify/SKILL.md`
Expected: ファイルパスが出力され、カウントが `5` 以上

- [ ] **Step 4: Commit**

```bash
git add skills/worklog-skillify/SKILL.md
git commit -F <msgfile>
# msg: "feat(worklog): worklog-skillify スキルを追加（ADR-0044/0046）"
```

---

## Task 7: 統合検証・プラグイン更新・ADR 昇格・完了

**Files:**
- Modify: `docs/records/decisions/0044〜0047`（Status を Accepted へ）＋ `docs/records/decisions/README.md`
- Modify: `docs/current/specs/2026-07-17-worklog-skill-pipeline/00-overview.md`（完了基準チェック）
- Modify: `docs/working/handoff/master.md`

- [ ] **Step 1: 構造セルフチェック（全ファイル存在）**

Run: `ls skills/worklog-record/SKILL.md skills/worklog-record/references/store-format.md skills/worklog-extract/SKILL.md skills/worklog-skillify/SKILL.md skills/worklog-skillify/references/skill-authoring-techniques.md`
Expected: 5ファイルすべて存在

- [ ] **Step 2: frontmatter 妥当性チェック**

Run: `grep -h "^name:" skills/worklog-record/SKILL.md skills/worklog-extract/SKILL.md skills/worklog-skillify/SKILL.md`
Expected: `name: worklog-record` / `name: worklog-extract` / `name: worklog-skillify` の3行

- [ ] **Step 3: プラグイン更新（ユーザーに依頼）**

ユーザーに次を依頼: プロンプトで `! /plugin marketplace update ai-driven-dev-principles` 実行（skills/ 改定の反映）。
その後、`/skills` 一覧に worklog-record / worklog-extract / worklog-skillify が現れることを確認する。

- [ ] **Step 4: スモークテスト（end-to-end 1件）**

worklog-record を手動起動し、記録ゲートを満たすダミー作業（例: 本タスクで踏んだ非自明手順）で1エントリを記録させる。
Run: `cat "$HOME/.ai-dev-worklog/"*/log.jsonl | tail -1`
Expected: 必須フィールド（id/date/project/scope/title/context/procedure）と delta（friction または corrections）を持つ JSONL が1行出力される。id が `<project>-<date>-<NN>` 形式であること。
続けて worklog-extract を起動し、その1件を含む候補リストが提示されること（採否は保留でよい）を確認する。

- [ ] **Step 5: 完了基準チェック（spec 00）**

`docs/current/specs/2026-07-17-worklog-skill-pipeline/00-overview.md` の「完了基準」チェックボックスを実測に基づき更新する（実装済み項目に `[x]`）。

- [ ] **Step 6: ADR 0044〜0047 を Accepted へ昇格**

実装完了・検証後、4件の Status を Accepted へ（ADR-0019 の「承認の昇格」手順）:
- 各 ADR ファイルの `Status: Proposed` → `Status: Accepted`
- `docs/records/decisions/README.md` のテーブルの当該4行を Accepted へ

- [ ] **Step 7: handoff 更新＋最終コミット**

`session-handoff` の update で master.md を最新化（実装完了・Accepted 昇格を反映）。

```bash
git add docs/records/decisions/ docs/current/specs/2026-07-17-worklog-skill-pipeline/00-overview.md docs/working/handoff/master.md
git commit -F <msgfile>
# msg: "feat(worklog): 3スキルパイプライン実装完了・ADR 0044-0047 を Accepted へ昇格"
```

---

## Self-Review（計画者チェック済み）

- **spec 網羅**: 01→Task1、02→Task2＋Task3（start-work 配線）、03→Task4、04→Task5＋Task6。00 完了基準→Task7。ADR-0047→Task3。網羅を確認
- **プレースホルダ**: 各 SKILL.md は frontmatter を確定文で、本文は必須セクションと具体アルゴリズム（id 採番・ゲート・環境ガード・upsert）を明示。詳細プロセスは spec ブロックを正典参照（別ファイル重複を避ける本 repo 規約に沿う）
- **型/名称整合**: スキル名（worklog-record/extract/skillify）、ストアのフィールド名（id/scope/friction/corrections、台帳 outcome=skillified/rejected/merged/deferred、evidence_count）は全タスクで一致。store-format.md を single source とし skill2/skill3 が参照
- **検証整合**: 各受入チェックの grep キーワードは、そのタスクが実際に書く内容（記録ゲート・delta・クラスタ・環境ガード等）と一致（ADR-0034）
