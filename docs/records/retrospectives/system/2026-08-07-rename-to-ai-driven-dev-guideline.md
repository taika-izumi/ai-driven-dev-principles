# Retrospective: 体系呼称の改名（AI駆動開発ガイドライン）

- **Subject**: 体系の呼称を「メタ・ガイドライン」から「AI駆動開発ガイドライン」へ改める
- **Branch**: feature/rename-to-ai-driven-dev-guideline（merge済み: `992a49f`）
- **Period**: 2026-08-06 〜 2026-08-07
- **Plan**: `docs/working/plans/2026-08-06-rename-to-ai-driven-dev-guideline-plan.md`
- **Spec**: なし（名称決定は ADR-0078 に集約。仕様書を要する規模ではないと判断し brainstorming・feature-block-design を経ず writing-plans 直行）
- **Related ADRs**: ADR-0078（Accepted）
- **Facilitator**: メインエージェント (claude-fable-5)

## 1. 達成サマリ

- 体系の正式呼称を「AI駆動開発ガイドライン」へ改名し、規範文書・仕様書・プラグインメタデータの全 37 箇所（日本語）＋英語 2 箇所を書き換えた。追記型の記録（ADR / retrospective / 完了 plan / 過去 handoff / issue）は ADR-0011 に従い据え置き
- 初出箇所（`README.md` / `CLAUDE.md` / `CONTRIBUTING.md`）に一行定義「AIエージェントと協働して開発を進めるための、原則・行動指示・スキルの体系」を追加（`f9767e2` / `3155b6a` / `4f830d2`）
- `docs/current/specs/` 配下 10 ファイル・18 箇所を書き換え、ファイル名は維持（`7ffcdab`、表記揺れ修正 `6836617`）。プラグインメタデータは `17aa0c6`、template 同期は `94c9ef6`
- 検証: 書き換え対象スコープ 65 ファイルで旧名称 0 件（日本語・英語とも）、置換ミスによる重複表現 0 件、表記揺れ 0 件、新名称 39 件。template とソースはバイト一致。ADR-0078 を Accepted へ昇格（`219b4bd`）
- 実行方式は `superpowers:subagent-driven-development`。タスクごとに実装サブエージェントを立て、仕様適合レビューと品質レビューを別エージェントで実施（本 repo で `subagent-dispatch` を初めて実運用。全 8 回の委譲すべてに B 群判定行を付与）

## 2. 課題（対象システム固有）

課題の抽出と分類まで（対策の設計・採否判断・ADR化は次サイクル。ADR-0021）。

- **課題 #1**: 仕様書内から ADR を相対パスで参照しているリンクが壊れている
  - **事象**: `docs/current/specs/2026-04-12-meta-guidelines-design.md` L179 の `[0001](0001-adopt-layered-guidelines.md)` は、specs ディレクトリからの相対パスとして解決されるためリンク先が存在しない（実在は `docs/records/decisions/0001-adopt-layered-guidelines.md`）。`Test-Path` で不在を確認済み
  - **原因**: 当該仕様書が ADR インデックスの表をそのまま転記したまま、相対パスの起点が変わったことに追従していない。仕様書は「現時点のシステム全容が分かるスナップショット」として維持する規約（`CLAUDE.md`）だが、リンク健全性を点検する工程が無い
  - **影響**: 本改名サイクルとは無関係の pre-existing 事項で、改名作業自体への影響は無い。ただし仕様書からの ADR 追跡が切れており、原則1（追跡可能性）が部分的に成立していない。同種のリンクが他の仕様書にもある可能性は未調査
  - **起票**: Issue-0055（`../../working/issues/system/0055-specs-relative-adr-links-broken.md`）

- **課題 #2**: 改名後、仕様書のファイル名と内容の呼称が乖離した
  - **事象**: `docs/current/specs/2026-04-12-meta-guidelines-design.md` は本文を新名称へ書き換えたが、ファイル名は `meta-guidelines` のまま残る。ADR-0078 で「ADR 等からの参照を壊さないためファイル名は維持する」と決定した結果
  - **原因**: 決定どおりの意図的な状態。ファイル名を安定識別子として扱う方針（ADR-0077 の思想と同型）と、名称の一貫性がトレードオフになっている
  - **影響**: 将来の読み手が「ファイル名の meta-guidelines は何か」を都度解決する必要がある。改名した体系名で検索してもファイル名からは辿れない
  - **起票**: （ユーザー判断待ち。決定どおりの状態であり課題として扱うかも含めて判断が要る）

> 開発フロー課題は `flow/2026-08-07-rename-to-ai-driven-dev-guideline.md` 参照。worklog 送りとした delta 型候補 3 件（起票なし。ADR-0056 の振り分け規則）: `MakeAiInstructions-2026-08-07-01`（委譲先の報告する識別子の検証）/ `-02`（PowerShell 検索の落とし穴）/ `MakeAiInstructions-2026-08-06-05`（一括置換前の表記揺れと重複の洗い出し）。

## 3. 既存課題の再発・進展

- **Issue-0044**（スキル改定の同一セッション検証不可）: 残っていた未実測「plugin update を挟まない場合の反映可否」を実測し、**挟まなければ反映されない**ことを確認した。`skills/retrospective/SKILL.md` を改定（`70fddf1`）後、追加 update なしで同セッションに `retrospective` を起動したところ改定前の本文が返り、repo 実ファイルとの不一致を突合で確認。あわせてプラグインキャッシュの内容が供給本文とも repo 実ファイルとも異なり、**キャッシュを読んでも「いま何が供給されているか」は判定できない**ことが分かった（反映確認は返り本文と実ファイルの突合しかない）。「検討状況」へ追記済み（ADR-0031）。実測の worklog は `MakeAiInstructions-2026-08-07-03`

- **Issue-0020**（ステージング内容確認の機械 gate）: 再発せず。全 12 コミットで untracked 4 件（`docs/conversation_log.md` と `docs/inbox/` 配下 3 件）の混入ゼロを最終レビューが全コミット走査で確認。委譲プロンプトに毎回「ディレクトリ指定の `git add` を使わない」旨を明記した運用が効いた

## 4. 観察（課題ではないが記録に値するもの）

- **`subagent-dispatch` の初回実運用**: 全 8 回の委譲すべてで B 群判定行を残した。A 群 1（指示より実態を優先し報告）が実際に機能し、レビューエージェントが「渡されたコミットハッシュが実在しない」ことを自力で検知して正しいコミットを特定した
- **二段レビューが実欠陥を捕捉**: 仕様適合レビューが specs L38 の半角スペース欠落（`replace_all` では入らない箇所）を検出し、差し戻して修正（`6836617`）。レビューを挟まなければ表記揺れとして残っていた
- **`pre-finalization-review` は今回も未実運用**: writing-plans 完了時に次手として提示したが、ユーザーは実装への直行を選択。ADR-0072 の提示義務は履行済み
