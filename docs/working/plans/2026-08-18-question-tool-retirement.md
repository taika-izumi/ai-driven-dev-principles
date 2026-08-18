# 構造化質問ツール全面廃止（ADR-0109）実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ADR-0109 の Decision 1〜7 を実装する — 質問規範のテキスト一本化（CLAUDE.md 3 箇条化）、参照追従、旧 ADR 整理、spec 回復（Issue-0082 close）、環境・メモリ撤回、配布物生成と version bump。

**Architecture:** 変更は (A) リポジトリ内の規範・参照の書き換え → (B) 生成器実行（sync-template / build-dist）と同一コミット化 → (C) リポジトリ外（ユーザー環境・メモリ）の撤回、の 3 群。設計の正本は `docs/records/decisions/0109-retire-structured-question-tool-unconditionally.md`（Proposed・コミット 7e0f328）。

**Tech Stack:** Markdown 編集、PowerShell スクリプト（`scripts/sync-template.ps1` / `scripts/build-dist.ps1` / `scripts/check-claude-md-size.ps1`）、git。

**検証の原則:** 期待値はすべて本 plan 作成時（2026-08-18）の実測から書いた。実装時に前提値がずれていたら、盲進せず実測し直してから進むこと（Issue-0095 の教訓）。

---

### Task 1: CLAUDE.md「ユーザーへの質問と意思決定要求」節を 3 箇条へ置換

**Files:**
- Modify: `CLAUDE.md:73-83`（節全体。現行 6 箇条＋サブ箇条 3）

- [ ] **Step 1: 節を置換する**

L73「### ユーザーへの質問と意思決定要求」から L83「  - ユーザーの応答を得るまで次のステップへ進まないこと」までを、次の内容に置き換える（見出しは同じ、本文 3 箇条）:

```markdown
### ユーザーへの質問と意思決定要求

- ユーザーに質問する、または意思決定を求めるときは、原則として選択肢を提示し、推奨する選択肢を「（推奨）」として先頭に置き、推奨理由を一言添えること
- 質問・意思決定要求はすべてテキストのみのターンで行い、説明に続けて番号付き選択肢を提示すること。構造化された質問ツール（GitHub Copilot CLI の ask_user、Claude Code の AskUserQuestion 等）は、モデル・ツール・環境設定を問わず使用しないこと
- 本質的に自由記述が必要な質問（目的・背景の説明を求める等、選択肢を自然に列挙できないもの）に限り、例外として自由記述を許すこと
```

第 1・第 3 箇条は現行 L75・L78 と同文（変更しない）。削除されるのは L76（環境変数ゲート）・L77（テキストフォールバック分岐）・L79（Fable 5 条項）・L80-83（タイムアウト停止）。

- [ ] **Step 2: 実測で確認する**

```powershell
./scripts/check-claude-md-size.ps1
(Select-String -Path CLAUDE.md -Pattern 'AskUserQuestion' -AllMatches).Matches.Count
(Select-String -Path CLAUDE.md -Pattern 'CLAUDE_CODE_DISABLE_MOUSE_CLICKS' -AllMatches).Matches.Count
(Select-String -Path CLAUDE.md -Pattern 'タイムアウト' -AllMatches).Matches.Count
```

期待値: bullets **25**（変更前実測 28 − 節内トップレベル 6 箇条 ＋ 新 3 箇条。計測スクリプトは行頭 `- ` のみ数え、L81-83 のサブ箇条は計数対象外であることを実測済み）、バイト数は変更前実測 10732 より減（目安 7000 台）で閾値 12000 内。AskUserQuestion = **1**（変更前 2）、CLAUDE_CODE_DISABLE_MOUSE_CLICKS = **0**（変更前 1）、タイムアウト = **0**（変更前 1）。

`docs/overview/principles.md` は**変更しない**（ADR-0109 Decision 2。L46・L48 の 2 文が残っていることを目視確認のみ）。

### Task 2: skills 2 ファイルの追従

**Files:**
- Modify: `skills/start-work/SKILL.md:121`
- Modify: `skills/worklog-record/SKILL.md:69`

- [ ] **Step 1: start-work の差分明示の条件文を単純化する**

L121 の末尾の文:

> 差分明示を伴う提示は長文になるため、構造化質問ツールの利用可否は CLAUDE.md「ユーザーへの質問と意思決定要求」の規範に従って判断する（同規範がテキストのみのターンでの提示を求める条件に該当する場合は、説明と番号付き選択肢をテキストで提示する）。

を次に置換:

> 差分明示を伴う提示も、CLAUDE.md「ユーザーへの質問と意思決定要求」の規範に従い、説明と番号付き選択肢をテキストで提示する。

- [ ] **Step 2: worklog-record のエントリ例を中立題材へ差し替える**

L69 の JSONL 行全体を次に置換（`project` は中立名 `X`・`applied_rules` はプレースホルダ維持。記法規約 R4/R5 適合）:

```jsonl
{"v":2,"id":"X-2026-07-17-01","date":"2026-07-17","project":"X","model":"claude-fable-5","scope":"general-candidate","title":"生成物の同期を確認してからコミット","context":"配布物の生成元ファイルを変更した後、生成スクリプトの実行を忘れてコミットしかけた","procedure":["生成元を変更したら生成スクリプトを実行する","git status で生成物の差分がステージ済みか確認してからコミットする"],"corrections":["生成元と生成物は同じコミットに含めること"],"applied_rules":["ADR-NNNN"]}
```

- [ ] **Step 3: 実測で確認する**

```powershell
(Select-String -Path skills/start-work/SKILL.md -Pattern '構造化質問ツール' -AllMatches).Matches.Count
(Select-String -Path skills/worklog-record/SKILL.md -Pattern 'AskUserQuestion|CLAUDE_CODE_DISABLE_MOUSE_CLICKS' -AllMatches).Matches.Count
```

期待値: どちらも **0**（変更前はそれぞれ 1、2）。

### Task 3: CONTRIBUTING.md 2 箇所と spec スナップショット 1 箇所の追従

**Files:**
- Modify: `CONTRIBUTING.md:54`（是正パターンの実例参照）
- Modify: `CONTRIBUTING.md:509`（事例参照）
- Modify: `docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md:53`（CONTRIBUTING:54 と同文）

- [ ] **Step 1: 実例参照を履歴表現へ改める（2 ファイル同文）**

`CONTRIBUTING.md:54` と `docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md:53` の:

> （ADR-0032 の型。実例: CLAUDE.md の構造化質問ツール規範。CLAUDE.md への規範追加では「CLAUDE.md を更新するとき」手順のゲート必須と同一の要求である）

を次に置換（両ファイルとも）:

> （ADR-0032 の型。過去の実例: CLAUDE.md の旧・構造化質問ツール規範〈事象確認済みモデルの列挙。規範ごと ADR-0109 で撤回済み〉。CLAUDE.md への規範追加では「CLAUDE.md を更新するとき」手順のゲート必須と同一の要求である）

- [ ] **Step 2: 事例参照を差し替える**

`CONTRIBUTING.md:509` の「ADR-0036 の事例参照」を「ADR-0037 の事例参照」に置換（ADR-0037 = .gitattributes で改行正規化を git 側に固定した、撤回されていない構造的解決の実例）。

- [ ] **Step 3: 実測で確認する**

```powershell
(Select-String -Path CONTRIBUTING.md,docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md -Pattern '実例: CLAUDE.md の構造化質問ツール規範' -AllMatches).Matches.Count
(Select-String -Path CONTRIBUTING.md -Pattern 'ADR-0036 の事例参照' -AllMatches).Matches.Count
(Select-String -Path CONTRIBUTING.md,docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md -Pattern '過去の実例: CLAUDE.md の旧・構造化質問ツール規範' -AllMatches).Matches.Count
```

期待値: 上から **0**（変更前 2）、**0**（変更前 1）、**2**。

### Task 4: 選択肢提示規範 spec の回復と Issue-0082 の close

**Files:**
- Modify: `docs/current/specs/2026-06-16-choice-with-recommendation-design.md`
- Modify: `docs/working/issues/flow/0082-choice-recommendation-spec-snapshot-stale.md`
- Modify: `docs/working/issues/README.md:98`

- [ ] **Step 1: spec を現行規範のスナップショットへ書き換える**

次の 4 点を編集する:

1. L4 の関連 ADR 行を `- **関連ADR**: ADR-0024（ADR-0109 でツール選択条項を改定）` に置換
2. L24-28「ツールの扱い」節の箇条 3 つを次に置換:

```markdown
- 質問・意思決定要求はすべてテキストのみのターンで行い、説明に続けて番号付き選択肢を提示する。
- 構造化された質問ツール（Copilot CLI の `ask_user`、Claude Code の `AskUserQuestion` 等）は、モデル・ツール・環境設定を問わず使用しない（ADR-0109）。
- 規範は「振る舞い（選択肢＋推奨を出す）」を主として記述し、特定ツール名に依存させない。
```

3. L44-50 の引用ブロック内の 2 箇条目（「構造化された質問ツール（…）が利用できる場合はそれを使い、無ければテキストで選択肢を列挙すること」）を次に置換:

```
- 質問・意思決定要求はすべてテキストのみのターンで行い、説明に続けて番号付き選択肢を提示すること。構造化された質問ツール（GitHub Copilot CLI の ask_user、Claude Code の AskUserQuestion 等）は、モデル・ツール・環境設定を問わず使用しないこと
```

4. 旧パス `docs/principles.md` を全出現（L5・L32・L54・L64・L66 の 5 箇所。L66 は `template/docs/principles.md`）で `docs/overview/principles.md`（L66 は `template/docs/overview/principles.md`）へ置換

- [ ] **Step 2: Issue-0082 を close する**

`docs/working/issues/flow/0082-choice-recommendation-spec-snapshot-stale.md`:
- L3 を `- **Status**: closed` に、L4 の下に `- **Closed**: 2026-08-18` を追加
- 末尾に節を追加:

```markdown
## 結論

ADR-0109 の Decision 6 により、spec の「ツールの扱い」節・引用ブロックをテキスト一本化規範へ書き換え、旧パス参照 5 箇所を `docs/overview/principles.md` へ修正して解消（2026-08-18）。
```

- 「検討状況」に `- 2026-08-18: ADR-0109 Decision 6 で本サイクルの対策対象に採用。spec 書き換えを実施し close` を追記
- `docs/working/issues/README.md:98` の 0082 行の Status を `open` → `closed` に変更

- [ ] **Step 3: 実測で確認する**

```powershell
(Select-String -Path docs/current/specs/2026-06-16-choice-with-recommendation-design.md -Pattern 'docs/principles\.md' -AllMatches).Matches.Count
(Select-String -Path docs/current/specs/2026-06-16-choice-with-recommendation-design.md -Pattern '利用できる場合はそれを使' -AllMatches).Matches.Count
(Select-String -Path docs/working/issues/flow/0082-choice-recommendation-spec-snapshot-stale.md -Pattern 'Status..: closed' -AllMatches).Matches.Count
```

期待値: 上から **0**（変更前 5）、**0**（変更前 2）、**1**。

### Task 5: 旧 ADR 4 件の整理

**Files:**
- Modify: `docs/records/decisions/0085-no-structured-question-tool-on-affected-models.md`（Status・Consequences）
- Modify: `docs/records/decisions/0036-selection-ui-env-setting-and-text-fallback.md`（Status・Consequences）
- Modify: `docs/records/decisions/0035-question-tool-timeout-stop-norm.md`（Consequences のみ）
- Modify: `docs/records/decisions/0024-choice-with-recommendation-norm.md`（Status 行のみ）
- Modify: `docs/records/decisions/README.md`（0085・0036 の行）

- [ ] **Step 1: ADR-0085 を Superseded 化する**

L3 を `- **Status**: Superseded by ADR-0109` に置換。Consequences 末尾に追記:

```markdown
- **置換（2026-08-18）**: 本 ADR のモデル条件付き全面不使用は、全ツール・全モデルでの無条件廃止（ADR-0109）へ置換された。撤去基準は Deprecated 化を想定していたが、置換 ADR が存在するため遷移表に従い Superseded とする。
```

- [ ] **Step 2: ADR-0036 を Superseded 化する**

L3 を `- **Status**: Superseded by ADR-0109` に置換。Consequences 末尾に追記:

```markdown
- **置換（2026-08-18）**: 質問ツールの全面廃止（ADR-0109）により、本 ADR の 2 分岐（環境確認ゲート）と環境変数の推奨環境設定としての文書化はともに撤回された。
```

- [ ] **Step 3: ADR-0035 へ部分修正注記を追記する**

Status は Accepted のまま。Consequences 末尾に追記:

```markdown
- **部分修正（ADR-0109）**: 決定 1（CLAUDE.md「ユーザーへの質問と意思決定要求」節のタイムアウト停止規範）は、構造化質問ツールの全面廃止により発動機会が消滅したため撤去された。決定 2（原則4 の「停止を既定の撤退とする」一文）は撤退条件の一般則として現役のまま維持する。
```

- [ ] **Step 4: ADR-0024 の Status 行を最新化する**

L3 を次に置換:

```markdown
- **Status**: Accepted（ADR-0109 で一部改定: 質問はテキストの番号付き選択肢に一本化し、構造化質問ツールは使用しない。ADR-0036 / 0085 による旧改定は ADR-0109 へ置換済み）
```

- [ ] **Step 5: インデックスを更新する**

`docs/records/decisions/README.md` の 0085・0036 の行の Status を `Accepted` → `Superseded by ADR-0109` に変更（0035・0024 は Accepted のまま変更しない）。

- [ ] **Step 6: 実測で確認する**

```powershell
(Select-String -Path docs/records/decisions/README.md -Pattern 'Superseded by ADR-0109' -AllMatches).Matches.Count
(Select-String -Path docs/records/decisions/0085-no-structured-question-tool-on-affected-models.md,docs/records/decisions/0036-selection-ui-env-setting-and-text-fallback.md -Pattern 'Status..: Superseded by ADR-0109' -AllMatches).Matches.Count
(Select-String -Path docs/records/decisions/0035-question-tool-timeout-stop-norm.md -Pattern '部分修正（ADR-0109）' -AllMatches).Matches.Count
```

期待値: 上から **2**、**2**、**1**。

### Task 6: version bump と配布物生成（執行点 4 手順）

**Files:**
- Modify: `.claude-plugin/plugin.json:4`・`.claude-plugin/marketplace.json:11`（0.1.10 → 0.1.11）
- Generate: `dist/`（build-dist）・`template/`（sync-template）

- [ ] **Step 1: version を 0.1.11 へ上げる**

`.claude-plugin/plugin.json:4` と `.claude-plugin/marketplace.json:11` の `"version": "0.1.10"` を `"version": "0.1.11"` に変更。

- [ ] **Step 2: 生成器を実行する**

```powershell
./scripts/build-dist.ps1        # skills/ を変更したため
./scripts/sync-template.ps1     # CLAUDE.md を変更したため（サイズ計測が自動で走る）
./scripts/build-dist.ps1 -Check
./scripts/sync-template.ps1 -Check
```

期待値: 4 コマンドすべて exit code 0（記法規約違反があれば非ゼロで停止 → 修正して再実行）。sync-template の計測が閾値内であること。

- [ ] **Step 3: dist の version と配布物への反映を実測する**

```powershell
(Select-String -Path dist/.claude-plugin/plugin.json -Pattern '0\.1\.11' -AllMatches).Matches.Count
(Select-String -Path template/CLAUDE.md -Pattern 'AskUserQuestion' -AllMatches).Matches.Count
(Select-String -Path dist/skills/start-work/SKILL.md,dist/skills/worklog-record/SKILL.md -Pattern '構造化質問ツール|AskUserQuestion' -AllMatches).Matches.Count
```

期待値: 上から **1**（build-dist が dist へ複製しない場合は手動で 0.1.11 に揃えて再実行）、**1**（新箇条のツール名列挙のみ）、**0**。

- [ ] **Step 4: 配布物を目視する（機械判定が届かない 5 型）**

`dist/skills/start-work/SKILL.md`・`dist/skills/worklog-record/SKILL.md` の変更箇所と `template/CLAUDE.md` の当該節を読み、R1-a（括弧内の説明語同居）・R1-b（半角括弧）・書式例の実在固有名・自己参照・docstring の 5 型がないことを確認する。

### Task 7: 実装コミット（リポジトリ内一式）

- [ ] **Step 1: ステージして pathspec 付きでコミットする**

```powershell
git add CLAUDE.md skills/start-work/SKILL.md skills/worklog-record/SKILL.md CONTRIBUTING.md docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md docs/current/specs/2026-06-16-choice-with-recommendation-design.md docs/working/issues/flow/0082-choice-recommendation-spec-snapshot-stale.md docs/working/issues/README.md docs/records/decisions/0085-no-structured-question-tool-on-affected-models.md docs/records/decisions/0036-selection-ui-env-setting-and-text-fallback.md docs/records/decisions/0035-question-tool-timeout-stop-norm.md docs/records/decisions/0024-choice-with-recommendation-norm.md docs/records/decisions/README.md .claude-plugin/plugin.json .claude-plugin/marketplace.json dist template
git status --short   # 意図したファイルのみステージされていることを確認（docs/inbox・conversation_log を巻き込まない）
git commit -m "feat: 構造化質問ツール全面廃止をテキスト選択肢一本化で実装（ADR-0109・v0.1.11）" -- CLAUDE.md skills CONTRIBUTING.md docs/current docs/working/issues docs/records/decisions .claude-plugin dist template
```

期待値: コミット成功。`git status` に docs/inbox/*・docs/conversation_log.md が untracked のまま残る（巻き込み禁止。Issue-0020）。

### Task 8: リポジトリ外の撤回（環境・メモリ）

**Files:**
- Modify: `C:\Users\d12an\.claude\settings.json`（env から 1 キー削除）
- Modify: `D:\Dev\002_AiDev\MakeAiInstructions\.claude\settings.local.json:36`（permission 1 行削除）
- Modify: `C:\Users\d12an\.claude\projects\D--Dev-002-AiDev-MakeAiInstructions\memory\askuserquestion-text-not-visible.md`・`memory\MEMORY.md`

- [ ] **Step 1: 環境変数を削除する（中リスク: 実行前にサマリー提示）**

`C:\Users\d12an\.claude\settings.json` の `"env"` から `"CLAUDE_CODE_DISABLE_MOUSE_CLICKS": "1"` のエントリを削除（`env` が空になる場合はキーごと削除してよい）。有効化は次セッション起動から。

- [ ] **Step 2: ローカル permission の残渣を削除する**

`.claude/settings.local.json` の `"PowerShell($env:CLAUDE_CODE_DISABLE_MOUSE_CLICKS)",` の行を削除（JSON の配列カンマ整合に注意）。

- [ ] **Step 3: メモリを更新する**

`askuserquestion-text-not-visible.md` の本文を「全ツール・全モデルで構造化質問ツールを使用しない（ADR-0109・2026-08-18 確定）。質問はテキストのみのターンで番号付き選択肢＋推奨。モデル条件・環境変数条件は撤廃済み（モデル切替時の再評価は不要）」の趣旨に書き換え、`MEMORY.md` の該当行のフックも「全モデルで質問ツール不使用・テキスト番号付き選択肢で聞く」に更新する。経緯（2026-07〜08 の再発履歴）は要約 1 段落に圧縮して残してよい。

- [ ] **Step 4: 確認する**

```powershell
(Select-String -Path C:\Users\d12an\.claude\settings.json -Pattern 'CLAUDE_CODE_DISABLE_MOUSE_CLICKS' -AllMatches).Matches.Count
```

期待値: **0**。settings.local.json が有効な JSON であること（`Get-Content .claude/settings.local.json | ConvertFrom-Json` がエラーなし）。

### Task 9: 現役文書の残参照の追従

**Files:**
- Modify: `docs/working/handoff/master.md:64`
- Modify: `docs/working/issues/flow/0043-decision-request-framing-norm-not-effective.md:6`

- [ ] **Step 1: master handoff の環境変数留意行を差し替える**

L64 の行を次に置換:

```markdown
- 構造化質問ツールは全ツール・全モデルで廃止（ADR-0109）。質問はテキストの番号付き選択肢のみ。`CLAUDE_CODE_DISABLE_MOUSE_CLICKS` は撤去済み（クリック操作は再有効化）
```

- [ ] **Step 2: Issue-0043 の関連欄を張り替える**

L6 の `ADR-0036（クリック誤操作の防止設定）、ADR-0035（質問ツールのタイムアウト）` を `ADR-0109（質問ツール全面廃止・テキスト一本化。旧 ADR-0036/0035 の関連条項は撤去・置換済み）` に置換。

- [ ] **Step 3: コミットする**

```powershell
git add docs/working/handoff/master.md docs/working/issues/flow/0043-decision-request-framing-norm-not-effective.md
git commit -m "docs: 質問ツール廃止（ADR-0109）に伴う現役文書の残参照を追従" -- docs/working/handoff/master.md docs/working/issues/flow/0043-decision-request-framing-norm-not-effective.md
```

### Task 10: ADR-0109 の Accepted 昇格（実装完了チェックポイント）

- [ ] **Step 1: サイクル全体整合検査を実施する**

decision-log「サイクル全体整合検査」に従い、`git diff --name-only master HEAD` ＋ `git status --porcelain` で変更ファイルを列挙し、固定 5 観点（スナップショット性・規範の書き戻し・数値整合・経路の閉じ・引用の整合）をインライン検査。指摘があればその場で修正（配布対象ソースに及ぶ場合は Task 6 Step 2 を再実行）。

- [ ] **Step 2: 粒度を点検し Status を昇格する**

ADR-0109 のタイトルが本文の全決定に答えているか突合（確定前レビューで判定記録済み）。`docs/records/decisions/0109-retire-structured-question-tool-unconditionally.md` の Status を `Accepted` へ、`docs/records/decisions/README.md` の行も更新。

- [ ] **Step 3: コミットする**

```powershell
git add docs/records/decisions/0109-retire-structured-question-tool-unconditionally.md docs/records/decisions/README.md
git commit -m "adr: ADR-0109 を Accepted へ昇格（実装完了チェックポイント）" -- docs/records/decisions
```

- [ ] **Step 4: Post ラッパーを消し込む**

worklog-record（記録ゲート判定）→ session-handoff update（マイルストーン名に `Accepted 昇格` を含め、`cyclecheck=` を併記）→ handoff コミット。

---

## 完了基準

1. Task 1〜6 の各実測コマンドがすべて期待値どおり
2. `-Check` 2 種が exit 0、`dist/`・`template/` がソースと同一コミットに含まれる
3. ADR-0109 が Accepted、ADR-0036/0085 が Superseded、Issue-0082 が closed
4. 次セッションでクリック操作（コピペ）が有効になっている（ユーザー確認。エージェントからは観測不能）

## 対象外（YAGNI）

- 過去記録（docs/records/ の retrospective・audit・過去 handoff・過去 plan）への遡及追従はしない（時点記録）
- `docs/current/specs/2026-08-07-distributed-artifact-generation/05-source-migration.md` は移行時点の処理台帳のため追従不要（ADR-0109 Decision 3 で判定済み）
- Copilot CLI 側の deny 設定調査はしない（ADR-0109 Considered Alternatives 5 で不採用）
