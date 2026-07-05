# Flow Feedback: 選択UI誤操作対策（Issue-0005 対策）

開発フロー/ガイドラインに関する課題の記録。配布先システム開発repoでは、このファイルがガイドラインrepo（ai-driven-dev-principles）への申し送りバックログになる。

- **Subject**: 選択UI誤操作対策 — 環境設定＋環境ベース2分岐規範への改定
- **Period**: 2026-07-05 〜 2026-07-05
- **対応する system 振り返り**: [system/2026-07-05-selection-ui-misclick-mitigation.md](../system/2026-07-05-selection-ui-misclick-mitigation.md)
- **Facilitator**: メインエージェント (Claude Fable 5)

## 開発フロー/ガイドライン課題

各課題は抽出と分類までにとどめる。**対策の設計・採否判断・ADR 化は行わない**（次サイクルでユーザーが対策要と判断した時点で着手。ADR-0021）。

- **課題 #1**: 対策検討の初手に「環境・ツール設定による構造的解決の調査」を促す観点がない
  - **事象**: Issue-0005 対策の brainstorming で、当初合意の方針（規範改定のみ）を所与として「重要判断」の定義の選択肢提示まで進み、ユーザーの深掘り提案（ツール・環境側で防げないか）で初めて環境変数（`CLAUDE_CODE_DISABLE_MOUSE_CLICKS`）による根本解決を調査した
  - **原因**: brainstorming・課題対策の手順に「規範・運用ルールで縛る前に、環境/ツール設定で構造的に塞げないか先に調べる」というチェック観点が定式化されていない
  - **影響**: 今回はユーザー指摘で好転したが、指摘がなければ複雑な規範（重要判断の定義）を導入し、より単純で根本的な解を見逃していた。規範の複雑化は配布先全プロジェクトの運用コストに波及する
  - **なぜフロー課題か**: 対象システムの欠陥ではなく、対策検討の進め方（brainstorming / 課題対策シナリオ）にチェック観点が欠けているというガイドラインの問題であるため
  - **関連**: CONTRIBUTING.md「振り返りで抽出された課題に対策するとき」、superpowers:brainstorming、ADR-0036（本事例）、原則5（漸進的検証）
  - **起票**: Issue-0017（`../../working/issues/flow/0017-environment-solution-survey-before-norms.md`）
