# Flow Feedback: ADR 粒度・文章量の規範整備

開発フロー/ガイドラインに関する課題の記録。配布先システム開発repoでは、このファイルがガイドラインrepo（ai-driven-dev-principles）への申し送りバックログになる。

- **Subject**: ADR 粒度・文章量の規範整備（Issue-0022 対処）
- **Period**: 2026-08-03 〜 2026-08-04
- **対応する system 振り返り**: [system/2026-08-04-adr-granularity-norms.md](../system/2026-08-04-adr-granularity-norms.md)
- **Facilitator**: メインエージェント (Claude Opus 5)

> 起票する各フロー課題には振り分け判定（delta 型・早期対処 / 構造観察型。ADR-0056）を1行記載する。delta 型で急がない候補は起票せず worklog へ記録する（本ファイルには載せない）。

## 開発フロー/ガイドライン課題

各課題は抽出と分類までにとどめる。**対策の設計・採否判断・ADR 化は行わない**（次サイクルでユーザーが対策要と判断した時点で着手。ADR-0021）。

- **課題 #1**: `CONTRIBUTING.md` のテンプレート同期指示が現行のテンプレート構成と矛盾している
  - **事象**: 「start-work を変更するとき」「feature-block-design を変更するとき」「retrospective を変更するとき」の各シナリオの手順に「テンプレート対象なので `scripts/sync-template.ps1` を実行する」とあるが、`template.manifest` の対象は `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` の4件のみで、skills は ADR-0016 により除外されている。スキルを改定しても同期は不要
  - **原因**: ADR-0016（template ワークフローの再設計・プラグイン一本化）で skills を manifest から除外した際、CONTRIBUTING.md 側の各シナリオ手順が追従しなかった
  - **影響**: 手順書どおりに実行すると不要な同期が走る（実害自体は軽微）。本サイクルでも同期要否の判断を手順書ではなく `template.manifest` の直接確認で行う必要があり、手順書の記述が判断材料として使えなかった。同種の追従漏れが他シナリオにも潜在する可能性がある
  - **なぜフロー課題か**: 対象システム固有の成果物ではなく、ガイドライン拡張の手順書（CONTRIBUTING.md）自体の記述が現行構成と食い違っている問題であるため
  - **振り分け判定**: **構造観察型**（実行前に manifest を確認したため躓きとして顕在化せず、delta として表現しにくい。手順書と構成の突合で初めて見える不整合）
  - **関連**: `CONTRIBUTING.md`（3シナリオの手順）、`template.manifest`、ADR-0016（skills を template から除外）、ADR-0015（プラグイン配布）
  - **起票**: Issue-0040（`../../../working/issues/flow/0040-contributing-template-sync-instruction-stale.md`）

## worklog 送りとした候補（起票なし）

ADR-0056 の振り分け規則により、以下は issue 起票せず worklog パイプラインへ委ねた。

- **配布物の設計判断を自リポジトリの実測だけで行いかけた**: 「後から ADR を分割するコスト」を本 repo の実測（分割が軽い）のみで評価して推奨を切り替え、ユーザーの指摘で配布先 LoopForAlpha を実測したところ結論が覆った（推奨の変更2回）。delta 型で急を要さないため、中央ストア `MakeAiInstructions-2026-08-04-01`（skillification_hint 付き）に記録済み。仕組み化の要否は worklog-extract の再発裏付けに委ねる
