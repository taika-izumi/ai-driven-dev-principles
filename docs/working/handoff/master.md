# Handoff: worklog v1.1 改訂サイクル完了・次サイクル待ち

- **Branch**: master（feature/worklog-v1.1 を merge `ba7e81d` として取り込み・feature ブランチ削除済み）
- **Last Updated**: 2026-07-18 09:48 (Asia/Tokyo)
- **Status**: completed（実装・master merge・簡易 retrospective 実施済み。次サイクル待ち）
- **Current Phase**: 全フェーズ完了。抽出した課題 Issue-0030（新規）・Issue-0024（再発追記）は次サイクル判断待ち（着手はユーザー判断）

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

**直近サイクル（2026-07-17〜18: worklog v1.1 改訂）**: 3スキルパイプライン（worklog-record → worklog-extract → worklog-skillify）初回実装（merge `7ed7b32`）後に起票された改善課題 6 件を一括対処。中央ストアのエントリ/台帳スキーマを **v2** へ改訂した。決定は ADR-0048〜0053（すべて Accepted）:

- ADR-0048: `model` 必須フィールド追加（delta 発生元モデルの判別）
- ADR-0049: スキーマバージョン `v` を log.jsonl / processed.jsonl 両方に必須導入。読み側規約「`v` なし = v1」を明文化
- ADR-0050: id 採番衝突を「追記直前の再カウント＋追記後の読み直し検証（重複時は自行のみ再採番。追記専用の唯一の例外）」で対処
- ADR-0051: `friction` を string[] 化（delta ペアの型対称）
- ADR-0052: 定性材料（corrections の誤答側・損失規模）はフィールド追加でなく運用ガイドで扱う
- ADR-0053: 記録単位 = 同一 context の delta 束・節目のテーマ単位で複数記録可

既存 v1 データ（`MakeAiInstructions-2026-07-17-01`）は無変更で互換維持。v2 エントリ（`-02`）のスモークテスト合格（BOM なし・LF を実体確認）。Issue-0023/0025/0026/0027/0029 を close、Issue-0028 は v2 据え置き。ADR-0045 に一部改定注記を追加。

その前のサイクル（2026-07-16〜17）は 3スキルパイプラインの新規追加（ADR-0044〜0047）。さらに前は ループエンジニアリング方向性決定（ADR-0043）。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open: system 0003/0008/0028/0030、flow 0006/0015/0020/0021/0022/0024）
- 直近サイクルの plan: `docs/working/plans/2026-07-17-worklog-v1.1.md`（Task1〜7 全完了）
- 直近サイクルの retrospective（簡易版）: `docs/records/retrospectives/system/2026-07-18-worklog-v1.1.md`
- worklog スキーマ正典: `skills/worklog-record/references/store-format.md`（v2）
- worklog spec: `docs/current/specs/2026-07-17-worklog-skill-pipeline/`（01/02 は v2 反映済み。03/04 は初回実装のまま）
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0053。Rejected 3件・部分修正注記あり）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`
- 課題管理の規約: `docs/overview/folder-structure.md` §7

## 完了済みタスク

- [x] **worklog v1.1 改訂サイクル**: スキーマ v2 化（model/v 必須・friction string[]）・id 採番強化・運用ガイド・記録単位規範。ADR-0048〜0053（Accepted）。Issue-0023/0025/0026/0027/0029 close・0028 据え置き。merge `ba7e81d`。簡易 retrospective で Issue-0030 起票・Issue-0024 再発追記（2026-07-18）
- [x] **3スキルパイプライン初回実装サイクル**: worklog-record/extract/skillify 3スキル・中央ストア契約を新規追加。ADR-0044〜0047。merge `7ed7b32`（2026-07-17）
- [x] **ループエンジニアリング方向性決定サイクル**: 実証先行・現行体系は対話モード専用として無変更維持（ADR-0043）。記録のみ（2026-07-08）
- [x] **Issue-0019 対策サイクル**: ADR ステータス体系の完成（Rejected 新設）・台帳監査定義（ADR-0041/0042）。merge `a9c7a5a`（2026-07-07）
- [x] （以前のサイクルは過去の handoff / retrospective 参照）

## 進行中のタスク

（なし。session-handoff finalize でセッション終了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化。目安:

1. [ ] **worklog 実運用堅牢化サイクル（推奨・次サイクル候補）**: 以下 3 件を一括対処が効率的（いずれも小規模・同じ worklog 領域）
   - **Issue-0030**（system・新規）: 中央ストアの文字コード・改行コード規約と追記手段が未定義（UTF-8/BOM なし/LF 固定の明記）
   - **Issue-0031**（system・新規）: worklog の `model` フィールドが「記録時」定義で、モデルまたぎセッションで delta を誤帰属。ADR-0048 文言を「delta 発生元モデル」へ修正。**ユーザーは「主作業＝高性能モデル / 事後処理＝安価モデル」の使い分けを恒常運用する意向を明言（2026-07-18）→ モデルまたぎは常態化する前提**
   - **Issue-0024**（flow・再発）: プラグイン更新後の新規/改定スキル availability 確認手順が start-work Phase -1 に未組み込み
3. [ ] **Issue-0003 / Issue-0008**（system）: conversation_log.md の分類 / 旧型式 spec 8本の維持方針 — どちらもユーザーの方針決めが主
4. [ ] **Issue-0021**（flow）: Tech Notes の横断再利用の仕組み — 中規模テーマ（brainstorming から設計し直す）
5. [ ] **Issue-0006 / 0015 / 0020 / 0022**（flow）: 検証・プロセス品質系の低優先課題群
6. [ ] **Issue-0028**（system）: worklog マルチユーザー・組織展開 — v2 テーマ（職場運用具体化時に着手）
7. [ ] **Theme C 問題A**「プロジェクト固有用語集（ユビキタス言語）の仕組み」: 大テーマ（brainstorming からの本格サイクル）
8. [ ] **ループプロファイル抽出サイクル**（ADR-0043）: トレード戦略プロジェクト LoopForAlpha での実証完了後に着手する大テーマ

## 既知のブロッカー・懸念

- **inbox 残置 3 件＋ conversation_log.md はユーザーが手動で別の場所へ移動予定（2026-07-17 明言）**。organize-inbox の提案は不要。次セッションの start-work Phase 1 でも検知されるが、提案せず残置してよい（うち `2026-07-17-worklog-entry-format-rationale.md` は worklog 設計意図ドキュメント）
- **中央ストアの現状**: `$HOME/.ai-dev-worklog/MakeAiInstructions/log.jsonl` に 5 件（`2026-07-17-01`=v1 旧スキーマ / `-02`=v2 スモークテスト / `2026-07-18-01〜03`=本セッションの実 delta 記録）。`processed.jsonl` は未作成（採否「保留」のため）。**v1 行は書き換えない**運用を維持。2026-07-18-01〜03 は worklog v1.1 サイクル自体の delta（store 追記の utf8NoBOM / 推奨の判断根拠 front-load / retrospective 簡易モード）を記録済み
- **モデルまたぎ運用**: ユーザーは主作業を高コストモデル・事後処理を安価モデルで行う使い分けを恒常運用する意向（2026-07-18 明言）。worklog の `model` 帰属は当面「delta 発生元モデル」で埋める（ADR-0048 文言修正待ち＝Issue-0031）
- **スキーマ v2 反映済み**: 2026-07-18 に本セッションでプラグイン更新（`√ Updated 1 marketplace`）。以後も skills/ 改定時は `/plugin marketplace update ai-driven-dev-principles` が必要（AI 側から実行不可＝Issue-0024）
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` は 2026-07-17 確認済み。構造化質問ツール使用前に毎回確認すること（ADR-0036）
- ADR-0023 の留意点（継続）: GitHub.com の Copilot コーディングエージェント（CLI 以外）がルート `CLAUDE.md` を読まない可能性

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **直近サイクルは完了**: 実装・merge・簡易 retrospective 済み。追加作業不要。次サイクルへ
3. **次サイクルの推奨候補（着手はユーザー判断）**: Issue-0030（中央ストア エンコーディング規約）＋ Issue-0024（プラグイン availability 確認）を **worklog 実運用堅牢化サイクル**として一括対処するのが効率的。どちらも小規模
4. **最初に確認すべきファイル**: 本ファイル、`docs/records/retrospectives/system/2026-07-18-worklog-v1.1.md`、`docs/working/issues/README.md`
5. **最初に実行すべき確認**: 構造化質問ツールを使う前に環境変数 `CLAUDE_CODE_DISABLE_MOUSE_CLICKS` が `1` であることを確認（ADR-0036）
6. **LoopForAlpha（別リポジトリ・トレード戦略 PoC）を開始する場合**（ADR-0043）: 引継ぎ書 `D:\Dev\001_Trade\LoopForAlpha\HANDOVER.md` を正とする。PoC 検証項目 ①対話規範（ADR-0035 停止・待機）がヘッドレスループに干渉しないか ②スキル可視範囲のモード制御 ③汎用化候補の学びの記録規律
7. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行
   - skills/ を編集したらプラグイン更新まで反映されない
   - コミット・マージメッセージのマルチライン文字列は `git commit -F <file>` / `git merge --no-ff -F <file>` で渡す（Bash=POSIX sh。Issue-0015）。未追跡ファイルへのパス指定コミットは不可（先に `git add`）
   - ADR 起票時は置換対象の特定（ADR-0042）・1決定=1ADR（Issue-0022）。コミット済み Proposed の不採用は Rejected 化（ADR-0041）
   - 主要 ADR 群（0019/0021/0022/0024/0028/0029/0030/0031/0032/0034/0035/0036/0037/0038/0039/0040/0041/0042、および worklog v2 の 0048〜0053）を守る

## 重要な意思決定の履歴

- ADR-0048〜0053: worklog v1.1 改訂（model 必須 / スキーマ版数 v / id 採番強化 / friction string[] / 定性材料は運用ガイド / 記録単位）（2026-07-17〜18, **Accepted**）
- ADR-0044〜0047: 3スキルパイプライン（中央集約 / スキーマ・ライフサイクル / スキル3借用・環境ガード / start-work Post 配線）（2026-07-16〜17, Accepted）
- ADR-0043: ループエンジニアリングは実証先行・現行体系は対話モード専用として無変更維持（2026-07-08, Accepted）
- ADR-0041/0042: Rejected 経路の定義 / Superseded 置換対象特定・台帳監査（2026-07-07, Accepted）
- （ADR-0001〜0040 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
