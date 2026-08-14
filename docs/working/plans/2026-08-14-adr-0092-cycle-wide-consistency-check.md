# ADR-0092 サイクル全体整合検査 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 決定の Accepted 昇格前に AI 自身が実施する「サイクル全体整合検査」を decision-log 昇格手順へ組み込み、記録・検査・参照経路を session-handoff / start-work / CONTRIBUTING.md へ配線する（ADR-0092 の実装）。

**Architecture:** 検査の定義は `skills/decision-log/SKILL.md` に一本化し、他文書は参照のみ追加する。記録は handoff 消化記録の新フィールド `cyclecheck=`（マイルストーン名の `Accepted 昇格` ラベルで欠落検査可能にする）で行い、session-handoff の 8 箇所を連動改定する。配布対象ソースの変更のため、コミット前に執行点 4 手順（生成器→両 -Check→dist 同梱→目視）と version bump（0.1.2→0.1.3）を行う。

**Tech Stack:** Markdown（スキル文書）、PowerShell 7（検証 grep・生成器 `scripts/build-dist.ps1` / `scripts/sync-template.ps1`。起動は `pwsh`）

**設計の正本:** `docs/records/decisions/0092-cycle-wide-consistency-check-before-adr-promotion.md`（独立レビュー 2 巡済み。本計画はその写像）

**前提（全タスク共通）:**
- 作業ディレクトリはリポジトリルート（`D:\Dev\002_AiDev\MakeAiInstructions`）、既定ブランチは `master`、作業ブランチは `feature/issue-0074-0065-cycle-wide-consistency`
- 配布対象ソース（`skills/` 配下）の編集は CONTRIBUTING.md「配布対象ソースの記法規約」に従う（R1-a: 全角括弧に識別子のみ、または除去後も文が成立する「説明。ADR-NNNN」の既存慣用形 / R1-b: 全角括弧 / R3 コロン形 / R4 フェンス内に識別子を書かない / 配布先で解決できない固有参照の禁止）
- Task 1〜6 の変更は**単一コミット**で確定する（生成物 `dist/` をソースと同じコミットに含める執行点規定のため。途中コミットしない）
- コミットは**必ず pathspec 付き**（`git commit -F <msg> -- <対象ファイル列挙>`）で行う。handoff がステージ済み（`AM` 状態）のため、pathspec なしのコミットは古い handoff を巻き込む。untracked（`docs/inbox/`・`docs/conversation_log.md`）も巻き込まない
- コミットメッセージはスクラッチパッド配下に BOM 無し UTF-8 の一時ファイルとして作成し、`git commit -F <その絶対パス>` で渡す

---

### Task 1: decision-log へ検査工程を追加

**Files:**
- Modify: `skills/decision-log/SKILL.md`（「承認の昇格」節・「ステータス変更」節・新節追加の計 4 編集）

- [ ] **Step 1: 「承認の昇格」節の冒頭に適用範囲を追記し、昇格手順の第 1 ステップに検査を挿入する**

Edit 1 — 現行（アンカー）:

```
ADRは**原則 Proposed で作成する**。Accepted への昇格は、その決定が確定（議論が収束）した**チェックポイント**で行う。作成直後に即 Accepted 化しないこと。議論の途中（とくに brainstorming 中）は決定が覆りうるため、Proposed のまま据え置く。
```

置換後:

```
ADRは**原則 Proposed で作成する**。Accepted への昇格は、その決定が確定（議論が収束）した**チェックポイント**で行う。作成直後に即 Accepted 化しないこと。議論の途中（とくに brainstorming 中）は決定が覆りうるため、Proposed のまま据え置く。

**本節の手順は Status が `Accepted` へ遷移するすべての場合（見直し後の再昇格を含む）に適用する。**
```

Edit 2 — 現行（アンカー）:

```
昇格手順:

1. **粒度を点検する（ADR-0059 / ADR-0060）**: 昇格対象 ADR のタイトルが本文の全決定に答えているかを突合する。答えていない決定があれば分割を提案し、分割してから昇格する
2. 該当ADRファイルの `Status` を `Accepted` に更新する
3. `docs/records/decisions/README.md` のテーブルのステータスも更新する
4. コミットする
```

置換後:

```
昇格手順:

1. **サイクル全体整合検査を実施する（ADR-0092）**: 手順は次節「サイクル全体整合検査」に従う。検査での修正・書き戻しを終えてから次のステップへ進む
2. **粒度を点検する（ADR-0059 / ADR-0060）**: 昇格対象 ADR のタイトルが本文の全決定に答えているかを突合する。答えていない決定があれば分割を提案し、分割してから昇格する
3. 該当ADRファイルの `Status` を `Accepted` に更新する
4. `docs/records/decisions/README.md` のテーブルのステータスも更新する
5. コミットする
```

- [ ] **Step 2: 「ステータス変更」節の但し書きを改め、再昇格経路の導線を閉じる**

現行（アンカー）:

```
ただし、Proposed → Accepted への初回昇格は次の「承認の昇格」に従い、Consequences への追記は不要とする。
```

置換後:

```
ただし、Status を `Accepted` へ遷移させる場合（初回昇格・見直し後の再昇格とも）は次の「承認の昇格」の手順に従う。Consequences への追記は、初回昇格では不要とし、再昇格では変更理由を追記する。
```

- [ ] **Step 3: 「承認の昇格」節の直後に新節「サイクル全体整合検査」を追加する**

現行（アンカー。承認の昇格の末尾行）:

```
`start-work` の Phase 2 Post でも、確定した据え置きADRの昇格漏れがないか確認される。
```

置換後（アンカー行の直後に新節を追加）:

```
`start-work` の Phase 2 Post でも、確定した据え置きADRの昇格漏れがないか確認される。

### サイクル全体整合検査

タスク単位のレビューでは検出できない累積ずれ・経路不全を、昇格チェックポイントで検査する工程（ADR-0092）。「承認の昇格」の第 1 ステップとして実施する。

**発動契機**: 実装（コード・文書の実体変更）を伴う決定の Accepted 昇格時。実装前（設計承認時など）に昇格する決定では実施せず、実施済みにも数えない。実装前に昇格を済ませた決定が同一サイクルにある場合は、実装完了のチェックポイントで検査のみを実施する。

**サイクルの定義**: `start-work`「確定前レビューの提示規則」にある「本サイクル」の既存定義に従う。ここでは再定義しない。

**発動条件の判定**: サイクル期間の変更ファイルを列挙する。ブランチ作業では `git merge-base <既定ブランチ> HEAD` を分岐点とする `git diff --name-only <分岐点> HEAD`、既定ブランチでの直接作業では `git diff --name-only <前回 cycle-reset コミット>..HEAD`。いずれも `git status --porcelain` の出力（ステージ済み・未ステージ・未追跡を含む）を併合する（昇格はコミット前に走ることがあり、コミット済み差分だけでは検査対象が空になるため）。列挙に次のいずれかの変更が含まれる場合に検査必須:

- 仕様書（現在の正。標準: `docs/current/specs/` 配下）
- 規範・手順文書（`start-work`「確定前レビューの提示規則」の推奨判定が定める型。ここでは再定義しない）

含まれない場合は検査本体を実施せず、判定結果のみ記録する。

**実施主体と手段**: メインエージェント自身のインライン検査とする。対象ファイルの実体の読み直し（Read/grep 等）で行い、差分表示や過去の作業記憶で代替しない。独立サブエージェントレビューは従来どおりユーザー指示時のみとする（ADR-0072）。

**検査観点（固定 5 項目。自由に増減しない）**:

1. **仕様のスナップショット性**: サイクル中の実作業・レビュー由来の変更が上流仕様に反映されているか。突合は上流仕様側の全体読解を伴う
2. **規範の書き戻し**: サイクル中に新設・改定され稼働している規範が、仕様と決定に記載されているか
3. **数値・完了基準の整合**: 件数・期待値が正本・下位仕様・実装の間で一致しているか。該当する数値が現れる全文書を同時に読んで突合する（1 文書の差分だけでは不一致を検出できないため）
4. **経路の閉じ**: 新設・改定した規範を 1 サイクル机上実行し、(a) 全到達経路にフックがあるか、(b) 同一内容へ複数の発動条件が同時に真になり二重発火しないか、(c) 発動条件がイベント依存で特定経路のみ偽にならないか、(d) 記録の書き込み順序と値の確定順序が整合するか、を見る。完了基準: 到達経路を全列挙し、各経路の発火有無と記録タイミングを 1 行ずつ書き出す
5. **引用の条件保存**: 他文書の規範を参照・引き写した箇所で、引用元のゲート（適用条件・発動条件）を落として無条件化していないか

**重複実施の抑止**: 同一サイクルで本検査を実施済み（消化記録に `cyclecheck=` の行がある）かつ以後の差分が無い場合に限り、再実施を省略する。差分がある場合、観点 4 は差分に関わる規範のみの再検査でよいが、観点 1・2・3・5 は突合対象文書の全体を読み直す。本検査以外のレビュー（独立レビュー・最終レビュー等）は同等検査とみなさない。昇格処理そのものが生む差分（ADR の Status 更新・決定インデックスの行更新・close する課題・handoff への記録）は「以後の差分」に数えない（検査→昇格→再検査のループに停止条件を与えるため）。

**検査結果の扱い**:

- 仕様・決定の追従漏れは、その場で修正してから昇格する
- 修正が規範の文言・適用範囲に及ぶ場合、プロジェクトに規範拡張時の点検規約（過剰適合点検など）があれば、当該差分について再点検し記録を更新する
- 修正が配布物・生成物の対象ソースに及ぶ場合、プロジェクトに生成・検査の執行手順があれば、それを再実行してから確定コミットする
- 上記 2 点は、ガイドライン配信元リポジトリでは CONTRIBUTING.md の再点検規定と執行点 4 手順が該当する
- 検査で ADR へ決定を追記した場合は、後続の粒度点検で通常どおり再突合する
- 新たな設計論点は課題として起票に留め、当該サイクルで対策設計に入らない

**記録**: 実施結果を handoff の「Post ラッパー消化記録」の当該マイルストーン行へ `cyclecheck=` として併記する（行形式・命名規約は `session-handoff` スキル参照。Accepted 昇格処理を含むマイルストーンは名称に `Accepted 昇格` を含める）。検査のみを実施したマイルストーン（実装前昇格の後追い検査）の行にも書く。値は次の 4 つに限る:

- `実施（指摘なし）`
- `実施（修正: <コミットハッシュ or Issue 番号>）`
- `非該当（対象文書の変更なし）`
- `非該当（実装前昇格）`

**退役**: 退役の判断と時期はユーザーが判断し指示した時点とする。判断材料は cycle-reset で消えない残存記録（retrospective・worklog・課題・検査由来の修正コミット）に検出実績が現れていない事実とする。AI はその事実を棚卸しや retrospective の際に観測した場合、簡素化・退役を候補としてユーザーへ提案する。
```

- [ ] **Step 4: 検証**

Run: `Select-String -Path skills/decision-log/SKILL.md -Pattern "サイクル全体整合検査" | Measure-Object | Select-Object -ExpandProperty Count`
Expected: 2（昇格手順ステップ 1 の行と新節見出しの行。ステップ 1 の行内には 2 回出現するが Select-String は行単位）

Run: `Select-String -Path skills/decision-log/SKILL.md -Pattern "cyclecheck=" | Measure-Object | Select-Object -ExpandProperty Count`
Expected: 2（重複実施の抑止の行・記録の行）

Run: `Select-String -Path skills/decision-log/SKILL.md -Pattern "初回昇格・見直し後の再昇格とも"`
Expected: 1 件

Run: `Select-String -Path skills/decision-log/SKILL.md -Pattern "すべての場合（見直し後の再昇格を含む）"`
Expected: 1 件

---

### Task 2: session-handoff の記録様式を連動改定（8 箇所）

**Files:**
- Modify: `skills/session-handoff/SKILL.md`

- [ ] **Step 1: 形式行の本体へ `cyclecheck=` フィールドを追加する**

現行（アンカー）:

```
形式: `- <日付> <マイルストーン>: ADR=<番号 or なし（理由）> / worklog=<エントリ id or 棄却（理由）> / review=<フル実施（レビュアーのモデル） or 差分再確認 or 見送り or 非発火（推奨判定が偽）>`
```

置換後:

```
形式: `- <日付> <マイルストーン>: ADR=<番号 or なし（理由）> / worklog=<エントリ id or 棄却（理由）> / review=<フル実施（レビュアーのモデル） or 差分再確認 or 見送り or 非発火（推奨判定が偽）> / cyclecheck=<実施（指摘なし） or 実施（修正: <識別子>） or 非該当（理由）>`
```

- [ ] **Step 2: フィールドの記載条件と命名規約を追記する**

現行（アンカー）:

```
行が存在すること自体が update の証跡であるため、session-handoff update の項目は書かない。
```

置換後:

```
`cyclecheck=` は、Accepted 昇格処理を含むマイルストーン行と、サイクル全体整合検査のみを実施したマイルストーン行に書く（値の定義と手順は `decision-log` スキルの「サイクル全体整合検査」を参照。ADR-0092）。それ以外のマイルストーンでは省略してよい。**Accepted 昇格処理を含むマイルストーンは、名称に `Accepted 昇格` を含める**（read の欠落検査の識別用）。
行が存在すること自体が update の証跡であるため、session-handoff update の項目は書かない。
```

- [ ] **Step 3: 書式例へ 1 行追加する**

現行（アンカー）:

```
- YYYY-MM-DD <確定点のマイルストーン名>: ADR=NNNN / worklog=`<project>-YYYY-MM-DD-NN` / review=フル実施（claude-opus-5）
```

置換後:

```
- YYYY-MM-DD <確定点のマイルストーン名>: ADR=NNNN / worklog=`<project>-YYYY-MM-DD-NN` / review=フル実施（claude-opus-5）
- YYYY-MM-DD <マイルストーン名・ADR-NNNN Accepted 昇格>: ADR=NNNN / worklog=棄却（delta なし） / cyclecheck=実施（指摘なし）
```

- [ ] **Step 4: 節別の記載規範のフィールド列挙へ追加する**

現行（アンカー）:

```
| Post ラッパー消化記録の 1 行 | 現行形式の必須要素（日付・マイルストーン名（確定点ラベル含む）・`ADR=` / `worklog=` / `review=` の各フィールド・なし/棄却時の理由）は維持する。
```

置換後:

```
| Post ラッパー消化記録の 1 行 | 現行形式の必須要素（日付・マイルストーン名（確定点・`Accepted 昇格` ラベル含む）・`ADR=` / `worklog=` / `review=` / `cyclecheck=` の各フィールド・なし/棄却/非該当時の理由）は維持する。
```

- [ ] **Step 5: update 手順 8 へ記録義務を追加する**

現行（アンカー。手順 8 の末尾）:

```
1 行は 200 字以内とし、各フィールド値は「判定結果＋安定識別子＋正本への参照」に限定する（ADR-0088）。詳細は正本側へ書く
```

置換後:

```
当該マイルストーンに Accepted 昇格処理が含まれる場合（名称に `Accepted 昇格` を含める）と、サイクル全体整合検査のみを実施した場合は、検査の結果（`cyclecheck=`）も併記する（値の定義は `decision-log` スキルの「サイクル全体整合検査」を参照。ADR-0092）。1 行は 200 字以内とし、各フィールド値は「判定結果＋安定識別子＋正本への参照」に限定する（ADR-0088）。詳細は正本側へ書く
```

- [ ] **Step 6: read 手順 6 の欠落検査へ名称ラベル条件で追加する**

現行（アンカー。手順 6 の末尾）:

```
確定点（spec 確定点 / plan 確定点）を通過したマイルストーン行に `review=` が欠けている場合も、同様に未消化として報告する（ADR-0080）
```

置換後:

```
確定点（spec 確定点 / plan 確定点）を通過したマイルストーン行に `review=` が欠けている場合も、同様に未消化として報告する（ADR-0080）。名称に `Accepted 昇格` を含むマイルストーン行に `cyclecheck=` が欠けている場合も、同様に未消化として報告する（ADR-0092）
```

- [ ] **Step 7: finalize の削除例外へ `cyclecheck=` 行を追加する**

現行（アンカー。finalize 手順 4 の 2 点目）:

```
**ただし本サイクル（＝前回 cycle-reset から次の cycle-reset までの作業単位）の `review=` を含む行は、過去セッションのものでも残す**（次の確定点で判定材料として読むため。ADR-0080）
```

置換後:

```
**ただし本サイクル（＝前回 cycle-reset から次の cycle-reset までの作業単位）の `review=` または `cyclecheck=` を含む行は、過去セッションのものでも残す**（`review=` は次の確定点の判定材料、`cyclecheck=` は重複実施の抑止の判定材料として読むため。ADR-0080 / ADR-0092）
```

- [ ] **Step 8: finalize の「圧縮しないもの」保護リストへ追加する**

現行（アンカー）:

```
**圧縮しないもの**: 正本が handoff 以外にないもの（進行中タスクの状態・残り、現役の申し送り・懸念、本サイクルの確定前レビュー実施・見送りの記録＝`review=` を含む消化記録行。ADR-0080）
```

置換後:

```
**圧縮しないもの**: 正本が handoff 以外にないもの（進行中タスクの状態・残り、現役の申し送り・懸念、本サイクルの確定前レビュー実施・見送りの記録＝`review=` を含む消化記録行、本サイクルのサイクル全体整合検査の記録＝`cyclecheck=` を含む消化記録行。ADR-0080 / ADR-0092）
```

- [ ] **Step 9: 検証**

Run: `Select-String -Path skills/session-handoff/SKILL.md -Pattern "cyclecheck=" | Measure-Object | Select-Object -ExpandProperty Count`
Expected: 8（形式行・記載条件/命名規約・書式例・節別規範・update・read・finalize 削除例外・finalize 保護リストの各 1 行）

Run: `Select-String -Path skills/session-handoff/SKILL.md -Pattern "Accepted 昇格" | Measure-Object | Select-Object -ExpandProperty Count`
Expected: 5（記載条件/命名規約の行・書式例の行・節別規範の行・update の行・read の行）

---

### Task 3: start-work の昇格記述を一般化・参照明示

**Files:**
- Modify: `skills/start-work/SKILL.md`（2 箇所）

- [ ] **Step 1: Post ラッパー項目 1 の「粒度の点検」名指しを一般化する**

現行（アンカー）:

```
昇格の手順には粒度の点検が含まれる（`decision-log` の「承認の昇格」第1ステップ。ADR-0059 / ADR-0060。点検の規範は `decision-log` 側にあり、ここには重複して書かない）。
```

置換後:

```
昇格の手順にはサイクル全体整合検査・粒度の点検を含む点検工程が含まれる（点検の規範は `decision-log` の「承認の昇格」「サイクル全体整合検査」側にあり、ここには重複して書かない。ADR-0059 / ADR-0060 / ADR-0092）。
```

- [ ] **Step 2: セッション終了処理 手順 2 へ「承認の昇格」参照を明示する**

現行（アンカー）:

```
2. 未コミットの ADR ドラフトがないか確認し、関連論点が収束済みのものはコミットする（Accepted 昇格漏れ・不採用確定分の Rejected 更新漏れの確認と合わせて行う。ADR-0030 / ADR-0019 / ADR-0041）
```

置換後:

```
2. 未コミットの ADR ドラフトがないか確認し、関連論点が収束済みのものはコミットする。Accepted 昇格漏れ・不採用確定分の Rejected 更新漏れの確認と合わせて行い、昇格する場合は `decision-log` の「承認の昇格」の手順（サイクル全体整合検査を含む）に従う（ADR-0030 / ADR-0019 / ADR-0041 / ADR-0092）
```

- [ ] **Step 3: 検証**

Run: `Select-String -Path skills/start-work/SKILL.md -Pattern "サイクル全体整合検査" | Measure-Object | Select-Object -ExpandProperty Count`
Expected: 2（項目 1 の行とセッション終了処理 手順 2 の行。項目 1 の行内には 2 回出現するが行数では 1）

---

### Task 4: CONTRIBUTING.md 手順 8 へ参照明示

**Files:**
- Modify: `CONTRIBUTING.md`（「振り返りで抽出された課題に対策するとき」手順 8。配布対象ソースではないため記法規約の適用外）

- [ ] **Step 1: 編集**

現行（アンカー）:

```
8. 対策サイクル完了時（ADR の Accepted 昇格時）に、対象 issue を close する（Status を closed に変更し「結論」に ADR 番号を記載。インデックスも更新）
```

置換後:

```
8. 対策サイクル完了時（ADR の Accepted 昇格時）に、対象 issue を close する（Status を closed に変更し「結論」に ADR 番号を記載。インデックスも更新）。昇格は `decision-log` の「承認の昇格」の手順（サイクル全体整合検査を含む）に従う（ADR-0092）
```

- [ ] **Step 2: 検証**

Run: `Select-String -Path CONTRIBUTING.md -Pattern "サイクル全体整合検査"`
Expected: 1 件（手順 8）

---

### Task 5: plugin version bump（0.1.2 → 0.1.3）

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: 両ファイルの `"version": "0.1.2"` を `"version": "0.1.3"` に更新する**（各 1 箇所）

- [ ] **Step 2: 検証**

Run: `Select-String -Path .claude-plugin/plugin.json,.claude-plugin/marketplace.json -Pattern '"version": "0.1.3"' | Measure-Object | Select-Object -ExpandProperty Count`
Expected: 2

---

### Task 6: 執行点 4 手順の実施と単一コミット

**Files:**
- 生成: `dist/skills/decision-log/SKILL.md`・`dist/skills/session-handoff/SKILL.md`・`dist/skills/start-work/SKILL.md`・`dist/.claude-plugin/plugin.json`（生成器が更新）

- [ ] **Step 1: 生成器を実行する**

Run: `pwsh -File scripts/build-dist.ps1`（実行後に `$LASTEXITCODE` を確認）
Expected: 終了コード 0（規約違反があれば非ゼロ終了。違反はソースを修正して再実行）

- [ ] **Step 2: 両者を -Check で実行する（1 コマンドずつ実行し、各々の終了コードを確認する）**

Run: `pwsh -File scripts/build-dist.ps1 -Check` → `$LASTEXITCODE`
Expected: 0

Run: `pwsh -File scripts/sync-template.ps1 -Check` → `$LASTEXITCODE`
Expected: 0

- [ ] **Step 3: 配布物の目視 5 点**（括弧内の説明語同居 / 半角括弧 / 書式例の実在固有名 / 自己参照 / docstring・表示メッセージ）

`dist/skills/decision-log/SKILL.md`・`dist/skills/session-handoff/SKILL.md`・`dist/skills/start-work/SKILL.md` の変更節を通読する。とくに新節「サイクル全体整合検査」は全文を読む。
Expected: 識別子の除去後に文が壊れる箇所・空括弧・実在固有名・自己参照（「ガイドライン配信元リポジトリ」の明示形は許容）が 0 件。5 点目（docstring・表示メッセージ）は本サイクルで `.ps1` を変更しないため非該当

- [ ] **Step 4: ステージ内容を確認して単一コミット（pathspec 付き）**

Run: `git status --short`（untracked と handoff の状態を確認）

```powershell
git add skills/decision-log/SKILL.md skills/session-handoff/SKILL.md skills/start-work/SKILL.md CONTRIBUTING.md .claude-plugin/plugin.json .claude-plugin/marketplace.json dist/
git commit -F <スクラッチパッドの一時ファイル絶対パス> -- skills/decision-log/SKILL.md skills/session-handoff/SKILL.md skills/start-work/SKILL.md CONTRIBUTING.md .claude-plugin/plugin.json .claude-plugin/marketplace.json dist/
# メッセージ: "feat: ADR-0092 サイクル全体整合検査を昇格手順へ実装（plugin 0.1.3）"
```

Expected: コミット成功。`git show --stat HEAD` に handoff・inbox が含まれない。`git status --short` で skills/dist の残変更なし（handoff の `AM` は残ってよい）

---

### Task 7: サイクル全体整合検査の初回自己適用

本サイクル自身が規範文書を編集しているため、ADR-0092 の昇格前に新工程を（Task 1 で実装した手順どおり）実施する。

- [ ] **Step 1: 発動条件の判定**

Run: `git merge-base master HEAD` → 分岐点。`git diff --name-only <分岐点> HEAD` と `git status --porcelain` を併合して変更ファイルを列挙
Expected: `skills/` 配下・CONTRIBUTING.md を含む → 検査必須と判定

- [ ] **Step 2: 観点 1〜5 の検査を実施する**

対象: 本サイクルの全変更（ADR-0092・plan・skills 3 件・CONTRIBUTING.md・plugin json・handoff）。実体の読み直しで行う。
- 観点 1・2: ADR-0092 の Decision と実装（skills / CONTRIBUTING の文言）の差。ADR-0092 の「過剰適合点検（ADR-0079）」ブロックが最終文言を反映しているかの再確認を含む
- 観点 3: 「観点 5 項目」「値は次の 4 つ」「8 箇所」等の数値・列挙が ADR・plan・実装の間で一致するか
- 観点 4: 新工程の到達経路（start-work Post 項目 1 / セッション終了処理 手順 2 / decision-log ユーザー確認「確定」/ decision-log ステータス変更（再昇格）/ CONTRIBUTING 手順 8）を全列挙し、各経路の発火と `cyclecheck=` 記録タイミングを 1 行ずつ書き出す
- 観点 5: ADR-0092 → SKILL.md への写像でゲート（発動契機の実装後限定・文書型の限定・値の 4 形）が落ちていないか

Expected: 指摘 0 件、または検出した追従漏れを修正して Task 6 の執行点を再実行（修正コミットを作る。昇格処理そのものが生む差分は再検査の契機に数えない）

- [ ] **Step 3: 検査結果を記録する**

Task 8 完了時の handoff update で、当該マイルストーン行（名称に `Accepted 昇格` を含める）へ `cyclecheck=実施（指摘なし）` または `cyclecheck=実施（修正: <ハッシュ>）` を書く

---

### Task 8: ADR-0092 の Accepted 昇格と Issue close

**Files:**
- Modify: `docs/records/decisions/0092-cycle-wide-consistency-check-before-adr-promotion.md`（Status: Proposed → Accepted）
- Modify: `docs/records/decisions/README.md`（0092 の行の Status）
- Modify: `docs/working/issues/flow/0074-spec-snapshot-check-missing-before-adr-promotion.md`（Status: closed・Closed 日付。「## 結論」節を新設し ADR-0092 を記載、「検討状況」に close の 1 行を追記）
- Modify: `docs/working/issues/flow/0065-task-scoped-review-misses-cross-document-paths.md`（Status: closed・Closed 日付・既存の「## 結論」節に ADR-0092 を記載）
- Modify: `docs/working/issues/README.md`（両 Issue の Status 更新）

注: `docs/records/decisions/README.md` と `docs/working/issues/README.md` は空インデックス生成対象（配布対象ソース）だが、テンプレート出力は空版のため行の増減は出力に影響しない。`sync-template.ps1 -Check` の再実行は不要（Task 6 で実施済み）

- [ ] **Step 1: 粒度点検（昇格手順の第 2 ステップ）**: ADR-0092 のタイトルが本文の全決定に答えているか突合
- [ ] **Step 2: Status 更新**（ADR 本文と README の 2 箇所を Accepted へ）
- [ ] **Step 3: Issue 2 件を close**（Status / Closed 日付 / 結論に ADR-0092。インデックス 2 行更新）
- [ ] **Step 4: 検証**

Run: `Select-String -Path docs/records/decisions/0092-cycle-wide-consistency-check-before-adr-promotion.md -Pattern "Status..: Accepted"`
Expected: 1 件

Run: `Select-String -Path docs/records/decisions/README.md -Pattern "0092.*Accepted"`
Expected: 1 件

Run: `Select-String -Path docs/working/issues/flow/0074-spec-snapshot-check-missing-before-adr-promotion.md,docs/working/issues/flow/0065-task-scoped-review-misses-cross-document-paths.md -Pattern "Status..: closed" | Measure-Object | Select-Object -ExpandProperty Count`
Expected: 2

Run: `Select-String -Path docs/working/issues/flow/0074-spec-snapshot-check-missing-before-adr-promotion.md,docs/working/issues/flow/0065-task-scoped-review-misses-cross-document-paths.md -Pattern "ADR-0092" | Measure-Object | Select-Object -ExpandProperty Count`
Expected: 2 以上（両ファイルの結論に各 1 件以上）

- [ ] **Step 5: コミット（pathspec 付き）**

```powershell
git add docs/records/decisions/0092-cycle-wide-consistency-check-before-adr-promotion.md docs/records/decisions/README.md docs/working/issues/flow/0074-spec-snapshot-check-missing-before-adr-promotion.md docs/working/issues/flow/0065-task-scoped-review-misses-cross-document-paths.md docs/working/issues/README.md
git commit -F <スクラッチパッドの一時ファイル絶対パス> -- docs/records/decisions/0092-cycle-wide-consistency-check-before-adr-promotion.md docs/records/decisions/README.md docs/working/issues/flow/0074-spec-snapshot-check-missing-before-adr-promotion.md docs/working/issues/flow/0065-task-scoped-review-misses-cross-document-paths.md docs/working/issues/README.md
# メッセージ: "chore: ADR-0092 を Accepted へ昇格し Issue-0074/0065 を close"
```

Expected: コミット成功

---

## 完了後（計画外・通常フロー）

merge 判断・retrospective・handoff finalize は start-work のセッション終了処理・`superpowers:finishing-a-development-branch` に従う（本計画のスコープ外）。配布反映は master へのマージ後に push し、そのうえでユーザーによる `/plugin marketplace update ai-driven-dev-principles` の実行が必要（ADR-0090。push 前に update しても版差分が見えず反映されない）。
