# ADR-0013: knowledge-distillation スキルを新設してドメイン知識抽出を担当させる

- **Status**: Rejected
- **Date**: 2026-05-01

## Context

ADR-0012 でサブプロジェクトC のスコープ外と決定した「ドメイン知識抽出」を、サブプロジェクトC の初回 retrospective（`docs/retrospectives/2026-05-01-retrospective-phase.md`）の Improvement Drafts #1 として採用判定した。

retrospective スキルが Tech Notes セクションに古びない技術知見を蓄積する仕組みを提供したが、サブプロジェクトを跨いで知見を再利用するための横断検索・index 化のメカニズムは未整備である。本サイクルだけでも 3 件の Tech Notes が追加されたが、これが 10 件、50 件と増えたとき、新規サブプロジェクト着手時に過去知見を網羅的に参照することは事実上不可能になる。

## Considered Alternatives

1. **何もしない（保留継続）**: Tech Notes は retrospective ファイル内に分散したまま。検索性は grep 依存で、サブプロジェクト数の増加に伴い線形劣化する。
2. **既存 retrospective スキルを拡張**: Phase 5 ハンドオフ更新の際に Tech Notes を `docs/knowledge/` へ自動転記する。スキル責務が肥大化し、関心の分離（原則2）に反する。
3. **新スキル `knowledge-distillation` を新設**（本案）: retrospective とは独立したスキルとして、`docs/retrospectives/` を入力に Tech Notes を集約・分類・index 化し `docs/knowledge/` 配下に出力する。retrospective スキルの Phase 5 末尾で呼び出しゲートを置く。

## Decision

選択肢3を採用する。理由:

- 知識抽出と振り返りは責務が異なる（振り返り = 1サイクルの観察、抽出 = 横断的な再利用パターン化）ため、独立スキルが原則2に整合する
- retrospective スキルを単純なまま保てる（テンプレ簡略化提案 #4 とも矛盾しない）
- `docs/knowledge/` は ADR-0008 のスナップショット規約と ADR-0011 の追記型規約のどちらに位置付けるか別途決定する必要があり、その決定をスキル新設時に明文化できる

実装は別セッションで `start-work` から brainstorming → spec → plan → 実装 のフルサイクルで進める。

## Consequences

- ＋ Tech Notes の横断再利用が可能になり、新規サブプロジェクト開始時のコンテキスト構築コストが下がる
- ＋ 「やらない決定」(ADR-0012) を「次サイクルでやる決定」へ正規に昇格させる流れが ADR チェーンとして追跡可能
- − 新スキル分のメンテナンスコストが増える
- − `docs/knowledge/` の保管規約を別途決める必要がある（新規 ADR が派生する可能性）
- **不採用（2026-07-07、初回台帳監査にて）**: 本 ADR を生んだ「retrospective 中の採否判断・即時 ADR 化」プロセスが ADR-0021 で廃止され、情報分類体系も ADR-0025 で刷新されたため、本設計（`docs/knowledge/` 等）をそのまま実装する前提が失われた。テーマ（知見の横断再利用）自体は Issue-0021 として課題に再起票し、着手時は現行フロー（brainstorming 起点）で設計し直す
