# Handoff: ハンドオフ剪定サイクル完了・次サイクル待ち

- **Branch**: master（feature/handoff-pruning-and-status を merge `1eba4c3` として取り込み・feature ブランチ削除済み）
- **Last Updated**: 2026-08-06 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: 全フェーズ完了。次サイクル着手はユーザー判断

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AI駆動開発ガイドライン（5原則 + スキル群 + ADR。AIエージェントと協働して開発を進めるための、原則・行動指示・スキルの体系）を整備するプロジェクト。

**直近サイクル（2026-08-06: ハンドオフ剪定規約と Status 整合）**: Issue-0049/0051 を同時対処し、ADR-0074〜0077（二段階剪定・受け皿は git 履歴のみ・Status 4 値化・外部参照の安定識別子）を Accepted 化。`session-handoff` に finalize 基準付き圧縮と cycle-reset 操作を実装し、`retrospective` Phase 3 を接続した。あわせて Issue-0044 の核心（同セッション検証可否）を実測し、plugin update を挟めば反映されることを確認。本ハンドオフ自体が cycle-reset の初回実運用（旧 Status 不整合注記を除去済み）。次サイクル着手はユーザー判断待ち。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open: system 0003/0008/0028/0036 の 4 件、flow 0006/0015/0020/0021/0038/0039/0042〜0048/0050/0052〜0054 の 17 件、計 21 件）
- 直近サイクルの retrospective: `docs/records/retrospectives/system/2026-08-06-handoff-pruning-and-status.md`
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0077。Rejected 3件）
- worklog スキーマ正典: `skills/worklog-record/references/store-format.md`（v2）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] 過去サイクルは retrospective（`docs/records/retrospectives/README.md`）/ git 履歴参照

## 進行中のタスク

（なし。サイクル完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化。次サイクルの候補として目安を示す:

0. [ ] **改名サイクル（決定済み・準備完了）**: 体系呼称を「AI駆動開発ガイドライン」へ改名（ADR-0078・Proposed）。ブランチ `feature/rename-to-ai-driven-dev-guideline` に ADR と handoff をコミット済み（`8967b55`）。着手時はこのブランチへ checkout し、handoff `feature_rename-to-ai-driven-dev-guideline.md` の指示に従う（writing-plans 直行）
1. [ ] **Issue-0045**（flow）: 既存 open 課題の対策方針の実行可能性点検。open 21 件（system 4 + flow 17）。0046×0050（規模とカデンス）のグルーピング示唆あり（0049/0051/0053 のうち 2 件は今回 close 済みでペア構成は変化）
2. [ ] **Issue-0044**（flow）: 残る未実測は「plugin update **なし**での同セッション反映可否」のみ。次のスキル改定サイクルで update を挟まず起動して切り分ける
3. [ ] **Issue-0042/0043**（flow）: 検出器の検出力 / 意思決定要求の front-load
4. [ ] **Issue-0020**（flow）: ステージング内容確認の機械 gate 調査（再発累計 3 回）
5. [ ] **Issue-0047/0048**（flow）: フックによる A 群機械注入 / 退役候補の機械検出（0048 は worklog 数サイクル蓄積後が安い）
6. [ ] **Issue-0008**（system）ほか低優先課題群 / **Issue-0028**（system・v2 テーマ）/ ループプロファイル抽出（ADR-0043）

## 既知のブロッカー・懸念

- **新設スキル 2 件（subagent-dispatch / pre-finalization-review）は実運用ゼロのまま**: 直近サイクルで pre-finalization-review の提示は初めて発生したが実施は見送り（ユーザー判断）。サブエージェント委譲も未発生。次に発生するサイクルが初回実測（ADR-0070 の効き目測定は worklog の同型 delta 再発の有無で行う）
- **`Add-Content` は使わないこと**。中央ストアへの追記は Python `open(path, "a", encoding="utf-8", newline="\n")`（ADR-0064）
- **クロス repo の課題参照は `<repo>#Issue-NNNN` で修飾**（ADR-0068）
- **中央ストアの現状**: 本repo 25 件（〜`MakeAiInstructions-2026-08-06-04`）＋ LoopForAlpha 106 件。台帳 33 行。`projects.json` lastSeen 更新済み（2026-08-06）
- **inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定**。organize-inbox 提案は不要。`git add <ディレクトリ>` で巻き込まないこと（Issue-0020）
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` は確認済み（構造化質問ツール使用前に毎回確認。ADR-0036）
- ADR-0023 の留意点（継続）: GitHub.com の Copilot コーディングエージェントがルート `CLAUDE.md` を読まない可能性

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。直近サイクル中の分は `feature_handoff-pruning-and-status.md` 参照（retrospective Phase 3 で突合済み・未消化なし）。

- 2026-08-06 master merge（`1eba4c3`）+ retrospective 完了（`d72a97a`）: ADR=なし（振り返りは課題抽出のみ。ADR-0021） / worklog=`MakeAiInstructions-2026-08-06-03`（総ざらいで delta 型候補を記録。未消化なし）
- 2026-08-06 セッション終了（切り替え直前。ADR-0058）: ADR=なし（終了処理に意思決定なし） / worklog=棄却（`-03` 以降に新規 delta なし）
- 2026-08-06 改名の名称決定（次サイクル準備。着手は延期）: ADR=0078（Proposed・`feature/rename-to-ai-driven-dev-guideline` の `8967b55` にコミット） / worklog=`MakeAiInstructions-2026-08-06-04`

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **直近サイクルは完了**: 追加作業不要。抽出した新規課題は 0 件（worklog 送り 2 件のみ: `MakeAiInstructions-2026-08-06-02` / `-03`）。Issue-0049/0051 は close 済み
3. **次サイクルの候補（着手はユーザー判断）**: **改名サイクルが決定済み・準備完了**（上記「未着手のタスク」項目 0。ブランチ checkout から開始）。それ以外では Issue-0045 の棚卸し、Issue-0044 の残る切り分けが有力
4. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - サブエージェント委譲時は `subagent-dispatch` を呼ぶ / plan・spec 確定時は `pre-finalization-review` を毎回提示する（いずれも初回実運用待ち）
   - Post ラッパーは1項目ずつ消し込み、結果を消化記録へ書く（ADR-0057）。worklog id は省略せず全体を書く
   - コミット前に `git status --short` を確認し、untracked の巻き込みとステージ済み別件の混入を見る（Issue-0020）。コミットはパス指定（`git commit -F <msg> -- <paths>`）が安全
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行（skills 改定では不要）
   - コミット・マージのマルチライン文字列は `git commit -F <絶対パスの一時ファイル>`（Issue-0015）
   - ハンドオフの剪定は新規約に従う: finalize で基準付き圧縮、サイクル完了時に cycle-reset（`skills/session-handoff/SKILL.md` 操作 4・5。ADR-0075）

## 重要な意思決定の履歴

- ADR-0074〜0077: 直近サイクル（ハンドオフ剪定規約と Status 整合）
- （ADR-0001〜0073 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
