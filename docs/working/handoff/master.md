# Handoff: handoff 肥大化制御サイクル完了・次サイクル待ち

- **Branch**: master（feature/handoff-bloat-analysis を fast-forward で取り込み。先端 `9259eec`・マージコミットなし → Issue-0084）
- **Last Updated**: 2026-08-14 20:59 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: 全フェーズ完了（実装・最終レビュー・retrospective 済み）。次サイクル着手はユーザー判断

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AI駆動開発ガイドライン（5原則 + スキル群 + ADR。AIエージェントと協働して開発を進めるための、原則・行動指示・スキルの体系）を整備するプロジェクト。

**直近サイクル（2026-08-13〜14: handoff 肥大化制御）**: 配布先実測（handoff 99KB・約 10KB/日 増）を起点に、「情報を削らず、置き場を直す」設計で Issue-0078〜0081 を一括対策した。session-handoff へ独立手順「移設」（種類別対応表・6 手順・3 起点の add 配線）、サイズ実測トリガー（デフォルト 40KB。read/finalize で実測）、節別記載規範（デフォルト 200 字・列挙外の節への既定規則）を導入（ADR-0086/0087/0088）。配置定義とスキル手順の責務境界を規定（ADR-0089）、folder-structure の配置表へ教訓・作業知見の移設先を明記。cycle-reset 発火点の一般化は撤回し Issue-0050 へ委譲。割り込みで ADR-0085（Fable 5 での構造化質問ツール全面不使用）も確定。確定前レビューを spec・plan 両確定点でフル実施（指摘 33＋12 件全採用）、実装は二段レビューで実欠陥 4 件を捕捉・修正し、完了基準 7 項目を全充足。ADR-0086〜0089 Accepted・Issue-0078〜0081 close。次サイクル着手はユーザー判断待ち。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open 計 43 件。2026-08-14 実測）
- 直近サイクルの retrospective: `docs/records/retrospectives/system/2026-08-14-handoff-bloat-control.md` と `flow/2026-08-14-handoff-bloat-control.md`
- 直近サイクルの仕様: `docs/current/specs/2026-08-13-handoff-bloat-control/`（00〜02）と plan `docs/working/plans/2026-08-14-handoff-bloat-control-plan.md`
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0089。Rejected 3件）
- 記法規約と執行点: `CONTRIBUTING.md`「全シナリオ共通: 配布対象ソースの記法規約」
- worklog スキーマ正典: `skills/worklog-record/references/store-format.md`（v2）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] 過去サイクルは retrospective（`docs/records/retrospectives/README.md`）/ git 履歴参照

## 進行中のタスク

（なし。サイクル完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化。次サイクルの候補として目安を示す:

0. [ ] **今サイクル起票分**: **Issue-0083**（system・session-handoff 文書のレビュー残 5 点。各 1 句〜1 行の追記で解消見込みの軽量課題。対応時は spec/ADR 同期＋執行点 4 手順） / **Issue-0084**（flow・マージ方式 --no-ff の完了フロー未配線。今サイクルで実発生） / 関連: **Issue-0050** が cycle-reset 発火点（呼び出し関係）一般化の検討を Issue-0078 から受託済み。また master handoff の教訓型申し送り（PowerShell 落とし穴群など）は、今サイクル導入の独立手順「移設」の対応表では参照知識（`docs/reference/`）への移設対象——プラグイン更新後の初回 finalize/cycle-reset で移設提案が出る見込み
1. [ ] **Issue-0074/0065 のペア**（flow・0074 は今サイクル起票）: 決定を Accepted へ昇格させる前に仕様が実装のスナップショットかを検査する工程がない / タスク単位レビューが文書間の経路を検出できない。**両者は同じ根（タスク単位の検査では累積のずれを検出できない）を持つ**ため、同時に扱うと対策が一度で設計できる。今サイクルで実害が 3 件出ており材料が揃っている
2. [ ] **Issue-0076**（flow・今サイクル起票）: 破壊的検証の委譲で隔離の作り方を指定する項目がない。**同じ機構で 2 度実害が出た**（決定記録インデックス 92 行が空に／配布物に BOM 混入）。原因（`Set-Location` が .NET 静的 API に効かない）まで特定済みで、対策は B 群への項目追加で足りる可能性
3. [ ] **Issue-0073**（flow・今サイクル起票）: 計画の検証期待値が実装中に陳腐化する。今サイクルで 4 件発生。Issue-0042/0056（検出器の検出力・検証コマンドの検査）と根が重なる
4. [ ] **Issue-0075**（flow・今サイクル起票）: 規範文書の実効性観点がレビューにない。今サイクルで「節だけを読んで 4 作業を試す」検査が 3 件詰まりを検出しており、観点の有効性は実証済み。Issue-0062 の続き
5. [ ] **Issue-0070/0072 のペア**（system・今サイクル起票）: 機械判定がスクリプト内の散文に届かない / 半角括弧を全角と同一視する。**両者とも ADR-0084 が引き受けた負債の機械化**であり、0072 は実害 0 件・1 行修正で塞げることまで確認済み
6. [ ] **Issue-0071/0077 のペア**（system・今サイクル起票）: 配布されるスキルが配布されない文書を必須参照にしている / 2 つの配布物の置き場が非対称で `dist` の名前が実態と合っていない。**どちらも「配布対象をどう定義するか」という同じ判断に帰着する**ため、同時に扱うと設計が一度で済む。ただし 0077 の案 A は `marketplace.json` の `source` 変更を伴い、**2 度事故が起きた領域**に触れる
7. [ ] **Issue-0066**（flow）: 過剰適合点検が引用元のゲートの脱落を見ない。Issue-0065 とペアだったが、0065 は上記 1 で扱う
8. [ ] **Issue-0057**（flow）: サブエージェント報告識別子の検証。今サイクルでも**自己申告と実態の食い違いが 2 回**（実在しない修正の報告／複製で検証したはずが実ファイル破壊）。Issue-0076 と併せて扱う余地あり
9. [ ] **Issue-0020**（flow）: コミット時のステージ内容確認。**今サイクルでは再発ゼロ**（委譲先が全件でパス指定を守った）
10. [ ] **Issue-0044**（flow）: スキル改定の同セッション反映。**今サイクルで再確認**（配布元切替後の `/plugin marketplace update` で反映を実測）。残るのは規範化の採否のみ
11. [ ] **Issue-0045**（flow）: 既存 open 課題の対策方針の実行可能性点検。open 38 件へ増加し、棚卸しの価値がさらに上昇
12. [ ] **Issue-0064**（system）/ **Issue-0061/0058/0008** ほか低優先課題群 / **Issue-0028**（system・v2 テーマ）/ ループプロファイル抽出（ADR-0043）

## 既知のブロッカー・懸念

- **配布元が `dist/` へ切り替わった**（ADR-0082。実機確認済み）。**`skills/` を編集しただけでは、実際に動くスキルは変わらない**。`scripts/build-dist.ps1` を実行して `dist/` を再生成し、生成物も同じコミットに含めること。手順は `CONTRIBUTING.md`「全シナリオ共通: 配布対象ソースの記法規約」の執行点（4 手順）
- **規約に適合していても配布物が壊れる型が 5 つある**（ADR-0084）。生成器が判定できるのは識別子の位置だけで、括弧内に説明語を同居させた行・半角括弧・書式例の実在の固有名・自己参照（`本リポジトリ` / `本 repo`）・スクリプトの docstring と表示メッセージは判定を通過する。**生成後の配布物を読む工程を別に置くこと**（今サイクルで、自己参照は 3 度にわたり別の箇所で見つかった）
- **確定前レビューの提示規則が稼働中**（ADR-0080）。spec 確定点（3 通り）と plan 確定点で毎回提示し、未レビューの規範・手順文書の変更を含む成果物ではフル推奨へ倒す。**提示結果は handoff の消化記録へ `review=` として必ず書くこと**——記録が無いと次の確定点で「未レビュー」に倒れる設計のため、書き漏らすと毎回フル推奨が立つ
- **スキルを改定したら、そのスキルを同セッションで使う前にユーザーへ `/plugin marketplace update` の実行を依頼すること**: update を挟まないと改定前の本文が供給される（4 サイクルで実測。Issue-0044）。プラグインキャッシュを読んでも供給内容は判定できない。確認は「起動して返った本文と repo 実ファイルの突合」で行う
- **破壊的な検証を委譲したら、受け取り時に `git status --short` を全件確認すること**（今サイクルで 2 度の実害。Issue-0076）。**PowerShell の `Set-Location` は .NET の静的 API に効かない**（`[System.IO.File]::WriteAllText` 等はプロセスの作業ディレクトリが基準）。委譲時は複製の作り方と**絶対パスの使用**を明示し、検証前後の `git status` 比較を報告に含めさせる
- **`Add-Content` は使わないこと**。中央ストアへの追記は Python `open(path, "a", encoding="utf-8", newline="\n")`（ADR-0064）
- **クロス repo の課題参照は `<repo>#Issue-NNNN` で修飾**（ADR-0068）
- **`,@($list)` は List に対して型エラーになる**（実測）。単項カンマで包むときは `.ToArray()` を使う
- **PowerShell の検索・集計の落とし穴**（いずれも実測）:
  - `Select-String` に `-Recurse` は無い。再帰検索は `Get-ChildItem -Recurse -File` とのパイプで書く
  - `Get-ChildItem -Path <ファイル名> -Recurse` はファイル名をフィルタ解釈して同名ファイルを全て拾う。ルート直下ファイルは `Get-Item`、ディレクトリは `Get-ChildItem -Recurse -File` で別々に集めてパイプする（Issue-0056）
  - `Group-Object Filename` は basename で束ねるため、同名ファイル（`SKILL.md` 等）のファイル別集計に使えない。`Group-Object Path` を使うか、最初からファイルごとに個別実行する
  - **`Select-String` は行数を数えるため、複数語句を正規表現の OR でまとめると同一行にある場合に 1 件としか数えない**。語句ごとに個別実行して件数を確認すること（Issue-0042）
  - **`Measure-Object -Line` は件数集計に使えない**（入力オブジェクトの行数を数える）。件数は `(… | Measure-Object).Count`
- **中央ストアの現状**: 本repo 58 件（〜`MakeAiInstructions-2026-08-14-02`）＋ LoopForAlpha 106 件。`projects.json` lastSeen 更新済み（2026-08-14）
- **検証用プラグイン `ai-driven-dev-principles-probe` の記録が残っている**（マーケットプレイス定義からは削除済みで実体なし）。片付けるならユーザースコープでのアンインストールが要る
- **inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定**。organize-inbox 提案は不要。`git add <ディレクトリ>` で巻き込まないこと（Issue-0020）
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` は確認済み（未確認モデルでの構造化質問ツール使用前に確認。ADR-0036）。ただし事象確認済みモデル（Fable 5）では構造化質問ツール自体を使用しない（ADR-0085）
- ADR-0023 の留意（継続）: GitHub.com の Copilot コーディングエージェントがルート `CLAUDE.md` を読まない可能性
- **リモート同期**: 前サイクルまでの分（`23e3fc6` まで）は push 済み。**今サイクル分（`693d87f`〜`9259eec` の 16 コミット＋retrospective 分）は未 push**。push は自動では行われないため、必要な区切りでユーザーが指示すること
- **今サイクルのスキル改定（session-handoff / start-work）はプラグイン未反映**。次に session-handoff / start-work を使う前にユーザーへ `/plugin marketplace update ai-driven-dev-principles` の実行を依頼すること（Issue-0044 の実測どおり、update を挟まないと改定前の本文が供給される）

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。形式は `skills/session-handoff/SKILL.md` のフォーマット節を参照（確定点を通過したマイルストーンには `review=` を併記する。ADR-0080）。直近サイクル中の分は `feature_handoff-bloat-analysis.md` 参照（retrospective Phase 3 で突合済み・未消化なし。消化記録 6 行と中央ストア 4 エントリが全件対応）。

- 2026-08-14 マージ（fast-forward `9259eec`）・retrospective 実施・cycle-reset 完了: ADR=なし（課題起票のみ。対策の採否・設計は次サイクル） / worklog=棄却（新規 delta なし。fast-forward マージ件は Issue-0084 が構造観察型として捕捉）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）。**その前にユーザーへ `/plugin marketplace update ai-driven-dev-principles` の実行を依頼すること**（今サイクルの session-handoff / start-work 改定が未反映のため）
2. **直近サイクルは完了**: 追加作業不要。抽出した課題は issues に起票済み（Issue-0083 / Issue-0084。着手はユーザー判断）。delta 型 2 件は worklog 送り（`MakeAiInstructions-2026-08-14-01` / `-02`）
3. **次サイクルの候補（着手はユーザー判断）**: 優先の目安は上記「未着手のタスク」の順。**Issue-0083**（軽量・今サイクルの残欠）を単独で早く畳む選択肢と、**Issue-0074/0065 のペア**（前サイクルで実害 3 件・同じ根）を本命とする選択肢がある。push も未実施のため区切りの指示を推奨
4. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **配布対象ソース（`template.manifest` 記載 / `skills/` 配下 / 空インデックス生成対象）を変更したら、コミット前に執行点 4 手順を実施する**（`CONTRIBUTING.md`。生成器の実行 → 両者を `-Check` → 生成物を同じコミットへ → 目視 5 点）。コミット前フックは無く、書き手の責任で行う
   - **ガイドライン拡張時は過剰適合点検が必須**（ADR-0079）。点検ブロックの無い拡張 spec / 拡張 ADR はコミットしない。**引用元の規範にゲート（条件節）がある場合、それを落としていないかも見ること**（Issue-0066）
   - **確定点（spec / plan）を通過したら確定前レビューを提示し、結果を消化記録へ `review=` で書く**（ADR-0080）。提示では推奨の由来と反対材料も併記する
   - サブエージェント委譲時は `subagent-dispatch` を呼ぶ。**報告された識別子は転記前に実体検証する**（Issue-0057。今サイクルで実在しない修正の報告が 1 件）。破壊的検証を課すときは絶対パスの使用を明示する（Issue-0076）
   - **複数文書にまたがる規範を実装したら、タスク単位のレビュー通過を完了の根拠にしないこと**（Issue-0065）。**決定を Accepted へ昇格させる前に、仕様が最終実装のスナップショットかを検査すること**（Issue-0074。今サイクルで昇格直後に 3 件の未追随が判明）
   - Post ラッパーは1項目ずつ消し込み、結果を消化記録へ書く（ADR-0057）。worklog id は省略せず全体を書く
   - コミット前に `git status --short` を確認し、untracked の巻き込みとステージ済み別件の混入を見る（Issue-0020）
   - コミット・マージのマルチライン文字列は `git commit -F <絶対パスの一時ファイル>`（Issue-0015）
   - ハンドオフの剪定は finalize で基準付き圧縮、サイクル完了時に cycle-reset（`skills/session-handoff/SKILL.md` 操作 4・5。ADR-0075）

## 重要な意思決定の履歴

- ADR-0085〜0089: 直近サイクル（事象確認済みモデルでは構造化質問ツール不使用 / handoff 正本移設の標準 / サイズ実測トリガー / 節別記載規範 / 配置定義とスキル手順の責務境界）。部分修正注記: ADR-0075（保護は移設とセット運用）・ADR-0080（「本サイクル」定義変更）
- （ADR-0001〜0084 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
