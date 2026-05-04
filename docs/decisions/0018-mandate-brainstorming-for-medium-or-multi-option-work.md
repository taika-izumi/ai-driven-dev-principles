# ADR-0018: 中規模以上の作業着手前に brainstorming skill 必須化

- **Status**: Proposed
- **Date**: 2026-05-05

## Context

サブプロジェクト「Copilot CLI プラグイン配布化」（feature/plugin-distribution）の retrospective（`docs/retrospectives/2026-05-05-plugin-distribution.md`）において、複数の手戻りが「要求整理の不足」を真因として連鎖的に発生したことが分析された:

- **真因 A（前提制約）**: ユーザーに Copilot CLI の install 仕組みに関するドメイン知識がなく、メイン提案の妥当性を判断・修正できなかった。**ドメイン知識ギャップを検知・補完する仕組みがメイン側に無かった**
- **真因 B（上流原因）**: メインから「要求を深堀りする質問」が不足していた。**brainstorming skill 必須化ルールがガイドラインに明記されていなかった**ため、設定通りの動作として brainstorming が実行されなかった
- **真因 C（下流原因）**: 動作確認のためのセッション跨ぎ検証で、メインが「落とし穴チェック」を行わずにセッション即終了を急いだ

このうち**真因 B への直接対処**として、本 ADR を起票する。

現状のメタ・ガイドライン（`.github/copilot-instructions.md`）には brainstorming skill の明示的な起動義務が定義されておらず、`start-work` skill の Phase 2 マッピング表でも brainstorming への割当が無い。superpowers プラグインの brainstorming skill 自体は利用可能だが、起動条件が暗黙のため、複数の解決策が想定される作業でも実装着手まで一直線に進んでしまう構造になっている。

retrospective 採用提案 #1 として承認された改善内容を ADR 化し、次サイクルで実装する。

## Decision

中規模以上の作業／複数の解決策が想定される作業の着手前に、`brainstorming` skill を必須実行するルールを明文化する。具体的な変更は以下の通り:

### 1. メタ・ガイドライン側（`.github/copilot-instructions.md`）

「メタ・ガイドライン」セクション配下に、新規ルールを追加:

> **要求の深堀り（継続適用）**
>
> 以下のいずれかに該当する作業を着手する時は、`start-work` Phase 0 内で `brainstorming` skill を必ず呼ぶこと:
>
> - **規模条件**: 主要機能が2つ以上、または想定モジュール/コンポーネントが3つ以上の作業（`feature-block-design` skill の閾値と一致）
> - **選択肢条件**: 規模に関係なく、複数の解決策・実装方式が想定される作業
>
> 「実装方針が一つしか思いつかない」と感じても、選択肢条件に該当する場合は brainstorming で代替案を強制的に検討すること。

### 2. start-work skill 側（`skills/start-work/SKILL.md`）

Phase 2 のマッピング表に新規行を追加:

| 状況 | 推奨スキル | 備考 |
|------|----------|------|
| 中規模以上、または複数解決策あり | `brainstorming`（superpowers） | Phase 0 内で実行。メタ・ガイドライン「要求の深堀り」に基づく |

### 3. 「中規模以上」の定義

既存の `feature-block-design` skill が定義する閾値（主要機能2つ以上、または想定モジュール/コンポーネント3つ以上）を流用する。これにより既存ガイドラインとの整合性を保ち、同じ基準を二箇所で別定義する混乱を回避する。

## Alternatives Considered

- **案 A: brainstorming を全作業で必須化**
  - 却下理由: 単純な改修・bugfix まで brainstorming を強制するとオーバーヘッドが大きい。原則4「人間の関与」は判断機会の確保が目的であり、判断不要な作業まで対象にする必要はない

- **案 B: メタ・ガイドラインのみ更新（start-work マッピング表は触らない）**
  - 却下理由: `start-work` skill のマッピング表が実運用上の起動トリガーとして機能している。メタ・ガイドラインに書くだけでは Phase 2 で見落とされるリスクが高い

- **案 C: brainstorming 起動を「ユーザーが要求した時のみ」とする**
  - 却下理由: 真因 A（ドメイン知識ギャップ）があるとユーザーは brainstorming の必要性を判断できない。メイン側からの能動的起動が必要

- **案 D: 「中規模以上」を独自閾値で定義（例: 想定変更ファイル数 5 以上）**
  - 却下理由: `feature-block-design` skill と別定義になり、運用時に「中規模かどうか」の判断揺れが発生する

## Consequences

### Positive

- 真因 B（要求深堀り不足）への構造的対処。同種の手戻りが再発しにくくなる
- `brainstorming` skill が活用される頻度が上がり、superpowers プラグインの効用を引き出せる
- `feature-block-design` の閾値を流用することで、既存ガイドラインとの整合性が保たれる

### Negative / Trade-offs

- 中規模以上の作業で必ず brainstorming フェーズが発生するため、着手から実装までの時間は若干増える（ただし手戻りコスト > brainstorming コストの想定）
- 「中規模以上か否か」の判断が `start-work` Phase 0 で必要になる。メイン側が誤判定すると brainstorming が呼ばれない／不要に呼ばれる可能性

### Follow-up

- 本 ADR は **Proposed**。次サイクルで `start-work` から実装を開始する
- 実装後、数サイクル運用して効果（手戻り削減・brainstorming 起動頻度）を観察し、必要なら閾値や条件を調整する
- 真因 A（ドメイン知識ギャップ補完）と真因 C（セッション跨ぎ検証チェック）は本 ADR では対応しない。それぞれ retrospective の提案 #3・#2 として保留中で、別 ADR で扱う

## Related

- ADR-0006: 意思決定の継続検出ルール
- ADR-0010: 振り返りフェーズ導入（本 ADR は retrospective 由来の改善提案）
- 関連 retrospective: `docs/retrospectives/2026-05-05-plugin-distribution.md`（提案 #1）
- 関連スキル: `start-work`, `brainstorming`（superpowers）, `feature-block-design`
- 関連原則: 原則3（コンテキスト管理）、原則4（人間の関与）
