# AI Agent Meta-Guidelines

AIエージェントを活用したシステム開発のためのメタ・ガイドライン。

## 概要

このリポジトリは、AIエージェントとの協働開発において有用な普遍的原則（メタ・ガイドライン）と、それを GitHub Copilot CLI / Claude Code で実践するための仕組みを提供する。

対象とする「システム」には、通常のソフトウェア（Webアプリ、API、CLIなど）だけでなく、AIエージェントによる情報収集・分析・意思決定を含むワークフロー型システムも含む。

## 構造

3層のレイヤード方式で構成される:

| レイヤー | ファイル | 役割 |
|----------|----------|------|
| Layer 1 | [`docs/principles.md`](docs/principles.md) | ツール非依存のメタ・ガイドライン原則集 |
| Layer 2 | [`CLAUDE.md`](CLAUDE.md) | エージェント向け行動指示（GitHub Copilot CLI / Claude Code 共通） |
| Layer 3 | [`skills/`](skills/) | ワークフローを実装するスキル群 |

## 5つの原則

1. **意思決定の追跡可能性** — 「なぜそうしたか」を記録する
2. **関心の分離** — エージェントを「万能な1人」ではなく「責務を持った専門家」として設計する
3. **コンテキストの明示的管理** — エージェントが「何を知っているか」を明示的に制御する
4. **重要局面での人間の関与** — 重要な判断や不可逆操作の前に人間の確認を挟む
5. **漸進的な検証** — 作業を小さく区切り、各ステップで正しさを確認する

詳細は [`docs/principles.md`](docs/principles.md) を参照。

## スキル

| スキル | 説明 |
|--------|------|
| [`start-work`](skills/start-work/) | 新しい作業の起点。横断関心（handoff、ADR検出、不可逆操作レビュー）を一貫適用し、次手のスキルへナビゲートする |
| [`session-handoff`](skills/session-handoff/) | セッション間の作業引き継ぎファイル（ハンドオフ）を読む・作成する・更新する・確定する |
| [`feature-block-design`](skills/feature-block-design/) | brainstorming と writing-plans の間で、システムを機能ブロックに分割し分割仕様書を作成・更新する |
| [`decision-log`](skills/decision-log/) | 意思決定をADR（Architecture Decision Record）として記録・管理する |
| [`pre-action-review`](skills/pre-action-review/) | 不可逆操作前にリスク評価と確認を実施する |
| [`extend-guidelines`](skills/extend-guidelines/) | ガイドラインの拡張作業をガイドするゲートウェイ |
| [`retrospective`](skills/retrospective/) | サブプロジェクトクローズ時の振り返り。Done / Went Well / Struggled / Tech Notes / Issues を抽出し、課題を「対象システム固有 / 開発フロー」に分類して system/flow の2フォルダに記録する（対策の採否・設計・ADR化は次サイクルでユーザー判断） |

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

> **Layer 2 について**: GitHub Copilot CLI と Claude Code はいずれもリポジトリルートの `CLAUDE.md` を行動指示として読み込む。本リポジトリの Layer 2 はこの単一ファイルに統一されている（ADR-0023）。

## 新しいプロジェクトでの使い方

### 前提条件

新規プロジェクトで本ガイドラインを使うには、GitHub Copilot CLI / Claude Code プラグイン `ai-driven-dev-principles` をインストールしておく必要がある（ADR-0016）。スキル群（`start-work`, `decision-log` 等）はプラグイン経由でのみツールに認識されるため、template をコピーしただけでは機能しない。

### 手順

1. **このリポジトリをプラグインとして 1 度インストール**（上記「Copilot CLI へのインストール」または「Claude Code へのインストール」節を参照）
2. `template/` フォルダの中身を新プロジェクトのルートにコピーする
3. `CLAUDE.md` にプロジェクト固有の指示を追記する

### 注意

- コピー先プロジェクトには `skills/` ディレクトリは含まれない（ADR-0016）。スキル定義の参照や改善提案は本リポジトリ（中央管理）で行うこと
- スキルのバージョンアップは `/plugin update` でプラグインを更新すれば全プロジェクトに反映される

## 成長サイクル

1. 実践で「こういうルールがあればよかった」と発見する
2. `extend-guidelines` スキルを実行し、拡張作業を開始する
3. スキルのガイドに従い、原則・行動指示・スキルを追加する

詳細な拡張ルールと判定基準は [`CONTRIBUTING.md`](CONTRIBUTING.md) を参照。
