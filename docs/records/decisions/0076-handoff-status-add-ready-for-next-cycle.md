# ADR-0076: handoff の Status に `ready-for-next-cycle` を正式追加する

- **Status**: Proposed
- **Date**: 2026-08-06

## Context

Issue-0051: `retrospective` は Phase 3 で「handoff Status を `completed` → `ready-for-next-cycle` へ遷移」と指示するが、`session-handoff` が定義する Status は `in_progress` / `paused` / `completed` の 3 値であり、`ready-for-next-cycle` は未定義。また「`completed` からの遷移」という記述も実態（retrospective 実施時点は通常 `in_progress`）と合っていない。Status はハンドオフの読み手が最初に見る値であり、定義外の値は読み手に運用の推測を強いる。両リポジトリで既に顕在化している。

## Considered Alternatives

1. **`session-handoff` の定義に `ready-for-next-cycle` を追加する** — サイクル完了後の長命ブランチ（master 等）の handoff は「作業完了（completed）」でも「中断（paused）」でもなく「次サイクル待ち」であり、専用の値に意味が立つ。両リポジトリの現運用とも一致し変更が最小
2. **`retrospective` 側を `completed` に合わせる** — 定義変更は不要だが、「master の handoff が completed」は誤読を招く（master の作業自体は終わらない）
3. **サイクル完了時にハンドオフをアーカイブして新規作成する** — ADR-0074 で明示アーカイブを設けないと決定済みのため、そのままでは採れない（同一ファイルの書き換えに読み替えた形は ADR-0075 のサイクル境界剪定として採用）

## Decision

案 1 を採用する。`session-handoff` のフォーマット定義の Status を 4 値とする:

- `in_progress` — 作業進行中
- `paused` — 中断中（再開待ち）
- `completed` — 作業完了（feature ブランチのマージ完了時など、そのブランチの handoff が役目を終えた状態）
- `ready-for-next-cycle` — サイクル完了・次サイクル待ち（長命ブランチの handoff が、retrospective 完了後にユーザーの次サイクル判断を待つ状態）

`retrospective` Phase 3 の遷移記述は「`in_progress` → `ready-for-next-cycle`」へ修正する。

## Consequences

- 2 スキル間の不整合が解消し、読み手が Status を定義どおりに解釈できる（Issue-0051 の解決）
- 現運用（両リポジトリで注記付き使用中）が正式化されるため、既存 handoff の値の書き換えは不要。本リポジトリ `master.md` の不整合注記は次回サイクル境界剪定で除去できる
- Status の値が 1 つ増え、読み手・書き手の分岐がわずかに増える
- `session-handoff` / `retrospective` の 2 スキルの改定が必要（ADR-0075 と同一サイクルで実施）
