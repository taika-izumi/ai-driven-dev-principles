# ADR-0111: Layer 2 は AGENTS.md を正本とし、CLAUDE.md は @AGENTS.md インポートの 1 行に置き換える

- **Status**: Proposed
- **Date**: 2026-08-25

## Context

Codex 対応（スコープは ADR-0110）で、Layer 2（エージェント向け行動指示）を 3 ツールへ届ける構成が必要になった。各ツールの読み込み挙動（2026-08-25 公式ドキュメント確認）:

- Codex: `AGENTS.md` を読む。`CLAUDE.md` は読まない
- Claude Code: `CLAUDE.md` を読む。`AGENTS.md` は読まないが、`CLAUDE.md` 内の `@path` インポート（起動時展開・相対パスは記述ファイル基準・再帰 4 段）が公式サポートされ、`@AGENTS.md` の 1 行を置く構成が公式ドキュメントで推奨されている。Windows ではシンボリックリンクに管理者権限が要るためインポートが推奨される
- GitHub Copilot CLI: `AGENTS.md`・`CLAUDE.md`・`GEMINI.md`・`.github/copilot-instructions.md` をすべて結合して読む（同一内容の重複は除去。一般的な優先順位は未定義）

ADR-0023 は「Layer 2 ファイルは 1 つに統一する（両方残すと Copilot CLI が二重読み込みするため）」と決めていた。

## Considered Alternatives

1. **AGENTS.md 正本化 + CLAUDE.md は `@AGENTS.md` の 1 行**: Codex は正本を直接読む。Claude Code は公式推奨のインポートで同一内容を読む。Copilot CLI は正本＋解釈されないポインタ 1 行を読む（内容の重複は生じない）。内容の正本は 1 ファイルのまま
2. **CLAUDE.md 正本のまま + AGENTS.md に「CLAUDE.md を読め」の指示文**: 変更最小だが、Codex にはインポート機構が無く、指示追従はモデル挙動頼みで起動時コンテキストに正本が入らない
3. **両ファイルへ生成器で同一内容を複製**: Copilot CLI の重複除去は効くが、物理正本が 2 つになり複写乖離型の監視点（ADR-0098 で監視中の型）を増やす

## Decision

案 1 を採用する。本リポジトリと template 配布物の両方で、Layer 2 の内容正本を `AGENTS.md` に移し、`CLAUDE.md` は `@AGENTS.md` インポートの 1 行に置き換える。配布先プロジェクトの固有指示は AGENTS.md 側へ追記する運用とする。

ADR-0023 の「Layer 2 ファイルは 1 つに統一する」は「Layer 2 の**内容の正本**は 1 つに統一する（物理ファイルはツール到達経路として複数置いてよい。ただし内容を持つのは正本のみ）」へ部分修正する（ADR-0023 は Accepted 維持・部分修正注記を追記）。

## Consequences

- 3 ツールすべてが同一内容の Layer 2 を起動時に読む状態になる
- ADR-0023 が懸念した二重読み込みは再発しない（Copilot CLI が余分に読むのはポインタ 1 行のみ）
- 配布先プロジェクトで CLAUDE.md へ固有指示を書き足してきた既存運用は AGENTS.md への追記に変わる（README の手順更新が必要。既存プロジェクトには移行手順の案内が必要）
- Copilot CLI がポインタ行を素のテキストとして読む状態は仕様外だが無害と評価した
- template.manifest・sync-template.ps1 の対象に AGENTS.md が加わる
