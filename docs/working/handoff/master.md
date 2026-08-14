# Handoff: Issue-0074/0065 対策サイクル完了・次サイクル待ち

- **Branch**: master（feature/issue-0074-0065-cycle-wide-consistency を --no-ff で取り込み。マージコミット `beb52fa`）
- **Last Updated**: 2026-08-15 05:50 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: サイクル完了（retrospective・cycle-reset 済み）。push と配布反映、次サイクル着手はユーザー判断

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AI駆動開発ガイドライン（5原則 + スキル群 + ADR。AIエージェントと協働して開発を進めるための、原則・行動指示・スキルの体系）を整備するプロジェクト。

**直近サイクル（2026-08-14〜15: Issue-0074/0065 対応）**: タスク単位検査の構造的死角（累積ずれ・経路の閉じ）への対策として、決定の Accepted 昇格前に AI 自身が実施する**サイクル全体整合検査**を decision-log 昇格手順の第 1 ステップへ導入（ADR-0092 Accepted）。記録様式 `cyclecheck=`（命名規約 `Accepted 昇格`・値 4 形）を session-handoff の 8 箇所へ、参照経路を start-work・CONTRIBUTING.md へ配線し plugin 0.1.3 へ bump。確定前レビューを spec/plan 両確定点でフル 3 観点実施し、検査の初回自己適用は指摘 0 件。Issue-0074/0065 close、Issue-0085 起票。push・配布反映（`/plugin marketplace update`）と次サイクル着手はユーザー判断待ち。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open 計 41 件。2026-08-15 実測: 前回 42 − close 2 ＋ 起票 1）
- 直近サイクルの retrospective: `docs/records/retrospectives/system/2026-08-15-issue-0074-0065-cycle-check.md` / `flow/2026-08-15-issue-0074-0065-cycle-check.md`
- 直近サイクルの決定: ADR-0092（設計文書を兼ねる。検査の定義は `skills/decision-log/SKILL.md`「サイクル全体整合検査」が正）
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0092。Rejected 3件）
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

1. [ ] **Issue-0076**（flow）: 破壊的検証の委譲で隔離の作り方を指定する項目がない。**同じ機構で 2 度実害**。原因特定済みで、対策は subagent-dispatch B 群への項目追加で足りる可能性
2. [ ] **Issue-0073**（flow）: 計画の検証期待値が実装中に陳腐化する（4 件＋本サイクルで関連観測を追記）。Issue-0042/0056 と根が重なる
3. [ ] **Issue-0075**（flow）: 規範文書の実効性観点がレビューにない。「節だけを読んで作業を試す」検査の有効性は実証済み。Issue-0062 の続き
4. [ ] **Issue-0066**（flow）: 過剰適合点検が引用元ゲートの脱落を見ない。ADR-0092 観点 5 が昇格検査側に部分実現済みで、残るは点検手順側の要否判断
5. [ ] **Issue-0070/0072 のペア**（system）: 機械判定がスクリプト内の散文に届かない / 半角括弧を全角と同一視する。**ADR-0084 が引き受けた負債の機械化**。0072 は 1 行修正で塞げることまで確認済み
6. [ ] **Issue-0071/0077 のペア**（system）: 配布されるスキルが配布されない文書を必須参照にしている / 配布物の置き場が非対称で `dist` の名前が実態と合っていない。**「配布対象をどう定義するか」という同じ判断に帰着**。ただし 0077 の案 A は `marketplace.json` の `source` 変更を伴い、2 度事故が起きた領域に触れる
7. [ ] **Issue-0084**（flow）: マージ方式 --no-ff の完了フロー未配線。直近 2 サイクルは手動適用で回避（`f557a04` / `beb52fa`）。関連: **Issue-0050** が cycle-reset 発火点一般化の検討を受託済み
8. [ ] **Issue-0085**（flow・新規）: 消化記録へフィールドを新設する拡張に様式側の連動改定チェックリストが無い（本サイクルでレビュー 2 巡・計 7 指摘の実測）
9. [ ] **Issue-0057**（flow）: サブエージェント報告識別子の検証（自己申告と実態の食い違い 2 回） / **Issue-0020**（flow）: コミット時のステージ内容確認
10. [ ] **Issue-0044**（flow）: スキル改定の同セッション反映。運用対処は ADR-0090 で確定済み。残るのは start-work Phase -1 等への規範組み込みの採否のみ
11. [ ] **Issue-0045**（flow）: 既存 open 課題の対策方針の実行可能性点検（open 41 件。棚卸しの価値が高い）
12. [ ] **Issue-0064**（system）/ **Issue-0061/0058/0008** ほか低優先課題群 / **Issue-0028**（system・v2 テーマ）/ ループプロファイル抽出（ADR-0043）

## 既知のブロッカー・懸念

- **配布元が `dist/` へ切り替わった**（ADR-0082。実機確認済み）。**`skills/` を編集しただけでは、実際に動くスキルは変わらない**。`scripts/build-dist.ps1` を実行して `dist/` を再生成し、生成物も同じコミットに含めること。手順は `CONTRIBUTING.md`「全シナリオ共通: 配布対象ソースの記法規約」の執行点（4 手順）
- **規約に適合していても配布物が壊れる型が 5 つある**（ADR-0084）。生成器が判定できるのは識別子の位置だけ。**生成後の配布物を読む工程を別に置くこと**。加えて長大なコードフェンス（handoff 書式テンプレート等）内の散文も R4 の対象（本サイクルで実測。worklog `MakeAiInstructions-2026-08-15-01`）
- **確定前レビューの提示規則が稼働中**（ADR-0080）。spec 確定点（3 通り）と plan 確定点で毎回提示し、結果を消化記録へ `review=` で書く。**加えてサイクル全体整合検査が稼働開始**（ADR-0092）: 仕様・規範文書を編集したサイクルの Accepted 昇格前に必須。結果は `cyclecheck=` で記録し、昇格を含むマイルストーン名に `Accepted 昇格` を含めること
- **スキル改定の配布反映には version bump が必須**（ADR-0090）: 本サイクルで 0.1.3 へ bump 済み。**push と、ユーザーによる `/plugin marketplace update ai-driven-dev-principles` が未実施**。反映確認は起動本文と `dist/` 実ファイルの突合
- **破壊的な検証を委譲したら、受け取り時に `git status --short` を全件確認すること**（2 度の実害。Issue-0076）。委譲時は複製の作り方と**絶対パスの使用**を明示し、検証前後の `git status` 比較を報告に含めさせる（技術的背景は `docs/reference/powershell-pitfalls.md`）
- **クロス repo の課題参照は `<repo>#Issue-NNNN` で修飾**（ADR-0068）
- **PowerShell / .NET API の実測済み落とし穴は `docs/reference/powershell-pitfalls.md` を参照**（`Add-Content` 禁止・`Set-Location` と静的 API・検索/集計の 5 点ほか）
- **中央ストアの現状**: 本repo 61 件（〜`MakeAiInstructions-2026-08-15-01`）＋ LoopForAlpha 106 件。`projects.json` lastSeen 更新済み（2026-08-15）
- **検証用プラグイン `ai-driven-dev-principles-probe` の記録が残っている**（マーケットプレイス定義からは削除済みで実体なし）。片付けるならユーザースコープでのアンインストールが要る
- **inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定**。organize-inbox 提案は不要。`git add <ディレクトリ>` で巻き込まないこと（Issue-0020）
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` は確認済み（未確認モデルでの構造化質問ツール使用前に確認。ADR-0036）。ただし事象確認済みモデル（Fable 5）では構造化質問ツール自体を使用しない（ADR-0085）
- ADR-0023 の留意（継続）: GitHub.com の Copilot コーディングエージェントがルート `CLAUDE.md` を読まない可能性
- **リモート同期**: `origin/master` へ push 済み（2026-08-15 セッション終了の finalize コミットまでローカルと同期。直近サイクルのマージは `beb52fa`）。push は自動では行われないため、必要な区切りでユーザーが指示すること

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。形式は `skills/session-handoff/SKILL.md` のフォーマット節を参照。直近サイクル中の分は `feature_issue-0074-0065-cycle-wide-consistency.md` 参照（retrospective Phase 3 で突合済み・未消化なし）。

- 2026-08-15 セッション終了（retrospective・cycle-reset・push・finalize）: ADR=なし（新規決定なし） / worklog=棄却（retrospective 以後の新規 delta なし）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **未完の後始末**: ユーザーによる `/plugin marketplace update ai-driven-dev-principles` の実行で 0.1.3 の配布反映が完了する（push 済み。ADR-0090。反映確認は起動本文と `dist/` 実ファイルの突合）
3. **次サイクルの候補（着手はユーザー判断）**: 抽出課題は issues に起票済み（〜Issue-0085。着手はユーザー判断）。優先の目安は上記「未着手のタスク」の順。本命は **Issue-0076**（2 度実害・対策小）。軽量に畳むなら **Issue-0072**（1 行修正で塞げることまで確認済み）
4. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **配布対象ソースを変更したら、コミット前に執行点 4 手順を実施する**（`CONTRIBUTING.md`。生成器の実行 → 両者を `-Check` → 生成物を同じコミットへ → 目視 5 点）。スキル改定の配布反映は version bump も必須（ADR-0090）
   - **ガイドライン拡張時は過剰適合点検が必須**（ADR-0079）。引用元の規範にゲートがある場合、それを落としていないかも見ること（Issue-0066。ADR-0092 観点 5 も同型を検査する）
   - **確定点（spec / plan）を通過したら確定前レビューを提示し、結果を消化記録へ `review=` で書く**（ADR-0080）。提示では推奨の由来と反対材料も併記する
   - **Accepted 昇格前はサイクル全体整合検査**（ADR-0092。手順は `skills/decision-log/SKILL.md`「サイクル全体整合検査」）。昇格を含むマイルストーン名に `Accepted 昇格` を入れ、結果を `cyclecheck=` で記録する
   - サブエージェント委譲時は `subagent-dispatch` を呼ぶ。報告された識別子は転記前に実体検証する（Issue-0057）。破壊的検証を課すときは絶対パスの使用を明示する（Issue-0076）
   - Post ラッパーは1項目ずつ消し込み、結果を消化記録へ書く（ADR-0057）。worklog id は省略せず全体を書く
   - コミット前に `git status --short` を確認し、untracked の巻き込みとステージ済み別件の混入を見る（Issue-0020）。コミットは pathspec 付きが安全
   - コミット・マージのマルチライン文字列は `git commit -F <絶対パスの一時ファイル>`（Issue-0015）
   - ハンドオフの剪定は finalize で基準付き圧縮、サイクル完了時に cycle-reset（`skills/session-handoff/SKILL.md` 操作 4・5。ADR-0075）

## 重要な意思決定の履歴

- ADR-0092: 仕様・規範文書を編集したサイクルでは、決定の Accepted 昇格前に AI 自身によるサイクル全体整合検査を必須とする（2026-08-15 Accepted。Issue-0074/0065 close）
- ADR-0085〜0091: 前サイクル群（構造化質問ツール不使用 / handoff 正本移設の標準 / サイズ実測トリガー / 節別記載規範 / 配置定義とスキル手順の責務境界 / 配布反映の version bump 必須 / session-handoff 明確化改定）
- （ADR-0001〜0084 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
