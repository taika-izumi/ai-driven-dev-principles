# Handoff: Post ラッパー消化漏れの検出不能性（Issue-0037）への対処

- **Branch**: feature/worklog-record-firing-reliability
- **Last Updated**: 2026-08-02 23:46 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 実装完了（ADR-0057/0058 Accepted・Issue-0037 close）→ master への merge 待ち

## 作業の目的・背景

Issue-0037（start-work Post ラッパーの worklog-record 発火）への対処サイクル。

着手前に「何が問題なのか」の実データ確認を行った結果、**起票時の事象認識と原因分析がいずれも誤りであることが判明**した。中央ストアと git 履歴の実測により、Post ラッパーは LoopForAlpha で 14 日間に約 89 回成立しており、「delegate 先から呼び出し元へ戻る契機を持たない」という構造的到達不能の分析は否定された。

真の問題は **Post ラッパーの消化が確率的で、消化しなかったことを検出できない**こと。`session-handoff` update は漏れればファイル履歴に空白が残るが、`worklog-record` は「発火しなかった」場合と「発火して記録ゲートが弾いた」場合が外形的に区別できず、漏れが検出されない。

観測された失敗モードは3種類（部分消化 / 完全未入場 / 発火契機の定義漏れ）。うち2種類は利用者の口頭指摘で初めて復旧しており、現状の記録信頼性は人間が漏れに気づくことに依存している。

## 関連ドキュメント

- 課題（正）: `docs/working/issues/flow/0037-worklog-record-post-wrapper-not-firing.md`（2026-08-01 に全面書き換え）
- 起票元（反証済み・上書き禁止）: `docs/records/retrospectives/flow/2026-07-31-retrospective-mode-review.md` 課題#1
- 関連 ADR: ADR-0047（Post ラッパーへの配線）、ADR-0044（記録ゲート）、ADR-0011（記録の上書き禁止）、ADR-0031（再発・進展の一次記録は issue の検討状況）
- 関連スキル: `skills/start-work/SKILL.md`（Phase 2 横断的ラッパー Post）、`skills/worklog-record/SKILL.md`、`skills/session-handoff/SKILL.md`、`skills/retrospective/SKILL.md`（Phase 3 総ざらい＝事後の救済経路）
- 実測の根拠データ: 中央ストア `<home>/.ai-dev-worklog/`（LoopForAlpha 88 件 / MakeAiInstructions 9 件）、`LoopForAlpha-2026-07-22-08` / `-2026-07-19-07`

## 完了済みタスク

- [x] 実データ調査（中央ストアの件数内訳・日別分布、LoopForAlpha と本 repo の handoff コミット日別、handoff コミットメッセージの契機分析、LoopForAlpha 側の追加配線の有無確認）（2026-08-01）
- [x] Issue-0037 の全面書き換え（タイトル・課題内容・検討状況）とインデックス行の更新（2026-08-01）
- [x] 対策方針の決定: 案C（handoff 相乗り＋事後突合）採用。ADR-0057/0058 起票、既存仕様書3件を書き換え（2026-08-01〜02、コミット `1192239` `0b9bd12`）
- [x] 実装: スキル4件の SKILL.md 改定（session-handoff `6c8b3c1` / start-work `e6df0ff` / retrospective `993d96a` / worklog-record `38f8f55`）。全 grep 検証パス・手順連番の実体確認済み（2026-08-02）
- [x] ADR-0057/0058 を Accepted へ昇格・Issue-0037 を close（2026-08-02）

## 進行中のタスク

- [ ] **現在の作業**: master への merge
  - 状態: 実装・検証・ADR 昇格・issue close まで完了
  - 残り: finishing-a-development-branch で merge → retrospective（突合手順の初回適用）

## 未着手のタスク

- [ ] master へ merge → retrospective（新形式＋突合手順のドッグフーディング2周目）

## 既知のブロッカー・懸念

- **プラグイン未更新（要対応）**: 前サイクルで `skills/retrospective/` を改定したが、リモート操作セッションのため `/plugin marketplace update ai-driven-dev-principles` が未実行。**ローカル操作である本セッションで実行を依頼済み（実行確認は未取得）**。実行までロードされる retrospective スキル本文は旧版
- **規約上の緊張（未処理）**: `docs/overview/folder-structure.md` 7.2 は「振り返り由来の課題は事象/原因/影響の詳細は起票元の振り返りファイルを正とする」と定めるが、その振り返りファイルは ADR-0011 で上書き禁止。今回のように起票元の分析が後日反証された場合の更新経路が未定義。暫定的に issue 側を正へ昇格させ、起票元行に反証の注記を置いて処理した。**Issue-0038（retrospective Phase 3 の知見を記録へ反映する経路がない）と同型**であり、起票の要否はユーザー判断待ち
- 07-31 サイクルが失敗モード2 になった環境要因（リモート操作）は1サンプルの仮説どまり
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` は本セッションで確認済み（ADR-0036）

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。

- 2026-08-01 課題定義の書き換え完了: ADR=なし（実データによる事実訂正のため。ADR-0031 に従い issue 側へ一次記録） / worklog=`MakeAiInstructions-2026-08-01-01`
- 2026-08-01 対策方針の決定（設計承認）: ADR=0057・0058 起票（Proposed） / worklog=棄却（方針決定自体に delta なし。調査時の delta は 2026-08-01-01 で記録済み）
- 2026-08-02 実装完了（スキル4件改定・検証パス）: ADR=0057・0058 を Accepted へ昇格（新規候補なし。計画どおりの実装のため） / worklog=棄却（計画の実文どおりに完遂し friction・corrections ともなし）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ファイル、`docs/working/issues/flow/0037-worklog-record-post-wrapper-not-firing.md`
2. 最初に実行すべきスキル: `superpowers:brainstorming`（対策方針の検討。入力は Issue-0037 の失敗モード3種）
3. 留意点:
   - 起票元の振り返りファイルは**編集しない**（ADR-0011）
   - `skills/` を編集したらプラグイン更新まで反映されない（ADR-0055）
   - コミットのマルチライン文字列は `git commit -F <file>`（Issue-0015）

## 重要な意思決定の履歴

- ADR-0057: Post ラッパーの消化結果を handoff に残し、未入場は事後突合で回収する（2026-08-01, **Accepted**）
- ADR-0058: worklog-record の発火契機にセッション切り替え直前を追加する（2026-08-01, **Accepted**）
- 課題定義の書き換え（Issue-0037）は事実訂正として issue の「検討状況」に一次記録した（ADR-0031 / folder-structure 7.3）
