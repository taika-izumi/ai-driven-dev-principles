# ADR-0004: ワークフロー起点スキル（start-work）の導入

- **Status**: Accepted
- **Date**: 2026-04-27

## Context

本リポジトリのメタ・ガイドラインを実プロジェクトに適用したところ、以下の問題が観察された:

1. brainstorming や writing-plans の途中で意思決定が行われても ADR が作成されない
2. セッションを跨ぐ作業継続の引き継ぎ記録が自動更新されない

これらの問題は、Layer 2（copilot-instructions.md）に常時ルールを書くだけでは LLM の遵守が希釈されやすく、また superpowers の各スキル本体は外部プラグインのため直接フローに割り込めないという制約から生じている。

## Considered Alternatives

1. **copilot-instructions.md に常時ルール追加のみ** — 軽量だが、LLMの遵守に依存し、長文化で希釈されやすい
2. **decision-gate スキルを新設し、間に挟む** — 検出と記録を分離できるが、superpowers から強制呼び出しできない以上、結局 copilot-instructions.md に「呼び出しを強制」と書くことになり、案1と実質同等
3. **作業起点スキル `start-work` を新設し、横断関心（handoff、ADR検出、pre-action-review）を一元化する** — フロー定義を独立した責務として分離でき、ハンドオフ・ADRゲートを始め、将来の横断関心追加にも拡張しやすい

## Decision

案3を採用する。`start-work` を新設し、「横断関心ゲートウェイ + 次手ナビゲーター」として機能させる。フローは1本に固定せず、ユーザーの作業意図に応じて superpowers の適切なスキルへ delegate する設計とする（順序固定によるフロー逸脱問題を回避）。

superpowers が不在の環境でも動作するよう、各フェーズには簡易インラインフォールバックを内包する。

## Consequences

- 横断関心が一元化され、ADRゲートとハンドオフ更新が確実に発火するようになる
- copilot-instructions.md の「作業開始時は start-work を呼ぶ」という1行ルールに集約され、ルールの希釈が抑えられる
- スキル数が2つ増える（start-work, session-handoff）。学習コストが微増する
- superpowers の API が破壊的変更を起こした場合、依存検出ロジックの更新が必要になる
