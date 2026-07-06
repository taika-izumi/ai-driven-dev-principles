# CLAUDE.md 肥大化ガバナンス（ADR-0040）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** CLAUDE.md（常時指示）の肥大化に対する監視・事前判定・棚卸しの仕組みを導入する（Issue-0018 対策、ADR-0040）。

**Architecture:** 計測スクリプト `scripts/check-claude-md-size.ps1` を新設し、`sync-template.ps1` 末尾から自動呼び出し（監視）。CONTRIBUTING.md に事前判定手順の小節と棚卸しシナリオを追加（判断業務は手順側）。CLAUDE.md 自体と template は変更しない（スクリプト・CONTRIBUTING.md は配布対象外）。

**Tech Stack:** PowerShell（5.1 互換、既存 sync-template.ps1 と同スタイル）、Markdown。

**前提の実測値（2026-07-06、本サイクル中 CLAUDE.md は無変更）:** 11,180 バイト / 114 行 / 箇条書き（行頭 `- `）38 件。閾値はバイト数 12,000 / 箇条書き 45 件（ADR-0040）。

**検証方針:** 本リポジトリにテストフレームワークはない。各タスクは実行コマンドと期待出力による手動検証を行う（ADR-0034: 期待値と編集内容の突合済み。ADR-0038: コミット直前は実体の読み直しで確認）。

---

### Task 1: 計測スクリプト `check-claude-md-size.ps1` の新設

**Files:**
- Create: `scripts/check-claude-md-size.ps1`

- [ ] **Step 1: スクリプトを作成する**

以下の内容で `scripts/check-claude-md-size.ps1` を作成する:

```powershell
# check-claude-md-size.ps1
# CLAUDE.md（常時指示）の規模を計測し、閾値超過時に棚卸しを促す警告を出す（ADR-0040）
# 使い方: pwsh scripts/check-claude-md-size.ps1 (PowerShell 5.1でも動作可)
#         sync-template.ps1 の末尾からも自動で呼ばれる
# 終了コードは常に 0（警告のみ。規範の追加や同期をブロックしない）

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# 閾値（ADR-0040）。データから導出した危険水域ではなく、既知の劣化域から
# 安全マージンを取った管理上のトリップワイヤー。棚卸ししても閾値内へ
# 戻せない場合は、引き上げをユーザーへ提起する（CONTRIBUTING.md 棚卸し手順）
$maxBytes = 12000
$maxBullets = 45

$repoRoot = Split-Path -Parent $PSScriptRoot
$targetPath = Join-Path $repoRoot "CLAUDE.md"

if (-not (Test-Path $targetPath)) {
    Write-Warning "[check-claude-md-size] CLAUDE.md not found at $targetPath"
    exit 0
}

$bytes = (Get-Item $targetPath).Length
$lines = @(Get-Content $targetPath)
$lineCount = $lines.Count
$bulletCount = @($lines | Where-Object { $_ -match '^- ' }).Count

Write-Host "[check-claude-md-size] CLAUDE.md: $bytes bytes (threshold $maxBytes), $bulletCount bullets (threshold $maxBullets), $lineCount lines"

$overBytes = $bytes -gt $maxBytes
$overBullets = $bulletCount -gt $maxBullets

if ($overBytes -or $overBullets) {
    Write-Warning "[check-claude-md-size] 閾値を超過しています。CONTRIBUTING.md「CLAUDE.md を棚卸しするとき」の実施を検討してください。"
    if ($overBytes) {
        Write-Warning "  - バイト数: $bytes > $maxBytes"
    }
    if ($overBullets) {
        Write-Warning "  - 箇条書き件数: $bulletCount > $maxBullets"
    }
}

exit 0
```

- [ ] **Step 2: 単体実行して現在値の出力を確認する**

Run（Bash ツール）: `pwsh scripts/check-claude-md-size.ps1; echo "exit=$?"`
Expected: `[check-claude-md-size] CLAUDE.md: 11180 bytes (threshold 12000), 38 bullets (threshold 45), 114 lines` と `exit=0`。警告は出ない（現在値は閾値内）

- [ ] **Step 3: 警告分岐の動作を一時的な閾値で確認する**

スクリプトの `$maxBytes = 12000` を一時的に `$maxBytes = 10000` へ書き換えて実行する。

Run（Bash ツール）: `pwsh scripts/check-claude-md-size.ps1; echo "exit=$?"`
Expected: 計測行に続き `閾値を超過しています` の警告と `- バイト数: 11180 > 10000` が出力され、`exit=0`（警告が出ても終了コードは 0）

確認後、`$maxBytes = 12000` へ戻し、Step 2 と同じコマンドで警告が消えることを再確認する。

- [ ] **Step 4: コミット**

```bash
git add scripts/check-claude-md-size.ps1
git commit -m "feat: CLAUDE.md 規模計測スクリプトを新設（閾値 12,000 バイト / 45 件。ADR-0040）"
```

---

### Task 2: `sync-template.ps1` 末尾から計測を自動呼び出し

**Files:**
- Modify: `scripts/sync-template.ps1`（末尾、`Write-Host "[sync-template] Done. ..."` の直後）

- [ ] **Step 1: 呼び出しを追記する**

`sync-template.ps1` の最終行 `Write-Host "[sync-template] Done. $totalFiles files synced to template/"` の直後に以下を追加する:

```powershell

# CLAUDE.md 規模計測（ADR-0040。警告のみで同期はブロックしない）
& (Join-Path $PSScriptRoot "check-claude-md-size.ps1")
```

- [ ] **Step 2: sync-template を実行して連動を確認する**

Run: `pwsh scripts/sync-template.ps1`
Expected: 従来の同期出力（`[sync-template] Done. 7 files synced to template/`）に続けて `[check-claude-md-size] CLAUDE.md: 11180 bytes ...` の計測行が表示される

- [ ] **Step 3: template/ に差分がないことを確認する**

Run: `git status --short template/`
Expected: 出力なし（CLAUDE.md ほか manifest 対象は本サイクルで無変更のため、同期結果も差分なし）

- [ ] **Step 4: コミット**

```bash
git add scripts/sync-template.ps1
git commit -m "feat: sync-template.ps1 末尾に CLAUDE.md 規模計測の自動呼び出しを追加（ADR-0040）"
```

---

### Task 3: CONTRIBUTING.md に事前判定手順の小節を追加

**Files:**
- Modify: `CONTRIBUTING.md`（「シナリオ: CLAUDE.md を更新するとき」内、「判定基準」小節と「注意事項」小節の間）

- [ ] **Step 1: 小節を挿入する**

「シナリオ: CLAUDE.md を更新するとき」の「判定基準」小節（`- Skill化するほど複雑ではないが、毎回伝えたい指示` の行）と「### 注意事項」の間に、以下を挿入する:

```markdown
### 手順（規範を追加するときの事前判定）

CLAUDE.md は常時指示として最も高価な置き場所である（毎セッション読み込まれ、template 経由で配布先全プロジェクトへ波及する）。規範の追加を検討し始めた時点で、以下の事前判定を行う（ADR-0040）:

1. **実測**: `scripts/check-claude-md-size.ps1` を単体実行して現在値（バイト数・箇条書き件数）を確認し、追加する規範の概算サイズと合わせて数字で把握する（感覚論で議論しない）
2. **放置リスク評価**: その規範が防ぐ失敗の性質を評価する。「静かに壊れて発見が遅れ、修復コストが高い」失敗なら常時指示の候補。「人間レビューや後続工程で必ず顕在化する」失敗なら常時指示には置かない
3. **配置先の優先順位検討**: ① 環境・ツール設定による構造的解決（ADR-0039）→ ② Layer 3 スキル（特定状況でのみ必要な場合）→ ③ 発生箇所の手順書（CONTRIBUTING.md 等）→ ④ CLAUDE.md（最後の選択肢）の順に検討する
4. **ゲート必須**: CLAUDE.md に置く場合は、観測可能な発動条件でゲートする（ADR-0032。無条件の「常に〜せよ」型を避ける）
5. **追加後の確認**: 追加後に `scripts/sync-template.ps1` を実行する（計測が自動で走る。閾値超過の警告が出たら「CLAUDE.md を棚卸しするとき」の実施を検討する）
```

- [ ] **Step 2: read-back 検証**

Run: `grep -c "事前判定" CONTRIBUTING.md`
Expected: `2`（小節見出しと手順導入文の2箇所）

Run: `grep -n "### 手順（規範を追加するときの事前判定）" CONTRIBUTING.md`
Expected: 1件、「シナリオ: CLAUDE.md を更新するとき」ブロック内（行 65 前後）

- [ ] **Step 3: コミット**

```bash
git add CONTRIBUTING.md
git commit -m "docs: CONTRIBUTING.md に CLAUDE.md 規範追加時の事前判定手順を追加（ADR-0040）"
```

---

### Task 4: CONTRIBUTING.md に棚卸しシナリオを追加

**Files:**
- Modify: `CONTRIBUTING.md`（「シナリオ: CLAUDE.md を更新するとき」の直後、「## シナリオ: Skillを新規作成するとき」の直前）

- [ ] **Step 1: 新シナリオを挿入する**

「シナリオ: CLAUDE.md を更新するとき」の末尾（注意事項の最終箇条 `- 規範の適用条件・撤去基準は、エージェントが観測・実行できる事実で書くこと（ADR-0032）`）と `## シナリオ: Skillを新規作成するとき` の間に、以下を挿入する:

```markdown
## シナリオ: CLAUDE.md を棚卸しするとき

### 背景

CLAUDE.md の規範は課題対策のたびに増える一方になりやすい。累積した常時指示は、今の作業に無関係な指示への注意配分とコンテキスト消費を通じて配布先全プロジェクトへ波及するため、減らす側のフローとして棚卸しを行う（ADR-0040、Issue-0018）。

### 発動条件

- `scripts/check-claude-md-size.ps1`（単体実行または `sync-template.ps1` 経由）が閾値超過を警告したとき。エージェントは棚卸しの実施をユーザーに提案し、実施の要否・時期はユーザーが判断する
- または、ユーザーが棚卸しを指示したとき

### 手順

1. `scripts/check-claude-md-size.ps1` を単体実行し、現在値を確認する
2. CLAUDE.md の箇条を1件ずつ、導入元の ADR（`docs/records/decisions/README.md` から特定する）と突合し、以下の4分類で判定する:
   - **構造的置換**: 環境・ツール設定・自動検査で塞げるようになった → 置換して削除する（ADR-0039 の事後適用。例: 改行規範を .gitattributes へ置き換えた ADR-0037）
   - **失効**: 発動条件のモデル・ツール・状況が変わり、もう発動しない → 削除する
   - **退避**: 常時適用ではなく特定状況でのみ必要と分かった → Layer 3（スキル）へ移動する
   - **現役**: 維持する（必要なら文言だけ圧縮する）
3. 削除・退避・置換の判断は ADR で記録する（規範を導入した元 ADR のステータスを更新し、新 ADR を作成する）
4. 変更後に `scripts/sync-template.ps1` を実行し、計測が閾値内へ戻ったことを確認する
5. 現役規範だけで閾値を超えていて戻せない場合は、閾値（`check-claude-md-size.ps1` 内の定数）の引き上げをユーザーに提起する

### チェックリスト

- 削除・退避・置換を ADR に記録したか（元 ADR のステータス更新を含む）
- template 同期と read-back 検証をしたか
- 計測が閾値内へ戻ったか（戻らない場合、閾値引き上げをユーザーへ提起したか）
- （任意）重要度の高い規範ほど前方に配置されているか（先に書かれた指示ほど守られやすい傾向の報告がある。ADR-0040 の Context 参照）
```

- [ ] **Step 2: read-back 検証**

Run: `grep -c "check-claude-md-size" CONTRIBUTING.md`
Expected: `4`（事前判定の手順1、棚卸しの発動条件・手順1・手順5）

Run: `grep -n "^## シナリオ" CONTRIBUTING.md`
Expected: 既存9シナリオ＋新規1件の計10件。「CLAUDE.md を棚卸しするとき」が「CLAUDE.md を更新するとき」の直後に位置する

- [ ] **Step 3: コミット**

```bash
git add CONTRIBUTING.md
git commit -m "docs: CONTRIBUTING.md に CLAUDE.md 棚卸しシナリオを追加（ADR-0040）"
```

---

### Task 5: 全体検証とサイクル完了処理

**Files:**
- Modify: `docs/records/decisions/0040-claude-md-growth-governance.md`（Status を Accepted へ）
- Modify: `docs/records/decisions/README.md`（0040 の Status 更新）
- Modify: `docs/working/issues/flow/0018-claude-md-norm-growth-monitoring.md`（close）
- Modify: `docs/working/issues/README.md`（Issue-0018 の Status 更新）
- Modify: `docs/working/handoff/feature_claude-md-growth-governance.md`（進捗反映)

- [ ] **Step 1: 全体 read-back 検証**

Run: `pwsh scripts/sync-template.ps1 && git status --short`
Expected: 同期出力＋計測行（`11180 bytes ... 38 bullets ... 警告なし`）。`git status` に template/ の差分が現れない（CLAUDE.md 無変更のため）

Run: `grep -c "ADR-0040" CONTRIBUTING.md scripts/check-claude-md-size.ps1 scripts/sync-template.ps1`
Expected: CONTRIBUTING.md=3（事前判定の導入文・棚卸しの背景・棚卸しチェックリスト）、check-claude-md-size.ps1=2（ヘッダーコメント・閾値コメント）、sync-template.ps1=1（呼び出しコメント）

- [ ] **Step 2: ADR-0040 を Accepted へ昇格する（実装完了チェックポイント。ADR-0019）**

`docs/records/decisions/0040-claude-md-growth-governance.md` の `- **Status**: Proposed` を `- **Status**: Accepted` に変更し、`docs/records/decisions/README.md` の 0040 行の `Proposed` を `Accepted` に変更する。

- [ ] **Step 3: Issue-0018 を close する**

`docs/working/issues/flow/0018-claude-md-norm-growth-monitoring.md` を更新する:
- `- **Status**: open` → `- **Status**: closed`
- `- **Opened**: 2026-07-05` の直後に `- **Closed**: 2026-07-06` を追加
- 「検討状況」に1行追記: `- 2026-07-06: Issue-0018 対策サイクルで対策実装（ADR-0040）。下り方向の配布経路はスコープ外と決定（手動運用継続）`
- 「結論」の `（open）` を以下へ書き換える: `ADR-0040 により対策実装。監視は scripts/check-claude-md-size.ps1（sync-template.ps1 連動、閾値 12,000 バイト / 45 件）、事前判定と棚卸しは CONTRIBUTING.md の手順として定義した。`

`docs/working/issues/README.md` の Issue-0018 行の Status を `closed` に更新する。

- [ ] **Step 4: read-back 検証とコミット**

Run: `grep -n "Status" docs/records/decisions/0040-claude-md-growth-governance.md docs/working/issues/flow/0018-claude-md-norm-growth-monitoring.md`
Expected: 0040 が `Accepted`、0018 が `closed`

```bash
git add docs/records/decisions/0040-claude-md-growth-governance.md docs/records/decisions/README.md docs/working/issues/flow/0018-claude-md-norm-growth-monitoring.md docs/working/issues/README.md
git commit -m "docs: Issue-0018 close と ADR-0040 の Accepted 昇格（対策実装完了）"
```

- [ ] **Step 5: ハンドオフ更新**

`docs/working/handoff/feature_claude-md-growth-governance.md` の完了済みタスク・進行中タスク・Current Phase を実装完了状態へ更新する（session-handoff の update 操作。コミットはセッション終了処理またはマージ前処理に含める）。

---

## 実行後の残作業（plan 対象外、セッションフローで実施）

- master へ `--no-ff` マージ（マージメッセージは `git merge --no-ff -F <file>` で渡す。Issue-0015 回避策）
- マージ直後に `retrospective` スキルを起動（CLAUDE.md「検証」節の規範）
- handoff finalize
