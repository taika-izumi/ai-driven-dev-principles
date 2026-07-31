# Flow Feedback: retrospective の役割再定義

開発フロー/ガイドラインに関する課題の記録。配布先システム開発repoでは、このファイルがガイドラインrepo（ai-driven-dev-principles）への申し送りバックログになる。

- **Subject**: retrospective スキルの役割再定義（課題抽出記録への純化）
- **Period**: 2026-07-31（単日）
- **対応する system 振り返り**: [system/2026-07-31-retrospective-mode-review.md](../system/2026-07-31-retrospective-mode-review.md)
- **Facilitator**: メインエージェント (claude-opus-5 / 一部 claude-fable-5)

> 起票する各フロー課題には振り分け判定（delta 型・早期対処 / 構造観察型。ADR-0056）を1行記載する。delta 型で急がない候補は起票せず worklog へ記録する（本ファイルには載せない）。

## 開発フロー/ガイドライン課題

各課題は抽出と分類までにとどめる。**対策の設計・採否判断・ADR 化は行わない**（次サイクルでユーザーが対策要と判断した時点で着手。ADR-0021）。

- **課題 #1**: start-work Post ラッパーの worklog-record 発火が実運用で起きない
  - **事象**: ADR-0047 が定める発火契機（スキル完了 / plan の1タスク完了 / 重要な分岐通過）が本サイクルで最低3回（brainstorming 完了・writing-plans 完了・executing-plans 完了）あったが、worklog-record の発火は 0 回だった。session-handoff update も同じ契機で未実施
  - **原因**: Post ラッパーの規定が `start-work` の SKILL.md にしか存在せず、他スキルへ delegate している間、メインエージェントが「start-work の Phase 2 Post に戻る」契機を持たない。delegate 先スキルは自身の終了条件（次スキルへの遷移）で完結するため、呼び出し元の横断的ラッパーが素通りされる
  - **影響**: サイクル中の delta が記録されず worklog-extract の材料が痩せる。本リポジトリ由来の中央ストアエントリは 6 件にとどまり、パイプラインの入口が実質機能していない
  - **なぜフロー課題か**: 特定システムの実装ではなく、スキル間の制御フロー（横断的ラッパーの実行保証）というガイドライン体系自体の構造問題であるため
  - **関連**: ADR-0047, ADR-0044, `skills/start-work/SKILL.md`, `skills/session-handoff/SKILL.md`, Issue-0036
  - **振り分け判定**: 構造観察型（ADR-0056）— 規範が実行されなかったという欠落であり、躓き・人間の指示として worklog に載せられない
  - **起票**: Issue-0037（`../../working/issues/flow/0037-worklog-record-post-wrapper-not-firing.md`）

- **課題 #2**: retrospective の Phase 3 で得た知見を記録へ反映する経路がない
  - **事象**: Phase 2 で記録ファイルを確定した後、Phase 3 の worklog 総ざらい中に Issue-0032 の再発（grep 系検出手段の誤判定、2例目）が判明したが、ADR-0011 の上書き禁止により記録へ反映する正規の経路がなかった。今回は「未コミットのドラフト」と解釈し ADR-0030 に準じて追記した
  - **原因**: 旧形式では Phase 3（rubber-duck）の結果を Phase 2 のドラフトへ反映する手順が明示されていたが、ADR-0056 で rubber-duck をオプション化した際に反映経路の記述が失われた。worklog 総ざらいが新事実を生みうることを設計時に考慮していなかった
  - **影響**: Phase 3 で得た知見が記録から落ちるか、規約外の運用（未定義の上書き）で処理される。新形式で retrospective を回すたびに再現する
  - **なぜフロー課題か**: retrospective スキル自体のフェーズ構成と記録規約（ADR-0011 / ADR-0030）の整合という、ガイドライン体系内部の構造問題であるため
  - **関連**: ADR-0056, ADR-0011, ADR-0030, `skills/retrospective/SKILL.md`
  - **振り分け判定**: 構造観察型（ADR-0056）— 新形式の初回適用で顕在化した設計の欠落であり、躓き・人間の指示として worklog に載せられない
  - **起票**: Issue-0038（`../../working/issues/flow/0038-retrospective-phase3-findings-no-path-to-record.md`）

## worklog へ送った delta 型候補（起票なし）

ADR-0056 の振り分け規則により、以下は issue 化せず worklog へ記録した（仕組み化の要否は worklog-extract の再発裏付けに委ねる）。

- 記録の要否を判断する際、「既存記録と重複するか」だけでなく「活用経路（読み手）が存在するか」も判定軸に加えること（ユーザーの corrections 由来）
