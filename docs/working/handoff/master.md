# Handoff: worklog 実運用堅牢化サイクル完了・次サイクル待ち

- **Branch**: master（feature/worklog-operational-hardening を merge `50bef04` として取り込み・feature ブランチ削除済み）
- **Last Updated**: 2026-07-18 (Asia/Tokyo)
- **Status**: completed（実装・master merge・簡易 retrospective・worklog 記録まで完了。次サイクル待ち）
- **Current Phase**: 全フェーズ完了。次サイクル着手はユーザー判断

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

**直近サイクル（2026-07-18: worklog 実運用堅牢化）**: worklog パイプラインの実運用堅牢化 3 件を一括対処（merge `50bef04`）。

- **Issue-0031**（close）: ADR-0048 の `model` 定義を「記録時の AI モデル ID」→「**delta 発生元の AI モデル ID**（記録時と異なる場合は発生元を優先）」へ **in-place 改定**。store-format.md / worklog-record SKILL.md / spec 01・02 も文言統一。ADR タイトル・Status 注記・Consequences（モデルまたぎはテーマ分割）も更新
- **Issue-0030**（close, ADR-0054 Accepted）: 中央ストア（log.jsonl / processed.jsonl / projects.json）を **UTF-8・BOM なし・LF 固定**の契約とし、書き側手段（PowerShell `Add-Content -Encoding utf8NoBOM` / POSIX `>>`）を注記、worklog-extract に走査直前の **read-side loud validation**（検出→報告・停止、正規化は明示 opt-in。silent tolerance 不採用）を追加
- **Issue-0024**（close, ADR-0055 Accepted）: start-work Phase -1 に「新規/改定スキルの availability は AI 側 system-reminder / Skill ツール呼び出し可否で判定（UI 非依存）、未反映ならユーザーへプラグイン更新依頼」する step 4 を追加

簡易 retrospective で課題 A/B/C を抽出。**Issue-0032**（system, open）を起票（B: worklog-extract の健全性検証の具体的検出手段が未定義）。A（flow: 規範系対策提案時に被害規模を添える観点）・C（flow: Accepted ADR の in-place 改定の可否・注記フォーマット未定義）はユーザー判断で不起票。

**実データでの副産物（重要）**: worklog-record 実行時、新設した ADR-0054 の read-side validation を中央ストアに適用したところ、既存 5 エントリ中 4 件に**生の CR（0x0d）が文字列値内部に混入**していた（前サイクルの Windows 系追記由来と推定）。ユーザー opt-in で `tr -d '\r'` により正規化（バックアップ取得済み）。さらに素朴な `grep -P` 検出が Git Bash ロケールでエラー→誤「clean」報告し、`od` のバイト直接カウントが唯一信頼できた＝Issue-0032 の裏付け。

その前のサイクル（2026-07-17〜18）は worklog スキーマ v2 改訂（ADR-0048〜0053）。さらに前は 3スキルパイプライン新規追加（ADR-0044〜0047）。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open: system 0003/0008/0028/0032、flow 0006/0015/0020/0021/0022）
- 直近サイクルの plan: `docs/working/plans/2026-07-18-worklog-operational-hardening.md`（Task1〜5 全完了）
- 直近サイクルの retrospective（簡易版）: `docs/records/retrospectives/system/2026-07-18-worklog-operational-hardening.md`
- worklog スキーマ正典: `skills/worklog-record/references/store-format.md`（v2・エンコーディング契約追加済み）
- worklog spec: `docs/current/specs/2026-07-17-worklog-skill-pipeline/`（01/02 は v2・model 文言反映済み。03/04 は初回実装のまま）
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0055。Rejected 3件・ADR-0048 は in-place 改定注記あり）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`
- 課題管理の規約: `docs/overview/folder-structure.md` §7

## 完了済みタスク

- [x] **worklog 実運用堅牢化サイクル**: model 定義訂正（Issue-0031）・エンコーディング契約＋読み側検証（Issue-0030, ADR-0054）・start-work availability 規範（Issue-0024, ADR-0055）。merge `50bef04`。簡易 retrospective で Issue-0032 起票。worklog entry -04 記録・ストア CR 正規化（2026-07-18）
- [x] **worklog v1.1 改訂サイクル**: スキーマ v2 化（model/v 必須・friction string[]）。ADR-0048〜0053。merge `ba7e81d`（2026-07-17〜18）
- [x] **3スキルパイプライン初回実装サイクル**: worklog-record/extract/skillify 新規追加。ADR-0044〜0047。merge `7ed7b32`（2026-07-17）
- [x] （以前のサイクルは過去の handoff / retrospective 参照）

## 進行中のタスク

（なし。サイクル完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化。目安:

1. [ ] **Issue-0032**（system・新規）: worklog-extract の健全性検証の具体的検出手段（例コマンド）が未定義。次に worklog-extract を実装/実運用する時に一括具体化が効率的（小規模。今回 `grep -P` が環境依存で誤検出・`od` が確実、という実例あり）
2. [ ] **Issue-0003 / Issue-0008**（system）: conversation_log.md の分類 / 旧型式 spec 8本の維持方針 — どちらもユーザーの方針決めが主
3. [ ] **Issue-0021**（flow）: Tech Notes の横断再利用の仕組み — 中規模テーマ（brainstorming から設計し直す）
4. [ ] **Issue-0006 / 0015 / 0020 / 0022**（flow）: 検証・プロセス品質系の低優先課題群
5. [ ] **Issue-0028**（system）: worklog マルチユーザー・組織展開 — v2 テーマ（職場運用具体化時に着手）
6. [ ] **retrospective 課題 A / C（不起票）**: 再発したら改めて検討（A: 規範系対策提案時に被害規模を添える観点 / C: Accepted ADR の in-place 改定の可否・注記フォーマット）
7. [ ] **Theme C 問題A**「プロジェクト固有用語集（ユビキタス言語）の仕組み」: 大テーマ（brainstorming からの本格サイクル）
8. [ ] **ループプロファイル抽出サイクル**（ADR-0043）: LoopForAlpha での実証完了後に着手する大テーマ

## 既知のブロッカー・懸念

- **プラグイン未更新（要対応）**: 本サイクルは skills/（start-work / worklog-record / worklog-extract）を改定した。反映にはユーザーの `/plugin marketplace update ai-driven-dev-principles` が必要（AI 実行不可。ADR-0055/Issue-0024）。**未実行のため、現在ロードされているスキル本文は旧版**（worklog-record SKILL は「model＝記録時」の旧文言のまま表示された。実際の記録は確定済み ADR-0048 改定に従い delta 発生元＝Opus 4.8 で実施）
- **中央ストアの現状**: `$HOME/.ai-dev-worklog/MakeAiInstructions/log.jsonl` に 6 件（`2026-07-17-01`=v1 / `-02`=v2 / `2026-07-18-01〜03`=worklog v1.1 サイクル / `-04`=本サイクルの course-A delta）。全行 CR 除去済み・UTF-8/BOM なし/LF。`processed.jsonl` は未作成。バックアップ（正規化前）は本セッションの scratchpad に `log.jsonl.bak`
- **inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定（2026-07-17 明言）**。organize-inbox 提案は不要
- **モデルまたぎ運用**: ユーザーは主作業＝高性能モデル・事後処理＝安価モデルの使い分けを恒常運用する意向。worklog の `model` は「delta 発生元」で埋める（ADR-0048 改定済み）
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` は確認済み（構造化質問ツール使用前に毎回確認。ADR-0036）
- ADR-0023 の留意点（継続）: GitHub.com の Copilot コーディングエージェント（CLI 以外）がルート `CLAUDE.md` を読まない可能性

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **直近サイクルは完了**: 実装・merge・簡易 retrospective・worklog 記録済み。追加作業不要
3. **プラグイン更新の確認**: skills/ を改定済み。まだ `/plugin marketplace update ai-driven-dev-principles` を実行していなければ、新しい作業の前にユーザーへ依頼（Phase -1 の新 step 4＝ADR-0055 に従い AI 側 availability で判定）
4. **次サイクルの候補（着手はユーザー判断）**: Issue-0032（worklog-extract 検証手段の具体化）は小規模。他は上記バックログ参照
5. **最初に確認すべきファイル**: 本ファイル、`docs/records/retrospectives/system/2026-07-18-worklog-operational-hardening.md`、`docs/working/issues/README.md`
6. **LoopForAlpha を開始する場合**（ADR-0043）: 引継ぎ書 `D:\Dev\001_Trade\LoopForAlpha\HANDOVER.md` を正とする
7. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行（本サイクルはいずれも非変更＝実行不要だった）
   - skills/ を編集したらプラグイン更新まで反映されない（Issue-0024/ADR-0055）
   - コミット・マージメッセージのマルチライン文字列は `git commit -F <file>` / `git merge --no-ff -F <file>` で渡す（Bash=POSIX sh。Issue-0015）。未追跡ファイルへのパス指定コミットは不可（先に `git add`）
   - 中央ストアへの追記は UTF-8/BOM なし/LF（POSIX `>>` か PowerShell `utf8NoBOM`）。健全性は `od` でバイト確認が確実（`grep -P` は環境依存。Issue-0032）
   - ADR 起票時は置換対象の特定（ADR-0042）・1決定=1ADR（Issue-0022）。コミット済み Proposed の不採用は Rejected 化（ADR-0041）

## 重要な意思決定の履歴

- ADR-0054/0055: worklog 中央ストアのエンコーディング契約＋読み側検証 / start-work Phase -1 の availability 判定規範（2026-07-18, **Accepted**）
- ADR-0048（改定）: model 定義を「記録時」→「delta 発生元」へ in-place 訂正（2026-07-18, Accepted・改定注記あり）
- ADR-0048〜0053: worklog v1.1 改訂（2026-07-17〜18, Accepted）
- ADR-0044〜0047: 3スキルパイプライン（2026-07-16〜17, Accepted）
- ADR-0043: ループエンジニアリングは実証先行・現行体系は対話モード専用（2026-07-08, Accepted）
- ADR-0041/0042: Rejected 経路 / Superseded 置換対象特定・台帳監査（2026-07-07, Accepted）
- （ADR-0001〜0040 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
