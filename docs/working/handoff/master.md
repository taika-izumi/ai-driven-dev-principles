# Handoff: Post ラッパー消化可視化サイクル完了・次サイクル待ち

- **Branch**: master（feature/worklog-record-firing-reliability を merge `9464574` として取り込み・feature ブランチ削除済み）
- **Last Updated**: 2026-08-03 (Asia/Tokyo)
- **Status**: ready-for-next-cycle（実装・master merge・retrospective・worklog 記録まで完了。次サイクル着手はユーザー判断）
- **Current Phase**: 全フェーズ完了。次サイクル着手はユーザー判断

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

**直近サイクル（2026-08-01〜03: Post ラッパー消化の可視化 = Issue-0037 対処）**: 着手時の実データ調査（中央ストア LoopForAlpha 88件/本repo 9件・git 履歴）で起票時の前提「Post ラッパーへ戻る契機が構造的に無い」を**反証**し、課題を「**消化漏れの検出不能性**」（未発火と記録ゲート棄却が外形的に区別できない）へ再定義した上で対処した（ADR-0057/0058 Accepted、merge `9464574`）。

- **ADR-0057**: handoff に「Post ラッパー消化記録」節を新設し、マイルストーンごとに ADR 候補検出と worklog-record の判定結果（棄却含む）を1行残す。完全未入場（行そのものが無い）は即時検出が原理的に不可能なため、retrospective Phase 3 の **git log 突合**で事後回収する二段構え
- **ADR-0058**: worklog-record の発火契機に「セッション切り替え・コンテキスト逼迫による中断の直前」を追加（節目かどうかを問わない）。start-work のセッション終了処理に finalize 前の worklog-record ステップを追加
- **改定スキル4件**: session-handoff `6c8b3c1` / start-work `e6df0ff` / retrospective `993d96a` / worklog-record `38f8f55`
- **重要な発見**: LoopForAlpha の高い消化率は Claude Code プロジェクトメモリ（`feedback-follow-mandatory-steps`）による補完で説明がつく。体系外・不可視の機構への依存として **Issue-0039 起票**
- **ドッグフーディング**: 消化記録を同サイクル内で開始。retrospective の突合手順は初回適用で未消化1件（writing-plans 完了時の記入漏れ）を実際に検出した

その前のサイクル（2026-07-31）は retrospective の役割再定義（ADR-0056）。さらに前は worklog 実運用堅牢化（ADR-0054/0055）、worklog スキーマ v2（ADR-0048〜0053）、3スキルパイプライン（ADR-0044〜0047）。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open: system 0003/0008/0028/0032/0036、flow 0006/0015/0020/0021/0022/0033/0034/0038/0039）
- 直近サイクルの retrospective: `docs/records/retrospectives/system/2026-08-03-post-wrapper-consumption-visibility.md` / `flow/` 同名
- 直近サイクルの plan: `docs/working/plans/2026-08-02-post-wrapper-consumption-visibility.md`（Task1〜5 全完了）
- 改定 spec: `docs/current/specs/2026-04-25-record-strengthening-design.md`（§5.3.1）/ `2026-07-17-worklog-skill-pipeline/02-skill1-record.md` / `2026-05-01-retrospective-design.md`（Phase 3）
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0058。Rejected 3件）
- worklog スキーマ正典: `skills/worklog-record/references/store-format.md`（v2）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] **Post ラッパー消化可視化サイクル**: ADR-0057/0058（Accepted）。スキル4件改定・仕様書3件書き換え・Issue-0037 close（前提反証による書き換えを含む）・Issue-0039 起票・消化記録ドッグフーディング開始。merge `9464574`（2026-08-01〜03）
- [x] **retrospective 役割再定義サイクル**: ADR-0056。merge `066b4e0`（2026-07-31）
- [x] **worklog 実運用堅牢化サイクル**: ADR-0054/0055。merge `50bef04`（2026-07-18）
- [x] （以前のサイクルは過去の handoff / retrospective 参照）

## 進行中のタスク

（なし。サイクル完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化。目安:

1. [ ] **Issue-0038**（flow）: 確定済み記録が後日反証された場合の更新経路がない — 2026-08-01 に同型事例（Issue-0037 の起票元分析の反証）で射程拡張済み。小〜中規模
2. [ ] **Issue-0022**（flow）: ADR 粒度（1決定=1ADR）・文章量の確認観点 — 2026-08-03 にユーザー再提起。LoopForAlpha の再発実例（1 ADR に決定9件 → 4本へ分割、`LoopForAlpha-2026-07-19-02`）あり。worklog-extract の横断走査でも検出見込み
3. [ ] **Issue-0039**（flow・新規）: ガイドライン遵守の Claude Code メモリ依存（不可視性） — 対処方法 TBD。方向性候補は issue に記載
4. [ ] **Issue-0032**（system）: ストア健全性検証の具体的検出手段（バイト直接カウント例示。小規模）
5. [ ] **Issue-0021**（flow）: Tech Notes の横断再利用 — ADR-0056 で解消方向。**close 判断がユーザー待ち**
6. [ ] **Issue-0033 / 0034**（flow）: worklog-extract 初回走査の採用候補
7. [ ] **Issue-0003 / 0008 / 0036**（system）: conversation_log 分類 / 旧型式 spec 方針（2026-08-01 に旧パス表記残存を追記）/ 単発エントリ扱い
8. [ ] **Issue-0006 / 0015 / 0020**（flow）: 検証・プロセス品質系の低優先課題群
9. [ ] **Issue-0028**（system）: worklog マルチユーザー・組織展開 — v2 テーマ
10. [ ] **worklog-extract の再走査**: 中央ストアは LoopForAlpha 88件＋本repo 11件に成長。前回走査（2026-07-31）以降の未処理分が蓄積
11. [ ] **ループプロファイル抽出サイクル**（ADR-0043）: LoopForAlpha での実証完了後に着手する大テーマ

## 既知のブロッカー・懸念

- **プラグイン未更新（要対応・2サイクル分蓄積）**: 未反映の skills/ 改定が **前サイクル（retrospective 3ファイル）＋本サイクル（session-handoff / start-work / retrospective / worklog-record の4ファイル）** に及ぶ。ローカル操作セッションで `/plugin marketplace update ai-driven-dev-principles` の実行が必要（AI 実行不可。ADR-0055）。未更新の間、ロードされるスキル本文は旧版のため、**コミット済み SKILL.md を直接読んで新手順を適用する**（2026-07-31・2026-08-03 の両セッションで実績あり）
- **モデル条件付き規範の再評価（新規・worklog 記録済み）**: セッション途中の `/model` 切替後、モデル条件付き規範（Fable 5 の AskUserQuestion 同一ターンテキスト非表示への対処）の再評価漏れが発生（`MakeAiInstructions-2026-08-03-01`）。Fable 5 では説明テキストを質問と別ターンに分離すること
- **中央ストアの現状**: 本repo 11件（`2026-07-17-01`〜`2026-08-03-01`）＋ LoopForAlpha 88件。全行 CR 0・BOM なし・UTF-8/LF をバイト直接カウントで検証済み（grep 系は不可。Issue-0032）
- **inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定（2026-07-17 明言）**。organize-inbox 提案は不要
- **モデルまたぎ運用**: worklog の `model` は「delta 発生元」で埋める（ADR-0048）。本サイクルは Opus 5 → Fable 5 と切替
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` は確認済み（構造化質問ツール使用前に毎回確認。ADR-0036）
- ADR-0023 の留意点（継続）: GitHub.com の Copilot コーディングエージェントがルート `CLAUDE.md` を読まない可能性

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。master 上の新規マイルストーン発生時に記入（直近サイクル分は `feature_worklog-record-firing-reliability.md` 参照）。

（次サイクル開始後に記入）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read。改定後の read は消化記録の空白検査を含む）
2. **プラグイン更新**: ローカル操作セッションであれば、新しい作業の前に `/plugin marketplace update ai-driven-dev-principles` をユーザーへ依頼（2サイクル分未反映。ADR-0055）
3. **直近サイクルは完了**: 追加作業不要
4. **次サイクルの候補（着手はユーザー判断）**: Issue-0038（更新経路。射程拡張済み）/ Issue-0022（ADR 粒度。ユーザー再提起あり）/ Issue-0039（メモリ依存。TBD）/ Issue-0032（小規模）/ worklog-extract 再走査。Issue-0021 の close 可否も要判断
5. **最初に確認すべきファイル**: 本ファイル、`docs/records/retrospectives/system/2026-08-03-post-wrapper-consumption-visibility.md`、`docs/working/issues/README.md`
6. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **Post ラッパーは1項目ずつ消し込み、結果を消化記録へ書く**（ADR-0057。handoff update ≠ worklog-record の免除）。セッション終了時は finalize 前に worklog-record（ADR-0058）
   - Fable 5 では AskUserQuestion と同一ターンに説明テキストを書かない（表示されない。説明は独立ターンで）
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行（本サイクルは対象外のため未実行）
   - skills/ を編集したらプラグイン更新まで反映されない（ADR-0055）
   - コミット・マージのマルチライン文字列は `git commit -F <絶対パスの一時ファイル>`（Issue-0015）
   - 中央ストアへの追記は UTF-8/BOM なし/LF。健全性はバイト直接カウント（Issue-0032）
   - ADR 起票時は置換対象の特定（ADR-0042）・1決定=1ADR（Issue-0022。粒度再提起あり）

## 重要な意思決定の履歴

- ADR-0057: Post ラッパーの消化結果を handoff に残し、未入場は事後突合で回収（2026-08-01, **Accepted**）
- ADR-0058: worklog-record の発火契機にセッション切り替え直前を追加（2026-08-01, **Accepted**）
- ADR-0056: retrospective を課題抽出記録に純化し worklog へ委譲（2026-07-31, Accepted）
- ADR-0054/0055: エンコーディング契約＋読み側検証 / availability 判定規範（2026-07-18, Accepted）
- ADR-0044〜0053: worklog パイプライン導入と v1.1 改訂（2026-07-16〜18, Accepted）
- ADR-0043: ループエンジニアリングは実証先行（2026-07-08, Accepted）
- （ADR-0001〜0042 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
