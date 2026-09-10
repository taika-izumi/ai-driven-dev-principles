# モデル裁量との比較・準備と実行計画

> エージェント向け: `superpowers:executing-plans` で各タスクを順に進める。独立した作成実行の開始はTask 4の個別承認後。本計画の作成だけでモデルを起動しない。

**目的:** 既存契約枠を使う2モデル・2題材・2条件の比較を、入力・保護・停止・固定検査の成立を確認して実施する。

**構成:** 入力準備、公式CLIによる実行管理、外側の採点を分ける。常設基盤は作らず、試験用のファイルと公式出力で受け渡す。

**技術:** Windows、PowerShell、Python標準ライブラリ・pytest、Codex CLI 0.153.4、Claude Code 2.1.267。

**仕様:** [概要と3ブロック](../../current/specs/2026-09-10-model-discretion-comparison/00-overview.md)。仕様はフル1回・差分1回・機械検証1回を経て確定済み。本計画は確定した仕様との対応確認を終え、計画確定点の判断待ち。

## 全体制約

- モデルは `gpt-6-astra / medium` と `claude-opus-5[1m] / high`。既存契約枠のみ。
- 8実行・各30分・作成側240分・準備と外側検査60分・実行段階全体300分。子と再開を同じ実行へ合算。
- 元版は `86d89a8091de8366161569a7771affb0ff279607`。元のLoopForAlpha、既存WorkflowTrials/run-*、中断中のworktreeは変更しない。
- 作成側の領域と、検査原本・相手成果物の領域を分ける。設定分離・境界・親子停止を実測するまで比較を起動しない。
- 実装時レビューへの引き継ぎ指摘: 現時点でなし（確定前レビュー未実施）。逸脱判断はstart-workの `references/plan-deviation-defaults.md` を適用する。
- 今回の成果物は比較の準備資料。試験用スクリプト・人工ログの作成は以下のタスクで行い、既に実装済みとは扱わない。

## Task 1: 起動条件を確かめ、可能な操作だけに絞る

**読むもの:** 仕様02、CLIの実際のヘルプ、公式認証・設定資料、準備メモの確認結果。
**出力:** 試験用領域の `control/preflight.json`。各確認項目はpass/fail/unknownと証拠を持つ。
**受け渡し:** Task 4の承認提示へは、非モデル確認の結果と具体的な起動引数案を渡す。モデル起動が必要な項目はunknownのままでよい。全項目passはTask 4の事前実測後、本比較の開始直前に要求する。

- [ ] 次の非モデル実行コマンドを通常ユーザーの権限で確認する。認証情報本文を表示しない。

```powershell
codex --version
codex login status
codex exec --help
codex sandbox --help
claude --version
claude auth status --json
claude --help
```

期待値: 版は上記と一致、CodexはChatGPTログイン、Claudeはclaude.ai契約。既に今回の確認は成功しているため、後続時点で環境が変わっていなければ証拠を再利用する。Claudeの認証出力はloggedIn/authMethod/apiProvider/subscriptionTypeだけを保存する。

- [ ] 試験専用の設定読み込み元、AGENTS/CLAUDE・スキル・プラグイン・メモリの自動読み込み、子への継承、管理側の上位制約を照合する。Codexの `--ignore-user-config` はユーザーconfigだけの説明であり、全指示無効化と解釈しない。Claudeのsafe-modeは通常の委譲条件まで変えないか確認する。
- [ ] 公式機能で親子に同じ保護を適用する経路と、停止・実行結果回収の経路を特定する。ヘルプにないサブコマンドを推測で実行しない。今回 `codex sandbox windows --help` は現在の構文と異なり、サンドボックス起動を試みてエラーになった。現CLIは `codex sandbox [OPTIONS] [COMMAND]...` であり、この失敗を保護検証の結果に数えない。
- [ ] `preflight.json` に未実測の項目をunknownとして残す。起動引数は一度PowerShell文字列へ連結せず、実行ファイルと引数配列で保存する。取得不能や未確定の引数を推測で埋めない。
- [ ] モデル起動を伴う確認、試験用領域への作成、無害な保護・停止確認を含めた具体的な操作範囲を提示する。実行承認と現在の環境権限が揃うまで依存操作を行わない。

完了条件: 起動方法の候補・許可範囲・非モデル確認の結果・未実測項目を区別し、Task 4で何を承認後に実測するか提示できること。本比較はTask 4の実測で全passになるまで始めない。経路を成立させるための新規隔離基盤・通常設定変更・別モデルへの変更は、本タスクの自動対処に含めない。

## Task 2: 同一開始版と人工ログを準備する

**作成先:** `D:/Dev/002_AiDev/WorkflowTrials/model-discretion-20260910`。
**ファイル:** `control/manifest.json`、`source.zip`、`baseline/`、`public-fixtures/`、`prompts/`、`guidelines/template-source/`、`guidelines/ai-driven-dev-principles/`、`guidelines/superpowers/`。
**入力:** 仕様01の取得対象と題材依頼。
**出力:** 共通入力のハッシュと固定開始版。各実行のコピーはTask 4でこのbaselineから作る。

- [ ] 対象ディレクトリが既存なら上書きしない。実体と用途を確認する。新規なら許可された範囲内で作成し、同名の既存試験と混ぜない。
- [ ] 次のコマンドで指定版の限定ファイルを取得する。既存の作業ツリーをコピーしない。

```powershell
git -c safe.directory=D:/Dev/001_Trade/LoopForAlpha -C D:/Dev/001_Trade/LoopForAlpha archive --format=zip --output=D:/Dev/002_AiDev/WorkflowTrials/model-discretion-20260910/source.zip 86d89a8091de8366161569a7771affb0ff279607 tools/process_trace tests/test_process_trace_records.py tests/test_process_trace_session.py tests/test_process_trace_tables.py
Expand-Archive -LiteralPath D:/Dev/002_AiDev/WorkflowTrials/model-discretion-20260910/source.zip -DestinationPath D:/Dev/002_AiDev/WorkflowTrials/model-discretion-20260910/baseline
```

期待値: tools/process_trace内の8 Pythonファイルと既存テスト3本を取得。元リポジトリの.env、実データ、会話履歴、Git管理領域、設定ファイルは含まれない。実際の `git ls-tree -r --name-only` と照合し、数が違えば開始版の実体を確認して期待値を訂正する。

- [ ] 次の固定取得元から、通常の導入先を変更せず条件用資料を複製する。templateは公開時コミットの10ファイルを使う（同コミットの実在と一覧を確認済み）。存在しないv0.1.26タグは使わない。

```powershell
$trialRoot = 'D:/Dev/002_AiDev/WorkflowTrials/model-discretion-20260910'
New-Item -ItemType Directory -Path "$trialRoot/guidelines" | Out-Null
git -c safe.directory=D:/Dev/002_AiDev/MakeAiInstructions -C D:/Dev/002_AiDev/MakeAiInstructions archive --format=zip --output=D:/Dev/002_AiDev/WorkflowTrials/model-discretion-20260910/guidelines/template.zip f5229a836156e9a502f2fbde5a5ffddcb2509256 template
Expand-Archive -LiteralPath "$trialRoot/guidelines/template.zip" -DestinationPath "$trialRoot/guidelines/template-source"
$packages = @(
    @{ Source='C:/Users/d12an/.codex/plugins/cache/ai-driven-dev-principles/ai-driven-dev-principles/0.1.26'; Name='ai-driven-dev-principles'; Version='0.1.26' },
    @{ Source='C:/Users/d12an/.codex/plugins/cache/superpowers-marketplace/superpowers/6.3.0'; Name='superpowers'; Version='6.3.0' }
)
foreach ($package in $packages) {
    $metadata = Get-Content -Raw -LiteralPath "$($package.Source)/.codex-plugin/plugin.json" | ConvertFrom-Json
    if ($metadata.version -ne $package.Version) { throw '取得元の版が不一致' }
    $destination = "$trialRoot/guidelines/$($package.Name)"
    if (Test-Path -LiteralPath $destination) { throw '複製先が既存のため停止' }
    New-Item -ItemType Directory -Path $destination | Out-Null
    Get-ChildItem -Force -LiteralPath $package.Source | Where-Object Name -ne '.git' | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $destination -Recurse
    }
}
```

取得物の相対パス・SHA256と版をmanifestへ保存し、コピー元との一致を確認する。templateの版は `guideline_template_commit=f5229a836156e9a502f2fbde5a5ffddcb2509256` として記録する。取得物を勝手に更新しない。template-source/templateの内容は既存手順条件の作業コピーへだけ配置し、2プラグインのコピーは同条件の試験専用読み込み設定へ渡す。モデル裁量条件へは配置・有効化しない。実際の設定と親子への継承はTask 4で確認する。

- [ ] `public-fixtures/bug/` と `public-fixtures/feature/` を分け、次の親ログをUTF-8で保存する。本文の検査文字列は全条件共通。日時題材の追加例は `bug/alpha.jsonl` の3行目と同じ形式で、時刻を `invalid` とキー欠落に変える。小機能の `feature/alpha.jsonl` は先頭2行だけにして、日時題材の不具合と混ぜない。

```jsonl
{"type":"user","timestamp":"2026-09-01T00:00:00Z","origin":{"kind":"human"},"message":{"content":"BODY_SENTINEL_ALPHA"}}
{"type":"assistant","timestamp":"2026-09-01T09:00:01+09:00","attributionSkill":"example:skill","message":{"id":"m-alpha","model":"fixture-model","usage":{"input_tokens":10,"output_tokens":2},"content":[{"type":"text","text":"ASSISTANT_SENTINEL_ALPHA"}]}}
{"type":"user","timestamp":"2026-09-01T00:00:02","origin":{"kind":"human"},"message":{"content":"BODY_SENTINEL_UNKNOWN"}}
```

`beta.jsonl` と `gamma.jsonl` はそれぞれ次の1行。選択機能用のalphaは上記の先頭2行のみ。

```jsonl
{"type":"user","timestamp":"2026-09-01T00:10:00Z","origin":{"kind":"human"},"message":{"content":"BODY_SENTINEL_BETA"}}
```

```jsonl
{"type":"user","timestamp":"2026-09-01T00:20:00Z","origin":{"kind":"human"},"message":{"content":"BODY_SENTINEL_GAMMA"}}
```

- [ ] 両題材の `alpha/subagents/agent-fixture.jsonl` には親例のassistant行を複製し、message.idをそれぞれ `m-child-1` と `m-child-2` に、時刻を有効値・タイムゾーンなし値へ変えた2応答を保存する。選択機能用では両方を有効時刻にする。
- [ ] 題材依頼は仕様01の引用文をそのまま保存する。共通の製品説明と権限・上限・報告要求を別ファイルへまとめる。解法・正解コードは含めない。
- [ ] 取得ファイル、人工ログ、依頼、追加するガイドライン一式のSHA256をmanifestへ記録する。設定に必要な製品情報を片方だけから除去しない。

検証: baselineをcwdに `python -B -m pytest -p no:cacheprovider` で対象3本を明示して実行し、終了コードと実行・成功・失敗・スキップ・エラー数を保存する。今回、通常ユーザー権限の `D:/Dev/001_Trade/LoopForAlpha/.venv/Scripts/python.exe` では23件成功・スキップ0だった。これは固定された原版の確認結果であり、生成された候補コードを通常ユーザー権限で実行する指定ではない。実際の試験用プロファイルで元リポジトリ・Python本体・依存パッケージへ変更できない状態で利用できるかを確認する。必要テストのスキップ・0件実行はpassにしない。pytest不足なら自動インストールせず既存環境を確認する。元の製品全テストを本試験用コピーへ持ち込まない。

## Task 3: 固定検査を作り、正常・不合格を区別する

**ファイル:** `control/checks/test_contract.py`、`control/private-fixtures/`、`control/checks-manifest.json`。
**入力:** 仕様03のBUG-01〜05、FEATURE-01〜04、COMMON-01〜02。
**出力:** 検査原本のハッシュと正常・不合格例の実施記録。作成側へ原本を書き込み可能にしない。

- [ ] 固定検査は作成側のconftest等を読み込まない外側のテスト環境で実行する。公開例とは値が異なる人工ログを使用し、仕様外の要求を追加しない。
- [ ] 日時関数を直接確かめる部分は次の内容を用いる。対象ソースは環境変数 `COMPARISON_CANDIDATE` で外側から指定する。原版ではタイムゾーンなし値の検査が失敗することを先に確認する。

```python
import importlib
import os
import sys
import unittest
from pathlib import Path

class TimestampContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        candidate = Path(os.environ["COMPARISON_CANDIDATE"]).resolve()
        sys.path.insert(0, str(candidate))
        module = importlib.import_module("tools.process_trace.records")
        if not Path(module.__file__).resolve().is_relative_to(candidate):
            raise RuntimeError("candidate module resolved outside candidate")
        cls.parse_ts = staticmethod(module.parse_ts)

    def test_equivalent_offsets(self):
        first = self.parse_ts("2026-08-20T00:00:00Z")
        second = self.parse_ts("2026-08-20T09:00:00+09:00")
        self.assertIsNotNone(first)
        self.assertIsNotNone(first.tzinfo)
        self.assertEqual(first, second)

    def test_unknown_times(self):
        for value in (None, "invalid", "2026-08-20T00:00:00"):
            with self.subTest(value=value):
                self.assertIsNone(self.parse_ts(value))

if __name__ == "__main__":
    unittest.main()
```

- [ ] CLI検査はサブプロセスで `python -B -m tools.process_trace INPUT --out-dir OUTPUT` を実行し、終了コード・4CSV・入力ハッシュを読む。引数は配列で渡す。指定機能では `--session-id alpha --session-id gamma --session-id alpha` を追加し、全CSVのsession_id集合が `{alpha,gamma}` の部分集合、sessionsのID列が `alpha,gamma` の各1行、seqが順に1・2で各CSVの存在する行の対応が一致することを検査する。該当種類の入力記録がないCSVに行を要求せず、入力にある関連行の省略は認めない。
- [ ] 不明時刻の親・子を含む日時例で、CLI終了コード0と集計件数・空欄を確認する。全不明時刻の親ログにはタイムゾーンなし値・無効文字列・時刻キー欠落を各1件以上入れ、first_ts・last_ts・wall_minutesが空欄でhuman_turnsが入力の人間レコード数と一致することを検査する。
- [ ] 未知ID検査は同じ成果物のFEATURE-02が合格した後に評価し、合格しなければ前提未成立として未観測にする。終了コード0だけで成功対照成立とはしない。4出力へ異なる検査文字列を書き各SHA256を保存し、`--session-id alpha --session-id nonexistent` の終了コード2、stderr内のnonexistent、4ハッシュ不変を検査する。指定なしの出力は開始版の同一人工ログから得た4CSVとバイト比較する。
- [ ] BODY_SENTINELとASSISTANT_SENTINELで始まる全文がCSVへないこと、公開列が開始版と一致すること、入力ハッシュ不変を検査する。
- [ ] 採点側だけに置く正常例と、仕様03の誤実装例で各検査のpass/failを照合する。コードの構文エラーを仕様不合格の証拠にしない。検査が正常例を落とす、誤実装を通す場合は本比較前に修正する。

完了条件: 11個の検査IDそれぞれがどの検査コード・人工ログ・期待値へ対応するかを記録でき、題材ごとの必要検査が正常例を通す。原版ではFEATURE-02・03が不合格、FEATURE-04は成功対照を満たさず未観測になる。後退検査の個々がすべて原版で失敗することは要求せず、検査一式の識別力を確認する。

## Task 4: 起動操作を承認へ提示し、最初の対比較を実行する

**入力:** Task 1〜3の証拠・manifest・保護された検査、仕様02。
**出力:** 最初の2実行のrun.json・固定成果物・assessment.json。

- [ ] 通常ユーザーの認証、試験専用設定、書き込み境界、親子停止方法、モデル名と利用量の取得方法を、実際の実行ファイル・引数配列・許可パスとともに提示する。モデル起動を伴う事前確認と本比較の順序、300分上限、モデル別の時間・利用量の見込み（仕様02）、利用者に必要な操作を含める。
- [ ] 起動承認を得てから、無害な対象で仕様02のpreflight各項目を実測する。1項目でもfail/unknownなら本比較を開始せず、証拠と比較不能時の選択肢を提示する。未成立の前提を飛ばした起動コマンドは作らない。
- [ ] 全項目pass後に `codex-bug-discretion` と `codex-bug-guideline` を順に起動する。片方が使った解法や差分をもう片方へ渡さない。30分期限と残る240分枠の双方を外側で計数する。
- [ ] 作成側の親子が停止したことを確認して成果物を固定し、ハッシュを採点へ渡す。固定検査は生成コードの実行を含むため、採点側でも対象コードを保護された原本の書き込み権限で実行しない。Task 1で確認した境界内の別プロセスで実行する。
- [ ] 両結果について、入力同一性・意図した条件差・検査結果・利用量の回収が成立したか照合する。品質不合格は結果として保持し、比較不能と区別する。

## Task 5: 残りの比較・中断再開・結果整理

**入力:** 最初の対比較の成立記録。
**出力:** 残り6実行の結果と、`docs/records/experiments/2026-09-10-model-discretion-comparison.md`（本リポジトリには匿名化した要約と証拠パスを置く）。

- [ ] 最初の対比較が成立した場合だけ仕様02の残り6行へ進む。全実行を新しい開始版コピーから作る。時間・利用枠の不足時は止め、追加購入やリセットを行わない。
- [ ] 小機能第一段階の終了時に親子を停止し、保存物を固定する。第二段階では新規セッションへ共通依頼と保存物を渡し、復元した5項目を採点側で照合する。会話継続機能で前のコンテキストを渡さない。
- [ ] 判断を伴う継続情報・介入分類用の資料は、モデル名・条件名を含まない採点用IDに置き換え、対応表を管理側に残す。条件を推測できる残存情報は記録する。判定後にrun_idへ対応付けて結果を揃える。
- [ ] 全実行を仕様03で採点し、必要な介入・不要な再確認・訂正、親子利用量、未回収、稼働時間・人の待ち時間を分ける。提供元をまたぐトークン数を同じ金額として比較しない。追加物の用途と今後の更新要否を維持負担として記録し、共通準備・採点費用と方式別の実行・導入・修正費用を分ける。
- [ ] 各モデル内で2条件を比較し、品質・継続情報を満たした範囲と未達を示す。ロードマップ4.0節の進路を提案し、通常ガイドラインの変更・公開は自動実行しない。

## 計画自身の検証と確定状態

仕様の入力はTask 2、実行条件はTask 1・4・5、採点はTask 3・5へ対応する。8実行はTask 4の2とTask 5の6。4CSVは全タスクで同じ名前、検査IDは日時5・指定4・共通2の11。コード取得は8モジュールと既存テスト3本。個々のテスト件数は原版で実測して記録し、検査ID数と混同しない。

本計画は具体的な準備順を定めるが、起動経路の成立は未実測である。Task 1で成立しない場合にも停止できる計画として扱う。実行準備完了・モデル比較済みとは報告しない。

確定前レビュー: 仕様に対してclaude-opus-5の1体4観点フル実施を1回、差分再確認を新規1体で1回実施した。[初回対応](../../records/reviews/2026-09-10-model-discretion-spec-r1.md)、[差分再確認の対応](../../records/reviews/2026-09-10-model-discretion-spec-r2.md)、[機械検証と仕様確定](../../records/reviews/2026-09-10-model-discretion-spec-finalization.md)を参照。仕様確定点は実質的な収束として終了。本計画のコード例・対応タスクも仕様レビュー内で確認されているが、計画確定点の実施判断とは区別する。計画は未レビューの新規規範を追加しない写像であり通常型と判定し、追加の独立レビューを見送って確定する案を推奨する。ユーザーが追加レビューを選ぶ場合は1体4観点を候補とする（概算5〜10分、未実測）。上流要件の写像漏れを完全に保証する判断ではない。
