# Issue 肥大化抑制（Issue-0088 / ADR-0094〜0098）実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ADR-0094〜0098 で確定した Issue 肥大化抑制の規範を、課題管理定義の新設・folder-structure §7 の縮約・スキル 4 本への配線・CONTRIBUTING/仕様スナップショットの追従・配布物再生成として実装する。

**Architecture:** 境界原則（ADR-0098）に従い、構造・命名・分量の定義は新設の `docs/overview/issue-management.md`（template 配布）を正本とし、発火条件・手順はスキル側（プラグイン配布）の実追記・close 経路へフックとして配線する。境界をまたぐ複写は置かず、ポインタ（標準パス併記形。ADR-0089 の型）とフォールバックのみ書く。

**Tech Stack:** Markdown 規範文書、PowerShell 生成器（`scripts/sync-template.ps1` / `scripts/build-dist.ps1`）、配布対象ソースの記法規約（CONTRIBUTING.md R1〜R5）

**重要な前提（全タスク共通）**:
- 編集前に対象ファイルの該当箇所を必ず Read し、本計画の「旧文字列」が実体と一致することを確認してから Edit する。食い違いがあれば実態を優先し、理由を添えて報告する
- `docs/overview/issue-management.md`・`docs/overview/folder-structure.md`・`docs/working/issues/README.md` は template/空インデックス配布対象、`skills/` はプラグイン配布対象。**いずれもコミット前に執行点 4 手順（Task 9）を通す**。Task 1〜8 の中間コミットは行わず、Task 9 でまとめてコミットする（生成物と同一コミット要件のため）
- **コミットは必ず pathspec 付き `git commit -m "..." -- <paths>` で行う**（index に別件（handoff 等）がステージ済みでも巻き込まない形）。コミット直前に `git diff --cached --name-only` と `git status --short` で意図外の staged / untracked（`docs/inbox/`・`docs/conversation_log.md`）を確認する

---

### Task 1: 課題管理定義 `docs/overview/issue-management.md` の新設と manifest 追加

**Files:**
- Create: `docs/overview/issue-management.md`
- Modify: `template.manifest`（1 行追加）

- [x] **Step 1-1: `docs/overview/issue-management.md` を以下の内容で作成する**

````markdown
# 課題（issue）管理定義

## 1. この文書の目的と位置づけ

課題（issue）の起票・記録・フォルダ運用・クローズの規範を定義する。情報の 5 分類とフォルダ全体の配置判断は `docs/overview/folder-structure.md` が正であり、本文書はその分類 3（進行中の作業）のうち課題の運用詳細を担う。

> **スキルからの参照について**: 本文書の定義（昇格条件・フォルダ内の役割と命名・close 時の移設判定・記載規範）は、プラグイン配布のスキル（decision-log / retrospective / session-handoff / worklog-extract）から参照される。定義を書き換えた場合、スキルは書き換え後の定義に従って動作する。定義が見つからない場合、スキルはデフォルト値で動作を提案し、その旨をユーザーへ報告する。

## 2. フォルダ構造と分類

課題は「対象システム固有」「開発フロー/ガイドライン関連」のいずれかに分類し、対応するフォルダに配置する:

```
docs/working/issues/
  README.md          # インデックス（唯一）。system / flow の2セクション
  system/            # 対象システム固有の課題
    NNNN-<slug>.md
    NNNN-<slug>/     # フォルダ昇格時（課題ファイルは同名のままフォルダ内へ）
  flow/              # 開発フロー/ガイドライン課題
    NNNN-<slug>.md
    NNNN-<slug>/
```

- フォルダ名は振り返り記録の2フォルダ（`docs/records/retrospectives/system|flow/`）と対応する
- `flow/` の課題は、ガイドライン配布先のシステム開発プロジェクトでは「ガイドライン repo への申し送り対象」を表す
- 課題ファイルに分類フィールドは設けない（フォルダが分類を表す）。分類を変える場合はファイル移動とインデックスの行移動で行う

## 3. 起票・採番・粒度

- 課題は1件ごとに `docs/working/issues/system|flow/NNNN-<slug>.md`（NNNN は4桁ゼロ埋め連番、slug は英語ケバブケース）で起票し、インデックス `docs/working/issues/README.md` の対応セクションに1行追加する
- **採番は両フォルダ通しの連番** — インデックス全体（両セクション）の最大番号+1。Issue-NNNN の参照がプロジェクト内で一意になる
- **粒度は「1 Issue ＝ 1 問題」**（解決したい事象）とする。1 つの課題は、その問題を解くために決めるべき複数の問い（問いの単位は検討ノート。「5. フォルダ内の役割と命名」参照）を内包してよい
- 起票経路は4つ:
  - **振り返り由来** — retrospective スキルが抽出・分類した課題は、その場で全件起票される。課題内容は要約のみを書き、事象/原因/影響の詳細は「起票元」の振り返りファイルを正とする
  - **議論由来** — 仕様検討中の未決事項など（ADR 記述規律による分離）。課題内容を本文に直接書く
  - **worklog-extract 走査由来** — 中央ストアの横断走査で採用（`adopted`）された候補。根拠エントリ id と再発回数を本文に書き、台帳の `ref` に起票先を記録する
  - **配布先からの申し送り由来** — ガイドライン配布先の `flow/` 課題のうち、構造観察型のもの。delta 型は worklog 経路へ委ねる（ADR-0061）。起票元に配布先リポジトリ名と課題番号を明記する
- **新規起票と既存課題への追記の使い分け** — 取り込もうとする課題の一般形が既存課題に含まれている場合は、新規起票せず、その課題の「検討状況」へ1行追記する（形式は「4. ライフサイクル」の再発・進展記録に準じる）。一般形が存在しない場合のみ新規起票する。判断は起票前にインデックス（`docs/working/issues/README.md`）と中央ストアの在庫を突合して行う

## 4. ライフサイクル

- **Status は open → closed** — 対策方針が決定したら ADR を作成し、課題の「結論」に ADR 番号を記載して close する（進行中の作業 → 追跡型の記録への遷移）
- **再発・進展の一次記録は課題側**（ADR-0031） — 既存 open 課題の再発・進展を検出したら、検出したその場で1行追記する（形式: `YYYY-MM-DD: 事象の要約（必要なら詳細への参照）`）。追記先は、単一ファイルの課題では「検討状況」、フォルダ昇格済みの課題では検討経緯ログ（`NNNN-log.md`）とし、昇格済みでは課題ファイルの「現在地の要約」を合わせて書き換える。振り返りファイルで言及する場合は Issue-NNNN への参照を付け、一次記録は課題側とする
- **追記時のサイズ確認** — 課題ファイルへ追記したら、ファイルサイズをシェルで実測する（例: PowerShell は `(Get-Item <path>).Length`、POSIX は `wc -c < <path>`）。目安値 **10KB**（単位は 1KB = 1000 バイト。プロジェクトの CLAUDE.md に調整値があればそれを優先）を超えていたらフォルダ昇格を提案する
- **フォルダ昇格** — 次のいずれかを満たしたとき昇格を**提案**する（判断はユーザー）:
  - (a) 課題ファイルの外に置くべき資料（任意形式の時点資料や、独立に育つ検討ノート）を作る必要が生じた時
  - (b) 追記時のサイズ実測が目安値を超えていた時

  昇格の操作: フォルダ `NNNN-<slug>/` を作り、課題ファイル `NNNN-<slug>.md` を**同名のまま**中へ移動する（README.md への改名はしない）。インデックスのリンク先を更新する。追記禁止の記録類（振り返り等）に残る旧パス参照は壊れを許容する（安定識別子 Issue-NNNN で辿れるため）

  経過措置: 既存の課題は遡及改修しない（既存の形のまま有効。次回の追記時に昇格条件が判定される）。旧方式（課題ファイルをフォルダ内 `README.md` とする形）で昇格済みのフォルダは、次にそのフォルダを触る時に本節の命名へ移行する（一括移行は求めない）
- **close 時の移設判定**（フォルダ昇格済みの課題では必須。義務判定は close 時のみとし、open 中の定期走査は行わない） — close するとき、フォルダ内の材料を次の対応で判定し移設する。この判定は close の経路（ADR 化による close・申し送り済み close・対処なし close）を問わず行う:
  - 恒久価値のある知見（再利用可能な調査結果・ノウハウ）→ 性質別の置き場（`docs/reference/` 等）へ移し、課題側は参照に置き換える
  - 未解決の別論点 → 新規課題の起票、または既存課題への追記へ振り出す
  - 一時的な作業材料・検討経緯ログ → フォルダに残して凍結する

  移設操作の付随則: 移設した材料の索引行を移設先パスへ書き換える / 移設先の本文冒頭または索引行に出所（Issue-NNNN）を 1 行残す / 検討経緯ログから決定へ至った分岐を課題ファイルの結論節へ 5 行以内で要約する
- **配布先プロジェクトの `flow/` 課題**は「ガイドライン repo へ申し送り済み（または対応済み）」で close する。close の条件は「解決済み」ではなく「申し送り済み」である（ガイドライン側の修正はプラグイン更新で配布先へ届くため、配布先で追跡を続ける必要はない）
- **申し送りの close トリガー** — 配布先の課題を close するのは、ガイドライン repo 側に受け皿（新規課題、または既存課題への追記行）が**実在することを確認した時点**である。順序を逆にすると申し送りが蒸発する。worklog 経路で申し送られた場合も同じで、起票が済んだ時点で配布先の対応課題を close する
- **クローズ済み課題はその場に残す** — アーカイブは独立した分類ではなく、この分類内の状態として扱う
- **TBD を積極的に使う** — 不確定な情報を確定した事実のように書かない。未確定箇所は「TBD」と明示する

## 5. フォルダ内の役割と命名

昇格後のフォルダ内は次の 4 役割に固定する。役割外の自由ファイルは置かない。

| 役割 | 命名 | 内容と成長の扱い |
|---|---|---|
| 課題ファイル | `NNNN-<slug>.md`（昇格前と同名） | 状態・課題内容・**現在地の要約**（書き換え。追記しない）・結論・**索引** |
| 検討経緯ログ | `NNNN-log.md` | 時系列の一次記録（`YYYY-MM-DD: 事象・判断`）。現在地の判断には使わない（現在地は課題ファイルが正）が、経緯の追跡ではこれを読む。サイズ上限なし |
| 検討ノート | `NNNN-note-<slug>.md` | **決めるべき問い 1 つ**の検討材料（前提整理・選択肢比較）。冒頭に問いを明記し、slug は問いの要約とする。論点が生きている間は追記・更新し、決着したら結論を課題ファイル（と必要なら ADR）へ書いて凍結する |
| 時点資料 | `NNNN-YYYY-MM-DD-<slug>.<拡張子>` | 書き切りの記録（調査結果の時点スナップショット・説明スライド・合意記録等）。**任意形式**（プレゼン・PDF・画像等）。作成後は原則不変。同名衝突時は末尾に `-2` からの連番を付す |

- 番号接頭辞 `NNNN-` は全ファイルに付け、ファイル名単体を自己識別的にする。番号直後の予約トークンで役割が読める: `NNNN-log.md` は**ファイル名の完全一致**で判定、`note-` は前方一致、日付は時点資料、それ以外は課題ファイル
- フォルダ内の名前順ソートでは役割ごとにまとまる（先頭に来るのは時点資料であり、入口の課題ファイルではない点に留意）
- **判別規則**: 検討ノートか時点資料か迷ったら「この後も更新し続けるか?」で判定する。それでも迷ったら時点資料に置き、索引の一言説明で補う
- **索引義務**: フォルダ内ファイルの作成・外部成果物（指定席送り・確定成果物）の確定のたび、課題ファイルの索引へ 1 行（パス＋一言説明。説明はプロジェクトの記述言語で書く）を追加する。**単一ファイルの課題でも、外部成果物を確定したときは「関連資料」節（無ければ新設）へ参照 1 行を追加する**。所在の一次手がかりはファイル名、二次手がかりは索引の一言説明とする

## 6. フォルダに置くもの・置かないもの（境界規則）

境界の軸は「未確定の検討材料か、確定したスナップショットか」である。

**置くもの＝方針決定に至るまでの材料・経過（未確定側）**:

- 問題の調査・原因分析
- 設計判断に必要な前提情報の収集・整理、選択肢の比較検討
- 関係者への説明資料・合意記録（スライド・PDF 等の任意形式を含む）

**置かないもの＝確定した成果物と指定席のある情報種**（課題ファイルの索引から外部参照 1 行で辿る）:

- 確定した仕様 → `docs/current/specs/`（スナップショット。分割軸は機能ブロックであり、検討のトピック切りの軸を仕様へ持ち込まない）
- 下した決定 → ADR / 実装計画 → `docs/working/plans/`
- 5 分類で指定席が既にある情報種（議事録 → `docs/records/minutes/`、インシデント報告 → `docs/records/` 等）
- コードの実体（PoC 含む）→ リポジトリのコード側（ブランチ等）。フォルダには結果報告のみ置く
- 確定済みで複数の課題にまたがる資料・再利用可能な知見 → 性質別の置き場

**未確定の検討材料が複数の課題にまたがる場合**: 主たる課題のフォルダに置き、他方の課題の索引から参照 1 行で辿る（物理位置は一方に固定し、重複コピーを作らない）。

## 7. 記載規範

- 「検討状況」（昇格後は「現在地の要約」）の 1 エントリは 200 字（全角換算）以内を**目安**とする。昇格済みの課題では超過分を検討ノート・時点資料・検討経緯ログへ移し、参照を置く。単一ファイルの課題では超過を禁止しない（成長の制御は追記時のサイズ確認が担う）
- 外部参照は安定識別子（ADR-NNNN / Issue-NNNN / ファイルパス / コミットハッシュ）で書く。他リポジトリの課題は `<repo>#Issue-NNNN` で修飾する（「9. クロスリポジトリの課題参照」参照）

## 8. 課題ファイルのフォーマット

```markdown
# Issue-NNNN: <タイトル>

- **Status**: open | closed
- **Opened**: YYYY-MM-DD
- **Closed**: YYYY-MM-DD（closed 時のみ）
- **起票元**: <起票のきっかけへの参照>（任意。振り返り由来なら「retrospectives/flow/YYYY-MM-DD-<topic>.md 課題#N」の形式）
- **関連**: ADR-NNNN 等（あれば）

## 課題内容

（振り返り由来: 要約のみ。詳細は起票元の振り返りファイルが正。
　議論由来: 何が問題か・なぜケアが必要かを直接書く。TBD を積極的に使ってよい）

## 検討状況

（対策検討の経過と、再発・進展の記録。再発は `YYYY-MM-DD: 事象の要約` 形式で1行ずつ追記する。
　追記したらファイルサイズを実測し、目安値超過ならフォルダ昇格を検討）

## 関連資料

（外部成果物を確定した場合のみ: パス＋一言説明を 1 件 1 行。無ければ節ごと省略してよい）

## 結論

（closed 時: 下した決定への参照。決定内容自体は ADR に書く）
```

フォルダ昇格後の課題ファイルは「検討状況」を「現在地の要約」（書き換え型・経緯は検討経緯ログへ）に改め、「関連資料」をフォルダ内・外の全材料の索引として必須にする。

## 9. クロスリポジトリの課題参照

（ADR-0068）課題番号はリポジトリ内で一意に採番されるため、`Issue-NNNN` という無修飾の表記はリポジトリをまたぐと別の課題を指す。**他リポジトリの課題を参照するときは必ずリポジトリ名で修飾する**:

- 書式: `<repo>#Issue-NNNN`（例: `OtherProject#Issue-NNNN`）
- 同一リポジトリ内の参照は従来どおり `Issue-NNNN` でよい
- worklog 台帳（`processed.jsonl`）の `ref` フィールドも同様に、リポジトリ名を含む形で記録する（例: `OtherProject:docs/working/issues/flow/NNNN-....md`）

無修飾の表記は実際に衝突している。2 つのリポジトリがどちらも同じ番号を採番し、内容の異なる別課題を指した実例がある。

## 10. インデックスの形式

`docs/working/issues/README.md` はフォルダに対応する2セクション構成。各セクションは1課題1行のテーブル（# / タイトル / Status / Opened）で、リンク先は `system|flow/NNNN-<slug>.md` 形式（フォルダ昇格済みの課題は `system|flow/NNNN-<slug>/NNNN-<slug>.md`）。採番規則（通し連番）を冒頭に明記する。
````

- [x] **Step 1-2: `template.manifest` の末尾（`docs/inbox/README.md` の行の直前）に 1 行追加する**

旧文字列（末尾 4 行）:

```
CLAUDE.md
docs/overview/principles.md
docs/overview/folder-structure.md
docs/inbox/README.md
```

新文字列:

```
CLAUDE.md
docs/overview/principles.md
docs/overview/folder-structure.md
docs/overview/issue-management.md
docs/inbox/README.md
```

- [x] **Step 1-3: 検証** — Run: `Test-Path docs/overview/issue-management.md`（期待: True）、`Select-String -Path template.manifest -Pattern 'issue-management'`（期待: 1 行ヒット）

---

### Task 2: `docs/overview/folder-structure.md` §7 の縮約と関連節・インデックス参照の追従

**Files:**
- Modify: `docs/overview/folder-structure.md`
- Modify: `docs/working/issues/README.md`（冒頭の参照 1 行）

- [x] **Step 2-1: §7 全体を縮約版へ置き換える**。削除範囲は L78「## 7. 課題（issue）管理」から §7.5 本文の末尾（L157。次の見出し `## 8. 運用例...`＝L159 の直前）まで。以下に差し替え:

```markdown
## 7. 課題（issue）管理

課題の起票・記録・フォルダ運用・クローズの規範は `docs/overview/issue-management.md`（課題管理定義）を正とする。早見表:

| やりたいこと | 読む節（課題管理定義） |
|---|---|
| 課題を起票する | 3. 起票・採番・粒度 |
| 既存課題へ経過・再発を追記する | 4. ライフサイクル（再発・進展の一次記録 / 追記時のサイズ確認） |
| 課題フォルダへ資料を置く・整理する | 5. フォルダ内の役割と命名 / 6. 境界規則 |
| 課題ファイルの書式・記載分量を確認する | 7. 記載規範 / 8. 課題ファイルのフォーマット |
| 課題を close する | 4. ライフサイクル（close 時の移設判定を含む） |
| インデックスを更新する | 10. インデックスの形式 |
| 他リポジトリの課題を参照する | 9. クロスリポジトリの課題参照 |
```

- [x] **Step 2-2: §1 の「唯一の参照元」文言を分類に限定する**

旧: `プロジェクトで発生する情報・ドキュメントを「どこに置くか」の判断基準を定義する。本文書は配置判断の唯一の参照元であり、プロジェクト参画直後に読むべき文書として `docs/overview/` に置かれている。`

新: `プロジェクトで発生する情報・ドキュメントを「どこに置くか」の判断基準を定義する。本文書は情報分類と配置判断の唯一の参照元であり、プロジェクト参画直後に読むべき文書として `docs/overview/` に置かれている（課題（issue）の運用詳細は `docs/overview/issue-management.md` が正）。`

- [x] **Step 2-3: §8 運用例の手順 2 を新条件へ書き換える**

旧: `2. **検討・叩き台** — 検討が多観点・長期になったら課題をフォルダに昇格し、現状分析・影響範囲・比較案・叩き台資料を並置する`

新: `2. **検討・叩き台** — フォルダ外に置くべき資料が生じた時、または課題ファイルがサイズ目安を超えた時に課題をフォルダへ昇格し（課題管理定義の昇格条件）、検討ノート・時点資料を役割固定の命名で並置する`

- [x] **Step 2-4: `docs/working/issues/README.md` 冒頭の運用ルール参照を差し替える**

旧: `進行中・クローズ済みの課題のインデックス。運用ルールは `../../overview/folder-structure.md` の「課題（issue）管理」を参照。`

新: `進行中・クローズ済みの課題のインデックス。運用ルールは `../../overview/issue-management.md`（課題管理定義）を参照。`

- [x] **Step 2-5: 検証** — Run: `Select-String -Path docs/overview/folder-structure.md -Pattern 'issue-management'`（期待: **2 件**。§1 と §7 前文）、`Select-String -Path docs/overview/folder-structure.md -Pattern '長期化・多観点化|多観点・長期|README\.md.{0,2}とし'`（期待: 0 件）、`Select-String -Path docs/working/issues/README.md -Pattern 'issue-management'`（期待: 1 件）

---

### Task 3: `skills/decision-log/SKILL.md` の配線と ADR-0096 への追補

**Files:**
- Modify: `skills/decision-log/SKILL.md`（L140 / L146 / L152 付近）
- Modify: `docs/records/decisions/0096-issue-folder-promotion-trigger-and-role-system.md`（Proposed につき書き直し可）

- [x] **Step 3-1: 起票手順（L140）の参照先を更新する**

旧: `フォーマットは `docs/overview/folder-structure.md` の「課題（issue）管理」を参照`

新: `フォーマットは課題管理定義（標準: `docs/overview/issue-management.md`）を参照`

- [x] **Step 3-2: ライフサイクル節の close 手順（L146）へ移設判定フックを追加する**

旧: `2. ADR 化したら課題を close する: 課題ファイルの Status を `closed` に変更し、Closed 日付を記入し、「結論」セクションに ADR 番号を記載する。インデックスの Status も更新する`

新: `2. ADR 化したら課題を close する: 課題ファイルの Status を `closed` に変更し、Closed 日付を記入し、「結論」セクションに ADR 番号を記載する。インデックスの Status も更新する。**フォルダ昇格済みの課題では、close 時に課題管理定義（標準: `docs/overview/issue-management.md`）の移設判定を実施する**（定義が見つからない場合は「再利用知見の移設・別論点の振り出し・残りは凍結」をデフォルトとして提案し、その旨をユーザーへ報告する）`

- [x] **Step 3-3: 旧昇格条件（L152）を新条件の要約＋参照へ書き換える**

旧: `- 検討が長期化・多観点化した課題はフォルダへ昇格できる（`docs/overview/folder-structure.md` 参照）`

新: `- 課題ファイルの外に置くべき資料が生じた時、または追記時のサイズ実測が目安値を超えた時、フォルダ昇格を提案する（判断はユーザー。条件・目安値・フォルダ内体系は課題管理定義（標準: `docs/overview/issue-management.md`）を参照。定義が見つからない場合は目安 10KB（プロジェクトの CLAUDE.md に調整値があればそれを優先）をデフォルトとして提案し、その旨をユーザーへ報告する）`

- [x] **Step 3-4: ADR-0096 の「規範の定義場所と配線」節の末尾へ、レビューで確定した 2 判断を追補する**（Proposed ドラフトの書き直し。以下の 2 行を同節末尾へ追加）

```markdown
- close のスキル配線は decision-log の 1 経路のみとする。申し送り済み close・対処なし close にはスキル手順が存在しないため配線せず、課題管理定義の close 条項（経路を問わない判定）を正とする（スキル経路が新設された時点で配線を追加する）
- 索引の一言説明は「プロジェクトの記述言語で書く」とする（原案の「日本語」から一般化。配布先の記述言語を限定しないため）
```

- [x] **Step 3-5: 検証** — Run: `Select-String -Path skills/decision-log/SKILL.md -Pattern '長期化・多観点化'`（期待: 0 件）、`Select-String -Path skills/decision-log/SKILL.md -Pattern 'issue-management'`（期待: 3 件）

---

### Task 4: `skills/retrospective/SKILL.md` の配線（追記時サイズ確認）

**Files:**
- Modify: `skills/retrospective/SKILL.md`（Phase 2 手順 3 = L88）

- [x] **Step 4-1: 既存課題への「検討状況」追記手順へ 1 句追加する**

旧: `3. 既存 open 課題の再発・進展の「検討状況」追記（`YYYY-MM-DD: 事象の要約`）を実施する（ADR-0031）`

新: `3. 既存 open 課題の再発・進展の「検討状況」追記（`YYYY-MM-DD: 事象の要約`）を実施する（ADR-0031）。追記後にファイルサイズを実測し、目安値超過ならフォルダ昇格を提案する（条件・目安値は課題管理定義（標準: `docs/overview/issue-management.md`）を参照。定義が見つからない場合は目安 10KB（プロジェクトの CLAUDE.md に調整値があればそれを優先）をデフォルトとして提案し、その旨をユーザーへ報告する）`

- [x] **Step 4-2: 検証** — Run: `Select-String -Path skills/retrospective/SKILL.md -Pattern 'issue-management'`（期待: 1 件）

---

### Task 5: `skills/session-handoff/SKILL.md` の配線（移設起点の既存課題追記）

**Files:**
- Modify: `skills/session-handoff/SKILL.md`（独立手順「移設」手順 3 = L144）

- [x] **Step 5-1: 未解決事項の起票・追記行へ 1 句追加する**

旧: `   - 未解決事項 → 課題として起票する（**インデックスへの 1 行追加と通し採番を含む**。既存課題に一般形があれば「検討状況」へ追記する。system/flow の分岐はプロジェクトの課題管理規約に従う）`

新: `   - 未解決事項 → 課題として起票する（**インデックスへの 1 行追加と通し採番を含む**。既存課題に一般形があれば「検討状況」へ追記する。system/flow の分岐はプロジェクトの課題管理規約に従う）。既存課題へ追記した場合はファイルサイズを実測し、目安値超過ならフォルダ昇格を提案する（条件・目安値は課題管理定義（標準: `docs/overview/issue-management.md`）を参照。定義が見つからない場合は目安 10KB（プロジェクトの CLAUDE.md に調整値があればそれを優先）をデフォルトとして提案し、その旨をユーザーへ報告する）`

- [x] **Step 5-2: 検証** — Run: `Select-String -Path skills/session-handoff/SKILL.md -Pattern '目安値超過ならフォルダ昇格'`（期待: 1 件）

---

### Task 6: `skills/worklog-extract/SKILL.md` の配線（既存 issue への統合追記）

**Files:**
- Modify: `skills/worklog-extract/SKILL.md`（手順 8 の Issue 草案化行 = L37）

- [x] **Step 6-1: 重複排除・統合の行へ 1 句追加する**

旧: `   - Issue 草案化時に、retrospective 由来の Issue バックログとの重複排除を行う（唯一の合流点）`

新: `   - Issue 草案化時に、retrospective 由来の Issue バックログとの重複排除を行う（唯一の合流点）。既存 issue へ統合（追記）した場合はファイルサイズを実測し、目安値超過ならフォルダ昇格を提案する（条件・目安値は課題管理定義（標準: `docs/overview/issue-management.md`）を参照。定義が見つからない場合は目安 10KB（プロジェクトの CLAUDE.md に調整値があればそれを優先）をデフォルトとして提案し、その旨をユーザーへ報告する）`

- [x] **Step 6-2: 検証** — Run: `Select-String -Path skills/worklog-extract/SKILL.md -Pattern '目安値超過ならフォルダ昇格'`（期待: 1 件）

---

### Task 7: `CONTRIBUTING.md` の参照更新と close 2 経路へのフック追加

**Files:**
- Modify: `CONTRIBUTING.md`（「未決事項・課題を記録するとき」手順 1・手順 3、「振り返りで抽出された課題に対策するとき」手順 8）

- [x] **Step 7-0: 「未決事項・課題を記録するとき」手順 1 の参照先を更新する**

旧（行末部分）: `フォーマットは `docs/overview/folder-structure.md` の「課題（issue）管理」を参照`

新: `フォーマットは課題管理定義（`docs/overview/issue-management.md`）を参照`

- [x] **Step 7-1: 同シナリオ手順 3 へ 1 句追加する**

旧: `3. ADR 化したら課題を close する（Status を closed に変更し「結論」に ADR 番号を記載。ファイルは削除せず残す）`

新: `3. ADR 化したら課題を close する（Status を closed に変更し「結論」に ADR 番号を記載。ファイルは削除せず残す。フォルダ昇格済みの課題では課題管理定義（`docs/overview/issue-management.md`）の close 時移設判定を実施する）`

- [x] **Step 7-2: 「振り返りで抽出された課題に対策するとき」手順 8 へ 1 句追加する**

旧: `8. 対策サイクル完了時（ADR の Accepted 昇格時）に、対象 issue を close する（Status を closed に変更し「結論」に ADR 番号を記載。インデックスも更新）。昇格は `decision-log` の「承認の昇格」の手順（サイクル全体整合検査を含む）に従う（ADR-0092）`

新: `8. 対策サイクル完了時（ADR の Accepted 昇格時）に、対象 issue を close する（Status を closed に変更し「結論」に ADR 番号を記載。インデックスも更新。フォルダ昇格済みの課題では課題管理定義（`docs/overview/issue-management.md`）の close 時移設判定を実施する）。昇格は `decision-log` の「承認の昇格」の手順（サイクル全体整合検査を含む）に従う（ADR-0092）`

CONTRIBUTING の 2 フックにはフォールバック句を付けない（本ファイルはガイドライン配信元リポジトリ内の文書であり、参照先定義が同リポジトリに常在するため。ADR-0096 の「各フックにフォールバック」の対象はプラグイン配布スキルの 4 フックとする）。

- [x] **Step 7-3: 検証** — Run: `Select-String -Path CONTRIBUTING.md -Pattern 'close 時移設判定'`（期待: 2 件）、`Select-String -Path CONTRIBUTING.md -Pattern '「課題（issue）管理」を参照'`（期待: 0 件）

---

### Task 8: 仕様スナップショットの追従（7 ファイル）

**Files:**
- Modify: `docs/current/specs/2026-07-04-project-folder-structure/00-overview.md`（L86 付近）
- Modify: `docs/current/specs/2026-07-04-project-folder-structure/01-folder-structure-definition.md`（L32 / L37 / L68 付近）
- Modify: `docs/current/specs/2026-07-04-project-folder-structure/05-template-sync-update.md`（L20-27 の manifest 逐語スナップショット）
- Modify: `docs/current/specs/2026-07-05-retrospective-issue-integration/01-issue-management-structure.md`（L5 / L21 / L54 / L64 / L69 / L95 付近）
- Modify: `docs/current/specs/2026-07-05-record-process-norms-design.md`（L41-43 の §7.3/§7.4 参照）
- Modify: `docs/current/specs/2026-08-07-distributed-artifact-generation/01-provenance-notation-convention.md`（L46「現在 4 ファイル」）・`02-distribution-generator.md`（L77「計 25 ファイル」/ L80「（4）」）・`03-template-sync-integration.md`（L29 の 4 ファイル列挙 / L31「全 7 ファイル分」/ L72 影響ファイル表）
- Modify: `docs/current/specs/2026-08-13-handoff-bloat-control/01-relocation-standard.md`（L29 の未解決事項行）

- [x] **Step 8-1: 旧昇格規則の書き換え**。対象: 00-overview L86 / 01-folder-structure-definition L32・L37・L68 / 01-issue-management-structure L21・L54。各箇所を Read し、旧規則（「長期化・多観点化」による昇格 / 課題ファイルの README.md 化 / フォーマット内「長期化したらフォルダ昇格を検討」）を次の要約へ書き換える:
  - 昇格条件: 「フォルダ外に置くべき資料が生じた時、または追記時のサイズ実測が目安値（デフォルト 10KB、1KB = 1000 バイト）を超えた時に提案（判断はユーザー）」
  - 昇格操作: 「課題ファイルは同名のままフォルダ内へ移動（README.md 化はしない）」
  - フォルダ内: 「4 役割（課題ファイル / `NNNN-log.md` / `NNNN-note-<slug>.md` / `NNNN-YYYY-MM-DD-<slug>.<拡張子>`）・全ファイル番号接頭辞・索引義務」
- [x] **Step 8-2: 分離の反映**。01-issue-management-structure の L5（構成説明）・L64（インデックスのリンク形式 → 昇格形 `system|flow/NNNN-<slug>/NNNN-<slug>.md` を併記）・L69（ひな形の参照文 → `../../overview/issue-management.md` へ）・L95（「§7 …全面書き換え」→ 縮約と課題管理定義への分離を反映）を書き換える。00-overview / 01-folder-structure-definition にも folder-structure の節構成に触れる記述があれば「§7 は早見表＋課題管理定義への参照」へ追従させる
- [x] **Step 8-3: 生成器仕様の数値更新**。05-template-sync-update L20-27 の manifest 逐語ブロックへ `docs/overview/issue-management.md` の 1 行を追加 / 01-provenance-notation-convention L46 の「現在 4 ファイル」→「現在 5 ファイル」 / 02-distribution-generator L77「計 25 ファイル」→「計 26 ファイル」・L80「（4）」→「（5）」 / 03-template-sync-integration L29 の列挙へ issue-management.md を追加し「現在 5 ファイル」、L31「全 7 ファイル分」→「全 8 ファイル分」、L72 の影響ファイル表へ issue-management.md の行を追加
- [x] **Step 8-4: 移設標準 spec の追従**。2026-08-13-handoff-bloat-control/01-relocation-standard.md L29 の未解決事項行へ、Task 5-1 と同旨のサイズ実測 1 句を反映する（スキルと spec のスナップショット一致を保つ）
- [x] **Step 8-5: record-process-norms-design の参照更新**。L41-43 の「`docs/overview/folder-structure.md` §7 / §7.3 / §7.4」への言及を「課題管理定義（`docs/overview/issue-management.md`）4. ライフサイクル / 8. 課題ファイルのフォーマット」へ書き換える
- [x] **Step 8-6: 検証** — Run:
  - `Get-ChildItem docs/current/specs -Recurse -Filter *.md | Select-String -Pattern '長期化・多観点化|多観点・長期|長期化したらフォルダ昇格|README\.md.{0,2}(とし|にする|とする)'`（期待: 0 件）
  - `Get-ChildItem docs/current/specs -Recurse -Filter *.md | Select-String -Pattern '現在 4 ファイル|計 25 ファイル|全 7 ファイル分'`（期待: 0 件）

---

### Task 9: 執行点 4 手順（生成器実行・Check・生成物コミット・目視）

**Files:**
- Create/Modify（生成物）: `template/docs/overview/issue-management.md`、`template/docs/overview/folder-structure.md`、`template/docs/working/issues/README.md`、`dist/skills/`（decision-log / retrospective / session-handoff / worklog-extract）

- [x] **Step 9-1: 生成器を実行する** — Run: `./scripts/sync-template.ps1` と `./scripts/build-dist.ps1`（期待: いずれも終了コード 0。sync-template の出力は `Syncing 5 files + 3 empty indexes...` に変わる。記法規約違反があれば非ゼロで止まるので、違反を修正して再実行）
- [x] **Step 9-2: 両方を Check で実行する** — Run: `./scripts/sync-template.ps1 -Check` と `./scripts/build-dist.ps1 -Check`（期待: いずれも差分なし・終了コード 0）
- [x] **Step 9-3: 配布物の目視 5 点** — `dist/skills/` の変更 4 スキル・`template/docs/overview/issue-management.md`・`template/docs/overview/folder-structure.md`・`template/docs/working/issues/README.md` を読み、(1) 括弧内に識別子以外の語の同居、(2) 識別子を含む半角括弧、(3) 書式例の実在固有名、(4) 自己参照（「本リポジトリ」等）、(5) 除去後に文が壊れる箇所、の 5 点を確認する（機械判定が届かない型。CONTRIBUTING.md 参照）
- [x] **Step 9-4: 旧文言の残存ゼロ確認** — Run: `Get-ChildItem docs/overview, docs/current, skills, template, dist, CONTRIBUTING.md -Recurse -File -Include *.md | Select-String -Pattern '長期化・多観点化|多観点・長期|長期化したらフォルダ昇格|README\.md.{0,2}(とし|にする|とする)'`（期待: **2 件のみ**＝`docs/overview/issue-management.md` とその template 生成物の経過措置条項。「旧方式（README.md とする形）」は移行規定として意図された言及であり残存ではない。それ以外のヒットは 0 件であること。`docs/records/`・`docs/working/plans/` は ADR の Context・過去計画が旧文言を引用するため対象外）（実行時追記: 当初期待値 0 件は経過措置条項の追加を織り込んでいなかったため、実測に合わせて訂正した）
- [x] **Step 9-5: ソース・生成物・本計画を pathspec 付きで 1 コミットにまとめる** — Run:

```powershell
git status --short          # 意図外の untracked（inbox / conversation_log）を確認
git diff --cached --name-only   # 意図外の staged（handoff 等）が commit 対象に混ざらないことを確認（pathspec コミットなら混ざらない）
git commit -m "feat: Issue 肥大化抑制の実装（課題管理定義の新設・スキル配線。ADR-0094〜0098）" -- docs/overview/issue-management.md docs/overview/folder-structure.md docs/working/issues/README.md template.manifest template/ skills/decision-log/SKILL.md skills/retrospective/SKILL.md skills/session-handoff/SKILL.md skills/worklog-extract/SKILL.md dist/ CONTRIBUTING.md docs/current/specs/ docs/records/decisions/0096-issue-folder-promotion-trigger-and-role-system.md docs/working/plans/2026-08-15-issue-bloat-control-plan.md
```

（注: `git commit -- <paths>` は untracked を含められないため、新規ファイル `docs/overview/issue-management.md` と本計画ファイルは事前に `git add <個別パス>` してからコミットする。add も個別パス指定とし、ディレクトリ一括 add はしない）

---

### Task 10: プラグイン version bump（0.1.5）

**Files:**
- Modify: `.claude-plugin/plugin.json`（`"version": "0.1.4"` → `"0.1.5"`）
- Modify: `.claude-plugin/marketplace.json`（`"version": "0.1.4"` → `"0.1.5"`。ADR-0090 により両ファイル無条件）
- 生成物: `dist/.claude-plugin/plugin.json`

- [x] **Step 10-1: 両ファイルの version を `0.1.5` へ更新する**
- [x] **Step 10-2: `./scripts/build-dist.ps1` を再実行し、`./scripts/build-dist.ps1 -Check` で差分なしを確認した上で反映を検証する** — Run: `Select-String -Path .claude-plugin/plugin.json, .claude-plugin/marketplace.json, dist/.claude-plugin/plugin.json -Pattern '0\.1\.5'`（期待: 3 件）
- [x] **Step 10-3: コミット** — Run:

```powershell
git commit -m "chore: plugin 0.1.5 へ bump（Issue 肥大化抑制のスキル配線を配布）" -- .claude-plugin/ dist/.claude-plugin/
```

push は自動では行わない（本リポジトリの運用）。区切りとしてユーザーへ push 実施を確認する。

---

### Task 11: 完了検証と後続整理

- [x] **Step 11-1: フック配線の全数確認** — Run: `Get-ChildItem skills -Recurse -Filter SKILL.md | Select-String -Pattern '目安値超過ならフォルダ昇格|移設判定を実施'`（期待: decision-log 1 件以上・retrospective 1 件・session-handoff 1 件・worklog-extract 1 件）
- [x] **Step 11-2: 経過措置の確認** — 既存の**課題ファイル**（`docs/working/issues/system/`・`docs/working/issues/flow/` 配下）に変更が無いことを確認する（インデックス README.md の参照 1 行更新は Task 2-4 の意図した変更であり対象外。ADR-0096 の経過措置＝課題本体の遡及改修をしない、の検証）
- [x] **Step 11-3: ユーザーへ完了報告する**。報告に必ず含めるもの: (1) **新設した課題管理定義は template 配布（作成時 1 回コピー）のため、既存配布先には手動反映が必要**であること、(2) close のスキル配線は decision-log の 1 経路のみで、申し送り済み close・対処なし close は課題管理定義の close 条項が正であること（Step 3-4 で ADR-0096 に記録済み）、(3) 次工程は Accepted 昇格（サイクル全体整合検査を含む）・Issue-0088 close・retrospective であること

---

## 検証期待値とタスクの突合（レビュー反映後のセルフチェック）

- folder-structure の `issue-management` 期待値は **2 件**（§1 = Step 2-2 の 1 行、§7 前文 = Step 2-1 の 1 行。早見表の表内と Step 2-3 の新文はパス文字列を含まないため数えない）
- decision-log の `issue-management` 期待値は 3 件（Step 3-1/3-2/3-3 で各 1 行）。CONTRIBUTING の `close 時移設判定` は 2 件（Step 7-1/7-2）
- 旧文言 grep のパターンは表現ゆれ（`多観点・長期`）とバッククォート（`README\.md.{0,2}とし`）を吸収する形にした。除外範囲は `docs/records/`（ADR-0096 Context 等が旧文言を引用）と `docs/working/plans/`（本計画自身と過去計画が旧文言を引用）
- ポインタ表記は 4 スキル＋CONTRIBUTING とも「課題管理定義（標準: `docs/overview/issue-management.md`）」の標準パス併記形（ADR-0089 の型）に統一した。CONTRIBUTING の 2 フックのみフォールバック句を持たない（配信元リポジトリ内文書で定義が常在するため。Task 7 に根拠を明記）
- 索引の一言説明は ADR-0096 原案の「日本語」から「プロジェクトの記述言語」へ意図的に一般化した（template 配布物のため）。Step 3-4 で ADR-0096 側へ追補し、差分を吸収する
- close のスキル配線が 1 経路のみである判断（残 2 経路は定義側の「経路を問わず」条項が正）も Step 3-4 で ADR-0096 へ記録する
