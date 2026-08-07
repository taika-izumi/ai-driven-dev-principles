# 確定前レビューの提示規則（ADR-0080）実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ADR-0080 が定める確定前レビューの提示規則（確定点の定義・推奨判定・差分明示・適用例・判定材料の記録）を、4 スキル・README・関連 ADR 2 件へ実装し、Issue-0062 を close する。

**Architecture:** 判定規則の正本は `skills/start-work/SKILL.md` Phase 2（判定が行われ、その時点でロードされている場所）に置く。`skills/pre-finalization-review/SKILL.md` はレビューの実施手順と適用例を持つ。`feature-block-design` の非該当終了時の推奨文言と `session-handoff` の記録規範を、新しい提示点・記録要求に合わせて改める。発火条件の判定文はスキル本文へインライン展開し（配布先プロジェクトから本 repo の ADR / CONTRIBUTING.md は参照できない）、ADR 番号は出所注記に留める。

**Tech Stack:** Markdown（スキル定義）、PowerShell / grep（検証）、git（パス指定コミット）

**編集上の注意（全タスク共通）:**
- Edit の `old_string` は本計画の引用どおり正確に使う。1 件でもずれたら原因を特定してから進む（ファイルが既に別タスクで変更されている可能性がある）
- コミットは必ずパス指定（`git add <paths>` → `git commit -F <絶対パスの一時ファイル> -- <paths>`）。`docs/inbox/` と `docs/conversation_log.md` は未追跡のまま残す対象で、巻き込んではならない（Issue-0020）
- マルチラインのコミットメッセージは絶対パスの一時ファイルへ書いて `-F` で渡す（`$TMPDIR` は未設定。スクラッチパッドの絶対パスを使う。Issue-0015）
- `scripts/sync-template.ps1` は実行しない。本計画は `skills/` と `docs/records/` と `README.md` しか触らず、template 対象（`CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md`）を変更しない（ADR-0016）

---

## File Structure

| ファイル | 責務 | 本計画での変更 |
|---|---|---|
| `skills/start-work/SKILL.md` | ワークフローのオーケストレーション。**確定前レビュー提示規則の正本** | Phase 2 の提示規範 1 行を、確定点定義・推奨判定・差分明示の規則へ置き換え（Task 1） |
| `skills/pre-finalization-review/SKILL.md` | 確定前レビューの実施手順 | frontmatter description・「いつ使うか」・適用例（欠陥クラス 3 種）・根拠と世代を更新（Task 2） |
| `skills/feature-block-design/SKILL.md` | 機能ブロック分割 | 適用要否判定の非該当終了時の推奨文言を、確定前レビュー提示を経由する形へ（Task 3） |
| `skills/session-handoff/SKILL.md` | ハンドオフ管理 | update にレビュー結果の併記、finalize の「圧縮しないもの」に追加（Task 4） |
| `README.md` | 人間向けスキル索引 | `pre-finalization-review` の説明を新しい提示規則に合わせる（Task 5） |
| `docs/records/decisions/0067-*.md` / `0072-*.md` | 既存 ADR | Consequences へ部分修正の追記（Status は Accepted 維持）（Task 6） |
| `docs/working/issues/flow/0062-*.md` / `0006-*.md` / `README.md` | 課題管理 | 0062 を close、0006 に本サイクルの知見を追記（Task 7） |
| `docs/records/decisions/0080-*.md` / `README.md` | 本サイクルの ADR | Proposed → Accepted（Task 8） |

---

### Task 1: start-work Phase 2 へ判定規則の正本を実装する

**Files:**
- Modify: `skills/start-work/SKILL.md`（Phase 2 の末尾、現行 79〜81 行付近）

- [ ] **Step 1: 変更前の現行文言を確認する**

Run:
```powershell
Select-String -Path skills\start-work\SKILL.md -Pattern "確定前レビュー" -Context 2,2
```
Expected: 1 件ヒット。80 行目の「`superpowers:writing-plans` または `feature-block-design` が完了した直後は、確定前レビュー（`pre-finalization-review`）の実施を次手の選択肢として毎回提示する（実施はユーザー判断。ADR-0072）。」が表示される（Phase 2 マッピング表の行にも「pre-finalization-review」が現れるため、Context 付きで両者を区別すること）

- [ ] **Step 2: 提示規範の 1 行を規則本体へ置き換える**

`old_string`（1 行、正確に一致させる）:
```
`superpowers:writing-plans` または `feature-block-design` が完了した直後は、確定前レビュー（`pre-finalization-review`）の実施を次手の選択肢として毎回提示する（実施はユーザー判断。ADR-0072）。
```

`new_string`:
```
確定前レビュー（`pre-finalization-review`）は、下記「確定前レビューの提示規則」に従って提示する（実施の判断はユーザー。ADR-0072 / ADR-0080）。
```

- [ ] **Step 3: Phase 2 の直後に規則の節を新設する**

`skills/start-work/SKILL.md` の Phase 2 末尾（`選択されたスキルへ delegate する。` の直後、`### 横断的ラッパー（全スキル実行の前後で適用）` の直前）に、次の節を挿入する。

`old_string`:
```
選択されたスキルへ delegate する。

### 横断的ラッパー（全スキル実行の前後で適用）
```

`new_string`:
```
選択されたスキルへ delegate する。

### 確定前レビューの提示規則（ADR-0080）

確定前レビュー（`pre-finalization-review`）の提示は、以下の 2 つの確定点で**毎回**行う（発動の判断はユーザーに残す。ADR-0072）。以下は提示内の**推奨順位**の規則である。

**1. 確定点**

| 確定点 | 到達時点 |
|---|---|
| spec 確定点 (a) | `feature-block-design` が適用され、同スキルが完了したとき |
| spec 確定点 (b) | `feature-block-design` が適用要否判定で非該当終了したとき（対象は直前に確定した brainstorming の設計文書。設計がファイル化されない場合はユーザーが設計を承認した発言をもって確定とみなす） |
| spec 確定点 (c) | 設計文書ファイルを作らない拡張で、設計を確定させた ADR ドラフトをコミットする直前（ADR が設計文書を兼ねる型） |
| plan 確定点 | `superpowers:writing-plans` が完了したとき |

brainstorming の完了直後には提示しない（`feature-block-design` の適用要否がまだ判定されておらず、確定点が (a)(b) のどちらの型か決まらないため）。brainstorming 自体を省略する小規模経路では spec 確定点は生じず、plan 確定点のみとなる。

**2. 推奨判定**

確定しようとする成果物が記述する**変更対象**に、将来の作業・挙動を拘束する規範・手順文書——原則、エージェント向け指示文書、スキル、プロセスルール、運用手順書・規約、出力構造を規定するテンプレート・雛形——の新設・改定が含まれ、**かつその内容が独立レビューを受けていない**場合、**フルレビュー（3 観点）を選択肢の先頭に置き「（推奨）」を付す**。推奨理由として「この型の成果物には実行による安全網が無く、欠陥は数サイクル後まで潜伏する」旨を添える。見送り・他の次手も必ず並記する。

判定の但し書き:

- 誤記修正・表現の圧縮・参照の張り替えのみの変更は対象に数えない
- plan 自身のタスク遂行指示・検証手順の文言は「規範・手順文書」に数えない（確定後に成果物として残る文書ではないため）
- レビュー指摘を反映した改訂差分は「未レビューの内容」に数えない（同一確定点での再発火を止めるため）。差分の再確認の要否はユーザー判断とし、選択肢として並記する
- 上流の spec がその確定時点で独立レビューを受けている場合、そこから写像された内容はレビュー済みとして扱う（サイクル・セッションを跨いでよい）
- 判定に迷う場合は「未レビューの規範内容を含む」側（フル推奨）へ倒す
- 該当しない場合も提示は行う。確定前レビューを選択肢に含め、推奨順位は当該サイクルの他の次手との比較で判断する（CLAUDE.md「ユーザーへの質問と意思決定要求」の推奨提示規範に従う）

**3. 差分明示**

推奨判定が真になったサイクルの各確定点では、「本サイクルで何がレビュー済みで、この成果物の何が未レビューか」を提示に含める（実施判断はユーザーに残るため、その判断材料を供給する）。上流 spec がレビュー済みで当該 plan がその写像である場合は、「写像欠落（spec 要件が plan から脱落すること）は独立レビューでのみ捕捉できる」旨を添える。差分明示を伴う提示は長文になるため、構造化質問ツールは使わず、説明と番号付き選択肢をテキストのみのターンで提示する（CLAUDE.md「ユーザーへの質問と意思決定要求」）。

**4. 判定材料の記録**

確定点を通過したら、提示結果（フル実施 / 差分再確認 / 見送り / 非発火）を `session-handoff` update が「Post ラッパー消化記録」の当該マイルストーン行へ併記する。記録が確認できない場合は**未レビューとみなす**（安全側へ倒れる）。「本サイクル」とは現 feature ブランチの作業単位（cycle-reset まで）を指す。

### 横断的ラッパー（全スキル実行の前後で適用）
```

- [ ] **Step 4: 実装結果を検証する**

Run:
```powershell
Select-String -Path skills\start-work\SKILL.md -Pattern "^### 確定前レビューの提示規則（ADR-0080）$"
Select-String -Path skills\start-work\SKILL.md -Pattern "spec 確定点 \(c\)|判定に迷う場合|未レビューとみなす"
```
Expected: 1 行目の検索で新設した節見出しが 1 件ヒットする（見出し行そのものを固定して数えるため、本文中の言及ではヒットしない）。2 行目で 3 件ヒットする（確定点 (c)・迷ったときの既定・記録欠落時の既定が揃っていることの確認）

Run:
```powershell
Select-String -Path skills\start-work\SKILL.md -Pattern "完了した直後は、確定前レビュー"
```
Expected: **0 件**（旧文言が残っていないこと）

- [ ] **Step 5: コミットする**

```bash
git add skills/start-work/SKILL.md
git commit -m "feat(start-work): 確定前レビューの提示規則を Phase 2 へ実装（ADR-0080）" -- skills/start-work/SKILL.md
```

---

### Task 2: pre-finalization-review へ適用例と新しい提示規則の参照を実装する

**Files:**
- Modify: `skills/pre-finalization-review/SKILL.md`（frontmatter 3 行目、「いつ使うか」12〜15 行、「根拠と世代」40〜43 行）

- [ ] **Step 1: frontmatter の description を更新する**

`old_string`:
```
description: "計画・仕様など非コード成果物の確定前に、実証を課した独立レビューを実施するスキル。3 観点（敵対的・実装整合性・仕様適合）を独立サブエージェントへ委譲し、成果物中のコードはスクラッチで実際に実行させる。発動はユーザーが実施を指示したときのみ。writing-plans / feature-block-design の完了後に start-work から次手として毎回提示される。"
```

`new_string`:
```
description: "計画・仕様など非コード成果物の確定前に、実証を課した独立レビューを実施するスキル。3 観点（敵対的・実装整合性・仕様適合）を独立サブエージェントへ委譲し、成果物中のコードはスクラッチで実際に実行させる。発動はユーザーが実施を指示したときのみ。spec 確定点と plan 確定点で start-work から毎回提示され、未レビューの規範・手順文書の変更を含む成果物では推奨側に置かれる。"
```

- [ ] **Step 2: 「いつ使うか」を新しい提示規則へ揃える**

`old_string`:
```
- **発動はユーザーの指示のみ**（ADR-0072）。規模・不可逆性による自動必須化はしない
- ただし AI 側は、`superpowers:writing-plans` / `feature-block-design` の完了後に本スキルの実施を**毎回提示する**。発動の判断はユーザーに残るが、判断の機会を作る責務は AI 側にある（ADR-0072）
```

`new_string`:
```
- **発動はユーザーの指示のみ**（ADR-0072）。規模・不可逆性による自動必須化はしない
- ただし AI 側は、spec 確定点と plan 確定点で本スキルの実施を**毎回提示する**。発動の判断はユーザーに残るが、判断の機会を作る責務は AI 側にある（ADR-0072）
- **確定点の定義と推奨順位の規則の正本は `start-work` の「確定前レビューの提示規則」にある**（判定はそこで行われるため。ADR-0080）。本スキルは提示後の実施手順を担う
```

- [ ] **Step 3: 「レビューの狙い（スコープ）」の直後へ適用例の節を挿入する**

`old_string`:
```
構文・スコープ・足場の配線といった**局所的・機械的な誤りは主目標に置かない**。直接実装すれば最初の実行で数分のうちに露見するため、確定前レビューで拾うより安い。

## 根拠と世代（ADR-0073）
```

`new_string`:
```
構文・スコープ・足場の配線といった**局所的・機械的な誤りは主目標に置かない**。直接実装すれば最初の実行で数分のうちに露見するため、確定前レビューで拾うより安い。

## 適用例: 独立レビューでしか捕まらなかった欠陥（ADR-0080）

拘束的な検査項目ではなく、観点を立てるときの手がかりとして使う適用例である。出所は本リポジトリの ADR-0079 サイクル（`MakeAiInstructions-2026-08-07-04` / claude-fable-5。規範文書の spec に対する 3 観点レビューで Critical 3・Major 8 を検出した回）に限られ、網羅の保証はない。

1. **選定漏れ型（成果物に「載っていない」欠陥）**: 実装も検証も成果物に書かれたものしか見ないため、比較対象が下流のどの工程にも存在しない。実例 = 点検観点に「退役経路」が無い / スナップショット仕様書の同期タスクが spec に無く実装にも現れない / 是正パターンに「見送り・撤回」が無く規範が増える一方になる棘輪構造
2. **文書間相互作用型（編集対象外ファイルとの矛盾）**: タスク単位で委譲された実装者は自分の編集箇所しか読まないため構造的に検出できない。実例 = 記録義務が定める記録先が、対象シナリオの一部では存在しない経路が残っていた / 記録先の規定が別 ADR の記述規律と衝突していた
3. **検出力欠陥型（検証が緑を返すが何も守っていない）**: レビュアーが実装後の状態を再現して検証コマンドを写経実行したことで実証された。実例 = 検証の grep が節見出しを特定しておらず、節の新設を丸ごと忘れてもチェックリスト行さえあれば合格する状態だった

対照として、期待値の数値ズレ・構文誤り・連番ズレ・挿入アンカーの不一致は実装時に機械的に露見するため、本スキルの主目標には置かない（上記「レビューの狙い」のスコープ規定のとおり）。

## 根拠と世代（ADR-0073）
```

- [ ] **Step 4: 「根拠と世代」へ本サイクルの根拠を追記する**

`old_string`:
```
- 根拠: Issue-0034（根拠 7 件・`corrections` 比率が全クラスタ最高＝人間が繰り返し「レビューは行われたか」を差し込んでいた型）。観測世代: claude-opus-4-8 / claude-fable-5 / claude-opus-5 の 3 世代（モデル固有の躓きではない）
```

`new_string`:
```
- 根拠: Issue-0034（根拠 7 件・`corrections` 比率が全クラスタ最高＝人間が繰り返し「レビューは行われたか」を差し込んでいた型。7 件はすべて LoopForAlpha 由来）。観測世代: claude-opus-4-8 / claude-fable-5 / claude-opus-5 の 3 世代（モデル固有の躓きではない）
- 推奨順位の規則（ADR-0080）の根拠: Issue-0062 / `MakeAiInstructions-2026-08-07-04`（claude-fable-5）。本リポジトリ 1 サイクルの実測であり、適用例の 3 クラスも同じ出所に由来する
```

- [ ] **Step 5: 実装結果を検証する**

Run:
```powershell
Select-String -Path skills\pre-finalization-review\SKILL.md -Pattern "^## 適用例: 独立レビューでしか捕まらなかった欠陥（ADR-0080）$"
Select-String -Path skills\pre-finalization-review\SKILL.md -Pattern "spec 確定点と plan 確定点"
Select-String -Path skills\pre-finalization-review\SKILL.md -Pattern "writing-plans / feature-block-design の完了後に"
```
Expected: 1 行目 = 1 件（新設した節見出し）。2 行目 = 2 件（frontmatter と「いつ使うか」の両方が更新されている）。3 行目 = **0 件**（旧 description の文言が残っていない）

- [ ] **Step 6: コミットする**

```bash
git add skills/pre-finalization-review/SKILL.md
git commit -m "feat(pre-finalization-review): 適用例と新提示規則への参照を追加（ADR-0080）" -- skills/pre-finalization-review/SKILL.md
```

---

### Task 3: feature-block-design の非該当終了時の推奨文言を改める

**Files:**
- Modify: `skills/feature-block-design/SKILL.md`（22 行目「適用要否判定（しきい値）」の末尾、および 56 行目 Phase 0）

**背景（実装者向け）**: この 1 行は Issue-0062 の事象（「writing-plans へ進む（推奨）」を先頭に置いて確定前レビューを非推奨側へ倒した）と同型の推奨を、まさに新しい spec 確定点 (b) にあたる箇所で規範として指示している。改めないと、実装後も同じ場所で 2 つの推奨が競合する。

- [ ] **Step 1: 適用要否判定の末尾を書き換える**

`old_string`:
```
該当しない場合は、判定理由をユーザーに提示して writing-plans への直行を推奨し、本スキルを終了する。
```

`new_string`:
```
該当しない場合は、判定理由をユーザーに提示して本スキルを終了する。このとき、直前に確定した brainstorming の設計文書が spec 確定点 (b) にあたるため、`start-work` の「確定前レビューの提示規則」に従って確定前レビューを提示したうえで次手（writing-plans への直行を含む）を確認する（ADR-0080）。本スキルの側から writing-plans 直行を推奨側に固定しないこと。
```

- [ ] **Step 2: Phase 0 の記述を整合させる**

`old_string`:
```
### Phase 0: 適用要否判定

上記の「適用要否判定」を実施する。該当しなければスキル終了。
```

`new_string`:
```
### Phase 0: 適用要否判定

上記の「適用要否判定」を実施する。該当しなければ、上記のとおり確定前レビューの提示を経てスキル終了。
```

- [ ] **Step 3: 実装結果を検証する**

Run:
```powershell
Select-String -Path skills\feature-block-design\SKILL.md -Pattern "writing-plans への直行を推奨し"
Select-String -Path skills\feature-block-design\SKILL.md -Pattern "spec 確定点 \(b\)|推奨側に固定しないこと"
```
Expected: 1 行目 = **0 件**（旧文言が消えている）。2 行目 = 2 件

- [ ] **Step 4: コミットする**

```bash
git add skills/feature-block-design/SKILL.md
git commit -m "fix(feature-block-design): 非該当終了時の直行推奨を確定前レビュー提示経由へ改める（ADR-0080）" -- skills/feature-block-design/SKILL.md
```

---

### Task 4: session-handoff へレビュー実施記録の規範を実装する

**Files:**
- Modify: `skills/session-handoff/SKILL.md`（フォーマット節の「Post ラッパー消化記録」、update 手順 8、finalize 手順 2）

- [ ] **Step 1: フォーマット節の消化記録の形式にレビュー欄を追加する**

`old_string`:
```
形式: `- <日付> <マイルストーン>: ADR=<番号 or なし（理由）> / worklog=<エントリ id or 棄却（理由）>`
```

`new_string`:
```
形式: `- <日付> <マイルストーン>: ADR=<番号 or なし（理由）> / worklog=<エントリ id or 棄却（理由）> / review=<フル実施（レビュアーのモデル） or 差分再確認 or 見送り or 非発火>`

`review=` は確定点（spec 確定点 / plan 確定点）を通過したマイルストーンにのみ書く（ADR-0080）。それ以外のマイルストーンでは省略してよい。
```

- [ ] **Step 2: update 手順 8 にレビュー結果の併記を追加する**

`old_string`:
```
8. 「Post ラッパー消化記録」へ当該マイルストーンの1行を追記する（ADR-0057）。ADR 候補検出の結果（番号 or なし＋理由）と worklog-record の結果（エントリ id or 棄却＋理由）を書く。棄却を明示しない限り未発火と区別できないため、棄却時も必ず書く
```

`new_string`:
```
8. 「Post ラッパー消化記録」へ当該マイルストーンの1行を追記する（ADR-0057）。ADR 候補検出の結果（番号 or なし＋理由）と worklog-record の結果（エントリ id or 棄却＋理由）を書く。棄却を明示しない限り未発火と区別できないため、棄却時も必ず書く。当該マイルストーンが確定点（spec 確定点 / plan 確定点）だった場合は、確定前レビューの結果（`review=`）も併記する。この記録は次の確定点での推奨判定の material になるため、欠けると判定は「未レビュー」側へ倒れる（ADR-0080）
```

- [ ] **Step 3: finalize の「圧縮しないもの」へレビュー記録を加える**

`old_string`:
```
   **圧縮しないもの**: 正本が handoff 以外にないもの（進行中タスクの状態・残り、現役の申し送り・懸念）。無条件の 1 行要約はしない。落とした情報の受け皿は git 履歴のみとし、退避ファイルは作らない（ADR-0074）
```

`new_string`:
```
   **圧縮しないもの**: 正本が handoff 以外にないもの（進行中タスクの状態・残り、現役の申し送り・懸念、本サイクルの確定前レビュー実施・見送りの記録＝`review=` を含む消化記録行。ADR-0080）。無条件の 1 行要約はしない。落とした情報の受け皿は git 履歴のみとし、退避ファイルは作らない（ADR-0074）
```

- [ ] **Step 4: 実装結果を検証する**

Run:
```powershell
(Select-String -Path skills\session-handoff\SKILL.md -Pattern "review=" | Measure-Object).Count
```
Expected: `4`（フォーマット節の形式行・その直後の但し書き・update 手順 8・finalize の圧縮しないもの。`Measure-Object -Line` は入力オブジェクトの行数を数えるもので件数集計には使わない）

Run:
```powershell
Select-String -Path skills\session-handoff\SKILL.md -Pattern "ADR-0080"
```
Expected: 3 件（但し書き・update 手順 8・finalize）

- [ ] **Step 5: コミットする**

```bash
git add skills/session-handoff/SKILL.md
git commit -m "feat(session-handoff): 確定前レビュー結果の記録を消化記録へ追加（ADR-0080）" -- skills/session-handoff/SKILL.md
```

---

### Task 5: README のスキル一覧を更新する

**Files:**
- Modify: `README.md:46`

- [ ] **Step 1: スキル一覧の該当行を書き換える**

`old_string`:
```
| [`pre-finalization-review`](skills/pre-finalization-review/) | 計画・仕様など非コード成果物の確定前に、実証を課した 3 観点の独立レビューを実施する。発動はユーザー指示のみ（ADR-0067/0072） |
```

`new_string`:
```
| [`pre-finalization-review`](skills/pre-finalization-review/) | 計画・仕様など非コード成果物の確定前に、実証を課した 3 観点の独立レビューを実施する。発動はユーザー指示のみ。spec 確定点と plan 確定点で毎回提示され、未レビューの規範・手順文書の変更を含む成果物では推奨側に置かれる（ADR-0067 / ADR-0072 / ADR-0080） |
```

（ADR 番号は `ADR-0080` の形で書く。Task 8 Step 2 の全ファイル走査がこの文字列を数えるため、`0067/0072/0080` のような連結形にしないこと）

- [ ] **Step 2: 実装結果を検証する**

Run:
```powershell
Select-String -Path README.md -Pattern "ADR-0080"
```
Expected: 1 件

- [ ] **Step 3: コミットする**

```bash
git add README.md
git commit -m "docs: README のスキル一覧へ提示規則の変更を反映（ADR-0080）" -- README.md
```

---

### Task 6: ADR-0067 / ADR-0072 へ部分修正を追記する

**Files:**
- Modify: `docs/records/decisions/0067-pre-finalization-review-as-new-skill.md`（Consequences 末尾）
- Modify: `docs/records/decisions/0072-pre-finalization-review-triggered-by-user-only.md`（Consequences 末尾）

**背景（実装者向け）**: 両 ADR は Decision 本文で提示点を「`writing-plans` および `feature-block-design` の完了後」と列挙しており、ADR-0080 でこの列挙が事実として古くなる。答えている問いが異なるため Superseded にはせず、Consequences への追記で現役のまま維持する（ADR-0073 と同じ部分修正の型。CONTRIBUTING.md「台帳監査」の分類でいう「部分修正あり（本体現役・状態変更なし）」）。Status は両者とも `Accepted` のまま変更しない。

- [ ] **Step 1: ADR-0067 の Consequences 末尾へ追記する**

`docs/records/decisions/0067-pre-finalization-review-as-new-skill.md` の Consequences セクション最終行の後に、次の 1 行を追加する（ファイル末尾に空行が 1 行ある場合はその前に挿入する）:

```
- **部分修正（ADR-0080）**: 本 ADR が定めた配線先の提示点「`writing-plans` および `feature-block-design` の完了後」は、ADR-0080 により spec 確定点（3 通り）と plan 確定点の 2 種へ一般化された。新規スキルとして立てる決定と `start-work` へ配線する決定は現役のため、Status は Accepted のまま維持する
```

- [ ] **Step 2: ADR-0072 の Consequences 末尾へ追記する**

`docs/records/decisions/0072-pre-finalization-review-triggered-by-user-only.md` の Consequences セクション最終行（「- **自動必須化は将来の選択肢として残る。**」で始まる行）の後に、次の 1 行を追加する:

```
- **部分修正（ADR-0080）**: Decision 本文の提示点「`writing-plans` および `feature-block-design` の完了後」は、ADR-0080 により spec 確定点（3 通り）と plan 確定点の 2 種へ一般化され、あわせて提示内の推奨順位の規則が加わった。骨格（発動はユーザー指示のみ・AI は毎回提示する・自動必須化しない）は現役のため、Status は Accepted のまま維持する
```

- [ ] **Step 3: 実装結果を検証する**

Run:
```powershell
Select-String -Path docs\records\decisions\0067-pre-finalization-review-as-new-skill.md,docs\records\decisions\0072-pre-finalization-review-triggered-by-user-only.md -Pattern "部分修正（ADR-0080）"
Select-String -Path docs\records\decisions\0067-pre-finalization-review-as-new-skill.md,docs\records\decisions\0072-pre-finalization-review-triggered-by-user-only.md -Pattern "^- \*\*Status\*\*"
```
Expected: 1 行目 = 2 件（各ファイル 1 件ずつ）。2 行目 = 2 件で、いずれも `Accepted`（Superseded / Deprecated へ変わっていないこと）

Run:
```powershell
Select-String -Path docs\records\decisions\README.md -Pattern "\[0067\]|\[0072\]"
```
Expected: 2 件で、いずれも Status 列が `Accepted`（インデックスの変更は不要。変わっていないことの確認）

- [ ] **Step 4: コミットする**

```bash
git add docs/records/decisions/0067-pre-finalization-review-as-new-skill.md docs/records/decisions/0072-pre-finalization-review-triggered-by-user-only.md
git commit -m "adr: 0067/0072 へ ADR-0080 による提示点の部分修正を追記（Status は Accepted 維持）" -- docs/records/decisions/0067-pre-finalization-review-as-new-skill.md docs/records/decisions/0072-pre-finalization-review-triggered-by-user-only.md
```

---

### Task 7: Issue-0062 を close し、Issue-0006 へ知見を追記する

**Files:**
- Modify: `docs/working/issues/flow/0062-review-recommendation-ignores-artifact-safety-net.md`
- Modify: `docs/working/issues/flow/0006-cross-cutting-change-plan-coverage.md`
- Modify: `docs/working/issues/README.md`

- [ ] **Step 1: Issue-0062 のヘッダと結論を更新する**

`old_string`:
```
- **Status**: open
- **Opened**: 2026-08-07
```

`new_string`:
```
- **Status**: closed
- **Opened**: 2026-08-07
- **Closed**: 2026-08-07
```

続けて「結論」セクションを更新する。

`old_string`:
```
## 検討状況

- 2026-08-07: 起票のみ（対策の設計・採否は次サイクル。ADR-0021）

## 結論

（未定）
```

`new_string`:
```
## 検討状況

- 2026-08-07: 起票のみ（対策の設計・採否は次サイクル。ADR-0021）
- 2026-08-07: 対策サイクルで ADR-0080 を策定。設計段階で「spec レビュー済みの写像 plan に軽量レビュー（仕様適合単観点）を推奨する」枝も設計したが、本 ADR 自身への確定前レビューで根拠の崩壊が実証され撤回した（Issue-0006 は spec に明示されない横断参照側の漏れであり、母数を spec 要件数に取る突合では原理的に拾えない）。再導入条件は ADR-0080 の Considered Alternatives 6 に記載

## 結論

ADR-0080（確定前レビューは spec/plan 確定点で提示し、未レビューの規範・手順文書の変更を含む成果物では推奨側に倒す）で対処。`start-work` に判定規則の正本を置き、`pre-finalization-review` / `feature-block-design` / `session-handoff` を整合させた。
```

- [ ] **Step 2: Issue-0006 の検討状況へ本サイクルの知見を追記する**

`old_string`:
```
## 検討状況

（未着手）
```

`new_string`:
```
## 検討状況

- 2026-08-07: ADR-0080 のサイクルで本課題を対策候補として検討し、対象外と確定した。本課題の漏れは「仕様書に明示されていない旧参照の洗い出し」の側であり、spec 要件を母数とする spec→plan 突合では原理的に検出できない（ADR-0080 Considered Alternatives 6）。有効な対策は横断洗い出し自体を plan 作成手順へ組み込む方向であり、確定前レビューの提示規則とは別の設計になる
```

- [ ] **Step 3: インデックスの Status を更新する**

`docs/working/issues/README.md`（79 行目）:

`old_string`:
```
| [0062](flow/0062-review-recommendation-ignores-artifact-safety-net.md) | 確定前レビューの次手提示が成果物の性質を問わず中立で、安全網の無い成果物でも非推奨側に倒れる | open | 2026-08-07 |
```

`new_string`:
```
| [0062](flow/0062-review-recommendation-ignores-artifact-safety-net.md) | 確定前レビューの次手提示が成果物の性質を問わず中立で、安全網の無い成果物でも非推奨側に倒れる | closed | 2026-08-07 |
```

- [ ] **Step 4: 実装結果を検証する**

Run:
```powershell
Select-String -Path docs\working\issues\flow\0062-review-recommendation-ignores-artifact-safety-net.md -Pattern "^- \*\*Status\*\*: closed$|^- \*\*Closed\*\*: 2026-08-07$"
Select-String -Path docs\working\issues\README.md -Pattern "0062.*closed"
Select-String -Path docs\working\issues\flow\0006-cross-cutting-change-plan-coverage.md -Pattern "ADR-0080"
```
Expected: 1 行目 = 2 件、2 行目 = 1 件、3 行目 = 1 件

Run（0006 が誤って close されていないこと）:
```powershell
Select-String -Path docs\working\issues\flow\0006-cross-cutting-change-plan-coverage.md -Pattern "^- \*\*Status\*\*: open$"
```
Expected: 1 件

- [ ] **Step 5: コミットする**

```bash
git add docs/working/issues/flow/0062-review-recommendation-ignores-artifact-safety-net.md docs/working/issues/flow/0006-cross-cutting-change-plan-coverage.md docs/working/issues/README.md
git commit -m "issue: 0062 を close（ADR-0080）／0006 に対象外判定の根拠を追記" -- docs/working/issues/flow/0062-review-recommendation-ignores-artifact-safety-net.md docs/working/issues/flow/0006-cross-cutting-change-plan-coverage.md docs/working/issues/README.md
```

---

### Task 8: ADR-0080 を Accepted へ昇格する

**Files:**
- Modify: `docs/records/decisions/0080-review-presentation-scaled-by-unreviewed-normative-content.md:3`
- Modify: `docs/records/decisions/README.md`（0080 の行）

**前提**: Task 1〜7 がすべて完了し、各タスクの検証がパスしていること（実装を伴う決定は実装完了・検証後に昇格する。ADR-0019）。

- [ ] **Step 1: 粒度を点検する（ADR-0059 / ADR-0060）**

ADR-0080 のタイトル「確定前レビューは spec/plan 確定点で提示し、未レビューの規範・手順文書の変更を含む成果物では推奨側に倒す」が、Decision 1〜5 のすべてに答えているかを突合する。Decision 5（判定材料の記録）はタイトルの「未レビューの…判定」を成立させるための従属規定であり、独立した問いには割れないため分割不要と判断してよい。もし突合の結果、タイトルが答えていない決定が見つかった場合は、昇格を止めてユーザーへ分割を提案すること

- [ ] **Step 2: 全変更が入っていることを機械的に確認する**

Run:
```powershell
$files = @(
  'skills\start-work\SKILL.md',
  'skills\pre-finalization-review\SKILL.md',
  'skills\feature-block-design\SKILL.md',
  'skills\session-handoff\SKILL.md',
  'README.md',
  'docs\records\decisions\0067-pre-finalization-review-as-new-skill.md',
  'docs\records\decisions\0072-pre-finalization-review-triggered-by-user-only.md',
  'docs\working\issues\flow\0006-cross-cutting-change-plan-coverage.md'
)
foreach ($f in $files) {
  $n = (Select-String -Path $f -Pattern 'ADR-0080' | Measure-Object).Count
  "$f : $n"
}
```
Expected: 8 ファイルすべてが 1 以上（各ファイルに ADR-0080 由来の変更が入っていること）。`Group-Object Filename` は使わない — 同名ファイル（SKILL.md）が basename で束ねられ、ファイル別集計にならないため

- [ ] **Step 3: Status を Accepted へ更新する**

`docs/records/decisions/0080-review-presentation-scaled-by-unreviewed-normative-content.md`:

`old_string`:
```
- **Status**: Proposed
```

`new_string`:
```
- **Status**: Accepted
```

- [ ] **Step 4: インデックスを更新する**

`docs/records/decisions/README.md`:

`old_string`:
```
| [0080](0080-review-presentation-scaled-by-unreviewed-normative-content.md) | 確定前レビューは spec/plan 確定点で提示し、未レビューの規範・手順文書の変更を含む成果物では推奨側に倒す | Proposed | 2026-08-07 |
```

`new_string`:
```
| [0080](0080-review-presentation-scaled-by-unreviewed-normative-content.md) | 確定前レビューは spec/plan 確定点で提示し、未レビューの規範・手順文書の変更を含む成果物では推奨側に倒す | Accepted | 2026-08-07 |
```

- [ ] **Step 5: 実装結果を検証する**

Run:
```powershell
Select-String -Path docs\records\decisions\0080-review-presentation-scaled-by-unreviewed-normative-content.md -Pattern "^- \*\*Status\*\*: Accepted$"
Select-String -Path docs\records\decisions\README.md -Pattern "\[0080\].*Accepted"
Select-String -Path docs\records\decisions\0080-review-presentation-scaled-by-unreviewed-normative-content.md -Pattern "^## 過剰適合点検（ADR-0079）$"
```
Expected: 3 行とも 1 件ずつ（3 行目は点検ブロックがコミット時点で存在することの確認。ADR-0079 の執行点）

- [ ] **Step 6: コミットする**

```bash
git add docs/records/decisions/0080-review-presentation-scaled-by-unreviewed-normative-content.md docs/records/decisions/README.md
git commit -m "adr: 0080 を Accepted へ昇格（実装完了・検証済み）" -- docs/records/decisions/0080-review-presentation-scaled-by-unreviewed-normative-content.md docs/records/decisions/README.md
```

---

## 完了後の状態

- `start-work` Phase 2 が確定前レビューの提示規則（確定点 4 通り・推奨判定・差分明示・記録）の正本を持つ
- `pre-finalization-review` が実施手順と欠陥クラス 3 種の適用例を持ち、規則の正本を start-work 側へ参照する
- `feature-block-design` の非該当終了時に writing-plans 直行が推奨側へ固定されなくなる
- `session-handoff` がレビュー実施結果を消化記録へ残し、finalize で圧縮しない
- ADR-0067 / ADR-0072 に部分修正が追記され、Status は Accepted のまま
- Issue-0062 が closed、Issue-0006 に対象外判定の根拠が残る
- ADR-0080 が Accepted

## スコープ外（本計画で扱わないこと）

- 横断洗い出しの網羅漏れ対策（Issue-0006 の本体。別サイクル）
- 軽量レビュー枝の再導入（写像欠落の同型 delta が実測されてから。ADR-0080 Considered Alternatives 6）
- `scripts/sync-template.ps1` の実行（template 対象ファイルを変更しないため不要。ADR-0016）
