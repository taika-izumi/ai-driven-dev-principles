# 開発プロジェクトのフォルダ構成定義 — 全体仕様

## 1. このドキュメントの読み方

本ディレクトリは「開発プロジェクトのフォルダ構成定義」サブプロジェクトの分割仕様書である。現時点のシステム全容のスナップショットとして維持する。

| ファイル | 内容 |
|---------|------|
| `00-overview.md`（本ファイル） | 概要、機能ブロック一覧、処理フロー、意思決定、スコープ外、完了基準 |
| `01-folder-structure-definition.md` | 定義本体ドキュメント `docs/overview/folder-structure.md` の仕様 |
| `02-organize-inbox-skill.md` | organize-inbox スキルと start-work への inbox 検知組み込みの仕様 |
| `03-skill-path-updates.md` | 既存スキル群のパス参照更新と未決事項運用の改訂の仕様 |
| `04-layer-docs-updates.md` | CLAUDE.md / principles.md / CONTRIBUTING.md / README の更新仕様 |
| `05-template-sync-update.md` | template.manifest / sync-template.ps1 / template/ の更新仕様 |
| `06-repo-docs-migration.md` | 本リポジトリ既存 docs の新構成への移行仕様 |

## 2. 背景・動機

本ガイドラインのドキュメント配置規約は各スキル・ADR に断片的に定義されており、規約に列挙されていない種類のドキュメント（議事録、用語集、リリース手順など）の置き場が開発時のAIの都度判断に委ねられていた。「情報の更新頻度とライフサイクルの長さ」による情報分類体系を導入し、開発プロジェクト全体のフォルダ構成を体系的に定義する（ADR-0025）。あわせて、分類に迷う情報の受け皿として inbox と organize-inbox スキルを導入する（ADR-0026）。

## 3. 全体アーキテクチャ

### 情報分類体系（5分類）

分類軸は「話題」ではなく**情報の性質（更新様式 × ライフサイクルの長さ）**。

| # | 分類 | 性質 | 代表例 |
|---|------|------|--------|
| 1 | オリエンテーション | 低頻度更新・恒久。参画直後のキャッチアップ情報 | プロジェクト概要、用語集、体制 |
| 2 | 現在の正 | 書き換え型スナップショット・恒久 | 仕様書、アーキテクチャ、ロードマップ |
| 3 | 進行中の作業 | 高頻度更新・短寿命・クローズされる | 課題（issue）、handoff、実装計画 |
| 4 | 追跡型の記録 | 確定後不変・追記型・恒久 | ADR、議事録、retrospective、リリースノート |
| 5 | 参照知識 | 低頻度改訂・恒久 | リリース手順、既知エラー、調査メモ |

### 標準フォルダレイアウト

```
docs/
  overview/        # 1. オリエンテーション
  current/         # 2. 現在の正（specs/ 等）
  working/         # 3. 進行中の作業（issues/ handoff/ plans/）
  records/         # 4. 追跡型の記録（decisions/ retrospectives/ minutes/ 等）
  reference/       # 5. 参照知識
  inbox/           # 未分類の投入口（organize-inbox が処理）
```

種別サブフォルダはオンデマンド作成（空フォルダを先行作成しない）。

### 機能ブロック一覧

| # | ブロック | 責務 | 依存 |
|---|---------|------|------|
| 01 | folder-structure-definition | 定義本体ドキュメントの作成 | なし |
| 02 | organize-inbox-skill | organize-inbox スキル新設＋start-work への inbox 検知追加 | 01 |
| 03 | skill-path-updates | 既存スキルのパス参照更新＋未決事項運用の改訂 | 01 |
| 04 | layer-docs-updates | Layer 1/2 文書と README の更新 | 01 |
| 05 | template-sync-update | テンプレート配布機構の新構成対応 | 01, 04 |
| 06 | repo-docs-migration | 本リポジトリ既存 docs の移行 | 01, 03 |

```
01 ──┬──> 02
     ├──> 03 ──┬──> 06
     ├──> 04 ──┴──> 05
```

**順序制約**: `skills/start-work/SKILL.md` はブロック03（パス更新）とブロック02（inbox 検知追加）の両方が触る。実装は 03 → 02 の順で適用する。

## 4. 主要な処理フロー

### フロー A: ドキュメントの配置判断（日常運用）

1. 作成・受領した情報の性質（更新様式・ライフサイクル）を判断する
2. `docs/overview/folder-structure.md` の分類基準（境界判断基準3つを含む）に照らして分類を決める
3. 該当分類フォルダの種別サブフォルダ（なければ分類フォルダ直下、または新サブフォルダを作成）に配置する
4. 迷った場合は `docs/inbox/` に置く（分類判断を organize-inbox に委ねる）

### フロー B: inbox 処理

1. ユーザーが情報を `docs/inbox/` に投入する
2. start-work の状況診断（Phase 1）が inbox の未分類ファイルを検知し、organize-inbox の実行を提案する（またはユーザーが任意のタイミングで直接実行する）
3. organize-inbox が1件ずつ分類し、移動・分割・既存ファイルへの追記統合を行う（詳細は `02-organize-inbox-skill.md`）

### フロー C: 課題（issue）のライフサイクル

1. 課題・未決事項を検出したら `docs/working/issues/system|flow/NNNN-<slug>.md` を起票する（Status: open。分類は ADR-0028）
2. 検討が長期化・多観点化したら各分類フォルダ内で `NNNN-<slug>/` フォルダへ昇格できる
3. 対策方針が決定したら ADR を作成し、課題を Status: closed に変更する（進行中の作業 → 追跡型の記録への遷移）
4. クローズ済み課題はその場に残す（アーカイブフォルダへは移動しない）

## 5. 設計上の主要な意思決定

- ADR-0025: 情報の5分類体系を導入し、ドキュメント構成を全面再配置する（分類軸、境界判断基準、蒸留規則、`open-questions.md` の課題管理への統合、本リポジトリへの自己適用を含む）
- ADR-0026: inbox フォルダと organize-inbox スキルによる情報分類の仕組みを導入する（スキル名の選定、分割・追記統合を含む機能スコープ、start-work 検知を含む）
- ADR-0024: 質問・意思決定要求時の選択肢＋推奨提示（organize-inbox の曖昧時確認フローが準拠する）
- ADR-0019: ADR記述規律（未決事項の分離先が `open-questions.md` から課題管理へ変わる。規律自体は維持）
- ADR-0027: テンプレート初期セットの基準（ユーザー直接操作フォルダとインデックス継続性フォルダをシードし、スキル自動生成フォルダはシードしない）とインデックス空生成の一般化
- 機能ブロック分割は ADR-0025/0026 で承認済みの実装対象から導出したものであり、独立の ADR は起票しない

## 6. スコープ外（YAGNI）

- クローズ済み課題・完了 handoff のアーカイブ機構（状態管理のみで運用し、必要になったら別サイクルで導入）
- 議事録・用語集などの個別テンプレート整備（置き場の定義のみ行う）
- 分類の自動監査（誤配置の検出）スキル
- 既存の完了済みドキュメント（過去の ADR・retrospective・完了 handoff・過去 plan/spec）本文中の旧パス表記の書き換え（記録の不変性を優先。詳細は `06-repo-docs-migration.md`）
- GitHub Issues 等の外部課題管理との連携

## 7. 完了基準

1. `docs/overview/folder-structure.md` が存在し、5分類・境界判断基準・蒸留規則・標準レイアウト・課題運用・コード配置原則を単体で読める（スナップショットとして完結）
2. organize-inbox スキルが存在し、README のスキル一覧に掲載されている
3. start-work が Phase 1 で inbox を検知し提案する（inbox が空なら何も起きない）
4. 全スキル（session-handoff / decision-log / retrospective / feature-block-design / start-work）の参照パスが新構成のみを指す
5. `docs/open-questions.md` が存在せず、既存項目が `docs/working/issues/` に課題ファイルとして存在する
6. `scripts/sync-template.ps1` が新構成で冪等に動作し（2回実行して差分ゼロ）、3つのインデックス（decisions / retrospectives / issues）が空生成され、シード対象（issues インデックス・inbox README）が template に含まれる（ADR-0027）
7. 本リポジトリの docs/ が新レイアウトに移行済みで、生きているドキュメント（README / CLAUDE.md / CONTRIBUTING.md / 本仕様書 / アクティブな handoff / 各インデックス)からのリンクが切れていない
8. スキル変更（organize-inbox 新設・既存スキル修正）がプラグインの再インストール/更新で利用環境に反映され、新しいセッションで最新のスキル定義が読み込まれることを確認済みである
