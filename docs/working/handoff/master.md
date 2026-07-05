# Handoff: Issue-0012 対策サイクル完了・次サイクル待機

- **Branch**: master
- **Last Updated**: 2026-07-05 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: Issue-0012 対策サイクル完了（merge: a13e796、retrospective 実施済み）/ 次サイクル未着手

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

直近サイクルは「Issue-0012: 構造化質問ツールのタイムアウト時にエージェントがどこまで自走してよいかの基準がない」の対策。`CLAUDE.md`「ユーザーへの質問と意思決定要求」節と `docs/overview/principles.md` 原則4に「タイムアウト時は操作のリスク・可逆性を問わず一律で停止・待機する」規範を追加（ADR-0035, Accepted）。骨子は「構造化質問ツールを起動した＝人間の判断が必要とエージェント自身が判断した局面なので、回答が得られない以上リスクの大小を問わず前進しない」。停止時は破損しない区切りまで整えてから止め、待っている判断と再開に必要な回答を報告する。template 同期済み（追加のみ・改行差分なし）。小規模のため plan/spec は作らず ADR-0035 が設計記録を兼ねた。Issue-0012 は close。feature ブランチは merge 後削除済み。

本サイクルでは **Issue-0005（選択UIの誤操作が即「方針確定」として扱われる）の実例が実際に発生**（brainstorming の選択UI誤クリック）。テキスト運用への切替で実害は回避。Issue-0005 は解の性質が異なる（選択UIをやめてテキスト提示＝ADR-0024 の改定）ため本サイクルから分離し、次サイクルへ送った。対策方針の方向性（重要判断では選択UIをやめテキスト提示）はユーザーと合意済み。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open 7件 / closed 9件）
- 直近サイクルの ADR: ADR-0035（Accepted）
- 直近サイクルの retrospective: `docs/records/retrospectives/system/2026-07-05-question-tool-timeout-autonomy.md`（新規課題なし。Issue-0005 再発と Issue-0015 進展を検討状況へ追記。flow ファイルなし）
- 課題管理の規約: `docs/overview/folder-structure.md` §7
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0035）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] **Issue-0012 対策サイクル**: タイムアウト時の一律停止・待機規範を `CLAUDE.md` 質問節と原則4へ追加（ADR-0035）。merge `a13e796`、Issue-0012 close、差分検証済み（grep 各1件・template 追加のみ）、retrospective 実施済み（新規課題なし。Issue-0005 の実例再発を検討状況へ追記、Issue-0015 の回避策実践を進展として追記。rubber-duck 指摘#1 反映で対称化）（2026-07-05）
- [x] **Issue-0013 対策サイクル**: plan 検証整合規範を `CLAUDE.md`「検証」節へ追加（ADR-0034）。merge `afef02a`、Issue-0013 close（2026-07-05）
- [x] **Issue-0002 対策サイクル**: sync-template.ps1 の LF 固定書き出し（ADR-0033）。merge `d9329d8`、Issue-0002 close（2026-07-05）
- [x] **記録プロセス規範一括対策サイクル**: Issue-0009/0010/0011 を ADR-0030/0031/0032 として規範化・実装。merge `71d383c`（2026-07-05）

## 進行中のタスク

なし（Issue-0012 対策サイクルは retrospective・handoff update まで完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化済み（open 7件）。Issue-0012 close・Issue-0005 の候補昇格・Issue-0016 起票を反映した目安:

1. [ ] **Issue-0005**（flow）: 選択UIの誤操作が即「方針確定」として扱われる — **最優先を推奨**。**本サイクルで実例が実際に発生**し、対策方針の方向性（後戻りコストの高い重要判断では選択UIをやめ、選択肢＋推奨をテキスト提示する＝ADR-0024 の改定を伴う）もユーザーと合意済み。着手準備が整っており効果も直接的。ただし ADR-0024（Accepted）の改定を伴うため独立サイクルで腰を据える価値がある
2. [ ] **Issue-0014**（system）: .gitattributes 未導入で改行正規化が各自の core.autocrlf 任せ — **2番手（即効の小規模対策）を推奨**。`.gitattributes` 追加 + 一度の `git add --renormalize .` で解消でき数分規模。ADR-0033 の残存リスクを塞ぎ改行問題を完全終息できる
3. [ ] **Issue-0006**（flow）: 横断変更の計画網羅漏れ / **Issue-0016**（flow）: ツール適用結果を独立確認せず既遂とみなすと記録と実体が乖離する — 3番手（検証・品質系）。0006 は Issue-0013（整合性）の隣接軸（網羅性）。0016 は本サイクルの完了処理中に実際に発生（Edit 未適用を成功と誤認）した検証観点の課題で、対策方向（read-back verification をリスク比例・git 非依存で導入）はユーザー合意済み、ADR-0034・原則5 の隣接
4. [ ] **Issue-0003**（system）: conversation_log.md の分類 / **Issue-0008**（system）: 旧型式 spec 8本の維持方針 — 4番手。どちらもユーザーの方針決めが主
5. [ ] **Issue-0015**（flow）: マルチライン文字列をツールのシェル種別に合わせる規範・チェックがない — **低優先**。実害は軽微（回避策 `git commit -F` は有効と本サイクルで確認済み。ただし規範・チェックは未整備）
6. [ ] **Theme C 問題A**「プロジェクト固有用語集（ユビキタス言語）の仕組み」: 大テーマ（課題ではなく作業テーマのため issues 対象外）。規模が大きく brainstorming からの本格サイクルが必要
7. [ ] **ADR-0013 / 0014 / 0018 の Proposed 据え置き解消**: 最後尾。どこかのサイクルの Post チェックで昇格/棚卸しの判断だけ済ませると台帳が締まる

## 既知のブロッカー・懸念

- Issue-0005（選択UIの誤操作即確定）は **未対策のまま次サイクルへ**。本サイクルで実例が発生したため、重要判断はテキストの番号選択肢で提示する運用を当面継続すること
- AskUserQuestion の無応答タイムアウトは **ADR-0035 で規範化済み**（一律停止・待機）。今後タイムアウトに直面したらリスクを問わず停止しユーザーの応答を待つこと
- ADR-0023 の留意点（継続）: GitHub.com の Copilot コーディングエージェント（CLI 以外）がルート `CLAUDE.md` を読まない可能性
- `docs/conversation_log.md` は untracked のまま docs/ 直下に残置（Issue-0003。ユーザー判断待ち）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **最初に確認すべきファイル**: 本ファイル、`docs/working/issues/README.md`
3. **次に走らせる作業（候補）**: 「未着手のタスク」の優先順位付け（1: Issue-0005 → 2: Issue-0014 → …）を参考にユーザーが選択（着手はユーザー判断。必ず次サイクルではない）。Issue-0005 は方針合意済みで着手準備が整っている
4. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行（ADR-0033 により改行のみ差分は解消済み）
   - skills/ を編集したらプラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）まで反映されない
   - **コミット・マージメッセージ等のマルチライン文字列は `git commit -F <file>` / `git merge --no-ff -F <file>` で渡す**（Bash ツール=POSIX sh では PowerShell here-string `@'...'@` が使えない。Issue-0015。本サイクルで有効性確認済み）
   - **後戻りコストの高い重要判断は、選択UIでなくテキストの番号選択肢で提示する**（Issue-0005 未対策のため。誤クリック即確定を避ける）
   - ADR-0019（決定のみ・遅延昇格）、ADR-0021（retrospective は課題抽出のみ）、ADR-0022（説明的な用語）、ADR-0024（選択肢＋推奨）、ADR-0028（課題の全件起票）、ADR-0029（質問の自己完結）、ADR-0030（ADR コミットは収束チェックポイント）、ADR-0031（再発・進展は検討状況へ追記）、ADR-0032（判定条件は観測可能な事実）、ADR-0034（plan 検証整合の突合）、ADR-0035（質問ツールのタイムアウト時は一律停止・待機）を守る

## 重要な意思決定の履歴

- ADR-0035: 構造化質問ツールのタイムアウト時は一律で停止・待機する規範を追加（2026-07-05, Accepted）
- ADR-0034: 実装計画の検証ステップ期待値と編集内容の整合を確認する規範を追加（2026-07-05, Accepted）
- ADR-0033: sync-template.ps1 の生成ファイルは LF 改行で書き出す（2026-07-05, Accepted）
- ADR-0030/0031/0032: 記録プロセス規範一括対策（2026-07-05, Accepted）
- ADR-0029: 質問ツールの表示特性への対処規範をモデル条件付きで追加（2026-07-05, Accepted）
- ADR-0028: 振り返り課題を issue 管理へ全件起票し、issues を system/flow フォルダに分割する（2026-07-05, Accepted）
- （ADR-0001〜0027 は `docs/records/decisions/README.md` 参照）
