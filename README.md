# AI-Driven Development Guidelines

AI駆動開発ガイドライン — AIエージェントと協働して開発を進めるための、原則・行動指示・スキルの体系。

## 概要

このリポジトリは、AIエージェントとの協働開発において有用な普遍的原則（AI駆動開発ガイドライン）と、それを GitHub Copilot CLI / Claude Code / OpenAI Codex で実践するための仕組みを提供する。

対象とする「システム」には、通常のソフトウェア（Webアプリ、API、CLIなど）だけでなく、AIエージェントによる情報収集・分析・意思決定を含むワークフロー型システムも含む。

## 構造

3層のレイヤード方式で構成される:

| レイヤー | ファイル | 役割 |
|----------|----------|------|
| Layer 1 | [`docs/overview/principles.md`](docs/overview/principles.md) | ツール非依存の AI駆動開発ガイドライン原則集 |
| Layer 2 | [`AGENTS.md`](AGENTS.md) | エージェント向け行動指示（GitHub Copilot CLI / Claude Code / OpenAI Codex 共通）。[`CLAUDE.md`](CLAUDE.md) は `@AGENTS.md` インポートのポインタ |
| Layer 3 | [`skills/`](skills/) | ワークフローを実装するスキル群 |

ドキュメントの配置規範（情報の5分類体系）は [`docs/overview/folder-structure.md`](docs/overview/folder-structure.md) で定義される（ADR-0025）。

今後の整備案は[開発ガイドライン整備のロードマップ](docs/current/development-roadmap.md)を参照。公式ツールを使ったループ／AI組織の実証と、先行Issue対応の順序を整理している（提案・確認待ち）。

## 5つの原則

1. **意思決定の追跡可能性** — 「なぜそうしたか」を記録する
2. **関心の分離** — エージェントを「万能な1人」ではなく「責務を持った専門家」として設計する
3. **コンテキストの明示的管理** — エージェントが「何を知っているか」を明示的に制御する
4. **重要局面での人間の関与** — 重要な判断や不可逆操作の前に人間の確認を挟む
5. **漸進的な検証** — 作業を小さく区切り、各ステップで正しさを確認する

詳細は [`docs/overview/principles.md`](docs/overview/principles.md) を参照。

## スキル

| スキル | 説明 |
|--------|------|
| [`start-work`](skills/start-work/) | 新しい作業の起点。横断関心（handoff、ADR検出、不可逆操作レビュー）を一貫適用し、次手のスキルへナビゲートする |
| [`session-handoff`](skills/session-handoff/) | セッション間の作業引き継ぎファイル（ハンドオフ）を読む・作成する・更新する・確定する・サイクル完了時にリセットする（5 操作）。独立手順「移設」とサイズ実測トリガーで肥大化を制御する |
| [`feature-block-design`](skills/feature-block-design/) | brainstorming と writing-plans の間で、システムを機能ブロックに分割し分割仕様書を作成・更新する |
| [`decision-log`](skills/decision-log/) | 意思決定をADR（Architecture Decision Record）として記録・管理する |
| [`pre-action-review`](skills/pre-action-review/) | 不可逆操作前にリスク評価と確認を実施する |
| [`organize-inbox`](skills/organize-inbox/) | `docs/inbox/` の未分類情報を分類基準に照らして整理する（移動・分割・既存ドキュメントへの統合） |
| [`extend-guidelines`](skills/extend-guidelines/) | ガイドラインの拡張作業をガイドするゲートウェイ |
| [`retrospective`](skills/retrospective/) | サブプロジェクトクローズ時の課題抽出記録。AI が課題候補（事象/原因/影響）を一括提示し、ユーザーが起票判断。課題を「対象システム固有 / 開発フロー」に分類して system/flow の2フォルダに記録する（対策の採否・設計・ADR化は次サイクルでユーザー判断。知見の再利用は worklog パイプラインが担う。ADR-0056） |
| [`subagent-dispatch`](skills/subagent-dispatch/) | サブエージェント委譲の直前に、委譲プロンプトへ入れる制約ブロック（常時適用の 4 件＋条件発火の判定行）を組み立てる（ADR-0066/0070/0071/0073） |
| [`pre-finalization-review`](skills/pre-finalization-review/) | 計画・仕様など非コード成果物の、確定点での確定前レビュー提示（毎回）と 3領域と反例探索を覆う独立レビューの実施（実証つき・担当数と独立性を区別・発動はユーザー指示のみ）を担う。確定点・提示・反復の規則の正本は本スキル（ADR-0067 / ADR-0072 / ADR-0080 / ADR-0116 / ADR-0117） |
| [`worklog-record`](skills/worklog-record/) | 作業の節目とセッション切り替え直前に、AI のデフォルト挙動と実際に必要だったことの差分（delta）を中央ストアへ記録する（ADR-0044/0047/0058） |
| [`worklog-extract`](skills/worklog-extract/) | 中央ストアの作業ログをオンデマンドで走査し、スキル化・ルール化の候補をクラスタリングしてランク付き提示する（ADR-0044） |
| [`worklog-skillify`](skills/worklog-skillify/) | 採用された worklog 候補を writing-skills 委譲でスキル化する。スコープで配置先を振り分ける（ADR-0044/0046/0069） |

## Copilot CLI へのインストール

本リポジトリは **private リポジトリ**であり、利用想定はリポジトリ所有者および招待された知人に限定される。スキル群を Copilot CLI の `skill:` ツールから構造化呼び出しできるようにするには、Copilot CLI プラグインとしてインストールする（ADR-0015, ADR-0017）。

### A. GitHub 経由でインストール（別 PC やリポジトリ所有者の通常利用）

`copilot login` で GitHub 認証済みのアカウントが本 private リポジトリへのアクセス権を持っていれば、以下のコマンドでインストールできる:

```sh
copilot login   # 既に Copilot CLI を使えていれば済んでいる
copilot plugin marketplace add taika-izumi/ai-driven-dev-principles
copilot plugin install ai-driven-dev-principles@ai-driven-dev-principles
```

更新時:

```sh
copilot plugin update ai-driven-dev-principles
```

> **注意**: private リポジトリでの GitHub source 経由 install は CLI 側の認証フローに依存する。動作しない場合は方式 B（ローカル clone）にフォールバックすること。

### B. ローカルパスからインストール（開発時／GitHub source が使えないとき）

本リポジトリを clone 済みのマシンでは、ローカル絶対パスをマーケットプレイスとして登録できる（ADR-0017）:

```sh
copilot plugin marketplace add <このリポジトリの絶対パス>
copilot plugin install ai-driven-dev-principles@ai-driven-dev-principles
```

`skills/` を編集したら以下で反映する（install はファイルコピーのため、編集の即時反映はされない）:

```sh
copilot plugin update ai-driven-dev-principles
```

リポジトリのフォルダを別の場所へ移動した場合は、登録パスを更新する必要がある:

```sh
copilot plugin uninstall ai-driven-dev-principles
copilot plugin marketplace remove ai-driven-dev-principles
copilot plugin marketplace add <新しい絶対パス>
copilot plugin install ai-driven-dev-principles@ai-driven-dev-principles
```

> **注意**: 本リポジトリは過去に `scripts/dev-link.{ps1,sh}` で junction を張る方式を提供していたが、CLI に「local」マーケットプレイスは存在せずプラグインが認識されないことが判明したため、ADR-0017 で当該方式を廃止した。既存利用者は `~/.copilot/installed-plugins/local/ai-driven-dev-principles` の junction と `~/.copilot/settings.json` の `enabledPlugins."ai-driven-dev-principles@local"` エントリを手動で削除のうえ、上記の正規手順で再インストールすること。

## Claude Code へのインストール

Claude Code でも同じスキル群をプラグインとして利用できる。本リポジトリには Claude Code ネイティブのプラグイン定義（`.claude-plugin/plugin.json` と `.claude-plugin/marketplace.json`）が含まれており、追加変換なしでインストールできる。

### A. GitHub 経由でインストール

Claude Code 上で以下を実行する:

```sh
/plugin marketplace add taika-izumi/ai-driven-dev-principles
/plugin install ai-driven-dev-principles@ai-driven-dev-principles
```

### B. ローカルパスからインストール（開発時）

本リポジトリを clone 済みのマシンでは、ローカルパスをマーケットプレイスとして登録できる:

```sh
/plugin marketplace add <このリポジトリの絶対パス>
/plugin install ai-driven-dev-principles@ai-driven-dev-principles
```

`skills/` を編集した場合は `/plugin marketplace update ai-driven-dev-principles` で反映する。

## Codex へのインストール

OpenAI Codex（Codex CLI / ChatGPT デスクトップアプリ同梱ランタイム）でも同じスキル群をプラグインとして利用できる。本リポジトリには Codex ネイティブのマーケットプレイス定義（`.agents/plugins/marketplace.json`）とプラグインマニフェスト（`dist/.codex-plugin/plugin.json`）が含まれる。いずれも `scripts/build-dist.ps1` の生成物であり、手編集しないこと。

以下は Codex CLI 0.149.0-alpha.4.3（2026-08-25 確認）での手順である。インストールのサブコマンドは公式ドキュメントに記載のある `plugin install` ではなく `plugin add` である（実装がドキュメントに先行している）。

### A. GitHub 経由でインストール

```sh
codex plugin marketplace add taika-izumi/ai-driven-dev-principles
codex plugin add ai-driven-dev-principles@ai-driven-dev-principles
```

> **実測済み**: 本リポジトリの Codex ネイティブ構成を GitHub 経由で解決する経路は 2026-08-25 に実測した（`codex plugin marketplace add taika-izumi/ai-driven-dev-principles` → `codex plugin list` が `…\.agents\plugins\marketplace.json` を解決先として表示 → `codex plugin add` が `installed, enabled 0.1.12`）。ローカルパスからの登録（下記 B）も同日に実測済み。なお本リポジトリは private であり、private リポジトリでの GitHub source 経由 install は CLI 側の認証フローに依存する。動作しない場合は方式 B（ローカル clone）にフォールバックすること。

### B. ローカルパスからインストール（開発時）

本リポジトリを clone 済みのマシンでは、ローカルパスをマーケットプレイスとして登録できる:

```sh
codex plugin marketplace add <このリポジトリの絶対パス>
codex plugin add ai-driven-dev-principles@ai-driven-dev-principles
```

### 更新

GitHub 経由で登録している場合は、スナップショットを更新してから再インストールする:

```sh
codex plugin marketplace upgrade ai-driven-dev-principles
codex plugin add ai-driven-dev-principles@ai-driven-dev-principles
```

ローカルパス登録の場合は `marketplace upgrade`（Git 登録のスナップショット更新用）の対象外のため、`codex plugin add` の再実行だけで反映される。登録の確認は `codex plugin marketplace list`、インストール済みプラグインの削除は `codex plugin remove ai-driven-dev-principles`。

### superpowers の導入

本ガイドラインのスキルは superpowers のスキル（brainstorming / writing-plans など）へ委譲する。Codex でも次の手順で導入できる（superpowers 6.3.0 で確認）:

```sh
codex plugin marketplace add obra/superpowers-marketplace
codex plugin add superpowers@superpowers-marketplace
```

> **注意**: 本リポジトリは `.claude-plugin/marketplace.json`（Claude Code / Copilot CLI 用）と `.agents/plugins/marketplace.json`（Codex 用）を併置している。Codex は両者が同居する場合ネイティブ側を優先し legacy 側を無視するため、二重登録は起きない（2026-08-25 実測）。

> **Layer 2 について**: Layer 2 の**内容の正本**はリポジトリルートの `AGENTS.md` である（ADR-0111）。Codex と GitHub Copilot CLI は `AGENTS.md` を直接読み、Claude Code は `CLAUDE.md` に置いた `@AGENTS.md` インポート 1 行を経由して同じ内容を読む。内容を持つファイルは 1 つであり、`CLAUDE.md` はツール到達経路にすぎない。

### 選択肢が表示されない場合

CodexでAGENTS.mdに従った選択肢提示が行われない場合、モード指示との競合を確認する。CLI 0.153.4では `include_collaboration_mode_instructions=false` の効果を確認し、アプリでも設定後に選択肢が表示されたとの利用者報告がある。全利用者の必須設定ではなく、モード指示全体を除外する点に注意する。設定場所・一時指定・確認・元に戻す方法は[対処手順](docs/reference/codex-collaboration-mode-question-format.md)を参照。

## 新しいプロジェクトでの使い方

### 前提条件

新規プロジェクトで本ガイドラインを使うには、GitHub Copilot CLI / Claude Code / OpenAI Codex のいずれかにプラグイン `ai-driven-dev-principles` をインストールしておく必要がある（ADR-0016）。スキル群（`start-work`, `decision-log` 等）はプラグイン経由でのみツールに認識されるため、template をコピーしただけでは機能しない。

### 手順

1. **このリポジトリをプラグインとして 1 度インストール**（上記「Copilot CLI へのインストール」「Claude Code へのインストール」「Codex へのインストール」のうち、利用するツールの節を参照）
2. `template/` フォルダの中身を新プロジェクトのルートにコピーする
3. `AGENTS.md` にプロジェクト固有の指示を追記する（`CLAUDE.md` は `@AGENTS.md` の 1 行のままにする）

### 注意

- コピー先プロジェクトには `skills/` ディレクトリは含まれない（ADR-0016）。スキル定義の参照や改善提案は本リポジトリ（中央管理）で行うこと
- スキルのバージョンアップは、利用ツールのプラグイン更新コマンド（Claude Code は `/plugin marketplace update`、Copilot CLI は `copilot plugin update`、Codex は `codex plugin marketplace upgrade` ＋ `codex plugin add`）を実行すれば全プロジェクトに反映される

## 既存プロジェクトを AGENTS.md 構成へ移行する

以前の template をコピーしたプロジェクトは、Layer 2 の内容を `CLAUDE.md` に持っている。新しい template をそのまま再コピーすると `CLAUDE.md` が `@AGENTS.md` の 1 行で上書きされ、そこへ書き足していたプロジェクト固有の指示が消える。**必ず次の順序で移行すること。**

1. **現 `CLAUDE.md` の内容を `AGENTS.md` へ退避する**: 共通部（ガイドライン本体）は新しい `template/AGENTS.md` で置き換えてよいが、プロジェクト固有の追記は `AGENTS.md` 側へ移し替える
2. **`CLAUDE.md` をポインタ 1 行にする**: 内容を `@AGENTS.md` の 1 行だけにする（`template/CLAUDE.md` をコピーしてもよい）
3. **確認する**: 利用ツールを起動し、Layer 2 の指示が読み込まれていること（Claude Code なら `/context`、Codex なら `codex debug prompt-input`）を確かめる

手順 1 を飛ばして手順 2 から始めると固有指示が失われる。復旧は git 履歴からになる。

## 成長サイクル

1. 実践で「こういうルールがあればよかった」と発見する
2. `extend-guidelines` スキルを実行し、拡張作業を開始する
3. スキルのガイドに従い、原則・行動指示・スキルを追加する

詳細な拡張ルールと判定基準は [`CONTRIBUTING.md`](CONTRIBUTING.md) を参照。
