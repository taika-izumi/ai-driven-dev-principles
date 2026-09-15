# 隔離検証 v3 実装計画 タスク1〜7 の実装時レビューと最終レビューの記録

- 対象計画: `docs/working/plans/2026-09-14-isolated-verification-v3-implementation.md`（plan 確定点 285f315）
- 対象範囲: コミット `2d0db67`（実装着手前）〜 `7450e74`（最終修正）。成果物は `scripts/verification/` 配下
- 実施: 2026-09-15〜16。実行方式は subagent-driven-development（タスクごとに実装担当・タスクレビュー・差分再確認）。主担当は当初 claude-fable-5-1、利用者の指示（トークン消費の抑制）で途中から claude-opus-5
- 実行していないもの: タスク8・9（実VM・実モデル。個別承認が必要）

## 結果の要約

| 項目 | 結果 |
|---|---|
| 独立試験ランナー（最終修正と残件修正の後、`9f4ce11`） | 11群合格、終了値0、1705秒（`Independent verification: 11 suites passed (no agent launched)`） |
| 群ごとの件数（同上） | RequestCopy 26 / History 23 / Execution 7 / Result 15 / RequestCopyV3 61 / ExecutionV3 18 / SbxRuntimeV3 24 / ProposalV3 16 / ReplayV3 17 / ResultV3 18 / CliV3 17 |
| 実装時の逸脱記録 | 計画の各タスク末尾に `逸脱記録:` 行として記録（型の内訳は計画ファイルを正本とする） |
| 起票した課題 | Issue-0146（run 配下のパックファイルのパス長で履歴復元が失敗）、Issue-0147（MSIX 版 pwsh の ProcessHost で非パッケージの子がジョブに入らない。修正済み、残る窓はタスク8a で観測） |
| 起票した決定記録 | ADR-0198（全体期限の後に pilot 排他を取得できない場合も、CLI は VM を作らない型付き結果を照合へ渡す。Proposed） |

## レビューの経過

| タスク | 実装時レビュー（Opus） | 修正ラウンド | 差分再確認（Sonnet） |
|---|---|---|---|
| 1 依頼・設定・固定入力と基準版準備 | 承認（Minor 8） | なし | — |
| 2 プロセス実行の v3 拡張 | Important 2 | 1回 ＋ Issue-0147 の統合修正 | 解消 |
| 3 sbx 実行基盤 | 差分が大きくツール上限で停止 → 本体側・試験側の2分割で Important 7 | 1回 | 解消 |
| 4 提案VMと未信頼 Envelope | Important 1 ＋ ブリーフ整合2 | 1回 | 解消 |
| 5 通信なし再実行 | Important 1 ＋ 仕様差2を引上げ | 1回 | 解消 |
| 6 3入力の照合 | Important 2 ＋ 能力証拠の未照合 | 1回（重複処理の RequestCopy への集約を前倒し） | 2分割で解消 |
| 7 共通CLI・ランナー・README | Important 1（期限到達で照合を通らない） | 1回（ADR-0198） | 解消 |
| 最終レビュー | 3分割（契約と CLI／保護条件／試験と README）でいずれも With fixes、Critical なし | 1回（22件） | 3分割で解消 |

最終レビューで直した主な点: 停止手順の例外経路で停止証拠と停止結果を必ず残す、ジョブ割当の失敗を作成成否不明として扱う、profile の sbx の版をデーモンの版と照合する、全体期限を run 単位の単調時計でも強制する、提案・再実行の例外の説明文を標準エラーに残す、時間に依存していた試験3件、未試験だった作成時の値不一致・照合側の別 runId・CLI の finally 停止。

## 主担当が利用者の代わりに下した判断（覆す場合は該当箇所を参照）

判断の全件と、誤っていた場合の費用は台帳 `.superpowers/sdd/2026-09-14-isolated-verification-v3-implementation/progress.md`（未追跡の作業領域）にある。計画の逸脱記録と重ならない、利用者の確認を特に勧めるものを次に挙げる。

1. **ADR-0198**: 全体期限の後に Lease を取得できない場合、CLI は Lease なしで提案（VM を作らず timed_out を返す）と照合へ進む。仕様00「Lease は両経路を覆う」の字面から外れるが、Lease の無い VM 作成は SbxRuntime が拒否する。ADR-0158 の委任に基づくAI判断
2. **前回結果の再利用条件**（タスク1）: recheck の前回結果は `timed_out` と停止未確認だけを拒否し、`completed` を要求しない（ブリーフどおり）。仕様03「証拠欠落の結果からは再利用しない」と緊張関係にあり、incomplete でも再実行が停止済み・hash 一致なら再利用しうる
3. **再実行の Environment**（タスク5）: 計画内の食い違い（profile に環境辞書の項目が無い）を、Replay の定数の空辞書で固定した。タスク8a で環境変数が必要と分かれば schema 変更として扱う
4. **import 検査の過検出**（タスク5）: コメント・文字列内の import も数え、拒否側に倒す
5. **試験 test の配置**（タスク4）: 提案の test は `tests/` 直下だけを受理する（サブディレクトリ不可）
6. **偽 sbx の本体がジョブに入らない制約**（タスク3）: 試験は PID 指定の後片付けで吸収し、保持停止の確認は対象プロセスの消失で代替する。実機の sbx.exe は非パッケージなので製品の保護判定には及ばない
7. **ランナーの所要**（タスク7）: 11群を順に実行すると約25分かかることを受け入れ、並行実行や省略の仕組みは入れていない
8. **モデル配置**: 利用者の切替え以後、実装担当 Opus・タスクレビュー Opus・差分再確認 Sonnet。タスク3の実装担当だけは起動済みの Fable のまま完了させた

## 未対応で残したもの

- （解決済み）復旧操作が結果を保存したあとに例外を投げ直す件は、利用者の指示（2026-09-16「1で」）で `9f4ce11` にて修正した。Lease 取得後の照会失敗では保存した recovery-result を返し、全対象を `stateBefore='query-failed'`・`stopState='unverified'`・`evidencePath=null` にする。理由は標準エラーへ1行出す。結果の schema は変えていない（`stateBefore` は値を制限しない）。CLI は返った結果を標準出力に1件出し終了値2。試験は SbxRuntimeV3 ケース17f と CliV3 ケース12b。差分再確認は要件5件とも満たすと判定
- **繰り延べた Minor**: 最終レビューの指摘一覧 `.superpowers/sdd/2026-09-14-isolated-verification-v3-implementation/final-fix-findings.md` の「繰り延べ」節（停止確認の ls の各回で running を再確認しない、chown 直前の維持確認なし、profile 拒否が照合を通らない、同じ約束の写し、試験の組み立て補助の約120行の重複など）
- **タスク8a で確認する事項**: 実機 sbx.exe が起動からジョブ割当までの一瞬に子を生むか（Issue-0147）、SSH 転送ログ行の形式、デーモンの版の表記、テンプレートの python3 での import 起点と unittest 要約の出力先、`sbx cp` の配置、ジョブ割当失敗時の実機の挙動
