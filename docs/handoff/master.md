# Handoff: ガイドライン/スキル改善 — ユーザーフィードバック対応

- **Branch**: master
- **Last Updated**: 2026-06-15 22:53 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: フィードバック対応 Theme A・B・C(B) 完了 / Theme C(A)「用語集の仕組み」未着手 / 今サイクルの retrospective はスキップ

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

今サイクルは、ユーザーが `docs/conversation_log.md` の **188行目以降** に記載したガイドライン/スキルへの不満・改善案への対応。フィードバックを複数テーマに分割し、テーマごとに1つずつ片付ける方針。

- **Theme A「retrospective スキル改善」**: 完了・master merge 済（`7e398a8`）。ADR-0021 Accepted。
- **Theme B「ADR記述規律」**: 完了・master merge 済（`ee1b2e7`）。ADR-0019 Accepted。
- **Theme C「ユビキタス言語」**: 2つの問題に分解した。
  - **問題B（AIの言葉遣い規範）**: 完了・master merge 済（`b247467`）。ADR-0022 Accepted。← 今セッションで対応
  - **問題A（プロジェクト固有用語集の仕組み）**: 未着手。別サイクルへ送った（ADR-0022 でスコープ外と決定）。

## 関連ドキュメント

- フィードバック元: `docs/conversation_log.md`（188行目以降。Theme C 原文は 206-208行目）
- 原則: `docs/principles.md`
- 拡張ルール: `CONTRIBUTING.md`
- ADR: 0001〜0022（`docs/decisions/README.md` 参照）
- 未決事項: `docs/open-questions.md`
- 今サイクルの spec: `docs/specs/2026-06-15-naming-clarity-discipline-design.md`
- 今サイクルの plan: `docs/plans/2026-06-15-naming-clarity-discipline-plan.md`
- スキル一覧: `README.md`

## 完了済みタスク

- [x] **Theme A「retrospective スキル改善」**: master merge 済（`7e398a8`）。ADR-0021 Accepted
- [x] **Theme B「ADR記述規律」**: master merge 済（`ee1b2e7`）。ADR-0019 Accepted
- [x] **別件: responding-to-user 撤去**: master merge 済（`8a64619`）。ADR-0020 Accepted
- [x] **Theme C 問題B「AIの言葉遣いの明確性規範」**: master merge 済（`b247467`）。ADR-0022 Accepted
  - `.github/copilot-instructions.md` の「コンテキスト管理」セクションに行動規範2点を追加:
    - 対話・成果物ドキュメントで使う用語は説明的にし、その場限りの略号・記号的呼称（「Aモード」「Primary/Secondary」等）を避ける
    - 初出のプロジェクト固有用語には簡潔な説明を添える
  - アプローチA採用（Layer 2 のみ。`principles.md` と Skill は変更しない。原則3の系）
  - `scripts/sync-template.ps1` で `template/` へ同期済み
  - 個人メモリに依存していた「説明的名称を使う」規範をリポジトリ共有ガイドラインへ昇格

## 進行中のタスク

なし

## 未着手のタスク

- [ ] **Theme C 問題A「プロジェクト固有用語集（ユビキタス言語）の仕組み」**（次サイクルの最有力候補）
  - 内容: ハンドオフ等の成果物で使うプロジェクト固有ドメイン用語を一元管理する用語集の置き場・作成タイミング・管理方法を設計する
  - 規模: 中（用語集の置き場・フロー上の作成タイミング・どのスキルが管理するか）
  - ADR-0022 で「今サイクルはスコープ外、別サイクルへ」と決定済み
  - 推奨フロー: `start-work` → `extend-guidelines` → brainstorming

### 今サイクルの retrospective（スキップ済み）

- [ ] **今サイクル（Theme A/B/C-B 等）の retrospective**: 今セッションではユーザー判断でスキップ。実施するかは次セッション以降のユーザー判断に委ねる。実施する場合 ADR-0021 後の新フロー（課題抽出のみ・system/flow 2フォルダ出力）の初回ドッグフーディングになる

### 旧サイクルからの持ち越し（別件・低優先）

- [ ] ADR-0013（knowledge-distillation スキル新設）: Proposed のまま
- [ ] ADR-0014（新規ファイル作成時の親ディレクトリ先行確認）: Proposed のまま
- [ ] Improvement Draft #3/#4/#5（前々サイクルの保留提案）: 再発時に格上げ判断

## 既知のブロッカー・懸念

- `docs/open-questions.md` に未解決1件: **template同期の非対称性**（`sync-template.ps1` はADRインデックスを空生成するが `docs/retrospectives/README.md` は repo固有行ごとコピーする）。小改善候補。
- `docs/conversation_log.md` は untracked のまま（ユーザーのフィードバック記録。コミット対象外）。

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **最初に確認すべきファイル**:
   - 本ファイル `docs/handoff/master.md`
   - `docs/conversation_log.md` 206-208行目（Theme C 原文。問題A「用語集の仕組み」が残課題）
   - `docs/decisions/0022-naming-clarity-discipline.md`（問題A をスコープ外にした決定の経緯）
3. **最初に実行すべきコマンド**:
   - `git --no-pager log --oneline -8` で Theme C-B merge（`b247467`）を確認
   - `git status` で untracked の扱いを判断
4. **次に走らせる作業**:
   - 推奨: Theme C 問題A「用語集の仕組み」に着手（用語集の置き場・作成タイミング・管理スキルを brainstorming で設計）
   - `extend-guidelines` → brainstorming で設計合意 → 実装 → master merge
   - 今サイクルの retrospective を実施するかをユーザーに確認（スキップ済みのため任意）
5. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **ADR-0019 を守ること**: ADRには決定のみ記載・未決事項は `docs/open-questions.md` へ・Proposed 作成→確定チェックポイントで Accepted 昇格
   - **ADR-0021 を守ること**: retrospective は課題抽出のみ・出力は system/flow の2フォルダ・Tech Notes は汎用知見限定
   - **ADR-0022 を守ること**: 対話・成果物で説明的な用語を使い、その場限りの略号・記号的呼称を避ける
   - copilot-instructions.md / principles.md / template対象スキルを変更したら `scripts/sync-template.ps1` を実行

## 重要な意思決定の履歴

- ADR-0019: ADR記述規律 — 決定のみ記載・未決事項の分離・承認の遅延昇格（2026-06-15, Accepted）
- ADR-0020: responding-to-user 必須化の廃止 + ask-user-enforcer プラグイン撤去（2026-06-15, Accepted）
- ADR-0021: retrospective を課題抽出に限定し、出力を system/flow に分割（2026-06-15, Accepted。ADR-0010/0011 を一部改定）
- ADR-0022: AIの言葉遣いの明確性規範を copilot-instructions に追加（Theme C をBに限定・問題Aは別サイクル）（2026-06-15, Accepted）
- （ADR-0001〜0018 は `docs/decisions/README.md` 参照）
