# Handoff: Issue-0084 マージ方式配線サイクル完了・次サイクル待ち

- **Branch**: master（feature/issue-0084-wire-no-ff-merge を --no-ff で取り込み。マージコミット `6333928`）
- **Last Updated**: 2026-08-18 00:05 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: サイクル完了（retrospective・cycle-reset 済み）。次サイクル着手はユーザー判断。本ファイルは 2026-08-18 に事後同期（cycle-reset が feature 側 handoff へ誤適用された欠落の補正。経緯は Issue-0102）

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AI駆動開発ガイドライン（5原則 + スキル群 + ADR。AIエージェントと協働して開発を進めるための、原則・行動指示・スキルの体系）を整備するプロジェクト。

**直近サイクル（2026-08-17: Issue-0084 対応）**: fast-forward マージ再発（8 サイクル目で実証）の対策として ADR-0106 を設計・実装。`start-work` への予防配線（完了処理行＋マージ方式確認節＋Pre 条項）、`retrospective` への検出配線（ff 検出・やり直し手順・取り込み方式欄）、本リポジトリの git 設定（mergeoptions --no-ff / pull.ff true）を plugin 0.1.9 として master へ `--no-ff` マージ（`6333928`。新配線の初適用で ff なしを確認）。ADR-0106 Accepted・Issue-0084 close・Issue-0101 起票。次サイクル着手はユーザー判断待ち。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open 計 48 件。2026-08-18 実測: 前回 47 − close 1〈0084〉＋ 起票 2〈0101/0102〉）
- 課題管理の運用規範の正本: `docs/overview/issue-management.md`（課題管理定義）
- 直近サイクルの決定: ADR-0106（`docs/records/decisions/0106-two-layer-wiring-for-merge-mode-norm.md`・Accepted）。retrospective: `docs/records/retrospectives/system/2026-08-17-issue-0084-merge-mode-wiring.md`。実装 plan（スモーク 13 項目の結果を含む）: `docs/working/plans/2026-08-17-adr-0106-merge-mode-wiring-plan.md`
- 前サイクルの監査記録: `docs/records/audits/2026-08-16-guideline-process-audit/`（`ledger.md` 台帳・`report.md` 報告。確定後不変。行番号アンカーは陳腐化）
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0106。Rejected 3件）
- 記法規約と執行点: `CONTRIBUTING.md`「全シナリオ共通: 配布対象ソースの記法規約」
- worklog スキーマ正典: `skills/worklog-record/references/store-format.md`（v2）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`
- PowerShell / .NET API の落とし穴集: `docs/reference/powershell-pitfalls.md`

## 完了済みタスク

- [x] 過去サイクルは retrospective（`docs/records/retrospectives/README.md`）/ git 履歴参照

## 進行中のタスク

（なし。サイクル完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化。次サイクルの候補として目安を示す:

1. [ ] **Issue-0101**（flow）: start-work 旧設計仕様書の図示乖離（小規模。Issue-0008 と関連）
2. [ ] **Issue-0098**（flow）: 確定前レビューの反復の発動基準。実測蓄積済み（決定にはユーザーのコスト許容の判断が要る）。着手時にファイルのフォルダ昇格判断も（下記懸念）
3. [ ] **Issue-0100**（flow）: 配線行に可変数値を書かない規律の恒久規範化（有効性実測済み・小規模）
4. [ ] **Issue-0102**（flow・新規）: マージ後の cycle-reset の適用先 handoff の明示配線（2026-08-18 起票。応急処置済み・恒久対策未着手）
5. [ ] **Issue-0095**（flow）: A-13（計画の期待値突合）の再設計。検出力反証済み。Issue-0056・0073 と同時対策
6. [ ] **Issue-0072**（system）: 半角括弧の同一視。1 行修正で塞げることまで確認済み（軽量に畳む候補）
7. [ ] **Issue-0097 / Issue-0099**（flow・待機）: 保留 44 行＋存置 5 行の再判定。発火はユーザーの棚卸し指示のみ（常設化しない）
8. [ ] その他の既存 backlog: Issue-0089（指定席の命名・索引）/ Issue-0075（実効性観点）/ Issue-0090（残る成長型成果物）/ Issue-0045（open 課題の実行可能性点検。open 48 件）/ Issue-0008（旧型式 spec の方針）/ Issue-0070/0071/0077 ほか低優先課題群 / Issue-0028（v2 テーマ）

## 既知のブロッカー・懸念

- **配布元が `dist/` へ切り替わっている**（ADR-0082）。`skills/` を編集しただけでは動くスキルは変わらない。`scripts/build-dist.ps1` で再生成し、生成物も同じコミットへ。手順は `CONTRIBUTING.md` の執行点（4 手順）
- **規約に適合していても配布物が壊れる型が 5 つある**（ADR-0084）。生成後の配布物を読む工程を別に置くこと
- **確定前レビューの提示規則**（ADR-0080）・**サイクル全体整合検査**（ADR-0092/0099）・**新設の評価可能性**（ADR-0102）が稼働中。確定点で `review=`、Accepted 昇格で `cyclecheck=` を消化記録へ。正本の所在: 検出トリガー・記述規律＝decision-log、消化記録・「本サイクル」定義＝session-handoff、起票・採番＝issue-management 節 3、仕様書運用＝folder-structure 節 7、レビュー発動・提示規則＝start-work
- **レビュー指摘の反映後は、確定前に「再レビュー / 差分再確認 / このまま確定」を必ず並記して確認**（Issue-0098 起票の経緯。改訂が新規の規範文・設計を含むなら再レビューを推奨側に置く）
- **Issue 運用の新規範が稼働中**（ADR-0095〜0098 の決定群）: 課題ファイルへ追記したらサイズ実測（目安 10KB）、超過なら昇格提案。フォルダ昇格済み課題の close 時は移設判定必須。正本は `docs/overview/issue-management.md`
- **Issue-0098 のファイルが約 11.4KB で目安 10KB を超過**。フォルダ昇格は Issue-0098 対策サイクル着手時にユーザー判断（2026-08-17 確認済み・再提案不要）
- **decision-log の昇格条件要約は、課題管理定義の改定時に同時更新が必要**（意図された配線。ADR-0098 の複写乖離型の監視点）
- **未完の後始末（過去サイクル分）**: 改定スキル（decision-log）の本文と repo 実ファイルの突合、課題管理定義の既存配布先への手動コピーが未実施のままなら次セッションで
- **リモート同期**: `0c6adf6`（master handoff 同期・Issue-0102 起票）まで push 済み（2026-08-18。ユーザー指示）。以降の未 push は本同期更新コミットのみ（直後に push 済み）
- **プラグインは 0.1.9 へ更新済み**（installed_plugins.json 実測・SHA `11e9beb`）。ただし update 前に起動した CLI セッションはスラッシュコマンド索引が旧版（0.1.6）を掴む（2026-08-18 実測。`/clear` では再構築されない）。**セッション再起動で解消**
- **クロス repo の課題参照は `<repo>#Issue-NNNN` で修飾**（ADR-0068）
- **PowerShell / .NET API の実測済み落とし穴は `docs/reference/powershell-pitfalls.md` を参照**
- **中央ストアの現状**: 本 repo 79 件（〜`MakeAiInstructions-2026-08-17-06`）＋ LoopForAlpha 190 件 ＋ OrderAutomateSupporter 4 件。`projects.json` lastSeen 2026-08-17
- **検証用プラグイン `ai-driven-dev-principles-probe` の記録が残っている**（実体なし。片付けはユーザースコープのアンインストール）
- **inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定**。organize-inbox 提案は不要。`git add <ディレクトリ>` で巻き込まないこと（Issue-0020）
- **docs 配下へ新規ファイルを作らせる委譲では、Write ガードの迂回手段（Python 経由）を指示に明示**（worklog `MakeAiInstructions-2026-08-16-05`。Task 8 で 2 回実測）
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` は確認済みだが、事象確認済みモデル（Fable 5）では構造化質問ツール自体を使用しない（ADR-0085）
- ADR-0023 の留意（継続): GitHub.com の Copilot コーディングエージェントがルート `CLAUDE.md` を読まない可能性

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。形式は `skills/session-handoff/SKILL.md` のフォーマット節を参照。直近サイクル中の分は git 履歴（`36f23de` 以前・`feature_issue-0084-wire-no-ff-merge.md`）参照。

- 2026-08-18 master handoff 事後同期・Issue-0102 起票: ADR=なし（課題管理定義の既定運用の適用のみ・新規決定なし） / worklog=棄却（構造観察型として Issue-0102 へ起票。delta 型ではない）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: セッション再起動（プラグイン索引を 0.1.9 で再構築）→ `start-work`（Phase 0 で本ハンドオフを read）
2. **リモート同期**: push 済み・未 push なし（`0c6adf6` とその同期更新コミットまで）
3. **次サイクルの候補（着手はユーザー判断）**: 目安の優先順は「未着手のタスク」参照。**Issue-0101**（小規模）/ **Issue-0098**（実測蓄積・昇格判断も）/ **Issue-0100**（小規模）/ **Issue-0102**（新規）
4. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **配布対象ソースを変更したら執行点 4 手順**（`CONTRIBUTING.md`）。スキル改定は version bump も必須（ADR-0090。現行 0.1.9）
   - **ガイドライン拡張時は過剰適合点検が必須**（ADR-0079/0099）。**新設を含む ADR は評価可能性の記載要件（比較・期待検出量・向き付き退役条件）も必須**（ADR-0102 決定。CONTRIBUTING「全シナリオ共通: 新設の評価可能性」）
   - **確定点（spec / plan）で確定前レビューを提示し `review=` を記録**（ADR-0080。正本は start-work「確定前レビューの提示規則」）。**レビュー指摘の反映後は再レビュー要否を必ず並記**（Issue-0098）。**Accepted 昇格前はサイクル全体整合検査**（ADR-0092/0099。マイルストーン名に `Accepted 昇格` を含める）
   - **Issue へ追記したらサイズ実測・close 時は移設判定**（課題管理定義 `docs/overview/issue-management.md` が正）
   - サブエージェント委譲時は `subagent-dispatch`（判定行必須）。**再委譲・再レビューでは前提値を委譲直前に再実測して渡す**（worklog `MakeAiInstructions-2026-08-15-06`）。**数値は書く直前に計数コマンドで実測し、レビュー指摘は帰属まで裏取りして適用**（worklog `MakeAiInstructions-2026-08-17-01`/`-03`）
   - **レビューの差分範囲は対象コミットの直前..対象で取る**（worklog `MakeAiInstructions-2026-08-16-06`。中間コミットの誤帰属を実測）
   - **統合・削除系の plan では、除去される側の文言でも全 spec を逐語 grep して母集団を固定し、定義語の供給元を消すタスクへ使用箇所側の配線を同梱する**（worklog `MakeAiInstructions-2026-08-17-05`/`-06`）
   - Post ラッパーは1項目ずつ消し込み、結果を消化記録へ（ADR-0057）。worklog id は全体を書く
   - コミット前に `git status --short` と staged 確認。**コミットは pathspec 付き `git commit -- <paths>` が安全**（Issue-0020）。未追跡ファイルは先に `git add` が必要（pathspec commit は未追跡に効かない。2026-08-16 実測）
   - マルチライン文字列は `git commit -F <絶対パス>`（Issue-0015）。**-F のパスはコピーで再利用し打ち直さない**
   - インデックス・台帳へ行を追加する前に挿入位置（表の終端・並び順）を実体確認（worklog `MakeAiInstructions-2026-08-15-03`）
   - ハンドオフの剪定は finalize で基準付き圧縮、サイクル完了時に cycle-reset（ADR-0075）。**cycle-reset の適用先は現在ブランチの handoff。feature 側は `completed` で閉じる**（Issue-0102 の応急規範。恒久配線は同課題で設計）

## 重要な意思決定の履歴

- ADR-0106: マージコミット規範の再発防止＝予防・検出 2 層配線＋git 設定＋ff やり直し（2026-08-17 Accepted）
- （ADR-0001〜0105 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
