# ADR 更新手順（終端ステータスの意味境界・ステータス変更・承認の昇格）

`decision-log` の既存 ADR の状態を変えるときの正本。Rejected / Deprecated / Superseded への遷移、Accepted 済み ADR 本文の改訂記録、Proposed → Accepted の昇格を扱う。

## 終端ステータスの意味境界

| ステータス | 意味 | 遷移元 |
|-----------|------|--------|
| Accepted | 承認され有効 | Proposed |
| Rejected | 承認前に不採用が確定 | Proposed |
| Deprecated | 承認後に廃止（置換先なし） | Accepted |
| Superseded by ADR-XXXX | 承認後に新 ADR で置換 | Accepted |

いずれの遷移でもファイルは削除しない（削除してよいのは未コミットのドラフトのみ。`adr-authoring.md`「ユーザーへの確認」参照）。

## ステータス変更

ADRのステータスを変更する場合（Rejected、Deprecated、Superseded、いったん Accepted にした決定の見直しなど）:

「いったん Accepted にした決定の見直し」は終端ステータスへの遷移（Deprecated 化・新 ADR による Superseded 化）として行うものであり、Accepted → Proposed の差し戻しを含意しない。

1. 該当ADRファイルの `Status` を更新する（Rejected, Deprecated, Superseded by ADR-XXXX 等）
2. `docs/records/decisions/README.md` のテーブルのステータスも更新する
3. 変更理由（Rejected の場合は不採用の理由）をADRのConsequencesセクションに追記する
4. コミットする

**Accepted 昇格後の自 ADR 本文の改訂**: 昇格済み ADR 自身の本文を書き換える改訂（確定前レビューの反復・実装時レビューの指摘反映・整合検査による修正など、契機を問わない）は、決定内容の変更有無で扱いを分ける:

- **決定内容を変えない改訂**（文言精度・参照整合・レビュー指摘の反映で、Decision の実質が変わらないもの）: Status は Accepted のまま維持し、当該 ADR の Consequences 末尾へ改訂記録を 1 行残す。書式は `- 改訂記録（<契機>）: <改訂箇所>・<日付>。Status は Accepted のまま維持` に固定する（Consequences 直下のトップレベル箇条として置く。計数 grep の前提）。同一の確定前レビュー反復（1 確定点。反復・回・終了時の定義は pre-finalization-review の `references/iteration-norms.md`「指摘反映後の反復」と session-handoff の `references/review-field-values.md` を参照）に由来する複数の回の改訂は 1 行に集約し `<契機>` に回の範囲を書く（改訂記録は反復の終了時に 1 回書き、途中では書かない）。反復以外の契機による改訂は改訂の都度その場で書き、同一サイクル（定義は session-handoff「「本サイクル」の定義」節）内の同一 ADR への 2 回目以降は行を増やさず既存行の契機・改訂箇所・回数を更新する（`<契機>` に契機名と改訂回数を書き、`<日付>` は最新の改訂日へ更新する——初回日と各回の内訳は git 履歴が担う。ここでの「既存行」は反復以外の契機で当該サイクルに書いた行を指す——反復由来の集約行は別カテゴリであり更新対象にしない（反復の行と反復以外の行が同一サイクルに並ぶことは許容する））
- **決定内容を変える改訂**（Decision の骨格・帰結が置き換わる場合に限る）: 本文を書き換えず、新 ADR を作成して旧 ADR を `Superseded by ADR-XXXX` へ更新する。決定の一部のみが改まる場合は部分修正の型へ振る（新 ADR を作る点は同じだが、旧 ADR は本文を書き換えず Accepted 維持＋新 ADR からの部分修正注記とする）。全部か一部かの判定に迷う場合はユーザーへ確認する
- **Accepted → Proposed の差し戻しは、いずれの場合も用いない**（遷移表に無い遷移を運用しない。再検討は終端ステータスへの遷移〈Deprecated 化・新 ADR による Superseded 化〉で行う）
- 対象外: (1) 他 ADR への部分修正注記の追記——既存の部分修正の型（旧 ADR の Consequences へ `- **部分修正（ADR-XXXX）**:` 書式で注記を追記し、Status は Accepted 維持・Superseded にはしない）に従い、**部分修正を本規範の 2 分岐に当てはめて Superseded 化しないこと**。(2) コミット済み Proposed への改訂・(3) 終端ステータスの ADR への改訂——いずれも記録義務なし（履歴は git が担う）

ただし、Status を `Accepted` へ遷移させる場合は次の「承認の昇格」の手順に従う。初回昇格では Consequences への追記は不要とする（本文改訂の改訂記録規定は昇格ではなく改訂に適用される）。

## 承認の昇格（Proposed → Accepted）

ADRは**原則 Proposed で作成する**。Accepted への昇格は、その決定が確定（議論が収束）した**チェックポイント**で行う。作成直後に即 Accepted 化しないこと。議論の途中（とくに brainstorming 中）は決定が覆りうるため、Proposed のまま据え置く。

**本節の手順は Status が `Accepted` へ遷移するすべての場合に適用する。**

チェックポイントの目安:

| 決定の文脈 | Accepted へ昇格するチェックポイント |
|------------|-----------------------------------|
| brainstorming 起点の決定 | 設計承認時（ユーザーが設計案を承認したタイミング） |
| 実装を伴う決定 | 実装完了・検証後 |
| 上記に当てはまらない決定（純粋なスコープ・方針決定など） | ユーザーがその決定を確定したことを確認した時 |

昇格手順:

1. **サイクル全体整合検査を実施する**: 手順は `cycle-consistency-check.md` に従う。検査での修正・書き戻しを終えてから次のステップへ進む
2. **粒度を点検する**: 昇格対象 ADR のタイトルが本文の全決定に答えているかを照合する。答えていない決定があれば分割を提案し、分割してから昇格する
3. **Status・インデックスを更新しコミットする**: 該当ADRファイルの `Status` を `Accepted` に更新し、`docs/records/decisions/README.md` のテーブルのステータスも更新して、コミットする

`start-work` の Phase 2 の節目の確認でも、確定した据え置きADRの昇格漏れがないか確認される。
