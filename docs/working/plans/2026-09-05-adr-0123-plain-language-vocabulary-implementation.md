# ガイドライン文書の分かりにくい語の置き換え 実装計画

> **実行者へ**: 本計画は `superpowers:subagent-driven-development` または `superpowers:executing-plans` でタスク単位に実行する。手順はチェックボックス（`- [ ]`）で追跡する。

**目的**: ガイドライン文書に含まれる分かりにくい語・記号的なラベル・見出しの名前を平易な語へ置き換え、再流入を防ぐ置き換え表と 1 行の規範を配布する。

**進め方**: 語の置き換えは機械的な一括置換をせず、語ごとに全出現を列挙して 1 件ずつ文脈を見て直す。名前の変更は定義箇所を先に、参照箇所を後に行う。各タスクの終わりに差分を取り、列挙外の変更がないことを確認してからコミットする。

**対象と規模**（2026-09-05 実測。確定前レビューで再実測し訂正）: **54 ファイル**。件数は設計書の設計 2 の表の合計で 群 A 348・群 B 2・群 C 48・群 D 277、総計 675 件。

> **件数は数え方で変わる目安値である**。当初は群 D を 283 件・総計 681 件と書いていたが、これは設計書が対象外と明記した裸の `(i)` `(ii)` 6 件（`2026-08-13-handoff-bloat-control/00-overview.md` 3 件・`2026-08-28-start-work-responsibility-split-design.md` 3 件）を含めた誤りだった。訂正後の 277 は設計書の表の合計と一致する。
>
> ただし別の数え方では別の値になる。`退役経路` は `退役` にも一致するため両方を数えると二重になり、`プロジェクト識別子` を除外するかでも 4 件動く。Task 14 の完了検証のパターン集合で数えると群 D は 287 件になる。**件数は作業量の目安としてのみ使い、完了の判定には使わない**（完了の判定は Task 14 の「残存 0」で行う）。ファイル数 54 は数え方に依らない。

> **検証コマンドの注意**: 否定後読み・否定先読み（`(?<!...)`・`(?!...)`）は PCRE 専用の書き方で、`grep -E` は解釈せずエラーも出さずに常に 0 件を返す。本環境の `grep -P` も `-P supports only unibyte and UTF-8 locales` で失敗する。この種の検査は本計画では Python の `re` で行う（`LC_ALL=C.UTF-8 grep -P` でも動くが、Task 14 の完了検証と書き方を揃える）。

**正本**: 設計書 `docs/current/specs/2026-09-04-plain-language-vocabulary-design.md`（確定済み）／ADR-0123。

---

## 逸脱判断の既定

既定どおり（`skills/start-work/references/plan-deviation-defaults.md`。plugin 0.1.18 時点の版）。基準の追加・強化はしない。

確定前レビューからの引き継ぎ一覧: なし（全観点レビュー 3 回で不採用として実装時レビューへ委ねた指摘は無い。第 3 回の 14 件は全件反映済み）。

本計画の全帰結は、当該タスクの最後の手順の直後へ行頭 `逸脱記録:` の 1 行で残す。

---

## 語の置き換え表（全タスク共通の参照）

### 型 1（語の置き換え）

| 置き換え前 | 置き換え後 |
|---|---|
| 突合 | 照合 |
| 消化記録 | 節目ごとの確認記録（見出し）／確認の記録（文中） |
| 未消化 | 未記録 |
| 消化漏れ | 記録漏れ |
| 消化結果 | 実施結果 |
| 消し込み・消し込む | 1 つずつ確認して記録する |
| 母数 | 対象の総数 |
| 裁定 | 判断 |
| 前置（動詞） | 前に付ける |
| 前置（名詞。接頭辞の意味） | 接頭辞 |
| 現役性 | 有効性 |
| 現役 | 有効 |
| 配線（動詞） | 接続する |
| 配線（名詞） | 接続の記述 |
| 射程外 | 範囲外 |
| 射程 | 範囲 |
| 巡 | 回 |
| 実質収束 | 実質的な収束 |
| 格下げ | 独立レビューへの切り替え |
| 逐語厳守 | 計画のコードをそのまま書き写す方式 |
| 退役 | 廃止 |
| 識別子（`出所識別子`・`安定識別子`・`プロジェクト識別子` を除く） | 参照番号（他文書から指すための番号）／見出しや書式の名前（文書の構造に付けた名前） |
| 検出資産 | 継続して検査する仕組み |
| 機械的な適応 | 実体に合わせる調整 |

**据え置く語**: 正本・確定点・移設・写経・発火・陳腐化・ADR・出所識別子・安定識別子・プロジェクト識別子・素の。

`プロジェクト識別子`（プロジェクトを一意に特定する鍵の意）は、上の 2 通りの言い換え（参照番号／見出しや書式の名前）のどちらにも当たらない第 3 の用法なので据え置く（確定前レビューで検出。`skills/worklog-record/references/store-format.md` 1 件・`docs/current/specs/2026-07-17-worklog-skill-pipeline/` 4 件）。

### 記号的ラベル

| 置き換え前 | 置き換え後 |
|---|---|
| A 群 | 常時適用（定義見出し）／常時適用の 4 件（参照） |
| B 群 | 条件発火（定義見出し）／条件発火の判定（参照） |
| Post ラッパー・Pre ラッパー・横断的ラッパー・横断ラッパー | 節目の前後で行う共通処理／作業前の確認／節目の確認 |
| spec 確定点 (a)(b)(c) | 記録には型を書かず「spec 確定点」のみ |
| 基準 (i) | 検査の仕組みが無い場合の基準 |
| 基準 (ii) | 自分で持ち込んだ後退の基準 |
| 観点 1〜5 | 名前は据え置き、参照時に中身を添える |
| 前置 1 | 設計縮小の先行判定 |
| 前置 2 | 締めモードの先行判定 |

### 記録に書かれる文字列

| 置き換え前 | 置き換え後 |
|---|---|
| `Post ラッパー消化記録`（節見出し） | `節目ごとの確認記録` |
| `B群判定:` | `条件発火判定:` |
| `逸脱突合:` | `逸脱照合:` |
| `格下げ: 発火` / `格下げ: 不発` | `独立レビュー切替: 発火` / `独立レビュー切替: 不発` |
| `退役経路`（点検の観点名・是正のやり方の名前・表の行名） | `規範の廃止条件` |
| `逸脱記録:` | 据え置き |
| `フル実施` / `差分再確認` / `機械検証` | 据え置き |

---

## Task 1: 着手前の実測と置き換え表ファイルの新設

**Files:**
- Create: `docs/overview/wording-replacements.md`
- Modify: `template.manifest`
- Modify: `docs/overview/folder-structure.md`（配置の早見表に 1 行）
- Modify: `docs/reference/README.md`（索引には追加しない。理由を確認するのみ）

- [ ] **Step 1: 着手前の値を記録する**

```bash
cd D:/Dev/002_AiDev/MakeAiInstructions
find skills -name '*.md' -exec cat {} + | wc -c
for f in skills/*/SKILL.md; do printf "%s %s\n" "$(wc -c < $f)" "$f"; done | sort -rn | head -3
wc -c < CONTRIBUTING.md
```

期待: skills 合計 227867、最大の SKILL.md は `skills/retrospective/SKILL.md` 19042、CONTRIBUTING.md 58150。この値を Task 13 の増分計算に使うので、実行結果をこのタスクのコミットメッセージに残す。

- [ ] **Step 2: 置き換え表ファイルを作成する**

`docs/overview/wording-replacements.md` を次の内容で作成する。表の行に ADR 番号・課題番号を書かない（配布対象ソースの記法規約に従う）。

```markdown
# 分かりにくい語の置き換え表

本ファイルは、ガイドライン文書で使う語の判定基準と、これまでに置き換えた語の一覧である。

**記録型の文書には当時の語彙が残る。記録を数えるときは、この表の新旧両方を数えること。**

## 判定の基準

対象とする「分かりにくい語」は次の 3 型である。判定条件は 2 つを同時に満たすこと。(1) 一般的に認知されていない、または一般的な意味で使っていない。(2) 同程度の文字数の一般的な語に置き換え可能。ただし、利用者が意味を尋ねた実例がある語・誤用・造語は、置き換え先が長くなっても対象に含める。

| 型 | 定義 | 対策 |
|---|---|---|
| 語自体型 | 語そのものが業界外で通じない、誤用、または造語 | 同程度の長さの一般語へ置き換える。短い一般語が無い造語は説明的な句へ書き直す |
| 目的語省略型 | 語は一般的だが、何に対する動作かがプロジェクト固有で、それを省いて使っている | 見出しや書式の名前には目的語を埋め込む。文中は意味が取れない箇所に限って目的語を添える |
| 記号的ラベル | 定義箇所以外では意味が推測できない英字・番号のラベル | 定義箇所にある説明文から名前を取る。定義箇所に既に名前がある場合はその名前を使い、第 3 の呼び名を作らない |

**対象外**:

- システム開発の現場で使いうる語
- 語だけで意味がおおむね推測でき、同程度の長さの一般語に置き換えると意味が変わる固有の概念語
- 機械が読む書式のキー
- LLM の言語的な癖として出る語

**適用範囲**: 今後も書き換える文書（規範・手順・案内・現用の仕様書）。記録型の文書（決定記録・過去の引き継ぎファイル・完了した実装計画・振り返り・課題）の本文は対象としない。ただしタイトルは一覧に並んで検索の入口になるため置き換える。

## 置き換え表

| 今使う語 | 置き換え前の語 | 変更日 |
|---|---|---|
| 照合 | 突合 | 2026-09-05 |
| 節目ごとの確認記録 | Post ラッパー消化記録 | 2026-09-05 |
| 確認の記録 | 消化記録 | 2026-09-05 |
| 未記録 | 未消化 | 2026-09-05 |
| 記録漏れ | 消化漏れ | 2026-09-05 |
| 実施結果 | 消化結果 | 2026-09-05 |
| 1 つずつ確認して記録する | 消し込み・消し込む | 2026-09-05 |
| 対象の総数 | 母数 | 2026-09-05 |
| 判断 | 裁定 | 2026-09-05 |
| 前に付ける・接頭辞 | 前置 | 2026-09-05 |
| 有効性・有効 | 現役性・現役 | 2026-09-05 |
| 接続する・接続の記述 | 配線 | 2026-09-05 |
| 範囲・範囲外 | 射程・射程外 | 2026-09-05 |
| 回 | 巡 | 2026-09-05 |
| 実質的な収束 | 実質収束 | 2026-09-05 |
| 独立レビューへの切り替え | 格下げ | 2026-09-05 |
| 計画のコードをそのまま書き写す方式 | 逐語厳守 | 2026-09-05 |
| 廃止 | 退役 | 2026-09-05 |
| 参照番号・見出しや書式の名前 | 識別子（`出所識別子`・`安定識別子`・`プロジェクト識別子` は据え置く） | 2026-09-05 |
| 継続して検査する仕組み | 検出資産 | 2026-09-05 |
| 実体に合わせる調整 | 機械的な適応 | 2026-09-05 |
| 常時適用・条件発火 | A 群・B 群 | 2026-09-05 |
| 節目の前後で行う共通処理・作業前の確認・節目の確認 | Pre / Post ラッパー・横断的ラッパー | 2026-09-05 |
| 検査の仕組みが無い場合の基準・自分で持ち込んだ後退の基準 | 基準 (i)・基準 (ii) | 2026-09-05 |
| 設計縮小の先行判定・締めモードの先行判定 | 前置 1・前置 2 | 2026-09-05 |
| 規範の廃止条件 | 退役経路 | 2026-09-05 |
| `条件発火判定:` | `B群判定:` | 2026-09-05 |
| `逸脱照合:` | `逸脱突合:` | 2026-09-05 |
| `独立レビュー切替:` | `格下げ:` | 2026-09-05 |
```

- [ ] **Step 3: `template.manifest` へ追加する**

`docs/inbox/README.md` の行の直前へ次の 1 行を挿入する（`docs/overview/` の 3 行の直後）。

```
docs/overview/wording-replacements.md
```

- [ ] **Step 4: `docs/overview/folder-structure.md` の配置の早見表へ 1 行足す**

76 行目「| 技術調査・検証メモ、セッション跨ぎに再利用する教訓・作業知見 | `docs/reference/` |」の直後へ次を挿入する。

```
| 分かりにくい語の置き換え表 | `docs/overview/wording-replacements.md` |
```

- [ ] **Step 5: 検証**

```bash
test -f docs/overview/wording-replacements.md && echo "created"
grep -c "wording-replacements" template.manifest docs/overview/folder-structure.md
grep -cE "ADR-[0-9]{4}|Issue-[0-9]{4}" docs/overview/wording-replacements.md
```

期待: `created`、`template.manifest:1`・`folder-structure.md:1`、最後は `0`（記法規約に従い出所を書かない）。

- [ ] **Step 6: コミット**

```bash
git add docs/overview/wording-replacements.md template.manifest docs/overview/folder-structure.md
git commit -m "docs: 分かりにくい語の置き換え表を新設し配布対象に加える"
```

---

## Task 2: `AGENTS.md` と `CONTRIBUTING.md` への規範の追加

**Files:**
- Modify: `AGENTS.md`（コンテキスト管理節へ 1 行、`突合` 1 語）
- Modify: `CONTRIBUTING.md`（新節の追加。語の置き換えは Task 8）

- [ ] **Step 1: `AGENTS.md` のコンテキスト管理節へ 1 行足す**

「初出のプロジェクト固有用語には簡潔な説明を添えること」の直後へ次を挿入する。

```
- 今後も書き換える文書を編集するときは、`docs/overview/wording-replacements.md` にある置き換え前の語を見つけたら、置き換えを提案すること。記録型の文書（決定記録・過去のハンドオフ・完了した実装計画・振り返り・課題）の本文は対象としない
```

- [ ] **Step 2: `AGENTS.md` の `突合` を置き換える**

```bash
grep -n "突合" AGENTS.md
```

該当 1 箇所の「突合」を「照合」に直す。文脈を読み、照合で意味が通ることを確認してから直す。

- [ ] **Step 3: `CONTRIBUTING.md` へ新節を追加する**

「## 全シナリオ共通: SKILL.md のサイズと分割」節の直前（205 行目の直前）へ次の節を挿入する。

小節の見出しは「### 本規範自体の廃止規範」とする。設計書 3-3 が「既存の共通節 4 つがすべて持つ小節に揃える」を求めており、既存 4 箇所（`CONTRIBUTING.md` 76・92・201・241 行）はいずれも「### 本…自体の退役規範」で、Task 8 の `退役` → `廃止` 置換後は「廃止規範」になるため。`退役経路` → `規範の廃止条件` の置き換えとは語形が異なるが、前者は節見出しの名前、後者は点検の観点名で別物である。

```markdown
## 全シナリオ共通: 規範文書の語彙

### 適用対象

AI が作業時に読み込み、今後も書き換える文書。次の 4 群である。

- 配布対象ソースのうち `skills/` 配下の `.md`
- 配布対象ソースのうち `template.manifest` 記載のファイル（空インデックス生成対象 3 件を除く）
- `CONTRIBUTING.md`・`README.md`・`docs/reference/`
- 現用仕様書 `docs/current/`

記録型・作業中文書（`docs/records/`・`docs/working/`）の本文は対象外とする。ただしタイトルは一覧に並んで検索の入口になるため対象に含める。

### 規約

分かりにくい語の 3 型と判定の基準は `docs/overview/wording-replacements.md` が正本である。同ファイルは置き換え済みの語の一覧も持つ。

語を追加・除外するときは同ファイルの判定条件で判定し、判定の理由を表の行の備考へ書く。

### 執行点

対象文書を編集したら、`docs/overview/wording-replacements.md` の置き換え前の語が新たに入っていないかを確認する。自動検査は設けない（ADR-0123）。

### 本規範自体の廃止規範

配布先から語彙が原因の課題・記録が 3 サイクル連続で 0 件、かつ本リポジトリで置き換え表へ追加する語が 3 サイクル連続で 0 件の状態が観測されたら、本規範の簡素化・廃止を候補としてユーザーへ提案する。いずれか有りなら存置側。判断はユーザーが行う。
```

- [ ] **Step 4: 「シナリオ: Skillを新規作成・改定するとき」のチェックリストへ 1 行足す**

同シナリオのチェックリストの末尾へ次を挿入する。

```
- 分かりにくい語を新たに持ち込んでいないか（「全シナリオ共通: 規範文書の語彙」／`docs/overview/wording-replacements.md`）
```

- [ ] **Step 5: 検証**

```bash
grep -c "wording-replacements" AGENTS.md CONTRIBUTING.md
grep -c "突合" AGENTS.md
grep -n "^## 全シナリオ共通" CONTRIBUTING.md
```

期待: `AGENTS.md:1`・`CONTRIBUTING.md:3`（新節 2 箇所＋チェックリスト 1 箇所）、`AGENTS.md` の `突合` は `0`、共通節が 5 つ並ぶ。

- [ ] **Step 6: 差分の確認とコミット**

```bash
git diff --stat AGENTS.md CONTRIBUTING.md
git add AGENTS.md CONTRIBUTING.md
git commit -m "docs: 語彙の規範を AGENTS.md と CONTRIBUTING.md へ追加"
```

差分は AGENTS.md が 2 行、CONTRIBUTING.md が新節と 1 行のみであることを確認する。

---

## Task 3: ハンドオフの節見出しの改名

**Files:**
- Modify: `skills/session-handoff/SKILL.md`（節見出しと書式定義）
- Modify: `skills/session-handoff/references/op-read.md`・`op-update.md`・`op-cycle-reset.md`（各 1 箇所＋汎用の 1 文）
- Modify: `skills/session-handoff/references/section-volume-norms.md`（行名）
- Modify: `skills/decision-log/references/cycle-consistency-check.md`・`skills/pre-finalization-review/SKILL.md`・`skills/retrospective/SKILL.md`・`skills/worklog-record/SKILL.md`（各 1 箇所）
- Modify: `skills/start-work/SKILL.md`（3 箇所）

- [ ] **Step 1: 対象を列挙する**

```bash
grep -rn "Post ラッパー消化記録" skills --include=*.md
```

期待: 12 件・10 ファイル。うち `session-handoff` が 5 件、他スキルが 7 件（`start-work/SKILL.md` に 3 件）。

- [ ] **Step 2: 定義箇所を変える**

`skills/session-handoff/SKILL.md` の 58 行目の節見出しを変える。

```
## Post ラッパー消化記録
```
を
```
## 節目ごとの確認記録
```
に直す。同ファイルの書式定義の本文にある「Post ラッパー消化記録」も同じ名前に直す。

- [ ] **Step 3: `session-handoff` の各手順の参照を変える**

`references/op-read.md`・`op-update.md`・`op-cycle-reset.md`・`section-volume-norms.md` の「Post ラッパー消化記録」を「節目ごとの確認記録」に直す。

- [ ] **Step 4: 汎用の 1 文を足す**

`skills/session-handoff/SKILL.md` の「操作」節の導入文の直後へ次を挿入する。

```
書式で定めた節見出しが実ファイルに無い場合、検査や追記を進めず、ユーザーへ報告して判断を仰ぐ（古い名前からの更新か、新規作成か）。古い名前は本スキルへ列挙しない。
```

- [ ] **Step 5: 他スキルの引用 7 箇所を変える**

Step 1 の列挙のうち `session-handoff` 以外の 7 箇所を「節目ごとの確認記録」に直す。対象ファイルは `decision-log/references/cycle-consistency-check.md`・`pre-finalization-review/SKILL.md`・`retrospective/SKILL.md`・`worklog-record/SKILL.md`・`start-work/SKILL.md`（3 箇所）。

- [ ] **Step 6: 検証**

```bash
grep -rc "Post ラッパー消化記録" skills --include=*.md | grep -v ":0" || echo "0 件"
grep -rc "節目ごとの確認記録" skills --include=*.md | grep -v ":0"
grep -c "書式で定めた節見出しが実ファイルに無い場合" skills/session-handoff/SKILL.md
```

期待: 1 行目が「0 件」、2 行目が 10 ファイルで計 12 件、3 行目が `1`。

- [ ] **Step 7: 差分の確認とコミット**

```bash
git diff --stat skills/
git add skills/
git commit -m "docs(skills): ハンドオフの節見出しを「節目ごとの確認記録」へ改名"
```

差分が 10 ファイル・14 行（12 件の置き換え＋汎用 1 文＋空行）に収まることを確認する。自リポジトリのハンドオフファイル自体は書き換えない。

逸脱記録: 事実誤り・期待値の陳腐化の訂正 / 採用 / Step 2 第 2 文が指す「書式定義の本文にある Post ラッパー消化記録」は実体に存在しない、`skills/session-handoff/SKILL.md` の当該文字列は 58 行の節見出し 1 件のみで 60 行の本文は `Post ラッパー`（Task 5 の担当）、節見出し 1 箇所のみを変更した、実測は委譲前に委譲元が実施

---

## Task 4: 記録に書かれる文字列の改名

**Files:**
- Modify: `skills/subagent-dispatch/SKILL.md`（`B群判定:`）
- Modify: `skills/start-work/references/plan-deviation-defaults.md`（`逸脱突合:`・`格下げ:`）
- Modify: `skills/session-handoff/references/review-field-values.md`（`実質収束`・`N 巡`）
- Modify: `skills/pre-finalization-review/references/iteration-norms.md`（`実質収束`・`巡`）

- [ ] **Step 1: 対象を列挙する**

```bash
grep -rn "B群判定\|逸脱突合\|格下げ" skills --include=*.md
grep -rc "実質収束" skills --include=*.md | grep -v ":0"
```

期待: `B群判定` 1 件、`逸脱突合` 2 件、`格下げ` 6 件、`実質収束` は 3 ファイル計 14 件。

- [ ] **Step 2: `B群判定:` を `条件発火判定:` に直す**

`skills/subagent-dispatch/SKILL.md` の判定行の書式定義（27 行目付近）と、同ファイル内の説明文の `B群判定` をすべて `条件発火判定` に直す。書式の例は次のようになる。

```
条件発火判定: 検査=yes / ミューテーション=no / 並列書き換え=no / 計画実装=no / 長時間書き込み=no / 破壊的検証=no
```

- [ ] **Step 3: `逸脱突合:` を `逸脱照合:` に直す**

`skills/start-work/references/plan-deviation-defaults.md` の 2 箇所を直す。計画ファイルへ書く `逸脱記録:` は据え置く。

- [ ] **Step 4: `格下げ` を「独立レビューへの切り替え」に直す**

`plan-deviation-defaults.md` の 6 箇所を、機械的な置換ではなく文単位で直す。具体的には次のとおり。

- 「タスク別独立レビューへ格下げ」→「タスク別独立レビューへ切り替える」
- 「格下げ安全弁」→「独立レビューへ切り替える安全弁」
- 「格下げの発火判定」→「切り替えの発火判定」
- 「格下げ対象外」→「切り替えの対象外」
- 記録の文字列 `格下げ: 発火` / `格下げ: 不発` → `独立レビュー切替: 発火` / `独立レビュー切替: 不発`

- [ ] **Step 5: `実質収束` を「実質的な収束」に直す**

3 ファイル 14 箇所を文単位で直す。次の 4 箇所は語をそのまま置くと重言・非文になるので、示した形にする。

- 「…となった巡を実質収束とみなす」→「…となった回を実質的な収束とみなす」
- 「実質収束の判定結果は」→「実質的な収束かどうかの判定結果は」
- 「`実質収束` — 実質収束（…）の判定が真のまま確定した場合」→「`実質的な収束` — 実質的な収束（…）の判定が真のまま確定した場合」
- 「`提示後確定（実質収束せず）`」→「`提示後確定（実質的な収束に至らず）`」

- [ ] **Step 6: 検証**

```bash
grep -rc "B群判定\|逸脱突合\|実質収束" skills --include=*.md | grep -v ":0" || echo "0 件"
grep -rn "格下げ" skills --include=*.md || echo "格下げ 0 件"
grep -rc "条件発火判定\|逸脱照合\|独立レビュー切替\|実質的な収束" skills --include=*.md | grep -v ":0"
```

期待: 1 行目・2 行目が「0 件」、3 行目に置き換え後の語が現れる。

- [ ] **Step 7: 差分の確認とコミット**

```bash
git diff --stat skills/
git add skills/
git commit -m "docs(skills): 記録に書かれる文字列を平易な名前へ改名"
```

逸脱記録: 事実誤り・期待値の陳腐化の訂正 / 採用 / Files 欄が `実質収束` の対象を 2 ファイルとしか挙げていないが Step 5 は 3 ファイルと書いており、実測の 3 つ目は `skills/session-handoff/SKILL.md` 71 行（確認記録の書式の例）、同ファイルも対象に含めて 3 ファイル 8 行 14 件を置き換えた、実測は委譲前に委譲元が実施

---

## Task 5: 記号的なラベルの改名

**Files:**
- Modify: `skills/subagent-dispatch/SKILL.md`（`A 群` / `B 群` の定義見出しと参照）
- Modify: `skills/pre-finalization-review/references/iteration-norms.md`・`review-procedure.md`、`skills/start-work/SKILL.md`・`references/plan-deviation-defaults.md`（`A 群` / `B 群` の参照）
- Modify: `skills/session-handoff/SKILL.md`・`references/op-update.md`、`skills/pre-finalization-review/SKILL.md`、`skills/feature-block-design/SKILL.md`、`skills/decision-log/references/adr-authoring.md`（`spec 確定点 (a)(b)(c)`）
- Modify: `skills/decision-log/references/cycle-consistency-check.md`（観点の参照）
- Modify: `skills/start-work/references/plan-deviation-defaults.md`（基準 `(i)` `(ii)`）
- Modify: `skills/pre-finalization-review/references/iteration-norms.md`・`SKILL.md`（`前置 1` / `前置 2`）
- Modify: 「ラッパー」を含む 14 ファイル

- [ ] **Step 1: 対象を列挙する**

```bash
grep -rnE "[AB] 群" skills --include=*.md
grep -rnE "spec ?確定点 ?\([abc]\)" skills --include=*.md
grep -nE "\([abc]\)" skills/pre-finalization-review/SKILL.md   # 括弧が「確定点」に隣接しない裸の型参照
grep -rnE "観点 ?[1-5]" skills --include=*.md
grep -rnE "前置 ?[12]|\((i|ii)\)" skills --include=*.md
grep -rn "ラッパー" skills --include=*.md
```

上の `-n` 付きの列挙は**行**を出す。下の期待値は設計書の数え方（行ではなく出現回数）なので、件数を照合するときは `-o` で数える。

```bash
for p in "[AB] 群" "spec ?確定点 ?\([abc]\)" "観点 ?[1-5]" "前置 ?[12]|\((i|ii)\)" "ラッパー"; do
  echo -n "$p : "; grep -rohE "$p" skills --include=*.md | wc -l
done
```

期待: `A 群/B 群` 19 件、`spec 確定点 (a-c)` 14 件、`観点 N` 2 件、`前置 1/2` 4 件と `(i)(ii)` 4 件、`ラッパー` 28 件。

- [ ] **Step 2: `A 群` / `B 群` の定義見出しを変える**

`skills/subagent-dispatch/SKILL.md` の見出しを直す。

```
## A 群: 常時適用（4 件）
## B 群: タスクの型で条件発火（6 条件）
```
を
```
## 常時適用（4 件）
## 条件発火（タスクの型で発火。6 条件）
```
に直す。同ファイル内の「A 群 4 件」は「常時適用の 4 件」、「B 群判定表」は「条件発火の判定表」のように、文脈に合わせて直す。「条件発火項目の発火条件表」のような重言にしない。

- [ ] **Step 3: 他ファイルの `A 群` / `B 群` の参照を直す**

`iteration-norms.md`・`review-procedure.md`・`start-work/SKILL.md`・`plan-deviation-defaults.md` の参照を「常時適用の 4 件」「条件発火の判定」の形へ直す。

- [ ] **Step 4: `spec 確定点 (a)(b)(c)` を扱う**

`skills/session-handoff/SKILL.md` の記入規則を次のように直す。

```
確定点を通過したマイルストーンは、**名称に `spec 確定点` / `plan 確定点` のいずれかを含める**（read の欠落検査が対象行を識別できるようにするため）。型の括弧書きは書かない。
```

`pre-finalization-review/SKILL.md` の定義表（38〜40 行）は残し、行の見出しを到達の仕方の説明へ直す。**3 行すべての文言をここで決めておく**（1 行だけ例示すると、実装者が残り 2 行に別の言い回しを選び、下の本文側の語と揃わなくなる）。

- 38 行目 `| spec 確定点 (a) |` → `| spec 確定点（機能ブロック設計を経た場合） |`
- 39 行目 `| spec 確定点 (b) |` → `| spec 確定点（設計文書型） |`
- 40 行目 `| spec 確定点 (c) |` → `| spec 確定点（設計文書兼用 ADR 型） |`

他ファイルの `spec 確定点 (a)` 等の参照は「spec 確定点」へ直す。

**同ファイル内の裸の型参照も同時に直す。** Step 1 の列挙パターン `spec ?確定点 ?\([abc]\)` は「確定点」に括弧が隣接する形しか拾わないため、次の 4 行（32・43・54・66）は列挙から漏れる。見出しから型ラベルを外すとこの 4 行が指す先が消える。

- 32 行目「spec 確定点（到達経路により (a)〜(c) の 3 通り）」→「spec 確定点（到達の仕方が 3 通りある）」
- 43 行目「確定点が (a)〜(c) のどの型になるか決まらない」→「確定点がどの到達の仕方になるか決まらない」
- 54 行目「(b) と (c) は成立条件の軸が異なるため」→「設計文書型と設計文書兼用 ADR 型は成立条件の軸が異なるため」
- 66 行目「既存項目「対象確定点の型」〈spec (a)〜(c)／plan〉」→「既存項目「対象確定点の型」〈spec／plan〉」

97 行目「設計文書兼用 ADR——spec 確定点 (c) の型——は」→「設計文書兼用 ADR——設計文書ファイルを作らない拡張で ADR が設計文書を兼ねる型——は」。**この行は Step 1 のパターンに一致するので列挙に出る**（漏れる 4 行とは別扱い。確定前レビューで、当初「5 箇所すべてが漏れる」と書いていた誤りを訂正した）。

なお 78・79 行目の `(a) 推奨の由来を明示する` / `(b) 反対材料の欄を常設する` は別の列挙の記号で、`spec 確定点` の型ラベルではない。同じ節の中で定義と説明が隣接しているため据え置く。`references/examples-and-evidence.md` にある `SKILL.md 提示規則 3-2 (b)` という参照も同じ列挙を指すので据え置く（Step 1 の裸の型参照の列挙を `SKILL.md` に限ったのはこのため）。

- [ ] **Step 5: 観点の参照に中身を添える**

`skills/decision-log/references/cycle-consistency-check.md` の 28 行目「観点 4 は差分に関わる規範のみの再検査でよいが、観点 1・2・3・5 は」を次のように直す。

```
観点 4（発動経路と記録順序の整合）は差分に関わる規範のみの再検査でよいが、観点 1（仕様のスナップショット性）・2（規範の書き戻し）・3（数値・完了基準の整合）・5（引用の整合）は
```

定義側の観点名「経路の閉じ」は据え置く。

- [ ] **Step 6: 基準 `(i)` `(ii)` に名前を与える**

`skills/start-work/references/plan-deviation-defaults.md` の定義を直す。

```
- **(i) 検出資産の不在**:
- **(ii) 当該コミット（委譲実装では当該タスクの成果物）自身が持ち込んだ後退**
```
を
```
- **検査の仕組みが無い場合の基準**:
- **自分で持ち込んだ後退の基準**（当該コミット、委譲実装では当該タスクの成果物が持ち込んだ後退）
```
に直す。同ファイル内の「基準 (i) に該当し」は「検査の仕組みが無い場合の基準に該当し」へ直す。

- [ ] **Step 7: `前置 1` / `前置 2` に名前を与える**

`skills/pre-finalization-review/references/iteration-norms.md` の 17・18 行目と `SKILL.md` の該当箇所を直す。「本前置を適用せず」は「本判定を適用せず」、「締めモード（前置 2）を推奨する」は「締めモードを推奨する」へ、文単位で直す。

- [ ] **Step 8: 「ラッパー」を直す**

28 件を文単位で直す。「横断的ラッパー」は「節目の前後で行う共通処理」、「Pre（実行前）」は「作業前の確認」、「Post（実行後）」は「節目の確認」、「横断的ラッパー Pre」は「全スキル実行前の共通処理」、「Post ラッパーの消し込み」は Task 3 の改名と Task 6 の語の置き換えに従う。

- [ ] **Step 9: 検証**

```bash
grep -rcE "[AB] 群|spec ?確定点 ?\([abc]\)|前置 ?[12]|ラッパー" skills --include=*.md | grep -v ":0" || echo "0 件"
grep -rn "観点 4（" skills/decision-log/references/cycle-consistency-check.md
grep -rc "基準 (i)" skills --include=*.md | grep -v ":0" || echo "基準 (i) 0 件"
```

期待: 1 行目が「0 件」、2 行目が 1 件ヒット、3 行目が「基準 (i) 0 件」。

- [ ] **Step 10: 差分の確認とコミット**

```bash
git diff --stat skills/
git add skills/
git commit -m "docs(skills): 記号的なラベルへ定義箇所の名前を与える"
```

---

## Task 6: 群 A（`skills/`）の語の置き換え

**Files:** 群 A の 26 ファイル。件数の多い順に `pre-finalization-review/references/iteration-norms.md`（93）・`start-work/references/plan-deviation-defaults.md`（42）・`session-handoff/references/review-field-values.md`（27）・`pre-finalization-review/SKILL.md`（25）・`subagent-dispatch/SKILL.md`（20）・`start-work/SKILL.md`（19）・`retrospective/SKILL.md`（16）・`session-handoff/SKILL.md`（15）ほか。

- [ ] **Step 1: 語ごとに全出現を列挙する**

```bash
for w in 突合 消化 消し込 母数 裁定 現役 配線 射程 巡 逐語厳守 退役 検出資産 機械的な適応; do echo "=== $w"; grep -rn "$w" skills --include=*.md | head -50; done
python - <<'PY'
import re,glob
for name,pat in [("前置",r"前置(?!き)"),("識別子",r"(?<!出所)(?<!安定)識別子")]:
    print("===",name)
    for f in sorted(glob.glob("skills/**/*.md",recursive=True)):
        for i,line in enumerate(open(f,encoding="utf-8"),1):
            if re.search(pat,line): print(f"{f}:{i}:{line.rstrip()}")
PY
```

- [ ] **Step 2: 語ごとに 1 件ずつ直す**

「語の置き換え表」の型 1 に従い、文脈を見て 1 件ずつ直す。一括置換はしない。次の箇所は語を置くと文が壊れるので、示した形にする。

- `iteration-norms.md` の「配線（規範を発火点・記録先に接続する記述）」→「接続の記述（規範を発火点・記録先につなぐ記述）」
- `iteration-norms.md` の「規範を発火点・記録先へ接続する配線の新設・変更・削除」→「規範を発火点・記録先へつなぐ記述の新設・変更・削除」
- `start-work/SKILL.md` の「1つずつ明示的に消し込む」→「1 つずつ明示的に確認して記録する」
- `adr-authoring.md` の「独立した消し込み項目としては設けない」→「独立した確認項目としては設けない」
- `op-cycle-reset.md` の「1 件ずつ現役性点検し、現役のものだけを残す」→「1 件ずつ有効性を点検し、有効なものだけを残す」
- `review-field-values.md` の「通算 N 巡」→「通算 N 回」、「機械検証 N 回」は据え置き。「巡を立てる方式の和」→「回を立てる方式の和（機械検証は数えない）」
- `iteration-norms.md` の「初回巡」→「初回の回」ではなく「1 回目」、「巡種」→「方式の種類」
- `plan-deviation-defaults.md` の「逐語厳守＋設計の変更に至ったら」→「計画のコードをそのまま書き写す方式を採り、設計の変更に至ったら」
- `worklog-skillify/SKILL.md` の「根拠と世代＋退役経路」→「根拠と世代＋規範の廃止条件」。**`退役` の単純置換で「廃止経路」にしないこと**（`退役経路` は 1 語として「規範の廃止条件」へ置き換える。誤って「廃止経路」にすると Task 14 の完了検証は `退役経路` を探すため検出できない）
- `subagent-dispatch/SKILL.md` の見出し「## 退役規範」と `examples-and-evidence.md` の同語形は「## 廃止規範」へ（`CONTRIBUTING.md` の既存 4 小節と語形を揃えるため。Task 2 の新設小節も同じ語形にする）
- `examples-and-evidence.md` 9 行目の「実例 = 点検観点に『退役経路』が無い」→「実例 = 点検観点に『規範の廃止条件』が無い」。**これも `退役` の単純置換で「廃止経路」にしないこと**（群 A の `退役経路` は `worklog-skillify/SKILL.md:43` と本箇所の 2 件で、どちらも 1 語として置き換える）

- [ ] **Step 3: 検証**

```bash
for w in 突合 消化 消し込 母数 裁定 現役 配線 射程 巡 実質収束 格下げ 逐語厳守 退役 検出資産 機械的な適応; do n=$(grep -roh "$w" skills --include=*.md | wc -l); echo "$w=$n"; done
python - <<'PY'
import re,glob
for name,pat in [("前置",r"前置(?!き)"),("識別子",r"(?<!出所)(?<!安定)識別子")]:
    n=sum(len(re.findall(pat,open(f,encoding="utf-8").read())) for f in glob.glob("skills/**/*.md",recursive=True))
    print(f"{name}={n}")
PY
```

期待: すべて `0`。`出所識別子`・`安定識別子`・`プロジェクト識別子` は残るので、`識別子` 単独の検査は否定後読みを使う（`プロジェクト識別子` は 1 件のみで、上の Python は 1 を返す。この 1 件が `store-format.md` の `プロジェクト識別子` であることを目視で確認して 0 とみなす）。

> 当初は `grep -rohE "前置(?!き)"` と書いていたが、`grep -E` は否定先読み・否定後読みを解釈せず常に 0 件を返すため、置き換えの前後を問わず検証が真になっていた（確定前レビューで検出。実測: `grep -E` は 0 件、Python は 前置 6 件・識別子 9 件）。

- [ ] **Step 4: 差分の確認とコミット**

```bash
git diff --stat skills/
git add skills/
git commit -m "docs(skills): 分かりにくい語を平易な語へ置き換え"
```

差分が Step 1 で列挙した箇所に限られることを確認する。

---

## Task 7: 型 2（目的語を添える）の点検（4 群）

**Files:** 4 群すべてのうち `昇格`・`移設`・`剪定`・裸の `確定点` を含むファイル。設計書 6-3 の完了条件 2 は「文中の裸の使用を 4 群で目視点検した」を求めており、群 A だけでは足りない（設計書の型 2 の表では群 B・C・D にも非ゼロ件数がある）。

- [ ] **Step 1: 裸の使用を 4 群で列挙する**

```bash
python - <<'PY'
import re,glob
manifest=[l.strip() for l in open("template.manifest",encoding="utf-8") if l.strip() and not l.startswith("#")]
G={"A":sorted(glob.glob("skills/**/*.md",recursive=True)),
   "B":[f for f in manifest if f.endswith(".md") and "wording-replacements" not in f],
   "C":["CONTRIBUTING.md","README.md"]+sorted(glob.glob("docs/reference/*.md")),
   "D":[f for f in sorted(glob.glob("docs/current/**/*.md",recursive=True)) if "2026-09-04-plain-language" not in f]}
pats=[("昇格",r"昇格"),("移設",r"移設"),("剪定",r"剪定"),("確定点(裸)",r"(?<!spec )(?<!plan )確定点")]
for g,fs in G.items():
    for name,pat in pats:
        hits=[]
        for f in sorted(set(fs)):
            try: lines=open(f,encoding="utf-8").readlines()
            except OSError: continue
            for i,line in enumerate(lines,1):
                if re.search(pat,line): hits.append(f"{f}:{i}:{line.rstrip()}")
        print(f"=== 群{g} {name}: {len(hits)} 行")
        for h in hits: print(" ",h)
PY
```

`昇格` は `Accepted 昇格`・`フォルダ昇格`・`承認の昇格` のように既に目的語が付いた形も列挙に混ざる。Step 2 で 1 件ずつ読んで判断するため、列挙側では除外しない（除外条件を書くと、まだ知らない付き方を取りこぼす）。

- [ ] **Step 2: 意味が取れない箇所に目的語を添える**

列挙した箇所を 1 件ずつ読み、同じ文の中に何が昇格・移設・剪定するのかが書かれていない箇所にだけ目的語を添える。全数の置き換えは求めない。`pre-finalization-review` の中で定義済みの中心語として使う裸の「確定点」は据え置く。

- [ ] **Step 3: 点検の実施を記録する**

このタスクのコミットメッセージへ、群ごとに点検した件数と目的語を添えた件数を書く（完了条件 2 が「点検の実施を実装計画に記録する」を求めるため、本計画のこの行に実測値を追記する）。

実測値の記入欄（Step 1 の実行後に埋める）: 群 A 点検 __ 件・修正 __ 件 / 群 B __・__ / 群 C __・__ / 群 D __・__

- [ ] **Step 4: 差分の確認とコミット**

```bash
git diff --stat skills/ CONTRIBUTING.md README.md docs/reference/ docs/overview/ docs/current/
git add -- skills CONTRIBUTING.md README.md docs/reference docs/overview docs/current
git commit -m "docs: 目的語が省かれた語へ目的語を添える（4 群・点検 N 件・修正 M 件）"
```

---

## Task 8: 群 C（拡張手引き・案内文書）の置き換え

**Files:**
- Modify: `CONTRIBUTING.md`（45 件）
- Modify: `README.md`（2 件）
- Modify: `docs/reference/powershell-pitfalls.md`（1 件）

- [ ] **Step 1: 対象を列挙する**

```bash
for w in 突合 前置 現役 退役 識別子 巡; do echo "=== $w"; grep -n "$w" CONTRIBUTING.md README.md docs/reference/*.md; done
grep -nE "[AB] 群|観点 ?[1-5]" CONTRIBUTING.md README.md docs/reference/*.md
```

- [ ] **Step 2: 「退役経路」の 3 つの役割を直す**

`CONTRIBUTING.md` の 5 箇所を次のように直す。

- 45 行目（点検の観点名）: 「4. **退役経路**: 追加する規範が不要になったことを判定する経路」→「4. **規範の廃止条件**: 追加する規範が不要になったことを判定する条件」
- 55 行目（是正のやり方の名前）: 「**根拠と世代＋退役経路**」→「**根拠と世代＋規範の廃止条件**」
- 74 行目（表の行名）: 「| 退役経路 | 定義済み / 不要（理由） |」→「| 規範の廃止条件 | 定義済み / 不要（理由） |」
- 86 行目（省略の要件）: 「同一 ADR 内の過剰適合点検ブロック「退役経路」欄の記載がある場合に限り」→「同一 ADR 内の過剰適合点検ブロック**の当該欄**の記載がある場合に限り」
- 243 行目（ADR-0121 の欄への参照）: 「正本は ADR-0121 の過剰適合点検ブロック「退役経路」欄」→「正本は ADR-0121 の過剰適合点検ブロック**の当該欄**」

`skills/worklog-skillify/SKILL.md` の是正のやり方の名前の再掲は Task 6 Step 2 の例外リストで扱う（同ファイルは群 A なので Task 6 の担当。ここでは触らない）。Task 6 の完了後に `grep -rn "廃止経路" skills` が 0 件であることを確認する（`退役` の単純置換で「廃止経路」になっていないかの確認。Task 14 の完了検証は `退役経路` を探すためこの誤りを検出できない）。

- [ ] **Step 3: 残りの語を直す**

`突合` → `照合`、`前置`（接頭辞の意味）→ `接頭辞`、`現役` → `有効`、`退役` → `廃止`、`識別子` → 文脈に応じた語、`A 群` / `B 群` → `常時適用` / `条件発火`、`観点 2・3` → 名前を併記した形。`README.md` の「常時 A 群 4 件＋条件発火 B 群」は「常時適用の 4 件＋条件発火の項目」へ直す。

- [ ] **Step 4: 検証**

```bash
for w in 突合 現役 退役 検出資産 巡; do n=$(grep -oh "$w" CONTRIBUTING.md README.md docs/reference/*.md | wc -l); echo "$w=$n"; done
grep -ohE "[AB] 群" CONTRIBUTING.md README.md docs/reference/*.md | wc -l
grep -nE "観点 ?[1-5]" CONTRIBUTING.md README.md docs/reference/*.md
python - <<'PY'
import re,glob
fs=["CONTRIBUTING.md","README.md"]+sorted(glob.glob("docs/reference/*.md"))
for name,pat in [("前置",r"前置(?!き)"),("識別子",r"(?<!出所)(?<!安定)(?<!プロジェクト)識別子")]:
    print(f"{name}={sum(len(re.findall(pat,open(f,encoding='utf-8').read())) for f in fs)}")
PY
grep -c "退役経路" CONTRIBUTING.md || echo "退役経路 0 件"
grep -c "規範の廃止条件" CONTRIBUTING.md
```

期待: 1 行目の語はすべて `0`、`[AB] 群` は 0 件、`前置` と `識別子` は 0、`退役経路` は 0 件、`規範の廃止条件` が 3 件以上。`観点 ?[1-5]` は 0 にはならない（置き換え表は「名前は据え置き、参照時に中身を添える」と定めているため）。列挙された各行に観点の中身が併記されていることを目視で確認する。

- [ ] **Step 5: 差分の確認とコミット**

```bash
git diff --stat CONTRIBUTING.md README.md docs/reference/
git add CONTRIBUTING.md README.md docs/reference/
git commit -m "docs: 拡張手引きと案内文書の語彙を置き換え、退役経路を規範の廃止条件へ統一"
```

---

## Task 9: 群 B（配布テンプレート対象）の置き換え

**Files:**
- Modify: `docs/overview/issue-management.md`（`突合` 1 件）

`AGENTS.md` の `突合` は Task 2 で済んでいる。

- [ ] **Step 1: 対象を列挙する**

```bash
grep -n "突合" docs/overview/issue-management.md
```

期待: 1 件（「インデックスと中央ストアの在庫を突合して行う」）。

- [ ] **Step 2: 直す**

「突合して行う」→「照合して行う」に直す。

- [ ] **Step 3: 検証とコミット**

```bash
grep -c "突合" docs/overview/issue-management.md || echo "0 件"
git add docs/overview/issue-management.md
git commit -m "docs(overview): 課題管理定義の語彙を置き換え"
```

---

## Task 10: 群 D（現用仕様書）の置き換え

**Files:** `docs/current/` 配下の 23 ファイル（本計画の設計書を除く）。件数の多い順に `2026-08-07-overfitting-check-for-extensions-design.md`（32）・`2026-08-05-dispatch-and-pre-review-skills-design.md`（32）・`2026-04-25-record-strengthening-design.md`（30）・`2026-08-28-start-work-responsibility-split-design.md`（27）・`2026-08-07-distributed-artifact-generation/01-provenance-notation-convention.md`（27）ほか（Task 14 の完了検証と同じパターン集合での実測。冒頭の注記どおり目安値）。

- [ ] **Step 1: 対象を列挙する**

```bash
for w in 突合 消化 消し込 母数 現役 配線 射程 巡 実質収束 退役 識別子; do echo "=== $w"; grep -rn "$w" docs/current --include=*.md | grep -v "2026-09-04-plain-language"; done
grep -rnE "[AB] 群|spec ?確定点 ?\([abc]\)|観点 ?[1-5]" docs/current --include=*.md | grep -v "2026-09-04-plain-language"
```

- [ ] **Step 2: 語ごとに 1 件ずつ直す**

「語の置き換え表」に従う。仕様書は「今どうなっているか」を書く文書なので、スキルの名前を変えた箇所（節見出し・記録の文字列・ラベル）は新しい名前に揃える。

「退役経路」は群 D の **7 ファイル・16 件**に出現する。点検の観点名・是正のやり方の名前・表の行名として、Task 8 と同じ「規範の廃止条件」に揃える（当初は 1 ファイル・5 箇所としていたが、確定前レビューの再実測で 7 ファイル・16 件だった）。

- `2026-08-07-overfitting-check-for-extensions-design.md` 7 件
- `2026-08-07-distributed-artifact-generation/00-overview.md` 3 件
- `2026-08-25-codex-support-design.md` 2 件
- `2026-08-05-dispatch-and-pre-review-skills-design.md` 1 件
- `2026-08-07-distributed-artifact-generation/01-provenance-notation-convention.md` 1 件
- `2026-08-13-handoff-bloat-control/00-overview.md` 1 件
- `2026-08-28-start-work-responsibility-split-design.md` 1 件

`退役` の単純置換で「廃止経路」にしないこと（`退役経路` は 1 語として扱う）。

`2026-08-06-handoff-pruning-and-status-design.md` のタイトル「ハンドオフ剪定規約と Status 整合の設計」は既に目的語を含むため据え置く。

`(i)` `(ii)` の 6 件は、採用の基準とは無関係な列挙記号なので据え置く。

- [ ] **Step 3: 検証**

```bash
for w in 突合 消化 消し込 母数 裁定 現役 配線 射程 巡 実質収束 格下げ 逐語厳守 退役 検出資産 機械的な適応 廃止経路; do n=$(find docs/current -name '*.md' ! -name '2026-09-04-plain*' -exec grep -oh "$w" {} \; | wc -l); echo "$w=$n"; done
find docs/current -name '*.md' ! -name '2026-09-04-plain*' -exec grep -ohE "[AB] 群|spec ?確定点 ?\([abc]\)" {} \; | wc -l
python - <<'PY'
import re,glob
fs=[f for f in sorted(glob.glob("docs/current/**/*.md",recursive=True)) if "2026-09-04-plain-language" not in f]
txt="".join(open(f,encoding="utf-8").read() for f in fs)
for name,pat in [("前置",r"前置(?!き)"),("識別子",r"(?<!出所)(?<!安定)(?<!プロジェクト)識別子")]:
    print(f"{name}={len(re.findall(pat,txt))}")
PY
find docs/current -name '*.md' ! -name '2026-09-04-plain*' -exec grep -nE "観点 ?[1-5]" {} +
```

期待: 1 つ目の for 文の語はすべて `0`（`廃止経路` を含む。`退役経路` を誤って単純置換した場合の検出）、`[AB] 群` と `spec 確定点 (a)` は 0 件、`前置` と `識別子` は 0。`観点 ?[1-5]` は 0 にはならないので、列挙された各行に観点の中身が併記されていることを目視で確認する。

当初は検証の語リストが Step 1 の列挙より短く、群 D で最も件数の多い `識別子`（85 件）と `裁定`・`前置`・`観点` が検証から漏れていた（確定前レビューで検出）。

- [ ] **Step 4: 差分の確認とコミット**

```bash
git diff --stat docs/current/
git add docs/current/
git commit -m "docs(specs): 現用仕様書の語彙と名前を置き換え"
```

---

## Task 11: 記録型文書のタイトルの置き換え

**Files:** ADR 11 件・振り返り 4 件・課題 14 件と、対応する 3 つの一覧ファイル。

- [ ] **Step 1: 対象を機械的に列挙する**

```bash
python - <<'PY'
import re,glob,os
pats=[r"突合",r"消化",r"消し込",r"母数",r"裁定",r"前置(?!き)",r"現役",r"配線",r"射程",r"巡",
r"実質収束",r"格下げ",r"逐語厳守",r"退役",r"(?<!出所)(?<!安定)識別子",r"検出資産",r"機械的な適応",
r"ラッパー",r"[AB] 群",r"spec ?確定点 ?\([abc]\)",r"観点 ?[1-5]"]
for d in ["docs/records/decisions","docs/records/retrospectives","docs/working/issues"]:
    print("===",d)
    for f in sorted(glob.glob(d+"/**/*.md",recursive=True)):
        if os.path.basename(f)=="README.md": continue
        for l in open(f,encoding="utf-8"):
            if l.startswith("# "):
                if any(re.search(p,l) for p in pats): print("  ",f,"|",l.strip()[:90])
                break
PY
```

期待: ADR 11 件・振り返り 4 件・課題 14 件の計 29 件。件数が異なる場合はこの実測を正とし、逸脱記録へ 1 行残す。

- [ ] **Step 2: タイトルを直す**

各ファイルの 1 行目の見出しを、「語の置き換え表」に従って直す。本文は書き換えない。例:

- `ADR-0057: Post ラッパーの消化結果を handoff に残し、未入場は事後突合で回収する` → `ADR-0057: 節目の確認の実施結果を handoff に残し、未入場は事後照合で回収する`
- `Issue-0037: start-work Post ラッパーの消化漏れが検出できない（worklog-record の発火が確率的）` → `Issue-0037: start-work の節目の確認の記録漏れが検出できない（worklog-record の発火が確率的）`
- `ADR-0073: 委譲制約の規範項目には根拠と世代を添え、実測にもとづく退役経路を持たせる` → `ADR-0073: 委譲制約の規範項目には根拠と世代を添え、実測にもとづく規範の廃止条件を持たせる`

- [ ] **Step 3: 3 つの一覧の記載を直す（一覧ごとに扱いが違う）**

3 つの一覧は書式が同じではないため、「同じタイトルが書かれているので揃える」という 1 つの手順では扱えない（確定前レビューで検出）。一覧ごとに次のように扱う。

- `docs/records/decisions/README.md`: 該当 11 行のタイトルは実ファイルの H1 をそのまま転記した形なので、Step 2 と**同じ文字列**に直す
- `docs/working/issues/README.md`: 該当 14 行のうち 12 行は H1 の転記だが、2 行（Issue-0080・Issue-0123）は H1 を短くした要約になっている。転記の行は同じ文字列に直し、要約の 2 行は**その行に含まれる置き換え対象の語だけ**を直す（行の要約としての書き方は変えない）
- `docs/records/retrospectives/README.md`: 表の「サブプロジェクト」列は H1 の転記ではなく自由記述のラベルである（例: 実ファイルの H1「Retrospective: 記録プロセス規範の一括対策」に対し一覧は「記録プロセス規範の一括対策（Issue-0009/0010/0011 対策）」）。この列は一覧が各振り返りを指すための識別ラベルなので、ADR-0123 の決定 6 が言う「対応する一覧」に当たる。**この列にある 4 件（`突合`・`消化`・`配線`・`ラッパー` 各 1 件）だけ**を直す
  - **同じ表の「備考」列は触らない。** 同列は当時の観察を当時の語彙で残した記録本文にあたり、置き換え対象の語が 105 件ある（Step 4 の検査と同じパターン集合での実測。`巡` 39・`spec 確定点`〈裸〉15・`配線` 14・`実質収束` 10 ほか）。ADR-0123 の決定 6 は「記録型文書はタイトルのみ置き換える」と定め、**「本文への拡大の前例にはしない」**と明記している。`AGENTS.md` へ足す 1 行も「記録型文書の本文は対象としない」である。この 105 件は置き換えない

設計書 5 の「計 58 箇所」の内訳は次のとおりで、実測と一致する（数え直しは要らない）。

| 対象 | 件数 |
|---|---|
| 記録型文書のタイトル（ADR 11・振り返り 4・課題 14） | 29 |
| 決定記録の一覧の行 | 11 |
| 課題の一覧の行 | 14 |
| 振り返りの一覧の「サブプロジェクト」列 | 4 |
| 合計 | 58 |

- [ ] **Step 4: 検証**

Step 1 のスクリプトを再実行して 0 件になることを確認したうえで、一覧側を次で確認する。

```bash
python - <<'PY'
import re
pats=[r"突合",r"消化",r"消し込",r"母数",r"裁定",r"前置(?!き)",r"現役",r"配線",r"射程",r"巡",
r"実質収束",r"格下げ",r"逐語厳守",r"退役",r"(?<!出所)(?<!安定)(?<!プロジェクト)識別子",r"検出資産",
r"機械的な適応",r"ラッパー",r"[AB] 群",r"spec ?確定点 ?\([abc]\)",r"観点 ?[1-5]"]
def count(text): return sum(len(re.findall(p,text)) for p in pats)

# (1) 決定記録と課題の一覧: 表の行に残っていないこと（着手前は 13 件・15 件）
for f in ["docs/records/decisions/README.md","docs/working/issues/README.md"]:
    t=open(f,encoding="utf-8").read()
    rows="\n".join(l for l in t.splitlines() if l.startswith("| ") and not l.startswith("| ---"))
    print(f"{f}: 表の行 {count(rows)} 件（表以外 {count(t)-count(rows)} 件）")

# (2) 振り返りの一覧: サブプロジェクト列のみ 0 へ。備考列は触らないので 105 のまま
cols={"サブプロジェクト":[], "備考":[]}
for line in open("docs/records/retrospectives/README.md",encoding="utf-8"):
    if not line.startswith("| ") or line.startswith("| ---") or "実施日" in line: continue
    c=[x.strip() for x in line.strip().strip("|").split("|")]
    if len(c)<5: continue
    cols["サブプロジェクト"].append(c[1]); cols["備考"].append(c[4])
for k,v in cols.items(): print(f"振り返り一覧 {k}列: {count(chr(10).join(v))} 件")
PY
```

期待:

- Step 1 の再実行が 0 件（タイトル行に残っていない）
- 決定記録の一覧・課題の一覧はどちらも表の行が **0 件**（着手前は 13 件・15 件。表以外は着手前も 0 件で、変わらない）
- 振り返り一覧の「サブプロジェクト」列が **0 件**（着手前は 4 件）、「備考」列は **105 件のまま変わらない**（触らないため。減っていたら記録本文を書き換えてしまっている）

`git diff docs/records/retrospectives/README.md` で、変更が「サブプロジェクト」列の 4 箇所だけであることを目視で確認する。

- [ ] **Step 5: 差分の確認とコミット**

```bash
git diff --stat docs/records/ docs/working/issues/
git add docs/records/ docs/working/issues/
git commit -m "docs(records): 記録型文書のタイトル 29 件と一覧の記載を置き換え"
```

差分が各ファイル 1 行（タイトル行）と一覧の該当行に限られることを確認する。本文が変わっていないことを `git diff` で目視する。

---

## Task 12: `master.md` の申し送り 2 節

**Files:**
- Modify: `docs/working/handoff/master.md`（「既知のブロッカー・懸念」節と「次セッション開始時のアクション」節）

- [ ] **Step 1: 対象を列挙する**

```bash
sed -n '/^## 既知のブロッカー・懸念/,/^## 実行後処理\|^## Post/p' docs/working/handoff/master.md | grep -nE "突合|消化|消し込|母数|裁定|現役|配線|射程|巡|実質収束|格下げ|逐語厳守|退役|検出資産|基準 \(i\)|逸脱突合|B群判定|spec 確定点 \(|A 群|B 群|ラッパー"
sed -n '/^## 次セッション開始時のアクション/,/^## 重要な意思決定/p' docs/working/handoff/master.md | grep -nE "突合|消化|消し込|母数|裁定|現役|配線|射程|巡|実質収束|格下げ|逐語厳守|退役|検出資産|基準 \(i\)|逸脱突合|B群判定|spec 確定点 \(|A 群|B 群|ラッパー"
```

- [ ] **Step 2: この 2 節だけを直す**

「語の置き換え表」に従う。同ファイルの他の節（作業の目的・関連ドキュメント・節見出しそのもの）は書き換えない。節見出し「Post ラッパー消化記録」も書き換えない（Task 13 で配布物を更新し、利用者がプラグインを更新した後に自然に移行する）。

- [ ] **Step 3: 検証とコミット**

```bash
git diff docs/working/handoff/master.md | grep "^[+-]" | head -40
git add docs/working/handoff/master.md
git commit -m "docs(handoff): master の申し送り 2 節の語彙を置き換え"
```

差分が対象 2 節に収まっていることを目視する。

---

## Task 13: 配布物の生成と版数の更新

**Files:**
- Modify: `.claude-plugin/plugin.json` ほか版数を持つファイル
- Regenerate: `dist/`・`template/`・`.agents/plugins/marketplace.json`

- [ ] **Step 1: 版数を 0.1.19 に上げる**

```bash
grep -rn "0\.1\.18" --include=*.json . | grep -v node_modules | grep -v "^./dist" | grep -v "^./.agents"
```

ヒットした版数をすべて `0.1.19` に直す。

- [ ] **Step 2: 生成器を実行する**

```bash
pwsh -NoProfile -File scripts/build-dist.ps1
pwsh -NoProfile -File scripts/sync-template.ps1
```

`sync-template.ps1` は新しく `docs/overview/wording-replacements.md` を同期するので、`template/docs/overview/wording-replacements.md` が生成されることを確認する。

- [ ] **Step 3: 両方を `-Check` で実行する**

```bash
pwsh -NoProfile -File scripts/build-dist.ps1 -Check; echo "build-dist exit=$?"
pwsh -NoProfile -File scripts/sync-template.ps1 -Check; echo "sync-template exit=$?"
```

期待: どちらも `exit=0`。記法規約の違反が出た場合は、置き換え表ファイルに ADR 番号・課題番号が入っていないかを確認して直す。

- [ ] **Step 4: 生成物を読んで、機械判定が届かない 5 つを目視で確かめる**

`CONTRIBUTING.md`「執行点」の 4 手順のうち 4 番目にあたる工程（確定前レビューで、この手順が計画から漏れていることを検出した）。生成後の `dist/skills/` と `template/` を読んで次の 5 つを探す。

1. 括弧内に参照番号以外の語が同居した行
2. 半角括弧の参照番号
3. 書式例の実在の固有名（プロジェクト名・絶対パス・文書名）
4. 自己参照（`本リポジトリ` / `本 repo`）
5. スクリプトの docstring・利用者へ表示するメッセージ

本サイクルで新規に配布物へ入るのは `template/docs/overview/wording-replacements.md` なので、まずこのファイルを通読する。次に、語を書き換えた `dist/skills/` の各ファイルを差分（`git diff` の範囲）に絞って読む。`CONTRIBUTING.md` は「目視は 1 回で終わらせない」ことを求めているため、Step 7 のコミット直前にもう一度読む。

- [ ] **Step 5: SKILL.md のサイズを確認する**

```bash
for f in skills/*/SKILL.md; do printf "%s %s\n" "$(wc -c < $f)" "$f"; done | sort -rn | head -5
```

期待: すべて 20000 未満。超えた場合は `CONTRIBUTING.md`「全シナリオ共通: SKILL.md のサイズと分割」の判断（責務帰属型 → references 型 → 例外登録）へ進み、その判断を ADR-0123 へ追記する。

- [ ] **Step 6: 増分を記録する**

```bash
find skills -name '*.md' -exec cat {} + | wc -c
wc -c < CONTRIBUTING.md
```

Task 1 Step 1 の値（skills 227867・CONTRIBUTING 58150）との差と増分率を計算し、ADR-0123 の Consequences へ 1 行追記する。

- [ ] **Step 7: 差分の確認とコミット**

```bash
git status --short
git add -- .claude-plugin dist template .agents docs/records/decisions/0123-plain-language-vocabulary-in-normative-documents.md
git commit -m "chore: version 0.1.19 と配布物の再生成"
```

未追跡の 4 件（`docs/conversation_log.md`・`docs/inbox/` の 3 件）を巻き込まないよう、パスを明示して add する。

---

## Task 14: 完了条件の照合とサイクルの終了処理

**Files:**
- Modify: `docs/working/issues/flow/0119-guideline-wording-violates-its-own-plain-language-norm/0119-guideline-wording-violates-its-own-plain-language-norm.md`
- Modify: `docs/working/issues/README.md`
- Modify: `docs/records/decisions/0123-plain-language-vocabulary-in-normative-documents.md`（Status）
- Modify: `docs/records/decisions/README.md`（Status）

- [ ] **Step 1: 完了条件 12 項を 1 つずつ照合する**

設計書 6-3 の 12 項を上から順に確認し、結果を表にしてコミットメッセージへ残す。特に次を機械的に確認する。

```bash
# 条件 1: 4 群に置き換え前の語が残っていないこと
python - <<'PY'
import re,glob
manifest=[l.strip() for l in open("template.manifest",encoding="utf-8") if l.strip() and not l.startswith("#")]
# 置き換え表ファイル自身は「置き換え前」列に旧語を保持する設計なので走査対象から外す。
# Task 1 でこのファイルを template.manifest へ追加するため、除外しないと群 B に入り「残存 0」が原理的に成立しない（確定前レビューで検出）。
manifest=[f for f in manifest if "wording-replacements" not in f]
G={"A":sorted(glob.glob("skills/**/*.md",recursive=True)),"B":manifest,
   "C":["CONTRIBUTING.md","README.md"]+sorted(glob.glob("docs/reference/*.md")),
   "D":[f for f in sorted(glob.glob("docs/current/**/*.md",recursive=True)) if "2026-09-04-plain-language" not in f]}
pats=[("突合",r"突合"),("消化",r"消化"),("消し込",r"消し込"),("母数",r"母数"),("裁定",r"裁定"),
("前置",r"前置(?!き)"),("現役",r"現役"),("配線",r"配線"),("射程",r"射程"),("巡",r"巡"),
("実質収束",r"実質収束"),("格下げ",r"格下げ"),("逐語厳守",r"逐語厳守"),("退役",r"退役"),
("識別子",r"(?<!出所)(?<!安定)(?<!プロジェクト)識別子"),("検出資産",r"検出資産"),("機械的な適応",r"機械的な適応"),
("ラッパー",r"ラッパー"),("A/B群",r"[AB] 群"),("spec確定点(a-c)",r"spec ?確定点 ?\([abc]\)"),
("退役経路",r"退役経路"),("廃止経路",r"廃止経路"),("B群判定",r"B群判定"),("逸脱突合",r"逸脱突合")]
ng=0
for g,fs in G.items():
    for f in fs:
        t=open(f,encoding="utf-8").read()
        for n,p in pats:
            m=re.findall(p,t)
            if m: print(f"残存 群{g} {f}: {n} x{len(m)}"); ng+=len(m)
print("残存合計:",ng)
PY
```

期待: 残存合計 0。

- [ ] **Step 2: ADR-0123 を Accepted へ昇格する**

`decision-log` の `references/status-updates.md`「承認の昇格」の手順に従う。サイクル全体整合検査（5 観点）を実施し、結果をハンドオフの確認記録へ `cyclecheck=` として残す。

あわせて、決定 6 の「対応する一覧」に次の 1 文を補う（本サイクルで実際に読み違えが起きた箇所。差分確認巡で「決定 6 の文言だけでは一段階の解釈を要する」と指摘された）。

```
一覧の側で置き換えるのは、各記録を指す識別ラベルの列である（実ファイルの見出しの逐語転記でない言い換えラベルも含む）。同じ表にあっても、当時の観察を残した記録本文にあたる列は置き換えない。
```

- [ ] **Step 3: Issue-0119 を閉じる**

課題ファイルの Status を `closed` にし、「結論」節へ ADR-0123 と本計画のパスを書く。`docs/working/issues/README.md` の該当行を `closed` に更新する。フォルダ昇格済みの課題なので、課題管理定義の閉じるときの移設判定を実施する。未検証のまま残る 2 件（置き換え候補語の読みやすさの利用者評価・括弧説明の誘発によるトークン増）を新規課題として起票するかを判定する。

- [ ] **Step 4: 検証**

```bash
grep -n "Status" docs/working/issues/flow/0119-*/0119-*.md | head -2
grep -n "0123" docs/records/decisions/README.md
grep -n "0119" docs/working/issues/README.md
```

期待: 課題が `closed`、ADR-0123 が `Accepted`、課題一覧の行が更新済み。

- [ ] **Step 5: コミット**

```bash
git add -- docs/working/issues docs/records/decisions
git commit -m "docs: ADR-0123 を Accepted へ昇格し Issue-0119 を close"
```

---

## 自己点検の結果

**設計書の各節に対応するタスク**

| 設計書の節 | タスク |
|---|---|
| 設計 1（対象の定義） | Task 1（表ファイルへ判定の基準を書く） |
| 設計 2（置き換え表） | Task 6・8・9・10（4 群の置き換え）・Task 7（型 2） |
| 設計 3-1（表ファイル） | Task 1 |
| 設計 3-2（AGENTS.md の 1 行） | Task 2 |
| 設計 3-3（CONTRIBUTING の新節） | Task 2 |
| 設計 4-1（節見出しと汎用 1 文） | Task 3 |
| 設計 4-2（マイルストーン名） | Task 5 Step 4 |
| 設計 4-3（記録の文字列） | Task 4 |
| 設計 4-4（退役経路の 3 役割） | Task 8 Step 2（群 C）・Task 10 Step 2（群 D の 7 ファイル 16 件）・Task 6 Step 2（群 A の `worklog-skillify`） |
| 設計 4-5（master.md の 2 節） | Task 12 |
| 設計 5（記録型文書のタイトル） | Task 11 |
| 設計 6-2（サイズ） | Task 13 Step 5・6 |
| 設計 6-3（完了条件 12 項） | Task 14 Step 1 |

**未対応が無いことの確認**: 完了条件 12 項のうち、

- 条件 2「型 2 の 4 語を 4 群で目視点検」→ Task 7（確定前レビューで群 A のみになっていたのを 4 群へ広げた）
- 条件 4「配置の早見表へ 1 行」→ Task 1 Step 4
- 条件 5「他 5 スキル 7 箇所」→ Task 3 Step 5
- 条件 7「執行点 4 手順」→ Task 13 Step 2（生成器の実行）・Step 3（両方の `-Check`）・Step 4（機械判定が届かない 5 つの目視）・**Step 7（生成物を同じコミットに含める）**。4 手順の 3 番目に対応するのは Step 7 で、Step 2・3・4 には含まれない
- 条件 11「本サイクルの成果物（設計書・ADR-0123・ハンドオフ・実装計画）が新しい語彙で書かれている」→ 設計書・ADR-0123・本計画は該当し、置き換え対象の語は表と説明の中でのみ使っている。**ハンドオフは本サイクルでは書き換えない**（設計書 6-1。自リポジトリのハンドオフを読み書きするスキルが配布物経由で動いており、まだ古い書式を前提にしているため）。したがって条件 11 のうちハンドオフの分は、Task 13 で配布物を更新し利用者がプラグインを更新した後の次サイクルで満たす。この扱いを Task 14 Step 1 の照合結果に 1 行書き残す
