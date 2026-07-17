# ブロック01: worklog-store（共有データ層）

## 対象ファイル

- 実行コードは持たない。**データ契約（フォーマット規約）**であり、実体は各スキル doc（02/03/04）が参照・遵守するフォーマット定義として `skills/` 内に記述される。正典は共有 reference ファイル `skills/worklog-record/references/store-format.md` に置き、skill2/skill3 doc はこれを参照する
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
| id 採番 | 02 | 追記直前に `<folderName>/log.jsonl` を再読みしてその日の連番 NN を決め `<project>-<date>-<NN>` を生成。追記後に読み直して自行の id 重複を検証（ADR-0050） |
| エントリ追記 | 02 | 検証済みエントリ1件を `<folderName>/log.jsonl` に1行追記 |
| 全エントリ読み取り | 03 | 全 `<folderName>/log.jsonl` を連結して1パス走査 |
| 台帳読み取り | 03 | `processed.jsonl` を読み、処理済み id 集合と deferred レコードを得る |
| 台帳追記 | 03（adopted/rejected/deferred）, 04（skillified/merged） | 採否結果を `processed.jsonl` に1行追記。追記専用のため状態遷移は同一 id の後続レコード追記で表現 |

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
| `v` | number | スキーマ版数。現行は `2`（ADR-0049） |
| `id` | string | `<project>-<date>-<NN>`。台帳との突合キー |
| `date` | string | 記録日（YYYY-MM-DD） |
| `project` | string | 出所プロジェクト名（連結後も行内で出所が分かる） |
| `model` | string | 記録時の AI モデル ID（例 `"claude-fable-5"`）。モデル固有か全モデル共通かの判別材料（ADR-0048） |
| `scope` | enum | `project-specific` / `general-candidate`（record 時は暫定、スキル2が最終確定） |
| `title` | string | 動詞句15文字程度（一覧・重複目視用） |
| `context` | string | 何をしていて、なぜこの作業が発生したか |
| `procedure` | string[] | 実際に踏んだ手順 |

delta ペア（**`friction` または `corrections` の少なくとも一方が必須**）:

| フィールド | 型 | 役割 |
|---|---|---|
| `friction` | string[] | 躓き型 delta（エラー・手戻り・非自明な試行錯誤）。複数の躓きは要素を分ける（ADR-0051） |
| `corrections` | string[] | 注入型 delta（人間が与えた指示・修正を発言に近い形で） |

任意フィールド: `skillification_hint`(string) / `outcome`(enum: success/partial/failed＝**作業結果**) / `tools`(string[]) / `applied_rules`(string[]、逸脱注記可) / `refs`(string[])

### 台帳レコード（`processed.jsonl`、1行1レコード、追記専用）

```jsonl
{"v":2,"id":"MakeAiInstructions-2026-07-16-01","outcome":"skillified","ref":"skills/xxx","date":"2026-07-20"}
{"v":2,"id":"LoopForAlpha-2026-07-18-03","outcome":"deferred","evidence_count":2,"date":"2026-07-20"}
```

| フィールド | 型 | 役割 |
|---|---|---|
| `v` | number | スキーマ版数。現行は `2`。`v` なしの行は v1 と解釈する（ADR-0049） |
| `id` | string | 対象エントリまたはクラスタ代表の id |
| `outcome` | enum | `adopted` / `skillified` / `rejected` / `merged` / `deferred`（**採否結果**。エントリ側 `outcome` とは別物。状態遷移: `adopted` → `skillified` または `merged`） |
| `evidence_count` | number | `deferred` のときのみ。保留時点のクラスタ根拠数（再浮上判定の基準） |
| `ref` | string | 任意。skillified/merged 時の作成先（`skills/...` 等） |
| `date` | string | 台帳追記日 |

## このブロック固有の制約・前提

- ルート名 `<home>/.ai-dev-worklog/` はツール中立名（`~/.claude/` は避ける）。`$HOME`/`%USERPROFILE%` で解決
- **識別子解決の規則**（プロジェクト移動・同名衝突への自己修復）:
  - **upsert**: 記録のたびフォルダ名をキーに実パスを最新へ更新（フォルダ名が同じならプロジェクトを移動しても次回自動修正）
  - **衝突判定**: フォルダ名がリストにあり実パスが違う場合、旧パスがまだ存在→別プロジェクト同名（サフィックス付き別フォルダ＋リスト追加）、旧パスが消失→同一プロジェクト移動（パス更新）
- すべて**追記専用**で in-place 書き換えを避ける（`projects.json` のみ全体読み書きの upsert）。状態遷移は同一 id の後続レコード追記で表現し、読み側は最新レコードの `outcome` を採用する
- **スキーマ版数**: 全レコードに `v`（現行 `2`）を必須で書く。読み側規約「`v` なし = v1」。v1 行は `model` なしを許容し `friction`（string）を 1 要素配列と読み替える（ADR-0049/0051）。サイクル名「worklog v1.1」とスキーマ版数 `v` は別物
- **追記専用の唯一の例外**: id 採番の読み直し検証で自行の id 重複を検出した場合に限り、自分が書いた直後の行を再採番して書き直してよい（ADR-0050）
- **`adopted` の意義**: skill2 が採用した候補は skill3 完了までの窓（別セッション持ち越し・環境ガード発火・中断）で台帳未登録になる穴がある。skill2 採用時に即 `adopted` を追記し、次回 skill2 で処理済み扱いとして除外することでこの窓を厳密層で捕捉する（ADR-0045 追補）
- 中央ストアは `docs/overview/folder-structure.md` の5分類の**管轄外**（リポジトリ外・中央集約のため）。この理由をスキル doc に明記して records 誤解を予防する
- git 管理は v1 ではオプション

## 関連 ADR

- ADR-0044（中央集約・識別子スキーム）
- ADR-0045（エントリ/台帳スキーマ・ライフサイクル）
- ADR-0048〜0053（v1.1 改訂: model 必須・スキーマ版数 v・id 採番強化・friction string[]・運用ガイド・記録単位）
