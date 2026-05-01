# Retrospective: サブプロジェクトC「振り返りフェーズ導入」

- **Subject**: サブプロジェクトC（AI駆動開発フローの末尾に振り返りフェーズを導入する）
- **Branch**: feature/retrospective-phase（merge済み: 49906e8）
- **Period**: 2026-05-01
- **Plan**: docs/plans/2026-05-01-retrospective-phase-plan.md
- **Spec**: docs/specs/2026-05-01-retrospective-design.md
- **Related ADRs**: ADR-0010, ADR-0011, ADR-0012
- **Facilitator**: メインエージェント (Claude Opus 4.7)
- **Independent Reviewer**: rubber-duck (default model)

## 1. Done（達成サマリ）

- ADR-0010 / 0011 / 0012 を Proposed → Accepted まで運用（`7f0706d`, `51dae89`, `019ba8b`, `b2c2576`）
- 新スキル `retrospective` 本体 + テンプレート作成（`54fdf82`, `3f879da`）
- `docs/retrospectives/` ディレクトリ初期化（append-only index）（`d34a643`）
- 横断統合: 原則5（`772df15`）/ copilot-instructions 検証セクション（`2e5430c`）/ start-work Phase 2 表 + 終了処理（`e14382f`）/ decision-log 強トリガー（`8a13b0b`）
- README / CONTRIBUTING / template.manifest / template/ 同期（`998e6a1`, `471e441`, `cd57e1d`）
- handoff 全文書き換え（`4354ef1`）→ master へ `--no-ff` merge & push（merge: `49906e8`、handoff merge SHA fill: `ec63649`）

## 2. Went Well（うまくいったこと）

- **設計 / スコープ判断**: brainstorming 段階でユーザーから提起された「ドメイン知識抽出」論点を γ案（C スコープ外、初回 retro で議題化）として整理し、ADR-0012 で正式に「やらない決定」として明文化。スコープクリープを未然に防いだ。
- **プロセス**: spec を6セクションに分けユーザー承認を取りながら進めたため、後戻りなく plan へ移行できた。
- **ツール**: `sync-template.ps1` 2回実行で差分ゼロを確認、CI 不在でも安心して merge できた。

## 3. Struggled（苦労したこと・手戻り）

- **事象**: `create` ツールが親ディレクトリ無しで失敗（Task 4）
  - **原因**: `create` は親ディレクトリを自動作成しない
  - **影響**: 1往復のロス
  - **対処**: `New-Item -ItemType Directory` で先に作成してリトライ

- **事象**: ほぼ全コミットで "CRLF will be replaced by LF" 警告
  - **原因**: Windows 環境 + リポジトリの autocrlf 設定
  - **影響**: 実害なし、ノイズのみ
  - **対処**: 無視で運用

## 4. Tech Notes（古びない技術知見）

- **タイトル**: PowerShell here-string の `` ` `` エスケープ罠
  - **コンテキスト**: Windows + PowerShell でダブルクォート here-string を使うとき
  - **知見**: ダブルクォート here-string 内では `` ` `` がエスケープ文字として解釈され、`` `f `` などはフォームフィードに展開されて `f` が消える
  - **回避策・代替**: シングルクォート here-string を使う、または Python スクリプト経由で bytes append する（サブプロジェクトBで `_append.py` 採用実績あり）
  - **参照**: サブプロジェクトB checkpoint（002-b-master-push.md）

- **タイトル**: `create` ツールの親ディレクトリ要件
  - **コンテキスト**: 新規スキル / 新規ドキュメントを `create` ツールで作成するとき
  - **知見**: `create` は親ディレクトリを自動作成しない。親無しなら失敗する
  - **回避策・代替**: 作成前に `Test-Path` → 必要なら `New-Item -ItemType Directory -Path <dir>` を先行
  - **参照**: 本サイクル Task 4

- **タイトル**: `scripts/sync-template.ps1` の冪等性確認手順
  - **コンテキスト**: template 同期コミットを作成する直前
  - **知見**: 1回目実行で diff が出たあと、ステージ前に必ず2回目を実行して差分ゼロを確認する。これでマニフェスト記述ミスや動的生成箇所（ADR README 空版生成など）の不整合を検出できる
  - **回避策・代替**: 2回目実行で `git status --short` の出力が同一なら冪等
  - **参照**: 本サイクル Task 11

## 5. Improvement Drafts（ガイドライン・フロー改善提案）

- **提案 #1**: knowledge-distillation スキル新設
  - **背景**: ADR-0012 で C スコープ外とした「ドメイン知識抽出」を専用スキルとして次サイクルで実装する。retrospective の Tech Notes セクションに知見が蓄積されていくが、サブプロジェクトを跨いだ再利用可能パターンへの昇華メカニズムがない
  - **提案内容**: retrospective の Tech Notes を入力に、`docs/knowledge/` 配下へ index 化して保管する新スキル `knowledge-distillation` を新設する。retrospective の Phase 5 末尾に呼び出しゲートを置く
  - **判断**: **採用**
  - **理由**: ADR-0012 で次サイクル課題として明示済み。本サイクルの実体験で「Tech Notes は溜まるが横断検索性がない」という具体的な不便さが確認できた
  - **採用の場合**: ADR-0013（Proposed）として起票 / 影響範囲: `skills/knowledge-distillation/`（新規）, `skills/retrospective/SKILL.md`（Phase 5 拡張）, `docs/knowledge/`（新規ディレクトリ）

- **提案 #2**: `create` ツール前置きルールの常時化
  - **背景**: Task 4 で発生した手戻り。`create` ツールは親ディレクトリ無しで失敗するが、これは複数回踏みうるパターン
  - **提案内容**: `.github/copilot-instructions.md` の「タスク構造」または「ドキュメント運用」セクションに「新規ファイル作成前に親ディレクトリ存在を `Test-Path` で確認し、無ければ `New-Item -ItemType Directory` を先行させる」の1文を追加
  - **判断**: **採用**
  - **理由**: 1サイクルで踏んでおり再発リスクが高い。コスト（1文追加）が極小
  - **採用の場合**: ADR-0014（Proposed）として起票 / 影響範囲: `.github/copilot-instructions.md`, `template/.github/copilot-instructions.md`（sync-template 経由）

- **提案 #3**: PowerShell here-string 罠回避規約
  - **背景**: サブプロジェクトB / C と連続して罠を踏みうる場面があった（C は事前回避）
  - **提案内容**: CONTRIBUTING.md または copilot-instructions.md にダブルクォート here-string 禁止規約を明記
  - **判断**: **保留**
  - **理由**: 回避策は既知でメインエージェント側で対処可能。今回の retrospective で Tech Notes として記録したことで知見の参照性は確保された。ドキュメント追加コストに見合う再発頻度かは、もう1サイクル様子を見たい
  - **再検討タイミング・条件**: 次サブプロジェクトでも罠を踏んだら採用に格上げ

- **提案 #4**: retrospective スキル自体のテンプレ簡略化
  - **背景**: 7セクションは初学者には多く感じる可能性
  - **提案内容**: テンプレートのセクション統合（例: Independent Review Notes を Improvement Drafts 内に折り畳む）
  - **判断**: **保留**
  - **理由**: 初回実施で「多すぎ」感は出なかった。早期最適化を避ける
  - **再検討タイミング・条件**: 3サイクル分の retrospective を実施したあと、未記入率の高いセクションが安定して出れば採用検討

## 6. Independent Review Notes（rubber-duck 指摘）

（Phase 3 で記入予定）

## 7. Handoff Forward（次サイクルへの申し送り）

- **着手予定**:
  - ADR-0013（knowledge-distillation スキル新設）の実装。次セッションで `start-work` から開始し、brainstorming → spec → plan → 実装 のフルサイクルを回す
  - ADR-0014（`create` 前置きルール常時化）の実装。小規模なので brainstorming 省略可、`start-work` Phase 2 から直接 writing-plans → 実装で良い
- **継続観察**:
  - 提案#3（PowerShell here-string 罠回避規約）: 次サブプロジェクトで再発したら採用へ格上げ
  - 提案#4（テンプレ簡略化）: 3サイクル分の retrospective が溜まったら未記入率を集計
- **次サブプロジェクト候補**: ADR-0013 由来の「サブプロジェクトD: ドメイン知識蒸留スキル」が最有力候補
