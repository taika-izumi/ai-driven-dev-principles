# 計画逸脱判断の既定（ADR-0119）実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 確定済み計画からの逸脱判断の既定（型分類・採用基準・宣言欄・逸脱記録・検出層）を references 正本として新設し、start-work / subagent-dispatch へ配線して plugin 0.1.15 として配布可能にする。

**Architecture:** 設計の正本は ADR-0119（`docs/records/decisions/0119-plan-deviation-decision-defaults.md`。確定前レビュー実質収束済み）。実装は (1) 正本ファイル新設 (2) start-work の予防層配線（Pre 条項＋マッピング表 3 セル） (3) subagent-dispatch の注入想起ポインタ (4) version bump と執行点 4 手順、の 4 部構成。検出層は正本の規範文として実装される（コード変更なし）。

**Tech Stack:** Markdown（配布対象ソース。CONTRIBUTING「配布対象ソースの記法規約」R1〜R5 適用）/ PowerShell（生成器 `scripts/build-dist.ps1`）

## 逸脱判断の既定（宣言欄・ADR-0119 の自己適用）

- 本計画は ADR-0119 の既定どおり（正本ファイルは本計画の Task 1 で新設されるため、計画確定時点の基準は ADR-0119 Decision 1〜6 を直接参照する。plugin 0.1.15 予定版）
- 前倒し型判定（タスク別）: **Task 1〜3**（規範文書の新設・配線）= 3 条件すべて真（設計確定 = ADR-0119 実質収束済み / 成果物全文を本計画に記載 / 実行による安全網なし）→ **前倒し型（逐語厳守＋設計の変更に至ったら当該タスクをタスク別独立レビューへ格下げ）**。**Task 4〜6**（version・生成・コミット）= 実行による安全網が実在（build-dist の version 一致検査・記法規約判定・自己検査、両 -Check）するため 3 条件は部分成立 → **逐語厳守は課さず格下げ安全弁のみ維持**
- 確定前レビューからの実装時レビュー引き継ぎ一覧: **なし**（第 1〜4 巡の指摘は全件採用済み。不採用 1 件〈是正案実証義務の機構化〉は ADR-0119 の射程宣言に記録済み）

---

### Task 1: references 正本 `plan-deviation-defaults.md` の新設

**Files:**
- Create: `skills/start-work/references/plan-deviation-defaults.md`

- [ ] **Step 1-1: ファイルを以下の全文で作成する**（記法規約適合: 出所識別子は全角括弧・出所リスト行のみ。コードフェンス内はプレースホルダのみ）

````markdown
# 計画逸脱判断の既定

確定済み実装計画の実行中に、実装時レビュー（独立レビュー）または実装者検証が「計画どおりでは欠陥が残る」型の指摘を出したときの、逸脱の型分類・採用基準・記録の正本（ADR-0119）。`start-work` の横断的ラッパー Pre・Phase 2 マッピング表、および `subagent-dispatch` の手順から参照される。

## 適用対象と前処理

適用対象は、確定済み実装計画の実行中（plan 確定点の通過後）に発生した指摘・改訂。次の 2 つは対象外とする:

- 確定前レビューの反復（確定点前）。正本は `pre-finalization-review` であり、同工程内の指摘は同工程の既存記録に委ね、逸脱記録行は残さない
- 非ゼロ終了で工程を止める阻止型の検査が捕捉した事象。実装が計画・規約を満たしていない状態であり修正必須で、逸脱判断の余地がないため逸脱記録行も残さない

前処理は 2 つ:

1. 検査委譲の指摘には `subagent-dispatch` 手順 6 の前提検査を先に通す。実装者検証由来の指摘には委譲元（委譲を伴わない場合は実装を進めている本人）が同旨の前提検査を行う
2. 確定前レビューが「実装時レビューへの引き継ぎ対象」として正本に残した指摘（所在は計画の宣言欄に書く）は、型分類に入る前に当該一覧と突合する。一致した指摘は、前巡の不採用理由が実装後の実体で覆っていると実証できた場合に採否をユーザーへ提示し、それ以外は不採用のまま逸脱記録行に残す。一致・実証の判定に迷う場合は提示側へ倒す

本既定の適用対象として検討したうえで対象外と裁定した指摘も、逸脱記録行へ残す。

## 指摘の型分類と既定の扱い

委譲先は候補としての型分類を添えて報告し、確定分類は委譲元が行う。型の判定に迷う場合・複数型にまたがる場合は「設計の変更」側へ倒す。

| 型 | 定義 | 既定の扱い |
|---|---|---|
| 機械的な適応 | 計画の意図を写す先の実体（ファイル慣習・既存規約）に合わせて実現する調整。設計は不変 | 採用可。逸脱として数え、逸脱記録へ 1 行（他型との差は記録の軽さのみ） |
| 事実誤り・期待値の陳腐化の訂正 | 計画の根拠・期待値・記述が、実体または計画自身が明示した意図と食い違う場合の訂正。直す向きは自明でないため、編集前に全数列挙・実測で向きを決める | 採用可。実測根拠を添えて逸脱記録へ |
| 設計の変更 | 条件・分岐・機構・契約に触れる逸脱（訂正型であっても条件・分岐・契約に触れるものを含む） | 次節の採用基準で判定 |
| 計画の射程外の既存欠陥 | 計画が扱っていない既存の欠陥（逸脱ではなくスコープ追加） | 既定で issue 起票（逸脱記録にも 1 行。帰結は「不採用」とし第 3 欄に課題番号。統合採用時は「採用」）。次節の基準 (i) に該当し、同一領域を触るタスクが計画内にある場合に限り統合採用可 |

## 設計変更級の採用基準

- **(i) 検出資産の不在**: 当該計画とリポジトリが現に持つ検出資産のいずれにも捕捉される経路が無い型 → 採用可。検出資産とは「当該計画の完了後も、当該欠陥型を毎回検査するものとしてリポジトリに残る資産」（自動テスト・機械検査・計画内の検証手順のうち恒久化されるもの・配布物検査・後続タスクの再測）を指す。レビュー委譲は反復頻度によらず検出資産に数えない。(i) の判定には不在の根拠（走査した資産名と、それが当該欠陥型を捕捉しない理由）を採用記録の ADR または当該サイクルの正本（課題ログ等）に残し、逸脱記録行の第 3 欄にはその識別子のみを書く（実証要件。`pre-finalization-review` の前提実在観点と同水準）
- **(ii) 当該コミット（委譲実装では当該タスクの成果物）自身が持ち込んだ後退** → 採用可（逸脱というより修繕）
- 採用時の記録: 設計変更の採用は `decision-log` の強トリガー（方針の変更）で ADR 化される（発火・手順の正本は同スキル）。本既定が足すのは逸脱記録行に ADR 番号を残すことのみ
- **基準外 → 既定で不採用**。次サイクルで判断が要るものは issue 起票する（いずれの帰結でも逸脱記録へ 1 行残す）
- **基準は計画確定時に固定し、変更（拡大・縮小のいずれも）にはユーザー承認と ADR を要する**（宣言欄の実装中の変更も本要件に従う）
- 判断を求めるユーザー介入は主に「基準への当てはめに迷う場合」「ADR の確定」「宣言欄の実装中の変更」へ縮む（ほかに前処理 2. の突合提示がある）。不可逆操作・大規模変更の確認（`pre-action-review`）等の既存の確認ゲートは本既定の対象外で従来どおり適用される
- 採用した是正案自体の妥当性検証は本既定の射程外とする（実装者検証・レビュー工程の役割分担へ委ねる）

## 計画側の宣言（計画作成時）

計画に「逸脱判断の既定」欄を置く。既定どおりなら参照 1 行に plugin 版数を添える（版数はどの版の既定で判断したかの事後追跡の記録。実行中に本正本が改定された場合、改定を当該計画へ適用するかはユーザーが判断し、基準を広げる改定は前節の承認・ADR 要件に従う）。上書きが要る計画はここで基準を追加・強化し、確定前レビューからの引き継ぎ一覧の所在もここに書く。

判定 3 条件（設計が確定している・実コード全文を計画に載せられる規模・実行による安全網が無い）が**すべて揃う**前倒し型のタスクは「逐語厳守＋設計の変更に至ったら当該タスクをタスク別独立レビューへ格下げ」を既定とする。3 条件のいずれかが判定不能・部分成立のまま、タスク別独立レビューを置かない工程を採る場合は、逐語厳守は課さず格下げ安全弁のみ維持する。格下げの発火判定は確定分類（昇格後の型）で行い、機械的な適応・昇格に至らない訂正は格下げ対象外として記録して続行する。

宣言欄が無い計画（既存計画・置き忘れ）では既定どおり（現行版）として扱い、前処理 2. は引き継ぎ一覧を特定できないため非適用とし、その旨を最初の逸脱記録行に残す。

## 逸脱記録と検出層

本既定を適用した**全帰結**は、計画ファイルの当該タスク（是正を適用したタスク。指摘が生じたタスクと異なる場合は生じた側にポインタ 1 行）の最後の手順の直後へ「逸脱記録」行を 1 行残す。書式:

```
逸脱記録: <型> / <帰結> / <識別子・根拠>
```

- 行頭から `逸脱記録:` で始め、箇条マーカー・インデント・チェックボックスを前置せず、直前の行との間に空行を 1 行置く（行頭固定は計数 grep の前提）
- 型は上表の 4 型名または「対象外」、帰結は「採用 / 不採用 / 対象外」の 3 値
- 第 3 欄に識別子（課題番号・ADR 番号・実証の所在・`格下げ: 発火` または `格下げ: 不発`）と短い根拠を書く。`/` を根拠テキストに含めず、第 3 欄内の複数要素は読点（、）で区切る
- 当てはめがユーザーに覆された場合は行末へ ` / 覆し: <日付> <覆し後の帰結>` を追記する
- **行の書き込みは委譲元が行う**（委譲先は報告のみ。隔離コピー・並列委譲下で記録が実リポジトリへ届かない事故と同時編集の衝突を避けるため）。書き込みは帰結確定時に行い、当該タスクの実装時レビューを委譲する時点で既知の帰結はすべて記録済みにする（当該レビュー由来の指摘は帰結確定時に追記する）
- 計画がファイル化されない経路（インライン簡易 plan）では、`docs/working/plans/` へ宣言欄とタスク列挙を持つ最小の計画ファイルを起こすことを既定とする（記録先と計数を 1 系統に保つため）。handoff の消化記録はサイクル完了時に消えるため計数手段にしない

検出層:

- タスク別の仕様適合レビューを置く工程型では、そのレビューの委譲プロンプトの判定対象に「計画との差分が逸脱記録の列挙に限られるか」を含める（委譲元が注入する）
- 置かない工程型（前倒し型・インライン TDD）では、タスク完了時に委譲元が計画との差分（git diff 等）と逸脱記録行を突合する自己検査で代替し、タスク完了報告へ「逸脱突合: 一致」または「逸脱突合: 差分あり」の 1 行を残す。自己検査が拾えるのは記録漏れであり、型分類の甘さは拾えない——後者は覆しの観測・委譲先の候補型分類報告・タスク別仕様適合レビューを置く工程型の検出層が補完する

## 委譲プロンプトへの注入（委譲時）

実装を委譲する委譲プロンプトには次を含める:

> 機械的な適応・昇格に至らない訂正は実態優先で適用し、型分類を添えて事後報告する。設計の変更・計画の射程外の既存欠陥に該当しうる候補、および型判定に迷う候補は、自ら採否を決めず候補の型分類を添えて委譲元へ報告する（A 群 1 の実態優先は前二者〈機械的な適応・昇格に至らない訂正〉に限って適用する。報告は DONE_WITH_CONCERNS 相当の状態で返してよい）

実装時の仕様適合レビューを委譲する委譲プロンプトには、判定対象として「計画との差分が逸脱記録の列挙に限られるか」を含める。

## 発火点

1. 計画作成（writing-plans またはインライン簡易 plan）へ進む直前 — 本正本を読み、宣言欄を計画に含める
2. 実装系スキル（executing-plans / subagent-driven-development またはインライン TDD）へ delegate する直前 — 本正本を読む。適用は委譲中に発生する実装時レビュー・実装者検証の指摘受領時にも及ぶ
3. 実装・実装時レビューの委譲プロンプトを組み立てる時点 — 前節の注入項目を確認する（`subagent-dispatch` の手順から配線）

読み込みと宣言欄の確認は同一セッション内の同一発火点（計画作成 / 実装着手）につき 1 回とし、`start-work` のマッピング表経由で当該発火点を実施済みなら Pre 条項経由の再読は省略する。セッション再開時は本正本と宣言欄を読み直す。

## 根拠

- ADR-0119: 設計決定の正本（型分類・採用基準・記録・配線の根拠と実測出所）
- Issue-0110: 起票元（逸脱判断の既定不在により実装サイクルでユーザー介入が 4 回発生した実測）

## 退役条件

型「設計の変更」「計画の射程外の既存欠陥」の当てはめ直近 10 件（計画ファイルの日付昇順・同一ファイル内は行出現順）のうち 3 件以上に「覆し:」が記録された場合、本既定の改良・退役を候補としてユーザーへ提案する。不採用とした指摘が後続サイクルで課題・ADR として再浮上した件数を逆向きの判断材料に添える。判断はユーザーが行う。

## 対応する原則

- 原則1（追跡可能性）: 逸脱の全帰結を計画本体へ 1 行で記録する
- 原則4（人間の関与）: 設計変更級の採否と基準の変更をユーザー承認・ADR に紐づける
- 原則5（漸進的検証）: 検出層がタスク単位で逸脱記録の網羅を検査する
````

- [ ] **Step 1-2: 作成結果を検証する**

Run: `(Select-String -Path 'skills/start-work/references/plan-deviation-defaults.md' -Pattern '^## ').Count`
Expected: **10**（適用対象と前処理 / 指摘の型分類と既定の扱い / 設計変更級の採用基準 / 計画側の宣言（計画作成時） / 逸脱記録と検出層 / 委譲プロンプトへの注入（委譲時） / 発火点 / 根拠 / 退役条件 / 対応する原則）

Run: `(Select-String -Path 'skills/start-work/references/plan-deviation-defaults.md' -Pattern '逸脱記録:' -SimpleMatch).Count`
Expected: **2**（書式フェンスの 1 行＋行頭固定の記述）

### Task 2: start-work SKILL.md の予防層配線

**Files:**
- Modify: `skills/start-work/SKILL.md`（Pre 節＝86 行の merge-practice 条項の直後、マッピング表 62・63・65 行）

- [ ] **Step 2-1: Pre 節へ条項を 1 つ追加する**。既存の merge-practice 条項（「- 完了処理〈既定ブランチへの取り込み〉を行うスキル・手順の実行直前は、…」の行）の**直後**に以下の 1 条項を挿入:

```markdown
- 計画作成（writing-plans またはインライン簡易 plan）へ進む直前、および実装系スキル（executing-plans / subagent-driven-development またはインライン TDD）へ delegate する直前は、`references/plan-deviation-defaults.md`（計画逸脱判断の既定の正本）を読んで適用する。適用は委譲中に発生する実装時レビュー・実装者検証の指摘受領時にも及ぶ（本条項も冒頭の適用範囲文の例外として delegate 済みスキル内部の当該時点に適用される。Post ラッパーの発火粒度は現行のまま変わらない。二重発火の抑止と再開時の扱いは正本の「発火点」節が正）
```

- [ ] **Step 2-2: マッピング表の 3 セルへポインタを追記する**（逐語置換。推奨スキル列のセル末尾へ全角括弧で追記。実体規範は書かずポインタに徹する）

62 行の旧:

```markdown
| 既存仕様からの計画作成 | superpowers:writing-plans | インライン簡易plan作成 |
```

62 行の新:

```markdown
| 既存仕様からの計画作成 | superpowers:writing-plans（実行直前に `references/plan-deviation-defaults.md`〈計画逸脱判断の既定の正本〉を読んで適用） | インライン簡易plan作成 |
```

63 行の旧:

```markdown
| 既存planの実装 | superpowers:executing-plans または superpowers:subagent-driven-development | インラインTDDサイクル |
```

63 行の新:

```markdown
| 既存planの実装 | superpowers:executing-plans または superpowers:subagent-driven-development（いずれも実行直前に `references/plan-deviation-defaults.md`〈計画逸脱判断の既定の正本〉を読んで適用） | インラインTDDサイクル |
```

65 行の旧:

```markdown
| コードレビュー対応 | superpowers:receiving-code-review | インライン指摘整理→対応 |
```

65 行の新:

```markdown
| コードレビュー対応 | superpowers:receiving-code-review（確定済み計画の実行中の場合は `references/plan-deviation-defaults.md`〈計画逸脱判断の既定の正本〉を適用） | インライン指摘整理→対応 |
```

- [ ] **Step 2-3: 検証**

Run: `(Select-String -Path 'skills/start-work/SKILL.md' -Pattern 'plan-deviation-defaults').Count`
Expected: **4**（Pre 条項 1＋セル 3）

Run: `Select-String -Path 'skills/start-work/SKILL.md' -Pattern '\([^)]*plan-deviation-defaults'`
Expected: **0 件**（追記括弧が半角で書かれていないこと。全角（）のみ）

### Task 3: subagent-dispatch SKILL.md へ注入想起ポインタ

**Files:**
- Modify: `skills/subagent-dispatch/SKILL.md`（「## 手順」節・手順 6 の直後）

- [ ] **Step 3-1: 手順 6 の直後へ手順 7 として以下を追加する**

```markdown
7. 実装、または実装時レビュー（仕様適合・コード品質等）を委譲するときは、`skills/start-work/references/plan-deviation-defaults.md` の注入項目（実装委譲の報告特則・実装時の仕様適合レビューの判定対象）を委譲プロンプトへ含めることを確認する（ADR-0119）
```

- [ ] **Step 3-2: 検証**

Run: `(Select-String -Path 'skills/subagent-dispatch/SKILL.md' -Pattern 'plan-deviation-defaults').Count`
Expected: **1**

Run: `Select-String -Path 'skills/subagent-dispatch/SKILL.md' -Pattern '\(ADR-'`
Expected: **0 件**（手順 7 の（ADR-0119）が半角括弧で書かれていないこと。半角だと識別子除去後に空括弧が dist へ残る）

### Task 4: version bump（0.1.14 → 0.1.15）

**Files:**
- Modify: `.claude-plugin/plugin.json`（version 行）
- Modify: `.claude-plugin/marketplace.json`（version 行）

- [ ] **Step 4-1: 両ファイルの `"version": "0.1.14"` を `"version": "0.1.15"` へ置換する**

- [ ] **Step 4-2: 検証**

Run: `Select-String -Path '.claude-plugin/plugin.json','.claude-plugin/marketplace.json' -Pattern '"version": "0.1.15"'`
Expected: **2 件**（各ファイル 1 件）

### Task 5: 生成と執行点 4 手順

**Files:**
- 生成物: `dist/` 配下の対応ファイル（生成器が更新。ルート `.agents/plugins/marketplace.json` は version を持たず、本サイクルでは name / source も変えないため差分は生じない）

- [ ] **Step 5-1: 生成器を実行する**

Run: `pwsh -File scripts/build-dist.ps1`
Expected: 非ゼロ終了しない（記法規約違反・version 不一致があれば非ゼロで停止 → 違反を修正して再実行）

- [ ] **Step 5-2: 両生成器を -Check で実行する**

Run: `pwsh -File scripts/build-dist.ps1 -Check` → Expected: exit 0
Run: `pwsh -File scripts/sync-template.ps1 -Check` → Expected: exit 0

- [ ] **Step 5-3: 配布物を目視する**（機械判定が届かない 5 領域）

対象: `dist/skills/start-work/references/plan-deviation-defaults.md`・`dist/skills/start-work/SKILL.md`・`dist/skills/subagent-dispatch/SKILL.md`
確認: (1) 識別子除去後に空括弧・文法破綻が残っていないか（とくに手順 7 の「（ADR-0119）」が行ごと自然に読めるか） (2) 半角括弧の識別子がないか (3) 実在の固有名（プロジェクト名・絶対パス）が例示に残っていないか (4) 「本リポジトリ」等の自己参照がないか (5) 逸脱記録行の書式フェンス内にプレースホルダ以外の識別子がないか

- [ ] **Step 5-4: dist 側の配線を検証**

Run: `(Select-String -Path 'dist/skills/start-work/SKILL.md' -Pattern 'plan-deviation-defaults').Count`
Expected: **4**
Run: `(Select-String -Path 'dist/skills/subagent-dispatch/SKILL.md' -Pattern 'plan-deviation-defaults').Count`
Expected: **1**
Run: `Test-Path 'dist/skills/start-work/references/plan-deviation-defaults.md'`
Expected: **True**

### Task 6: 全体検証とコミット

- [ ] **Step 6-1: 変更の全体を確認する**

Run: `git status --short`
Expected: 変更 = `skills/start-work/SKILL.md`・`skills/subagent-dispatch/SKILL.md`・`.claude-plugin/plugin.json`・`.claude-plugin/marketplace.json`・`dist/.claude-plugin/plugin.json`・`dist/.codex-plugin/plugin.json`・`dist/skills/start-work/SKILL.md`・`dist/skills/subagent-dispatch/SKILL.md`。新規（未追跡） = `skills/start-work/references/plan-deviation-defaults.md`・`dist/skills/start-work/references/plan-deviation-defaults.md`・本計画ファイル。`.agents/plugins/marketplace.json` は version を持たないため差分なし。未追跡ノイズ（含めない） = `docs/inbox/` の 3 件＋`docs/conversation_log.md`

- [ ] **Step 6-2: pathspec 付きでコミットする**

```powershell
git add skills/start-work/references/plan-deviation-defaults.md skills/start-work/SKILL.md skills/subagent-dispatch/SKILL.md .claude-plugin/plugin.json .claude-plugin/marketplace.json dist .agents/plugins/marketplace.json docs/working/plans/2026-08-30-plan-deviation-defaults-implementation.md
git commit -m "feat: ADR-0119 計画逸脱判断の既定を references 正本として実装（plugin 0.1.15）"
```

Expected: コミット成功。`git status --short` で配布対象ソース・生成物の残差分なし

## 完了条件

1. `plan-deviation-defaults.md` がソース・dist の両方に存在し、見出し 10 本・書式規定を含む
2. 配線の出現数: start-work = 4 / subagent-dispatch = 1（ソース・dist とも。Step 2-3 / 3-2 / 5-4 の Run が対応）
3. version 0.1.15 が 2 正本＋生成物で一致し、両 -Check が exit 0
4. 配布物目視 5 領域で違反なし
5. 単一コミットにソースと生成物が同梱されている
6. 各タスクの完了報告に「逸脱突合: 一致」または「逸脱突合: 差分あり」の 1 行がある（本計画は前倒し型＝検出層の自己検査の自己適用）

（ADR-0119 / 0118 の Accepted 昇格・Issue-0110 の close・サイクル全体整合検査は本計画の外＝start-work Post ラッパーの昇格チェックポイントで実施する）
