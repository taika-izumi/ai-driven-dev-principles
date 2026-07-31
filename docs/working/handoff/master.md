# Handoff: retrospective 役割再定義サイクル完了・次サイクル待ち

- **Branch**: master（feature/retrospective-mode-review を merge `066b4e0` として取り込み・feature ブランチ削除済み）
- **Last Updated**: 2026-07-31 (Asia/Tokyo)
- **Status**: ready-for-next-cycle（実装・master merge・新形式 retrospective・worklog 記録まで完了。次サイクル着手はユーザー判断）
- **Current Phase**: 全フェーズ完了。次サイクル着手はユーザー判断

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

**直近サイクル（2026-07-31: retrospective の役割再定義）**: Issue-0035（簡易モードが未定義）を起点に brainstorming を実施し、「簡易モードを追加する」のではなく **retrospective の役割自体を再定義**する方針を採用（merge `066b4e0`、ADR-0056 Accepted）。

- **残す情報を2つに限定**: 課題の詳細記録（issue 詳細の正本）＋最小サイクル文脈。Went Well / Tech Notes は**観点として廃止**し、スキル化に有用な知見は worklog パイプライン（record → extract → skillify）へ委譲
- **単一形式化**: 完全版 / 簡易版の選択を廃止。AI が課題候補を一括提示し、ユーザーが修正・起票判断を行う方式が標準
- **rubber-duck をオプション化**: 既定では実施せず、ユーザー要求時のみ（観点は抽出漏れ・分類妥当性の2点）
- **フロー課題の振り分け規則**: delta 型（worklog で捕捉可能）は原則 worklog へ、早期対処が必要なものと構造観察型のみ起票。構造観察型の発見主経路はサイクル中の随時起票であり、retrospective は起票漏れの最終チェックポイント
- **記録漏れ対策**: retrospectives README への行追加を省略不可工程として明記し、簡易実施時に欠落していた2行（2026-07-18 の2サイクル）を追記

判断の経緯（重要）: 「worklog で代替可能か」だけでなく「**残した記録に読み手（活用経路）がいるか**」を第2の判定軸としたこと、および「構造観察型の受け皿は retrospective」という当初案を**過去実績の調査（発見実績0件）で否定**したことが設計を決定づけた。

**新形式の初回適用（ドッグフーディング）で欠陥を1件検出**: Phase 2 で記録を確定した後、Phase 3 の worklog 総ざらいで新事実（Issue-0032 の再発）が判明したが、ADR-0011 の上書き禁止により反映経路がない → **Issue-0038 起票**。

その前のサイクル（2026-07-18）は worklog 実運用堅牢化（ADR-0054/0055）。さらに前は worklog スキーマ v2 改訂（ADR-0048〜0053）と 3スキルパイプライン新規追加（ADR-0044〜0047）。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open: system 0003/0008/0028/0032/0036、flow 0006/0015/0020/0021/0022/0033/0034/0037/0038）
- 直近サイクルの spec: `docs/current/specs/2026-05-01-retrospective-design.md`（ADR-0056 反映版へ全面書き換え済み）
- 直近サイクルの plan: `docs/working/plans/2026-07-31-retrospective-issue-extraction-redesign.md`（Task1〜6 全完了）
- 直近サイクルの retrospective（新形式・初回）: `docs/records/retrospectives/system/2026-07-31-retrospective-mode-review.md` / `flow/2026-07-31-retrospective-mode-review.md`
- retrospective スキル: `skills/retrospective/SKILL.md`（新4フェーズ構成）/ `template.md` / `flow-template.md`
- worklog スキーマ正典: `skills/worklog-record/references/store-format.md`（v2）
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0056。Rejected 3件）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] **retrospective 役割再定義サイクル**: ADR-0056（Accepted）。SKILL.md 全面改訂・テンプレート2種・README/CONTRIBUTING 整合・retrospectives README 規約更新と欠落2行追記・Issue-0035 close。merge `066b4e0`。新形式で初回 retrospective を実施し Issue-0037/0038 を起票、worklog 3エントリ記録（2026-07-31）
- [x] **worklog 実運用堅牢化サイクル**: model 定義訂正・エンコーディング契約＋読み側検証（ADR-0054）・start-work availability 規範（ADR-0055）。merge `50bef04`（2026-07-18）
- [x] **worklog v1.1 改訂サイクル**: スキーマ v2 化。ADR-0048〜0053。merge `ba7e81d`（2026-07-17〜18）
- [x] **3スキルパイプライン初回実装サイクル**: worklog-record/extract/skillify 新規追加。ADR-0044〜0047。merge `7ed7b32`（2026-07-17）
- [x] （以前のサイクルは過去の handoff / retrospective 参照）

## 進行中のタスク

（なし。サイクル完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化。目安:

1. [ ] **Issue-0037**（flow・新規）: start-work Post ラッパーの worklog-record 発火が実運用で起きない — **パイプラインの入口が機能していない**ため影響大。本サイクルでも発火0回（総ざらいで事後補完した）
2. [ ] **Issue-0038**（flow・新規）: retrospective の Phase 3 で得た知見を記録へ反映する経路がない — 新形式を回すたび再現。小規模（規約の明文化で解決見込み）
3. [ ] **Issue-0033 / 0034**（flow）: worklog-extract 初回走査の採用候補。0034（非コード成果物への実証を課した独立レビュー）は本サイクルでも同型が再発し追記済み
4. [ ] **Issue-0032**（system）: worklog-extract の健全性検証の具体的検出手段 — 再発2例目を追記済み。**grep 系は環境依存で誤判定するため、バイト直接カウントを例示すべき**という結論に近づいている（小規模）
5. [ ] **Issue-0021**（flow）: Tech Notes の横断再利用 — ADR-0056 で解消方向。**close 判断がユーザー待ち**
6. [ ] **Issue-0003 / 0008 / 0036**（system）: conversation_log の分類 / 旧型式 spec の維持方針（ファイル名の日付規約も未定義。2026-07-31 追記）/ worklog-extract の単発エントリ扱い
7. [ ] **Issue-0006 / 0015 / 0020 / 0022**（flow）: 検証・プロセス品質系の低優先課題群
8. [ ] **Issue-0028**（system）: worklog マルチユーザー・組織展開 — v2 テーマ
9. [ ] **Theme C 問題A**「プロジェクト固有用語集（ユビキタス言語）の仕組み」: 大テーマ
10. [ ] **ループプロファイル抽出サイクル**（ADR-0043）: LoopForAlpha での実証完了後に着手する大テーマ

## 既知のブロッカー・懸念

- **プラグイン未更新（要対応・環境制約あり）**: 本サイクルは `skills/retrospective/`（SKILL.md・テンプレート2種）を改定した。反映には `/plugin marketplace update ai-driven-dev-principles` が必要（AI 実行不可。ADR-0055）。ただし **2026-07-31 のセッションはリモート操作のため `/plugin` コマンド自体が使用不可**だった（「/plugin isn't available over Remote Control」）。当該セッションではコミット済み SKILL.md を直接読んで新手順を適用した。**次にローカル操作するときプラグイン更新を実行すること**。それまでロードされる retrospective スキル本文は旧版（5観点ヒアリング）のまま
- **中央ストアの現状**: `$HOME/.ai-dev-worklog/MakeAiInstructions/log.jsonl` に 9 件（`2026-07-17-01/-02`、`2026-07-18-01〜04`、`2026-07-31-01〜03`）。全行 CR 0 件・BOM なし・UTF-8/LF をバイト直接カウントで検証済み。`processed.jsonl` は LoopForAlpha の extract 走査分あり
- **ストア健全性検証の注意（Issue-0032）**: `od -c \| grep -c '\r'` が **CR 147件という誤検出**を返した実例あり（実際は0件）。Python の `open(p,'rb').read().count(b'\r')` が確実
- **inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定（2026-07-17 明言）**。organize-inbox 提案は不要
- **モデルまたぎ運用**: 主作業＝高性能モデル・事後処理＝安価モデルの使い分けを恒常運用。worklog の `model` は「delta 発生元」で埋める（ADR-0048）。本サイクルは Opus 5 → Fable 5 → Opus 5 と切り替わり、delta の大半は Fable 5 期に発生
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` は確認済み（構造化質問ツール使用前に毎回確認。ADR-0036）
- ADR-0023 の留意点（継続）: GitHub.com の Copilot コーディングエージェント（CLI 以外）がルート `CLAUDE.md` を読まない可能性

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **直近サイクルは完了**: 実装・merge・新形式 retrospective・worklog 記録済み。追加作業不要
3. **プラグイン更新**: ローカル操作セッションであれば、新しい作業の前に `/plugin marketplace update ai-driven-dev-principles` をユーザーへ依頼（ADR-0055。リモート操作では不可）
4. **次サイクルの候補（着手はユーザー判断）**: Issue-0037（worklog 発火漏れ。影響大）/ Issue-0038（Phase 3 反映経路。小規模）/ Issue-0032（検証手段の具体化。小規模）。Issue-0021 の close 可否も要判断
5. **最初に確認すべきファイル**: 本ファイル、`docs/records/retrospectives/system/2026-07-31-retrospective-mode-review.md`、`docs/working/issues/README.md`
6. **LoopForAlpha を開始する場合**（ADR-0043）: 引継ぎ書 `D:\Dev\001_Trade\LoopForAlpha\HANDOVER.md` を正とする
7. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行（本サイクルは retrospectives README の規約更新で template 同期が発生した）
   - skills/ を編集したらプラグイン更新まで反映されない（Issue-0024/ADR-0055）
   - コミット・マージメッセージのマルチライン文字列は `git commit -F <file>` / `git merge --no-ff -F <file>` で渡す（Issue-0015）。Git Bash では `$TMPDIR` が空になりうるため、一時ファイルは絶対パスで指定する
   - 中央ストアへの追記は UTF-8/BOM なし/LF。健全性はバイト直接カウントで確認（grep 系は不可。Issue-0032）
   - ADR 起票時は置換対象の特定（ADR-0042）・1決定=1ADR（Issue-0022）。コミット済み Proposed の不採用は Rejected 化（ADR-0041）

## 重要な意思決定の履歴

- ADR-0056: retrospective を課題抽出記録に純化し Went Well / Tech Notes を worklog へ委譲（2026-07-31, **Accepted**）
- ADR-0054/0055: worklog 中央ストアのエンコーディング契約＋読み側検証 / start-work Phase -1 の availability 判定規範（2026-07-18, Accepted）
- ADR-0048（改定）: model 定義を「記録時」→「delta 発生元」へ in-place 訂正（2026-07-18, Accepted・改定注記あり）
- ADR-0048〜0053: worklog v1.1 改訂（2026-07-17〜18, Accepted）
- ADR-0044〜0047: 3スキルパイプライン（2026-07-16〜17, Accepted）
- ADR-0043: ループエンジニアリングは実証先行・現行体系は対話モード専用（2026-07-08, Accepted）
- ADR-0041/0042: Rejected 経路 / Superseded 置換対象特定・台帳監査（2026-07-07, Accepted）
- （ADR-0001〜0040 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
