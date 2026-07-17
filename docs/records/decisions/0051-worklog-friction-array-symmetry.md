# ADR-0051: worklog の friction を string[] 化して delta ペアの型を対称にする

- **Status**: Proposed
- **Date**: 2026-07-17

## Context

現行スキーマ（ADR-0045）は friction（string）と corrections（string[]）で型が非対称であり、1 作業に複数の躓きがあった場合 friction は文字列連結するしかない（Issue-0029 の指摘 2）。本サイクルでスキーマ版数の導入（ADR-0049）とスキーマ改訂（ADR-0048）を行うため、型変更の追加コストが最小になる機会でもある。

## Considered Alternatives

- **現状維持（string のまま）**: 型変更の波及（読み側分岐）を避けられるが、複数躓きの個別保持ができず、記録単位規範（ADR-0053 の「同一 context の delta 束」）とも整合しない

## Decision

`friction` を **string[]** へ変更する（v2 スキーマ）。delta ペアは friction（string[]）/ corrections（string[]）の対称になり、同一作業内の複数の躓きを個別要素として保持できる。読み側は v1 行（string）を 1 要素配列として解釈する（ADR-0049 の版数規約で判別）。

## Consequences

- 良い影響: 複数躓きの個別保持が可能になり、抽出時のクラスタリング単位が揃う。delta ペアの型対称で記述・検証ルールが単純になる
- コスト・留意: 読み側（worklog-extract）に v1 互換の読み替え（string → 1 要素配列）が必要
- Issue-0029 の指摘 2 は本 ADR で対処（指摘 1・3 は ADR-0052）
