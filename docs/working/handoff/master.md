# Handoff: start-work 責務分割サイクル完了・次サイクル待ち

- **Branch**: master（feature/start-work-responsibility-split を --no-ff で取り込み。マージコミット `5c1ac0e`）
- **Last Updated**: 2026-08-28 23:30 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: サイクル完了（retrospective・cycle-reset 済み）。次サイクル着手はユーザー判断

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AI駆動開発ガイドライン（5原則 + スキル群 + ADR。AIエージェントと協働して開発を進めるための、原則・行動指示・スキルの体系）を整備するプロジェクト。

**直近サイクル（2026-08-28〜29: start-work 責務分割）**: start-work の本文約 6 割を占めたドメイン規範 2 節を責務帰属で移設した（ADR-0115/0116）。「確定前レビューの提示規則」16,771B は pre-finalization-review へ（提示操作・実施操作の 2 操作構成へ改組。確定点・提示・反復・停止判定の正本は同スキル）、「完了処理のマージ方式確認」4,270B は `skills/start-work/references/merge-practice.md` へ。start-work は 34,676B → 14,456B のオーケストレーション＋発火点ポインタに残留化。張り替え 9＋4＋2 箇所・ADR 部分修正注記 7 件・plugin 0.1.13。実装時の独立レビュー（claude-opus-5・32 ファイル全数）が整合検査の見落とした Important 1 を検出し反映＝実質収束と実装時レビューの補完関係の初実測（Issue-0107 事例 9）。次サイクル着手はユーザー判断待ち。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open 計 55 件。2026-08-29 実測: 前回 54 ＋ 新規起票 1〈0111〉・close 0）
- 課題管理の運用規範の正本: `docs/overview/issue-management.md`（課題管理定義）
- 直近サイクルの決定: ADR-0115/0116。設計 spec: `docs/current/specs/2026-08-28-start-work-responsibility-split-design.md`。retrospective: `docs/records/retrospectives/system/2026-08-29-start-work-responsibility-split.md`（system のみ）。実装 plan: `docs/working/plans/2026-08-28-start-work-responsibility-split-implementation.md`
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0116。Rejected 3 件・部分修正注記は ADR-0116 由来 7 件を含む）
- 記法規約と執行点: `CONTRIBUTING.md`「全シナリオ共通: 配布対象ソースの記法規約」
- worklog スキーマ正典: `skills/worklog-record/references/store-format.md`（v2）
- 原則: `docs/overview/principles.md` / **Layer 2: `AGENTS.md`（`CLAUDE.md` は `@AGENTS.md` の 1 行）** / 拡張ルール: `CONTRIBUTING.md`
- PowerShell / .NET API の落とし穴集: `docs/reference/powershell-pitfalls.md`

## 完了済みタスク

- [x] 過去サイクルは retrospective（`docs/records/retrospectives/README.md`）/ git 履歴参照

## 進行中のタスク

（なし。サイクル完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化。次サイクルの候補として目安を示す:

1. [ ] **Issue-0110**（flow）: 確定済み計画からの逸脱判断の既定が無い。Codex 対応サイクルで 4 回発生し採用基準を事後に固定して収束。Issue-0103 と隣接
2. [ ] **Issue-0109**（flow）: Layer 3 の退行確認がマージ・push 後にしか実行できない。プレフライト手段の設計
3. [ ] **Issue-0108**（system）: `build-dist.ps1` の見送り指摘 4 群（C0 制御文字・`.agents/` の stale 未検出・保守性・1 要素配列の素通り）。同ファイルを次に触るサイクルでまとめて処理するのが自然
4. [ ] **Issue-0111**（system・新規）: merge-practice.md 冒頭の導入文重複（軽微。配布対象のため執行点・version bump 対象。他の配布物修正と同サイクルが自然）
5. [ ] **Issue-0102**（flow）: マージ後の cycle-reset の適用先 handoff の明示配線（応急規範は 5 サイクル連続で機能。恒久対策未着手）
6. [ ] **Issue-0095 / 0073 / 0056**（flow）: 計画の検証期待値の突合・陳腐化・実行可能性。3 件同時対策が前提
7. [ ] **Issue-0107**（flow）: 反復レビューの推奨規範の乖離（乖離事例 9 件＋一般観察 3 件を記録済み。事例 9 = 実装時レビューとの補完関係の初実測）
8. [ ] **Issue-0101 / 0100 / 0104 / 0103 / 0105 / 0106**（flow）: 旧設計仕様書の図示乖離（本サイクルで拡大・追記済み） / 配線行の可変数値 / R1-a 型の機械検出 / 反復のコスト予算（実測追記済み） / SKILL.md サイズ規範（分割実例追記済み） / 退避領域の掃除規定
9. [ ] **Issue-0097 / Issue-0099**（flow・待機）: 保留 44 行＋存置 5 行の再判定。発火はユーザーの棚卸し指示のみ
10. [ ] その他の既存 backlog: Issue-0072（半角括弧・軽量）/ Issue-0089 / Issue-0075 / Issue-0090 / Issue-0045 / Issue-0008 / Issue-0070/0071/0077 ほか低優先課題群 / Issue-0028（v2 テーマ）

## 既知のブロッカー・懸念

- **Layer 2 の内容正本は `AGENTS.md`**（ADR-0111）。`CLAUDE.md` は `@AGENTS.md` の 1 行のポインタで、内容を書き足さないこと。Codex は `AGENTS.md` を直読み、Claude Code はインポート経由、Copilot CLI は両方を結合読み
- **既存プロジェクトの移行手順は README の「既存プロジェクトを AGENTS.md 構成へ移行する」節**。template を再コピーする前に固有指示を `AGENTS.md` へ退避しないと消える。未移行プロジェクトを検知する機構は無い（ADR-0114 で受容）
- **配布元が `dist/` へ切り替わっている**（ADR-0082）。`skills/` を編集しただけでは動くスキルは変わらない。`scripts/build-dist.ps1` で再生成し、生成物も同じコミットへ。**ルートの `.agents/plugins/marketplace.json` も生成物**（手編集しない）。手順は `CONTRIBUTING.md` の執行点（4 手順）
- **規約に適合していても配布物が壊れる型がある**（ADR-0084）。生成後の配布物を読む工程を別に置くこと。R1-a 型の機械検出は Issue-0104
- **Layer 3 の退行確認はマージ・push 後にしか実行できない**（Issue-0109）。マーケットプレイス登録が GitHub 経由のため、feature ブランチの内容は `marketplace update` に降りてこない
- **質問はテキストの番号付き選択肢のみ**（ADR-0109）。構造化質問ツールは全ツール・全モデルで使用しない
- **確定前レビューの提示規則＋指摘反映後の反復規範**（ADR-0080/0107）・**サイクル全体整合検査**（ADR-0092/0099）・**新設の評価可能性**（ADR-0102）・**Accepted 後改訂の改訂記録規定**（ADR-0108）が稼働中。確定点で `review=`、Accepted 昇格で `cyclecheck=` を消化記録へ。**提示規則・反復・停止判定の正本は ADR-0116 により pre-finalization-review（提示操作）へ、マージ方式確認の正本は `skills/start-work/references/merge-practice.md` へ移設済み**（start-work は発火点ポインタのみ）
- **Issue 運用の規範が稼働中**（ADR-0095〜0098): 課題ファイルへ追記したらサイズ実測（目安 10KB）、超過なら昇格提案。フォルダ昇格済み課題の close 時は移設判定必須
- **リモート同期**: `a9bc086` まで push 済み。**`master` はローカルが 12 コミット ahead**（本サイクル一式＋前サイクルの記録分）。push はユーザー指示時。**Codex への配布は push＋marketplace update までは旧 0.1.12 のまま**（ローカルは 0.1.13）
- **inbox に未整理 3 件が滞留**: `docs/inbox/` の 3 ファイル（いずれも未追跡）。`docs/conversation_log.md` も未追跡のまま。**ユーザーが手動移動予定のため organize-inbox の提案は不要**。`git add <ディレクトリ>` で巻き込まないこと（Issue-0020）
- **Codex に本プラグインを GitHub 経由で登録済み**（実運用状態。配布版は push まで 0.1.12）。取り消すなら `codex plugin remove` ＋ `codex plugin marketplace remove`
- **Copilot CLI は未契約**のため、同ツール向けの検証（Layer 2・Layer 3 の退行確認）が恒久的に実行できない。3 ツール対応を謳う以上、片方が検証不能なまま続く
- **改訂前退避の恒久領域 `~/.ai-dev-review-snapshots/` に 29 世代が残置**（本サイクル分 `2026-08-28-start-work-responsibility-split/` を含む）。掃除規定は Issue-0106。当面は手動判断
- **中央ストアの現状**: 本 repo 111 件（〜`MakeAiInstructions-2026-08-29-01`。2026-08-29 実測）
- **クロス repo の課題参照は `<repo>#Issue-NNNN` で修飾**（ADR-0068）
- **PowerShell / .NET API の実測済み落とし穴は `docs/reference/powershell-pitfalls.md` を参照**
- ADR-0023 の留意（継続): GitHub.com の Copilot コーディングエージェントがルート `CLAUDE.md` を読まない可能性

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。形式は `skills/session-handoff/SKILL.md` のフォーマット節を参照。直近サイクル中の分は git 履歴（`feature_start-work-responsibility-split.md`）参照。

- 2026-08-29 サイクル完了処理（マージ 5c1ac0e・retrospective・cycle-reset・Issue-0111 起票）: ADR=なし（完了処理と記録のみ） / worklog=棄却（delta なし。確立済みフローどおり）

## 次セッション開始時のアクション

1. **最初に実行**: `start-work`（Phase 0 で本ハンドオフを read）。**ローカル master が 12 コミット ahead** のため、必要なら先に `git push origin master`（push で Codex 配布側も 0.1.13 へ）
2. **抽出した課題は issues に起票済み**（Issue-0111。着手はユーザー判断）。優先順の目安は「未着手のタスク」参照
3. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **Layer 2 へ固有指示を書くときは `AGENTS.md`**（`CLAUDE.md` はポインタのまま）
   - **配布対象ソースを変更したら執行点 4 手順**（`CONTRIBUTING.md`）。スキル改定は version bump も必須（ADR-0090。現行 0.1.13）
   - **ガイドライン拡張時は過剰適合点検＋新設の評価可能性が必須**（ADR-0079/0099/0102）
   - **確定点で確定前レビューを提示し、指摘反映後は反復提示**（ADR-0080/0107）。**Accepted 昇格前はサイクル全体整合検査**（ADR-0092/0099）。**Accepted 済み ADR 本文を改訂したら改訂記録規定**（ADR-0108）
   - サブエージェント委譲時は `subagent-dispatch`（判定行必須）。**再委譲・再レビューでは前提値を委譲直前に再実測して渡す**。**数値・ファイルパス・名称は書く直前に実測する**（Issue-0095 の教訓）
   - **計画の検証コマンドは書いたら実行してから確定する**（本サイクルで同一セッション内に 2 度再発。worklog `-02` / `-10`）
   - **インデックス・台帳へ行を追加する前に挿入位置を実体確認**（表がファイル末尾にあるとは限らない。本サイクルで再発。worklog `-24`）
   - Post ラッパーは1項目ずつ消し込み、結果を消化記録へ（ADR-0057）。worklog id は全体を書く
   - コミット前に `git status --short` と staged 確認。**コミットは pathspec 付きが安全**（Issue-0020）
   - ハンドオフの剪定は finalize で基準付き圧縮、サイクル完了時に cycle-reset（ADR-0075）。**cycle-reset の適用先は現在ブランチの handoff。feature 側は `completed` で閉じる**（Issue-0102 の応急規範）

## 重要な意思決定の履歴

- ADR-0116: start-work のドメイン規範 2 節は責務帰属で移設し、提示規則は pre-finalization-review へ・マージ方式確認は references へ移す（2026-08-28 Accepted。実装時レビュー由来の改訂記録 1 件）
- ADR-0115: start-work 責務過多の解消サイクルは分割の実施に集中し、SKILL.md サイズ・分割の一般規範は扱わない（2026-08-28 Accepted）
- （ADR-0001〜0114 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
