# ADR-0099 引用突合の文言拡張 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ADR-0099 の決定（サイクル全体整合検査の観点 5 拡張・過剰適合点検の注記＋雛形改定・台帳整合）を、4 文書＋配布物へ矛盾なく反映する。

**Architecture:** 新規ファイルは作らない。既存 4 文書（decision-log スキル / CONTRIBUTING.md / 過剰適合点検 spec / ADR-0092・0079）の文言編集と、plugin version bump ＋ `dist/` 再生成のみ。スキル編集を最後に置き、執行点 4 手順（生成器実行・両 -Check・dist 同一コミット・5 点目視)をソース編集と同一コミットで満たす。

**Tech Stack:** Markdown 編集・PowerShell（grep 検証・生成器実行）・git（pathspec コミット）

**前提知識（実装者向け）:**

- 本プロジェクトの配布スキルの正本は `skills/` 配下。`dist/` は `scripts/build-dist.ps1` が生成する配布物で、両方を同一コミットに含める規約（CONTRIBUTING.md「配布対象ソースの記法規約」の執行点 4 手順）
- CONTRIBUTING.md と `docs/current/specs/` は配布対象外（template.manifest 非記載）。`scripts/sync-template.ps1` の再生成は不要だが、執行点手順 2 により `-Check` は両方実行する
- コミットは pathspec 付き `git commit -- <paths>` を使う（untracked の inbox 4 ファイルを巻き込まない。Issue-0020）
- 検証の期待値はすべて等号（ちょうど N 件）。1 件でもずれたら原因を特定してから進む

---

### Task 1: CONTRIBUTING.md への注記追加と雛形改定＋spec スナップショット同期

**Files:**
- Modify: `CONTRIBUTING.md`（「全シナリオ共通: 過剰適合の点検」節。観点リスト直後と定型ブロック雛形）
- Modify: `docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md`（変更 1 のコードフェンス内の同一箇所＋関連 ADR 行）

- [ ] **Step 1: 編集対象の現行文言を実体確認する**

Run: `Select-String -Path CONTRIBUTING.md -Pattern '4\. \*\*退役経路\*\*|\| システム種別依存性 \| 問題なし / 要是正' | ForEach-Object {"$($_.LineNumber): $($_.Line)"}`
Expected: 2 行（観点 4 の行 L43 付近、雛形の観点 2 行 L68 付近。行番号は多少ずれてよいが各 1 箇所であること）

- [ ] **Step 2: CONTRIBUTING.md の観点リスト直後に注記を挿入する**

観点 4 の行（`4. **退役経路**: 追加する規範が不要になった…定義されているか`）と `### 是正パターン` 見出しの間に、空行を挟んで次の段落を挿入する:

```
観点 2・3 の判定では、拡張が既存規範を参照・引き写している箇所を列挙し、引用元にあるゲート（システム種別・モデル・状況の条件節）を引き継いでいるかを突合する。ゲートを落とす方向の誤りは「種別・モデルに依存しない無条件規範」に見えるため、引用箇所の列挙なしの自己判定では検出できない。
```

- [ ] **Step 3: CONTRIBUTING.md の定型ブロック雛形の観点 2・3 根拠欄を書き換える**

雛形（4 スペースインデントのブロック内）の 2 行を書き換える。

変更前:

```
    | システム種別依存性 | 問題なし / 要是正→<是正パターン> | <前提の有無と内容> |
    | AIモデル/ツール依存性 | 問題なし / 要是正→<是正パターン> | <前提の有無と内容> |
```

変更後:

```
    | システム種別依存性 | 問題なし / 要是正→<是正パターン> | <前提の有無と内容。既存規範の引き写し箇所と引用元ゲートの引き継ぎ判定を箇所ごとに列挙（無ければ「引き写し箇所: なし」と明記）> |
    | AIモデル/ツール依存性 | 問題なし / 要是正→<是正パターン> | <前提の有無と内容。既存規範の引き写し箇所と引用元ゲートの引き継ぎ判定を箇所ごとに列挙（無ければ「引き写し箇所: なし」と明記）> |
```

- [ ] **Step 4: spec スナップショットのコードフェンス内へ同一の 2 編集を反映する**

`docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md` の「変更 1」コードフェンス内（```markdown ブロック）の対応箇所へ、Step 2 と同一の注記段落（観点 4 行の直後に空行を挟んで挿入）と Step 3 と同一の雛形 2 行書き換えを適用する。フェンス内の雛形は 4 スペースインデントのまま維持する。

- [ ] **Step 5: spec の関連 ADR 行へ ADR-0099 を追記する**

変更前（spec 5 行目）: `- **関連 ADR**: ADR-0079（本設計の決定）。是正パターンの参照元: ...`（行末まで現状維持）

行末に次を追記する: `。部分修正: ADR-0099（観点 2・3 の引用突合注記と雛形根拠欄の改定。2026-08-16）`

- [ ] **Step 6: 検証（期待値は等号）**

Run: `(Select-String -Path CONTRIBUTING.md -Pattern '引用箇所の列挙なしの自己判定では検出できない').Count; (Select-String -Path CONTRIBUTING.md -Pattern '引き写し箇所: なし').Count; (Select-String -Path CONTRIBUTING.md -Pattern '過剰適合の点検を実施し').Count`
Expected: `1` / `2` / `8`（8 は既存 spec の検証 3 の期待値。本編集はこの語句を含まないため不変であること）

Run: `(Select-String -Path docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md -Pattern '引用箇所の列挙なしの自己判定では検出できない').Count; (Select-String -Path docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md -Pattern '引き写し箇所: なし').Count; (Select-String -Path docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md -Pattern 'ADR-0099').Count`
Expected: `1` / `2` / `1`

- [ ] **Step 7: コミット**

```powershell
git add CONTRIBUTING.md docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md
git commit -m "docs: 過剰適合点検へ観点2・3の引用突合注記と雛形根拠欄を追加 (ADR-0099)" -- CONTRIBUTING.md docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md
```

---

### Task 2: ADR-0092 / ADR-0079 への部分修正追記

**Files:**
- Modify: `docs/records/decisions/0092-cycle-wide-consistency-check-before-adr-promotion.md`（Consequences 末尾）
- Modify: `docs/records/decisions/0079-overfitting-check-required-for-guideline-extensions.md`（Consequences 末尾）

- [ ] **Step 1: ADR-0092 の Consequences 末尾（「退役経路:」の行の後、`## 過剰適合点検` 見出しの前）へ 1 行追加する**

```
- 部分修正（ADR-0099・2026-08-16）: 検査観点 5 は名称を「引用の条件保存」から「引用の整合」へ改め、対象に同一 ADR 内の Context 実測と Considered Alternatives の対応を、判定に主張の向きの一致を、完了基準（引用箇所の列挙と 1 行ずつの判定）を加えた。本 ADR は現役のまま維持する（正本は `decision-log` スキル側）
```

- [ ] **Step 2: ADR-0079 の Consequences 末尾（最終 bullet の後）へ 1 行追加する**

```
- 部分修正（ADR-0099・2026-08-16）: 点検の観点リスト直後に観点 2・3 共通の引用突合注記を追加し、記録ブロック雛形の観点 2・3 根拠欄へ引き写し箇所の列挙（無ければ「引き写し箇所: なし」と明記）を加えた。本 ADR は現役のまま維持する（正本は CONTRIBUTING.md 側）
```

- [ ] **Step 3: 検証**

Run: `(Select-String -Path docs/records/decisions/0092-cycle-wide-consistency-check-before-adr-promotion.md,docs/records/decisions/0079-overfitting-check-required-for-guideline-extensions.md -Pattern '部分修正（ADR-0099').Count`
Expected: `2`

- [ ] **Step 4: コミット**

```powershell
git add docs/records/decisions/0092-cycle-wide-consistency-check-before-adr-promotion.md docs/records/decisions/0079-overfitting-check-required-for-guideline-extensions.md
git commit -m "docs: ADR-0092/0079 へ ADR-0099 による部分修正を追記" -- docs/records/decisions/0092-cycle-wide-consistency-check-before-adr-promotion.md docs/records/decisions/0079-overfitting-check-required-for-guideline-extensions.md
```

---

### Task 3: decision-log スキルの観点 5 書き換え＋version bump＋dist 再生成（同一コミット）

**Files:**
- Modify: `skills/decision-log/SKILL.md`（「サイクル全体整合検査」検査観点 5）
- Modify: `.claude-plugin/plugin.json` / `.claude-plugin/marketplace.json`（version 0.1.5 → 0.1.6）
- Regenerate: `dist/`（`scripts/build-dist.ps1`）

- [ ] **Step 1: 観点 5 の現行文言を実体確認する**

Run: `Select-String -Path skills/decision-log/SKILL.md -Pattern '引用の条件保存' | ForEach-Object {"$($_.LineNumber): $($_.Line)"}`
Expected: 1 行（L225 付近）

- [ ] **Step 2: 観点 5 を書き換える**

変更前:

```
5. **引用の条件保存**: 他文書の規範を参照・引き写した箇所で、引用元のゲート（適用条件・発動条件）を落として無条件化していないか
```

変更後:

```
5. **引用の整合**: 規範・実測を参照・引き写した箇所（他文書からの引用に加え、同一 ADR 内で Context が引用する実測と Considered Alternatives・Decision の各主張の対応を含む）で、(a) 引用元のゲート（適用条件・発動条件）を落として無条件化していないか、(b) 見送り理由・根拠として書かれた事実主張の向きが、引用元・Context の実測の内容と一致しているか（主張側が引用元を明示していない場合も対象とする）。完了基準: 参照・引き写し箇所と、昇格対象 ADR の「Context の実測 × 各 Considered Alternatives の評価」の対応を列挙し、(a)(b) の判定を 1 行ずつ書き出す
```

注意: 同ファイル内の「観点 1・2・3・5 は突合対象文書の全体を読み直す」（重複実施の抑止の段落）は番号参照のため変更しない。出所識別子は新文言に含まれないため記法規約違反は生じない（半角括弧 (a)(b) は識別子を含まず、観点 4 に既存の同型がある）。

- [ ] **Step 3: version bump**

`.claude-plugin/plugin.json` と `.claude-plugin/marketplace.json` の `"version": "0.1.5"` をどちらも `"version": "0.1.6"` へ書き換える（各ファイル 1 箇所。書き換え前に `Select-String -Path .claude-plugin/plugin.json,.claude-plugin/marketplace.json -Pattern '0\.1\.5'` で各 1 件であることを確認し、2 件以上なら対象を特定してから編集する）。

- [ ] **Step 4: 生成器の実行と両 -Check**

Run: `powershell -File scripts/build-dist.ps1`
Expected: exit 0（記法規約違反があれば非ゼロ終了する。違反が出たら Step 2 の文言を修正して再実行）

Run: `powershell -File scripts/build-dist.ps1 -Check; powershell -File scripts/sync-template.ps1 -Check`
Expected: どちらも exit 0

- [ ] **Step 5: 配布物の目視（機械判定が届かない 5 点）**

`dist/skills/decision-log/SKILL.md` の観点 5 付近を Read し、次を確認する: 括弧内に識別子以外の語が同居した残骸が無い / 空括弧が無い / 実在の固有名・自己参照（「本リポジトリ」等）が無い / 新文言が原文どおり残っている。

Run: `(Select-String -Path dist/skills/decision-log/SKILL.md -Pattern '引用の整合').Count; (Select-String -Path dist/skills/decision-log/SKILL.md -Pattern '引用の条件保存').Count`
Expected: `1` / `0`

- [ ] **Step 6: 検証（ソース側）**

Run: `(Select-String -Path skills/decision-log/SKILL.md -Pattern '引用の整合').Count; (Select-String -Path skills/decision-log/SKILL.md -Pattern '引用の条件保存').Count`
Expected: `1` / `0`

- [ ] **Step 7: コミット（ソース・version・dist を同一コミットに）**

```powershell
git add skills/decision-log/SKILL.md .claude-plugin/plugin.json .claude-plugin/marketplace.json dist/
git commit -m "feat: サイクル全体整合検査の観点5を「引用の整合」へ拡張、plugin 0.1.6 (ADR-0099)" -- skills/decision-log/SKILL.md .claude-plugin/plugin.json .claude-plugin/marketplace.json dist/
```

---

### Task 4: 全体検証

- [ ] **Step 1: 編集済み全ファイルの実体再読**

Task 1〜3 の全編集箇所を Read で読み直し、意図した文言と一致することを確認する（ツールの戻り値ではなく実体で確認。CLAUDE.md 検証規範）。

- [ ] **Step 2: 期待値の一括再検証**

Run:
```powershell
(Select-String -Path CONTRIBUTING.md -Pattern '引き写し箇所: なし').Count
(Select-String -Path docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md -Pattern '引き写し箇所: なし').Count
(Select-String -Path skills/decision-log/SKILL.md,dist/skills/decision-log/SKILL.md -Pattern '引用の整合').Count
(Select-String -Path docs/records/decisions/0092-cycle-wide-consistency-check-before-adr-promotion.md,docs/records/decisions/0079-overfitting-check-required-for-guideline-extensions.md -Pattern '部分修正（ADR-0099').Count
git status --short
```
Expected: `2` / `2` / `2` / `2`、git status は inbox 4 ファイル（`docs/conversation_log.md`・`docs/inbox/` 3 件）以外に未コミット差分なし

---

## サイクル完了時の後処理（plan タスク外。メインセッションで実施）

- ADR-0099 の Accepted 昇格（実装完了・検証後）: `decision-log`「承認の昇格」に従い、サイクル全体整合検査（この時点では改定後の観点 5 を適用）→ 粒度点検 → Status 更新・インデックス更新・コミット。マイルストーン名に `Accepted 昇格` を含め、消化記録へ `cyclecheck=` を記録
- Issue-0086 / Issue-0066 の close: Status・Closed 日付・結論（ADR-0099）を記入し、`docs/working/issues/README.md` の該当 2 行を closed へ更新。フォルダ昇格なしのため移設判定は非該当
- 配布反映: ユーザーへ `/plugin marketplace update ai-driven-dev-principles`（0.1.6）を依頼し、改定スキル本文と repo 実ファイルを突合（Issue-0044 の運用知見）
