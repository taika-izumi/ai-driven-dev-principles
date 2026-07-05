# Handoff: Issue-0016/0017 対策サイクル完了・次サイクル待機

- **Branch**: master
- **Last Updated**: 2026-07-06 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: Issue-0016/0017 対策サイクル完了（merge: d6b50c8、retrospective 実施済み）/ 次サイクル未着手

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

直近サイクルは「Issue-0016: ツール適用結果の独立確認」「Issue-0017: 環境解決の先行調査観点」のまとめ対策。`CLAUDE.md`「検証」節に read-back verification の1箇条（発動条件は「後続の判断・記録が依存する場合」「複数変更を節目で確定する直前」の2つに限定、git 非依存。ADR-0038）、`CONTRIBUTING.md`「振り返りで抽出された課題に対策するとき」の手順に環境・ツール設定による構造的解決の先行調査ステップ（新手順4。ADR-0039）を追加し、template 同期済み。設計議論でユーザーから「CLAUDE.md は配布先全プロジェクトに影響する常時指示であり、安易な規模拡大を防止したい」という方針が示され、Issue-0017 の対策は当初案（CLAUDE.md にも配置）から CONTRIBUTING.md のみへ縮小。この方針から Issue-0018（CLAUDE.md 常時指示の肥大化を監視・棚卸しする仕組みがない）を起票した。小規模のため plan/spec は作らず ADR-0038/0039 が設計記録を兼ねた。Issue-0016/0017 は close。retrospective では新規課題なし（Issue-0018 へ事前判定の観点を進展追記）。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open 6件 / closed 13件）
- 直近サイクルの ADR: ADR-0038, ADR-0039（Accepted）
- 直近サイクルの retrospective: `docs/records/retrospectives/system/2026-07-06-process-check-norms.md`（retrospective 起点の新規課題なしのため flow/ ファイルなし。Issue-0018 はサイクル内起票）
- 課題管理の規約: `docs/overview/folder-structure.md` §7
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0039）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] **Issue-0016/0017 対策サイクル**: read-back verification 規範を `CLAUDE.md`「検証」節へ（ADR-0038）、環境解決の先行調査ステップを `CONTRIBUTING.md` 課題対策手順へ（ADR-0039）追加、template 同期。CLAUDE.md 規模拡大の抑制方針を初適用（0017 は CONTRIBUTING.md のみ配置）し Issue-0018 起票。merge `d6b50c8`、Issue-0016/0017 close、grep read-back 検証済み、retrospective 実施済み（新規課題なし。rubber-duck 指摘4件中3件採用・1件部分採用）（2026-07-06）
- [x] **Issue-0014 対策サイクル**: `.gitattributes`（`* text=auto`）追加＋renormalize（差分ゼロ）で改行正規化を git 側に固定（ADR-0037）。template への配布は見送り（ADR-0027 シード基準）。merge `cc67f73`、Issue-0014 close、CRLF→LF 正規化を実機検証済み、retrospective 実施済み（新規課題なし。Issue-0016/0017 へ進展追記。rubber-duck 指摘4件すべて採用・反映）。改行問題の課題系列（Issue-0002 → ADR-0033 → Issue-0014 → ADR-0037）が終息（2026-07-05）
- [x] **Issue-0005 対策サイクル**: 選択UI誤操作対策を環境設定（`CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` をユーザー環境へ適用）＋環境ベース2分岐規範（`CLAUDE.md` ツール選択条項の改定）で実装（ADR-0036）。merge `5012033`、Issue-0005 close、差分検証済み（grep 新文言1件・旧文言0件・template 置換のみ）、retrospective 実施済み（フロー課題1件 → Issue-0017 起票。rubber-duck 指摘4件すべて採用・反映）（2026-07-05）
- [x] **Issue-0012 対策サイクル**: タイムアウト時の一律停止・待機規範を `CLAUDE.md` 質問節と原則4へ追加（ADR-0035）。merge `a13e796`、Issue-0012 close、差分検証済み（grep 各1件・template 追加のみ）、retrospective 実施済み（新規課題なし。Issue-0005 の実例再発を検討状況へ追記、Issue-0015 の回避策実践を進展として追記。rubber-duck 指摘#1 反映で対称化）（2026-07-05）
- [x] **Issue-0013 対策サイクル**: plan 検証整合規範を `CLAUDE.md`「検証」節へ追加（ADR-0034）。merge `afef02a`、Issue-0013 close（2026-07-05）
- [x] **Issue-0002 対策サイクル**: sync-template.ps1 の LF 固定書き出し（ADR-0033）。merge `d9329d8`、Issue-0002 close（2026-07-05）
- [x] **記録プロセス規範一括対策サイクル**: Issue-0009/0010/0011 を ADR-0030/0031/0032 として規範化・実装。merge `71d383c`（2026-07-05）

## 進行中のタスク

なし（Issue-0005 対策サイクルは retrospective・handoff update まで完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化済み（open 6件）。Issue-0016/0017 close・Issue-0018/0019 起票を反映した目安:

1. [ ] **Issue-0018**（flow）: CLAUDE.md 常時指示の肥大化を監視・棚卸しする仕組みがない — 筆頭候補（ユーザーの規模拡大抑制方針の延長で関心が高い。事前判定・事後棚卸しの両面を扱う。検討状況参照）
2. [ ] **Issue-0006**（flow）: 横断変更の計画網羅漏れ — 検証・プロセス品質系の残り1件
3. [ ] **Issue-0003**（system）: conversation_log.md の分類 / **Issue-0008**（system）: 旧型式 spec 8本の維持方針 — どちらもユーザーの方針決めが主
4. [ ] **Issue-0015**（flow）: マルチライン文字列をツールのシェル種別に合わせる規範・チェックがない — **低優先**。実害は軽微（回避策 `git commit -F` は有効と確認済み。ただし規範・チェックは未整備）
5. [ ] **Theme C 問題A**「プロジェクト固有用語集（ユビキタス言語）の仕組み」: 大テーマ（課題ではなく作業テーマのため issues 対象外）。規模が大きく brainstorming からの本格サイクルが必要
6. [ ] **Issue-0019**（flow）: コミット済み Proposed ADR を不採用で終える経路（Rejected）が未定義 — 下記の Proposed 棚卸しの前提になるため、棚卸しと同時に扱うと効率的
7. [ ] **ADR-0013 / 0014 / 0018 の Proposed 据え置き解消**: 最後尾。どこかのサイクルの Post チェックで昇格/棚卸しの判断だけ済ませると台帳が締まる（不採用の着地には Issue-0019 の解決が必要。※ここでの「ADR-0018」は ADR 台帳の番号であり、課題 Issue-0018 とは別物）

## 既知のブロッカー・懸念

- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` の実機検証は **2026-07-05 に完了**（環境変数 `1` を確認、AskUserQuestion を2回運用し誤確定なし）。以後のセッションでも規範どおり、使用前に環境変数の値を確認すること（ADR-0036）
- AskUserQuestion の無応答タイムアウトは **ADR-0035 で規範化済み**（一律停止・待機）。今後タイムアウトに直面したらリスクを問わず停止しユーザーの応答を待つこと
- ADR-0023 の留意点（継続）: GitHub.com の Copilot コーディングエージェント（CLI 以外）がルート `CLAUDE.md` を読まない可能性
- `docs/conversation_log.md` は untracked のまま docs/ 直下に残置（Issue-0003。ユーザー判断待ち）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **最初に確認すべきファイル**: 本ファイル、`docs/working/issues/README.md`
3. **最初に実行すべき確認**: 構造化質問ツールを使う前に環境変数 `CLAUDE_CODE_DISABLE_MOUSE_CLICKS` の値が `1` であることを確認（ADR-0036 の使用条件。実機検証自体は 2026-07-05 完了済み）
4. **次に走らせる作業（候補）**: 「未着手のタスク」の優先順位付け（1: Issue-0018 → 2: Issue-0006 → …）を参考にユーザーが選択（着手はユーザー判断。必ず次サイクルではない）
5. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行（ADR-0033 により改行のみ差分は解消済み）
   - skills/ を編集したらプラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）まで反映されない
   - **コミット・マージメッセージ等のマルチライン文字列は `git commit -F <file>` / `git merge --no-ff -F <file>` で渡す**（Bash ツール=POSIX sh では PowerShell here-string `@'...'@` が使えない。Issue-0015）
   - **構造化質問ツールの使用可否は環境で判定する**（ADR-0036: クリック誤操作の防止設定が確認できる場合のみ使用可。確認できなければテキストの番号付き選択肢で提示）
   - ADR-0019（決定のみ・遅延昇格）、ADR-0021（retrospective は課題抽出のみ）、ADR-0022（説明的な用語）、ADR-0024（選択肢＋推奨）、ADR-0028（課題の全件起票）、ADR-0029（質問の自己完結）、ADR-0030（ADR コミットは収束チェックポイント）、ADR-0031（再発・進展は検討状況へ追記）、ADR-0032（判定条件は観測可能な事実）、ADR-0034（plan 検証整合の突合）、ADR-0035（質問ツールのタイムアウト時は一律停止・待機）、ADR-0036（質問ツールの使用は防止設定の環境確認が条件）、ADR-0037（改行正規化は .gitattributes で git 側に固定済み・template へは配布しない）、ADR-0038（後続依存・節目直前はツール戻り値でなく実体の読み直しで確認）、ADR-0039（課題対策は方針検討前に環境・ツール設定による構造的解決を調査）を守る
   - **CLAUDE.md への規範追加は抑制方針**（常時指示の規模拡大を防止。放置リスクが高い課題に限り、観測可能な発動条件でゲートして追加する。Issue-0018 検討状況参照）

## 重要な意思決定の履歴

- ADR-0039: 課題対策手順に環境・ツール設定による構造的解決の先行調査ステップを追加する（2026-07-05, Accepted）
- ADR-0038: ツール適用結果はリスク比例で実体の読み直しにより独立確認する規範を追加（2026-07-05, Accepted）
- ADR-0037: .gitattributes で改行正規化を git 側に固定し、template へは配布しない（2026-07-05, Accepted）
- ADR-0036: 選択UI誤操作対策は環境側の誤操作防止設定とテキスト提示フォールバック規範の両輪とする（2026-07-05, Accepted）
- ADR-0035: 構造化質問ツールのタイムアウト時は一律で停止・待機する規範を追加（2026-07-05, Accepted）
- ADR-0034: 実装計画の検証ステップ期待値と編集内容の整合を確認する規範を追加（2026-07-05, Accepted）
- ADR-0033: sync-template.ps1 の生成ファイルは LF 改行で書き出す（2026-07-05, Accepted）
- ADR-0030/0031/0032: 記録プロセス規範一括対策（2026-07-05, Accepted）
- ADR-0029: 質問ツールの表示特性への対処規範をモデル条件付きで追加（2026-07-05, Accepted）
- ADR-0028: 振り返り課題を issue 管理へ全件起票し、issues を system/flow フォルダに分割する（2026-07-05, Accepted）
- （ADR-0001〜0027 は `docs/records/decisions/README.md` 参照）
