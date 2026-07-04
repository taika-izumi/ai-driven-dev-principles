# retrospective スコープ縮小（課題抽出のみ）実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans または subagent-driven-development でタスク単位に実装する。各ステップは `- [ ]` で追跡する。

**Goal:** retrospective スキルを「課題抽出のみ」に縮小し、課題を system/flow に分類して2フォルダ出力する。Tech Notes のスコープを明確化する。

**Architecture:** retrospective から提案・採否判断・即時ADRドラフト化（Phase 4）を撤去。第5観点を Issues（課題抽出・分類）化。出力は `docs/retrospectives/system/` と `docs/retrospectives/flow/` の2フォルダ（同名 per-cycle ファイル）。波及して decision-log / start-work / CONTRIBUTING / copilot-instructions / README を更新。ADR-0021 を設計記録とし、ADR-0010/0011 を一部改定。

**Tech Stack:** Markdown ドキュメント、PowerShell（sync-template.ps1）、git。

**検証方針:** markdown のためテストは無し。各タスクの検証は (1) 当該ファイルの目視/grep 確認、(2) 整合性確認（撤去した文言の残存が無いこと）、(3) 完了後 `scripts/sync-template.ps1` 実行。

---

### Task 1: ADR-0021 作成（Proposed）

**Files:**
- Create: `docs/decisions/0021-retrospective-issue-extraction-only.md`
- Modify: `docs/decisions/README.md`（表に行追加）

- [ ] **Step 1: ADR-0021 を Proposed で作成**

内容（Context/Decision/Alternatives/Consequences/Related）:
- Status: Proposed（実装完了・検証後に Accepted 昇格）
- Decision の骨子:
  1. retrospective のスコープを「課題抽出と分類」までに限定。提案・採否判断・即時ADRドラフト化（Phase 4）を撤去。
  2. 抽出課題は「バックログ記録」のみ。着手タイミングはユーザー判断（必ず次サイクルではない）。
  3. 課題を「対象システム固有」「開発フロー/ガイドライン関連」に分類。
  4. 出力を2フォルダ化: `docs/retrospectives/system/YYYY-MM-DD-<topic>.md`（メイン）と `docs/retrospectives/flow/YYYY-MM-DD-<topic>.md`（フロー課題）。
  5. Tech Notes はフロー非依存の汎用技術知見に限定。開発対象システムの仕様/ドメイン知識は除外（ADR-0012準拠）。
- Alternatives: 単一蓄積ファイル `flow-feedback.md` 案（ADR-0011の per-cycle 不変モデルと不整合のため却下）、別セクション案（一覧性低のため却下）、提案・採否を残す案（フィードバック(a)に反するため却下）。
- Related: ADR-0010（Phase構造を改定）、ADR-0011（保管パス構造を改定）、ADR-0012（ドメイン知識スコープ外）、ADR-0006、ADR-0019。

- [ ] **Step 2: ADR-0010 / ADR-0011 に改定注記を追記**

両ファイルの Related もしくは Status 行付近に「（ADR-0021 で一部改定: Phase4撤去 / 保管パス2フォルダ化）」の1行を追加。Status は Accepted のまま（全面 Superseded ではない部分改定）。

- [ ] **Step 3: docs/decisions/README.md の表に ADR-0021 行を追加**

- [ ] **Step 4: 検証**

`grep -n "0021" docs/decisions/README.md` で行が存在すること。

---

### Task 2: skills/retrospective/SKILL.md 改修

**Files:**
- Modify: `skills/retrospective/SKILL.md`

- [ ] **Step 1: frontmatter description 更新**

「Improvement Drafts」「採用判断された改善提案は ADR-0006 に従い即時 ADR ドラフト化する」を撤去し、「課題を抽出・分類（system/flow）して記録する。採否判断・対策設計・ADR化は行わず次サイクルへ委ねる」旨へ。

- [ ] **Step 2: 「重要な前提」更新**

「Phase 4 で行う採用判断は ADR起票対象」を撤去。「retrospective は課題抽出までに限定（ADR-0021）。対策の採否・設計・ADR化は次サイクル（着手はユーザー判断）」を追加。出力規約は ADR-0011 + ADR-0021（2フォルダ）に更新。

- [ ] **Step 3: Phase 1 第4観点（Tech Notes）にスコープ注記追加**

含める: ツール挙動・環境の罠・回避策・推奨手順などフロー非依存で古びない汎用技術知見。除外: 開発対象システムの仕様・ドメイン知識（当該システムの仕様書へ。ADR-0012）。

- [ ] **Step 4: Phase 1 第5観点を Improvement Drafts → Issues(課題抽出) に置換**

各課題は `事象 / 原因 / 影響 / 分類（system or flow）` を記録するのみ。対策設計・採用/保留/却下・ADRは行わない。

- [ ] **Step 5: Phase 2（ドラフト保存）を2フォルダ出力へ更新**

`docs/retrospectives/system/YYYY-MM-DD-<topic>.md` にメイン記録。Issues の flow 分類分は `docs/retrospectives/flow/YYYY-MM-DD-<topic>.md` へ書き出し、system 側 Issues には「フロー課題N件は flow/<同名>.md 参照」を残す。flow/ ファイルは flow-template.md 準拠。両フォルダ・両ファイルはオンデマンド作成。

- [ ] **Step 6: Phase 4（採用判断の即時 ADR 化）を削除し、後続 Phase を繰り上げ**

旧 Phase 3 rubber-duck の観点から「改善提案の採用判断の妥当性」を「課題抽出の網羅性・分類（system/flow）の妥当性」へ差し替え。

- [ ] **Step 7: Phase 5（ハンドオフ更新）をバックログ記述へ更新**

「起票した ADR を実装する」を撤去。「抽出課題はバックログとして記録済み。着手はユーザー判断（必ず次サイクルではない）」を handoff に残す旨へ。status 遷移文言調整。

- [ ] **Step 8: 「出力ファイル」「対応する原則」「関連」節を更新**

出力ファイルパスを system/ + flow/ へ。原則2の記述を「振り返り=課題の抽出と分類のみ／対策決定=次サイクル」へ。関連に ADR-0021 追加。

- [ ] **Step 9: 検証**

`grep -niE "改善提案|採用判断|Improvement Draft|即時 ADR|Phase 4" skills/retrospective/SKILL.md` が撤去対象の残存を返さないこと（関連節での参照を除く）。

---

### Task 3: skills/retrospective/template.md 改修 + flow-template.md 新規

**Files:**
- Modify: `skills/retrospective/template.md`
- Create: `skills/retrospective/flow-template.md`

- [ ] **Step 1: template.md §4 Tech Notes にスコープ注記追加**（含める/除外）

- [ ] **Step 2: template.md §5 Improvement Drafts → Issues（課題抽出）へ置換**

各課題 `事象 / 原因 / 影響 / 分類（system|flow）`。採否・対策・ADR欄を削除。flow 分類分は flow/ ファイルへ転記する旨の注記。

- [ ] **Step 3: template.md §7 Handoff Forward を更新**

「Phase 4 で起票した ADR の実装タスク」を撤去。「課題バックログ（着手はユーザー判断）」「次サブプロジェクト候補」へ。

- [ ] **Step 4: flow-template.md 新規作成**

flow/ ファイル用テンプレート。ヘッダ（Subject/Period/対応 system retro へのリンク）＋ フロー課題リスト（`課題 / なぜフロー課題か / 事象・原因・影響 / 発生サイクル`）。

- [ ] **Step 5: 検証**

両ファイルに採否/ADR欄が残っていないことを目視確認。

---

### Task 4: docs/retrospectives/README.md 改修（template対象）

**Files:**
- Modify: `docs/retrospectives/README.md`

- [ ] **Step 1: 運用規約を2フォルダ構成へ更新**

配置を `docs/retrospectives/system/YYYY-MM-DD-<topic>.md`（メイン）と `docs/retrospectives/flow/YYYY-MM-DD-<topic>.md`（フロー課題）に。ADR-0011 + ADR-0021 を参照。per-cycle・上書き禁止は維持。

- [ ] **Step 2: 一覧表を2フォルダ前提に更新**

既存2行（2026-05-01 C / 2026-05-05 plugin）は履歴として保持（ADR-0011 行追加のみ規約）。リンクパスは現状維持（過去ファイルは旧フラット配置のため、注記で「旧配置」と明記）。

- [ ] **Step 3: 関連に ADR-0021 追加**

- [ ] **Step 4: 検証**: `grep -n "system/\|flow/" docs/retrospectives/README.md` でパス更新を確認。

---

### Task 5: skills/decision-log/SKILL.md 改修

**Files:**
- Modify: `skills/decision-log/SKILL.md`

- [ ] **Step 1: 強トリガー #7（振り返りで採用された改善提案）を削除**

番号繰り上げまたは削除。retrospective は採用判断をしないため。

- [ ] **Step 2: 昇格チェックポイント表の「retrospective で採用した改善提案」行を削除**

- [ ] **Step 3: 検証**: `grep -niE "retrospective|採用された改善提案" skills/decision-log/SKILL.md` が撤去対象を返さないこと。

---

### Task 6: skills/start-work/SKILL.md 改修

**Files:**
- Modify: `skills/start-work/SKILL.md`

- [ ] **Step 1: セッション終了処理のパス参照を更新**

`docs/retrospectives/` 存在チェックを `docs/retrospectives/system/` に該当ファイルが無ければ、へ更新。

- [ ] **Step 2: Phase 2 マッピング/終了処理に retrospective の採用提案ADR文言があれば撤去**

`grep -niE "採用|ADR ドラフト" 周辺確認。retrospective 行の説明を「課題抽出」基準へ。

- [ ] **Step 3: 検証**: `grep -n "retrospectives" skills/start-work/SKILL.md` でパス更新確認。

---

### Task 7: CONTRIBUTING.md 改修

**Files:**
- Modify: `CONTRIBUTING.md`

- [ ] **Step 1: 「retrospectiveを変更するとき」シナリオの背景・チェックリスト更新**

7セクション記述を新構成（Issues化・採用判断撤去）へ。チェックリストの「採用判断と実装着手の分離原則（採用時に ADR ドラフト起票）」項目を撤去し、「課題抽出のみ・採否/ADRは次サイクル」「system/flow 2フォルダ出力」項目へ差し替え。

- [ ] **Step 2: 「振り返りで採用された改善提案を取り込みたいとき」シナリオを改訂**

タイトル/内容を「振り返りで抽出された課題に対策するとき」へ。手順: system/ + flow/ の Issues を読む → ユーザーが対策要と判断した課題を起点に → start-work → （規模に応じ brainstorming）→ 対策決定で ADR 起票（Proposed→実装後Accepted）。retrospective ファイルは追記型のため書き換えない（ADR-0011）。

- [ ] **Step 3: 検証**: `grep -niE "採用された改善提案|ADR ドラフト起票" CONTRIBUTING.md` が retrospective 文脈で残らないこと。

---

### Task 8: README.md 改修

**Files:**
- Modify: `README.md`

- [ ] **Step 1: retrospective 行の説明文更新**

「Improvement Drafts を抽出し、採用提案を ADR ドラフト化する」→「課題を抽出・分類（system/flow）して記録する（採否・対策・ADRは次サイクル）」。

- [ ] **Step 2: 検証**: 当該行を目視確認。

---

### Task 9: .github/copilot-instructions.md 改修（template対象）

**Files:**
- Modify: `.github/copilot-instructions.md`

- [ ] **Step 1: 検証セクションの retrospective 記述を更新**

L86「採用された改善提案は ADR ドラフトに転写し、実装は次サイクルで start-work から開始する」→「課題を抽出・分類して記録する。対策の採否・設計・ADR化は行わず、ユーザーが対策要と判断した時点で次サイクルで着手する」。パス記述を system/ へ。

- [ ] **Step 2: 検証**: `grep -n "retrospective" .github/copilot-instructions.md` で更新確認。

---

### Task 10: テンプレート同期 + 全体検証 + ADR昇格

- [ ] **Step 1: sync-template.ps1 実行**

`pwsh scripts/sync-template.ps1`（または該当パス）。template対象（copilot-instructions.md, retrospectives/README.md）が同期されること。

- [ ] **Step 2: 全体整合 grep**

撤去対象文言（「採用判断」「Improvement Draft」「即時 ADR ドラフト化」など）が retrospective 文脈で残っていないか横断確認。

- [ ] **Step 3: git diff レビュー** で全変更を確認。

- [ ] **Step 4: ADR-0021 を Accepted へ昇格**（実装完了・検証後、ADR-0019準拠）。docs/decisions/README.md の Status も更新。

- [ ] **Step 5: コミット**

```
git add -A
git commit -m "feat: narrow retrospective to issue-extraction only; system/flow split (ADR-0021)"
```

---

## Self-Review チェック

- Spec coverage: フィードバック(a)=Task2/3/4/5/7/8/9、(b)=Task2/3、(c)=Task2/3/4。全カバー。
- Placeholder: 各タスクに具体的変更箇所を明記済み。
- 整合: ADR-0021 を全関連ファイルが参照。撤去対象文言の grep 検証を各タスクに配置。
