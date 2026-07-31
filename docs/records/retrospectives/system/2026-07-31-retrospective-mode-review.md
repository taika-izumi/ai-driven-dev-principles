# Retrospective: retrospective の役割再定義

- **Subject**: retrospective スキルの役割再定義（課題抽出記録への純化）
- **Branch**: feature/retrospective-mode-review（merge済み: 066b4e0）
- **Period**: 2026-07-31（単日）
- **Plan**: docs/working/plans/2026-07-31-retrospective-issue-extraction-redesign.md
- **Spec**: docs/current/specs/2026-05-01-retrospective-design.md
- **Related ADRs**: ADR-0056（Accepted）
- **Facilitator**: メインエージェント (claude-opus-5 / 一部 claude-fable-5)

> 本ファイルは ADR-0056 の新形式で作成した初回の記録（改訂スキル自身のドッグフーディング）。

## 1. 達成サマリ

- Issue-0035（簡易モード未定義）を起点に brainstorming を実施し、「簡易モードの追加」ではなく retrospective の役割自体を再定義する方針を決定（ADR-0056 Accepted、`c8661dd` → `c729101`）
- 残す情報を「課題詳細」＋「最小サイクル文脈」の 2 つに限定。Went Well / Tech Notes 観点を廃止し worklog パイプラインへ委譲。単一形式化、rubber-duck のオプション化、フロー課題の振り分け規則（delta 型 / 構造観察型）を導入
- SKILL.md・テンプレート 2 種・retrospectives README・README.md・CONTRIBUTING.md を新形式へ整合（`5b54a59`〜`cf2f2b2`）。旧観点の残存 0 件を grep で確認
- 簡易実施時に欠落していた retrospectives README の 2 行（2026-07-18 の 2 サイクル）を追記し、行追加を省略不可工程として明記
- Issue-0035 close、Issue-0021 に解消方向を追記（`c0c71c1`）

## 2. 課題（対象システム固有）

本サイクルで新規起票した対象システム固有の課題はない。検出した 2 件はいずれも既存課題への追記・不起票とした。

- **spec ファイル名の日付の意味が未定義**（構造観察型）: `2026-05-01-retrospective-design.md` を全面書き換えしたがファイル名は初版日付のまま。spec 一覧から現行性が読めない。→ 新規起票せず **Issue-0008 の検討状況へ追記**（ADR-0031。維持/アーカイブ方針の決定時に命名規約もあわせて決める）
- **spec の Status 語彙が未定義**（構造観察型）: 既存 spec は `Draft` 表記だが現行スナップショットを表す語がなく `Current` を新造した。実害が軽微なため**不起票**（ユーザー判断。再発時に改めて検討）

> 開発フロー課題 2 件（Issue-0037 / Issue-0038）は `flow/2026-07-31-retrospective-mode-review.md` 参照。worklog 送りとした delta 型候補 1 件（起票なし。ADR-0056 の振り分け規則）。

## 3. 既存課題の再発・進展

- **Issue-0008**（system, open）: 旧型式 spec 1 本を「維持（書き換え更新）」で処理し 8 本中 1 本が解消。あわせてファイル名の日付規約が未定義である点を追記（ADR-0031）
- **Issue-0034**（flow, open）: 「新工程に責務を割り当てる際、その工程が実際に果たせるかを実績で検証していない」形で同型が再発。ユーザーの指摘で過去実績を調査し、retrospective が構造観察型課題を発見した実績が 0 件であることが判明して設計を修正した。対策設計時の観点として追記（ADR-0031）
- **Issue-0021**（flow, open）: ADR-0056 で Tech Notes 観点自体を廃止し worklog へ委譲したため解消方向。close 判断はユーザーへ委ねる旨を追記
- **Issue-0032**（system, open）: Phase 3 の worklog 追記後の健全性検証で再発（2例目）。`od -c | grep -c '\r'` が CR 147 件と誤検出したが、Python のバイト直接カウントでは CR 0 件。前サイクルの `grep -P` ロケールエラーと同型で、「grep 系の検出手段は環境依存で誤判定する」ことが再確認された。例コマンドはバイト直接カウントを第一候補とすべき旨を追記（ADR-0031）
- **Issue-0035**（flow）: ADR-0056 で対処し **close**
