> 出所: LoopForAlpha#Issue-0117 の全文コピー（2026-08-30 委譲。ADR-0118）。本文中の Issue-NNNN / ADR-NNNN / worklog id / ファイルパスは LoopForAlpha 側を指す。原本: `docs/working/issues/flow/0117-measure-marginal-utility-of-independent-review-and-stratify-quality-defaults/0117-2026-08-27-ponytail-audit-result.md`（LoopForAlpha リポジトリ）

# Issue-0117 軸2・時点資料: ponytail-audit 相当の独立監査の結果と検証（2026-08-27）

`0117-2026-08-27-mechanical-enumeration.md` が覆えなかった判断型の3タグ（`stdlib:` / `native:` / `shrink:`）と `delete:` を、ponytail の `ponytail-audit` 規範（一次ソースの写し）をそのまま与えたサブエージェント1体に走査させた記録。**監査は一覧のみ・修正は未適用**。指摘の採否は未決（§4 の分類が判断材料）。

## 0. 方法

- 委譲: `subagent-dispatch` の A 群4件 + B 群「検査」（全数走査・母数明示・実証なき指摘は不採用）。本プロジェクト固有の「削らないもの」（deny 一覧・fail-closed throw・テストシーム・情報衛生・障害文脈ラッパー・`PortfolioStrategy` の予定実装・判定済み `Get-BudgetSlot`）を明示
- 対象: `src/loopforalpha` 31 ファイル 8,579 行 + `loop/oracle.py`・`loop/calibration/*.py` 4 ファイル 1,807 行 + PowerShell 非テスト 6 ファイル 4,109 行 = **14,495 行**。`tests/`・文書は対象外
- 委譲先の報告: 21 件・`net: -228 lines, -0 deps`（対象の 1.6%）。置換案は Python 3.12 / pwsh 7.6 で置換前後の等値を実行確認したと報告。加えて「判定に迷って書かなかった候補」12 件
- **監査側の検証**（本資料作成者）: (a) 引用の実在 = 削減幅上位3件 + `delete:` 2件の引用行を実コードと突合し一致 (b) 標準ライブラリ置換の等値 = `dataclasses.asdict` 深いコピー・`dict.fromkeys` 順序保持・`max(dict)` 最終キー・`hashlib.file_digest` の存在を手元で再現 (c) 既存判断との重複 = Issue-0116 / ADR-0166 の4件と突合（下記）。**個々の置換コードの全件実行はしていない**（採用時に実施）

## 1. 指摘一覧（削減幅順・委譲先の報告を要約。引用と置換コードは報告原文＝本資料末尾 §6 を参照）

| # | タグ | 箇所 | 内容 | 削減 | 分類（§4） |
|---|---|---|---|---|---|
| 1 | shrink | `driver/cross_section.py:L317-327,L468-553` ↔ `driver/session.py:L623-637,L776-890` | 断面セッションの対話末尾（end 送信→終了待ち→本数検査→余剰 drain→join→転記→cleanup→マーカー検査）が単一銘柄版の逐語複製。`_finish_session()` 切り出し | -55 | **I 重複** |
| 2 | shrink | `loop/final-eval.ps1` 4 箇所 | `summary.json` 書き出しが4回ほぼ同一。ヘルパ1本 | -34 | I 重複 |
| 3 | delete | `driver/session.py:L798-815` / `cross_section.py:L491-499` | 応答本数の最終防壁。コメント自身が「削除しても全テスト緑の冗長な最終防壁（実測）」と明記 | -27 | **II 意図的冗長** |
| 4 | shrink | `HarnessLib.ps1:L1470-1511` | `Get-EvalConfigFinalSetCount` / `-Size` がキー名以外同一 | -20 | I 重複 |
| 5 | delete | `driver/session.py:L700-708` / `cross_section.py:L420-425` | 応答待ち前の締切先読み。コメント自身が「冗長な先読き（実測）」と明記 | -15 | II 意図的冗長 |
| 6 | shrink | `run.ps1:L74-88` / `final-eval.ps1:L110-124` | docker プリフライトが2ファイルで同一 | -12 | I 重複 |
| 7 | yagni | `cross_section.py:L71-83` | `build_snapshot_calendar` は `_union_calendar` への委譲のみ。別名 import で足りる | -12 | III 微小 |
| 8 | yagni | `cross_section.py:L568-576` | `build_portfolio_container_name` は1行委譲 | -8 | III 微小 |
| 9 | delete | `driver/scoring.py:L76-82` | 連結後空検査。コメント自身が「到達不能」と明記 | -7 | II 意図的冗長 |
| 10 | stdlib | `portfolio.py:L94-98,L299-300` | `as_dict` 手書き + リスト複製 = `dataclasses.asdict` | -7 | III 微小 |
| 11 | stdlib | `data/fetch.py:L71-79` | 順序保持デデュープ = `dict.fromkeys` | -6 | III 微小 |
| 12 | native | `HarnessLib.ps1` 3 箇所 | SHA-256 の hex 化手書き = `[Convert]::ToHexStringLower`（.NET 9+） | -5 | III 微小 |
| 13 | delete | `cross_section.py:L45-48` | `_DIRECTIONS = DIRECTIONS` の別名 | -4 | III 微小 |
| 14 | stdlib | `loop/oracle.py:L283-288` | チャンク読み SHA-256 = `hashlib.file_digest` | -4 | III 微小 |
| 15 | yagni | `HarnessLib.ps1:L181-187` | `Get-GoalSettingsPath` の 0004 以外フォールバックは到達不能 | -3 | III 微小（Pester 2件が依存） |
| 16 | shrink | `contract/__init__.py:L94-98,L229-231` | 行→DataFrame 変換3行が2箇所同一 | -3 | I 重複 |
| 17 | shrink | `run.ps1` 2 箇所 / `HarnessLib.ps1` | `docker kill` パイプが3箇所 | -2 | I 重複 |
| 18 | stdlib | `execution.py:L259-261` | sorted ループの最終値 = `max` | -2 | III 微小 |
| 19 | stdlib | `universe/filters.py:L97-99` | `list.count` 内包 = `Counter` | -1 | III 微小 |
| 20 | yagni | `HarnessLib.ps1:L1802-1804` | `Get-RemainingBudget` の `$Kind` は本体で未参照 | -1 | III 微小 |

（委譲先の報告は 21 件と数えたが、本表は同一箇所の再掲を除き 20 行。差は集計上の丸め）

## 2. 判定に迷って書かれなかった候補（12 件・委譲先の自己申告）

いずれも「作者コメントが冗長と明記しつつ多層防御・将来の検出力・凍結部品・利用者確定（Issue-0103）を理由に残している」型、または ADR-0166 D3 で共通化を却下済みの型（`contract/session.py` の JSON 行読み）。監査者が既存判断を尊重して自制した記録であり、§4 の分類 II と同じ性格。

## 3. 既存判断との突合

- **Issue-0116 / ADR-0166 との重複**: 指摘 #1（driver 側の終了処理の複製）は Issue-0116 の4件（`new_run_token`・`_int_at_least_one`・リポジトリルート導出・`contract/session.py` の `run_session`/`run_cross_section`）に**含まれていない**。ADR-0166 が却下したのは凍結部品 `contract/session.py` 側であり、`driver/` 側は凍結対象外。`cross_section.py` 冒頭 docstring は「複製しない（ADR-0140）」と宣言しており、**宣言と実体が食い違う**
- **ADR-0057 / 多層防御の方針**: 分類 II の指摘は、コード自身が「実測で冗長」と記録したうえで残す判断をしている箇所。監査はその判断へ反論（「到達不能な検査を残すより実体を1行で書く方が誤読を防ぐ」）を添えている

## 4. 分類と読み

| 分類 | 件数 | 行数 | 性格 |
|---|---|---|---|
| **I 重複**（ponytail 梯子2 = コード内再利用の不履行） | 6 | **-126** | Issue-0116 と同型。第7段階第1部が「配管の無傷経路」を優先して先送りした複製が、Issue-0116 の選別後にも残っていた（#1 は宣言と矛盾するため最も強い） |
| **II 意図的冗長**（作者が到達不能と明記して残した防壁） | 3（+保留 5） | -49 | 設計スタンスの問題。「多層防御」を理由に、テストで区別できない検査を所有している。ponytail の物差しでは `delete:` だが、本プロジェクトは ADR-0057 等で意図して残している |
| **III 微小**（stdlib/native/1行委譲/未参照引数） | 11 | -53 | 各1〜12行。単独で動く価値は薄い。「Lean already」に近い |

**読み**: 対象 14,495 行に対し -228 行（1.6%）。うち半分強が**重複**で、これは軸2 の懸念（作りすぎ）ではなく **ADR-0140 の規範の未履行**（作るべきものを2回作った）。「目的に不要なモジュール・依存・抽象」（`delete:` の投機的機能・`yagni:` の抽象）は **0 件**。機械列挙（該当1）と合わせ、**コード粒度での「所有するものの過剰」は、複製と意図的冗長の2種に限られ、投機的な構造物は検出されなかった**。

## 5. 採否（2026-08-27 利用者判断 = 下記 1）

**決定**: 分類 I の #1 のみ **Issue-0119** として起票し、他の指摘（I の残り 5 件・II・III）の採否は次サイクル（フェーズ6 / 第2部の工程設計）へ送る。理由: 得られた結論は「投機的構造物なし」であり、残りの採否は軸1 と同じ検査投資の限界効用の問題になるため、工程設計と合流させる。

提示時の未決事項（記録用）:

1. 分類 I の解消を Issue-0116 の続きとして扱うか（#1 は単独で -55 行・宣言との矛盾解消。ADR-0166 の「実害の有無で選別」の基準では「片方だけ直る」実害が起きうる箇所）
2. 分類 II を設計スタンスとして明示的に受容するか（受容なら ADR-0057 系の典拠を各所へ添えて閉じる。削るなら「実測で冗長」の記録を根拠に削れる）
3. 分類 III は一括で流すか放置か（ponytail 規範なら流すが、変更コスト > 効果の可能性）

## 6. 委譲先の報告原文（引用・置換コード・呼び出し元 grep を含む。採用時の作業材料）

（以下、報告テキストをそのまま転記）

```text
走査: Python 31 ファイル 8,579 行（src/loopforalpha）+ 4 ファイル 1,807 行（loop/oracle.py・loop/calibration/*.py）= 35 ファイル 10,386 行 / PowerShell 6 ファイル 4,109 行。全ファイルを全行読了。各置換案は下記の実証済み（Python 3.12.1 / pwsh 7.6.5・.NET 10 で置換前後の等値を実行確認）。

shrink 断面セッションの対話末尾（end 送信→終了待ち→本数検査→余剰 drain→join→転記→cleanup→マーカー検査）が単一銘柄版の逐語複製. session.py に `_finish_session(...)` を切り出して両者から呼ぶ. [src/loopforalpha/driver/cross_section.py:L317-327,L468-553 ↔ src/loopforalpha/driver/session.py:L623-637,L776-890]
  現行（cross_section L503-517。session L820-834 と同一）:
    leftovers: list = []
    while True:
        try:
            extra = responses.get(timeout=_session._LEFTOVER_DRAIN_SEC)
        except queue.Empty:
            break
  置換後: 両ファイルの L776-890 / L468-553 をコメント除去して diff すると差分は「バー/断面」の文言・`len(bars)`↔`len(calendar)`・`_session.` 接頭辞のみ（実測 diff 済み。コード行 69 対 63）。`_finish_session(proc, pump_state, responses, transcript, stderr_lines, deadline, state, expected=len(bars), label="バー", container_name=..., started_marker=..., threads=(out_thread, err_thread))` を session.py に置き、cross_section は `return _finish_session(..., expected=len(calendar), label="断面")`。スレッド起動 + `fail()` 定義（L623-658 / L317-340）も同型なので同時に共有可
  反論: cross_section.py の冒頭 docstring 自身が「タイムアウト・ロックステップ・転記・出力量上限・後始末の実装を複製しない（ADR-0140）」と宣言しており、現状はその宣言に反した複製である
  削減: -55 行

shrink final-eval.ps1 の summary.json 書き出しブロックが 4 回ほぼ同一. 共通ヘルパ 1 本. [loop/final-eval.ps1:L309-324,L396-408,L454-473,L475-487]
  現行（L396-408。L309-324・L475-487 と同一のキー構成、L454-473 は outcome/passed/strategy_sha256/evaluated_at が増えるだけ）:
    [ordered]@{
        goal = $GoalId; run = $Run; iteration = $Iteration; strategy = $strategy
        params = $paramsId; snapshot_digest = $snapshotDigest
        outcome = 'judgement_failed'; reason = $failureReason
        calibrated = (-not $AllowUncalibrated)
  置換後:
    function Write-FinalEvalSummary([hashtable]$Extra) {
        $s = [ordered]@{ goal=$GoalId; run=$Run; iteration=$Iteration; strategy=$strategy
            params=$paramsId; snapshot_digest=$snapshotDigest; calibrated=(-not $AllowUncalibrated)
            production_budget_ledger=$productionBudgetLedger; set_results=@($setResults)
            eval_sets_sha256=$evalSetsSha256; final_sets_fingerprint=$finalSetsFingerprint
            config_sha256=$configSha256; duration_min=[math]::Round(((Get-Date) - $startTime).TotalMinutes, 1) }
        foreach ($k in $Extra.Keys) { $s[$k] = $Extra[$k] }
        $s | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $evalDir 'summary.json') -Encoding utf8
    }
    # 各所: Write-FinalEvalSummary @{ outcome='judgement_failed'; reason=$failureReason }
  削減: -34 行

delete 応答本数の最終防壁（`n_responses != len(bars)` / `len(calendar)`）. なし（コメント自身が「丸ごと削除しても全テストが緑のまま通る冗長な最終防壁であり（実測）」と明記）. [src/loopforalpha/driver/session.py:L798-815, src/loopforalpha/driver/cross_section.py:L491-499]
  現行:
    if n_responses != len(bars):
        fail(
            f"応答本数が送信バー数に一致しません（バー {len(bars)} 件 / 応答 "
            f"{n_responses} 件。ADR-0063）"
        )
  置換後: なし（ループは「応答を得る」か「fail して break」の二択で、完走時は必ず一致 — L801-802 の作者記述どおり。切り詰まりは EOF 分岐 L724、先出しは L767、余剰は L842 が捕捉）
  反論: 監査者向け注記が「ここだけを見て (f) を確認済みとしないこと」と読み手を警告するために 18 行を費やしている。到達不能な検査を残すより、(f) の実体が EOF 分岐 + 余剰検出であると 1 行で書く方が誤読を防ぐ
  削減: -27 行

shrink Get-EvalConfigFinalSetCount と Get-EvalConfigFinalSetSize がキー名以外バイト一致. 1 関数に畳む. [loop/HarnessLib.ps1:L1470-1511]
  現行（L1480-1489。L1501-1510 はキー名 final_set_size に置換しただけ）:
    $v = $raw.universe.final_set_count
    if ($null -eq $v) { throw "評価設定の universe 節に final_set_count が無い（$Path）" }
    if ($v -isnot [int] -and $v -isnot [long]) {
        throw "評価設定の universe.final_set_count が整数でない（$Path）: $v"
    }
  置換後:
    function Get-EvalConfigUniverseInt {
        param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Key)
        $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($raw.PSObject.Properties.Name -notcontains 'universe' -or $null -eq $raw.universe) { return $null }
        $v = $raw.universe.$Key
        if ($null -eq $v) { throw "評価設定の universe 節に $Key が無い（$Path）" }
        if ($v -isnot [int] -and $v -isnot [long]) { throw "評価設定の universe.$Key が整数でない（$Path）: $v" }
        if ($v -gt [int]::MaxValue -or $v -lt [int]::MinValue) { throw "評価設定の universe.$Key が int の範囲外（$Path）: $v" }
        return [int]$v
    }
    function Get-EvalConfigFinalSetCount { param([Parameter(Mandatory)][string]$Path); Get-EvalConfigUniverseInt -Path $Path -Key final_set_count }
    function Get-EvalConfigFinalSetSize  { param([Parameter(Mandatory)][string]$Path); Get-EvalConfigUniverseInt -Path $Path -Key final_set_size }
  （呼び出し元 final-eval.ps1:L202-203 と Pester の関数名参照は不変）
  削減: -20 行

delete 応答待ちの前の締切先読み（`remaining <= 0` 分岐）. なし（コメント自身が「これは冗長な先読みである（実測）」「削っても…同じ分類・同じ文言を出す」と明記）. [src/loopforalpha/driver/session.py:L700-708, src/loopforalpha/driver/cross_section.py:L420-425]
  現行:
    remaining = deadline - time.monotonic()
        if remaining <= 0:
            fail(f"セッション全体の上限 {total_timeout_sec} 秒を超過しました")
            break
        try:
            reply = responses.get(timeout=min(bar_timeout_sec, remaining))
  置換後:
    try:
        reply = responses.get(timeout=max(0.0, min(bar_timeout_sec, deadline - time.monotonic())))
  （timeout=0 で即 queue.Empty → 直下の L716-717 が同じ分類で fail する。`max(0.0, …)` は負の timeout を `queue.get` に渡さないための 1 語）
  反論: 「意図の明示」のために残すとあるが、意図は直下の except 節のコメント（L712-715）が既に説明している
  削減: -15 行

shrink docker プリフライト（CLI 存在・デーモン応答・イメージ存在・uv.lock ラベル一致）が run.ps1 と final-eval.ps1 で同一. HarnessLib へ 1 関数. [loop/run.ps1:L74-88, loop/final-eval.ps1:L110-124]
  現行（run.ps1。final-eval.ps1 は `$preflightErrors`→`$errors` と 1 行の折り返し以外同一）:
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        $preflightErrors += 'docker が見つからない'
    } else {
        docker info 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) { $preflightErrors += 'Docker デーモンが応答しない（Docker Desktop を起動すること）' }
  置換後（HarnessLib.ps1）:
    function Get-DockerPreflightError {
        if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { return 'docker が見つからない' }
        docker info 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) { return 'Docker デーモンが応答しない（Docker Desktop を起動すること）' }
        $label = docker image inspect loopforalpha-sandbox:latest --format '{{ index .Config.Labels "lfa.uvlock-sha256" }}' 2>$null
        if ($LASTEXITCODE -ne 0) { return 'サンドボックスイメージ未ビルド（pwsh -File loop/sandbox/build.ps1 を実行すること）' }
        if ($label -ne (Get-FileHash 'uv.lock' -Algorithm SHA256).Hash.ToLowerInvariant()) { return 'uv.lock がイメージのラベルと不一致（依存変更後の再ビルドが必要）' }
        return $null
    }
    # 呼び出し側: $e = Get-DockerPreflightError; if ($e) { $preflightErrors += $e }
  削減: -12 行

yagni build_snapshot_calendar は `_union_calendar` へ委譲するだけのラッパー. `from loopforalpha.portfolio import _union_calendar as build_snapshot_calendar`（1 行）. [src/loopforalpha/driver/cross_section.py:L71-83]
  現行:
    def build_snapshot_calendar(bars_by_symbol: dict) -> pd.DatetimeIndex:
        """対象銘柄のバー日付の和集合カレンダー（仕様08 §3.7・ADR-0067）。
        ...
        return _union_calendar(bars_by_symbol)
  置換後: import 行での別名束縛（呼び出し元 grep: 本番は cross_section.py:L608 の 1 箇所、tests/test_driver_cross_section.py が 20 箇所で名前を参照 — 別名 import なら名前は保たれる。L471 の `is sentinel` テストは monkeypatch 先が portfolio 側になるため要修正）
  反論: docstring の「正は portfolio 側の 1 箇所」は別名 import でも同じく成立する
  削減: -12 行

yagni build_portfolio_container_name は `build_session_container_name(run_token, "portfolio")` の 1 行委譲. 呼び出し側でインライン. [src/loopforalpha/driver/cross_section.py:L568-576]
  現行:
    def build_portfolio_container_name(run_token: str) -> str:
        """断面セッションのコンテナ名（仕様08 §3.7 = §3.6 の命名規約の断面版）。
        ...
        return build_session_container_name(run_token, "portfolio")
  置換後: __main__.py:L210 を `container = build_session_container_name(run_token, "portfolio")` に（呼び出し元 grep: 本番は __main__.py:L24,L210 のみ。tests/test_driver_cross_section.py:L1556 が 1 件参照）
  削減: -8 行

delete load_symbol_bars の連結後空検査. なし（コメント自身が「上の2つの検査…を通った時点で到達不能」と明記）. [src/loopforalpha/driver/scoring.py:L76-82]
  現行:
    bars = pd.concat(frames)
    if len(bars) == 0:
        # 上の2つの検査（系統が0本・各系統が0行）を通った時点で到達不能。
        raise EnvironmentProblem(
            f"銘柄 {symbol} の対象期間にバーが1本もありません（期間設定を確認してください）"
        )
  置換後: なし（L46 が `not streams` を、L68 が各 frame の `len == 0` を弾くため、非空 frame の concat は非空）
  反論: 「上流の検査が将来変わったときの歯止め」とあるが、上流が変わればこの分岐の到達性も同時に変わる — 検査を 3 重に書く理由にならない
  削減: -7 行

stdlib _Diagnostics.as_dict の手書き + result() でのリスト複製は dataclasses.asdict（深いコピー）と同値. [src/loopforalpha/portfolio.py:L94-98, L299-300]
  現行:
    def as_dict(self) -> dict[str, list]:
        return {"entry_skips": self.entry_skips,
                "deferred_exits": self.deferred_exits,
                "forced_closes": self.forced_closes,
                "negative_equity_days": self.negative_equity_days}
    ...
            diagnostics={key: list(values) for key, values
                         in self._ledger.diagnostics.as_dict().items()})
  置換後: `diagnostics=asdict(self._ledger.diagnostics)`（実測: 結果 dict は等値で、リストも要素 dict も別オブジェクト。`asdict` は既に `execution.py`・`records.py` で使用中）
  削減: -7 行

stdlib `--codes-file` の順序保持デデュープは dict.fromkeys. [src/loopforalpha/data/fetch.py:L71-79]
  現行:
    codes: list[str] = []
    for line in Path(path).read_text(encoding="utf-8-sig").splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        code = cache.normalize_code(stripped)
        if code not in codes:
            codes.append(code)
    return codes
  置換後:
    return list(dict.fromkeys(
        cache.normalize_code(stripped)
        for line in Path(path).read_text(encoding="utf-8-sig").splitlines()
        if (stripped := line.strip())))
  （実測: 空行・BOM・重複を含む入力で同一出力）
  削減: -6 行

native SHA-256 のバイト列→小文字 hex 化 3 箇所の手書き. [Convert]::ToHexStringLower（.NET 9+。実行環境は .NET 10.0.11 で確認）. [loop/HarnessLib.ps1:L1318-1319, L1677-1678, L2160-2162]
  現行（L2160-2162）:
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return [System.BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
  置換後: `return [Convert]::ToHexStringLower([System.Security.Cryptography.SHA256]::HashData($bytes))`（L1318-1319・L1677-1678 の `ForEach-Object { $_.ToString('x2') }) -join ''` も同じ 1 行に。実測で等値）
  削減: -5 行

delete `_DIRECTIONS = DIRECTIONS` の別名. `DIRECTIONS` を直接参照. [src/loopforalpha/driver/cross_section.py:L45-48, L202-204]
  現行:
    _DIRECTIONS = DIRECTIONS
  置換後: なし（呼び出し元 grep: 本番は同ファイル L202,L204 の 2 箇所のみ → `DIRECTIONS` に置換。tests/test_driver_cross_section.py:L1021 が `_cross_section_module._DIRECTIONS is _portfolio_module.DIRECTIONS` を主張しているが、これは別名が存在するから要る検査であり、別名を消せば検査対象も消える）
  削減: -4 行

stdlib チャンク読み SHA-256 は hashlib.file_digest（3.11+。requires-python >=3.12）. [loop/oracle.py:L283-288]
  現行:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()
  置換後:
    with path.open("rb") as f:
        return hashlib.file_digest(f, "sha256").hexdigest()
  （実測: 3 MB 超の入力で同一ダイジェスト。関数名 `_sha256` は loop/tests/test_oracle_0004.py:L684 が monkeypatch するため残す）
  削減: -4 行

yagni Get-GoalSettingsPath の 0004 以外への汎用設定フォールバック. 到達不能（run.ps1:L40-45 が 0004 以外を exit 2 で先に落とす）. [loop/HarnessLib.ps1:L181-187]
  現行:
    if (Test-Path (Join-Path $RepoRoot $goalSpecific)) { return $goalSpecific }
    if ($GoalId -ceq '0004') {
        throw ("ゴール専用の権限設定 $goalSpecific が無い（…）")
    }
    return 'loop/settings/loop-settings.json'
  置換後:
    if (Test-Path (Join-Path $RepoRoot $goalSpecific)) { return $goalSpecific }
    throw ("ゴール専用の権限設定 $goalSpecific が無い（…）")
  （呼び出し元 grep: run.ps1:L121 のみ。loop/tests/HarnessLib.Tests.ps1:L335,L338 が '0002' のフォールバックを検査しているが、同ファイルの兄弟 Get-DeniedWritePath / Get-AllowedWritePattern は既に「0004 以外は throw」で統一済み — ADR-0082 の「default で黙って値を返さない」規律とも揃う）
  削減: -3 行

shrink _HistoryBuffer.frame と _IncrementalHistory.frame の行→DataFrame 変換 3 行が同一. モジュール関数 1 本. [src/loopforalpha/contract/__init__.py:L94-98, L229-231]
  現行（L229-231。L94-98 と同一式）:
    fresh = pd.DataFrame(self._pending, columns=["Date", *HISTORY_COLUMNS])
    fresh["Date"] = pd.to_datetime(fresh["Date"])
    fresh = fresh.set_index("Date")[list(HISTORY_COLUMNS)].astype("float64")
  置換後:
    def _rows_to_frame(rows: list[dict]) -> pd.DataFrame:
        df = pd.DataFrame(rows, columns=["Date", *HISTORY_COLUMNS])
        df["Date"] = pd.to_datetime(df["Date"])
        return df.set_index("Date")[list(HISTORY_COLUMNS)].astype("float64")
    # 両 frame(): `self._frame = _rows_to_frame(self._rows)` / `fresh = _rows_to_frame(self._pending)`
  削減: -3 行

shrink `docker ps -q --filter name=lfa-sandbox- | docker kill` が 3 箇所. HarnessLib に `Stop-SandboxContainers`. [loop/run.ps1:L321-322, L383-384, loop/HarnessLib.ps1:L2232-2233]
  現行:
    docker ps -q --filter 'name=lfa-sandbox-' 2>$null |
        ForEach-Object { docker kill $_ 2>$null | Out-Null }
  置換後: `function Stop-SandboxContainers { docker ps -q --filter 'name=lfa-sandbox-' 2>$null | ForEach-Object { docker kill $_ 2>$null | Out-Null } }` + 3 箇所を 1 行呼び出しに
  削減: -2 行

stdlib 宣言列の最終状態を sorted ループで求めている. `max`. [src/loopforalpha/execution.py:L259-261]
  現行:
    last_state = FLAT
    for ts in sorted(targets):
        last_state = targets[ts]
  置換後: `last_state = targets[max(targets)] if targets else FLAT`（実測: 3 件の順不同 dict で同一結果）
  削減: -2 行

stdlib 正規化後コードの重複検出が list.count の内包. collections.Counter. [src/loopforalpha/universe/filters.py:L97-99]
  現行:
    duplicates = sorted(
        {code for code in normalized_all if normalized_all.count(code) > 1}
    )
  置換後: `duplicates = sorted(c for c, n in Counter(normalized_all).items() if n > 1)`（実測で同一。`from collections import Counter` を追加）
  削減: -1 行

yagni Get-RemainingBudget の `$Kind` パラメータは本体で未参照. 削除. [loop/HarnessLib.ps1:L1802-1804]
  現行:
    param([Parameter(Mandatory)]$Ledger,
          [ValidateSet('iteration')][string]$Kind = 'iteration')
    return [int]$Ledger.iteration_holdout.budget - [int]$Ledger.iteration_holdout.used
  置換後: `param([Parameter(Mandatory)]$Ledger)`（呼び出し元 grep: HarnessLib.ps1:L2483 / run.ps1:L157,L344 / Pester 6 件 — すべて `-Ledger` のみで `-Kind` を渡す箇所は 0 件）
  反論: コメントは「誤って残高判定に使う実装を型で防ぐ」とあるが、取りうる値が 1 つの ValidateSet は何も区別しない
  削減: -1 行

net: -228 lines, -0 deps possible.

判定に迷って書かなかった候補:
- shrink contract/session.py:L167-178 ↔ L314-325 — run_session と run_cross_section の JSON 行読み（空行スキップ→loads→dict 検査）12 行が同一。ジェネレータ _messages(stdin) で -8 行だが、ADR-0166 Decision 3 が「凍結部品 run_session の本体への改変」を理由に同型の共通化を却下済みのため見送り
- delete driver/__main__.py:L33-35 _no_negative_zero — value + 0.0 で同じ（実測 -0.0+0.0 → 0.000）。3 行減るが呼び出し側の可読性が落ちるため保留
- delete execution.py:L264-269 forced 判定の符号条件と break — コメント自身が「振る舞いに影響しない（実測）」と述べるが「多層防御」を理由に残しており、ADR-0057 の同型判断に紐づくため保留
- delete config.py:L586-590 window_bars < MIN_WINDOW_BARS — 直後の <= MIN_ACTIVE_BARS に包含される（作者も明記）。役割が別で定数校正で分離しうるとの理由に従い保留
- delete universe/build.py:L978-995 抽出結果の形の表明 — draw_eval_sets の戻り値は引数の size で構造的に決まる（rng.choice(size=size)）ため恒真。ただし「引数取り違え」を捕まえる自己検証としてレビューが要求した経緯があり保留
- shrink calibration/null_distribution.py:L300-302 期間リターンの手計算 — scoring.py:L216-219 は同じ量を compute_metrics(equity, []).return_pct で取り「定義を 1 箇所に保つ」と述べている。行数は同じなので見送り（一貫性の問題であり複雑性ではない）
- delete HarnessLib.ps1:L847-857 Resolve-DuplicateTrialOutcome 検証1 — 作者が「現状この検査は到達不能【冗長】」と明記。純関数側の対称性を理由に残しているため保留
- delete HarnessLib.ps1:L742,L757 Get-PastSubmissionFailure の条件 (1)(2)(5) — 作者が「現時点で冗長な層」「外しても全緑（変異で実測）」と明記。将来の検出力を理由にしているため保留
- delete HarnessLib.ps1:L603 Find-DuplicateTrial の $Identity 側の事前判定 — 作者が「片側から導出できる冗長な防御」と明記。同上
- stdlib universe/master.py:L34-41 / fetch_master.py:L61-69 / driver/config.py:L300-320 / universe/build.py:L130-151 の日付検証 4 重複 — Issue-0103 で「5 箇所目まで共通化を見送る」と利用者確定済みのため書かない
- yagni oracle.py:L25 _STRATEGY_NAME と L42 _PARAM_KEY が同一正規表現 — 概念が別（戦略名/params キー）と HarnessLib 側も同じ理由で別定数にしており、統一すると片方だけ緩める変更ができなくなるため保留
- delete execution.py:L306-307 週末判定による年率化係数 365/252 — docstring が「営業日インデックス前提」と述べるため 365 分岐は実データで到達しないが、backtesting.py との黄金比較（ADR-0051）の等価性に関わるため保留
```
