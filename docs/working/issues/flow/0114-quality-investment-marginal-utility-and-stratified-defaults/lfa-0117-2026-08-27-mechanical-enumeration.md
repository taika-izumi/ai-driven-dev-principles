> 出所: LoopForAlpha#Issue-0117 の全文コピー（2026-08-30 委譲。ADR-0118）。本文中の Issue-NNNN / ADR-NNNN / worklog id / ファイルパスは LoopForAlpha 側を指す。原本: `docs/working/issues/flow/0117-measure-marginal-utility-of-independent-review-and-stratify-quality-defaults/0117-2026-08-27-mechanical-enumeration.md`（LoopForAlpha リポジトリ）

# Issue-0117 軸2・時点資料: 機械列挙できる3観点の実測（2026-08-27）

`0117-2026-08-27-ponytail-check-perspectives.md` §5 の写像表のうち「機械列挙: 可」とした3観点（実装1つの抽象 / 誰も設定しない設定 / 呼び出し元1つの層）を `src/`・`loop/` に対して実測した記録。**列挙は機械、判定は人手**（列挙結果の各行に判定と根拠を付す）。

## 0. 方法と母数

- 走査スクリプト: 作業用一時領域の `enum0117.py`（Python `ast` でクラス・関数を抽出し、`src/`・`tests/`・`loop/`（`runs/`・`portfolio-runs/` 除外）のテキストに対して識別子の単語一致で参照数を数える。再現は本資料 §0 の方法で足り、スクリプトはリポジトリへ持ち込まない）
- 母数: `src/` 31 ファイル 8,579 行・クラス 60・関数/メソッド 201（dunder 除く）。`loop/` の PowerShell 非テスト 4,109 行・関数 68。`tests/` 30 ファイル 24,515 行・Pester 7,191 行
- 参照数の限界: 単語一致のため同名メソッド（`symbols`・`result` 等）は過大に数える。**過小には倒れない**ので「参照 0 / 1」の抽出には使える

## 1. 観点 A: 実装1つの抽象（`yagni:` インターフェース・ファクトリ）

| 対象 | 実測 | 判定 | 根拠 |
|---|---|---|---|
| `Protocol` / `ABC` / `@abstractmethod` | **0 件** | 該当なし | 抽象基底の機構自体を使っていない |
| `BarStrategy`（`contract/__init__.py:102`） | 派生 **7** | 該当なし | 単一銘柄戦略の共通基底。実装7 |
| `PortfolioStrategy`（`contract/__init__.py:266`） | 派生 **1**（`XsSmaCross`） | **判定保留（設計上の予定実装）** | 第7段階第1部で新設したスロット方式（ADR-0159）の枠。第2部で複数実装を置くことが仕様（仕様08）に書かれており、「実装1つ」は時点の状態。ponytail の `yagni:` は「2つ目が現れるまでインライン」を勧めるが、本プロジェクトでは断面プロトコル（配管の両方向一致を凍結フィクスチャで検査済み）が抽象の対価を既に払っている |
| `_TargetTraceStrategy(backtesting.Strategy)`（`execution.py:81`） | 派生 1 | 該当なし | 外部ライブラリへのアダプタ。ライブラリ側が基底を要求する |
| `dataclass` | 32 | 対象外 | レコード型であり抽象ではない（列挙のみ） |
| `Exception` 派生 | 13 | 観察のみ | モジュールごとに1〜3種。ファクトリ・インターフェースの型ではない。「例外の種類が多い」は本観点の検出対象ではないため判定しない |

**観点 A の結論: 該当 0・判定保留 1（`PortfolioStrategy`）。** 保留の解消条件は第2部の着手（2つ目の実装が置かれた時点で自然解消）。

## 2. 観点 B: 誰も設定しない設定（`yagni:` 設定項目・死んだフラグ）

`loop/eval-config.json` の全キー 49（`_` 始まりの注記を除く）と `loop/settings/loop-settings.json` の全キー 3 について、`src/`・`tests/`・`loop/` での参照数を数えた。

| 分類 | キー | 判定 |
|---|---|---|
| `src/` で参照あり | 47 / 49 | 該当なし |
| `src/` 参照 0・`loop/` 参照あり | `budget.iteration_holdout`（loop 25）・`budget.final_test_limit`（loop 5） | 該当なし。予算台帳はハーネス側（PowerShell）の責務であり Python が読まない設計（ADR-0034/0035） |
| `loop-settings.json` | `permissions.allow` / `permissions.deny` | 該当なし。CLI が読む権限設定。`deny` は Pester が `Get-DeniedReadPath` / `Get-DeniedWritePath` と双方向一致で検査（src=3 は突合用） |

**観点 B の結論: 該当 0。** 参照されない設定キーは存在しない。

## 3. 観点 C: 呼び出し元1つの層（`yagni:` 委譲しかしないラッパー）

### 3-1. Python（`src/`）

| 抽出条件 | 件数 | 内訳と判定 |
|---|---|---|
| `src/` 内参照 0（未使用またはテスト専用） | **0** | — |
| `src/` 内参照 1 かつ委譲型（本体が `return f(...)` の1文） | **3** | `fetch_daily_quotes`（`jquants_client.py:108`。tests 21）/ `fetch_daily_quotes_by_date`（`:127`。tests 8）/ `_jst_now`（`universe/build.py:718`。tests 6） |
| 委譲型（参照数問わず） | 22 | 大半は `@property`（`symbols`・`max_positions` 等）と2〜3行のヘルパ。列挙のみ |

3件の判定:

- `fetch_daily_quotes` / `fetch_daily_quotes_by_date`: **該当なし**。兄弟 `fetch_master` と3本で `_paginate` を共有し、各関数はエンドポイント・パラメータ・障害時の文脈文字列（どの銘柄/日付で落ちたか）を固定する役割を持つ。「委譲しかしないラッパー」ではなく、ponytail 梯子 2（コード内再利用）の実践形
- `_jst_now`: **該当なし**。docstring が「テストはここを固定して書き込みを決定的にする」と用途を明記した**テストシーム**。ponytail の「削らないもの」（検査を1つ残す）側

### 3-2. PowerShell（`loop/`）

68 関数のうち非テスト呼び出し元が **1 以下**のもの 14 件（`Add-FinalEvalIndexEntry`・`Clear-PreviousSubmission`・`Get-BoundaryViolations`・`Get-BudgetPromptSection`・`Get-BudgetSlot`・`Get-DeniedReadPath`・`Get-EvalConfigFinalSetSize`・`Get-EvalConfigFinalSymbolsMin`・`Get-FinalSetsFingerprint`・`Get-FinalTextFromStreamJson`・`Get-NewUntracked`・`Get-SessionTimeLimitPromptSection`・`New-BudgetLedger`・`Test-SandboxConcurrencyAllowed`）。

| 対象 | 実測 | 判定 |
|---|---|---|
| 上記 14 件のうち 12 件 | 非テスト 1・Pester 2〜28 | 該当なし。`run.ps1` / `final-eval.ps1` から1回呼ばれる工程関数で、Pester が個別に検査する単位として切り出されている（呼び出し元1つは「層」ではなく「工程の分割」） |
| `Get-DeniedReadPath`（`HarnessLib.ps1:75`） | 非テスト **0**・Pester 10 | 該当なし。読み取り拒否一覧の**単一の正**（ADR-0090）。実行時には CLI が `loop-settings-0004.json` を読み、Pester が本関数と設定の双方向一致を検査する構成。呼び出し元 0 は設計の帰結 |
| `Get-BudgetSlot`（`HarnessLib.ps1:1807`） | 非テスト **1**（`Add-BudgetEntry`）・Pester **0** | **候補（`shrink:` 級・微小）**。本体2行の内部ヘルパで呼び出し元1つ・直接検査なし。`ValidateSet` で区分を型制約する役割はあるが、呼び出し元の `param` が同じ `ValidateSet` を持つため二重。インライン化しても失うものは無い（効果: -6 行） |

**観点 C の結論: 該当候補 1（`Get-BudgetSlot`。-6 行）・該当なし 16。**

## 4. 総括

| 観点 | 母数 | 該当 | 保留 | 候補の削減幅 |
|---|---|---|---|---|
| A 実装1つの抽象 | 基底 3 | 0 | 1（`PortfolioStrategy`。第2部で解消） | — |
| B 誰も設定しない設定 | キー 52 | 0 | 0 | — |
| C 呼び出し元1つの層 | 関数 269 | 1（`Get-BudgetSlot`） | 0 | -6 行 |

**機械列挙できる3観点では、本システムに過剰設計の兆候はほぼ検出されなかった。** これは調査前に置いた反対材料（`0117-2026-08-27-ponytail-check-perspectives.md` §6 および第95回の提示）どおりであり、**軸2 の懸念が実在するなら、それは関数・設定の粒度ではなく、次のいずれかの粒度にある**と読むのが妥当:

1. **`delete:` 観点 = 完了基準に紐づかない実装**（モジュール・機能単位。逆引き = 人手。写像表の「半自動」行）
2. **検査の最小主義 = 検出器あたりが守る実挙動の数**（`tests/` 24,515 行 + Pester 7,191 行に対して実装 `src/` 8,579 行 + PowerShell 4,109 行 = **検査:実装 ≈ 2.5 : 1**。ponytail は「非自明ロジックに検査1つ・関数ごとのスイートは作らない」を規範とする。ただしこれは軸1 の集計〈検出器 72%〉と同じ対象であり、軸2 として二重に数えない）
3. **観点の粒度が機械列挙に合わない領域** = 仕様 00〜10・ADR 167 件・参照知識・監査記録などの**文書資産**。ponytail はコードのみを対象とするため物差しが無い。本プロジェクトの「所有するもの」の相当部分は文書であり、軸2 を文書へ広げるなら別の物差しが要る

## 5. 本資料の限界

- 参照数は単語一致であり、動的呼び出し（`getattr`・`& $name`）は拾わない。ただし該当 0 側への影響は「見逃し」でなく「過大計上」方向
- 「該当なし」の判定は列挙結果に対する人手判断であり、独立レビューは受けていない
- `Get-BudgetSlot` のインライン化は候補の提示であり、実施は未決（-6 行に対し変更コストと Pester の回帰確認が要る。ponytail 自身の規範でも「Lean already. Ship.」に近い規模）
