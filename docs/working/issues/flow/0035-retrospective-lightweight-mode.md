# Issue-0035: retrospective の簡易モードが正式な選択肢として未定義

- **Status**: open
- **Opened**: 2026-07-31
- **起票元**: `worklog-extract` 走査（2026-07-31、初回実行）候補14。2 プロジェクト（LoopForAlpha / MakeAiInstructions）で同型が再発
- **関連**: `ai-driven-dev-principles:retrospective`（Phase 1 のヒアリング手順）、ADR-0021（retrospective は課題抽出・分類までにとどめる）、ADR-0028（抽出課題は全件その場で起票）、CLAUDE.md「検証」節（マージ直後の retrospective 起動）

## 課題内容

`retrospective` スキルは、Done / Went Well / Struggled / Tech Notes / Issues の 5 観点を**ユーザーから 1 問ずつヒアリング**し、rubber-duck サブエージェントで独立視点レビューを 1 回かける手順を既定としている。

しかし実運用では、ユーザーが毎回「AI が git log / handoff から 5 観点の案を一括提示し、利用者は修正と起票判断のみ行う」形（簡易モード）を指示していた。根拠エントリ内の記録では、**過去 6 回中 5 回が簡易実施**であり、既定手順のほうが少数派になっている。

簡易モードはスキルに明文化されていないため、毎回ユーザーが同じ指示を出し直す必要があり（2 件とも `corrections` 型 delta、`friction` は 0）、往復コストが固定的に発生している。

## 根拠エントリ

- 代表 id: `LoopForAlpha-2026-07-24-01`
- 全根拠 id: `LoopForAlpha-2026-07-24-01`, `MakeAiInstructions-2026-07-18-03`
- delta 内訳: friction 0 / corrections 2（両件とも人間が同じ指示を出している）
- model 分布: claude-fable-5 ×1 / claude-opus-4-8 ×1（不明 0）
- scope: 記録時は `MakeAiInstructions-2026-07-18-03` が `project-specific` だったが、LoopForAlpha でも同型が再発したため `general-candidate` へ格上げ

## 検討状況

- 2026-07-31: `worklog-extract` 初回走査で採用（`processed.jsonl` へ `adopted` 追記済み）。`worklog-skillify` へ受け渡し予定。既存 `retrospective` スキルの拡張として扱う見込み
- 根拠エントリ由来の対策案: Phase 1 に「簡易モード」を正式な選択肢として追加し、開始時にどちらの形式にするか確認する。過去記録で簡易実施が多数派である実績から、簡易をデフォルト候補として提示してよい
- 検討時の論点: 簡易モードで rubber-duck の独立視点レビューを省略してよいか（ADR-0021 が定める「課題抽出の質」との兼ね合い）。省略可否は次サイクルで判断する

## 結論

（open）
