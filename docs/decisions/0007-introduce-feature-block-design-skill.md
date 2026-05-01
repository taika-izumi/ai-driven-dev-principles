# ADR-0007: 機能ブロック駆動の設計スキル（feature-block-design）の導入

- **Status**: Accepted
- **Date**: 2026-05-01

## Context

AIエージェントを活用した開発で、以下の課題が繰り返し観察されている:

1. brainstorming 時点では「全体方針」までしか確定せず、システムを疎結合な機能ブロックに分割する作業がしばしば省略される
2. その結果、生成されたシステムが大きな泥団子化・スパゲッティ化する
3. 既存の brainstorming スキルにも "design for isolation and clarity" の指針はあるが、抽象的指針のためトリガーとして弱い

AIは一般的な設計原則の知識を持っているにも関わらず、「いつ・どの粒度で・どんな形式で」分割するかの強制トリガーがないため、知識が実行に結びつかない。

## Decision

brainstorming と writing-plans の間に新スキル `feature-block-design` を挟む。

このスキルは:
- brainstorming で合意済みの全体方針を入力に
- 適用要否を判定し（主要機能 ≥ 2 または想定モジュール ≥ 3）
- 機能ブロックを抽出してユーザー承認を得て
- 各ブロックの詳細仕様を分割形式で出力する

## Alternatives Considered

- **2スキル分離（feature-block-decomposition + spec-partitioning）**: 関心分離は綺麗だが、実運用ではほぼ常にセットで使うためハンドオフが過剰。
- **スキルを増やさず原則拡張＋既存スキル強化のみ**: トリガーが弱く、既存問題（知識があっても実行されない）を再生産する懸念が大きい。

## Consequences

- brainstorming 直後にもう1段の合意プロセスが入るため、小タスクではオーバーヘッドになる → 適用要否判定で回避
- brainstorming との責務境界をスキル内に明示する必要がある → スキルに明文化
- writing-plans が「ブロック単位の詳細仕様」を入力にできるようになり、plan 自体もブロック単位で分割しやすくなる

## Related

- spec: `docs/specs/2026-05-01-feature-block-design/00-overview.md`
- spec: `docs/specs/2026-05-01-feature-block-design/01-skill-feature-block-design.md`
