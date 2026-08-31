# ADR-0121 実装計画: SKILL.md のサイズ警告と分割判断の型・例外テーブル（＋Issue-0111 同梱）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** SKILL.md の肥大を `build-dist.ps1` のサイズ警告で検知し、CONTRIBUTING.md の全シナリオ共通節が分割判断（責務帰属型 → references 型 → 例外登録）の正本を担う機構を導入する。あわせて本サイクルの適用として `pre-finalization-review` を references 型で分割し、Issue-0111（merge-practice.md 導入文の重複）を同梱で解消する。

**Architecture:** 検知はスクリプト（`scripts/build-dist.ps1` の定数＋計測ループ＋例外テーブル）、判断規範は文書（`CONTRIBUTING.md` の全シナリオ共通節）、到達経路は警告文のポインタと 5 シナリオのチェックリスト配線が担う。`pre-finalization-review` は SKILL.md（提示規則・観点と初回体数・レビューの狙い）と `references/` 3 ファイル（反復規範と実施方式／実施手順／適用例と根拠）へ分ける。移設対象節を名指しする参照は本文側・移設側・移設側どうし・他文書・ADR の 5 方向を全数走査して張り替える。

**Tech Stack:** PowerShell 7（`scripts/build-dist.ps1`）、Markdown（skills / docs）、git。配布物生成は `scripts/build-dist.ps1`、テンプレート同期 `scripts/sync-template.ps1` は本サイクルでは**実行しない**。根拠: `skills/` は ADR-0016 により template 対象外。`template.manifest` 記載 6 ファイルは変更しない。空インデックス生成対象 3 件のうち `docs/working/issues/README.md`（Task 1・13）と `docs/records/decisions/README.md`（Task 13）は変更するが、変更はいずれもインデックスのテーブル行のみで、`sync-template.ps1` はデータ行を除去して空インデックスを生成する（`scripts/sync-template.ps1` の `New-EmptyIndexContent`）ため生成結果は変わらない。無差分であることは Task 12 Step 12-3 の `-Check` が確認する（**ただし Task 12 は Task 13 より前に走るため、`-Check` が実測で覆うのは Task 1 の変更まで**。Task 13 Step 13-4・13-7 の Status 変更も同じくテーブルのデータ行のみの編集なので同じ結論になるが、これは `New-EmptyIndexContent` の実装に基づく推定であり、Task 13 の後に `-Check` を再実行するわけではない）。

---

## 逸脱判断の既定

`skills/start-work/references/plan-deviation-defaults.md`（plugin 0.1.16 時点の版）の既定どおり。基準の追加・強化は行わない。

- **確定前レビューからの引き継ぎ一覧の所在**: 2 系統あるので分けて書く。
  - **本計画自身の plan 確定点レビュー由来**（`plan-deviation-defaults.md` の前処理 2. が突合対象とするのはこちら）: **不採用 2 件あり**。(1) 新設節へ転記する `（写像 plan を 3 体分離で 2 巡・指摘 31 件を要した対抗実測がある。Issue-0107）` が記法規約 R1-a に該当するか — **引き継ぎ先は Task 5 Step 5-14 の配布物目視**。(2) 執行点手順 1 の解釈判断が Task 1・Task 13 の各コミット時点で参照されない — **引き継ぎ先は Task 12 preamble の記述**。いずれも不採用の理由と実証は末尾「確定前レビューの記録」の第 2 巡・第 3 巡を参照
  - **上流（ADR-0121 の spec 確定点レビュー）由来の参照材料**: ADR-0121 の Considered Alternatives 4・5・7・8 と Consequences の受容記述（`docs/records/decisions/0121-skill-md-size-trigger-and-split-norm.md`）。設計時の不採用判断は同 ADR 本文へ吸収済みで独立の一覧ファイルは無い。これは前処理 2. の突合対象ではなく、実装時に設計意図を確認するための参照先である
- **前倒し型の判定 3 条件**: 部分成立（設計は確定済み＝成立、実コード全文を計画に載せられる規模＝成立、実行による安全網が無い＝**不成立**。Task 2 の PowerShell 変更は `build-dist.ps1` の実行と `-Check` が安全網になり、文書編集は Task 12 の生成器実行と目視が受ける）。したがって**逐語厳守は課さず、格下げ安全弁（設計の変更に至ったタスクはタスク別独立レビューへ格下げ）のみ維持する**
- 逸脱記録は当該タスクの最後の手順の直後へ `逸脱記録: <型> / <帰結> / <識別子・根拠>` の 1 行で残す（行頭固定・直前に空行 1 行）
- **日付リテラルの一般規定**: 本計画は作成日 2026-08-31 の日付を各所に固定文字列で書いている。**本計画が課題・インデックス・ADR へ新規に書き込む日付リテラルは、例外なくすべて実装当日の日付へ機械的に読み替える**（`issue-management.md` は `Opened` / `Closed` と検討状況の日付を実イベント日として扱うため）。**列挙ではなく規則として適用すること** — 対象箇所を列挙する形にすると必ず漏れが出る（起票する課題の `Opened` は読み替えたのに同じファイルの検討状況の起票行は据え置き、といった同一ファイル内の食い違いが生じる）。読み替えは機械的な適応として、当該タスクの逸脱記録へ 1 行残す。以降の各タスクで個別の注記は繰り返さない。**対象外**: 歴史的事実として書く実測日（Issue-0115/0116 本文の「31,097B（2026-08-31 実測）」「26,801B（2026-08-31 実測）」など）。これは計画作成時点の実測を記述したもので実イベント日ではないため、読み替えない

## 前提の確認（着手前に 1 度だけ）

- [ ] **Step 0-1: ブランチと現況を確認**

```bash
git branch --show-current
```

Expected: `feature/issue-0105-skill-size-norm`

- [ ] **Step 0-2: 分割前のサイズを実測して控える**

```bash
for f in skills/*/SKILL.md; do echo "$(wc -c < $f) $f"; done | sort -rn
```

Expected（2026-08-31 時点の基準値。以降の Task の期待値はこれを起点とする）:

```
42643 skills/pre-finalization-review/SKILL.md
31097 skills/session-handoff/SKILL.md
26801 skills/decision-log/SKILL.md
19042 skills/retrospective/SKILL.md
15558 skills/start-work/SKILL.md
```

（以下 `subagent-dispatch` 10956 ほか、すべて 20000 未満）

---

## ファイル構成

| ファイル | 区分 | 責務 / 変更内容 | Task |
|---|---|---|---|
| `docs/working/issues/flow/0115-session-handoff-size-split-candidate.md` | 新規 | session-handoff 分割候補の課題 | 1 |
| `docs/working/issues/flow/0116-decision-log-size-split-candidate.md` | 新規 | decision-log 分割候補の課題 | 1 |
| `docs/working/issues/README.md` | 変更 | 課題インデックスへ 2 行追加、Issue-0105 / 0111 の Status 更新 | 1 / 13 |
| `scripts/build-dist.ps1` | 変更 | サイズ計測・目安値定数・例外テーブル・警告出力の追加 | 2 / 11 |
| `CONTRIBUTING.md` | 変更 | 全シナリオ共通節の新設＋5 シナリオのチェックリスト配線 | 3 / 4 |
| `skills/pre-finalization-review/SKILL.md` | 変更 | 本文を提示規則・観点と初回体数・レビューの狙いへ絞る（20KB 以下） | 5 |
| `skills/pre-finalization-review/references/iteration-norms.md` | 新規 | 指摘反映後の反復（反復規範）＋反復の実施（方式） | 5 |
| `skills/pre-finalization-review/references/review-procedure.md` | 新規 | 実施手順 1〜6 | 5 |
| `skills/pre-finalization-review/references/examples-and-evidence.md` | 新規 | 適用例 2 種＋根拠と世代 | 5 |
| `skills/session-handoff/SKILL.md` | 変更 | 移設先を指す参照 2 箇所の張り替え | 6 |
| `skills/decision-log/SKILL.md` | 変更 | 移設先を指す参照 1 箇所の張り替え | 6 |
| `skills/subagent-dispatch/SKILL.md` | 変更 | 移設先を指す参照 1 箇所の張り替え | 6 |
| `docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md` | 変更 | 正本ポインタ 3 箇所の張り替え＋分割の注記 1 行 | 6 |
| `docs/current/specs/2026-08-28-start-work-responsibility-split-design.md` | 変更 | 分割の部分修正注記 1 行 | 6 |
| `docs/records/decisions/0067,0080,0093,0107,0108,0117,0120-*.md` | 変更 | 部分修正注記 各 1 行 | 7 |
| `docs/records/decisions/0116-*.md` | 変更 | 退役判定（存置）1 行＋改訂記録 1 行 | 7 |
| `skills/start-work/references/merge-practice.md` | 変更 | 導入文を発火点の説明へ絞る（Issue-0111） | 8 |
| `docs/working/issues/flow/0099-*.md` | 変更 | 検討状況へ 1 行追記 | 9 |
| `docs/current/specs/2026-08-07-distributed-artifact-generation/02-distribution-generator.md` | 変更 | 責務・標準出力・サブ機能の追従 | 10 |
| `.claude-plugin/plugin.json` / `.claude-plugin/marketplace.json` | 変更 | version 0.1.16 → 0.1.17 | 12 |
| `dist/**` / `.agents/plugins/marketplace.json` | 生成 | `build-dist.ps1` で再生成し、`skills/` を触った各タスクのコミットへ同梱する | 2/3・5・6・8・11・12 |
| `docs/records/decisions/0121-*.md` | 変更 | Status を Accepted へ | 13 |
| `docs/working/issues/flow/0105-*.md` / `system/0111-*.md` | 変更 | close＋実測値訂正 | 13 |

---

### Task 1: 分割候補 2 件の課題起票

**Files:**
- Create: `docs/working/issues/flow/0115-session-handoff-size-split-candidate.md`
- Create: `docs/working/issues/flow/0116-decision-log-size-split-candidate.md`
- Modify: `docs/working/issues/README.md`（flow セクション末尾に 2 行追加）

採番は両セクション通しの連番で、現在の最大は 0114（`docs/overview/issue-management.md` 3 節）。この 2 件は Task 2 の例外テーブルの根拠コメントから参照されるため、最初に起票する。

- [ ] **Step 1-1: 採番の最大値を確認**

```bash
grep -oE "^\| \[0[0-9]{3}\]" docs/working/issues/README.md | grep -oE "[0-9]{4}" | sort -n | tail -1
```

Expected: `0114`（異なる場合は以降の番号を最大値+1、+2 へ読み替える。読み替えは機械的な適応として逸脱記録へ 1 行）

- [ ] **Step 1-2: Issue-0115 を作成**

`docs/working/issues/flow/0115-session-handoff-size-split-candidate.md`:

```markdown
# Issue-0115: session-handoff の SKILL.md が分割候補のまま暫定登録されている

- **Status**: open
- **Opened**: 2026-08-31
- **起票元**: ADR-0121 決定 5（本サイクルの適用範囲を pre-finalization-review 1 件に絞った残余）
- **関連**: ADR-0121（サイズ警告と分割判断の型）、ADR-0116（責務帰属型・references 型の分割）、Issue-0105（サイズ・分割規範の不在）

## 課題内容

`skills/session-handoff/SKILL.md` は 31,097B（2026-08-31 実測）で、ADR-0121 の目安値 20KB を超過している。偏りの実測は独立手順「移設」3 節 5.8KB＋操作 5 種のうち read を除く 4 種（create / update / finalize / cycle-reset）10.1KB ＝ 約 51% が条件発火の内容である。同スキルは Post ラッパーで毎マイルストーン読まれるため、肥大はセッションのコンテキスト費用へ反復的に効く（Issue-0105 の起票理由でもある）。

本サイクル（ADR-0121）では中核スキルの参照配線の張り替え規模を理由に分割実施を pre-finalization-review 1 件へ絞り、本件は次サイクル以降へ送った。`scripts/build-dist.ps1` の例外テーブルへ**分割待ちの暫定行**として本 Issue 番号を根拠に登録してあり、承認済みサイズを超えて成長すれば再警告する。

分割の型は ADR-0121 決定 4 の ①責務帰属型 → ②references 型 → ③例外登録 の順で検討する。

## 検討状況

- 2026-08-31: 起票。分割の着手はユーザー判断。例外テーブルへの暫定登録で警告は沈黙しているが、承認済みサイズを超えた成長で再発火する

## 結論

（open）
```

- [ ] **Step 1-3: Issue-0116 を作成**

`docs/working/issues/flow/0116-decision-log-size-split-candidate.md`:

```markdown
# Issue-0116: decision-log の SKILL.md が分割候補のまま暫定登録されている

- **Status**: open
- **Opened**: 2026-08-31
- **起票元**: ADR-0121 決定 5（本サイクルの適用範囲を pre-finalization-review 1 件に絞った残余）
- **関連**: ADR-0121（サイズ警告と分割判断の型）、ADR-0116（責務帰属型・references 型の分割）、Issue-0105（サイズ・分割規範の不在）

## 課題内容

`skills/decision-log/SKILL.md` は 26,801B（2026-08-31 実測）で、ADR-0121 の目安値 20KB を超過している。偏りの実測はサイクル全体整合検査 6.7KB＋ステータス変更 4.1KB ＝ 約 40% が条件発火の内容である（前者はチェックポイント通過時、後者は既存 ADR の状態を変えるときにのみ読む）。

本サイクル（ADR-0121）では分割実施を pre-finalization-review 1 件へ絞り、本件は次サイクル以降へ送った。`scripts/build-dist.ps1` の例外テーブルへ**分割待ちの暫定行**として本 Issue 番号を根拠に登録してある。

分割の型は ADR-0121 決定 4 の ①責務帰属型 → ②references 型 → ③例外登録 の順で検討する。

## 検討状況

- 2026-08-31: 起票。分割の着手はユーザー判断。例外テーブルへの暫定登録で警告は沈黙しているが、承認済みサイズを超えた成長で再発火する

## 結論

（open）
```

- [ ] **Step 1-4: インデックスへ 2 行追加**

`docs/working/issues/README.md` の flow セクション末尾（`| [0114](flow/0114-quality-investment-marginal-utility-and-stratified-defaults/0114-quality-investment-marginal-utility-and-stratified-defaults.md) | …` の行の直後）へ:

```
| [0115](flow/0115-session-handoff-size-split-candidate.md) | session-handoff の SKILL.md が分割候補のまま暫定登録されている | open | 2026-08-31 |
| [0116](flow/0116-decision-log-size-split-candidate.md) | decision-log の SKILL.md が分割候補のまま暫定登録されている | open | 2026-08-31 |
```

- [ ] **Step 1-5: 検証**

```bash
ls docs/working/issues/flow/0115-session-handoff-size-split-candidate.md docs/working/issues/flow/0116-decision-log-size-split-candidate.md && grep -c "^| \[011[56]\]" docs/working/issues/README.md
```

Expected: 2 ファイルのパスが表示され、最終行が `2`

- [ ] **Step 1-6: コミット**

```bash
git add docs/working/issues/flow/0115-session-handoff-size-split-candidate.md docs/working/issues/flow/0116-decision-log-size-split-candidate.md docs/working/issues/README.md && git commit -m "issue: 0115/0116 - session-handoff / decision-log を SKILL.md 分割候補として起票（ADR-0121 決定 5 の残余）"
```

逸脱記録: 機械的な適応 / 採用 / 日付リテラルの一般規定（宣言欄）、Issue-0115/0116 の Opened・検討状況の起票行とインデックス 2 行の日付を 2026-08-31 から実装当日 2026-09-01 へ読み替え、本文の「31,097B（2026-08-31 実測）」「26,801B（2026-08-31 実測）」は歴史的事実の実測日のため据え置き

逸脱記録: 対象外 / 対象外 / 実装着手前に計画末尾「確定前レビューの記録」へ第 5 巡の節を補完（コミット dc0323c、ユーザー承認 2026-09-01）、確定前レビュー工程の記録欠落の補完でありタスクの指示内容は不変のため plan-deviation-defaults.md の適用対象外と裁定、あわせて本タスクのコミットへ計画ファイルを含めて逸脱記録行を同時に残す

---

### Task 2: build-dist.ps1 へサイズ計測と例外テーブルを組み込む

**Files:**
- Modify: `scripts/build-dist.ps1`（`$sources` 収集の直後・規約判定ループと `-Check` 分岐より前）

ADR-0121 決定 1・2・3 の実装。計測は**走査対象の収集直後**に置く。規約違反の abort（`exit 1`）と `-Check` の早期 `exit` はいずれも後段にあるため、この位置なら通常実行・`-Check` の両モードで必ず走る。出力は `Write-Warning`（警告ストリーム）で、終了コードは変えない。

`scripts/build-dist.ps1` は配布対象ソースではない（`template.manifest` 未記載・`skills/` 外）ため記法規約の適用外だが、既存コメントの house style（全角括弧に識別子）へ揃える。

- [ ] **Step 2-1: 挿入位置を確認**

```bash
grep -n '^\$sources = @(Get-ChildItem' scripts/build-dist.ps1
```

Expected: `204:$sources = @(Get-ChildItem -Path $srcDir -Recurse -File | Sort-Object FullName)`

- [ ] **Step 2-2: 計測ブロックを挿入**

`$sources = @(...)` の行の直後（`# 2. 規約判定と変換を1ループで行う` のコメントブロックより前）へ、空行を 1 行はさんで以下を挿入する:

```powershell
# 1.5 SKILL.md のサイズ計測（ADR-0121）。走査対象の収集直後・規約判定と -Check 分岐より前に置き、
#     通常実行と -Check の両モードで同じ計測が走ることを保証する。警告は非ブロック（終了コードを変えない）。
#     目安値の根拠と分割判断の手順は CONTRIBUTING.md「全シナリオ共通: SKILL.md のサイズと分割」が正本。
$skillSizeThreshold = 20000   # 目安値 20KB（1KB = 1000 バイト）
# 例外テーブル: スキル名 → 承認済みサイズ（バイト）。各行に判断根拠を必ず併記する。
# 承認済みサイズ以下は警告せず、それを超えて成長したら再警告する。引き上げは
# CONTRIBUTING.md の共通節が定める ①責務帰属型 →②references 型 →③例外登録 の判断を経てから行う。
$skillSizeExceptions = @{
    'session-handoff' = 31097   # 分割待ちの暫定行。根拠と追跡は起票済みの課題（Issue-0115）
    'decision-log'    = 26801   # 分割待ちの暫定行。根拠と追跡は起票済みの課題（Issue-0116）
}
$skillNormRef = 'CONTRIBUTING.md「全シナリオ共通: SKILL.md のサイズと分割」'
foreach ($skillDir in @(Get-ChildItem -Path $srcDir -Directory | Sort-Object Name)) {
    $skillMd = Join-Path $skillDir.FullName 'SKILL.md'
    if (-not (Test-Path $skillMd)) { continue }
    $skillBytes = (Get-Item $skillMd).Length
    $limit = $skillSizeThreshold
    $limitLabel = "目安値 $skillSizeThreshold"
    if ($skillSizeExceptions.ContainsKey($skillDir.Name)) {
        $limit = $skillSizeExceptions[$skillDir.Name]
        $limitLabel = "承認済みサイズ $limit"
    }
    if ($skillBytes -gt $limit) {
        $mdTotal = 0
        foreach ($md in @(Get-ChildItem -Path $skillDir.FullName -Recurse -File -Filter '*.md')) { $mdTotal += $md.Length }
        Write-Warning "[build-dist] $($skillDir.Name)/SKILL.md: $skillBytes bytes > ${limitLabel}。分割判断は ${skillNormRef}を参照してください。"
        Write-Warning "  - スキルディレクトリ配下の全 md 合計: $mdTotal bytes（参考値。出力雛形等も含む粗い値で、閾値は課さない）"
    }
}
```

- [ ] **Step 2-3: 通常実行して警告が出ないことを確認**

この時点では `session-handoff` / `decision-log` は例外テーブルの登録値と同値、`pre-finalization-review` はまだ 42,643B で目安値超過のため**警告が 1 件出る**のが正しい（分割は Task 5 で行う）。

警告 2 行は計測の挿入位置（`$sources` 収集の直後）ゆえ**出力の先頭**（`Scanning` 行より前）に出るため、`tail` で末尾を見ると切り落とされる。警告の確認と `Done.` の確認は 2 コマンドに分ける。

```bash
pwsh scripts/build-dist.ps1 2>&1 | grep "SKILL.md: 42643 bytes"
```

Expected: `pre-finalization-review/SKILL.md: 42643 bytes > 目安値 20000。…` の本体 1 行が表示される（続く参考値の行は `全 md 合計` を含む別行）

```bash
pwsh scripts/build-dist.ps1 2>&1 | grep -c "全 md 合計"
```

Expected: `1`（参考値の行が 1 件）

```bash
pwsh scripts/build-dist.ps1 2>&1 | tail -1
```

Expected: `[build-dist] Done. 22 files written to dist/, 1 to repository root.`

```bash
pwsh scripts/build-dist.ps1 > /dev/null 2>&1; echo "exit=$?"
```

Expected: `exit=0`（警告が非ブロックであることの確認）

- [ ] **Step 2-4: `-Check` モードでも同じ計測が走ることを確認**

```bash
pwsh scripts/build-dist.ps1 -Check 2>&1 | grep -c "SKILL.md: 42643 bytes"
```

Expected: `1`

- [ ] **Step 2-5: この時点ではコミットしない**

警告文が指す `CONTRIBUTING.md`「全シナリオ共通: SKILL.md のサイズと分割」は Task 3 で新設するため、ここで単独コミットすると宙に浮いたポインタを持つ状態が履歴に残る。**コミットは Task 3 Step 3-4 で束ねて 1 回**行う（Task 5 と同じ扱い。参照が宙に浮く中間状態を単独コミットにしない）。

逸脱記録: 対象外 / 対象外 / 本タスクで指摘は発生していない、行は Task 実行時に帰結が出た場合のみ追記する

---

### Task 3: CONTRIBUTING.md へ全シナリオ共通節を新設

**Files:**
- Modify: `CONTRIBUTING.md`（`### 本規約自体の退役規範`（記法規約節の末尾）と `## シナリオ: 原則を追加・変更するとき` の間）

ADR-0121 決定 4 の常設先。既存 3 共通節と同じ「共通節に正本・各シナリオのチェックリストから参照」の型に揃え、参照元を示す 1 行と「本規範自体の退役規範」小節を含める。`CONTRIBUTING.md` は配布対象ソースではない（`template.manifest` 未記載）ため記法規約の適用外。

- [ ] **Step 3-1: 挿入位置を確認**

```bash
grep -n "^## シナリオ: 原則を追加・変更するとき" CONTRIBUTING.md
```

Expected: `205:## シナリオ: 原則を追加・変更するとき`

- [ ] **Step 3-2: 共通節を挿入**

上記の行の直前へ、以下を丸ごと挿入する（末尾に空行 1 行を置き、既存の見出しと詰めない）:

```markdown
## 全シナリオ共通: SKILL.md のサイズと分割

本節は `scripts/build-dist.ps1` のサイズ警告文と、「Skillを新規作成・改定するとき」「AGENTS.md を棚卸しするとき」「機能ブロック駆動の設計スキル（feature-block-design）を変更するとき」「振り返りスキル（retrospective）を変更するとき」「ワークフロー起点スキル（start-work）を変更するとき」の各チェックリストから参照される。

### 適用対象

`skills/*/SKILL.md`（ソース側）に適用する。書き手が編集する実体を対象とするためであり、配布物（`dist/` 側）は出所識別子の除去により小さくなるため対象にしない。`references/` 配下その他の同梱ファイルには閾値を課さない（総量は警告文へ参考値として併記される）。

### 背景

SKILL.md は全文がコンテキストへ読み込まれる。規範の追加は既存スキルへの追記に流れやすく、条件発火・低頻度の内容が大きな割合を占める「偏り」が生じても、常設の検知経路が無ければ振り返りまで浮上しない（Issue-0105。start-work が 34.7KB へ成長した実測）。サイズは「条件発火節の割合 × 読み込み頻度」の代理指標であり、条件発火割合そのものは機械計測できない。したがって**サイズ超過は分割の義務づけではなく、分割判断の発火である**（ADR-0121）。

### 検知

`scripts/build-dist.ps1` が `skills/*/SKILL.md` のサイズを実測し、目安値（既定 **20KB**。1KB = 1000 バイト）または例外テーブルの承認済みサイズを超えていたら警告する。警告は**非ブロック**（終了コードを変えない）で、通常実行・`-Check` の両モードで走る。計測は「配布対象ソースの記法規約」の執行点 4 手順が課す生成器実行へ相乗りするため、別途「測ること」を想起する必要はない。ただしコミット前フックは無く、執行点手順の遵守には依存する。

### 警告発火時の判断

次の順で検討する。

1. **責務帰属型**: 当該規範の正本が他スキルの責務である場合、所有スキルへ移設する（ADR-0116 決定 1 の型）
2. **references 型**: **条件発火節に限り** `skills/<skill>/references/` 配下へ移し、発火時にのみ読ませる（ADR-0116 決定 4 の型）。**発火時に毎回必要な内容の退避は認めない**
3. **例外登録**: 1 ファイル維持が合理的な場合（凝集）、または分割を先送りする場合。判断を ADR に記録し、例外テーブルへ登録する

1・2 のいずれも**条文複写を禁止する**（正本ごと移し、移設対象節を名指しする参照を全数走査して張り替える）。

### 例外テーブルの運用規律

例外テーブルは `scripts/build-dist.ps1` 内の定数表（スキル名 → 承認済みサイズ）である。定数表の設置場所と警告の挙動はスクリプト側の実装が定め、本節は運用の規律のみを定める。

- **根拠コメント必須**: 各行に判断根拠（ADR 番号・Issue 番号）をコメントで必ず併記する
- **登録値はユーザー承認で確定する**: 実測値のままとするか運用余裕を積むかは、警告の再発頻度と分割着手の見込みを材料にその場で判断する。分割待ちの行が成長して立つ警告は、分割着手までの意図的な圧力として受容してよい
- **引き上げは判断を経てから**: 承認済みサイズの引き上げは、上記「警告発火時の判断」の 1 → 2 → 3 を経てから行う（テーブルの数値だけを書き換える最安経路は採らない）
- **行の性質と追跡の帰属**: 凝集と判断した恒久行か分割待ちの暫定行か、およびその解消の追跡は、行が根拠として指す ADR / Issue 側が担う。テーブル側に分類の規範は置かない
- 承認済みサイズ**以下**は警告せず、それを**超えて成長したら再警告する**

### 本規範自体の退役規範

次の 2 条件が揃った状態が観測されたら、本規範とサイズ警告の簡素化・退役を候補としてユーザーへ提案する: (1) 警告の発火が長期にわたり 0 件である（例外テーブルに分割待ち根拠の Issue 行が残る間は存置側とする） (2) 肥大の同型 delta（worklog）・同型課題が中央ストアへ現れない。判断はユーザーが行う。（正本は ADR-0121 の過剰適合点検ブロック「退役経路」欄。本小節はその要旨である）
```

- [ ] **Step 3-3: 検証**

```bash
grep -n "^## 全シナリオ共通" CONTRIBUTING.md
```

Expected: 4 行（過剰適合の点検 / 新設の評価可能性 / 配布対象ソースの記法規約 / SKILL.md のサイズと分割）。新設節が `## シナリオ: 原則を追加・変更するとき` より前にあること

```bash
grep -c "本節は \`scripts/build-dist.ps1\` のサイズ警告文と" CONTRIBUTING.md
```

Expected: `1`（参照元を示す 1 行の存在確認）

- [ ] **Step 3-4: Task 2 の成果と束ねてコミット**

Task 2 の変更（生成器・生成物）と本タスクの変更（共通節）を 1 コミットにする。警告文の指し先が同じコミット内で実在するようにするため。`build-dist.ps1` の実行で `dist/` が再生成されているので生成物も含める（CONTRIBUTING 執行点手順 3）。

```bash
git add scripts/build-dist.ps1 CONTRIBUTING.md dist .agents/plugins/marketplace.json && git commit -m "feat: SKILL.md のサイズ警告と例外テーブル、および分割判断の共通節を導入（ADR-0121 決定 1〜4）"
```

---

### Task 4: CONTRIBUTING.md のチェックリスト配線（5 シナリオ）

**Files:**
- Modify: `CONTRIBUTING.md`（4 シナリオへ項目追加、start-work シナリオは既存項目の文言拡張）

ADR-0121 決定 4 の配線。「AGENTS.md を更新するとき」シナリオはチェックリスト節を持たず、`skills/` への退避の実行経路は棚卸しシナリオが受けるため**非配線**とする。「原則を追加・変更するとき」「ADRを記録するとき」「未決事項・課題を記録するとき」「振り返りで抽出された課題に対策するとき」も対象外（SKILL.md の編集を伴う経路を自前で持たない）。

- [ ] **Step 4-1: 「Skillを新規作成・改定するとき」チェックリストへ 1 項目追加**

現行の最終行:

```
- 配布対象ソースの記法規約に適合しているか（「全シナリオ共通: 配布対象ソースの記法規約」の執行点 4 手順を実施したか。ADR-0083）
```

は CONTRIBUTING.md 中に **6 箇所**（原則追加・変更 L229 / 棚卸し L296 / Skill 新規作成・改定 L330 / start-work L412 / feature-block-design L445 / retrospective L487）存在する。個数に頼らず、**「シナリオ: Skillを新規作成・改定するとき」節内の行**（`### チェックリスト` 直後のブロック内、`- \`template.manifest\` には skills/ を追加していないか（ADR-0016 で除外規約）` を含むブロック）を対象にする。その最終行の直後へ追加:

```
- SKILL.md のサイズ警告（`scripts/build-dist.ps1`）が発火していないか。発火したら分割判断を行ったか（「全シナリオ共通: SKILL.md のサイズと分割」/ ADR-0121。対象は `skills/*/SKILL.md` であり、AGENTS.md の閾値〈`check-claude-md-size.ps1`〉とは別の判定である）
```

- [ ] **Step 4-2: 「AGENTS.md を棚卸しするとき」チェックリストへ 1 項目追加**

同節の最終行（記法規約の行）の直後へ追加:

```
- 退避（Layer 3 への移設）を行った場合、移設先の SKILL.md のサイズ警告が発火していないか。発火したら分割判断を行ったか（「全シナリオ共通: SKILL.md のサイズと分割」/ ADR-0121。対象は `skills/*/SKILL.md` であり、本節の閾値〈AGENTS.md 自身のバイト数・箇条書き件数〉とは別の判定である）
```

- [ ] **Step 4-3: feature-block-design シナリオのチェックリストへ 1 項目追加**

`## シナリオ: 機能ブロック駆動の設計スキル（feature-block-design）を変更するとき` の `### チェックリスト` 最終行（記法規約の行）の直後へ追加:

```
- SKILL.md のサイズ警告（`scripts/build-dist.ps1`）が発火していないか。発火したら分割判断を行ったか（「全シナリオ共通: SKILL.md のサイズと分割」/ ADR-0121。対象は `skills/feature-block-design/SKILL.md`）
```

- [ ] **Step 4-4: retrospective シナリオのチェックリストへ 1 項目追加**

`## シナリオ: 振り返りスキル（retrospective）を変更するとき` の `### チェックリスト` 最終行（記法規約の行）の直後へ追加:

```
- SKILL.md のサイズ警告（`scripts/build-dist.ps1`）が発火していないか。発火したら分割判断を行ったか（「全シナリオ共通: SKILL.md のサイズと分割」/ ADR-0121。対象は `skills/retrospective/SKILL.md`）
```

- [ ] **Step 4-5: start-work シナリオは既存項目を文言拡張（項目を増やさない）**

ADR-0116 決定 5（start-work シナリオへ新規チェックリスト項目を追加しない）を維持するため、既存項目を置換する。

旧:

```
- フェーズの責務分離が崩れていないか（ドメイン規範の正本を本文へ持ち込んでいないか。正本は所有スキルまたは references へ。ADR-0116）
```

新:

```
- フェーズの責務分離が崩れていないか（ドメイン規範の正本を本文へ持ち込んでいないか。正本は所有スキルまたは references へ。ADR-0116）。SKILL.md のサイズ警告が発火した場合は「全シナリオ共通: SKILL.md のサイズと分割」の分割判断へ進む（ADR-0121）
```

- [ ] **Step 4-6: 検証**

```bash
grep -c "全シナリオ共通: SKILL.md のサイズと分割" CONTRIBUTING.md
```

Expected: `6`（新設節の見出し 1＋節内の自己言及 0＋チェックリスト 4＋start-work の文言拡張 1）

```bash
grep -n "SKILL.md のサイズ警告" CONTRIBUTING.md
```

Expected: 5 行（Skill 新規作成・改定 / 棚卸し / feature-block-design / retrospective / start-work）

```bash
grep -c "^- フェーズの責務分離が崩れていないか" CONTRIBUTING.md
```

Expected: `1`（置換後も 1 行のまま。項目が増えていないこと）

- [ ] **Step 4-7: コミット**

```bash
git add CONTRIBUTING.md && git commit -m "docs: SKILL.md サイズ共通節を 5 シナリオのチェックリストへ配線（ADR-0121 決定 4）"
```

---

### Task 5: pre-finalization-review の references 型分割

**Files:**
- Create: `skills/pre-finalization-review/references/iteration-norms.md`
- Create: `skills/pre-finalization-review/references/review-procedure.md`
- Create: `skills/pre-finalization-review/references/examples-and-evidence.md`
- Modify: `skills/pre-finalization-review/SKILL.md`

ADR-0121 決定 5 の実装。**コミットは本タスクの末尾で 1 回**とし、参照が宙に浮く中間状態を単独コミットにしない。

**完了条件（2 つ）**: (1) `SKILL.md` が 20,000 バイト以下 (2) 確定点での初回提示が references の読み込みなしで履行できる。

**本文へ正本ごと残す範囲**（ADR-0121 決定 5 の明示列挙）: 型別体数既定の本体・その適用に要する但し書き（写像判定の迷い既定・「レビュー済み上流」の参照・設計文書兼用 ADR の扱い）・前提文（観点は 4 つを維持し体数は 1〜4 体）・4 観点の名称列挙・型別の概算コスト実測値 1 行・1 体兼務適用時の記録義務の文。**配置先は新設する本文節「観点と初回フル巡の体数」**とする（提示規則 2-2 の「提示への明示」が直接指す位置に正本を置き、完了条件 (2) を満たすため。提示規則の小節番号体系〈1 / 2 / 2-2 / 3 / 3-2〉を増やさず、`review-procedure.md` 手順 1 と `iteration-norms.md` フル巡定義の双方から一意に指せる）。

明示列挙のない節（いつ使うか・レビューの狙い・対応する原則）は本文残留。

**明示列挙を超えて本文へ残す 1 文（宣言）**: 現「手順」1 の末尾にある「1 体兼務は初回の体数既定であって巡数を約束しない（写像 plan を 3 体分離で 2 巡・指摘 31 件を要した対抗実測がある。Issue-0107）」は ADR-0121 決定 5 の明示列挙 6 要素に含まれないが、**本文へ残す**。理由: これを references 側だけに置くと、本文の概算コスト 1 行（「約 1/3」）が支持実測のみを示す片側提示になり、本スキル自身の提示規則 3-2（反対材料の併記）と逆行するため。列挙との差分を明示するためにここへ宣言する。

`skills/` 配下は配布対象ソースであり、記法規約（R1〜R5）が適用される。新規に書く導入文・ポインタ行には出所識別子を持ち込まないか、持ち込む場合は全角括弧に識別子だけを入れる。

**跨り残存の同期対象**（ADR-0121 決定 5 が実装計画への列挙を課す項目。分割後もファイルを跨いで同じ内容が残るため、変更時は次の全箇所を同時に直す）:

1. **4 観点の名称列挙**（正本は SKILL.md「観点と初回フル巡の体数」）— 跨り残存 3 箇所: (i) `SKILL.md` の frontmatter `description` (ii) `references/review-procedure.md` 手順 1 の観点定義（定義に必要な最小限として残す） (iii) `references/iteration-norms.md`「反復の実施」のフル巡定義の括弧内
2. **1 体兼務の概算コスト実測値「観点分離の実測比で約 1/3」**（正本は SKILL.md「観点と初回フル巡の体数」の概算コスト 1 行）— 跨り残存 1 箇所: `references/iteration-norms.md`「体数・反復の適用例」の初回体数の判断材料
3. **体数の縮小範囲「1〜4 体」**（正本は SKILL.md「観点と初回フル巡の体数」の前提文）— 跨り残存 1 箇所: `references/iteration-norms.md`「反復の実施」のフル巡定義にある「担当を兼務させて体数のみ 1〜4 体へ縮小してよい」（現行 SKILL.md の L112 と L123 の双方に同じ数値規範があり、前者は本文へカーブアウト、後者は無改変で移設されるため分割後に跨る。ADR-0121 決定 5 が跨りの残存を受容しているので解消はせず、同期対象として記録する）

**移設側に残す無修飾参照の許容判断**: `references/iteration-norms.md` の改訂前退避の段落に残る「設計文書兼用 ADR（spec 確定点 (c) の型）」は、提示規則 1. の確定点表の**値**を使っているだけで節を名指ししていないため、ADR-0121 決定 5 (b) の張り替え対象に数えず現状のまま移す（判断を明記する。将来 (a)〜(c) の型名を変える場合はこの箇所も同期対象になる）。

- [ ] **Step 5-1: 分割前の内部参照を控える（張り替えの母数確認）**

```bash
grep -nE "下記「|上記「" skills/pre-finalization-review/SKILL.md | cut -c1-60
```

Expected: L16 / L17 / L42 / L51 / L54 / L65 / L76 / L82 / L98 / L111 / L116 / L117 / L121 / L125 / L127 / L158 の **16 行**（L51 は 1 行に 2 参照）。**L112 はここに現れない** — 同行の「反復の実施」節への参照 2 出現は「下記／上記」の接頭辞を持たないためパターン外だが、L112 全体は Step 5-10 の新設節へカーブアウトされ、そこで references パス表記へ書き換えられる（漏れではない）

- [ ] **Step 5-2: `references/iteration-norms.md` を新規作成**

現行 SKILL.md の L74〜L103（`**4. 指摘反映後の反復（ADR-0107）**` から実質収束の第 2 経路の段落まで）と L119〜L137（`## 反復の実施（ADR-0107）` から体数・反復の適用例の最終箇条まで）を移す。見出しは H2 へ昇格し、「4.」の番号接頭辞は落とす（外部参照は既に「指摘反映後の反復」の形で呼んでおり、番号の二重管理を避ける）。

移設に伴う書き換えは以下の 5 箇所のみ。それ以外は無改変で移す（1・2・4・5 はいずれも移設側から**本文残留部**を名指しする記述で、ADR-0121 決定 5 (b) が書き換えを必須としている）。

1. `**通算巡数の分布外検知（ADR-0120）**` の段落内、**1 つ目**の `（型は提示規則 2-2。迷い既定の適用時は通常型の値）` → `（型は SKILL.md 提示規則 2-2。迷い既定の適用時は通常型の値）`
2. **同じ段落の 2 つ目**の `先に型の再判定または迷い既定（提示規則 2-2）を適用し` → `先に型の再判定または迷い既定（SKILL.md 提示規則 2-2）を適用し`（現行 SKILL.md の L92 は 1 行に「提示規則 2-2」を 2 出現含む。1 だけでは同一行内で表記が割れる）
3. `- **フル巡**:` の箇条内 `初回フル巡の体数の型別既定は手順 1 が定める）` → `初回フル巡の体数の型別既定は SKILL.md「観点と初回フル巡の体数」が定める）`
4. 指摘の重大度の段落内 `反復提示にも 3-2（推奨の由来の明示・反対材料欄の常設）を準用する` → `反復提示にも SKILL.md 提示規則 3-2（推奨の由来の明示・反対材料欄の常設）を準用する`（現行 SKILL.md の L90。3-2 は本文へ残るため分割後はファイル跨ぎ参照になる）
5. `- **差分確認巡**:` 以降の同一ファイル内参照（`上記「指摘反映後の反復」` / `下記「反復の実施」`）は、両節が同一ファイルへ同居するため**そのまま維持**する

ファイル冒頭は次のとおり（Issue-0111 の教訓により、導入文は発火点の説明に限り、直後の条文の書き出しと重複させない）:

```markdown
# 指摘反映後の反復と反復の実施

`pre-finalization-review` の反復規範（反復提示・推奨の向き・通算巡数の分布外検知・停止判定）と、反復の実施方式（フル巡 / 差分確認巡 / 機械検証・継続レビュアー・改訂前退避）の正本。同スキルの SKILL.md から、確定前レビューの指摘を反映した改訂が発生して反復提示を行うとき、および反復を実施するときに読まれる。

## 指摘反映後の反復（ADR-0107）

（以下、現行 SKILL.md L76〜L103 を上記の書き換え 1 を適用して転記）

## 反復の実施（ADR-0107）

（以下、現行 SKILL.md L121〜L137 を上記の書き換え 2 を適用して転記）
```

- [ ] **Step 5-3: `references/review-procedure.md` を新規作成**

現行 SKILL.md の L105〜L117（`## 手順` と手順 1〜6）を移す。ただし **L112 全体は本文へカーブアウト**するため転記しない。

書き換えは以下の 5 箇所。

1. 手順 1 の前提実在の箇条末尾 `特に疑う型は下記「適用例: 前提実在観点で特に疑う型」を参照` → `特に疑う型は \`examples-and-evidence.md\`「適用例: 前提実在観点で特に疑う型」を参照`
2. L112 を削除した位置へ、代替の 1 行を置く: `   観点は 4 つを維持する。観点数・体数の既定（初回フル巡の型別既定・写像判定の但し書き・型別の概算コスト実測値・1 体兼務時の記録義務）は SKILL.md「観点と初回フル巡の体数」が正本である。反復のフル巡での体数縮小は \`iteration-norms.md\`「反復の実施」節が定める。`
3. 手順 2 の `初回フル巡の体数の型別既定は手順 1 が、反復の実施方式による体数の縮小・レビュアーを立てない方式は「反復の実施」節が特則として定める` → `初回フル巡の体数の型別既定は SKILL.md「観点と初回フル巡の体数」が、反復の実施方式による体数の縮小・レビュアーを立てない方式は \`iteration-norms.md\`「反復の実施」節が特則として定める`
4. 手順 5 の `上記「指摘反映後の反復」参照` → `\`iteration-norms.md\`「指摘反映後の反復」参照`
5. 手順 6 の `「反復の実施」節の改訂前退避の規定に従う` → `\`iteration-norms.md\`「反復の実施」節の改訂前退避の規定に従う`、および `改訂後の再レビュー（反復）の提示は上記「指摘反映後の反復」に従う` → `改訂後の再レビュー（反復）の提示は \`iteration-norms.md\`「指摘反映後の反復」に従う`

ファイル冒頭:

```markdown
# 確定前レビューの実施手順

`pre-finalization-review` の実施操作（4 観点の独立レビューを実証つきで実行する手順）の正本。同スキルの SKILL.md から、ユーザーがレビューの実施を指示したときに読まれる。発動主体の規範と観点・初回体数の既定は SKILL.md 側が正本である。

## 手順

（以下、現行 SKILL.md L107〜L117 を上記の書き換え 1〜5 を適用して転記。L112 は本文へカーブアウトするため転記しない）
```

- [ ] **Step 5-4: `references/examples-and-evidence.md` を新規作成**

現行 SKILL.md の L150〜L177（適用例 2 節と根拠と世代）を移す。

書き換えは以下の 2 箇所。

1. 適用例 1 の末尾 `本スキルの主目標には置かない（上記「レビューの狙い」のスコープ規定のとおり）` → `本スキルの主目標には置かない（SKILL.md「レビューの狙い（スコープ）」のスコープ規定のとおり）`
2. 根拠と世代の `- 前提実在観点・手順 5 の前提検査・3-2 (b) の探索先併記の根拠:` → `- 前提実在観点・\`review-procedure.md\` 手順 5 の前提検査・SKILL.md 提示規則 3-2 (b) の探索先併記の根拠:`

ファイル冒頭:

```markdown
# 適用例と根拠

`pre-finalization-review` の適用例 2 種（観点を立てるときの手がかり。拘束的な検査項目ではない）と、本スキルの根拠・観測世代・退役規範の正本。同スキルの SKILL.md から、観点を立てるとき、および退役を判断するときに読まれる。

（以下、現行 SKILL.md L150〜L177 を上記の書き換え 1〜2 を適用して転記）
```

- [ ] **Step 5-5: SKILL.md から移設部を削除する**

削除する範囲は 3 ブロック（削除は後方から行い、行番号のずれを避ける）:

1. L150〜**L178**（`## 適用例: 独立レビューでしか捕まらなかった欠陥（ADR-0080）` から `## 対応する原則` の見出し行の直前まで。**L178 の空行まで含める** — L149 が既に区切りの空行なので、L177 までで切ると L149 と L178 が隣接して空行 2 連になる。範囲 3 の L104 と同じ理由）
2. L105〜L137（`## 手順` から `## レビューの狙い（スコープ）` の直前まで）
3. L74〜**L104**（`**4. 指摘反映後の反復（ADR-0107）**` から `## 手順` の見出し行の直前まで。**L104 は旧「4. 指摘反映後の反復」ブロックと旧「手順」ブロックの区切りの空行で、削除範囲 2 にも 3 にも入らないため、L103 までで切ると孤立して残り、Step 5-9／5-10 の挿入後に空行 3 連が生じる**）

- [ ] **Step 5-6: SKILL.md の「いつ使うか」節のポインタを張り替える**

旧（L17）:

```
- **実施操作**: 下記「手順」の 4 観点独立レビューを実行する。**発動はユーザーの指示のみ**（`start-work` を経由しない直接呼び出しでも同じ。ADR-0072）
```

新:

```
- **実施操作**: `references/review-procedure.md`「手順」の 4 観点独立レビューを実行する。**発動はユーザーの指示のみ**（`start-work` を経由しない直接呼び出しでも同じ。ADR-0072）
```

- [ ] **Step 5-7: SKILL.md へ「参照ファイル」節を新設**

`## いつ使うか` 節の直後・`## 確定点での提示（提示規則）` の直前へ挿入:

```markdown
## 参照ファイル

本スキルの正本は 4 ファイルに分かれる。読むタイミングで分けてあり、**確定点での提示（提示操作）は本ファイルだけで履行できる**。

| ファイル | 正本として持つ内容 | 読むとき |
|---|---|---|
| 本ファイル | 提示規則（確定点・推奨判定・2 型分類・差分明示・反対材料の併記）／観点と初回フル巡の体数／レビューの狙い | 確定点に到達したとき（提示操作。毎回） |
| `references/iteration-norms.md` | 指摘反映後の反復（反復提示・推奨の向き・通算巡数の分布外検知・停止判定・骨格安定）／反復の実施（方式 3 種・継続レビュアー・改訂前退避・体数と反復の適用例） | 改訂が発生して反復提示を行うとき／反復を実施するとき |
| `references/review-procedure.md` | 実施手順 1〜6（対象と観点の確定・委譲プロンプトの組み立て・実証・隔離・集約・修正と報告） | レビューを実施するとき（実施操作） |
| `references/examples-and-evidence.md` | 適用例 2 種（独立レビューでしか捕まらなかった欠陥／前提実在観点で特に疑う型）／根拠と世代・退役規範 | 観点を立てるとき（手がかり）／退役を判断するとき |
```

- [ ] **Step 5-8: SKILL.md 提示規則内の参照 5 箇所・6 出現を張り替える**

1. 提示規則 2. 但し書き（旧 L42）: `指摘反映後の反復提示は下記「4. 指摘反映後の反復」が独立に定める` → `指摘反映後の反復提示は \`references/iteration-norms.md\`「指摘反映後の反復」が独立に定める`
2. 提示規則 2-2 冒頭（旧 L51。**1 行に 2 参照**）: `型を使うのは 2 箇所: 初回フル巡の体数の既定（下記「手順」1）と、通算巡数の分布外検知の閾値（下記「4. 指摘反映後の反復」の発火条項）。` → `型を使うのは 2 箇所: 初回フル巡の体数の既定（下記「観点と初回フル巡の体数」）と、通算巡数の分布外検知の閾値（\`references/iteration-norms.md\`「指摘反映後の反復」の発火条項）。`
3. 提示規則 2-2「提示への明示」（旧 L54）: `対応する初回体数の既定（下記「手順」1）` → `対応する初回体数の既定（下記「観点と初回フル巡の体数」）`
4. 提示規則 2-2「迷い既定」（旧 L56）: `分布外検知の閾値は通常型の値（4 巡）を適用する` → `分布外検知の閾値は通常型の値を適用する（値は \`references/iteration-norms.md\`「指摘反映後の反復」の分布外検知の発火条項が定める）`（**数値直書きの解消**。ADR-0121 決定 5 が明示する張り替え）
5. 提示規則 3-2 冒頭（旧 L65）: `指摘反映後の反復提示（下記「4. 指摘反映後の反復」）では` → `指摘反映後の反復提示（\`references/iteration-norms.md\`「指摘反映後の反復」）では`
6. 提示規則 3-2 (a)（旧 L67）: `「上記の既定」は「4. 指摘反映後の反復」でフル巡側・設計骨格側へ倒すことを命じる各既定` → `「上記の既定」は \`references/iteration-norms.md\`「指摘反映後の反復」でフル巡側・設計骨格側へ倒すことを命じる各既定`

- [ ] **Step 5-9: SKILL.md 提示規則の末尾へ移設先ポインタ 1 行を置く**

提示規則節の最後（3-2 の適用範囲の段落の直後、`## 観点と初回フル巡の体数` の直前）へ:

```markdown
指摘を反映した改訂が発生したあとの反復提示・推奨の向き・通算巡数の分布外検知・停止判定は、`references/iteration-norms.md`「指摘反映後の反復」が正本である。本節は初回提示までを覆う。
```

- [ ] **Step 5-10: SKILL.md へ「観点と初回フル巡の体数」節を新設（カーブアウト）**

`## 確定点での提示（提示規則）` 節の直後・`## レビューの狙い（スコープ）` の直前へ挿入:

```markdown
## 観点と初回フル巡の体数

レビューの観点は 4 つ——**敵対的 / 実装整合性 / 仕様適合 / 前提実在**——を維持する（各観点の定義は `references/review-procedure.md`「手順」1）。体数は担当を兼務させて 1〜4 体へ縮小してよい（反復のフル巡での縮小は `references/iteration-norms.md`「反復の実施」節）。

初回フル巡の体数の既定は成果物の型（上記の提示規則 2-2）で層別する:

- **規範改定型** → 観点分離（4 観点・4 体）
- **通常型のうち、内容の大部分がレビュー済み上流からの写像である場合** → 1 体 4 観点兼務
- **それ以外の通常型** → 観点分離

写像か否かの判定に迷う場合は観点分離側へ倒す。「レビュー済み上流」は提示規則 2. 但し書きの「上流の spec がその確定時点で独立レビューを受けている場合」の概念を用い、設計文書兼用 ADR——spec 確定点 (c) の型——は spec 確定点の一型として但し書きの範囲内で扱う。

**型別の概算コスト（実測値）**: 1 体 4 観点兼務は観点分離の実測比で約 1/3 のコストで、支持実測は写像 plan 1 件（Issue-0103）に限られる。1 体兼務は初回の体数既定であって巡数を約束しない（写像 plan を 3 体分離で 2 巡・指摘 31 件を要した対抗実測がある。Issue-0107）。体数の増減の判断材料は `references/iteration-norms.md`「体数・反復の適用例」を参照する。

1 体兼務を適用した確定点では、初回体数（1 体 4 観点兼務である旨）を当該サイクルの正本（plan または課題ログ）へ 1 行残す（`review=` の記録形式は変えない。plan・課題ログのいずれも無いサイクルでは記録先が無く、当該確定点は評価可能性の帰属母数から除かれる——記録の不在を「兼務でなかった」と推定しない）。
```

- [ ] **Step 5-11: 完了条件 (1) — サイズを実測**

```bash
wc -c < skills/pre-finalization-review/SKILL.md
```

Expected: 20000 未満（見積り約 16.5KB）。超過している場合は分割対象の取りこぼしがあるため、Step 5-5 の削除範囲を再確認する

- [ ] **Step 5-12: 見出し構成と宙に浮いた参照の不在を検証**

```bash
grep -n "^## " skills/pre-finalization-review/SKILL.md
```

Expected: **6 行** — `## いつ使うか` / `## 参照ファイル` / `## 確定点での提示（提示規則）` / `## 観点と初回フル巡の体数` / `## レビューの狙い（スコープ）` / `## 対応する原則`（`## 手順`・`## 反復の実施`・`## 適用例:` 2 件・`## 根拠と世代` が消えていること）

```bash
grep -rnE "「4\. 指摘反映後の反復」" skills/
```

Expected: 0 件（番号接頭辞つきの旧呼称が残っていないこと）。**`-r` は必須** — 付けないと `grep: skills/: Is a directory` で終了コード 2 になり、走査せずに「0 件」に見える空振り検証になる（実測済み）

```bash
grep -nE "下記「手順」|上記「指摘反映後の反復」|下記「4\." skills/pre-finalization-review/SKILL.md
```

Expected: 0 件（本文から移設側への旧形式参照が残っていないこと）

```bash
grep -c "（4 巡）" skills/pre-finalization-review/SKILL.md
```

Expected: `0`（迷い既定の数値直書きが解消されていること）

```bash
for f in skills/pre-finalization-review/SKILL.md skills/pre-finalization-review/references/*.md; do echo "$(wc -c < $f) $f"; done
```

Expected: 4 ファイルが表示され、`SKILL.md` が最小でないこと自体は問題ない。references 3 ファイルの合計が約 28KB

- [ ] **Step 5-13: 記法規約に適合していることを生成器で検査**

```bash
pwsh scripts/build-dist.ps1 2>&1 | grep -E "Convention violations|Aborted|Done\."
```

Expected: `[build-dist] Convention violations: 0` と `[build-dist] Done. 25 files written to dist/, 1 to repository root.`（skills 23 ＋ plugin.json 2）。`Aborted` が出ないこと

```bash
pwsh scripts/build-dist.ps1 2>&1 | grep -c "pre-finalization-review/SKILL.md: "
```

Expected: `0`（分割により pre-finalization-review の警告が消えていること）。**末尾のコロンとスペースは必須** — 付けないと生成器が常に出す除去数の行 `  ✓ skills/pre-finalization-review/SKILL.md (N identifiers removed)` にヒットし、分割が成功していても `1` が返って検証が偽陽性で落ちる（実測済み。警告行だけが `SKILL.md: ` の形を持つ）

- [ ] **Step 5-14: 配布物の目視（記法規約の執行点 手順 4）**

生成された `dist/skills/pre-finalization-review/` 配下 4 ファイルを読み、括弧内に識別子以外の語が同居した行・半角括弧・書式例の実在の固有名・自己参照（「本リポジトリ」等）が残っていないことを確認する。

```bash
ls dist/skills/pre-finalization-review/ dist/skills/pre-finalization-review/references/
```

Expected: `SKILL.md` と references 3 ファイルが生成されていること

- [ ] **Step 5-15: コミット**

```bash
git add skills/pre-finalization-review dist .agents/plugins/marketplace.json && git commit -m "refactor: pre-finalization-review を references 型で分割（ADR-0121 決定 5。本文 20KB 以下・初回提示は本文のみで履行可）"
```

逸脱記録: 対象外 / 不採用 / 前処理 2. の突合対象である第 2 巡の不採用 1 件（新設節へ転記する対抗実測の括弧が記法規約 R1-a に該当するか）を Step 5-14 の配布物目視で検査、除去後は `（写像 plan を 3 体分離で 2 巡・指摘 31 件を要した対抗実測がある）` となり残骸も文法破綻も無く生成器の違反も 0 件のため、前巡の不採用理由が実体で覆っておらず不採用のまま維持

逸脱記録: 事実誤り・期待値の陳腐化の訂正 / 採用 / Step 12-5 の Expected「0 件」が実体と食い違う（是正の適用先は Task 12。詳細と実測根拠は同タスクの逸脱記録行）

---

### Task 6: 外部参照の張り替え（skills 3 件・現用 spec 2 件）

**Files:**
- Modify: `skills/session-handoff/SKILL.md`（2 箇所）
- Modify: `skills/decision-log/SKILL.md`（1 箇所）
- Modify: `skills/subagent-dispatch/SKILL.md`（1 箇所）
- Modify: `docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md`（3 箇所＋注記 1 行）
- Modify: `docs/current/specs/2026-08-28-start-work-responsibility-split-design.md`（注記 1 行）

ADR-0121 決定 5 の (d)。**移設対象節を名指しする参照のみ**を対象とし、本文に残った節（提示規則・確定点での提示・2 型分類）を指す参照は書き換えない。書き換え対象外であることを確認済みの参照: `skills/start-work/SKILL.md` L73 / L76 / L97、`skills/start-work/references/plan-deviation-defaults.md` L9 / L32、`skills/session-handoff/SKILL.md` L129 / L209 / L210、`skills/decision-log/SKILL.md` L121 / L226（いずれもスキル名のみ、または本文残留節を指す）。

`docs/records/` 配下・過去 handoff・close 済み課題・open 課題内の経緯記述・**`docs/working/plans/` 配下の過去サイクルの実装計画**は**書き換えない**（ADR-0121 が壊れを許容する範囲。ADR-0116 サイクルと同じ扱い）。過去計画に旧形式ポインタが残ることは確認済みで（`2026-08-18-issue-0098-adr-0107-0108-implementation.md` / `2026-08-28-start-work-responsibility-split-implementation.md` / `2026-08-29-premise-existence-review-implementation.md` / `2026-08-31-adr-0120-stratified-review-implementation.md` の 4 件）、これらは確定後不変の記録として壊れを許容する。**Step 6-7 の検証 grep は `skills/` と `docs/current/specs/` のみを走査対象にしているため、これらはヒットしない。**

- [ ] **Step 6-1: session-handoff の 2 箇所を張り替え**

`skills/session-handoff/SKILL.md`「`review=` の値定義」節（現行 L87）:

旧: `それぞれフル巡・差分確認巡〈定義は pre-finalization-review「反復の実施」節〉に対応する`
新: `それぞれフル巡・差分確認巡〈定義は pre-finalization-review の \`references/iteration-norms.md\`「反復の実施」節〉に対応する`

同節の終了状態の箇条（現行 L91）:

旧: `- \`実質収束\` — 実質収束（pre-finalization-review「指摘反映後の反復」の停止判定。いずれかの経路）の判定が真のまま確定した場合`
新: `- \`実質収束\` — 実質収束（pre-finalization-review の \`references/iteration-norms.md\`「指摘反映後の反復」の停止判定。いずれかの経路）の判定が真のまま確定した場合`

- [ ] **Step 6-2: decision-log の 1 箇所を張り替え**

`skills/decision-log/SKILL.md`「ステータス変更」節（現行 L186）:

旧: `反復・巡・終了時の定義は pre-finalization-review「指摘反映後の反復」と session-handoff「\`review=\` の値定義」節を参照`
新: `反復・巡・終了時の定義は pre-finalization-review の \`references/iteration-norms.md\`「指摘反映後の反復」と session-handoff「\`review=\` の値定義」節を参照`

- [ ] **Step 6-3: subagent-dispatch の 1 箇所を張り替え**

`skills/subagent-dispatch/SKILL.md` 手順 6（現行 L21）:

旧: `確定前レビュー経路の正本は \`pre-finalization-review\` 手順 5 で、本項はそれ以外の検査・監査・走査委譲を覆う`
新: `確定前レビュー経路の正本は \`pre-finalization-review\` の \`references/review-procedure.md\` 手順 5 で、本項はそれ以外の検査・監査・走査委譲を覆う`

- [ ] **Step 6-4: 2026-08-05 spec の 3 箇所を張り替え**

`docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md`

L67（B 群の受け取り時義務の段落）:

旧: `（ADR-0117。確定前レビュー経路の正本は pre-finalization-review 手順 5）`
新: `（ADR-0117。確定前レビュー経路の正本は pre-finalization-review の \`references/review-procedure.md\` 手順 5）`

L95（手順の骨子 6）:

旧: `改訂後の反復提示は pre-finalization-review「指摘反映後の反復」に従う（ADR-0107）`
新: `改訂後の反復提示は pre-finalization-review の \`references/iteration-norms.md\`「指摘反映後の反復」に従う（ADR-0107）`

L99（反復の実施の節。**2 参照を含む 1 行**）:

旧: `各条件は pre-finalization-review「反復の実施」節が正本）` および同行末尾 `発動・推奨・停止判定の正本は pre-finalization-review「指摘反映後の反復」。`
新: `各条件は pre-finalization-review の \`references/iteration-norms.md\`「反復の実施」節が正本）` および `発動・推奨・停止判定の正本は同ファイルの「指摘反映後の反復」。`

- [ ] **Step 6-5: 2026-08-05 spec へ分割の注記 1 行を追加**

`### 責務`（`## スキル2: \`pre-finalization-review\`` 配下、L82 の段落）の直後へ 1 行追加:

```markdown
> **注記（ADR-0121 決定 5）**: 本スキルの正本は SKILL.md と `references/` 3 ファイル（`iteration-norms.md` / `review-procedure.md` / `examples-and-evidence.md`）へ分割された。本 spec の節構成は分割前のスナップショットであり、節ごとの現在の所在は SKILL.md「参照ファイル」節が正である。
```

- [ ] **Step 6-6: 2026-08-28 spec へ部分修正注記 1 行を追加**

`docs/current/specs/2026-08-28-start-work-responsibility-split-design.md` の `### skills/pre-finalization-review/SKILL.md（提示規則を統合し、操作分化）` 節の最終箇条（`- 見込みサイズ: 約 30.6KB…` の行）の直後へ:

```markdown
- **部分修正（ADR-0121 決定 5）**: 本節が SKILL.md へ統合するとした提示規則のうち「指摘反映後の反復・停止判定・骨格安定・実質収束」は、ADR-0121 の references 型分割により `skills/pre-finalization-review/references/iteration-norms.md` へ移った。移設は正本所在の変更のみで規則内容は不変。見込みサイズの記載も分割前の値である
```

- [ ] **Step 6-7: 検証**

```bash
LANG=C.UTF-8 grep -rnF -e 'pre-finalization-review「反復の実施」' -e 'pre-finalization-review「指摘反映後の反復」' -e 'pre-finalization-review` 手順 5' -e 'pre-finalization-review 手順 5' skills/ docs/current/specs/
```

Expected: 0 件（references を経由しない旧形式の外部参照が残っていないこと）。

**検出力の確認済み事項**: **固定文字列（`-F`）で書くことが要点**。`」?` のように多バイト文字へ量指定子を付けた正規表現は、この環境（ロケール未設定の Git Bash）ではバイト単位に解釈され、**張り替え前でも 0 件を返す空振り検証**になる（実測）。上のコマンドは張り替え前の状態で対象 7 箇所（decision-log L186 / session-handoff L87・L91 / subagent-dispatch L21 / 2026-08-05 spec L67・L95・L99）を検出することを実測済みで、Task 6 の張り替え対象と一致する。`LANG=C.UTF-8` の前置は保険であり、**`-F` 版ではロケールの有無で結果が変わらないことを実測済み**（前置は無害なので残すが、検出力の根拠は `-F` 側にある）

```bash
grep -rc "references/iteration-norms.md" skills/session-handoff/SKILL.md skills/decision-log/SKILL.md
```

Expected: `skills/session-handoff/SKILL.md:2` と `skills/decision-log/SKILL.md:1`

```bash
pwsh scripts/build-dist.ps1 2>&1 | grep -E "Convention violations|Aborted"
```

Expected: `[build-dist] Convention violations: 0` のみ（`Aborted` が出ないこと）

- [ ] **Step 6-8: コミット**

```bash
git add skills docs/current/specs dist .agents/plugins/marketplace.json && git commit -m "refactor: pre-finalization-review 分割に伴う外部参照の張り替え（skills 3 件・現用 spec 2 件。ADR-0121 決定 5）"
```

---

### Task 7: ADR の部分修正注記 7 件と ADR-0116 の退役判定

**Files:**
- Modify: `docs/records/decisions/0067-pre-finalization-review-as-new-skill.md`
- Modify: `docs/records/decisions/0080-review-presentation-scaled-by-unreviewed-normative-content.md`
- Modify: `docs/records/decisions/0093-destructive-verification-dispatch-isolation-constraints.md`
- Modify: `docs/records/decisions/0107-iterative-review-recommendation-by-revision-nature.md`
- Modify: `docs/records/decisions/0108-accepted-adr-revision-status-handling.md`
- Modify: `docs/records/decisions/0117-premise-existence-viewpoint-and-premise-checks.md`
- Modify: `docs/records/decisions/0120-stratified-initial-review-bodies-and-round-outlier-detection.md`
- Modify: `docs/records/decisions/0116-relocate-start-work-domain-norms-by-ownership.md`（ADR-0116。ファイル名は spec `2026-08-28-start-work-responsibility-split-design.md` と異なるので取り違えないこと）

ADR-0121 決定 5 の (e) と決定 6。7 件は**部分修正注記 1 行のみ**とし、別途の改訂記録行は書かない（ADR-0116 サイクルの先例に揃える。ADR-0121 が改訂記録 1 行を別立てで求めているのは ADR-0116 のみである）。注記は各 ADR の `## Consequences` 節の末尾へ、トップレベル箇条として追加する。

- [ ] **Step 7-1: ADR-0067 へ注記を追加**

`## Consequences` 末尾（`- **注記（ADR-0120）**:` の行の直後）へ:

```markdown
- **部分修正（ADR-0121）**: 注記（ADR-0107）が実装先として名指しする pre-finalization-review「反復の実施」節は、ADR-0121 決定 5 の references 型分割により `skills/pre-finalization-review/references/iteration-norms.md` へ移った。観点数・体数の規定内容は不変のため、Status は Accepted のまま維持
```

- [ ] **Step 7-2: ADR-0080 へ注記を追加**

`## Consequences` 末尾（既存の部分修正注記は ADR-0107 → 0116 → 0117 → 0120 の順に並ぶ。**最後の `- **部分修正（ADR-0120）**:` の行の直後**）へ:

```markdown
- **部分修正（ADR-0121）**: 本 ADR の変更対象が名指しする pre-finalization-review の「適用例」「根拠と世代」は、ADR-0121 決定 5 の references 型分割により `skills/pre-finalization-review/references/examples-and-evidence.md` へ移った。提示規則（決定 1〜3）と「レビューの狙い」は SKILL.md 本文に残る。規則内容は不変のため、Status は Accepted のまま維持
```

- [ ] **Step 7-3: ADR-0093 へ注記を追加**

`## Consequences` 末尾（同期対象を列挙した箇条のさらに後ろにある**最終箇条「配布反映にはプラグインの version bump と `dist/` 再生成が必要」の直後**、`## 過剰適合点検（ADR-0079）` の直前）へ:

```markdown
- **部分修正（ADR-0121）**: 同期対象が名指しする `skills/pre-finalization-review/SKILL.md` 手順 4 の隔離条項は、ADR-0121 決定 5 の references 型分割により `skills/pre-finalization-review/references/review-procedure.md` 手順 4 へ移った。条項の内容は不変のため、Status は Accepted のまま維持
```

- [ ] **Step 7-4: ADR-0107 へ注記を追加**

`## Consequences` 末尾（`- **注記（ADR-0120）**:` の行の直後）へ:

```markdown
- **部分修正（ADR-0121）**: 決定 3 が正本として指定した pre-finalization-review「反復の実施」節、決定 1・2 の実装先である同スキルの「指摘反映後の反復」、および適用例の記載先は、ADR-0121 決定 5 の references 型分割によりいずれも `skills/pre-finalization-review/references/iteration-norms.md` へ移った。見出しの番号接頭辞「4.」は分割時に落としたが呼称「指摘反映後の反復」は不変であり、規則内容も不変のため、Status は Accepted のまま維持
```

- [ ] **Step 7-5: ADR-0108 へ注記を追加**

`## Consequences` 末尾（既存行の最後、`## 過剰適合点検（ADR-0079）` の直前）へ:

```markdown
- **部分修正（ADR-0121）**: 実装対象が名指しする pre-finalization-review 手順 6 のポインタは、ADR-0121 決定 5 の references 型分割により `skills/pre-finalization-review/references/review-procedure.md` 手順 6 へ移った。改訂記録規定への配線内容は不変のため、Status は Accepted のまま維持
```

- [ ] **Step 7-6: ADR-0117 へ注記を追加**

`## Consequences` 末尾（`- **射程の受容**:` を含むブロックの後、`## 過剰適合点検（ADR-0079）` の直前）へ:

```markdown
- **部分修正（ADR-0121）**: 実装対象が名指しする `skills/pre-finalization-review/SKILL.md` の記載箇所のうち、手順 1 の前提実在観点の定義と手順 5 の前提検査は `skills/pre-finalization-review/references/review-procedure.md` へ、適用例「前提実在観点で特に疑う型」は `skills/pre-finalization-review/references/examples-and-evidence.md` へ、ADR-0121 決定 5 の references 型分割により移った。frontmatter description と提示規則の記載箇所は SKILL.md 本文に残る。観点の定義・前提検査の内容は不変のため、Status は Accepted のまま維持
```

- [ ] **Step 7-7: ADR-0120 へ注記を追加**

`## Consequences` 末尾（実装対象を列挙した箇条のさらに後ろに Issue-0103 の箇条と構造的解決の箇条が続く。**最終箇条「構造的解決の検討結果: 巡数の計数は…」の直後**、`## 過剰適合点検（ADR-0079）` の直前）へ:

```markdown
- **部分修正（ADR-0121）**: 実装対象が名指しする手順 1 の体数規定は、ADR-0121 決定 5 の references 型分割により `skills/pre-finalization-review/SKILL.md` の新設節「観点と初回フル巡の体数」へ移った（初回提示が references の読み込みなしで履行できるようにするため、本文へ残す側のカーブアウトとして扱った）。決定 3 の型別既定・決定の内容はいずれも不変のため、Status は Accepted のまま維持
```

- [ ] **Step 7-8: ADR-0116 へ退役判定と改訂記録の 2 行を追加**

ADR-0121 決定 6 の実装。`## Consequences` 末尾（`- 配布対象ソースの変更であり、執行点 4 手順と plugin version bump の対象になる` の直後）へ 2 行を追加する。

```markdown
- **退役判定（ADR-0121 決定 6）**: 本 ADR の退役条件が判定契機に指定する「SKILL.md のサイズ・分割の一般規範の導入」は ADR-0121 で成立した。判定結果は**両宣言（start-work のオーケストレーション限定宣言・pre-finalization-review の管轄宣言）の存置**である。分割判断の型は CONTRIBUTING.md の共通節へ常設されたが、同規範は拡張フローを経る編集にしか届かず、編集中のファイル内で境界を読ませる宣言は代替されない。本 ADR の「包含されないまま宣言だけが残り続ける場合は存置が正」に従う
- 改訂記録（ADR-0121 の退役判定）: Consequences へ存置判定 1 行を追記・2026-08-31。Status は Accepted のまま維持
```

（日付は冒頭「逸脱判断の既定」の日付リテラルの一般規定に従って実装当日へ読み替える。ADR-0121 Consequences が示す書式そのものは変えない）

**あわせて配置判断の計数を行う**: ADR-0121 Consequences は「本サイクルの配置判断 1 件（決定 5 の本文残留／references 移設の判断）は ADR-0116 評価可能性が定める期待検出量（配置判断 1 回以上／改定サイクル）の計数対象として扱う」と定めている。**ADR-0116 の当該条項は計数先を「当該改定の ADR・handoff 消化記録」の 2 箇所と明記している**ため、両方を満たす:

- **ADR 側**: ADR-0121 Consequences の当該記述が既に担う（追加の編集は不要）
- **handoff 側**: Task 13 Step 13-9 のコミット後に `session-handoff` の update で書く消化記録行の**マイルストーン名へ「配置判断 1 件」を含める**（例: `ADR-0121 Accepted 昇格・配置判断 1 件`）。`cyclecheck=` は値の語彙が固定されているため同フィールドには入れない

- [ ] **Step 7-9: 検証**

```bash
grep -c "部分修正（ADR-0121）" docs/records/decisions/*.md | grep -v ":0"
```

Expected: 7 ファイルがそれぞれ `:1`（0067 / 0080 / 0093 / 0107 / 0108 / 0117 / 0120）

```bash
grep -n "退役判定（ADR-0121 決定 6）\|改訂記録（ADR-0121 の退役判定）" docs/records/decisions/0116-*.md
```

Expected: 2 行

```bash
grep -c "^- 改訂記録（" docs/records/decisions/0116-*.md
```

Expected: `2`（既存の実装時レビュー由来 1 行＋今回 1 行。書式は decision-log の固定書式に従い、トップレベル箇条であること）

- [ ] **Step 7-10: コミット**

```bash
git add docs/records/decisions && git commit -m "adr: 分割に伴う部分修正注記 7 件と ADR-0116 の退役判定（存置）を追記（ADR-0121 決定 5・6）"
```

---

### Task 8: Issue-0111 — merge-practice.md 導入文の絞り込み

**Files:**
- Modify: `skills/start-work/references/merge-practice.md`（L3 のみ）

ADR-0121 Consequences の同梱テーマ。修正は導入文を発火点の説明へ置換するだけで、**移設条文本体（L5 以降）は無改変を維持する**（無改変移設の検証状態を保つため）。規範内容を変えないため過剰適合点検・評価可能性の適用対象外。

- [ ] **Step 8-1: 重複を確認**

```bash
sed -n '3p;5p' skills/start-work/references/merge-practice.md
```

Expected: 両行が `feature ブランチを既定ブランチへ取り込む完了処理の実行直前に` で始まっていること

- [ ] **Step 8-2: 導入文を置換**

旧（L3）:

```
feature ブランチを既定ブランチへ取り込む完了処理の実行直前に適用する慣行判定の手順。`start-work` の完了処理の発火点（Phase 2 マッピング表・横断的ラッパー Pre 条項・セッション終了処理）から読まれる。
```

新（L3）:

```
`start-work` の完了処理の発火点（Phase 2 マッピング表・横断的ラッパー Pre 条項・セッション終了処理）から読まれる。
```

- [ ] **Step 8-3: 検証**

```bash
grep -c "^feature ブランチを既定ブランチへ取り込む完了処理の実行直前に" skills/start-work/references/merge-practice.md
```

Expected: `1`（条文本体の L5 のみ。導入文からは消えていること）

```bash
git diff --stat skills/start-work/references/merge-practice.md
```

Expected: `1 file changed, 1 insertion(+), 1 deletion(-)`（条文本体に触れていないこと）

- [ ] **Step 8-4: 生成器を実行して配布物を追従させる**

`merge-practice.md` は `skills/` 配下＝配布対象ソースであり、`dist/skills/start-work/references/merge-practice.md` が実在する。ソースだけコミットすると次の `-Check` が落ちる状態を作り込むため（CONTRIBUTING 執行点手順 1・3）、ここで再生成する。

```bash
pwsh scripts/build-dist.ps1 2>&1 | grep -E "Convention violations|Aborted|Done\."
```

Expected: `[build-dist] Convention violations: 0` と `[build-dist] Done. 25 files written to dist/, 1 to repository root.`（`Aborted` が出ないこと）

```bash
LANG=C.UTF-8 grep -c "^feature ブランチを既定ブランチへ取り込む完了処理の実行直前に" dist/skills/start-work/references/merge-practice.md
```

Expected: `1`（配布物側にも重複解消が伝播していること）

- [ ] **Step 8-5: コミット**

```bash
git add skills/start-work/references/merge-practice.md dist .agents/plugins/marketplace.json && git commit -m "fix: merge-practice.md の導入文を発火点の説明へ絞る（Issue-0111。条文本体は無改変）"
```

---

### Task 9: Issue-0099 への 1 行追記

**Files:**
- Modify: `docs/working/issues/flow/0099-overturned-5-duplicated-rows-conditional-backlog.md`

ADR-0121 Consequences が定める到達経路の作成。正式な再判定対象への編入ではなく、次回棚卸しへの到達経路のみを作る。

- [ ] **Step 9-1: 「検討状況」節へ 1 行追記**

既存の最終行（`- 2026-08-18: ADR-0107 実装で 3-2 準用の記載が…`）の直後へ:

```markdown
- 2026-08-31: ADR-0121 でサイズ実測トリガーが 4 箇所（監査クラスタ K3）から 5 箇所目（`skills/*/SKILL.md` の警告）へ増えた。条文複写を伴わない独立機構のため本 Issue の対象定義（統合を覆した二重定義 5 行）には当たらず、再判定対象への編入ではない。次回棚卸しでトリガー群を見るときの到達経路として記録する
```

- [ ] **Step 9-2: 検証**

```bash
grep -c "ADR-0121 でサイズ実測トリガーが" docs/working/issues/flow/0099-overturned-5-duplicated-rows-conditional-backlog.md && wc -c < docs/working/issues/flow/0099-overturned-5-duplicated-rows-conditional-backlog.md
```

Expected: `1` と、バイト数が 10000 未満（課題管理定義の目安値。超過していたらフォルダ昇格を提案する）。**日付部分は grep に含めない** — 冒頭の日付リテラルの一般規定により追記日は実装当日へ読み替えるため、日付込みで照合すると正しく読み替えたときに偽陰性になる

- [ ] **Step 9-3: コミット**

```bash
git add docs/working/issues/flow/0099-overturned-5-duplicated-rows-conditional-backlog.md && git commit -m "issue: 0099 へサイズ実測トリガー 5 箇所目の到達経路を追記（ADR-0121）"
```

---

### Task 10: spec 02-distribution-generator.md の追従

**Files:**
- Modify: `docs/current/specs/2026-08-07-distributed-artifact-generation/02-distribution-generator.md`

ADR-0121 Consequences が列挙する追従対象。責務・標準出力・サブ機能の 3 節に加え、既に陳腐化していた件数 3 箇所（走査対象 18 / `Done.` 20 / 配布対象ソース総計 27）を実測へ是正する。**Task 5 の分割で件数がさらに増えるため、本タスクは分割の完了後に行う。**

- [ ] **Step 10-1: 現在の実測値を確認**

```bash
echo "skills files: $(find skills -type f | wc -l)" && echo "dist files: $(find dist -type f | wc -l)" && echo "manifest entries: $(grep -vE '^\s*(#|$)' template.manifest | wc -l)"
```

Expected: `skills files: 23` / `dist files: 25` / `manifest entries: 6`。配布対象ソース総計 = 23 + 6 + 空インデックス 3 = **32**

- [ ] **Step 10-2: 「責務」節へ計測の責務を追記**

`## 責務` の段落末尾（`…Codex 向けマニフェスト 2 生成物を正本から導出する。` の直後）へ、同じ段落の続きとして追加:

```
あわせて `skills/*/SKILL.md` のサイズを実測し、目安値または例外テーブルの承認済みサイズを超えていれば警告する（非ブロック。終了コードを変えない）。
```

- [ ] **Step 10-3: 「標準出力」節の件数を是正し、警告ストリームの記載を追加**

コードブロック内の 2 行を置換する。

旧: `[build-dist] Scanning 18 source files...` → 新: `[build-dist] Scanning 23 source files...`
旧: `[build-dist] Done. 20 files written to dist/, 1 to repository root.` → 新: `[build-dist] Done. 25 files written to dist/, 1 to repository root.`

さらに、`` `✓` 行（ファイル別の除去数）は… `` で始まる段落の直後へ 1 段落追加:

```markdown
SKILL.md のサイズ警告は**標準出力ではなく警告ストリーム**（`Write-Warning`）へ出す。上記の標準出力の並びには現れず、超過が 1 件も無ければ何も出力しない。警告は走査対象の収集直後・規約判定より前に評価されるため、`Scanning` 行の近傍に現れる。1 件の超過につき 2 行（本体と、スキルディレクトリ配下の全 md 合計の参考値）を出す。
```

- [ ] **Step 10-4: 「サブ機能 / 内部構成」の走査対象の件数を是正**

旧: `配布対象ソースは計 27 ファイルで、走査は生成器ごとに分担する。`
新: `配布対象ソースは計 32 ファイルで、走査は生成器ごとに分担する。`

旧: `- \`scripts/build-dist.ps1\`（本ブロック）: \`skills/\` 配下の全ファイル（18）`
新: `- \`scripts/build-dist.ps1\`（本ブロック）: \`skills/\` 配下の全ファイル（23）`

- [ ] **Step 10-5: サブ機能へ「7. SKILL.md のサイズ計測」を追加**

`### 6. 自己検査` 節の末尾（`## このブロック固有の制約・前提` の直前）へ:

```markdown
### 7. SKILL.md のサイズ計測

走査対象の収集直後・規約判定と `-Check` 分岐より前で、`skills/*/SKILL.md`（ソース側）のバイト数を実測する。この位置に置くことで、規約違反の abort と `-Check` の早期終了より前になり、通常実行・`-Check` の両モードで同じ計測が走る。

- **目安値**: 生成器内の定数 20000 バイト（1KB = 1000 バイト）
- **例外テーブル**: 生成器内の定数表（スキル名 → 承認済みサイズ）。登録されたスキルは目安値ではなく承認済みサイズと比較する。各行には判断根拠をコメントで併記する
- **警告**: 超過時に `Write-Warning` で 2 行（超過の本体と、スキルディレクトリ配下の全 md 合計の参考値）を出す。**終了コードは変えない**。警告文には分割判断の正本（`CONTRIBUTING.md` の全シナリオ共通節）の所在を含める
- 正本 JSON 2 ファイルの不在・不正 JSON・`plugins` 0 件・version 不一致による中断はこの計測より前に起きるため、その場合は計測されない（受容）

判断規範（分割判断の型・例外テーブルの運用規律）は生成器ではなく `CONTRIBUTING.md`「全シナリオ共通: SKILL.md のサイズと分割」が正本である。生成器が持つのは分量の定義（定数・定数表）と警告の挙動のみ。
```

- [ ] **Step 10-6: 「関連 ADR」へ 1 行追加**

`## 関連 ADR` の末尾へ（出所リスト行の形式 `- <識別子>: <説明>` に従う）:

```markdown
- ADR-0121: SKILL.md の肥大は生成器のサイズ警告で検知し、例外テーブルで凝集スキルへの常時警告を避ける
```

- [ ] **Step 10-7: 検証**

```bash
grep -nE "Scanning 23 source files|Done\. 25 files|計 32 ファイル|全ファイル（23）" docs/current/specs/2026-08-07-distributed-artifact-generation/02-distribution-generator.md
```

Expected: 4 行すべてがヒットすること

```bash
grep -nE "Scanning 18|Done\. 20 files|計 27 ファイル|全ファイル（18）" docs/current/specs/2026-08-07-distributed-artifact-generation/02-distribution-generator.md
```

Expected: 0 件（陳腐化した値が残っていないこと）

- [ ] **Step 10-8: コミット**

```bash
git add docs/current/specs/2026-08-07-distributed-artifact-generation/02-distribution-generator.md && git commit -m "spec: 02-distribution-generator へサイズ計測サブ機能を追記し件数 3 箇所を実測へ是正（ADR-0121）"
```

---

### Task 11: 例外テーブル登録値の再実測とユーザー承認

**Files:**
- Modify: `scripts/build-dist.ps1`（例外テーブルの登録値。承認結果によっては無変更）

ADR-0121 決定 3・決定 5 が定める確定手順。**登録値はユーザー承認で確定する**ため、本タスクは AI が単独で完了させない。

- [ ] **Step 11-1: 全編集完了後のサイズを再実測**

```bash
for f in skills/*/SKILL.md; do echo "$(wc -c < $f) $f"; done | sort -rn | head -5
```

Expected: `session-handoff` と `decision-log` が Task 6 の張り替えにより数十バイト増えている（`session-handoff` は 2 箇所、`decision-log` は 1 箇所の参照追記）。`pre-finalization-review` は 20000 未満

- [ ] **Step 11-2: 実測値とテーブル値の差分を提示してユーザー承認を得る**

以下をユーザーへテキストで提示する（構造化質問ツールは使わない）:

- `session-handoff` / `decision-log` の再実測値と、現在の登録値（31097 / 26801）
- 判断材料: 警告の再発頻度（登録値を実測値ちょうどにすると、次の 1 バイトの追記で再警告する）と、分割着手の見込み（Issue-0115 / Issue-0116 は次サイクル以降・着手時期未定）
- 選択肢を番号付きで提示し、推奨を先頭に置いて理由を 1 行添える:
  1. **（推奨）再実測値ちょうどを登録する** — 分割待ちの行が成長して立つ警告は分割着手までの意図的な圧力として受容してよい（ADR-0121 決定 3 が明示的に許す扱い）
  2. 再実測値へ運用余裕を積む（例: +10%） — 些細な追記のたびに警告が再発するのを避けたい場合
  3. 現在の登録値（31097 / 26801）を据え置く — 実測が登録値以下なら警告は出ないため、追記があった場合はこの選択で即時に再警告が立つ

- [ ] **Step 11-3: 承認された値でテーブルを更新（据え置きの場合は変更なし）**

`scripts/build-dist.ps1` の `$skillSizeExceptions` の 2 行を承認値へ更新する。根拠コメント（`Issue-0115` / `Issue-0116`）は必ず残す。

- [ ] **Step 11-4: 警告ゼロを確認**

```bash
pwsh scripts/build-dist.ps1 2>&1 | grep -c "SKILL.md:"
```

Expected は Step 11-2 でユーザーが選んだ選択肢で分岐する:

- **選択肢 1（再実測値ちょうど）または 2（余裕を積む）を選んだ場合**: `0` — ADR-0121 Consequences が言う「導入直後の警告ゼロ」＝真陽性 2 件を分割待ちとして明示的に沈黙させた状態
- **選択肢 3（登録値を据え置く）を選んだ場合**: `2` — Task 6 の参照追記で session-handoff・decision-log が登録値を超えるため、選択肢 3 の説明どおり即時に再警告が立つ。これは想定どおりの帰結であり失敗ではない（この場合、Task 12 以降も警告が出続けることを織り込む）

なお `grep -c "SKILL.md:"` が生成器の除去数の行（`✓ … SKILL.md (N identifiers removed)`）を拾わないことは確認済み — 除去数の行はファイル名の直後が半角スペース＋括弧であり、コロンを持つのは警告行だけである。

- [ ] **Step 11-5: コミット（変更があった場合のみ）**

```bash
git add scripts/build-dist.ps1 dist .agents/plugins/marketplace.json && git commit -m "chore: 例外テーブルの登録値を全編集完了後の実測値で確定（ADR-0121 決定 3。ユーザー承認済み）"
```

逸脱記録: 対象外 / 対象外 / 登録値の確定はユーザー承認事項であり、逸脱判断の既定の対象外

---

### Task 12: version bump と執行点 4 手順

**Files:**
- Modify: `.claude-plugin/plugin.json`（`version`）
- Modify: `.claude-plugin/marketplace.json`（`plugins[].version`）
- 生成: `dist/**`、`.agents/plugins/marketplace.json`

配布対象ソース（`skills/`）を変更したため、CONTRIBUTING「全シナリオ共通: 配布対象ソースの記法規約」の執行点 4 手順と plugin version bump を 1 回で行う。Issue-0111 の同梱により bump は 1 回で済む。

`scripts/sync-template.ps1` は**実行しない**。根拠は冒頭の Tech Stack のとおり、`template.manifest` 記載 6 ファイルを変更せず、空インデックス生成対象への変更（`docs/working/issues/README.md`・`docs/records/decisions/README.md` のテーブル行）は空インデックス化で除去されるため生成結果が変わらないことによる。

**これは執行点手順 1 の字義（「空インデックス生成対象を変更したなら実行する」）に対する解釈上の判断である**ことを明記しておく。手順 1 は生成物を最新化させるための規定で、生成結果が変わらないことが確定している場合に書き込みモードの実行を省いても手順の目的は損なわれない。判断の安全網は手順 2 の `-Check`（Step 12-3）が担い、そこで差分が出たら前提が崩れているので書き込みモードで実行する。省略に不安があれば書き込みモードで実行してよい（差分ゼロのため無害）。

- [ ] **Step 12-1: version を 0.1.17 へ上げる**

`.claude-plugin/plugin.json`: `"version": "0.1.16"` → `"version": "0.1.17"`
`.claude-plugin/marketplace.json`: `"version": "0.1.16"` → `"version": "0.1.17"`

- [ ] **Step 12-2: 執行点 手順 1 — 生成器を実行**

```bash
pwsh scripts/build-dist.ps1
```

Expected: `[build-dist] Convention violations: 0` と `[build-dist] Done. 25 files written to dist/, 1 to repository root.`。version 不一致の中断が起きないこと

- [ ] **Step 12-3: 執行点 手順 2 — `-Check` で両生成器を回す**

```bash
pwsh scripts/build-dist.ps1 -Check; echo "build-dist exit=$?"
```

Expected: `[build-dist] Up to date.` と `build-dist exit=0`

```bash
pwsh scripts/sync-template.ps1 -Check; echo "sync-template exit=$?"
```

Expected: `sync-template exit=0`。`template.manifest` 記載ファイルを変更しておらず、空インデックス生成対象への変更はデータ行のみで生成結果に影響しないため一致するはず。**これが `sync-template.ps1` を書き込みモードで回さない判断の安全網**であり、落ちた場合は前提が崩れているので原因を調べること（`skills/` は template 対象外なので、`skills/` の変更が原因になることはない）

- [ ] **Step 12-4: 執行点 手順 3 — 生成物を同じコミットに含める**

- [ ] **Step 12-5: 執行点 手順 4 — 配布物を目視**

`dist/skills/pre-finalization-review/` の 4 ファイルと `dist/skills/start-work/references/merge-practice.md` を読み、記法規約「機械判定が届かない領域」の 5 型を確認する:

1. 括弧内に識別子以外の語が同居した行（除去後に `規範（の型）` のような残骸が出ていないか）
2. 半角括弧（除去後に `型()に従い` のような空括弧が残っていないか）
3. 書式例の実在の固有名（プロジェクト名・絶対パス・文書名）
4. 自己参照（「本リポジトリ」「本 repo」）
5. スクリプトの docstring・利用者へ表示するメッセージ（本サイクルでは `skills/` 配下にスクリプト変更なし）

```bash
LANG=C.UTF-8 grep -nE "（[^）]*（|）に従い|\(\)|本リポジトリ|本 repo" dist/skills/pre-finalization-review/SKILL.md dist/skills/pre-finalization-review/references/*.md dist/skills/start-work/references/merge-practice.md
```

Expected: 0 件（機械で拾える範囲の残骸がないこと）。**`LANG=C.UTF-8` の前置は必須** — 否定文字クラス `[^）]` はロケール未設定の環境でバイト単位に解釈され、検出力が大きく落ちる。実測（`skills/pre-finalization-review/SKILL.md` を対象）で **前置なし 1 件・前置あり 6 件**と差が出る。Step 6-7 の `-F` 版はロケール非依存だが、**本 Step の正規表現版は事情が異なるので混同しないこと**。**この grep は補助であり、目視での通読を省略しない** — 記法規約が挙げる 5 型のうち、書式例の実在の固有名と自己参照は grep では拾えない

- [ ] **Step 12-6: コミット**

```bash
git add .claude-plugin dist .agents/plugins/marketplace.json && git commit -m "chore: plugin version 0.1.17（ADR-0121 のサイズ警告・分割と Issue-0111 修正の配布反映）"
```

---

### Task 13: 課題 close と ADR-0121 の Accepted 昇格

**Files:**
- Modify: `docs/records/decisions/0121-skill-md-size-trigger-and-split-norm.md`（Status）
- Modify: `docs/working/issues/flow/0105-skill-md-size-growth-no-norm.md`（実測値訂正・close）
- Modify: `docs/working/issues/system/0111-merge-practice-duplicate-intro.md`（close）
- Modify: `docs/working/issues/README.md`（Status 2 件）
- Modify: `docs/records/decisions/README.md`（ADR インデックスの Status）

昇格は `decision-log` の「承認の昇格」の手順に従い、**サイクル全体整合検査を含める**。

- [ ] **Step 13-1: Issue-0105 の実測値を訂正**

`docs/working/issues/flow/0105-skill-md-size-growth-no-norm.md` の 2026-08-31 行:

旧: `- 2026-08-31: ADR-0120 実装で pre-finalization-review が 34,193B → 41,539B（+21.5%。2 型分類・分布外検知・体数型別既定ほか 8 編集）。`
新: `- 2026-08-31: ADR-0120 実装で pre-finalization-review が 34,193B → 42,643B（+24.7%。2 型分類・分布外検知・体数型別既定ほか 8 編集）。`

- [ ] **Step 13-2: Issue-0105 を close**

- ヘッダの `- **Status**: open` → `- **Status**: closed`
- ヘッダへ `- **Closed**: 2026-08-31` を `Opened` の直後へ追加
- 「検討状況」末尾へ 1 行追加:

```markdown
- 2026-08-31: ADR-0121 でサイズ・分割の一般規範を導入（build-dist のサイズ警告＋目安値 20KB＋例外テーブル、CONTRIBUTING の全シナリオ共通節、pre-finalization-review の references 型分割）。残余（session-handoff / decision-log の分割）は Issue-0115 / Issue-0116 で追跡する
```

- 「結論」を `（open）` から次へ置換:

```markdown
ADR-0121。残余の分割候補は Issue-0115 / Issue-0116 へ分離した。
```

- [ ] **Step 13-3: Issue-0111 を close**

- `- **Status**: open` → `- **Status**: closed`、`- **Closed**: 2026-08-31` を追加
- 「検討状況」末尾へ: `- 2026-08-31: ADR-0121 のサイクルへ同梱して修正（導入文を発火点の説明へ絞り込み、移設条文本体は無改変。執行点 4 手順と version bump 0.1.17 を共有）`
- 「結論」を `ADR-0121 のサイクルで同梱修正。` へ置換

- [ ] **Step 13-4: 課題インデックスの Status を更新**

`docs/working/issues/README.md` の Issue-0105 行と Issue-0111 行の `open` を `closed` へ。

- [ ] **Step 13-5: サイクル全体整合検査を実施**

`decision-log`「サイクル全体整合検査」の手順に従う。**検査観点は同スキルが定める固定 5 項目で、各観点のサブ基準（観点 4 は (a)〜(d)、観点 5 は (a)(b)）と完了基準も同スキルが定める。本計画ではそれらを再列挙しない** — 第 3 巡・第 4 巡と 2 回続けて、計画側の自前の列挙が正本のサブ基準を覆えていないと指摘されたため。**実施時は `skills/decision-log/SKILL.md` の当該節を開き、5 観点とそのサブ基準・完了基準を全項目そのまま実施すること。**

計画側が足すのは、正本が知りえない**本サイクル固有の突合材料**だけとする。

- **観点 1（仕様のスナップショット性）の対象**: Task 10 で追従させた `docs/current/specs/2026-08-07-distributed-artifact-generation/02-distribution-generator.md` と、Task 6 で注記を入れた現用 spec 2 件
- **観点 2（規範の書き戻し）の対象**: 本サイクルで新設・稼働した規範＝サイズ警告・例外テーブルの運用規律・CONTRIBUTING 新設節・分割判断の型 ①②③。あわせて過剰適合点検ブロックと評価可能性の再点検（実装で規範の文言・適用範囲を変えていないか）
- **観点 3（数値・完了基準の整合）の対象数値**: 目安値 20000 / 例外テーブルの登録値 / spec 02 の件数（走査 23・`Done.` 25・配布対象ソース総計 32）/ Issue-0105 の実測値 42,643B / 分割後の本文サイズ。二重定義の点検では、目安値 20000 を持つのは `build-dist.ps1` の定数のみで CONTRIBUTING は所在をスクリプト側と明記した参照であること、意図的に残す跨りが Task 5 preamble「跨り残存の同期対象」の 3 件のみであることを確認する
- **観点 4（経路の閉じ）の材料**: 到達経路は「通常実行と `-Check` の両モード」「目安値超過・承認済みサイズ超過・非超過の 3 分岐」「警告文から CONTRIBUTING 共通節への到達」「共通節から 5 シナリオのチェックリストへの到達」。二重発火の候補は「例外テーブルに登録されたスキルで目安値判定と承認済みサイズ判定が同時に真にならないこと」（`$limit` の上書きで一本化されている）。イベント依存の候補は「`skills/` を変更しないサイクルでは計測が一度も走らない」「正本 JSON の中断経路では計測より前に終了する」の 2 件（いずれも ADR-0121 決定 1 が明示的に受容した範囲に収まるかを見る）。値の確定順序の候補は「例外テーブルの登録値が Task 2 の暫定値でコミットされ Task 11 で確定する」「配置判断の handoff 記録が Task 13 Step 13-9 のコミット後に書かれる」の 2 件
- **観点 5（引用の整合）の突合対象**: ADR-0087（handoff のサイズトリガーとデフォルト値の型。当初案 20KB を棄却した理由が本件と前提を異にする点）・ADR-0116（分割 2 型と境界宣言の退役条件）・ADR-0040（警告型計測の先例）・ADR-0105 / ADR-0098（サイズ実測トリガー 4 箇所の共通規範化を覆した 4 理由）・Issue-0103 / Issue-0107 / Issue-0114（体数と巡数の実測）。ゲートの無条件化の点検には、ADR-0121 の過剰適合点検ブロックが引き写し箇所ごとに記載している引き継ぎ判定を実装と突合する形を使う

検査結果は handoff の消化記録へ `cyclecheck=` として残す（値の語彙は `decision-log` が正本）。

- [ ] **Step 13-6: 粒度を点検する**

`decision-log`「承認の昇格」の手順 2。**ADR-0121 のタイトルが本文の全決定に答えているか**を突合する。本 ADR は 6 決定を 1 タイトルに束ねているため、この点検は省けない。

現行タイトル: 「SKILL.md の肥大は build-dist のサイズ警告で検知し、分割判断の型と例外テーブルで制御する（ADR-0116 境界宣言は存置）」

決定との突合: 決定 1（検知＝サイズ警告）・決定 2（目安値）・決定 3（例外テーブル）・決定 4（分割判断の型）はタイトルの前半が答える。決定 6（境界宣言の存置）は括弧が答える。**決定 5（本サイクルの適用＝pre-finalization-review の分割実施と課題 2 件の起票）がタイトルで名指しされていない**ため、これを「分割判断の型」の適用事例と読めるかを判断する。読めなければ ADR の分割をユーザーへ提案してから昇格する（答えない決定を残したまま昇格しない）。

- [ ] **Step 13-7: ADR-0121 を Accepted へ昇格**

`docs/records/decisions/0121-skill-md-size-trigger-and-split-norm.md`: `- **Status**: Proposed` → `- **Status**: Accepted`

`docs/records/decisions/README.md` の ADR-0121 行の Status も更新する。

```bash
grep -n "0121" docs/records/decisions/README.md
```

Expected: 1 行がヒットし、Status 欄が Proposed であること（更新前）

- [ ] **Step 13-8: 検証**

```bash
grep -n "Status" docs/records/decisions/0121-*.md | head -1 && grep -n "Status" docs/working/issues/flow/0105-*.md docs/working/issues/system/0111-*.md | head -2
```

Expected: `Accepted` / `closed` / `closed`

```bash
grep -c "41,539B" docs/working/issues/flow/0105-*.md
```

Expected: `0`（陳腐化した実測値が残っていないこと）

```bash
for f in docs/working/issues/flow/0105-skill-md-size-growth-no-norm.md docs/working/issues/system/0111-merge-practice-duplicate-intro.md; do echo "$(wc -c < $f) $f"; done
```

Expected: 両ファイルとも 10000 未満（課題管理定義の「追記時のサイズ確認」。目安値 10KB を超えていたらフォルダ昇格を提案する）

- [ ] **Step 13-9: コミット**

```bash
git add docs/records/decisions docs/working/issues && git commit -m "adr: 0121 Accepted 昇格 - Issue-0105/0111 close・サイクル全体整合検査実施"
```

---

## 完了後の次手

1. `superpowers:verification-before-completion` で完了前検証（本計画の各 Expected を再走査）
2. `superpowers:finishing-a-development-branch` で master への取り込み（実行直前に `skills/start-work/references/merge-practice.md` を読む。ADR-0119 の Pre 条項）
3. マージ後に `retrospective` を起動（AGENTS.md の検証節が課す）

## 自己レビュー結果

**1. spec（ADR-0121）カバレッジ**

| ADR-0121 の記述 | 対応タスク |
|---|---|
| 決定 1（検知: build-dist へ計測組み込み・非ブロック警告・配置位置・警告文のポインタ・総量の参考値併記） | Task 2 |
| 決定 2（目安値 20KB） | Task 2 Step 2-2 の `$skillSizeThreshold` |
| 決定 3（例外テーブル・根拠コメント必須・ユーザー承認・引き上げ規律） | Task 2（機構）／ Task 11（登録値の確定）／ Task 3（運用規律の常設） |
| 決定 4（CONTRIBUTING 全シナリオ共通節・①②③・チェックリスト 5 シナリオ配線・start-work は文言拡張・AGENTS.md 更新シナリオは非配線） | Task 3・4 |
| 決定 5（pre-finalization-review の references 型分割・本文 20KB 以下・初回提示は本文のみ・(a)〜(e) 全数走査・数値直書きの解消・課題 2 件起票と暫定登録・Issue-0105 close と残余分離） | Task 5・6・7・1・11・13 |
| 決定 5（跨り残存を変更時の同期対象として実装計画に列挙する） | Task 5 preamble「跨り残存の同期対象」 |
| decision-log「承認の昇格」手順 2（粒度の点検） | Task 13 Step 13-6 |
| 決定 6（ADR-0116 境界宣言の存置判定） | Task 7 Step 7-8 |
| Consequences: ADR-0116 Consequences へ 2 行 | Task 7 Step 7-8 |
| Consequences: Issue-0099 へ 1 行 | Task 9 |
| Consequences: Issue-0111 の同梱と close | Task 8・13 |
| Consequences: spec 02 の追従（責務・標準出力・サブ機能・件数 3 箇所） | Task 10 |
| Consequences: 執行点 4 手順＋bump 0.1.17 | Task 12 |
| Consequences: Issue-0105 close 時の実測値訂正 | Task 13 Step 13-1 |

**2. プレースホルダ走査**: 「TBD」「後で」「適宜」「同様に」型の指示なし。移設条文は転記元の行範囲と書き換え箇所を全数明示した。Task 11 のユーザー承認は仕様上の判断保留であり、プレースホルダではない（提示内容と選択肢を確定して書いてある）。

**3. 名称の一貫性**: 新設ファイル名（`iteration-norms.md` / `review-procedure.md` / `examples-and-evidence.md`）、新設節名（`## 参照ファイル` / `## 観点と初回フル巡の体数` / `## 全シナリオ共通: SKILL.md のサイズと分割`）、変数名（`$skillSizeThreshold` / `$skillSizeExceptions` / `$skillNormRef` / `$limitLabel` / `$mdTotal`）は Task 2〜10 を通じて同一表記で統一した。移設後の節呼称は「指摘反映後の反復」（番号接頭辞「4.」を落とした形）に統一し、Task 5 Step 5-12 の grep で旧呼称の残存 0 件を検査する。

## 確定前レビューの記録

### 第 1 巡（フル巡）

plan 確定点で 4 観点・4 体の観点分離によるフルレビューを実施した（レビュアーのモデルは claude-fable-5。作成側は claude-opus-5）。指摘 22 件（Critical 0 / Major 12 / Minor 10。観点間の重複を統合した件数）を全件採用し、本計画へ反映済み。**不採用とした指摘は無いため、実装時レビューへの引き継ぎ対象の一覧も無い**（逸脱判断の既定の前処理 2. は突合対象なしとなる）。

反映の主な内訳:

- **検証コマンドの検出力欠陥 6 件**（Step 2-3 の `tail -20` が警告を切り落とす / Step 5-1 の期待値 17→16 / Step 5-12 の `-r` 欠落と見出し数の自己矛盾 / Step 5-13 の grep が除去数の行に誤ヒット / Step 6-7 の正規表現が多バイト文字の量指定子でロケール依存の空振り / Step 11-4 の期待値がユーザー選択と矛盾）。いずれも「壊れていても緑を返す」型で、レビュアーが実際にコマンドを走らせて実証した
- **張り替えの取りこぼし 3 件**（現 SKILL.md の L90 の「3-2」・L92 の 2 つ目の「提示規則 2-2」・L129 の確定点型名の扱い）
- **上流要求の欠落 3 件**（跨り残存の同期対象列挙・昇格手順の粒度の点検・課題追記後のサイズ実測）
- **執行点の抜け 2 件**（Task 8 が dist を再生成せずコミットする / Task 2 が未存在の節を指す警告文を単独コミットする）
- **前提誤り 3 件**（`sync-template` 非実行の根拠文が偽 / ADR-0116 のファイル名 / ADR 3 件の注記アンカー位置）
- **設計の縮小 1 件**: CONTRIBUTING 新設節に書いていた「移設したら参照を 5 方向について全数走査する」という一般規範を削り、ADR-0121 決定 4 が定める「正本ごと移し、移設対象節を名指しする参照を全数走査して張り替える」まで戻した。5 方向 (a)〜(e) は決定 5 が**本サイクルの実務**として定めたもので、将来の全分割へ課す決定は ADR に無い。ADR-0121 の Considered Alternatives 8（増設した機構自体が次巡の欠陥源になる棘輪を実測し、パッチ機構の規範化を撤回した設計縮小）とも逆行していた
- **陳腐化の埋め込み 1 件**（retrospective のチェックリスト項目に実測値「19.0KB」を書いていた。本サイクルが対策している陳腐化と同型のため削除）

### 第 2 巡（フル巡）

第 1 稿の改訂後、**フル巡 2 巡目を 4 観点・4 体で実施**（レビュアーのモデルは claude-sonnet-5。前巡の指摘一覧は渡さず、改訂前退避のパスのみ渡して差分は各自に取らせた）。指摘 9 件（**Critical 0 / Major 2 / Minor 7**。観点間の重複を統合した件数）。

**採用 8 件**:

- **Major 2 件**: (1) 逸脱判断の宣言欄の「引き継ぎ一覧の所在」が、`plan-deviation-defaults.md` が求める「本計画のレビューが不採用のまま残した指摘の所在」ではなく ADR の設計時 Considered Alternatives を指しており、末尾の「不採用ゼロ」の記載と矛盾していた → 2 系統に分けて書き直した。(2) 跨り残存の同期対象列挙から「体数の縮小範囲 1〜4 体」が漏れていた（現行 SKILL.md の L112 と L123 の双方にあり、分割後も跨る）→ 3 件目として追加
- **Minor 6 件**: Step 5-5 の削除範囲が区切りの空行 L104 を残し空行 3 連を生む（分割シミュレーションで実証）/ Step 6-7・12-5 の「`LANG=C.UTF-8` が必須」という根拠が `-F` 版・否定文字クラス版には当てはまらない（ロケール有無で結果が同一と実測。前巡の修正が持ち込んだ過剰一般化）/ Task 6 の除外列挙に `docs/working/plans/` の過去計画が無い / Step 4-1 の「3 箇所以上」が実測 6 箇所 / ADR-0121 Consequences の「配置判断 1 件を計数対象として扱う」がどのタスクにも無い / `sync-template` 非実行が執行点手順 1 の字義に対する解釈判断である旨が書かれていない

**不採用 1 件**: 新設節へ転記する「（写像 plan を 3 体分離で 2 巡・指摘 31 件を要した対抗実測がある。Issue-0107）」が記法規約 R1-a のパターン（括弧内に説明語と識別子が同居）にあたる、という指摘。**不採用の理由**: レビュアー自身が `strip-provenance.ps1` を dot-source して当該行を変換にかけ、除去後も文法が破綻しないことを実証しており（「規範（の型）」のような残骸は生じない）、機械判定も `ok` を返す。現行 SKILL.md の既存文の無改変転記であり本計画が新規に書いた文ではない。Step 5-14 と Step 12-5 の配布物目視工程が既に同型を覆う。指摘者も「計画を修正する必要は薄い」としている。**実装時レビューへの引き継ぎ対象**として本節に記録する（引き継ぎ先は Task 5 Step 5-14 の目視）。

第 1 稿の修正が新たな欠陥を持ち込んでいないかは 3 観点が第 1 稿との `diff`（391 行）を取って全件確認し、上記の `LANG` 根拠文 1 件を除いて「新たな矛盾なし」との判定だった。実装整合性観点は Task 5 の分割手順をスクラッチで完全にシミュレートし、分割後の SKILL.md が 17,542 バイト（完了条件の 20,000 未満）・見出し 6 行・旧呼称と数値直書きの残存 0 件になることを実測している。

### 第 3 巡（フル巡・重点指定つき）

第 2 稿の改訂後、**フル巡 3 巡目を 4 観点・4 体で実施**（レビュアーのモデルは claude-sonnet-5・新規。第 3 巡以降の適用例に従い、第 2 稿→第 3 稿の改訂 10 箇所を重点検証項目として明示し、全数走査と併用した）。指摘 8 件（**Critical 1 / Major 4 / Minor 3**。観点間の重複を統合した件数）。

**重点指定は機能した** — Critical 1・Major 3 が重点指定した改訂箇所から出ており、うち **3 件は前巡の改訂が持ち込んだ欠陥**だった。

**採用 7 件**:

- **Critical 1 件**: 逸脱判断の宣言欄が「不採用なし・引き継ぎ一覧は存在しない」と書きながら、末尾の第 2 巡の記録は「不採用 1 件を実装時レビューへの引き継ぎ対象として記録する」と書いており、同一文書内で矛盾していた。第 2 巡で宣言欄を書き直したときに、同じ巡で発生した不採用 1 件を反映し忘れたもの。実装時レビューの委譲で `plan-deviation-defaults.md` の前処理 2. が「突合対象なし」という誤った前提で進む欠陥 → 不採用 1 件の内容と引き継ぎ先を宣言欄へ明記した
- **Major 4 件**: (1) Step 12-5 の `LANG=C.UTF-8` の根拠文が実測と逆だった。**第 2 巡の指摘（「`-F` 版・否定文字クラス版とも差なし」）を検証せずに採用し、根拠を「必須」から「保険」へ弱めた私の改悪**。第 3 巡の 3 観点が独立に実測し、否定文字クラス版は前置なし 1 件・前置あり 6 件と大きく変わることを確認 → 「必須」へ戻し、`-F` 版と混同しない旨を明記。(2) 固定日付 2026-08-31 の実装日ずれ対応が Task 7 の 1 箇所にしかなく、Task 1・9・13 の 10 箇所以上が無防備だった（本日は既に 2026-09-01）→ 宣言欄へ日付リテラルの一般規定を 1 本置き、個別注記を不要にした。あわせて Step 9-2 の検証 grep が日付込みで偽陰性を生む点も直した。(3) 第 2 巡で私が足した「配置判断の計数対象扱い」の判断が、**ADR-0116 の明文（「当該改定の ADR・handoff 消化記録で計数する」）に反していた**。根拠として引いた「緩い観測」は ADR-0121 の別の評価可能性の記述で、混同していた → ADR 側と handoff 側の両方を満たす形へ訂正。(4) Task 13 Step 13-5 が `decision-log` の**固定 5 観点**（自由に増減しない）に対して自前の 3 点を書いており、観点 4「経路の閉じ」と観点 5「引用の整合」が計画上不可視だった → 5 観点すべてに本サイクルの材料を当てはめる形へ書き換えた
- **Minor 2 件**: Step 5-5 の削除範囲 1（L150〜L177）が範囲 3 と同型の空行問題（2 連）を残していた → L178 まで拡張。Task 12 Step 12-3 の `-Check` が Task 13 の編集をカバーしないのに「確認する」と書いていた → 検証の実施時点と技術的根拠を分けて記述

**不採用 1 件**: 執行点手順 1 の解釈判断が Task 12 にのみ書かれ、同種のファイルを変更する Task 1・Task 13 の各コミット時点で参照されない、という指摘。**不採用の理由**: 判断の内容は正しく（`New-EmptyIndexContent` の実装で 3 観点が検証済み）、欠けているのは「当該コミットだけを読む実装者への案内」のみ。本計画は通しで実行されるため実害が無く、各タスクへ参照を足すのは前置 1（設計縮小）が抑制しようとしている増設にあたる。**実装時レビューへの引き継ぎ対象**として本節に記録する（引き継ぎ先は Task 12 preamble の記述）。

### 第 4 巡（差分確認巡）

第 3 稿の改訂後、**差分確認巡を 1 体で実施**（claude-sonnet-5・新規レビュアー。改訂 8 ハンク・49 行の全数を退避 r3 との `diff` で機械列挙し、前巡指摘 8 件との対応表を渡した）。

**対応表の判定**: 解消済み 5 件 / 部分的 2 件 / 対象外（不採用として記録済み）1 件。**対応表の外にあった変更はゼロ**。

**新規指摘 4 件（Major 2 / Minor 2）、全件採用**:

- **Major 2 件**: (1) 日付リテラルの一般規定が対象箇所を**列挙**していたため、Issue-0115/0116 自身の検討状況の起票行が漏れ、同一ファイル内で `Opened`（読み替え後）と検討状況（据え置き）が食い違う状態が残っていた。(2) Step 13-5 の観点 4・5 が `decision-log` のサブ基準（観点 4 は (a)〜(d)、観点 5 は (a)(b)）と完了基準を覆えておらず、半分が計画上不可視のままだった
- **Minor 2 件**: いずれも**私の第 3 巡の改訂が持ち込んだもの** — Task 7 Step 7-8 に個別の日付注記が一般規定導入後も重複して残っていた（一般規定自身が「以降繰り返さない」と宣言しているのに）、および同 Step の末尾に空行 3 連が生じていた

**この巡で構造的な手当てをした**: Major 2 件はいずれも「正本にある列挙を計画側で再現しようとして取りこぼした」型で、第 3 巡の Major（固定 5 観点に対して自前の 3 点を書いた）と**同型の 3 度目**だった。そこで両方とも**再現をやめる方向**へ直した — 日付は対象箇所の列挙を捨てて「新規に書き込む日付リテラルはすべて」という規則へ置き換え（対象外の実測日だけを明示）、Step 13-5 は 5 観点とサブ基準・完了基準の再列挙をやめて `decision-log` を実施時に開く指示へ置き換え、計画側は正本が知りえない本サイクル固有の突合材料だけを持つ形にした。**本サイクルで初めて、実体を伴う設計縮小が行われた**（第 3 巡末に前置 1 が推奨した縮小は、詰めると削れるものが無く実体を欠いていた）。

コスト実測: 1 体・約 15.7 万トークン（フル巡 4 体の約 1/4）。

改訂前退避: `~/.ai-dev-review-snapshots/MakeAiInstructions/2026-08-31-adr-0121-plan/` 配下の `r1/`（第 1 稿）・`r2/`（第 2 稿）・`r3/`（第 3 稿）・`r4/`（第 4 稿）。

### 第 5 巡（差分確認巡）

第 4 稿の改訂後、**差分確認巡を実施**（claude-sonnet-5）。**新規指摘 2 件・全件採用**で、不採用は無い（実装時レビューへの引き継ぎ対象は第 2 巡・第 3 巡の 2 件のままである）。

- **`decision-log` 観点 4 のサブ基準の取りこぼし**: Step 13-5 の観点 4（経路の閉じ）の材料に**二重発火の候補が無かった** → 「例外テーブルに登録されたスキルで目安値判定と承認済みサイズ判定が同時に真にならないこと（`$limit` の上書きで一本化されている）」を追記した。第 3 巡 Major (4)・第 4 巡 Major (2) と同じ「正本にある列挙を計画側で覆えていない」型の再発で、第 4 巡の構造的手当て（再列挙をやめて正本参照へ寄せる）を適用したあとにも残っていた差分にあたる
- **空行 3 連の残存**: Task 7 Step 7-8 の末尾（Step 7-9 の直前）が空行 3 連のままだった → 1 行削除して 2 連へ是正した。第 4 巡 Minor で同一箇所を是正したが取りきれていなかった

反映後の機械検証で齟齬ゼロ・設計骨格への新規指摘なしのため**実質収束**と判定し、plan 確定点を通過した。通算 5 巡（フル巡 3・差分確認巡 2）＋機械検証 1 回。

改訂前退避: `r5/`（第 5 稿）。r1〜r5 の掃除は Issue-0106 の管轄・手動判断。

> **本節の出所（2026-09-01 追記）**: 第 5 巡の記録は確定作業の当日に本節へ書き込まれないまま計画がコミットされた（`2b4458f`）。上記は改訂前退避 `r5/` と確定稿の差分（1 挿入・2 削除）を実測して復元したものである。指摘 2 件・全件採用という件数は、確定コミット `2b4458f` のメッセージが記す通算「指摘 45 件のうち 43 件を採用」と第 1〜4 巡の記録（22 + 9 + 8 + 4 = 43 件・不採用 2 件）の差から確定した。重大度の内訳・コスト実測・対応表の判定はレビュアーの報告が残っていないため記載しない。レビュアーのモデルと巡の方式は handoff の消化記録（`review=` の `差分再確認（claude-sonnet-5・2 巡）`）による。
