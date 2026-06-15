# Handoff: ガイドライン/スキル改善 — ユーザーフィードバック対応

- **Branch**: master
- **Last Updated**: 2026-06-15 19:54 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: フィードバック対応 Theme B 完了 / 別件「responding-to-user 撤去」完了 / Theme A・C 未着手

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

今サイクルは、ユーザーが `docs/conversation_log.md` の **188行目以降** に記載したガイドライン/スキルへの不満・改善案への対応。フィードバックを3テーマに分割し、テーマごとに1つずつ片付ける方針（Theme 2「作業フロー終端」は対応不要と確定し除外）。

- **Theme A「retrospective スキル改善」**: 未着手。(a) 振り返りで対策決定までやらず課題抽出に留める (b) 陳腐化しない技術知識に開発対象システムの仕様を挙げない (c) 開発フロー改善案は個別システムrepoでなく本リポジトリ側へ向ける
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

- [ ] **Theme A「retrospective スキル改善」**（次セッションの最有力候補）
  - 規模: 中（`skills/retrospective/SKILL.md` + テンプレート + CONTRIBUTING の retrospective シナリオ + おそらく ADR）
  - 推奨フロー: `start-work` → `extend-guidelines` → brainstorming（CONTRIBUTING「retrospectiveを変更するとき」シナリオが制約）
- [ ] **Theme C「ユビキタス言語」**
  - 規模: 中（用語集の置き場・フロー上の作成タイミング・どのスキルが管理するか）
  - 推奨フロー: 同上
- [ ] **3テーマ完了後の retrospective**（今サイクルぶんを1回でまとめて実施する想定。ユーザーの意向次第）

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
   - `docs/conversation_log.md` 188行目以降（Theme A・C の原文フィードバック）
   - `skills/retrospective/SKILL.md` と `CONTRIBUTING.md` の「retrospectiveを変更するとき」シナリオ（Theme A 着手時）
3. **最初に実行すべきコマンド**:
   - `git --no-pager log --oneline -10` で Theme B merge を確認
   - `git status` で untracked の扱いを判断
4. **次に走らせる作業**:
   - 推奨: ユーザーに Theme A / Theme C のどちらから着手するか確認（A 推奨）
   - 選択後 `extend-guidelines` → brainstorming で設計合意 → 実装 → master merge
5. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **今サイクルで導入した新ルール（ADR-0019）を必ず守ること**: ADRには決定のみ記載・未決事項は `docs/open-questions.md` へ・ADRは Proposed 作成→確定チェックポイントで Accepted 昇格
   - copilot-instructions.md / principles.md / template対象スキルを変更したら `scripts/sync-template.ps1` を実行
   - 3テーマ完了後に retrospective をまとめて実施するか、テーマ単位かはユーザーに確認

## 重要な意思決定の履歴

- ADR-0019: ADR記述規律 — 決定のみ記載・未決事項の分離・承認の遅延昇格（2026-06-15, Accepted）
- ADR-0020: responding-to-user 必須化の廃止 + ask-user-enforcer プラグイン撤去（2026-06-15, Accepted）
- （ADR-0001〜0018 は `docs/decisions/README.md` 参照）
