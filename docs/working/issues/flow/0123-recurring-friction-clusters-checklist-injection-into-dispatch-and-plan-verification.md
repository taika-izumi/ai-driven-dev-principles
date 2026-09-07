# Issue-0123: 躓き型 5 クラスタ（計画のコードをそのまま書き写す際の写しずれ・PowerShell の落とし穴・対象の総数の引き写し・検証コマンドの未実行・標本の退化）の 1 行チェックリストを委譲制約ブロックと計画の検証ステップへ注入する

- **Status**: open
- **Opened**: 2026-09-04
- **起票元**: `worklog-extract` 走査由来（配布先 LoopForAlpha で 2026-09-04 に実施。作業記録 578 件 → 60 クラスタ。走査記録 = `LoopForAlpha:docs/records/reviews/2026-09-04-dev-process-review/measurement/02-worklog-candidates.md` / `02-worklog-cluster-stats.md` / `worklog-clusters.json`。手順 8 の人間採否で本 5 クラスタを採用〈他 52 候補は未採否〉。台帳 `processed.jsonl` に代表 id 5 件を `adopted` で記録済み）
- **関連**: **Issue-0118**（情報到達の体系。LoopForAlpha#Issue-0169 の申し送り = 注入経路の設計）/ Issue-0122（推奨一致時の既定実行。同じレビュー由来）/ ADR-0065（skillify は適用条件の設計を挟む）/ ADR-0073（B 群表の行は根拠と世代・退役経路を持つ）/ ADR-0102（期待検出量と退役条件）/ ADR-0079（過剰適合点検）/ `skills/subagent-dispatch/SKILL.md` B 群表（注入先 1。「計画に基づく実装を委譲するとき」行は C17a と重なる既存行）/ `skills/start-work/references/plan-deviation-defaults.md` の注入項目（注入先 2）/ Issue-0042（検出器の検出力実証）・Issue-0056・Issue-0073・Issue-0095（C09a・C10a の対策射程）

## 課題内容

配布先 LoopForAlpha の「開発の進め方の見直し」（`LoopForAlpha:docs/records/reviews/2026-09-04-dev-process-review/report.md` 所見 U4・提案 D・E）で、作業記録 578 件のクラスタリングから **人間の指摘を待たずに 9 割超が再発している躓き型クラスタ 5 件** が特定された。いずれも既存スキルに「部分」または「なし」の重複しか無く、記録済みの教訓が発火点で想起されない構造（記録側に読み戻し経路が無い = Issue-0118）の症状として読める。本課題は、この 5 クラスタを 1 行ずつのチェックリストへ圧縮し、**委譲プロンプトの制約ブロック（`subagent-dispatch` B 群表）と計画の検証ステップ（`plan-deviation-defaults.md` の注入項目）の 2 箇所へ注入する**ための skillify の受け皿である（`worklog-skillify` の入力）。

| クラスタ | 再発数（出所） | 代表 id | 既存スキル重複 | 1 行チェックリスト草案 |
|---|---|---|---|---|
| C17a 計画の逐語コード・擬似コードの写しずれ | 17（LoopForAlpha 16・MakeAiInstructions 1） | `LoopForAlpha-2026-07-20-02` / `-08-08-09` / `-08-11-01` | 部分（subagent-driven-development） | 計画のコードを写す前に、写す先ファイルの規約・既存定義・ガード・返り値の識別子・暗黙変換を突合する |
| C08 PowerShell・Pester 固有の落とし穴 | 16（LoopForAlpha 14・MakeAiInstructions 2） | `LoopForAlpha-2026-07-26-07` / `-08-09-31` / `-08-20-06` | なし | 配列は `,@()` かハッシュテーブルで持つ・`-Filter` に文字クラス不可・大小区別は `-cmatch` / `-ceq`・アンカー照合は `.Contains()`・変数名衝突を疑う |
| C10a 件数・母数の引き写し | 16（LoopForAlpha 10・MakeAiInstructions 6） | `LoopForAlpha-2026-07-30-06` / `-08-04-04` / `-08-09-26` | 部分（verification-before-completion） | 件数・母数を書く箇所は出所コマンドを併記し、書く直前に機械で数え直す。レビュー報告の数値も再測する |
| C09a 検証コマンド・期待値の未実行 | 16（LoopForAlpha 7・MakeAiInstructions 9） | `LoopForAlpha-2026-08-01-02` / `-08-22-02` / `MakeAiInstructions-2026-08-07-10` | 部分（verification-before-completion） | 計画に書いた検証コマンドは確定前に欠陥状態を作って検出力を測る。期待値は編集適用後を数える |
| C13b 標本の退化で検出力が消える | 17（LoopForAlpha 17。単一出所） | `LoopForAlpha-2026-08-21-08` / `-08-26-20` / `-09-01-11` | 部分（test-driven-development） | 変異が生存したら実装より先に標本の退化を疑い、境界・分岐ごとに非ゼロの標本があるか数え、行実行計測で MISS を先に見る |

副候補（他クラスタ所属だが関連）と月別分布は走査記録の正本に載っている。

## 対策の方向（skillify で決める。採否は未定）

1. **注入先と形**: B 群表へ 5 行を足すか、既存行（「計画に基づく実装を委譲するとき」= C17a と重なる）へ統合するかを ADR-0065 の適用条件設計で決める。C08 は言語固有のため、B 群行でなく参照知識（PowerShell 検査台本の落とし穴一覧）へ置き、行からは参照だけにする案がある
2. **根拠と世代・退役条件**: 各行に根拠エントリ id（上表）と観測世代（claude-opus-5 系〜claude-fable-5-1）を添え、同型 delta が長期に現れなければ退役候補にする（ADR-0073 / 0102）
3. **過剰適合点検**（ADR-0079）: C13b は単一プロジェクト出所であり、テスト一般へ一般化してよいかを点検する
4. **効果の測定**: 対照が無いため削減量は測定不能。導入後 1 サイクルで各クラスタの再発件数を作業記録で数える（配布先の実測 = `LoopForAlpha:docs/records/reviews/2026-09-04-dev-process-review/measurement/02-worklog-cluster-stats.md` (f) が基線）。反証材料: 規範文の存在だけでは再発が止まらない実例（記録済み教訓の再演クラスタ C21 = 12 件）

## 検討状況

- 2026-09-08: **同じ判定表・注入先を触る申し送り 2 件を配布先から受け入れ**。Issue-0136（LoopForAlpha#Issue-0172。検査委譲で破壊的検証行が発火しない。判定表の発火条件と展開項目）と Issue-0137（LoopForAlpha#Issue-0179。確定前レビューの実装整合性観点に検査 × 実装例の突合が無い。C09a と隣接し注入先 2 が同じ）。着手時は 3 件を同じ機会に扱う（配布先の推奨順は #0123 → 0136 → 0137）
- 2026-09-04: 配布先の手順 8 で採用され起票。**検討難易度 = 中**（skillify の適用条件設計と過剰適合点検が要る。上位モデル推奨）。着手はユーザー判断。Issue-0118 の到達性設計と同じ機会に扱うのが安い

## 結論

（open）
