# Handoff: Issue-0088 対応（handoff 以外の成果物の肥大化抑制の検討）

- **Branch**: feature/issue-0088-artifact-bloat-survey
- **Last Updated**: 2026-08-15 (Asia/Tokyo)
- **Status**: completed
- **Current Phase**: サイクル完了（master へ --no-ff マージ済み `e4590bf`・retrospective 済み）。以後の正本は `docs/working/handoff/master.md`

## 作業の目的・背景

Issue-0088 の検討サイクル。ハンドオフには肥大化対策（ADR-0074/0075/0077、ADR-0086〜0088）が入ったが、それ以外の成果物（Issue・各種インデックス・retrospective 等）には肥大化を抑制する機構がない。配布先の業務利用（マネジメント用途・旧版）で Issue の肥大化が実際に発生した（詳細は Issue-0088 が正）。

先行論点として「そもそも本リポジトリで対処すべき問題か」（マネジメント用途をスコープに含めるか）自体が議論対象。議論のみで終える場合は Issue-0088 に経緯を記録して close する。

## 関連ドキュメント

- 本サイクルの課題: `docs/working/issues/flow/0088-issue-and-other-artifacts-growth-control.md`（起票コミット `f2ac91f`）
- handoff 側の先行対策: ADR-0074/0075/0077・ADR-0086/0087/0088（`docs/records/decisions/README.md`）
- 同型・隣接課題: Issue-0049（closed）/ 0087 / 0050 / 0021 / 0045
- 拡張ルール: `CONTRIBUTING.md` / 原則: `docs/overview/principles.md`

## 完了済みタスク

- [x] Issue-0088 起票・インデックス追記（2026-08-15。コミット `f2ac91f`）
- [x] brainstorming（棚卸し・対処要否・配置モデル・体系・粒度の設計確定。ADR-0094〜0098）
- [x] 確定前レビュー フル実施（4 観点・claude-opus-5。指摘 29 クラスタを反映）と Issue-0089/0090 起票（`7f9f1dc`）
- [x] 設計 ADR 群コミット（`8972765`）

## 進行中のタスク

（実装完了。残作業はユーザー判断待ち）

## 未着手のタスク

- [ ] master への --no-ff マージ（Issue-0084: 完了フロー未配線のため手動適用。ユーザー判断）
- [ ] マージ後の retrospective → cycle-reset
- [ ] push（ユーザー指示待ち）と配布反映: `/plugin marketplace update ai-driven-dev-principles`（0.1.5）。**課題管理定義（template 配布）は既存配布先へ手動コピーが必要**
- [ ] retrospective の気付き候補: `specs/2026-08-07-distributed-artifact-generation/05-source-migration.md` 153 行目のひな形パス言及が分離後と乖離（最終レビュー検出・実害小） / decision-log 152 行目の昇格条件要約は定義側改定時に同時更新が必要（ADR-0098 の複写乖離型の監視点）

## 既知のブロッカー・懸念

- 配布先の観測データは業務 PC 上にあり参照不可。事象の詳細は報告者（ユーザー）の記憶ベース（Issue-0088 に記載）
- master の handoff（`docs/working/handoff/master.md`）の留意点・ブロッカー節が本サイクルにも適用される（配布物の執行点 4 手順・version bump・確定前レビュー提示・サイクル全体整合検査ほか）

## Post ラッパー消化記録

- 2026-08-15 設計確定・spec 確定点 (c) 通過（ADR コミット `8972765`）: ADR=0094〜0098（Proposed 起票） / worklog=`MakeAiInstructions-2026-08-15-04` / review=フル実施（claude-opus-5）
- 2026-08-15 実装計画確定・plan 確定点通過（`docs/working/plans/2026-08-15-issue-bloat-control-plan.md`）: ADR=なし（新規決定なし。ADR-0096 への追補 2 件は計画 Step 3-4 で実施） / worklog=`MakeAiInstructions-2026-08-15-05`（Issue-0056 再発追記も実施） / review=フル実施（claude-opus-5）
- 2026-08-15 実装完了・ADR-0094〜0098 Accepted 昇格・Issue-0088 close（コミット `6b5c419`〜`c655868`）: ADR=0094〜0098 昇格（新規なし） / worklog=棄却（`-2026-08-15-05` と同型の期待値誤り 1 件のみ。新規 delta なし） / cyclecheck=実施（指摘なし）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本 handoff と `docs/working/issues/flow/0088-issue-and-other-artifacts-growth-control.md`
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本 handoff を read）→ 中断地点の再開
3. 留意点: 対処要否（マネジメント用途のスコープ判断）が先行論点。決定を検出したら即 `decision-log`

## 重要な意思決定の履歴

- ADR-0094: 肥大化は用途別対応でなく成長様式への対策として扱う（2026-08-15 Proposed）
- ADR-0095: 検討中はフォルダ集約・close で性質別置き場へ移設（2026-08-15 Proposed）
- ADR-0096: 昇格条件の観測可能化・4 役割・番号接頭辞・配線とフォールバック（2026-08-15 Proposed）
- ADR-0097: 1 Issue＝1 問題・複数の問いの内包可（2026-08-15 Proposed）
- ADR-0098: 発火条件はスキル・構造定義はプロジェクト文書・複写禁止（2026-08-15 Proposed）
