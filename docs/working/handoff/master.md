# Handoff: ADR-0109 サイクル完了・次サイクル待ち

- **Branch**: master（feature/question-tool-retirement を --no-ff で取り込み。マージコミット `c95d231`）
- **Last Updated**: 2026-08-19 00:18 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: サイクル完了（retrospective・cycle-reset 済み）。次サイクル着手はユーザー判断

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AI駆動開発ガイドライン（5原則 + スキル群 + ADR。AIエージェントと協働して開発を進めるための、原則・行動指示・スキルの体系）を整備するプロジェクト。

**直近サイクル（2026-08-18: 構造化質問ツール全面廃止）**: ユーザー実測（テキスト選択肢で不便なし・クリック無効化でコピペ不可）を起点に、質問規範を全ツール・全モデルでテキスト番号付き選択肢へ一本化（CLAUDE.md 6 箇条＋サブ 3 → 3 箇条、10732B→7915B）し、環境変数 `CLAUDE_CODE_DISABLE_MOUSE_CLICKS` を撤去してクリック操作を再有効化（次セッションから実効）。ADR-0109 Accepted・ADR-0036/0085 Superseded・0035 部分修正・plugin 0.1.11・Issue-0082 close（spec 回復）。次サイクル着手はユーザー判断待ち。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open 計 50 件。2026-08-18 実測: 前回 51 − close 1〈0082〉・新規起票 0）
- 課題管理の運用規範の正本: `docs/overview/issue-management.md`（課題管理定義）
- 直近サイクルの決定: ADR-0109（設計文書兼用）。retrospective: `docs/records/retrospectives/system/2026-08-18-question-tool-retirement.md`。実装 plan: `docs/working/plans/2026-08-18-question-tool-retirement.md`
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0109。Rejected 3件・Superseded に 0036/0085 追加）
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
2. [ ] **Issue-0102**（flow）: マージ後の cycle-reset の適用先 handoff の明示配線（応急規範は 3 サイクル連続で機能。恒久対策未着手）
3. [ ] **Issue-0100**（flow）: 配線行に可変数値を書かない規律の恒久規範化（有効性実測済み・小規模）
4. [ ] **Issue-0104**（flow）: 識別子除去後の文法破綻（R1-a 型）の機械検出（実測 3 件・目視依存の解消）
5. [ ] **Issue-0103**（flow）: 確定前レビュー反復のコスト・巡数の予算基準（ADR-0107 の運用実測が貯まってからの設計も選択肢）
6. [ ] **Issue-0105 / 0106**（flow）: SKILL.md サイズ規範 / 退避領域の掃除規定
7. [ ] **Issue-0095**（flow）: A-13（計画の期待値突合）の再設計。再発 3 回目（2026-08-18 に slug 未実測の軽微再発を追記）。Issue-0056・0073 と同時対策
8. [ ] **Issue-0097 / Issue-0099**（flow・待機）: 保留 44 行＋存置 5 行の再判定。発火はユーザーの棚卸し指示のみ
9. [ ] その他の既存 backlog: Issue-0072（半角括弧・軽量）/ Issue-0089 / Issue-0075 / Issue-0090 / Issue-0045 / Issue-0008 / Issue-0070/0071/0077 ほか低優先課題群 / Issue-0028（v2 テーマ）

## 既知のブロッカー・懸念

- **配布元が `dist/` へ切り替わっている**（ADR-0082）。`skills/` を編集しただけでは動くスキルは変わらない。`scripts/build-dist.ps1` で再生成し、生成物も同じコミットへ。手順は `CONTRIBUTING.md` の執行点（4 手順）
- **規約に適合していても配布物が壊れる型がある**（ADR-0084）。生成後の配布物を読む工程を別に置くこと。R1-a 型の機械検出は Issue-0104
- **質問はテキストの番号付き選択肢のみ**（ADR-0109）。構造化質問ツールは全ツール・全モデルで使用しない。`CLAUDE_CODE_DISABLE_MOUSE_CLICKS` は撤去済み（クリック操作は次セッションから再有効化。コピペ実効性の確認は次セッションでユーザーが行う）。TUI 全体の誤クリック確定は受容済みリスク（誤確定が実測されたら ADR-0109 を見直し）
- **確定前レビューの提示規則＋指摘反映後の反復規範**（ADR-0080/0107）・**サイクル全体整合検査**（ADR-0092/0099）・**新設の評価可能性**（ADR-0102）・**Accepted 後改訂の改訂記録規定**（ADR-0108）が稼働中。確定点で `review=`、Accepted 昇格で `cyclecheck=` を消化記録へ。正本の所在: 反復＝start-work「4. 指摘反映後の反復」、実施方式＝pre-finalization-review「反復の実施」、`review=` 値＝session-handoff「`review=` の値定義」、改訂記録＝decision-log「ステータス変更」
- **Issue 運用の規範が稼働中**（ADR-0095〜0098): 課題ファイルへ追記したらサイズ実測（目安 10KB）、超過なら昇格提案。フォルダ昇格済み課題の close 時は移設判定必須。正本は `docs/overview/issue-management.md`
- **decision-log の昇格条件要約は、課題管理定義の改定時に同時更新が必要**（意図された配線。ADR-0098 の複写乖離型の監視点）
- **未完の後始末（過去サイクル分）**: 改定スキル（decision-log）の本文と repo 実ファイルの突合、課題管理定義の既存配布先への手動コピーが未実施のままなら次セッションで
- **リモート同期**: 2026-08-19 に `a53f8d4` まで push 済み（origin/master と behind 0 / ahead 0）。以後も push はユーザー指示時
- **プラグイン実体は 0.1.10**。0.1.11 の反映には `/plugin marketplace update ai-driven-dev-principles`（AI からは実行不可）とセッション再起動（索引再構築）が必要
- **クロス repo の課題参照は `<repo>#Issue-NNNN` で修飾**（ADR-0068）
- **PowerShell / .NET API の実測済み落とし穴は `docs/reference/powershell-pitfalls.md` を参照**。Git Bash の grep で多バイト文字の否定文字クラス（`[^）]` 等）はバイト単位解釈で偽陰性を出す（worklog `MakeAiInstructions-2026-08-18-02`。同一セッションで 2 回遭遇）
- **中央ストアの現状**: 本 repo 84 件（〜`MakeAiInstructions-2026-08-18-04`。2026-08-18 実測）＋ LoopForAlpha 190 件 ＋ OrderAutomateSupporter 4 件
- **改訂前退避の恒久領域 `~/.ai-dev-review-snapshots/` に残置あり**（前サイクル 5 世代＋本サイクル `2026-08-18-adr-0109/` 2 世代。掃除規定は Issue-0106。当面は手動判断）
- **検証用プラグイン `ai-driven-dev-principles-probe` の記録が残っている**（実体なし。片付けはユーザースコープのアンインストール）
- **inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定**。organize-inbox 提案は不要。`git add <ディレクトリ>` で巻き込まないこと（Issue-0020）
- **docs 配下へ新規ファイルを作らせる委譲では、Write ガードの迂回手段（Python 経由）を指示に明示**（worklog `MakeAiInstructions-2026-08-16-05`）
- ADR-0023 の留意（継続): GitHub.com の Copilot コーディングエージェントがルート `CLAUDE.md` を読まない可能性

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。形式は `skills/session-handoff/SKILL.md` のフォーマット節を参照。直近サイクル中の分は git 履歴（`feature_question-tool-retirement.md`）参照。

- 2026-08-18 ADR-0109 サイクル retrospective 実施・cycle-reset: ADR=なし（課題抽出のみ・対策設計なし） / worklog=棄却（総ざらいはマイルストーン 3 件×ストア突合で漏れゼロ）
- 2026-08-18 セッション終了処理: ADR=なし（新規決定なし） / worklog=`MakeAiInstructions-2026-08-18-04`（README 時系列誤挿入の 2 サイクル連続再発）
- 2026-08-19 ADR-0109 サイクル分のリモート push（`a53f8d4`）: ADR=なし（既定運用の実行のみ・方針決定なし） / worklog=棄却（delta なし）

## 次セッション開始時のアクション

1. **最初に確認**: クリック操作（コピペ）が有効になっているか（環境変数撤去の実効確認はユーザーのみ可能）。`/plugin marketplace update ai-driven-dev-principles` ＋ セッション再起動でプラグインを 0.1.11 へ → `start-work`（Phase 0 で本ハンドオフを read）
2. **リモート同期**: `a53f8d4` まで push 済み（2026-08-19 実測で behind 0 / ahead 0）。以後の push もユーザー指示時
3. **次サイクルの候補（着手はユーザー判断）**: 目安の優先順は「未着手のタスク」参照（新規起票 0 件・Issue-0082 close 済み）
4. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **配布対象ソースを変更したら執行点 4 手順**（`CONTRIBUTING.md`）。スキル改定は version bump も必須（ADR-0090。現行 0.1.11）
   - **ガイドライン拡張時は過剰適合点検＋新設の評価可能性が必須**（ADR-0079/0099/0102）
   - **確定点で確定前レビューを提示し、指摘反映後は反復提示**（ADR-0080/0107。正本は start-work）。**Accepted 昇格前はサイクル全体整合検査**（ADR-0092/0099。マイルストーン名に `Accepted 昇格` を含める）。**Accepted 済み ADR 本文を改訂したら改訂記録規定**（ADR-0108）
   - **Issue へ追記したらサイズ実測・close 時は移設判定**（課題管理定義が正）
   - サブエージェント委譲時は `subagent-dispatch`（判定行必須）。**再委譲・再レビューでは前提値を委譲直前に再実測して渡す**。**数値・ファイルパス・名称は書く直前に実測し、検証期待値は出現数（`-AllMatches`）で数える**（Issue-0095 再発 3 回の教訓）
   - **レビューの差分範囲は対象コミットの直前..対象で取る**（worklog `MakeAiInstructions-2026-08-16-06`）
   - Post ラッパーは1項目ずつ消し込み、結果を消化記録へ（ADR-0057）。worklog id は全体を書く
   - コミット前に `git status --short` と staged 確認。**コミットは pathspec 付き `git commit -- <paths>` が安全**（Issue-0020）。マルチライン文字列は `git commit -F <絶対パス>`（Issue-0015）
   - インデックス・台帳へ行を追加する前に挿入位置（表の終端・並び順）を実体確認（2026-08-18 に retrospectives README で時系列順の誤挿入を再度自己検出・即修正。2 サイクル連続）
   - ハンドオフの剪定は finalize で基準付き圧縮、サイクル完了時に cycle-reset（ADR-0075）。**cycle-reset の適用先は現在ブランチの handoff。feature 側は `completed` で閉じる**（Issue-0102 の応急規範）

## 重要な意思決定の履歴

- ADR-0109: 構造化質問ツールを全ツール・全モデルで廃止しテキスト選択肢に一本化、クリック操作を再有効化する（2026-08-18 Accepted）
- （ADR-0001〜0108 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
