# ADR-0112: Codex 向け配信は ネイティブの .agents/plugins/marketplace.json と .codex-plugin/plugin.json を生成器導出で追加する

- **Status**: Proposed
- **Date**: 2026-08-25

## Context

Codex 対応（スコープは ADR-0110）で、Layer 3（スキル群のプラグイン配信）を Codex へ届ける構成が必要になった。現行の配布構成はルート `.claude-plugin/marketplace.json`（source: `./dist`）と、`build-dist.ps1` が生成する `dist/`（`.claude-plugin/plugin.json` ＋ `skills/`）である（ADR-0082）。

2026-08-25 の公式ドキュメント確認: Codex のマーケットプレイス探索先はネイティブの `$REPO_ROOT/.agents/plugins/marketplace.json`・個人用 `~/.agents/plugins/marketplace.json`・legacy 互換の `$REPO_ROOT/.claude-plugin/marketplace.json` の 3 つ。プラグイン側マニフェストは `.codex-plugin/plugin.json`（必須: name / version / description / skills）。Codex ネイティブの marketplace 形式には `interface.displayName`・各プラグインの `policy.installation` / `policy.authentication` / `category` を常に含めるべきとされる。

## Considered Alternatives

1. **legacy 互換に乗る（`.claude-plugin/marketplace.json` を Codex にも読ませ、`dist/.codex-plugin/plugin.json` のみ追加）**: 変更最小だが、互換経路は公式の第一推奨ではなく、将来の非推奨化・削除リスクが相対的に高い。legacy 互換が Claude 形式スキーマをどこまで解釈するかも未記載
2. **Codex ネイティブの `.agents/plugins/marketplace.json` を追加**: 公式の第一推奨パスに乗る。素朴にやるとマーケットプレイス定義が 2 ファイルになり複写乖離点が増えるが、生成器導出にすれば乖離は構造的に塞げる
3. **Codex はプラグイン化せず `~/.agents/skills` への手動コピー手順を案内**: 中央管理・一括更新（ADR-0015/0016 の設計意図）を Codex 利用者だけが失う

## Decision

案 2 を生成器導出で採用する。

- `.claude-plugin/marketplace.json` を正本とし、`build-dist.ps1` が `.agents/plugins/marketplace.json`（ルート）を導出生成する。Codex 固有の必須フィールド（`interface.displayName`・`policy.installation`・`policy.authentication`・`category`）は生成器内の固定マッピングで付与する
- `dist/.codex-plugin/plugin.json` も同様に `.claude-plugin/plugin.json` から導出生成する（dist は両形式のマニフェストを併記する）
- 生成物はいずれも git 管理し、既存の `-Check` 検査対象に加える（執行点 4 手順の枠内で運用。ADR-0083）

## Consequences

- Codex 利用者は `codex plugin marketplace add taika-izumi/ai-driven-dev-principles` → install で、Claude Code / Copilot CLI と同一のスキル群を中央管理のまま利用できる
- マーケットプレイス定義・プラグインマニフェストの正本は従来どおり `.claude-plugin/` の 2 ファイルのみ。Codex 向けファイルは生成物であり手編集しない
- `build-dist.ps1` の責務が「dist 生成」から「dist ＋ Codex 向けマニフェスト生成」へ広がる
- ネイティブと legacy の両探索先が同居する状態になる。Codex が二重登録しないかは公式に記載が無く、実機検証項目とする（二重登録が観測された場合の扱いは検証結果を見て決める）
- スキル一覧の初期予算（コンテキスト窓の 2% または 8,000 文字）は name + description のみに適用されるため、現行 13 スキルの description 合計が予算内に収まることを実機で確認する
