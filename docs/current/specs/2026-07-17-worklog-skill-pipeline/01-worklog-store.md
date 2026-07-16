# ブロック01: worklog-store（共有データ層）

## 対象ファイル

- 実行コードは持たない。**データ契約（フォーマット規約）**であり、実体は各スキル doc（02/03/04）が参照・遵守するフォーマット定義として `skills/` 内に記述される（例: スキル1 doc 内の「ストア仕様」節、または共有 reference ファイル `skills/<skill1>/references/store-format.md`。配置は実装時に確定）
- 実行時に生成・更新される物理ファイル群（リポジトリ外・ユーザーのホーム配下）:
  - `<home>/.ai-dev-worklog/projects.json`
  - `<home>/.ai-dev-worklog/<folderName>/log.jsonl`
  - `<home>/.ai-dev-worklog/processed.jsonl`

## 責務

3スキルが共通で読み書きする中央ストアの物理レイアウト・エントリスキーマ・台帳スキーマ・プロジェクト識別子解決規則を、単一の契約として定義する。この契約を変更すると 02/03/04 すべてに影響するため、独立ブロックとして凝集させる。

## インターフェース（各スキルが遵守する操作）

markdown スキルであるため「インターフェース」は関数ではなく、各スキルが行うファイル操作の約束事である。

| 操作 | 主な呼び出し元 | 内容 |
|------|--------------|------|
| プロジェクト識別子解決（upsert） | 02 | 現在の作業ディレクトリのルートフォルダ名をキーに `projects.json` を最新パスへ upsert |
| id 採番 | 02 | `<folderName>/log.jsonl` の末尾を見てその日の連番 NN を決め `<project>-<date>-<NN>` を生成 |
| エントリ追記 | 02 | 検証済みエントリ1件を `<folderName>/log.jsonl` に1行追記 |
| 全エントリ読み取り | 03 | 全 `<folderName>/log.jsonl` を連結して1パス走査 |
| 台帳読み取り | 03 | `processed.jsonl` を読み、処理済み id 集合と deferred レコードを得る |
| 台帳追記 | 03（rejected/deferred）, 04（skillified/merged） | 採否結果を `processed.jsonl` に1行追記 |

## データモデル

### `projects.json`（プロジェクト識別子リスト）

```json
{
  "MakeAiInstructions": { "path": "D:/Dev/002_AiDev/MakeAiInstructions", "lastSeen": "2026-07-17" },
  "LoopForAlpha":       { "path": "D:/Dev/001_Trade/LoopForAlpha",       "lastSeen": "2026-07-18" }
}
```

- キー = 各プロジェクトのルートフォルダ名（実パスは長すぎるので使わない）
- 値 = 現在の絶対パス＋最終更新日

### エントリ（`<folderName>/log.jsonl`、1行1エントリ、追記専用）

必須フィールド（いずれか空なら記録を弾く）:

| フィールド | 型 | 役割 |
|---|---|---|
| `id` | string | `<project>-<date>-<NN>`。台帳との突合キー |
| `date` | string | 記録日（YYYY-MM-DD） |
| `project` | string | 出所プロジェクト名（連結後も行内で出所が分かる） |
| `scope` | enum | `project-specific` / `general-candidate`（record 時は暫定、スキル2が最終確定） |
| `title` | string | 動詞句15文字程度（一覧・重複目視用） |
| `context` | string | 何をしていて、なぜこの作業が発生したか |
| `procedure` | string[] | 実際に踏んだ手順 |

delta ペア（**`friction` または `corrections` の少なくとも一方が必須**）:

| フィールド | 型 | 役割 |
|---|---|---|
| `friction` | string | 躓き型 delta（エラー・手戻り・非自明な試行錯誤） |
| `corrections` | string[] | 注入型 delta（人間が与えた指示・修正を発言に近い形で） |

任意フィールド: `skillification_hint`(string) / `outcome`(enum: success/partial/failed＝**作業結果**) / `tools`(string[]) / `applied_rules`(string[]、逸脱注記可) / `refs`(string[])

### 台帳レコード（`processed.jsonl`、1行1レコード、追記専用）

```jsonl
{"id":"MakeAiInstructions-2026-07-16-01","outcome":"skillified","ref":"skills/xxx","date":"2026-07-20"}
{"id":"LoopForAlpha-2026-07-18-03","outcome":"deferred","evidence_count":2,"date":"2026-07-20"}
```

| フィールド | 型 | 役割 |
|---|---|---|
| `id` | string | 対象エントリまたはクラスタ代表の id |
| `outcome` | enum | `skillified` / `rejected` / `merged` / `deferred`（**採否結果**。エントリ側 `outcome` とは別物） |
| `evidence_count` | number | `deferred` のときのみ。保留時点のクラスタ根拠数（再浮上判定の基準） |
| `ref` | string | 任意。skillified/merged 時の作成先（`skills/...` 等） |
| `date` | string | 台帳追記日 |

## このブロック固有の制約・前提

- ルート名 `<home>/.ai-dev-worklog/` はツール中立名（`~/.claude/` は避ける）。`$HOME`/`%USERPROFILE%` で解決
- **識別子解決の規則**（プロジェクト移動・同名衝突への自己修復）:
  - **upsert**: 記録のたびフォルダ名をキーに実パスを最新へ更新（フォルダ名が同じならプロジェクトを移動しても次回自動修正）
  - **衝突判定**: フォルダ名がリストにあり実パスが違う場合、旧パスがまだ存在→別プロジェクト同名（サフィックス付き別フォルダ＋リスト追加）、旧パスが消失→同一プロジェクト移動（パス更新）
- すべて**追記専用**で in-place 書き換えを避ける（`projects.json` のみ全体読み書きの upsert）
- 中央ストアは `docs/overview/folder-structure.md` の5分類の**管轄外**（リポジトリ外・中央集約のため）。この理由をスキル doc に明記して records 誤解を予防する
- git 管理は v1 ではオプション

## 関連 ADR

- ADR-0044（中央集約・識別子スキーム）
- ADR-0045（エントリ/台帳スキーマ・ライフサイクル）
