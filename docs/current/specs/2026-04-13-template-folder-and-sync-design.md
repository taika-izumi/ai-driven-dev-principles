# テンプレートフォルダと同期メカニズムの設計

## 課題

新しいプロジェクトへの転用時に手作業が多い（フォルダコピー2回、フォルダ作成1回、ADRインデックスのコピーとエントリ削除）。
この手間を減らし、テンプレートフォルダからのコピー1回で転用を完了できるようにする。

## 提案

リポジトリ内に `template/` フォルダを設け、新プロジェクトに必要なファイル一式を格納する。
マニフェストファイルで対象ファイルを管理し、同期スクリプトでリポジトリ直下からテンプレートフォルダへの一方向同期を行う。

## 設計

### テンプレートフォルダ構造

```
template/
├── .github/
│   └── copilot-instructions.md
├── docs/
│   ├── decisions/
│   │   └── README.md          ← 空のADRインデックス（エントリなし）
│   └── principles.md
└── skills/
    ├── decision-log/
    │   └── SKILL.md
    └── pre-action-review/
        └── SKILL.md
```

テンプレートに **含めないもの**:
- `CONTRIBUTING.md` — 拡張ルールはこのリポジトリ専用
- `skills/extend-guidelines/` — ゲートウェイスキルはこのリポジトリの運用専用
- `docs/specs/`, `docs/plans/`, ADR本体 — 開発経緯
- `README.md` — テンプレート用のREADMEは不要（利用者はコピー前にリポジトリ直下のREADMEを参照する）

### マニフェストファイル

ファイル: `template.manifest`（リポジトリ直下）

```
# テンプレート対象ファイル
# リポジトリ直下のパス → template/ 内に同じパスでコピーされる
#
# 空行・#始まりの行は無視される

.github/copilot-instructions.md
docs/principles.md
skills/decision-log/SKILL.md
skills/pre-action-review/SKILL.md
```

仕様:
- 1行1ファイル、リポジトリルートからの相対パスで記述
- `#` で始まる行はコメント、空行は無視
- ADRインデックス（`docs/decisions/README.md`）はマニフェストに含めない（スクリプトが空版を自動生成する）

### 同期スクリプト

ファイル: `scripts/sync-template.ps1`

動作（完全同期方式）:
1. `template/` フォルダが存在すれば **完全に削除**
2. `template.manifest` を読み込み、コメント行・空行をスキップ
3. マニフェストに記載された各ファイルをリポジトリ直下から `template/` 配下の同じパスにコピー（ディレクトリは自動作成）
4. ADRインデックスを特別処理: リポジトリ直下の `docs/decisions/README.md` からヘッダー部分（タイトル・説明・判定基準・テーブルヘッダー行・セパレーター行）のみを抽出し、データ行（`| [NNNN]...`）を除外した空版を `template/docs/decisions/README.md` に生成
5. 完了時にコピーしたファイル一覧を表示

保証:
- **冪等性**: 何度実行しても同じ結果になる
- **クリーン性**: マニフェストから除外されたファイルの残骸が残らない
- **一方向**: リポジトリ直下 → テンプレートへの一方向同期（リポジトリ直下が正）

出力例:
```
[sync-template] Cleaning template/ ...
[sync-template] Reading template.manifest...
[sync-template] Syncing 4 files + ADR index...
  ✓ .github/copilot-instructions.md
  ✓ docs/principles.md
  ✓ skills/decision-log/SKILL.md
  ✓ skills/pre-action-review/SKILL.md
  ✓ docs/decisions/README.md (empty index generated)
[sync-template] Done. 5 files synced to template/
```

### 既存ファイルの更新

#### CONTRIBUTING.md — シナリオ3「Skill作成」

「手順」セクションにテンプレート判定ステップを追加:

1. 上の判定表でSkill化が適切か確認する
2. `skills/<skill-name>/SKILL.md` を作成する（YAMLフロントマター + markdown本文）
3. 対応する原則との紐付けをSkill内に記載する
4. テンプレート対象か判断する: 新プロジェクトで汎用的に使えるSkillなら `template.manifest` に追加する。このリポジトリの運用専用Skillなら追加しない
5. テンプレート対象の場合、`scripts/sync-template.ps1` を実行してテンプレートフォルダを同期する
6. ADRで作成理由を記録する

#### extend-guidelines SKILL.md — テンプレート同期案内の追加

ステップ4（brainstorming開始）の後にステップ5を追加:
「テンプレートに影響する変更（原則・copilot-instructions・テンプレート対象スキルの変更）がある場合は `scripts/sync-template.ps1` を実行してテンプレートフォルダを同期してください」と案内する。

#### README.md — 「新しいプロジェクトでの使い方」セクションの簡素化

現在の4ステップ手順を以下に置き換え:

1. `template/` フォルダの中身を新プロジェクトのルートにコピーする
2. `copilot-instructions.md` にプロジェクト固有の指示を追記する

## ワークフロー

### 新プロジェクトへの転用

```
template/ の中身をコピー → copilot-instructions.md にプロジェクト固有の指示を追記 → 完了
```

### ガイドライン拡張時の同期

```
extend-guidelines 実行 → 原則/スキル/指示を改修 → sync-template.ps1 実行 → テンプレートに反映 → コミット
```

### 新しいスキル追加時

```
Skill作成 → テンプレート対象か判定（CONTRIBUTING.md参照）
  → 対象: template.manifest に追加 → sync-template.ps1 実行
  → 非対象: マニフェスト変更なし
```

## 成果物一覧

| 種別 | ファイル | 説明 |
|------|---------|------|
| 新規 | `template/`（フォルダ + 中身一式） | 新プロジェクト用テンプレート |
| 新規 | `template.manifest` | テンプレート対象ファイルの定義 |
| 新規 | `scripts/sync-template.ps1` | マニフェストベースの完全同期スクリプト |
| 更新 | `CONTRIBUTING.md` | シナリオ3にテンプレート判定ステップ追加 |
| 更新 | `skills/extend-guidelines/SKILL.md` | テンプレート同期案内ステップ追加 |
| 更新 | `README.md` | 「新しいプロジェクトでの使い方」簡素化 |
