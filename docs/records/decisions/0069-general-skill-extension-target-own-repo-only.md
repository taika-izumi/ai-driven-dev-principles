# ADR-0069: 汎用スキルの拡張先は自リポジトリの `skills/` に限り、third-party プラグインのスキルは編集しない

- **Status**: Accepted
- **Date**: 2026-08-05

## Context

本リポジトリのワークフローは superpowers プラグイン（`brainstorming` / `writing-plans` / `executing-plans` / `subagent-driven-development` / `requesting-code-review` / `verification-before-completion` 等）に強く依存している。運用の中で「既存スキルにこの規律が足りない」と判明することが繰り返し起きており、その対処先として superpowers のスキルが自然に候補に挙がる。

実際、`worklog-extract` が採用した 2 件の課題は、いずれも対策方針に superpowers のスキルを拡張先として書いていた。

- Issue-0033: 「新規スキル作成より `subagent-driven-development` / `dispatching-parallel-agents` への定型チェックリスト追加が適する見込み」
- Issue-0034: 「`requesting-code-review` の射程を非コード成果物へ広げる」「`writing-plans` / `feature-block-design` の末尾に独立レビュー工程を必須ステップとして足す」

しかし superpowers の実体は `~/.claude/plugins/cache/superpowers-marketplace/superpowers/5.1.0/skills/` にあるマーケットプレイス配信物である。**編集してもプラグイン更新で失われる。** 両課題とも、この確認を経ずに対策方針を書いていた。

**この制約は `worklog-skillify` を起動して初めて表面化した。** 課題の起票時点でも、`worklog-extract` の採用時点でも検出されていない。

## Considered Alternatives

1. **third-party スキルを編集し、プラグイン更新のたびに再適用する** — 更新のたびに手作業が発生し、再適用漏れは静かに規律を失わせる。更新があったことに気づく仕組みもない
2. **superpowers をフォークして自前で配信する** — 編集の自由は得られるが、上流の改善を取り込むコストが恒久的に発生する。ワークフローの中核を自前で保守することになり、依存の利点を失う
3. **拡張先を自リポジトリに限り、既存スキルの穴は自リポジトリ側で補完する** — 採用

## Decision

- **汎用スキル（プラグイン配信）の拡張先は、自リポジトリの `skills/` 配下に限る。** third-party プラグインのスキルは編集対象にしない
- **既存スキルの射程を広げたい場合は、次のいずれかで補完する**
  - 自リポジトリ側に補完するスキルを新設し、`start-work` の Phase 2 マッピング表から配線する
  - `CLAUDE.md` の規範で上書きする（superpowers の `using-superpowers` が定める優先順位により、ユーザー指示が最上位に立つ）
- **課題の対策方針を書く段階で「拡張先が自リポジトリにあるか」を確認する。** `worklog-skillify` の起動時ではなく、起票・採用の時点で確認する

## Consequences

- **プラグイン更新で規律が失われる経路を塞ぐ。** 更新の追随コストも発生しない
- **上流の改善をそのまま受け取れる。** superpowers 側の変更を自前の編集と突き合わせる作業が不要になる
- **自リポジトリのスキル数が増える。** 既存スキルの穴を埋めるたびに新規スキルが立ち、`start-work` Phase 2 のナビゲーションが複雑化する。ADR-0067 で決めた非コード成果物のレビュースキルがその第 1 例になる
- **補完スキルは既存スキルと責務が隣接する。** 「どちらを使うか」の判断が実行時に必要になり、境界が曖昧だと両方走るか両方走らないかのどちらかになる
- **既存の課題 2 件（Issue-0033 / Issue-0034）は、この確認を経ずに対策方針を書いていた。** 同種の見落としが他の未着手課題にも潜在しうる
- 本 ADR は ADR-0065（採用した worklog 候補をどの段階でスキル化するか）から分割された。両者は同じ着手判断の中で決まったが、答える問いが異なる（ADR-0059 / ADR-0060 の粒度規範）
