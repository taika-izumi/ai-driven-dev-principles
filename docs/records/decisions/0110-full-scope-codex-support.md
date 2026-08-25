# ADR-0110: Codex 対応はフル対応（Layer 2 + Layer 3 + 周辺文書の中立化）を単一サイクルのスコープとする

- **Status**: Accepted
- **Date**: 2026-08-25

## Context

本ガイドライン（原則・行動指示・スキルの体系）は GitHub Copilot CLI / Claude Code の 2 ツールを前提に整備されてきた（Layer 2 一本化は ADR-0023）。これを OpenAI Codex（Codex CLI）でも利用可能にする拡張を開始するにあたり、1 サイクルで扱う範囲を決める必要があった。

2026-08-25 の公式ドキュメント調査（developers.openai.com/codex 配下）で次が確認された:

- Codex はスキル機構を持つ（`$REPO_ROOT/.agents/skills` ほか、SKILL.md + frontmatter `name`/`description`。Claude Code とほぼ同形）
- スキル一覧の予算（コンテキスト窓の 2% または 8,000 文字）は初期一覧（name + description）のみに適用され、本文サイズには及ばない（現行最大 34,676B の SKILL.md も配信可能な見込み）
- プラグイン機構があり、マーケットプレイス探索先に `$REPO_ROOT/.claude-plugin/marketplace.json` が legacy 互換として含まれる。プラグイン側マニフェストは `.codex-plugin/plugin.json`
- Codex は Layer 2 として `AGENTS.md` 系を読み、`CLAUDE.md` は読まない

## Considered Alternatives

1. **フル対応**: Layer 2（AGENTS.md 経路）+ Layer 3（Codex 向けプラグイン配信）+ README/CONTRIBUTING/スキル本文のツール中立化を 1 サイクルで行う。Layer 2 だけではスキルが動かず「ガイドラインの大半が機能しない」状態が残るのに対し、調査により Layer 3 の追加コストが当初想定より小さいと判明したため、完成状態まで到達できる
2. **Layer 2 のみ先行**: AGENTS.md 経路だけ整え、スキル配信は次サイクルへ。ADR-0023 改訂の判断に集中できるが、Codex 上でガイドラインが実質機能しない中間状態が 1 サイクル残る
3. **Layer 3 のみ先行**: プラグイン配信を先に通す。機械的作業中心で確実だが、行動指示（Layer 2）が読まれないままスキルだけ動く不整合な状態になる

## Decision

案 1（フル対応）を採用する。スコープは Layer 2 の Codex 到達経路の設計・実装、Layer 3 の Codex 向け配信対応、および README・CONTRIBUTING・スキル本文のツール依存記述の中立化を含む。Layer 2 の具体設計（AGENTS.md と CLAUDE.md の構成、ADR-0023 の部分改訂の形）と Layer 3 の具体設計は本サイクルの後続の設計決定で確定する。

## Consequences

- Codex 対応が 1 サイクルで完成状態（行動指示＋スキル呼び出しの両方が機能）に到達できる
- 影響ファイルが多く（前回の Claude Code 対応 ADR-0023 で 9 件、今回は同等以上の見込み）、配布物生成の既知の落とし穴（ADR-0082/0084 の型）を踏む面が広がる。執行点 4 手順と配布物の目視工程で受け止める
- ADR-0023 の「Layer 2 ファイルは 1 つに統一する」決定に対する部分改訂が本サイクル内で必要になる（具体の形は後続の設計決定）
- Claude Code の `@AGENTS.md` インポート挙動など非公式情報に依拠した前提が残っており、設計確定前にユーザーの実機確認を要する
