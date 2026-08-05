# Handoff: Issue-0033/0034 のスキル authoring（subagent-dispatch / pre-finalization-review）

- **Branch**: feature/skillify-subagent-dispatch-and-pre-review
- **Last Updated**: 2026-08-05 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 新規開発/brainstorming 完了・writing-plans へ移行

## 作業の目的・背景

前サイクル（ADR-0061〜0069）で設計まで確定した Issue-0033（サブエージェント委譲の定型項目）/ Issue-0034（非コード成果物の確定前レビュー）のスキル本体を authoring し、worklog パイプラインの出口（台帳 `skillified`）へ到達させる。両課題は `adopted` のまま 4 サイクル目。

成果物は新規スキル 2 件（`skills/subagent-dispatch/`、`skills/pre-finalization-review/`）と `start-work` の配線 2 箇所、README スキル一覧の更新（既存の worklog 3 スキル記載漏れの補完を含む）。

## 関連ドキュメント

- Spec: `docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md`（承認済み）
- 起点課題: `docs/working/issues/flow/0033-*.md` / `0034-*.md`（authoring 完了時に close）
- 関連ADR: ADR-0066/0067（前サイクルの設計）、ADR-0070/0071/0072/0073（本サイクルで Accepted）
- 新規起票: Issue-0047（フック機械注入。繰り延べ）、Issue-0048（退役候補の機械検出。繰り延べ）

## 完了済みタスク

- [x] 未決 2 点の解消と ADR 化: ADR-0070（規範文方式）/ 0071（B 群判定表）/ 0072（レビュー発動条件）— Accepted（2026-08-05）
- [x] 過剰適合レビュー対応: ADR-0073（根拠・世代・退役経路）— Accepted。ADR-0066/0071 部分修正、spec 反映済み（2026-08-05）
- [x] 設計 spec 作成・承認（2026-08-05）

## 進行中のタスク

- [ ] **現在の作業**: writing-plans で実装計画を作成
  - 状態: brainstorming 完了、spec 承認済み
  - 残り: plan 作成 → スキル 2 件の authoring → 配線 → README → Issue close → 台帳 skillified 追記

## 未着手のタスク

- [ ] `skills/subagent-dispatch/SKILL.md` 作成（A 群 4 件＋B 群判定表。各項目に根拠 id・モデル世代を添える。ADR-0073）
- [ ] `skills/pre-finalization-review/SKILL.md` 作成（3 観点・実証必須・ユーザー起動）
- [ ] `start-work` 配線（Phase 2 マッピング表 1 行＋横断的ラッパー Pre 1 項目）
- [ ] README スキル一覧更新（新規 2 件＋worklog 3 件の記載漏れ補完）
- [ ] Issue-0033/0034 close、台帳 `processed.jsonl` へ skillified 追記（LF 契約遵守。ADR-0064）

## 既知のブロッカー・懸念

- `sync-template.ps1` は実行不要（skills/ のみの変更。CLAUDE.md 等 template 対象を触らない限り）
- 改定スキルの同セッション検証: 本環境は marketplace が directory 参照（`installLocation` = 本 repo 直指し）のため、キャッシュを経由せず反映される可能性を今セッション冒頭で観測。Issue-0044 の材料
- inbox 残置 3 件＋ conversation_log.md はユーザー手動移動予定。`git add` で巻き込まない（Issue-0020）

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。
形式: `- <日付> <マイルストーン>: ADR=<番号 or なし（理由）> / worklog=<エントリ id or 棄却（理由）>`

- 2026-08-05 brainstorming 完了（設計承認・ADR 昇格）: ADR=0070/0071/0072/0073（すべて Accepted 済み） / worklog=`MakeAiInstructions-2026-08-05-07`（規範化時の過剰適合点検の欠落。corrections 型）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ファイル、spec（`docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md`）
2. 最初に実行すべきコマンド/スキル: `start-work` → writing-plans の再開（plan 未作成の場合）
3. 留意点: コミット前に `git status --short` でステージ確認（Issue-0020）。worklog id は省略形で書かない

## 重要な意思決定の履歴

- ADR-0070: 委譲の常時制約は規範文で実装し、フック機械注入は採らない（2026-08-05, Accepted）
- ADR-0071: B 群の発火判定は行数固定の表の読み下ろし＋判定行で担保（2026-08-05, Accepted。固定条項は 0073 で部分修正）
- ADR-0072: 確定前レビューの発動はユーザー指示に限る（2026-08-05, Accepted）
- ADR-0073: 規範項目に根拠・世代を添え退役経路を持たせる（2026-08-05, Accepted）
