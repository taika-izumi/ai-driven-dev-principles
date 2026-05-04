# ADR-0015: スキル群を Copilot CLI プラグインとして配布（公式プラグイン化 + dev-link ハイブリッド）

- **Status**: Accepted
- **Date**: 2026-05-04

## Context

本リポジトリ `taika-izumi/ai-driven-dev-principles` は `skills/` 配下に独自のメタ・ガイドライン用スキル（`start-work`, `decision-log`, `session-handoff`, `feature-block-design`, `pre-action-review`, `extend-guidelines`, `retrospective`）を保持している。これらは `copilot-instructions.md` から「必ず呼ぶこと」と指示されているが、Copilot CLI の `skill:` ツールは `~/.copilot/installed-plugins/<marketplace>/<plugin>/skills/<name>/SKILL.md` に配置されたスキルのみを自動認識するため、本リポジトリの `skills/` ディレクトリは未認識となり、構造化呼び出しが不可能だった。

本セッション内でも `skill: "decision-log"` 呼び出しが "Skill not found" で失敗したことで、問題が実証されている。

リポジトリは「他プロジェクトへコピーするテンプレート」と「自身の開発資産」の二重用途を持っており、解決策はこの両用途と将来の公開可能性を維持する必要がある。

## Considered Alternatives

| # | 案 | 評価 |
|---|---|---|
| 1 | 公式プラグイン化のみ（`.claude-plugin/plugin.json` + `marketplace.json` 追加 → `extraKnownMarketplaces` 経由 install） | 標準フローだが、開発中に `skills/` を編集しても再インストールしないと反映されない |
| 2 | ローカル junction のみ（`installed-plugins/<任意>/<repo>` を本リポジトリに junction） | 開発即時反映だが公開不可、各開発者が手動セットアップ必要 |
| 3 | `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` で skills を instructions として読み込ませる | `skill:` ツール経由起動が不可能で要件未達 |
| 4 | `copilot-instructions.md` で「skills/<name>/SKILL.md を view せよ」と明記 | 構造化呼び出しではなく毎回 view が必要、enforcement が弱い |
| 5 | 別リポジトリで marketplace を配信 | 二重管理コスト発生、原則1（追跡可能性）と矛盾しがち |
| 6 | **公式プラグイン化 + dev-link スクリプト併用**（採用） | 公開可能性と開発体験を両立、両者は同じディレクトリ実体を見る |

## Decision

**案6: 公式プラグイン化と dev-link スクリプトのハイブリッドを採用する。**

具体的には:

1. **プラグイン manifest の追加**
   - `.claude-plugin/plugin.json`: プラグインメタデータ（name, description, version 等）
   - `.claude-plugin/marketplace.json`: 単一プラグインを配信するマーケットプレイス定義
   - `skills/` の構造（`<name>/SKILL.md`）はそのまま維持（既に Copilot CLI 規約に準拠）
2. **README に「Copilot CLI へのインストール手順」セクションを追加**
   - `extraKnownMarketplaces` への追記例
   - `/plugin install` 手順
3. **`scripts/dev-link.ps1`（および可能なら sh 版）の追加**
   - `~/.copilot/installed-plugins/local/ai-driven-dev-principles` から本リポジトリへの junction/symlink を作成し、開発時に `skills/` への変更を即時反映可能にする
   - 安全性: 既存ディレクトリがあれば確認、`settings.json` への自動追記は行わず手順を README に明示
4. **`template.manifest` の更新**
   - 新規プロジェクトでも同様の配布をしたい場合に備え、`.claude-plugin/` ファイルを template に含めるかは別途判断（本ADRのスコープ外）

## Consequences

### 良い影響

- 本リポジトリの開発において `skill: "start-work"` 等が構造化呼び出しで認識される
- 他者も `extraKnownMarketplaces` 経由で標準フローでインストール可能
- 開発者は dev-link で即時反映の恩恵を受けられる
- リポジトリは「テンプレート + プラグイン + 開発資産」の三役を担うが、ディレクトリ構造の追加は `.claude-plugin/` と `scripts/dev-link.*` のみで済む

### 悪い影響 / 留意点

- `.claude-plugin/plugin.json` の `version` 管理が必要になる（更新ルール未策定 → 将来 ADR 候補）
- dev-link 利用時は `settings.json` の `enabledPlugins` への手動追記が必要（README で誘導）
- Windows 環境で junction を作成する場合、管理者権限不要だがパスの違いに注意（ドキュメント明記）
- `template.manifest` への取り込み判断は持ち越し（テンプレート利用先が常にプラグイン化したいとは限らない）

### 派生する将来ADR候補

- プラグインバージョニング規約
- `template.manifest` への `.claude-plugin/` 取り込み可否
