# Flow Feedback: Post ラッパー消化の可視化（Issue-0037 対処サイクル）

開発フロー/ガイドラインに関する課題の記録。配布先システム開発repoでは、このファイルがガイドラインrepo（ai-driven-dev-principles）への申し送りバックログになる。

- **Subject**: Post ラッパー消化の可視化と事後突合（Issue-0037 対処）
- **Period**: 2026-08-01 〜 2026-08-03
- **対応する system 振り返り**: [system/2026-08-03-post-wrapper-consumption-visibility.md](../system/2026-08-03-post-wrapper-consumption-visibility.md)
- **Facilitator**: メインエージェント (claude-opus-5 / 途中から claude-fable-5)

> 起票する各フロー課題には振り分け判定（delta 型・早期対処 / 構造観察型。ADR-0056）を1行記載する。delta 型で急がない候補は起票せず worklog へ記録する（本ファイルには載せない）。

## 開発フロー/ガイドライン課題

各課題は抽出と分類までにとどめる。**対策の設計・採否判断・ADR 化は行わない**（次サイクルでユーザーが対策要と判断した時点で着手。ADR-0021）。

- **課題 #1**: ガイドライン遵守が Claude Code プロジェクトメモリという不可視機構に依存しうる
  - **事象**: LoopForAlpha の Post ラッパー消化率が本 repo より顕著に高かった要因が、同プロジェクトの Claude Code メモリ `feedback-follow-mandatory-steps`（2026-07-22 作成。「Post ラッパーは1項目ずつ消し込む」「handoff update は worklog-record の免除にならない」）による補完であることが実データ調査で判明した。本 repo に同メモリは無く、同一ガイドライン下で信頼性に差が出ていた
  - **原因**: Claude Code のメモリはツール固有・プロジェクト固有・プラグイン配布の外側にあり、ガイドライン体系から観測も配布もできない。メモリが規範の欠落を静かに補完すると、うまく回っているプロジェクトでは体系側の欠落が見えなくなる
  - **影響**: 体系の信頼性評価が誤る（Issue-0037 の起票時診断が誤った遠因）。新規プロジェクトや他ツール（Copilot CLI 等）ではメモリの補完が効かず、同じ欠落が再現する。メモリに蓄積された規範系の知見は worklog と違い体系へ還流する経路がない
  - **なぜフロー課題か**: 特定システムの実装ではなく、ガイドライン体系の信頼性がどの機構に担保されているかという体系自体の構造問題であるため
  - **振り分け判定**: 構造観察型（ADR-0056）— 躓き・人間の指示として worklog に載せられず、体系の俯瞰（複数プロジェクトの実データ比較）で初めて見えた欠落
  - **関連**: ADR-0057（Context に個別事例として記載）、`skills/start-work/SKILL.md`、`skills/retrospective/SKILL.md`、worklog パイプライン（メモリと異なり体系側から観測可能な対照例）
  - **起票**: Issue-0039（`../../working/issues/flow/0039-guideline-reliance-on-invisible-tool-memory.md`）
