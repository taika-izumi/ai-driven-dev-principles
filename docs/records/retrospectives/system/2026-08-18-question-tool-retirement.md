# Retrospective: 構造化質問ツールの全面廃止とクリック操作再有効化

- **Subject**: 構造化質問ツールの全ツール・全モデル廃止（テキスト選択肢一本化）とクリック操作の再有効化
- **Branch**: feature/question-tool-retirement（取り込み方式: マージコミット c95d231）
- **Period**: 2026-08-18 〜 2026-08-18
- **Plan**: docs/working/plans/2026-08-18-question-tool-retirement.md
- **Spec**: docs/records/decisions/0109-retire-structured-question-tool-unconditionally.md（設計文書兼用 ADR・spec 確定点 (c) 型）
- **Related ADRs**: ADR-0109（新設・Accepted）、ADR-0036/0085（Superseded 化）、ADR-0035（部分修正）、ADR-0024（Status 注記更新）
- **Facilitator**: メインエージェント (claude-fable-5)

## 1. 達成サマリ

- ユーザー指示（テキスト選択肢で不便なし・コピペ不可の解消）を起点に、CLAUDE.md「ユーザーへの質問と意思決定要求」節を 6 箇条＋サブ 3 → 3 箇条へ置換（10732B/28 箇条 → 7915B/25 箇条）。ADR-0109 起票（7e0f328）→ 実装（ffa08d6）→ Accepted 昇格（b1d7f1e・整合検査指摘なし）
- 確定前レビュー: spec 確定点 (c) でフル 1 巡（3 観点・claude-opus-5）→ 指摘全反映（Critical 1〈TUI 全体の誤クリックリスク受容の明記〉・Major 7・Minor 12）→ 差分確認 1 巡（14 行対応表・全解消・新規 Minor 3）→ 機械検証（齟齬ゼロ）で終了状態は提示後確定（実質収束せず）。plan 確定点はレビュー見送り
- 追従: skills 2 件・CONTRIBUTING 2 箇所・spec 2 件（Issue-0082 の spec 回復を含む）・旧 ADR 4 件・メモリ 2 件・環境設定 2 件（`~/.claude/settings.json` の環境変数削除＝クリック再有効化・settings.local.json の残渣掃除）
- 執行点 4 手順完了（build-dist / sync-template / -Check 両方 exit 0・dist と template を実装コミットへ同梱・配布物目視 5 型該当なし）。plugin 0.1.11（version 3 箇所）
- Issue-0082 close（spec スナップショット回復）

## 2. 課題（対象システム固有）

対象システム固有の新規課題なし。

> 開発フロー課題の新規起票 0 件。worklog 送りとした delta 型候補 2 件（起票なし。振り分け規則による）: 多バイト否定文字クラス grep の偽陰性（`MakeAiInstructions-2026-08-18-02`・同一セッションで 2 回遭遇）、plan 記載ファイルパスの実測不足（`MakeAiInstructions-2026-08-18-03`）。

## 3. 既存課題の再発・進展

- Issue-0095: plan 記載の Issue-0043 ファイル名（slug）を実測せず記憶から補完し実装時に File not found（軽微再発。数値以外のパス・名称も実測対象に含める必要の実例として「検討状況」へ追記）
