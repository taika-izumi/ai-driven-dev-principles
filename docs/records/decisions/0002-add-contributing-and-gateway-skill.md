# ADR-0002: コンテキスト継続性のためのCONTRIBUTING.mdとゲートウェイSkillの追加

- **Status**: Accepted
- **Date**: 2026-04-13

## Context

新しいセッションのAIエージェントは会話履歴を持たないため、このリポジトリの設計思想（3層アーキテクチャ、リスクスケーリング、独立拡張性）や拡張ルール（原則追加の基準、Skill化の判定基準等）を把握できない。README.mdの「成長サイクル」セクションは手順の概要のみで、判断基準が不足していた。

## Considered Alternatives

1. **README.mdに詳細な拡張ガイドを追記する** — README.mdが肥大化し、プロジェクト概要としての役割が薄れる
2. **copilot-instructions.mdにCONTRIBUTING.mdへの参照を追加する** — copilot-instructions.mdの他プロジェクトへの流用性が損なわれる
3. **CONTRIBUTING.md + ゲートウェイSkillの2層構成** — 情報の単一ソース（CONTRIBUTING.md）とSkillによる自動ガイドで、発見性と流用性の両立を実現する

## Decision

選択肢3を採用する。CONTRIBUTING.mdをシナリオ駆動型（やりたいことベースで逆引き）で構成し、extend-guidelinesスキルをゲートウェイとしてCONTRIBUTING.mdの読み込みからbrainstormingへの接続を自動化する。

## Consequences

- 新セッションのエージェントがextend-guidelinesスキルを実行するだけで、設計思想の把握から拡張作業の開始まで自動的にガイドされる
- CONTRIBUTING.mdが拡張ルールの単一ソースとなり、情報の二重管理を回避できる
- copilot-instructions.mdの流用性は維持される（プロジェクト固有の参照を含まない）
- CONTRIBUTING.md自体のメンテナンスが必要になる（新しいシナリオの追加等）
