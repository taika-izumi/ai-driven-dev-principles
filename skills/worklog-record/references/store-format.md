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

必須（いずれか空なら記録を弾く）: `id` / `date` / `project` / `scope` / `title` / `context` / `procedure`
delta ペア（`friction` または `corrections` の少なくとも一方が必須）: `friction` / `corrections`
任意: `skillification_hint` / `outcome`（success/partial/failed＝作業結果）/ `tools` / `applied_rules`（逸脱注記可）/ `refs`

| フィールド | 型 | 説明 |
|---|---|---|
| `id` | string | `<project>-<date>-<NN>`。台帳との突合キー |
| `date` | string | YYYY-MM-DD |
| `project` | string | 出所プロジェクト名（連結後も行内で出所が分かる） |
| `scope` | enum | `project-specific` / `general-candidate`（record 時は暫定） |
| `title` | string | 動詞句15文字程度 |
| `context` | string | 何をしていてなぜ発生したか |
| `procedure` | string[] | 実際に踏んだ手順 |
| `friction` | string | 躓き型 delta |
| `corrections` | string[] | 注入型 delta（人間の指示・修正を発言に近い形で） |

### id 採番アルゴリズム

1. `date` = 今日（YYYY-MM-DD）、`project` = フォルダ名
2. `<folderName>/log.jsonl` を読む（無ければ NN=01）
3. 同一 `project` かつ同一 `date` のエントリ数を数え、その数+1 を2桁ゼロ埋めして NN とする
4. `id = "<project>-<date>-<NN>"`

> 注: ADR-0045 / spec 01 の記述「末尾を見て採番」の**改善版**。末尾1行だけでなく同一 date 全件をカウントすることで、順序が乱れた場合でも正しい NN が決まる。両表現は同等の意図で本アルゴリズムを正典とする。

## 台帳レコード（processed.jsonl、1行1レコード、追記専用）

```jsonl
{"id":"MakeAiInstructions-2026-07-16-01","outcome":"adopted","date":"2026-07-16"}
{"id":"MakeAiInstructions-2026-07-16-01","outcome":"skillified","ref":"skills/xxx","date":"2026-07-20"}
{"id":"LoopForAlpha-2026-07-18-03","outcome":"deferred","evidence_count":2,"date":"2026-07-20"}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `id` | string | 対象エントリまたはクラスタ代表の id |
| `outcome` | enum | `adopted` / `skillified` / `rejected` / `merged` / `deferred`（**採否結果**。エントリ側 outcome とは別物。状態遷移: `adopted` → `skillified` または `merged`） |
| `evidence_count` | number | `deferred` のときのみ。保留時点のクラスタ根拠数 |
| `ref` | string | 任意。skillified/merged 時の作成先 |
| `date` | string | 台帳追記日 |

すべて追記専用で in-place 書き換えを避ける（projects.json のみ全体読み書きの upsert）。状態遷移は同一 id の後続レコード追記で表現し、読み側は最新レコードの outcome を採用する。git 管理は v1 ではオプション。

**`adopted` の意義**: skill2 が採用した候補は skill3 完了までの窓（別セッション持ち越し・環境ガード発火・中断）で台帳未登録になる穴がある。skill2 採用時に即 `adopted` を追記し、次回 skill2 で処理済み扱いとして除外することで穴を厳密層で捕捉する。
