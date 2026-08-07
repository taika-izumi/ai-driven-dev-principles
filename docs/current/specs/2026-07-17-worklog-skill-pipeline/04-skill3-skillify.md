# ブロック04: skill3-skillify（スキル化スキル）

## 対象ファイル

- `skills/worklog-skillify/SKILL.md`（スキル本体）
- `skills/worklog-skillify/references/`（Skill Creator から設計時抽出した技術＝description 自動最適化・定量 eval ループの手法を自前で蒸留内包）

## 責務

スキル2で選ばれた採用候補から、新規スキル作成または既存スキル拡張を行う。委譲エンジンは writing-skills を既定とし、スコープに応じて成果物の配置先を振り分ける。薄いオーケストレーション層に留める。

## インターフェース

- **トリガー**: スキル2の採用候補（Issue 草案＋根拠エントリ参照）を受けて起動
- **入力**: 採用候補（Issue 草案・根拠エントリ・スキル2が確定した scope）
- **出力**:
  - スコープ別の成果物（プラグイン配信スキル／プロジェクトローカルスキル `.claude/skills/`／CLAUDE.md 追記）
  - `processed.jsonl` への追記（skillified / merged）
- **01 への依存操作**: 台帳追記
- **委譲先**: writing-skills（既定エンジン）。汎用パスは既存「Issue → extend-guidelines → スキル作成」フローへの橋渡し

## サブ機能 / 内部構成

1. **実行環境ガード**: スキル冒頭で実行環境が本 repo（ai-driven-dev-principles）かを安定マーカー（git remote URL に `ai-driven-dev-principles`、またはプラグイン manifest 等の固有ファイル存在。実装時に確定）で判定
2. **スコープ3分岐（振り分け）**:
   - **汎用**（複数プロジェクトで再現・ドメイン非依存）→ 本 repo のプラグイン配信スキル
   - **プロジェクト固有だが価値あり** → そのプロジェクトのローカルスキル（`.claude/skills/`）
   - **固有ルールでスキル化不要** → そのプロジェクトの CLAUDE.md
3. **ガード発火**: 「汎用パス かつ 本 repo でない」場合のみ警告＋ユーザー確認（①この場のプロジェクトローカルスキルとして作成 ②配信元 repo へ移動して実行 ③中止）。固有パスはガード不要でそのまま
4. **出所点検**: 汎用スコープ、および本 repo で実行し CLAUDE.md 追記へ振り分ける場合、根拠エントリの出所プロジェクト数・モデル世代を数え、単一出所に偏る場合は CONTRIBUTING.md「全シナリオ共通: 過剰適合の点検」の是正パターンの適用をユーザーへ提示（ADR-0079）
5. **委譲実行**: writing-skills へ委譲してスキルを作成/拡張。Skill Creator 設計時借用の references（description 最適化・eval ループ）を併用。**実行時に Skill Creator はロードしない**（エンジンは writing-skills のみ）
6. **台帳追記**: 作成/拡張完了後、`processed.jsonl` へ確定結果（skillified＝新規作成 / merged＝既存スキルへ統合）を追記し、対応する `adopted` エントリの状態を確定させる（追記専用 JSONL のため後続レコードで遷移を表現。読み側は最新レコードの outcome を採用）

## データモデル

01（worklog-store）の台帳スキーマに従う（skillified/merged の書き込み側）。

## このブロック固有の制約・前提

- スキル3自体は薄いオーケストレーション層（候補コンテキスト収集＋本 repo 規約充足の保証）。汎用パスは extend-guidelines フローへの橋渡しで足りる
- Skill Creator 借用は「設計時抽出」で実現（実装段階で一度読み手法を references に蒸留）。実行時依存・外部構成への結合を持たない
- スキル配信元は本 repo。プラグイン配信スキルを作った場合はプラグイン更新まで反映されない

## 関連 ADR

- ADR-0044（スコープ3分岐・skill3 橋渡し）
- ADR-0046（writing-skills 既定・Skill Creator 設計時借用・実行環境ガード）
- ADR-0079（出所点検）
