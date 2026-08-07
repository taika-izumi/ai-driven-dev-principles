# Handoff: 確定前レビューの提示規則の導入サイクル完了・次サイクル待ち

- **Branch**: master（feature/review-recommendation-by-artifact-type を merge `afed223` として取り込み）
- **Last Updated**: 2026-08-07 18:05 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: 全フェーズ完了。次サイクル着手はユーザー判断

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AI駆動開発ガイドライン（5原則 + スキル群 + ADR。AIエージェントと協働して開発を進めるための、原則・行動指示・スキルの体系）を整備するプロジェクト。

**直近サイクル（2026-08-07: 確定前レビューの提示規則の導入）**: Issue-0062 の対策として、確定前レビューの提示点を「spec 確定点（3 通り）＋ plan 確定点」へ一般化し、成果物の変更対象に未レビューの規範・手順文書の新設・改定が含まれる場合はフルレビューを推奨側に置く片方向規範を導入した（ADR-0080・Accepted）。判定規則の正本は `start-work` Phase 2 に置き、判定材料の記録経路を `session-handoff` の read / update / finalize へ配線（記録欠落時は安全側へ倒す）。あわせて推奨の由来の明示と反対材料の併記を義務化した（片側だけの提示は本規範が塞ぐ偏りと同型のため）。設計段階で採用しかけた軽量レビュー枝は、独立レビューで根拠の崩壊が実証され撤回した。次サイクル着手はユーザー判断待ち。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open: system 7 件 = 0003/0008/0028/0036/0055/0058/0064、flow 25 件 = 0006/0015/0020/0021/0038/0039/0042〜0048/0050/0052〜0054/0056/0057/0059〜0061/0063/0065/0066。計 32 件）
- 直近サイクルの retrospective: `docs/records/retrospectives/system/2026-08-07-review-presentation-by-artifact-type.md` と `flow/2026-08-07-review-presentation-by-artifact-type.md`
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0080。Rejected 3件）
- worklog スキーマ正典: `skills/worklog-record/references/store-format.md`（v2）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] 過去サイクルは retrospective（`docs/records/retrospectives/README.md`）/ git 履歴参照

## 進行中のタスク

（なし。サイクル完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化。次サイクルの候補として目安を示す:

1. [ ] **Issue-0065/0066 のペア**（flow・今サイクル起票）: タスク単位レビューが文書間の経路を検出できない / 過剰適合点検が引用元のゲートの脱落を見ない。**両者とも発見経路が「文書間の突合」で共通**しており、対処先も独立レビューの観点か点検手順かで重なるため、同時に扱うと判断が一度で済む（Issue-0066 の「留意」に明記）
2. [ ] **Issue-0042/0056 のペア**（flow）: 検出器の検出力 / 計画の検証コマンドの検査。**今サイクルで有効な検査方式が実測された**（正しい状態と欠陥状態 28 件を構築し全 24 コマンドを両方に実行して Critical 2・Major 5 を検出）。対策設計の材料が揃っている
3. [ ] **Issue-0057**（flow）: サブエージェント報告識別子の検証。3 サイクル連続で有効性を確認済み。今サイクルで検証対象の拡張が必要と判明（識別子の実在に加え、報告された履歴操作が実際にその通り行われたか）
4. [ ] **Issue-0020**（flow）: コミット時のステージ内容確認。今サイクルで再発（11 委譲中 1 回。指示の明示では防げない比率の実測）。ADR-0039 に従い機械 gate（フック等）を先に調べること
5. [ ] **Issue-0044**（flow）: スキル改定の同セッション反映。3 サイクル分の実測で対処内容と有効性が固まっており、**残るのは規範化の採否のみ**（運用規範 1 行で足りる可能性）
6. [ ] **Issue-0064**（system）: 点検ブロックの見出しレベルが 2 通りで存在確認を単一 grep で書けない。ADR-0079 の執行点の機械化に直結し、規模は小さい
7. [ ] **Issue-0045**（flow）: 既存 open 課題の対策方針の実行可能性点検。open 32 件（system 7 + flow 25）に増加し、棚卸しの価値がさらに上昇
8. [ ] **Issue-0061/0058**（Skill 改定シナリオの手順整備 / 2026-04-13 仕様書の陳腐化）: 0058 は Issue-0008（旧型式 spec の維持方針）と同時に扱うと判断が一度で済む
9. [ ] **Issue-0006/0043/0059/0060/0063** ほか低優先課題群 / **Issue-0028**（system・v2 テーマ）/ ループプロファイル抽出（ADR-0043）

## 既知のブロッカー・懸念

- **確定前レビューの提示規則が稼働開始**（ADR-0080）。spec 確定点（3 通り）と plan 確定点で毎回提示し、未レビューの規範・手順文書の変更を含む成果物ではフル推奨へ倒す。**提示結果は handoff の消化記録へ `review=` として必ず書くこと**——記録が無いと次の確定点で「未レビュー」に倒れる設計のため、書き漏らすと毎回フル推奨が立つ
- **スキルを改定したら、そのスキルを同セッションで使う前にユーザーへ `/plugin marketplace update` の実行を依頼すること**: update を挟まないと改定前の本文が供給される（3 サイクルで実測。Issue-0044）。プラグインキャッシュを読んでも供給内容は判定できない。確認は「起動して返った本文と repo 実ファイルの突合」で行う
- **`Add-Content` は使わないこと**。中央ストアへの追記は Python `open(path, "a", encoding="utf-8", newline="\n")`（ADR-0064）
- **クロス repo の課題参照は `<repo>#Issue-NNNN` で修飾**（ADR-0068）
- **PowerShell の検索・集計の落とし穴**（いずれも実測）:
  - `Select-String` に `-Recurse` は無い。再帰検索は `Get-ChildItem -Recurse -File` とのパイプで書く
  - `Get-ChildItem -Path <ファイル名> -Recurse` はファイル名をフィルタ解釈して同名ファイルを全て拾う。ルート直下ファイルは `Get-Item`、ディレクトリは `Get-ChildItem -Recurse -File` で別々に集めてパイプする（Issue-0056 / worklog `MakeAiInstructions-2026-08-07-02`）
  - `Group-Object Filename` は basename で束ねるため、同名ファイル（`SKILL.md` 等）のファイル別集計に使えない。`Group-Object Path` を使うか、最初からファイルごとに個別実行する（worklog `MakeAiInstructions-2026-08-07-05`）
  - **`Select-String` は行数を数えるため、複数語句を正規表現の OR でまとめると同一行にある場合に 1 件としか数えない**。語句ごとに個別実行して件数を確認すること（今サイクルで、正しい実装でも期待値に届かない検証を生んだ。Issue-0042）
  - **`Measure-Object -Line` は件数集計に使えない**（入力オブジェクトの行数を数える）。件数は `(… | Measure-Object).Count`
- **中央ストアの現状**: 本repo 37 件（〜`MakeAiInstructions-2026-08-07-11`）＋ LoopForAlpha 106 件。台帳 33 行。`projects.json` lastSeen 更新済み（2026-08-07）
- **inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定**。organize-inbox 提案は不要。`git add <ディレクトリ>` で巻き込まないこと（Issue-0020）
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` は確認済み（構造化質問ツール使用前に毎回確認。ADR-0036）
- ADR-0023 の留意（継続）: GitHub.com の Copilot コーディングエージェントがルート `CLAUDE.md` を読まない可能性
- **リモート同期**: 2026-08-07 のセッション終了時に `origin/master` へ push 済み（`1727524..7398860` の 21 コミット）。push は自動では行われないため、必要な区切りでユーザーが指示すること

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。形式は `skills/session-handoff/SKILL.md` のフォーマット節を参照（確定点を通過したマイルストーンには `review=` を併記する。ADR-0080）。直近サイクル中の分は `feature_review-recommendation-by-artifact-type.md` 参照（retrospective Phase 3 で突合済み・未消化なし）。

- 2026-08-07 セッション終了（切り替え直前。ADR-0058）: ADR=なし（Proposed 残ゼロ・未コミットドラフトなしを確認。終了処理に意思決定なし） / worklog=`MakeAiInstructions-2026-08-07-12`（既存ファイル経路の推測による Edit 失敗。`-2026-08-04-02` と同型の再発） / review=非発火（推奨判定が偽。確定点ではないため）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **直近サイクルは完了**: 追加作業不要。抽出した課題は issues に起票済み（Issue-0065/0066。着手はユーザー判断）。delta 型 1 件は worklog 送り（`MakeAiInstructions-2026-08-07-11`）
3. **次サイクルの候補（着手はユーザー判断）**: 優先の目安は上記「未着手のタスク」の順。**Issue-0065/0066 のペア**が最有力（今サイクルで実害寸前まで至り、対処先が重なる）。次いで **Issue-0042/0056 のペア**（有効な検査方式が実測済み）、**Issue-0044**（残るのは規範化の採否のみ）
4. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **ガイドライン拡張時は過剰適合点検が必須**（ADR-0079。CONTRIBUTING.md「全シナリオ共通: 過剰適合の点検」）。点検ブロックの無い拡張 spec / 拡張 ADR はコミットしない。**引用元の規範にゲート（条件節）がある場合、それを落としていないかも見ること**（今サイクルで見落とし 1 件。Issue-0066）
   - **確定点（spec / plan）を通過したら確定前レビューを提示し、結果を消化記録へ `review=` で書く**（ADR-0080）。提示では推奨の由来と反対材料も併記する
   - サブエージェント委譲時は `subagent-dispatch` を呼ぶ。報告された識別子は転記前に `git cat-file -t` 等で実体検証する（Issue-0057）。履歴操作（reset 等）の申告は reflog で裏取りする
   - **複数文書にまたがる規範を実装したら、タスク単位のレビュー通過を完了の根拠にしないこと**。実装全体に対して「規範を 1 サイクル机上実行して経路が閉じるか」を検査する（今サイクルで Major 4 件を検出。Issue-0065）
   - Post ラッパーは1項目ずつ消し込み、結果を消化記録へ書く（ADR-0057）。worklog id は省略せず全体を書く
   - コミット前に `git status --short` を確認し、untracked の巻き込みとステージ済み別件の混入を見る（Issue-0020）。コミットはパス指定（`git commit -F <msg> -- <paths>`）が安全
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md`、または空インデックス生成対象（`docs/records/decisions/README.md` / `docs/records/retrospectives/README.md` / `docs/working/issues/README.md`）を変更したら `scripts/sync-template.ps1` を実行
   - コミット・マージのマルチライン文字列は `git commit -F <絶対パスの一時ファイル>`（Issue-0015。`$TMPDIR` は未設定のため絶対パスで書く）
   - ハンドオフの剪定は finalize で基準付き圧縮、サイクル完了時に cycle-reset（`skills/session-handoff/SKILL.md` 操作 4・5。ADR-0075）

## 重要な意思決定の履歴

- ADR-0080: 直近サイクル（確定前レビューは spec/plan 確定点で提示し、未レビューの規範・手順文書の変更を含む成果物では推奨側に倒す）
- （ADR-0001〜0079 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
