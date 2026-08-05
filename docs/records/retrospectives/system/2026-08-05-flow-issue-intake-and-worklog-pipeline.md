# Retrospective: 配布先 flow 課題の取り込みと worklog パイプラインの疎通

- **Subject**: 配布先 LoopForAlpha の flow 課題を取り込む経路の規範化と、worklog パイプライン（record → extract → skillify）の疎通
- **Branch**: feature/flow-issue-intake-and-worklog-pipeline（merge済み: `a0b16c9`）
- **Period**: 2026-08-05 〜 2026-08-05（単一セッション）
- **Plan**: `docs/working/plans/2026-08-05-flow-issue-intake-and-worklog-pipeline.md`
- **Spec**: （なし。規範文書と skills の改定が成果物）
- **Related ADRs**: ADR-0061, ADR-0062, ADR-0063, ADR-0064, ADR-0065, ADR-0066, ADR-0067, ADR-0068, ADR-0069
- **Facilitator**: メインエージェント (claude-opus-5[1m])

## 1. 達成サマリ

- **取り込み経路を規範化した**。配布先の flow 課題は issue 自身の振り分け判定に従い、delta 型は `worklog-extract` の再走査へ委ね、構造観察型のみ手で取り込む（ADR-0061）。申し送りの起票経路を 2→4 へ拡張し、close トリガーを「受け皿の実在確認」と定義（ADR-0063）、クロスリポジトリ参照を `<repo>#Issue-NNNN` に固定した（ADR-0068）。`folder-structure.md` 7.2〜7.4 改定・`sync-template.ps1` 実行済み（`7110e36` / `6f2c1fb`）
- **中央ストアの契約と手段の矛盾を解消した**。`Add-Content` は Windows で CRLF を書くため契約（LF 固定）を満たせない。書き側を行終端の明示できる API へ限定し、読み側に `check-store-health.py` を新設（ADR-0064、`00f2289` / `452f2da`）。既存の CR 混入 5 行をユーザー opt-in のうえ正規化（内容不変を検証、`a4f6250`）
- **止まっていたパイプラインを疎通させた**。3 サイクル起動していなかった経路を動かし、118 件を全数走査して 14 クラスタを検出。Issue-0042 / 0043 を起票、候補7 を Issue-0033 へ合流、7 件 deferred・2 件 rejected。台帳 18→31 行（`125a846`）
- **採用済み候補の設計を確定した**。根拠一覧をそのまま規範へ写さず適用条件の設計を挟む方針（ADR-0065）のもと、委譲の定型項目を A 群 4 件（常時適用）と B 群 8 件（条件発火）へ分割し（ADR-0066）、確定前レビューは新規スキルとする方式を決めた（ADR-0067）。**スキル本体の authoring は次サイクル**（`8b4068a`）
- **配布先の課題 20 件を処理した**。受け皿の実在を確認した 5 件を close、残り 15 件に処置を注記（LoopForAlpha `438192c`）。規範 7.3 は両リポジトリに存在しながら一度も適用されていなかったため、これが初回適用にあたる

## 2. 課題（対象システム固有）

課題の抽出と分類まで（対策の設計・採否判断・ADR化は次サイクル。ADR-0021）。

**本サイクルで抽出された対象システム固有の課題はない。** 本リポジトリの成果物はガイドライン本体（規範文書・スキル）であり、今サイクルで観測された課題はすべて開発の進め方に関するものだった。

> 開発フロー課題 3 件は [flow/2026-08-05-flow-issue-intake-and-worklog-pipeline.md](../flow/2026-08-05-flow-issue-intake-and-worklog-pipeline.md) 参照。worklog 送りとした delta 型候補 2 件（起票なし。ADR-0056 の振り分け規則）。

## 3. 既存課題の再発・進展

- **Issue-0020**（コミット直前のステージング内容確認）: 同一セッションで 2 回再発。範囲の広い `git add docs/` がユーザー管理の untracked ファイル 4 件を巻き込み、1 回目は commit 直前に気づいて回避、**2 回目は気づかずコミットまで通し** `git rm --cached` ＋ `commit --amend` で修復した。**1 回目の再発防止手順を worklog へ記録した直後の再発**であり、記述による規律では防げないことの実測になる（ADR-0031。worklog `MakeAiInstructions-2026-08-05-05`）
- **Issue-0042**（検出器の検出力）: 起票当日に本サイクル内で同型を 1 件観測。健全性検査の初版が課題本文の明記していた要求（追記チャンク中途の BOM）を満たさないまま self-test は PASS しており、**対照の網羅性が不足すれば対照があっても欠陥は見えない**という知見を追記した（worklog `MakeAiInstructions-2026-08-05-02`）
- **Issue-0032 / Issue-0040 / Issue-0041**: 本サイクルで close（それぞれ ADR-0064 / Task 1 / ADR-0063・0068）
- **Issue-0033 / Issue-0034**: 対策方針を ADR-0066 / ADR-0067 で確定。`adopted` のまま authoring は次サイクルへ
