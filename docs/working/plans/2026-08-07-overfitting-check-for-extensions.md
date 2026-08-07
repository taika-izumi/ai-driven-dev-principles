# ガイドライン拡張の過剰適合点検（ADR-0079）実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ガイドライン拡張の全経路に過剰適合点検（4 観点）と記録義務を導入する（spec: `docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md` v2 / ADR-0079）

**Architecture:** ルールの正本を CONTRIBUTING.md の横断節に新設し、9 シナリオと 2 スキル（extend-guidelines / worklog-skillify）から参照配線する。スナップショット仕様書 1 件を同期し、レビューで発見された既存の穴 3 件を課題起票する。

**Tech Stack:** Markdown 文書編集のみ（コードなし）。検証は PowerShell `Select-String`（全コマンド実行可能性検査済み 2026-08-07。現状値: CMD1〜4,7 = 0 件、CMD6 = 8 行）。

**編集上の注意（全タスク共通）:**
- コミットは必ずパス指定（`git commit -m "..." -- <paths>`）。inbox の untracked 4 件を巻き込まない（Issue-0020）
- Edit の old_string は本計画の記載どおり正確に使う。重複文字列は 2 行コンテキストで一意化してある（Task 2 (f)）
- 検証の期待値はすべて等号。1 件でもずれたら原因を特定してから進む

---

### Task 1: CONTRIBUTING.md — リード文改訂と横断節の新設

**Files:**
- Modify: `CONTRIBUTING.md`（「設計思想」節末尾〜「シナリオ: 原則を追加・変更するとき」の間）

- [ ] **Step 1: リード文を書き換え、直後に横断節を挿入する**

Edit（old_string）:

```
拡張したい場合は、以下のシナリオから該当するものを読むこと。

## シナリオ: 原則を追加・変更するとき
```

Edit（new_string）— リード文改訂＋横断節全文（spec v2 変更 1 と同一）:

```
拡張したい場合は、まず「全シナリオ共通: 過剰適合の点検」を読み、そのうえで以下のシナリオから該当するものを読むこと。

## 全シナリオ共通: 過剰適合の点検

### 背景

本ガイドラインは、開発対象とするシステムの種類・性質を限定せず、利用する AI モデルも限定しないことを前提に設計されている。特定のシステム種別に過剰適合した手順・ルールは他種のシステム開発で非効率・不合理になり、特定の AI モデルに過剰適合した手順・ルールは将来のモデルの性能発揮を阻害する（ADR-0079）。

### 適用対象

規範・手順・観点を追加または強化する拡張のすべて（原則の追加・変更、CLAUDE.md の規範追加、スキルの新規作成・改定）。「強化」とは、拘束的な文（「〜すること」「〜しないこと」「必須」「禁止」等）の新規追加、または既存規範の適用条件の拡大を指す。規範のレイヤー間移設（例: 棚卸しの「退避」で CLAUDE.md からスキルへ移す）も移設先への追加として対象に含む。誤記修正・表現の圧縮・参照の張り替えなど、規範の内容を変えない変更は対象外。

### 点検の観点

設計承認前（spec を作る場合は spec 確定前）に、以下の 4 観点を点検する:

1. **出所の偏り**: 根拠となった観測・課題・worklog エントリの出所プロジェクト数とモデル世代を実際に数える。単一プロジェクト・単一モデル世代の教訓を、無条件の拘束的規範へ昇格させていないか。根拠エントリを持たない拡張（実測に基づかない拡張）は判定を「該当なし」とし、実測なしに一般規範として妥当と言える理由を根拠欄に必ず記載する
2. **システム種別依存性**: 特定のシステム種類・技術スタック・テスト文化・開発体制を暗黙の前提にしていないか。前提が崩れるプロジェクトでもその規範は合理的か
3. **AI モデル/ツール依存性**: 特定モデル・ツールの挙動・制約（既知バグ、コンテキスト制約、ツール仕様）を暗黙の前提にしていないか。より高性能な将来モデルの性能発揮を制限する方向に働かないか
4. **退役経路**: 追加する規範が不要になったことを判定する経路（エージェントが観測可能な条件、または「ユーザーが判断し指示した時点」への判断主体の明示的な移譲）が定義されているか

### 是正パターン

過剰適合の芽が見つかった場合、以下の型で汎用性を回復する:

- **適用例への降格**: 拘束的規範ではなく「発火条件に紐づく適用例」として記載し、出所（プロジェクト・根拠 id）を明記する（ADR-0073 の型）
- **観測可能な発動条件でゲート**: 前提が成立する場合に限り適用されるよう、エージェントが観測できる発動条件を付ける。モデル依存の規範は事象確認済みモデルを列挙し、未確認モデルには適用しない（ADR-0032 の型。実例: CLAUDE.md の構造化質問ツール規範。CLAUDE.md への規範追加では「CLAUDE.md を更新するとき」手順のゲート必須と同一の要求である）
- **根拠と世代＋退役経路**: 根拠エントリ id と観測されたモデル世代を添え、前提が消えたときに退役させる経路を定義する（ADR-0073 の型）
- **規範化の見送り・適用範囲の降格・撤回**: 汎用側に便益が無ければ汎用規範として書かない。観測記録（worklog / issue）に留める、配布範囲をプロジェクト固有側へ降格する（`worklog-skillify` のスコープ降格を含む）、既存の固定条項を撤回する（ADR-0073 の型）

### 記録義務

点検結果を次の定型ブロックで成果物に残す。記録先は次の 2 つに固定する:

- spec を作る拡張 → spec の節「過剰適合点検（ADR-0079）」
- spec を作らない拡張 → 当該 ADR の末尾に独立節「## 過剰適合点検（ADR-0079）」として記載する。規範・手順・観点を追加または強化する拡張には `decision-log` の強トリガー（ガイドライン・ルールの追加・変更）により ADR が必ず存在する。点検ブロックは「下した決定」ではない付随記録であり、この独立節への配置を ADR-0019 の記述規律の例外として認める（Context / Consequences には書かない）

**執行点**: 拡張 spec / 拡張 ADR をコミットする直前に点検ブロックの存在を確認する。無ければコミットしない。**再点検**: 点検後に規範の文言・適用範囲を追加・変更した場合は、当該差分について点検を再実施し、点検ブロックを更新する。

    ### 過剰適合点検（ADR-0079）

    | 観点 | 判定 | 根拠 |
    |------|------|------|
    | 出所の偏り | 問題なし / 該当なし / 要是正→<是正パターン> | <出所プロジェクト数・件数・モデル世代の実数。該当なしの場合は実測なしで妥当とする理由> |
    | システム種別依存性 | 問題なし / 要是正→<是正パターン> | <前提の有無と内容> |
    | AIモデル/ツール依存性 | 問題なし / 要是正→<是正パターン> | <前提の有無と内容> |
    | 退役経路 | 定義済み / 不要（理由） | <退役条件、または判断主体の移譲先> |

### 本点検自体の退役規範

点検が長期にわたり全拡張で「問題なし / 該当なし」のみとなり、かつ過剰適合の同型事象（ユーザー指摘・worklog delta）が中央ストアへ現れない場合、本点検の簡素化・退役を候補としてユーザーへ提案する。判断はユーザーが行う。

## シナリオ: 原則を追加・変更するとき
```

- [ ] **Step 2: 検証**

Run: `"CMD1: " + (Select-String -Path CONTRIBUTING.md -Pattern '^## 全シナリオ共通: 過剰適合の点検').Count; "CMD2: " + (Select-String -Path CONTRIBUTING.md -Pattern '### 過剰適合点検（ADR-0079）').Count`
Expected: `CMD1: 1` / `CMD2: 1`

- [ ] **Step 3: コミット**

```powershell
git add CONTRIBUTING.md && git commit -m "docs: CONTRIBUTING に横断節「全シナリオ共通: 過剰適合の点検」を新設 (ADR-0079)" -- CONTRIBUTING.md
```

---

### Task 2: CONTRIBUTING.md — 9 シナリオへの配線

**Files:**
- Modify: `CONTRIBUTING.md`（8 シナリオ + ADR 記録シナリオの記述規律）

- [ ] **Step 1: チェックリスト参照行を 6 箇所へ追加（(a)）**

以下 6 つの Edit を行う。各 old_string の行の直後に、次の 1 行（6 箇所とも同一）を追加する:

```
- 過剰適合の点検を実施し、点検ブロックを記録したか（「全シナリオ共通: 過剰適合の点検」/ ADR-0079）
```

| # | シナリオ | old_string（この行の直後に追加） |
|---|---------|----------------------------------|
| ① | 原則を追加・変更するとき | `- リスクスケーリングの分類（常時適用 or リスク比例）を決めたか` |
| ② | Skillを新規作成するとき | `` - `template.manifest` には skills/ を追加していないか（ADR-0016 で除外規約） `` |
| ③ | start-work を変更するとき | `- 横断関心の追加が他スキルとの責務重複を生んでいないか` |
| ④ | feature-block-design を変更するとき | `- 粒度ガイドラインがパラダイムを問わず適用可能な抽象度になっているか` |
| ⑤ | retrospective を変更するとき | `` - `docs/records/retrospectives/README.md` への行追加が省略不可の工程として維持されているか（ADR-0056） `` |
| ⑥ | 課題に対策するとき | `- 取り込みサイクル完了後の retrospective で「前回課題への対策結果」を達成サマリまたは「既存課題の再発・進展」に明示的に書く準備ができているか` |

- [ ] **Step 2: CLAUDE.md 更新シナリオの手順へ工程を挿入（(b)）**

Edit（old_string）:

```
5. **追加後の確認**: 追加後に `scripts/sync-template.ps1` を実行する（計測が自動で走る。閾値超過の警告が出たら「CLAUDE.md を棚卸しするとき」の実施を検討する）
```

Edit（new_string）:

```
5. **過剰適合の点検を実施し、点検ブロックを記録する**（「全シナリオ共通: 過剰適合の点検」/ ADR-0079。是正パターン「観測可能な発動条件でゲート」は前項のゲート必須と同一の要求）
6. **追加後の確認**: 追加後に `scripts/sync-template.ps1` を実行する（計測が自動で走る。閾値超過の警告が出たら「CLAUDE.md を棚卸しするとき」の実施を検討する）
```

- [ ] **Step 3: Skill 新規作成シナリオの改題と改定カバー文（(c)）**

Edit 1（old_string → new_string）:

```
## シナリオ: Skillを新規作成するとき
```

```
## シナリオ: Skillを新規作成・改定するとき

既存スキルの改定で規範・手順・観点を追加または強化する場合も本シナリオに従う（専用シナリオを持つ start-work / feature-block-design / retrospective はそれぞれのシナリオを優先する）。
```

- [ ] **Step 4: 棚卸しシナリオへ条件付き行を追加（(d)）**

old_string の行 `- （任意）重要度の高い規範ほど前方に配置されているか（先に書かれた指示ほど守られやすい傾向の報告がある。ADR-0040 の Context 参照）` の直後に追加:

```
- 退避（Layer 3 への移設）を行った場合、過剰適合の点検を実施し、点検ブロックを記録したか（ADR-0079。移設は移設先への規範追加である）
```

- [ ] **Step 5: ADR 記録シナリオの記述規律へ 1 行追加（(e)）**

old_string の行 `- 撤去基準・発動条件・適用条件などの判定条件は、実行主体であるエージェントが**観測・実行できる事実**で書く。エージェントが判定できない条件は「ユーザーが判断し指示した時点」のように判断主体をユーザーへ明示的に移す（ADR-0032）。` の直後に追加:

```
- spec を作らない拡張（規範・手順・観点の追加または強化）の ADR には、末尾に独立節「## 過剰適合点検（ADR-0079）」として点検ブロックを含めること（「下した決定」ではない付随記録の例外配置。Context / Consequences には書かない）。
```

- [ ] **Step 6: スキル改定 3 シナリオの ADR 任意文言を改訂（(f)）**

Edit 1（start-work。同一文が feature-block-design にもあるため 2 行で一意化）:

old:
```
1. ADRを作成して変更理由を記録する（重要な変更の場合）
2. `skills/start-work/SKILL.md` を更新する
```
new:
```
1. ADRを作成して変更理由を記録する（規範・手順・観点を追加または強化する変更では必須。それ以外は重要な変更の場合）
2. `skills/start-work/SKILL.md` を更新する
```

Edit 2（feature-block-design）:

old:
```
1. ADRを作成して変更理由を記録する（重要な変更の場合）
2. `skills/feature-block-design/SKILL.md` を更新する
```
new:
```
1. ADRを作成して変更理由を記録する（規範・手順・観点を追加または強化する変更では必須。それ以外は重要な変更の場合）
2. `skills/feature-block-design/SKILL.md` を更新する
```

Edit 3（retrospective）:

old:
```
1. ADR を作成して変更理由を記録する（重要な変更の場合。新セクション追加など出力構造に影響するものは必須）
```
new:
```
1. ADR を作成して変更理由を記録する（規範・手順・観点を追加または強化する変更、および新セクション追加など出力構造に影響するものは必須。それ以外は重要な変更の場合）
```

- [ ] **Step 7: 検証**

Run: `"CMD3: " + (Select-String -Path CONTRIBUTING.md -Pattern '過剰適合の点検を実施し').Count; "CMD4: " + (Select-String -Path CONTRIBUTING.md -Pattern 'ADR-0079').Count; "改題: " + (Select-String -Path CONTRIBUTING.md -Pattern '^## シナリオ: Skillを新規作成・改定するとき').Count`
Expected: `CMD3: 8`（チェックリスト 6 + 棚卸し 1 + CLAUDE.md 手順 1）/ `CMD4: 13`（横断節 4 + チェックリスト 6 + CLAUDE.md 手順 1 + 棚卸し 1 + ADR 記述規律 1）/ `改題: 1`

- [ ] **Step 8: コミット**

```powershell
git add CONTRIBUTING.md && git commit -m "docs: 過剰適合点検を 9 シナリオへ配線（チェックリスト・工程・改題・ADR必須化）(ADR-0079)" -- CONTRIBUTING.md
```

---

### Task 3: extend-guidelines スキルへ点検工程を追加

**Files:**
- Modify: `skills/extend-guidelines/SKILL.md`

- [ ] **Step 1: ヒアリング選択肢に改定を追加**

old:
```
- 原則を追加・変更したい
- CLAUDE.md を更新したい
- 新しいSkillを作成したい
```
new:
```
- 原則を追加・変更したい
- CLAUDE.md を更新したい
- 新しいSkillを作成したい
- 既存のSkillを改定したい
```

- [ ] **Step 2: 独立工程「5. 確定前の過剰適合点検」を挿入し旧 5 を 6 へ renumber**

old:
```
### 5. テンプレートの同期を案内する
```
new:
```
### 5. 確定前の過剰適合点検

設計承認の前に、CONTRIBUTING.md「全シナリオ共通: 過剰適合の点検」を実施し、点検結果の定型ブロックを spec（spec を作らない場合は ADR 末尾の独立節「## 過剰適合点検（ADR-0079）」）へ記録する。点検ブロックの無い拡張 spec / 拡張 ADR はコミットしないこと（ADR-0079）。

### 6. テンプレートの同期を案内する
```

- [ ] **Step 3: 検証**

Run: `(Select-String -Path skills/extend-guidelines/SKILL.md -Pattern 'ADR-0079').Count; (Select-String -Path skills/extend-guidelines/SKILL.md -Pattern '^### \d\.').Count`
Expected: `1`（点検工程の行）/ `6`（手順見出し `### 1.`〜`### 6.` の 6 件。実装前は 5 件）

- [ ] **Step 4: コミット**

```powershell
git add skills/extend-guidelines/SKILL.md && git commit -m "skills: extend-guidelines に確定前の過剰適合点検工程と改定入口を追加 (ADR-0079)" -- skills/extend-guidelines/SKILL.md
```

---

### Task 4: worklog-skillify スキルへ出所点検を追加

**Files:**
- Modify: `skills/worklog-skillify/SKILL.md`

- [ ] **Step 1: 手順 2 と 3 の間に出所点検を挿入し renumber**

old:
```
3. **writing-skills へ委譲**してスキルを作成/拡張する。`references/skill-authoring-techniques.md` を併用し、description 最適化と定量 eval ループを回す（**Skill Creator は実行時ロードしない**。ADR-0046 の設計時借用）
4. **汎用パスは既存フローへ橋渡し**: 「Issue → `extend-guidelines` → スキル作成」の本 repo 既存フローに合流させる
```
new:
```
3. **出所点検**（汎用スコープ、および本 repo（ai-driven-dev-principles）で実行し CLAUDE.md 追記へ振り分ける場合。本 repo の CLAUDE.md は template 経由で配布されるため）: 根拠エントリの出所プロジェクト数・モデル世代を数える。単一プロジェクトまたは単一モデル世代に偏る場合、CONTRIBUTING.md「全シナリオ共通: 過剰適合の点検」の是正パターン（適用例への降格 / 発動条件ゲート / 根拠と世代＋退役経路 / 見送り・スコープ降格）の適用をユーザーへ提示する（ADR-0079）
4. **writing-skills へ委譲**してスキルを作成/拡張する。`references/skill-authoring-techniques.md` を併用し、description 最適化と定量 eval ループを回す（**Skill Creator は実行時ロードしない**。ADR-0046 の設計時借用）
5. **汎用パスは既存フローへ橋渡し**: 「Issue → `extend-guidelines` → スキル作成」の本 repo 既存フローに合流させる
```

続けて旧 5 を 6 へ:

old:
```
5. **台帳追記**: 作成/拡張完了後、`processed.jsonl` へ確定結果を追記する
```
new:
```
6. **台帳追記**: 作成/拡張完了後、`processed.jsonl` へ確定結果を追記する
```

- [ ] **Step 2: 関連 ADR へ 1 行追加**

old:
```
- ADR-0046（writing-skills 既定・Skill Creator 設計時借用・実行環境ガード）
```
new:
```
- ADR-0046（writing-skills 既定・Skill Creator 設計時借用・実行環境ガード）
- ADR-0079（出所点検）
```

- [ ] **Step 3: 検証**

Run: `(Select-String -Path skills/worklog-skillify/SKILL.md -Pattern 'ADR-0079').Count; (Select-String -Path skills/worklog-skillify/SKILL.md -Pattern '^\d+\. ').Count`
Expected: `2`（手順ステップ + 関連 ADR 行）/ `9`（「ガード発火時の対応」の 1〜3 ＋「手順」の 1〜6。実装前は 8）。あわせて「## 手順」節内の番号が 1〜6 の連番であることを目視確認する（他節の番号付きリストは対象外）

- [ ] **Step 4: コミット**

```powershell
git add skills/worklog-skillify/SKILL.md && git commit -m "skills: worklog-skillify に出所点検ステップを追加 (ADR-0079)" -- skills/worklog-skillify/SKILL.md
```

---

### Task 5: スナップショット仕様書の同期

**Files:**
- Modify: `docs/current/specs/2026-07-17-worklog-skill-pipeline/04-skill3-skillify.md`

- [ ] **Step 1: サブ機能へ出所点検を挿入し renumber**

old:
```
4. **委譲実行**: writing-skills へ委譲してスキルを作成/拡張。Skill Creator 設計時借用の references（description 最適化・eval ループ）を併用。**実行時に Skill Creator はロードしない**（エンジンは writing-skills のみ）
5. **台帳追記**: 作成/拡張完了後、`processed.jsonl` へ確定結果（skillified＝新規作成 / merged＝既存スキルへ統合）を追記し、対応する `adopted` エントリの状態を確定させる（追記専用 JSONL のため後続レコードで遷移を表現。読み側は最新レコードの outcome を採用）
```
new:
```
4. **出所点検**: 汎用スコープ、および本 repo で実行し CLAUDE.md 追記へ振り分ける場合、根拠エントリの出所プロジェクト数・モデル世代を数え、単一出所に偏る場合は CONTRIBUTING.md「全シナリオ共通: 過剰適合の点検」の是正パターンの適用をユーザーへ提示（ADR-0079）
5. **委譲実行**: writing-skills へ委譲してスキルを作成/拡張。Skill Creator 設計時借用の references（description 最適化・eval ループ）を併用。**実行時に Skill Creator はロードしない**（エンジンは writing-skills のみ）
6. **台帳追記**: 作成/拡張完了後、`processed.jsonl` へ確定結果（skillified＝新規作成 / merged＝既存スキルへ統合）を追記し、対応する `adopted` エントリの状態を確定させる（追記専用 JSONL のため後続レコードで遷移を表現。読み側は最新レコードの outcome を採用）
```

- [ ] **Step 2: 関連 ADR へ 1 行追加**

old:
```
- ADR-0046（writing-skills 既定・Skill Creator 設計時借用・実行環境ガード）
```
new:
```
- ADR-0046（writing-skills 既定・Skill Creator 設計時借用・実行環境ガード）
- ADR-0079（出所点検）
```

※ この old_string は `skills/worklog-skillify/SKILL.md` にも存在するが、Edit はファイル単位のため衝突しない。

- [ ] **Step 3: 検証**

Run: `(Select-String -Path docs/current/specs/2026-07-17-worklog-skill-pipeline/04-skill3-skillify.md -Pattern '出所点検').Count`
Expected: `2`（サブ機能 4 + 関連 ADR 行）

- [ ] **Step 4: コミット**

```powershell
git add docs/current/specs/2026-07-17-worklog-skill-pipeline/04-skill3-skillify.md && git commit -m "docs: 04-skill3-skillify 仕様書へ出所点検を同期 (ADR-0079)" -- docs/current/specs/2026-07-17-worklog-skill-pipeline/04-skill3-skillify.md
```

---

### Task 6: 課題起票 3 件（確定前レビューで発見された既存の穴）

**Files:**
- Create: `docs/working/issues/system/0058-legacy-contributing-gateway-spec-stale.md`
- Create: `docs/working/issues/flow/0059-adr-0065-gate-not-wired-into-worklog-skillify.md`
- Create: `docs/working/issues/flow/0060-claude-md-decision-triggers-missing-guideline-change.md`
- Modify: `docs/working/issues/README.md`

- [ ] **Step 1: Issue-0058 を作成**

`docs/working/issues/system/0058-legacy-contributing-gateway-spec-stale.md`:

```markdown
# Issue-0058: contributing-and-gateway 仕様書が旧名称・旧構成のまま陳腐化している

- **Status**: open
- **Opened**: 2026-08-07
- **起票元**: 2026-08-07 確定前レビュー（`pre-finalization-review` 実装整合性観点。ADR-0079 サイクル）
- **関連**: `docs/current/specs/2026-04-13-contributing-and-gateway-skill-design.md`、Issue-0008（旧型式の単一ファイル spec の維持方針が未定義）、Issue-0055（同型の仕様書陳腐化）

## 課題内容

`docs/current/specs/2026-04-13-contributing-and-gateway-skill-design.md` が「セクション3: copilot-instructions.md を更新するとき」等の旧名称・旧セクション構成（セクション 1〜5）のままであり、実際の CONTRIBUTING.md（シナリオ 10 個＋横断節）と大きく乖離している。「読むだけで現時点の全容が分かるスナップショット」というドキュメント運用規律を満たしていない。

ADR-0079 サイクルでは同サイクル起因の乖離のみ同期し（`04-skill3-skillify.md`）、本仕様書は既存の陳腐化のため対象外とした。

## 留意（対処を設計するときに参照すること）

- Issue-0008（旧型式 spec の維持・アーカイブ方針）と同時に扱うと、書き換え更新か廃止かの判断が一度で済む

## 検討状況

- 2026-08-07: 起票のみ

## 結論

（未定）
```

- [ ] **Step 2: Issue-0059 を作成**

`docs/working/issues/flow/0059-adr-0065-gate-not-wired-into-worklog-skillify.md`:

```markdown
# Issue-0059: ADR-0065 の適用条件設計ゲートが worklog-skillify に配線されていない

- **Status**: open
- **Opened**: 2026-08-07
- **起票元**: 2026-08-07 確定前レビュー（`pre-finalization-review` 敵対的観点。ADR-0079 サイクル）
- **関連**: ADR-0065、`skills/worklog-skillify/SKILL.md`、ADR-0079（出所点検。同じ位置＝スコープ確定後・委譲前に入る隣接ゲート）

## 課題内容

ADR-0065（Accepted）は「worklog-extract で採用した候補は根拠エントリの一覧をそのままスキルの規範へ写さず、スキル化の前に『常時適用する項目』と『タスクの型で条件発火する項目』の切り分けを設計し ADR として確定させる」と定めるが、`skills/worklog-skillify/SKILL.md` にはこの工程が書かれておらず、関連 ADR 一覧にも 0065 が無い。Accepted 決定がスキル手順に反映されていない。

ADR-0079 の出所点検は同じ位置（スコープ確定後・writing-skills 委譲前）に入るため、対処時は 1 工程への統合を検討できる。

## 検討状況

- 2026-08-07: 起票のみ（ADR-0079 サイクルではスコープ外と明記して見送り）

## 結論

（未定）
```

- [ ] **Step 3: Issue-0060 を作成**

`docs/working/issues/flow/0060-claude-md-decision-triggers-missing-guideline-change.md`:

```markdown
# Issue-0060: CLAUDE.md の意思決定即時記録トリガーに「ガイドライン・ルールの追加・変更」が無い

- **Status**: open
- **Opened**: 2026-08-07
- **起票元**: 2026-08-07 確定前レビュー（`pre-finalization-review` 敵対的観点。ADR-0079 サイクル）
- **関連**: `CLAUDE.md`「意思決定の即時記録（継続適用）」、`skills/decision-log/SKILL.md` 強トリガー 5、ADR-0079（記録義務が「拡張には ADR が必ず存在する」ことを前提にする）

## 課題内容

`CLAUDE.md` の「意思決定の即時記録」が列挙するトリガーは 4 件（複数選択肢の比較 / 方針変更 / スコープ・優先度 / アーキテクチャ）で、「ガイドライン・ルールの追加・変更」を含まない。これを含むのは `decision-log` スキルの強トリガー 5 のみで、decision-log が呼ばれない限り読まれない。ADR-0079 の記録義務は「規範を追加・強化する拡張には ADR が必ず存在する」ことを decision-log の強トリガーに依存して前提にしており、CLAUDE.md 側との不整合が残っている。

CLAUDE.md の変更は template 経由で配布先全プロジェクトへ波及し、サイズ事前判定（ADR-0040）を要するため、ADR-0079 サイクルでは対象外とした。

## 検討状況

- 2026-08-07: 起票のみ

## 結論

（未定）
```

- [ ] **Step 4: インデックスへ 3 行追加**

`docs/working/issues/README.md` の system テーブル末尾行 `| [0055](system/0055-specs-relative-adr-links-broken.md) | 仕様書内から ADR を相対パスで参照しているリンクが壊れている | open | 2026-08-07 |` の直後に:

```
| [0058](system/0058-legacy-contributing-gateway-spec-stale.md) | contributing-and-gateway 仕様書が旧名称・旧構成のまま陳腐化している | open | 2026-08-07 |
```

flow テーブル末尾行 `| [0057](flow/0057-subagent-report-identifiers-relayed-without-verification.md) | サブエージェントの完了報告に含まれる識別子を検証せず後続へ転記する経路がある | open | 2026-08-07 |` の直後に:

```
| [0059](flow/0059-adr-0065-gate-not-wired-into-worklog-skillify.md) | ADR-0065 の適用条件設計ゲートが worklog-skillify に配線されていない | open | 2026-08-07 |
| [0060](flow/0060-claude-md-decision-triggers-missing-guideline-change.md) | CLAUDE.md の意思決定即時記録トリガーに「ガイドライン・ルールの追加・変更」が無い | open | 2026-08-07 |
```

- [ ] **Step 5: 検証**

Run: `(Select-String -Path docs/working/issues/README.md -Pattern '005[89]|0060').Count`
Expected: `3`

- [ ] **Step 6: コミット**

```powershell
git add docs/working/issues/system/0058-legacy-contributing-gateway-spec-stale.md docs/working/issues/flow/0059-adr-0065-gate-not-wired-into-worklog-skillify.md docs/working/issues/flow/0060-claude-md-decision-triggers-missing-guideline-change.md docs/working/issues/README.md && git commit -m "issues: 0058-0060 を起票（確定前レビューで発見された既存の穴 3 件）" -- docs/working/issues
```

---

### Task 7: 全体検証

- [ ] **Step 1: 検証 1〜7 を一括再実行**

Run:
```powershell
"CMD1: " + (Select-String -Path CONTRIBUTING.md -Pattern '^## 全シナリオ共通: 過剰適合の点検').Count
"CMD2: " + (Select-String -Path CONTRIBUTING.md -Pattern '### 過剰適合点検（ADR-0079）').Count
"CMD3: " + (Select-String -Path CONTRIBUTING.md -Pattern '過剰適合の点検を実施し').Count
"CMD4: " + (Select-String -Path CONTRIBUTING.md -Pattern 'ADR-0079').Count
Select-String -Path skills/extend-guidelines/SKILL.md,skills/worklog-skillify/SKILL.md -Pattern 'ADR-0079' | Group-Object Filename | Format-Table Name,Count
"CMD7: " + (Select-String -Path docs/current/specs/2026-07-17-worklog-skill-pipeline/04-skill3-skillify.md -Pattern '出所点検').Count
```
Expected: CMD1=1 / CMD2=1 / CMD3=8 / CMD4=13 / SKILL.md グループ: extend-guidelines=1・worklog-skillify=2 / CMD7=2

- [ ] **Step 2: git status でブランチ・未コミットを確認**

Run: `git status --short; git log --oneline -8`
Expected: inbox の untracked 4 件のみ残置。Task 1〜6 の 6 コミットが積まれている

---

### Task 8: プラグイン更新と反映突合（ユーザー協働）

- [ ] **Step 1: ユーザーへ `/plugin marketplace update ai-driven-dev-principles` の実行を依頼する**（AI からは実行不可。ADR-0055 / Issue-0044）

- [ ] **Step 2: 反映突合**

update 完了後、`extend-guidelines` スキルを起動して返る本文に「### 5. 確定前の過剰適合点検」が含まれることを、repo 実ファイルと突合して確認する（キャッシュ参照では判定できない。Issue-0044 の実測知見）

---

### Task 9: ADR-0079 の Accepted 昇格

- [ ] **Step 1: 粒度点検**（ADR-0059/0060: タイトル「ガイドライン拡張の全経路に過剰適合点検を課し、点検結果の記録を義務化する」が本文の全決定に答えているか確認）

- [ ] **Step 2: Status を Proposed → Accepted へ更新**（`docs/records/decisions/0079-overfitting-check-required-for-guideline-extensions.md` と `docs/records/decisions/README.md` の両方）

- [ ] **Step 3: コミット**

```powershell
git add docs/records/decisions/0079-overfitting-check-required-for-guideline-extensions.md docs/records/decisions/README.md && git commit -m "adr: 0079 を Accepted へ昇格（過剰適合点検の実装・検証完了）" -- docs/records/decisions/0079-overfitting-check-required-for-guideline-extensions.md docs/records/decisions/README.md
```
