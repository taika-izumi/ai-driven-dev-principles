# Handoff: Issue-0013 対策サイクル完了・次サイクル待機

- **Branch**: master
- **Last Updated**: 2026-07-05 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: Issue-0013 対策サイクル完了（merge: afef02a、retrospective 実施済み・Issue-0015 起票）/ 次サイクル未着手

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

直近サイクルは「Issue-0013: plan のセルフレビューに検証手順と編集内容の整合を見る観点がない」の対策。`superpowers:writing-plans` は変更できないため、本 repo の運用規範として `CLAUDE.md`「検証」節に「実装計画作成時に各検証ステップの期待値（grep 件数・存在すべきファイル名・期待する出力など）と各タスクの編集内容の矛盾を突合する」観点を1項目追加（ADR-0034, Accepted）。template へ同期済み（LF 書き出し・1行のみのクリーン差分を検証）。小規模のため plan/spec ファイルは作らず ADR-0034 が設計記録を兼ねた。Issue-0013 は close。feature ブランチは merge 後削除済み。

retrospective で rubber-duck 指摘を受け、コミットメッセージへの `@` 混入（PowerShell 形式 here-string `@'...'@` を POSIX sh の Bash ツールで使ったのが原因）を Tech Notes 止まりにせず **Issue-0015（flow）として起票**（対策採否の暗黙判断を避け全件起票の原則に沿う。ADR-0028）。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open 7件 / closed 8件）
- 直近サイクルの ADR: ADR-0034（Accepted）
- 直近サイクルの retrospective: `docs/records/retrospectives/system/2026-07-05-plan-verification-consistency-check.md` および `flow/2026-07-05-plan-verification-consistency-check.md`（Issue-0015 抽出）
- 課題管理の規約: `docs/overview/folder-structure.md` §7
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0034）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] **Issue-0013 対策サイクル**: plan 検証整合規範を `CLAUDE.md`「検証」節へ追加（ADR-0034）。merge `afef02a`、Issue-0013 close、差分検証済み（1行・LF）、retrospective 実施済み（フロー課題1件を Issue-0015 として起票、Issue-0012 再発を検討状況へ追記）（2026-07-05）
- [x] **Issue-0002 対策サイクル**: sync-template.ps1 の LF 固定書き出し（ADR-0033）。merge `d9329d8`、Issue-0002 close、赤緑検証済み（PS 5.1/7）、retrospective 実施済み（Issue-0014 起票）（2026-07-05）
- [x] **記録プロセス規範一括対策サイクル**: Issue-0009/0010/0011 を ADR-0030/0031/0032 として規範化・実装。merge `71d383c`（2026-07-05）
- [x] **Issue-0004 対策サイクル**: 質問ツール表示特性への対処規範（ADR-0029）。merge `18e0c85`（2026-07-05）

## 進行中のタスク

なし（Issue-0013 対策サイクルは retrospective・handoff update まで完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化済み（open 7件）。前サイクルの優先順位付けを踏襲し、Issue-0013 close・Issue-0015 追加を反映した目安:

1. [ ] **Issue-0012**（flow）: 質問ツールタイムアウト時の自走基準がない — **最優先を推奨**。merge 等の不可逆な節目操作がユーザー不在時に確認なしで実行されうる構造的リスク。**Issue-0013 サイクルでも再発**（検討状況へ追記済み）。再発実績が積み上がっており、全サイクルの安全性に関わるため他の作業より先に規範を固める価値が高い
2. [ ] **Issue-0014**（system）: .gitattributes 未導入で改行正規化が各自の core.autocrlf 任せ — **2番手（即効の小規模対策）を推奨**。`.gitattributes` 追加 + 一度の `git add --renormalize .` で解消でき数分規模。ADR-0033 の残存リスクを塞ぎ改行問題を完全終息できる
3. [ ] **Issue-0005 / 0006**（flow）: 選択UIの誤操作の即確定 / 横断変更の計画網羅漏れ — 3番手。0005 は Issue-0012 と論点隣接のため 0012 設計時に併せて扱えるか検討。0006 は今回対策した Issue-0013（整合性）の隣接軸（網羅性）
4. [ ] **Issue-0003**（system）: conversation_log.md の分類 / **Issue-0008**（system）: 旧型式 spec 8本の維持方針 — 4番手。どちらもユーザーの方針決めが主
5. [ ] **Issue-0015**（flow）: マルチライン文字列をツールのシェル種別に合わせる規範・チェックがない — **低優先**。実害は軽微（即 amend で修正可能）。commit -F 徹底などの軽微な規範追加で対応可能だが緊急性は低い
6. [ ] **Theme C 問題A**「プロジェクト固有用語集（ユビキタス言語）の仕組み」: 大テーマ（課題ではなく作業テーマのため issues 対象外）。規模が大きく brainstorming からの本格サイクルが必要。小粒課題を掃除してから着手する方が集中できる
7. [ ] **ADR-0013 / 0014 / 0018 の Proposed 据え置き解消**: 最後尾。どこかのサイクルの Post チェックで昇格/棚卸しの判断だけ済ませると台帳が締まる

## 既知のブロッカー・懸念

- AskUserQuestion の無応答タイムアウト（約60秒で自走指示）: Issue-0012 として起票済み（未対策）。**Issue-0013 サイクルで再発**し、可逆作業のみ best judgment で進め不可逆な merge 手前で停止する運用で凌いだが、基準は未定義のまま
- ADR-0023 の留意点（継続）: GitHub.com の Copilot コーディングエージェント（CLI 以外）がルート `CLAUDE.md` を読まない可能性
- `docs/conversation_log.md` は untracked のまま docs/ 直下に残置（Issue-0003。ユーザー判断待ち）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **最初に確認すべきファイル**: 本ファイル、`docs/working/issues/README.md`
3. **次に走らせる作業（候補）**: 「未着手のタスク」の優先順位付け（1: Issue-0012 → 2: Issue-0014 → …）を参考にユーザーが選択（着手はユーザー判断。必ず次サイクルではない）。今サイクルで抽出した Issue-0015 は低優先
4. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行（ADR-0033 により改行のみ差分は解消済み）
   - skills/ を編集したらプラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）まで反映されない
   - **コミットメッセージ等のマルチライン文字列は、利用ツールのシェル種別に合わせる**（Bash ツール=POSIX sh では PowerShell here-string `@'...'@` が使えない。`git commit -F <file>` が確実。Issue-0015）
   - ADR-0019（決定のみ・遅延昇格）、ADR-0021（retrospective は課題抽出のみ）、ADR-0022（説明的な用語）、ADR-0024（選択肢＋推奨）、ADR-0028（課題の全件起票）、ADR-0029（質問の自己完結）、ADR-0030（ADR コミットは収束チェックポイント）、ADR-0031（再発は検討状況へ追記）、ADR-0032（判定条件は観測可能な事実）、ADR-0034（plan 検証整合の突合）を守る

## 重要な意思決定の履歴

- ADR-0034: 実装計画の検証ステップ期待値と編集内容の整合を確認する規範を追加（2026-07-05, Accepted）
- ADR-0033: sync-template.ps1 の生成ファイルは LF 改行で書き出す（2026-07-05, Accepted）
- ADR-0030/0031/0032: 記録プロセス規範一括対策（2026-07-05, Accepted）
- ADR-0029: 質問ツールの表示特性への対処規範をモデル条件付きで追加（2026-07-05, Accepted）
- ADR-0028: 振り返り課題を issue 管理へ全件起票し、issues を system/flow フォルダに分割する（2026-07-05, Accepted）
- （ADR-0001〜0027 は `docs/records/decisions/README.md` 参照）
