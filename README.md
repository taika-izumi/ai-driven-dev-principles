# AI Agent Meta-Guidelines

AIエージェントを活用したシステム開発のためのメタ・ガイドライン。

## 概要

このリポジトリは、AIエージェントとの協働開発において有用な普遍的原則（メタ・ガイドライン）と、それを GitHub Copilot で実践するための仕組みを提供する。

対象とする「システム」には、通常のソフトウェア（Webアプリ、API、CLIなど）だけでなく、AIエージェントによる情報収集・分析・意思決定を含むワークフロー型システムも含む。

## 構造

3層のレイヤード方式で構成される:

| レイヤー | ファイル | 役割 |
|----------|----------|------|
| Layer 1 | [`docs/principles.md`](docs/principles.md) | ツール非依存のメタ・ガイドライン原則集 |
| Layer 2 | [`.github/copilot-instructions.md`](.github/copilot-instructions.md) | Copilot向け行動指示 |
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
| [`retrospective`](skills/retrospective/) | サブプロジェクトクローズ時の振り返り。Done / Went Well / Struggled / Tech Notes / Improvement Drafts を抽出し、採用提案を ADR ドラフト化する |

## Copilot CLI へのインストール

本リポジトリのスキル群を Copilot CLI の `skill:` ツールから構造化呼び出しできるようにするには、Copilot CLI プラグインとしてインストールする。詳細は ADR-0015 を参照。

### A. 利用者向け（公式インストール）

`~/.copilot/settings.json` の `extraKnownMarketplaces` と `enabledPlugins` に以下を追記する:

```jsonc
{
  "extraKnownMarketplaces": {
    "ai-driven-dev-principles": {
      "source": {
        "source": "github",
        "repo": "taika-izumi/ai-driven-dev-principles"
      }
    }
  },
  "enabledPlugins": {
    "ai-driven-dev-principles@ai-driven-dev-principles": true
  }
}
```

その後 Copilot CLI を起動し、必要に応じて `/plugin` でインストールを完了させる。`/env` でスキルが認識されているか確認できる。

### B. 本リポジトリの開発者向け（dev-link）

開発中の `skills/` 編集を即時反映したい場合、再インストール不要の junction/symlink 方式を使う:

- Windows (PowerShell):
  ```powershell
  pwsh -File scripts/dev-link.ps1
  ```
- macOS / Linux:
  ```bash
  bash scripts/dev-link.sh
  ```

スクリプト実行後、`~/.copilot/settings.json` の `enabledPlugins` にスクリプトが表示する行を手動で追加し、Copilot CLI を再起動する。

## 新しいプロジェクトでの使い方

### 前提条件

新規プロジェクトで本ガイドラインを使うには、Copilot CLI プラグイン `ai-driven-dev-principles` をインストールしておく必要がある（ADR-0016）。スキル群（`start-work`, `decision-log` 等）はプラグイン経由でのみ Copilot CLI に認識されるため、template をコピーしただけでは機能しない。

### 手順

1. **このリポジトリをプラグインとして 1 度インストール**（上記「Copilot CLI へのインストール」節を参照）
2. `template/` フォルダの中身を新プロジェクトのルートにコピーする
3. `copilot-instructions.md` にプロジェクト固有の指示を追記する

### 注意

- コピー先プロジェクトには `skills/` ディレクトリは含まれない（ADR-0016）。スキル定義の参照や改善提案は本リポジトリ（中央管理）で行うこと
- スキルのバージョンアップは `/plugin update` でプラグインを更新すれば全プロジェクトに反映される

## 成長サイクル

1. 実践で「こういうルールがあればよかった」と発見する
2. `extend-guidelines` スキルを実行し、拡張作業を開始する
3. スキルのガイドに従い、原則・行動指示・スキルを追加する

詳細な拡張ルールと判定基準は [`CONTRIBUTING.md`](CONTRIBUTING.md) を参照。
