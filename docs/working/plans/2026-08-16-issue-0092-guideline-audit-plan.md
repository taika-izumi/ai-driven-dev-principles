# Issue-0092 ガイドライン全体棚卸し監査 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> **ただし Task 6・Task 9 はユーザーゲート（メインエージェントがユーザーへ提示して回答を待つ工程）であり、サブエージェントへ委譲しないこと。**

**Goal:** ADR-0100 が定める方法（全数台帳・二トラック判定・二段階プロセス）で、常時発火規範の一回限りの監査を実施し、分類案とユーザー判断の記録までを完成させる。

**Architecture:** Phase A（Task 1〜6）で台帳骨格＝「何を数えるか・どう数えるか」を確定してユーザー中間確認を得る。Phase B（Task 7〜10）で分子を集計し、分布 → 閾値提案 → 機械的分類の順で分類案を提示、ユーザー判断を別 ADR に記録して閉じる。方法の正本は ADR-0100（コミット `3a044ff`）であり、本計画はその写像である。判断（本サイクル）と改修（次サイクル Issue）を分離する。

**Tech Stack:** Markdown 文書のみ（コード変更なし）。計測は git log / grep / PowerShell。配布対象ソース（`skills/`・`dist/`・`template/`）には触れない（ADR-0100 Consequences）。

---

## 前提・横断規則（全タスク共通）

- 作業ディレクトリ: `D:\Dev\002_AiDev\MakeAiInstructions`（ブランチ `feature/issue-0092-guideline-audit`）
- **読むだけの対象**（変更禁止）: `skills/`・`dist/`・`template/`・`CLAUDE.md`・`CONTRIBUTING.md`・`docs/overview/`
- **作成・変更する対象**: `docs/records/audits/` 配下、（Task 10 のみ）`docs/records/decisions/`・`docs/working/issues/`
- コミットは pathspec 付き `git commit -- <paths>` を使う（Issue-0020。`docs/inbox/` と `docs/conversation_log.md` の未追跡ファイルを巻き込まないため）
- 実測値はすべて安定識別子（ADR・Issue・worklog id・コミットハッシュ）で出所を記す（ADR-0100 決定 2）
- 期待値の注記: 「2026-08-16 時点で N」と書かれた期待値は、以後のセッションで作業した場合は増えていてよい（≥N で判定する）

### 台帳（ledger.md）のレコード様式

ADR-0100 決定 4 の列定義を、1 規範 = 1 レコード（`###` ブロック）として実装する（18 フィールドは表 1 行に収まらないため。冒頭にサマリー表を併設し、行との対応は id で取る）。レコード雛形:

```markdown
### A-01: <規範名（単位）>

- 正本の所在: `<file>` の <節名 or 行範囲>
- 導入 ADR: ADR-NNNN
- 発火条件（ゲート）: <発動条件。無条件なら「常時」>
- 対象・対象外: 対象 | 対象外（理由: <発火機会が毎サイクル観測できない等>）
- 規範の型: 検査型 | 記録・証跡型 | 予防・閾値型
- 1 回あたりコスト: <読解・記録量の見積り 1 行>
- 発火機会数（分母）: <実測値>（期間: ADR-NNNN の日付〜2026-08-16。可測性: 実測 | 近似（<代替指標と限界>） | 不可測）
- 検出実績: 検出件数 <N> / 検出のあった発火回数 <M> / 出所: <id 列挙。なければ「なし」>
- 比または逸脱率: <値。構造判定トラックは「—（参考値）」>
- 検出力実証: <導入根拠事例を現手順に当てた結果 1 行。Phase B で記入> | 未実施
- 構造的基準: (a) 重複: <具体的な重複先 or なし> / (b) 出所: <プロジェクト数・モデル世代数・事例数> / (c) 受容のみ案: <実在有無と見送り理由の現在成立性> / (d) 退役条項の観測可能性: <観測可能 | 移譲型 | なし>
- 既存退役条項: <所在と条件文の転記 or なし>
- 判定の向き: <どちら向きの値が退役側か。Phase A で事前登録>
- トラック: 比判定 | 構造判定
- 分類案: keep | 簡素化 | 統合 | 退役候補 | 保留（観測継続: 計測点=<...> 再判定条件=<...>）（Phase B で記入）
- 根拠: <分類案の根拠 1〜3 行。出所 id 付き>
```

id の接頭辞は正本ファイル別に振る（A=CLAUDE.md、B=start-work、C=session-handoff、D=decision-log、E=CONTRIBUTING.md、F=worklog-record、G=subagent-dispatch、H=pre-finalization-review、I=その他スキル、J=docs/overview/ 3 文書）。

---

## Phase A: インベントリ確定

### Task 1: audits ディレクトリと索引の新設

**Files:**
- Create: `docs/records/audits/README.md`
- Create: `docs/records/audits/2026-08-16-guideline-process-audit/ledger.md`（骨格ヘッダのみ）

- [ ] **Step 1: 前提確認**

Run: `git branch --show-current` → Expected: `feature/issue-0092-guideline-audit`
Run: `Test-Path docs/records/audits` → Expected: `False`（新設であること）

- [ ] **Step 2: 索引 README を作成**

`docs/records/audits/README.md` に次の内容を書く:

```markdown
# Audits

一回限りの監査（棚卸し調査）の記録の索引。各監査はディレクトリ単位で追跡型の記録（確定後不変）として保管する。配置根拠は `docs/overview/folder-structure.md` の運用規約（種別サブフォルダはオンデマンド作成・列挙されていない新種別）による。

| 実施日 | 監査 | 方法の決定 | 結果の決定 |
|--------|------|-----------|-----------|
| 2026-08-16 | [ガイドライン常時発火規範の全数棚卸し](2026-08-16-guideline-process-audit/) | ADR-0100 | （Phase B 終了時に記入） |
```

- [ ] **Step 3: ledger.md の骨格ヘッダを作成**

`docs/records/audits/2026-08-16-guideline-process-audit/ledger.md` の冒頭に、タイトル・ADR-0100 への参照・「台帳のレコード様式」（本計画の雛形をそのまま転記）・空のサマリー表ヘッダを書く。

- [ ] **Step 4: コミット**

```powershell
git add docs/records/audits/
git commit -m "audit: Issue-0092 監査の置き場と台帳骨格を新設（ADR-0100 Phase A 開始）" -- docs/records/audits/
```

### Task 2: 正本群 18 ファイルの走査と規範の全数列挙

**Files:**
- Modify: `docs/records/audits/2026-08-16-guideline-process-audit/ledger.md`

- [ ] **Step 1: 正本群 18 ファイルの実在を確認**

Run: `(Get-ChildItem skills -Recurse -Filter SKILL.md).Count` → Expected: `13`
Run: `@('CLAUDE.md','CONTRIBUTING.md','docs/overview/principles.md','docs/overview/folder-structure.md','docs/overview/issue-management.md') | ForEach-Object { Test-Path $_ }` → Expected: `True` × 5
（合計 18。数が合わない場合は実態を優先し、ADR-0100 決定 3 の正本群リストとの差分をユーザーへ報告してから進む）

- [ ] **Step 2: 18 ファイルを 1 ファイルずつ読み、規範を列挙する**

各ファイルを Read し、「毎サイクル 1 回以上の発火機会がある工程・規範」を退役条項単位（ADR-0100 決定 1）で抽出する。発火機会が毎サイクル観測できないものも行として立て「対象外（理由付き）」と記す。この時点で埋めるフィールド: id / 規範名（単位） / 正本の所在 / 導入 ADR / 発火条件（ゲート） / 対象・対象外。後工程のフィールドは、分類案に `（Phase B で記入）`、検出力実証に `未実施` と書いておく（Task 8 Step 4 の検証 grep がこの文字列を数えるため、表記を揺らさない）。

- [ ] **Step 3: サマリー表を同期**

各レコードの id / 規範名 / 対象・対象外 / トラック（未定は空欄）をサマリー表へ転記する。
Run: `(Select-String -Path docs/records/audits/2026-08-16-guideline-process-audit/ledger.md -Pattern '^### ').Count` → Expected: サマリー表の行数と一致

- [ ] **Step 4: コミット**

```powershell
git commit -m "audit: 台帳骨格 v1（規範の全数列挙と対象判定）" -- docs/records/audits/
```

### Task 3: 分母（発火機会数）の実測

**Files:**
- Modify: `docs/records/audits/2026-08-16-guideline-process-audit/ledger.md`

- [ ] **Step 1: サイクル数の基礎データを取る**

Run: `(Select-String -Path docs/records/retrospectives/README.md -Pattern '^\| 2026-').Count` → Expected: 2026-08-16 時点で `34`（≥34 で判定）
各規範の導入 ADR の日付以降のサイクル数を、この一覧の行から数える（ADR-0100: 集計期間は導入 ADR の日付以降）。

- [ ] **Step 2: 消化記録の全履歴を復元する**

Run（Git Bash）: `git log -p -- docs/working/handoff/ | grep -E '^\+- 2026-.*(ADR=|worklog=)' | sed 's/^\+//' | sort -u | wc -l` → Expected: 2026-08-16 時点で ≥101
この復元行から、消化記録系規範（`review=` 49・`cyclecheck=` 4 ほか）の発火機会数・発火数を数える。

- [ ] **Step 3: worklog 中央ストアの件数を取る**

Run（Git Bash）: `wc -l ~/.ai-dev-worklog/MakeAiInstructions/log.jsonl` → Expected: ≥69
配布先分（LoopForAlpha 等）は分子の材料であり分母に入れない（ADR-0100 決定 2）。

- [ ] **Step 4: 各レコードの分母を記入**

発火機会数（実測値・期間・可測性）を全レコードに記入する。実測できない規範は「近似（代替指標と限界）」または「不可測」と明記する（例: subagent-dispatch の委譲回数はリポジトリに残らない → サイクル数で近似）。

- [ ] **Step 5: コミット**

```powershell
git commit -m "audit: 台帳 v2（発火機会数の実測と可測性判定）" -- docs/records/audits/
```

### Task 4: 型・トラック割当・判定の向き・退役条項の転記

**Files:**
- Modify: `docs/records/audits/2026-08-16-guideline-process-audit/ledger.md`

- [ ] **Step 1: 規範の型と 1 回あたりコストを記入**

検査型 / 記録・証跡型 / 予防・閾値型を全レコードに記入（ADR-0100 決定 2 の定義）。

- [ ] **Step 2: 既存退役条項を転記**

退役条項を持つ規範（少なくとも: サイクル全体整合検査 `skills/decision-log/SKILL.md` の退役節、過剰適合点検 `CONTRIBUTING.md` の退役条件、subagent-dispatch / pre-finalization-review / worklog 系の各退役規範節、ADR-0073）について、条項の所在と条件文を「既存退役条項」フィールドへ転記し、(d) の観測可能性（観測可能 | 移譲型）を判定する。

- [ ] **Step 3: 露出閾値を提案しトラックを割り当てる**

分母の分布を見て比判定トラックに入る露出閾値の数値案を作り、ledger.md 冒頭の「Phase A 提案」節に閾値案と根拠を書く。閾値案と可測性で全レコードのトラックを機械的に割り当てる（露出十分でも分母不可測は構造判定へ）。

- [ ] **Step 4: 判定の向きを事前登録**

全レコードに「判定の向き」を記入する（閾値の後決め抑止。ADR-0100 決定 2）。

- [ ] **Step 5: コミット**

```powershell
git commit -m "audit: 台帳 v3（型・トラック割当・判定の向き・退役条項転記・露出閾値案）" -- docs/records/audits/
```

### Task 5: 全数性の検証と中間確認資料の準備

**Files:**
- Modify: `docs/records/audits/2026-08-16-guideline-process-audit/ledger.md`

- [ ] **Step 1: 正本群 18 ファイルを再走査して取りこぼしを突合**

Task 2 とは別の手でもう一度走査する: 各ファイルに対し拘束表現の grep（`Select-String -Pattern 'こと$|必須|禁止|毎回|常に|必ず'` 等）を実行し、ヒット行が台帳のいずれかのレコード（対象外行を含む）に対応するかを 1 ファイルずつ確認する。取りこぼしがあればレコードを追加する。

- [ ] **Step 2: 被覆の完了基準を検証**

Run（Git Bash）: `grep -oE '正本の所在: \`[^\`]+\`' docs/records/audits/2026-08-16-guideline-process-audit/ledger.md | sort -u`
Expected: 出現するファイルパスの集合が正本群 18 ファイルを被覆している（18/18。ADR-0100 決定 3 の完了基準）

- [ ] **Step 3: 行数見積りとサマリー整合を確認**

Run: `(Select-String -Path docs/records/audits/2026-08-16-guideline-process-audit/ledger.md -Pattern '^### ').Count` → レコード総数を記録し、サマリー表の行数と一致することを確認する。

- [ ] **Step 4: コミット**

```powershell
git commit -m "audit: 台帳 v4（再走査による全数性検証。被覆 18/18）" -- docs/records/audits/
```

### Task 6: ユーザー中間確認（ユーザーゲート。委譲禁止）

- [ ] **Step 1: 中間確認を提示**

ユーザーへ次を提示し、番号付き選択肢で回答を得る: (1) 台帳のレコード総数と対象・対象外の内訳、(2) トラック割当の内訳と露出閾値案、(3) 再走査の突合結果（走査ファイル 18 件と取りこぼしの有無）、(4) 行数が人間のレビュー可能量を超える場合のスコープ再交渉案。

- [ ] **Step 2: 回答を反映**

修正指示があれば ledger.md へ反映して再提示する。承認が出たら Phase A 完了。承認後のマイルストーン処理（handoff 更新・worklog 記録）は start-work の Post ラッパーが担う（本計画の管轄外）。

- [ ] **Step 3: コミット**

```powershell
git commit -m "audit: Phase A 完了（台帳骨格のユーザー中間確認済み）" -- docs/records/audits/
```

---

## Phase B: 集計・分類・判断

### Task 7: 分子の集計と検出力の実証

**Files:**
- Modify: `docs/records/audits/2026-08-16-guideline-process-audit/ledger.md`

- [ ] **Step 1: 検出実績を全行で収集**

材料: `docs/records/retrospectives/README.md` の各サイクル行、Task 3 で復元した消化記録、worklog 中央ストア（配布先エントリ含む。出所プロジェクトを併記）、各 ADR の検出実績記述、検査由来の修正コミット。検査型は「検出件数」と「検出のあった発火回数」の 2 列で記録する。

- [ ] **Step 2: 予防・閾値型の逸脱率を実測**

例: handoff 節別 200 字規範は消化記録復元行の全角換算字数、サイズトリガーは git 全 blob の handoff 最大サイズ。違反件数 ÷ 適用機会を記入する。

- [ ] **Step 3: 比判定トラックの検出力を実証**

比判定トラックの各検査型規範について、導入根拠の欠陥事例（またはその同型）1 件を現在の手順に当てて検出できるかを確認し、結果を「検出力実証」に記入する。確認できない規範は比を使わず保留（観測継続）へ（再判定条件に検出力実証を含める）。実証・反証の実測は Issue-0042 へ追記する（Task 10 でまとめて行う）。

- [ ] **Step 4: 構造的基準 (a)〜(c) を記入**

全レコード（少なくとも構造判定トラックの全行）に、(a) 他規範との重複（具体的な重複先。検査三層が同じ成果物を読む型はここで突合する）、(b) 導入根拠の出所の広がり（導入 ADR の点検表・根拠節から出所プロジェクト数・モデル世代数・事例数を転記）、(c) 導入 ADR の Considered Alternatives に「変更ゼロ・受容のみ」案が実在するか、その見送り理由が現時点でも成立するか、を記入する（(d) は Task 4 Step 2 で記入済み）。

- [ ] **Step 5: 比・逸脱率を計算しコミット**

```powershell
git commit -m "audit: 台帳 v5（検出実績・逸脱率・検出力実証の集計）" -- docs/records/audits/
```

### Task 8: 分類案の作成と report.md

**Files:**
- Create: `docs/records/audits/2026-08-16-guideline-process-audit/report.md`
- Modify: `docs/records/audits/2026-08-16-guideline-process-audit/ledger.md`（分類案・根拠列）

- [ ] **Step 1: 分布・ランキングを作る**

トラック別に比・逸脱率のランキング表を report.md に書く（分類案より先に書く。提示順の分離。ADR-0100 決定 2）。

- [ ] **Step 2: 閾値を提案し機械的に分類**

分布に当てた閾値案と根拠を書き、Phase A で事前登録した「判定の向き」と閾値から全レコードの分類案を機械的に導く。**既存退役条項を持つ規範は、条項の条件の成否を先に判定し、比・構造的基準はそれを補う材料とする**（ADR-0100 決定 2「既存退役条項の優先」。条項が退役不可を示す規範は比の値によらず退役候補にしない）。構造判定トラックは既定＝保留（観測継続）とし、退役候補へ振る条件（(a) 具体的重複先 or (c) 受容のみ案の見送り理由の崩れ）の該当だけ例外とする。保留には計測点と再判定条件を観測可能な形で必ず付す。

- [ ] **Step 3: 仮説 3 領域の検証結果を書く**

Issue-0092 の仮説 3 領域（検査三層の重複・証跡台帳系の増殖・Post ラッパー 4 項目）それぞれに支持 / 不支持 / 判定保留と根拠行 id を report.md へ書く。

- [ ] **Step 4: 整合検証とコミット**

Run（Git Bash）: `grep -c '分類案: （Phase B で記入）' docs/records/audits/2026-08-16-guideline-process-audit/ledger.md` → Expected: `0`（未記入の分類案が残っていない）
分類案が「判定の向き」の事前登録と矛盾する行がないか全行確認する。

```powershell
git add docs/records/audits/
git commit -m "audit: 分類案と report（分布→閾値→機械的分類、仮説 3 領域の検証）" -- docs/records/audits/
```

### Task 9: Phase B ユーザー判断（ユーザーゲート。委譲禁止）

- [ ] **Step 1: 分類案・歯止め方針案・消費装置要否を提示**

report.md の内容（ランキング → 閾値案 → 分類案の順）に加え、(i) 歯止め（ADR-0099 の複雑化抑制制約の一般規範化）の方針案、(ii) 保留 Issue の消費装置の要否（retrospective 接続 / worklog-extract 退役候補走査〈Issue-0048 の設計〉/ 新設せず）をユーザーへ提示し、規範ごとの分類と方針の判断を得る。

- [ ] **Step 2: 判断を反映**

修正・差し戻しがあれば ledger.md / report.md へ反映して再提示する。

### Task 10: 結果の確定（結果 ADR・Issue 起票・close 処理）

**Files:**
- Create: `docs/records/decisions/0101-<slug>.md`（結果 ADR。番号は作成時にインデックスから採番し直す）
- Modify: `docs/records/decisions/README.md`（行追加）
- Modify: `docs/records/audits/README.md`（「結果の決定」列に ADR 番号）
- Modify: `docs/records/audits/2026-08-16-guideline-process-audit/report.md`（ユーザー判断は ADR 番号ポインタのみ追記）
- Create/Modify: `docs/working/issues/` 配下（次サイクル Issue の起票、Issue-0092 close、Issue-0042/0045/0048 への追記、インデックス更新）

- [ ] **Step 1: 結果 ADR を作成**

`decision-log` スキルの手順で、ユーザー判断の結果（規範ごとの分類の確定・歯止めの方針・消費装置の要否）を ADR に記録する（これが判定結果の正本。ADR-0100 決定 4）。

- [ ] **Step 2: 台帳・報告・索引を確定**

report.md 末尾に「ユーザー判断の結果: ADR-NNNN 参照」のポインタを追記し、audits/README.md の「結果の決定」列を埋める。以後 ledger.md / report.md は不変（ADR-0100 決定 4 の確定時点）。

- [ ] **Step 3: Issue の起票・追記・close**

課題管理定義（`docs/overview/issue-management.md`）に従い: 改修が決まった規範の次サイクル Issue を起票、保留（観測継続）の再判定条件付き Issue を起票、検出力の実証・反証を Issue-0042 へ追記、重なる知見があれば Issue-0045・Issue-0048 へ追記。Issue-0092 は Status を closed にし、結論へ ADR-0100 と結果 ADR の番号を記載、インデックスを更新する。追記した課題ファイルはサイズ実測（目安 10KB）を行う。

- [ ] **Step 4: コミット**

```powershell
git add docs/records/ docs/working/issues/
git commit -m "audit: 監査結果の確定（結果 ADR・Issue 起票・Issue-0092 close）" -- docs/records/ docs/working/issues/
```

- [ ] **Step 5: 完了処理への引き継ぎ**

ADR-0100・結果 ADR の Accepted 昇格（サイクル全体整合検査を含む）、マージ・retrospective・cycle-reset は start-work のセッション終了処理・完了フローが担う（本計画の管轄外。昇格前の検査発動判定では、本サイクルの変更に規範・手順文書が含まれないことを実測で確認する）。

---

## 検証期待値の一覧（計画確定時の突合用）

| 期待値 | 出所 | 対応タスク |
|---|---|---|
| skills/*/SKILL.md = 13 本 | 2026-08-16 実測（レビュー時） | Task 2 Step 1 |
| 正本群 = 18 ファイル・被覆 18/18 | ADR-0100 決定 3 | Task 2 Step 1 / Task 5 Step 2 |
| retrospectives サイクル行 ≥34 | 2026-08-16 実測 | Task 3 Step 1 |
| 消化記録の復元ユニーク行 ≥101 | 2026-08-16 実測（レビュー時） | Task 3 Step 2 |
| 本 repo worklog ≥69 件 | 2026-08-16 実測 | Task 3 Step 3 |
| 分類案の未記入 = 0 | 台帳の全行判定 | Task 8 Step 4 |
| レコード数 = サマリー表行数 | 台帳の内部整合 | Task 2 Step 3 / Task 5 Step 3 |
