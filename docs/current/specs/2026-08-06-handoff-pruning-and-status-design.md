# ハンドオフ剪定規約と Status 整合の設計（Issue-0049 / Issue-0051 対処）

- **Date**: 2026-08-06
- **対象課題**: Issue-0049（ハンドオフ肥大・剪定規約なし・外部参照が節名で不安定）/ Issue-0051（`retrospective` の Status 値 `ready-for-next-cycle` が `session-handoff` 未定義）
- **関連 ADR**: ADR-0074（受け皿は git 履歴のみ）/ ADR-0075（二段階剪定）/ ADR-0076（Status 4 値化）/ ADR-0077（外部参照は安定識別子）
- **スコープ外**: Issue-0053（セッション再起動での振り返り素材消失）。ただし剪定規約は素材消失と逆方向のリスクを持つため、「正本が handoff 以外にないものは圧縮しない」制約として設計に反映済み

## 設計の骨子

ハンドオフ肥大の根本原因は剪定機会の不足ではなく、**剪定の許可と基準が明文化されていないこと**。対処は「イベント駆動の構造的剪定規約」を `session-handoff` / `retrospective` の 2 スキルに組み込むことで行う。数値ゲート（行数閾値等）は設けない。

- 剪定で落とした情報の受け皿は git 履歴のみ。明示アーカイブファイルは設けない（ADR-0074）
- 剪定は二段階: セッション境界（finalize）で基準付き圧縮、サイクル境界（retrospective 完了時）で初期状態への書き換え（ADR-0075）
- 剪定は「情報の削減」ではなく「重複の参照への置き換え」。参照の壊れにくさを担保するため外部参照は安定識別子で書く（ADR-0077）

## 変更 1: Status 定義の 4 値化（`skills/session-handoff/SKILL.md` フォーマット節）

Status の定義を次の 4 値とする（ADR-0076）:

| 値 | 意味 |
|----|------|
| `in_progress` | 作業進行中 |
| `paused` | 中断中（再開待ち） |
| `completed` | 作業完了（feature ブランチのマージ完了時など、そのブランチの handoff が役目を終えた状態） |
| `ready-for-next-cycle` | サイクル完了・次サイクル待ち（長命ブランチの handoff が、retrospective 完了後にユーザーの次サイクル判断を待つ状態） |

## 変更 2: 外部参照の安定識別子規約（`skills/session-handoff/SKILL.md` フォーマット節）

フォーマット節に次の規約を追記する（ADR-0077）:

> 外部文書への参照は安定識別子（ADR-NNNN / Issue-NNNN / ファイルパス / コミットハッシュ）を必ず含めること。節名・項番だけの参照は書かない（安定識別子への併記は可。例: `skills/retrospective/SKILL.md の Phase 3` は可、「振り返りスキルの仕上げ節」だけは不可）。

## 変更 3: finalize への基準付き圧縮の組み込み（`skills/session-handoff/SKILL.md` 操作 4）

finalize の手順に剪定ステップを追加する（ADR-0075 前段）。圧縮対象は次の 2 種のみ:

1. **詳細が他の正本（ADR / issue / worklog / plan / spec / コミット履歴）に記録済みの完了タスク・記述** → 1 行要約＋正本への参照（安定識別子）に置き換える
2. **役目を終えた状態情報**（解消済みブロッカー、確定済み過去セッションの消化記録行 = 既存 ADR-0057 規約）→ 削除する

**圧縮しないもの**: 正本が handoff 以外にないもの（進行中タスクの状態・残り、現役の申し送り・懸念）。無条件の 1 行要約はしない。

あわせて finalize の Status 更新ガイドに次の分岐を追加する: cycle-reset 実施済みで次サイクル未着手のまま終了する場合は `ready-for-next-cycle` を維持する（paused 等で上書きしない）。

## 変更 4: 新操作 `cycle-reset` の追加（`skills/session-handoff/SKILL.md` 操作 5）

サイクル完了時の深い剪定を独立した操作として定義する（ADR-0075 後段）。呼び出し元は `retrospective` Phase 3（責務分離: ファイル操作の知識は session-handoff に集約する）。

呼ばれるタイミング: サブプロジェクトの master マージ後、`retrospective` の仕上げ（Phase 3）。

手順:

1. 完了サイクルの経緯を落とす: 完了済みタスクは「過去サイクルは retrospective / git 履歴参照」の 1 行に集約し、Post ラッパー消化記録は全行削除し、完了サイクル固有の記述を除去する（受け皿は git 履歴。ADR-0074）
2. **申し送り（既知のブロッカー・懸念）を 1 件ずつ現役性点検**し、現役のものだけを残す（一括削除も一括温存もしない）
3. 「作業の目的・背景」を「直近サイクルの成果 1 段落＋次サイクル待ち」に書き直す
4. Status を `ready-for-next-cycle` へ更新し、「次セッション開始時のアクション」を次サイクル候補で更新する
5. ファイルを git に add する。コミットはしない（`retrospective` の「スキル内ではコミットしない」前提と整合させ、セッション終了時の finalize または通常フローのコミットに委ねる）

## 変更 5: `retrospective` Phase 3 の修正（`skills/retrospective/SKILL.md`）

Phase 3 手順 3 の現行記述「`session-handoff` の **update** 操作を呼ぶ …… handoff Status を `completed` → `ready-for-next-cycle` へ遷移」を次に置き換える:

> `session-handoff` の **cycle-reset** 操作を呼ぶ（Status は `in_progress` → `ready-for-next-cycle` へ遷移する。剪定・書き換えの手順は session-handoff 側の定義に従う）。「次セッション開始時のアクション」に起票済み issue 番号と次サイクル候補の優先順位の目安を記載する点は従来どおり

誤記述（`completed` からの遷移）はこの置き換えで同時に解消する。

## 変更 6: 既存 spec の書き換え更新

`docs/current/specs/2026-05-01-retrospective-design.md` の Phase 3 記述（`session-handoff update` を呼び Status を `ready-for-next-cycle` へ遷移する行）を、cycle-reset 呼び出しに合わせて書き換える（スナップショット規約: 差分ファイルを作らず既存仕様書を更新する）。

## 変更対象外

- `CLAUDE.md` / `docs/overview/principles.md` / template 対象ファイル → 変更なし。`scripts/sync-template.ps1` の実行は不要
- `skills/start-work/SKILL.md` → 変更なし（セッション終了処理は finalize を呼ぶ既存配線のまま。cycle-reset は retrospective 経由でのみ発動する）
- 既存 handoff ファイルの一括修正 → しない。新規約は次回以降の操作時に適用される

## 検証

1. 改定後の 2 スキルの記述整合を突合する: Status 値の集合（4 値）、操作名（cycle-reset）、遷移記述（`in_progress` → `ready-for-next-cycle`）が両スキルで一致すること
2. `docs/current/specs/2026-05-01-retrospective-design.md` に `update` ベースの旧記述が残っていないこと（grep で確認）
3. プラグイン更新（ADR-0055）後にスキルが読み込めること。本サイクルはスキル改定を含むため、Issue-0044（スキル改定の同セッション検証可否）の実測機会として、改定直後の同セッションでのスキル起動可否を観測・記録する
4. 本サイクル完了時の retrospective で `cycle-reset` を初回実運用し、本 repo `master.md` の Status 不整合注記が除去されることを確認する（ドッグフーディング）

## サイクル完了時の後処理

- ADR-0074〜0077 を Accepted へ昇格（実装完了・検証後。ADR-0019）
- Issue-0049 を close（結論: ADR-0074 / 0075 / 0077）、Issue-0051 を close（結論: ADR-0076）。`docs/working/issues/README.md` のインデックスも更新
- Issue-0044 の「検討状況」に同セッション検証の実測結果を追記
