# Retrospective: Codex（OpenAI Codex CLI）対応

- **Subject**: OpenAI Codex 対応（Layer 2 の AGENTS.md 正本化＋Layer 3 の Codex ネイティブ配信）
- **Branch**: feature/codex-support（取り込み方式: マージコミット `a9bc086`）
- **Period**: 2026-08-25 〜 2026-08-25
- **Plan**: docs/working/plans/2026-08-25-codex-support-implementation.md
- **Spec**: docs/current/specs/2026-08-25-codex-support-design.md
- **Related ADRs**: ADR-0110, ADR-0111, ADR-0112, ADR-0113, ADR-0114（ADR-0023 に部分修正注記）
- **Facilitator**: メインエージェント (claude-opus-5)

## 1. 達成サマリ

- **Layer 2 の正本移動**: ルート `CLAUDE.md` の内容を `AGENTS.md` へ移し、`CLAUDE.md` を `@AGENTS.md` インポート 1 行にした（`13d4106`）。3 ツール（GitHub Copilot CLI / Claude Code / OpenAI Codex）が同一内容を起動時に読む構成へ
- **Layer 3 の Codex 配信**: `.agents/plugins/marketplace.json`（ルート）と `dist/.codex-plugin/plugin.json` を `.claude-plugin/` の 2 正本から生成器導出で追加。あわせて生成器へ version 一致検査と正本 JSON の入力ガードを入れた（`29bc6ff` / `1f24a02`）
- **参照の 3 ツール中立化**: skills 21 箇所・`docs/overview` 2 箇所・README・CONTRIBUTING を更新（`7b71c5d` / `bc51327` / `57f5cec` / `dcb2e81`）。プラグイン version を 0.1.12 へ（`a9e3432`）
- **仕様スナップショット同期**: 配布物生成 spec 5 ファイルほか計 10 ファイルを実装後の挙動へ同期（`5f84c65`）
- **検証**: spec の検証 1〜10 のうち実行可能な 8 件がすべて通過。Copilot CLI 関連 2 件は同ツール未契約により実行不能で、spec の規定により完了条件外とした
- **実装方式**: `superpowers:subagent-driven-development` により全 12 タスクで実装 → 仕様適合レビュー → コード品質レビューの二段を実施。レビューは実在の欠陥を複数検出した（規範の探索条件の曖昧さ・Layer 2 書き込み点の無言の不発・ADR 注記の自己言及の矛盾・未実測を「確認済み」と書いた過剰主張）

## 2. 課題（対象システム固有）

課題の抽出と分類まで（対策の設計・採否判断・ADR 化は次サイクル。ADR-0021）。

本サイクルの対象システム固有の課題は、サイクル中に随時起票済みであり、本振り返りでの新規抽出はない。

- **既起票（サイクル中）**: Issue-0108（`build-dist.ps1` のコード品質レビューで採用を見送った指摘 4 群が未対応）。生成器の `no plugins found` 診断が二重定義になり片方が到達不能である件も、同 Issue の群 3 に含まれる

> 開発フロー課題 1 件は [flow/2026-08-25-codex-support.md](../flow/2026-08-25-codex-support.md) 参照。worklog 送りとした delta 型候補 1 件（検証コマンドを実行せず確定する挙動の同一セッション内再発。起票なし。振り分け規則による。ADR-0056）。

## 3. 既存課題の再発・進展

- **Issue-0073**（計画の検証ステップの期待値が実装中に判明した事実で陳腐化する）: **新しい型**を追記した。既存 4 型は「実装中に判明した事実」による陳腐化だが、今回は**同一サイクル内で自分が承認した決定**（ADR-0114）が期待値を動かした。計画 Task 11 の検証 9 が 20 行を期待するのに実測 21 行となり、素直に読むと正しい追加を残留参照として消す方向へ誘導した（ADR-0031）
- **Issue-0102**（マージ後の cycle-reset の適用先 handoff が暗黙）: 本サイクルでも該当。`feature_codex-support.md` を `completed` にした一方、`master.md` は前サイクルの `ready-for-next-cycle` のままで、cycle-reset の適用先が手順から一意に読めなかった
- **Issue-0107**（反復レビューの推奨規範が状況要素を無視して推奨を決める）: 本サイクルで乖離事例 6 件＋一般観察 2 件を検討経緯ログへ記録済み（計画確定前の作業）
