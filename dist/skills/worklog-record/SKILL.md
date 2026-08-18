---
name: worklog-record
description: "作業の節目（スキル完了・plan タスク完了・重要な分岐通過）とセッション切り替え直前で、AI のデフォルト挙動と実際に必要だったことの差分（delta）を中央ストアへ1件記録する。start-work の Post ラッパーおよびセッション終了処理から発火。記録ゲート（既存スキルで実施済みでない かつ AI 自律で毎回再現できない）を満たす場合のみ追記する。"
---

# worklog-record

AI に作業させた後の節目で、その作業の delta（差分）を核とするコンパクトな構造化エントリを1件、中央ストア `<home>/.ai-dev-worklog/` へ追記する。full context を持つメインエージェント本人が書く。横断的な重い分析（頻度判定・重複排除）はここではやらず、`worklog-extract` へ遅延する。

## いつ使うか

`start-work` の Post ラッパーから、`session-handoff` update と同じマイルストーン契機で呼ばれる（全プロジェクトへ伝播している）。手動起動も可。

マイルストーン契機:

- スキルの完了
- plan の 1 タスク完了
- 重要な分岐の通過
- セッション切り替え・コンテキスト逼迫による中断の直前（節目かどうかを問わない。`start-work` のセッション終了処理から `session-handoff` finalize の前に発火する。判定条件は利用者による終了・切替の明示指示または終了処理への到達とし、コンテキスト残量そのものは判定条件にしない）

タスクごとの継続的インラインログはしない（上記契機でのみ発火）。

発火結果（記録したエントリ id、または記録ゲートによる棄却の旨）は、handoff の「Post ラッパー消化記録」へ1行残す（記載の形式と棄却時の記載義務は `session-handoff` update の消化記録手順が正）。

## 記録ゲート判定

以下の**両方**を満たすときのみ記録する（片方でも欠ければ記録しない）:

- (a) 既存スキル・原則・CLAUDE.md で既に実施している作業では**ない**
- (b) AI が自律判断でも毎回同じに確実に再現できる作業では**ない**

判定の実効ルール = **delta（`friction` または `corrections`）が少なくとも一方存在するか**。両方空なら「AI が自律で毎回再現できた作業」＝記録不要として弾く（純粋判断型は記録しない）。

## 記録単位

1 エントリ = **同一 `context`（作業テーマ）を共有する delta の束**。同一作業内の複数の躓きは `friction` の要素として列挙し、節目に独立した作業テーマの delta が複数あれば、テーマごとに複数エントリを記録してよい。「どれを捨てるか」の優先順位判断はしない（ノイズ抑制は記録ゲートが担う）。

## 手順

1. **記録ゲート判定**: delta の有無を検査。不成立なら「記録なし」で終了
2. **delta 抽出**:
   - `friction`（string[]）: 躓き型 = エラー・手戻り・非自明な試行錯誤を要素ごとに1〜2行で。複数の躓きは要素を分ける。損失が大きかった場合は規模感（手戻り回数・時間ロス等）を本文に含めてよい
   - `corrections`（string[]）: 注入型 = 人間が注入した指示・修正を発言に近い形で1〜2行ずつ。**AI の当初挙動（指示がなければ何をしようとしていたか）が自明でなければ `context` に 1 行添える**
3. **識別子解決**（`references/store-format.md` の upsert 規則）:
   - 現在の作業ディレクトリのルートフォルダ名をキーに `projects.json` を upsert
   - **初回**は `<home>/.ai-dev-worklog/` ディレクトリと `projects.json`・`<folderName>/log.jsonl` を新規作成
   - `lastSeen` は今日の日付（YYYY-MM-DD）で毎回上書き
   - 衝突（同名別プロジェクト・移動）の判定は `references/store-format.md` に従う
4. **id 採番**（`references/store-format.md` の採番アルゴリズム）:
   - **追記直前に** log.jsonl を読み直し、同一 `project` かつ同一 `date` のエントリ数 + 1 を2桁ゼロ埋めして NN
   - `id = "<project>-<date>-<NN>"`
5. **scope 暫定タグ付け**: `project-specific` / `general-candidate` を記録時点の判断で付ける（`worklog-extract` が横断視点で最終確定）
6. **エントリ構築と検証**:
   - 必須フィールド（`v`＝現行 `2` / `id` / `date` / `project` / `model`＝delta 発生元の AI モデル ID / `scope` / `title` / `context` / `procedure`）を埋める
   - delta 必須（`friction` または `corrections` の少なくとも一方）を検証
   - 任意フィールド（`skillification_hint` / `outcome` / `tools` / `applied_rules` / `refs`）は関連あれば付ける
   - `<folderName>/log.jsonl` へ1行 append（UTF-8・BOM なし・LF 固定）。**`Add-Content` は使わない**（Windows で CRLF を書き契約に違反する）。Python は `open(path, "a", encoding="utf-8", newline="\n")`、POSIX シェルは `>>`。手段の一覧と根拠は `references/store-format.md` の「エンコーディング・改行コード」を参照
   - **追記後に log.jsonl を読み直し、自行の id 重複がないか検証する**。重複時は自行のみ再採番して書き直す

### コンパクトさの規律

- 各フィールド原則1〜2行
- `corrections` は人間の発言に近い形で（規約・好みがスキルの原文になるため）
- `title` は動詞句15文字程度

## エントリ例

```jsonl
{"v":2,"id":"X-2026-07-17-01","date":"2026-07-17","project":"X","model":"claude-fable-5","scope":"general-candidate","title":"生成物の同期を確認してからコミット","context":"配布物の生成元ファイルを変更した後、生成スクリプトの実行を忘れてコミットしかけた","procedure":["生成元を変更したら生成スクリプトを実行する","git status で生成物の差分がステージ済みか確認してからコミットする"],"corrections":["生成元と生成物は同じコミットに含めること"],"applied_rules":["ADR-NNNN"]}
```

## ストア仕様

中央ストアの物理レイアウト・スキーマ・upsert 規則の正典は `references/store-format.md`。本スキルおよび `worklog-extract` / `worklog-skillify` はこれを参照する。

中央ストアはリポジトリ外・中央集約であり、`docs/overview/folder-structure.md` の5分類の**管轄外**である（records と混同しないこと）。

## 対応する原則

- **原則1（追跡可能性）**: AI の作業 delta を単一のジャーナルとして永続化する
- **原則2（関心の分離）**: 記録（軽い・オンライン）と横断分析（重い・オフライン）を分離し、重い分析は `worklog-extract` へ遅延する
