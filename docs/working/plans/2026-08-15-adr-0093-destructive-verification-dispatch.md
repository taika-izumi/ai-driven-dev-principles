# ADR-0093 実装計画: 破壊的検証の委譲制約

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ADR-0093 の決定（B 群へ「破壊的検証」条件を追加・判定行キー追加・受け取り時確認・既存並列行への絶対パス追記）を `subagent-dispatch` と同期対象 3 文書へ実装し、配布物を再生成する。

**Architecture:** 正本は ADR-0093 の Decision / Consequences。編集は skills/ 2 ファイル＋docs 4 ファイル（spec・pitfalls・ADR-0066/0071 追記）＋version 2 ファイル。skills/ は配布対象ソースのため記法規約（R1〜R5）に適合させ、執行点 4 手順（生成器実行・両 -Check・dist 同コミット・目視 5 点）で確定する。

**Tech Stack:** Markdown、PowerShell（`scripts/build-dist.ps1` / `scripts/sync-template.ps1`）、git。

**検証の前提（期待値の根拠）:** 各 grep 期待値は本計画のタスクが挿入する文言から数えた値。タスクの文言を変更した場合は期待値を再計算すること。

---

### Task 1: `skills/subagent-dispatch/SKILL.md` の改定

**Files:**
- Modify: `skills/subagent-dispatch/SKILL.md`

- [ ] **Step 1: frontmatter description の行数を更新**

3 行目の description 内、次を置換:

```
旧: B 群の発火条件表 5 行を全行読み下ろして判定行を残し
新: B 群の発火条件表 6 行を全行読み下ろして判定行を残し
```

- [ ] **Step 2: 手順へ受け取り時確認のステップ 5 を追加**

「## 手順」の項目 4（「各項目は根拠を一言添えた文で書く…」の行）の直後に追加:

```markdown
5. 破壊的検証（B 群の該当行）を委譲した場合は、受け取り時に委譲先の報告のみへ依存せず、自ら状態比較（同行の展開項目と同じ手段）を実行して確認する。委譲先が複製実施を報告しながら実リポジトリが破壊されていた実測があるため（Issue-0076）
```

- [ ] **Step 3: 判定行の形式へキーを追加**

コードフェンス内の判定行例を置換:

```
旧: B群判定: 検査=yes / ミューテーション=no / 並列書き換え=no / 計画実装=no / 長時間書き込み=no
新: B群判定: 検査=yes / ミューテーション=no / 並列書き換え=no / 計画実装=no / 長時間書き込み=no / 破壊的検証=no
```

- [ ] **Step 4: B 群見出しの条件数を更新**

```
旧: ## B 群: タスクの型で条件発火（5 条件）
新: ## B 群: タスクの型で条件発火（6 条件）
```

- [ ] **Step 5: 既存「並列書き換え」行へ絶対パス項目を追記**

B 群表の当該行を次で置換（1 行）:

```markdown
| 並列に委譲し、かつ委譲先がファイルを書き換えるとき | worktree または `git archive` による隔離コピーを与えること / 隔離コピー内でもすべてのファイル操作で絶対パスを使わせること（隔離コピーの供与だけでは、シェルの現在位置に依存する相対パスが隔離の外の元ファイルを指す事故機構が残るため） | 同一ツリー並列でミューテーションが相互汚染し、汚染中の測定 281/1 とクリーンな木 282/0 が食い違い「回帰」と読み違える寸前だった。汚染の不在を事後に証明する手段も無い。絶対パス項目は複製内から実リポジトリを書き換えた事故由来（出所: LoopForAlpha#Issue-0069 / Issue-0076） |
```

- [ ] **Step 6: B 群表へ新規行を追加**

「長時間かつ書き込みを伴う作業を委譲するとき」の行の直後に追加（1 行）:

```markdown
| 破壊的検証（既存ファイルの書き換え・破壊を伴い、書き換えを成果物として残さない検証・実験）を委譲するとき | 隔離を与えること。サブエージェントを隔離コピー内で起動するツール機構（プロセスの作業ディレクトリが隔離側を指すと確認できるもの）を第一選択とし、手動複製ならコピー元・コピー先・手段を明記する。隔離コピーが検証対象の現作業ツリー状態（未追跡・未コミット分を含む）を含むことを確認し、並列委譲では隔離を委譲ごとに分ける / すべてのファイル操作で絶対パスを使わせ、破壊的な書き込み先が隔離ルート配下であることを実行前に突合させること（シェルの現在位置とプロセスの作業ディレクトリが一致しないランタイムでは相対パスが隔離の外を指し、絶対パスでも実リポジトリを指せば被害は同じため） / 検証対象範囲のファイル一覧と内容ハッシュを作業前後で記録・比較させ、想定した変更以外の差分がないことと、途中で観測した差分・復旧の有無を報告に含めさせること（実リポジトリのルートを絶対パス指定した git status は補助にできるが、未追跡ファイルの内容改変・ignore 対象・リポジトリ外の破壊は検出できない） | 複製での検証を明記し委譲先も複製実施を報告したのに、実リポジトリが 2 度破壊された（決定記録インデックス 92 行の空化・配布物への BOM 混入）。全件が単一プロジェクト出所。世代: claude-fable-5（出所: Issue-0076 / MakeAiInstructions-2026-08-08-06 / -2026-08-08-09） |
```

- [ ] **Step 7: 表直後の総括段落の主語を現状に合わせる**

```
旧: A 群・B 群いずれの根拠も単一プロジェクトの運用から得たもので、他プロジェクトへの一般化は保証されない。
新: A 群・B 群の各項目の根拠はそれぞれ単一プロジェクトの運用から得たもので、他プロジェクトへの一般化は保証されない。
```

- [ ] **Step 8: 検証**

Run: `grep -c "破壊的検証" skills/subagent-dispatch/SKILL.md`
Expected: `3`（手順 5・判定行例・新規行の条件列。Step 5/6 の他の文言には「破壊的検証」の 4 文字連続は現れない）

Run: `grep -c "6 条件\|6 行" skills/subagent-dispatch/SKILL.md`
Expected: `2`（description と見出し）

Run: `grep -c "5 条件\|発火条件表 5 行" skills/subagent-dispatch/SKILL.md`
Expected: `0`

### Task 2: spec スナップショットの更新

**Files:**
- Modify: `docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md`

- [ ] **Step 1: 根拠 ADR 行（5 行目）へ ADR-0093 を追記**

行末の「ADR-0073（根拠・世代の記録と退役経路）」の直後に追加:

```
、ADR-0093（破壊的検証の委譲制約と受け取り時確認）
```

- [ ] **Step 2: B 群の条件数・行数（46 行目）を更新**

```
旧: **B 群（条件発火・5 条件 8 項目）**: 委譲先の作業量を増やすため、タスクの型で発火させる。5 行の表を毎回読み下ろし、
新: **B 群（条件発火・6 条件 12 項目）**: 委譲先の作業量を増やすため、タスクの型で発火させる。6 行の表を毎回読み下ろし、
```

（項目数の内訳: 検査 2＋ミューテーション 3＋並列書き換え 2＋計画実装 1＋長時間 1＋破壊的検証 3 ＝ 12）

- [ ] **Step 3: 判定行フェンス（51 行目）へキーを追加**

Task 1 Step 3 と同一の置換（`/ 破壊的検証=no` を末尾へ追加）。

- [ ] **Step 4: B 群表の並列書き換え行を更新し、新規行を追加**

並列書き換え行（60 行目）を置換:

```markdown
| 並列に委譲し、かつ委譲先がファイルを書き換えるとき | worktree または `git archive` による隔離コピーを与えること / 隔離コピー内でもすべてのファイル操作で絶対パスを使わせること |
```

表末尾（「長時間かつ書き込みを伴う…」行の直後）に追加:

```markdown
| 破壊的検証（書き換えを成果物として残さない検証・実験）を委譲するとき | サブエージェントを隔離コピー内で起動するツール機構を第一選択（プロセスの作業ディレクトリの隔離を確認）とし、手動複製はコピー元・コピー先・手段を明記。隔離コピーが現作業ツリー状態を含むことを確認し、並列は隔離を委譲ごとに分けること / 絶対パスを使わせ、破壊的な書き込み先が隔離ルート配下であることを突合させること / 対象範囲の内容ハッシュを前後比較させ、想定外の差分と復旧の有無を報告させること |
```

- [ ] **Step 5: 受け取り時確認の 1 文を追加**

表直後の段落「担保の本体は…見直してよい（ADR-0073。…）。」の直後（66 行目「ミューテーション検査」段落の前）に独立段落として追加:

```markdown
破壊的検証の委譲では、委譲側は受け取り時に委譲先の報告のみへ依存せず、自ら状態比較を実行して確認する（ADR-0093）。
```

- [ ] **Step 6: pre-finalization-review 手順の骨子 4（90 行目）を更新**

```
旧: 4. 並列かつ書き換えを伴う場合は隔離コピーを与える（ADR-0066 B 群の該当条件）
新: 4. レビュアーが写経実行等でファイルを書き換える場合の隔離・絶対パス・前後状態比較は、subagent-dispatch B 群の該当条件（破壊的検証・並列書き換え）に従う（ADR-0093）
```

- [ ] **Step 7: 検証**

Run: `grep -c "破壊的検証" docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md`
Expected: `5`（根拠 ADR 行の追記・判定行フェンス・新規行の条件列・受け取り時確認の段落・骨子 4）

Run: `grep -c "5 条件\|5 行の表" docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md`
Expected: `0`

### Task 3: `skills/pre-finalization-review/SKILL.md` 手順 4 の張り替え

**Files:**
- Modify: `skills/pre-finalization-review/SKILL.md:26`

- [ ] **Step 1: 手順 4 を置換**

```
旧: 4. **隔離**: 観点を並列で回し、かつレビュアーが写経実行等でファイルを書き換える場合、worktree または `git archive` による隔離コピーを与える（`subagent-dispatch` B 群の該当条件）
新: 4. **隔離**: レビュアーが写経実行等でファイルを書き換える場合の隔離・絶対パス・前後状態比較は、`subagent-dispatch` B 群の該当条件（破壊的検証・並列書き換え）の展開項目に従う
```

- [ ] **Step 2: 検証**

Run: `grep -c "破壊的検証" skills/pre-finalization-review/SKILL.md`
Expected: `1`

### Task 4: `docs/reference/powershell-pitfalls.md` の参照更新

**Files:**
- Modify: `docs/reference/powershell-pitfalls.md:8`

- [ ] **Step 1: Set-Location 項の末尾を置換**

```
旧: サブエージェントへ破壊的検証を委譲するときは、複製の作り方と絶対パスの使用を明示する（Issue-0076。同じ機構で 2 度の実害: 決定記録インデックス 92 行が空に／配布物に BOM 混入）
新: サブエージェントへ破壊的検証を委譲するときの制約一式は `subagent-dispatch` B 群「破壊的検証」の行が定める（ADR-0093。出所: Issue-0076。同じ機構で 2 度の実害: 決定記録インデックス 92 行が空に／配布物に BOM 混入）
```

- [ ] **Step 2: 検証**

Run: `grep -c "ADR-0093" docs/reference/powershell-pitfalls.md`
Expected: `1`

### Task 5: ADR-0066 / ADR-0071 への部分修正追記（ADR-0093 Decision 6）

**Files:**
- Modify: `docs/records/decisions/0066-dispatch-constraints-split-always-vs-conditional.md`（ファイル名は `ls docs/records/decisions/0066-*.md` で確認）
- Modify: `docs/records/decisions/0071-*.md`（同上）

- [ ] **Step 1: ADR-0066 の Consequences 末尾へ追記**

```markdown
- 2026-08-15 部分修正（ADR-0093）: B 群へ発火条件「破壊的検証」が追加され 5 条件 → 6 条件となり、「並列書き換え」行の展開項目に絶対パス使用が追加された。本 ADR の A 群 / B 群の分割構造は現役のまま維持する
```

- [ ] **Step 2: ADR-0071 の Consequences 末尾へ追記**

```markdown
- 2026-08-15 部分修正（ADR-0093）: 判定行の形式へキー「破壊的検証」が追加され 6 キーとなった。判定行による読み下ろし担保の設計は現役のまま維持する
```

- [ ] **Step 3: 検証**

Run: `grep -l "ADR-0093" docs/records/decisions/0066-*.md docs/records/decisions/0071-*.md`
Expected: 2 ファイルとも列挙される（Status は Accepted のまま変更しない。インデックスも変更しない）

### Task 6: version bump（0.1.3 → 0.1.4）

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: 両ファイルの `"version": "0.1.3"` を `"version": "0.1.4"` へ置換**

- [ ] **Step 2: 検証**

Run: `grep -rn "0.1.3" .claude-plugin/`
Expected: 0 件

### Task 7: 配布物の生成と検査（執行点 4 手順）

**Files:**
- Regenerate: `dist/skills/subagent-dispatch/SKILL.md`, `dist/skills/pre-finalization-review/SKILL.md`

- [ ] **Step 1: 生成器を実行**

Run: `pwsh -File scripts/build-dist.ps1`
Expected: exit 0（規約違反があれば非ゼロ終了する。違反が出たら Task 1/3 の文言を修正して再実行）

- [ ] **Step 2: 両者を -Check で実行**

Run: `pwsh -File scripts/build-dist.ps1 -Check` → Expected: exit 0
Run: `pwsh -File scripts/sync-template.ps1 -Check` → Expected: exit 0（template 対象は無変更のため差分なし）

- [ ] **Step 3: 生成物の検証**

Run: `grep -c "破壊的検証" dist/skills/subagent-dispatch/SKILL.md`
Expected: `3`（出所注記は除去されるが「破壊的検証」の語は残る）

Run: `grep -c "Issue-0076\|MakeAiInstructions-2026" dist/skills/subagent-dispatch/SKILL.md`
Expected: `0`（出所識別子は配布物から除去される）

- [ ] **Step 4: 機械判定が届かない 5 型の目視**

`dist/skills/subagent-dispatch/SKILL.md` と `dist/skills/pre-finalization-review/SKILL.md` の変更箇所を読み、次を確認: (1) 括弧内に識別子以外の語が同居した残骸（「（の型）」等）がない (2) 半角括弧の空残骸がない (3) 書式例に実在の固有名がない (4) 「本リポジトリ」等の自己参照がない (5) 除去により文が壊れた箇所がない

### Task 8: コミット

- [ ] **Step 1: ステージ内容の確認**

Run: `git status --short`
Expected: 変更は Task 1〜7 の対象ファイル＋本計画ファイルのみ（未追跡の inbox 群・conversation_log.md を含めないこと）

- [ ] **Step 2: pathspec 指定でコミット**

メッセージは一時ファイル（例: スクラッチパッド配下の `commit-msg-impl.txt`）へ書き、`git commit -F <その絶対パス>` で与える。メッセージ 1 行目: `feat: subagent-dispatch へ破壊的検証の委譲制約を追加（ADR-0093、plugin 0.1.4）`

```bash
git add skills/subagent-dispatch/SKILL.md skills/pre-finalization-review/SKILL.md dist/skills/subagent-dispatch/SKILL.md dist/skills/pre-finalization-review/SKILL.md docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md docs/reference/powershell-pitfalls.md docs/records/decisions/0066-*.md docs/records/decisions/0071-*.md .claude-plugin/plugin.json .claude-plugin/marketplace.json docs/working/plans/2026-08-15-adr-0093-destructive-verification-dispatch.md
git commit -F <一時ファイルの絶対パス>
```

### 完了後のフロー（本計画の外。start-work の手順に従う）

実装完了の検証後、`decision-log` の昇格手順（サイクル全体整合検査つき）で ADR-0093 を Accepted へ昇格し、Issue-0076 を close する。master へのマージ（--no-ff）・retrospective・配布反映（ユーザーによる `/plugin marketplace update`）はセッションのフローで実施する。
