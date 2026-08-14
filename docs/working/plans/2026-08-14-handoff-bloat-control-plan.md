# handoff 肥大化制御 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** spec `docs/current/specs/2026-08-13-handoff-bloat-control/`（00/01/02）の変更対象 6 ファイルを実装し、完了処理（ADR-0086〜0089 の Accepted 昇格・Issue-0078〜0081 close）まで行って、spec `00-overview.md` §4 の完了基準 7 項目を満たす。

**Architecture:** 配布対象ソース（`skills/session-handoff/SKILL.md`・`skills/start-work/SKILL.md`）を先に編集して生成器で `dist/` を確定し、次に template 対象（`docs/overview/folder-structure.md`）を編集して `template/` を確定する。その後、非配布ドキュメントの整合更新（旧 spec・ADR-0075・README）、最後に ADR 昇格と Issue close。コード変更はなく、検証は grep・生成器チェック・目視で行う（TDD のテスト工程は適用外）。

**Tech Stack:** Markdown、PowerShell（`scripts/build-dist.ps1` / `scripts/sync-template.ps1`）

---

## 実装者が事前に読むべき正本

| 文書 | 用途 |
|---|---|
| `docs/current/specs/2026-08-13-handoff-bloat-control/00-overview.md` | 変更対象一覧（§3）と完了基準（§4） |
| `docs/current/specs/2026-08-13-handoff-bloat-control/01-relocation-standard.md` | 移設標準の規範文の正本（本計画の編集文はここからの写像） |
| `docs/current/specs/2026-08-13-handoff-bloat-control/02-volume-norms.md` | 定量規範（40KB・200 字）とトリガーの正本 |
| `CONTRIBUTING.md`「全シナリオ共通: 配布対象ソースの記法規約」 | 執行点 4 手順と目視 5 型（Task 3 / Task 4 で使用） |

## 配布対象ソースを書くときの記法規約（Task 1・2 で厳守）

`skills/` 配下は配布対象ソースであり、生成器が出所識別子（ADR-NNNN 等）を除去して `dist/` を作る。編集文は次に従う（CONTRIBUTING.md の記法規約・spec `01-relocation-standard.md` §6）:

1. 出所識別子は**全角括弧に単独**で置く（例: `（ADR-0086）`）か、全角括弧内の**文末に「。ADR-NNNN」の形**で置く（例: `（…読むため。ADR-0080）`。生成器が句点ごと除去する。既存ファイルの現用パターン）。識別子と説明語を読点なしで同居させない。なお CONTRIBUTING の R1-a が禁じるのは「除去後に破損文が残る同居」であり、「。ADR-NNNN」形は句点ごと除去されるため該当しない（現行 `dist/skills/session-handoff/SKILL.md` の生成結果で確認済み）
2. 識別子を**半角括弧に入れない**
3. 実在プロジェクト名（実測の出所名）・絶対パス・自己参照（「本リポジトリ」等）を書かない
4. 数値の根拠（実測値）は ADR-0087/0088 が正本。SKILL.md には規範文（デフォルト値と手順）のみを書く

---

### Task 1: `skills/session-handoff/SKILL.md` の 8 変更点

**Files:**
- Modify: `skills/session-handoff/SKILL.md`

spec `00-overview.md` §3 の (a)〜(h) を 5 つの編集で実装する。対応: 編集 1 = (a)(b)、編集 2 = (c)、編集 3 = (d)、編集 4 = (e)(f)(h)、編集 5 = (g)。

- [x] **Step 1: 編集 1 — フォーマット節へ節別規範 (a)、独立手順「移設」の新設 (b)**

「### 外部参照の書き方（ADR-0077）」節の直後・「## 操作」の直前に挿入する。変更前（アンカー）:

```markdown
## 操作

このスキルは5つの操作を提供する。呼び出し側は操作を明示すること。
```

変更後（アンカーの前に以下を挿入。アンカー自体は変更しない）:

```markdown
### 節別の記載規範（ADR-0088）

字数はすべて全角換算の**デフォルト値**である。プロジェクトが調整する場合は自プロジェクトの CLAUDE.md に調整値を明記し、調整値を優先する。

| 節・要素 | 規範 |
|---|---|
| Post ラッパー消化記録の 1 行 | 現行形式の必須要素（日付・マイルストーン名（確定点ラベル含む）・`ADR=` / `worklog=` / `review=` の各フィールド・なし/棄却時の理由）は維持する。各フィールド値は「判定結果＋安定識別子＋正本への参照」に限定する。1 行 200 字以内。詳細は正本側へ書く |
| タイトル（見出し 1 行） | 作業名のみを書く。進捗・状態・参照は Status / Current Phase / 本文の各節へ |
| 次セッション開始時のアクション | 3 項目・各 200 字以内。詳細は参照で書く |
| 「要点のみ」と称する抜粋（全節共通） | 1 項目 200 字以内。必ず正本への参照を伴う |
| 既知のブロッカー・懸念 | 1 件 200 字以内。教訓型に膨らんだものは独立手順「移設」の対象 |
| 列挙外の節への既定規則 | 個別の定めがない節（完了済みタスク・未着手のタスク・作業の目的・背景・重要な意思決定の履歴など）も 1 項目 200 字以内を既定とし、超える内容は独立手順「移設」の対応表に従って正本へ移して参照に置き換える |
| 圧縮・削除の実施記録 | handoff に残さない。受け皿は git 履歴のみとする（ADR-0074） |

項目の**数**は制約しない（作業量に比例するため）。項目数の増加による肥大は、既定規則の移設とサイズ実測トリガーの二段構えで受け止める。節別規範の機械検査は設けない。逸脱の累積はサイズ実測トリガーの発火時にまとめて検出・是正する。

## 独立手順「移設」（ADR-0086）

handoff が正本になっている記述を、種類に応じた正本の置き場へ引っ越し、handoff 側を参照に置き換える手順。操作（read / update / finalize / cycle-reset）から独立した名前付き手順であり、次の 3 箇所から参照される:

- finalize の圧縮前段（必須工程）
- read でサイズ超過を提案しユーザーが受諾した時（その場で実行）
- cycle-reset の申し送り現役性点検の前段（教訓型を落とす前に移設する）

### 種類別対応表

移設先は情報分類の**分類名**で書き、標準パスを括弧で併記する。具体パスの解決はプロジェクトのフォルダ構成定義（`docs/overview/folder-structure.md`）に従う（ADR-0089）。

| 情報の種類 | 正本の置き場 | handoff に残すもの |
|---|---|---|
| 進行中タスクの状態・残り | handoff（進行中の作業。唯一 handoff が正本でよい） | そのまま（節別の記載規範の分量内） |
| 教訓のうち、スキル化・ルール化に有用な delta 型（AI の挙動と必要だったことの差分） | worklog 中央ストア（記録経路は worklog-record スキル） | 記録済みなら削除してよい（worklog が消費装置を持つため参照も不要） |
| 教訓のうち、プロジェクト固有の参照知識（次サイクルの作業者が読む運用ノウハウ・既知の落とし穴） | 参照知識（標準: `docs/reference/`。初回に索引 README を作り、ドキュメント追加時に行を足す） | 「関連ドキュメント」節に正本ドキュメント単位で参照 1 行 |
| 未解決の論点・要対応事項 | 課題＝進行中の作業（標準: `docs/working/issues/`。system/flow の分岐と採番・インデックス追記はプロジェクトの課題管理規約に従う） | Issue 番号の参照 |
| 今サイクル限りの一時的な注意・ブロッカー | handoff「既知のブロッカー・懸念」 | 1 件 200 字以内 |
| レビュー結果・検査の詳細 | 計画・課題・記録類の正本（進行中の作業または追跡型の記録） | 消化記録 1 行（参照のみ） |

判別の指針: 「AI の挙動改善に使う差分か?」→ worklog、「次サイクルの人間・AI が読み返す知識か?」→ 参照知識、「誰かが対応すべき未解決事項か?」→ 課題、「今サイクルの作業状態か?」→ handoff に残す。

### 手順

1. handoff を走査し、対応表の worklog / 参照知識 / 課題の行に該当する記述（handoff が正本になっているもの）を特定する
2. 移設対象の一覧（何をどこへ移すか）をユーザーへサマリー提示する（複数ファイル変更の中リスク対応）
3. 正本を外部へ作成または追記する:
   - delta 型の教訓 → worklog-record の記録経路へ（既に記録済みならこのステップは不要）
   - 参照知識 → 該当ドキュメントへ追記する（なければ新設。**初回は置き場のディレクトリと索引 README を作成し**、以後ドキュメント追加時に索引へ行を足す）
   - 未解決事項 → 課題として起票する（**インデックスへの 1 行追加と通し採番を含む**。既存課題に一般形があれば「検討状況」へ追記する。system/flow の分岐はプロジェクトの課題管理規約に従う）
4. handoff 側の記述を対応表の「handoff に残すもの」へ置換する。参照知識への参照は「関連ドキュメント」節に**正本ドキュメント単位で 1 行**とする（項目単位に並べない。cycle-reset では正本側の索引に載っているものは handoff から落としてよい）
5. 移設は「情報の削減」ではなく「正本の引っ越し」である。移設先で情報が減っていないことを確認してから handoff 側を置換する
6. **移設で作成・更新した正本ファイルを、handoff と同じコミットに含める**（finalize のコミット手順を拡張する。正本が git 履歴に入らないまま handoff が参照だけになる状態を防ぐ）
```

- [x] **Step 2: 編集 2 — read へサイズ実測 (c)**

read の手順 3〜6 をブロック全体で置き換える（番号振り直しの分離による中途状態を避けるため）。変更前:

```markdown
3. ファイルが存在しなければ「ハンドオフなし」と呼び出し側に返す
4. 存在すれば内容を読み込み、以下の要素を抽出して要約をユーザーに提示する:
   - 作業の目的
   - 進行中タスク（状態と残り）
   - 次セッション開始時のアクション
5. 「Post ラッパー消化記録」を検査する（ADR-0057）: 「完了済みタスク」にあるマイルストーンで消化記録の行が無いもの、または `ADR=` / `worklog=` の記載が欠けた行があれば、未消化として呼び出し元（start-work）へ報告する。確定点（spec 確定点 / plan 確定点）を通過したマイルストーン行に `review=` が欠けている場合も、同様に未消化として報告する（ADR-0080）
6. ユーザーに「前回の続きから始めますか?」と確認する
```

変更後:

```markdown
3. ファイルが存在しなければ「ハンドオフなし」と呼び出し側に返す
4. ファイルサイズを実測する（ADR-0087）。シェルで行い、専用スクリプトは設けない。例: PowerShell `(Get-Item <path>).Length`、POSIX `wc -c < <path>`。単位は 1KB = 1000 バイト。目安値のデフォルトは **40KB**（プロジェクトの CLAUDE.md に調整値があればそれを優先する）
5. 存在すれば内容を読み込み、以下の要素を抽出して要約をユーザーに提示する:
   - 作業の目的
   - 進行中タスク（状態と残り）
   - 次セッション開始時のアクション

   手順 4 で目安値を超過していた場合、要約の提示に移設・剪定の提案を添える。ユーザーが受諾したら、独立手順「移設」を**その場で実行する**
6. 「Post ラッパー消化記録」を検査する（ADR-0057）: 「完了済みタスク」にあるマイルストーンで消化記録の行が無いもの、または `ADR=` / `worklog=` の記載が欠けた行があれば、未消化として呼び出し元（start-work）へ報告する。確定点（spec 確定点 / plan 確定点）を通過したマイルストーン行に `review=` が欠けている場合も、同様に未消化として報告する（ADR-0080）
7. ユーザーに「前回の続きから始めますか?」と確認する
```

- [x] **Step 3: 編集 3 — update へ消化記録の内容限定と分岐 (d)**

update の手順 8・9 を置き換える。変更前（手順 8 の末尾と手順 9）:

```markdown
8. 「Post ラッパー消化記録」へ当該マイルストーンの1行を追記する（ADR-0057）。ADR 候補検出の結果（番号 or なし＋理由）と worklog-record の結果（エントリ id or 棄却＋理由）を書く。棄却を明示しない限り未発火と区別できないため、棄却時も必ず書く。当該マイルストーンが確定点（spec 確定点 / plan 確定点）だった場合は、確定前レビューの結果（`review=`）も併記する。この記録は次の確定点での推奨判定の判定材料になるため、欠けると判定は「未レビュー」側へ倒れる（ADR-0080）
9. ファイルを上書き保存する（コミットはセッション終了時、または明示的なコミットタイミングで実施）
```

変更後:

```markdown
8. 「Post ラッパー消化記録」へ当該マイルストーンの1行を追記する（ADR-0057）。ADR 候補検出の結果（番号 or なし＋理由）と worklog-record の結果（エントリ id or 棄却＋理由）を書く。棄却を明示しない限り未発火と区別できないため、棄却時も必ず書く。当該マイルストーンが確定点（spec 確定点 / plan 確定点）だった場合は、確定前レビューの結果（`review=`）も併記する。この記録は次の確定点での推奨判定の判定材料になるため、欠けると判定は「未レビュー」側へ倒れる（ADR-0080）。1 行は 200 字以内とし、各フィールド値は「判定結果＋安定識別子＋正本への参照」に限定する（ADR-0088）。詳細は正本側へ書く
9. 各節への追記で詳細を書きたくなったら、正本（対応する ADR / issue / worklog / 参照知識ドキュメント）へ書き、handoff の行には参照を書く（独立手順「移設」の対応表に従う。ADR-0088）
10. ファイルを上書き保存する（コミットはセッション終了時、または明示的なコミットタイミングで実施）
```

- [x] **Step 4: 編集 4 — finalize の 7 段再構成 (e)・「圧縮しないもの」の暫定文言 (f)・「本サイクル」定義変更 (h)**

finalize の手順ブロック全体を置き換える（対象は `### 4. finalize — セッション終了確定` 節内の `手順:` から PowerShell コードブロックまで。`手順:` はファイル内に複数あるが、同節内では一意）。変更前:

````markdown
手順:
1. update と同様の更新を実施
2. **基準付き圧縮を実施する（ADR-0075）**。圧縮対象は次の 2 種のみ:
   - 詳細が他の正本（ADR / issue / worklog / plan / spec / コミット履歴）に記録済みの完了タスク・記述 → 1 行要約＋正本への参照（安定識別子）に置き換える
   - 役目を終えた状態情報（解消済みブロッカー、確定済み過去セッションの消化記録行。ADR-0057）→ 削除する。**ただし本サイクル（＝現ブランチの作業単位。cycle-reset まで）の `review=` を含む行は、過去セッションのものでも残す**（次の確定点で判定材料として読むため。ADR-0080）

   **圧縮しないもの**: 正本が handoff 以外にないもの（進行中タスクの状態・残り、現役の申し送り・懸念、本サイクルの確定前レビュー実施・見送りの記録＝`review=` を含む消化記録行。ADR-0080）。無条件の 1 行要約はしない。落とした情報の受け皿は git 履歴のみとし、退避ファイルは作らない（ADR-0074）
3. **「次セッション開始時のアクション」セクションを必ず埋める**:
   - 最初に確認すべきファイル
   - 最初に実行すべきコマンド/スキル
   - 留意点
4. Status を更新する（作業継続なら `paused`、完了なら `completed`、まだ進行中なら `in_progress`）。cycle-reset 実施済みで次サイクル未着手のまま終了する場合は `ready-for-next-cycle` を維持する（`paused` 等で上書きしない）
5. ファイルを git に add してコミットする:

   ```powershell
   git add docs/working/handoff/<branch>.md
   git commit -m "chore: update handoff for <branch>"
   ```
````

変更後:

````markdown
手順:
1. **ファイルサイズを実測する**（ADR-0087）。実測手段・目安値は read の手順 4 と同じ（シェルで実測。デフォルト **40KB**、プロジェクトの CLAUDE.md に調整値があればそれを優先する）
2. update と同様の更新を実施する
3. **独立手順「移設」を実施する**（ADR-0086）。手順 1 で目安値を超過していた場合は**必須**。超過していない場合も、対応表に該当する記述を見つけたら実施する。移設候補がなく、手順 4 の基準付き圧縮を再適用しても超過が解けない場合は、目安値の調整をユーザーへ提起する
4. **基準付き圧縮を実施する（ADR-0075）**。圧縮対象は次の 2 種のみ:
   - 詳細が他の正本（ADR / issue / worklog / plan / spec / コミット履歴）に記録済みの完了タスク・記述 → 1 行要約＋正本への参照（安定識別子）に置き換える
   - 役目を終えた状態情報（解消済みブロッカー、確定済み過去セッションの消化記録行。ADR-0057）→ 削除する。**ただし本サイクル（＝前回 cycle-reset から次の cycle-reset までの作業単位）の `review=` を含む行は、過去セッションのものでも残す**（次の確定点で判定材料として読むため。ADR-0080）

   **圧縮しないもの**: 正本が handoff 以外にないもの（進行中タスクの状態・残り、現役の申し送り・懸念、本サイクルの確定前レビュー実施・見送りの記録＝`review=` を含む消化記録行。ADR-0080）。無条件の 1 行要約はしない。落とした情報の受け皿は git 履歴のみとし、退避ファイルは作らない（ADR-0074）。なお「正本が handoff 以外にないもの」の保護は、**独立手順「移設」で正本を外へ作るまでの暫定**である。移設の対応表に該当する記述は、保護を理由に移設をスキップしない（ADR-0086）
5. **「次セッション開始時のアクション」セクションを必ず埋める**:
   - 最初に確認すべきファイル
   - 最初に実行すべきコマンド/スキル
   - 留意点
6. Status を更新する（作業継続なら `paused`、完了なら `completed`、まだ進行中なら `in_progress`）。cycle-reset 実施済みで次サイクル未着手のまま終了する場合は `ready-for-next-cycle` を維持する（`paused` 等で上書きしない）
7. ファイルを git に add してコミットする。**移設で作成・更新した正本ファイルを add 対象に含める**:

   ```powershell
   git add docs/working/handoff/<branch>.md
   git add <移設で作成・更新した正本ファイル>
   git commit -m "chore: update handoff for <branch>"
   ```
````

- [x] **Step 5: 編集 5 — cycle-reset へ移設判定の前段追加 (g)**

cycle-reset の手順 2〜5 をブロック全体で置き換える（番号振り直しの分離による中途状態を避けるため）。変更前:

```markdown
2. 「既知のブロッカー・懸念」（申し送り）を **1 件ずつ現役性点検**し、現役のものだけを残す（一括削除も一括温存もしない。実測済みの申し送りは削ると同じ罠を再び踏むため、落とすのは役目を終えたと確認できたものだけ）
3. 「作業の目的・背景」を「直近サイクルの成果 1 段落＋次サイクル待ち」に書き直す
4. Status を `ready-for-next-cycle` へ更新し（ADR-0076）、「次セッション開始時のアクション」を次サイクル候補で更新する
5. ファイルを git に add する。コミットはしない（`retrospective` の「スキル内ではコミットしない」前提と整合させ、セッション終了時の finalize または通常フローのコミットに委ねる）
```

変更後（新手順 2 を挿入し、旧 2〜5 を 3〜6 へ振り直したもの）:

```markdown
2. 「既知のブロッカー・懸念」の各項目を独立手順「移設」の対応表で判定し、教訓型（worklog / 参照知識 / 課題に該当するもの）を**落とす前に移設する**（ADR-0086）
3. 「既知のブロッカー・懸念」（申し送り）の残りを **1 件ずつ現役性点検**し、現役のものだけを残す（一括削除も一括温存もしない。実測済みの申し送りは削ると同じ罠を再び踏むため、落とすのは役目を終えたと確認できたものだけ）
4. 「作業の目的・背景」を「直近サイクルの成果 1 段落＋次サイクル待ち」に書き直す
5. Status を `ready-for-next-cycle` へ更新し（ADR-0076）、「次セッション開始時のアクション」を次サイクル候補で更新する
6. ファイルを git に add する。コミットはしない（`retrospective` の「スキル内ではコミットしない」前提と整合させ、セッション終了時の finalize または通常フローのコミットに委ねる）
```

- [x] **Step 6: ソースの grep 検証**

Run（PowerShell）:
```powershell
(Select-String -Path skills/session-handoff/SKILL.md -Pattern '独立手順「移設」' -AllMatches).Matches.Count
(Select-String -Path skills/session-handoff/SKILL.md -Pattern '40KB' -AllMatches).Matches.Count
(Select-String -Path skills/session-handoff/SKILL.md -Pattern '200 字' -AllMatches).Matches.Count
(Select-String -Path skills/session-handoff/SKILL.md -Pattern '前回 cycle-reset から次の cycle-reset までの作業単位' -AllMatches).Matches.Count
(Select-String -Path skills/session-handoff/SKILL.md -SimpleMatch '正本を外へ作るまでの暫定').Count
(Select-String -Path skills/session-handoff/SKILL.md -SimpleMatch '移設で作成・更新した正本ファイル').Count
(Select-String -Path skills/session-handoff/SKILL.md -SimpleMatch '落とす前に移設する').Count
```
Expected:
- 独立手順「移設」 = 8（定義見出し 1＋節別規範表 2＋read 手順 5・update 手順 9・finalize 手順 3・finalize「圧縮しないもの」・cycle-reset 手順 2 の各 1）
- 40KB = 2（read 手順 4・finalize 手順 1）
- 200 字 = 7（節別規範表 5＋対応表 1＋update 手順 8）
- 本サイクル新定義 = 1（finalize 手順 4）
- 「正本を外へ作るまでの暫定」 = 1 行（(f) の判別検証）
- 「移設で作成・更新した正本ファイル」 = 3 行（移設手順 6・finalize 手順 7 の本文とコードブロック。(e) コミット拡張の判別検証）
- 「落とす前に移設する」 = 2 行（移設セクションの参照箇条書きと cycle-reset 手順 2。(g) の判別検証）

---

### Task 2: `skills/start-work/SKILL.md` の「本サイクル」文言同期

**Files:**
- Modify: `skills/start-work/SKILL.md`（「確定前レビューの提示規則」§4 判定材料の記録）

- [x] **Step 1: 1 文を置き換える**

変更前（対象は「確定前レビューの提示規則」の「4. 判定材料の記録」段落の**末尾 1 文**。段落の他部分は変更しない）:
```markdown
「本サイクル」とは現 feature ブランチの作業単位（cycle-reset まで）を指す。
```

変更後:
```markdown
「本サイクル」とは前回 cycle-reset から次の cycle-reset までの作業単位を指す。
```

- [x] **Step 2: 検証**

Run: `Select-String -Path skills/start-work/SKILL.md,skills/session-handoff/SKILL.md -Pattern '現 feature ブランチの作業単位|現ブランチの作業単位'`
Expected: 0 件（旧定義の残存なし。両スキルの語彙が揃う）

---

### Task 3: 生成器実行と配布物検証（執行点 4 手順）＋コミット 1

**Files:**
- Regenerate: `dist/`（`scripts/build-dist.ps1`）

- [x] **Step 1: 生成器を実行する**

Run: `powershell -File scripts/build-dist.ps1`
Expected: 正常終了（exit 0）。規約違反（識別子の位置違反）があれば非ゼロ終了するので、ソースを修正して再実行する

- [x] **Step 2: 両生成器を -Check で実行する**

Run: `powershell -File scripts/build-dist.ps1 -Check` および `powershell -File scripts/sync-template.ps1 -Check`
Expected: 両方 exit 0（sync-template 側はこの時点で差分なしのはず）

- [x] **Step 3: 配布物の目視（5 型）**

`dist/skills/session-handoff/SKILL.md` と `dist/skills/start-work/SKILL.md` を通読し、機械判定の届かない 5 型（半角括弧内の識別子・識別子と説明語の同居残骸・実在の固有名・自己参照「本リポジトリ」等・表示文字列内の識別子)がないことを確認する。補助 grep（5 型のうち識別子残存・自己参照・実在固有名のみを拾う。**通読目視の代替ではない** — 半角括弧内の識別子・表示文字列は目視で拾う）:

```powershell
Select-String -Path dist/skills/session-handoff/SKILL.md,dist/skills/start-work/SKILL.md -Pattern 'ADR-[0-9]{4}|Issue-[0-9]{4}|本リポジトリ|本 repo|LoopForAlpha|MakeAiInstructions'
```
Expected: 0 件。違反を見つけたら（既存行由来でも）ソース側を修正し、Step 1 から再実行する

- [x] **Step 4: コミット 1（ソースと dist/ を同一コミットに）**

```powershell
git add skills/session-handoff/SKILL.md skills/start-work/SKILL.md dist/
git commit -m "feat: session-handoff へ移設手順・サイズトリガー・節別規範を追加（ADR-0086/0087/0088）"
```

---

### Task 4: `docs/overview/folder-structure.md` の配置表拡張＋コミット 2

**Files:**
- Modify: `docs/overview/folder-structure.md`（「6. 代表的なドキュメント種別の配置表」）
- Regenerate: `template/`（`scripts/sync-template.ps1`）

- [x] **Step 1: 既存行を拡張する（新規行は追加しない）**

変更前:
```markdown
| 技術調査・検証メモ | `docs/reference/` |
```

変更後:
```markdown
| 技術調査・検証メモ、セッション跨ぎに再利用する教訓・作業知見 | `docs/reference/` |
```

- [x] **Step 2: sync-template を実行し、両 -Check を回す**

Run: `powershell -File scripts/sync-template.ps1`、続けて `powershell -File scripts/sync-template.ps1 -Check` と `powershell -File scripts/build-dist.ps1 -Check`
Expected: すべて exit 0

- [x] **Step 3: template 側の実在確認と目視**

Run: `Select-String -Path docs/overview/folder-structure.md,template/docs/overview/folder-structure.md -Pattern 'セッション跨ぎに再利用する教訓・作業知見'`
Expected: 各 1 件・計 2 件（完了基準 3。本体と template の両方）。あわせて template 側の変更行周辺を目視し 5 型の違反がないことを確認する

- [x] **Step 4: コミット 2（ソースと template/ を同一コミットに）**

```powershell
git add docs/overview/folder-structure.md template/
git commit -m "docs: folder-structure の配置表へ教訓・作業知見の移設先を明記（ADR-0086/0089）"
```

---

### Task 5: 旧 spec `2026-08-06-handoff-pruning-and-status-design.md` の矛盾記述の書き換え

**Files:**
- Modify: `docs/current/specs/2026-08-06-handoff-pruning-and-status-design.md`

スナップショット規約に従い既存仕様書を書き換えで更新する（差分ファイルを作らない）。spec `00-overview.md` §3 の (i)〜(iv) に、確定前レビューが検出した残存矛盾 2 件（(v) 「template 対象ファイル → 変更なし」行、(vi) 「圧縮しないもの」規定）を加えた 6 編集。(v)(vi) は spec §3 の列挙外からの追加であり、spec 側の列挙は Task 6 Step 3 で現状化する。

- [x] **Step 1: (i) 「数値ゲートは設けない」の書き換え（設計の骨子 節）**

変更前:
```markdown
ハンドオフ肥大の根本原因は剪定機会の不足ではなく、**剪定の許可と基準が明文化されていないこと**。対処は「イベント駆動の構造的剪定規約」を `session-handoff` / `retrospective` の 2 スキルに組み込むことで行う。数値ゲート（行数閾値等）は設けない。
```

変更後:
```markdown
ハンドオフ肥大の根本原因は剪定機会の不足ではなく、**剪定の許可と基準が明文化されていないこと**。対処は「イベント駆動の構造的剪定規約」を `session-handoff` / `retrospective` の 2 スキルに組み込むことで行う。サイズの実測トリガーは本設計の対象外とし、後続設計 `docs/current/specs/2026-08-13-handoff-bloat-control/02-volume-norms.md`（ADR-0087）が定める。
```

- [x] **Step 2: (ii) finalize 手順構成の現状化（変更 3 節の末尾へ追記）**

変更前（変更 3 節の Status 分岐段落）:
```markdown
あわせて finalize の Status 更新ガイドに次の分岐を追加する: cycle-reset 実施済みで次サイクル未着手のまま終了する場合は `ready-for-next-cycle` を維持する（paused 等で上書きしない）。
```

変更後（段落を維持し、直後に 1 段落追加）:
```markdown
あわせて finalize の Status 更新ガイドに次の分岐を追加する: cycle-reset 実施済みで次サイクル未着手のまま終了する場合は `ready-for-next-cycle` を維持する（paused 等で上書きしない）。

finalize の現行の手順構成は、後続設計により 7 段（サイズ実測・移設を含む）へ再構成されている。現状の正は `docs/current/specs/2026-08-13-handoff-bloat-control/01-relocation-standard.md` §3 と `skills/session-handoff/SKILL.md` を参照。
```

- [x] **Step 3: (iii) cycle-reset の現役性点検へ移設前段を反映（変更 4 節の手順 2）**

変更前:
```markdown
2. **申し送り（既知のブロッカー・懸念）を 1 件ずつ現役性点検**し、現役のものだけを残す（一括削除も一括温存もしない）
```

変更後:
```markdown
2. 申し送り（既知のブロッカー・懸念）のうち教訓型は独立手順「移設」（`docs/current/specs/2026-08-13-handoff-bloat-control/01-relocation-standard.md` §2）で先に移設し、**残りを 1 件ずつ現役性点検**して現役のものだけを残す（一括削除も一括温存もしない）
```

- [x] **Step 4: (iv) 「start-work 変更なし」の現状化（変更対象外 節）**

変更前:
```markdown
- `skills/start-work/SKILL.md` → 変更なし（セッション終了処理は finalize を呼ぶ既存配線のまま。cycle-reset は retrospective 経由でのみ発動する）
```

変更後:
```markdown
- `skills/start-work/SKILL.md` → 本設計での変更はなし（セッション終了処理は finalize を呼ぶ既存配線のまま。cycle-reset は retrospective 経由でのみ発動する）。ただし「本サイクル」の定義文言は後続設計（`docs/current/specs/2026-08-13-handoff-bloat-control/02-volume-norms.md` §2）で変更された
```

- [x] **Step 5: (v) 「template 対象ファイル → 変更なし」の現状化（変更対象外 節）**

本 plan の Task 4 が template 対象の `docs/overview/folder-structure.md` を変更し `sync-template.ps1` を実行するため、この行は plan 完了時点で偽になる（確定前レビューの指摘）。変更前:

```markdown
- `CLAUDE.md` / `docs/overview/principles.md` / template 対象ファイル → 変更なし。`scripts/sync-template.ps1` の実行は不要
```

変更後:

```markdown
- `CLAUDE.md` / `docs/overview/principles.md` → 変更なし。ただし template 対象の `docs/overview/folder-structure.md` は後続設計（`docs/current/specs/2026-08-13-handoff-bloat-control/01-relocation-standard.md` §5）で変更され、`scripts/sync-template.ps1` の実行が必要になった
```

- [x] **Step 6: (vi) 「圧縮しないもの」規定への暫定注記（変更 3 節）**

変更前:

```markdown
**圧縮しないもの**: 正本が handoff 以外にないもの（進行中タスクの状態・残り、現役の申し送り・懸念）。無条件の 1 行要約はしない。
```

変更後:

```markdown
**圧縮しないもの**: 正本が handoff 以外にないもの（進行中タスクの状態・残り、現役の申し送り・懸念）。無条件の 1 行要約はしない。この保護規定はその後、`review=` を含む消化記録行の保護（ADR-0080）が加わり、独立手順「移設」で正本を外へ作るまでの暫定と位置付けられた（ADR-0086）。現状の正は `skills/session-handoff/SKILL.md` を参照。
```

- [x] **Step 7: grep 検証（完了基準 5）**

Run（PowerShell）:
```powershell
Select-String -Path docs/current/specs/2026-08-06-handoff-pruning-and-status-design.md -Pattern '数値ゲート'
Select-String -Path docs/current/specs/2026-08-06-handoff-pruning-and-status-design.md -SimpleMatch 'SKILL.md` → 変更なし'
Select-String -Path docs/current/specs/2026-08-06-handoff-pruning-and-status-design.md -SimpleMatch '後続設計により 7 段'
Select-String -Path docs/current/specs/2026-08-06-handoff-pruning-and-status-design.md -SimpleMatch '教訓型は独立手順「移設」'
Select-String -Path docs/current/specs/2026-08-06-handoff-pruning-and-status-design.md -SimpleMatch '実行が必要になった'
Select-String -Path docs/current/specs/2026-08-06-handoff-pruning-and-status-design.md -SimpleMatch '正本を外へ作るまでの暫定と位置付けられた'
```
Expected: 上 2 本 = 0 件（(i)(iv) の矛盾除去。SimpleMatch は start-work 行だけを狙う）、下 4 本 = 各 1 件（(ii)(iii)(v)(vi) の現状化の実在確認）。(v) 適用後に旧 spec へ残る「→ 変更なし」は `CLAUDE.md` / `docs/overview/principles.md` の行のみで、これは現在も真

---

### Task 6: ADR-0075/0080 の部分修正注記・spec 現状化・README 更新＋コミット 3

**Files:**
- Modify: `docs/records/decisions/0075-handoff-two-stage-pruning-discipline.md`（Consequences 末尾）
- Modify: `docs/records/decisions/0080-review-presentation-scaled-by-unreviewed-normative-content.md`（Consequences 末尾）
- Modify: `docs/current/specs/2026-08-13-handoff-bloat-control/00-overview.md`（§3 表・§4 基準 4/5）
- Modify: `README.md`（スキル一覧テーブルの session-handoff 行）

- [x] **Step 1: ADR-0075 Consequences へ追記**

`- **部分修正（ADR-0080）**:` で始まる行（Consequences の最終行）の直後に追加する（再実行時は同内容の行が既に無いことを確認してから追加する）:

```markdown
- **部分修正（ADR-0086）**: 「圧縮しないもの＝正本が handoff 以外にないもの」の保護規定は維持するが、保護は独立手順「移設」で正本を外へ作るまでの暫定とし、移設とセットで運用する（移設の対応表に該当する記述は、保護を理由に移設をスキップしない）。既存の ADR-0080 由来の注記とは対象条項が異なり両立する。二段階剪定の骨格は現役のため、Status は Accepted のまま維持する
```

- [x] **Step 2: ADR-0080 Consequences へ追記（「本サイクル」定義変更の部分修正）**

確定前レビューの指摘: ADR-0080 の「5. 判定材料の記録」は「本サイクル」の旧定義（現 feature ブランチの作業単位）を明文化しており、実装後に唯一の矛盾記述として残る。ADR-0075 と同型の部分修正注記で現状化する。

Consequences の最終箇条書き `- 退役経路: ...相乗りする` の直後（`## 過剰適合点検（ADR-0079）` 見出しの前）に追加:

```markdown
- **部分修正（ADR-0087）**: Decision 5 の「本サイクル」定義（現 feature ブランチの作業単位）は「前回 cycle-reset から次の cycle-reset までの作業単位」へ改められた（master 直接開発ではブランチ基準で保持範囲が定義できないため）。判定材料の記録規範そのものは現役のため、Status は Accepted のまま維持する
```

- [x] **Step 3: spec `00-overview.md` の変更対象一覧・完了基準を現状化**

Task 5 の (v)(vi)・本タスクの ADR-0080 注記は spec §3 の列挙外からの追加のため、spec をスナップショットとして現状に合わせる（4 編集）。

編集 1 — §3 表の旧 spec 行。変更前（1 行）:

```markdown
| `docs/current/specs/2026-08-06-handoff-pruning-and-status-design.md` | 本設計と矛盾する記述をスナップショット規約に従い書き換え: (i)「数値ゲート（行数閾値等）は設けない」（サイズトリガー新設と矛盾） (ii) finalize 手順構成（移設工程が入り 7 段になる） (iii) cycle-reset の申し送り現役性点検（前段に移設判定が入る） (iv)「`skills/start-work/SKILL.md` → 変更なし」（「本サイクル」文言変更が入る）。なお「cycle-reset は retrospective 経由でのみ発動する」は撤回後も真のため書き換え対象ではない | なし |
```

変更後（`(iv)…` と `。なお` の間に (v)(vi) を挿入）:

```markdown
| `docs/current/specs/2026-08-06-handoff-pruning-and-status-design.md` | 本設計と矛盾する記述をスナップショット規約に従い書き換え: (i)「数値ゲート（行数閾値等）は設けない」（サイズトリガー新設と矛盾） (ii) finalize 手順構成（移設工程が入り 7 段になる） (iii) cycle-reset の申し送り現役性点検（前段に移設判定が入る） (iv)「`skills/start-work/SKILL.md` → 変更なし」（「本サイクル」文言変更が入る） (v)「template 対象ファイル → 変更なし。sync-template の実行は不要」（folder-structure 変更が入り矛盾） (vi) 変更 3 節の「圧縮しないもの」規定（保護の暫定化と矛盾するため暫定注記を追記）。なお「cycle-reset は retrospective 経由でのみ発動する」は撤回後も真のため書き換え対象ではない | なし |
```

編集 2 — §3 表の ADR-0075 行の直後に ADR-0080 行を追加。変更前（1 行）:

```markdown
| `docs/records/decisions/0075-…` | Consequences へ部分修正の注記（保護規定は移設とセット運用へ） | なし |
```

変更後（2 行）:

```markdown
| `docs/records/decisions/0075-…` | Consequences へ部分修正の注記（保護規定は移設とセット運用へ） | なし |
| `docs/records/decisions/0080-…` | Consequences へ部分修正の注記（「本サイクル」定義の変更） | なし |
```

編集 3 — §4 完了基準 4。変更前:

```markdown
4. ADR-0075 の Consequences に移設セット運用の部分修正注記が実在する
```

変更後:

```markdown
4. ADR-0075 の Consequences に移設セット運用の部分修正注記が、ADR-0080 の Consequences に「本サイクル」定義変更の部分修正注記が実在する
```

編集 4 — §4 完了基準 5 の対象範囲。変更前:

```markdown
5. 旧 spec `2026-08-06-handoff-pruning-and-status-design.md` に §3 (i)〜(iv) の矛盾記述が残っていない（「数値ゲート（行数閾値等）は設けない」等が grep で不検出）
```

変更後:

```markdown
5. 旧 spec `2026-08-06-handoff-pruning-and-status-design.md` に §3 (i)〜(vi) の矛盾記述が残っていない（「数値ゲート（行数閾値等）は設けない」等が grep で不検出）
```

- [x] **Step 4: README のスキル一覧を現状化**

変更前:
```markdown
| [`session-handoff`](skills/session-handoff/) | セッション間の作業引き継ぎファイル（ハンドオフ）を読む・作成する・更新する・確定する |
```

変更後:
```markdown
| [`session-handoff`](skills/session-handoff/) | セッション間の作業引き継ぎファイル（ハンドオフ）を読む・作成する・更新する・確定する・サイクル完了時にリセットする（5 操作）。独立手順「移設」とサイズ実測トリガーで肥大化を制御する |
```

- [x] **Step 5: コミット 3（Task 5 の旧 spec 書き換えと合わせる）**

```powershell
git add docs/current/specs/2026-08-06-handoff-pruning-and-status-design.md docs/current/specs/2026-08-13-handoff-bloat-control/00-overview.md docs/records/decisions/0075-handoff-two-stage-pruning-discipline.md docs/records/decisions/0080-review-presentation-scaled-by-unreviewed-normative-content.md README.md
git commit -m "docs: 旧剪定 spec・ADR-0075/0080・spec 現状化・README を肥大化制御設計と整合させる"
```

---

### Task 7: 完了基準の全体検証（spec `00-overview.md` §4 の 1〜6）

- [x] **Step 1: 基準 1 — 生成器の最終確認**

Run: `powershell -File scripts/build-dist.ps1 -Check` と `powershell -File scripts/sync-template.ps1 -Check`
Expected: 両方 exit 0（違反 0）

- [x] **Step 2: 基準 2〜6 のチェックリスト消し込み**

| 基準 | 確認方法 | 期待値 |
|---|---|---|
| 2. 配布物の目視 | Task 3 Step 3 / Task 4 Step 3 のチェックボックスが両方 `[x]` であること | 5 型の違反 0 |
| 3. folder-structure 拡張行 | 本体と `template/` を grep（Task 4 Step 3） | 各 1 件・計 2 件 |
| 4. ADR-0075/0080 注記 | `Select-String -Path docs/records/decisions/0075-handoff-two-stage-pruning-discipline.md -Pattern '部分修正（ADR-0086）'` と `Select-String -Path docs/records/decisions/0080-review-presentation-scaled-by-unreviewed-normative-content.md -Pattern '部分修正（ADR-0087）'` | 各 1 件 |
| 5. 旧 spec の矛盾除去・現状化 | Task 5 Step 7 の grep | (i)(iv) 0 件・(ii)(iii)(v)(vi) 各 1 件 |
| 6. README 現状化 | `Select-String -Path README.md -Pattern 'サイクル完了時にリセットする（5 操作）'` | 1 件 |

Expected: 全項目が期待値どおり。不一致があれば該当 Task に戻って修正し、コミットを追加する

---

### Task 8: 完了処理 — ADR 昇格・Issue close＋コミット 4（完了基準 7）

**Files:**
- Modify: `docs/records/decisions/0086-handoff-canonical-relocation-standard.md` ほか 0087/0088/0089（Status 行）
- Modify: `docs/records/decisions/README.md`（ADR インデックスの 0086〜0089 の Status 4 行）
- Modify: `docs/working/issues/flow/0050-retrospective-cadence-bound-to-subproject-granularity.md`（検討状況）
- Modify: `docs/working/issues/flow/0078-cycle-reset-too-coarse-for-long-cycles.md` ほか 0079/0080/0081（Status / Closed / 結論）
- Modify: `docs/working/issues/README.md`（0078〜0081 の 4 行）

前提: 本タスクは実装完了・検証通過後にのみ実施する。ADR の昇格は `decision-log` スキルの「承認の昇格」手順に従う（第 1 ステップの粒度点検を含む。点検の規範は decision-log 側が正本）。

- [x] **Step 1: ADR-0086〜0089 の Status を昇格する**

4 ファイルそれぞれで変更前 `- **Status**: Proposed` → 変更後 `- **Status**: Accepted`。昇格前に decision-log の粒度点検を実施し、問題があればユーザーへ報告して指示を待つ。

あわせて ADR インデックス `docs/records/decisions/README.md` の 0086〜0089 の 4 行の Status 列を `Proposed` → `Accepted` に更新する（decision-log「承認の昇格」手順がインデックスのテーブル更新を含むため。本体だけ昇格するとインデックスと乖離する）

- [x] **Step 2: Issue-0050 へ委譲の受け皿を追記する（close の前提。順序を逆にしない）**

`0050-retrospective-cadence-bound-to-subproject-granularity.md` の「検討状況」末尾に追加:

```markdown
- 2026-08-14: Issue-0078 の close に伴い、cycle-reset 発火点（呼び出し関係）の一般化の検討を本課題へ受託（ADR-0087 の Considered Alternatives 3）。サイクル内の実効制御はサイズ実測トリガー（ADR-0087）が担うため、本課題では振り返り契機の設計と合わせて扱う
```

- [x] **Step 3: Issue-0078〜0081 を close する**

各ファイル共通: `- **Status**: open` → `- **Status**: closed`、Opened 行の直後に `- **Closed**: 2026-08-14` を追加（既に `- **Closed**:` 行がある場合は追加しない。実施日が異なる場合は実施日を書く。以下同じ）。**対象 4 ファイルには `## 結論` 節が存在しない**（4 件とも実測で不在。課題フォーマットの正規の節のため新設が必要）。各ファイル末尾に `## 結論` 節を新設して以下を記入:

- 0078: `サイクル内の実効制御はサイズ実測トリガー（ADR-0087）が担う。cycle-reset 発火点の一般化は撤回し（ADR-0087 の Considered Alternatives 3）、呼び出し関係の検討は Issue-0050 へ委譲した（同 issue 検討状況 2026-08-14 の行が受け皿）`
- 0079: `種類別対応表と独立手順「移設」を session-handoff スキルに定義した（ADR-0086）。「正本が handoff 以外にないもの」の保護は移設とセット運用へ改めた（ADR-0075 の部分修正注記）`
- 0080: `消化記録 1 行の内容を「判定結果＋安定識別子＋正本への参照」に限定し、1 行 200 字以内（デフォルト値）を規定した（ADR-0088）`
- 0081: `節別の字数規範（デフォルト 200 字）・列挙外の節への既定規則・圧縮記録の残置禁止を規定した（ADR-0088）`

- [x] **Step 4: 課題インデックスを更新する**

`docs/working/issues/README.md` の 0078〜0081 の 4 行で `open` → `closed` に変更する

- [x] **Step 5: 検証**

Run（PowerShell）:
```powershell
Select-String -Path docs/records/decisions/008[6-9]-*.md -Pattern '\*\*Status\*\*: Proposed'
Select-String -Path docs/records/decisions/README.md -Pattern '\[008[6-9]\].*Proposed'
Select-String -Path docs/working/issues/flow/0078-*.md,docs/working/issues/flow/0079-*.md,docs/working/issues/flow/0080-*.md,docs/working/issues/flow/0081-*.md -Pattern '\*\*Status\*\*: open'
Select-String -Path docs/working/issues/flow/0078-*.md,docs/working/issues/flow/0079-*.md,docs/working/issues/flow/0080-*.md,docs/working/issues/flow/0081-*.md -Pattern '^## 結論'
Select-String -Path docs/working/issues/flow/0078-*.md -SimpleMatch 'Issue-0050 へ委譲'
Select-String -Path docs/working/issues/flow/0050-*.md -SimpleMatch 'Issue-0078 の close に伴い'
powershell -File scripts/sync-template.ps1 -Check
```
Expected: 上 3 本 = 0 件（本体・インデックスとも昇格/close 済み）、`^## 結論` = 4 件（節の新設。完了基準 7）、委譲の明記 = 1 件、Issue-0050 の受け皿 = 1 件、`sync-template.ps1 -Check` = exit 0（`docs/working/issues/README.md` は空インデックス生成対象のため、編集後の生成器整合を確認する）

- [x] **Step 6: コミット 4**

```powershell
git add docs/records/decisions/ docs/working/issues/
git commit -m "adr: 0086-0089 を Accepted へ昇格、Issue-0078〜0081 を close（0078 は Issue-0050 へ委譲）"
```

---

## タスクと完了基準の対応

| spec §4 完了基準 | 担当タスク |
|---|---|
| 1. スキル 2 件への (a)〜(h) 記載＋生成器通過 | Task 1・2・3・7 |
| 2. 配布物の目視（5 型） | Task 3 Step 3・Task 4 Step 3・Task 7 |
| 3. folder-structure 拡張行（本体＋template） | Task 4・7 |
| 4. ADR-0075/0080 注記 | Task 6・7 |
| 5. 旧 spec の矛盾除去・現状化（(i)〜(vi)） | Task 5・6 Step 3・7 |
| 6. README 現状化 | Task 6・7 |
| 7. ADR 昇格（本体＋インデックス）・Issue close（結論節新設・委譲明記） | Task 8 |

## 実装上の注意（全タスク共通）

- push はユーザー指示待ち（handoff の申し送り）。本計画のコミットはすべてローカルに留める
- `skills/` の編集だけでは動くスキルは変わらない（実行されるのはプラグイン側）。実装完了後のスキル反映には `/plugin marketplace update ai-driven-dev-principles` の実行をユーザーへ依頼する（AI からは実行不可）
- 編集後の確認は Edit ツールの戻り値ではなく Read / grep での読み直しで行う（コミット直前は特に）
- 本 plan ファイル（`docs/working/plans/2026-08-14-handoff-bloat-control-plan.md`）は plan 確定時にコミットされている想定。未コミットのまま実装に入っていた場合は、コミット 1 の `git add` に本ファイルを含める（どのコミットにも入らないまま完走する構造を避ける）
