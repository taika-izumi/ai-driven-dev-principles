# start-work 責務分割 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** start-work の 2 節（確定前レビューの提示規則・完了処理のマージ方式確認）を責務帰属で移設し、参照を全数張り替える（ADR-0116。spec: `docs/current/specs/2026-08-28-start-work-responsibility-split-design.md`）

**Architecture:** 条文の無改変移設＋許容差分（参照張り替え・見出し/導入文・自己言及/R1-a 1 箇所）。skills/ の編集と dist/ 再生成は同一コミット（執行点 4 手順）。docs 側の張り替えは別コミット。

**Tech Stack:** Markdown・PowerShell（build-dist.ps1 / sync-template.ps1）・grep/diff 検証

**行番号の注意:** 本計画の「現行 LNN」は 2026-08-28 時点の各ファイルの実測行番号。編集前に必ず該当行を Read で実体確認し、引用文と一致することを確かめてから編集する（一致しなければ実態優先で位置を特定し直す）。

---

### Task 0: 基準スナップショットと事前実測

**Files:** 作成: `~/.ai-dev-review-snapshots/2026-08-28-start-work-responsibility-split/impl-base/`（リポジトリ外）

- [ ] **Step 0-1: 移設 2 節の本文を抽出退避**

```bash
base=~/.ai-dev-review-snapshots/2026-08-28-start-work-responsibility-split/impl-base
mkdir -p "$base"
sed -n '75,88p' skills/start-work/SKILL.md > "$base/merge-section-before.md"
sed -n '89,161p' skills/start-work/SKILL.md > "$base/review-section-before.md"
wc -c "$base"/*.md
```

期待: merge-section-before.md = 4,270B / review-section-before.md = 16,771B（実測済みの確定値）

退避ファイルが失われた場合の代替取得元: `git show HEAD:skills/start-work/SKILL.md`（Task 3-2 で原文を削除した後でも git 履歴から復元できる）

- [ ] **Step 0-2: ベースライン grep（実装前の現状確認）**

```bash
grep -rl "写像欠落" skills/        # 期待: skills/start-work/SKILL.md のみ
grep -rl "ai-dev.mergepractice" skills/   # 期待: skills/start-work/SKILL.md のみ
```

### Task 1: `skills/start-work/references/merge-practice.md` 新設

**Files:** 作成: `skills/start-work/references/merge-practice.md`

- [ ] **Step 1-1: ファイル作成**。冒頭に次の見出し・導入文を置き（許容差分 (ii)）、続けて Task 0 で退避した `merge-section-before.md` の内容から**見出し行（`### 完了処理のマージ方式確認`）を除いた本文**を貼り付ける:

```markdown
# 完了処理のマージ方式確認

feature ブランチを既定ブランチへ取り込む完了処理の実行直前に適用する慣行判定の手順。`start-work` の完了処理の発火点（Phase 2 マッピング表・横断的ラッパー Pre 条項・セッション終了処理）から読まれる。
```

- [ ] **Step 1-2: 許容差分 (iii) の 2 箇所を書き換え**（これ以外の本文は無改変）:

置換 1（自己言及語）:
- 前: `**本節が慣行判定の正本である**（他スキルからは節の主題によるポインタで参照される。条件文の複写はしない）`
- 後: `**本ファイルが慣行判定の正本である**（他スキル・`start-work` 本文からはポインタで参照される。条件文の複写はしない）`

置換 2（start-work 本文構造への参照のファイル跨ぎ化。現行 start-work L87 相当の行）:
- 前: `実行そのものの承認取得は横断的ラッパー Pre の pre-action-review 条項が担い、本節は方式の確認のみを担う（役割が異なり重複しない）。同一セッション内の同一完了処理につき確認は 1 回とする（マッピング表経由で確認済みなら Pre 条項経由の再確認は省略する）。`
- 後: `実行そのものの承認取得は `start-work` の横断的ラッパー Pre の pre-action-review 条項が担い、本ファイルは方式の確認のみを担う（役割が異なり重複しない）。同一セッション内の同一完了処理につき確認は 1 回とする（`start-work` Phase 2 のマッピング表経由で確認済みなら Pre 条項経由の再確認は省略する）。`

- [ ] **Step 1-3: 検証**

```bash
grep -c "ai-dev.mergepractice" skills/start-work/references/merge-practice.md   # 期待: 2
grep -c "本節" skills/start-work/references/merge-practice.md                    # 期待: 0
```

### Task 2: `skills/pre-finalization-review/SKILL.md` へ提示規則を統合

**Files:** 変更: `skills/pre-finalization-review/SKILL.md`

- [ ] **Step 2-1: frontmatter description を操作列挙型へ全置換**

- 後: `"計画・仕様など非コード成果物の確定に関わる 2 操作を提供するスキル。提示操作: spec/plan 確定点への到達時に毎回、確定前レビューの実施をユーザーへ提示する（AI が呼ぶ。確定点の定義・提示・推奨順位・反復・停止判定の正本は本スキル）。実施操作: 3 観点（敵対的・実装整合性・仕様適合）の独立レビューを実証つきで実行する（発動はユーザーが実施を指示したときのみ）。"`

- [ ] **Step 2-2: 「いつ使うか」節の本文（現行 L14-15。見出し L12 と直下の空行 L13 は残す）を次で全置換**（発動主体行の文言は保持・正本参照句は管轄宣言へ置換。「本スキルは提示後の実施手順を担う」行は削除）:

```markdown
本スキルは 2 つの操作を提供する。確定点の定義・提示・推奨順位・反復・停止判定・実施方式の正本は本スキルである（ADR-0116）。

- **提示操作**: spec/plan 確定点への到達時に毎回、下記「確定点での提示（提示規則）」に従って確定前レビューの実施をユーザーへ提示する（AI が呼ぶ。提示は省略しない）
- **実施操作**: 下記「手順」の 3 観点独立レビューを実行する。**発動はユーザーの指示のみ**（`start-work` を経由しない直接呼び出しでも同じ。ADR-0072）
```

- [ ] **Step 2-3: 「いつ使うか」の直後に新節 `## 確定点での提示（提示規則）` を挿入**し、Task 0 の `review-section-before.md` の内容から**見出し行（`### 確定前レビューの提示規則（ADR-0080）`）を除いた本文**を貼り付ける

- [ ] **Step 2-4: 移設本文へ許容差分 5 箇所を適用**（これ以外は無改変）:

1. 冒頭行（旧 L91）: `確定前レビュー（`pre-finalization-review`）の提示は、` → `確定前レビュー（本スキル）の提示は、`
2. 旧 L136: `実施方式 3 種の定義・実施手順は `pre-finalization-review`「反復の実施」節が正本である（1 行要約: フル巡＝3 観点の全数走査〈初回提示の「フルレビュー（3 観点）」と同一方式。反復では体数のみ 1〜3 体に縮小可〉・差分確認巡＝前巡指摘の対応表方式 1 体・機械検証＝レビュアーを立てない grep 等の機械判定〈巡は立てない〉）。` → `実施方式 3 種の定義・実施手順は下記「反復の実施」節が正本である。`（1 行要約は移設先に定義が既存のため削除）
3. 旧 L142: `（退避規定は `pre-finalization-review`「反復の実施」節に従う）` → `（退避規定は下記「反復の実施」節に従う）`
4. 旧 L152: `**停止判定（ADR-0107 決定 2）**` → `**停止判定（ADR-0107）**`（R1-a 修正）
5. 旧 L156: `（最終判断はユーザー。継続レビュアーの扱いは `pre-finalization-review`「反復の実施」節）` → `（最終判断はユーザー。継続レビュアーの扱いは下記「反復の実施」節）`

- [ ] **Step 2-5: 既存本文の逆参照 5 箇所を内部参照へ**:

1. 手順 5（現行 L27）: `（本手順の採否決定は推奨案の作成として読む。start-work「指摘反映後の反復」参照）` → `（本手順の採否決定は推奨案の作成として読む。上記「指摘反映後の反復」参照）`
2. 手順 6（現行 L28）: `改訂後の再レビュー（反復）の提示は start-work「指摘反映後の反復」に従う。` → `改訂後の再レビュー（反復）の提示は上記「指摘反映後の反復」に従う。`
3. 反復の実施 冒頭（現行 L32）: `指摘反映後の再レビュー（反復）の発動・推奨順位・停止判定の正本は `start-work`「指摘反映後の反復」である。` → `指摘反映後の再レビュー（反復）の発動・推奨順位・停止判定の正本は上記「指摘反映後の反復」である。`
4. 機械検証（現行 L36）: ``start-work` の反復提示へ戻る` → `上記「指摘反映後の反復」の反復提示へ戻る`
5. 継続レビュアー（現行 L38）: `骨格安定（`start-work` 同節）` → `骨格安定（上記「指摘反映後の反復」）`

- [ ] **Step 2-6: 検証**

```bash
grep -c "start-work" skills/pre-finalization-review/SKILL.md   # 期待: 1（実施操作の発動主体行のみ）
grep -c "写像欠落" skills/pre-finalization-review/SKILL.md      # 期待: 1
```

### Task 3: `skills/start-work/SKILL.md` の残留化

**Files:** 変更: `skills/start-work/SKILL.md`

- [ ] **Step 3-1: 「いつ使うか」節の直後に境界宣言を挿入**:

```markdown
## 責務境界

start-work が正本として持つのはオーケストレーション（フェーズ構造・次手ナビゲーション・横断的ラッパーの配線・セッション終了処理）のみである。ドメイン規範の正本は所有スキルへ、所有スキルが無いものは `references/` 配下へ置き、本文には発火点のポインタのみを書く（ADR-0116）。
```

- [ ] **Step 3-2: 2 節を削除**（現行 L75-161「完了処理のマージ方式確認」＋「確定前レビューの提示規則（ADR-0080）」の 2 節と、直後の空行 L162。見出し行ごと削除し、スタブは残さない。削除後に L74 の空行が次節見出しの直前に来る〈空行が二重化していない〉ことを確認する）

- [ ] **Step 3-3: 発火点 6 箇所を置換**:

1. Phase 2 表の完了処理行（現行 L64）:
   - 前: `superpowers:finishing-a-development-branch（実行直前に下記「完了処理のマージ方式確認」を適用）`
   - 後: `superpowers:finishing-a-development-branch（実行直前に `references/merge-practice.md`〈マージ方式確認の正本〉を読んで適用）`
2. Phase 2 表の確定前レビュー行（現行 L69）:
   - 前: `| 計画・仕様など非コード成果物の確定前レビュー（発動はユーザー指示時。提示は確定点で毎回。指摘反映後の反復提示を含む） | pre-finalization-review | （本プラグイン提供のスキル、フォールバック不要） |`
   - 後: `| 計画・仕様など非コード成果物の確定前レビュー（確定点での提示・反復・実施。規則の正本は同スキル） | pre-finalization-review | （本プラグイン提供のスキル、フォールバック不要） |`
3. 提示規則参照行（現行 L72）:
   - 前: `確定前レビュー（`pre-finalization-review`）は、下記「確定前レビューの提示規則」に従って提示する（実施の判断はユーザー。ADR-0072 / ADR-0080）。`
   - 後:

```markdown
確定前レビューの提示・推奨順位・反復・停止判定の正本は `pre-finalization-review`（提示操作）である。確定点に到達したら同スキルを提示操作で呼ぶ（実施の判断はユーザー。ADR-0072 / ADR-0080 / ADR-0116）。ここで列挙する到達時点は次の 2 種に限る: spec 確定点 (b)＝brainstorming の設計が確定し feature-block-design を適用しないと判断した時点（同スキルの起動有無を問わない）、plan 確定点＝superpowers:writing-plans が完了したとき（インライン簡易 plan の確定を含む）。
```

4. 横断的ラッパー Pre 条項（現行 L170）:
   - 前: `- 完了処理〈既定ブランチへの取り込み〉を行うスキル・手順の実行直前は、Phase 2 の「完了処理のマージ方式確認」を適用する。`（行の後半は変更しない）
   - 後: `- 完了処理〈既定ブランチへの取り込み〉を行うスキル・手順の実行直前は、`references/merge-practice.md`（マージ方式確認の正本）を読んで適用する。`（行の後半は現状維持）
5. Post 項目 1（現行 L180）:
   - 前: `Phase 2 の「確定前レビューの提示規則」に従って提示すること（ADR-0080）。`
   - 後: ``pre-finalization-review` の提示操作を呼んで提示すること（ADR-0080）。`
6. セッション終了処理（現行 L199）:
   - 前: `（これは事後確認であり、マージ実行前の方式確認は Phase 2 の「完了処理のマージ方式確認」が担う）`
   - 後: `（これは事後確認であり、マージ実行前の方式確認は `references/merge-practice.md` が担う）`

L176（提示→回答→update の順序規定）は変更しない。

- [ ] **Step 3-4: 検証**

```bash
grep -c "写像欠落\|ai-dev.mergepractice" skills/start-work/SKILL.md   # 期待: 0（条文本体の消滅）
grep -n "確定前レビューの提示規則\|完了処理のマージ方式確認\|指摘反映後の反復" skills/start-work/SKILL.md   # 期待: 0（宙に浮いたポインタの残存なし）
wc -c skills/start-work/SKILL.md   # 実測値を記録（目安は設けない。合否基準ではない）
```

### Task 4: 他スキル 4 ファイルの参照張り替え（9 箇所）

**Files:** 変更: `skills/decision-log/SKILL.md`・`skills/session-handoff/SKILL.md`・`skills/feature-block-design/SKILL.md`・`skills/retrospective/SKILL.md`

- [ ] **Step 4-1: decision-log 3 箇所**

1. L121: `コミットの前に `start-work` の「確定前レビューの提示規則」に従って確定前レビューを提示すること（ADR-0080）。` → `コミットの前に `pre-finalization-review` の提示操作を呼んで確定前レビューを提示すること（ADR-0080）。`
2. L186 内: `反復・巡・終了時の定義は start-work「指摘反映後の反復」と session-handoff「`review=` の値定義」節を参照` → `反復・巡・終了時の定義は pre-finalization-review「指摘反映後の反復」と session-handoff「`review=` の値定義」節を参照`
3. L226: `- 規範・手順文書（`start-work`「確定前レビューの提示規則」の推奨判定が定める型。ここでは再定義しない）` → `- 規範・手順文書（`pre-finalization-review`「確定点での提示（提示規則）」の推奨判定が定める型。ここでは再定義しない）`

- [ ] **Step 4-2: session-handoff 3 箇所**

1. L91: `実質収束（start-work「指摘反映後の反復」の停止判定。いずれかの経路）` → `実質収束（pre-finalization-review「指摘反映後の反復」の停止判定。いずれかの経路）`
2. L129: `本スキルのほか `start-work`（確定前レビューの提示規則）と `decision-log`（サイクル全体整合検査）がこの定義を参照する` → `本スキルのほか `pre-finalization-review`（確定点での提示）と `decision-log`（サイクル全体整合検査）がこの定義を参照する`
3. L210 内: `確定点の型（`spec 確定点 (a)〜(c)` / `plan 確定点`）の定義は start-work スキルの「確定前レビューの提示規則」節を参照（ADR-0080）` → `確定点の型（`spec 確定点 (a)〜(c)` / `plan 確定点`）の定義は pre-finalization-review スキルの「確定点での提示（提示規則）」節を参照（ADR-0080）`

- [ ] **Step 4-3: feature-block-design 2 箇所**（L22・L128）

いずれも: ``start-work` の「確定前レビューの提示規則」に従って確定前レビューを提示` → ``pre-finalization-review` の提示操作を呼んで確定前レビューを提示`（前後の文は変更しない）

- [ ] **Step 4-4: retrospective 1 箇所**（L69）

`（判定手続きと既定ブランチの解決手続きの正本は `start-work` の「完了処理のマージ方式確認」節。条件文はここに複写しない）` → `（判定手続きと既定ブランチの解決手続きの正本は `skills/start-work/references/merge-practice.md`。条件文はここに複写しない）`

### Task 5: 現用 spec・open 課題・README の張り替え（6 箇所）

**Files:** 変更: `docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md`（3）・`docs/current/specs/2026-05-01-retrospective-design.md`（1）・`docs/working/issues/flow/0107-iterative-review-recommendation-divergence/0107-iterative-review-recommendation-divergence.md`（1）・`README.md`（1）

- [ ] **Step 5-1: 2026-08-05 spec**

1. L86: `確定点の定義・提示内の推奨順位を含む発動・提示規則の正本は `start-work` の「確定前レビューの提示規則」である` → `確定点の定義・提示内の推奨順位を含む発動・提示規則の正本は `pre-finalization-review` の「確定点での提示（提示規則）」である`（行内の他の句——「`start-work` が確定点…で毎回提示する」を含む——は変更しない）
2. L95: `反復提示は start-work「指摘反映後の反復」に従う` → `反復提示は pre-finalization-review「指摘反映後の反復」に従う`
3. L99: `発動・推奨・停止判定の正本は start-work「指摘反映後の反復」。` → `発動・推奨・停止判定の正本は pre-finalization-review「指摘反映後の反復」。`

- [ ] **Step 5-2: 2026-05-01 spec L61**: `慣行判定（正本は start-work「完了処理のマージ方式確認」）` → `慣行判定（正本は `skills/start-work/references/merge-practice.md`）`

- [ ] **Step 5-3: Issue-0107 L10**: `確定前レビューの反復規範（start-work「指摘反映後の反復」の 2 段型・前置 1・前置 2）` → `確定前レビューの反復規範（pre-finalization-review「指摘反映後の反復」の 2 段型・前置 1・前置 2）`

- [ ] **Step 5-4: README L46 を全置換**:

- 後: `| [`pre-finalization-review`](skills/pre-finalization-review/) | 計画・仕様など非コード成果物の、確定点での確定前レビュー提示（毎回）と 3 観点独立レビューの実施（実証つき・発動はユーザー指示のみ）を担う。確定点・提示・反復の規則の正本は本スキル（ADR-0067 / ADR-0072 / ADR-0080 / ADR-0116） |`

### Task 6: ADR 部分修正注記（7 件。全数走査は計画作成時に実施済み）

**Files:** 変更: `docs/records/decisions/0072-*.md`・`0080-*.md`・`0091-*.md`・`0092-*.md`・`0105-*.md`・`0106-*.md`・`0107-*.md`

走査結果: 節名・正本所在を参照する Accepted 済み ADR は上記 7 件（パターン `確定前レビューの提示規則|完了処理のマージ方式確認|指摘反映後の反復|start-work 提示規則|start-work 側に維持` の全 ADR grep。0115/0116 は本サイクルの決定のため対象外）。ADR-0067 は当該パターン grep 非該当であり、内容も配線先（Phase 2 マッピング表への行追加。本改修後も行は維持される）の決定のみで正本所在を定めないため対象外。

- [ ] **Step 6-1: 各 ADR の Consequences 末尾へ 1 行追記**（`- **部分修正（ADR-0116）**:` 書式・Status は Accepted 維持）:

1. 0072: `- **部分修正（ADR-0116）**: 提示規則の正本所在は ADR-0116 により `pre-finalization-review` へ移設された。発動はユーザーの指示のみとする決定自体は不変のため、Status は Accepted のまま維持`
2. 0080: `- **部分修正（ADR-0116）**: 本 ADR が定めた提示規則の正本所在（start-work「確定前レビューの提示規則」）は、ADR-0116 により pre-finalization-review「確定点での提示（提示規則）」へ移設された。提示・推奨の規則内容は不変のため、Status は Accepted のまま維持`
3. 0091: `- **部分修正（ADR-0116）**: 決定 5 と Consequences の「定義の正本は start-work 側に維持する」旨は、ADR-0116 による移設後は pre-finalization-review 側と読み替える。参照 1 文に集約する決定自体は不変のため、Status は Accepted のまま維持`
4. 0092: `- **部分修正（ADR-0116）**: サイクルの定義・規範文書の型の参照先（start-work「確定前レビューの提示規則」）は、ADR-0116 により pre-finalization-review へ移設された。検査の決定自体は不変のため、Status は Accepted のまま維持`
5. 0105: `- **部分修正（ADR-0116）**: K12 の統合先（start-work の提示規則）は、ADR-0116 により pre-finalization-review へ移設された（あわせて K12 が定めた H-01 の文言は操作列挙型の記述へ改められた）。正本一元化の決定自体は不変で正本は 1 箇所のままのため、Status は Accepted のまま維持`
6. 0106: `- **部分修正（ADR-0116）**: 慣行判定の正本所在（start-work Phase 2 の独立小節）は、ADR-0116 により skills/start-work/references/merge-practice.md へ移設された。2 層配線の決定自体は不変のため、Status は Accepted のまま維持`
7. 0107: `- **部分修正（ADR-0116）**: 反復規範の正本所在（start-work「指摘反映後の反復」）は、ADR-0116 により pre-finalization-review へ移設された。推奨切替・収束判定の規則内容は不変のため、Status は Accepted のまま維持`

### Task 7: CONTRIBUTING.md のチェックリスト文言拡張

**Files:** 変更: `CONTRIBUTING.md`（start-work シナリオのチェックリスト。現行 L406）

- [ ] **Step 7-1**: `- フェーズの責務分離が崩れていないか` → `- フェーズの責務分離が崩れていないか（ドメイン規範の正本を本文へ持ち込んでいないか。正本は所有スキルまたは references へ。ADR-0116）`

### Task 8: Issue-0105 検討状況への実例追記

**Files:** 変更: `docs/working/issues/flow/0105-skill-md-size-growth-no-norm.md`

- [ ] **Step 8-1: 「検討状況」へ 1 行追記**:

`- 2026-08-28: start-work を分割（ADR-0115/0116）。提示規則 16,771B を pre-finalization-review へ、マージ方式確認 4,270B を references/merge-practice.md へ移設。分割前 34,676B → 分割後 <分割後実測>B（確定点到達セッションの合計は <合計実測>B）。一般規範の設計は本サイクルでも見送り（分割の実例 1 件を判断材料として追加）。Status は open のまま。`

`<分割後実測>` と `<合計実測>` は追記の直前に `wc -c skills/start-work/SKILL.md skills/pre-finalization-review/SKILL.md` で取得した値（合計は両者の和）で埋める。

### Task 9: 検証 3 種＋サイズ・到達実測

- [ ] **Step 9-1: 無改変移設の diff 検証**。新所在から移設本文を抽出し、Task 0 の退避と比較。差分が計画に列挙した許容差分（Task 1: 2 箇所＋見出し/導入文、Task 2: 5 箇所＋見出し）**のみ**であることを差分一覧で確認する:

```bash
base=~/.ai-dev-review-snapshots/2026-08-28-start-work-responsibility-split/impl-base
git diff --no-index "$base/merge-section-before.md" skills/start-work/references/merge-practice.md || true
# 提示規則側は新節の開始行〜終了行を Read で特定して抽出し比較:
# sed -n '<新節開始>,<新節終了>p' skills/pre-finalization-review/SKILL.md > /tmp/review-after.md
# git diff --no-index "$base/review-section-before.md" /tmp/review-after.md || true
```

- [ ] **Step 9-2: 残存ゼロ確認**（4 本。期待値は計画作成時に実測突合済み）

```bash
# skills/ 全域: 節名の単純 grep（start-work 内部の「下記」「Phase 2 の」型の自己参照ポインタも捕捉する）
grep -rn "確定前レビューの提示規則" skills/          # 期待: 0 件
grep -rn "完了処理のマージ方式確認" skills/          # 期待: 1 件（references/merge-practice.md の見出しのみ）
grep -rnE "start-work.*「指摘反映後の反復」" skills/  # 期待: 0 件（内部参照形「上記「指摘反映後の反復」」と新所在参照形は正当に残るため start-work 共起で判定）
# 張り替え対象 docs 4 ファイル: start-work 共起で旧所在参照を検査
grep -rnE "start-work.*「(確定前レビューの提示規則|指摘反映後の反復|完了処理のマージ方式確認)」" docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md docs/current/specs/2026-05-01-retrospective-design.md docs/working/issues/flow/0107-iterative-review-recommendation-divergence/ README.md   # 期待: 0 件
```

検査範囲は skills/ 全域＋設計 2 の張り替え対象ファイルに限る（`docs/current/specs/` `docs/working/issues/` のディレクトリ全体を走査しない——本サイクルの上流 spec 自身と closed 課題〈Issue-0084/0098〉に移設前の状態を記述した行が正当に残るため）。

- [ ] **Step 9-3: 重複ゼロ確認**（特徴句。期待値を明記）

```bash
grep -rl "写像欠落" skills/            # 期待: skills/pre-finalization-review/SKILL.md の 1 ファイルのみ
grep -rl "ai-dev.mergepractice" skills/  # 期待: skills/start-work/references/merge-practice.md の 1 ファイルのみ
```

- [ ] **Step 9-4: サイズ・到達実測（記録。合否基準ではない）**

```bash
wc -c skills/start-work/SKILL.md skills/pre-finalization-review/SKILL.md skills/start-work/references/merge-practice.md
```

start-work 単体と「確定点到達セッションの合計」（start-work＋pre-finalization-review）を handoff へ記録（Issue-0105 側は Task 8 で記入済み）。あわせて start-work の新ポインタの表記どおりに `references/merge-practice.md` を（skills/start-work/ を基点として）Read で解決・読了できることを 1 回確認し、結果を handoff へ記録する（記録には「パス解決の確認であり、完了処理の発火経路の実走ではない」旨を明記する）。

### Task 10: version bump → 執行点 4 手順 → コミット

- [ ] **Step 10-1: version bump**。`.claude-plugin/plugin.json` と `.claude-plugin/marketplace.json` の `"version": "0.1.12"` を `"0.1.13"` へ（両方）

- [ ] **Step 10-2: 生成器実行**

```powershell
./scripts/build-dist.ps1          # 期待: 正常終了（非ゼロ終了なら違反を修正して再実行）
./scripts/build-dist.ps1 -Check   # 期待: 差分なし
./scripts/sync-template.ps1 -Check # 期待: 差分なし（template 対象ソースは非変更）
```

- [ ] **Step 10-3: 配布物の目視 5 点**。`dist/skills/start-work/SKILL.md`・`dist/skills/start-work/references/merge-practice.md`・`dist/skills/pre-finalization-review/SKILL.md` を読み、R1-a 破損（括弧内の説明語残り）・半角括弧・書式例の実在固有名・自己参照（「本リポジトリ」等）・スクリプトの docstring／表示メッセージ（本サイクルは .ps1/.py 非変更のため非該当と記録）の 5 点（CONTRIBUTING「機械判定が届かない領域」の表の写し）を確認。特に旧 L152 相当が dist で `**停止判定**` 系の壊れなく出ていること

- [ ] **Step 10-4: コミット 1（配布対象一式）**

```bash
git add skills/start-work/SKILL.md skills/start-work/references/merge-practice.md skills/pre-finalization-review/SKILL.md skills/decision-log/SKILL.md skills/session-handoff/SKILL.md skills/feature-block-design/SKILL.md skills/retrospective/SKILL.md CONTRIBUTING.md .claude-plugin/plugin.json .claude-plugin/marketplace.json dist/ .agents/plugins/marketplace.json
git status --short   # staged を確認（未追跡の docs/inbox/ 等を巻き込まないこと）
git commit -m "feat: start-work のドメイン規範 2 節を責務帰属で移設（ADR-0116。plugin 0.1.13）"
```

- [ ] **Step 10-5: コミット 2（docs 側の張り替え・記録）**

```bash
git add docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md docs/current/specs/2026-05-01-retrospective-design.md docs/working/issues/flow/0107-iterative-review-recommendation-divergence/0107-iterative-review-recommendation-divergence.md docs/working/issues/flow/0105-skill-md-size-growth-no-norm.md README.md docs/records/decisions/0072-pre-finalization-review-triggered-by-user-only.md docs/records/decisions/0080-review-presentation-scaled-by-unreviewed-normative-content.md docs/records/decisions/0091-session-handoff-doc-clarity-fixes.md docs/records/decisions/0092-cycle-wide-consistency-check-before-adr-promotion.md docs/records/decisions/0105-integration-design-wiring-two-commons-and-simplification.md docs/records/decisions/0106-two-layer-wiring-for-merge-mode-norm.md docs/records/decisions/0107-iterative-review-recommendation-by-revision-nature.md
git status --short
git commit -m "docs: 正本移設に伴う参照張り替えと ADR 部分修正注記 7 件（ADR-0116）"
```

handoff（`docs/working/handoff/feature_start-work-responsibility-split.md`）は本 2 コミットには含めず、セッション終了処理（session-handoff finalize）でコミットする。

### 完了基準との対応（spec 完了基準 1〜8）

| spec 完了基準 | 担うタスク |
|---|---|
| 1 start-work 残留化 | Task 3 |
| 2 merge-practice.md | Task 1 |
| 3 pre-finalization-review 2 操作構成 | Task 2 |
| 4 張り替え全数 | Task 2〜5 |
| 5 検証 3 種 | Task 9 |
| 6 部分修正注記（全数走査済み・7 件） | Task 6 |
| 7 Issue-0105 追記 | Task 8 |
| 8 version bump＋執行点 | Task 10 |
