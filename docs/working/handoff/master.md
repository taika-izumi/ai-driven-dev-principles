# Handoff: Issue-0098 反復基準サイクル完了・次サイクル待ち

- **Branch**: master（feature/issue-0098-iterative-review-criteria を --no-ff で取り込み。マージコミット `976b45c`）
- **Last Updated**: 2026-08-18 17:40 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: サイクル完了（retrospective・cycle-reset 済み）。次サイクル着手はユーザー判断

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AI駆動開発ガイドライン（5原則 + スキル群 + ADR。AIエージェントと協働して開発を進めるための、原則・行動指示・スキルの体系）を整備するプロジェクト。

**直近サイクル（2026-08-18: Issue-0098 対応）**: 確定前レビューの反復（指摘反映後の再レビュー）の発動・停止・実施・記録基準を ADR-0107/0108 として設計・実装。規範自身への先行適用がフル 12 巡＋差分確認 1 巡＋機械検証・設計縮小 5 回という最深の反復実測になり（停止の転換点はユーザー介入）、start-work「4. 指摘反映後の反復」・pre-finalization-review「反復の実施」・session-handoff「`review=` の値定義」・decision-log 改訂記録規定として plugin 0.1.10 で配布。ADR-0107/0108 Accepted・Issue-0098 close・Issue-0103〜0106 起票。次サイクル着手はユーザー判断待ち。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open 計 51 件。2026-08-18 実測: 前回 48 − close 1〈0098〉＋ 起票 4〈0103〜0106〉）
- 課題管理の運用規範の正本: `docs/overview/issue-management.md`（課題管理定義）
- 直近サイクルの決定: ADR-0107（反復基準・設計文書兼用）/ ADR-0108（Accepted 後改訂のステータス運用）。retrospective: `docs/records/retrospectives/system|flow/2026-08-18-issue-0098-iterative-review-criteria.md`。実装 plan: `docs/working/plans/2026-08-18-issue-0098-adr-0107-0108-implementation.md`。反復の一次記録: `docs/working/issues/flow/0098-iterative-review-trigger-criteria/0098-log.md`
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0108。Rejected 3件）
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
2. [ ] **Issue-0102**（flow）: マージ後の cycle-reset の適用先 handoff の明示配線（応急規範は 2 サイクル連続で機能。恒久対策未着手）
3. [ ] **Issue-0100**（flow）: 配線行に可変数値を書かない規律の恒久規範化（有効性実測済み・小規模）
4. [ ] **Issue-0104**（flow・新規）: 識別子除去後の文法破綻（R1-a 型）の機械検出（実測 3 件・目視依存の解消）
5. [ ] **Issue-0103**（flow・新規）: 確定前レビュー反復のコスト・巡数の予算基準（ADR-0107 の運用実測が貯まってからの設計も選択肢）
6. [ ] **Issue-0105 / 0106**（flow・新規）: SKILL.md サイズ規範 / 退避領域の掃除規定
7. [ ] **Issue-0095**（flow）: A-13（計画の期待値突合）の再設計。再発 2 回目。Issue-0056・0073 と同時対策
8. [ ] **Issue-0097 / Issue-0099**（flow・待機）: 保留 44 行＋存置 5 行（3-2 準用 3 重記載を追加済み）の再判定。発火はユーザーの棚卸し指示のみ
9. [ ] その他の既存 backlog: Issue-0072（半角括弧・軽量）/ Issue-0089 / Issue-0075 / Issue-0090 / Issue-0045 / Issue-0008 / Issue-0070/0071/0077 ほか低優先課題群 / Issue-0028（v2 テーマ）

## 既知のブロッカー・懸念

- **配布元が `dist/` へ切り替わっている**（ADR-0082）。`skills/` を編集しただけでは動くスキルは変わらない。`scripts/build-dist.ps1` で再生成し、生成物も同じコミットへ。手順は `CONTRIBUTING.md` の執行点（4 手順）
- **規約に適合していても配布物が壊れる型がある**（ADR-0084）。生成後の配布物を読む工程を別に置くこと。2026-08-18 に R1-a 型（識別子が文の文法要素）3 件を目視が捕捉（機械検出は Issue-0104）
- **確定前レビューの提示規則＋指摘反映後の反復規範**（ADR-0080/0107）・**サイクル全体整合検査**（ADR-0092/0099）・**新設の評価可能性**（ADR-0102）・**Accepted 後改訂の改訂記録規定**（ADR-0108）が稼働中。確定点で `review=`（方式連結＋終了状態の新形式）、Accepted 昇格で `cyclecheck=` を消化記録へ。正本の所在: 反復の発動・推奨・停止＝start-work「4. 指摘反映後の反復」、実施方式＝pre-finalization-review「反復の実施」、`review=` 値＝session-handoff「`review=` の値定義」、改訂記録＝decision-log「ステータス変更」
- **Issue 運用の規範が稼働中**（ADR-0095〜0098）: 課題ファイルへ追記したらサイズ実測（目安 10KB）、超過なら昇格提案。フォルダ昇格済み課題の close 時は移設判定必須。正本は `docs/overview/issue-management.md`
- **decision-log の昇格条件要約は、課題管理定義の改定時に同時更新が必要**（意図された配線。ADR-0098 の複写乖離型の監視点）
- **未完の後始末（過去サイクル分）**: 改定スキル（decision-log）の本文と repo 実ファイルの突合、課題管理定義の既存配布先への手動コピーが未実施のままなら次セッションで
- **リモート同期**: `efc66fe`（cycle-reset）まで push 済み（2026-08-18・ユーザー指示）。未 push はリモート同期状態の本更新コミットのみ（直後に push）
- **プラグイン実体は 0.1.9 のまま**。0.1.10 の反映には `/plugin marketplace update ai-driven-dev-principles`（AI からは実行不可）とセッション再起動（索引再構築）が必要
- **クロス repo の課題参照は `<repo>#Issue-NNNN` で修飾**（ADR-0068）
- **PowerShell / .NET API の実測済み落とし穴は `docs/reference/powershell-pitfalls.md` を参照**
- **中央ストアの現状**: 本 repo 80 件（〜`MakeAiInstructions-2026-08-18-01`）＋ LoopForAlpha 190 件 ＋ OrderAutomateSupporter 4 件
- **改訂前退避の恒久領域 `~/.ai-dev-review-snapshots/` に本サイクルの 5 世代が残置**（掃除規定は Issue-0106。当面は手動判断）
- **検証用プラグイン `ai-driven-dev-principles-probe` の記録が残っている**（実体なし。片付けはユーザースコープのアンインストール）
- **inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定**。organize-inbox 提案は不要。`git add <ディレクトリ>` で巻き込まないこと（Issue-0020）
- **docs 配下へ新規ファイルを作らせる委譲では、Write ガードの迂回手段（Python 経由）を指示に明示**（worklog `MakeAiInstructions-2026-08-16-05`）
- 構造化質問ツールは全ツール・全モデルで廃止（ADR-0109）。質問はテキストの番号付き選択肢のみ。`CLAUDE_CODE_DISABLE_MOUSE_CLICKS` は撤去済み（クリック操作は再有効化）
- ADR-0023 の留意（継続): GitHub.com の Copilot コーディングエージェントがルート `CLAUDE.md` を読まない可能性

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。形式は `skills/session-handoff/SKILL.md` のフォーマット節を参照。直近サイクル中の分は git 履歴（`feature_issue-0098-iterative-review-criteria.md`）参照。

- 2026-08-18 retrospective 実施・cycle-reset: ADR=なし（課題抽出のみ・対策設計なし） / worklog=棄却（セッション終了時判定含め新規 delta なし。総ざらいは消化記録 14 行×ストア突合で漏れゼロ）

## 次セッション開始時のアクション

1. **最初に実行**: `/plugin marketplace update ai-driven-dev-principles` ＋ セッション再起動（プラグイン索引を 0.1.10 で再構築）→ `start-work`（Phase 0 で本ハンドオフを read）
2. **リモート同期**: push 済み・未 push なし（`efc66fe` とその同期更新コミットまで）
3. **次サイクルの候補（着手はユーザー判断）**: 抽出した課題は issues に起票済み（Issue-0103〜0106。着手はユーザー判断）。目安の優先順は「未着手のタスク」参照
4. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **配布対象ソースを変更したら執行点 4 手順**（`CONTRIBUTING.md`）。スキル改定は version bump も必須（ADR-0090。現行 0.1.10）
   - **ガイドライン拡張時は過剰適合点検＋新設の評価可能性が必須**（ADR-0079/0099/0102）
   - **確定点で確定前レビューを提示し、指摘反映後は反復提示**（ADR-0080/0107。正本は start-work）。**Accepted 昇格前はサイクル全体整合検査**（ADR-0092/0099。マイルストーン名に `Accepted 昇格` を含める）。**Accepted 済み ADR 本文を改訂したら改訂記録規定**（ADR-0108）
   - **Issue へ追記したらサイズ実測・close 時は移設判定**（課題管理定義が正）
   - サブエージェント委譲時は `subagent-dispatch`（判定行必須）。**再委譲・再レビューでは前提値を委譲直前に再実測して渡す**。**数値は書く直前に計数コマンドで実測し、検証期待値は出現数（`-AllMatches`）で数える**（Issue-0095 再発 2 回の教訓）
   - **レビューの差分範囲は対象コミットの直前..対象で取る**（worklog `MakeAiInstructions-2026-08-16-06`）
   - Post ラッパーは1項目ずつ消し込み、結果を消化記録へ（ADR-0057）。worklog id は全体を書く
   - コミット前に `git status --short` と staged 確認。**コミットは pathspec 付き `git commit -- <paths>` が安全**（Issue-0020）。マルチライン文字列は `git commit -F <絶対パス>`（Issue-0015）
   - インデックス・台帳へ行を追加する前に挿入位置（表の終端・並び順）を実体確認（2026-08-18 にも retrospectives README で時系列順の誤挿入を自己検出・即修正）
   - ハンドオフの剪定は finalize で基準付き圧縮、サイクル完了時に cycle-reset（ADR-0075）。**cycle-reset の適用先は現在ブランチの handoff。feature 側は `completed` で閉じる**（Issue-0102 の応急規範）

## 重要な意思決定の履歴

- ADR-0107: 指摘反映後の再レビューは改訂の性質で推奨を切り替え、収束は指摘の分類で判定する（2026-08-18 Accepted）
- ADR-0108: Accepted 昇格後の ADR 本文改訂は決定内容の変更有無でステータス運用を分ける（2026-08-18 Accepted）
- （ADR-0001〜0106 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
