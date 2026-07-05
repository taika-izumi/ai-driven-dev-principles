# Handoff: Issue-0005 対策サイクル完了・次サイクル待機

- **Branch**: master
- **Last Updated**: 2026-07-05 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: Issue-0005 対策サイクル完了（merge: 5012033、retrospective 実施済み）/ 次サイクル未着手

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

直近サイクルは「Issue-0005: 選択UIの誤操作が即『方針確定』として扱われる」の対策。調査により Claude Code v2.1.195 以降の環境変数 `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` で選択UIのクリック確定を無効化（キーボード操作のみに限定）できると判明し、対策を当初方針（重要判断のみテキスト化）から「環境設定＋環境ベース2分岐規範」へ変更した（ADR-0036, Accepted）。`CLAUDE.md`「ユーザーへの質問と意思決定要求」節のツール選択条項を「クリック誤操作の防止設定が環境で確認できる場合のみ構造化質問ツールを使用可（重要度を問わず使用してよい）／確認できない場合はテキストの番号付き選択肢で提示」の2分岐に改定。ユーザー環境の `~/.claude/settings.json` に環境変数を適用済み（起動時注入のため次セッションから有効）。template 同期済み（該当2箇条の置換のみ）。小規模のため plan/spec は作らず ADR-0036 が設計記録を兼ねた。Issue-0005 は close。feature ブランチは merge 後削除済み。retrospective でフロー課題1件を抽出し Issue-0017（対策検討の初手に「環境・ツール設定による構造的解決の調査」を促す観点がない）を起票した。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open 7件 / closed 10件）
- 直近サイクルの ADR: ADR-0036（Accepted）
- 直近サイクルの retrospective: `docs/records/retrospectives/system/2026-07-05-selection-ui-misclick-mitigation.md` + `flow/` 同名（フロー課題1件 → Issue-0017 起票）
- 課題管理の規約: `docs/overview/folder-structure.md` §7
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0036）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] **Issue-0005 対策サイクル**: 選択UI誤操作対策を環境設定（`CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` をユーザー環境へ適用）＋環境ベース2分岐規範（`CLAUDE.md` ツール選択条項の改定）で実装（ADR-0036）。merge `5012033`、Issue-0005 close、差分検証済み（grep 新文言1件・旧文言0件・template 置換のみ）、retrospective 実施済み（フロー課題1件 → Issue-0017 起票。rubber-duck 指摘4件すべて採用・反映）（2026-07-05）
- [x] **Issue-0012 対策サイクル**: タイムアウト時の一律停止・待機規範を `CLAUDE.md` 質問節と原則4へ追加（ADR-0035）。merge `a13e796`、Issue-0012 close、差分検証済み（grep 各1件・template 追加のみ）、retrospective 実施済み（新規課題なし。Issue-0005 の実例再発を検討状況へ追記、Issue-0015 の回避策実践を進展として追記。rubber-duck 指摘#1 反映で対称化）（2026-07-05）
- [x] **Issue-0013 対策サイクル**: plan 検証整合規範を `CLAUDE.md`「検証」節へ追加（ADR-0034）。merge `afef02a`、Issue-0013 close（2026-07-05）
- [x] **Issue-0002 対策サイクル**: sync-template.ps1 の LF 固定書き出し（ADR-0033）。merge `d9329d8`、Issue-0002 close（2026-07-05）
- [x] **記録プロセス規範一括対策サイクル**: Issue-0009/0010/0011 を ADR-0030/0031/0032 として規範化・実装。merge `71d383c`（2026-07-05）

## 進行中のタスク

なし（Issue-0005 対策サイクルは retrospective・handoff update まで完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化済み（open 7件）。Issue-0005 close・Issue-0017 起票を反映した目安:

1. [ ] **Issue-0014**（system）: .gitattributes 未導入で改行正規化が各自の core.autocrlf 任せ — **最優先（即効の小規模対策）を推奨**。`.gitattributes` 追加 + 一度の `git add --renormalize .` で解消でき数分規模。ADR-0033 の残存リスクを塞ぎ改行問題を完全終息できる
2. [ ] **Issue-0006**（flow）: 横断変更の計画網羅漏れ / **Issue-0016**（flow）: ツール適用結果を独立確認せず既遂とみなすと記録と実体が乖離する / **Issue-0017**（flow）: 対策検討の初手に「環境・ツール設定による構造的解決の調査」を促す観点がない — 2番手（検証・プロセス品質系）。0016 は対策方向（read-back verification をリスク比例・git 非依存で導入）がユーザー合意済み。0017 は Issue-0005 対策サイクルで抽出（規範設計の前に環境解決を調べる観点の定式化。0016 と同じく「進め方のチェック観点」系で、まとめて扱える可能性がある）
3. [ ] **Issue-0003**（system）: conversation_log.md の分類 / **Issue-0008**（system）: 旧型式 spec 8本の維持方針 — 3番手。どちらもユーザーの方針決めが主
4. [ ] **Issue-0015**（flow）: マルチライン文字列をツールのシェル種別に合わせる規範・チェックがない — **低優先**。実害は軽微（回避策 `git commit -F` は有効と確認済み。ただし規範・チェックは未整備）
5. [ ] **Theme C 問題A**「プロジェクト固有用語集（ユビキタス言語）の仕組み」: 大テーマ（課題ではなく作業テーマのため issues 対象外）。規模が大きく brainstorming からの本格サイクルが必要
6. [ ] **ADR-0013 / 0014 / 0018 の Proposed 据え置き解消**: 最後尾。どこかのサイクルの Post チェックで昇格/棚卸しの判断だけ済ませると台帳が締まる

## 既知のブロッカー・懸念

- **`CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` の実機検証が未了**（設定は起動時注入のため、適用した 2026-07-05 のセッションでは検証不能）。次セッション冒頭で環境変数の値を確認し、AskUserQuestion のクリック無効を実機確認すること。確認できるまでは改定後の規範に従いテキスト提示で質問する
- AskUserQuestion の無応答タイムアウトは **ADR-0035 で規範化済み**（一律停止・待機）。今後タイムアウトに直面したらリスクを問わず停止しユーザーの応答を待つこと
- ADR-0023 の留意点（継続）: GitHub.com の Copilot コーディングエージェント（CLI 以外）がルート `CLAUDE.md` を読まない可能性
- `docs/conversation_log.md` は untracked のまま docs/ 直下に残置（Issue-0003。ユーザー判断待ち）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **最初に確認すべきファイル**: 本ファイル、`docs/working/issues/README.md`
3. **最初に実行すべき確認**: 環境変数 `CLAUDE_CODE_DISABLE_MOUSE_CLICKS` の値を出力し `1` であることを確認（ADR-0036 の実機検証。あわせて AskUserQuestion のクリック無効をユーザーに一言確認できるとなお良い）
4. **次に走らせる作業（候補）**: 「未着手のタスク」の優先順位付け（1: Issue-0014 → 2: Issue-0006/0016/0017 → …）を参考にユーザーが選択（着手はユーザー判断。必ず次サイクルではない）
5. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行（ADR-0033 により改行のみ差分は解消済み）
   - skills/ を編集したらプラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）まで反映されない
   - **コミット・マージメッセージ等のマルチライン文字列は `git commit -F <file>` / `git merge --no-ff -F <file>` で渡す**（Bash ツール=POSIX sh では PowerShell here-string `@'...'@` が使えない。Issue-0015）
   - **構造化質問ツールの使用可否は環境で判定する**（ADR-0036: クリック誤操作の防止設定が確認できる場合のみ使用可。確認できなければテキストの番号付き選択肢で提示）
   - ADR-0019（決定のみ・遅延昇格）、ADR-0021（retrospective は課題抽出のみ）、ADR-0022（説明的な用語）、ADR-0024（選択肢＋推奨）、ADR-0028（課題の全件起票）、ADR-0029（質問の自己完結）、ADR-0030（ADR コミットは収束チェックポイント）、ADR-0031（再発・進展は検討状況へ追記）、ADR-0032（判定条件は観測可能な事実）、ADR-0034（plan 検証整合の突合）、ADR-0035（質問ツールのタイムアウト時は一律停止・待機）、ADR-0036（質問ツールの使用は防止設定の環境確認が条件）を守る

## 重要な意思決定の履歴

- ADR-0036: 選択UI誤操作対策は環境側の誤操作防止設定とテキスト提示フォールバック規範の両輪とする（2026-07-05, Accepted）
- ADR-0035: 構造化質問ツールのタイムアウト時は一律で停止・待機する規範を追加（2026-07-05, Accepted）
- ADR-0034: 実装計画の検証ステップ期待値と編集内容の整合を確認する規範を追加（2026-07-05, Accepted）
- ADR-0033: sync-template.ps1 の生成ファイルは LF 改行で書き出す（2026-07-05, Accepted）
- ADR-0030/0031/0032: 記録プロセス規範一括対策（2026-07-05, Accepted）
- ADR-0029: 質問ツールの表示特性への対処規範をモデル条件付きで追加（2026-07-05, Accepted）
- ADR-0028: 振り返り課題を issue 管理へ全件起票し、issues を system/flow フォルダに分割する（2026-07-05, Accepted）
- （ADR-0001〜0027 は `docs/records/decisions/README.md` 参照）
