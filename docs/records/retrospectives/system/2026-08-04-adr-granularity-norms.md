# Retrospective: ADR 粒度・文章量の規範整備

- **Subject**: ADR 粒度・文章量の規範整備（Issue-0022 対処）
- **Branch**: feature/adr-granularity-and-size（merge済み: `9a3f70e`）
- **Period**: 2026-08-03 〜 2026-08-04
- **Plan**: docs/working/plans/2026-08-04-adr-granularity-norms.md
- **Spec**: docs/current/specs/2026-04-25-record-strengthening-design.md（§5.3.1 / §7.4 を改定）
- **Related ADRs**: ADR-0059, ADR-0060
- **Facilitator**: メインエージェント (Claude Opus 5)

## 1. 達成サマリ

- 着手時に実データを取得し、Issue-0022 の3論点（粒度の確認観点 / Proposed への追記継続による主題ドリフト / 文章量の上限目安）をすべて決着させた
- **ADR-0059**: 粒度の単位を「後から探しに来るときの問い」1つと定め、**文章量は基準にしないことを明示的に決定**した。文章量の棄却は実測が根拠 — 肥大 ADR 5,545文字に対し分割後4本の合計は 13,918文字（約2.5倍）へ増え、かつ LoopForAlpha には肥大 ADR より大きい正常な ADR が複数ある（最大 7,558文字）ため、閾値は見逃しと誤検出を同時に生む（`9ec6682`）
- **ADR-0060**: 点検契機を「決定の追記時（一次経路）＋ Accepted 昇格前（受け皿）」と定め、いずれも既存操作に内包させて Post ラッパーの消化項目を増やさない構成とした。規範の置き場所は `decision-log` に一本化し、`start-work` は参照のみ（`9ec6682`）
- 実装は `decision-log` 3箇所（`aa5b686` / `94ff0a9` / `4bfca43`）、`start-work` 1文（`f5bdb8e`）、仕様書 §5.3.1・§7.4（`2f0520c`）。受入チェック5項目はマージ後の master でも期待値どおり
- ADR-0059/0060 を Accepted へ昇格し Issue-0022 を close（`f76b13b`）。昇格前には新規範の粒度点検を自分自身へ適用し、両件とも分割不要と判定した（ADR-0060 の決定3の帰属は境界例として判断を明示）
- 設計の根拠は配布先 LoopForAlpha の実測。ADR-0034 の肥大（決定9件 → 4本へ分割、`6ea5d48`）で被参照ファイルは分割時10 → 昇格時24 → 2週間後40と拡大し、決定序数参照275回の振り直しを伴った

## 2. 課題（対象システム固有）

課題の抽出と分類まで（対策の設計・採否判断・ADR化は次サイクル。ADR-0021）。

本サイクルでは対象システム固有の新規課題は抽出されなかった。

> 開発フロー課題 1 件は [flow/2026-08-04-adr-granularity-norms.md](../flow/2026-08-04-adr-granularity-norms.md) 参照。worklog 送りとした delta 型候補 1 件（起票なし。ADR-0056 の振り分け規則）。

## 3. 既存課題の再発・進展

- Issue-0022: 本サイクルの対象。ADR-0059/0060 で決着し close（`f76b13b`）
- Issue-0008: 記録強化仕様（`2026-04-25-record-strengthening-design.md`）の §7.2 が現行 `decision-log` 本文より古い記述を保持し、§6.2 に旧パス `docs/handoff/` 表記が残存していることを再確認。前サイクルの前例に従い変更箇所のみ訂正し、全面訂正は本 issue の方針決定に委ねた旨を「検討状況」へ追記（ADR-0031）
