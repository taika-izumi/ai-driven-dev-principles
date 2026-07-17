# Flow Feedback: 3スキルパイプライン（作業記録→候補抽出→スキル化）

開発フロー/ガイドラインに関する課題の記録。配布先システム開発repoでは、このファイルがガイドラインrepo（ai-driven-dev-principles）への申し送りバックログになる。

- **Subject**: 対話モードのガイドライン拡張として3スキル（worklog-record / worklog-extract / worklog-skillify）を新規追加
- **Period**: 2026-07-16 〜 2026-07-17
- **対応する system 振り返り**: [system/2026-07-17-worklog-skill-pipeline.md](../system/2026-07-17-worklog-skill-pipeline.md)
- **Facilitator**: メインエージェント (Claude Opus 4.7)

## 開発フロー/ガイドライン課題

各課題は抽出と分類までにとどめる。**対策の設計・採否判断・ADR 化は行わない**（次サイクルでユーザーが対策要と判断した時点で着手。ADR-0021）。

- **課題 #1**: worklog-record の記録件数規範と複数 delta 候補時の優先順位付けが未明示
  - **事象**: worklog-record スモークテスト実施時、本セッションの delta 候補が複数（ADR 追補判断・grep 検証整合順序・プラグイン availability 経路差など）あり、記録する 1 件を絞る判断に一瞬迷った
  - **原因**: `skills/worklog-record/SKILL.md` および `docs/current/specs/2026-07-17-worklog-skill-pipeline/02-skill1-record.md` は「1 件記録」を前提と読める記述だが、明示的な「1 件のみ」or「複数記録可」規範がなく、複数 delta 候補時の優先順位付けも未明示
  - **影響**: 実運用開始で節目ごとに複数 delta が発生し、毎回この判断が必要になる。記録の粒度がブレると、後段の `worklog-extract` のクラスタリング入力の粒度が揃わず、抽出精度に影響する可能性
  - **なぜフロー課題か**: worklog-* スキルは開発フロー支援ツール（AI 作業ノウハウの継続捕捉）であり、スキル doc/spec の記述規範に関する欠落は開発フロー/ガイドラインの課題として分類する
  - **関連**: `skills/worklog-record/SKILL.md`、spec 02-skill1-record.md、ADR-0044、ADR-0045
  - **起票**: Issue-0023（`../../../working/issues/flow/0023-worklog-record-entry-count-and-priority-norm.md`）

- **課題 #2**: プラグイン更新後の新規スキル availability 確認手順が start-work Phase -1 に未組み込み
  - **事象**: 本サイクルでプラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）を実施した後、Claude Code の `/skills` UI 一覧には本セッション内で新規追加スキル（`worklog-*` 3 スキル）が反映されなかったが、AI エージェント側の Skill ツール availability（system-reminder に含まれる available-skills 一覧）にはセッション内で反映済みだった
  - **原因**: 現行 `start-work` の Phase -1（依存検出）は superpowers スキルの有無を確認するが、「本セッションで新規追加された ai-driven-dev-principles スキルの availability 判定手順」は明示されていない。私は最初「UI /skills 表示の有無」でユーザーに確認依頼したが、system-reminder の available-skills を先に見れば一往復のやりとりを省けた
  - **影響**: プラグイン更新→スキル追加のたびに、ユーザー確認往復が発生する運用オーバーヘッドが積み上がる。Tech Notes に「AI 側 availability で判定する」を残したが、`start-work` Phase -1 に組み込めばより堅牢
  - **なぜフロー課題か**: `start-work` スキル（開発ワークフローの起点）の Phase -1 依存検出の記述に関する欠落で、開発フローの標準運用に組み込むべき手順の課題
  - **関連**: `skills/start-work/SKILL.md`（Phase -1 依存検出）、ADR-0047
  - **起票**: Issue-0024（`../../../working/issues/flow/0024-plugin-skill-availability-check-in-start-work.md`）
