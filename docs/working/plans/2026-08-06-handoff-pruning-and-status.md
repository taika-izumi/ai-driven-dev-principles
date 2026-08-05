# ハンドオフ剪定規約と Status 整合 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ハンドオフの二段階剪定規約（ADR-0075）・Status 4 値化（ADR-0076）・外部参照の安定識別子規約（ADR-0077）を `session-handoff` / `retrospective` の 2 スキルへ組み込み、Issue-0049 / Issue-0051 を解決する。

**Architecture:** スキル定義ファイル（markdown）の改定のみ。コード・テストは存在しないため、TDD の代替として「編集 → grep による整合突合 → コミット」を各タスクの検証単位とする。剪定の受け皿は git 履歴のみ（ADR-0074）。

**Tech Stack:** markdown / git / grep。プラグイン更新は Claude Code の `/plugin marketplace update`（ユーザー操作。ADR-0055）。

**Spec:** `docs/current/specs/2026-08-06-handoff-pruning-and-status-design.md`

**注意（このリポジトリ固有）:**

- コミットは `git commit -F <絶対パスの一時ファイル>` でマルチライン文字列を渡す（Issue-0015）
- コミット前に `git status --short` を確認し、untracked（`docs/inbox/` 残置 3 件・`docs/conversation_log.md`）とステージ済みの handoff ファイルを巻き込まない。コミットはパス指定（`git commit -F <msg> -- <paths>`）で行う（Issue-0020）
- `skills/` は template 対象外のため `scripts/sync-template.ps1` は実行しない（ADR-0016）

---

### Task 1: `skills/session-handoff/SKILL.md` の改定

**Files:**
- Modify: `skills/session-handoff/SKILL.md`

- [ ] **Step 1: frontmatter の description に cycle-reset を追記**

old:

```
description: "セッション間で作業を継続するためのハンドオフファイル（docs/working/handoff/<branch>.md）を読む・作成する・更新する・確定する。マイルストーン到達時とセッション終了時に呼ばれる。"
```

new:

```
description: "セッション間で作業を継続するためのハンドオフファイル（docs/working/handoff/<branch>.md）を読む・作成する・更新する・確定する・サイクル完了時にリセット（cycle-reset）する。マイルストーン到達時・セッション終了時・retrospective 完了時に呼ばれる。"
```

- [ ] **Step 2: フォーマット内の Status 行を 4 値化**

old:

```
- **Status**: in_progress | paused | completed
```

new:

```
- **Status**: in_progress | paused | completed | ready-for-next-cycle
```

- [ ] **Step 3: フォーマットのコードブロック直後に「Status の意味」表と「外部参照の書き方」を追加**

フォーマットの closing ``` の直後（「## 操作」の前）に以下を挿入:

```
### Status の意味（ADR-0076）

| 値 | 意味 |
|----|------|
| `in_progress` | 作業進行中 |
| `paused` | 中断中（再開待ち） |
| `completed` | 作業完了（feature ブランチのマージ完了時など、そのブランチの handoff が役目を終えた状態） |
| `ready-for-next-cycle` | サイクル完了・次サイクル待ち（長命ブランチの handoff が、retrospective 完了後にユーザーの次サイクル判断を待つ状態） |

### 外部参照の書き方（ADR-0077）

ハンドオフから外部文書を参照するときは、安定識別子（ADR-NNNN / Issue-NNNN / ファイルパス / コミットハッシュ）を必ず含めること。節名・項番だけの参照は書かない（安定識別子への併記は可。例: 「`skills/retrospective/SKILL.md` の Phase 3」は可、「振り返りスキルの仕上げ節」だけは不可）。参照先の構造変更で参照が壊れることを防ぐ。
```

- [ ] **Step 4: 操作数の宣言を 4 → 5 に更新**

old: `このスキルは4つの操作を提供する。呼び出し側は操作を明示すること。`
new: `このスキルは5つの操作を提供する。呼び出し側は操作を明示すること。`

- [ ] **Step 5: finalize の手順を差し替え（基準付き圧縮の組み込み・Status 分岐追加・旧手順 4 の統合）**

「### 4. finalize — セッション終了確定」の手順 1〜5 全体を以下に置き換える（旧手順 4「消化記録の過去分削除」は新手順 2 の圧縮基準 2 種目に統合される。コミットブロックはそのまま新手順 5 に残す）:

````
手順:
1. update と同様の更新を実施
2. **基準付き圧縮を実施する（ADR-0075）**。圧縮対象は次の 2 種のみ:
   - 詳細が他の正本（ADR / issue / worklog / plan / spec / コミット履歴）に記録済みの完了タスク・記述 → 1 行要約＋正本への参照（安定識別子）に置き換える
   - 役目を終えた状態情報（解消済みブロッカー、確定済み過去セッションの消化記録行。ADR-0057）→ 削除する

   **圧縮しないもの**: 正本が handoff 以外にないもの（進行中タスクの状態・残り、現役の申し送り・懸念）。無条件の 1 行要約はしない。落とした情報の受け皿は git 履歴のみとし、退避ファイルは作らない（ADR-0074）
3. **「次セッション開始時のアクション」セクションを必ず埋める**:
   - 最初に確認すべきファイル
   - 最初に実行すべきコマンド/スキル
   - 留意点
4. Status を更新する（作業継続なら `paused`、完了なら `completed`、まだ進行中なら `in_progress`）。cycle-reset 実施済みで次サイクル未着手のまま終了する場合は `ready-for-next-cycle` を維持する（`paused` 等で上書きしない）
5. ファイルを git に add してコミットする:

   ```powershell
   git add docs/working/handoff/<branch>.md
   git commit -m "chore: update handoff for <branch>"
   ```
````

- [ ] **Step 6: cycle-reset 操作を新設**

「### 4. finalize — セッション終了確定」ブロックの直後（「## 完了済みハンドオフの扱い」の前）に以下を挿入:

```
### 5. cycle-reset — サイクル完了リセット

呼ばれるタイミング: サブプロジェクトの master マージ後、`retrospective` の仕上げ（Phase 3）から呼ばれる（ADR-0075）

手順:
1. 完了サイクルの経緯を落とす（受け皿は git 履歴のみ。ADR-0074）:
   - 「完了済みタスク」を「過去サイクルは retrospective / git 履歴参照」の 1 行に集約する
   - 「Post ラッパー消化記録」の行を全行削除する
   - 本文各節に残る完了サイクル固有の経緯記述を除去する
2. 「既知のブロッカー・懸念」（申し送り）を **1 件ずつ現役性点検**し、現役のものだけを残す（一括削除も一括温存もしない。実測済みの申し送りは削ると同じ罠を再び踏むため、落とすのは役目を終えたと確認できたものだけ）
3. 「作業の目的・背景」を「直近サイクルの成果 1 段落＋次サイクル待ち」に書き直す
4. Status を `ready-for-next-cycle` へ更新し（ADR-0076）、「次セッション開始時のアクション」を次サイクル候補で更新する
5. ファイルを git に add する。コミットはしない（`retrospective` の「スキル内ではコミットしない」前提と整合させ、セッション終了時の finalize または通常フローのコミットに委ねる）
```

- [ ] **Step 7: 「完了済みハンドオフの扱い」のアーカイブ記述を ADR-0074 に合わせて更新**

old:

```
PR マージなどで作業完了した handoff は `Status: completed` のまま `docs/working/handoff/` に残す。アーカイブ機構（`docs/working/handoff/archive/` への移動）は本スキルでは未実装。将来必要になれば追加する。
```

new:

```
PR マージなどで作業完了した handoff は `Status: completed` のまま `docs/working/handoff/` に残す。アーカイブ機構（`docs/working/handoff/archive/` への移動）は設けない（ADR-0074。剪定・リセットで落とした情報の受け皿は git 履歴のみとする）。
```

- [ ] **Step 8: 編集結果を grep で確認**

Run: `grep -c "ready-for-next-cycle" skills/session-handoff/SKILL.md`
Expected: `4`（フォーマット行 / Status 表 / finalize 手順 4 / cycle-reset 手順 4）

Run: `grep -c "cycle-reset" skills/session-handoff/SKILL.md`
Expected: `3`（frontmatter / finalize 手順 4 / 操作 5 見出し）

Run: `grep -n "5つの操作" skills/session-handoff/SKILL.md`
Expected: 1 行ヒット

- [ ] **Step 9: コミット**

コミットメッセージを一時ファイルに書き、パス指定でコミット:

```
skills: session-handoff に二段階剪定・Status 4 値・安定参照規約を実装

- Status に ready-for-next-cycle を正式追加し意味表を定義（ADR-0076）
- 外部参照の安定識別子規約を追加（ADR-0077）
- finalize に基準付き圧縮を組み込み（ADR-0075 前段。旧手順 4 を統合）
- cycle-reset 操作を新設（ADR-0075 後段。受け皿は git 履歴のみ ADR-0074）

Issue-0049 / Issue-0051 対処。
```

Run: `git add skills/session-handoff/SKILL.md && git commit -F <msg-file> -- skills/session-handoff/SKILL.md`
Expected: 1 file changed

### Task 2: `skills/retrospective/SKILL.md` と既存 spec の修正

**Files:**
- Modify: `skills/retrospective/SKILL.md`（Phase 3 手順 3）
- Modify: `docs/current/specs/2026-05-01-retrospective-design.md`（Phase 3 記述の書き換え更新。スナップショット規約）

- [ ] **Step 1: retrospective SKILL.md の Phase 3 手順 3 を差し替え**

old:

```
3. `session-handoff` の **update** 操作を呼ぶ:
   - 「次セッション開始時のアクション」に「抽出した課題は issues に起票済み（Issue-NNNN〜。着手はユーザー判断）」旨を記す
   - handoff Status を `completed` → `ready-for-next-cycle` へ遷移
   - 課題が複数ある場合は優先順位の目安を併記してよい（着手の決定はユーザー）
```

new:

```
3. `session-handoff` の **cycle-reset** 操作を呼ぶ（剪定・書き換えの手順は session-handoff 側の定義に従う。ADR-0075）:
   - Status は `in_progress` → `ready-for-next-cycle` へ遷移する（ADR-0076）
   - 「次セッション開始時のアクション」に「抽出した課題は issues に起票済み（Issue-NNNN〜。着手はユーザー判断）」旨を記す
   - 課題が複数ある場合は優先順位の目安を併記してよい（着手の決定はユーザー）
```

- [ ] **Step 2: 既存 spec `2026-05-01-retrospective-design.md` の Phase 3 手順 3 を書き換え**

old:

```
3. `session-handoff update` を呼ぶ。「次セッション開始時のアクション」に起票済み issue 番号を記載し、Status を `ready-for-next-cycle` へ遷移する
```

new:

```
3. `session-handoff` の cycle-reset 操作を呼ぶ（剪定・書き換えの手順は session-handoff 側の定義に従う。ADR-0075）。「次セッション開始時のアクション」に起票済み issue 番号を記載し、Status を `in_progress` から `ready-for-next-cycle` へ遷移する（ADR-0076）
```

- [ ] **Step 3: 編集結果を grep で確認**

Run: `grep -c "cycle-reset" skills/retrospective/SKILL.md docs/current/specs/2026-05-01-retrospective-design.md`
Expected: 各ファイル `1`

Run: `grep -n 'completed` → `ready-for-next-cycle' skills/retrospective/SKILL.md`
Expected: ヒットなし（誤記述の解消）

Run: `grep -n "session-handoff update" docs/current/specs/2026-05-01-retrospective-design.md`
Expected: ヒットなし

- [ ] **Step 4: コミット**

コミットメッセージ:

```
skills: retrospective Phase 3 を cycle-reset 呼び出しに変更、既存 spec を書き換え更新

- update 呼び出し＋誤記述（completed からの遷移）を cycle-reset＋
  in_progress → ready-for-next-cycle に修正（ADR-0075 / ADR-0076）
- 2026-05-01-retrospective-design.md をスナップショット規約に従い書き換え

Issue-0051 対処。
```

Run: `git add skills/retrospective/SKILL.md docs/current/specs/2026-05-01-retrospective-design.md && git commit -F <msg-file> -- skills/retrospective/SKILL.md docs/current/specs/2026-05-01-retrospective-design.md`
Expected: 2 files changed

### Task 3: 2 スキル間の整合突合（spec 検証 1・2）

**Files:** なし（読み取りのみ）

- [ ] **Step 1: Status 値・操作名・遷移記述の突合**

Run: `grep -rn "ready-for-next-cycle" skills/`
Expected: `session-handoff/SKILL.md` に 4 行、`retrospective/SKILL.md` に 1 行、`start-work/SKILL.md` に 0 行（start-work は変更対象外）

Run: `grep -rn "cycle-reset" skills/ docs/current/specs/`
Expected: `session-handoff/SKILL.md` 3 行 / `retrospective/SKILL.md` 1 行 / `2026-05-01-retrospective-design.md` 1 行 / `2026-08-06-handoff-pruning-and-status-design.md`（本サイクル spec 内の言及）

- [ ] **Step 2: 旧記述の残存チェック**

Run: `grep -rn "アーカイブ機構.*未実装" skills/`
Expected: ヒットなし

### Task 4: プラグイン更新と Issue-0044 の同セッション実測

**Files:**
- Modify: `docs/working/issues/flow/0044-*.md`（検討状況へ実測結果を追記）

- [ ] **Step 1: ユーザーにプラグイン更新を依頼**

AI からは実行不可（ADR-0055）。ユーザーに `/plugin marketplace update ai-driven-dev-principles` の実行を依頼し、完了報告を待つ。

- [ ] **Step 2: 同セッションでの改定スキル起動を実測（Issue-0044）**

Skill ツールで `ai-driven-dev-principles:session-handoff` を呼び、返ってきた内容に cycle-reset 操作（操作 5）が含まれるかを確認する。
Expected: 含まれる（直読み仮説どおりなら update 直後の同セッションで新内容が返る）

- [ ] **Step 3: Issue-0044 の「検討状況」へ実測結果を 1 行追記**

追記フォーマット（Step 2 の実測結果に応じて「反映を確認」または「反映されず旧内容が返った」を書き分ける）: `- 2026-08-06: session-handoff 改定（cycle-reset 追加）直後、プラグイン update 後の同セッションで Skill 起動 → 新内容の反映を確認 / 反映されず旧内容`

- [ ] **Step 4: コミット**

コミットメッセージ: `issues: 0044 にスキル改定の同セッション検証実測を追記`
Run: `git add docs/working/issues/flow/0044-*.md && git commit -F <msg-file> -- docs/working/issues/flow/`
Expected: 1 file changed

### Task 5: ADR 昇格と Issue close（サイクル完了処理の前半）

**Files:**
- Modify: `docs/records/decisions/0074〜0077 の 4 ファイル`（Status: Proposed → Accepted）
- Modify: `docs/records/decisions/README.md`（同上）
- Modify: `docs/working/issues/flow/0049-handoff-single-file-growth-no-pruning-rules.md`（close）
- Modify: `docs/working/issues/flow/0051-handoff-status-value-mismatch-between-skills.md`（close）
- Modify: `docs/working/issues/README.md`（2 件の Status 更新）

- [ ] **Step 1: 昇格前の粒度点検（ADR-0059 / ADR-0060）**

ADR-0074〜0077 それぞれについて、タイトルが本文の全決定に答えているかを確認する（1 ADR = 1 つの問い）。答えていない決定があれば分割を提案してから昇格する。
Expected: 4 件とも単一の問いに収まっている（起票時に分割済み）

- [ ] **Step 2: 4 ADR の Status を Accepted に更新**

各ファイルの `- **Status**: Proposed` → `- **Status**: Accepted`。`README.md` テーブルの 4 行も `Proposed` → `Accepted`。

- [ ] **Step 3: Issue-0049 / Issue-0051 を close**

両ファイルの `- **Status**: open` → `- **Status**: closed`、`- **Closed**: 2026-08-06` を追記、「結論」セクションを記入:

- 0049: `ADR-0074（受け皿は git 履歴のみ）・ADR-0075（二段階剪定）・ADR-0077（外部参照の安定識別子）で対処。実装は session-handoff / retrospective スキル改定（2026-08-06）`
- 0051: `ADR-0076（ready-for-next-cycle の正式追加）で対処。retrospective Phase 3 は cycle-reset 呼び出しに変更し、誤記述（completed からの遷移）も解消（2026-08-06）`

`docs/working/issues/README.md` の 0049 / 0051 行の Status も closed へ更新。

- [ ] **Step 4: 整合確認**

Run: `grep -l "Status.*: Proposed" docs/records/decisions/007[4-7]-*.md`
Expected: ヒットなし

Run: `grep -n "0049\|0051" docs/working/issues/README.md`
Expected: 両行とも closed 表記

- [ ] **Step 5: コミット**

コミットメッセージ:

```
adr: 0074-0077 を Accepted へ昇格、Issue-0049/0051 を close

スキル改定の実装完了・整合検証済み（ADR-0019 のチェックポイント）。
```

Run: `git add docs/records/decisions/ docs/working/issues/ && git commit -F <msg-file> -- docs/records/decisions/ docs/working/issues/`
Expected: 7 files changed

---

## 完了後（プラン外の通常フロー）

1. handoff 更新（Post ラッパー消化: ADR / worklog / update）
2. master へ `--no-ff` マージ（`finishing-a-development-branch` の選択肢提示に従う）
3. `retrospective` 実施 — **cycle-reset の初回実運用**。master.md の Status 不整合注記（Issue-0051 由来）が除去されることを確認（spec 検証 4 のドッグフーディング）
4. session-handoff finalize
