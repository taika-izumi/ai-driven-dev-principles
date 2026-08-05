# subagent-dispatch / pre-finalization-review スキル authoring 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Issue-0033 / Issue-0034 のスキル本体 2 件を authoring し、`start-work` へ配線し、両 Issue を close して台帳を `skillified` へ到達させる。

**Architecture:** 新規スキル 2 件は SKILL.md 単体（テンプレート埋め込み・スクリプトなし）。`pre-finalization-review` → `subagent-dispatch` の一方向依存。配線は `start-work` の 2 箇所（Phase 2 マッピング表＋横断的ラッパー Pre）。spec は `docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md`（承認済み）、根拠 ADR は 0066/0067/0069〜0073。

**Tech Stack:** Markdown（SKILL.md）、Git、Python（台帳追記のみ。LF 契約 ADR-0064）

**注意（全タスク共通):**
- コミット前に必ず `git status --short` でステージ内容を確認する（Issue-0020）。`docs/conversation_log.md` と `docs/inbox/` の未追跡 3 件は**絶対に巻き込まない**（ユーザー手動移動予定）
- `scripts/sync-template.ps1` は**実行しない**（変更対象は `skills/` と README・issues・handoff のみで template 対象外）
- `template.manifest` には**何も追加しない**（ADR-0016）
- コミットメッセージは一時ファイル経由の `git commit -F`（Issue-0015）

---

### Task 1: `skills/subagent-dispatch/SKILL.md` を作成

**Files:**
- Create: `skills/subagent-dispatch/SKILL.md`

- [ ] **Step 1: ファイルを以下の内容で作成する**

````markdown
---
name: subagent-dispatch
description: "サブエージェントへ作業を委譲する直前に、委譲プロンプトへ入れる制約ブロックを組み立てるスキル。常時適用の A 群 4 件を無条件で含め、B 群の発火条件表 5 行を全行読み下ろして判定行を残し、該当項目のみ展開する。委譲の要否・タスク分割は扱わない。あらゆるスキル実行中のサブエージェント委譲で毎回発動する。"
---

# subagent-dispatch

サブエージェントへの委譲プロンプトに入れる制約ブロックを組み立てるスキル。「いつ委譲するか」「どう分割するか」は扱わない（`superpowers:dispatching-parallel-agents` / `superpowers:subagent-driven-development` の責務）。**委譲プロンプトに何を書くか**だけを担う。

## いつ使うか

サブエージェント（Task ツール等）へ作業を委譲する直前。タスクの型を問わず毎回。`start-work` の横断的ラッパー Pre から配線されている。

## 手順

1. **A 群 4 件を無条件で委譲プロンプトへ含める**（判断を挟まない。ADR-0066 / ADR-0070）
2. **B 群判定表の全行を読み下ろし**、判定行を委譲プロンプト冒頭へ 1 行書く（ADR-0071）
3. 判定が yes の行に紐づく項目を本文へ展開する
4. 各項目は根拠を一言添えた文で書く（根拠のない禁止は委譲先が黙って迂回する。実際、委譲先が指示に黙って従っていれば品質が下がった事例が 2 回実測されている）

### 判定行の形式

```
B群判定: 検査=yes / ミューテーション=no / 並列書き換え=no / 計画実装=no / 長時間書き込み=no
```

判定行は証跡である。判定行の無い委譲は**想起漏れ**、判定行があって内容が誤っている委譲は**判定誤り**として、事後に区別できる（ADR-0071）。

## A 群: 常時適用（4 件）

禁止と報告義務であり、委譲先の作業量を増やさない。**タスクの型を問わず無条件で含める**（ADR-0066。実測では「常時のはずの項目を判断で落とした」例があり、条件判断に委ねてはならない）。

| # | 制約 | 根拠と観測世代（ADR-0073） |
|---|---|---|
| 1 | 指示と実態が食い違ったら実態を優先し、理由を添えて報告すること | `LoopForAlpha-2026-07-22-09`（黙って従えば品質が下がる指示が 2 回）、`-2026-08-01-03` / `-2026-08-03-02`（計画の欠陥 6 件 / 4 件を実態優先の報告が検出）。世代: claude-opus-4-7〜claude-opus-5[1m] |
| 2 | 既存（pre-existing）のファイル・ディレクトリの削除は事前承認を要すること | Issue-0033 項目2。原則4（不可逆操作前の人間関与）の委譲先への伝播 |
| 3 | 本タスクの範囲外の作業（handoff 更新・ADR 作成など）はしないこと | Issue-0033 項目3。原則2（責務境界）の伝播 |
| 4 | 副エージェントを起動しないこと。起動が必要な場合は本制約一式を継承させること | Issue-0033 項目7、`LoopForAlpha#Issue-0063`（検証足場がプロセス名で子プロセスを一括停止し、作業セッションごと消失させた事故に隣接） |

## B 群: タスクの型で条件発火（5 条件）

委譲先の作業量を増やすため、該当する型のときのみ展開する（ADR-0066）。

| 発火条件 | 展開する項目 | 根拠と観測世代（ADR-0073） |
|---|---|---|
| 検査・監査・走査を委譲するとき | 検査対象は全数走査し、母数を明示すること / 実証を伴わない指摘は採用しないこと | Issue-0033 項目5/6。2026-08-05 の走査委譲（118 件全数）で有効性を実測。世代: claude-opus-5 系 |
| ミューテーション検査を委譲するとき | **（適用例）** 変異対象の実在を先に grep で確認してから指示する / 各変異行に「その変異を検出できる入力」を併記させ、書けない行は等価変異として扱う / throw を投げるだけの検査を RED 件数から除外する | `LoopForAlpha-2026-08-01-03`。**根拠 8 件全件が単一プロジェクト（LoopForAlpha）のテスト運用出所のため、拘束的規範ではなく適用例**（ADR-0073）。委譲側は例を出発点に対象プロジェクトのテスト文化へ合わせて調整する |
| 並列に委譲し、かつ委譲先がファイルを書き換えるとき | worktree または `git archive` による隔離コピーを与えること | `LoopForAlpha#Issue-0069`（同一ツリー並列でミューテーションが相互汚染し、汚染中の測定 281/1 とクリーンな木 282/0 が食い違い「回帰」と読み違える寸前だった。汚染の不在を事後に証明する手段も無い） |
| 計画に基づく実装を委譲するとき | 計画に書かれた期待値は以降のタスク増減で陳腐化するため、現在の実測値と計画の古い期待値の両方を渡すこと | `LoopForAlpha-2026-07-28-08`（10 タスク中 7 回ずれた） |
| 長時間かつ書き込みを伴う作業を委譲するとき | 複数コミットへ分割し、中断時の復旧単位を作らせること | Issue-0033 項目4 |

担保の本体は「委譲の時点で、その時点の表の**全行**を読み下ろし判定行を残すこと」であり、表の行構成そのものは worklog の実測にもとづき見直してよい（ADR-0073。条件の追加・入れ替えは新しいプロジェクト型・作業様式の観測が根拠になる）。

## 退役規範（ADR-0073）

項目に対応する同型 delta が長期にわたり中央ストアへ現れない場合、その項目は退役候補としてユーザーへ提案する。退役の判断はユーザーが行う。検出は当面手動（棚卸し時・ユーザー指示時）。機械化は Issue-0048。

## 対応する原則

- 原則2（関心の分離）: 委譲先の責務境界を制約として明示する
- 原則3（コンテキスト管理）: 委譲先が持たない全体文脈（並列状況・計画の陳腐化）を委譲側が補って渡す
- 原則4（人間の関与）: 不可逆操作の承認要求を委譲先へ伝播させる
````

- [ ] **Step 2: 読み直しで検証する（ADR-0038）**

Run: `head -3 skills/subagent-dispatch/SKILL.md`
Expected: `---` / `name: subagent-dispatch` / `description: "サブエージェントへ...` の 3 行

Run: `grep -c "B群判定:" skills/subagent-dispatch/SKILL.md`
Expected: `1`（判定行の形式ブロック）

Run: `grep -c "（適用例）" skills/subagent-dispatch/SKILL.md`
Expected: `1`（ミューテーション行のみ）

- [ ] **Step 3: コミット**

```bash
git add skills/subagent-dispatch/SKILL.md
git status --short   # 対象 1 件のみ A 表示であること・inbox/conversation_log が入っていないことを確認
git commit -F <一時ファイル>   # "skill: subagent-dispatch を新設（Issue-0033、ADR-0066/0070/0071/0073）"
```

---

### Task 2: `skills/pre-finalization-review/SKILL.md` を作成

**Files:**
- Create: `skills/pre-finalization-review/SKILL.md`

- [ ] **Step 1: ファイルを以下の内容で作成する**

````markdown
---
name: pre-finalization-review
description: "計画・仕様など非コード成果物の確定前に、実証を課した独立レビューを実施するスキル。3 観点（敵対的・実装整合性・仕様適合）を独立サブエージェントへ委譲し、成果物中のコードはスクラッチで実際に実行させる。発動はユーザーが実施を指示したときのみ。writing-plans / feature-block-design の完了後に start-work から次手として毎回提示される。"
---

# pre-finalization-review

計画（plan）・仕様（spec）・設計文書など**非コード成果物**を確定させる前に、コンテキストを持たない独立レビュアーへ委譲し、**実証を課した**レビューを実施するスキル。

自己レビューは記載内容の誤りは検出できるが、**載せる項目の選定漏れ**と**既存コードとの相互作用**は検出できない（実測: 独立レビューが Critical 5 件を検出した回で、直前の自己レビューはその全数を取り逃していた。`LoopForAlpha-2026-07-19-05`）。この構造的な限界を、独立性と実証で補う。

## いつ使うか

- **発動はユーザーの指示のみ**（ADR-0072）。規模・不可逆性による自動必須化はしない
- ただし AI 側は、`superpowers:writing-plans` / `feature-block-design` の完了後に本スキルの実施を**毎回提示する**。発動の判断はユーザーに残るが、判断の機会を作る責務は AI 側にある（ADR-0072）

## 手順

1. **対象と観点の確定**: 対象成果物（plan / spec / 設計文書）を特定し、3 観点を立てる:
   - **敵対的**: この計画・仕様が失敗するとしたらどこか。前提を崩す入力・順序・状態を探す
   - **実装整合性**: 既存コード・既存文書との矛盾はないか。参照先の実在、期待値と実測の整合
   - **仕様適合**: 上流の要求（spec / Issue / ADR）を漏れなく満たしているか。載っていない要求はないか
2. **委譲プロンプトの組み立て**: 観点ごとに独立サブエージェントへ委譲する。委譲プロンプトは `subagent-dispatch` スキルで組む（B 群「検査・監査・走査」が発火し、全数走査・母数明示・実証なし指摘の不採用が制約に入る）。**レビュアーのモデルは前工程（成果物を作った側）と変える**（Issue-0034 の根拠エントリ由来の運用ヒント）
3. **実証を課す**: 成果物中のコード（テストコード・コマンド・スクリプト）は、レビュアーに**スクラッチで写経して実際に実行させる**。「読んだ限り妥当」は成果物として受け取らない（実測: 計画中のテストコード 10 件すべてが `CommandNotFoundException` で 1 件も動かないことを、写経実行だけが検出した。`LoopForAlpha-2026-07-28-11` / `LoopForAlpha#Issue-0054`）
4. **隔離**: 観点を並列で回し、かつレビュアーが写経実行等でファイルを書き換える場合、worktree または `git archive` による隔離コピーを与える（`subagent-dispatch` B 群の該当条件）
5. **集約**: 指摘を集約する。**実証の伴わない指摘は採用しない**。採用する指摘ごとに、対象文書のどの箇所をどう直すかを決める
6. **修正と報告**: 対象文書を修正し、指摘の採否と根拠をユーザーへ報告する。確定（コミット・次工程への引き渡し）はユーザー確認後に行う

## レビューの狙い（スコープ）

狙うのは**構造的な誤り**である（ADR-0067、`LoopForAlpha#Issue-0054` の分析）:

- タスクの順序の誤り
- 新旧の契約（インターフェース・期待値）の食い違い
- 自分が足した制約が自分の検証工程を止める構造
- 境界の抜け（どのタスクも担当しない領域）

構文・スコープ・足場の配線といった**局所的・機械的な誤りは主目標に置かない**。直接実装すれば最初の実行で数分のうちに露見するため、確定前レビューで拾うより安い。

## 根拠と世代（ADR-0073）

- 根拠: Issue-0034（根拠 7 件・`corrections` 比率が全クラスタ最高＝人間が繰り返し「レビューは行われたか」を差し込んでいた型）。観測世代: claude-opus-4-8 / claude-fable-5 / claude-opus-5 の 3 世代（モデル固有の躓きではない）
- 退役規範: 同型 delta（確定後に構造的欠陥が発覚する・人間がレビュー実施を差し込む）が長期にわたり中央ストアへ現れない場合、本スキルの簡素化・退役を候補としてユーザーへ提案する。判断はユーザーが行う

## 対応する原則

- 原則2（関心の分離）: レビュアーを成果物作成者のコンテキストから独立させる
- 原則4（人間の関与）: 発動判断はユーザー。AI は判断の機会を毎回作る
- 原則5（漸進的検証）: 確定という節目の前に、実証を伴う検証を挟む
````

- [ ] **Step 2: 読み直しで検証する（ADR-0038）**

Run: `head -3 skills/pre-finalization-review/SKILL.md`
Expected: `---` / `name: pre-finalization-review` / `description: "計画・仕様など...` の 3 行

Run: `grep -c "subagent-dispatch" skills/pre-finalization-review/SKILL.md`
Expected: `2`（手順2 と手順4 の参照）

- [ ] **Step 3: コミット**

```bash
git add skills/pre-finalization-review/SKILL.md
git status --short   # 対象 1 件のみ、巻き込みなし
git commit -F <一時ファイル>   # "skill: pre-finalization-review を新設（Issue-0034、ADR-0067/0072/0073）"
```

---

### Task 3: `start-work` への配線（2 箇所）

**Files:**
- Modify: `skills/start-work/SKILL.md:76-77`（Phase 2 マッピング表の末尾行の直後）
- Modify: `skills/start-work/SKILL.md:85-86`（横断的ラッパー Pre）

- [ ] **Step 1: Phase 2 マッピング表に行を追加し、表直後に提示規範を 1 文追加する**

変更前（`skills/start-work/SKILL.md` 76〜79 行目）:

```markdown
| サブプロジェクト完了直後の振り返り | retrospective | （本リポジトリ固有スキル、フォールバック不要） |

ユーザーに次手を確認する（推奨を提示するが強制しない。ユーザーの意図優先）。
選択されたスキルへ delegate する。
```

変更後:

```markdown
| サブプロジェクト完了直後の振り返り | retrospective | （本リポジトリ固有スキル、フォールバック不要） |
| 計画・仕様など非コード成果物の確定前レビュー（ユーザー指示時） | pre-finalization-review | （本リポジトリ固有スキル、フォールバック不要） |

ユーザーに次手を確認する（推奨を提示するが強制しない。ユーザーの意図優先）。
`superpowers:writing-plans` または `feature-block-design` が完了した直後は、確定前レビュー（`pre-finalization-review`）の実施を次手の選択肢として毎回提示する（実施はユーザー判断。ADR-0072）。
選択されたスキルへ delegate する。
```

- [ ] **Step 2: 横断的ラッパー Pre に委譲時の配線を追加する**

変更前（85〜86 行目付近）:

```markdown
**Pre（実行前）:**
- 不可逆操作・大規模変更の可能性があれば `pre-action-review` スキルを呼ぶ
```

変更後:

```markdown
**Pre（実行前）:**
- 不可逆操作・大規模変更の可能性があれば `pre-action-review` スキルを呼ぶ
- サブエージェントへ作業を委譲する場合は `subagent-dispatch` スキルを呼び、委譲プロンプトの制約ブロック（A 群＋B 群判定行）を組み立てる（ADR-0066 / ADR-0071）
```

- [ ] **Step 3: 読み直しで検証する（ADR-0038）**

Run: `grep -c "pre-finalization-review" skills/start-work/SKILL.md`
Expected: `2`（マッピング表 1・提示規範 1）

Run: `grep -c "subagent-dispatch" skills/start-work/SKILL.md`
Expected: `1`（Pre ラッパー）

- [ ] **Step 4: CONTRIBUTING.md「ワークフロー起点スキル（start-work）を変更するとき」チェックリストを確認する**

- フェーズの責務分離: 変更はマッピング行追加と Pre 項目追加のみで、フェーズ構造は不変 → OK
- マッピングと superpowers スキル群の一致: 追加行は本リポジトリ固有スキルで、superpowers 側の変更なし → OK
- 横断関心の責務重複: `subagent-dispatch` は委譲プロンプト組み立てのみで、`pre-action-review`（不可逆操作レビュー）と重複しない → OK

- [ ] **Step 5: コミット**

```bash
git add skills/start-work/SKILL.md
git status --short   # 対象 1 件のみ、巻き込みなし
git commit -F <一時ファイル>   # "skill: start-work へ subagent-dispatch / pre-finalization-review を配線（ADR-0067/0070/0071/0072）"
```

---

### Task 4: README スキル一覧の更新（新規 2 件＋既存記載漏れ 3 件）

**Files:**
- Modify: `README.md:44`（スキル一覧テーブル `retrospective` 行の直後）

- [ ] **Step 1: テーブル末尾（44 行目 `retrospective` 行の直後）に 5 行を追加する**

追加する行:

```markdown
| [`subagent-dispatch`](skills/subagent-dispatch/) | サブエージェント委譲の直前に、委譲プロンプトへ入れる制約ブロック（常時 A 群 4 件＋条件発火 B 群の判定行）を組み立てる（ADR-0066/0070/0071/0073） |
| [`pre-finalization-review`](skills/pre-finalization-review/) | 計画・仕様など非コード成果物の確定前に、実証を課した 3 観点の独立レビューを実施する。発動はユーザー指示のみ（ADR-0067/0072） |
| [`worklog-record`](skills/worklog-record/) | 作業の節目とセッション切り替え直前に、AI のデフォルト挙動と実際に必要だったことの差分（delta）を中央ストアへ記録する（ADR-0044/0047/0058） |
| [`worklog-extract`](skills/worklog-extract/) | 中央ストアの作業ログをオンデマンドで走査し、スキル化・ルール化の候補をクラスタリングしてランク付き提示する（ADR-0044） |
| [`worklog-skillify`](skills/worklog-skillify/) | 採用された worklog 候補を writing-skills 委譲でスキル化する。スコープで配置先を振り分ける（ADR-0044/0046/0069） |
```

- [ ] **Step 2: 読み直しで検証する**

Run: `grep -c "skills/worklog-" README.md`
Expected: `3`

Run: `grep -c "skills/subagent-dispatch/\|skills/pre-finalization-review/" README.md`
Expected: `2`

- [ ] **Step 3: コミット**

```bash
git add README.md
git status --short   # 対象 1 件のみ、巻き込みなし
git commit -F <一時ファイル>   # "docs: README スキル一覧へ新規 2 件を追加し worklog 3 スキルの記載漏れを補完"
```

---

### Task 5: Issue-0033 / 0034 の close と台帳 `skillified` 追記

**Files:**
- Modify: `docs/working/issues/flow/0033-subagent-dispatch-prompt-boilerplate.md`（Status と結論）
- Modify: `docs/working/issues/flow/0034-independent-review-with-proof-for-non-code-artifacts.md`（Status と結論）
- Modify: `docs/working/issues/README.md`（2 行の Status）
- Modify（リポジトリ外・git 管理外）: `~/.ai-dev-worklog/processed.jsonl`

- [ ] **Step 1: Issue-0033 の Status を closed に変更し、結論を記入する**

`- **Status**: open` → `- **Status**: closed（2026-08-05）`

結論セクション `（open）` を以下へ置換:

```markdown
`skills/subagent-dispatch/` として skillified（2026-08-05）。適用条件は ADR-0066（A 群/B 群）、実装方式は ADR-0070（規範文。フック注入は Issue-0047 へ）、発火判定の担保は ADR-0071（判定表の読み下ろし＋判定行）、過剰適合の防止は ADR-0073（根拠・世代の記録と退役経路。ミューテーション 3 項目は適用例へ降格）。残課題: フック機械注入は Issue-0047、退役検出の機械化は Issue-0048。
```

- [ ] **Step 2: Issue-0034 の Status を closed に変更し、結論を記入する**

`- **Status**: open` → `- **Status**: closed（2026-08-05）`

結論セクション `（open。対策方式は ADR-0067 で確定。スキル authoring 完了時に close する）` を以下へ置換:

```markdown
`skills/pre-finalization-review/` として skillified（2026-08-05）。対策方式は ADR-0067（新規スキル＋start-work 配線）、発動条件は ADR-0072（ユーザー指示のみ・提示は毎回）、根拠・世代の記録と退役経路は ADR-0073。
```

- [ ] **Step 3: `docs/working/issues/README.md` の 0033 / 0034 行の Status を `open` → `closed` に変更する**

- [ ] **Step 4: 台帳へ skillified を追記する（Python。LF 契約 ADR-0064。`Add-Content` 禁止）**

```python
import json, os
path = os.path.expanduser("~/.ai-dev-worklog/processed.jsonl")
records = [
    {"v": 2, "id": "LoopForAlpha-2026-07-27-04", "outcome": "skillified",
     "ref": "MakeAiInstructions:skills/subagent-dispatch", "date": "2026-08-05"},
    {"v": 2, "id": "LoopForAlpha-2026-07-28-11", "outcome": "skillified",
     "ref": "MakeAiInstructions:skills/pre-finalization-review", "date": "2026-08-05"},
]
with open(path, "a", encoding="utf-8", newline="\n") as f:
    for r in records:
        f.write(json.dumps(r, ensure_ascii=False) + "\n")
# 読み直し検証
lines = open(path, encoding="utf-8").read().splitlines()
tail = [json.loads(l) for l in lines[-2:]]
assert [t["outcome"] for t in tail] == ["skillified", "skillified"]
print("ledger ok, total:", len(lines))
```

Expected: `ledger ok, total: <既存行数+2>`

- [ ] **Step 5: コミット（issues のみ。台帳はリポジトリ外なのでコミット対象外）**

```bash
git add docs/working/issues/flow/0033-subagent-dispatch-prompt-boilerplate.md docs/working/issues/flow/0034-independent-review-with-proof-for-non-code-artifacts.md docs/working/issues/README.md
git status --short   # 対象 3 件のみ、巻き込みなし
git commit -F <一時ファイル>   # "issues: 0033/0034 を close（skillified 到達。ADR-0070〜0073）"
```

---

### Task 6: 全体突合検証

**Files:** なし（読み取りのみ）

- [ ] **Step 1: spec の要求と成果物を突合する**

Run: `ls skills/subagent-dispatch/SKILL.md skills/pre-finalization-review/SKILL.md`
Expected: 両ファイルが存在

Run: `grep -c "pre-finalization-review" skills/start-work/SKILL.md`
Expected: `2`

Run: `grep -c "subagent-dispatch" skills/start-work/SKILL.md`
Expected: `1`

Run: `grep -c "skills/worklog-\|skills/subagent-dispatch/\|skills/pre-finalization-review/" README.md`
Expected: `5`

Run: `grep "subagent-dispatch\|pre-finalization" template.manifest; echo "exit=$?"`
Expected: 出力なし・`exit=1`（template.manifest に新スキルが入っていないこと。ADR-0016。grep のヒット 0 件は exit 1 が正常）

- [ ] **Step 2: スキルの availability を確認する（ADR-0055 / Issue-0044 の実地確認）**

Skill ツールの available-skills 一覧（system-reminder）に `ai-driven-dev-principles:subagent-dispatch` と `ai-driven-dev-principles:pre-finalization-review` が現れるかを確認する。本環境は marketplace が directory 参照のため即反映の可能性があるが、現れない場合はユーザーへ `/plugin marketplace update ai-driven-dev-principles` の実行を依頼する（AI からは実行不可。ADR-0055）。確認結果を Issue-0044 の検討状況へ追記する材料として handoff に記録する

- [ ] **Step 3: 未コミット・巻き込みの最終確認**

Run: `git status --short`
Expected: 未追跡は `docs/conversation_log.md` と `docs/inbox/` の 3 件のみ（ユーザー手動移動分）。ステージ済み・変更済みが残っていないこと（handoff は Task 外で update 時にコミット）
