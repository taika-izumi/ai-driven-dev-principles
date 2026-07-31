# retrospective スキル再定義（課題抽出記録への純化）実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ADR-0056 / 仕様書 `docs/current/specs/2026-05-01-retrospective-design.md` に従い、retrospective スキルを「サイクル末尾の課題抽出記録」へ書き換え、波及ドキュメントと issue 状態を整合させる。

**Architecture:** ドキュメントのみの変更（コードなし・自動テストなし）。検証は grep / Read による実体確認（ADR-0038）。スキル本体 → テンプレート → インデックス → 周辺ドキュメント → issue 状態 → 横断検証・ADR 昇格の順に、意味単位でコミットする。

**Tech Stack:** Markdown / PowerShell（`scripts/sync-template.ps1`）/ git

**前提:**

- ブランチ `feature/retrospective-mode-review` 上で作業する（作成済み）
- ADR-0056 は Proposed でコミット済み（`c8661dd`）。本計画の最終タスクで Accepted へ昇格する
- 過去の retrospective 記録ファイル（`docs/records/retrospectives/system|flow/*.md`）と retrospectives README の既存一覧行は**一切改変しない**（ADR-0011）

---

### Task 1: `skills/retrospective/SKILL.md` 全面書き換え

**Files:**
- Modify: `skills/retrospective/SKILL.md`（全置換）

- [ ] **Step 1: SKILL.md を以下の内容で全置換する**

````markdown
---
name: retrospective
description: "サブプロジェクト1サイクル完了直後（feature ブランチを master へマージ後、handoff finalize 前）に実施する、サイクル末尾の課題抽出記録スキル。AI が plan / git log / handoff から課題候補（事象/原因/影響、system/flow 分類つき）を一括提示し、ユーザーが修正と起票判断を行う。フロー課題は delta 型（worklog で捕捉可能）か構造観察型かを振り分け、delta 型で急がないものは worklog パイプラインへ委ねる（ADR-0056）。抽出課題は docs/working/issues/system|flow/ へ起票し（ADR-0028）、対策の採否・設計・ADR化は次サイクルへ委ねる（ADR-0021）。rubber-duck 独立レビューはユーザー要求時のみのオプション。"
---

# retrospective

サイクル末尾に「課題抽出記録（issue 詳細の正本）」を作成するスキル。残す情報は次の2つに限定する（ADR-0056）:

1. **課題の詳細記録**（事象 / 原因 / 影響、system / flow 分類）— issue が「要約＋ライフサイクル管理」、本記録が「詳細の正」（ADR-0028）
2. **最小のサイクル文脈**（対象・期間・merge コミット・関連 plan / ADR へのポインタ）— 課題詳細を将来単独で読むためのヘッダ

旧5観点のうち Went Well / Tech Notes は観点として廃止した。スキル化に有用な知見（躓き・人間の指示＝ delta）は worklog パイプライン（worklog-record → worklog-extract → worklog-skillify）が捕捉・再利用する（ADR-0056）。

## いつ使うか

サブプロジェクトの feature ブランチを master へ `--no-ff` マージし、対応 handoff を completed 状態へ遷移させる**直前**。`start-work` Phase 2 マッピング表の「サブプロジェクト完了直後の振り返り」行から推奨される。

実行は **手動トリガー**のみ。merge 検知などの自動起動は導入していない（ADR-0010）。形式は単一で、開始時の形式選択（完全版 / 簡易版）は設けない（ADR-0056）。

## スコープ（ADR-0021 を維持）

retrospective は **「課題の抽出と分類」までに限定**する。対策の設計・採否判断（採用/保留/却下）・即時 ADR ドラフト化は**行わない**。それらは次の作業サイクルの責務。

抽出した課題は**バックログとして記録・起票するのみ**。着手の要否・時期はユーザーの判断に委ねる。ユーザーが対策を要すると判断した時点で、その課題を起点に通常フロー（`start-work` →（規模に応じ brainstorming）→ 対策決定で ADR 起票）を開始する。

課題の issue 起票（Phase 2）は**記録行為であり、対策の設計・採否判断ではない**（ADR-0028）。

## worklog パイプラインとの棲み分け（ADR-0056）

`docs/working/issues/README.md` を唯一のバックログとして、2つの起票経路が合流する:

- **retrospective 由来**: そのサイクルで観測された未解決の問題（バグ、設計負債、未定義の規約、プロセスの欠落）。証拠はサイクルの成果物。1回の観測でも起票できる
- **worklog-extract 由来**: 横断走査で再発が裏付けられた「AI デフォルト挙動との差分」のスキル化・ルール化候補。証拠は中央ストアの根拠エントリ

### フロー課題の振り分け規則

フロー課題候補ごとに「作業時点の delta（躓き・人間の指示）として worklog に記録済み／記録可能か」を判定する:

- **delta 型 かつ 急がない** → issue は起票しない。worklog 記録の有無を確認し、未記録なら Phase 3 の worklog 総ざらいで記録する。仕組み化の要否は worklog-extract の再発裏付けに委ねる
- **delta 型 だが ユーザーが早期対処を要すると判断** → 即起票する（後日 worklog-extract が同クラスタを検出したら既存 issue へ統合される。worklog-extract 手順8）
- **構造観察型**（delta として表現できない。例:「記録に読み手がいない」等、体系の俯瞰で初めて見える欠落）→ issue 経路で扱う。発見の主経路はサイクル中の随時起票（decision-log の未決事項起票・気づきの即時起票）であり、retrospective は起票漏れの最終チェックポイントにとどまる

対象システム固有の課題は無条件で retrospective が起票する（worklog-extract はスキル化候補のみを扱う）。

### 重複防止（両方向）

- retrospective 側: 起票前に既存 open 課題（worklog-extract 由来を含む）と突合し、既存があれば「検討状況」へ追記する（ADR-0031）
- worklog-extract 側: Issue 草案化時に retrospective 由来のバックログと重複排除する（worklog-extract 手順8。唯一の合流点）

## 重要な前提

- ADR-0006（意思決定の継続検出ルール）は本スキル中も常時適用される。ただし retrospective 内では対策の採否を決めないため、retrospective 起因の ADR 起票は発生しない
- 出力ファイルは ADR-0011（時系列追記型）に従い、一度書いたら原則上書き禁止（typo 修正のみ例外）
- スキル内ではコミットしない。コミットはユーザーまたは通常フローに委ねる

## 手順

### Phase 0: 前提収集（メイン実行）

1. 対象サブプロジェクト名・feature ブランチ名・対応 plan/spec パスをユーザーから受け取る。直近 merge コミットから推定する場合は必ずユーザー確認を取る
2. 以下を読み込む:
   - 対応 plan ファイル（`docs/working/plans/...`）
   - 対応 spec ディレクトリ or ファイル（`docs/current/specs/...`）
   - 該当ブランチの merge コミット範囲の `git log --oneline`
   - `docs/working/handoff/master.md` 現行版
   - 該当期間に追加・変更された ADR
3. 既存 `docs/records/retrospectives/` に同一トピックの既存ファイルが無いことを確認する。あれば中止し、扱いをユーザーに確認する

### Phase 1: 課題案の一括提示（メイン実行）

1. Phase 0 の材料から課題候補を**一括提示**する。各候補に添えるもの:
   - 事象 / 原因 / 影響
   - system / flow 分類
   - flow 候補には delta 型 / 構造観察型の判定・worklog 記録状況・起票要否の提案（振り分け規則）
   - 既存 open 課題の再発・進展は新規候補とせず「検討状況」追記対象として提示（ADR-0031）
2. ユーザーが修正・追加・削除と起票判断を行う
3. 末尾に確認1問:「このサイクル中に言語化されたが未起票の気づき（会話中の指摘・見送った論点など）はありませんか？」（体系全体を走査する構造チェック工程は設けない）

### Phase 2: 記録保存と起票（メイン実行）

1. `docs/records/retrospectives/system/YYYY-MM-DD-<topic>.md`（メイン記録。テンプレートは `skills/retrospective/template.md`）と、起票したフロー課題があれば `flow/YYYY-MM-DD-<topic>.md`（`skills/retrospective/flow-template.md`）を書き出す（ADR-0021。両フォルダで同名。フォルダ・ファイルはオンデマンド作成）
2. 起票対象の課題を**全件** `docs/working/issues/` へ起票する（ADR-0028）:
   1. インデックス `docs/working/issues/README.md` 全体（両セクション）の最大番号+1 で採番する
   2. `docs/working/issues/system|flow/NNNN-<slug>.md` を起票する（Status: open。課題内容は要約のみとし、「起票元」に `retrospectives/system|flow/YYYY-MM-DD-<topic>.md 課題#N` を記載）
   3. インデックスの対応セクションに1行追加する
   4. 振り返りファイル側の各課題項目に「**起票**: Issue-NNNN」行を記載する
3. 既存 open 課題の再発・進展の「検討状況」追記（`YYYY-MM-DD: 事象の要約`）を実施する（ADR-0031）
4. **`docs/records/retrospectives/README.md` の一覧へ行追加する（省略不可）**
5. ユーザーへ提示し確認を得る

### Phase 3: 仕上げ（メイン実行）

1. **（オプション）rubber-duck 独立レビュー**: ユーザーが求めた場合のみ、サブエージェント `rubber-duck` を1回呼び出す。プロンプトに含めるもの:
   - ドラフト全文（system/ と flow/ の両方）と対応 plan の内容・ADR 一覧
   - 「独立視点レビューであり、再生成や書き換えではない」旨
   - レビュー観点は「課題の抽出漏れがないか・system / flow 分類が妥当か」の2点に限定
   - 出力フォーマット指定（短い指摘のリスト形式、優先度タグ付き）

   結果はメインが受け取り、ユーザーと相談の上で反映する。やり取りは記録ファイルの「Independent Review Notes」節（実施時のみ追加）に記録する
2. **worklog 総ざらい確認**: サイクル全体を俯瞰し、未記録の delta（躓き・人間の指示）に気づいたら `worklog-record` を呼んで記録する。振り分け規則で「worklog 送り」とした delta 型候補の記録漏れもここで拾う
3. `session-handoff` の **update** 操作を呼ぶ:
   - 「次セッション開始時のアクション」に「抽出した課題は issues に起票済み（Issue-NNNN〜。着手はユーザー判断）」旨を記す
   - handoff Status を `completed` → `ready-for-next-cycle` へ遷移
   - 課題が複数ある場合は優先順位の目安を併記してよい（着手の決定はユーザー）

## 出力ファイル

- メイン記録: `docs/records/retrospectives/system/YYYY-MM-DD-<topic>.md`
- フロー課題記録: `docs/records/retrospectives/flow/YYYY-MM-DD-<topic>.md`（起票したフロー課題がある場合のみ）
- 課題起票: `docs/working/issues/system|flow/NNNN-<slug>.md` + `docs/working/issues/README.md` への行追加
- インデックス更新: `docs/records/retrospectives/README.md` に行追加（過去行の編集は禁止、ADR-0011）
- テンプレ参照: `skills/retrospective/template.md`（メイン）/ `skills/retrospective/flow-template.md`（フロー）

## 対応する原則

- **原則1（追跡可能性）**: 課題の事象・原因・影響がサイクル単位で永続化され、issue の正本として参照される
- **原則2（関心の分離）**: 課題抽出（retrospective）と知見の再利用（worklog パイプライン）を消費経路で分離。対策の決定・実装は次サイクル
- **原則3（コンテキスト管理）**: 最小サイクル文脈により課題詳細が単独で理解可能。重複記録の排除でトークン消費を抑制
- **原則4（人間の関与）**: 起票判断・早期対処判断・rubber-duck 実施判断はユーザー / 自動トリガー禁止
- **原則5（漸進的検証）**: サイクル単位の課題抽出でメタ・ガイドライン自体の検証ループを回す

## 関連

- ADR-0056: 課題抽出記録への純化・worklog 委譲・振り分け規則・単一形式・rubber-duck オプション化
- ADR-0031: 既存 open 課題の再発・進展は issue の「検討状況」へ一次記録
- ADR-0028: 振り返り課題の全件起票と issues の system/flow フォルダ分割
- ADR-0021: retrospective を課題抽出に限定し、出力を system/flow に分割
- ADR-0010: 振り返りフェーズ導入 / ADR-0011: 保管規約（時系列追記型）
- 関連スキル: start-work, decision-log, session-handoff, worklog-record, worklog-extract
````

- [ ] **Step 2: 実体確認**

Run: `grep -n "Went Well\|Tech Notes\|5観点\|1問ずつ" skills/retrospective/SKILL.md`
Expected: ヒットは「旧5観点のうち Went Well / Tech Notes は観点として廃止した」の宣言行（1行）のみ。手順・観点定義としての出現が 0 件であること

Run: `grep -c "Phase" skills/retrospective/SKILL.md`
Expected: Phase 0〜3 の見出しを含む（Phase 4 見出しが存在しない）

- [ ] **Step 3: コミット**

```bash
git add skills/retrospective/SKILL.md
git commit -m "retrospective: SKILL.md を課題抽出記録スキルへ全面改訂（ADR-0056）"
```

---

### Task 2: テンプレート2種の改訂

**Files:**
- Modify: `skills/retrospective/template.md`（全置換）
- Modify: `skills/retrospective/flow-template.md`（ヘッダ追記）

- [ ] **Step 1: `template.md` を以下の内容で全置換する**

````markdown
# Retrospective: <サブプロジェクト名>

- **Subject**: <サブプロジェクトの正式名>
- **Branch**: feature/<name>（merge済み: <merge-commit-sha>）
- **Period**: <開始日> 〜 <完了日>
- **Plan**: docs/working/plans/<...>
- **Spec**: docs/current/specs/<...>
- **Related ADRs**: ADR-NNNN, ADR-NNNN
- **Facilitator**: メインエージェント (<モデル名>)

## 1. 達成サマリ

<plan の主要マイルストーンを3〜5行の箇条書きで。課題詳細を将来単独で読むための最小のサイクル文脈（対応コミット SHA を併記）>

## 2. 課題（対象システム固有）

課題の抽出と分類まで（対策の設計・採否判断・ADR化は次サイクル。ADR-0021）。このファイルには**対象システム固有**の課題のみを記載し、開発フロー/ガイドライン課題は `flow/<同名>.md` に記載してここにはポインタを残す。

- **課題 #N**: <一文タイトル>
  - **事象**: <何が起きたか>
  - **原因**: <分析>
  - **影響**: <時間損失・スコープ影響など>
  - **起票**: Issue-NNNN（`../../working/issues/system/NNNN-<slug>.md`）

> 開発フロー課題 N 件は `flow/<同名>.md` 参照。worklog 送りとした delta 型候補 N 件（起票なし。ADR-0056 の振り分け規則）。

## 3. 既存課題の再発・進展

- Issue-NNNN: <「検討状況」へ追記した内容の要約>（ADR-0031）

## 4. (任意) Independent Review Notes

rubber-duck レビューをユーザー要求で実施した場合のみ本セクションを追加する。

- **指摘 #N**（優先度: high / medium / low）: <指摘内容>
  - **メインの応答**: 採用 / 部分採用 / 反論
  - **反映先**: <更新したセクション / 起票した Issue>
````

- [ ] **Step 2: `flow-template.md` のヘッダに振り分け判定行を追記する**

以下の Edit を行う（既存行はそのまま）:

旧:
```markdown
- **対応する system 振り返り**: [system/<同名>.md](../system/<同名>.md)
- **Facilitator**: メインエージェント (<モデル名>)
```

新:
```markdown
- **対応する system 振り返り**: [system/<同名>.md](../system/<同名>.md)
- **Facilitator**: メインエージェント (<モデル名>)

> 起票する各フロー課題には振り分け判定（delta 型・早期対処 / 構造観察型。ADR-0056）を1行記載する。delta 型で急がない候補は起票せず worklog へ記録する（本ファイルには載せない）。
```

あわせて各課題項目のフィールドに判定行を追加する:

旧:
```markdown
  - **なぜフロー課題か**: <対象システム固有でなく、開発の進め方・スキル・原則・ガイドラインの問題である理由>
```

新:
```markdown
  - **なぜフロー課題か**: <対象システム固有でなく、開発の進め方・スキル・原則・ガイドラインの問題である理由>
  - **振り分け判定**: <delta 型（早期対処のため起票） / 構造観察型>（ADR-0056）
```

- [ ] **Step 3: 実体確認**

Run: `grep -n "Went Well\|Tech Notes\|Handoff Forward" skills/retrospective/template.md skills/retrospective/flow-template.md`
Expected: 0 件

Run: `grep -n "振り分け判定" skills/retrospective/flow-template.md`
Expected: 2 件（ヘッダ注記と課題フィールド）

- [ ] **Step 4: コミット**

```bash
git add skills/retrospective/template.md skills/retrospective/flow-template.md
git commit -m "retrospective: テンプレートを新形式（達成サマリ+課題+再発進展）へ改訂（ADR-0056）"
```

---

### Task 3: retrospectives README の規約更新と欠落2行の追加

**Files:**
- Modify: `docs/records/retrospectives/README.md`

- [ ] **Step 1: 運用規約セクションを更新する**

冒頭説明と「運用規約」を以下へ書き換える（一覧テーブルの既存行・末尾注記は**変更しない**）:

旧（冒頭〜運用規約の該当箇所）:
```markdown
サブプロジェクトクローズ時に `retrospective` スキルで作成された振り返り記録の一覧。

## 運用規約（ADR-0011 / ADR-0021）
```

新:
```markdown
サブプロジェクトクローズ時に `retrospective` スキルで作成された課題抽出記録の一覧。

## 運用規約（ADR-0011 / ADR-0021 / ADR-0056）
```

運用規約の箇条書きに以下を追記する（既存の箇条書きの末尾、「訂正が必要な場合は…」の行の前に挿入）:

```markdown
- **形式（ADR-0056、2026-07-31 以降）**: 記録は「最小サイクル文脈（達成サマリ）＋課題詳細（事象/原因/影響）＋既存課題の再発・進展」で構成する。旧5観点の Went Well / Tech Notes は観点として廃止（知見は worklog パイプラインが捕捉）。rubber-duck レビューはユーザー要求時のみ（実施時に「Independent Review Notes」節を追加）。フロー課題は delta 型 / 構造観察型の振り分け規則に従う（詳細は `skills/retrospective/SKILL.md`）
- それ以前の記録（7セクション形式・非定型の簡易形式）は当時の形式のまま改変しない
```

- [ ] **Step 2: 一覧テーブルに欠落2行を追加する**

一覧テーブルの末尾（2026-07-17 行の後）に追加:

```markdown
| 2026-07-18 | worklog パイプライン スキーマ v2 改訂 | system/ のみ | feature/worklog-v1.1 (merge: ba7e81d) | ADR-0048〜0053 サイクル。簡易形式で実施（当時未定型）。Issue-0030/0031 起票。※本行は 2026-07-31 に追記（作成時の記載漏れ） |
| 2026-07-18 | worklog 実運用堅牢化 | system/ のみ | feature/worklog-operational-hardening (merge: 50bef04) | ADR-0054/0055 サイクル。簡易形式で実施（当時未定型）。Issue-0032 起票、課題 A/C は不起票。※本行は 2026-07-31 に追記（作成時の記載漏れ） |
```

- [ ] **Step 3: 「関連」セクションに ADR-0056 を追記する**

旧:
```markdown
- ADR-0021: retrospective を課題抽出に限定し、出力を system/flow に分割
```

新:
```markdown
- ADR-0021: retrospective を課題抽出に限定し、出力を system/flow に分割
- ADR-0056: 課題抽出記録への純化・worklog 委譲・振り分け規則（2026-07-31 以降の形式）
```

- [ ] **Step 4: template 同期を実行し差分を確認する**

Run: `pwsh scripts/sync-template.ps1`
Expected: 正常終了。続けて `git status --short template/` で `template/docs/records/retrospectives/README.md` が更新されていること（空インデックス版に規約更新が反映される。ADR-0027）

- [ ] **Step 5: 実体確認**

Run: `grep -c "2026-07-18" docs/records/retrospectives/README.md`
Expected: 2 以上（追加した2行）

Run: `grep -n "ADR-0056" docs/records/retrospectives/README.md`
Expected: 2 件以上（運用規約見出し・形式規約・関連）

- [ ] **Step 6: コミット**

```bash
git add docs/records/retrospectives/README.md template/
git commit -m "retrospectives: README 運用規約を新形式へ更新・欠落2行を追記（ADR-0056）"
```

---

### Task 4: README.md / CONTRIBUTING.md の整合更新

**Files:**
- Modify: `README.md:44`（スキル一覧の retrospective 行）
- Modify: `CONTRIBUTING.md:256-291`（シナリオ「振り返りスキル（retrospective）を変更するとき」）
- Modify: `CONTRIBUTING.md:326`（シナリオ「振り返りで抽出された課題に対策するとき」チェックリスト）

- [ ] **Step 1: README.md のスキル一覧行を書き換える**

旧:
```markdown
| [`retrospective`](skills/retrospective/) | サブプロジェクトクローズ時の振り返り。Done / Went Well / Struggled / Tech Notes / Issues を抽出し、課題を「対象システム固有 / 開発フロー」に分類して system/flow の2フォルダに記録する（対策の採否・設計・ADR化は次サイクルでユーザー判断） |
```

新:
```markdown
| [`retrospective`](skills/retrospective/) | サブプロジェクトクローズ時の課題抽出記録。AI が課題候補（事象/原因/影響）を一括提示し、ユーザーが起票判断。課題を「対象システム固有 / 開発フロー」に分類して system/flow の2フォルダに記録する（対策の採否・設計・ADR化は次サイクルでユーザー判断。知見の再利用は worklog パイプラインが担う。ADR-0056） |
```

- [ ] **Step 2: CONTRIBUTING.md シナリオ「振り返りスキルを変更するとき」の背景を書き換える**

旧（背景の第1段落）:
```markdown
`retrospective` はサブプロジェクトを master へ merge した直後に1回だけ起動するスキルで、Done / Went Well / Struggled / Tech Notes / Issues / Independent Review Notes / Handoff Forward の7セクションを対話的に埋める。**振り返りは課題の抽出と分類までにとどめ、対策の採否判断・設計・ADR 化は行わない**（次サイクルの責務。ADR-0021）。課題は「対象システム固有」「開発フロー/ガイドライン関連」に分類し、前者は `docs/records/retrospectives/system/`、後者は `docs/records/retrospectives/flow/` に per-cycle で記録する。抽出した課題は分類を問わず全件 `docs/working/issues/system|flow/` へ起票される（ADR-0028。起票は記録行為であり、抽出限定スコープは変わらない）。
```

新:
```markdown
`retrospective` はサブプロジェクトを master へ merge した直後に1回だけ起動するスキルで、「最小サイクル文脈（達成サマリ）＋課題詳細（事象/原因/影響）＋既存課題の再発・進展」の課題抽出記録を作成する（ADR-0056。AI が課題候補を一括提示し、ユーザーが修正・起票判断を行う単一形式）。**振り返りは課題の抽出と分類までにとどめ、対策の採否判断・設計・ADR 化は行わない**（次サイクルの責務。ADR-0021）。課題は「対象システム固有」「開発フロー/ガイドライン関連」に分類し、前者は `docs/records/retrospectives/system/`、後者は `docs/records/retrospectives/flow/` に per-cycle で記録する。フロー課題は delta 型（worklog で捕捉可能）/ 構造観察型の振り分け規則に従い、delta 型で急がないものは起票せず worklog パイプラインへ委ねる（ADR-0056）。起票する課題は全件 `docs/working/issues/system|flow/` へ起票される（ADR-0028。起票は記録行為であり、抽出限定スコープは変わらない）。rubber-duck 独立レビューはユーザー要求時のみのオプション工程。
```

- [ ] **Step 3: 同シナリオのチェックリストを書き換える**

旧:
```markdown
- 起動タイミングがサブプロジェクト単位 = merge 直後1回 のままか（粒度を変える場合は ADR-0010 の更新も必要）
- 出力ファイル規約（ADR-0011: 上書き禁止、インデックス追記のみ / ADR-0021: system/flow 2フォルダ配置）が手順内で守られているか
- rubber-duck 呼び出しは1サイクルにつき1回に留まっているか
- 課題抽出限定スコープが崩れていないか（振り返り内で対策の採否・設計・ADR化をしていないか。対策決定は次サイクル、着手はユーザー判断。ADR-0021）
- Tech Notes のスコープ（汎用技術知見のみ。システム仕様・ドメイン知識は除外。ADR-0012 / ADR-0021）が守られているか
- 課題の全件起票（要約＋起票元参照・振り返りファイルへの Issue 番号記載）が手順内で維持されているか（ADR-0028）
```

新:
```markdown
- 起動タイミングがサブプロジェクト単位 = merge 直後1回 のままか（粒度を変える場合は ADR-0010 の更新も必要）
- 出力ファイル規約（ADR-0011: 上書き禁止、インデックス追記のみ / ADR-0021: system/flow 2フォルダ配置）が手順内で守られているか
- rubber-duck 呼び出しがユーザー要求時のみ・1サイクルにつき1回に留まっているか（ADR-0056）
- 課題抽出限定スコープが崩れていないか（振り返り内で対策の採否・設計・ADR化をしていないか。対策決定は次サイクル、着手はユーザー判断。ADR-0021）
- Went Well / Tech Notes 等の観点を復活させていないか（知見の記録は worklog パイプラインの責務。ADR-0056）
- フロー課題の振り分け規則（delta 型は原則 worklog へ、緊急時と構造観察型のみ起票）が手順内で維持されているか（ADR-0056）
- 起票する課題の全件起票（要約＋起票元参照・振り返りファイルへの Issue 番号記載）が手順内で維持されているか（ADR-0028）
- `docs/records/retrospectives/README.md` への行追加が省略不可の工程として維持されているか（ADR-0056）
```

- [ ] **Step 4: シナリオ「振り返りで抽出された課題に対策するとき」のチェックリスト末尾行を書き換える**

旧:
```markdown
- 取り込みサイクル完了後の retrospective で「前回課題への対策結果」を Done または Tech Notes に明示的に書く準備ができているか
```

新:
```markdown
- 取り込みサイクル完了後の retrospective で「前回課題への対策結果」を達成サマリまたは「既存課題の再発・進展」に明示的に書く準備ができているか
```

- [ ] **Step 5: 実体確認**

Run: `grep -n "Went Well\|Tech Notes" README.md CONTRIBUTING.md`
Expected: README.md は 0 件。CONTRIBUTING.md は「Went Well / Tech Notes 等の観点を復活させていないか」の1行のみ

- [ ] **Step 6: コミット**

```bash
git add README.md CONTRIBUTING.md
git commit -m "docs: README/CONTRIBUTING の retrospective 記述を新形式へ整合（ADR-0056）"
```

---

### Task 5: issue 状態の更新（Issue-0035 close / Issue-0021 追記）

**Files:**
- Modify: `docs/working/issues/flow/0035-retrospective-lightweight-mode.md`
- Modify: `docs/working/issues/flow/0021-tech-notes-cross-cycle-reuse.md`
- Modify: `docs/working/issues/README.md`

- [ ] **Step 1: Issue-0035 を close する**

`docs/working/issues/flow/0035-retrospective-lightweight-mode.md` を編集:

旧:
```markdown
- **Status**: open
- **Opened**: 2026-07-31
```

新:
```markdown
- **Status**: closed
- **Opened**: 2026-07-31
- **Closed**: 2026-07-31
```

「検討状況」に追記:
```markdown
- 2026-07-31: 対策サイクル（feature/retrospective-mode-review）で brainstorming を実施。「簡易モードの追加」ではなく retrospective の役割自体を再定義する方針を採用（ADR-0056）
```

「結論」を書き換え:

旧:
```markdown
## 結論

（open）
```

新:
```markdown
## 結論

ADR-0056 で対処。「簡易モード」を選択肢として追加するのではなく、retrospective 自体を「課題抽出記録」へ純化し単一形式とした（Went Well / Tech Notes 観点は廃止し worklog パイプラインへ委譲。rubber-duck はユーザー要求時のみのオプション）。実運用多数派だった簡易実施が定型化された標準形式となった。
```

- [ ] **Step 2: Issue-0021 の検討状況へ追記する**

`docs/working/issues/flow/0021-tech-notes-cross-cycle-reuse.md` の「検討状況」セクション末尾に追記（Status は open のまま。close 判断はユーザー）:

```markdown
- 2026-07-31: ADR-0056 により retrospective の Tech Notes 観点自体を廃止し、スキル化に有用な知見は worklog パイプライン（record → extract → skillify）が捕捉・再利用する構造へ委譲。「Tech Notes の横断再利用の仕組み」は worklog-extract がその役割を担うため、本課題は解消方向。close の判断はユーザーに委ねる
```

- [ ] **Step 3: issues インデックスを更新する**

`docs/working/issues/README.md` の 0035 行:

旧:
```markdown
| [0035](flow/0035-retrospective-lightweight-mode.md) | retrospective の簡易モードが正式な選択肢として未定義 | open | 2026-07-31 |
```

新:
```markdown
| [0035](flow/0035-retrospective-lightweight-mode.md) | retrospective の簡易モードが正式な選択肢として未定義 | closed | 2026-07-31 |
```

- [ ] **Step 4: 実体確認**

Run: `grep -n "Status.*closed" docs/working/issues/flow/0035-retrospective-lightweight-mode.md && grep -n "0035.*closed" docs/working/issues/README.md && grep -c "2026-07-31" docs/working/issues/flow/0021-tech-notes-cross-cycle-reuse.md`
Expected: 0035 ファイルとインデックスの closed 表記が各1件、0021 に追記日付が1件以上

- [ ] **Step 5: コミット**

```bash
git add docs/working/issues/flow/0035-retrospective-lightweight-mode.md docs/working/issues/flow/0021-tech-notes-cross-cycle-reuse.md docs/working/issues/README.md
git commit -m "issues: 0035 を close（ADR-0056 で対処）・0021 に解消方向を追記"
```

---

### Task 6: 横断検証と ADR-0056 の Accepted 昇格

**Files:**
- Modify: `docs/records/decisions/0056-retrospective-issue-extraction-core-worklog-delegation.md`
- Modify: `docs/records/decisions/README.md`

- [ ] **Step 1: 波及漏れの横断確認**

Run: `grep -n "5観点\|Went Well\|Tech Notes" CLAUDE.md skills/start-work/SKILL.md skills/decision-log/SKILL.md docs/overview/principles.md docs/overview/folder-structure.md`
Expected: 0 件（ヒットした場合はその記述を新形式へ修正してからコミットに含める。CLAUDE.md を修正した場合のみ `pwsh scripts/sync-template.ps1` を再実行）

Run: `grep -rn "Went Well\|Tech Notes" skills/ --include="*.md" | grep -v "worklog"`
Expected: Task 1〜2 改訂後の宣言行（SKILL.md の廃止宣言・CONTRIBUTING 相当）以外に 0 件

注: `docs/records/`（過去の ADR・retrospective 記録）と `docs/working/issues/` の既存記述は歴史的記録のため対象外（改変しない）。

- [ ] **Step 2: ADR-0056 を Accepted へ昇格する**

`docs/records/decisions/0056-retrospective-issue-extraction-core-worklog-delegation.md`:

旧:
```markdown
- **Status**: Proposed
```

新:
```markdown
- **Status**: Accepted
```

`docs/records/decisions/README.md` の 0056 行の `Proposed` を `Accepted` に変更する。

- [ ] **Step 3: 実体確認**

Run: `grep -n "Status" docs/records/decisions/0056-retrospective-issue-extraction-core-worklog-delegation.md && grep -n "0056" docs/records/decisions/README.md`
Expected: 両方 Accepted 表記

- [ ] **Step 4: コミット**

```bash
git add docs/records/decisions/0056-retrospective-issue-extraction-core-worklog-delegation.md docs/records/decisions/README.md
git commit -m "adr: 0056 を Accepted へ昇格（retrospective 再定義 実装完了）"
```

---

### 実装完了後（計画外・通常フローで実施）

1. handoff 更新（session-handoff update）
2. master へ `--no-ff` マージ（finishing-a-development-branch / ユーザー確認）
3. マージ後、**新形式での初回 retrospective を本サイクル自身に実施**（ドッグフーディング。改訂後スキルの初検証）
4. ユーザーへ `/plugin marketplace update ai-driven-dev-principles` の実行を依頼（skills/ 改定の反映。ADR-0055。未反映の間、ロードされるスキル本文は旧版のままである点に注意）
