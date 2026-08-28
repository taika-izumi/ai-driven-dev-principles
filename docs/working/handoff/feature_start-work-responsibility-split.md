# Handoff: start-work スキルの責務過多の解消

- **Branch**: feature/start-work-responsibility-split
- **Last Updated**: 2026-08-28 00:24 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: ガイドライン拡張/extend-guidelines（brainstorming 接続前）

## 作業の目的・背景

start-work スキルが責務過多ではないかという指摘を受け、分析の結果、妥当と判定した（2026-08-28）。SKILL.md は 34.7KB で全 13 スキル中最大。本来のオーケストレーション責務（Phase -1〜2・横断的ラッパー・終了処理）に加え、「確定前レビューの提示規則」（本文の約 45%）と「完了処理のマージ方式確認」（約 14%）というドメイン規範の正本を抱えており、毎セッション冒頭で全文が読まれるため確定点に到達しないセッションでもコンテキスト費用を払っている。Issue-0105 が同じ偏りを実測済み。

本サイクルでは、責務の分割単位と正本の移設先（pre-finalization-review 側へ移すか、references/ への遅延読み込みか等）を brainstorming で設計し、改修を実施する。制約: 条文複写の禁止（正本ごと移して参照を張り替える。Issue-0093 で統合した二重定義を再導入しない）。分割後の責務境界を将来の追記者が迷わない形で明文化することも設計項目。

## 関連ドキュメント

- Issue-0105: `docs/working/issues/flow/0105-skill-md-size-growth-no-norm.md`（SKILL.md サイズ・分割規範が無い。open）
- Issue-0101: `docs/working/issues/flow/0101-start-work-spec-figure-drift.md`（旧設計仕様書の図示乖離。open）
- Issue-0093: `docs/working/issues/flow/0093-integrate-22-duplicated-norm-records.md`（二重定義 22 行の統合。closed。複写禁止の根拠）
- 監査記録: `docs/records/audits/2026-08-16-guideline-process-audit/report.md`（クラスタ一覧 1-6）
- 拡張ルール: `CONTRIBUTING.md`（過剰適合点検＝ADR-0079、新設の評価可能性＝ADR-0102、執行点 4 手順）

## 完了済みタスク

- [x] 責務過多の指摘の妥当性分析（2026-08-28。節別実測: 確定前レビュー提示規則 6,206 字≈45% / マージ方式確認 1,970 字≈14%）

## 進行中のタスク

- [ ] **現在の作業**: extend-guidelines → brainstorming で分割設計
  - 状態: feature ブランチ作成・handoff 新規作成まで完了
  - 残り: CONTRIBUTING.md 読み込み → brainstorming で分割単位・移設先・責務境界の明文化方法を設計

## 未着手のタスク

- [ ] 分割設計の確定（spec 確定点で確定前レビュー提示）
- [ ] 実装計画の作成（plan 確定点で確定前レビュー提示）
- [ ] 改修の実施（執行点 4 手順・plugin version bump 対象）

## 既知のブロッカー・懸念

- 条文複写の禁止: 提示規則・マージ方式確認を移す場合は正本ごと移し、start-work 側はポインタのみにする（Issue-0093 の統合を再導入しない）
- 参照配線の張り替え範囲: session-handoff・pre-finalization-review・decision-log・AGENTS.md が start-work の節を参照しており、移設時は全参照の更新が必要
- 配布対象ソースに触れるため執行点 4 手順・plugin version bump（現行 0.1.12）・過剰適合点検＋新設の評価可能性が必須

## Post ラッパー消化記録

（未記入）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本 handoff と `skills/start-work/SKILL.md`
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本 handoff を read）→ 進行中タスクの再開ポイントへ
3. 留意点: 分割設計は brainstorming 未完了。設計判断が出たら decision-log で即ドラフト

## 重要な意思決定の履歴

（なし。分割設計の判断は brainstorming で ADR 化予定）
