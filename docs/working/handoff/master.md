# Handoff: Issue-0033/0034 スキル化サイクル完了・次サイクル待ち

- **Branch**: master（feature/skillify-subagent-dispatch-and-pre-review を merge `da2d351` として取り込み・feature ブランチ削除済み）
- **Last Updated**: 2026-08-05 (Asia/Tokyo)
- **Status**: ready-for-next-cycle（実装・master merge・retrospective・worklog 記録まで完了。次サイクル着手はユーザー判断）
- **Current Phase**: 全フェーズ完了。次サイクル着手はユーザー判断

> 注: `ready-for-next-cycle` は `retrospective` スキル Phase 3 が指定する値だが、`session-handoff` スキルが定義する Status（`in_progress` / `paused` / `completed`）には含まれない。この不整合は `LoopForAlpha#Issue-0087` として配布先で起票済み、取り込みは繰り延べ中（ADR-0062）。より具体的な指示である `retrospective` 側に従っている。

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

**直近サイクル（2026-08-05: Issue-0033/0034 のスキル化）**: `adopted` のまま 4 サイクル滞留していた 2 課題を worklog パイプラインの出口（`skillified`）へ初めて到達させた（ADR-0070〜0073 の 4 本、merge `da2d351`）。

- **`skills/subagent-dispatch/` 新設**: 委譲プロンプトの制約ブロック。A 群 4 件は無条件、B 群 5 条件は判定表の全行読み下ろし＋判定行で担保（ADR-0070/0071）
- **`skills/pre-finalization-review/` 新設**: 非コード成果物の確定前に実証を課した 3 観点独立レビュー。発動はユーザー指示のみ・提示は writing-plans / feature-block-design 完了後に毎回（ADR-0067/0072）
- **過剰適合の防止を規範化**: 設計承認後のユーザーレビューで 3 点を修正。各項目に根拠 id・観測モデル世代を添え、退役規範を新設。ミューテーション 3 項目は単一プロジェクト出所のため適用例へ降格（ADR-0073）
- **配線**: `start-work` Phase 2 マッピング表＋横断的ラッパー Pre。README スキル一覧の記載漏れ 3 件（worklog 系）も補完

その前のサイクル（2026-08-05 午前）は配布先 flow 課題の取り込みと worklog パイプラインの疎通（ADR-0061〜0069）。さらに前は ADR 粒度規範（0059/0060）、Post ラッパー消化可視化（0057/0058）。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open: system 0003/0008/0028/0036、flow 0006/0015/0020/0021/0038/0039/0042/0043/0044/0045/0046/0047/0048）
- 直近サイクルの retrospective: `docs/records/retrospectives/system/2026-08-05-skillify-dispatch-and-pre-review.md`（flow/ ファイルなし。新規フロー起票 0 件）
- 直近サイクルの plan: `docs/working/plans/2026-08-05-dispatch-and-pre-review-skills.md`（Task 1〜6 全完了）
- 直近サイクルの spec: `docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md`
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0073。Rejected 3件）
- worklog スキーマ正典: `skills/worklog-record/references/store-format.md`（v2）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] **Issue-0033/0034 スキル化サイクル**: ADR-0070〜0073（Accepted）。スキル 2 件新設・start-work 配線・README 補完。Issue-0033/0034 close、Issue-0047/0048 起票。台帳 31→33 行（skillified 2 件）。merge `da2d351`（2026-08-05）
- [x] **配布先 flow 課題の取り込みと worklog パイプライン疎通サイクル**: ADR-0061〜0069。merge `a0b16c9`（2026-08-05）
- [x] （以前のサイクルは過去の handoff / retrospective 参照）

## 進行中のタスク

（なし。サイクル完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化。次サイクルの候補として目安を示す:

1. [ ] **構造観察型の配布先課題の取り込み**（ADR-0062 で繰り延べ、2 サイクル経過）: `LoopForAlpha#Issue-0085`（ハンドオフ肥大）/ `#0086`（振り返りカデンス）/ `#0087`（Status 値の不整合）/ `#0042`（規模再見積もり。本repo Issue-0046 と同一主題）/ `#0008`（免除条件）/ `#0013`（素材消失）
2. [ ] **Issue-0045**（flow）: 既存 open 課題の対策方針の実行可能性点検。**棚卸し 1 回で相当数が片付く可能性**。open が 17 件まで増えており価値が上がっている
3. [ ] **Issue-0044**（flow）: スキル改定の同セッション検証不可。**本サイクルで前提を揺るがす観測あり**（directory 参照 marketplace はリポジトリ直読みの可能性）。実測 1 回で対処方針が決まる状態
4. [ ] **Issue-0042/0043**（flow）: 検出器の検出力 / 意思決定要求の front-load
5. [ ] **Issue-0020**（flow）: ステージング内容の確認。**再発累計 3 回**（本サイクルで「ステージ済み別件の混入」型が追加）。機械 gate の調査から
6. [ ] **Issue-0047/0048**（flow・新規）: フックによる A 群機械注入 / 退役候補の機械検出。いずれも意図的な繰り延べで、着手材料は Issue 本文に記録済み（0048 は worklog 数サイクル蓄積後が安い）
7. [ ] **Issue-0008**（system）ほか低優先課題群 / **Issue-0028**（system・v2 テーマ）/ ループプロファイル抽出（ADR-0043）

## 既知のブロッカー・懸念

- **プラグイン更新が必要（未実施）**: 本サイクルで `skills/subagent-dispatch`・`skills/pre-finalization-review` を新設し `skills/start-work` を改定。`/plugin marketplace update ai-driven-dev-principles` をユーザーが実行し、新スキル 2 件が available-skills 一覧へ現れるか確認すること（ADR-0055。結果は Issue-0044 の材料）
- **新設スキルは実運用ゼロ**: `subagent-dispatch` の判定行・`pre-finalization-review` の 3 観点レビューは一度も実際の委譲・レビューで使われていない。次に委譲・plan 確定が発生するサイクルが初回実測になる（ADR-0070 の効き目測定は worklog の同型 delta 再発の有無で行う）
- **`Add-Content` は使わないこと**。中央ストアへの追記は Python `open(path, "a", encoding="utf-8", newline="\n")`（ADR-0064）
- **クロス repo の課題参照は `<repo>#Issue-NNNN` で修飾**（ADR-0068）
- **中央ストアの現状**: 本repo 21 件（〜`2026-08-05-07`）＋ LoopForAlpha 106 件。台帳 33 行（adopted 5 / skillified 2 / deferred 11 / rejected 2 / merged 1 ほか）。健全性 `check-store-health.py` exit=0 確認済み（2026-08-05）
- **inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定**。organize-inbox 提案は不要。`git add <ディレクトリ>` で巻き込まないこと（Issue-0020）
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` は確認済み（構造化質問ツール使用前に毎回確認。ADR-0036）
- ADR-0023 の留意点（継続）: GitHub.com の Copilot コーディングエージェントがルート `CLAUDE.md` を読まない可能性

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。直近サイクル中の分は `feature_skillify-subagent-dispatch-and-pre-review.md` 参照（retrospective Phase 3 で突合済み・未消化なし）。

- 2026-08-05 master merge（`da2d351`）+ retrospective 完了: ADR=なし（振り返りは課題抽出のみ。ADR-0021） / worklog=棄却（振り返り実施中の delta なし。サイクル分は `MakeAiInstructions-2026-08-05-07` で記録済み）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **最初にユーザーへ依頼すること**: `/plugin marketplace update ai-driven-dev-principles`（スキル 2 件新設＋start-work 改定。ADR-0055）
3. **更新後に確認すること**: available-skills 一覧に `ai-driven-dev-principles:subagent-dispatch` / `pre-finalization-review` が現れるか。結果を Issue-0044 の検討状況へ追記する（directory 参照の直読み仮説の検証を兼ねる）
4. **直近サイクルは完了**: 追加作業不要。抽出課題は起票済み（新規なし。Issue-0044/0020 へ追記のみ）
5. **次サイクルの候補（着手はユーザー判断）**: 上記「未着手のタスク」1〜3 が目安。構造観察型の取り込み（2 サイクル繰り延べ）と Issue-0045（棚卸し）が有力
6. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **サブエージェント委譲時は `subagent-dispatch` を呼ぶ**（本サイクルで start-work Pre へ配線済み。初回実運用）
   - **plan / spec 確定時は `pre-finalization-review` を毎回提示する**（実施はユーザー判断。ADR-0072）
   - Post ラッパーは1項目ずつ消し込み、結果を消化記録へ書く（ADR-0057）。worklog id は省略せず全体を書く
   - コミット前に `git status --short` を確認し、**untracked の巻き込みだけでなくステージ済み別件の混入も見る**（Issue-0020。本サイクルで後者が再発）
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行（skills 改定では不要）
   - コミット・マージのマルチライン文字列は `git commit -F <絶対パスの一時ファイル>`（Issue-0015）

## 重要な意思決定の履歴

- ADR-0070: 委譲の常時制約は規範文で実装し、フック機械注入は採らない（2026-08-05, **Accepted**）
- ADR-0071: B 群の発火判定は行数固定の表の読み下ろし＋判定行で担保（2026-08-05, **Accepted**。固定条項は 0073 で部分修正）
- ADR-0072: 確定前レビューの発動はユーザー指示に限り、提示は毎回（2026-08-05, **Accepted**）
- ADR-0073: 規範項目に根拠・世代を添え、実測にもとづく退役経路を持たせる（2026-08-05, **Accepted**。ADR-0066/0071 を部分修正）
- ADR-0061〜0069: 前サイクル（配布先課題の取り込みと worklog パイプライン疎通）
- （ADR-0001〜0060 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
