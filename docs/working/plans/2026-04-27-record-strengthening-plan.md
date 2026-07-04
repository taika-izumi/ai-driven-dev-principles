# 記録の強化（サブプロジェクトA）実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ADRゲート（意思決定の継続検出と即時記録）と、セッション継続のためのハンドオフ記録を、`start-work` 起点スキルおよび `session-handoff` スキルとして導入し、既存の `decision-log` スキル・`copilot-instructions.md`・テンプレート系を整合させる。

**Architecture:** Layer 2（`copilot-instructions.md`）に「作業起点ルール」と「継続的ADR検出ルール」を常時ルールとして追加し、Layer 3 に新スキル `start-work`（横断関心ゲートウェイ + 次手ナビゲーション）と `session-handoff`（ハンドオフファイル管理）を追加する。`decision-log` の発動条件を強化し、ADRが意思決定の瞬間に作成されるようにする。`docs/principles.md`（Layer 1）は変更しない。

**Tech Stack:** Markdown, YAML frontmatter（Skill定義）, PowerShell（既存の `scripts/sync-template.ps1`）

**前提:** 本タスクは `master` ブランチで作業する想定。ブランチ切り替えが必要な場合は事前にユーザーへ確認すること。

---

## File Structure（変更ファイル一覧）

| 種別 | パス | 役割 |
|------|------|------|
| 新規 | `docs/decisions/0004-introduce-start-work-skill.md` | ADR: start-work 導入の決定記録 |
| 新規 | `docs/decisions/0005-adopt-handoff-file-scheme.md` | ADR: ハンドオフファイル方式の決定記録 |
| 新規 | `docs/decisions/0006-continuous-adr-detection-rule.md` | ADR: 継続的ADR検出ルール導入の決定記録 |
| 新規 | `skills/session-handoff/SKILL.md` | ハンドオフファイル管理スキル |
| 新規 | `skills/start-work/SKILL.md` | 作業起点スキル |
| 修正 | `skills/decision-log/SKILL.md` | 検出トリガー一覧追加・description 強化・手順修正 |
| 修正 | `.github/copilot-instructions.md` | 「作業の起点」「意思決定の即時記録」セクション追加・既存重複削除 |
| 修正 | `docs/decisions/README.md` | ADR-0004〜0006 のインデックスエントリ追加 |
| 修正 | `template.manifest` | 新スキル2件を追加 |
| 修正 | `CONTRIBUTING.md` | 新スキルの説明追加・シナリオ追加 |
| 修正 | `README.md` | スキル一覧更新 |
| 自動 | `template/**` | `scripts/sync-template.ps1` 実行で再生成 |

---

### Task 1: ADR-0004 を作成する（start-work 導入）

**Files:**
- Create: `docs/decisions/0004-introduce-start-work-skill.md`
- Modify: `docs/decisions/README.md`

**依存:** なし

- [ ] **Step 1: ADRファイルを作成する**

`docs/decisions/0004-introduce-start-work-skill.md` を以下の内容で作成する:

```markdown
# ADR-0004: ワークフロー起点スキル（start-work）の導入

- **Status**: Proposed
- **Date**: 2026-04-27

## Context

本リポジトリのメタ・ガイドラインを実プロジェクトに適用したところ、以下の問題が観察された:

1. brainstorming や writing-plans の途中で意思決定が行われても ADR が作成されない
2. セッションを跨ぐ作業継続の引き継ぎ記録が自動更新されない

これらの問題は、Layer 2（copilot-instructions.md）に常時ルールを書くだけでは LLM の遵守が希釈されやすく、また superpowers の各スキル本体は外部プラグインのため直接フローに割り込めないという制約から生じている。

## Considered Alternatives

1. **copilot-instructions.md に常時ルール追加のみ** — 軽量だが、LLMの遵守に依存し、長文化で希釈されやすい
2. **decision-gate スキルを新設し、間に挟む** — 検出と記録を分離できるが、superpowers から強制呼び出しできない以上、結局 copilot-instructions.md に「呼び出しを強制」と書くことになり、案1と実質同等
3. **作業起点スキル `start-work` を新設し、横断関心（handoff、ADR検出、pre-action-review）を一元化する** — フロー定義を独立した責務として分離でき、ハンドオフ・ADRゲートを始め、将来の横断関心追加にも拡張しやすい

## Decision

案3を採用する。`start-work` を新設し、「横断関心ゲートウェイ + 次手ナビゲーター」として機能させる。フローは1本に固定せず、ユーザーの作業意図に応じて superpowers の適切なスキルへ delegate する設計とする（順序固定によるフロー逸脱問題を回避）。

superpowers が不在の環境でも動作するよう、各フェーズには簡易インラインフォールバックを内包する。

## Consequences

- 横断関心が一元化され、ADRゲートとハンドオフ更新が確実に発火するようになる
- copilot-instructions.md の「作業開始時は start-work を呼ぶ」という1行ルールに集約され、ルールの希釈が抑えられる
- スキル数が2つ増える（start-work, session-handoff）。学習コストが微増する
- superpowers の API が破壊的変更を起こした場合、依存検出ロジックの更新が必要になる
```

- [ ] **Step 2: ADRインデックスを更新する**

`docs/decisions/README.md` のテーブルに以下の行を追加する（既存の最終行 0003 の下）:

```markdown
| [0004](0004-introduce-start-work-skill.md) | ワークフロー起点スキル（start-work）の導入 | Proposed | 2026-04-27 |
```

- [ ] **Step 3: コミット**

```powershell
git add docs/decisions/0004-introduce-start-work-skill.md docs/decisions/README.md
git commit -m "adr: 0004 - introduce start-work skill" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 2: ADR-0005 を作成する（ハンドオフファイル方式）

**Files:**
- Create: `docs/decisions/0005-adopt-handoff-file-scheme.md`
- Modify: `docs/decisions/README.md`

**依存:** Task 1（インデックス追記の順序整合のため）

- [ ] **Step 1: ADRファイルを作成する**

`docs/decisions/0005-adopt-handoff-file-scheme.md` を以下の内容で作成する:

```markdown
# ADR-0005: セッション継続のためのハンドオフファイル方式の採用

- **Status**: Proposed
- **Date**: 2026-04-27

## Context

AIエージェントとの作業はセッションコンテキストが揮発するため、別セッションで作業を継続する際に「文脈ゼロから再開できる」状態を保つ必要がある。現状はユーザーが手動で「進捗ファイルを出力してほしい」と依頼する必要があり、忘却・粒度のばらつきが発生している。

## Considered Alternatives

1. **プロジェクト全体で1ファイル**（`docs/handoff.md`） — シンプルだが、複数機能を並行開発する場合に競合する
2. **作業中ブランチごとに1ファイル**（`docs/handoff/<branch>.md`、git管理） — ブランチと作業の対応が自然、履歴が残る
3. **git管理外のローカルファイル**（`.session/handoff.md`、.gitignore で除外） — 個人用で軽量だが、共有・引き継ぎが困難
4. **feature/spec ごとの仕様書ディレクトリ内に同梱** — 仕様変更との一体管理が可能だが、仕様書のないアドホック作業を扱えない

## Decision

案2を採用する。`docs/handoff/<branch-name>.md` をブランチ単位で git 管理する。ブランチ名のスラッシュは `_` に置換する（例: `feature/auth` → `feature_auth.md`）。

更新タイミングは「マイルストーン到達時（スキル完了、plan の 1 タスク完了など）+ セッション終了時」とする。新セッション開始時は `start-work` スキルが現在ブランチの handoff を自動検出して読み込み、「前回の続きから始めますか?」とユーザーに確認する。

ファイルの読み書きは専用スキル `session-handoff` に責務分離する。

## Consequences

- ブランチを切り替えると自動的に該当作業の文脈に切り替わる
- handoff の履歴が git に残るため、過去の作業経緯を追える
- 並行ブランチが多い場合は handoff ファイルが増える。将来的に `docs/handoff/archive/` への移動機構が必要になる可能性がある
- ブランチ名に依存するため、PR後にブランチを削除すると該当 handoff ファイルが孤立する（残しておけば履歴として有用）
```

- [ ] **Step 2: ADRインデックスを更新する**

`docs/decisions/README.md` のテーブルに以下の行を追加する（0004 の下）:

```markdown
| [0005](0005-adopt-handoff-file-scheme.md) | セッション継続のためのハンドオフファイル方式の採用 | Proposed | 2026-04-27 |
```

- [ ] **Step 3: コミット**

```powershell
git add docs/decisions/0005-adopt-handoff-file-scheme.md docs/decisions/README.md
git commit -m "adr: 0005 - adopt handoff file scheme" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 3: ADR-0006 を作成する（継続的ADR検出ルール）

**Files:**
- Create: `docs/decisions/0006-continuous-adr-detection-rule.md`
- Modify: `docs/decisions/README.md`

**依存:** Task 2

- [ ] **Step 1: ADRファイルを作成する**

`docs/decisions/0006-continuous-adr-detection-rule.md` を以下の内容で作成する:

```markdown
# ADR-0006: 意思決定の継続検出ルールの導入

- **Status**: Proposed
- **Date**: 2026-04-27

## Context

ADR作成は従来「明示的に decision-log スキルを呼んだ場合」のみ発火していたため、brainstorming や writing-plans のような長時間スキルの実行中に意思決定が行われても ADR が作成されないことが多発した。「スキルが終わってから作ろう」とすると、その間にコンテキストが失われ、ADR の質が落ちるか、そもそも作られない。

## Considered Alternatives

1. **start-work スキル内の境界チェックでまとめて作成** — 実装は容易だが、長時間スキルの途中では発火しない
2. **copilot-instructions.md に「常時適用」のルールとして追加** — どのスキル実行中でも有効、希釈リスクはあるが多層化で補強可能
3. **decision-log スキルの description を強化し、即時呼び出しを誘導** — 補助的だが、単独では発火を保証しない

## Decision

案2を主軸とし、案1と案3を補強として組み合わせる:

- **層1**: `copilot-instructions.md` に「実行中のスキル・タスクに関わらず、意思決定を検出した瞬間に decision-log を呼ぶ」常時ルールを追加
- **層2**: `start-work` スキル冒頭で本ルールを再宣言
- **層3**: `decision-log` スキルの description と「いつ使うか」セクションを「検出トリガー一覧」に書き換え、即時呼び出しを明示

「スキルの途中だから後で」を明確に禁止する文言を含める。

## Consequences

- brainstorming のような長時間スキルの途中でも ADR がリアルタイムに作成されるようになる
- ADR ドラフトの作成回数が増えるため、ユーザーの承認操作が増える可能性がある
- 弱トリガー（命名規則、ライブラリ選定など）は自己評価にゆだねるため、ノイズと取りこぼしのバランス調整が将来必要になる可能性がある
```

- [ ] **Step 2: ADRインデックスを更新する**

`docs/decisions/README.md` のテーブルに以下の行を追加する（0005 の下）:

```markdown
| [0006](0006-continuous-adr-detection-rule.md) | 意思決定の継続検出ルールの導入 | Proposed | 2026-04-27 |
```

- [ ] **Step 3: コミット**

```powershell
git add docs/decisions/0006-continuous-adr-detection-rule.md docs/decisions/README.md
git commit -m "adr: 0006 - continuous ADR detection rule" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 4: `session-handoff` スキルを作成する

**Files:**
- Create: `skills/session-handoff/SKILL.md`

**依存:** なし（Task 5 の `start-work` がこのスキルを参照するため、先に作る）

- [ ] **Step 1: スキルファイルを作成する**

`skills/session-handoff/SKILL.md` を以下の内容で作成する:

````markdown
---
name: session-handoff
description: "セッション間で作業を継続するためのハンドオフファイル（docs/handoff/<branch>.md）を読む・作成する・更新する・確定する。マイルストーン到達時とセッション終了時に呼ばれる。"
---

# session-handoff

セッション間の作業引き継ぎファイルを管理するスキル。

## ファイル配置

```
docs/handoff/<branch-name>.md
```

- ブランチ名のスラッシュは `_` に置換する（例: `feature/auth-flow` → `feature_auth-flow.md`）
- main/master ブランチでも作成可能
- git管理対象（コミットして履歴を残す）

## ハンドオフファイルのフォーマット

```markdown
# Handoff: <作業タイトル>

- **Branch**: <branch-name>
- **Last Updated**: YYYY-MM-DD HH:MM (Asia/Tokyo)
- **Status**: in_progress | paused | completed
- **Current Phase**: <作業タイプ>/<現在のスキル or 段階>

## 作業の目的・背景

（このブランチで何を達成しようとしているかの要約。1-3段落）

## 関連ドキュメント

- Spec: `docs/specs/...`
- Plan: `docs/plans/...`
- 関連ADR: ADR-NNNN, ADR-NNNN

## 完了済みタスク

- [x] タスクA（YYYY-MM-DD 完了）

## 進行中のタスク

- [ ] **現在の作業**: タスクC
  - 状態: <どこまでやったか>
  - 残り: <次に何をすべきか>

## 未着手のタスク

- [ ] タスクD

## 既知のブロッカー・懸念

（なし、または箇条書き）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: ...
2. 最初に実行すべきコマンド/スキル: ...
3. 留意点: ...

## 重要な意思決定の履歴

- ADR-NNNN: <タイトル>（YYYY-MM-DD）
```

## 操作

このスキルは4つの操作を提供する。呼び出し側は操作を明示すること。

### 1. read — ハンドオフ読み込み

呼ばれるタイミング: `start-work` の Phase 0（セッション継続チェック）

手順:
1. 現在のブランチ名を取得する: `git branch --show-current`
2. ブランチ名のスラッシュを `_` に置換し、ファイルパス `docs/handoff/<branch>.md` を組み立てる
3. ファイルが存在しなければ「ハンドオフなし」と呼び出し側に返す
4. 存在すれば内容を読み込み、以下の要素を抽出して要約をユーザーに提示する:
   - 作業の目的
   - 進行中タスク（状態と残り）
   - 次セッション開始時のアクション
5. ユーザーに「前回の続きから始めますか?」と確認する

### 2. create — 新規ハンドオフ作成

呼ばれるタイミング: `start-work` の Phase 1（handoff 不在で新規作業開始時）

手順:
1. 上記フォーマットに沿って新規ファイルを作成する
2. 最低限以下を埋める:
   - Branch, Last Updated, Status (in_progress), Current Phase
   - 作業の目的・背景（ヒアリング結果）
   - 関連ドキュメント（あれば）
3. 完了/進行中/未着手のタスクは空でも可（更新で埋める）
4. ファイルを git に add するが、コミットは update/finalize にゆだねる

### 3. update — マイルストーン更新

呼ばれるタイミング: 各スキル完了後、plan の 1 タスク完了時、その他マイルストーン到達時

手順:
1. 既存ファイルを読み込む
2. Last Updated を現在時刻（Asia/Tokyo）に更新する
3. Current Phase を最新の状態に更新する
4. 完了したタスクを「完了済みタスク」セクションに移動する
5. 進行中のタスクの「状態」「残り」を最新化する
6. 重要な意思決定があれば「重要な意思決定の履歴」に ADR 番号を追記する
7. 既知のブロッカーがあれば追記する
8. ファイルを上書き保存する（コミットはセッション終了時、または明示的なコミットタイミングで実施）

### 4. finalize — セッション終了確定

呼ばれるタイミング: ユーザーが「ここまで」「続きは別セッションで」と明示した時、または明らかなセッション終了サイン時

手順:
1. update と同様の更新を実施
2. **「次セッション開始時のアクション」セクションを必ず埋める**:
   - 最初に確認すべきファイル
   - 最初に実行すべきコマンド/スキル
   - 留意点
3. Status を更新する（作業継続なら `paused`、完了なら `completed`、まだ進行中なら `in_progress`）
4. ファイルを git に add してコミットする:

   ```powershell
   git add docs/handoff/<branch>.md
   git commit -m "chore: update handoff for <branch>"
   ```

## 完了済みハンドオフの扱い

PR マージなどで作業完了した handoff は `Status: completed` のまま `docs/handoff/` に残す。アーカイブ機構（`docs/handoff/archive/` への移動）は本スキルでは未実装。将来必要になれば追加する。

## 対応する原則

- 原則1（追跡可能性）: 作業状態と次のステップを記録に残し、後続の作業者が継続可能にする
- 原則3（コンテキスト管理）: セッション間でコンテキストを明示的に引き継ぐ
````

- [ ] **Step 2: ファイル存在を確認する**

```powershell
Test-Path skills/session-handoff/SKILL.md
```

期待: `True`

- [ ] **Step 3: コミット**

```powershell
git add skills/session-handoff/SKILL.md
git commit -m "feat: add session-handoff skill" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 5: `start-work` スキルを作成する

**Files:**
- Create: `skills/start-work/SKILL.md`

**依存:** Task 4（`session-handoff` スキルを参照するため）

- [ ] **Step 1: スキルファイルを作成する**

`skills/start-work/SKILL.md` を以下の内容で作成する:

````markdown
---
name: start-work
description: "新しい作業（新規開発、改修、デバッグ、レビュー、調査など）を開始する起点スキル。セッション継続チェック、状況診断、次手ナビゲーションを行い、横断関心（handoff更新、ADR検出、不可逆操作レビュー）を一貫して適用する。"
---

# start-work

AIエージェントを活用した作業のフローを定義し、フロー通りに動かすための起点スキル。superpowers のフレームワークで実行可能なすべての作業の入り口として機能する。

## いつ使うか

新しい作業を開始する時は、必ず最初にこのスキルを呼ぶこと。ここで言う「作業」とは、新規開発、機能追加、改修、リファクタリング、バグ修正、デバッグ、コードレビュー、調査、PoC、ガイドライン拡張など、superpowers のフレームワークで扱える全ての作業を指す。

## 重要な前提: 継続的ADR検出ルール

このスキルから始まる全ての作業期間中、以下のルールが常時適用される（`copilot-instructions.md` でも宣言されている）:

> 実行中のスキル・タスクに関わらず、以下を検出した瞬間に `decision-log` スキルを呼んでADRドラフトを作成すること:
>
> - 複数の選択肢を比較して1つを選んだ
> - 当初の方針を変更した
> - スコープ・優先度を判断した
> - アーキテクチャや構造に影響する決定をした
>
> 「スキルの途中だから後で」は禁止。検出 → 即ドラフト作成 → ユーザー承認 → 元のスキルへ復帰。

## 手順

### Phase -1: 依存検出

スキル冒頭で以下を確認する:

1. superpowers プラグインの存在を確認する
2. 主要スキル（brainstorming, writing-plans, executing-plans, subagent-driven-development, systematic-debugging, requesting-code-review, receiving-code-review, verification-before-completion）の利用可否を内部マッピング表に記録する
3. 不足があればユーザーに報告する:
   「superpowers の <スキル名> が見つかりません。該当フェーズではインライン簡易フローへフォールバックします。」

### Phase 0: セッション継続チェック

1. `session-handoff` スキルの **read** 操作を呼ぶ
2. 結果に応じて分岐:
   - ハンドオフなし → Phase 1 へ
   - ハンドオフあり → 内容の要約をユーザーに提示し「前回の続きから始めますか?」と確認
     - Yes → ハンドオフの「次セッション開始時のアクション」に従って該当ワークフローの再開ポイントへ移動し、Phase 2 から続行
     - No → Phase 1 へ

### Phase 1: 状況診断（state assessment）

1. リポジトリ状態を確認する:
   - `git branch --show-current`
   - `git status`（未コミット変更の有無）
2. ユーザーから今回の作業意図をヒアリングする（目的・スコープ・成功基準）
3. ハンドオフが存在しない場合は `session-handoff` の **create** 操作を呼んで新規作成する

### Phase 2: 次手のナビゲーション（ループ）

ユーザーの作業意図に応じて、以下のマッピングから推奨スキルを提示する:

| 作業意図 | 推奨スキル | フォールバック |
|----------|----------|--------------|
| 新規開発・機能追加・改修 | superpowers:brainstorming | インライン簡易ヒアリング |
| 既存仕様からの計画作成 | superpowers:writing-plans | インライン簡易plan作成 |
| 既存planの実装 | superpowers:executing-plans または superpowers:subagent-driven-development | インラインTDDサイクル |
| バグ修正・デバッグ | superpowers:systematic-debugging | インライン仮説立案→検証→修正 |
| コードレビュー対応 | superpowers:receiving-code-review | インライン指摘整理→対応 |
| コードレビュー依頼 | superpowers:requesting-code-review | インラインPR説明作成 |
| 完了前検証 | superpowers:verification-before-completion | インラインチェックリスト確認 |
| ガイドライン拡張 | extend-guidelines | （本リポジトリ固有スキル、フォールバック不要） |
| 調査・分析・PoC | アドホック | アドホック |

ユーザーに次手を確認する（推奨を提示するが強制しない。ユーザーの意図優先）。
選択されたスキルへ delegate する。

### 横断的ラッパー（全スキル実行の前後で適用）

スキルへ delegate する前後で以下を実施する:

**Pre（実行前）:**
- 不可逆操作・大規模変更の可能性があれば `pre-action-review` スキルを呼ぶ

**Post（実行後）:**
1. **ADR候補検出**: 実行中に行われた意思決定が以下のいずれかに該当するか自己評価する:
   - 複数の選択肢を比較して1つを選んだ
   - 当初の方針を変更した
   - スコープ・優先度を判断した
   - アーキテクチャや構造に影響する決定をした

   該当すれば `decision-log` スキルを呼ぶ（実行中に既に作成済みのものは除く）。

2. **ハンドオフ更新**: マイルストーン到達と判断したら `session-handoff` の **update** 操作を呼ぶ。マイルストーンの例:
   - スキルの完了
   - plan の 1 タスク完了
   - 重要な分岐の通過

3. **次手ナビゲーションへ復帰**: Phase 2 へ戻る

### セッション終了処理

ユーザーが「ここまで」「続きは別セッションで」と明示した時、または明らかなセッション終了サイン（PR作成完了、作業完了宣言など）を検出した時:

1. `session-handoff` の **finalize** 操作を呼ぶ
2. ハンドオフの「次セッション開始時のアクション」が確実に埋まっていることを確認する
3. ユーザーに完了を報告する

## インラインフォールバックの内容

superpowers が無い環境でも最低限動くよう、各フェーズの簡易ガイダンスを以下に記載する。

### 要件明確化（brainstorming 不在時）

1. 1問ずつヒアリングする（複数質問を1メッセージに混ぜない）
2. 確認する項目: 目的、スコープ、制約、成功基準、関係者・利用者
3. 2-3案を比較してアプローチを選ぶ → ADR候補
4. 設計の概要をユーザーに提示し承認を得る

### 計画（writing-plans 不在時）

1. タスクを箇条書きで列挙する
2. 各タスクの依存関係を明示する
3. 各タスクのファイルパスを明示する
4. 各タスクの完了基準（手動でも自動でも）を明示する

### 実装（executing-plans 不在時）

1. plan の 1 タスクを取り出す
2. テストを先に書く（TDDサイクル）
3. 最小限の実装でテストを通す
4. リファクタリング
5. コミット
6. 次のタスクへ

### デバッグ（systematic-debugging 不在時）

1. 再現手順を確認する
2. 仮説を立てる（何が原因か）
3. 仮説を検証する（ログ追加、最小再現、二分探索）
4. 原因を修正する
5. 再現手順で再検証する

## 対応する原則

- 原則1（追跡可能性）: ADRゲート、handoff の自動適用
- 原則2（関心の分離）: ワークフローのオーケストレーションを独立した責務として分離
- 原則3（コンテキスト管理）: handoff によるセッション間コンテキスト引継ぎ
- 原則4（人間の関与）: 次手選択、ADR承認、handoff 確認
- 原則5（漸進的検証）: マイルストーン単位での handoff 更新
````

- [ ] **Step 2: ファイル存在を確認する**

```powershell
Test-Path skills/start-work/SKILL.md
```

期待: `True`

- [ ] **Step 3: コミット**

```powershell
git add skills/start-work/SKILL.md
git commit -m "feat: add start-work skill" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 6: `decision-log` スキルを拡張する

**Files:**
- Modify: `skills/decision-log/SKILL.md`

**依存:** なし

- [ ] **Step 1: description を強化する**

`skills/decision-log/SKILL.md` の YAML frontmatter の description を以下に置き換える。

旧:

```yaml
description: "重要な意思決定をADR（Architecture Decision Record）として記録・管理する。設計判断、プロセス決定、スコープ決定、方針決定など、「迷って選んだもの」をすべて構造化して記録する。"
```

新:

```yaml
description: "重要な意思決定をADR（Architecture Decision Record）として記録・管理する。設計判断、プロセス決定、スコープ決定、方針決定を構造化して記録する。意思決定を検出した瞬間に呼ぶこと。実行中の他スキルの完了を待ってはならない。"
```

`edit` ツールで該当行を置換する。

- [ ] **Step 2: 「いつ使うか」セクションを置き換える**

旧:

```markdown
## いつ使うか

以下のいずれかに該当する場合にこのスキルを呼び出す:

1. **設計・アーキテクチャの決定時** — 例: 「レイヤード方式を採用する」「マイクロサービスではなくモノリスで始める」
2. **プロセス・ワークフローの決定時** — 例: 「情報収集と分析を別セッションに分ける」「コードレビューはAI自動レビュー＋人間の最終確認」
3. **スコープ・優先度の決定時** — 例: 「MVPでは通知機能を含めない」「セキュリティ強化を機能追加より優先する」
4. **方針・ルールの決定時** — 例: 「外部APIの情報は必ずキャッシュ経由」「エージェント3回連続エラーで人間にエスカレーション」
5. **既存の判断の変更時** — 旧ADRを Superseded に更新し、新ADRを作成する

**判断基準**: 「迷って選んだもの」はすべてADR候補。迷わなかったもの（自明な選択）はADR不要。
```

新:

```markdown
## いつ使うか — 検出トリガー一覧

以下のいずれかを **検出した瞬間に**、現在実行中のスキル・タスクに関わらずこのスキルを呼び出すこと。「スキルの途中だから後で」は禁止。

### 強トリガー（必ず呼ぶ）

1. **複数案からの選択** — 2つ以上の選択肢を比較し1つを選んだとき
   - 例: brainstorming で 2-3 案から採用案を決めた直後
   - 例: writing-plans で技術スタックを選定した直後
2. **方針の変更** — 当初決めた方針・設計を覆したとき
   - 例: 実装中に「設計を変更する」と判断した瞬間
3. **アーキテクチャに影響する決定** — 層構成、モジュール境界、依存関係に関する判断
4. **スコープ・優先度の判断** — 「この機能は含める/含めない」「これを優先する」と決めたとき
5. **ガイドライン・ルールの追加・変更**
6. **既存の判断の変更** — 旧ADRを Superseded に更新し、新ADRを作成する

### 弱トリガー（自己評価して必要なら呼ぶ）

- 命名規則の決定
- ライブラリ・ツールの選定
- フォーマット・スタイルの決定

### 呼ぶ必要がない場面

- 自明な選択（迷いがなかったもの）
- 既存ADRに従っただけの判断
- 一時的な実装の詳細（後で変えても影響が限定的）

**判断基準**: 強トリガーに該当したら必ず作成。弱トリガーは「将来この判断の理由を知りたくなる可能性が中程度以上」なら作成。
```

`edit` ツールで該当ブロックを置換する。

- [ ] **Step 3: 「ADR作成手順」セクションに「検出を報告」ステップを追加する**

「## ADR作成手順」セクションの直後（`### 1. 次の連番を決定する` の前）に以下を追加する:

```markdown
### 0. 検出を報告

ユーザーに以下のように通知する:

「意思決定を検出しました（トリガー: <該当した強/弱トリガー>）。ADRドラフトを作成します。」
```

- [ ] **Step 4: 「## ユーザーへの確認」セクションを修正する**

旧:

```markdown
## ユーザーへの確認

ADR作成後、ユーザーに以下を確認する:
「ADR-NNNN を作成しました。内容を確認して、承認（Accepted）してよいか教えてください。」
```

新:

```markdown
## ユーザーへの確認

ADR作成後、ユーザーに以下を提示する:

「ADR-NNNN を作成しました。内容を確認して以下から選んでください:
- 承認 → Status を Accepted に更新します
- 修正依頼 → 該当箇所を修正します
- 却下 → ファイルとインデックスエントリを削除します」

ユーザー応答に応じて確定処理を実施する:
- 承認: Status を Accepted に更新 → インデックスも更新 → コミット
- 却下: ADRファイル削除 → インデックスエントリ削除 → コミット（理由を commit message に残す）
```

- [ ] **Step 5: 編集後の内容を確認する**

```powershell
Get-Content skills/decision-log/SKILL.md | Select-Object -First 60
```

期待: 新しい description と「いつ使うか — 検出トリガー一覧」が表示される。

- [ ] **Step 6: コミット**

```powershell
git add skills/decision-log/SKILL.md
git commit -m "feat: enhance decision-log skill with continuous detection triggers" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 7: `.github/copilot-instructions.md` を更新する

**Files:**
- Modify: `.github/copilot-instructions.md`

**依存:** Task 4, Task 5, Task 6（参照される新スキルが存在している必要があるため）

- [ ] **Step 1: 「システム設定」セクションの末尾（### 言語 の直後）に「作業の起点」と「意思決定の即時記録」を追加する**

`.github/copilot-instructions.md` の `### 言語` ブロック（既存の末尾の `</EXTREMELY-IMPORTANT>` を含む）の直後、`## メタ・ガイドライン` の前に以下を挿入する:

```markdown
### 作業の起点

<EXTREMELY-IMPORTANT>

新しい作業（新規開発、改修、デバッグ、レビュー、調査など）を開始する時は、必ず `start-work` スキルを呼ぶこと。これにより、ワークフロー、ハンドオフ、ADR検出といった横断関心が一貫して適用される。

</EXTREMELY-IMPORTANT>

### 意思決定の即時記録（継続適用）

<EXTREMELY-IMPORTANT>

実行中のスキル・タスクに関わらず、以下を検出した瞬間に `decision-log` スキルを呼んでADRドラフトを作成すること:

- 複数の選択肢を比較して1つを選んだ
- 当初の方針を変更した
- スコープ・優先度を判断した
- アーキテクチャや構造に影響する決定をした

「スキルの途中だから後で」は禁止。検出 → 即ドラフト作成 → ユーザー承認 → 元のスキルへ復帰。

</EXTREMELY-IMPORTANT>
```

`edit` ツールで `### 言語` セクションの `</EXTREMELY-IMPORTANT>` 直後に追記する。

- [ ] **Step 2: 「メタ・ガイドライン」配下の「### 意思決定の記録」を簡素化する**

旧:

```markdown
### 意思決定の記録

- 設計判断を行った場合、その理由をコミットメッセージまたはコード内コメントに残すこと
- 新規ファイルや重要な変更には、変更理由を明記すること
- 複数の選択肢を比較検討して一つを選んだ場合、decision-log スキルを使用してADRを作成すること
```

新（重複した3項目目を削除し、システム設定の常時ルールへ集約）:

```markdown
### 意思決定の記録

- 設計判断を行った場合、その理由をコミットメッセージまたはコード内コメントに残すこと
- 新規ファイルや重要な変更には、変更理由を明記すること
- ADR作成のトリガーは「システム設定 / 意思決定の即時記録（継続適用）」を参照すること
```

`edit` ツールで該当ブロックを置換する。

- [ ] **Step 3: 編集後の内容を確認する**

```powershell
Get-Content .github/copilot-instructions.md
```

期待: 「### 作業の起点」「### 意思決定の即時記録（継続適用）」が「### 言語」の後・「## メタ・ガイドライン」の前に存在し、「### 意思決定の記録」の3項目目が新しい文言になっている。

- [ ] **Step 4: コミット**

```powershell
git add .github/copilot-instructions.md
git commit -m "docs: add start-work and continuous ADR rules to copilot-instructions" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 8: `template.manifest` を更新し、テンプレートを同期する

**Files:**
- Modify: `template.manifest`
- Auto-regen: `template/**`

**依存:** Task 4, Task 5, Task 6, Task 7

- [ ] **Step 1: `template.manifest` に新スキル2件を追加する**

旧:

```
.github/copilot-instructions.md
docs/principles.md
skills/decision-log/SKILL.md
skills/pre-action-review/SKILL.md
```

新:

```
.github/copilot-instructions.md
docs/principles.md
skills/decision-log/SKILL.md
skills/pre-action-review/SKILL.md
skills/start-work/SKILL.md
skills/session-handoff/SKILL.md
```

`edit` ツールで `skills/pre-action-review/SKILL.md` 行の直後に2行追加する。

- [ ] **Step 2: 同期スクリプトを実行する**

```powershell
pwsh scripts/sync-template.ps1
```

期待: 出力に以下が含まれる:
- `✓ skills/start-work/SKILL.md`
- `✓ skills/session-handoff/SKILL.md`
- `[sync-template] Done. 7 files synced to template/`

- [ ] **Step 3: 同期結果を確認する**

```powershell
Test-Path template/skills/start-work/SKILL.md
Test-Path template/skills/session-handoff/SKILL.md
Get-Content template/docs/decisions/README.md
```

期待:
- 両 `Test-Path` が `True`
- `template/docs/decisions/README.md` には ADR データ行が含まれない（ヘッダーのみの空インデックス）

- [ ] **Step 4: コミット**

```powershell
git add template.manifest template/
git commit -m "chore: sync template with new start-work and session-handoff skills" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 9: `CONTRIBUTING.md` を更新する

**Files:**
- Modify: `CONTRIBUTING.md`

**依存:** Task 5

- [ ] **Step 1: 新しいシナリオセクションを追加する**

`CONTRIBUTING.md` の末尾（既存の「## シナリオ: ADRを記録するとき」の後）に以下を追加する:

```markdown

## シナリオ: ワークフロー起点スキル（start-work）を変更するとき

### 背景

`start-work` はAIエージェントの作業フロー全体のオーケストレーション層を担う。横断関心（handoff更新、ADR検出、不可逆操作レビュー）の適用や、作業意図に応じた次手スキルのナビゲーションが含まれる。

### 判定基準

以下に該当する場合に `start-work` の変更を検討する:

- 新しい作業タイプ（例: 新しい開発スタイル、新しい品質保証フロー）への対応が必要
- 横断関心を新しく追加する（例: テレメトリ、進捗可視化）
- 推奨スキルマッピングを更新する（superpowers の新スキル対応など）
- フェーズ構造そのものを見直す

### 手順

1. ADRを作成して変更理由を記録する（重要な変更の場合）
2. `skills/start-work/SKILL.md` を更新する
3. 横断関心を追加する場合、対応する補助スキル（例: `decision-log`, `session-handoff`, `pre-action-review`）の整合を確認する
4. テンプレート対象なので `scripts/sync-template.ps1` を実行する

### チェックリスト

- フェーズの責務分離が崩れていないか
- 推奨スキルマッピングと現実の superpowers スキル群が一致しているか
- インラインフォールバックが各フェーズで提供されているか
- 横断関心の追加が他スキルとの責務重複を生んでいないか
```

`edit` ツールでファイル末尾に追記する。

- [ ] **Step 2: コミット**

```powershell
git add CONTRIBUTING.md
git commit -m "docs: add scenario for modifying start-work skill" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 10: `README.md` のスキル一覧を更新する

**Files:**
- Modify: `README.md`

**依存:** Task 4, Task 5

- [ ] **Step 1: スキル一覧テーブルに2行追加する**

旧:

```markdown
| スキル | 説明 |
|--------|------|
| [`decision-log`](skills/decision-log/) | 意思決定をADR（Architecture Decision Record）として記録・管理する |
| [`pre-action-review`](skills/pre-action-review/) | 不可逆操作前にリスク評価と確認を実施する |
| [`extend-guidelines`](skills/extend-guidelines/) | ガイドラインの拡張作業をガイドするゲートウェイ |
```

新:

```markdown
| スキル | 説明 |
|--------|------|
| [`start-work`](skills/start-work/) | 新しい作業の起点。横断関心（handoff、ADR検出、不可逆操作レビュー）を一貫適用し、次手のスキルへナビゲートする |
| [`session-handoff`](skills/session-handoff/) | セッション間の作業引き継ぎファイル（ハンドオフ）を読む・作成する・更新する・確定する |
| [`decision-log`](skills/decision-log/) | 意思決定をADR（Architecture Decision Record）として記録・管理する |
| [`pre-action-review`](skills/pre-action-review/) | 不可逆操作前にリスク評価と確認を実施する |
| [`extend-guidelines`](skills/extend-guidelines/) | ガイドラインの拡張作業をガイドするゲートウェイ |
```

`edit` ツールで該当ブロックを置換する。

- [ ] **Step 2: コミット**

```powershell
git add README.md
git commit -m "docs: list start-work and session-handoff skills in README" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 11: ADR の Status を Accepted に更新する（ユーザー承認後）

**Files:**
- Modify: `docs/decisions/0004-introduce-start-work-skill.md`
- Modify: `docs/decisions/0005-adopt-handoff-file-scheme.md`
- Modify: `docs/decisions/0006-continuous-adr-detection-rule.md`
- Modify: `docs/decisions/README.md`

**依存:** Task 1〜10 完了後、ユーザーに最終確認

- [ ] **Step 1: ユーザーに承認を求める**

以下を提示する:

「ADR-0004, 0005, 0006 を Proposed として作成しました。実装も完了しました。3件とも Accepted に更新してよいですか?」

承認が得られた場合のみ Step 2 へ進む。否認・修正依頼があれば該当 ADR を修正してから再確認する。

- [ ] **Step 2: 各ADRの Status を更新する**

3ファイルそれぞれについて、`- **Status**: Proposed` を `- **Status**: Accepted` に置き換える。

- [ ] **Step 3: インデックスを更新する**

`docs/decisions/README.md` の3行を `Proposed` から `Accepted` に置き換える。

- [ ] **Step 4: テンプレート同期（インデックスのテンプレート版も更新するため）**

```powershell
pwsh scripts/sync-template.ps1
```

- [ ] **Step 5: コミット**

```powershell
git add docs/decisions/0004-introduce-start-work-skill.md docs/decisions/0005-adopt-handoff-file-scheme.md docs/decisions/0006-continuous-adr-detection-rule.md docs/decisions/README.md template/
git commit -m "adr: accept 0004, 0005, 0006" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 12: 最終検証

**Files:** なし（読み取り専用検証）

**依存:** Task 1〜11

- [ ] **Step 1: ファイル一式の存在確認**

```powershell
$paths = @(
  "skills/start-work/SKILL.md",
  "skills/session-handoff/SKILL.md",
  "skills/decision-log/SKILL.md",
  ".github/copilot-instructions.md",
  "docs/decisions/0004-introduce-start-work-skill.md",
  "docs/decisions/0005-adopt-handoff-file-scheme.md",
  "docs/decisions/0006-continuous-adr-detection-rule.md",
  "template/skills/start-work/SKILL.md",
  "template/skills/session-handoff/SKILL.md",
  "template/.github/copilot-instructions.md"
)
$paths | ForEach-Object { "{0}`t{1}" -f (Test-Path $_), $_ }
```

期待: 全行が `True` で始まる。

- [ ] **Step 2: 同期スクリプト再実行で差分が出ないことを確認**

```powershell
pwsh scripts/sync-template.ps1
git status
```

期待: `git status` に変更が無い（テンプレートが既に最新）。

- [ ] **Step 3: 検証シナリオの机上確認**

以下のシナリオを `start-work` の手順に沿って机上トレースし、フローが破綻しないことを確認する:

1. **新規開発フロー**: 新ブランチ → start-work → handoff なし → Phase 1 → ユーザーが「新規機能」と回答 → brainstorming へ delegate → 途中で2-3案比較 → 継続的ADR検出ルールにより decision-log が呼ばれる
2. **セッション継続**: 一度作業を中断 → handoff finalize → 次セッションで start-work → handoff 検出 → 「続きから?」表示
3. **superpowers 不在**: brainstorming 等が利用できない状況 → Phase -1 でユーザーへ通知 → インライン簡易フローへフォールバック
4. **デバッグフロー**: start-work → 「バグ修正」と回答 → systematic-debugging が選択肢に出ること、brainstorming を強制されないこと

各シナリオで詰まる箇所があれば該当スキルへの修正を Task 13 として追加する。

- [ ] **Step 4: ハンドオフを完了状態にする**

このplan自体の作業 handoff（`docs/handoff/<branch>.md`）の Status を `completed` に更新し、コミットする（実装中に start-work / session-handoff を使い始めている場合）。本planを起点としたhandoffがなければスキップ。

---

## Self-Review

- **Spec coverage**: spec のセクション 4〜11 すべてに対応する Task が存在することを確認済み（4→Task 5,7 / 5→Task 5 / 6→Task 4 / 7→Task 6 / 8→Task 7 / 9→Task 8 / 10→Task 9 / 11→Task 1,2,3,11）。section 12 の検証は Task 12 でカバー。
- **Placeholder scan**: TBD/TODO/「適切に」等の曖昧表現なし。各 Step に実コード/コマンドを記載済み。
- **Type consistency**: `read`/`create`/`update`/`finalize` の操作名は session-handoff スキル内・start-work からの呼び出しで統一。`docs/handoff/<branch>.md` のパス規約も統一。Status 値（in_progress/paused/completed）も統一。

## Execution Handoff

Plan complete and saved to `docs/plans/2026-04-27-record-strengthening-plan.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
