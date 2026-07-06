# Handoff: Issue-0018 対策サイクル完了・次サイクル待機

- **Branch**: master
- **Last Updated**: 2026-07-06 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: Issue-0018 対策サイクル完了（merge: e3e6768、retrospective 実施済み）/ 次サイクル未着手

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

直近サイクルは「Issue-0018: CLAUDE.md 常時指示の肥大化を監視・棚卸しする仕組みがない」への対策（ADR-0040）。監視は `scripts/check-claude-md-size.ps1` 新設（閾値 12,000 バイト / 45 件、警告のみ・exit 0）＋ `sync-template.ps1` 末尾からの自動呼び出し。事前判定は CONTRIBUTING.md「CLAUDE.md を更新するとき」の手順小節（実測 → 放置リスク評価 → 配置優先順位 → ゲート必須）、棚卸しは同新シナリオ「CLAUDE.md を棚卸しするとき」（4分類判定: 構造的置換/失効/退避/現役、閾値内へ戻らなければ閾値引き上げをユーザーへ提起）として定義。閾値は既知の劣化域（指示150件前後・入力数万トークン）から安全マージンを取った管理上のトリップワイヤーで、運用して棚卸しが困難なら引き上げ検討（ユーザー方針）。下り方向の配布経路はスコープ外・課題起票も見送り（手動運用で困った時点で起票。ユーザー判断）。spec なし・簡易 plan あり（ADR-0040 が設計記録を兼ねる）。Issue-0018 close。retrospective でフロー課題1件を Issue-0020 として起票、Issue-0015 へ進展追記。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open 6件 / closed 14件）
- 直近サイクルの ADR: ADR-0040（Accepted）
- 直近サイクルの retrospective: `docs/records/retrospectives/system/2026-07-06-claude-md-growth-governance.md` ＋ `flow/` 同名ファイル（フロー課題1件 → Issue-0020）
- 直近サイクルの plan: `docs/working/plans/2026-07-06-claude-md-growth-governance.md`
- 課題管理の規約: `docs/overview/folder-structure.md` §7
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0040）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] **Issue-0018 対策サイクル**: CLAUDE.md 肥大化ガバナンス導入（ADR-0040）。監視スクリプト `check-claude-md-size.ps1`（sync-template 連動・警告分岐の実機検証済み）、CONTRIBUTING.md へ事前判定手順＋棚卸しシナリオ追加。環境解決の先行調査ステップ（ADR-0039）初発動、閾値は研究データ（IFScale / Context Rot）参照のうえ保守側 12,000 バイト / 45 件をユーザー選択。merge `e3e6768`、Issue-0018 close、retrospective 実施済み（フロー課題1件 → Issue-0020 起票、Issue-0015 進展追記、rubber-duck 指摘3件すべて採用・反映）（2026-07-06）
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

バックログは `docs/working/issues/README.md` に一元化済み（open 6件: 0003, 0006, 0008, 0015, 0019, 0020）。Issue-0018 close・Issue-0020 起票を反映した目安:

1. [ ] **Issue-0006**（flow）: 横断変更の計画網羅漏れ — 検証・プロセス品質系の残り1件
2. [ ] **Issue-0019**（flow）: コミット済み Proposed ADR の不採用経路（Rejected）未定義 ＋ **ADR-0013 / 0014 / 0018 の Proposed 据え置き解消** — 同時に扱うと台帳が締まる（※「ADR-0018」は ADR 台帳の番号であり、課題 Issue-0018 とは別物）
3. [ ] **Issue-0003**（system）: conversation_log.md の分類 / **Issue-0008**（system）: 旧型式 spec 8本の維持方針 — どちらもユーザーの方針決めが主
4. [ ] **Issue-0015**（flow）: シェル種別依存の構文の規範・チェックがない — 低優先だが、射程拡大の材料が追加（2026-07-06 進展追記: 単行構文でも発生）
5. [ ] **Issue-0020**（flow）: コミット直前のステージング内容確認の観点がない — 低優先（実害軽微。ADR-0038 の隣接盲点）
6. [ ] **Theme C 問題A**「プロジェクト固有用語集（ユビキタス言語）の仕組み」: 大テーマ（課題ではなく作業テーマのため issues 対象外）。規模が大きく brainstorming からの本格サイクルが必要

## 既知のブロッカー・懸念

- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` の実機検証は **2026-07-05 に完了**（環境変数 `1` を確認、AskUserQuestion を2回運用し誤確定なし）。以後のセッションでも規範どおり、使用前に環境変数の値を確認すること（ADR-0036）
- AskUserQuestion の無応答タイムアウトは **ADR-0035 で規範化済み**（一律停止・待機）。今後タイムアウトに直面したらリスクを問わず停止しユーザーの応答を待つこと
- ADR-0023 の留意点（継続）: GitHub.com の Copilot コーディングエージェント（CLI 以外）がルート `CLAUDE.md` を読まない可能性
- `docs/conversation_log.md` は untracked のまま docs/ 直下に残置（Issue-0003。ユーザー判断待ち）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **最初に確認すべきファイル**: 本ファイル、`docs/working/issues/README.md`
3. **最初に実行すべき確認**: 構造化質問ツールを使う前に環境変数 `CLAUDE_CODE_DISABLE_MOUSE_CLICKS` の値が `1` であることを確認（ADR-0036 の使用条件。実機検証自体は 2026-07-05 完了済み）
4. **次に走らせる作業（候補）**: 「未着手のタスク」の優先順位付け（1: Issue-0006 → 2: Issue-0019＋Proposed 棚卸し → …）を参考にユーザーが選択（着手はユーザー判断。必ず次サイクルではない）。抽出課題は issues に起票済み（Issue-0020。着手はユーザー判断）
5. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行（ADR-0033 により改行のみ差分は解消済み）
   - skills/ を編集したらプラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）まで反映されない
   - **コミット・マージメッセージ等のマルチライン文字列は `git commit -F <file>` / `git merge --no-ff -F <file>` で渡す**（Bash ツール=POSIX sh では PowerShell here-string `@'...'@` が使えない。Issue-0015）
   - **構造化質問ツールの使用可否は環境で判定する**（ADR-0036: クリック誤操作の防止設定が確認できる場合のみ使用可。確認できなければテキストの番号付き選択肢で提示）
   - ADR-0019（決定のみ・遅延昇格）、ADR-0021（retrospective は課題抽出のみ）、ADR-0022（説明的な用語）、ADR-0024（選択肢＋推奨）、ADR-0028（課題の全件起票）、ADR-0029（質問の自己完結）、ADR-0030（ADR コミットは収束チェックポイント）、ADR-0031（再発・進展は検討状況へ追記）、ADR-0032（判定条件は観測可能な事実）、ADR-0034（plan 検証整合の突合）、ADR-0035（質問ツールのタイムアウト時は一律停止・待機）、ADR-0036（質問ツールの使用は防止設定の環境確認が条件）、ADR-0037（改行正規化は .gitattributes で git 側に固定済み・template へは配布しない）、ADR-0038（後続依存・節目直前はツール戻り値でなく実体の読み直しで確認）、ADR-0039（課題対策は方針検討前に環境・ツール設定による構造的解決を調査）、ADR-0040（CLAUDE.md 追加は事前判定・変更後は計測、超過時は棚卸し）を守る
   - **CLAUDE.md への規範追加は事前判定必須**（CONTRIBUTING.md「CLAUDE.md を更新するとき」の手順に定式化済み: 実測 → 放置リスク評価 → 配置優先順位 → ゲート必須。ADR-0040）。追加後の sync-template.ps1 実行で規模計測が自動で走り、閾値超過なら棚卸し（CONTRIBUTING.md 新シナリオ）を提案する

## 重要な意思決定の履歴

- ADR-0040: CLAUDE.md 肥大化ガバナンスを計測スクリプト連動と CONTRIBUTING.md 手順で導入する（2026-07-06, Accepted）
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
