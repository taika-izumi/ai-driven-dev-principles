# Handoff: session-handoff / decision-log の発火単位分割サイクル完了・次サイクル待ち

- **Branch**: master（feature/issue-0115-0116-skill-split を --no-ff で取り込み。マージコミット `2295f07`）
- **Last Updated**: 2026-09-03 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: サイクル完了（retrospective・cycle-reset 済み）。次サイクル着手はユーザー判断

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AI駆動開発ガイドライン（5原則 + スキル群 + ADR。AIエージェントと協働して開発を進めるための、原則・行動指示・スキルの体系）を整備するプロジェクト。

**直近サイクル（2026-09-01〜09-03: session-handoff / decision-log の発火単位分割）**: Issue-0115 / 0116 を対象に ADR-0122 を設計・実装（Accepted・plugin 0.1.18・両課題 close）。両 SKILL.md を条件発火の単位（操作・用途 / 横断規範）で `references/` 13 ファイルへ分割し、本文を共通部＋ディスパッチ表に絞った（31,169B → 8,308B・26,837B → 4,073B）。最頻経路の実読み込み量は update 素経路 12,744B〈41%〉・新規ドラフト作成 12,823B〈48%〉で完了条件を達成。移設は無改変の機械抽出とし列挙外の差分ゼロを diff で検証、外部参照 18 箇所と Accepted 済み ADR 22 件を張り替え・注記した。`build-dist.ps1` の例外テーブルの暫定行 2 件は削除して通常判定へ戻した。**次サイクル待ち**。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（**open 計 59 件**。2026-09-03 実測: close 2〈0115・0116〉・新設 2〈0117・0118〉。Issue-0099 へ検討状況追記。**同日さらに配布先からの申し送りで新設 3** = 0119〈LoopForAlpha#Issue-0130 の受け皿〉・0120〈申し送り時に随伴検出〉・0121〈LoopForAlpha#Issue-0140 の受け皿〉）
- 課題管理の運用規範の正本: `docs/overview/issue-management.md`（課題管理定義）
- 直近サイクルの決定: ADR-0122（設計文書兼用・spec 確定点 (c) 型のため設計 spec なし）。retrospective: `docs/records/retrospectives/system/2026-09-03-adr-0122-skill-split.md`（system のみ）。実装 plan: `docs/working/plans/2026-09-03-adr-0122-skill-split-implementation.md`
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0122。Rejected 3 件）
- 記法規約と執行点／SKILL.md のサイズと分割: `CONTRIBUTING.md` の各「全シナリオ共通」節
- worklog スキーマ正典: `skills/worklog-record/references/store-format.md`（v2）
- 原則: `docs/overview/principles.md` / **Layer 2: `AGENTS.md`（`CLAUDE.md` は `@AGENTS.md` の 1 行）** / 拡張ルール: `CONTRIBUTING.md`
- PowerShell / .NET API の落とし穴集: `docs/reference/powershell-pitfalls.md`

## 完了済みタスク

- [x] 過去サイクルは retrospective（`docs/records/retrospectives/README.md`）/ git 履歴参照

## 進行中のタスク

（なし。サイクル完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化。次サイクルの候補として目安を示す:

1. [ ] **Issue-0117**（system）: references 型分割の完了基準に、参照表の各行の到達元が実在するかの確認が無い。ADR-0122 サイクルで横断規範の参照表 1 行が到達不能になり、Accepted 昇格時のサイクル全体整合検査 観点 4 が検出した（当該欠陥は昇格前に修正済み）。対策候補は CONTRIBUTING の分割手順へ足すか、観点 4 の完了基準へ足すか
2. [ ] **Issue-0118**（flow）: 総情報量の増加に対し、AI が必要な情報へ到達する仕組みが体系として設計されていない。構造観察型。到達手段（AGENTS.md・ディスパッチ表・5 分類・分類ごとの独立インデックス・handoff）は個別の必要から足されたもので、網羅性・役割の重複欠落・スケールが未検証。参照グラフの採否はこの検討の中で決める。**Issue-0117 とは独立に進められる**
3. [ ] **Issue-0114 残余射程**（flow）: レビュー対象からの層の除外・変異検査・実装時レビュー深度の既定・「コードを含む計画」の独立型層別・サイクル通算の予算（ADR-0120 Decision 4 が明示的に残した射程）
4. [ ] **Issue-0107**（flow）: 反復レビューの推奨規範の乖離（事例 12・一般観察 4 まで蓄積。一般観察 4 = 骨格安定の判定が欠陥の由来〈設計の不安定さ か 書き手の記述ミス か〉を区別しない）
5. [ ] **Issue-0113 / 0112**（flow）: 実装工程 2 型の使い分け基準（**前倒し型の完走実測 1 件を追記済み**。対照実験は未実施） / 多層レビューの役割分担指針
6. [ ] **Issue-0109**（flow）: Layer 3 の退行確認がマージ・push 後にしか実行できない。プレフライト手段の設計
7. [ ] **Issue-0108**（system）: `build-dist.ps1` の見送り指摘 4 群（C0 制御文字・`.agents/` の stale 未検出・保守性・1 要素配列の素通り）。同ファイルを次に触るサイクルでまとめて処理するのが自然
8. [ ] **Issue-0102**（flow）: マージ後の cycle-reset の適用先 handoff の明示配線（応急規範は 7 サイクル連続で機能。恒久対策未着手）
9. [ ] **Issue-0095 / 0073 / 0056**（flow）: 計画の検証期待値の突合・陳腐化・実行可能性。3 件同時対策が前提（0073 は累計 10 件目を追記済み。**新種「検出器の性質を期待値へ写し損ねた」型で、確定前レビュー 5 巡でも検出されなかった**）
10. [ ] **Issue-0101 / 0100 / 0104 / 0106**（flow）: 旧設計仕様書の図示乖離 / 配線行の可変数値（**ADR-0121 で同型を新規に作った実測を追記済み**）/ R1-a 型の機械検出 / 退避領域の掃除規定（**退避が記録復元の唯一の手段になった実測を追記済み**）
11. [ ] **Issue-0097 / Issue-0099**（flow・待機）: 保留 44 行＋存置 5 行の再判定。発火はユーザーの棚卸し指示のみ
12. [ ] その他の既存 backlog: Issue-0072（半角括弧・軽量）/ Issue-0089 / Issue-0075 / Issue-0090 / Issue-0045 / Issue-0008 / Issue-0070/0071/0077 ほか低優先課題群 / Issue-0028（v2 テーマ）

## 既知のブロッカー・懸念

- **Layer 2 の内容正本は `AGENTS.md`**（ADR-0111）。`CLAUDE.md` は `@AGENTS.md` の 1 行のポインタで、内容を書き足さないこと。Codex は `AGENTS.md` を直読み、Claude Code はインポート経由、Copilot CLI は両方を結合読み
- **既存プロジェクトの移行手順は README の「既存プロジェクトを AGENTS.md 構成へ移行する」節**。template を再コピーする前に固有指示を `AGENTS.md` へ退避しないと消える。未移行プロジェクトを検知する機構は無い（ADR-0114 で受容）
- **配布元が `dist/` へ切り替わっている**（ADR-0082）。`skills/` を編集しただけでは動くスキルは変わらない。`scripts/build-dist.ps1` で再生成し、生成物も同じコミットへ。**ルートの `.agents/plugins/marketplace.json` も生成物**（手編集しない）。手順は `CONTRIBUTING.md` の執行点（4 手順）
- **規約に適合していても配布物が壊れる型がある**（ADR-0084）。生成後の配布物を読む工程を別に置くこと。R1-a 型の機械検出は Issue-0104
- **SKILL.md のサイズ警告が稼働中**（ADR-0121。ADR-0122 で例外テーブルは空になり全スキルが通常判定）。`skills/` を変更するサイクルでは `build-dist.ps1` 実行時に自動で計測される（非ブロック警告）。発火したら CONTRIBUTING「全シナリオ共通: SKILL.md のサイズと分割」の判断（責務帰属型 → references 型 → 例外登録）へ進む。例外テーブルの現行登録は session-handoff 31169・decision-log 26837 の 2 行（分割待ちの暫定行。根拠は Issue-0115/0116）。**`skills/retrospective/SKILL.md` は 19,042B で、次の追記でほぼ確実に発火する**（ADR-0121 Consequences が予告。その際の判断は「凝集 → 例外登録」1 回で足りる見込み）
- **Layer 3 の退行確認はマージ・push 後にしか実行できない**（Issue-0109）。マーケットプレイス登録が GitHub 経由のため、feature ブランチの内容は `marketplace update` に降りてこない
- **質問はテキストの番号付き選択肢のみ**（ADR-0109）。構造化質問ツールは全ツール・全モデルで使用しない
- **確定前レビューの提示規則＋指摘反映後の反復規範**（ADR-0080/0107）・**サイクル全体整合検査**（ADR-0092/0099）・**新設の評価可能性**（ADR-0102）・**Accepted 後改訂の改訂記録規定**（ADR-0108）が稼働中。確定点で `review=`、Accepted 昇格で `cyclecheck=` を消化記録へ。**ADR-0121 により pre-finalization-review は 4 ファイル構成**——提示規則・観点と初回体数・レビューの狙いは `SKILL.md`、反復規範と実施方式は `references/iteration-norms.md`、実施手順は `references/review-procedure.md`、適用例と根拠は `references/examples-and-evidence.md`（所在の一覧は SKILL.md「参照ファイル」節が正）。マージ方式確認の正本は `skills/start-work/references/merge-practice.md`
- **確定前レビューは 4 観点**（敵対的・実装整合性・仕様適合・前提実在。ADR-0117）・**体数 1〜4 体**。集約手順は指摘 1 件ずつの前提検査、3-2 (b) の「なし」記載は探索先併記が必須。**ADR-0120 により確定点は 2 型分類**（規範改定型／通常型。到達時に凍結）——初回フル巡は規範改定型 = 観点分離 4 体・写像通常型 = 1 体 4 観点兼務（迷えば観点分離）、反復提示には通算巡数の分布外検知（通常型 4 巡・規範改定型 8 巡。発火は提示であり上限ではない）
- **計画逸脱判断の既定が稼働中**（ADR-0119。正本 = `skills/start-work/references/plan-deviation-defaults.md`）: 計画作成・実装着手の直前に正本を読み、計画に「逸脱判断の既定」宣言欄を置く。実装中の指摘は型分類（4 型）→ 採用基準 (i)(ii) で裁き、**全帰結を計画ファイルへ行頭 `逸脱記録:` の 1 行で残す**。前倒し型・インライン TDD ではタスク完了報告に「逸脱突合:」1 行。委譲時は注入項目（subagent-dispatch 手順 7）を確認
- **Issue 運用の規範が稼働中**（ADR-0095〜0098): 課題ファイルへ追記したらサイズ実測（目安 10KB）、超過なら昇格提案。フォルダ昇格済み課題の close 時は移設判定必須
- **リモート同期**: 2026-09-03 の `351b0d5` まで push 済み（マージ `2295f07` を含む。配布 0.1.18 は反映済み）。各ツールのローカルキャッシュへの反映は利用側の更新操作が要る。**feature ブランチは push しない慣行**（リモートは `origin/master` のみ）。各ツールのローカルキャッシュへの反映は利用側の更新コマンド実行が必要（README「スキルのバージョンアップ」参照。ユーザーが実行）
- **inbox に未整理 3 件が滞留**: `docs/inbox/` の 3 ファイル（いずれも未追跡）。`docs/conversation_log.md` も未追跡のまま。**ユーザーが手動移動予定のため organize-inbox の提案は不要**。`git add <ディレクトリ>` で巻き込まないこと（Issue-0020）
- **Codex に本プラグインを GitHub 経由で登録済み**（実運用状態。配布版は 0.1.15）。取り消すなら `codex plugin remove` ＋ `codex plugin marketplace remove`
- **LoopForAlpha リポジトリに委譲済み追記 4 ファイルが未コミットで残置**（`feature/stage7-part2-design` の作業ツリー上。ユーザーが LFA セッションで LFA 側の流儀によりコミット予定。本リポジトリからはコミットしない。ADR-0118）
- **Copilot CLI は未契約**のため、同ツール向けの検証（Layer 2・Layer 3 の退行確認）が恒久的に実行できない。3 ツール対応を謳う以上、片方が検証不能なまま続く
- **改訂前退避の恒久領域 `~/.ai-dev-review-snapshots/` の残置が 20 ディレクトリへ増加**（本サイクル分 = `MakeAiInstructions/2026-09-01-adr-0122-spec/r1〜r9`・`2026-09-03-adr-0122-plan/r1〜r6`。整理はユーザー判断）
- **中央ストアの現状**: 本 repo 134 件（〜`MakeAiInstructions-2026-09-03-06`。2026-09-03 実測）。本サイクル分は 9 件（`-2026-09-02-01`〜`-2026-09-03-06`）で、うち 3 件は起票せず worklog 送りとした delta 型候補
- **クロス repo の課題参照は `<repo>#Issue-NNNN` で修飾**（ADR-0068）
- **PowerShell / .NET API の実測済み落とし穴は `docs/reference/powershell-pitfalls.md` を参照**
- **`python3` は Windows ストアのスタブで exit 49 を返すが、`python` は 3.12.1 が動作する**（2026-09-03 実測。ADR-0122 サイクルで多数の一括編集に使用）。旧記載「この環境に Python は無い」は `python3` についてのみ正しかった。一括編集は `python` のヒアドキュメント・Edit ツール・シェルの heredoc のいずれでもよい
- ADR-0023 の留意（継続): GitHub.com の Copilot コーディングエージェントがルート `CLAUDE.md` を読まない可能性

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。形式は `skills/session-handoff/SKILL.md` のフォーマット節を参照。直近サイクル中の分は git 履歴（`feature_issue-0105-skill-size-norm.md`）参照。

- 2026-09-03 サイクル完了処理（マージ `2295f07`・retrospective・cycle-reset・push `351b0d5`・配布 0.1.18 反映）: ADR=なし（完了処理と記録のみ。ADR-0122 の Accepted 昇格は feature 側で消化済み） / worklog=`MakeAiInstructions-2026-09-03-07`
- 2026-09-03 セッション終了処理（Proposed 据え置き・Rejected 更新漏れの確認を含む。いずれもなし）: ADR=なし（新規の意思決定なし。ADR-0122 は昇格済み） / worklog=`MakeAiInstructions-2026-09-03-08`
- 2026-09-03 Issue-0117 への参考情報追記と Issue-0118 の起票（サイクル完了後の追加記録）: ADR=なし（下されたのは参照グラフ採否の決定ではなく、その決定を Issue-0117 の解決から切り離す判断。未解決の論点は課題経路で扱う） / worklog=棄却（delta なし。既存の起票手順どおりで躓き・注入なし）

## 次セッション開始時のアクション

1. **最初に実行**: `start-work`（Phase 0 で本ハンドオフを read）。リモート同期は `351b0d5` まで完了済み（配布 0.1.18 反映済み）
2. **直近サイクルは新規起票 2 件・close 2 件**（新設: Issue-0117〈references 型分割の完了基準に到達元の実在確認が無い〉・Issue-0118〈AI が必要な情報へ到達する仕組みが体系として未設計。構造観察型〉。close: Issue-0115/0116。Issue-0099 へ検討状況追記）。次サイクルの候補は「未着手のタスク」節の 1〜11 を参照
3. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **Layer 2 へ固有指示を書くときは `AGENTS.md`**（`CLAUDE.md` はポインタのまま）
   - **配布対象ソースを変更したら執行点 4 手順**（`CONTRIBUTING.md`）。スキル改定は version bump も必須（ADR-0090。現行 0.1.18）
   - **`skills/` を変更したら SKILL.md のサイズ警告に注意**（ADR-0121。例外テーブルは空なので全スキルが通常判定）。**references 型で分割したら参照表の各行の到達元を数えること**（Issue-0117。ADR-0122 サイクルで 1 行が到達不能になった）
   - **ガイドライン拡張時は過剰適合点検＋新設の評価可能性が必須**（ADR-0079/0099/0102）
   - **確定点で確定前レビューを提示し、指摘反映後は反復提示**（ADR-0080/0107）。**反復の最終巡まで記録節へ書き切ってから確定コミットする**（本サイクルで第 5 巡の記録欠落が発生。復元は退避頼みだった）。**Accepted 昇格前はサイクル全体整合検査**（ADR-0092/0099）。**Accepted 済み ADR 本文を改訂したら改訂記録規定**（ADR-0108）
   - **計画作成・実装着手の直前に `references/plan-deviation-defaults.md` を読み、計画へ宣言欄・実装中は逸脱記録行**（ADR-0119。稼働規範の詳細は「既知のブロッカー・懸念」参照）
   - サブエージェント委譲時は `subagent-dispatch`（判定行必須）。**再委譲・再レビューでは前提値を委譲直前に再実測して渡す**。**数値・ファイルパス・名称は書く直前に実測する**
   - **計画の検証コマンドは書いたら実行してから確定する**。**検出器の近似が正当なヒットを拾わないかも配布物側で実測する**（本サイクルの Issue-0073 追記）
   - **worklog の id 採番・検証は JSON パースで行う**（素の grep はストアの整形差で 0 件を返す。worklog `MakeAiInstructions-2026-09-01-02` / `-05`）。**`python` が使える**（3.12.1。`python3` はスタブ）
   - Post ラッパーは1項目ずつ消し込み、結果を消化記録へ（ADR-0057）。worklog id は全体を書く
   - コミット前に `git status --short` と staged 確認。**コミットは pathspec 付きが安全**（Issue-0020）
   - ハンドオフの剪定は finalize で基準付き圧縮、サイクル完了時に cycle-reset（ADR-0075）。**cycle-reset の適用先は現在ブランチの handoff。feature 側は `completed` で閉じる**（Issue-0102 の応急規範）

## 重要な意思決定の履歴

- ADR-0122: session-handoff と decision-log は発火単位で references へ分割し、SKILL.md 本文を共通部とディスパッチ表に絞る（2026-09-03 Accepted）
- （ADR-0001〜0121 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
