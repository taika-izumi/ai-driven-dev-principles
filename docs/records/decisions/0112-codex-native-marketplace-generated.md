# ADR-0112: Codex 向け配信は ネイティブの .agents/plugins/marketplace.json と .codex-plugin/plugin.json を生成器導出で追加する

- **Status**: Accepted
- **Date**: 2026-08-25

## Context

Codex 対応（スコープは ADR-0110）で、Layer 3（スキル群のプラグイン配信）を Codex へ届ける構成が必要になった。現行の配布構成はルート `.claude-plugin/marketplace.json`（source: `./dist`）と、`build-dist.ps1` が生成する `dist/`（`.claude-plugin/plugin.json` ＋ `skills/`）である（ADR-0082）。

2026-08-25 の公式ドキュメント確認と実機実測（Codex CLI 0.149.0-alpha.4.3・本開発機）:

- Codex のマーケットプレイス探索先はネイティブの `$REPO_ROOT/.agents/plugins/marketplace.json`・個人用 `~/.agents/plugins/marketplace.json`・legacy 互換の `$REPO_ROOT/.claude-plugin/marketplace.json` の 3 つ。プラグイン側マニフェストは `.codex-plugin/plugin.json`
- 実測: 本リポジトリと同レイアウト（ルート `.agents/plugins/marketplace.json`・`source: {"source":"local","path":"./dist"}`・`dist/.codex-plugin/plugin.json`・`dist/skills/`）の scratch marketplace で、登録 → プラグイン列挙 → `codex plugin add` → `installed, enabled` の全経路を確認。`source.path` は**マーケットプレイスルート（= リポジトリルート）基準**で解決される
- 実測: native と legacy の両 manifest が同居する場合、**native が優先され legacy は無視される（二重登録は起きない）**
- 実測: インストールコマンドは `codex plugin add <plugin>@<marketplace>`（公式ドキュメントの `plugin install` は存在しない。実装がドキュメントに先行）
- ネイティブ marketplace.json の実例 2 件: openai-bundled は `name` / `interface.displayName` / `plugins[]`（`name`・`source.{source,path}`・`policy.{installation,authentication}`・`category`）を持つ。openai-primary-runtime はトップレベル `interface` を持たない（`interface` は必須ではない模様）
- `.codex-plugin/plugin.json` の実物例（superpowers 6.3.0）は `"skills": "./skills/"` ＋ `interface` ブロックを持つ。正本 `.claude-plugin/plugin.json` に `skills` / `interface` フィールドは存在しない
- 現行 `build-dist.ps1` の `-Check`・wipe・残存識別子自己検査はすべて `dist/` 限定であり、ルート直下の生成物をそのまま生成対象に足すと `-Check` が恒久的に失敗する

## Considered Alternatives

1. **legacy 互換に乗る（`.claude-plugin/marketplace.json` を Codex にも読ませ、`dist/.codex-plugin/plugin.json` のみ追加）**: 変更最小で動作も実測済み（superpowers が同構成）だが、互換経路は公式の第一推奨ではなく、将来の非推奨化・削除リスクが相対的に高い
2. **Codex ネイティブの `.agents/plugins/marketplace.json` を追加**: 公式の第一推奨パスに乗る。素朴にやるとマーケットプレイス定義が 2 ファイルになり複写乖離点が増えるが、生成器導出にすれば乖離は構造的に塞げる
3. **Codex はプラグイン化せず `~/.agents/skills` への手動コピー手順を案内**: 中央管理・一括更新（ADR-0015/0016 の設計意図）を Codex 利用者だけが失う

## Decision

案 2 を生成器導出で採用する。

- `.claude-plugin/marketplace.json` を正本とし、`build-dist.ps1` が `.agents/plugins/marketplace.json`（ルート）を導出生成する。`source` は実測済みの `{"source":"local","path":"./dist"}`（リポジトリルート基準）とし、`interface.displayName`・`policy.installation`・`policy.authentication`・`category` は生成器内の固定マッピングで付与する
- `dist/.codex-plugin/plugin.json` も導出生成する。`name` / `version` / `description` / `author` は正本 `.claude-plugin/plugin.json` から複写し、`skills` は `"./skills/"` 固定、`interface` は `displayName`・`category` の 2 キーのみ生成器内の固定マッピングで付与し、それ以外の interface キー（資産参照キーを含む）は生成しない
- `build-dist.ps1` の出力先を一般化する。ディレクトリ走査を伴う工程（wipe・stale 検出・残存識別子自己検査）は従来どおり `dist/` に限定し、ルート直下の生成物は既知パスのホワイトリストに対するファイル単位の生成・存在・内容比較とする（「余分なファイルの不在」条件はルート側に適用しない）
- 通常実行・`-Check` の両モードの冒頭で、正本 `.claude-plugin/plugin.json` の `version` と `.claude-plugin/marketplace.json` の `plugins[].version`（全件）の一致を検査し、不一致なら非ゼロ終了する（二重保持で無検査だった既存の乖離点を同時に塞ぐ）
- 生成物はいずれも git 管理し、手編集しない（正本は `.claude-plugin/` の 2 ファイルのみ。執行点 4 手順の枠内で運用。ADR-0083）

## Consequences

- Codex 利用者は `codex plugin marketplace add taika-izumi/ai-driven-dev-principles` → `codex plugin add ai-driven-dev-principles@ai-driven-dev-principles` で、Claude Code / Copilot CLI と同一のスキル群を中央管理のまま利用できる
- native/legacy 同居時は native が優先されるため（実測）、既存の Claude Code / Copilot CLI 経路（legacy 側）と Codex 経路（native 側）が干渉しない
- マーケットプレイス定義・プラグインマニフェストの正本は従来どおり `.claude-plugin/` の 2 ファイルのみ。Codex 向けファイルは生成物であり手編集しない
- `build-dist.ps1` の責務が「dist 生成」から「複数出力先の生成物生成＋version 一致検査」へ広がる（生成器 spec のスナップショット同期が必要）
- GitHub 経由の marketplace 登録（`codex plugin marketplace add owner/repo`）は legacy 構成の superpowers で実測済み。**native 構成の GitHub 経由登録も 2026-08-25 に実測した**（設計 spec の検証 10。`codex plugin list` の解決先が `.agents/plugins/marketplace.json` であること・`installed, enabled 0.1.12` を確認）
- 改訂記録（検証 10 の実測反映）: Consequences の未実測記述を実測済みへ更新・2026-08-25。Status は Accepted のまま維持
- スキル一覧の初期予算（コンテキスト窓の 2%、不明時 8,000 文字）は全スキルの name + description に適用されるため、実装検証では superpowers 併用状態の全体列挙で警告が出ないことを確認する（自プラグイン単独では dist 側 13 スキルの `description` 値のみ〈囲み引用符を除く〉の合計が 2,069 文字・name を加えても約 2,272 文字〈2026-08-25 実測〉で予算 8,000 文字に対し余裕がある）
