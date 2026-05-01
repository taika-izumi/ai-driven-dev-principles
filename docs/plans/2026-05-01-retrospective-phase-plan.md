# 振り返りフェーズ導入 実装計画（サブプロジェクトC）

> **For agentic workers:** 本 plan は **メインセッション直接実行** を想定。タスクを上から順に処理し、各タスク完了時に SQL todos のステータスを更新する。subagent-driven-development は適用しない（仕様書 §6.3）。

**Goal:** 開発サイクル末尾の振り返りフェーズを `retrospective` スキルとして導入し、ガイドライン・フロー改善案と古びない技術ノウハウを構造化記録する仕組みを確立する。

**Architecture:** 単一責務の独立スキル + 時系列追記型の保管ファイル。`start-work` Phase 2 ナビ表に統合。Phase 3 で rubber-duck サブエージェントを1回挟み独立視点レビューを得る。本サブプロジェクトC自身に対する初回 retrospective を最終タスクで実施し、ドメイン知識抽出スキルを次サイクル提案議題化する。

**Tech Stack:** Markdown / PowerShell 7 (sync-template) / Git / 本リポジトリ独自スキル基盤

**Spec:** `docs/specs/2026-05-01-retrospective-design.md`

**Branch:** `feature/retrospective-phase`

---

## Task 1: ADR-0010 Proposed 起票

**Files:**
- Create: `docs/decisions/0010-introduce-retrospective-phase.md`
- Modify: `docs/decisions/README.md`（新規行追加）

**内容**:
- Status: Proposed
- 構成: Context / Decision / Consequences / Alternatives Considered（既存 ADR と同一フォーマット）
- 主決定: `retrospective` スキルを新設し、サブプロジェクトクローズ時の標準ステップとする
- 代替案: start-work 内蔵自動トリガー、finishing-a-development-branch 拡張

**完了基準**: ADR インデックスから新規行が辿れる。`git status` クリーン後コミット。

**コミットメッセージ案**:
```
adr: propose 0010 introduce retrospective phase
```

---

## Task 2: ADR-0011 Proposed 起票

**Files:**
- Create: `docs/decisions/0011-retrospective-storage-policy.md`
- Modify: `docs/decisions/README.md`

**内容**:
- 主決定: `docs/retrospectives/YYYY-MM-DD-<topic>.md` 単一ファイル / サブプロジェクト、追記型（typo修正以外の上書き禁止）
- ADR-0008（spec スナップショット規約）との差別化を明記
- README インデックスは行追加のみ・過去行編集禁止

**完了基準**: ADR インデックスから新規行が辿れる。

**コミットメッセージ案**:
```
adr: propose 0011 retrospective storage policy
```

---

## Task 3: ADR-0012 Proposed 起票

**Files:**
- Create: `docs/decisions/0012-domain-knowledge-out-of-scope-for-c.md`
- Modify: `docs/decisions/README.md`

**内容**:
- 主決定: ドメイン知識抽出は本サブプロジェクトC のスコープ外。初回 retrospective の Improvement Drafts で正式提案議題化
- 代替案: α(retrospective テンプレ1セクション追加) / β(同時設計) / γ(現スコープ維持＝採用)
- 採用理由: 原則2、ドッグフーディング素材化

**完了基準**: ADR インデックスから新規行が辿れる。

**コミットメッセージ案**:
```
adr: propose 0012 domain knowledge extraction deferred
```

---

## Task 4: retrospective スキル本体作成

**Files:**
- Create: `skills/retrospective/SKILL.md`

**内容（節構成）**:
1. メタ frontmatter（name / description）
2. 「いつ使うか」: feature ブランチ master merge 直後、handoff finalize 前
3. 前提: ADR-0006 即時検出ルールが本スキル中も適用されること
4. Phase 0〜5 の手順（仕様書 §3 に対応）
5. 出力テンプレ参照: `skills/retrospective/template.md`
6. サブエージェント呼び出し方: rubber-duck を1回、ドラフト全文 + plan + 関連 ADR を渡す
7. コミット方針: スキル内ではコミットしない
8. 対応する原則（仕様書 §7 と整合）

**完了基準**: 仕様書 §3 の Phase 0〜5 が全て対応する節を持つ。

**コミットメッセージ案**:
```
feat: add retrospective skill
```

---

## Task 5: retrospective テンプレート作成

**Files:**
- Create: `skills/retrospective/template.md`

**内容**: 仕様書 §4.2 の Markdown 構造をそのまま記述。プレースホルダーは `<...>` 形式。

**完了基準**: 7 セクション（Done / Went Well / Struggled / Tech Notes / Improvement Drafts / Independent Review Notes / Handoff Forward）+ メタヘッダ完備。

**コミットメッセージ案**:
```
feat: add retrospective output template
```

---

## Task 6: docs/retrospectives/ ディレクトリ初期化

**Files:**
- Create: `docs/retrospectives/.gitkeep`
- Create: `docs/retrospectives/README.md`

**内容（README.md）**:
- ディレクトリの目的（仕様書 §4 引用）
- 命名規則
- インデックステーブル（カラム: Date / Subject / Branch / Plan / Spec / Reviewer / 備考）。初期は空テーブル。
- 「行追加のみ・過去行編集禁止」のルール明記

**完了基準**: ディレクトリが git に乗る、README が ADR README と同じ運用方針を持つ。

**コミットメッセージ案**:
```
docs: initialize retrospectives directory and index
```

---

## Task 7: principles.md 原則5 拡張

**Files:**
- Modify: `docs/principles.md`（原則5 セクション末尾）

**内容**: 「サイクル単位の振り返りで検証結果をメタ・ガイドラインへ反映する」一文を追加。既存記述は触らない。

**完了基準**: diff が「原則5に1〜2行追加」のみ。

**コミットメッセージ案**:
```
docs(principles): extend principle 5 with cycle-end retrospective
```

---

## Task 8: copilot-instructions.md に振り返り運用追加

**Files:**
- Modify: `.github/copilot-instructions.md`

**内容**: 「ドキュメント運用」セクション内に「振り返り運用」項を新設。次の点を含める:
- サブプロジェクトクローズ時に `retrospective` スキルを実行する
- 出力は `docs/retrospectives/` 配下に時系列で保管（追記型）
- 振り返り中の採用判断は ADR-0006 に従い即時 ADR 化

**完了基準**: 既存セクション構造を壊さず追記。

**コミットメッセージ案**:
```
docs(instructions): add retrospective operations section
```

---

## Task 9: start-work スキルに retrospective を統合

**Files:**
- Modify: `skills/start-work/SKILL.md`

**内容**:
1. Phase 2 マッピング表に1行追加:
   `| サブプロジェクトのfeatureブランチをmasterにmerge直後 | retrospective | （本リポジトリ固有スキル、フォールバック不要） |`
2. 「セッション終了処理」直前のチェックに「対象サブプロジェクトの retrospective が完了しているか確認。未完なら retrospective を先に走らせる」を追加

**完了基準**: ナビゲーション表にretrospective行があり、終了処理がretrospective完了をチェックする。

**コミットメッセージ案**:
```
docs(start-work): map retrospective skill at sub-project closure
```

---

## Task 10: decision-log スキルに振り返り検出トリガー追記

**Files:**
- Modify: `skills/decision-log/SKILL.md`

**内容**: 検出トリガー一覧に「振り返り中の改善提案を採用と判断した時」を追加。重複検出を許容する旨も明記。

**完了基準**: 既存トリガーリストに1項目追加されている。

**コミットメッセージ案**:
```
docs(decision-log): add retrospective adoption as trigger
```

---

## Task 11: template.manifest 同期

**Files:**
- Modify: `template.manifest`
- Run: `pwsh scripts/sync-template.ps1`

**内容**:
- manifest に追加するパス: `skills/retrospective/SKILL.md`, `skills/retrospective/template.md`, `docs/retrospectives/.gitkeep`, `docs/retrospectives/README.md`, ADR-0010/0011/0012, 各既存ファイル更新分（既に manifest 上ある可能性あり、確認）
- スクリプト実行後、再実行で差分ゼロを確認

**完了基準**: `pwsh scripts/sync-template.ps1` を2回連続実行して2回目で `git status` がクリーン。

**コミットメッセージ案**:
```
chore: sync template with retrospective skill
```

---

## Task 12: README.md 更新

**Files:**
- Modify: `README.md`

**内容**:
- スキル一覧表に `retrospective` 行追加（カラム: スキル名 / 概要 / トリガー）
- docs ディレクトリ案内に `retrospectives/` 追加

**完了基準**: スキル表とディレクトリ案内の両方に retrospective が現れる。

**コミットメッセージ案**:
```
docs: list retrospective skill in README
```

---

## Task 13: CONTRIBUTING.md にシナリオ追加

**Files:**
- Modify: `CONTRIBUTING.md`

**内容**: 「振り返り提案を後から取り込みたい時」のシナリオを既存シナリオ末尾に追記。手順:
1. `docs/retrospectives/` の該当ファイルから採用提案を確認
2. `start-work` を起動して新規サブプロジェクトとして扱う
3. brainstorming → spec → plan の順で着手

**注意**: PowerShell here-string で `` `feature `` のような escape 衝突は Python `_append.py` 経由 or シングルクォート here-string で回避（過去の罠、Tech Notes 候補）。

**完了基準**: シナリオ節に新規項目が追加されている。

**コミットメッセージ案**:
```
docs(contributing): add scenario for retrospective adoption
```

---

## Task 14: ADR-0010 / 0011 / 0012 を Accepted 化

**Files:**
- Modify: `docs/decisions/0010-introduce-retrospective-phase.md` (Status 行)
- Modify: `docs/decisions/0011-retrospective-storage-policy.md` (Status 行)
- Modify: `docs/decisions/0012-domain-knowledge-out-of-scope-for-c.md` (Status 行)
- Modify: `docs/decisions/README.md`（Status 列の更新）
- Run: `pwsh scripts/sync-template.ps1`（template 内 ADR README が空版である運用前提のため、本体 ADR を編集してもテンプレ側に影響しないことを確認）

**内容**: 3 ADR の Status を Proposed → Accepted へ変更。日付は 2026-05-01。

**完了基準**: `git --no-pager diff` で Status 行のみ変更されていることを確認。

**コミットメッセージ案**:
```
adr: accept 0010, 0011, 0012
```

---

## Task 15: handoff 書き換え

**Files:**
- Overwrite: `docs/handoff/master.md`（ADR-0008 スナップショット規約に従い差分追記禁止、全文書き換え）

**内容**:
- Status: paused → completed-cycle-c
- Current Phase: サブプロジェクトA完了 / B完了 / C完了 / D未着手
- 完了済みタスクに C を追加
- 「次セッション開始時のアクション」: 初回 retrospective を本サブプロジェクトCに対して実行 → 採用提案を ADR/スキル化 → サブプロジェクトD（最有力: ドメイン知識抽出）へ
- 重要な意思決定の履歴に ADR-0010/0011/0012 を追加

**注意**: `master.md.new` を一時ファイルとして書き出してから `Move-Item -Force` で置換する（過去事例での安全策）。

**完了基準**: 旧内容が完全に置き換わっている。差分追記の痕跡がない。

**コミットメッセージ案**:
```
chore: update handoff for sub-project C completion
```

---

## Task 16: master へ merge & push

**Files:** （ファイル変更なし、git 操作のみ）

**手順**:
1. `git checkout master`
2. `git pull --ff-only`
3. `git merge --no-ff feature/retrospective-phase -m "Merge branch 'feature/retrospective-phase'"`
4. `git push origin master`

**完了基準**: `git --no-pager log --oneline -3` で merge コミットが master 先頭に乗っている。push 成功。

**注意**: master 直接編集は禁止。merge コミット以外の追加変更はしない。

---

## Task 17: 初回 retrospective を本サブプロジェクトC自身に対して実行

**Files:**
- Create: `docs/retrospectives/2026-05-01-retrospective-phase.md`
- Modify: `docs/retrospectives/README.md`（インデックス行追加）

**手順**: `retrospective` スキル（Task 4 で作成）を起動し、対象を「サブプロジェクトC（feature/retrospective-phase）」として Phase 0〜5 を完走する。

**特記**:
- Phase 1 の「Improvement Drafts」で **「ドメイン知識抽出スキル knowledge-distillation の新設」を最重要提案として記録**（採用判断 = 採用、ADR起票は次セッション）
- Phase 4 で採用提案分の ADR ドラフトを作成（ADR-0013 候補）
- Phase 5 で handoff 更新（次セッションは knowledge-distillation スキルの brainstorming から開始）

**完了基準**:
- retrospective ファイル存在
- インデックス更新
- handoff の「次セッション開始時のアクション」に「knowledge-distillation の brainstorming」が記録
- ADR-0013 ドラフト存在（Proposed のまま、実装は次サイクル）

**コミットメッセージ案**: 振り返り完了後に ADR ドラフトと共に
```
docs: first retrospective for sub-project C with domain-knowledge proposal
```

そして再度 master へ merge & push（Task 16 と同じ手順、コミット数行のみ）。

---

## Self-Review

- **Spec coverage**: spec §1〜§7 全てに対応タスクあり（§1 → Task 1-3, §2 → Task 4-11, §3 → Task 4, §4 → Task 5-6, §5.1 → Task 1-3+14, §5.2 → Task 7-13+15, §6 → 本plan全体, §7 → Task 7）。OK。
- **Placeholder scan**: `<...>` は意図的なテンプレ形式。TODO/TBD なし。OK。
- **Type consistency**: スキル名 `retrospective`、ファイルパス `docs/retrospectives/`、ADR 番号 0010/0011/0012、初回 retrospective ファイル名 `2026-05-01-retrospective-phase.md` で全タスク統一。OK。

## 進行モード

- **メインセッション直接実行**（仕様書 §6.3）
- 各タスク完了後に SQL todos を `done` に更新
- Task 16（master merge）の前にユーザー確認必須
- Task 17 はスキルそのものの初回運用。質問は通常のスキル進行に従う

## Out of Scope（再掲）

- ドメイン知識抽出スキル `knowledge-distillation` の設計・実装（サブプロジェクトD）
- 振り返り採用提案の自動 ADR/スキル化
- 自動トリガー（merge検知など）
- メトリクス計測
