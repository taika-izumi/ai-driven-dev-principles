# ADR-0017: ローカル開発時のプラグイン登録方式を `copilot plugin marketplace add <path>` に修正

- **Status**: Accepted
- **Date**: 2026-05-04

## Context

ADR-0015 で「公式プラグイン化 + dev-link スクリプト併用」を採用し、`scripts/dev-link.ps1` および `dev-link.sh` で `~/.copilot/installed-plugins/local/ai-driven-dev-principles` から本リポジトリへ junction を張る方式を実装した。利用者は `~/.copilot/settings.json` の `enabledPlugins` に `"ai-driven-dev-principles@local": true` を追記する手順だった。

しかし feature/plugin-distribution ブランチでの動作検証で、Copilot CLI が以下の警告を出力していることが判明した（`~/.copilot/logs/process-*.log`）:

```
[WARNING] Failed to auto-install plugin "ai-driven-dev-principles@local": Marketplace "local" not found
```

調査の結果、Copilot CLI には `local` という暗黙のマーケットプレイスは存在せず、`enabledPlugins` の `<plugin>@<marketplace>` 形式における `<marketplace>` 部分は `extraKnownMarketplaces` または `copilot plugin marketplace add` で明示的に登録されたマーケットプレイス名でなければ解決されない。junction を作成しても、対応するマーケットプレイス登録が無ければプラグインは未認識のまま残る。

加えて `copilot plugin --help` を確認したところ、CLI には以下の機能が存在することが分かった:

- `copilot plugin marketplace add <source>`: GitHub リポジトリ・URL・**ローカルパス** をマーケットプレイスとして登録
- ローカルパスを渡した場合、`source: { source: "directory", path: "..." }` として `extraKnownMarketplaces` に自動追記され、マーケットプレイス名は `marketplace.json` の `plugins[].name`（本リポでは `ai-driven-dev-principles`）が使われる
- 登録後 `copilot plugin install <plugin>@<marketplace>` で `installed-plugins/<marketplace>/<plugin>/` に**ファイルがコピー**される（junction ではない）

したがって ADR-0015 の方式は二点で誤っていた:

1. `local` マーケットプレイスを暗黙の存在として扱った
2. 「junction で本リポジトリの skills/ 編集を即時反映」を主目的にしたが、公式の `plugin install` 経路はファイルコピーであり、両者は同じディレクトリ実体を見ない

## Considered Alternatives

| # | 案 | 評価 |
|---|---|---|
| 1 | 現状維持（dev-link.ps1 + 手動 settings.json 編集） | CLI が認識せず、目的を達成しない（実証済） |
| 2 | `copilot plugin marketplace add <local-path>` をローカル開発の正規手順とし、`plugin install` でコピー受容 | 公式手順、確実に認識される。編集即時反映は失われ、変更時は `copilot plugin update` が必要 |
| 3 | 案2 + インストール後にコピーを削除して junction で置換するハイブリッド | 即時反映を維持しつつ公式登録も得られる。ただし `plugin update` で junction が壊れる可能性、サポート外操作 |
| 4 | `--plugin-dir <directory>` フラグで起動時に指定 | CLI 起動コマンド側の制御が必要、VS Code 経由起動では設定箇所が不明、汎用性に欠ける |

## Decision

**案2 を採用し、ローカル開発も `copilot plugin marketplace add <local-path>` 経由で行う。dev-link スクリプト（`scripts/dev-link.ps1`, `scripts/dev-link.sh`）は廃止する。**

具体的な変更:

1. **dev-link スクリプトの削除**: `scripts/dev-link.ps1`, `scripts/dev-link.sh` を削除
2. **README の修正**:
   - 「B. 本リポジトリの開発者向け（dev-link）」節を、「B. ローカルパスからのインストール（開発・未公開時）」へ改訂
   - 手順を `copilot plugin marketplace add <repo-root>` → `copilot plugin install ai-driven-dev-principles@ai-driven-dev-principles` に置き換え
   - 編集後の反映方法として `copilot plugin update ai-driven-dev-principles` を案内
3. **ADR-0015 の Status を Superseded by ADR-0017 に変更**（dev-link 方式の部分のみ）。プラグイン化の方針自体は維持されるため Superseded ではなく Amended 相当だが、本リポジトリの ADR ステータス語彙に Amended が無いため、`Accepted (amended by ADR-0017)` とする
4. **既存環境の後始末**: `~/.copilot/installed-plugins/local/` 配下の junction は手動で削除案内（README）。`enabledPlugins` の `ai-driven-dev-principles@local` エントリも削除案内
5. **ハンドオフ更新**: feature/plugin-distribution ブランチの未着手タスクのうち「設定切替」項目を本 ADR の手順に置き換え

将来の改善余地（案3 の即時反映ハイブリッド）は、公式 CLI の `--plugin-dir` フラグ統合や `directory` ソースのライブモード機能追加が CLI 側で行われた場合に再検討する。

## Consequences

### 良い影響

- ローカル開発でもプラグインが確実に認識される（実証済: `copilot plugin install` 後 `installed plugins` に `ai-driven-dev-principles` が表示）
- 公式 CLI コマンド経由で完結し、`settings.json` の手動編集が不要になる
- 「local」という非標準マーケットプレイス名への依存が消える
- README の手順が公開／開発で統一感のある形になる

### 悪い影響 / 留意点

- **編集即時反映が失われる**: `skills/` を編集した後 `copilot plugin update ai-driven-dev-principles` を実行する必要がある（dev-link の主目的だった即時反映は犠牲）
- 既存の dev-link 利用者（本リポ開発者）は `local/ai-driven-dev-principles` junction と `enabledPlugins` の `@local` エントリを手動削除する必要がある
- ADR-0015 のステータス表記が独自運用（`Accepted (amended by ADR-0017)`）になる

### 派生する将来ADR候補

- ADR ステータス語彙に `Amended` を追加するか、新規 ADR で完全置換する慣習を採るかの整理
- 編集即時反映が必要なワークフローを取り戻すための CLI 機能要望／ハック手順の標準化（案3 を再検討）

## 補足: private リポジトリ前提での運用

本リポジトリは public 化予定がない private リポジトリである。利用想定は所有者および招待された知人に限定される。したがって本 ADR の手順は以下の二段階運用となる（README 参照）:

- **方式 A (GitHub 経由)**: `copilot login` で認証済みかつ private リポへアクセス権を持つアカウントから `copilot plugin marketplace add taika-izumi/ai-driven-dev-principles` で登録。別 PC への展開や知人共有時の標準。
- **方式 B (ローカル directory)**: 本リポジトリを clone し、絶対パスで登録。本ファイルの「Decision」項で実証した手順そのもの。フォルダ移動時は uninstall → marketplace remove → marketplace add（新パス）→ install で再構成する。

private リポでの方式 A の動作は CLI 認証フローに依存し未検証のため、初回の別 PC 利用時に動作確認し、不可なら方式 B にフォールバックする。
