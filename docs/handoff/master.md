# Handoff: 質問・意思決定時の選択肢＋推奨提示規範の追加

- **Branch**: master
- **Last Updated**: 2026-06-16 22:17 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: 選択肢＋推奨提示規範サブプロジェクト完了・master merge & push 済（ADR-0024 Accepted）/ 今サイクルの retrospective 未実施（ユーザー判断待ち）

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

今サイクルは「AIがユーザーに質問・意思決定を求めるとき、必ず選択肢を提示し、その中で推奨する選択肢と理由を明示する」規範の追加。実現手段はガイドライン修正かスキル修正かを brainstorming で検討し、発動条件が「常時」かつ「数行で表現できる」ことから、**Layer 2 `CLAUDE.md` への対話規範追加＋Layer 1 原則4 への一文補足**（案A）を採用した（ADR-0024）。規範はツール非依存とし、Copilot CLI の `ask_user`・Claude Code の `AskUserQuestion` 双方で機能する書き方とした。既存スキルは改修せず、横断規範でカバーする。

## 関連ドキュメント

- 今サイクルの spec: `docs/specs/2026-06-16-choice-with-recommendation-design.md`
- 今サイクルの plan: `docs/plans/2026-06-16-choice-with-recommendation-plan.md`
- 今サイクルの ADR: `docs/decisions/0024-choice-with-recommendation-norm.md`（Accepted）
- 前サイクルの ADR: `docs/decisions/0023-unify-layer2-into-claude-md.md`（Accepted）
- 原則: `docs/principles.md`（原則4 に規範追加）
- Layer 2 指示: `CLAUDE.md`（「ユーザーへの質問と意思決定要求」サブセクション追加）
- 拡張ルール: `CONTRIBUTING.md`
- ADR インデックス: `docs/decisions/README.md`（0001〜0024）
- 未決事項: `docs/open-questions.md`
- スキル一覧: `README.md`

## 完了済みタスク

- [x] **選択肢＋推奨提示規範の追加**: master merge & push 済（merge: `4a833de`、push: `f414367..4a833de`）。ADR-0024 Accepted
  - `docs/principles.md` 原則4 に「人間の判断を仰ぐ際は、可能な限り選択肢を提示し、推奨する選択肢とその理由を明示する」を追加
  - `CLAUDE.md` に「ユーザーへの質問と意思決定要求」サブセクションを追加（発動条件・推奨形式「（推奨）」先頭・ツール非依存・自由記述の例外条項）
  - `scripts/sync-template.ps1` で template 同期（ルート ≡ template、冪等性確認済み）
  - 既存スキル・README・CONTRIBUTING は改修不要（YAGNI、既存「CLAUDE.md を更新するとき」シナリオで説明可能）
- [x] （前サイクル）Claude Code 対応（Layer 2 を CLAUDE.md に一本化）: ADR-0023 Accepted
- [x] （前サイクル）retrospective スキル改善: ADR-0021 Accepted
- [x] （前サイクル）ADR記述規律: ADR-0019 Accepted
- [x] （前サイクル）AIの言葉遣いの明確性規範: ADR-0022 Accepted

## 進行中のタスク

なし

## 未着手のタスク

- [ ] **今サイクル（選択肢＋推奨提示規範）の retrospective**: 未実施。master merge 直後の振り返り（フロー/ガイドライン課題の抽出）。実施するかは次セッションのユーザー判断。前サイクル（Claude Code 対応）の retrospective も未実施のまま持ち越し中
- [ ] **Theme C 問題A「プロジェクト固有用語集（ユビキタス言語）の仕組み」**: 持ち越し。ハンドオフ等の成果物で使うドメイン用語を一元管理する用語集の置き場・作成タイミング・管理スキルを設計する（規模: 中）。推奨フロー: `start-work` → `extend-guidelines` → brainstorming
- [ ] （別件・低優先）ADR-0013（knowledge-distillation 新設）/ ADR-0014（親ディレクトリ先行確認）: Proposed のまま

## 既知のブロッカー・懸念

- ADR-0023 の留意点（継続）: `.github/copilot-instructions.md` を廃止したため、GitHub.com の Copilot コーディングエージェント（CLI 以外）がルート `CLAUDE.md` を読まない可能性がある。その用途が必要になれば AGENTS.md 併設の再検討が要る
- ADR-0024 の留意点: Claude Code の `AskUserQuestion` ツールの存在は高確度の認識だが、引数仕様の詳細までは公式ドキュメントで完全確認していない。仕様詳細に踏み込む場合は別途確定確認が必要
- `docs/open-questions.md` に未解決1件: template同期の非対称性（`sync-template.ps1` はADRインデックスを空生成するが `docs/retrospectives/README.md` は repo固有行ごとコピーする）。小改善候補
- `docs/conversation_log.md` は untracked のまま（ユーザーのフィードバック記録。コミット対象外）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **最初に確認すべきファイル**:
   - 本ファイル `docs/handoff/master.md`
   - `docs/decisions/0024-choice-with-recommendation-norm.md`（今サイクルの決定）
3. **最初に実行すべきコマンド**:
   - `git --no-pager log --oneline -5` で merge `4a833de` を確認
   - `git status` で untracked（conversation_log）の扱いを判断
4. **次に走らせる作業（候補）**:
   - 今サイクル（選択肢＋推奨提示規範）の retrospective を実施するかユーザーに確認（任意。前サイクル分も未実施）
   - もしくは Theme C 問題A「用語集の仕組み」に着手（`extend-guidelines` → brainstorming）
5. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **Layer 2 = ルート `CLAUDE.md`**（ADR-0023）。`.github/copilot-instructions.md` はもう存在しない
   - `CLAUDE.md` / `principles.md` / template対象スキルを変更したら `scripts/sync-template.ps1` を実行
   - **新規範（ADR-0024）**: 質問・意思決定要求時は選択肢＋推奨（「（推奨）」先頭）を提示。自由記述が本質的に必要な場合のみ例外
   - **ADR-0019**（決定のみ記載・未決は open-questions・Proposed→確定で Accepted）、**ADR-0021**（retrospective は課題抽出のみ・system/flow 2フォルダ）、**ADR-0022**（説明的な用語を使う）を守る

## 重要な意思決定の履歴

- ADR-0024: 質問・意思決定要求時に選択肢と推奨を提示する規範を追加（2026-06-16, Accepted）
- ADR-0023: Layer 2 を CLAUDE.md に一本化し Claude Code / Copilot CLI 両対応（2026-06-16, Accepted）
- ADR-0022: AIの言葉遣いの明確性規範を Layer 2 に追加（2026-06-15, Accepted）
- ADR-0021: retrospective を課題抽出に限定し出力を system/flow に分割（2026-06-15, Accepted）
- ADR-0020: responding-to-user 必須化の廃止 + ask-user-enforcer 撤去（2026-06-15, Accepted）
- ADR-0019: ADR記述規律 — 決定のみ記載・未決事項の分離・承認の遅延昇格（2026-06-15, Accepted）
- （ADR-0001〜0018 は `docs/decisions/README.md` 参照）
