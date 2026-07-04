# ADR-0021: retrospective を課題抽出に限定し、出力を system/flow に分割

- **Status**: Accepted
- **Date**: 2026-06-15

## Context

`retrospective` スキル（ADR-0010 で導入）の運用で3つの問題が観察された。

1. **対策まで決めようとする**: 振り返り中に AI が課題を挙げるだけでなく、その対策（改善提案の具体設計）と採否判断、即時 ADR ドラフト化（Phase 4）まで踏み込んだ。対策を決めるのは次の作業サイクルであるべきで、振り返りは振り返りと課題抽出にとどめたい。
2. **Tech Notes のスコープ逸脱**: 「古びない技術知見」に開発対象システムの仕様（ドメイン知識）を挙げてしまう。システム仕様は当該システムの仕様書に記載されるべきで、retrospective の Tech Notes に含めるべきではない（ADR-0012 で C 範囲外と決定済みの境界の明文化）。
3. **フロー課題の宛先誤り**: 開発フロー/ガイドラインに関する課題を、開発対象システムの改善提案として記録してしまう。retrospective はプラグインとして個別システム開発repoでも動くため、そこで挙がった開発フロー課題は本来このメタ・ガイドラインrepo（ai-driven-dev-principles）へ申し送られるべきで、対象システムrepoの改善として埋もれてはならない。

## Considered Alternatives

- **(a) スコープの縮小度合い**: ① 課題抽出のみ（提案・採否・ADR を全て次サイクルへ）/ ② 改善の方向性までは記録し対策設計と ADR は次サイクルへ / ③ 採否判断は残し対策設計だけ次サイクルへ。→ **① を採用**。フィードバックの「振り返りと課題を挙げるところまでにとどめる」に最も忠実。
- **(a) 課題の扱い**: 「必ず次サイクルで対策」vs「バックログ記録のみ・着手はユーザー判断」。→ **後者を採用**。対策の要否・着手時期もユーザーの判断対象とする。
- **(c) フロー課題の集約先**: ① 専用の単一蓄積ファイル `flow-feedback.md` / ② retrospective ファイル内の別セクション / ③ `system/` `flow/` の2フォルダに per-cycle で分割。→ **③ を採用**。①は ADR-0011 の per-cycle・上書き禁止モデルと不整合。②は一覧性が低い。③はシステム固有とフロー課題でファイル名を対称に保て、ADR-0011 の不変モデルとも整合する。
- **(b) Tech Notes**: 除外を明記するのみ / 除外に加え「宛先（システム仕様書）」もガイドする。→ **除外を明記**（宛先誘導は過剰、YAGNI）。

## Decision

1. **retrospective のスコープを「課題の抽出と分類」に限定する**。改善提案の具体設計・採否判断（採用/保留/却下）・即時 ADR ドラフト化（ADR-0010 の Phase 4）を撤去する。
2. **抽出した課題はバックログとして記録するのみ**とする。対策の要否・着手時期はユーザーの判断に委ねる（必ず次サイクルで着手するわけではない）。ユーザーが対策を要すると判断した時点で、その課題を起点に通常フロー（`start-work` →（規模に応じ brainstorming）→ 対策決定で ADR 起票）を開始する。
3. **課題を「対象システム固有」「開発フロー/ガイドライン関連」に分類する**。
4. **出力を2フォルダに分割する**:
   - `docs/retrospectives/system/YYYY-MM-DD-<topic>.md` — メイン振り返り記録（対象システム固有の課題を含む）
   - `docs/retrospectives/flow/YYYY-MM-DD-<topic>.md` — そのサイクルで抽出した開発フロー/ガイドライン課題
   - 同一サイクルは両フォルダで同名ファイル。`flow/` フォルダ全体が、配布先repoではガイドラインrepoへの申し送りバックログになる。両ファイルとも per-cycle・上書き禁止（ADR-0011 を踏襲、配置パスのみ本 ADR で改定）。
5. **Tech Notes はフロー非依存の汎用技術知見に限定する**。開発対象システムの仕様・ドメイン知識は除外する（それは当該システムの仕様書へ。ADR-0012 準拠）。

本決定は ADR-0010（retrospective の Phase 構造、特に Phase 4）と ADR-0011（保管パス構造）を一部改定する。両 ADR は全面 Superseded ではなく、該当部分のみ本 ADR で上書きする。

## Consequences

- **良い影響**: 振り返りが「抽出と分類」に純化され、対策の早すぎる決定が避けられる。フロー課題が `flow/` に集約され、配布先repoからガイドラインrepoへの申し送りが容易になる。Tech Notes が汎用知見に純化される。
- **コスト・悪い影響**: 出力フォルダが2つになり、retrospective ファイルのパスが変わる。過去の retrospective ファイル（旧フラット配置）は移動せず、`README.md` で旧配置と注記する。`decision-log` の検出トリガーから「retrospective で採用した改善提案」が除かれる。
- 波及更新: `skills/retrospective/SKILL.md` / `template.md`（+ `flow-template.md` 新設）/ `docs/retrospectives/README.md` / `CONTRIBUTING.md`（retrospective変更シナリオ・課題対策シナリオ）/ `skills/decision-log/SKILL.md` / `skills/start-work/SKILL.md` / `README.md` / `.github/copilot-instructions.md`。template対象ファイルは `scripts/sync-template.ps1` で同期する。

## Related

- ADR-0010: 振り返りフェーズ導入（本 ADR で Phase 4 を撤去）
- ADR-0011: 振り返り出力の保管規約（本 ADR で配置パスを2フォルダ化）
- ADR-0012: ドメイン知識抽出は次サイクル課題（Tech Notes 除外の根拠）
- ADR-0006: 意思決定の継続検出ルール
- ADR-0019: ADR記述規律（Proposed 作成 → 確定チェックポイントで Accepted 昇格）
