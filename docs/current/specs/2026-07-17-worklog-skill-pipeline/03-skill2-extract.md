# ブロック03: skill2-extract（候補抽出スキル）

## 対象ファイル

- `skills/worklog-extract/SKILL.md`（スキル本体）

## 責務

中央ストアに蓄積された作業ログをオンデマンドで走査し、スキル化・ルール化する価値のある候補をクラスタリング・評価して、ランク付き候補リストとして人間に提示する。人間の採否を受けて Issue 草案化と台帳更新を行う。

## インターフェース

- **トリガー**: ユーザーのオンデマンド実行（自動起動しない）
- **入力**: 中央ストア（`projects.json` ＋ 全 `log.jsonl` ＋ `processed.jsonl`）
- **出力**:
  - ランク付き候補リスト（人間へ提示）
  - 採用候補の Issue 草案（`docs/working/issues/`。general→本 repo backlog、project-specific→当該プロジェクト）＋スキル3への受け渡し
  - `processed.jsonl` への追記（rejected / deferred）
- **01 への依存操作**: 全エントリ読み取り／台帳読み取り／台帳追記
- **04 への受け渡し**: 採用候補（Issue 草案＋根拠エントリ参照）

## サブ機能 / 内部構成

1. **台帳による前処理**: `processed.jsonl` を読み、処理済み id（skillified/rejected/merged）を分析対象から除外。deferred は `evidence_count` とともに保持（分析コストは未処理エントリ数でスケール）
2. **サブエージェント走査**: 全コーパスをメインコンテキストに載せず、サブエージェントで未処理エントリを1パス走査 → 類似エントリをクラスタリング（同型手順の横断再発をまとめる）
3. **クラスタ評価**: 横断再発回数・出所プロジェクト数・friction/corrections の重みを集計
4. **scope 再判定**: ≥2プロジェクト再発→`general-candidate` へ格上げ、単一・ドメイン依存→`project-specific`（record 時タグを横断視点で最終確定）
5. **既存スキル重複排除**: superpowers＋ai-driven-dev-principles＋プロジェクトローカルの description と突合し、既存済みを除外（あいまい層）
6. **deferred 再浮上判定**: deferred クラスタは、現在のクラスタ根拠数が台帳の `evidence_count` を上回った（新しい該当エントリが増えた）場合のみ再提示。増えていなければ除外
7. **候補提示**: ランク付き候補リスト（再発数・scope・重複有無・根拠エントリ参照つき）を人間に提示。頻度はハード閾値を置かずソフトな判断材料
8. **採否反映**: 人間が採否 → rejected/deferred は即 `processed.jsonl` へ追記（deferred は `evidence_count` に現クラスタ根拠数を記録）／採用は Issue 草案化してスキル3へ

## データモデル

01（worklog-store）のエントリ・台帳スキーマに従う。読み取り側＋台帳の一部書き込み側（rejected/deferred）。

## このブロック固有の制約・前提

- 再提案防止は二層: ①台帳（厳密＝処理済みは丸ごと除外）②既存スキル重複排除（あいまい＝未処理でも既存 description 一致で除外）
- skillified/merged の台帳追記はスキル3側が行う（本ブロックは rejected/deferred のみ）
- retrospective との overlap は Issue バックログ1箇所での重複排除で解消（唯一の合流点）
- 出力3（既存ルール・スキルの改訂候補発見）は v1 スコープ外（逸脱注記データは貯めるが提示しない）

## 関連 ADR

- ADR-0044（overlap 対応・Issue 起票先行・scope 3分岐）
- ADR-0045（台帳による処理済み除外・deferred 再浮上・スキル2フロー）
