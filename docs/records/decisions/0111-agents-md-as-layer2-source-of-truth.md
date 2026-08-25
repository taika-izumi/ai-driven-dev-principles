# ADR-0111: Layer 2 は AGENTS.md を正本とし、CLAUDE.md は @AGENTS.md インポートの 1 行に置き換える

- **Status**: Accepted
- **Date**: 2026-08-25

## Context

Codex 対応（スコープは ADR-0110）で、Layer 2（エージェント向け行動指示）を 3 ツールへ届ける構成が必要になった。各ツールの読み込み挙動（2026-08-25 公式ドキュメント確認・実機実測）:

- Codex: `AGENTS.md` を読む。`CLAUDE.md` は読まない。実測: scratch ディレクトリで `codex debug prompt-input` を実行し、AGENTS.md 全文が `<INSTRUCTIONS>` として注入されること・ポインタ化した CLAUDE.md は注入されないことを確認（Codex CLI 0.149.0-alpha.4.3）
- Claude Code: `CLAUDE.md` を読む。`AGENTS.md` は読まないが、`CLAUDE.md` 内の `@path` インポート（起動時展開・相対パスは記述ファイル基準・再帰 4 段）が公式サポートされ、`@AGENTS.md` の 1 行を置く構成が公式ドキュメント（code.claude.com/docs/en/memory の「AGENTS.md」節）で推奨されている。Windows ではシンボリックリンクに管理者権限が要るためインポートが推奨される。実測: 同 scratch で `claude -p` を実行し、ポインタ経由で AGENTS.md 内のマーカー文字列がモデルへ到達することを確認
- GitHub Copilot CLI: `AGENTS.md`・`CLAUDE.md`・`GEMINI.md`・`.github/copilot-instructions.md` をすべて結合して読む（同一内容の重複は除去。一般的な優先順位は未定義。docs.github.com の Copilot CLI カスタム指示ページ）

ADR-0023 は「Layer 2 ファイルは 1 つに統一する（両方残すと Copilot CLI が二重読み込みするため）」（Decision 1）と「AGENTS.md は Claude Code がネイティブに読まないため採用しない」（Decision 7）を決めていた。現行の Copilot CLI 公式ドキュメントは重複除去を明記しており、Decision 1 の前提とは異なる（当時の仕様か記述の誤りかは判別不能）。Decision 7 の不採用理由は `@path` インポートの公式サポート確認により失効した。

## Considered Alternatives

1. **AGENTS.md 正本化 + CLAUDE.md は `@AGENTS.md` の 1 行**: Codex は正本を直接読む。Claude Code は公式推奨のインポートで同一内容を読む。Copilot CLI は正本＋解釈されないポインタ 1 行を読む（内容の重複は生じない）。内容の正本は 1 ファイルのまま
2. **CLAUDE.md 正本のまま + AGENTS.md に「CLAUDE.md を読め」の指示文**: 変更最小だが、Codex にはインポート機構が無く、指示追従はモデル挙動頼みで起動時コンテキストに正本が入らない
3. **両ファイルへ生成器で同一内容を複製**: Copilot CLI の重複除去は効くが、物理正本が 2 つになり複写乖離型の監視点（ADR-0098 で監視中の型）を増やす

## Decision

案 1 を採用する。本リポジトリと template 配布物の両方で、Layer 2 の内容正本を `AGENTS.md` に移し、`CLAUDE.md` は `@AGENTS.md` インポートの 1 行に置き換える。配布先プロジェクトの固有指示は AGENTS.md 側へ追記する運用とする。

ADR-0023 へは部分修正注記を追記する（Accepted 維持・書式は decision-log「ステータス変更」の部分修正の型に従う）。対象は次の 2 項目:

- Decision 1「Layer 2 ファイルは 1 つに統一する」→「Layer 2 の**内容の正本**は 1 つに統一する（物理ファイルはツール到達経路として複数置いてよい。ただし内容を持つのは正本のみ）」
- Decision 7「AGENTS.md は Claude Code がネイティブに読まないため採用しない」→ `@path` インポートの公式サポート確認により不採用理由が失効し、本 ADR で採用へ転換

あわせて、ADR-0023 Considered Alternatives 案 2（AGENTS.md 単一ソース＋`@AGENTS.md` インポート＝本 ADR で採用する構成）の否定評価が前提失効により覆った旨を、同じ部分修正注記内で言及する。

## Consequences

- 3 ツールすべてが同一内容の Layer 2 を起動時に読む状態になる（Claude Code・Codex は実測済み）
- ADR-0023 が懸念した二重読み込みは再発しない（Copilot CLI が余分に読むのはポインタ 1 行のみ）
- 配布先プロジェクトで CLAUDE.md へ固有指示を書き足してきた既存運用は AGENTS.md への追記に変わる。template 再コピーで固有指示が上書き消失する経路があるため、README に順序付き移行手順（固有指示の退避 → ポインタ化）を独立節で置く
- ポインタ化した CLAUDE.md を `check-claude-md-size.ps1` が測り続けると規範肥大監視（ADR-0040）が無音化するため、計測対象を AGENTS.md へ切り替える
- スキル等の「プロジェクトの CLAUDE.md に調整値」型参照は、プラグイン配信と template 同期の反映時期のずれに耐えるよう「AGENTS.md（記載が無ければ CLAUDE.md）」の二段フォールバック表現（ファイルの有無ではなく調整値の記載の有無で探索）へ書き換える
- template.manifest・sync-template.ps1 の対象に AGENTS.md が加わり、AGENTS.md は配布対象ソースとして記法規約（ADR-0083）の適用対象になる
