# Handoff: 配布物からの出所識別子の除去（Issue-0067 対策）

- **Branch**: feature/cross-repo-adr-reference
- **Last Updated**: 2026-08-07 23:05 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: ガイドライン拡張 / plan 確定済み・実装着手前

## 作業の目的・背景

ガイドラインの配布先プロジェクトへ届く成果物が、本リポジトリの文脈でしか解決できない参照を含んでいる。判定基準を「配布先の読み手が解決できるか」に統一し、5 種類の出所識別子（決定記録番号・課題番号・`<repo>#` 修飾参照・worklog エントリ id・出所注記）計 208 箇所を対象とする。

対処は「注記を保持したソースから、注記を除去した生成物を配布する」体制。`template/` が `sync-template.ps1` で生成されている既存の型を `skills/` へ水平展開し、生成器が記法規約の検査を兼ねる。**根拠の散文は残し、除去するのは識別子だけ**とする（ADR-0073 が要求する根拠と観測世代は散文が担う）。

## 関連ドキュメント

- 対象課題: `docs/working/issues/system/0067-distributed-artifacts-reference-repo-local-adr-numbers.md`
- 仕様（コミット `9b974ba`）: `docs/current/specs/2026-08-07-distributed-artifact-generation/`（00-overview ＋ 01〜05）
- 計画（コミット `7a1c0fc`）: `docs/working/plans/2026-08-07-distributed-artifact-generation-plan.md`（12 タスク）
- 本サイクルの決定（いずれも Proposed。実装完了時に Accepted 昇格）:
  - ADR-0081: 配布物から除くのは「配布先で解決できない参照」であり、決定記録番号に限らない
  - ADR-0082: 保守者向けの根拠注記はソースに残し、注記を除去した生成物を配布する
  - ADR-0083: 配布対象ソースの出所識別子は位置で規約化し、生成器が規約適合の検査を兼ねる
- 前提となる既存決定: ADR-0016 / ADR-0027 / ADR-0033 / ADR-0039 / ADR-0055 / ADR-0068 / ADR-0073

## 完了済みタスク

- [x] Task 1: 配布構造の実機判定（2026-08-07）— **構造 A が成立**。検証は別名エントリで行い本番エントリは無変更

- [x] 事象の実測と原因の切り分け（2026-08-07）— `template/` は ADR-0027 の「説明文は保持」の残余、`skills/` は ADR-0016 で template 同期の検査対象外
- [x] Issue-0067 起票（2026-08-07）
- [x] 参照の全件型別分類（2026-08-07）— 識別子を含む行 172、適合 135（括弧内 120・出所リスト行 15）、違反 37（R2 16・R3 15・R4 6）＋ R5 1
- [x] 配布経路の実機確認（2026-08-07）— マーケットプレイス登録は `"source":"directory"` で repo 直下を指し、プラグインキャッシュにリポジトリ全体 743KB の完全コピーが存在する
- [x] brainstorming 完了・設計承認（2026-08-07）
- [x] spec 確定（2026-08-07・コミット `9b974ba`）— 確定前レビュー 2 段（フル 3 観点＋差分再確認）で Critical 7・Major 14・Minor 16 を検出し全件反映
- [x] plan 確定（2026-08-07・コミット `7a1c0fc`）— 軽量レビューで Critical 2・Major 5・Minor 5 を検出し全件反映。修正版を写経実行し自己テスト 15/15・実データ違反 36 を確認

## 進行中のタスク

- [ ] **現在の作業**: 実装の開始（Task 1 から）
  - 状態: plan 確定済み（`docs/working/plans/2026-08-07-distributed-artifact-generation-plan.md`。コミット `7a1c0fc`）。spec・plan とも確定前レビューを通過し全指摘を反映済み
  - 残り: 実行方式（`subagent-driven-development` / `executing-plans`）をユーザーが選択して Task 1 から着手する

## 未着手のタスク

- [ ] Task 2〜4: 共有ライブラリと生成器の実装
- [ ] Task 5〜7: ソースの規約適合化（36 行 ＋ template ソース 1 行 ＋ R5 1 行）
- [ ] Task 8〜11: `sync-template.ps1` 改修 / CONTRIBUTING 配線 / ADR-0027 注記 / 本番切替
- [ ] Task 12: 全体検証 → ADR-0081/0082/0083 の粒度点検・Accepted 昇格 → Issue-0067 close

## 既知のブロッカー・懸念

- **同一マーケットプレイスへ 2 つ目のプラグインをインストールすると、1 つ目のインストール記録が消える**（2026-08-07 実測）。本番エントリに一切触れずに別名エントリで検証したにもかかわらず、`ai-driven-dev-principles` の記録が `installed_plugins.json` から消え、ガイドラインスキル 12 本が使えなくなった。復旧は `/plugin install ai-driven-dev-principles@ai-driven-dev-principles`（ユーザー操作。エージェントからは実行できない）。**Task 11 の本番切替でも同じ危険がある**ため、切替後は必ずインストール記録を確認すること（計画 Task 11 Step 2 に手順を追記済み）
- **検証用プラグイン `ai-driven-dev-principles-probe` の記録が残っている。** `./dist` に skills が無いためスキルは提供していないが、片付けるならユーザースコープでのアンインストールが要る（プロジェクトスコープの uninstall は「インストールされていない」と返る）
- **構造 A の成立を実機で確認済み（2026-08-07）。** 検証用エントリ `ai-driven-dev-principles-probe`（`source: "./dist"`）でスキルを起動したところ、ベースディレクトリが `dist/skills/probe-skill` を指した。マーケットプレイスの `source` にサブディレクトリを指定できる。**構造 B へのフォールバックは不要**で、計画 Task 1 Step 5 の読み替え表は適用しない
- **計画に載せた PowerShell は写経実行で検証済み**（自己テスト 15/15・実データ違反 36・見出し消失 0・インデント破壊 0・CR 0）。ただし `build-dist.ps1` 本体の全体実行はまだ行っていない
- **`,@($list)` は List に対して型エラーになる**（実測）。単項カンマで包むときは `.ToArray()` を使う
- **inbox 残置 3 件＋ `docs/conversation_log.md` はユーザーが手動移動予定**。organize-inbox 提案は不要。`git add <ディレクトリ>` で巻き込まないこと（Issue-0020）
- master 由来の申し送り（PowerShell の検索・集計の落とし穴、`Add-Content` 禁止、プラグイン update の必要性など）は `docs/working/handoff/master.md` の「既知のブロッカー・懸念」を参照

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。形式は `skills/session-handoff/SKILL.md` のフォーマット節を参照（確定点を通過したマイルストーンには `review=` を併記する。ADR-0080）。

- 2026-08-07 brainstorming 完了（配布物の記録参照の扱いを設計）: ADR=0081（設計収束にあわせ書き直し）・0082（配布体制）・0083（記法規約と検査） / worklog=`MakeAiInstructions-2026-08-07-13`・`MakeAiInstructions-2026-08-07-14`（確定点ではないため `review=` は省略。spec 確定点 (a) は `feature-block-design` 完了時）
- 2026-08-07 spec 確定点 (a)（`feature-block-design` 完了・spec 6 ファイル確定）: ADR=0081/0082/0083（いずれも Proposed のままコミット `9b974ba`。実装完了時に Accepted 昇格） / worklog=`MakeAiInstructions-2026-08-07-15` / review=フル実施（claude-opus-5）＋差分再確認（claude-opus-5）
- 2026-08-07 plan 確定点（`superpowers:writing-plans` 完了・12 タスクの計画を確定。コミット `7a1c0fc`）: ADR=なし（既存 ADR-0081〜0083 の写像であり新規の決定なし） / worklog=`MakeAiInstructions-2026-08-07-16` / review=軽量レビュー実施（claude-opus-5。写像欠落と自己テスト整合に限定。Critical 2・Major 5・Minor 5 を全件反映し、修正版を写経実行して検証）

- 2026-08-07 Task 1 完了（配布構造の実機判定・構造 A 成立。コミット `560be0f`）: ADR=なし（ADR-0082 が定めた判定手順の実行であり新規の決定なし） / worklog=`MakeAiInstructions-2026-08-07-17`（検証中に本番プラグインのインストール記録が消える事故。緩和策が実機で破れた型） / review=非発火（確定点ではない）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: `docs/working/plans/2026-08-07-distributed-artifact-generation-plan.md`（12 タスク。仕様は `docs/current/specs/2026-08-07-distributed-artifact-generation/`）
2. 最初に実行すべきコマンド/スキル: `start-work` → 実行方式を選んで計画の Task 1 から着手（`superpowers:subagent-driven-development` または `superpowers:executing-plans`）
3. 留意点:
   - **spec も plan も確定前レビュー済み**。実装中に設計を変える判断が出たら `decision-log` を呼び、spec を書き換えで更新する（差分ファイルを作らない）
   - Task 1 と Task 11 はユーザーへ `/plugin marketplace update` の依頼が要る（エージェントからは実行できない）
   - サブエージェントへ委譲するときは `subagent-dispatch` を呼び、B 群判定行を残す
   - Task 12 で ADR-0081/0082/0083 を Accepted へ昇格し、Issue-0067 を close する

## 重要な意思決定の履歴

- ADR-0081: 配布物から除くのは「配布先で解決できない参照」であり、決定記録番号に限らない（2026-08-07・Proposed）
- ADR-0082: 保守者向けの根拠注記はソースに残し、注記を除去した生成物を配布する（2026-08-07・Proposed）
- ADR-0083: 配布対象ソースの出所識別子は位置で規約化し、生成器が規約適合の検査を兼ねる（2026-08-07・Proposed）
