# Handoff: AI駆動開発メタ・ガイドラインの段階的整備

- **Branch**: master
- **Last Updated**: 2026-05-01 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: サブプロジェクトA/B/C 完全クローズ（C は初回 retrospective も完了済）

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。プロジェクト全体は複数のサブプロジェクトに分割して段階的に進行している。

- **サブプロジェクトA「記録の強化」**: 完了。意思決定の即時検出ルール、ハンドオフファイル方式、起点スキル `start-work` を導入。
- **サブプロジェクトB「機能ブロック駆動の設計＋仕様書分割」**: 完了。`feature-block-design` スキル導入、原則2の適用範囲拡張、仕様書スナップショット規約導入。
- **サブプロジェクトC「振り返りフェーズ導入」**: 完了。`retrospective` スキル導入 + 初回ドッグフーディング実施済。Improvement Drafts のうち採用2件は ADR-0013 / 0014 として Proposed 起票。実装は次サイクルへ持ち越し。

## 関連ドキュメント

- 原則: `docs/principles.md`（原則5に振り返り運用記載済）
- A/B/C 全 plan: `docs/plans/` 配下
- C spec: `docs/specs/2026-05-01-retrospective-design.md`
- 初回 retrospective: `docs/retrospectives/2026-05-01-retrospective-phase.md`
- ADR: 0004〜0014（README.md のテーブル参照）
- スキル一覧: `README.md` のテーブル参照

## 完了済みタスク

- [x] サブプロジェクトA: master merge 済み（`6bd8a08`）
- [x] サブプロジェクトB: master merge 済み（`6e3a845`）
- [x] サブプロジェクトC: master merge 済み（`49906e8`）
- [x] サブプロジェクトC Task 17（初回 retrospective ドッグフーディング）: feature/retro-c で実施済、CONTRIBUTING 補正コミット + retro 本体 + ADR-0013/0014 起票完了。本ハンドオフ更新後 master へ merge 予定

## 進行中のタスク

なし（feature/retro-c の master merge を残すのみ）

## 未着手のタスク

- [ ] **サブプロジェクトD（仮）「ADR-0013 実装: knowledge-distillation スキル新設」（最有力候補）**
  - 状態: Proposed ADR ドラフトあり
  - 規模: 中〜大（新スキル + `docs/knowledge/` 新設 + 保管規約 ADR の派生可能性）
  - 推奨フロー: フルサイクル（brainstorming → feature-block-design 適用判定 → spec → plan → 実装）

- [ ] **サブプロジェクトE（仮）「ADR-0014 実装: 親ディレクトリ先行確認ルール」（軽量）**
  - 状態: Proposed ADR ドラフトあり
  - 規模: 小（copilot-instructions.md に1文追加 + template 同期）
  - 推奨フロー: 軽量サイクル（`start-work` Phase 2 から writing-plans 直行可）
  - D と E はどちらを先に着手しても可。E の方が短時間で消化できるため、D 着手前のウォームアップに使うこともできる

- [ ] **継続観察（次回 retrospective で再評価）**:
  - Improvement Draft #3（PowerShell here-string 罠回避規約、保留）: 次サイクルで再発したら採用に格上げ
  - Improvement Draft #4（retrospective テンプレ簡略化、保留）: 3サイクル分の retrospective が溜まったら未記入率を集計
  - Improvement Draft #5（plan-実装整合チェック、保留）: 同種ズレが次サイクルで再発したら採用に格上げ

## 既知のブロッカー・懸念

- ADR-0013（knowledge-distillation）の実装着手時、`docs/knowledge/` の保管規約を ADR-0008（スナップショット型）/ ADR-0011（追記型）どちらに倣うか別途決定が必要。新規 ADR-0015 が派生する可能性高い
- `docs/conversation_log.md` および `docs/images/` が untracked のまま残っている（A 開始前から存在する作業外ファイル、扱い未確認）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフファイルを read してくれる）
2. **最初に確認すべきファイル**:
   - 本ファイル `docs/handoff/master.md`
   - `docs/retrospectives/2026-05-01-retrospective-phase.md`（前サイクル振り返り、Improvement Drafts と Handoff Forward を参照）
   - `docs/decisions/0013-introduce-knowledge-distillation-skill.md`（D 候補）
   - `docs/decisions/0014-parent-dir-check-before-file-create.md`（E 候補）
3. **最初に実行すべきコマンド**:
   - `git --no-pager log --oneline -25` で C と feature/retro-c の merge 状況を確認
   - `git status` で untracked ファイルの扱いを判断
4. **次に走らせるスキル / 作業選択**:
   - 推奨: ユーザーに「D（knowledge-distillation 新設）/ E（親dir確認ルール追加）/ 別件」の3択を提示し、選択させる
   - D を選ぶ場合: `superpowers:brainstorming` から開始（中規模以上のため）
   - E を選ぶ場合: `start-work` Phase 2 から `superpowers:writing-plans` に直行可
   - 選択した ADR は実装完了時に Status を Accepted へ昇格させること
5. **留意点**:
   - `retrospective` で記録した提案を取り込む手順は `CONTRIBUTING.md` の「シナリオ: 振り返りで採用された改善提案を取り込みたいとき」に従う
   - retrospective 出力ファイル（`docs/retrospectives/2026-05-01-...`）への加筆は禁止（ADR-0011 追記型規約）。フィードバックは次回 retrospective で記録する
   - master 直接作業は禁止。新サブプロジェクトは feature ブランチを切ること
   - 検出した意思決定は ADR-0006（即時検出）+ decision-log 強トリガー（振り返り採用判断含む）に従い即ドラフト起票

## 重要な意思決定の履歴

- ADR-0004: ワークフロー起点スキル（start-work）の導入（2026-04-27, Accepted）
- ADR-0005: セッション継続のためのハンドオフファイル方式の採用（2026-04-27, Accepted）
- ADR-0006: 意思決定の継続検出ルールの導入（2026-04-27, Accepted）
- ADR-0007: 機能ブロック駆動の設計スキル（feature-block-design）の導入（2026-05-01, Accepted）
- ADR-0008: 仕様書のディレクトリ分割形式とスナップショット規約の採用（2026-05-01, Accepted）
- ADR-0009: 原則2「関心の分離」の適用範囲拡張（2026-05-01, Accepted）
- ADR-0010: 開発サイクル末尾の振り返りフェーズ導入（2026-05-01, Accepted）
- ADR-0011: 振り返り出力の保管規約（時系列追記型）（2026-05-01, Accepted）
- ADR-0012: ドメイン知識抽出は次サイクル課題（C 範囲外、ADR ベースのスコープ宣言）（2026-05-01, Accepted）
- ADR-0013: knowledge-distillation スキル新設（2026-05-01, Proposed → 次サイクルで実装）
- ADR-0014: 新規ファイル作成時の親ディレクトリ先行確認（2026-05-01, Proposed → 次サイクルで実装）
