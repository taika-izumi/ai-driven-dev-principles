---
name: worklog-record
description: "作業の節目（スキル完了・plan タスク完了・重要な分岐通過）で、AI のデフォルト挙動と実際に必要だったことの差分（delta）を中央ストアへ1件記録する。start-work の Post ラッパーから発火。記録ゲート（既存スキルで実施済みでない かつ AI 自律で毎回再現できない）を満たす場合のみ追記する。"
---

# worklog-record

AI に作業させた後の節目で、その作業の delta（差分）を核とするコンパクトな構造化エントリを1件、中央ストア `<home>/.ai-dev-worklog/` へ追記する。full context を持つメインエージェント本人が書く。横断的な重い分析（頻度判定・重複排除）はここではやらず、`worklog-extract` へ遅延する。

## いつ使うか

`start-work` の Post ラッパーから、`session-handoff` update と同じマイルストーン契機で呼ばれる（ADR-0047 により全プロジェクトへ伝播）。手動起動も可。

マイルストーン契機:

- スキルの完了
- plan の 1 タスク完了
- 重要な分岐の通過

タスクごとの継続的インラインログはしない（節目でのみ発火）。

## 記録ゲート判定

以下の**両方**を満たすときのみ記録する（片方でも欠ければ記録しない）:

- (a) 既存スキル・原則・CLAUDE.md で既に実施している作業では**ない**
- (b) AI が自律判断でも毎回同じに確実に再現できる作業では**ない**

判定の実効ルール = **delta（`friction` または `corrections`）が少なくとも一方存在するか**。両方空なら「AI が自律で毎回再現できた作業」＝記録不要として弾く（純粋判断型は記録しない）。

## 手順

1. **記録ゲート判定**: delta の有無を検査。不成立なら「記録なし」で終了
2. **delta 抽出**:
   - `friction`（string）: 躓き型 = エラー・手戻り・非自明な試行錯誤を1〜2行で
   - `corrections`（string[]）: 注入型 = 人間が注入した指示・修正を発言に近い形で1〜2行ずつ
3. **識別子解決**（`references/store-format.md` の upsert 規則）:
   - 現在の作業ディレクトリのルートフォルダ名をキーに `projects.json` を upsert
   - **初回**は `<home>/.ai-dev-worklog/` ディレクトリと `projects.json`・`<folderName>/log.jsonl` を新規作成
   - `lastSeen` は今日の日付（YYYY-MM-DD）で毎回上書き
   - 衝突（同名別プロジェクト・移動）の判定は `references/store-format.md` に従う
4. **id 採番**（`references/store-format.md` の採番アルゴリズム）:
   - 同一 `project` かつ同一 `date` のエントリ数 + 1 を2桁ゼロ埋めして NN
   - `id = "<project>-<date>-<NN>"`
5. **scope 暫定タグ付け**: `project-specific` / `general-candidate` を記録時点の判断で付ける（`worklog-extract` が横断視点で最終確定）
6. **エントリ構築と検証**:
   - 必須フィールド（`id` / `date` / `project` / `scope` / `title` / `context` / `procedure`）を埋める
   - delta 必須（`friction` または `corrections` の少なくとも一方）を検証
   - 任意フィールド（`skillification_hint` / `outcome` / `tools` / `applied_rules` / `refs`）は関連あれば付ける
   - `<folderName>/log.jsonl` へ1行 append

### コンパクトさの規律

- 各フィールド原則1〜2行
- `corrections` は人間の発言に近い形で（規約・好みがスキルの原文になるため）
- `title` は動詞句15文字程度

## エントリ例

```jsonl
{"id":"MakeAiInstructions-2026-07-17-01","date":"2026-07-17","project":"MakeAiInstructions","scope":"general-candidate","title":"AskUserQuestion 前に環境変数を確認","context":"start-work Phase 1 で構造化質問ツールを使う前に、ADR-0036 の運用チェックを実行","procedure":["Bash: echo $CLAUDE_CODE_DISABLE_MOUSE_CLICKS","値が 1 であることを確認してから AskUserQuestion 発行"],"corrections":["構造化質問ツール使用前に環境変数の値を確認すること"],"applied_rules":["ADR-0036"]}
```

## ストア仕様

中央ストアの物理レイアウト・スキーマ・upsert 規則の正典は `references/store-format.md`。本スキルおよび `worklog-extract` / `worklog-skillify` はこれを参照する。

中央ストアはリポジトリ外・中央集約であり、`docs/overview/folder-structure.md` の5分類の**管轄外**である（records と混同しないこと）。

## 対応する原則

- **原則1（追跡可能性）**: AI の作業 delta を単一のジャーナルとして永続化する
- **原則2（関心の分離）**: 記録（軽い・オンライン）と横断分析（重い・オフライン）を分離し、重い分析は `worklog-extract` へ遅延する

## 関連 ADR

- ADR-0044（記録ゲート・スキル1/2 責務境界・scope 暫定タグ）
- ADR-0045（エントリスキーマ・delta 核心・id 採番・adopted 含む台帳ライフサイクル）
- ADR-0047（start-work Post への配線・全プロジェクト伝播）
