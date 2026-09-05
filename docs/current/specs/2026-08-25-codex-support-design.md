# 設計仕様: Codex 対応（AGENTS.md 正本化と Codex 向けプラグイン配信）

- **日付**: 2026-08-25
- **関連 ADR**: ADR-0110（スコープ）、ADR-0111（Layer 2）、ADR-0112（Layer 3）
- **対象ブランチ**: feature/codex-support

## 目的

本リポジトリのガイドライン／スキルは GitHub Copilot CLI / Claude Code 向けに整備されてきた。これを OpenAI Codex（Codex CLI / ChatGPT デスクトップアプリ同梱ランタイム）でも利用可能にし、3 ツールで同一のガイドラインが機能する状態にする。

## 背景と調査結果

公式ドキュメント（developers.openai.com/codex 配下、code.claude.com/docs/en/memory、docs.github.com。2026-08-25 確認）と実機実測で確認した事実:

| 項目 | Codex | Claude Code | Copilot CLI |
|---|---|---|---|
| `AGENTS.md`（ルート） | 読む | 読まない（`@path` インポートで到達可） | 読む |
| `CLAUDE.md`（ルート） | 読まない | 読む | 読む |
| 複数指示ファイルの扱い | — | — | すべて結合（同一内容は重複除去） |

- Claude Code の `CLAUDE.md` は `@AGENTS.md` インポート（起動時展開・相対パスは記述ファイル基準・再帰 4 段）を公式サポートし、AGENTS.md 併用リポジトリでの利用が公式推奨されている（code.claude.com/docs/en/memory の「AGENTS.md」節）。Windows ではシンボリックリンクに管理者権限が要るためインポートが推奨される
- なお ADR-0023 は「両方残すと Copilot CLI が二重読み込みする」を前提としていたが、現行の Copilot CLI 公式ドキュメントは「同一内容の重複は除去する」と明記しており、旧前提とは異なる（当時の仕様か記述の誤りかは判別不能。ADR-0111 Context 参照）
- Codex のスキル機構: `SKILL.md`（frontmatter `name`/`description` 必須）。スキル一覧の予算（コンテキスト窓の 2%、不明時 8,000 文字）は**ツールに載る全スキルの初期一覧（name + description）**に適用され、個々の本文サイズには及ばない
- Codex のマーケットプレイス探索先: ネイティブ `$REPO_ROOT/.agents/plugins/marketplace.json` / 個人 `~/.agents/plugins/marketplace.json` / legacy 互換 `$REPO_ROOT/.claude-plugin/marketplace.json`。プラグイン側マニフェストは `.codex-plugin/plugin.json`（必須: name / version / description / skills）

### 実機実測（2026-08-25・Codex CLI 0.149.0-alpha.4.3・Claude Code・本開発機）

1. **superpowers の Codex 導入**: legacy 構成（`.claude-plugin/marketplace.json` のみ）の marketplace を GitHub shorthand で登録し、`codex plugin add superpowers@superpowers-marketplace` で `installed, enabled 6.3.0`。インストールコマンドは公式ドキュメントの `plugin install` ではなく **`plugin add`**（実装がドキュメントに先行）。superpowers 6.3.0 は `.codex-plugin/plugin.json`（`"skills": "./skills/"` ＋ `interface` ブロック）を同梱
2. **`@AGENTS.md` インポート展開**: scratch ディレクトリ（AGENTS.md にマーカー文字列・CLAUDE.md は `@AGENTS.md` の 1 行）で `claude -p` を実行し、マーカーがモデルへ到達することを確認。ADR-0110 Consequences は設計確定前に**ユーザーの**実機確認を要すると記した。本実測は AI が本開発機で実施し結果をユーザーへ提示したもので、この実施方式はユーザーが確定前レビューの回答（実測 A・B の実施承認）で承認済みである（実施主体の変更を明示したうえで充足とみなす）
3. **Codex の AGENTS.md 注入**: 同 scratch ディレクトリで `codex debug prompt-input`（モデル呼び出し不要）を実行し、AGENTS.md 全文が `<INSTRUCTIONS>` としてプロンプト入力に注入されること、CLAUDE.md（ポインタ）は注入されないことを確認。あわせて superpowers 14 スキルがセッションのスキル一覧に列挙されることを確認
4. **native 形式・本リポジトリ同レイアウトの全通**: 一時ディレクトリにルート `.agents/plugins/marketplace.json`（`source: {"source":"local","path":"./dist"}`）＋ `dist/.codex-plugin/plugin.json` ＋ `dist/skills/` を作り、`codex plugin marketplace add <パス>` → 列挙 → `codex plugin add` → `installed, enabled` まで確認。**`source.path` はマーケットプレイスルート（= リポジトリルート）基準で解決される**
5. **native/legacy 同居**: 同一 marketplace に両 manifest を置いた場合、**native が優先され legacy は無視される（二重登録は起きない）**。ADR-0112 の懸念は解消
6. **ネイティブ marketplace.json のスキーマ実例**: `name` / `interface.displayName` / `plugins[]`（`name`・`source.{source,path}`・`policy.{installation,authentication}`・`category`）。実例 2 件のうち 1 件（openai-primary-runtime）はトップレベル `interface` を持たない（`interface` は必須ではない模様）

## スコープ

### 1. Layer 2 — AGENTS.md 正本化（ADR-0111）

- 現行ルート `CLAUDE.md` の内容を新規ルート `AGENTS.md` へ移す。`CLAUDE.md` は `@AGENTS.md` の 1 行に置き換える。**切替は 1 コミットで行い、コミットの前に作業ツリー上で再実測する**（`codex debug prompt-input` による AGENTS.md 注入確認と `claude -p` によるインポート展開確認。再実測に必要なのはディスク上のファイルでありコミットではないため、中間状態のコミットは作らない。これにより Copilot CLI が非同一内容の 2 ファイルを読む区間も生じない）
- `template.manifest` に `AGENTS.md` を追加（`CLAUDE.md` はポインタとして同期対象のまま）。AGENTS.md は配布対象ソースとなり、記法規約（CONTRIBUTING「配布対象ソースの記法規約」）の適用対象に加わる（移設元 CLAUDE.md は出所識別子 0 件・自己参照 0 件を確認済みで、新規違反は生じない）
- 配布先プロジェクトの固有指示は AGENTS.md 側へ追記する運用に変更する
- **既存プロジェクトの移行手順を README の独立節として追加する**: template 再コピーで固有指示ごと `@AGENTS.md` の 1 行に上書き消失する経路があるため、「(1) 現 CLAUDE.md の固有指示を AGENTS.md へ退避 → (2) CLAUDE.md をポインタ化（または template コピー）」の順序付き手順で書く
- `scripts/check-claude-md-size.ps1` の計測対象を AGENTS.md へ切り替える（ポインタ化した CLAUDE.md を測り続けると ADR-0040 の規範肥大監視が永久に無音化するため。ハードコード 5 箇所＋CONTRIBUTING・sync-template・生成器 spec の外部参照を追随）
- Layer 2 への**書き込み先**を指す参照（`skills/worklog-skillify` のスコープ 3 分岐表の 1 箇所）も、読み側と同じ二段フォールバックとする（`AGENTS.md` が無いプロジェクトでは `CLAUDE.md` へ追記する）。未移行の配布先で新規 `AGENTS.md` へ書くと、`CLAUDE.md` にインポート行が無いため Claude Code が読まず、規範が無言で不発になるため（ADR-0114）
- スキル本文等の「プロジェクトの CLAUDE.md に調整値があればそれを優先」型の参照（8 箇所）は、プラグイン（全配布先へ即時反映）と template（手動同期）の反映時期のずれで新旧どちらのプロジェクトも壊れうるため、**「プロジェクトの AGENTS.md（当該調整値の記載が無ければ CLAUDE.md）」の二段フォールバック表現**へ書き換える（ファイルの有無ではなく**調整値の記載の有無**で探索する。AGENTS.md が存在しても調整値を持たない移行途中のプロジェクトで CLAUDE.md 側の調整値を読み飛ばさないため）
- ADR-0023 への部分修正注記: 対象は Decision 1（「Layer 2 ファイルは 1 つに統一」→「内容の正本は 1 つに統一」）と **Decision 7（「AGENTS.md は Claude Code がネイティブに読まないため採用しない」→ `@path` インポートの公式サポート確認により不採用理由が失効）**の 2 項目。あわせて ADR-0023 Considered Alternatives 案 2（AGENTS.md 単一ソース＋`@AGENTS.md` インポート＝今回採用する構成）の否定評価が前提失効により覆った旨を同じ注記内で言及する。書式は decision-log の `references/status-updates.md`「ステータス変更」の部分修正の型（`- **部分修正（ADR-XXXX）**:`）に従い Consequences へ追記、Accepted 維持

### 2. Layer 3 — Codex 向けマニフェストの生成器導出（ADR-0112）

- `build-dist.ps1` の出力先を一般化する。ただし**ディレクトリ走査を伴う工程（wipe・stale 検出・残存する参照番号の自己検査）は従来どおり `dist/` に限定**し、ルート直下の生成物（`.agents/plugins/marketplace.json`）は**既知パスのホワイトリストに対するファイル単位の生成・存在・内容比較**とする。`-Check` の一致条件のうち「余分なファイルの不在」はルート側に適用しない（リポジトリルートを出力先ルートとして走査すると全リポジトリファイルが stale 判定され、wipe に含めると不可逆事故になるため。現行実装がルート生成物を扱えず `-Check` が恒久失敗する構造の解消がこの改修の目的）
- 正本 `.claude-plugin/marketplace.json`・`.claude-plugin/plugin.json` から次の 2 生成物を導出する:
  - `.agents/plugins/marketplace.json`（ルート）: 実測済みレイアウト（`source: {"source":"local","path":"./dist"}`・パス解決はリポジトリルート基準）。`interface.displayName`・`policy.installation`・`policy.authentication`・`category` は生成器内の固定マッピングで付与
  - `dist/.codex-plugin/plugin.json`: `name` / `version` / `description` / `author` は正本 plugin.json から複写、**`skills` は `"./skills/"` 固定、`interface` は `displayName`・`category` の 2 キーのみを生成器内の固定マッピングで付与**し、それ以外の interface キー（`composerIcon` / `logo` / `screenshots` / `shortDescription` ほか）は生成しない（資産参照キーは dist に実体が無く、その他は必須である根拠が無いため最小構成とする）
- 通常実行・`-Check` の**両モードの冒頭（規約判定より前）**で、正本 `.claude-plugin/plugin.json` の `version` と `.claude-plugin/marketplace.json` の `plugins[].version`（全件）の一致を検査し、不一致なら非ゼロ終了する（従来から二重保持で無検査だった乖離点を生成器導入と同時に塞ぐ。`-Check` モードでも走らせないと執行点手順 2 のゲートにならない）
- あわせて正本 `.claude-plugin/marketplace.json` の `plugins[].source` が文字列であること・`plugins` が 1 件以上あること・`plugins[].name` が空でないことを生成時に検査し、いずれも満たさなければ非ゼロ終了する（オブジェクト形式の `source` は暗黙の文字列変換で壊れた `path` を持つ構文的に妥当な JSON を生み、`-Check` も自己一致で通ってしまうため）
- 正本 JSON の読み込みは診断つきのヘルパへ寄せ、不正な JSON では `[build-dist]` 接頭辞つきの 1 行診断を出して非ゼロ終了する（`.NET` の例外スタックを生で出さない。既存の M-6 と同じ方針。ADR-0113）
- 生成物へ複写する必須の文字列値（`.claude-plugin/marketplace.json` の `name`、`.claude-plugin/plugin.json` の `name` / `version` / `description` / `author.name`）は、欠損・非文字列・空白のみのいずれでも非ゼロ終了する。`[string]` パラメータがオブジェクトを `@{...}`・`$null` を空文字へ黙って変換するため、素通りさせると構文的に妥当な JSON へ壊れた値が埋まり `-Check` が自己一致で恒久的に通ってしまう（ADR-0113 の追加決定）
- 生成物はいずれも git 管理し、`-Check` の検査対象に加える。手編集しない（正本は `.claude-plugin/` の 2 ファイルのみ）
- **プラグイン version を patch bump する（0.1.11 → 0.1.12）**: 本サイクルは dist の内容を改定するため ADR-0090 の bump 必須条件に該当する
- 生成器の正本仕様のスナップショット同期: `docs/current/specs/2026-08-07-distributed-artifact-generation/02-distribution-generator.md`（`-Check` 4 条件・dist 構成表・出力例・責務・走査対象の実数 26→27 / 5→6）と `03-template-sync-integration.md`（template.manifest「変更しない」注記の撤回・同期対象 5→6 ファイル・全 8→9 ファイル・影響表の CLAUDE.md 行・check-claude-md-size 呼び出し）を書き換えで更新する。あわせて同ディレクトリの `00-overview.md`（スコープ外リストの `template/CLAUDE.md` 参照）・`01-provenance-notation-convention.md`（配布対象ソース件数 5→6・シナリオの接続の一覧）・`04-plugin-distribution-layout.md`（配布構造図・プラグイン宣言元・スキル本数）、および skills の正本テキストを逐語ないし準逐語で写している `docs/current/specs/2026-08-13-handoff-bloat-control/01-relocation-standard.md`・`02-volume-norms.md` と `docs/current/specs/2026-07-17-worklog-skill-pipeline/00-overview.md`・`04-skill3-skillify.md` も、同じ基準（本サイクルの変更が直接無効化する記述であること）で同期する

### 3. superpowers 依存 — 実測により解消

- superpowers は Codex に導入可能で、セッションのスキル一覧にも列挙される（実測 1・3）。`start-work` の delegate 前提は 3 ツール共通で成立し、不在時は既存の Phase -1 インラインフォールバックが担う（変更なし）
- README の Codex 節に superpowers のインストール手順（`codex plugin marketplace add obra/superpowers-marketplace` → `codex plugin add superpowers@superpowers-marketplace`）を記載

### 対象外（変更しない）

- Layer 1（`docs/overview/principles.md`）: ツール非依存のため変更なし（ツール名言及 0 件を確認済み）
- 過去の ADR・spec・plan・retrospective・handoff 等の歴史的記録
- superpowers 本体・Codex 本体・Claude Code 本体への変更
- Codex 固有の新規スキル・新規規範の追加（既存体系の到達経路拡張のみ。規範・工程・観点の新設なし）
- スキル本文中のモデル ID 証跡（`claude-opus-5` 等の観測世代記録）と `.claude-plugin/plugin.json` を判定マーカーとして参照する箇所（worklog-skillify）: 実測記録・実在パスの参照であり中立化の対象にしない

## 影響を受けるファイル一覧

| ファイル | 操作 |
|---|---|
| `AGENTS.md`（新規・ルート） | 作成（旧 CLAUDE.md 内容＋前提条件節の 3 ツール化＋構造化質問ツール例示の中立化。ポインタ化と同一コミット・コミット前に作業ツリーで再実測） |
| `CLAUDE.md` | `@AGENTS.md` の 1 行へ置換（AGENTS.md 作成と同一コミット） |
| `README.md` | 「Codex へのインストール」節の新設（`add` 系コマンド・確認日とバージョン明記・更新手順を含む）、既存プロジェクト移行手順の独立節、概要（7 行目）・Layer 2 表（18 行目）・Layer 2 注記ブロック（123 行目）・「新しいプロジェクトでの使い方」の 3 ツール化 |
| `CONTRIBUTING.md` | 設計思想の Layer 2 行 / 執行点手順 1 の発火条件へ `.claude-plugin/` 2 ファイルを追加・手順 2 の「自分の出力先しか見ない」記述と手順 3 の生成物リストを新出力先へ追随 / シナリオ見出し 2 本（「CLAUDE.md を更新するとき」「CLAUDE.md を棚卸しするとき」）と本文の AGENTS.md 化 / sync-template 実行条件の列挙 3 箇所（start-work・feature-block-design・retrospective の各シナリオ内）へ AGENTS.md 追加 / Skill 化判定表（304 行目）・Skill シナリオのチェックリスト（322 行目）・「過剰適合の点検」適用対象定義（36 行目）・是正パターンのゲート規範（54 行目）の CLAUDE.md 言及の追随 |
| `template.manifest` | `AGENTS.md` エントリ追加＋コメントの 3 ツール化 |
| `.claude-plugin/plugin.json` | description を AGENTS.md ベースへ更新・version 0.1.12 |
| `.claude-plugin/marketplace.json` | version 0.1.12 |
| `scripts/build-dist.ps1` | 出力先一般化＋2 生成物の導出＋version 一致検査 |
| `scripts/check-claude-md-size.ps1` | 計測対象を AGENTS.md へ切替（ハードコード 5 箇所） |
| `scripts/sync-template.ps1` | check-claude-md-size 呼び出し部（235 行目付近）のコメント・文言の追随 |
| `docs/current/specs/2026-08-07-distributed-artifact-generation/00-overview.md` / `01-provenance-notation-convention.md` / `02-distribution-generator.md` / `03-template-sync-integration.md` / `04-plugin-distribution-layout.md`、`docs/current/specs/2026-08-13-handoff-bloat-control/01-relocation-standard.md` / `02-volume-norms.md`、`docs/current/specs/2026-07-17-worklog-skill-pipeline/00-overview.md` / `04-skill3-skillify.md` | スナップショット書き換え更新 |
| `docs/overview/issue-management.md`（44 行目） | 調整値参照の二段フォールバック化 |
| `docs/overview/folder-structure.md`（80 行目） | 参照元名の AGENTS.md 化（参照元の宣言であり調整値探索ではないため二段フォールバックにしない） |
| `skills/` 配下 | CLAUDE.md 参照 18 箇所/9 ファイルの二段フォールバック化ないし AGENTS.md 化（うち `worklog-skillify` のスコープ 3 分岐表は skills 配下で唯一の Layer 2 **書き込み**点であり、単純改名ではなく書き込み側の二段フォールバックとする。ADR-0114）、`.claude/skills/` パス参照 3 箇所（worklog-extract / worklog-skillify）のツール中立化（置換後は各ツールのスキル配置先の併記〈Claude Code `.claude/skills/`・Codex `.agents/skills/` 等〉とする）。モデル ID・判定マーカーは変更しない |
| `docs/records/decisions/0023-*.md` | 部分修正注記の追記（Decision 1・7。固定書式） |
| `template/` / `dist/` / `.agents/plugins/marketplace.json` | 生成器実行で反映（手編集しない） |

## 検証

1. **Codex Layer 2**: 実装リポジトリで `codex debug prompt-input` を実行し、AGENTS.md の内容が `<INSTRUCTIONS>` として注入されることを確認する（scratch では実測済み。実体で再確認）
2. **Codex Layer 3**: 本リポジトリをローカル marketplace 登録 → `codex plugin add ai-driven-dev-principles@ai-driven-dev-principles` → `installed, enabled` と 13 スキルの配置を確認し、`codex debug prompt-input` のスキル一覧に本プラグインのスキルが列挙されることを確認する
3. **native 優先の確認**: `codex plugin list` が表示する manifest パスが `.agents/plugins/marketplace.json` であることを確認する（scratch では native 優先・二重登録なしを実測済み）
4. **description 予算**: `codex debug prompt-input` のスキル一覧が警告なく全件列挙されること（superpowers 併用状態の全体で確認。自プラグイン単独では dist 側 13 スキルの frontmatter `description` 値のみ（囲み引用符を除く）の合計が 2,069 文字〈UTF-8 で 5,071 バイト。2026-08-25 実測。name を加えても約 2,272 文字〉で、予算 8,000 文字に対し余裕がある。超過警告が出た場合は description の短縮を課題起票する）
5. **生成器・執行点**: `build-dist.ps1` と `sync-template.ps1` を実行し、両者を `-Check` で通し、生成物（`dist/` / `template/` / `.agents/plugins/marketplace.json`）を同一コミットに含める。version 一致検査の動作（不一致時の非ゼロ終了）も確認する。配布物の目視 5 項目（CONTRIBUTING「機械判定が届かない領域」）を実施する
6. **既存 2 ツールの Layer 3 退行確認**: Claude Code 側で `/plugin marketplace update ai-driven-dev-principles` 後に、Copilot CLI 側で `copilot plugin update ai-driven-dev-principles` 後に、それぞれ 13 スキルが認識されること（ユーザー確認。`.agents/` 追加・`dist/.codex-plugin/` 追加による退行がないこと。Copilot CLI が利用不能な場合の扱いは検証 7 と同じ）。**実行タイミング**: 本開発機のマーケットプレイス登録は GitHub 経由（`source: github` / `repo: taika-izumi/ai-driven-dev-principles`。2026-08-25 実測）であり、`marketplace update` は `origin/master` を fetch する。したがって本検証は **master へマージして push した後**でないと新版が降りてこず実行できない。マージ前に退行を潰せない構造は Issue-0109 で扱う
7. **既存 2 ツールの Layer 2 退行確認**: Claude Code 側は `CLAUDE.md`（`@AGENTS.md`）経由で Layer 2 が読まれること（scratch で実測済み。実装後は次セッションの `/context` で最終確認）。**Layer 2 は作業ツリーから直接読まれるためプラグイン配信を経由せず、push もマージも不要で、feature ブランチをチェックアウトしたまま新セッションを起動すれば実行できる**（検証 6 と実行可能時期が異なる）。Copilot CLI 側は AGENTS.md ＋ ポインタ CLAUDE.md の同居で指示が読み込まれること（いずれもユーザー確認。Copilot CLI が利用不能な場合は「未確認」と handoff に明記し完了条件外とする）
8. **サイズ監視の生存確認**: `check-claude-md-size.ps1` の計測対象切替後、実測値（現 7,915 バイト / 25 箇条相当）が閾値内で報告されることを確認する
9. **網羅性チェック**: 生きたファイル（README・CONTRIBUTING・AGENTS.md・skills・scripts・docs/overview・plugin.json・template.manifest）に、`CLAUDE\.md` および `\.claude/skills` の残留参照（ポインタ・移行手順・二段フォールバック・配置先併記等の意図的言及を除く）と「2 ツールのみ前提」の記述が残っていないことを grep で確認する
10. **GitHub 経由の native 登録確認**: リリース後に `codex plugin marketplace add taika-izumi/ai-driven-dev-principles`（GitHub 経由）で native manifest が解決されること（ユーザー確認事項として handoff へ引き継ぐ。ローカル登録では実測済みだが GitHub 取得経路は未実測のため）

## 完了条件

- ルート `AGENTS.md` が Layer 2 の内容正本として存在し、`CLAUDE.md` が `@AGENTS.md` の 1 行である
- `.agents/plugins/marketplace.json` と `dist/.codex-plugin/plugin.json` が生成器から導出され、両 `-Check` が通る
- `.claude-plugin/` 2 ファイルの version が 0.1.12 で一致し、生成物へ波及している
- `check-claude-md-size.ps1` の計測対象が AGENTS.md である
- README に Codex インストール節（本ガイドライン＋superpowers・更新手順込み）と既存プロジェクト移行手順の節がある
- 検証 1〜5・8・9 が通る（6・7・10 はユーザー確認事項として handoff に引き継ぐ）
- ADR-0111・0112 が Accepted に昇格し、ADR-0023 に部分修正注記（Decision 1・7）が付いている
- 生成器 spec（02/03）のスナップショットが実装後の挙動と一致している

## 過剰適合点検（ADR-0079）

| 観点 | 判定 | 根拠 |
|------|------|------|
| 出所の偏り | 問題なし | 根拠は外部ツール公式仕様（OpenAI / Anthropic / GitHub。2026-08-25 確認）＋実機実測 6 件・1 環境（Windows 11・Codex CLI 0.149.0-alpha.4.3・Claude Code）。単一環境実測に依存する記載（コマンド名 `plugin add`・native 優先挙動）には確認日・バージョンを明記して依存を局所化する。プロジェクト横断の教訓の規範昇格ではない |
| システム種別依存性 | 問題なし | 開発対象システムの種別・技術スタックに依存しない（ツール到達経路の拡張のみ）。引き写し箇所: (1) CONTRIBUTING 執行点 4 手順の対象リスト拡張 — 引用元のゲート（配布対象ソース変更時のみ発火）を変えずに対象を追加する。(2) 「プロジェクトの CLAUDE.md に調整値」8 箇所の二段フォールバック化 — 各引用元の「プロジェクトの調整値優先」ゲートを変えずに参照先のみ拡張する |
| AIモデル/ツール依存性 | 問題なし | 対象 3 ツールの列挙に閉じ、将来モデル・将来ツールの性能発揮を制限する拘束は加えない。Codex 実測値（コマンド名・native 優先）は README・spec に確認日・バージョンを添えて記載する。引き写し箇所: 上記 2 件以外なし |
| 規範の廃止条件 | 定義済み | Codex が AGENTS.md 読み込みまたは `.codex-plugin` / `.agents/plugins` 探索を廃止・変更したことをユーザーまたはエージェントが観測した時点で、該当生成物・記述の撤去を提案しユーザーが判断する |

**新設の評価可能性（ADR-0102）**: 本拡張は規範・工程・観点の新設を含まない（生成器の生成対象追加・version 一致検査の追加は既存工程「執行点 4 手順」の内部拡張であり、新工程ではない。AGENTS.md はファイル追加であって規範の新設ではない）。よって ADR への記載要件は対象外と判定する。

**再点検（2026-08-25・実装中の差分について。ADR-0114）**: Task 4 のコード品質レビューを受けて、二段フォールバック句の探索対象を「当該調整値の記載」と明示し、Layer 2 の書き込み点 1 箇所（`skills/worklog-skillify/SKILL.md` のスコープ 3 分岐表）にも同じ二段フォールバックを適用し、ローカルスキル配置先の列挙を `など` で開いた。4 観点の判定は上表から変わらない——(a) 出所の偏り: 根拠は同一サイクルの独立レビューと ADR-0016 の既存記録で、プロジェクト横断の教訓の規範昇格ではない。(b) システム種別依存性: 引き写し箇所は上表 (2) の二段フォールバック化と同一で、適用先が読み側 7 箇所＋書き込み側 1 箇所へ増えるのみ。引用元のゲート（プロジェクトの調整値優先）は変えていない。(c) AI モデル / ツール依存性: **列挙を閉じない方向の是正であり、依存はむしろ減る**。特定ツールの非対応を断定しない判断（ADR-0114 の Considered Alternatives 3 を不採用）により、Copilot CLI の現行仕様への依存を持ち込んでいない。(d) 規範の廃止条件: 上表と同じ。**新設の評価可能性の判定も変わらない**——表現の明確化と既存パターンの適用先追加であり、新しい拘束的文を足していない。

