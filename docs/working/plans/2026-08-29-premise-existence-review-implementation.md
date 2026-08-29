# ADR-0117 前提実在観点・前提検査規範 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ADR-0117 の決定（前提実在観点の常設・前提検査・探索先併記・受け取り時義務・実体読み直し）をスキル 3 本・README・現行 spec 3 件・関連 ADR 注記・配布物・worklog 台帳へ反映する。

**Architecture:** 実装対象の正本は ADR-0117 Consequences「実装対象」。編集はすべて Markdown 規範文書（コード・テストなし）のため、各タスクは「編集 → grep/読み直しによる実体確認 → 節目でコミット」の型を取る。配布対象ソース（`skills/`）変更のため、最後に version bump（0.1.13 → 0.1.14）＋執行点 4 手順を実施し、ソースと `dist/` を同一コミットに含める。

**Tech Stack:** Markdown / PowerShell（生成器 `scripts/build-dist.ps1`・`scripts/sync-template.ps1 -Check`）/ Python（worklog 台帳追記。バックスラッシュ破損防止のためスクリプトファイル方式・パスはスラッシュ区切り）

**前提**: ブランチ `feature/premise-existence-review`。ADR-0117 はコミット済み（`0f4b5f5`）。現状実測: `skills/pre-finalization-review/SKILL.md` の「3 観点」7 行（3/17/36/95/110/122/138 行目）・「観点は 3」2 行（99/110 行目）・「1〜3 体」2 行（99/110 行目）。spec 2026-08-05 の観点数・体数 4 行（11/19/90/99 行目）。plugin.json / marketplace.json とも version 0.1.13。**行番号はすべて編集前の実測であり、挿入により以降の行は順次ずれる。各ステップは行番号ではなく併記した引用アンカー（old 文言）を正とする。**

**記法規約の注意（全タスク共通）**: `skills/` 配下は配布対象ソース。出所識別子（ADR-NNNN / Issue-NNNN / `LoopForAlpha#Issue-NNNN` / worklog id）は全角括弧の内側・出所注記 `（出所: …）` 形のみに置く（R1）。括弧に識別子と説明語を同居させない（R1-a）。半角括弧に識別子を入れない（R1-b）。`docs/` 配下（spec・ADR・README・本計画）は適用外。

---

### Task 1: `skills/pre-finalization-review/SKILL.md` の改修（12 編集）

**Files:**
- Modify: `skills/pre-finalization-review/SKILL.md`

- [ ] **Step 1-1: frontmatter description（3 行目）** — `3 観点（敵対的・実装整合性・仕様適合）の独立レビュー` → `4 観点（敵対的・実装整合性・仕様適合・前提実在）の独立レビュー`

- [ ] **Step 1-2: 「いつ使うか」（17 行目）** — `下記「手順」の 3 観点独立レビューを実行する` → `下記「手順」の 4 観点独立レビューを実行する`

- [ ] **Step 1-3: 提示規則 2（36 行目）** — `**フルレビュー（3 観点）を選択肢の先頭に置き「（推奨）」を付す**` → `**フルレビュー（4 観点）を選択肢の先頭に置き「（推奨）」を付す**`

- [ ] **Step 1-4: 3-2 (b) 探索先併記（58 行目）** — `無ければ「特定できた反対材料: なし」と明記する（**不在の判定も出力に残す**）。` の直後へ挿入:

```text
「なし」と書くときは、何を探して無かったか（探索した正本・課題・実測の出所）を併記する——探索不足と不在を出力で区別するため（出所: LoopForAlpha#Issue-0125）。
```

- [ ] **Step 1-5: 手順 1 観点追加（95〜99 行目）** — `3 観点を立てる:` → `4 観点を立てる:`。`- **仕様適合**: …` の行の直後へ挿入:

```text
   - **前提実在**: 成果物が新設・変更する各機構（条件・分岐・ゲート・記録・配線・データ経路・禁止事項）は本当に要るか。機構が守るもの・得るものを 1 件ずつ 1 行で特定し、それが方針の正本と実体（コード・設定・データ配置・起動順序）を読んだとき本当に存在するかを検査する。判定は 必要 / 不要 / 重複 / 欠落 / 前提誤り（機構は要るが根拠文が偽）の 5 値とし、「実在しない」と判定するときは到達経路・不在の根拠（何を読んで確認したか）を具体的に示す（実証要件は他観点と同じ）。統計設計の妥当性など「実在するか」では測れない検査は本観点の射程外（必要なら他観点・別手段が担う）。特に疑う型は下記「適用例: 前提実在観点で特に疑う型」を参照
```

さらに同手順末尾の `観点は 3 つを維持する。確定前レビューの反復（指摘反映後の再レビュー）のフル巡に限り、担当を兼務させて体数のみ 1〜3 体へ縮小してよい（「反復の実施」節参照）。` → `観点は 4 つを維持する。確定前レビューの反復（指摘反映後の再レビュー）のフル巡に限り、担当を兼務させて体数のみ 1〜4 体へ縮小してよい（「反復の実施」節参照。4 体構成・1 体 4 観点兼務の実測は無い）。`

- [ ] **Step 1-5b: 適用例節の新設** — ADR-0117 の指定（「特に疑う型」は適用例節へ収載）に従い、`## 適用例: 独立レビューでしか捕まらなかった欠陥（ADR-0080）` 節の末尾（`## 根拠と世代（ADR-0073）` 見出しの直前）へ新節を挿入:

```text
## 適用例: 前提実在観点で特に疑う型（ADR-0117）

拘束的な検査項目ではなく、前提実在観点を立てるときの手がかりとして使う適用例である。出所は単一プロジェクトの一次記録に限られ、網羅の保証はない（出所: LoopForAlpha#Issue-0125 / LoopForAlpha-2026-08-29-03）。

1. AI が自力再現できる情報を隠す機構
2. 既存ゲートが覆う対象への重複ゲート
3. 方針が許容している乖離を機構で塞ぐ
4. 実体では到達不能な経路の防御
5. 実在を確認せず「安全側」と称して足した条件
6. 逆方向: 方針が要求する保護を実体を確認せず「既存で足りる」と省いた箇所（実測で最多だった「欠落」型に対応する）
```

- [ ] **Step 1-6: 手順 2 正本の供給（100 行目）** — 行末 `（根拠エントリ由来の運用ヒント。Issue-0034）` の直後へ挿入:

```text
。前提実在観点の委譲プロンプトには、方針の正本と実体の所在（ファイルパス）を明記して渡す（コンテキストを持たないレビュアーに、読むべき正本を知らせずに正本との突合を課さないため）
```

- [ ] **Step 1-7: 手順 5 前提検査（103 行目）** — `**実証の伴わない指摘は採用しない**。` の直後へ挿入:

```text
採否は指摘 1 件ずつ「前提（守るもの・得るもの）」と「実体での確認箇所」を書いてから決め、採否の判断とともに反復提示・報告へ添える——実証は事実を担保するが、その事実が問題になる前提は担保しない。実証つき指摘 26 件を前提検査なしに一括採用し、実在しない資産を守る機構を仕様へ足した実測がある（出所: LoopForAlpha#Issue-0125 / LoopForAlpha-2026-08-29-01）。
```

注: ADR-0117 実装対象の「反復提示・報告〈手順 6・104 行目〉への併記を含む」は、本挿入文の「採否の判断とともに反復提示・報告へ添える」が担う（手順 6 自体は編集しない）。執行点確認時はこの読みで判定する。

- [ ] **Step 1-8: 停止判定の振り分け指針（82 行目）** — `迷う場合（指摘・改訂のいずれの判定でも）は設計骨格側へ倒す（振り分けは提示に添える判断材料であり、記録・引き継ぎの機構は置かない）。` の**直後（括弧と句点の後）**へ独立の文として挿入（既存の括弧注記が新文だけに係って読めるのを防ぐため）:

```text
前提誤り（機構は要るが根拠文が偽）の指摘で、修正が根拠文の訂正のみで済み機構の新設・変更を伴わないものは「周辺」へ振り分けてよい。
```

- [ ] **Step 1-9: フル巡定義（110 行目）** — `- **フル巡**: 3 観点（敵対的・実装整合性・仕様適合）を全数走査で覆う巡。観点は 3 つを維持し、反復のフル巡に限り担当を兼務させて体数のみ 1〜3 体へ縮小してよい（既定は 3 観点・3 体。初回の「フルレビュー（3 観点）」はフル巡と同一方式である）。レビュアーは新規とする` → `- **フル巡**: 4 観点（敵対的・実装整合性・仕様適合・前提実在）を全数走査で覆う巡。観点は 4 つを維持し、反復のフル巡に限り担当を兼務させて体数のみ 1〜4 体へ縮小してよい（既定は 4 観点・4 体。初回の「フルレビュー（4 観点）」はフル巡と同一方式である）。レビュアーは新規とする`

- [ ] **Step 1-10: 適用例への出所条件注記（121・122 行目）** — 「体制縮小」行の末尾へ `（3 観点時の実測）`、「観点構成の型別調整」行の末尾へ `（3 観点時の実測。4 観点構成での追試は無い）` を追加（138 行目の過去実測記述は据え置き）

- [ ] **Step 1-11: 根拠と世代（146〜150 行目）** — 節末尾へ箇条を追加:

```text
- 前提実在観点・手順 5 の前提検査・3-2 (b) の探索先併記の根拠: 単一プロジェクトの確定前レビュー 5 巡・11 体の実測（出所: LoopForAlpha#Issue-0125 / LoopForAlpha-2026-08-29-01 / -2026-08-29-02 / -2026-08-29-03）。観測世代は claude-fable-5（作成側）と claude-opus-5（レビュアー）。退役は双方向 — 同型 delta（前提検査なしの採用・要約からの設計・探索なしの「なし」記載）が長期にわたり中央ストアへ現れない場合は縮小・退役を、指摘の大半が不採用・誤検出に終わる場合は定義の改良・簡素化を候補としてユーザーへ提案する。判断はユーザーが行う
```

注: 本編集は ADR-0117 Consequences「実装対象」の列挙には無いが、同 ADR 過剰適合点検「出所の偏り」欄の是正記載（適用例への降格＋根拠と世代＋退役経路を明記する）が根拠。執行点確認時は基準外の追加編集ではなく点検ブロック由来の実装として扱う。

- [ ] **Step 1-12: 検証** — 実行と期待値:

```bash
grep -c "3 観点" skills/pre-finalization-review/SKILL.md
```

期待: `3`（121・122・138 行目の史実・注記のみ）

```bash
grep -c "前提実在" skills/pre-finalization-review/SKILL.md
```

期待: `7`（description・手順 1・手順 2・フル巡定義・適用例節の見出しと本文で 2・根拠と世代）。`観点は 3` `1〜3 体` は 0 件、`観点は 4 つを維持` `フルレビュー（4 観点）` は**各 2 件**（99/110 行目・36/110 行目の両方が書き換わるため）。あわせて `grep -n "^## " skills/pre-finalization-review/SKILL.md` で、新設節「適用例: 前提実在観点で特に疑う型」が「適用例: 独立レビューでしか捕まらなかった欠陥」の**後**・「根拠と世代」の**前**にあること

### Task 2: `skills/subagent-dispatch/SKILL.md` 手順 6 の追加

**Files:**
- Modify: `skills/subagent-dispatch/SKILL.md`

- [ ] **Step 2-1:** 手順 5（20 行目 `5. 破壊的検証…確認する（委譲先が複製での実施を報告しながら実リポジトリが破壊されていた実測がある（出所: Issue-0076））` — 実文はファイルで確認）の直後へ項目 6 を追加:

```text
6. 検査・監査・走査を委譲した場合、受け取った指摘の採否では、実証を伴う指摘でも指摘が守るもの・前提の実在を委譲側が検査する。実証は事実を担保してもその事実が問題になる前提は担保せず、採否の最終裁定は委譲側の責務であるため。確定前レビュー経路の正本は `pre-finalization-review` 手順 5 で、本項はそれ以外の検査・監査・走査委譲を覆う。観測世代: claude-fable-5（出所: LoopForAlpha#Issue-0125 / LoopForAlpha-2026-08-29-01）
```

注: 出所＋観測世代を手順文中に添える書式は、出所のみを添える既存の手順 5 と異なる**新形**である（ADR-0117 Decision 4 が「実装時に明示」を求めるため、本注記がその明示を担う。スキル本文には書かない）。

- [ ] **Step 2-2: 検証** — `grep -c "前提の実在" skills/subagent-dispatch/SKILL.md` 期待: `1`。B 群表（45〜52 行目）に変更が無いこと（`git diff` で表領域の差分ゼロ）

### Task 3: `skills/feature-block-design/SKILL.md` Phase 2〜4 の実体読み直し

**Files:**
- Modify: `skills/feature-block-design/SKILL.md`

- [ ] **Step 3-1: Phase 2（80 行目付近）** — `抽出結果（ブロック名、責務一行サマリ、依存関係）をユーザーに提示して**承認を得る**。` の直前へ段落を挿入:

```text
ブロック間の依存関係・接続点（置き場・誰が読む・何が検査する・起動順序・不変条件）を書く前に、接続先が既存の実体（コード・設定・構成定義）を持つ場合はそれを読み直す。文書の要約や記憶から書かない。新規要素どうしの接続はこの限りではない（出所: LoopForAlpha#Issue-0125 / LoopForAlpha-2026-08-29-02）。
```

- [ ] **Step 3-2: Phase 3（84 行目付近）** — `### Phase 3: `00-overview.md` の作成 / 更新` 見出し直後の `以下の構成で書く:` の前へ挿入:

```text
ブロック間関係図・主要な処理フローを書く前に、Phase 2 と同様に接続先の実体を読み直す（文書の要約・記憶から書かない）。
```

- [ ] **Step 3-3: Phase 4（103 行目付近）** — `ブロック数だけ繰り返す。ファイル名は `NN-<block-slug>.md`。` の直後へ挿入:

```text
「対象ファイル」「インターフェース」「このブロック固有の制約・前提」など接続点の記述では、Phase 2 と同様に接続先の実体を読み直してから書く。
```

- [ ] **Step 3-4: 検証** — `grep -c "読み直" skills/feature-block-design/SKILL.md` 期待: `3`（Phase 2・3・4 に各 1。Step 3-1 の挿入文は「実体（…）を持つ場合はそれを読み直す」の形で「実体を読み直」には一致しないため、パターンは「読み直」で数える）

### Task 4: `README.md` スキル一覧行の更新

**Files:**
- Modify: `README.md:46`

- [ ] **Step 4-1:** `3 観点独立レビューの実施（実証つき・発動はユーザー指示のみ）` → `4 観点独立レビューの実施（実証つき・発動はユーザー指示のみ）`、行末の参照 `（ADR-0067 / ADR-0072 / ADR-0080 / ADR-0116）` → `（ADR-0067 / ADR-0072 / ADR-0080 / ADR-0116 / ADR-0117）`

- [ ] **Step 4-2: 検証** — `grep -c "4 観点独立レビュー" README.md` 期待: `1`

### Task 5: 現行 spec 3 件の同期（スナップショット規約）

**Files:**
- Modify: `docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md`
- Modify: `docs/current/specs/2026-08-28-start-work-responsibility-split-design.md:36`
- Modify: `docs/current/specs/2026-05-01-feature-block-design/01-skill-feature-block-design.md`

- [ ] **Step 5-1: spec 2026-08-05** — 6 箇所:
  1. 5 行目の根拠 ADR 列挙の末尾へ `、ADR-0117（前提実在観点・前提検査・受け取り時義務の追加）` を追加
  2. 11 行目 `3 観点を独立サブエージェントへ委譲するため` → `4 観点を独立サブエージェントへ委譲するため`
  3. 19 行目 `│ 3 観点の委譲に使う` → `│ 4 観点の委譲に使う`
  4. 67 行目の段落末尾へ追加: `検査・監査・走査の委譲では、受け取った指摘の採否で、実証を伴う指摘でも守るもの・前提の実在を委譲側が検査する（ADR-0117。確定前レビュー経路の正本は pre-finalization-review 手順 5）。`
  5. 90 行目 `レビュー観点 3 つを立てる（敵対的 / 実装整合性 / 仕様適合）（観点は 3 つを維持。反復のフル巡に限り体数のみ 1〜3 体へ縮小可——「反復の実施」参照）` → `レビュー観点 4 つを立てる（敵対的 / 実装整合性 / 仕様適合 / 前提実在——機構が守るもの・得るものの実在を方針の正本と実体で検査。ADR-0117）（観点は 4 つを維持。反復のフル巡に限り体数のみ 1〜4 体へ縮小可——「反復の実施」参照）`。91 行目の末尾へ `。前提実在観点には方針の正本と実体の所在を委譲プロンプトで渡す` を追加。94 行目 `指摘を集約する。実証の伴わない指摘は採用しない。` の直後へ `採否は 1 件ずつ前提（守るもの・得るもの）と実体での確認箇所を書いてから決める（ADR-0117）。` を挿入
  6. 99 行目 `フル巡（3 観点・体数 1〜3 体・新規レビュアー）` → `フル巡（4 観点・体数 1〜4 体・新規レビュアー）`
- [ ] **Step 5-2: spec 2026-08-28（36 行目）** — `**実施操作**（既存）: 3 観点の独立レビュー実行。` → `**実施操作**（既存）: 4 観点の独立レビュー実行（ADR-0117 で前提実在を追加）。`
- [ ] **Step 5-3: spec 2026-05-01 の 01 ファイル** — Phase 2（80 行目 `抽出結果…承認を得る` の直前）・Phase 3（85 行目 `以下の構成で書く:` の前）・Phase 4（102 行目 `ブロック数だけ繰り返す…` の直後）へ、Task 3 と同旨の 3 段落（Step 3-1〜3-3 と同文。出所注記は `（ADR-0117）` に置き換え）を挿入
- [ ] **Step 5-4: 検証** — `grep -c "3 観点\|観点 3 つ\|1〜3 体" docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md` 期待: `0`（現状 4）。`grep -c "ADR-0117" docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md` 期待: `4` 以上。`grep -c "4 観点の独立レビュー実行" docs/current/specs/2026-08-28-start-work-responsibility-split-design.md` 期待: `1`。`grep -c "読み直" docs/current/specs/2026-05-01-feature-block-design/01-skill-feature-block-design.md` 期待: `3`

### Task 6: 既存 ADR への部分修正・注記（5 件・4 ファイル）

**Files:**
- Modify: `docs/records/decisions/0080-review-presentation-scaled-by-unreviewed-normative-content.md`（Consequences 末尾）
- Modify: `docs/records/decisions/0107-iterative-review-recommendation-by-revision-nature.md`（Consequences 末尾）
- Modify: `docs/records/decisions/0067-pre-finalization-review-as-new-skill.md`（ファイル末尾）
- Modify: `docs/records/decisions/0063-distributed-issue-handover-path.md`（Consequences 末尾）

いずれも Accepted 維持・本文は書き換えない（部分修正注記の追記は改訂記録規定の対象外）。挿入位置は各ファイルの Consequences 節の最後の箇条の直後（`## 過剰適合点検` 等の後続節がある場合はその直前）。

- [ ] **Step 6-1: ADR-0080 へ部分修正注記**:

```text
- **部分修正（ADR-0117）**: Decision 3-2 (b) の反対材料欄に「なし」記載時の探索先併記が追加された。また Decision 2 の呼称「フルレビュー（3 観点）」は、前提実在観点の追加により「フルレビュー（4 観点）」へ改められた。推奨判定・反対材料欄の常設の骨格は現役のため、Status は Accepted のまま維持する
```

- [ ] **Step 6-2: ADR-0107 へ部分修正注記＋注記**:

```text
- **部分修正（ADR-0117）**: フル巡の観点は 4（敵対的・実装整合性・仕様適合・前提実在）・兼務縮小の体数は 1〜4 体へ拡張された。Consequences の呼称 3 系統の「フルレビュー（3 観点）」は「フルレビュー（4 観点）」と読む。レイヤ振り分けには「前提誤りの指摘で修正が根拠文の訂正のみで済むものは周辺へ振り分けてよい」の指針が追加された。反復・停止判定の骨格は現役のため、Status は Accepted のまま維持する
- **注記（ADR-0117）**: 本 ADR の評価可能性の計数経路（git 履歴上の `review=` 行）は、ADR-0117 の評価可能性（発火機会の計数）も共用する
```

- [ ] **Step 6-3: ADR-0067 へ注記**（既存の `- **注記（ADR-0107）**: …` の直後）:

```text
- **注記（ADR-0117）**: 「観点は最低 3 つ」は下限規定であり、ADR-0117 による 4 観点目（前提実在）の常設はこれを満たす（決定の変更にあたらない）。直前の注記（ADR-0107）の「体数のみ 1〜3 体へ縮小できる」は、ADR-0117 により 1〜4 体へ置き換わった
```

- [ ] **Step 6-4: ADR-0063 へ注記**:

```text
- **注記（ADR-0117）**: 受け皿の実在確認には、課題起票のほか「決定（ADR）と実装で直ちに受ける場合」を含む読みを ADR-0117 が適用した（配信元側での課題起票を経ずに close トリガーを満たす）
```

- [ ] **Step 6-5: 検証** — `grep -l "ADR-0117" docs/records/decisions/0063-*.md docs/records/decisions/0067-*.md docs/records/decisions/0080-*.md docs/records/decisions/0107-*.md` 期待: 4 ファイルすべてが列挙される。0080・0107 では `grep -n "（ADR-0117）\|^## " <file>` で、挿入行の行番号が `## Consequences` 見出しより**後**・`## 過剰適合点検` 見出しより**前**にあること（両辺で判定する——前辺のみだと適用例・評価可能性など中間の節への誤挿入を通すため）。Step 6-3 の閉じ括弧は全角 `）` であること（挿入後に目視）

### Task 7: version bump・生成器・執行点 4 手順

**Files:**
- Modify: `.claude-plugin/plugin.json` / `.claude-plugin/marketplace.json`（version 0.1.13 → 0.1.14）
- Regenerate: `dist/`・ルート `.agents/plugins/marketplace.json`

- [ ] **Step 7-1:** 両 JSON の `"version": "0.1.13"` → `"0.1.14"`
- [ ] **Step 7-2:** 生成器実行: `powershell -File scripts/build-dist.ps1` 期待: exit 0（記法規約違反があれば非ゼロ終了 → 違反を修正して再実行）
- [ ] **Step 7-3:** 両 -Check: `powershell -File scripts/build-dist.ps1 -Check` および `powershell -File scripts/sync-template.ps1 -Check` 期待: いずれも exit 0
- [ ] **Step 7-4: 配布物目視** — `dist/skills/pre-finalization-review/SKILL.md`・`dist/skills/subagent-dispatch/SKILL.md`・`dist/skills/feature-block-design/SKILL.md` を読み、5 つの型（R1-a 同居・半角括弧・実在固有名・自己参照・docstring）を確認する。とくに今回挿入した出所注記の除去後に文が壊れていないこと（例: 「——探索不足と不在を出力で区別するため。」の後に空括弧が残らない）

### Task 8: ソース＋生成物の同一コミット

- [ ] **Step 8-1:** `git status --short` で対象を確認し、pathspec 指定で add（`docs/inbox/`・`docs/conversation_log.md` を巻き込まない）:

```bash
git add skills/ README.md docs/current/specs/ docs/records/decisions/ .claude-plugin/ dist/ .agents/plugins/marketplace.json docs/working/plans/2026-08-29-premise-existence-review-implementation.md docs/working/handoff/feature_premise-existence-review.md
```

- [ ] **Step 8-2:** staged 一覧を確認のうえコミット:

```bash
git commit -m "feat: ADR-0117 前提実在観点と前提検査規範を 3 スキルへ実装（plugin 0.1.14）"
```

### Task 9: worklog 台帳への記入（git 外・中央ストア）

- [ ] **Step 9-1:** スクラッチパッドへ Python スクリプトを作成して実行する（heredoc はバックスラッシュ破損の実測があるため使わない。パスはスラッシュ区切り・`newline="\n"`・UTF-8 BOM なし）。追記する 8 行（日付は実行日）:
  - `-01`/`-02`/`-03` へ各 2 行: `{"v":2,"id":"LoopForAlpha-2026-08-29-0N","outcome":"adopted","date":"<実行日>"}` と `{"v":2,"id":"…","outcome":"merged","ref":"<統合先>","date":"<実行日>"}`。ref は `-01` = `MakeAiInstructions:skills/pre-finalization-review`、`-02` = `MakeAiInstructions:skills/feature-block-design`、`-03` = `MakeAiInstructions:skills/pre-finalization-review`
  - `-04`/`-05` へ各 1 行: `{"v":2,"id":"…","outcome":"deferred","evidence_count":1,"date":"<実行日>"}`
  - 冪等性: 追記前に `processed.jsonl` を読み、**(id, outcome) の組**が既に存在する行のみスキップする（再実行・途中失敗後の再開で重複追記しない。台帳は同一 id への後続レコード追記で状態遷移を表現するため、id 単位でスキップすると `adopted` 書き込み後の失敗から再開したとき `merged` 行が永久に書かれなくなる）
  - `-01` の統合先は `pre-finalization-review` 手順 5 と `subagent-dispatch` 手順 6 の両方だが、`ref` は 1 値のため主統合先 `MakeAiInstructions:skills/pre-finalization-review` を指す（全統合先は ADR-0117 が正本）
- [ ] **Step 9-2: 検証** — 追記後に `processed.jsonl` を読み直し、8 行が JSON として parse でき、`-01`〜`-03` の最新 outcome が `merged`・`-04`/`-05` が `deferred` であること

### Task 10: 完了前検証

- [ ] **Step 10-1:** Task 1〜5 の検証 grep を一括再実行し、期待値どおりであること
- [ ] **Step 10-2:** `powershell -File scripts/build-dist.ps1 -Check` を再実行し exit 0 であること（検証是正等で Task 7 以降に `skills/` を再編集した場合の dist 陳腐化を検出する。`git status` はクリーンでも陳腐化は検出できない）。`git log --oneline -3` でコミットが立っていること、`git status --short` に `dist/` の未ステージ差分が残っていないこと
- [ ] **Step 10-3:** ADR-0117 の Accepted 昇格は実装完了・検証後のチェックポイントで別途実施（decision-log「承認の昇格」。サイクル全体整合検査を含むため本計画のタスクには含めない）

---

## 不採用指摘一覧（確定前レビューからの実装時レビュー引き継ぎ）

ADR-0117 の確定前レビュー（フル巡 2・差分確認巡 1）で不採用とした指摘。実装時の独立レビューを行う場合の判断材料として残す。

1. **Decision 4 の受け取り時義務への証跡新設**（第 2 巡敵対的）— 規定増殖の回避を理由に不採用。既存の受け取り時義務（破壊的検証）と同じ配線水準として ADR に受容記載
2. **停止機構（骨格安定・締めモード）への機構的手当て**（第 2 巡敵対的）— 実測が収束を示しており推奨はユーザー判断に残るため、ADR Consequences の受容記載で対応
3. **「守る資産 × 実現コスト」2 軸の常設**（第 1 巡仕様適合ほか）— 判定 5 値と 1 件ずつの前提記載が同機能を担うため不採用（ADR Decision 2 に明記）
4. **worklog `-05` の merged 化**（第 1 巡仕様適合）— 同エントリの手順（提案書の時点資料化）は未スキル化のため deferred が実態（ADR Consequences に明記）
