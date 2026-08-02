# Post ラッパー消化の可視化と事後突合 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Post ラッパーの消化結果を handoff に残して未発火とゲート棄却を外形的に区別可能にし（ADR-0057）、セッション切替直前を worklog-record の発火契機に追加する（ADR-0058）。

**Architecture:** スキル4件（session-handoff / start-work / retrospective / worklog-record）の SKILL.md を改定する。新規ファイルなし。handoff フォーマットに「Post ラッパー消化記録」節を追加し、start-work の Post ラッパーを1項目ずつ消し込む手順へ改め、retrospective Phase 3 を git log との突合手順に具体化する。

**Tech Stack:** Markdown（スキル定義）のみ。コードなし。検証は grep による静的確認（期待値は各編集内容と突合済み）。

**制約:**
- 仕様の正: `docs/current/specs/2026-04-25-record-strengthening-design.md` §5.3.1 / `2026-07-17-worklog-skill-pipeline/02-skill1-record.md` / `2026-05-01-retrospective-design.md` Phase 3（いずれも更新済み・コミット `1192239` `0b9bd12`）
- `skills/` は template 非同期・プラグイン配信。改定後の反映には `/plugin marketplace update ai-driven-dev-principles` が必要（AI 実行不可。ADR-0055）。**このコマンドはユーザーにしか実行できないため、実装完了報告時に依頼すること**
- `scripts/sync-template.ps1` の実行は不要（対象は CLAUDE.md / principles.md / folder-structure.md / inbox README のみで、今回はいずれも変更しない）
- コミットメッセージは `git commit -F <絶対パスの一時ファイル>` で渡す（Issue-0015）

---

### Task 1: session-handoff SKILL.md — フォーマットと4操作の改定

**Files:**
- Modify: `skills/session-handoff/SKILL.md`

- [ ] **Step 1: ハンドオフフォーマットに「Post ラッパー消化記録」節を追加**

「## ハンドオフファイルのフォーマット」のコードブロック内を Edit する。

old_string:

```markdown
## 既知のブロッカー・懸念

（なし、または箇条書き）

## 次セッション開始時のアクション
```

new_string:

```markdown
## 既知のブロッカー・懸念

（なし、または箇条書き）

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。
形式: `- <日付> <マイルストーン>: ADR=<番号 or なし（理由）> / worklog=<エントリ id or 棄却（理由）>`
行が存在すること自体が update の証跡であるため、session-handoff update の項目は書かない。

- YYYY-MM-DD <マイルストーン名>: ADR=NNNN / worklog=`<project>-YYYY-MM-DD-NN`
- YYYY-MM-DD <マイルストーン名>: ADR=なし（<理由>） / worklog=棄却（delta なし）

## 次セッション開始時のアクション
```

- [ ] **Step 2: read 操作に消化記録の検査ステップを追加**

old_string:

```markdown
4. 存在すれば内容を読み込み、以下の要素を抽出して要約をユーザーに提示する:
   - 作業の目的
   - 進行中タスク（状態と残り）
   - 次セッション開始時のアクション
5. ユーザーに「前回の続きから始めますか?」と確認する
```

new_string:

```markdown
4. 存在すれば内容を読み込み、以下の要素を抽出して要約をユーザーに提示する:
   - 作業の目的
   - 進行中タスク（状態と残り）
   - 次セッション開始時のアクション
5. 「Post ラッパー消化記録」を検査する（ADR-0057）: 「完了済みタスク」にあるマイルストーンで消化記録の行が無いもの、または `ADR=` / `worklog=` の記載が欠けた行があれば、未消化として呼び出し元（start-work）へ報告する
6. ユーザーに「前回の続きから始めますか?」と確認する
```

- [ ] **Step 3: update 操作に消化記録の追記ステップを追加**

old_string:

```markdown
6. 重要な意思決定があれば「重要な意思決定の履歴」に ADR 番号を追記する
7. 既知のブロッカーがあれば追記する
8. ファイルを上書き保存する（コミットはセッション終了時、または明示的なコミットタイミングで実施）
```

new_string:

```markdown
6. 重要な意思決定があれば「重要な意思決定の履歴」に ADR 番号を追記する
7. 既知のブロッカーがあれば追記する
8. 「Post ラッパー消化記録」へ当該マイルストーンの1行を追記する（ADR-0057）。ADR 候補検出の結果（番号 or なし＋理由）と worklog-record の結果（エントリ id or 棄却＋理由）を書く。棄却を明示しない限り未発火と区別できないため、棄却時も必ず書く
9. ファイルを上書き保存する（コミットはセッション終了時、または明示的なコミットタイミングで実施）
```

- [ ] **Step 4: finalize 操作に過去セッション分の剪定ステップを追加**

old_string:

```markdown
3. Status を更新する（作業継続なら `paused`、完了なら `completed`、まだ進行中なら `in_progress`）
4. ファイルを git に add してコミットする:
```

new_string:

```markdown
3. Status を更新する（作業継続なら `paused`、完了なら `completed`、まだ進行中なら `in_progress`）
4. 「Post ラッパー消化記録」のうち、確定済みの過去セッション分の行は削除してよい（履歴は git に残る。ADR-0057）
5. ファイルを git に add してコミットする:
```

- [ ] **Step 5: 検証**

Run: `grep -c "Post ラッパー消化記録" skills/session-handoff/SKILL.md`
Expected: `4`（フォーマット節見出し / read 手順5 / update 手順8 / finalize 手順4）

Run: `grep -c "ADR-0057" skills/session-handoff/SKILL.md`
Expected: `4`（同上の4箇所）

- [ ] **Step 6: コミット**

```bash
git add skills/session-handoff/SKILL.md
git commit -F <一時ファイル>  # "skills: session-handoff に Post ラッパー消化記録を追加（ADR-0057）"
```

---

### Task 2: start-work SKILL.md — Post ラッパー消し込み規律とセッション終了処理

**Files:**
- Modify: `skills/start-work/SKILL.md`

- [ ] **Step 1: Phase 0 のハンドオフあり分岐に未消化報告の提示を追加**

old_string:

```markdown
   - ハンドオフあり → 内容の要約をユーザーに提示し「前回の続きから始めますか?」と確認
```

new_string:

```markdown
   - ハンドオフあり → 内容の要約をユーザーに提示し「前回の続きから始めますか?」と確認（read が消化記録の未消化マイルストーンを報告した場合はあわせて提示する。ADR-0057）
```

- [ ] **Step 2: Post ラッパーに消し込み規律の前文を追加**

old_string:

```markdown
**Post（実行後）:**
1. **ADR候補検出**: 実行中に行われた意思決定が以下のいずれかに該当するか自己評価する:
```

new_string:

```markdown
**Post（実行後）:**

以下の項目を**1つずつ明示的に消し込む**（ADR-0057）。項目1と3の判定結果は、`session-handoff` update が handoff の「Post ラッパー消化記録」へ1行で残す（形式は session-handoff スキル参照）。ハンドオフ更新（項目2）の完了は worklog-record（項目3）の免除にならない。

1. **ADR候補検出**: 実行中に行われた意思決定が以下のいずれかに該当するか自己評価する:
```

- [ ] **Step 3: Post 項目3（作業記録の追記）に消化記録への記載を追加**

old_string:

```markdown
3. **作業記録の追記**: マイルストーン到達時、`worklog-record` スキルを呼ぶ。worklog-record が記録ゲート（既存スキルで実施済みでない かつ AI 自律で毎回再現できない＝delta が存在する）を自己判定し、満たさなければ記録しない。session-handoff update と同じ契機（スキル完了 / plan の1タスク完了 / 重要な分岐通過）で発火する（ADR-0047）
```

new_string:

```markdown
3. **作業記録の追記**: マイルストーン到達時、`worklog-record` スキルを呼ぶ。worklog-record が記録ゲート（既存スキルで実施済みでない かつ AI 自律で毎回再現できない＝delta が存在する）を自己判定し、満たさなければ記録しない。session-handoff update と同じ契機（スキル完了 / plan の1タスク完了 / 重要な分岐通過）で発火する（ADR-0047）。記録した場合はエントリ id を、記録ゲートで棄却した場合は棄却の旨を「Post ラッパー消化記録」へ書く（未発火と棄却を外形的に区別するため。ADR-0057）
```

- [ ] **Step 4: セッション終了処理に worklog-record ステップを挿入**

old_string:

```markdown
3. `session-handoff` の **finalize** 操作を呼ぶ
4. ハンドオフの「次セッション開始時のアクション」が確実に埋まっていることを確認する
5. ユーザーに完了を報告する
```

new_string:

```markdown
3. `worklog-record` を呼ぶ（ADR-0058）。セッション切り替え直前は節目かどうかを問わず発火契機となる（切り替え後は delta を保持する文脈が失われるため、ここが記録の最終機会）。記録ゲートの判定は通常どおり行い、結果を「Post ラッパー消化記録」へ書く
4. `session-handoff` の **finalize** 操作を呼ぶ
5. ハンドオフの「次セッション開始時のアクション」が確実に埋まっていることを確認する
6. ユーザーに完了を報告する
```

- [ ] **Step 5: 検証**

Run: `grep -c "Post ラッパー消化記録" skills/start-work/SKILL.md`
Expected: `3`（Post 前文 / Post 項目3 / セッション終了処理 手順3）

Run: `grep -c "ADR-0057" skills/start-work/SKILL.md`
Expected: `3`（Phase 0 / Post 前文 / Post 項目3）

Run: `grep -c "ADR-0058" skills/start-work/SKILL.md`
Expected: `1`（セッション終了処理 手順3）

- [ ] **Step 6: コミット**

```bash
git add skills/start-work/SKILL.md
git commit -F <一時ファイル>  # "skills: start-work の Post を1項目ずつ消し込む手順へ改定（ADR-0057/0058）"
```

---

### Task 3: retrospective SKILL.md — Phase 3 の突合手順化

**Files:**
- Modify: `skills/retrospective/SKILL.md`

- [ ] **Step 1: Phase 3 手順2を突合手順へ置換**

old_string:

```markdown
2. **worklog 総ざらい確認**: サイクル全体を俯瞰し、未記録の delta（躓き・人間の指示）に気づいたら `worklog-record` を呼んで記録する。振り分け規則で「worklog 送り」とした delta 型候補の記録漏れもここで拾う
```

new_string:

```markdown
2. **worklog 総ざらい確認（マイルストーン突合。ADR-0057）**: サイクル中のマイルストーンと中央ストアのエントリを突合し、Post ラッパーの消化漏れを回収する:
   1. サイクル中のマイルストーンを列挙する。情報源は handoff の「Post ラッパー消化記録」と「完了済みタスク」、および当該ブランチの `git log`
   2. 各マイルストーンについて、消化記録に `worklog=` の記載（エントリ id または棄却）があるかを検査し、記載が無いものを未消化として洗い出す
   3. 中央ストア `<home>/.ai-dev-worklog/<project>/log.jsonl` の当該サイクル分エントリと、消化記録に記載された id を突合する
   4. 未消化のマイルストーンに delta（躓き・人間の指示）があれば `worklog-record` を呼んで記録し、無ければ消化記録へ棄却として1行補う
   5. 振り分け規則で「worklog 送り」とした delta 型候補の記録漏れもここで拾う

   本工程は、Post ラッパーに完全に入らなかった場合（消化記録の行そのものが無い）を回収する唯一の経路である（設計意図は `docs/current/specs/2026-05-01-retrospective-design.md` Phase 3 参照）
```

- [ ] **Step 2: 検証**

Run: `grep -c "マイルストーン突合" skills/retrospective/SKILL.md`
Expected: `1`

Run: `grep -c "ADR-0057" skills/retrospective/SKILL.md`
Expected: `1`

- [ ] **Step 3: コミット**

```bash
git add skills/retrospective/SKILL.md
git commit -F <一時ファイル>  # "skills: retrospective Phase 3 を git log との突合手順へ具体化（ADR-0057）"
```

---

### Task 4: worklog-record SKILL.md — 発火契機の追加と消化記録の参照

**Files:**
- Modify: `skills/worklog-record/SKILL.md`

- [ ] **Step 1: frontmatter の description を更新**

old_string:

```markdown
description: "作業の節目（スキル完了・plan タスク完了・重要な分岐通過）で、AI のデフォルト挙動と実際に必要だったことの差分（delta）を中央ストアへ1件記録する。start-work の Post ラッパーから発火。記録ゲート（既存スキルで実施済みでない かつ AI 自律で毎回再現できない）を満たす場合のみ追記する。"
```

new_string:

```markdown
description: "作業の節目（スキル完了・plan タスク完了・重要な分岐通過）とセッション切り替え直前で、AI のデフォルト挙動と実際に必要だったことの差分（delta）を中央ストアへ1件記録する。start-work の Post ラッパーおよびセッション終了処理から発火。記録ゲート（既存スキルで実施済みでない かつ AI 自律で毎回再現できない）を満たす場合のみ追記する。"
```

- [ ] **Step 2: 「いつ使うか」に契機を追加し、消化記録の参照を追加**

old_string:

```markdown
マイルストーン契機:

- スキルの完了
- plan の 1 タスク完了
- 重要な分岐の通過

タスクごとの継続的インラインログはしない（節目でのみ発火）。
```

new_string:

```markdown
マイルストーン契機:

- スキルの完了
- plan の 1 タスク完了
- 重要な分岐の通過
- セッション切り替え・コンテキスト逼迫による中断の直前（節目かどうかを問わない。ADR-0058。`start-work` のセッション終了処理から `session-handoff` finalize の前に発火する。判定条件は利用者による終了・切替の明示指示または終了処理への到達とし、コンテキスト残量そのものは判定条件にしない）

タスクごとの継続的インラインログはしない（上記契機でのみ発火）。

発火結果（記録したエントリ id、または記録ゲートによる棄却の旨）は、handoff の「Post ラッパー消化記録」へ1行残す（ADR-0057。棄却を明示しない限り未発火と外形的に区別できないため、棄却時も記載する）。
```

- [ ] **Step 3: 関連 ADR 一覧に 0057/0058 を追加**

old_string:

```markdown
- ADR-0048〜0053（v1.1 改訂: model 必須・スキーマ版数 v・id 採番強化・friction string[]・運用ガイド・記録単位）
```

new_string:

```markdown
- ADR-0048〜0053（v1.1 改訂: model 必須・スキーマ版数 v・id 採番強化・friction string[]・運用ガイド・記録単位）
- ADR-0057（消化結果の handoff 記録・未発火とゲート棄却の外形的区別）
- ADR-0058（セッション切り替え直前の発火契機）
```

- [ ] **Step 4: 検証**

Run: `grep -c "ADR-0058" skills/worklog-record/SKILL.md`
Expected: `2`（「いつ使うか」の契機 / 関連 ADR 一覧）

Run: `grep -c "ADR-0057" skills/worklog-record/SKILL.md`
Expected: `2`（消化記録の段落 / 関連 ADR 一覧）

Run: `grep -c "セッション切り替え" skills/worklog-record/SKILL.md`
Expected: `3`（description / 契機の箇条書き / 関連 ADR 一覧）

- [ ] **Step 5: コミット**

```bash
git add skills/worklog-record/SKILL.md
git commit -F <一時ファイル>  # "skills: worklog-record にセッション切替直前の発火契機を追加（ADR-0057/0058）"
```

---

### Task 5: ドッグフーディング開始と全体検証

**Files:**
- Modify: `docs/working/handoff/feature_worklog-record-firing-reliability.md`

- [ ] **Step 1: 本サイクルの handoff に「Post ラッパー消化記録」節を追加**

「## 既知のブロッカー・懸念」の直後（「## 次セッション開始時のアクション」の前）に以下を挿入し、ここまでのマイルストーン2件を遡って記載する。

```markdown
## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。

- 2026-08-01 課題定義の書き換え完了: ADR=なし（実データによる事実訂正のため。ADR-0031 に従い issue 側へ一次記録） / worklog=`MakeAiInstructions-2026-08-01-01`
- 2026-08-01 対策方針の決定（設計承認）: ADR=0057・0058 起票（Proposed） / worklog=棄却（方針決定自体に delta なし。調査時の delta は 2026-08-01-01 で記録済み）
```

- [ ] **Step 2: 全体検証（4ファイル横断）**

Run: `grep -rc "ADR-0057" skills/session-handoff/SKILL.md skills/start-work/SKILL.md skills/retrospective/SKILL.md skills/worklog-record/SKILL.md`
Expected:

```
skills/session-handoff/SKILL.md:4
skills/start-work/SKILL.md:3
skills/retrospective/SKILL.md:1
skills/worklog-record/SKILL.md:2
```

Run: `grep -rc "ADR-0058" skills/start-work/SKILL.md skills/worklog-record/SKILL.md`
Expected:

```
skills/start-work/SKILL.md:1
skills/worklog-record/SKILL.md:2
```

Run: `git diff master --stat -- skills/`
Expected: 変更ファイルが上記4件のみであること

- [ ] **Step 3: 検証結果を実体の読み直しで確認**

各 SKILL.md の編集箇所を Read で読み直し、挿入位置（節・手順番号の連番）が崩れていないことを目視確認する（ツール戻り値でなく実体確認。CLAUDE.md 検証規約）。特に:
- session-handoff: read 手順が 1〜6、update 手順が 1〜9、finalize 手順が 1〜5 で連番になっていること
- start-work: セッション終了処理が 1〜6 で連番になっていること

- [ ] **Step 4: コミット**

```bash
git add docs/working/plans/2026-08-02-post-wrapper-consumption-visibility.md docs/working/handoff/feature_worklog-record-firing-reliability.md
git commit -F <一時ファイル>  # "chore: 消化記録のドッグフーディングを開始し、実装計画を確定する"
```

---

## 完了後の処理（実装タスク外・メインエージェントが実施）

1. ADR-0057 / ADR-0058 を Accepted へ昇格（実装完了・検証後。ADR-0019）し、Issue-0037 を close（結論に ADR 番号を記載）
2. ユーザーへ `/plugin marketplace update ai-driven-dev-principles` の実行を依頼（前サイクルの retrospective 改定分と合わせて反映される。ADR-0055）
3. `superpowers:finishing-a-development-branch` で master への merge を進める
4. merge 後に `retrospective` を起動（新形式・突合手順の初回適用＝ドッグフーディング2周目）
