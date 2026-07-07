# Handoff: Issue-0019 対策（コミット済み Proposed ADR の不採用経路の定義 + Proposed 据え置き解消）

- **Branch**: feature/adr-rejected-status-path
- **Last Updated**: 2026-07-07 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 課題対策サイクル / 実装完了（plan 全6タスク完了、ADR-0041/0042 Accepted、Issue-0019 closed）→ master へのマージ待ち

## 作業の目的・背景

Issue-0019 への対策サイクル。`decision-log` スキルには Accepted 後の破棄・置換手順（Deprecated / Superseded）はあるが、**コミット済みの Proposed ADR を「不採用」で終える経路（Rejected 相当）が未定義**。現行の「却下」手順はファイル削除を指示しており、コミット済み ADR に適用すると追跡可能性（原則1）と矛盾する。また `start-work` の Post チェックは Proposed の昇格漏れのみを見ており、不採用方向の見直しを促すトリガーがない。

あわせて、据え置き中の Proposed ADR 3件（ADR-0013 / 0014 / 0018）の棚卸しを行う。事前確認（2026-07-07）で3件とも**未実装**であることを確認済み:

- ADR-0013（knowledge-distillation スキル新設）: スキル未作成
- ADR-0014（親ディレクトリ存在の先行確認規範）: CLAUDE.md に規範なし
- ADR-0018（中規模以上の brainstorming 必須化）: CLAUDE.md に規範なし（feature-block-design の閾値記述はあるが brainstorming 必須化はない）

## 関連ドキュメント

- 対象課題: `docs/working/issues/flow/0019-adr-rejected-status-path.md`
- 対策手順の規約: `CONTRIBUTING.md`「振り返りで抽出された課題に対策するとき」
- 変更対象候補: `skills/decision-log/SKILL.md`（ステータス手順）、`skills/start-work/SKILL.md`（Post チェック）、`CONTRIBUTING.md`（ADR 記録シナリオ）
- 関連 ADR: ADR-0019（記述規律）、ADR-0030（コミット遅延）、ADR-0032（観測可能な判定条件）、ADR-0039（環境解決の先行調査）

## 完了済みタスク

- [x] feature ブランチ作成、課題・関連ドキュメント・据え置き ADR 3件の現状確認（2026-07-07）
- [x] brainstorming: 案A（ドキュメント定義のみ）で設計承認。棚卸しは台帳全40件へ拡張、置換対象特定は変更箇所起点の2経路（変更ファイルの ADR 引用＋インデックスのタイトル走査）、台帳監査のトリガーはユーザー指示＋矛盾発見の2つに確定。ADR-0041 ドラフト作成・コミット（`0c62152`、Proposed。設計記録を兼ねる。spec なし）（2026-07-07）
- [x] ユーザーレビュー指摘「Decision が長すぎる・1ADRで正しいか」を受け、1決定=1ADR に分割: ADR-0041（Rejected 経路の定義）＋ ADR-0042（Superseded の変更箇所起点特定と台帳監査）。本サイクル実施項目は ADR から除き plan 管理へ（`0925e04`）（2026-07-07）
- [x] plan 作成（`afcacc1`）と全6タスクの実装完了（2026-07-07）:
  - Task 1: decision-log に終端ステータス意味境界表・Rejected 手順・却下分岐分割・置換対象特定ステップを追加（`1ede0f9`、grep 検証 6/2/1/0 一致）
  - Task 2: start-work の Post チェックとセッション終了処理を不採用方向へ対称化（`f59b972`、grep 検証 2/2 一致）
  - Task 3: CONTRIBUTING.md に台帳監査小節を追加（`accf4fa`、grep 検証 1/1 一致）
  - Task 4: 初回台帳監査 全40件（`622f094`）: 実質置換・廃止 0件、部分修正注記 7件追加（0001/0003/0005/0008/0016/0019/0024。先例 0010/0011/0015 と統一）、残り現役
  - Task 5: 据え置き Proposed 3件をすべて Rejected に確定（`d25a0c6`。Rejected 経路の初適用）。0013 のテーマは Issue-0021 として再起票
  - Task 6: Issue-0019 close、ADR-0041/0042 を Accepted へ昇格（`8a1bb93`）

## 進行中のタスク

なし（plan 全6タスク完了。次は master へのマージ → retrospective → handoff finalize）

## 未着手のタスク

- [ ] master へのマージ（finishing-a-development-branch）
- [ ] retrospective（merge 直後）、handoff finalize
- [ ] プラグイン更新（`/plugin marketplace update ai-driven-dev-principles`。ユーザー操作。skills/ 変更の反映に必要）

## 既知のブロッカー・懸念

- なし

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ファイル、`docs/working/issues/flow/0019-adr-rejected-status-path.md`
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）
3. 留意点: skills/ を編集したらプラグイン更新まで反映されない。CLAUDE.md 等を変更したら `scripts/sync-template.ps1` を実行

## 重要な意思決定の履歴

- （まだなし）
