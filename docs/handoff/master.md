# Handoff: ガイドライン/スキル改善 — ユーザーフィードバック対応

- **Branch**: master
- **Last Updated**: 2026-06-15 19:54 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: フィードバック対応 Theme A・B 完了 / 別件「responding-to-user 撤去」完了 / Theme C 未着手

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

今サイクルは、ユーザーが `docs/conversation_log.md` の **188行目以降** に記載したガイドライン/スキルへの不満・改善案への対応。フィードバックを3テーマに分割し、テーマごとに1つずつ片付ける方針（Theme 2「作業フロー終端」は対応不要と確定し除外）。

- **Theme A「retrospective スキル改善」**: 完了・master merge 済（`7e398a8`）。ADR-0021 Accepted。
- **Theme B「ADR記述規律」**: 完了・master merge 済（`ee1b2e7`）。ADR-0019 Accepted。
- **Theme C「ユビキタス言語」**: 未着手。プロジェクト固有用語集の導入（ハンドオフ等での固有用語濫用を防ぐ）

## 関連ドキュメント

- フィードバック元: `docs/conversation_log.md`（188行目以降）
- 原則: `docs/principles.md`
- 拡張ルール: `CONTRIBUTING.md`
- ADR: 0001〜0019（`docs/decisions/README.md` 参照）
- 未決事項: `docs/open-questions.md`（今サイクルで新設）
- スキル一覧: `README.md`

## 完了済みタスク

- [x] **Theme A「retrospective スキル改善」**: master merge 済（`7e398a8`）。ADR-0021 Accepted
  - retrospective スコープを「課題抽出と分類」に限定。旧 Phase 4（採用判断の即時ADRドラフト化）を撤去
  - 抽出課題はバックログ記録のみ。対策の着手はユーザー判断（必ず次サイクルではない）
  - 課題を「対象システム固有 / 開発フロー」に分類し `docs/retrospectives/system/` と `flow/` の2フォルダへ出力（flow-template.md 新設）
  - Tech Notes を汎用技術知見に限定（システム仕様/ドメイン知識は除外、ADR-0012 準拠）
  - 波及更新: decision-log（トリガー#7・昇格表行を撤去）/ start-work / CONTRIBUTING（retrospective変更シナリオ＋「課題に対策するとき」シナリオに改題）/ README / copilot-instructions / retrospectives README
  - ADR-0010（Phase構造）/ ADR-0011（保管パス）に改定注記。template 同期済。code-review で重大な不整合なし
- [x] **Theme B「ADR記述規律」**: master merge 済（`ee1b2e7`）
  - decision-log: ADRは決定のみ記載 / 未決事項は `docs/open-questions.md`（スナップショット型）へ分離 / Proposedで作成し確定チェックポイントでAccepted昇格（承認プロンプトに「保留」追加）/ status変更と承認昇格の責務分離 + 網羅的チェックポイント
  - `docs/open-questions.md` 新規（オンデマンド作成・template非同期）
  - CONTRIBUTING に「未決事項を記録するとき」シナリオ追加 + ADRシナリオ補強
  - copilot-instructions に簡潔規則2点追加（sync-template 反映済）
  - start-work Phase 2 Post に据え置きADR昇格を追記
  - ADR-0019 作成 → 実装完了で Accepted 昇格
  - code-review サブエージェントのレビュー反映済（status変更/昇格の重複解消、catch-allチェックポイント追加）

## 進行中のタスク

なし

## 別件: responding-to-user 撤去（完了）

- [x] **responding-to-user 必須化の廃止 + ask-user-enforcer プラグイン撤去**: master merge 済（`8a64619`）。ADR-0020 Accepted。
  - `.github/copilot-instructions.md` の「システム設定 / responding-to-user スキル」節を削除（template同期済）
  - `ask-user-enforcer` プラグイン（arche-plugins, v4.0.0）を `copilot plugin uninstall` で撤去（config.json / キャッシュ削除を確認）
  - 効果は次セッション以降（応答前の responding-to-user 強制呼び出しは不要になる）
  - 過去サイクルの plan/spec に残る言及は履歴として保持

## 未着手のタスク

- [ ] **Theme C「ユビキタス言語」**（次セッションの最有力候補）
  - 規模: 中（用語集の置き場・フロー上の作成タイミング・どのスキルが管理するか）
  - 推奨フロー: `start-work` → `extend-guidelines` → brainstorming
- [ ] **残テーマ完了後の retrospective**（今サイクルぶんを1回でまとめて実施する想定。ユーザーの意向次第。ADR-0021 で system/flow 2フォルダ・課題抽出限定に変わった新フローでの初回ドッグフーディングになる）

### 旧サイクルからの持ち越し（今サイクルとは別件・低優先）

- [ ] ADR-0013（knowledge-distillation スキル新設）: Proposed のまま
- [ ] ADR-0014（新規ファイル作成時の親ディレクトリ先行確認）: Proposed のまま
- [ ] Improvement Draft #3/#4/#5（前々サイクルの保留提案）: 再発時に格上げ判断

## 既知のブロッカー・懸念

- `docs/open-questions.md` に未解決1件: **template同期の非対称性**（`sync-template.ps1` はADRインデックスを空生成するが `docs/retrospectives/README.md` は repo固有行ごとコピーする）。Theme群とは別の小改善候補。
- `docs/conversation_log.md` は untracked のまま（ユーザーのフィードバック記録。コミット対象外）。
- ハンドオフが plugin-distribution サイクル（ADR-0015〜0018, merge済）を反映しないまま今サイクル用に再構成した。詳細履歴は `git log` 参照。

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **最初に確認すべきファイル**:
   - 本ファイル `docs/handoff/master.md`
   - `docs/conversation_log.md` 206行目以降（Theme C「ユビキタス言語」の原文フィードバック）
3. **最初に実行すべきコマンド**:
   - `git --no-pager log --oneline -10` で Theme A merge（`7e398a8`）を確認
   - `git status` で untracked の扱いを判断
4. **次に走らせる作業**:
   - 推奨: Theme C「ユビキタス言語」に着手（用語集の置き場・作成タイミング・管理スキルを brainstorming で設計）
   - `extend-guidelines` → brainstorming で設計合意 → 実装 → master merge
   - Theme C 完了後、今サイクルぶんの retrospective をまとめて実施するかユーザーに確認（ADR-0021 後の新フロー初回ドッグフーディング）
5. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **ADR-0019 を必ず守ること**: ADRには決定のみ記載・未決事項は `docs/open-questions.md` へ・ADRは Proposed 作成→確定チェックポイントで Accepted 昇格
   - **ADR-0021 を必ず守ること**: retrospective は課題抽出のみ（対策の採否・設計・ADR化はしない）・出力は system/flow の2フォルダ・Tech Notes は汎用知見限定
   - copilot-instructions.md / principles.md / template対象スキル（retrospectives/README.md 等）を変更したら `scripts/sync-template.ps1` を実行
   - 残テーマ完了後に retrospective をまとめて実施するか、テーマ単位かはユーザーに確認

## 重要な意思決定の履歴

- ADR-0019: ADR記述規律 — 決定のみ記載・未決事項の分離・承認の遅延昇格（2026-06-15, Accepted）
- ADR-0020: responding-to-user 必須化の廃止 + ask-user-enforcer プラグイン撤去（2026-06-15, Accepted）
- ADR-0021: retrospective を課題抽出に限定し、出力を system/flow に分割（2026-06-15, Accepted。ADR-0010/0011 を一部改定）
- （ADR-0001〜0018 は `docs/decisions/README.md` 参照）
