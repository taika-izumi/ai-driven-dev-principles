# 開発プロジェクトのフォルダ構成定義 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 情報の5分類体系に基づくフォルダ構成定義をガイドラインに追加し、organize-inbox スキルを新設し、既存スキル・テンプレート・本リポジトリ docs を新構成へ移行する。

**Architecture:** 定義本体は `docs/overview/folder-structure.md` に一元化し、スキル・CLAUDE.md は参照のみ持つ。実装順序は仕様書の制約に従い ブロック01 → 03 → 02 → 04 → 06 → 05（start-work はパス更新後に inbox 検知を追加。テンプレート同期は内容更新と移行の完了後）。

**Tech Stack:** Markdown（スキル・ドキュメント）、PowerShell（sync-template.ps1）、git mv（履歴保持移行）。

**仕様書:** `docs/current/specs/2026-07-04-project-folder-structure/00〜06`（本計画の唯一の上位入力）

**注意:** Task 11 で本計画ファイル自身が `docs/working/plans/` へ移動する。Task 12 以降は移動後のパスで参照すること。テストコードは無いプロジェクトのため、各タスクの検証は grep・スクリプト実行・目視で行う。

---

### Task 1: フォルダ構成定義ドキュメントの作成（ブロック01）

**Files:**
- Create: `docs/overview/folder-structure.md`

- [ ] **Step 1: ファイルを作成する**

以下の全文で `docs/overview/folder-structure.md` を作成する:

````markdown
# フォルダ構成定義（情報分類とドキュメント配置の規範）

## 1. この文書の目的

プロジェクトで発生する情報・ドキュメントを「どこに置くか」の判断基準を定義する。本文書は配置判断の唯一の参照元であり、プロジェクト参画直後に読むべき文書として `docs/overview/` に置かれている。

## 2. 情報分類体系

分類の軸は「話題（トピック）」ではなく、**情報の性質（更新様式 × ライフサイクルの長さ）**である。同じ話題の情報でも、性質が異なれば別の分類になる。

| # | 分類 | 性質 | 代表例 |
|---|------|------|--------|
| 1 | オリエンテーション | 低頻度更新・恒久。参画直後のキャッチアップ情報。一時的なステータス情報は含めない | プロジェクト概要、用語集、ステークホルダー・体制 |
| 2 | 現在の正 | 書き換え型スナップショット・恒久。現時点のシステム・プロジェクトの姿 | 仕様書、アーキテクチャ、ロードマップ |
| 3 | 進行中の作業 | 高頻度更新・短寿命。いずれクローズされる | 課題（issue）、セッション引き継ぎ（handoff）、実装計画 |
| 4 | 追跡型の記録 | 確定後不変・追記型・恒久。出来事の時点記録 | 意思決定記録（ADR）、議事録、振り返り、リリースノート、インシデント報告 |
| 5 | 参照知識 | 低頻度改訂・恒久。作業を支える周辺知識 | リリース手順、運用手順、既知エラー、調査メモ、FAQ |

## 3. 境界の配置判断基準

分類に迷いやすい境界には、以下の基準を適用する:

1. **オリエンテーション vs 参照知識** — 「参画直後に全員が読むべきか（→オリエンテーション）、必要になった時に引くものか（→参照知識）」
2. **現在の正 vs 参照知識** — 「開発対象システム・プロジェクトそのものの姿を表すか（→現在の正）、作業を支える周辺知識か（→参照知識）」
3. **追跡型の記録 vs 参照知識** — 「出来事の時点記録で以後変更されないか（→追跡型の記録）、そこから蒸留され改訂されながら維持される再利用知識か（→参照知識）」

## 4. 蒸留規則

同じ出来事から「記録」と「知識」の両方が生まれてよい。時点記録（議事録、インシデント報告など）は書き換えずそのまま残し、そこから再利用可能な知識（運用ノウハウ、既知エラー対処など）が得られたら、**別ドキュメントとして**参照知識や現在の正に起こす。記録を後から繰り返し探して読み返している状態は、蒸留漏れのサインとして扱う。

## 5. 標準フォルダレイアウト

```
docs/
  overview/        # 1. オリエンテーション（プロジェクト概要、用語集、体制、本文書）
  current/         # 2. 現在の正
    specs/         #    仕様書（ディレクトリ分割形式 YYYY-MM-DD-<topic>/）
  working/         # 3. 進行中の作業
    issues/        #    課題（個別ファイル＋インデックス）
    handoff/       #    セッション引き継ぎ（ブランチごと）
    plans/         #    実装計画
  records/         # 4. 追跡型の記録
    decisions/     #    ADR（個別ファイル＋インデックス）
    retrospectives/  #  振り返り（system/ flow/）
    minutes/       #    議事録（必要なプロジェクトのみ）
  reference/       # 5. 参照知識
  inbox/           # 未分類の投入口（下記「inbox」参照）
```

運用規約:

- **種別サブフォルダはオンデマンド作成** — 使わない空フォルダを先行作成しない
- **列挙されていない新種別** — 分類基準で判断し、該当する分類フォルダ直下または新しい種別サブフォルダに置く
- **迷ったら inbox へ** — `docs/inbox/` に置けば、organize-inbox スキルが分類基準に照らして整理する（移動・分割・既存ドキュメントへの統合）
- **コードを docs/ に置かない** — コード領域との分離は「9. コード領域の配置原則」を参照

## 6. 代表的なドキュメント種別の配置表

| ドキュメント | 配置先 |
|-------------|--------|
| プロジェクト概要・ゴール | `docs/overview/` |
| 用語集 | `docs/overview/` |
| ステークホルダー・体制図 | `docs/overview/` |
| 要件・仕様書・設計書 | `docs/current/specs/` |
| ロードマップ | `docs/current/` |
| コーディング規約 | `docs/reference/`（作業を支える周辺知識） |
| 課題・未決事項 | `docs/working/issues/` |
| セッション引き継ぎ | `docs/working/handoff/` |
| 実装計画 | `docs/working/plans/` |
| 意思決定記録（ADR） | `docs/records/decisions/` |
| 議事録 | `docs/records/minutes/` |
| 振り返り | `docs/records/retrospectives/` |
| リリースノート・インシデント報告 | `docs/records/` |
| リリース手順・運用手順 | `docs/reference/` |
| 既知エラー・トラブルシュート | `docs/reference/` |
| 技術調査・検証メモ | `docs/reference/` |

## 7. 課題（issue）管理

- 課題は1件ごとに `docs/working/issues/NNNN-<slug>.md`（NNNN は4桁ゼロ埋め連番、slug は英語ケバブケース）で起票し、インデックス `docs/working/issues/README.md` に1行追加する
- **Status は open → closed** — 対策方針が決定したら ADR を作成し、課題の「結論」に ADR 番号を記載して close する（進行中の作業 → 追跡型の記録への遷移）
- **クローズ済み課題はその場に残す** — アーカイブは独立した分類ではなく、この分類内の状態として扱う
- **フォルダ昇格** — 検討が長期化・多観点化したら `docs/working/issues/NNNN-<slug>/` フォルダに昇格できる。課題ファイルをフォルダ内 `README.md` とし、分析・比較・叩き台のファイルを並置する
- **TBD を積極的に使う** — 不確定な情報を確定した事実のように書かない。未確定箇所は「TBD」と明示する

課題ファイルのフォーマット:

```markdown
# Issue-NNNN: <タイトル>

- **Status**: open | closed
- **Opened**: YYYY-MM-DD
- **Closed**: YYYY-MM-DD（closed 時のみ）
- **関連**: ADR-NNNN 等（あれば）

## 課題内容

（何が問題か・なぜケアが必要か。TBD を積極的に使ってよい）

## 検討状況

（対策検討の経過。長期化したらフォルダ昇格を検討）

## 結論

（closed 時: 下した決定への参照。決定内容自体は ADR に書く）
```

インデックス `docs/working/issues/README.md` は1課題1行のテーブル（# / タイトル / Status / Opened）。

## 8. 運用例: チーム開発での大規模リファクタリング

分類の間を情報が流れる代表例:

1. **発端** — 「技術的負債が溜まっている」→ 課題を起票（`working/issues/`, open）。候補が複数あれば課題ごとに起票する。課題インデックスがそのまま負債の棚卸し表になる
2. **検討・叩き台** — 検討が多観点・長期になったら課題をフォルダに昇格し、現状分析・影響範囲・比較案・叩き台資料を並置する
3. **合意形成** — 会議の議事録は `records/minutes/` に残し、合意した決定は ADR（`records/decisions/`）にする。課題は「結論」から ADR を参照して close する
4. **合意後** — 仕様書（`current/specs/`）を書き換えで更新し、実装計画（`working/plans/`）を作成して実装に進む

## 9. コード領域の配置原則

コード（ソースコード・テスト・ビルドスクリプト等）の配置は、以下の抽象原則のみ定める:

1. **コードとドキュメントは領域を分離する** — コードを `docs/` に置かない。ドキュメントをコードツリーの中に散在させない
2. **コード領域の内部構成は言語・フレームワークの標準慣習に従う** — 本ガイドラインは干渉しない。ソースとテストは分離する
3. **AI駆動システムの成果物はコード領域に置く** — プロンプト定義、エージェント定義、評価データセット等はコードと同様にバージョン管理する。それらの背景説明・運用知識は docs 側の該当分類に置く

## inbox

`docs/inbox/` は分類に迷った情報・とりあえず保存したい情報の投入口である。

- ユーザーはファイルを置くだけでよい（分類はその場で考えなくてよい）
- `organize-inbox` スキルが、各ファイルを本文書の分類基準に照らして処理する（移動・分割・既存ドキュメントへの統合・破棄確認）
- セッション開始時（`start-work`）に未処理ファイルがあれば、整理の実行が提案される

## 関連 ADR

- ADR-0025: 情報の5分類体系の導入
- ADR-0026: inbox と organize-inbox スキル
- ADR-0027: テンプレート初期セットの基準
````

- [ ] **Step 2: 仕様書ブロック01 の章立てと一致することを確認する**

`docs/current/specs/2026-07-04-project-folder-structure/01-folder-structure-definition.md` のセクション3（インターフェース）と見出しを突き合わせ、5分類・判断基準3つ・蒸留規則・レイアウト・配置表・課題管理・運用例・コード原則がすべて含まれることを目視確認する。

- [ ] **Step 3: コミット**

```bash
git add docs/overview/folder-structure.md
git commit -m "feat: フォルダ構成定義ドキュメントを追加（ブロック01, ADR-0025）"
```

---

### Task 2: session-handoff スキルのパス更新（ブロック03）

**Files:**
- Modify: `skills/session-handoff/SKILL.md`

- [ ] **Step 1: パスを置換する**

`skills/session-handoff/SKILL.md` 内の以下をすべて置換する（replace_all）:

| 旧 | 新 |
|----|----|
| `docs/handoff/` | `docs/working/handoff/` |

対象箇所: ファイル配置セクションのパスとツリー図、read 手順のファイルパス組み立て、finalize 手順の `git add` / `git commit` コマンド例。

- [ ] **Step 2: 旧パスが残っていないことを確認する**

Grep: `docs/handoff` を `skills/session-handoff/` で検索し、`docs/working/handoff` 以外のヒットが 0 件であること。

- [ ] **Step 3: コミット**

```bash
git add skills/session-handoff/SKILL.md
git commit -m "refactor: session-handoff のパスを docs/working/handoff へ更新（ブロック03）"
```

---

### Task 3: decision-log スキルのパス更新と未決事項運用の改訂（ブロック03）

**Files:**
- Modify: `skills/decision-log/SKILL.md`

- [ ] **Step 1: ADR パスを置換する**

以下をすべて置換する（replace_all）:

| 旧 | 新 |
|----|----|
| `docs/decisions/` | `docs/records/decisions/` |

対象箇所: 連番決定手順、ファイル作成手順、インデックス更新手順、コミットコマンド例。

- [ ] **Step 2: 「未決事項（open questions）の扱い」セクションを全置換する**

セクション見出し「## 未決事項（open questions）の扱い」から次の「## ADR更新手順」の直前までを、以下の内容に置き換える:

````markdown
## 未決事項（open questions）の扱い

ADRは「下した決定」だけを記録する。仕様検討の議論中に増えていく未解決の論点（「これからこれを決めないといけない」「ここに課題が潜んでいる」）は ADR ではなく**課題（issue）**として `docs/working/issues/` で管理する。

### 起票

1. 未決事項を検出したら `docs/working/issues/NNNN-<slug>.md` を起票する（Status: open）。連番はインデックス `docs/working/issues/README.md` の最大番号+1。フォーマットは `docs/overview/folder-structure.md` の「課題（issue）管理」を参照
2. インデックス `docs/working/issues/README.md` に1行追加する

### ライフサイクル

1. その論点について意思決定を下したら、通常どおり ADR を作成する
2. ADR 化したら課題を close する: 課題ファイルの Status を `closed` に変更し、Closed 日付を記入し、「結論」セクションに ADR 番号を記載する。インデックスの Status も更新する
3. **クローズ済み課題は削除せずその場に残す**（追跡可能性の維持）

### 注意

- 課題ファイル・インデックスは template には同期されない（新規プロジェクトでは空のインデックスから始まる）
- 検討が長期化・多観点化した課題はフォルダへ昇格できる（`docs/overview/folder-structure.md` 参照）
````

- [ ] **Step 3: 旧パス・旧運用が残っていないことを確認する**

Grep: `open-questions` と `docs/decisions` を `skills/decision-log/` で検索し、ヒットが 0 件であること（`docs/records/decisions` は可）。

- [ ] **Step 4: コミット**

```bash
git add skills/decision-log/SKILL.md
git commit -m "refactor: decision-log のパス更新と未決事項の課題管理への統合（ブロック03, ADR-0025）"
```

---

### Task 4: retrospective / feature-block-design スキルのパス更新（ブロック03）

**Files:**
- Modify: `skills/retrospective/SKILL.md`
- Modify: `skills/feature-block-design/SKILL.md`

- [ ] **Step 1: retrospective のパスを置換する**

`skills/retrospective/SKILL.md` 内で以下をすべて置換する（replace_all）:

| 旧 | 新 |
|----|----|
| `docs/retrospectives/` | `docs/records/retrospectives/` |
| `docs/plans/` | `docs/working/plans/` |
| `docs/specs/` | `docs/current/specs/` |
| `docs/handoff/master.md` | `docs/working/handoff/master.md` |

`skills/retrospective/template.md` と `skills/retrospective/flow-template.md` にも同様の旧パスが無いか Grep で確認し、あれば同じ置換を適用する。

- [ ] **Step 2: feature-block-design のパスを置換する**

`skills/feature-block-design/SKILL.md` 内で以下をすべて置換する（replace_all）:

| 旧 | 新 |
|----|----|
| `docs/specs/` | `docs/current/specs/` |

対象箇所: 出力ディレクトリ構造、Phase 1 のモード判定 glob（`docs/current/specs/*-<topic>/` になる）。

- [ ] **Step 3: 検証**

Grep: `docs/retrospectives|docs/plans|docs/specs|docs/handoff` を `skills/retrospective/ skills/feature-block-design/` で検索し、新パス（`docs/records/...` `docs/working/...` `docs/current/...`）以外のヒットが 0 件であること。

- [ ] **Step 4: コミット**

```bash
git add skills/retrospective/ skills/feature-block-design/SKILL.md
git commit -m "refactor: retrospective / feature-block-design のパスを新構成へ更新（ブロック03）"
```

---

### Task 5: start-work スキルのパス更新（ブロック03）

**Files:**
- Modify: `skills/start-work/SKILL.md`

- [ ] **Step 1: パスを置換する**

`skills/start-work/SKILL.md` 内で以下をすべて置換する（replace_all）:

| 旧 | 新 |
|----|----|
| `docs/retrospectives/` | `docs/records/retrospectives/` |

（現状 start-work が明示参照するパスは retrospectives のみ。他の旧パス `docs/handoff` `docs/specs` `docs/plans` が無いか Grep で確認し、あれば同様に新パスへ置換する。）

- [ ] **Step 2: コミット**

```bash
git add skills/start-work/SKILL.md
git commit -m "refactor: start-work のパスを新構成へ更新（ブロック03）"
```

---

### Task 6: organize-inbox スキルの新設（ブロック02）

**Files:**
- Create: `skills/organize-inbox/SKILL.md`

- [ ] **Step 1: スキルファイルを作成する**

以下の全文で `skills/organize-inbox/SKILL.md` を作成する:

````markdown
---
name: organize-inbox
description: "docs/inbox/ に置かれた未分類の情報を、フォルダ構成定義（docs/overview/folder-structure.md）の分類基準に照らして1件ずつ整理するスキル。移動だけでなく、複数分類への分割、既存ドキュメントへの追記統合も行う。ユーザーの明示実行、または start-work の inbox 検知からの提案で起動する。"
---

# organize-inbox

`docs/inbox/` の未分類ファイルを、情報分類体系に基づいて適切な場所へ整理するスキル。

## いつ使うか

- ユーザーが inbox の整理を指示した時
- `start-work` Phase 1 の inbox 検知で実行が提案され、ユーザーが承諾した時

## 重要な前提

- 分類基準は `docs/overview/folder-structure.md` を唯一の参照元とする。本スキル内に基準を複製しない
- `docs/inbox/README.md` は inbox の使い方を説明するシードファイルであり、**処理対象外**
- トークン消費対策: ファイル内容の読み込みは分類判断に必要な範囲（冒頭部分・見出し構造）に留める。全件を一括で読み込まない

## 手順

### 1. 一覧と確認

1. `docs/inbox/` 内のファイルを列挙する（README.md を除く）
2. 対象が 0 件なら「inbox は空です」と報告して終了する
3. 件数が多い場合（目安: 6件以上）は件数を提示し、全件処理するか対象を絞るかをユーザーに確認する

### 2. 1件ずつ処理（各ファイルで繰り返す）

1. `docs/overview/folder-structure.md` の分類基準（5分類・境界判断基準・蒸留規則）を確認する（初回のみ読み込めばよい）
2. ファイル内容を読む（大きいファイルは冒頭部分・見出し構造のみ）
3. 処理方針を4種から決める:
   - **移動**: ファイルを丸ごと適切な分類先へ移す
   - **分割**: 複数分類の情報が混在する場合、内容を分割して複数の分類先に配置する
   - **統合**: 既存ドキュメントに追記されるべき内容の場合、既存ファイルへ追記し、新規ファイルは作らない
   - **破棄**: 情報価値がない（重複・空・一時メモ）と判断した場合。**破棄は不可逆操作のため、必ずユーザーの承認を得る**（`pre-action-review` の高リスク扱い）
4. 分類・処理方針が曖昧な場合は、選択肢＋推奨（先頭に「（推奨）」）でユーザーに確認する。明確な場合は確認なしで処理してよい
5. 処理を実行する:
   - 移動・分割先に種別サブフォルダが必要でまだ無ければ作成する
   - 配置先にインデックス（`docs/working/issues/README.md` 等）があれば更新する
   - 処理済みの inbox ファイルを除去する（統合の場合も、反映完了後に inbox から取り除く）

### 3. サマリー報告

処理結果を一覧でユーザーに報告する（ファイルごとに: 元ファイル名 / 処理方針 / 配置先または統合先）。

### 4. 意思決定の検出

処理中に意思決定（分類基準自体への疑義、基準の解釈の決定など）が発生したら、通常どおり `decision-log` / 課題起票の対象とする。

## 対応する原則

- 原則2（関心の分離）: 分類判断を独立した責務として自動化する
- 原則3（コンテキスト管理）: 情報を分類体系に載せ、必要な時に見つかる状態を維持する
- 原則4（人間の関与）: 曖昧時の選択肢確認、破棄時の承認必須

## 関連

- ADR-0026: inbox フォルダと organize-inbox スキルの導入
- ADR-0025: 情報の5分類体系
- `docs/overview/folder-structure.md`: 分類基準の定義本体
````

- [ ] **Step 2: コミット**

```bash
git add skills/organize-inbox/SKILL.md
git commit -m "feat: organize-inbox スキルを新設（ブロック02, ADR-0026）"
```

---

### Task 7: start-work への inbox 検知追加（ブロック02）

**Files:**
- Modify: `skills/start-work/SKILL.md`

- [ ] **Step 1: Phase 1 に inbox 検知ステップを追加する**

`skills/start-work/SKILL.md` の「### Phase 1: 状況診断（state assessment）」のステップ1（リポジトリ状態確認）の直後に、以下をステップ2として挿入する（既存のステップ2以降は番号を繰り下げる）:

```markdown
2. `docs/inbox/` を確認する（ディレクトリ一覧の取得のみ。ファイル内容は読まない）:
   - README.md 以外のファイルが存在する場合、件数をユーザーに伝え、`organize-inbox` スキルの実行を提案する（強制はしない）
   - ユーザーが後回しを選んだ場合、handoff の「既知のブロッカー・懸念」に滞留件数を記録する
```

- [ ] **Step 2: Phase 2 のマッピング表に organize-inbox を追加する**

Phase 2 の推奨スキルマッピング表に以下の行を追加する:

```markdown
| inbox の整理 | organize-inbox | （本リポジトリ固有スキル、フォールバック不要） |
```

- [ ] **Step 3: コミット**

```bash
git add skills/start-work/SKILL.md
git commit -m "feat: start-work Phase 1 に inbox 検知を追加（ブロック02, ADR-0026）"
```

---

### Task 8: CLAUDE.md / principles.md の内容更新（ブロック04）

**Files:**
- Modify: `CLAUDE.md`
- Modify: `docs/principles.md`（移動前のパス。Task 11 で `docs/overview/principles.md` へ移動する）

- [ ] **Step 1: CLAUDE.md の「意思決定の記録」内の open-questions 記述を更新する**

置換（1箇所）:

旧:
```
- ADRには「下した決定」のみを記載すること。未解決の論点（未決事項）は ADR に書かず `docs/open-questions.md`（スナップショット型）に分離すること
```

新:
```
- ADRには「下した決定」のみを記載すること。未解決の論点（未決事項）は ADR に書かず、課題（`docs/working/issues/`）として起票すること
```

- [ ] **Step 2: CLAUDE.md の「ドキュメント運用」セクションを書き換える**

セクション全体を以下に置き換える:

```markdown
### ドキュメント運用

- ドキュメントの配置は `docs/overview/folder-structure.md` の情報分類体系（5分類）と配置判断基準に従うこと
- 配置に迷った情報は `docs/inbox/` に置き、`organize-inbox` スキルで整理すること
- 仕様書は、それを読むだけで現時点のシステム全容が分かるスナップショットとして維持すること
- 既存仕様書を改修する場合は、変更差分のみの別ファイルを作らず、既存仕様書を**書き換えで更新**すること
- 「なぜ変更したか」は ADR に記録し、仕様書には「今どうなっているか」のみを書くこと
- 中規模以上のシステムでは、仕様書は `docs/current/specs/YYYY-MM-DD-<topic>/` 配下にディレクトリ分割形式（`00-overview.md` + `NN-<block>.md`）で配置すること
- 実装計画は `docs/working/plans/` に配置すること（利用スキルのデフォルト出力先が異なる場合もこちらを優先する）
```

- [ ] **Step 3: CLAUDE.md の「検証」セクションの retrospective パスを更新する**

置換（1箇所）: `docs/retrospectives/system/YYYY-MM-DD-<topic>.md` → `docs/records/retrospectives/system/YYYY-MM-DD-<topic>.md`、`docs/retrospectives/flow/YYYY-MM-DD-<topic>.md` → `docs/records/retrospectives/flow/YYYY-MM-DD-<topic>.md`

- [ ] **Step 4: principles.md の原則3 に情報分類の一文を追加する**

原則3（コンテキストの明示的管理）の箇条書きに以下を追加する（「常に適用する」の行の前）:

```markdown
- プロジェクトの情報・ドキュメントは、その性質（更新様式とライフサイクルの長さ）に基づいて分類・配置し、必要な情報が見つかる状態を維持する
```

- [ ] **Step 5: コミット**

```bash
git add CLAUDE.md docs/principles.md
git commit -m "docs: CLAUDE.md と原則3 にフォルダ構成規範を反映（ブロック04, ADR-0025/0026）"
```

---

### Task 9: CONTRIBUTING.md の更新（ブロック04）

**Files:**
- Modify: `CONTRIBUTING.md`

- [ ] **Step 1: パスを置換する**

以下をすべて置換する（replace_all）:

| 旧 | 新 |
|----|----|
| `docs/principles.md` | `docs/overview/principles.md` |
| `docs/specs/YYYY-MM-DD-<topic>/` | `docs/current/specs/YYYY-MM-DD-<topic>/` |
| `docs/retrospectives/system/` | `docs/records/retrospectives/system/` |
| `docs/retrospectives/flow/` | `docs/records/retrospectives/flow/` |
| `docs/retrospectives/README.md` | `docs/records/retrospectives/README.md` |

- [ ] **Step 2: 「シナリオ: 未決事項（open questions）を記録するとき」を全置換する**

セクション見出しから次のシナリオ見出しの直前までを、以下に置き換える:

````markdown
## シナリオ: 未決事項・課題を記録するとき

### 背景

仕様検討の議論中は「まだこれを決めないといけない」「ここに課題が潜んでいる」といった未解決の論点が増えていく。これらを ADR に書くと ADR が意思決定の記録から逸脱するため、課題（issue）として `docs/working/issues/` に分離して管理する（ADR-0019 / ADR-0025）。

### 判定基準

- 議論の中で、まだ意思決定に至っていない論点・要検討事項が生じたとき
- プロジェクトの課題（技術的負債、プロセス上の問題など）を記録したいとき

### 手順

1. `docs/working/issues/NNNN-<slug>.md` を起票し（Status: open）、インデックス `docs/working/issues/README.md` に1行追加する。フォーマットは `docs/overview/folder-structure.md` の「課題（issue）管理」を参照
2. その論点について意思決定を下したら ADR を作成する（`decision-log`）
3. ADR 化したら課題を close する（Status を closed に変更し「結論」に ADR 番号を記載。ファイルは削除せず残す）

### チェックリスト

- ADR本文に未決事項を書いていないか（決定のみになっているか）
- 解決した課題の Status とインデックスを更新したか
- 課題を削除していないか（closed のまま残す）
````

- [ ] **Step 3: 「シナリオ: ADRを記録するとき」内の記述規律の参照を更新する**

置換（1箇所）:

旧:
```
- ADRには「下した決定」のみを記載する。仕様検討の途中で生じた**未解決の論点（未決事項）は ADR に書かない**。未決事項は次のシナリオに従って `docs/open-questions.md` に分離する。
```

新:
```
- ADRには「下した決定」のみを記載する。仕様検討の途中で生じた**未解決の論点（未決事項）は ADR に書かない**。未決事項は次のシナリオに従って課題（`docs/working/issues/`）に分離する。
```

- [ ] **Step 4: 検証**

Grep: `open-questions|docs/principles.md|docs/specs/|docs/retrospectives/` を `CONTRIBUTING.md` で検索し、ヒットが 0 件であること。

- [ ] **Step 5: コミット**

```bash
git add CONTRIBUTING.md
git commit -m "docs: CONTRIBUTING.md を新構成・課題管理へ更新（ブロック04）"
```

---

### Task 10: README.md の更新（ブロック04）

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Layer 1 のパスを更新する**

以下をすべて置換する（replace_all）: `docs/principles.md` → `docs/overview/principles.md`（構造テーブルのリンクと「詳細は…参照」の2箇所）。

- [ ] **Step 2: 構造セクションにフォルダ構成定義への案内を追加する**

「## 構造」のレイヤー表の直後に以下を追加する:

```markdown
ドキュメントの配置規範（情報の5分類体系）は [`docs/overview/folder-structure.md`](docs/overview/folder-structure.md) で定義される（ADR-0025）。
```

- [ ] **Step 3: スキル一覧テーブルに organize-inbox を追加する**

`pre-action-review` の行の直後に以下の行を追加する:

```markdown
| [`organize-inbox`](skills/organize-inbox/) | `docs/inbox/` の未分類情報を分類基準に照らして整理する（移動・分割・既存ドキュメントへの統合） |
```

- [ ] **Step 4: コミット**

```bash
git add README.md
git commit -m "docs: README に organize-inbox とフォルダ構成定義を追加（ブロック04）"
```

---

### Task 11: 本リポジトリ docs の移行（ブロック06）

**Files:**
- Move: `docs/specs/*` → `docs/current/specs/`、`docs/plans` → `docs/working/plans`、`docs/handoff` → `docs/working/handoff`、`docs/decisions` → `docs/records/decisions`、`docs/retrospectives` → `docs/records/retrospectives`、`docs/principles.md` → `docs/overview/principles.md`
- Create: `docs/inbox/README.md`、`docs/working/issues/README.md`、`docs/working/issues/0001-template-sync-asymmetry.md`
- Delete: `docs/open-questions.md`（**不可逆操作 — 実行前にユーザー承認を得る**。内容は課題 0001 へ移行済みであることを示して確認する）

- [ ] **Step 1: git mv で移行する**

Git Bash で実行:

```bash
mkdir -p docs/working docs/records
for f in docs/specs/*; do git mv "$f" docs/current/specs/; done
rmdir docs/specs 2>/dev/null || true
git mv docs/plans docs/working/plans
git mv docs/handoff docs/working/handoff
git mv docs/decisions docs/records/decisions
git mv docs/retrospectives docs/records/retrospectives
git mv docs/principles.md docs/overview/principles.md
```

`git status` でリネーム（`renamed:`）として認識されていることを確認する。

- [ ] **Step 2: inbox README を作成する**

`docs/inbox/README.md` を以下の全文で作成する:

```markdown
# inbox

分類先に迷った情報・とりあえず保存したい情報は、このフォルダにファイルとして置く。

- `organize-inbox` スキルが、ここのファイルを分類基準（`../overview/folder-structure.md`）に照らして適切な場所へ整理する（移動・分割・既存ドキュメントへの統合）
- セッション開始時（`start-work`）に未処理ファイルが残っていれば、整理の実行が提案される
- この README 自体は整理の対象外
```

- [ ] **Step 3: 課題インデックスと課題 0001 を作成する**

`docs/working/issues/README.md` を以下の全文で作成する:

```markdown
# 課題（Issues）

進行中・クローズ済みの課題のインデックス。運用ルールは `../../overview/folder-structure.md` の「課題（issue）管理」を参照。

| # | タイトル | Status | Opened |
|---|---------|--------|--------|
| [0001](0001-template-sync-asymmetry.md) | template 同期の非対称性 | closed | 2026-06-15 |
```

`docs/working/issues/0001-template-sync-asymmetry.md` を以下の全文で作成する:

```markdown
# Issue-0001: template 同期の非対称性

- **Status**: closed
- **Opened**: 2026-06-15
- **Closed**: 2026-07-04
- **関連**: ADR-0027

## 課題内容

`sync-template.ps1` は ADRインデックス（旧 `docs/decisions/README.md`）を空生成するが、振り返りインデックス（旧 `docs/retrospectives/README.md`）は repo固有の振り返り履歴行ごと verbatim コピーしてしまう。両インデックスとも新規プロジェクトでは空で始まるべきだが扱いが不揃い（発生源: Theme B コードレビュー, 2026-06-15。旧 `docs/open-questions.md` から移行）。

## 検討状況

フォルダ構成定義サイクル（2026-07-04）で、テンプレート初期セットの基準を定義する際に合わせて検討した。

## 結論

ADR-0027 で空インデックス生成ロジックを一般化し、decisions / retrospectives / issues の3インデックスすべてを空生成する方式に統一して解消した。
```

- [ ] **Step 4: open-questions.md を削除する（要ユーザー承認）**

ユーザーに「内容は課題 0001 へ移行済み。`docs/open-questions.md` を削除してよいか」を確認し、承認後:

```bash
git rm docs/open-questions.md
```

- [ ] **Step 5: 生きているドキュメントのパス表記を更新する**

以下のみ更新する（**過去の ADR・retrospective 本文・完了済み handoff・過去 plan/spec の本文は変更しない**）:

1. `docs/records/retrospectives/README.md` の「運用規約」セクション内のパス表記: `docs/retrospectives/system/` → `docs/records/retrospectives/system/`、`docs/retrospectives/flow/` → `docs/records/retrospectives/flow/`（「一覧」テーブルの過去行と「> 注:」ブロックは変更しない）
2. アクティブな handoff `docs/working/handoff/feature_project-folder-structure.md` 内のパス表記を新構成に更新する（関連ドキュメントのADRパス等）

- [ ] **Step 6: 旧パス参照の残存を確認する**

Grep: `docs/open-questions|docs/handoff/|docs/decisions/|docs/retrospectives/|docs/specs/|docs/plans/|docs/principles.md` を対象 `README.md` `CLAUDE.md` `CONTRIBUTING.md` `skills/` `docs/current/specs/2026-07-04-project-folder-structure/` `docs/working/handoff/feature_project-folder-structure.md` で検索し、ヒットが 0 件であること（過去の記録・過去仕様書・本計画ファイルのヒットは許容）。

- [ ] **Step 7: コミット**

```bash
git add -A
git commit -m "refactor: docs を5分類レイアウトへ移行、open-questions を課題管理へ統合（ブロック06, ADR-0025）"
```

---

### Task 12: template.manifest / sync-template.ps1 の更新（ブロック05）

**Files:**
- Modify: `template.manifest`
- Modify: `scripts/sync-template.ps1`

- [ ] **Step 1: template.manifest を書き換える**

全文を以下に置き換える:

```
# テンプレート対象ファイル（verbatim コピー対象のみ）
# リポジトリ直下のパス → template/ 内に同じパスでコピーされる
#
# 空行・#始まりの行は無視される
# 以下のインデックス3件は manifest に載せず、同期スクリプトが空版を自動生成する（ADR-0027）:
#   docs/records/decisions/README.md
#   docs/records/retrospectives/README.md
#   docs/working/issues/README.md
#
# ADR-0016 により、skills/ 関連エントリは template から除外している
# （スキル本体は GitHub Copilot CLI / Claude Code プラグイン ai-driven-dev-principles から提供されるため）

CLAUDE.md
docs/overview/principles.md
docs/overview/folder-structure.md
docs/inbox/README.md
```

- [ ] **Step 2: sync-template.ps1 の空インデックス生成を一般化する**

ADRインデックス専用の変数（`$adrIndexSource` / `$adrIndexDest`）と生成ブロックを、以下の構成に書き換える:

```powershell
# 空インデックス生成対象（repo固有のデータ行を除去してコピーする。ADR-0027）
$emptyIndexTargets = @(
    "docs/records/decisions/README.md",
    "docs/records/retrospectives/README.md",
    "docs/working/issues/README.md"
)

function New-EmptyIndexContent {
    param([string[]]$Lines)
    # インデックス表のデータ行と、表直後の引用ブロック（repo固有の注記）を除去する。
    # 表ヘッダー・セパレーター・その他の本文は保持する。
    $output = @()
    $state = "normal"   # normal | header-seen | in-data | after-table
    foreach ($line in $Lines) {
        switch ($state) {
            "normal" {
                $output += $line
                if ($line -match '^\|' -and $line -notmatch '^\|[-\s|]+\|$') { $state = "header-seen" }
            }
            "header-seen" {
                if ($line -match '^\|[-\s|]+\|$') { $output += $line; $state = "in-data" }
                else { $output += $line; $state = "normal" }
            }
            "in-data" {
                if ($line -match '^\|') { }                    # データ行: 除去
                else { $state = "after-table"
                       if (-not ($line -match '^>' -or $line -match '^\s*$')) { $output += $line; $state = "normal" } }
            }
            "after-table" {
                if ($line -match '^>') { }                     # 表直後の注記引用: 除去
                elseif ($line -match '^\s*$') { }              # 注記前後の空行: 除去（連続空行防止）
                else { $output += ""; $output += $line; $state = "normal" }
            }
        }
    }
    return $output
}

foreach ($target in $emptyIndexTargets) {
    $sourcePath = Join-Path $repoRoot $target
    $destPath = Join-Path $templateDir $target
    if (-not (Test-Path $sourcePath)) {
        Write-Warning "  ! $target not found, skipping empty index"
        continue
    }
    $destDir = Split-Path -Parent $destPath
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    $outputLines = New-EmptyIndexContent -Lines (Get-Content $sourcePath)
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($destPath, $outputLines, $utf8NoBom)
    Write-Host "  ✓ $target (empty index generated)"
}
```

末尾の合計件数表示は `$files.Count + $emptyIndexTargets.Count` に更新する。manifest 駆動コピー部分・template/ 全削除→再生成・UTF-8 no BOM は変更しない。

- [ ] **Step 3: 同期を実行して結果を検証する**

```powershell
pwsh scripts/sync-template.ps1
```

確認項目:
- `template/CLAUDE.md`、`template/docs/overview/principles.md`、`template/docs/overview/folder-structure.md`、`template/docs/inbox/README.md` が存在する
- `template/docs/records/decisions/README.md`、`template/docs/records/retrospectives/README.md`、`template/docs/working/issues/README.md` が存在し、いずれもインデックス表にデータ行が無い（ヘッダーとセパレーターのみ）。retrospectives の「> 注:」ブロックが含まれていない
- 旧パス（`template/docs/principles.md`、`template/docs/decisions/`、`template/docs/retrospectives/`）が存在しない

- [ ] **Step 4: 冪等性を検証する**

もう一度 `pwsh scripts/sync-template.ps1` を実行し、`git status` で template/ に差分が出ないことを確認する。

- [ ] **Step 5: コミット**

```bash
git add template.manifest scripts/sync-template.ps1 template/
git commit -m "feat: テンプレート初期セット基準の実装と空インデックス生成の一般化（ブロック05, ADR-0027）"
```

---

### Task 13: プラグイン反映と最終検証

**Files:**
- Modify: `docs/records/decisions/0027-template-seed-criteria.md`（Accepted へ昇格）
- Modify: `docs/records/decisions/README.md`（ステータス更新）

- [ ] **Step 1: プラグインを更新して最新スキルを反映する**

Claude Code の場合（このセッションのユーザー環境）:

```
/plugin marketplace update ai-driven-dev-principles
```

Copilot CLI も併用している場合は `copilot plugin update ai-driven-dev-principles` も実行する。反映後、新しいセッションで `organize-inbox` がスキル一覧に現れること・`start-work` の説明文が更新されていることを確認する（確認はユーザーに依頼してよい）。

- [ ] **Step 2: 仕様書の完了基準チェック**

`docs/current/specs/2026-07-04-project-folder-structure/00-overview.md` の「7. 完了基準」8項目を1つずつ確認し、結果をユーザーに報告する。

- [ ] **Step 3: ADR-0027 を Accepted へ昇格する**

`docs/records/decisions/0027-template-seed-criteria.md` の Status を `Accepted` に変更し、`docs/records/decisions/README.md` のテーブルも更新する（実装完了チェックポイント。ADR-0019）。

- [ ] **Step 4: コミット**

```bash
git add docs/records/decisions/0027-template-seed-criteria.md docs/records/decisions/README.md
git commit -m "adr: 0027 を Accepted へ昇格（実装完了）"
```
