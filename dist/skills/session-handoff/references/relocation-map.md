# 独立手順「移設」の導入と種類別対応表

移設先を判定するときに読む（update の移設判定・finalize の圧縮・cycle-reset の申し送り点検）。実際に記述を正本へ移す手順は `relocation-procedure.md`。

handoff が正本になっている記述を、種類に応じた正本の置き場へ引っ越し、handoff 側を参照に置き換える手順。操作（read / update / finalize / cycle-reset）から独立した名前付き手順であり、手順全体（`relocation-procedure.md`）は次の 3 起点から実行される:

- finalize の圧縮前段（実施条件は `op-finalize.md` 手順 3）
- read（`op-read.md`）でサイズ超過を提案しユーザーが受諾した時（その場で実行）
- cycle-reset（`op-cycle-reset.md`）の申し送り現役性点検の前段（教訓型を落とす前に移設する）

このほか、種類別対応表は update の移設判定の手順（`op-update.md` 手順 4）・節別の記載規範（`section-volume-norms.md` の既知のブロッカー・懸念の行、列挙外の節への既定規則）・finalize 手順 4（`op-finalize.md`）の「圧縮しないもの」規定からも書き分けの判定に参照される。対応表に従って実際に記述を正本へ移す場合は、起点にかかわらず `relocation-procedure.md` の手順 3〜6 に従う。

## 種類別対応表

移設先は情報分類の**分類名**で書き、標準パスを括弧で併記する。具体パスの解決はプロジェクトのフォルダ構成定義（`docs/overview/folder-structure.md`）に従う。ただし worklog 中央ストアはリポジトリ外・フォルダ構成定義の管轄外であり、パスの解決は worklog-record スキルに従う。

| 情報の種類 | 正本の置き場 | handoff に残すもの |
|---|---|---|
| 進行中タスクの状態・残り | handoff（進行中の作業。唯一 handoff が正本でよい） | そのまま（節別の記載規範〈`section-volume-norms.md`〉の分量内） |
| 教訓のうち、スキル化・ルール化に有用な delta 型（AI の挙動と必要だったことの差分） | worklog 中央ストア（標準: `<home>/.ai-dev-worklog/`。記録経路は worklog-record スキル） | 記録済みなら削除してよい（worklog が消費装置を持つため参照も不要） |
| 教訓のうち、プロジェクト固有の参照知識（次サイクルの作業者が読む運用ノウハウ・既知の落とし穴） | 参照知識（標準: `docs/reference/`。初回に索引 README を作り、ドキュメント追加時に行を足す） | 「関連ドキュメント」節に正本ドキュメント単位で参照 1 行 |
| 未解決の論点・要対応事項 | 課題＝進行中の作業（標準: `docs/working/issues/`。system/flow の分岐と採番・インデックス追記はプロジェクトの課題管理規約に従う） | Issue 番号の参照 |
| 今サイクル限りの一時的な注意・ブロッカー | handoff「既知のブロッカー・懸念」 | 1 件 200 字以内 |
| レビュー結果・検査の詳細 | 計画・課題・記録類の正本（進行中の作業＝標準: `docs/working/plans/` / `docs/working/issues/`、追跡型の記録＝標準: `docs/records/`） | 消化記録 1 行（参照のみ） |

判別の指針: 「AI の挙動改善に使う差分か?」→ worklog、「次サイクルの人間・AI が読み返す知識か?」→ 参照知識、「誰かが対応すべき未解決事項か?」→ 課題、「今サイクルの作業状態か?」→ handoff に残す。
