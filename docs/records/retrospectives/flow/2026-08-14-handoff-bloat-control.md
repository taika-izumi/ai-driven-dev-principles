# Flow Feedback: handoff 肥大化制御

開発フロー/ガイドラインに関する課題の記録。配布先システム開発repoでは、このファイルがガイドラインrepo（ai-driven-dev-principles）への申し送りバックログになる。

- **Subject**: handoff 肥大化制御（Issue-0078〜0081 対策）
- **Period**: 2026-08-13 〜 2026-08-14
- **対応する system 振り返り**: [system/2026-08-14-handoff-bloat-control.md](../system/2026-08-14-handoff-bloat-control.md)
- **Facilitator**: メインエージェント (claude-fable-5)

> 起票する各フロー課題には振り分け判定（delta 型・早期対処 / 構造観察型。ADR-0056）を1行記載する。delta 型で急がない候補は起票せず worklog へ記録する（本ファイルには載せない）。

## 開発フロー/ガイドライン課題

各課題は抽出と分類までにとどめる。**対策の設計・採否判断・ADR 化は行わない**（次サイクルでユーザーが対策要と判断した時点で着手。ADR-0021）。

- **課題 #1**: マージ方式の規範（--no-ff）が完了フローに配線されておらず、fast-forward でマージされた
  - **事象**: retrospective スキルは「feature ブランチを master へ `--no-ff` マージし」た直後の実施を前提と記すが、本サイクルの完了処理は `superpowers:finishing-a-development-branch` の手順（プレーンな `git merge`）で実行され、fast-forward マージとなりマージコミットが存在しない。振り返り一覧（`docs/records/retrospectives/README.md`）の過去サイクルはすべて merge SHA を記録している
  - **原因**: マージ方式の規範が retrospective スキルの前提文にしか書かれておらず、実際にマージを実行する完了フロー（finishing-a-development-branch、または CLAUDE.md の完了処理規範）に配線されていない。実行時に fast-forward を検出・阻止する仕組みもない
  - **影響**: サイクル境界が git 履歴上で見えにくくなる（`git log --merges` でサイクルを辿れない）。振り返り一覧の merge SHA 記録慣行が崩れる（本サイクルは先端 `9259eec` を代替記録）
  - **なぜフロー課題か**: 対象成果物の欠陥ではなく、規範の置き場所と実行フローの配線の問題（規範がスキル A の前提文にあり、実行はスキル B が担う構造）
  - **振り分け判定**: 構造観察型（作業時点の delta として表現できず、規範体系の俯瞰で見える配線欠落）
  - **関連**: `skills/retrospective/SKILL.md`「いつ使うか」、`superpowers:finishing-a-development-branch`、CLAUDE.md「検証」節のマージ後 retrospective 規範
  - **起票**: Issue-0084（`../../working/issues/flow/0084-merge-mode-norm-not-wired-into-finishing-flow.md`）
