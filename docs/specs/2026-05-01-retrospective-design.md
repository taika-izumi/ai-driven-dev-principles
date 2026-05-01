# 設計仕様: 開発サイクル末尾の振り返りフェーズ導入（サブプロジェクトC）

- **Status**: Draft（brainstorming 完了、plan 未着手）
- **Author**: メインエージェント（Claude Opus 4.7）+ ユーザー
- **Date**: 2026-05-01
- **Related Handoff**: `docs/handoff/master.md`
- **Predecessors**: ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008, ADR-0009
- **Planned ADRs**: ADR-0010, ADR-0011, ADR-0012

## 1. 概要・目的・スコープ

### 1.1 目的

AI駆動開発のサブプロジェクト1サイクル完了直後に「振り返り」を実施し、以下を構造化テキストとして抽出する仕組みを設ける。

1. ガイドライン・フローへの改善提案ドラフト
2. 古びない技術ノウハウ（再利用可能な技術知見）
3. 次サイクルへの申し送り

### 1.2 背景

本リポジトリではサブプロジェクトA（記録の強化）/ B（機能ブロック駆動の設計）と段階的に開発フローを成熟させてきたが、各サイクル終了時に得られた知見・反省・改善余地が体系的に記録されておらず、次サイクルでの活用が偶発的になっている。サイクル末尾に振り返りを必ず行うことで、メタ・ガイドラインの自己改善ループを定着させる。

### 1.3 スコープイン

- 新スキル `retrospective` の追加（手順 + 出力テンプレ）
- 振り返り出力の保管場所 `docs/retrospectives/YYYY-MM-DD-<topic>.md` 規約化
- start-work Phase 2 ナビゲーション表への統合（「サブプロジェクトクローズ直後」行）
- 振り返り中の採用判断を ADR-0006（即時 ADR 検出ルール）の対象として明文化
- 関連ドキュメント（principles / copilot-instructions / README / CONTRIBUTING / template / handoff）の整合更新
- サブプロジェクトC自身に対する初回振り返りの実施（ドッグフーディング）

### 1.4 スコープアウト

- 振り返りで採用された提案の実際の ADR起票・スキル化（次セッションで `start-work` から再開）
- メトリクス計測（タスク数・手戻り回数など）
- 自動トリガー（merge 検知などの自動化は導入しない）
- **ドメイン知識の抽出・整理スキル**: 本仕様の検討中に重要性が議論されたが、原則2（関心の分離）を保つため本サブプロジェクトCのスコープ外とする。初回 retrospective の Improvement Drafts で正式に提案議題化し、サブプロジェクトDで扱う想定。この扱い自体は ADR-0012 として起票する。

### 1.5 位置づけ

feature ブランチを master にマージ完了し、handoff を completed 状態へ遷移させる前の最後のチェックポイント。**実行は手動**（ユーザー明示指示、または start-work が「最近 merge があり対応 retrospective が無い」ことを検知して推奨提示）。自動トリガーは偽陽性リスクを避けるため導入しない。

## 2. アーキテクチャ

### 2.1 新規ファイル

```
skills/
  retrospective/
    SKILL.md          # 本体（手順・テンプレ参照・サブエージェント呼び出し方）
    template.md       # 振り返り出力ファイルのテンプレート
docs/
  retrospectives/
    .gitkeep          # ディレクトリ初期化
    README.md         # 振り返り一覧インデックス（手動更新、行追加のみ）
docs/decisions/
    0010-introduce-retrospective-phase.md
    0011-retrospective-storage-policy.md
    0012-domain-knowledge-out-of-scope-for-c.md
docs/specs/
    2026-05-01-retrospective-design.md   # 本ファイル
```

### 2.2 既存ファイル変更

- `skills/start-work/SKILL.md`: Phase 2 マッピング表に1行追加 + セッション終了処理直前のチェックリスト更新
- `skills/decision-log/SKILL.md`: 検出トリガー一覧に「振り返り中の採用判断」追記
- `docs/principles.md`: 原則5（漸進的検証）末尾に「サイクル単位の振り返りで検証結果を反映する」一文追加
- `.github/copilot-instructions.md`: 「振り返り運用」項追加
- `template.manifest`: 新規ファイルを追加して `pwsh scripts/sync-template.ps1` 実行
- `README.md`: スキル一覧表に retrospective 追加 + docs ディレクトリ説明に retrospectives/ 追加
- `CONTRIBUTING.md`: 「振り返り提案を後から取り込みたい時」のシナリオ追記
- `docs/handoff/master.md`: サブプロジェクトC完了の状態へ書き換え

### 2.3 他スキルとの関係

| 相手スキル | 関係 |
|---|---|
| start-work | ナビゲーターとして retrospective を提示 |
| decision-log (ADR-0006) | 振り返り中の「採用」判断は即時 ADR 化対象 |
| session-handoff | finalize の直前に retrospective が走ることを推奨。handoff の「次セッション開始時のアクション」へ採用提案実装タスクを書き込む |
| feature-block-design | retrospective は単一責務スキルなので適用不要 |

### 2.4 サブエージェントの役割

- **メイン**: ファシリテーター。git log / handoff / spec / ADR diff を集めてユーザーと対話、テンプレ埋め
- **サブ（rubber-duck 1回呼び出し）**: ドラフト全体に対する独立視点レビュー（盲点・偏り・採用基準の妥当性）

## 3. 振り返り実施フロー（retrospective スキル本体の手順）

### 3.1 Phase 0: 前提収集（メイン）

1. 対象サブプロジェクト名・feature ブランチ名・対応 plan/spec パスをユーザーから受け取る（または直近 merge コミットから推定して確認）
2. 以下を読み込む:
   - 対応 plan ファイル（`docs/plans/...`）
   - 対応 spec ディレクトリ or ファイル（`docs/specs/...`）
   - 該当ブランチの merge コミット範囲の `git log --oneline`
   - `docs/handoff/master.md` 現行版
   - 該当期間に追加・変更された ADR
3. 既存 `docs/retrospectives/` を確認し、同一トピックの既存ファイルが無いことを確認（あれば中止し、上書きの是非をユーザーに確認）

### 3.2 Phase 1: 5観点ヒアリング（メイン、1問ずつ）

ユーザーから順に聞く（1メッセージ1質問）:

1. **Done**: 計画通り完了したこと（plan のタスク達成度）
2. **Went Well**: うまくいったプラクティス
3. **Struggled**: 苦労した点・手戻り・誤解
4. **Learned (Tech Notes)**: 古びない技術知見（PowerShell の罠、ツール挙動など）
5. **Improvement Drafts**: ガイドライン・フロー・スキルへの改善提案（採用 / 保留 / 却下 の判断とともに）

各回答はメインがその場でテンプレに埋めながら、ユーザーが言及していない観点があれば「他に〇〇のような出来事はありませんでしたか？」と問いかける（例: spec 変更履歴から「途中で plan を3回修正してますがその経緯は？」など過去ログから具体ネタを引く）。

### 3.3 Phase 2: ドラフト保存（メイン）

- `docs/retrospectives/YYYY-MM-DD-<topic>.md` に書き出し（テンプレ準拠）
- ユーザーへ提示し、軽く確認

### 3.4 Phase 3: 独立視点レビュー（サブエージェント `rubber-duck` 1回）

プロンプトで渡すもの: ドラフト全文 + plan + 対応 ADR一覧。観点:

- 抽出漏れ（git log にあるが言及されていない事象）
- 改善提案の採用判断の妥当性（過剰採用 / 過小採用）
- ノウハウ項目の「古びなさ」検証（現バージョン依存ではないか）

レビュー結果はメインが受け取り、ユーザーと相談の上、ドラフトに反映。

### 3.5 Phase 4: 採用判断の即時 ADR 化（メイン）

- 「Improvement Drafts」のうち**採用**（実施に進む）と判定したものは、ADR-0006 ルールに従い即時 ADR ドラフト作成（status: Proposed のまま、実装は別セッション）
- 「保留」「却下」はドラフト内に理由とともに記録するのみ

### 3.6 Phase 5: ハンドオフ更新（メイン、`session-handoff update`）

- 「次セッション開始時のアクション」に「採用提案 X / Y を ADR-NNNN / スキル ZZZ として実装」を追記
- handoff Status を completed → ready-for-next-cycle へ

### 3.7 コミット方針

スキル内ではコミットしない。スキルの責務は出力ファイル生成まで。コミットはユーザー or 通常フローに委ねる。

## 4. 出力ファイル仕様

### 4.1 ファイル命名

`docs/retrospectives/YYYY-MM-DD-<topic>.md`（YYYY-MM-DD は振り返り実施日）

### 4.2 テンプレート構造

```markdown
# Retrospective: <サブプロジェクト名>

- **Subject**: <サブプロジェクトの正式名>
- **Branch**: feature/<name> （merge済み: <merge-commit-sha>）
- **Period**: <開始日> 〜 <完了日>
- **Plan**: docs/plans/<...>
- **Spec**: docs/specs/<.../>
- **Related ADRs**: ADR-NNNN, ADR-NNNN
- **Facilitator**: メインエージェント (<モデル名>)
- **Independent Reviewer**: rubber-duck (<モデル名>)

## 1. Done（達成サマリ）
- <plan の主要マイルストーンを箇条書き、対応コミットへのリンク>

## 2. Went Well（うまくいったこと）
- <観点：プロセス／ツール／設計判断／コミュニケーション>

## 3. Struggled（苦労したこと・手戻り）
- **事象**: <何が起きたか>
  - **原因**: <分析>
  - **影響**: <時間損失・スコープ影響など>

## 4. Tech Notes（古びない技術知見）
- **タイトル**: <短い見出し>
  - **コンテキスト**: <発生条件>
  - **知見**: <次に同じ状況に遭ったらこうする>
  - **回避策・代替**: <推奨手順>

## 5. Improvement Drafts（ガイドライン・フロー改善提案）
- **提案 #N**: <一文タイトル>
  - **背景**: <なぜ必要か、対応する 5 原則 / スキル / ADR>
  - **提案内容**: <具体的な変更案>
  - **判断**: 採用 / 保留 / 却下
  - **理由**: <採否の根拠>
  - **採用の場合**: 起票 ADR-NNNN（Proposed）/ 影響範囲: <files>

## 6. Independent Review Notes（rubber-duck 指摘）
- <受領した指摘とメインの応答（採用/反論）>

## 7. Handoff Forward（次サイクルへの申し送り）
- **着手予定**: <採用提案の実装タスク>
- **継続観察**: <まだ判断を要する事象>
```

### 4.3 保管規約

- ADR-0008（スナップショット規約）の **対象外**: retrospective は時系列の記録ファイル。一度書いたら原則上書きしない（typo 修正を除く）
- `docs/retrospectives/README.md` は ADR README と同様にインデックステーブルを手動で更新（行追加のみ、過去行の編集は禁止）

この方針自体を ADR-0011 として独立起票する。

## 5. 既存ガイドラインへの反映 / 起票予定 ADR

### 5.1 起票予定 ADR（plan 第1〜第3タスクで起票）

#### ADR-0010: 開発サイクル末尾の振り返りフェーズ導入

- 主決定: `retrospective` スキルを新設し、サブプロジェクトクローズ時の標準ステップとする
- 検討した代替案:
  - start-work 内蔵化（自動トリガー）: 偽陽性/陰性リスク、原則2違反
  - finishing-a-development-branch 拡張: 上流スキルへの依存増加でリポジトリ独立性低下
- 採用理由: ADR-0007 と同じ「独立スキル + start-work ナビゲーション」パターンで一貫性確保

#### ADR-0011: 振り返り出力の保管規約（時系列追記型）

- 主決定: `docs/retrospectives/YYYY-MM-DD-<topic>.md` 単一ファイル / サブプロジェクト。一度書いたら原則上書き禁止（typo 修正を除く）
- ADR-0008 のスナップショット規約とは別ポリシー
- 採用理由: retrospective は履歴ログとしての価値があり、過去事例の改変を許容すると学習素材にならない

#### ADR-0012: ドメイン知識抽出は次サイクル課題（スコープ判断 ADR）

- 主決定: 本サブプロジェクトCでは扱わず、初回 retrospective の Improvement Drafts で正式提案する
- 検討した代替案:
  - α: retrospective テンプレに Domain Knowledge セクションを1個追加 → 暫定が永続化するアンチパターンリスク
  - β: knowledge-distillation スキルを同時設計 → スコープ膨張、原則2違反
  - γ: 現スコープ維持、初回 retrospective で議題化 → ドッグフーディングになり採用
- 採用理由: 原則2（関心の分離）/ 振り返りスキルの実効性証明素材化

### 5.2 既存ファイル更新一覧

| ファイル | 更新内容 |
|---|---|
| `docs/principles.md` | 原則5（漸進的検証）末尾に「サイクル単位の振り返りで検証結果を反映する」一文追加 |
| `.github/copilot-instructions.md` | 「振り返り運用」項を「ドキュメント運用」セクション内 or 独立セクションとして追加 |
| `skills/start-work/SKILL.md` | Phase 2 マッピング表に「サブプロジェクトクローズ直後 \| retrospective」行追加 + セッション終了処理直前に「対象サブプロジェクトの retrospective 完了確認」追加 |
| `skills/decision-log/SKILL.md` | 検出トリガー一覧に「振り返り中の採用判断」追記 |
| `template.manifest` + `template/` | 新規ファイル群を追加し sync-template.ps1 で同期（差分ゼロ確認） |
| `README.md` | スキル一覧表に retrospective 追加 / docs ディレクトリ説明に retrospectives/ 追加 |
| `CONTRIBUTING.md` | 「振り返り提案を後から取り込みたい時」シナリオ追記 |
| `docs/handoff/master.md` | サブプロジェクトC完了として書き換え + 次セッションのアクションに「初回 retrospective の採用提案を ADR/スキル化」 |

## 6. 実装スコープ・最終チェック

### 6.1 高位タスク列（plan で詳細化する）

1. ADR-0010 / 0011 / 0012 を Proposed で起票
2. `skills/retrospective/SKILL.md` 新規作成
3. `skills/retrospective/template.md` 新規作成
4. `docs/retrospectives/` ディレクトリ + `README.md`（インデックス）+ `.gitkeep` 作成
5. `docs/principles.md` 原則5 末尾に1文追加
6. `.github/copilot-instructions.md` 「振り返り運用」項追加
7. `skills/start-work/SKILL.md` Phase 2 表 + セッション終了処理 更新
8. `skills/decision-log/SKILL.md` 検出トリガーに「振り返り中の採用判断」追記
9. `template.manifest` 追記 + `pwsh scripts/sync-template.ps1` 実行（差分ゼロ確認）
10. `README.md` 更新（スキル表 + docs ディレクトリ案内）
11. `CONTRIBUTING.md` シナリオ追加
12. ADR-0010 / 0011 / 0012 を Accepted 化
13. `docs/handoff/master.md` 書き換え（サブプロジェクトC完了 + Dの種としてドメイン知識抽出を明記）
14. master へ `--no-ff` merge + push
15. **初回 retrospective を本サブプロジェクトC自身に対して実行**（ドッグフーディング、最終検証）

### 6.2 feature-block-design 適用要否判定

- 単一スキル + 周辺整備のみ。機能ブロック分離の必要性は低い → **適用しない**
- spec ファイル自体は単一 md（本ファイル）で記述

### 6.3 進行モード（実装フェーズ）

サブプロジェクトBと同じく **メインセッション直接実行**（タスクが定型的・小粒）。subagent-driven-development は使用しない。

### 6.4 完了基準（Done Definition）

- 全15タスク完了
- `git status` クリーン（untracked の作業外2項目 `docs/conversation_log.md`, `docs/images/` を除く）
- master 上で `pwsh scripts/sync-template.ps1` を実行しても差分ゼロ
- 初回 retrospective ファイル `docs/retrospectives/2026-05-01-retrospective-phase.md`（仮名）が存在し、Improvement Drafts に「ドメイン知識抽出スキル」案が記録されている

### 6.5 Out of Scope（再掲）

- ドメイン知識抽出スキルの設計・実装（サブプロジェクトDで扱う）
- 振り返り採用提案の自動 ADR/スキル化
- 自動トリガー（merge検知など）
- メトリクス計測

## 7. 対応する原則

- **原則1（追跡可能性）**: 振り返り出力ファイルにより各サイクルの判断・反省・採用提案が永続化
- **原則2（関心の分離）**: retrospective を独立スキルとして責務分離 / ドメイン知識抽出をスコープ外とすることで本仕様の単一責務性を保つ
- **原則3（コンテキスト管理）**: 振り返り出力が次サイクル開始時のコンテキスト源になる
- **原則4（人間の関与）**: 5観点ヒアリングが対話形式 / 採用判断はユーザー承認必須 / 自動トリガー禁止
- **原則5（漸進的検証）**: サイクル単位の振り返りでメタ・ガイドライン自体の検証ループを回す（本仕様で原則5の文言も拡張）
