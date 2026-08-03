# Handoff: ADR 粒度・文章量の規範整備サイクル完了・次サイクル待ち

- **Branch**: master（feature/adr-granularity-and-size を merge `9a3f70e` として取り込み・feature ブランチ削除済み）
- **Last Updated**: 2026-08-04 (Asia/Tokyo)
- **Status**: ready-for-next-cycle（実装・master merge・retrospective・worklog 記録まで完了。次サイクル着手はユーザー判断）
- **Current Phase**: 全フェーズ完了。次サイクル着手はユーザー判断

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

**直近サイクル（2026-08-03〜04: ADR 粒度・文章量の規範整備 = Issue-0022 対処）**: 再提起で拡張された3論点（粒度の確認観点 / Proposed への追記継続による主題ドリフト / 文章量の上限目安）をすべて決着させた（ADR-0059/0060 Accepted、merge `9a3f70e`）。

- **ADR-0059**: ADR の粒度は「後から探しに来るときの問い」1つを単位とする。**文章量は基準にしない**ことを実測に基づき明示決定（分割は総文章量を 5,545 → 13,918文字へ増やし、肥大 ADR より大きい正常な ADR が存在するため、閾値は見逃しと誤検出を同時に生む）
- **ADR-0060**: 点検は「決定の追記時（一次経路）＋ Accepted 昇格前（受け皿）」。いずれも既存操作へ内包させ、Post ラッパーの消化項目を増やさない。規範は `decision-log` に一本化し `start-work` は参照のみ
- **改定**: `skills/decision-log`（起票時の blockquote `aa5b686` / 追記手順の新設 `94ff0a9` / 承認の昇格へ突合ステップ `4bfca43`）、`skills/start-work`（参照1文 `f5bdb8e`）、記録強化仕様 §5.3.1・§7.4（`2f0520c`）
- **設計の根拠は配布先の実測**: LoopForAlpha の ADR-0034 は決定9件まで肥大し4本へ分割（`6ea5d48`）。被参照ファイルは分割時10 → 昇格時24 → 2週間後40と拡大し、決定序数参照275回の振り直しを伴った。本 repo だけを見ると分割は軽い（序数参照5回）ため、**自 repo の実測だけでは誤った設計を選ぶところだった**

その前のサイクル（2026-08-03）は Post ラッパー消化の可視化（ADR-0057/0058）。さらに前は retrospective の役割再定義（ADR-0056）、worklog 実運用堅牢化（ADR-0054/0055）。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open: system 0003/0008/0028/0032/0036、flow 0006/0015/0020/0021/0033/0034/0038/0039/0040）
- 直近サイクルの retrospective: `docs/records/retrospectives/system/2026-08-04-adr-granularity-norms.md` / `flow/` 同名
- 直近サイクルの plan: `docs/working/plans/2026-08-04-adr-granularity-norms.md`（Task1〜7 全完了）
- 改定 spec: `docs/current/specs/2026-04-25-record-strengthening-design.md`（§5.3.1 / §7.4）
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0060。Rejected 3件）
- worklog スキーマ正典: `skills/worklog-record/references/store-format.md`（v2）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] **ADR 粒度・文章量の規範整備サイクル**: ADR-0059/0060（Accepted）。スキル2件改定・仕様書1件更新・Issue-0022 close・Issue-0040 起票。merge `9a3f70e`（2026-08-03〜04）
- [x] **Post ラッパー消化可視化サイクル**: ADR-0057/0058。merge `9464574`（2026-08-01〜03）
- [x] **retrospective 役割再定義サイクル**: ADR-0056。merge `066b4e0`（2026-07-31）
- [x] （以前のサイクルは過去の handoff / retrospective 参照）

## 進行中のタスク

（なし。サイクル完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化。目安:

1. [ ] **Issue-0038**（flow）: 確定済み記録が後日反証された場合の更新経路がない — 小〜中規模
2. [ ] **Issue-0039**（flow）: ガイドライン遵守の Claude Code メモリ依存（不可視性）— 対処方法 TBD
3. [ ] **Issue-0040**（flow・新規）: CONTRIBUTING.md のテンプレート同期指示が現行構成と矛盾 — 小規模。他シナリオの追従漏れも併せて点検する価値あり
4. [ ] **Issue-0008**（system）: 旧型式 spec の維持/アーカイブ方針 — **2サイクル連続で同一ファイル（記録強化 spec）にドリフトが顕在化**。優先度が上がっている
5. [ ] **Issue-0032**（system）: ストア健全性検証の具体的検出手段（小規模）
6. [ ] **Issue-0021**（flow）: Tech Notes の横断再利用 — ADR-0056 で解消方向。**close 判断がユーザー待ち**
7. [ ] **Issue-0033 / 0034**（flow）: worklog-extract 初回走査の採用候補
8. [ ] **Issue-0003 / 0036**（system）: conversation_log 分類 / 単発エントリ扱い
9. [ ] **Issue-0006 / 0015 / 0020**（flow）: 検証・プロセス品質系の低優先課題群
10. [ ] **Issue-0028**（system）: worklog マルチユーザー・組織展開 — v2 テーマ
11. [ ] **worklog-extract の再走査**: 中央ストアは LoopForAlpha 88件＋本repo 13件。前回走査（2026-07-31）以降の未処理分が蓄積
12. [ ] **ループプロファイル抽出サイクル**（ADR-0043）: LoopForAlpha での実証完了後に着手する大テーマ

## 既知のブロッカー・懸念

- **プラグイン更新が必要（未実施）**: 本サイクルで `skills/decision-log` と `skills/start-work` を改定したため、`/plugin marketplace update ai-driven-dev-principles` をユーザーが実行するまで実行環境へ反映されない（AI からは実行不可。ADR-0055）。**次サイクル開始前に実行すること**。反映は available-skills 一覧の記述で確認できる
- **新規範の運用観察**: ADR-0059 の「問いの立て方の幅」により粒度判定は一意に定まらない。本サイクルでも ADR-0060 の決定3（規範の置き場所）の帰属が境界例となり、分割不要と判断した。事例を積んで幅を狭める段階
- **中央ストアの現状**: 本repo 13件（`2026-07-17-01`〜`2026-08-04-01`）＋ LoopForAlpha 88件。健全性はバイト直接カウントで検証（grep 系は不可。Issue-0032）
- **inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定（2026-07-17 明言）**。organize-inbox 提案は不要
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` は確認済み（構造化質問ツール使用前に毎回確認。ADR-0036）
- ADR-0023 の留意点（継続）: GitHub.com の Copilot コーディングエージェントがルート `CLAUDE.md` を読まない可能性

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。直近サイクル中の分は `feature_adr-granularity-and-size.md` 参照（突合済み・未消化なし）。

- 2026-08-04 master merge + retrospective 完了: ADR=なし（振り返りは課題抽出のみで意思決定を行わない。ADR-0021） / worklog=`MakeAiInstructions-2026-08-04-02`
- 2026-08-04 セッション終了（切り替え直前。ADR-0058）: ADR=なし（終了処理に意思決定なし） / worklog=同上（`MakeAiInstructions-2026-08-04-02`。終了処理と同一 context のため1件に集約）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **最初にユーザーへ依頼すること**: `/plugin marketplace update ai-driven-dev-principles`（本サイクルで skills/ を2件改定済み。ADR-0055）
3. **直近サイクルは完了**: 追加作業不要
4. **次サイクルの候補（着手はユーザー判断）**: Issue-0008（2サイクル連続で顕在化・優先度上昇）/ Issue-0040（小規模・新規）/ Issue-0038 / Issue-0039 / worklog-extract 再走査。Issue-0021 の close 可否も要判断
5. **最初に確認すべきファイル**: 本ファイル、`docs/records/retrospectives/system/2026-08-04-adr-granularity-norms.md`、`docs/working/issues/README.md`
6. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **ADR を起票・追記・昇格するときは新規範が適用される**（ADR-0059/0060）。追記時はタイトル突合、昇格時は第1ステップで粒度点検
   - Post ラッパーは1項目ずつ消し込み、結果を消化記録へ書く（ADR-0057）。セッション終了時は finalize 前に worklog-record（ADR-0058）
   - **ガイドラインは配布物**。設計判断の根拠データは本 repo だけでなく配布先（LoopForAlpha）でも取ること（本サイクルの delta。`MakeAiInstructions-2026-08-04-01`）
   - 既存ファイルへ追記するときはパスを記憶から組み立てず Glob で解決する。自分が書いた markdown を grep で検査するときは強調・リンク記法を含まない識別子をパターンにする（`MakeAiInstructions-2026-08-04-02`）
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行（skills 改定では不要。Issue-0040）
   - コミット・マージのマルチライン文字列は `git commit -F <絶対パスの一時ファイル>`（Issue-0015）
   - 中央ストアへの追記は UTF-8/BOM なし/LF。健全性はバイト直接カウント（Issue-0032）

## 重要な意思決定の履歴

- ADR-0059: ADR の粒度は「後から探しに来るときの問い」で決め、文章量は基準にしない（2026-08-03, **Accepted**）
- ADR-0060: ADR 粒度の点検を決定追記の手順に組み込み、昇格前の一括点検を受け皿とする（2026-08-03, **Accepted**）
- ADR-0057/0058: Post ラッパー消化の可視化 / worklog-record のセッション切り替え契機（2026-08-01, Accepted）
- ADR-0056: retrospective を課題抽出記録に純化し worklog へ委譲（2026-07-31, Accepted）
- ADR-0054/0055: エンコーディング契約＋読み側検証 / availability 判定規範（2026-07-18, Accepted）
- ADR-0044〜0053: worklog パイプライン導入と v1.1 改訂（2026-07-16〜18, Accepted）
- ADR-0043: ループエンジニアリングは実証先行（2026-07-08, Accepted）
- （ADR-0001〜0042 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
