# 中央ストア フォーマット（worklog パイプライン共有契約）

3スキル（worklog-record / worklog-extract / worklog-skillify）が共通で読み書きする中央ストアの契約。これを変更すると3スキルすべてに影響する。

## 配置

- ルート: `<home>/.ai-dev-worklog/`（`$HOME` / `%USERPROFILE%` で解決。ツール中立名）
- `<home>/.ai-dev-worklog/projects.json` — プロジェクト識別子リスト
- `<home>/.ai-dev-worklog/<folderName>/log.jsonl` — プロジェクトごとの作業ログ（追記専用）
- `<home>/.ai-dev-worklog/processed.jsonl` — 処理済み台帳（追記専用）

このストアはリポジトリ外・中央集約であり、`docs/overview/folder-structure.md` の5分類の**管轄外**である（records と混同しないこと）。

## projects.json

```json
{
  "MakeAiInstructions": { "path": "D:/Dev/002_AiDev/MakeAiInstructions", "lastSeen": "2026-07-17" }
}
```

- キー = プロジェクトのルートフォルダ名（実パスは使わない）
- 値 = 現在の絶対パス＋最終更新日（YYYY-MM-DD）

### 識別子解決の規則

- **upsert（自己修復）**: 記録のたび、フォルダ名をキーに実パスを最新へ更新。フォルダ名が同じならプロジェクトを移動しても次回自動修正される
- **衝突判定**: フォルダ名がリストにあり実パスが違う場合 —
  - 旧パスがまだ存在 → 別プロジェクトの同名（フォルダ名にサフィックスを付けて別エントリを追加）
  - 旧パスが消失 → 同一プロジェクトの移動（パスを更新）

## エントリ（log.jsonl、1行1エントリ、追記専用）

必須（いずれか空なら記録を弾く）: `v` / `id` / `date` / `project` / `model` / `scope` / `title` / `context` / `procedure`
delta ペア（`friction` または `corrections` の少なくとも一方が必須）: `friction` / `corrections`
任意: `skillification_hint` / `outcome`（success/partial/failed＝作業結果）/ `tools` / `applied_rules`（逸脱注記可）/ `refs`

| フィールド | 型 | 説明 |
|---|---|---|
| `v` | number | スキーマ版数。現行は `2`（ADR-0049） |
| `id` | string | `<project>-<date>-<NN>`。台帳との突合キー |
| `date` | string | YYYY-MM-DD |
| `project` | string | 出所プロジェクト名（連結後も行内で出所が分かる） |
| `model` | string | delta 発生元の AI モデル ID（例 `"claude-fable-5"`。記録時と異なる場合は発生元を優先）。モデル固有か全モデル共通かの判別材料（ADR-0048） |
| `scope` | enum | `project-specific` / `general-candidate`（record 時は暫定） |
| `title` | string | 動詞句15文字程度 |
| `context` | string | 何をしていてなぜ発生したか |
| `procedure` | string[] | 実際に踏んだ手順 |
| `friction` | string[] | 躓き型 delta。複数の躓きは要素を分ける（ADR-0051） |
| `corrections` | string[] | 注入型 delta（人間の指示・修正を発言に近い形で） |

### スキーマ版数と互換読み（ADR-0049 / ADR-0051）

- 書き込み側は常に現行版数 `"v":2` を必ず書く（台帳レコードも同様）
- 読み側規約: **`v` フィールドなしの行 = v1（初版スキーマ）と解釈する**。v1 行は `model` なしを許容し、`friction`（string）は 1 要素配列として読み替える
- 既存の v1 行は書き換えない（追記専用）
- 注: サイクル名「worklog v1.1」はパイプライン全体の改訂名であり、スキーマ版数 `v`（現行 2）とは別物

### 記録単位（ADR-0053）

1 エントリ = **同一 `context`（作業テーマ）を共有する delta の束**。

- 同一作業内の複数の躓きは `friction` の要素として列挙する
- 節目に独立した作業テーマの delta が複数あれば、テーマごとに複数エントリを記録してよい
- 「どれを捨てるか」の優先順位判断はしない（ノイズ抑制は記録ゲート＝delta の存在が担う）

### id 採番アルゴリズム（ADR-0050 で強化）

1. `date` = 今日（YYYY-MM-DD）、`project` = フォルダ名
2. **追記の直前に** `<folderName>/log.jsonl` を読む（無ければ NN=01）
3. 同一 `project` かつ同一 `date` のエントリ数を数え、その数+1 を2桁ゼロ埋めして NN とする
4. `id = "<project>-<date>-<NN>"` で 1 行追記する
5. **追記後に log.jsonl を読み直し、自行の id が他エントリと重複していないか検証する**（ADR-0038 の読み直し規範と整合）。重複を検出した場合、**自分が書いた行のみ id を再採番して書き直す**（追記専用原則の唯一の例外。台帳突合レコードが発生する前・自分が書いた直後の行の修復に限るため安全）

> 注: ADR-0045 / spec 01 の旧記述「末尾を見て採番」の改善版（ADR-0050）。並行セッションの採番競合（Issue-0027）に対し、直前再カウントで競合窓を縮め、読み直し検証で検出・回復する。加えて末尾1行だけでなく同一 date 全件をカウントすることで、順序が乱れた場合でも正しい NN が決まる。

## 台帳レコード（processed.jsonl、1行1レコード、追記専用）

```jsonl
{"v":2,"id":"MakeAiInstructions-2026-07-16-01","outcome":"adopted","date":"2026-07-16"}
{"v":2,"id":"MakeAiInstructions-2026-07-16-01","outcome":"skillified","ref":"skills/xxx","date":"2026-07-20"}
{"v":2,"id":"LoopForAlpha-2026-07-18-03","outcome":"deferred","evidence_count":2,"date":"2026-07-20"}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `v` | number | スキーマ版数。現行は `2`。`v` なしの行は v1 と解釈する（ADR-0049） |
| `id` | string | 対象エントリまたはクラスタ代表の id |
| `outcome` | enum | `adopted` / `skillified` / `rejected` / `merged` / `deferred`（**採否結果**。エントリ側 outcome とは別物。状態遷移: `adopted` → `skillified` または `merged`） |
| `evidence_count` | number | `deferred` のときのみ。保留時点のクラスタ根拠数 |
| `ref` | string | 任意。skillified/merged 時の作成先 |
| `date` | string | 台帳追記日 |

すべて追記専用で in-place 書き換えを避ける（projects.json のみ全体読み書きの upsert）。状態遷移は同一 id の後続レコード追記で表現し、読み側は最新レコードの outcome を採用する。git 管理は v1 ではオプション。

**`adopted` の意義**: skill2 が採用した候補は skill3 完了までの窓（別セッション持ち越し・環境ガード発火・中断）で台帳未登録になる穴がある。skill2 採用時に即 `adopted` を追記し、次回 skill2 で処理済み扱いとして除外することで穴を厳密層で捕捉する。
