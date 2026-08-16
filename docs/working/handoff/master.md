# Handoff: Issue-0092 全数監査サイクル完了・次サイクル待ち

- **Branch**: master（feature/issue-0092-guideline-audit を --no-ff で取り込み。マージコミット `cbda17c`）
- **Last Updated**: 2026-08-16 21:20 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: サイクル完了（retrospective・cycle-reset 済み）。push と次サイクル着手はユーザー判断

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AI駆動開発ガイドライン（5原則 + スキル群 + ADR。AIエージェントと協働して開発を進めるための、原則・行動指示・スキルの体系）を整備するプロジェクト。

**直近サイクル（2026-08-16: Issue-0092 対応）**: 「確率的逸脱は残る」前提でのガイドライン全数監査を一回限りの調査として実施（ADR-0100 が方法、ADR-0101 が判定。ともに Accepted）。常時発火規範の全数台帳 155 レコード（対象 141）を二トラックで判定し、keep 72 / 統合 22 / 保留（観測継続）44 / 簡素化 3 / **退役 0** を確定。検出力実証（実証 9 / 未実証 3 / 反証 1）を初導入。増設の歯止めは強い形（新設禁止）を不採用とし「評価可能性の義務化（弱い形）」で確定（規範化は Issue-0096）。改修は Issue-0093〜0095、保留は Issue-0097 へ委譲し Issue-0092 close。監査記録の正本は `docs/records/audits/2026-08-16-guideline-process-audit/`（確定・以後不変）。次サイクル着手はユーザー判断待ち。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open 計 48 件。2026-08-16 実測: 前回 44 − close 1 ＋ 起票 5）
- 課題管理の運用規範の正本: `docs/overview/issue-management.md`（課題管理定義）
- 直近サイクルの監査記録: `docs/records/audits/2026-08-16-guideline-process-audit/`（`ledger.md` 台帳・`report.md` 報告。確定後不変）
- 直近サイクルの retrospective: `docs/records/retrospectives/system/2026-08-16-issue-0092-guideline-audit.md`（flow 新規起票なし）
- 直近サイクルの決定: ADR-0100（監査方法。設計文書を兼ねる）・ADR-0101（判定と歯止め）。実装計画は `docs/working/plans/2026-08-16-issue-0092-guideline-audit-plan.md`
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0101。Rejected 3件）
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

1. [ ] **Issue-0096**（flow・軽量）: 増設の歯止め（評価可能性の義務化・弱い形）の CONTRIBUTING への規範化。**内容は ADR-0101 決定 3 で確定済み**で残りは配置と文言のみ。監査の直接の帰結であり早期に畳むほど効く
2. [ ] **Issue-0093**（flow・中〜大）: 監査で特定した二重定義 22 行の統合（クラスタ単位で分割着手可。統合先案は report 1-6）。CLAUDE.md と start-work に集中
3. [ ] **Issue-0094**（flow・小）: 高コスト様式 3 行の簡素化（C-11 / D-11 / I-17。0093 の K6 と同時が自然）
4. [ ] **Issue-0084**（flow）: --no-ff の完了フロー配線。**6 サイクル連続で手動適用**（直近 `cbda17c`）
5. [ ] **Issue-0095**（flow）: A-13（計画の期待値突合）の再設計。検出力反証済み。Issue-0056・0073 と同時対策
6. [ ] **Issue-0072**（system）: 半角括弧の同一視。1 行修正で塞げることまで確認済み（軽量に畳む候補）
7. [ ] **Issue-0097**（flow・待機）: 保留 44 行の再判定。発火はユーザーの棚卸し指示のみ（常設化しない）
8. [ ] その他の既存 backlog: Issue-0089（指定席の命名・索引）/ Issue-0075（実効性観点）/ Issue-0090（残る成長型成果物）/ Issue-0045（open 課題の実行可能性点検。open 48 件）/ Issue-0070/0071/0077 ほか低優先課題群 / Issue-0028（v2 テーマ）

## 既知のブロッカー・懸念

- **配布元が `dist/` へ切り替わっている**（ADR-0082）。`skills/` を編集しただけでは動くスキルは変わらない。`scripts/build-dist.ps1` で再生成し、生成物も同じコミットへ。手順は `CONTRIBUTING.md` の執行点（4 手順）
- **規約に適合していても配布物が壊れる型が 5 つある**（ADR-0084）。生成後の配布物を読む工程を別に置くこと
- **確定前レビューの提示規則**（ADR-0080）と**サイクル全体整合検査**（ADR-0092/0099）が稼働中。確定点で `review=`、Accepted 昇格で `cyclecheck=` を消化記録へ
- **Issue 運用の新規範が稼働中**（ADR-0095〜0098）: 課題ファイルへ追記したらサイズ実測（目安 10KB）、超過なら昇格提案。フォルダ昇格済み課題の close 時は移設判定必須。正本は `docs/overview/issue-management.md`
- **decision-log の昇格条件要約は、課題管理定義の改定時に同時更新が必要**（意図された配線。ADR-0098 の複写乖離型の監視点）
- **未完の後始末（前々サイクル分）**: 改定スキル（decision-log）の本文と repo 実ファイルの突合、課題管理定義の既存配布先への手動コピーが未実施のままなら次セッションで
- **リモート同期**: `origin/master` は Issue-0092 起票時点まで。**本サイクル分（監査一式・マージ `cbda17c`）は未 push**。push はユーザー指示で実施
- **クロス repo の課題参照は `<repo>#Issue-NNNN` で修飾**（ADR-0068）
- **PowerShell / .NET API の実測済み落とし穴は `docs/reference/powershell-pitfalls.md` を参照**
- **中央ストアの現状**: 本 repo 73 件（〜`MakeAiInstructions-2026-08-16-07`）＋ LoopForAlpha 190 件 ＋ OrderAutomateSupporter 4 件。`projects.json` lastSeen 2026-08-16
- **検証用プラグイン `ai-driven-dev-principles-probe` の記録が残っている**（実体なし。片付けはユーザースコープのアンインストール）
- **inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定**。organize-inbox 提案は不要。`git add <ディレクトリ>` で巻き込まないこと（Issue-0020）
- **docs 配下へ新規ファイルを作らせる委譲では、Write ガードの迂回手段（Python 経由）を指示に明示**（worklog `MakeAiInstructions-2026-08-16-05`。Task 8 で 2 回実測）
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` は確認済みだが、事象確認済みモデル（Fable 5）では構造化質問ツール自体を使用しない（ADR-0085）
- ADR-0023 の留意（継続): GitHub.com の Copilot コーディングエージェントがルート `CLAUDE.md` を読まない可能性

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。形式は `skills/session-handoff/SKILL.md` のフォーマット節を参照。直近サイクル中の分は `feature_issue-0092-guideline-audit.md` 参照（retrospective Phase 3 で突合済み・未消化なし）。

- 2026-08-16 セッション終了処理（retrospective・cycle-reset 後）: ADR=なし（新規決定なし） / worklog=棄却（`MakeAiInstructions-2026-08-16-04`〜`-07` で記録済み・追加 delta なし）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **未 push の確認**: 本サイクル分（マージ `cbda17c` まで＋cycle-reset コミット）が `origin/master` へ未 push。区切りとして push するかユーザーに確認
3. **次サイクルの候補（着手はユーザー判断）**: 抽出した課題は issues に起票済み（Issue-0093〜0097。着手はユーザー判断）。目安の優先順: 軽量で監査の直接の帰結である **Issue-0096**（歯止めの規範化。内容確定済み）→ **Issue-0093**（統合 22 行。分割着手可）→ **Issue-0084**（6 サイクル連続の手動 --no-ff）。軽量に畳むなら **Issue-0072** / **Issue-0094**
4. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **配布対象ソースを変更したら執行点 4 手順**（`CONTRIBUTING.md`）。スキル改定は version bump も必須（ADR-0090）
   - **ガイドライン拡張時は過剰適合点検が必須**（ADR-0079/0099）。Issue-0096 実装後は評価可能性（期待検出量・観測可能な退役条件）の明記も
   - **確定点（spec / plan）で確定前レビューを提示し `review=` を記録**（ADR-0080）。**Accepted 昇格前はサイクル全体整合検査**（ADR-0092/0099。マイルストーン名に `Accepted 昇格` を含める）
   - **Issue へ追記したらサイズ実測・close 時は移設判定**（課題管理定義 `docs/overview/issue-management.md` が正）
   - サブエージェント委譲時は `subagent-dispatch`（判定行必須）。**再委譲・再レビューでは前提値を委譲直前に再実測して渡す**（worklog `MakeAiInstructions-2026-08-15-06`）。**委譲指示に書く派生期待値は暗算せず、書く前にコマンドで確認**（worklog `MakeAiInstructions-2026-08-16-04`。本サイクルで 3 回誤り実測）
   - **レビューの差分範囲は対象コミットの直前..対象で取る**（worklog `MakeAiInstructions-2026-08-16-06`。中間コミットの誤帰属を実測）
   - Post ラッパーは1項目ずつ消し込み、結果を消化記録へ（ADR-0057）。worklog id は全体を書く
   - コミット前に `git status --short` と staged 確認。**コミットは pathspec 付き `git commit -- <paths>` が安全**（Issue-0020）
   - マルチライン文字列は `git commit -F <絶対パス>`（Issue-0015）。**-F のパスはコピーで再利用し打ち直さない**
   - インデックス・台帳へ行を追加する前に挿入位置（表の終端・並び順）を実体確認（worklog `MakeAiInstructions-2026-08-15-03`）
   - ハンドオフの剪定は finalize で基準付き圧縮、サイクル完了時に cycle-reset（ADR-0075）

## 重要な意思決定の履歴

- ADR-0100: 全体棚卸しは常時発火規範の全数台帳と二トラック判定による一回限りの監査として実施する。2026-08-16 Accepted
- ADR-0101: 監査の判定を keep 72・統合 22・保留 44・簡素化 3・退役 0 で確定し、増設の歯止めは評価可能性の義務化（弱い形）とする。2026-08-16 Accepted
- （ADR-0001〜0099 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
