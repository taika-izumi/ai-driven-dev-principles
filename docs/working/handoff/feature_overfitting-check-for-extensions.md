# Handoff: ガイドライン拡張の過剰適合点検ルールの導入（ADR-0079）

- **Branch**: feature/overfitting-check-for-extensions
- **Last Updated**: 2026-08-07 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: ガイドライン拡張/実装完了（Task 1〜7・ファイナルレビュー済み）→ プラグイン更新の反映突合（Task 8・ユーザー操作待ち）→ ADR-0079 昇格（Task 9）

## 作業の目的・背景

本ガイドラインは開発対象システムの種類・利用 AI モデルを限定しない前提だが、この前提がルールとして明文化されておらず、2026-08-05 の Issue-0033/0034 スキル化サイクルで単一プロジェクト（LoopForAlpha）出所の教訓が汎用スキルの拘束的規範として spec 承認まで進んだ（検出はユーザー目視に依存。ADR-0073 で個別修正済み）。

本サイクルでは、ガイドライン拡張の全経路に過剰適合点検（4 観点: 出所の偏り / システム種別依存性 / AIモデル・ツール依存性 / 退役経路）を課し、点検結果の記録を義務化する（ADR-0079）。正本は CONTRIBUTING.md の横断節、`extend-guidelines` / `worklog-skillify` へ工程を配線する。

## 関連ドキュメント

- 設計 spec: `docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md`（設計承認済み・コミット `c067f3d`）
- 本サイクルの ADR: ADR-0079（Proposed・コミット `531e3aa`。昇格は実装完了・検証後）
- 型の参照元: ADR-0032（観測可能ゲート）/ ADR-0073（降格・根拠と世代・退役経路）/ ADR-0040（CLAUDE.md 事前判定）
- 契機の記録: worklog `MakeAiInstructions-2026-08-05-07`

## 完了済みタスク

- [x] 事例特定: 過剰適合しかけた実例を worklog `MakeAiInstructions-2026-08-05-07` / ADR-0073 で特定（2026-08-07）
- [x] brainstorming: 適用範囲（全経路）・強制力（記録義務化）・配置（案 A: CONTRIBUTING.md 横断節＋スキル配線）を確定、ADR-0079 起票（Proposed）、spec コミット `c067f3d`（2026-08-07）
- [x] pre-finalization-review（初回実運用）: 3 観点並列・レビュアー claude-opus-5。指摘 24 件→15 テーマ全採用、spec v2 + ADR-0079 改訂をコミット `b34e2ca`（観点 4 点化・是正 4 型化・記録先固定・執行点明確化・配線拡大・変更 5 新設）（2026-08-07）
- [x] writing-plans: 実装計画コミット `e4d9ef9`（検証コマンド 7 本の実行可能性検査済み。Issue-0056 の教訓適用）（2026-08-07）
- [x] 実装 Task 1〜7（subagent-driven・タスク毎二段レビュー）: CONTRIBUTING.md 横断節＋9 シナリオ配線（`08f8201` `47d916a` `408d1bb`）、extend-guidelines（`55d160e` `6670ea6`）、worklog-skillify（`2dddf2b` `89ad42f`）、04-skill3-skillify 同期（`213fcda`）、Issue-0058〜0060 起票（`d64013a`）。全体検証 1〜7 全 PASS（2026-08-07）
- [x] ファイナルレビュー（opus・spec 39 チェックポイント全数突合）: 実装漏れ 0・Ready to merge。Important 2 件へ対処: description 修正 `57b6e86`・Issue-0061 起票 `c311be7`（2026-08-07）

## 進行中のタスク

- [ ] **現在の作業**: Task 8（プラグイン更新の反映突合）
  - 状態: ユーザーへ `/plugin marketplace update ai-driven-dev-principles` の実行を依頼中（Issue-0044: update を挟まないと改定前の本文が供給される）
  - 残り: update 後に extend-guidelines を起動し「### 5. 確定前の過剰適合点検」の有無を repo 実ファイルと突合 → Task 9（ADR-0079 Accepted 昇格）→ merge → retrospective

## 未着手のタスク

- [ ] Task 9: ADR-0079 Accepted 昇格（粒度点検 → 本体＋インデックス更新 → コミット）
- [ ] master merge → retrospective（cycle-reset）

## 既知のブロッカー・懸念

- スキル 2 件（extend-guidelines / worklog-skillify）の改定を含むため、改定後の同セッション利用前にユーザーへ `/plugin marketplace update ai-driven-dev-principles` を依頼すること（Issue-0044）
- inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定。organize-inbox 提案は不要。`git add <ディレクトリ>` で巻き込まないこと（Issue-0020。コミットはパス指定）
- CONTRIBUTING.md・skills/ は template 対象外のため `sync-template.ps1` は不要（本サイクルの変更対象では発動しない）

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。
形式: `- <日付> <マイルストーン>: ADR=<番号 or なし（理由）> / worklog=<エントリ id or 棄却（理由）>`

- 2026-08-07 brainstorming 完了（設計承認・spec コミット `c067f3d`）: ADR=0079（Proposed・コミット済み） / worklog=棄却（設計プロセスはガイドラインどおりに進行し delta なし。事例特定は worklog 全文検索という自律再現可能な手順のみ）
- 2026-08-07 pre-finalization-review 完了（spec v2 `b34e2ca`）: ADR=なし（指摘の採否は ADR-0079 の Proposed 改訂に吸収。新規の独立決定なし） / worklog=`MakeAiInstructions-2026-08-07-04`（ルール文書型 spec はレビュー推奨に倒すキャリブレーション知見）
- 2026-08-07 writing-plans 完了（計画 `e4d9ef9`）: ADR=なし（計画は spec v2 の写像で新規決定なし） / worklog=棄却（検証コマンドの事前実行は Issue-0056・handoff 留意の既存知見の適用で delta なし）
- 2026-08-07 実装 Task 1〜7＋ファイナルレビュー完了（`08f8201`〜`c311be7`）: ADR=なし（レビュー派生の対処は description 修正と Issue-0061 起票で記録。新規の独立決定なし） / worklog=`MakeAiInstructions-2026-08-07-05`（Group-Object Filename が同名ファイルを併合する検証コマンドの落とし穴）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ハンドオフ、`docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md`
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）→ spec レビュー状況の確認 → `superpowers:writing-plans`
3. 留意点: 実装はスキル改定を含むため、検証段階でプラグイン更新のユーザー依頼が必要（Issue-0044）。コミットはパス指定で inbox を巻き込まない

## 重要な意思決定の履歴

- ADR-0079: ガイドライン拡張の全経路に過剰適合点検を課し、点検結果の記録を義務化する（2026-08-07、Proposed）
