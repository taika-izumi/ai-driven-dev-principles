---
name: worklog-extract
description: "中央ストアに蓄積された作業ログをオンデマンドで走査し、スキル化・ルール化する価値のある候補をクラスタリング・評価してランク付き候補リストとして人間に提示する。処理済み台帳で既処理を除外し、人間の採否を Issue 草案と台帳へ反映する。ユーザーが明示的に実行するスキル。"
---

# worklog-extract

中央ストア `<home>/.ai-dev-worklog/` に蓄積された作業ログ（`log.jsonl`）を横断で走査し、スキル化・ルール化する価値のある候補をランク付きリストとして人間に提示する。人間の採否を `processed.jsonl` 台帳と Issue 草案へ反映し、採用したものは `worklog-skillify` へ受け渡す。

## いつ使うか

**ユーザーがオンデマンドで実行するスキル**（自動起動しない）。開発サイクルの節目・retrospective の準備・スキル体系の棚卸しなどでユーザーが呼ぶ。

## 入力

- 中央ストア: `<home>/.ai-dev-worklog/`
  - `projects.json`（識別子リスト）
  - 全プロジェクトの `<folderName>/log.jsonl`（作業ログ）
  - `processed.jsonl`（処理済み台帳）

中央ストアのフォーマット・スキーマの正典は `skills/worklog-record/references/store-format.md`。本スキルはこれを参照する。

## 手順

1. **台帳前処理**: `processed.jsonl` を読み、処理済み id（`adopted` / `skillified` / `rejected` / `merged`）を分析対象から除外する。`deferred` は `evidence_count` とともに保持（分析コストは未処理エントリ数でスケール）
2. **ストア健全性検証 → サブエージェント走査**: 走査に先立ち、`scripts/check-store-health.py` を実行してストアのバイト健全性（UTF-8・BOM なし・LF 固定・全行 JSON パース可能）を検証する。実行は `python <skill-dir>/scripts/check-store-health.py` で、終了コード 0 が健全、1 が違反あり。grep 系では CR を検出できないためスクリプトを使うこと。BOM・CRLF・非 UTF-8 を検出したら**報告して停止**し、既存行の正規化（BOM 除去・CRLF→LF、内容は不変）は**ユーザーの明示 opt-in でのみ**実行する（ADR-0054。silent tolerance はしない）。健全性を確認後、全 `log.jsonl` を1パスで読み、類似エントリをクラスタリングする（メインコンテキストに載せない。原則3の関心分離）。読み込み時はスキーマ版数の互換規約に従う: **`v` なし行 = v1 と解釈し、v1 の `friction`（string）は 1 要素配列として読み替える**（ADR-0049/0051）

   検査スクリプト自体を変更したときは `--self-test` を実行し、正の対照 4 件が発火し負の対照が誤検出しないことを確認してから使うこと（検査が緑であることの意味を保つため。LoopForAlpha#Issue-0084）
3. **クラスタ評価**: 横断再発回数・出所プロジェクト数・`friction` / `corrections` の重みを集計する。`model` フィールドにより「特定モデル固有の躓きか、全モデル共通か」を判断材料に加える（ADR-0048。v1 行は model 不明として扱う）
4. **scope 再判定**: ≥2プロジェクトで再発するクラスタは `general-candidate` へ格上げ、単一プロジェクト・ドメイン依存は `project-specific` に確定（record 時の暫定タグを最終確定）
5. **既存スキル重複排除**: superpowers ＋ ai-driven-dev-principles ＋ プロジェクトローカル（`.claude/skills/`）の description と突合し、既存済みは除外（あいまい層）
6. **deferred 再浮上判定**: 台帳の代表 id を含む現在のクラスタを当該 deferred クラスタとして再同定し、現クラスタ根拠数 > 台帳 `evidence_count` のときのみ再提示。増えていなければ除外
7. **候補提示**: ランク付き候補リストを人間に提示。各候補に再発数・scope・重複有無・根拠エントリ参照を添える。頻度はハード閾値を置かずソフトな判断材料
8. **人間採否 → 反映**:
   - **rejected / deferred** → 即 `processed.jsonl` へ追記（`deferred` は `evidence_count` に現クラスタ根拠数を記録）
   - **採用** → Issue 草案化（`general` は本 repo `docs/working/issues/`、`project-specific` は当該プロジェクトの Issue 置き場）＋`adopted` を即 `processed.jsonl` へ追記し、`worklog-skillify` へ受け渡す
   - Issue 草案化時に、retrospective 由来の Issue バックログとの重複排除を行う（唯一の合流点）

## 出力

- ランク付き候補リスト（人間へ提示）
- 採用候補の Issue 草案（general → 本 repo `docs/working/issues/`、project-specific → 当該プロジェクト）＋`worklog-skillify` への受け渡し
- `processed.jsonl` への追記（`adopted` / `rejected` / `deferred`）

`skillified` / `merged` の台帳追記は `worklog-skillify` 側の責務。

## 再提案防止（二層）

- **①台帳（厳密層）**: 処理済み id（`adopted` を含む）は丸ごと除外する。`adopted` は skill3 完了前の窓を厳密層で捕捉するために追加された（ADR-0045 追補）
- **②既存スキル重複排除（あいまい層）**: 未処理でも既存 description と一致するものは除外。ただし本層は「スキルが作成されてから」効くため、`adopted` の厳密捕捉が併走することで完全性が確保される

## スコープ外（v1）

- **出力3（既存ルール・スキルの改訂候補発見）は作らない**。逸脱注記（`applied_rules` に "!" 等）データは記録側で貯めるが、本スキルからの提示は v2 で扱う

## 対応する原則

- **原則3（コンテキスト管理）**: 全ログの1パス走査をサブエージェントに委譲し、メインコンテキストに載せない
- **原則4（人間の関与）**: 採否・scope 確定は人間が判断。頻度もハード閾値でなくソフト判断

## 関連 ADR

- ADR-0044（overlap 対応・Issue 起票先行・scope 3分岐）
- ADR-0045（台帳による処理済み除外・deferred 再浮上・adopted 状態・スキル2フロー）
- ADR-0048/0049/0051（読み側互換: model 材料・v 版数判別・friction 読み替え）
- ADR-0054（走査直前のストア健全性検証: エンコーディング/EOL の loud validation）
