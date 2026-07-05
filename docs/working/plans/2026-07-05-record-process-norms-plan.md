# 記録プロセス規範一括対策 実装計画（Issue-0009 / 0010 / 0011）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ADR-0030/0031/0032 で決定した記録プロセス規範3件を、既存ガイドライン文書（スキル3件・CLAUDE.md・folder-structure.md・CONTRIBUTING.md）へ追記し、ADR 昇格と issue close まで完了させる。

**Architecture:** ドキュメントのみの変更（コード・テストなし）。課題ごとに1タスク＝1コミットとし、各タスクの検証は grep による反映確認で行う。最後に template 同期 → ADR Accepted 昇格 → issue close。

**Tech Stack:** Markdown、PowerShell（`scripts/sync-template.ps1`）、git

**Spec:** `docs/current/specs/2026-07-05-record-process-norms-design.md`

**前提知識:**

- 本リポジトリは AI 駆動開発のメタ・ガイドライン集。`skills/` はプラグイン配信対象（template.manifest には含めない）、`CLAUDE.md` と `docs/overview/folder-structure.md` は template.manifest 対象（変更後に sync-template 実行が必要）
- Issue-0002（open）: sync-template.ps1 は改行コード差分ノイズを出すことがある。無関係ファイルに改行のみの差分が出たら `git restore` で戻す（前サイクルの実績ある回避策）
- 日付はすべて 2026-07-05 を使う

---

### Task 1: Issue-0009 対策 — 即ドラフト作成・コミット遅延（ADR-0030）

**Files:**
- Modify: `skills/decision-log/SKILL.md`（「### 4. コミットする」と「ユーザーへの確認」の保留行）
- Modify: `CLAUDE.md`（「意思決定の即時記録（継続適用）」セクション）
- Modify: `skills/start-work/SKILL.md`（引用ブロック、Phase 2 Post、セッション終了処理）

- [ ] **Step 1: decision-log の手順4を「コミットのタイミング」に書き換え**

`skills/decision-log/SKILL.md` の以下のブロック:

```markdown
### 4. コミットする

ADRファイルとインデックスを一緒にコミットする:

```bash
git add docs/records/decisions/NNNN-slug.md docs/records/decisions/README.md
git commit -m "adr: NNNN - タイトル"
```
```

を次に置換する:

```markdown
### 4. コミットのタイミング（ADR-0030）

ADRファイルとインデックスは一緒にコミットする。ただしコミットは**関連論点が収束したチェックポイント**で行う（ドラフト作成・インデックス更新は即時のまま）:

| ドラフトの文脈 | コミットするチェックポイント |
|--------------|--------------------------|
| brainstorming 中に作成したドラフト | 設計承認時 |
| それ以外 | ユーザーがその決定の確定を確認した時 |
| 関連論点が既に収束している場合 | 即コミットしてよい |

未コミットの間、ドラフトは関連論点の進展に応じて**書き直し自由**とする（書き直しは想定された更新であり手戻りではない）。コミット漏れは `start-work` の Phase 2 Post とセッション終了処理で確認される。

```bash
git add docs/records/decisions/NNNN-slug.md docs/records/decisions/README.md
git commit -m "adr: NNNN - タイトル"
```
```

- [ ] **Step 2: decision-log「ユーザーへの確認」の保留行に補足**

同ファイルの行:

```markdown
- 保留: Proposed のまま。確定チェックポイントで改めて昇格させる
```

を次に置換する:

```markdown
- 保留: Proposed のまま。確定チェックポイントで改めて昇格させる（未コミットのドラフトは収束チェックポイントでコミットする。それまで書き直し自由。ADR-0030）
```

- [ ] **Step 3: CLAUDE.md のフロー文言に補足**

`CLAUDE.md` の行:

```markdown
「スキルの途中だから後で」は禁止。検出 → 即ドラフト作成 → ユーザー承認 → 元のスキルへ復帰。
```

を次に置換する:

```markdown
「スキルの途中だから後で」は禁止。検出 → 即ドラフト作成 → ユーザー承認 → 元のスキルへ復帰。ただしドラフトのコミットは、関連論点が収束したチェックポイントまで遅延してよい（収束までドラフトは書き直し自由。`decision-log` スキルの手順に従う）。
```

- [ ] **Step 4: start-work の引用ブロックを CLAUDE.md と整合**

`skills/start-work/SKILL.md` の行:

```markdown
> 「スキルの途中だから後で」は禁止。検出 → 即ドラフト作成 → ユーザー承認 → 元のスキルへ復帰。
```

を次に置換する:

```markdown
> 「スキルの途中だから後で」は禁止。検出 → 即ドラフト作成 → ユーザー承認 → 元のスキルへ復帰。ただしドラフトのコミットは、関連論点が収束したチェックポイントまで遅延してよい（収束までドラフトは書き直し自由。`decision-log` スキルの手順に従う）。
```

- [ ] **Step 5: start-work Phase 2 Post に未コミット確認を追加**

同ファイルの文:

```markdown
   また、設計承認・実装完了などのチェックポイントを通過した場合、Proposed のまま据え置かれているADRのうち決定が確定したものを Accepted へ昇格させる（`decision-log` の「承認の昇格」に従う）。
```

を次に置換する:

```markdown
   また、設計承認・実装完了などのチェックポイントを通過した場合、Proposed のまま据え置かれているADRのうち決定が確定したものを Accepted へ昇格させる（`decision-log` の「承認の昇格」に従う）。あわせて、未コミットの ADR ドラフトのうち関連論点が収束したものをコミットする（ADR-0030）。
```

- [ ] **Step 6: start-work セッション終了処理に未コミット確認ステップを追加**

同ファイルのセッション終了処理の番号付きリスト:

```markdown
2. `session-handoff` の **finalize** 操作を呼ぶ
3. ハンドオフの「次セッション開始時のアクション」が確実に埋まっていることを確認する
4. ユーザーに完了を報告する
```

を次に置換する（新ステップ2を挿入し繰り下げ）:

```markdown
2. 未コミットの ADR ドラフトがないか確認し、関連論点が収束済みのものはコミットする（Accepted 昇格漏れの確認と合わせて行う。ADR-0030 / ADR-0019）
3. `session-handoff` の **finalize** 操作を呼ぶ
4. ハンドオフの「次セッション開始時のアクション」が確実に埋まっていることを確認する
5. ユーザーに完了を報告する
```

- [ ] **Step 7: 反映確認**

Run: `grep -c "ADR-0030" skills/decision-log/SKILL.md skills/start-work/SKILL.md`
Expected: decision-log に 2 箇所以上、start-work に 2 箇所以上

Run: `grep -c "収束したチェックポイントまで遅延" CLAUDE.md skills/start-work/SKILL.md`
Expected: 各 1 箇所

- [ ] **Step 8: コミット**

```bash
git add skills/decision-log/SKILL.md CLAUDE.md skills/start-work/SKILL.md
git commit -m "feat: ADR ドラフトのコミット遅延規範を decision-log / CLAUDE.md / start-work に追加（ADR-0030, Issue-0009 対策）"
```

---

### Task 2: Issue-0010 対策 — 再発の一次記録を issue「検討状況」へ（ADR-0031）

**Files:**
- Modify: `docs/overview/folder-structure.md`（§7.3 ライフサイクル、§7.4 フォーマット）
- Modify: `skills/retrospective/SKILL.md`（Phase 2 起票手順、「関連」セクション）

- [ ] **Step 1: folder-structure §7.3 に再発記録ルールを追記**

`docs/overview/folder-structure.md` の行:

```markdown
- **Status は open → closed** — 対策方針が決定したら ADR を作成し、課題の「結論」に ADR 番号を記載して close する（進行中の作業 → 追跡型の記録への遷移）
```

を次に置換する（直後に新規箇条書きを追加）:

```markdown
- **Status は open → closed** — 対策方針が決定したら ADR を作成し、課題の「結論」に ADR 番号を記載して close する（進行中の作業 → 追跡型の記録への遷移）
- **再発・進展の一次記録は issue の「検討状況」**（ADR-0031） — 既存 open 課題の再発・進展を検出したら、検出したその場で該当 issue の「検討状況」に1行追記する（形式: `YYYY-MM-DD: 事象の要約（必要なら詳細への参照）`）。振り返りファイルで言及する場合は Issue-NNNN への参照を付け、一次記録は issue 側とする
```

- [ ] **Step 2: folder-structure §7.4 の「検討状況」説明を更新**

同ファイルの課題フォーマット例内:

```markdown
## 検討状況

（対策検討の経過。長期化したらフォルダ昇格を検討）
```

を次に置換する:

```markdown
## 検討状況

（対策検討の経過と、再発・進展の記録。再発は `YYYY-MM-DD: 事象の要約` 形式で1行ずつ追記する。長期化したらフォルダ昇格を検討）
```

- [ ] **Step 3: retrospective の起票手順に再発の扱いを追加**

`skills/retrospective/SKILL.md` の番号付きリスト末尾:

```markdown
4. 振り返りファイル側の各課題項目に「**起票**: Issue-NNNN」行を含めて書き出す（初回書き込みで記載するため、上書き禁止規約 ADR-0011 と衝突しない）
```

を次に置換する（ステップ5を追加）:

```markdown
4. 振り返りファイル側の各課題項目に「**起票**: Issue-NNNN」行を含めて書き出す（初回書き込みで記載するため、上書き禁止規約 ADR-0011 と衝突しない）
5. **既存 open 課題の再発・進展は新規起票しない**（ADR-0031）。該当 issue の「検討状況」への1行追記（`YYYY-MM-DD: 事象の要約`）が済んでいるか確認し、未追記ならこの時点で追記する。振り返りファイルで言及する場合は Issue-NNNN への参照を付ける
```

- [ ] **Step 4: retrospective の「関連」セクションに ADR-0031 を追加**

同ファイルの:

```markdown
- ADR-0028: 振り返り課題の全件起票と issues の system/flow フォルダ分割
```

を次に置換する:

```markdown
- ADR-0031: 既存 open 課題の再発・進展は issue の「検討状況」へ一次記録（再発は新規起票しない）
- ADR-0028: 振り返り課題の全件起票と issues の system/flow フォルダ分割
```

- [ ] **Step 5: 反映確認**

Run: `grep -c "ADR-0031" docs/overview/folder-structure.md skills/retrospective/SKILL.md`
Expected: folder-structure に 1 箇所、retrospective に 2 箇所

- [ ] **Step 6: コミット**

```bash
git add docs/overview/folder-structure.md skills/retrospective/SKILL.md
git commit -m "feat: 既存 open 課題の再発記録ルールを folder-structure / retrospective に追加（ADR-0031, Issue-0010 対策）"
```

---

### Task 3: Issue-0011 対策 — エージェント実行可能性チェック（ADR-0032）

**Files:**
- Modify: `skills/decision-log/SKILL.md`（記述規律の注記ブロック）
- Modify: `CONTRIBUTING.md`（「ADRを記録するとき」記述規律、「CLAUDE.md を更新するとき」注意事項）

- [ ] **Step 1: decision-log の記述規律に実行可能性チェックを追加**

`skills/decision-log/SKILL.md` の注記:

```markdown
> **記述規律（ADR-0019）**: ADRには「下した決定」のみを記載する。仕様検討の途中で生じた**未解決の論点（未決事項）は ADR に書かない**。未決事項は課題（`docs/working/issues/`）として分離する（後述「未決事項（open questions）の扱い」）。
```

を次に置換する（注記を1つ追加）:

```markdown
> **記述規律（ADR-0019）**: ADRには「下した決定」のみを記載する。仕様検討の途中で生じた**未解決の論点（未決事項）は ADR に書かない**。未決事項は課題（`docs/working/issues/`）として分離する（後述「未決事項（open questions）の扱い」）。

> **実行可能性チェック（ADR-0032）**: 撤去基準・発動条件・適用条件などの判定条件は、実行主体であるエージェントが**実際に観測・実行できる事実**（例: ユーザーの明示指示、ファイル・設定の存在、コマンド出力）で書くこと。観測できない状態（例: 他モデルの利用状況、ユーザー画面上の事象、セッション横断の利用履歴）を判定条件にしない。エージェントが判定できない場合は「ユーザーが判断し指示した時点」のように判断主体をユーザーへ明示的に移す。
```

- [ ] **Step 2: CONTRIBUTING「ADRを記録するとき」の記述規律に追記**

`CONTRIBUTING.md` の「### 記述規律（ADR-0019）」セクション:

```markdown
- ADRは**原則 Proposed で作成し、決定が確定したチェックポイントで Accepted に昇格**させる（brainstorming起点なら設計承認時、実装を伴うなら実装完了後）。作成直後の即 Accepted 化はしない。
```

を次に置換する（箇条書きを1つ追加）:

```markdown
- ADRは**原則 Proposed で作成し、決定が確定したチェックポイントで Accepted に昇格**させる（brainstorming起点なら設計承認時、実装を伴うなら実装完了後）。作成直後の即 Accepted 化はしない。
- 撤去基準・発動条件・適用条件などの判定条件は、実行主体であるエージェントが**観測・実行できる事実**で書く。エージェントが判定できない条件は「ユーザーが判断し指示した時点」のように判断主体をユーザーへ明示的に移す（ADR-0032）。
```

- [ ] **Step 3: CONTRIBUTING「CLAUDE.md を更新するとき」の注意事項に追記**

同ファイルの:

```markdown
- 記述言語は日本語で統一する（plugin注入部分は除く）
```

を次に置換する:

```markdown
- 記述言語は日本語で統一する（plugin注入部分は除く）
- 規範の適用条件・撤去基準は、エージェントが観測・実行できる事実で書くこと（ADR-0032）
```

- [ ] **Step 4: 反映確認**

Run: `grep -c "ADR-0032" skills/decision-log/SKILL.md CONTRIBUTING.md`
Expected: decision-log に 1 箇所、CONTRIBUTING に 2 箇所

- [ ] **Step 5: コミット**

```bash
git add skills/decision-log/SKILL.md CONTRIBUTING.md
git commit -m "feat: 規範・ADR の実行可能性チェック観点を decision-log / CONTRIBUTING に追加（ADR-0032, Issue-0011 対策）"
```

---

### Task 4: template 同期

**Files:**
- Modify: `template/` 配下（`scripts/sync-template.ps1` による自動生成）

- [ ] **Step 1: sync-template を実行**

Run（PowerShell）: `./scripts/sync-template.ps1`
Expected: エラーなく完了

- [ ] **Step 2: 差分を確認**

Run: `git status --short` と `git diff --stat`
Expected: `template/` 配下の CLAUDE.md と folder-structure.md 対応ファイルに今回の追記が反映されている

**注意（Issue-0002）**: 今回の変更と無関係なファイルに改行コードのみの差分が出た場合は `git restore <該当ファイル>` で戻す。その場合、Issue-0002 の再発として `docs/working/issues/system/0002-sync-template-line-endings.md` の「検討状況」に `2026-07-05: 本サイクルの template 同期でも改行のみ差分が再発、git restore で回避` を1行追記する（Task 2 で導入した ADR-0031 の規範の初回適用）。※0002 への追記は Task 5 のコミットに含めず、この場で `git add docs/working/issues/system/0002-sync-template-line-endings.md` してこの Task のコミットに含める

- [ ] **Step 3: コミット**

```bash
git add template/
git commit -m "chore: sync-template を実行し ADR-0030/0031 の規範追記を template へ反映"
```

---

### Task 5: ADR 昇格と issue close

**Files:**
- Modify: `docs/records/decisions/0030-adr-draft-commit-deferral.md` / `0031-issue-recurrence-recording.md` / `0032-agent-executability-check.md`（Status を Accepted へ）
- Modify: `docs/records/decisions/README.md`（3行の Status 更新）
- Modify: `docs/working/issues/flow/0009-adr-draft-timing.md` / `0010-issue-recurrence-recording.md` / `0011-norm-executability-check.md`（close 処理）
- Modify: `docs/working/issues/README.md`（3行の Status 更新）

- [ ] **Step 1: ADR 3本の Status を Accepted に変更**

各 ADR ファイルの `- **Status**: Proposed` を `- **Status**: Accepted` に置換する。

- [ ] **Step 2: decisions/README.md の3行を更新**

0030/0031/0032 の行の `Proposed` を `Accepted` に置換する。

- [ ] **Step 3: issue 3件を close**

各 issue ファイル（0009/0010/0011）に対して:

1. `- **Status**: open` → `- **Status**: closed`
2. `- **Opened**: 2026-07-05` の直後に `- **Closed**: 2026-07-05` を追加
3. 「検討状況」の `（未着手）` → `2026-07-05: 対策サイクル feature/record-process-norms で対策を設計・実装`
4. 「結論」の `（open）` を対応 ADR への参照に置換:
   - 0009: `ADR-0030（ADR ドラフトは即時作成・コミットは論点収束チェックポイントまで遅延可能とする）として規範化し、decision-log / CLAUDE.md / start-work に反映済み。`
   - 0010: `ADR-0031（既存 open 課題の再発・進展は issue ファイルの「検討状況」へ一次記録する）として規範化し、folder-structure §7 / retrospective スキルに反映済み。`
   - 0011: `ADR-0032（規範・ADR の判定条件はエージェントが観測・実行可能な事実で書く）として規範化し、decision-log / CONTRIBUTING に反映済み。`

- [ ] **Step 4: issues/README.md の3行を更新**

0009/0010/0011 の行の `open` を `closed` に置換する。

- [ ] **Step 5: 反映確認**

Run: `grep -l "Status.*: closed" docs/working/issues/flow/0009-adr-draft-timing.md docs/working/issues/flow/0010-issue-recurrence-recording.md docs/working/issues/flow/0011-norm-executability-check.md`
Expected: 3ファイルすべて出力される

Run: `grep -c "Proposed" docs/records/decisions/README.md`
Expected: 3（既存の 0013/0014/0018 のみ。0030-0032 は Accepted 化済み）

- [ ] **Step 6: コミット**

```bash
git add docs/records/decisions/ docs/working/issues/
git commit -m "docs: ADR-0030/0031/0032 を Accepted に昇格し Issue-0009/0010/0011 を close（実装完了）"
```

---

### Task 6: 最終検証とハンドオフ更新

- [ ] **Step 1: 全体整合の確認**

Run: `grep -rn "ADR-0030\|ADR-0031\|ADR-0032" skills/ CLAUDE.md CONTRIBUTING.md docs/overview/folder-structure.md --include="*.md" -l`
Expected: `skills/decision-log/SKILL.md`, `skills/start-work/SKILL.md`, `skills/retrospective/SKILL.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `docs/overview/folder-structure.md` の6ファイル

Run: `git log --oneline master..HEAD`
Expected: ADR 起票 → spec → Task 1〜5 のコミットが並ぶ

- [ ] **Step 2: ハンドオフ更新**

`docs/working/handoff/feature_record-process-norms.md` を更新する: 完了済みタスクへ移動、残作業を「merge → プラグイン更新（ユーザー操作）→ retrospective → finalize」に更新。

**実装完了後の残作業（プラン外・メインセッションで実施）:**

1. master へのマージ（superpowers:finishing-a-development-branch、ユーザー確認）
2. プラグイン更新（`/plugin marketplace update ai-driven-dev-principles`。ユーザー操作）
3. retrospective スキル起動（merge 直後）
4. handoff finalize
