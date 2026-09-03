---
name: session-handoff
description: "セッション間で作業を継続するためのハンドオフファイル（docs/working/handoff/<branch>.md）を読む・作成する・更新する・確定する・サイクル完了時にリセット（cycle-reset）する。マイルストーン到達時・セッション終了時・retrospective 完了時に呼ばれる。"
---

# session-handoff

セッション間の作業引き継ぎファイルを管理するスキル。

## ファイル配置

```
docs/working/handoff/<branch-name>.md
```

- ブランチ名のスラッシュは `_` に置換する（例: `feature/auth-flow` → `feature_auth-flow.md`）
- main/master ブランチでも作成可能
- git管理対象（コミットして履歴を残す）

## ハンドオフファイルのフォーマット

```markdown
# Handoff: <作業タイトル>

- **Branch**: <branch-name>
- **Last Updated**: YYYY-MM-DD HH:MM (Asia/Tokyo)
- **Status**: in_progress | paused | completed | ready-for-next-cycle
- **Current Phase**: <作業タイプ>/<現在のスキル or 段階>

## 作業の目的・背景

（このブランチで何を達成しようとしているかの要約。1-3段落）

## 関連ドキュメント

- Spec: `docs/current/specs/...`
- Plan: `docs/working/plans/...`
- 関連ADR: ADR-NNNN, ADR-NNNN

## 完了済みタスク

- [x] タスクA（YYYY-MM-DD 完了）

## 進行中のタスク

- [ ] **現在の作業**: タスクC
  - 状態: <どこまでやったか>
  - 残り: <次に何をすべきか>

## 未着手のタスク

- [ ] タスクD

## 既知のブロッカー・懸念

（なし、または箇条書き）

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す。
形式: `- <日付> <マイルストーン>: ADR=<番号 or なし（理由）> / worklog=<エントリ id or 棄却（理由）> / review=<見送り or 非発火（推奨判定が偽） or 実施記録> / cyclecheck=<実施（指摘なし） or 実施（修正: <識別子>） or 非該当（理由）>`

`review=` の値の定義は `references/review-field-values.md` を参照。

`review=` は確定点（spec 確定点 / plan 確定点）を通過したマイルストーンにのみ書く。反復の途中経過行には書かず確定点行へ集約する。途中経過行の名称には確定点ラベルを含めない（read の欠落検査の誤判定防止。対象確定点の識別は行本文の参照で行う）。確定点を通過したマイルストーンは、**名称に `spec 確定点 (a)` / `spec 確定点 (b)` / `spec 確定点 (c)` / `plan 確定点` のいずれかを含める**（read の欠落検査が対象行を識別できるようにするため）。
`cyclecheck=` は、Accepted 昇格処理を含むマイルストーン行と、サイクル全体整合検査のみを実施したマイルストーン行に書く（値の定義と手順は `decision-log` の `references/cycle-consistency-check.md` を参照）。それ以外のマイルストーンでは省略してよい。**Accepted 昇格処理を含むマイルストーンは、名称に `Accepted 昇格` を含める**（read の欠落検査の識別用）。
行が存在すること自体が update の証跡であるため、session-handoff update の項目は書かない。

- YYYY-MM-DD <マイルストーン名>: ADR=NNNN / worklog=`<project>-YYYY-MM-DD-NN`
- YYYY-MM-DD <マイルストーン名>: ADR=なし（<理由>） / worklog=棄却（delta なし）
- YYYY-MM-DD <確定点のマイルストーン名>: ADR=NNNN / worklog=`<project>-YYYY-MM-DD-NN` / review=フル実施（claude-opus-5・2 巡）＋差分再確認（claude-opus-5・1 巡・実質収束）
- YYYY-MM-DD <マイルストーン名・ADR-NNNN Accepted 昇格>: ADR=NNNN / worklog=棄却（delta なし） / cyclecheck=実施（指摘なし）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: ...
2. 最初に実行すべきコマンド/スキル: ...
3. 留意点: ...

## 重要な意思決定の履歴

- ADR-NNNN: <タイトル>（YYYY-MM-DD）
```

### Status の意味

| 値 | 意味 |
|----|------|
| `in_progress` | 作業進行中 |
| `paused` | 中断中（再開待ち） |
| `completed` | 作業完了（feature ブランチのマージ完了時など、そのブランチの handoff が役目を終えた状態） |
| `ready-for-next-cycle` | サイクル完了・次サイクル待ち（長命ブランチの handoff が、retrospective 完了後にユーザーの次サイクル判断を待つ状態） |

### 外部参照の書き方

ハンドオフから外部文書を参照するときは、安定識別子（ADR-NNNN / Issue-NNNN / ファイルパス / コミットハッシュ）を必ず含めること。節名・項番だけの参照は書かない（安定識別子への併記は可。例: 「`skills/retrospective/SKILL.md` の Phase 3」は可、「振り返りスキルの仕上げ節」だけは不可）。参照先の構造変更で参照が壊れることを防ぐ。

## 「本サイクル」の定義

「本サイクル」とは、前回 cycle-reset から次の cycle-reset までの作業単位を指す。本スキルのほか `pre-finalization-review`（確定点での提示）と `decision-log`（サイクル全体整合検査）がこの定義を参照する（各所で再定義しない）。

## 操作

このスキルは5つの操作を提供する。呼び出し側は操作を明示すること。各操作の手順は `references/` 配下の操作別ファイルが正本であり、呼び出された操作のファイルだけを読む。

| 操作 | ファイル | 正本として持つ内容 |
|---|---|---|
| read | `references/op-read.md` | ファイル特定・サイズ実測・要約提示・消化記録の欠落検査・継続確認 |
| create | `references/op-create.md` | 新規作成・最低限埋める項目・add とコミットの委任 |
| update | `references/op-update.md` | 各節の最新化・消化記録行の追記・移設判定・保存 |
| finalize | `references/op-finalize.md` | サイズ実測・update 同様の更新・移設・基準付き圧縮・次セッション開始時のアクション・Status・コミット |
| cycle-reset | `references/op-cycle-reset.md` | 完了サイクルの経緯の削除・申し送りの移設と現役性点検・目的の書き直し・Status・add |

### 横断規範の参照ファイル

複数の操作から共用される規範。操作ファイルが名指しした時点で読む（毎回は読まない）。

| 規範 | ファイル | 読むとき |
|---|---|---|
| `review=` の値定義（方式要素・終了状態・縮退規定） | `references/review-field-values.md` | 確定点（spec 確定点 / plan 確定点）を通過したマイルストーンの消化記録行を書くとき |
| 節別の記載規範（各節の分量・値限定・移設の既定規則） | `references/section-volume-norms.md` | 書き込み系操作で節の分量・書き分けを判断するとき |
| 独立手順「移設」の導入と種類別対応表 | `references/relocation-map.md` | 移設先を判定するとき（update の移設判定・finalize の圧縮・cycle-reset の申し送り点検） |
| 独立手順「移設」の手順 1〜6 | `references/relocation-procedure.md` | 実際に記述を正本へ移すとき（finalize の圧縮前段・read の超過受諾時・cycle-reset の前段・update で正本へ書いたとき） |

## 完了済みハンドオフの扱い

PR マージなどで作業完了した handoff は `Status: completed` のまま `docs/working/handoff/` に残す。アーカイブ機構（`docs/working/handoff/archive/` への移動）は設けない（剪定・リセットで落とした情報の受け皿は git 履歴のみとする）。

## 対応する原則

- 原則1（追跡可能性）: 作業状態と次のステップを記録に残し、後続の作業者が継続可能にする
- 原則3（コンテキスト管理）: セッション間でコンテキストを明示的に引き継ぐ
