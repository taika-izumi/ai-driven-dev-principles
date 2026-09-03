# ADR-0122 実装計画: session-handoff / decision-log の発火単位分割（Issue-0115 / 0116）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `skills/session-handoff/SKILL.md`（31,169B）と `skills/decision-log/SKILL.md`（26,837B）を発火単位（操作・用途／横断規範）で `references/` 13 ファイルへ分割し、本文を共通部＋ディスパッチ表に絞る。完了条件は ADR-0122 決定 1 の 2 条件（(a) 両本文 20KB 未満 (b) 最頻経路の実読み込み量が現行比で半減: session-handoff の update 素経路 ≤ 15.6KB、decision-log の新規ドラフト作成 ≤ 13.4KB）。

**Architecture:** 移設は**無改変の機械抽出**（`git show HEAD:<file> | sed -n 'A,Bp'` で範囲を切り出し、見出しレベルの昇格と列挙した参照書き換えのみを加える）とし、`diff` で「列挙外の差分ゼロ」を検証する。参照の張り替えは ADR-0122 決定 6 の (a)〜(g) を全数走査した結果を本計画の「張り替え判定規則」「(f) 単独では意味が確定しない要素」「(g) 一本化の対応表」へ写像し、各タスクはその写像を実行する。例外テーブル 2 行の削除・現用 spec の件数追従・version bump・Issue close・Accepted 昇格までを 1 サイクルで行う。

**Tech Stack:** Markdown（skills / docs）、PowerShell 7（`scripts/build-dist.ps1`）、git、Git Bash（`sed` / `diff` / `grep`）。`scripts/sync-template.ps1` は**実行しない**（`skills/` は ADR-0016 により template 対象外。`template.manifest` 記載 6 ファイルは変更しない。空インデックス生成対象のうち `docs/working/issues/README.md`・`docs/records/decisions/README.md` はテーブル行のみ変更し、`New-EmptyIndexContent` がデータ行を除去するため生成結果は変わらない。無差分は Task 7 Step 7-3 の `-Check` が確認する）。`python3` は Windows ストアのスタブで exit 49 を返すが、**`python` は 3.12.1 が動作する**（`docs/working/handoff/master.md` の申し送り「この環境に Python は無い」は `python3` についてのみ正しい。本計画は Python を使わないため影響しない）。

---

## 逸脱判断の既定

`skills/start-work/references/plan-deviation-defaults.md`（plugin 0.1.16 の版。稼働中の版が当該版であることを Step 0-3 で確認する。ソース側は出所注記のぶんだけ配布版と異なるのが設計どおりで、比較対は `dist/` 側を用いる）の既定どおり。基準の追加・強化は行わない。

- **確定前レビューからの引き継ぎ一覧の所在**: 2 系統。
  - **本計画自身の plan 確定点レビュー由来**（`plan-deviation-defaults.md` 前処理 2. の突合対象）: **不採用 3 件あり**。第 1 巡 —— (1) (g) へ「移設で作成・更新した正本ファイルの add 規定」をクラスタとして加えるか（**引き継ぎ先: Task 2 Step 2-10 の配布物目視**）／(2) `docs/current/specs/2026-04-12-meta-guidelines-design.md` を張り替え対象に加えるか（**引き継ぎ先: Task 8 Step 8-5 の観点 1**）。第 2 巡 —— (3) Step 6-3 の 2 本目の grep を Step 8-5 との重複として削るか（**引き継ぎ先: Task 8 Step 8-5**）。（第 2 巡で不採用とした「(g) の 40KB クラスタを撤回して両方に値を残すか」は、**第 3 巡で採用へ転じた**ため引き継ぎ対象から外れた。）いずれも不採用の理由と実証は末尾「確定前レビューの記録」の各巡を参照
  - **上流（ADR-0122 の spec 確定点 (c) レビュー。6 巡・15 体）由来**: 不採用判断は ADR-0122 本文（Considered Alternatives 1〜7・決定 1 の明示的受容）へ吸収済みで独立の一覧ファイルは無い。これは前処理 2. の突合対象ではなく、実装時に設計意図を確認する参照先である。退避は `~/.ai-dev-review-snapshots/MakeAiInstructions/2026-09-01-adr-0122-spec/`（r1〜r9）
- **前倒し型の判定 3 条件**: 部分成立（設計は確定済み＝成立、実コード全文を計画に載せられる規模＝**部分成立**〈移設本体は無改変の機械抽出であり、計画には切り出し範囲と改変点の全列挙を載せるが移設条文の全文複写は載せない〉、実行による安全網が無い＝**不成立**〈`build-dist.ps1` の規約判定・サイズ計測と、Task 1・2 の `diff` による列挙外差分ゼロ検証が安全網になる〉）。したがって**逐語厳守は課さず、格下げ安全弁（設計の変更に至ったタスクはタスク別独立レビューへ格下げ）のみ維持する**
- 逸脱記録は当該タスクの最後の手順の直後へ `逸脱記録: <型> / <帰結> / <識別子・根拠>` の 1 行で残す（行頭固定・直前に空行 1 行）
- **検出層**: 本計画はタスク別の仕様適合レビューを置かない工程型を採る（前倒し型の逐語厳守は課さないが、レビュー委譲も置かない）。したがって `plan-deviation-defaults.md`「逸脱記録と検出層」の代替規定に従い、**各タスクの完了時に委譲元が計画との差分（`git diff`）と逸脱記録行を突合する自己検査を行い、完了報告へ「逸脱突合: 一致」または「逸脱突合: 差分あり」の 1 行を残す**
- **日付リテラルの一般規定**: 本計画は作成日 2026-09-03 を各所に固定文字列で書いている。**本計画が課題・インデックス・ADR へ新規に書き込む日付リテラルは、例外なくすべて実装当日の日付へ機械的に読み替える**（列挙ではなく規則として適用する。読み替えは機械的な適応として当該タスクの逸脱記録へ 1 行残す）。**対象外**: 歴史的事実として書く実測日（ADR-0122 Context の「2026-09-01 実測」、Issue-0115/0116 本文の「2026-08-31 実測」）
- **行番号の扱い**: 本計画の行番号は 2026-09-03 時点の `HEAD`（`d56ba5c`）の実体である。各タスクは編集前に `grep -n` で行番号を再実測し、ずれていれば読み替える（機械的な適応として逸脱記録へ 1 行）

## 前提の確認（着手前に 1 度だけ）

- [ ] **Step 0-1: ブランチと現況を確認**

```bash
git branch --show-current && git status --short
```

Expected: `feature/issue-0115-0116-skill-split`。未追跡は 5 件——`docs/conversation_log.md`・`docs/inbox/` 3 件・**本計画ファイル自身**。前 4 件は本計画では触らず `git add` に巻き込まない（Issue-0020）。**本計画ファイルは Task 1 のコミットで追跡下へ入れる**（Task 6 が ADR-0122 へ本計画のパスを判定規則の正本として書き込み、Task 8 でその ADR を Accepted へ昇格させるため、未追跡のままでは確定記録が git に存在しないファイルを指す）

- [ ] **Step 0-2: 分割前のサイズと節構成を実測して控える**

```bash
wc -c skills/session-handoff/SKILL.md skills/decision-log/SKILL.md
```

Expected: `31169 skills/session-handoff/SKILL.md` / `26837 skills/decision-log/SKILL.md`（ADR-0122 Context と一致）

```bash
grep -n "^## \|^### " skills/session-handoff/SKILL.md
```

Expected（節の行番号。以降の切り出し範囲はこれを起点とする）: L10 ファイル配置 / L20 フォーマット / L85 `review=` の値定義 / L98 Status の意味 / L107 外部参照の書き方 / L111 節別の記載規範 / L127 「本サイクル」の定義 / L131 独立手順「移設」 / L141 種類別対応表 / L156 手順 / L168 操作 / L172 read / L190 create / L203 update / L214 finalize / L242 cycle-reset / L257 完了済みハンドオフの扱い / L261 対応する原則。**フェンス内の `## 作業の目的・背景` 〜 `## 重要な意思決定の履歴`（L30〜L80）も並ぶが、これはハンドオフ雛形の一部であり節ではない**（節見出し 18 行＋フェンス内 9 行＝出力は計 27 行）

```bash
grep -n "^## \|^### " skills/decision-log/SKILL.md
```

Expected: L10 いつ使うか / L14 強トリガー / L26 弱トリガー / L32 意思決定を伴わない起動契機 / L36 呼ぶ必要がない場面 / L44 ADR作成手順 / L46 0. / L52 1. / L64 2. / L101 3. / L109 4. / L128 Proposed の ADR へ決定を追記するとき / L140 未決事項 / L144 起票 / L149 ライフサイクル / L155 注意 / L160 ADR更新手順 / L162 終端ステータスの意味境界 / L173 ステータス変更 / L193 承認の昇格 / L215 サイクル全体整合検査 / L260 ユーザーへの確認。**このほかフェンス内の `## Context`（L76）/ `## Considered Alternatives`（L80）/ `## Decision`（L84）/ `## Consequences`（L88）も grep にヒットするが、これは ADR 雛形の一部であり節ではない**（節見出し 22 行＋フェンス内 4 行＝**出力は計 26 行**）

- [ ] **Step 0-3: 計画逸脱判断の既定の版を確認**

```bash
diff "$HOME/.claude/plugins/cache/ai-driven-dev-principles/ai-driven-dev-principles/0.1.16/skills/start-work/references/plan-deviation-defaults.md" dist/skills/start-work/references/plan-deviation-defaults.md && echo SAME
```

Expected: `SAME`（差分があれば宣言欄の版表記を実際に稼働している版へ読み替え、逸脱記録へ 1 行）

**比較対が `dist/` である理由**: plugin キャッシュへ配信されるのは `dist/`（出所識別子を除去した生成物）であり、`skills/` 側のソースとは**設計どおり一致しない**。実測: plugin キャッシュ 12,195B ＝ `dist/` 側と完全一致、`skills/` 側は 12,459B で 2 箇所差分（導入文の `（ADR-0119）` と末尾の `## 根拠` 節。いずれも生成器が除去する出所注記）。`skills/` 側と比べると本ゲートは構造上必ず失敗する。

- [ ] **Step 0-4: 参照の母数を控える（張り替えの取りこぼし検査の基準値）**

```bash
LANG=C.UTF-8 grep -rnF -e '「`review=` の値定義」' -e '「サイクル全体整合検査」' -e '「承認の昇格」' -e '「ステータス変更」' -e '独立手順「移設」' -e '節別の記載規範' skills/ CONTRIBUTING.md README.md docs/reference/README.md | wc -l
```

Expected: `32`（2026-09-03 実測）。本 Step で数えるのは**節名の出現総数**であり、旧形式参照の計数ではない（後者は Step 3-7 が 13 パターンで担う）。分割後は references ファイル内・SKILL.md 本文のディスパッチ表・横断規範の相互参照が加わるため**増える**（Task 3 完了後の実測は 34）。Step 3-7 の Expected を「0 件」と誤読しないための対照値として控える。

---

## ファイル構成

| ファイル | 区分 | 責務 / 変更内容 | Task |
|---|---|---|---|
| `skills/decision-log/references/adr-authoring.md` | 新規 | ADR 作成手順 0〜4・Proposed の ADR へ決定を追記するとき・ユーザーへの確認（現行 L44〜L138＋L260〜L276） | 1 |
| `skills/decision-log/references/open-questions.md` | 新規 | 未決事項（open questions）の扱い（現行 L140〜L158） | 1 |
| `skills/decision-log/references/status-updates.md` | 新規 | 終端ステータスの意味境界・ステータス変更・承認の昇格（現行 L160〜L213） | 1 / 2 |
| `skills/decision-log/references/cycle-consistency-check.md` | 新規 | サイクル全体整合検査（現行 L215〜L258） | 1 |
| `skills/decision-log/SKILL.md` | 変更 | 前文・検出トリガー一覧・用途ディスパッチ表に絞る（約 4.1KB） | 1 |
| `docs/working/plans/2026-09-03-adr-0122-skill-split-implementation.md` | 追跡開始 | 本計画ファイル自身。Task 6 が ADR-0122 から判定規則の正本として参照するため追跡下へ入れる | 1 |
| `skills/session-handoff/references/op-read.md` | 新規 | 操作 read（現行 L172〜L188） | 2 |
| `skills/session-handoff/references/op-create.md` | 新規 | 操作 create（現行 L190〜L201） | 2 |
| `skills/session-handoff/references/op-update.md` | 新規 | 操作 update（現行 L203〜L212） | 2 |
| `skills/session-handoff/references/op-finalize.md` | 新規 | 操作 finalize（現行 L214〜L240） | 2 |
| `skills/session-handoff/references/op-cycle-reset.md` | 新規 | 操作 cycle-reset（現行 L242〜L255） | 2 |
| `skills/session-handoff/references/relocation-map.md` | 新規 | 独立手順「移設」の導入と種類別対応表（現行 L131〜L154） | 2 |
| `skills/session-handoff/references/relocation-procedure.md` | 新規 | 独立手順「移設」の手順 1〜6（現行 L156〜L166） | 2 |
| `skills/session-handoff/references/review-field-values.md` | 新規 | `review=` の値定義（現行 L85〜L96） | 2 |
| `skills/session-handoff/references/section-volume-norms.md` | 新規 | 節別の記載規範（現行 L111〜L125） | 2 |
| `skills/session-handoff/SKILL.md` | 変更 | 前文・ファイル配置・フォーマット・Status・外部参照・「本サイクル」・操作ディスパッチ表・完了済みハンドオフの扱い・対応する原則に絞る（約 8.2KB） | 2 |
| `skills/start-work/SKILL.md` | 変更 | decision-log の移設先を指す参照 3 箇所の張り替え | 3 |
| `skills/pre-finalization-review/references/iteration-norms.md` | 変更 | session-handoff の移設先を指す参照 1 箇所 | 3 |
| `skills/pre-finalization-review/references/review-procedure.md` | 変更 | decision-log の移設先を指す参照 1 箇所 | 3 |
| `CONTRIBUTING.md` | 変更 | decision-log の移設対象節を指す 6 行の張り替え | 3 |
| `docs/reference/README.md` | 変更 | 独立手順「移設」のパス 1 箇所 | 3 |
| `docs/current/specs/2026-08-06-handoff-pruning-and-status-design.md` | 変更 | 正本ポインタ 2 箇所の張り替え（L40・L44） | 3 |
| `docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md` | 変更 | 正本ポインタ 1 箇所の張り替え（CONTRIBUTING L28 のスナップショット） | 3 |
| `docs/current/specs/2026-08-25-codex-support-design.md` | 変更 | 正本ポインタ 1 箇所の張り替え | 3 |
| `docs/current/specs/2026-08-13-handoff-bloat-control/00-overview.md` | 変更 | 分割の注記 1 行 | 3 |
| `docs/current/specs/2026-08-28-start-work-responsibility-split-design.md` | 変更 | 部分修正注記 1 行 | 3 |
| `docs/current/specs/2026-04-25-record-strengthening-design.md` | 変更 | 正本ポインタ 2 箇所の張り替え（L144・L225）＋分割の注記 2 行（§6.4・§7） | 3 |
| `docs/records/decisions/0028,0030,0032,0041,0042,0060,0075,0080,0086,0087,0088,0091,0092,0096,0099,0102,0105,0107,0108,0114,0120,0121-*.md` | 変更 | 部分修正注記 各 1 行（計 21 件） | 4 |
| `scripts/build-dist.ps1` | 変更 | 例外テーブルの暫定行 2 件を削除 | 5 |
| `docs/current/specs/2026-08-07-distributed-artifact-generation/02-distribution-generator.md` | 変更 | 数値 6 箇所の追従（件数 23→36・25→38・32→45、`✓` 行の除去数 2 件） | 5 |
| `docs/records/decisions/0122-*.md` | 変更 | 決定 6 の判明分を全数走査の実測へ更新（Proposed のため書き直し自由） | 6 |
| `.claude-plugin/plugin.json` / `.claude-plugin/marketplace.json` | 変更 | version 0.1.17 → 0.1.18 | 7 |
| `dist/**` / `.agents/plugins/marketplace.json` | 生成 | `build-dist.ps1` で再生成し、`skills/` を触った各タスクのコミットへ同梱する | 1・2・3・5・7 |
| `docs/records/decisions/0122-*.md` / `README.md` | 変更 | Status を Accepted へ | 8 |
| `docs/working/issues/flow/0115-*.md` / `0116-*.md` / `README.md` | 変更 | close | 8 |

**変更しないもの（判定済み）**: `docs/records/audits/`・`docs/records/retrospectives/`・過去 handoff・`docs/working/plans/` の過去計画・close 済み課題・open 課題内の経緯記述（ADR-0122 決定 6 末尾の壊れ許容の範囲）。**open 課題の「出所の名指し」の判定**（決定 6 末尾は「open 課題は出所の名指しに限り必要に応じて現状へ合わせる」と定める。`Status: open` の課題 59 件を全数走査した結果、**出所の名指し（所在ポインタ）**と判定した行は **6 件**（経緯記述・検討状況の日付つき記述は R5 で計数外。例: `flow/0102` L12 の再掲・`system/0008` L15・`flow/0044` の 4 行）。うち 1 件を現状へ合わせ、5 件を据え置く。本サイクルで close する Issue-0115 / 0116 の自己言及は対象に数えない）——

- **現状へ合わせる 1 件**: `docs/working/issues/flow/0085-…md` **L10**「session-handoff の様式 8 箇所（形式行・書式例・記載条件/命名規約・**節別記載規範**・**update**・**read**・**finalize 削除例外**・**「圧縮しないもの」保護リスト**）」— うち太字の 5 箇所が references へ移る（節別記載規範 → `section-volume-norms.md`／update → `op-update.md`／read → `op-read.md`／finalize の 2 件 → `op-finalize.md` 手順 4）。**同 L16 がこの 8 箇所を「対策の初期値とする」と定めており、経緯記述ではなく生きた運用データであるため追従させる**（Task 3 Step 3-6 で所在の注記 1 行を置く）
- **据え置き 5 件**: `0085-…md` L6「Post ラッパー消化記録」（本文残留節。R4）／`0102-…md` L6 `` `skills/session-handoff/SKILL.md`（cycle-reset 手順・パス解決規則） ``（前者は操作名で R1、後者は read 手順 2 の規則であって節名ではない）／`0099-…md` L12 の「`skills/session-handoff/SKILL.md` update の消化記録手順の同旨」（操作名。R1。**同行前半の「サイズ実測トリガー: C-07 / C-14 / J-09 / E-07」は監査台帳の記号であってパスの名指しではない**）／`0053-…md` L6・L12 `` `session-handoff` スキル（finalize） ``（操作名。R1）／`docs/working/issues/system/0071-…md` L16 の `decision-log/SKILL.md`（ファイル単位の表セル。節を指さない。R1）`docs/current/specs/2026-04-12-meta-guidelines-design.md`（L61・L128・L136・L202・L243。いずれもスキル名・ディレクトリ名のみで移設対象節を指さない。R1）。`docs/current/specs/2026-04-13-contributing-and-gateway-skill-design.md` L103（`skills/decision-log/SKILL.md` の**検出トリガー一覧**を指す生きた正本ポインタだが、当該節は本文残留のため据え置き。R4）。`docs/current/specs/2026-07-04-project-folder-structure/04-layer-docs-updates.md` L31（CONTRIBUTING のシナリオ名。非該当）。`docs/current/specs/2026-08-07-distributed-artifact-generation/05-source-migration.md` L18・L113・L154 と同 `00-overview.md` L40（いずれも `skills/session-handoff/SKILL.md` の**ハンドオフ書式テンプレート**＝本文残留のフォーマット節を指す。R4）。**現用 spec 45 ファイルを全数走査し、`session-handoff` / `decision-log` を含む 29 ファイルすべてを本計画の 3 分類（張り替え 7・所在注記 3・据え置き）のいずれかへ帰属させた**（第 1 巡の不採用 2「2026-04-12 を加えるか」の引き継ぎ先である Step 8-5 観点 1 は、この全数 45 に対する再確認として実施する）。`README.md` L38（機能説明であり所在ポインタではない）。`AGENTS.md` / `template/AGENTS.md`（スキル名のみ）。`docs/overview/issue-management.md` L7（スキル名のみ）。`skills/retrospective/SKILL.md` L42・L111、`skills/worklog-record/SKILL.md` L12・L19・L23、`skills/pre-finalization-review/SKILL.md` L56・L66・L72、`skills/start-work/SKILL.md` L20・L36・L52・L91・L95・L103・L120、`skills/start-work/references/plan-deviation-defaults.md` L34（いずれも操作名・用途名・本文残留節のみを指す。下記の張り替え判定規則 R1）。現用 spec のうち `2026-05-01-retrospective-design.md` L93（操作名）、`2026-07-04-project-folder-structure/03-skill-path-updates.md` L37・`2026-07-05-record-process-norms-design.md` L23〜L24・`2026-07-05-retrospective-issue-integration/03-related-doc-consistency.md` L5（いずれも当時の編集内容の記述であり現在の所在ポインタではない）、`2026-08-13-handoff-bloat-control/01-relocation-standard.md`・`02-volume-norms.md`（設計本文。所在は `00-overview.md` への注記 1 行で覆う）、`2026-08-05-dispatch-and-pre-review-skills-design.md`・`2026-07-17-worklog-skill-pipeline/02-skill1-record.md`（操作名のみ）。

## 張り替え判定規則（ADR-0122 決定 6 (d) の全数走査に適用した規則）

| 規則 | 参照の形 | 扱い |
|---|---|---|
| R1 | スキル名のみ、または「スキル名＋操作名／用途名」（例: `session-handoff` の **update** 操作、decision-log の未決事項起票） | 据え置き。操作名・用途名は分割後の SKILL.md 本文のディスパッチ表で一意に解決される |
| R2 | 「スキル名＋移設対象節の節名」（例: session-handoff「`review=` の値定義」節、`decision-log` の「承認の昇格」） | 節名の前に `references/<file>` を挿入する（前サイクル ADR-0121 の Task 6 と同形式） |
| R3 | `skills/<skill>/SKILL.md` のパス＋移設対象節 | パスを references ファイルへ置換する |
| R4 | 本文残留節（検出トリガー一覧・フォーマット節・Status の意味・「本サイクル」の定義・完了済みハンドオフの扱い）を指す参照 | 据え置き |
| R5 | 確定後不変の記録類（audits / retrospectives / 過去 plan / 過去 handoff / close 済み課題）・open 課題内の経緯記述 | 壊れを許容し変更しない（ADR-0122 決定 6 末尾） |
| R6 | 現用 spec が移設対象節を**記載箇所**として名指しする場合 | 所在の注記 1 行（当該 spec の変更対象一覧の直後）。ポインタが SKILL.md パス＋節なら R3 で張り替える |
| R7 | ADR が移設対象節を**記載箇所**（実装対象・正本の所在）として名指しする場合 | Consequences 末尾へ部分修正注記 1 行（Status は Accepted 維持）。規範の適用先・例え・実測の言及のみは非該当 |

## 跨り残存の同期対象（ADR-0122 決定 4 が実装計画への列挙を課す項目）

1. **`review=` の書式例**（本文残留の「ハンドオフファイルのフォーマット」節の書式例 2 行: `review=フル実施（claude-opus-5・2 巡）＋差分再確認（claude-opus-5・1 巡・実質収束）` と形式行の `review=<見送り or 非発火（推奨判定が偽） or 実施記録>`）— 語彙の完全な定義は `references/review-field-values.md`。値語彙（`フル実施` / `差分再確認` / `機械検証`・終了状態 4 値）を変えるときは両方を同時に直す
2. **`cyclecheck=` の値語彙**（本文残留のフォーマット節 形式行 `cyclecheck=<実施（指摘なし） or 実施（修正: <識別子>） or 非該当（理由）>`）— 正本は `decision-log` の `references/cycle-consistency-check.md`「記録」（既存の跨り。分割で所在が変わるため列挙する）
3. **4 観点の名称**は本サイクルの対象外（pre-finalization-review 側の同期対象。ADR-0121 実装計画 Task 5 参照）
4. **handoff 雛形の節名**（本文残留の「ハンドオフファイルのフォーマット」節のフェンス内が定義する `## 完了済みタスク`・`## 進行中のタスク`・`## 既知のブロッカー・懸念`・`## Post ラッパー消化記録`・`## 次セッション開始時のアクション`・`## 関連ドキュメント`・`## 作業の目的・背景` ほか）— これらを名指しする操作ファイルは `op-read.md`・`op-create.md`・`op-update.md`・`op-finalize.md`・`op-cycle-reset.md` の **5 件**（`op-create.md` は現行 L198〜L200 で「作業の目的・背景」「関連ドキュメント」「完了/進行中/未着手のタスク」を名指しする）。節名を変えるときは本文の雛形と 5 ファイルを同時に直す
5. **消化記録行の 200 字上限と値の限定**（(g) で非該当と裁定した数値定数の複写）— 正本は `section-volume-norms.md` の表、複写先は `op-update.md` 手順 3 の逐語規定と `review-field-values.md` の縮退規定・`relocation-map.md` 対応表の「1 件 200 字以内」。**数値 200 を変えるときは 4 箇所を同時に直す**
6. **サイズ実測の目安値 40KB とフォールバック句**（同上）— `op-read.md` 手順 4（実測手段・単位・目安値の原文）と `op-finalize.md` 手順 1 の再掲。**値を変えるときは 2 箇所を同時に直す**（現行の「実測手段・目安値は read の手順 4 と同じ（…デフォルト 40KB…）」という参照＋再掲の形をそのまま保つ。ADR-0105 L48 (d) はこの形をファイル内の一本化として達成済みと判定しているが、分割後はファイル間になるため同じ認定は引き継がれない——保持の理由は「finalize が毎回値を要する」ことにある）
7. **課題ファイルの目安値 10KB とフォールバック句**（同上）— `relocation-procedure.md` 手順 3 と `decision-log` の `references/open-questions.md`「注意」。**Issue-0099 が再判定対象として追跡中**（本サイクルでは触らない）

## (f) 分割後 13 ファイルの、単独では意味が確定しない語・手順・数値（ADR-0122 決定 6 (f) の完了基準）

各行は「そのファイル単独では定義・値が確定しない要素 → 所在」。**「（明示参照あり）」は現行本文に既に参照があるもの、「（新設）」は分割で新たに参照を書く必要があるもの、「（据え置き）」は参照を書かず据え置く判断をしたもの。** 新設は Task 1・2 の書き換え列挙に必ず含まれている（突合は各 Task の Step の列挙番号で行う）。

| ファイル | 単独では確定しない要素 → 所在 |
|---|---|
| `decision-log/references/adr-authoring.md` | 強/弱トリガーの種別名（手順 0 の通知文）→ SKILL.md「検出トリガー一覧」（据え置き。通知文の変数であり定義参照は不要）／「ステータス変更」の手順（手順 1・ユーザーへの確認）→ `status-updates.md`（新設 2 箇所）／「未決事項（open questions）の扱い」（記述規律注記の「後述」）→ `open-questions.md`（新設）／「承認の昇格」（ユーザーへの確認）→ `status-updates.md`（新設）／ADR-0041 のファイル削除規定 → `status-updates.md`「終端ステータスの意味境界」（据え置き。ユーザーへの確認の「却下」箇条が自己完結している）／台帳監査 → `CONTRIBUTING.md`「ADRを記録するとき」（明示参照あり）／spec 確定点 (c) → pre-finalization-review（明示参照あり）／`start-work` の Phase 2 Post（明示参照あり） |
| `decision-log/references/open-questions.md` | 課題管理定義・目安 10KB のフォールバック（明示参照あり・値は自ファイルで確定）／「通常どおり ADR を作成する」→ `adr-authoring.md`（新設）／close 時の移設判定 → 課題管理定義（明示参照あり） |
| `decision-log/references/status-updates.md` | 「ユーザーへの確認」（削除可否の参照）→ `adr-authoring.md`（新設）／「サイクル全体整合検査」（承認の昇格 手順 1 の「次節」）→ `cycle-consistency-check.md`（新設）／粒度点検 ADR-0059/0060 の規範 → `adr-authoring.md` の粒度注記・「Proposed の ADR へ決定を追記するとき」（据え置き。手順 2 は突合内容を自己完結して書いている）／反復・巡・終了時の定義 → pre-finalization-review `references/iteration-norms.md`（明示参照あり）・session-handoff `references/review-field-values.md`（Task 2 で張り替え）／「本サイクル」→ session-handoff SKILL.md（明示参照あり）／部分修正の型 → 自ファイル内で定義（確定）／`start-work` Phase 2 Post（明示参照あり） |
| `decision-log/references/cycle-consistency-check.md` | 「承認の昇格」の第 1 ステップ → `status-updates.md`（新設）／「本サイクル」→ session-handoff SKILL.md（明示参照あり）／規範・手順文書の型 → pre-finalization-review 提示規則（明示参照あり）／`cyclecheck=` の行形式・命名規約 → session-handoff SKILL.md フォーマット節（明示参照あり）／粒度点検 → `status-updates.md`「承認の昇格」手順 2（据え置き。「後続の粒度点検」の語で足りる）／課題起票 → `open-questions.md`（据え置き。「課題として起票に留め」は課題管理定義で確定する）／CONTRIBUTING の再点検規定・執行点（明示参照あり） |
| `session-handoff/references/op-read.md` | 要約で抽出する 3 要素の節名・確定点ラベル・`Accepted 昇格` ラベル → SKILL.md フォーマット節（据え置き。read の対象は handoff ファイルの実体であり雛形は SKILL.md 本文が常に同席する）／目安値 40KB → 自ファイルで確定（`op-finalize.md` が参照＋再掲の形でここを指す。(g) では非該当と裁定し跨り残存の同期対象 item 6 とした）／独立手順「移設」→ `relocation-procedure.md`（新設）／確定点の型 → pre-finalization-review（据え置き。ラベル文字列の照合のみ）／呼び出し元 `start-work`（明示参照あり） |
| `session-handoff/references/op-create.md` | 「上記フォーマット」→ SKILL.md「ハンドオフファイルのフォーマット」（新設）／最低限埋める項目として名指しする handoff 雛形の節名（作業の目的・背景／関連ドキュメント／完了・進行中・未着手のタスク）→ SKILL.md フォーマット節（据え置き。理由は `op-update.md` と同じ）／Status `in_progress` → SKILL.md「Status の意味」（据え置き。値そのものを書いている）／コミットは update/finalize → `op-update.md` / `op-finalize.md`（新設）／呼び出し元 `start-work` の Phase 1（明示参照あり） |
| `session-handoff/references/op-update.md` | 更新対象として名指しする handoff 雛形の節名（完了済みタスク・進行中のタスク・重要な意思決定の履歴・既知のブロッカー・懸念・Post ラッパー消化記録）→ SKILL.md フォーマット節（据え置き。update の対象は handoff ファイルの実体で、雛形は SKILL.md 本文が常に同席する）／確定点の型・成果物の型 3 値 → pre-finalization-review（明示参照あり）／`review=` の縮退規定 → `review-field-values.md`（新設）／`cyclecheck=` の値 → decision-log `references/cycle-consistency-check.md`（新設）／1 行の上限と値限定 → 自ファイルで確定（`section-volume-norms.md` と逐語で重複するが、(g) では非該当と裁定し跨り残存の同期対象 item 5 とした。update 手順 3 は行を書くたびに値を要するため）／移設の対応表 → `relocation-map.md`（新設）／移設を実行する場合の手順 3〜6 → `relocation-procedure.md`（新設。ADR-0122 (f) 判明分 (2)）／改訂記録規定 → decision-log `references/status-updates.md`（新設）／「本サイクル」（update では未使用） |
| `session-handoff/references/op-finalize.md` | 目安値 40KB とフォールバック句 → `op-read.md` 手順 4（新設。現行の「read の手順 4」という節参照をファイル参照へ改めるのみで、**同じ括弧内の数値の再掲はそのまま残す**。(g) では非該当と裁定〈ADR-0105 L48 (d) が参照＋再掲を一本化として認定済み〉）／「update と同様の更新」→ `op-update.md`（新設）／独立手順「移設」とその手順 1 → `relocation-procedure.md`（新設）／対応表 → `relocation-map.md`（新設）／「本サイクル」→ SKILL.md（明示参照あり）／Status 値 → SKILL.md「Status の意味」（据え置き。値そのものを書いている）／落とした情報の受け皿 → SKILL.md「完了済みハンドオフの扱い」（新設。(g) git 履歴クラスタ）／「次セッション開始時のアクション」節 → SKILL.md フォーマット節（据え置き。節名で足りる） |
| `session-handoff/references/op-cycle-reset.md` | 書き換え対象として名指しする handoff 雛形の節名（完了済みタスク・Post ラッパー消化記録・既知のブロッカー・懸念・作業の目的・背景・次セッション開始時のアクション）→ SKILL.md フォーマット節（据え置き。理由は `op-update.md` と同じ）／`retrospective` Phase 3（明示参照あり）／対応表と教訓型 3 分類 → `relocation-map.md`（新設）／移設の実行 → `relocation-procedure.md`（新設）／`ready-for-next-cycle` → SKILL.md「Status の意味」（据え置き）／受け皿 → SKILL.md「完了済みハンドオフの扱い」（新設。(g)）／finalize → `op-finalize.md`（新設） |
| `session-handoff/references/relocation-map.md` | 3 起点（finalize 手順 3・read 超過受諾・cycle-reset 前段）→ `op-finalize.md` / `op-read.md` / `op-cycle-reset.md`（新設）／判定材料としての参照元（update の移設判定・節別の記載規範・finalize 手順 4）→ `op-update.md` / `section-volume-norms.md` / `op-finalize.md`（新設）／手順 3〜6 → `relocation-procedure.md`（新設）／「節別の記載規範の分量内」→ `section-volume-norms.md`（新設）／「1 件 200 字以内」の値は自ファイルに残す（(g) で非該当と裁定したため参照化しない。跨り残存 item 5）／folder-structure・worklog-record・課題管理規約（明示参照あり） |
| `session-handoff/references/relocation-procedure.md` | 対応表の行名（worklog / 参照知識 / 課題）と「handoff に残すもの」列 → `relocation-map.md`（新設）／中リスク → pre-action-review（据え置き。語の意味は AGENTS.md の 3 段階で確定）／worklog-record の記録経路・課題管理定義・目安 10KB（明示参照あり・値は自ファイルで確定）／「関連ドキュメント」節 → SKILL.md フォーマット節（据え置き）／起点別の add 規定（finalize / read / cycle-reset / update の移設判定）→ `op-*.md`（新設） |
| `session-handoff/references/review-field-values.md` | フル巡・差分確認巡・実質収束の停止判定 → pre-finalization-review `references/iteration-norms.md`（明示参照あり）／1 行の上限 → 自ファイルで確定（値 200 は `section-volume-norms.md` と重複。跨り残存 item 5）／値限定の「判定結果」→ `section-volume-norms.md`（新設。ADR-0122 (f) 判明分 (1)）／「進行中のタスク」節 → SKILL.md フォーマット節（据え置き）／反復提示 → `iteration-norms.md`（明示参照あり） |
| `session-handoff/references/section-volume-norms.md` | 確定点・`Accepted 昇格` ラベル → SKILL.md フォーマット節（据え置き。表の 1 行目が「現行形式の必須要素」と書き、形式は本文が定める）／独立手順「移設」の対象 → `relocation-procedure.md`（新設）／対応表 → `relocation-map.md`（新設）／巡数・終了状態 → `review-field-values.md`（据え置き。値の所在は形式行の参照で確定）／サイズ実測トリガー → `op-read.md` 手順 4・`op-finalize.md` 手順 1（新設）／受け皿 → SKILL.md「完了済みハンドオフの扱い」（新設。(g)）／AGENTS.md の調整値（明示参照あり） |

## (g) 移設対象節どうしで重複している条文の一本化（ADR-0122 決定 6 (g)）

全数走査でクラスタ **5 件**を検出し、**一本化するのは 1 件**、**4 件は非該当**と裁定した。ADR-0122 決定 6 (g) は判明分として 200 字上限と git 履歴の 2 クラスタを挙げるが、**200 字上限は下記の理由で非該当へ振り替える**（決定 6 (g) の適用を狭める判断。理由は Task 6 で ADR へ記録する）。

**一本化する 1 件**:

| クラスタ | 正本（残す 1 箇所） | 参照へ置き換える箇所 |
|---|---|---|
| git 履歴（「落とした情報の受け皿は git 履歴のみ」の同趣旨 4 箇所） | SKILL.md 本文残留「完了済みハンドオフの扱い」（ADR-0074 の原文。アーカイブ機構を設けない決定と一体） | `section-volume-norms.md` の「圧縮・削除の実施記録」行（**「handoff に残さない」は別規定として保つ**）／`op-finalize.md` 手順 4 の「圧縮しないもの」段落（**「退避ファイルは作らない」は別規定として保つ**）／`op-cycle-reset.md` 手順 1 の括弧 |

**正本を SKILL.md 本文に置くため副作用が無い**——本文は全経路が必ず読むので、参照側に追加の読み込みが発生しない。

**非該当と判定した 4 件**（(g) の走査結果として残す）:

- **200 字上限**（「1 行 200 字以内・各フィールド値は判定結果＋安定識別子＋正本への参照に限定」が `section-volume-norms.md` と `op-update.md` 手順 3 に逐語で重複し、数値 200 が 3 箇所へ分散）— **一本化しない**。理由 1: `op-update.md` 手順 3 は消化記録行を書く手順で、上限値と値の限定は**行を書くたびに毎回必要**。参照化すると update が毎回 `section-volume-norms.md` を要し、**ADR-0121 決定 4 ②「発火時に毎回必要な内容の退避は認めない」**（分割の一般規範であり決定 6 (g) の上位）に触れる。理由 2: ADR-0122 決定 1 は最頻経路の素経路を「**節別の記載規範の参照…を伴わないもの**」と定義しており、参照化すると当該定義に当てはまる経路が実体から消え、完了条件 (b) の測定基盤が壊れる（実測: 参照化すると素経路は 12,670B → 15,273B で、閾値 15,600B に対し余裕 327B）。理由 3: 当該規定は「上限値」と「値の限定」が 1 文で不可分であり、値だけ残す切り分けに自然な境界がない
- **サイズ実測の目安値 40KB**（数値とフォールバック句が現行 L180〈read 手順 4〉・L219〈finalize 手順 1〉の 2 箇所へ分散）— **一本化しない**。理由 1: **ADR-0105 L48 (d) は当該 2 箇所について「ファイル内の一本化（C-14 が read 手順 4 を参照する形）は現状で達成済み」と判定している**。分割はこれをファイル間へ移すため (d) の認定はそのままでは引き継がれず、また ADR-0121 L50 が「(d)〈ファイル内一本化の既達成〉は C-14 固有の判定」と限定して読んでいるため、**(d) は再掲の保持を命じないが、除去の必然性も生まない**（(d) が支えるのは「文書側へ共通規範ノードを新設する統合先案」の否定であって、再掲の除去ではない）。理由 2: finalize 手順 1 はサイズ実測のたびに値を要するため、200 字と同じく ADR-0121 決定 4 ② に触れる。理由 3: ADR-0122 決定 6 (g) の判明分に本クラスタは含まれておらず、本計画が第 1 巡で追加したものである
- **移設で作成・更新した正本ファイルの add 規定**（現行 L166・L234・L255 の 3 箇所）— 一本化しない。実証: `relocation-procedure.md` へ移る手順 6（L166）が「どの操作を起点とする移設でも同じ。finalize ではコミット手順の add 対象に含め、read・cycle-reset 起点では…update の移設判定の手順を契機に正本へ書いた場合も…」と**全起点を統べる正本として既に一本化されている**。`op-finalize.md` 手順 7（L234）と `op-cycle-reset.md` 手順 6（L255）は各操作の実行手順内の指示で、しかも規定内容が異なる（前者は add してコミットする、後者は add してコミットしない）。同一条文の複写ではないため (g) の射程外
- **課題ファイルの目安値 10KB とフォールバック句**（`目安 10KB（プロジェクトの AGENTS.md（当該調整値の記載が無ければ CLAUDE.md）に調整値があればそれを優先）` が 4 箇所に逐語で存在。うち本サイクルの移設対象は現行 `skills/session-handoff/SKILL.md` L163〈→ `relocation-procedure.md`〉と `skills/decision-log/SKILL.md` L158〈→ `open-questions.md`〉の 2 件で、分割後は別ファイル間の複写になる）— **一本化しない**。実証: 10KB 句に対応するのは監査台帳の **J-09**（追記時のサイズ確認とフォルダ昇格の提案）で、ADR-0105 L48 の K3 クラスタ（C-07 / C-14 / J-09 / E-07）の構成員である。同 ADR は共通規範ノードへの統合を**検討したうえで覆し**、`docs/working/issues/flow/0099-…md` L12 が「存置。乖離リスクは受容済み。常設の監視経路は無い」として再判定を待つ状態にある。本サイクルで一本化すると ADR-0105 の決定を覆すことになるため、(g) の射程外とし Issue-0099 の再判定へ委ねる

**非該当 4 件のうち 200 字・40KB・10KB の 3 件は数値定数の複写が残る**ため、下記「跨り残存の同期対象」へ載せて変更時の同期対象とする（片側改定のリスクは、ADR-0105 が K3 クラスタについて採ったのと同じ「受容のうえ記録する」扱いになる）。


---

### Task 1: decision-log の references 型分割（4 ファイル＋本文）

**Files:**
- Create: `skills/decision-log/references/adr-authoring.md`
- Create: `skills/decision-log/references/open-questions.md`
- Create: `skills/decision-log/references/status-updates.md`
- Create: `skills/decision-log/references/cycle-consistency-check.md`
- Modify: `skills/decision-log/SKILL.md`

ADR-0122 決定 5 の実装。**コミットは本タスクの末尾で 1 回**とし、参照が宙に浮く中間状態を単独コミットにしない。session-handoff 側の references（Task 2 で新設）を指す参照 1 箇所（現行 L186 の session-handoff「`review=` の値定義」節）は**本タスクでは張り替えず**、Task 2 で行う（存在しないファイルを指す状態をコミットしないため）。

**移設の方式**: `git show HEAD:skills/decision-log/SKILL.md | sed -n '<範囲>p'` で切り出し、(1) ファイル冒頭に H1＋発火点の説明 1 文＋空行を置く (2) 切り出した範囲内の `### ` を `## ` へ昇格する (3) 下記に列挙した参照の書き換えのみを加える。それ以外は無改変。切り出し元の `## ADR作成手順`・`## 未決事項（open questions）の扱い`・`## ADR更新手順`・`### サイクル全体整合検査` の見出し行は各ファイルの H1 に置き換わるため範囲に含めない。

`skills/` 配下は配布対象ソースであり、記法規約（R1〜R5）が適用される。新規に書く導入文・ディスパッチ表・ポインタには出所識別子を持ち込まない。

- [ ] **Step 1-1: references ディレクトリを作り、4 ファイルを機械抽出する**

```bash
mkdir -p skills/decision-log/references
git show HEAD:skills/decision-log/SKILL.md | sed -n '46,139p;260,276p' | sed 's/^### /## /' > skills/decision-log/references/adr-authoring.body
git show HEAD:skills/decision-log/SKILL.md | sed -n '142,158p' | sed 's/^### /## /' > skills/decision-log/references/open-questions.body
git show HEAD:skills/decision-log/SKILL.md | sed -n '162,213p' | sed 's/^### /## /' > skills/decision-log/references/status-updates.body
git show HEAD:skills/decision-log/SKILL.md | sed -n '217,258p' > skills/decision-log/references/cycle-consistency-check.body
wc -l skills/decision-log/references/*.body
```

Expected: `adr-authoring.body` 111 行 / `open-questions.body` 17 行 / `status-updates.body` 52 行 / `cycle-consistency-check.body` 42 行（`.body` は作業用の中間ファイル。Step 1-2 で H1 と結合して `.md` にし、同 Step で削除する。**`.body` を残したまま `build-dist.ps1` を走らせない** — 走査対象に含まれ、**規約違反を出さずに配布物へ載る**〈実測: `.body` を 1 件残した状態で `Convention violations: 0` のまま `dist/…/adr-authoring.body` が生成される。ファイル数だけが 1 増える〉。**中断後の再開は必ず Step 1-1 から行う**（抽出は `>` による切り詰めで、`HEAD` も Task 内で不変なので冪等。Step 1-2 から再開すると古い `.body` を結合しうる）。`.body` の残置そのものは Step 1-7 の `Done. 29 files` がファイル数のずれとして検出する）

- [ ] **Step 1-2: 各ファイルの冒頭（H1＋導入 1 文）を置いて `.md` へ結合する**

導入文は発火点の説明に限り、直後の条文の書き出しと重複させない（Issue-0111 の教訓）。各ファイルの先頭 4 行は次のとおり（H1 / 空行 / 導入 1 文 / 空行）。Write ツールで先頭 4 行を書き、`.body` を末尾へ結合する。

`adr-authoring.md` の先頭:

```markdown
# ADR 作成手順

`decision-log` の新規ドラフト作成の正本（検出の報告・採番と置換対象の特定・ファイル作成・インデックス更新・コミットのタイミング・Proposed の ADR へ決定を追記するとき・作成後のユーザーへの確認）。意思決定を検出して ADR ドラフトを作る／追記するときに読む。

```

`open-questions.md` の先頭:

```markdown
# 未決事項（open questions）の扱い

`decision-log` の未決事項の課題起票の正本。仕様検討中に未解決の論点を検出したときに読む。

```

`status-updates.md` の先頭:

```markdown
# ADR 更新手順（終端ステータスの意味境界・ステータス変更・承認の昇格）

`decision-log` の既存 ADR の状態を変えるときの正本。Rejected / Deprecated / Superseded への遷移、Accepted 済み ADR 本文の改訂記録、Proposed → Accepted の昇格を扱う。

```

`cycle-consistency-check.md` の先頭:

```markdown
# サイクル全体整合検査

`decision-log` の Accepted 昇格時に実施する検査の正本。`status-updates.md`「承認の昇格」の第 1 ステップから読む。

```

```bash
for n in adr-authoring open-questions status-updates cycle-consistency-check; do cat skills/decision-log/references/$n.body >> skills/decision-log/references/$n.md && rm skills/decision-log/references/$n.body; done
ls skills/decision-log/references/
```

Expected: `adr-authoring.md  cycle-consistency-check.md  open-questions.md  status-updates.md`（`.body` が残っていないこと）

- [ ] **Step 1-3: 移設側の参照を張り替える（列挙 8 箇所）**

`adr-authoring.md`:

1. （現行 L62）`置換対象が見つかったら、新 ADR の作成と同時に旧 ADR を \`Superseded by ADR-XXXX\` へ更新する（「ステータス変更」の手順に従う）。` → `…へ更新する（\`status-updates.md\`「ステータス変更」の手順に従う）。`
2. （現行 L93）`未決事項は課題（\`docs/working/issues/\`）として分離する（後述「未決事項（open questions）の扱い」）。` → `…として分離する（\`open-questions.md\`）。`
3. （現行 L273）`- 確定: 「承認の昇格」の手順で Status を Accepted へ` → `- 確定: \`status-updates.md\`「承認の昇格」の手順で Status を Accepted へ`
4. （現行 L276）`- 却下（コミット済み）: 「ステータス変更」の手順で Status を \`Rejected\` へ` → `- 却下（コミット済み）: \`status-updates.md\`「ステータス変更」の手順で Status を \`Rejected\` へ`

`open-questions.md`:

5. （現行 L151）`1. その論点について意思決定を下したら、通常どおり ADR を作成する` → `1. その論点について意思決定を下したら、通常どおり ADR を作成する（\`adr-authoring.md\`）`

`status-updates.md`:

6. （現行 L171）`いずれの遷移でもファイルは削除しない（削除してよいのは未コミットのドラフトのみ。「ユーザーへの確認」参照）。` → `…（削除してよいのは未コミットのドラフトのみ。\`adr-authoring.md\`「ユーザーへの確認」参照）。`
7. （現行 L209）`1. **サイクル全体整合検査を実施する（ADR-0092）**: 手順は次節「サイクル全体整合検査」に従う。` → `1. **サイクル全体整合検査を実施する（ADR-0092）**: 手順は \`cycle-consistency-check.md\` に従う。`

`cycle-consistency-check.md`:

8. （現行 L217）`タスク単位のレビューでは検出できない累積ずれ・経路不全を、昇格チェックポイントで検査する工程（ADR-0092）。「承認の昇格」の第 1 ステップとして実施する。` → `…検査する工程（ADR-0092）。\`status-updates.md\`「承認の昇格」の第 1 ステップとして実施する。`

**据え置き（同一ファイル内に同居するため）**: `status-updates.md` の「ただし、Status を `Accepted` へ遷移させる場合は次の「承認の昇格」の手順に従う」（現行 L191）。**据え置き（Task 2 で張り替え）**: `status-updates.md` の session-handoff「`review=` の値定義」節（現行 L186）。**据え置き（本文残留節を指す R4）**: `status-updates.md` の session-handoff「「本サイクル」の定義」節（現行 L186）、`cycle-consistency-check.md` の同（現行 L221）と「行形式・命名規約は `session-handoff` スキル参照」（現行 L251）。

- [ ] **Step 1-4: 列挙外の差分がないことを `diff` で検証する**

```bash
diff <(git show HEAD:skills/decision-log/SKILL.md | sed -n '46,139p;260,276p' | sed 's/^### /## /') <(tail -n +5 skills/decision-log/references/adr-authoring.md) | grep -c '^[<>]'
diff <(git show HEAD:skills/decision-log/SKILL.md | sed -n '142,158p' | sed 's/^### /## /') <(tail -n +5 skills/decision-log/references/open-questions.md) | grep -c '^[<>]'
diff <(git show HEAD:skills/decision-log/SKILL.md | sed -n '162,213p' | sed 's/^### /## /') <(tail -n +5 skills/decision-log/references/status-updates.md) | grep -c '^[<>]'
diff <(git show HEAD:skills/decision-log/SKILL.md | sed -n '217,258p') <(tail -n +5 skills/decision-log/references/cycle-consistency-check.md) | grep -c '^[<>]'
```

Expected: `8` / `2` / `4` / `2`（それぞれ列挙 4 箇所・1 箇所・2 箇所・1 箇所の旧行＋新行。**これ以外の差分があれば無改変移設が破れている**。`grep -c` を外して `diff` の出力そのものを目視し、`<`/`>` の各対が Step 1-3 の列挙と 1 対 1 で対応することを確認する）

- [ ] **Step 1-5: SKILL.md 本文を共通部＋用途ディスパッチ表に絞る**

現行 L44〜L276 を削除し（L43 の空行は残す）、末尾へ次を置く:

```markdown
## 参照ファイル（用途ディスパッチ表）

本スキルの正本は本ファイルと `references/` 4 ファイルに分かれる。起動契機で用途が決まるため、該当する 1 ファイルだけを読む（検出トリガー一覧は本ファイルに残り、どの用途でも読む）。

| 用途（起動契機） | ファイル | 正本として持つ内容 |
|---|---|---|
| 新規ドラフトの作成・Proposed への追記 | `references/adr-authoring.md` | 検出の報告／採番と置換対象の特定／ファイル作成（記述規律・実行可能性・評価可能性・粒度の各注記を含む）／インデックス更新／コミットのタイミング／Proposed の ADR へ決定を追記するとき／ユーザーへの確認 |
| 未決事項の課題起票 | `references/open-questions.md` | 起票・ライフサイクル・注意（フォルダ昇格の提案） |
| 既存 ADR のステータス変更・Accepted 済み本文の改訂・承認の昇格 | `references/status-updates.md` | 終端ステータスの意味境界／ステータス変更（改訂記録規定・部分修正の型を含む）／承認の昇格（チェックポイント・昇格手順 3 ステップ） |
| Accepted 昇格時のサイクル全体整合検査 | `references/cycle-consistency-check.md` | 発動契機・発動条件の判定・固定 5 観点・重複実施の抑止・検査結果の扱い・記録・退役 |
```

あわせて「意思決定を伴わない起動契機」（現行 L34）の `「ステータス変更」節の改訂記録規定（ADR-0108）を適用する` を `\`references/status-updates.md\`「ステータス変更」の改訂記録規定（ADR-0108）を適用する` へ張り替える（本文から移設先への参照。ADR-0122 決定 6 (a)）。

- [ ] **Step 1-6: サイズ・構成・宙に浮いた参照の不在を検証する**

```bash
wc -c skills/decision-log/SKILL.md skills/decision-log/references/*.md
```

Expected: `SKILL.md` は **4,000〜4,200B**（20,000 未満。内訳の実測: 本文 2,579B＋Step 1-5 の張り替え増分 27B＋ディスパッチ表 1,467B ＝ **4,073B**。ADR-0122 の概算 3.4KB はディスパッチ表を約 1KB と見積もったための過少値で、**設計ではなく見積りのずれ**）。`adr-authoring.md` 8,750B / `open-questions.md` 2,852B / `status-updates.md` 6,788B / `cycle-consistency-check.md` 6,856B。**完了条件 (b)**: `SKILL.md`＋`adr-authoring.md` の合計が **13,400B 以下**（現行 26,837B の半減。実測見込み **12,823B**）

```bash
grep -n "^## \|^### " skills/decision-log/SKILL.md
```

Expected: `## いつ使うか — 検出トリガー一覧` / `### 強トリガー` / `### 弱トリガー` / `### 意思決定を伴わない起動契機` / `### 呼ぶ必要がない場面` / `## 参照ファイル（用途ディスパッチ表）` の **6 行**のみ

```bash
LANG=C.UTF-8 grep -rnF -e '後述「未決事項' -e '次節「サイクル全体整合検査」' -e '（「ステータス変更」の手順に従う）' -e '「ステータス変更」節の改訂記録規定' skills/decision-log/
```

Expected: 0 件（同一ファイル前提の相対参照が残っていないこと。**`-F` は必須**——多バイト文字に量指定子を付けた正規表現はこの環境でバイト単位に解釈され空振りする。前サイクル Task 6 Step 6-7 の実測）

```bash
ls skills/decision-log/references/ | grep -c body
```

Expected: `0`

- [ ] **Step 1-7: 生成器で記法規約とサイズ警告を検査する**

```bash
pwsh scripts/build-dist.ps1 2>&1 | grep -E "Convention violations|Aborted|Done\.|WARNING|警告"
```

Expected: `[build-dist] Convention violations: 0` と `[build-dist] Done. 29 files written to dist/, 1 to repository root.`（skills 23＋4＝27、plugin.json 2）。`Aborted` が出ないこと。**decision-log の警告行が出ないこと**（本文が承認済みサイズ 26837 を大きく下回るため）

- [ ] **Step 1-8: 配布物の目視（執行点 手順 4）**

`dist/skills/decision-log/SKILL.md` と `dist/skills/decision-log/references/` 4 ファイルを読み、括弧内に識別子以外の語が同居した行・半角括弧・書式例の実在の固有名・自己参照が残っていないことを確認する。

```bash
LANG=C.UTF-8 grep -nE "（[^）]*（|）に従い|\(\)|本リポジトリ|本 repo" dist/skills/decision-log/SKILL.md dist/skills/decision-log/references/*.md
```

Expected: **ヒット 5 件で、いずれも除去残骸ではないこと**（既知の正当な入れ子括弧 5 件。ヒット総数 0 を期待しない——総数ゼロを Expected にすると実運用で必ず外れ、検査が形骸化する。ヒット行は 1 件ずつ「除去後に文法が破綻した残骸か」を判定する。`LANG=C.UTF-8` の前置は必須——否定文字クラス `[^）]` はロケール未設定だとバイト単位に解釈され検出力が落ちる。前サイクル Task 12 Step 12-5 の実測）。**この grep は補助であり、目視での通読を省略しない**（書式例の実在の固有名と自己参照は grep では拾えない）

- [ ] **Step 1-9: コミット**

```bash
git add skills/decision-log dist .agents/plugins/marketplace.json docs/working/plans/2026-09-03-adr-0122-skill-split-implementation.md && git commit -m "refactor: decision-log を発火単位で references 4 ファイルへ分割（ADR-0122 決定 5。本文は検出トリガー一覧と用途ディスパッチ表）"
```

**本計画ファイルを本コミットに含める**（Task 6 が ADR-0122 へ本計画のパスを判定規則の正本として書き込み、Task 8 でその ADR を Accepted へ昇格させるため。過去サイクルの実装計画はいずれも追跡下にある）。以降の各タスクでも、逸脱記録行を追記した場合は同じコミットへ本計画を含める。

逸脱記録: 事実誤り・期待値の陳腐化の訂正 / 採用 / Step 1-2 が逐語指定した `cycle-consistency-check.md` の導入文第 2 文が本体 L5 と発火点の記述で重複し、計画自身の「導入文を直後の条文の書き出しと重複させない」規定に反する。向きは Task 2 Step 2-2 の同旨規則（本体が発火点を書くファイルの導入文は正本の説明のみを書く）が決めるため導入文側の第 2 文を削除（本体側の削除は無改変の機械抽出という設計の核を破るため採らない）。Step 1-6 の Expected 6,856B は実測 6,780B へ読み替え、完了条件 (b) は当該ファイルを含まないため不変。本行と同じコミットで適用

---

### Task 2: session-handoff の references 型分割（9 ファイル＋本文）＋ decision-log 側の相互参照 1 箇所

**Files:**
- Create: `skills/session-handoff/references/op-read.md` / `op-create.md` / `op-update.md` / `op-finalize.md` / `op-cycle-reset.md`
- Create: `skills/session-handoff/references/relocation-map.md` / `relocation-procedure.md`
- Create: `skills/session-handoff/references/review-field-values.md` / `section-volume-norms.md`
- Modify: `skills/session-handoff/SKILL.md`
- Modify: `skills/decision-log/references/status-updates.md`（Task 1 で据え置いた 1 箇所）

ADR-0122 決定 4 の実装。**コミットは本タスクの末尾で 1 回**。移設の方式は Task 1 と同じ（`git show HEAD:skills/session-handoff/SKILL.md` から機械抽出。Task 1 のコミットは session-handoff を触らないため HEAD の行番号は Step 0-2 の値のまま）。切り出し元の各見出し行（`### \`review=\` の値定義（ADR-0107）` / `### 節別の記載規範（ADR-0088）` / `## 独立手順「移設」（ADR-0086）` / `### 手順` / `### N. <操作>`）は各ファイルの H1 に置き換わるため範囲に含めない。`relocation-map.md` 内の `### 種類別対応表` は `## 種類別対応表` へ昇格する。

**(g) の一本化と (f) の新設参照は、下記 Step 2-3 の列挙に含めてある**（列挙番号の横に `(g)` / `(f)` を付す）。

- [ ] **Step 2-1: references ディレクトリを作り、9 ファイルを機械抽出する**

```bash
mkdir -p skills/session-handoff/references
S=skills/session-handoff/SKILL.md; R=skills/session-handoff/references
git show HEAD:$S | sed -n '87,96p'   > $R/review-field-values.body
git show HEAD:$S | sed -n '113,125p' > $R/section-volume-norms.body
git show HEAD:$S | sed -n '133,154p' | sed 's/^### /## /' > $R/relocation-map.body
git show HEAD:$S | sed -n '158,166p' > $R/relocation-procedure.body
git show HEAD:$S | sed -n '174,188p' > $R/op-read.body
git show HEAD:$S | sed -n '192,201p' > $R/op-create.body
git show HEAD:$S | sed -n '205,212p' > $R/op-update.body
git show HEAD:$S | sed -n '216,240p' > $R/op-finalize.body
git show HEAD:$S | sed -n '244,255p' > $R/op-cycle-reset.body
wc -l $R/*.body
```

Expected（行数）: `review-field-values` 10 / `section-volume-norms` 13 / `relocation-map` 22 / `relocation-procedure` 9 / `op-read` 15 / `op-create` 10 / `op-update` 8 / `op-finalize` 25 / `op-cycle-reset` 12。**中断後の再開は必ず本 Step から行う**（Task 1 Step 1-1 と同じ理由。抽出は冪等）

- [ ] **Step 2-2: 各ファイルの冒頭（H1＋導入 1 文）を置いて `.md` へ結合する**

先頭 4 行（H1 / 空行 / 導入 1 文 / 空行）を Write ツールで書き、`.body` を結合する。

**操作 5 ファイルの導入文は「本ファイルが何の正本か」だけを書き、呼び出し元は書かない。** 結合される本体の第 1 行が `呼ばれるタイミング: …` であり（現行 L174・L192・L205・L216・L244）、呼び出し元を導入文にも書くと直後の行と重複する（計画自身の「導入文を直後の条文の書き出しと重複させない」規定に反する。Issue-0111 の教訓）。横断規範 4 ファイルの本体は `呼ばれるタイミング:` 行を持たないため、導入文で発火点を説明する。

| ファイル | H1 | 導入 1 文 |
|---|---|---|
| `op-read.md` | `# read — ハンドオフ読み込み` | `` `session-handoff` の read 操作の正本。 `` |
| `op-create.md` | `# create — 新規ハンドオフ作成` | `` `session-handoff` の create 操作の正本。 `` |
| `op-update.md` | `# update — マイルストーン更新` | `` `session-handoff` の update 操作の正本。 `` |
| `op-finalize.md` | `# finalize — セッション終了確定` | `` `session-handoff` の finalize 操作の正本。 `` |
| `op-cycle-reset.md` | `# cycle-reset — サイクル完了リセット` | `` `session-handoff` の cycle-reset 操作の正本。 `` |
| `relocation-map.md` | `# 独立手順「移設」の導入と種類別対応表（ADR-0086）` | `移設先を判定するときに読む（update の移設判定・finalize の圧縮・cycle-reset の申し送り点検）。実際に記述を正本へ移す手順は `relocation-procedure.md`。` |
| `relocation-procedure.md` | `# 独立手順「移設」の手順（ADR-0086）` | `実際に記述を正本へ移すときに読む。判定材料の種類別対応表は `relocation-map.md`。` |
| `review-field-values.md` | `` # `review=` の値定義（ADR-0107） `` | `確定点（spec 確定点 / plan 確定点）を通過したマイルストーンの消化記録行を書くときに読む。` |
| `section-volume-norms.md` | `# 節別の記載規範（ADR-0088）` | `書き込み系操作で節の分量・書き分けを判断するときに読む。` |

```bash
R=skills/session-handoff/references
for n in op-read op-create op-update op-finalize op-cycle-reset relocation-map relocation-procedure review-field-values section-volume-norms; do cat $R/$n.body >> $R/$n.md && rm $R/$n.body; done
ls $R/ | grep -c body; ls $R/*.md | wc -l
```

Expected: `0` と `9`

- [ ] **Step 2-3: 移設側の参照を張り替える（列挙 29 項目・変更行 27 行）**

`review-field-values.md`（変更行 1: 現行 L96）:

1. 同行末尾 `巡数・終了状態は消化記録の値限定の「判定結果」に含まれる。` → `巡数・終了状態は消化記録の値限定（\`section-volume-norms.md\`）の「判定結果」に含まれる。` **(f)**

`section-volume-norms.md`（変更行 4: 現行 L121・L122・L123・L125）:

2. `教訓型に膨らんだものは独立手順「移設」の対象` → `教訓型に膨らんだものは独立手順「移設」（\`relocation-procedure.md\`）の対象` **(f)**
3. `超える内容は独立手順「移設」の対応表に従って正本へ移して` → `超える内容は独立手順「移設」の対応表（\`relocation-map.md\`）に従って正本へ移して` **(f)**
4. `| 圧縮・削除の実施記録 | handoff に残さない。受け皿は git 履歴のみとする（ADR-0074） |` → `| 圧縮・削除の実施記録 | handoff に残さない。落とした情報の受け皿は SKILL.md「完了済みハンドオフの扱い」に従う（ADR-0074） |` **(g)**（「handoff に残さない」は別規定として保つ）
5. `既定規則の移設とサイズ実測トリガーの二段構えで受け止める` → `既定規則の移設とサイズ実測トリガー（\`op-read.md\` 手順 4・\`op-finalize.md\` 手順 1）の二段構えで受け止める` **(f)**

`relocation-map.md`（変更行 6: 現行 L133・L135・L136・L137・L139・L147）:

6. `操作（read / update / finalize / cycle-reset）から独立した名前付き手順であり、手順全体は次の 3 起点から実行される:` → `…名前付き手順であり、手順全体（\`relocation-procedure.md\`）は次の 3 起点から実行される:` **(f)**
7. `- finalize の圧縮前段（実施条件は finalize 手順 3）` → `- finalize の圧縮前段（実施条件は \`op-finalize.md\` 手順 3）` **(f)**
8. `- read でサイズ超過を提案しユーザーが受諾した時（その場で実行）` → `- read（\`op-read.md\`）でサイズ超過を提案しユーザーが受諾した時（その場で実行）` **(f)**
9. `- cycle-reset の申し送り現役性点検の前段（教訓型を落とす前に移設する）` → `- cycle-reset（\`op-cycle-reset.md\`）の申し送り現役性点検の前段（教訓型を落とす前に移設する）` **(f)**
10. `このほか、種類別対応表は update の移設判定の手順・節別の記載規範（既知のブロッカー・懸念の行、列挙外の節への既定規則）・finalize 手順 4 の「圧縮しないもの」規定からも書き分けの判定に参照される。対応表に従って実際に記述を正本へ移す場合は、起点にかかわらず手順 3〜6 に従う。` → `このほか、種類別対応表は update の移設判定の手順（\`op-update.md\` 手順 4）・節別の記載規範（\`section-volume-norms.md\` の既知のブロッカー・懸念の行、列挙外の節への既定規則）・finalize 手順 4（\`op-finalize.md\`）の「圧縮しないもの」規定からも書き分けの判定に参照される。対応表に従って実際に記述を正本へ移す場合は、起点にかかわらず \`relocation-procedure.md\` の手順 3〜6 に従う。` **(f)**
11. `| 進行中タスクの状態・残り | handoff（進行中の作業。唯一 handoff が正本でよい） | そのまま（節別の記載規範の分量内） |` → `…| そのまま（節別の記載規範〈\`section-volume-norms.md\`〉の分量内） |` **(f)**

`relocation-procedure.md`（変更行 3: 現行 L158・L164・L166）:

12. `1. handoff を走査し、対応表の worklog / 参照知識 / 課題の行に該当する記述` → `1. handoff を走査し、対応表（\`relocation-map.md\`）の worklog / 参照知識 / 課題の行に該当する記述` **(f)**
13. `4. handoff 側の記述を対応表の「handoff に残すもの」へ置換する。` → `4. handoff 側の記述を対応表（\`relocation-map.md\`）の「handoff に残すもの」へ置換する。` **(f)**
14. `（どの操作を起点とする移設でも同じ。finalize ではコミット手順の add 対象に含め、read・cycle-reset 起点では次のコミット時に handoff と同時に add する。update の移設判定の手順を契機に正本へ書いた場合も、次のコミット時に handoff と同時に add する。` → `（どの操作を起点とする移設でも同じ。finalize（\`op-finalize.md\` 手順 7）ではコミット手順の add 対象に含め、read・cycle-reset 起点（\`op-read.md\` / \`op-cycle-reset.md\`）では次のコミット時に handoff と同時に add する。update の移設判定の手順（\`op-update.md\` 手順 4）を契機に正本へ書いた場合も、次のコミット時に handoff と同時に add する。` **(f)**

`op-read.md`（変更行 1: 現行 L186）:

15. `ユーザーが受諾したら、独立手順「移設」を**その場で実行する**` → `ユーザーが受諾したら、独立手順「移設」（\`relocation-procedure.md\`）を**その場で実行する**` **(f)**

`op-create.md`（変更行 2: 現行 L195・L201）:

16. `1. 上記フォーマットに沿って新規ファイルを作成する` → `1. SKILL.md「ハンドオフファイルのフォーマット」節に沿って新規ファイルを作成する` **(f)**
17. `4. ファイルを git に add するが、コミットは update/finalize にゆだねる` → `4. ファイルを git に add するが、コミットは update（\`op-update.md\`）/ finalize（\`op-finalize.md\`）にゆだねる` **(f)**

`op-update.md`（変更行 2: 現行 L210・L211。L210 は 1 行に 3 箇所）:

18. `（値の定義は \`decision-log\` スキルの「サイクル全体整合検査」を参照。ADR-0092）` → `（値の定義は \`decision-log\` の \`references/cycle-consistency-check.md\` を参照。ADR-0092）` **(f)**
19. `ただし 1 行 200 字を超える場合は「\`review=\` の値定義」節の縮退規定に従い、中間の方式要素を正本側へ移す` → `ただし 1 行 200 字を超える場合は \`review-field-values.md\` の縮退規定に従い、中間の方式要素を正本側へ移す` **(f)**（節名参照をファイル名参照へ。**200 字の値はそのまま残す**）
20. `Accepted 済み ADR 本文の改訂を含んでいた場合は decision-log の改訂記録規定を適用する（ADR-0108）` → `…含んでいた場合は decision-log の \`references/status-updates.md\` の改訂記録規定を適用する（ADR-0108）` **(f)**
21. `4. 各節への追記で詳細を書きたくなったら、正本（対応する ADR / issue / worklog / 参照知識ドキュメント）へ書き、handoff の行には参照を書く（独立手順「移設」の対応表に従う。ADR-0088）` → `…handoff の行には参照を書く（独立手順「移設」の対応表〈\`relocation-map.md\`〉に従う。正本へ書いた場合は \`relocation-procedure.md\` の手順 3〜6 に従い、手順 6 のとおり次のコミット時に handoff と同時に add する。ADR-0088）` **(f)**（ADR-0122 (f) 判明分 (2)）

`op-finalize.md`（変更行 5: 現行 L219・L220・L221・L224・L226）:

22. `実測手段・目安値は read の手順 4 と同じ` → `実測手段・目安値は \`op-read.md\` 手順 4 と同じ` **(f)**（**同じ括弧内に続く「シェルで実測。デフォルト 40KB、プロジェクトの AGENTS.md（…）に調整値があればそれを優先する」の再掲はそのまま残す**——(g) で非該当と裁定したため。ADR-0105 L48 (d) が参照＋再掲の形を一本化として認定済み）
23. `2. update と同様の更新を実施する` → `2. update（\`op-update.md\`）と同様の更新を実施する` **(f)**
24. `3. **独立手順「移設」を実施する**（ADR-0086）。手順 1 で目安値を超過していた場合は**必須**。超過していない場合も、対応表に該当する記述を見つけたら実施する。該当する記述の有無は独立手順「移設」の手順 1（handoff の走査）で判定する` → `3. **独立手順「移設」（\`relocation-procedure.md\`）を実施する**（ADR-0086）。手順 1 で目安値を超過していた場合は**必須**。超過していない場合も、対応表（\`relocation-map.md\`）に該当する記述を見つけたら実施する。該当する記述の有無は \`relocation-procedure.md\` の手順 1（handoff の走査）で判定する` **(f)**
25. `**ただし本サイクル（定義は「「本サイクル」の定義」節）の` → `**ただし本サイクル（定義は SKILL.md「「本サイクル」の定義」節）の` **(f)**
26. `落とした情報の受け皿は git 履歴のみとし、退避ファイルは作らない（ADR-0074）。なお「正本が handoff 以外にないもの」の保護は、**独立手順「移設」で正本を外へ作るまでの暫定**である。移設の対応表に該当する記述は` → `落とした情報の受け皿は SKILL.md「完了済みハンドオフの扱い」に従い、退避ファイルは作らない（ADR-0074）。なお「正本が handoff 以外にないもの」の保護は、**独立手順「移設」（\`relocation-procedure.md\`）で正本を外へ作るまでの暫定**である。移設の対応表（\`relocation-map.md\`）に該当する記述は` **(g)(f)**（「退避ファイルは作らない」は別規定として保つ）

`op-cycle-reset.md`（変更行 3: 現行 L247・L251・L255）:

27. `1. 完了サイクルの経緯を落とす（受け皿は git 履歴のみ。ADR-0074）:` → `1. 完了サイクルの経緯を落とす（受け皿は SKILL.md「完了済みハンドオフの扱い」に従う。ADR-0074）:` **(g)**
28. `2. 「既知のブロッカー・懸念」の各項目を独立手順「移設」の対応表で判定し、教訓型（worklog / 参照知識 / 課題に該当するもの）を**落とす前に移設する**（ADR-0086）` → `2. 「既知のブロッカー・懸念」の各項目を独立手順「移設」の対応表（\`relocation-map.md\`）で判定し、教訓型（worklog / 参照知識 / 課題に該当するもの）を**落とす前に \`relocation-procedure.md\` の手順 3〜6 で移設する**（ADR-0086）` **(f)**
29. `セッション終了時の finalize または通常フローのコミットに委ねる` → `セッション終了時の finalize（\`op-finalize.md\`）または通常フローのコミットに委ねる` **(f)**

（列挙は 29 項目・変更行 27 行。1 行に複数項目があるもの: L210 に 3 項目〈18〜20〉。第 3 巡の設計縮小により、200 字上限と 40KB の一本化に伴う 3 項目〈旧 1・13・21〉を取り下げた——両クラスタは (g) で非該当と裁定したため無改変で移す）

**据え置き（本文残留節を指す R4、または外部スキルへの既存参照）**: `review-field-values.md` の pre-finalization-review `references/iteration-norms.md` 参照 2 箇所（L87・L91）／`op-update.md` L209 の pre-finalization-review 提示規則参照と L210 の同「確定点での提示（提示規則）」節参照／`relocation-map.md` L143 の folder-structure・worklog-record／`relocation-procedure.md` L163 の worklog-record・課題管理定義／`op-read.md` L174 の `start-work`／`op-cycle-reset.md` L244 の `retrospective`。

- [ ] **Step 2-4: 列挙外の差分がないことを `diff` で検証する**

```bash
S=skills/session-handoff/SKILL.md; R=skills/session-handoff/references
diff <(git show HEAD:$S | sed -n '87,96p')   <(tail -n +5 $R/review-field-values.md)  | grep -c '^[<>]'
diff <(git show HEAD:$S | sed -n '113,125p') <(tail -n +5 $R/section-volume-norms.md) | grep -c '^[<>]'
diff <(git show HEAD:$S | sed -n '133,154p' | sed 's/^### /## /') <(tail -n +5 $R/relocation-map.md) | grep -c '^[<>]'
diff <(git show HEAD:$S | sed -n '158,166p') <(tail -n +5 $R/relocation-procedure.md) | grep -c '^[<>]'
diff <(git show HEAD:$S | sed -n '174,188p') <(tail -n +5 $R/op-read.md)        | grep -c '^[<>]'
diff <(git show HEAD:$S | sed -n '192,201p') <(tail -n +5 $R/op-create.md)      | grep -c '^[<>]'
diff <(git show HEAD:$S | sed -n '205,212p') <(tail -n +5 $R/op-update.md)      | grep -c '^[<>]'
diff <(git show HEAD:$S | sed -n '216,240p') <(tail -n +5 $R/op-finalize.md)    | grep -c '^[<>]'
diff <(git show HEAD:$S | sed -n '244,255p') <(tail -n +5 $R/op-cycle-reset.md) | grep -c '^[<>]'
```

Expected: `2` / `8` / `12` / `6` / `2` / `4` / `4` / `10` / `6`（変更行 1・4・6・3・1・2・2・5・3 の各 2 倍。**これ以外の差分があれば無改変移設が破れている**。`grep -c` を外して `diff` 出力を目視し、各対が Step 2-3 の列挙と対応することを確認する）

- [ ] **Step 2-5: SKILL.md 本文を共通部＋操作ディスパッチ表に絞る**

現行の L1〜L84（前文・ファイル配置・フォーマット節のフェンス）、L98〜L110（Status の意味・外部参照の書き方）、L127〜L130（「本サイクル」の定義）、L257〜L264（完了済みハンドオフの扱い・対応する原則）を残し、L85〜L97・L111〜L126・L131〜L256 を削除する。削除した「## 操作」（L168〜L170）の位置（「本サイクル」の定義の直後・完了済みハンドオフの扱いの直前）へ次を置く:

```markdown
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
```

構築コマンドの例（Write ツールで組み立ててもよい。ディスパッチ節は `dispatch.md` として一時ファイルに書く）:

```bash
S=skills/session-handoff/SKILL.md
{ git show HEAD:$S | sed -n '1,84p;98,110p;127,130p'; cat "$CLAUDE_SCRATCHPAD/dispatch.md"; echo; git show HEAD:$S | sed -n '257,264p'; } > $S
```

（`$CLAUDE_SCRATCHPAD` はスクラッチパッドの絶対パスに読み替える。一時ファイルは `skills/` 配下に置かない）

- [ ] **Step 2-6: 本文（フェンス内の地の文を含む）から移設先への参照 2 箇所を張り替える**

ADR-0122 決定 6 (a) が名指しする**コードフェンス内の相対参照**:

1. （現行 L63・フェンス内）`` `review=` の値の定義は本ファイルの「`review=` の値定義」節を参照。`` → `` `review=` の値の定義は `references/review-field-values.md` を参照。``
2. （現行 L66・フェンス内）`` （値の定義と手順は `decision-log` スキルの「サイクル全体整合検査」を参照） `` → `` （値の定義と手順は `decision-log` の `references/cycle-consistency-check.md` を参照） ``

**据え置き**: L129「本サイクル」の定義の `` `decision-log`（サイクル全体整合検査） `` — 参照元の列挙であり所在ポインタではない。

- [ ] **Step 2-7: decision-log 側の相互参照 1 箇所を張り替える**

`skills/decision-log/references/status-updates.md`「ステータス変更」の改訂記録規定の段落（Task 1 で据え置いた現行 L186 相当）:

`反復・巡・終了時の定義は pre-finalization-review の \`references/iteration-norms.md\`「指摘反映後の反復」と session-handoff「\`review=\` の値定義」節を参照` → `反復・巡・終了時の定義は pre-finalization-review の \`references/iteration-norms.md\`「指摘反映後の反復」と session-handoff の \`references/review-field-values.md\` を参照`

- [ ] **Step 2-8: サイズ・構成・宙に浮いた参照の不在を検証する**

```bash
wc -c skills/session-handoff/SKILL.md skills/session-handoff/references/*.md
```

Expected: `SKILL.md` は **8,100〜8,400B**（20,000 未満。内訳の実測: 残す範囲 6,122B＋Step 2-5 のディスパッチ節 2,141B＋区切りの空行 1B−Step 2-6 の差引 16B ＝ **8,248B**。ADR-0122 の概算 7.0KB はディスパッチ節を約 1.5KB と見積もったための過少値で、**設計ではなく見積りのずれ**）。**完了条件 (b)**: `SKILL.md`＋`op-update.md` の合計が **15,600B 以下**（現行 31,169B の半減。実測見込み **12,684B**）。references 9 ファイルの見込みは `op-create` 723 / `op-cycle-reset` 1,879 / `op-finalize` 3,838 / `op-read` 2,356 / `op-update` 4,436 / `relocation-map` 3,698 / `relocation-procedure` 2,812 / `review-field-values` 4,611 / `section-volume-norms` 2,603 ＝ **合計 26,956B（約 27.0KB）**

```bash
grep -n "^## \|^### " skills/session-handoff/SKILL.md
```

Expected: `## ファイル配置` / `## ハンドオフファイルのフォーマット` / `### Status の意味（ADR-0076）` / `### 外部参照の書き方（ADR-0077）` / `## 「本サイクル」の定義` / `## 操作` / `### 横断規範の参照ファイル` / `## 完了済みハンドオフの扱い` / `## 対応する原則` の **9 行**（フェンス内の `## 作業の目的・背景` 等は grep にヒットするが雛形であり数えない。`### \`review=\` の値定義` / `### 節別の記載規範` / `## 独立手順「移設」` / `### 1. read` 〜 `### 5. cycle-reset` が消えていること）

```bash
LANG=C.UTF-8 grep -rnF -e '本ファイルの「' -e '上記フォーマット' -e 'read の手順 4 と同じ' -e '（定義は「「本サイクル」の定義」節）' -e '受け皿は git 履歴のみ' skills/session-handoff/
```

Expected: **1 件のみ**（分割前の状態では L63・L123・L195・L219・L224・L226・L247・L259 の 8 件にヒットすることを実測済み。パターン `（定義は「「本サイクル」の定義」節）` は張り替え後の `（定義は SKILL.md「「本サイクル」の定義」節）` にはヒットしない）（`SKILL.md` の「完了済みハンドオフの扱い」の `受け皿は git 履歴のみとする` ＝ (g) の正本）。それ以外が出たら (g) の一本化または (b) の張り替えが漏れている

```bash
LANG=C.UTF-8 grep -rlF '200 字' skills/session-handoff/
```

Expected: **`references/section-volume-norms.md`（正本）・`op-update.md`・`review-field-values.md`・`relocation-map.md` の 4 ファイル**。(g) で 200 字クラスタを**非該当と裁定した**ため一本化せず、4 箇所は跨り残存の同期対象（item 5）として残す。**`SKILL.md` にヒットしないこと**（本文残留部は 200 字の値を持たない）

```bash
LANG=C.UTF-8 grep -rnF -e 'session-handoff「`review=` の値定義」' -e '`session-handoff`「`review=` の値定義」' skills/
```

Expected: `skills/pre-finalization-review/references/iteration-norms.md` の **1 件のみ**（Task 3 Step 3-2 で張り替える。decision-log 側は Step 2-7 で解消済み）。

**パターンを 2 本立てにする理由**: `iteration-norms.md` L7 の実体は `` 記録は `session-handoff`「`review=` の値定義」節が正本である。`` で、**`session-handoff` がバッククォートで囲まれている**。1 本目のパターンだけでは同ファイルに構造的に一致せず、Step 2-7 の完了後は 0 件が返る（張り替え漏れがあっても緑になる空振り検証だった。分割前の実測: 1 本目は `decision-log/SKILL.md:186` の 1 件のみを返す）

```bash
LANG=C.UTF-8 grep -rlF '40KB' skills/session-handoff/
```

Expected: **`references/op-read.md`（正本）・`op-finalize.md` の 2 ファイル**。(g) で 40KB クラスタを**非該当と裁定した**ため一本化せず、`op-finalize.md` 手順 1 の「参照＋再掲」の形をそのまま移す（ADR-0105 L48 (d) が当該形を一本化として認定済み）。跨り残存の同期対象（item 6）

- [ ] **Step 2-9: 生成器で記法規約とサイズ警告を検査する**

```bash
pwsh scripts/build-dist.ps1 2>&1 | grep -E "Convention violations|Aborted|Done\.|WARNING|警告"
```

Expected: `[build-dist] Convention violations: 0` と `[build-dist] Done. 38 files written to dist/, 1 to repository root.`（skills 23＋13＝36、plugin.json 2）。session-handoff / decision-log の警告行が出ないこと

- [ ] **Step 2-10: 配布物の目視（執行点 手順 4）**

`dist/skills/session-handoff/SKILL.md` と `dist/skills/session-handoff/references/` 9 ファイルを読み、除去残骸・半角括弧・実在の固有名・自己参照が無いことを確認する。

```bash
LANG=C.UTF-8 grep -nE "（[^）]*（|）に従い|\(\)|本リポジトリ|本 repo" dist/skills/session-handoff/SKILL.md dist/skills/session-handoff/references/*.md
```

Expected: **ヒット 10 件で、いずれも除去残骸ではないこと**（内訳の実測: `op-cycle-reset` 1・`op-finalize` 1・`op-read` 1・`op-update` 1・`relocation-procedure` 2・`review-field-values` 3・`section-volume-norms` 1、`SKILL.md` と `op-create`・`relocation-map` は 0）。

**合格条件は件数ではなくヒット行の性質である**——ヒット行を 1 件ずつ「除去後に文法が破綻した残骸か」で判定し、残骸が 0 であることを見る。件数は改訂で動くため参考値として扱う（第 3 巡までは 9 件だった——当時は Step 2-3 が `op-finalize.md` の 40KB の再掲を落とす設計で、その括弧が 1 件消えていた。設計縮小で再掲を残したため 10 件へ戻っている）。ヒット総数 0 を Expected にしない〈実運用で必ず外れ検査が形骸化する〉。**この grep は補助であり、目視での通読を省略しない**

- [ ] **Step 2-11: コミット**

```bash
git add skills/session-handoff skills/decision-log/references/status-updates.md dist .agents/plugins/marketplace.json docs/working/plans/2026-09-03-adr-0122-skill-split-implementation.md && git commit -m "refactor: session-handoff を発火単位で references 9 ファイルへ分割（ADR-0122 決定 4。本文は共通部と操作ディスパッチ表・update 素経路は半減）"
```

---

### Task 3: 外部参照の張り替え（skills 3 件・CONTRIBUTING・docs/reference・現用 spec 6 件）

**Files:**
- Modify: `skills/start-work/SKILL.md`（3 箇所）
- Modify: `skills/pre-finalization-review/references/iteration-norms.md`（1 箇所）
- Modify: `skills/pre-finalization-review/references/review-procedure.md`（1 箇所）
- Modify: `CONTRIBUTING.md`（6 行）
- Modify: `docs/reference/README.md`（1 箇所）
- Modify: `docs/current/specs/2026-08-06-handoff-pruning-and-status-design.md`（2 箇所）
- Modify: `docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md`（1 箇所）
- Modify: `docs/current/specs/2026-08-25-codex-support-design.md`（1 箇所）
- Modify: `docs/current/specs/2026-08-13-handoff-bloat-control/00-overview.md`（注記 1 行）
- Modify: `docs/current/specs/2026-08-28-start-work-responsibility-split-design.md`（部分修正注記 1 行）
- Modify: `docs/current/specs/2026-04-25-record-strengthening-design.md`（張り替え 2 箇所＋注記 2 行）
- Modify: `docs/working/issues/flow/0085-digest-field-extension-lacks-checklist.md`（注記 1 行。open 課題の「出所の名指し」で唯一の追従対象）

ADR-0122 決定 6 (d)。「張り替え判定規則」R2・R3・R6 に該当する箇所のみ。据え置き（R1・R4）と壊れ許容（R5）は「ファイル構成」末尾の「変更しないもの」に列挙済み。

- [ ] **Step 3-1: start-work の 3 箇所（現行 L99・L101・L118）**

1. L99: `手順は \`decision-log\` の「承認の昇格」（サイクル全体整合検査・粒度の点検を含む）「ステータス変更」「コミットのタイミング」が正であり、ここには重複して書かない` → `手順は \`decision-log\` の \`references/status-updates.md\`「承認の昇格」（サイクル全体整合検査・粒度の点検を含む）「ステータス変更」と \`references/adr-authoring.md\`「コミットのタイミング」が正であり、ここには重複して書かない`
2. L101: `意思決定の有無を問わず decision-log「ステータス変更」の改訂記録規定を適用する（ADR-0108）` → `意思決定の有無を問わず decision-log の \`references/status-updates.md\`「ステータス変更」の改訂記録規定を適用する（ADR-0108）`
3. L118: `昇格する場合は \`decision-log\` の「承認の昇格」の手順（サイクル全体整合検査を含む）に従う` → `昇格する場合は \`decision-log\` の \`references/status-updates.md\`「承認の昇格」の手順（サイクル全体整合検査を含む）に従う`

据え置き: L20（コミットのタイミングは `decision-log` スキルが正＝スキル名）・L95（検出トリガー一覧＝本文残留）・L36 / L52 / L91 / L103 / L120（操作名）。

- [ ] **Step 3-2: pre-finalization-review の references 2 箇所**

`references/iteration-norms.md` L7: `記録は \`session-handoff\`「\`review=\` の値定義」節が正本である。` → `記録は \`session-handoff\` の \`references/review-field-values.md\` が正本である。`

`references/review-procedure.md` L17: `改訂対象が Accepted 済み ADR 本文である場合は decision-log「ステータス変更」の改訂記録規定を適用する（ADR-0108）。` → `改訂対象が Accepted 済み ADR 本文である場合は decision-log の \`references/status-updates.md\`「ステータス変更」の改訂記録規定を適用する（ADR-0108）。`

据え置き: `SKILL.md` L56・L66（update＝操作名）・L72（「本サイクル」の定義＝本文残留）。

- [ ] **Step 3-3: CONTRIBUTING.md の 6 行（L28・L88・L386・L392・L397・L559）**

1. L28: `および \`decision-log\`（サイクル全体整合検査の再点検規定）から参照される。` → `および \`decision-log\`（\`references/cycle-consistency-check.md\` の再点検規定）から参照される。`
2. L88: `本節は \`decision-log\`（ADR 作成手順の注記）と` → `本節は \`decision-log\`（\`references/adr-authoring.md\` の注記）と`
3. L386: `は \`decision-log\` スキルの各注記（ADR-0019 / ADR-0032）および「承認の昇格」節が正である。` → `は \`decision-log\` スキルの \`references/adr-authoring.md\` の各注記（ADR-0019 / ADR-0032）および \`references/status-updates.md\`「承認の昇格」節が正である。`
4. L392: `新規 ADR 起票時の置換対象特定（\`decision-log\` の採番ステップ）` → `新規 ADR 起票時の置換対象特定（\`decision-log\` の \`references/adr-authoring.md\` の採番ステップ）`
5. L397: `状態変更は \`decision-log\` の「ステータス変更」手順で記録する。` → `状態変更は \`decision-log\` の \`references/status-updates.md\`「ステータス変更」手順で記録する。`
6. L559: `昇格は \`decision-log\` の「承認の昇格」の手順（サイクル全体整合検査を含む）に従う（ADR-0092）` → `昇格は \`decision-log\` の \`references/status-updates.md\`「承認の昇格」の手順（サイクル全体整合検査を含む）に従う（ADR-0092）`

据え置き: L378（検出トリガー一覧＝本文残留）・L63 / L257 / L382 / L415 / L443（スキル名のみ）。ADR-0122 の「節名を指す 7 行」は L28・L88・L378・L386・L392・L397・L559 で、うち張り替え 6・据え置き 1（Task 6 で ADR-0122 へ実測を書く）。

- [ ] **Step 3-4: docs/reference/README.md L3**

`独立手順「移設」（\`skills/session-handoff/SKILL.md\`）でここへ正本を移す。` → `独立手順「移設」（\`skills/session-handoff/references/relocation-procedure.md\`）でここへ正本を移す。`

- [ ] **Step 3-5: 現用 spec の正本ポインタ 6 箇所（R2・R3）**

1. `2026-08-06-handoff-pruning-and-status-design.md` L40: `現状の正は \`skills/session-handoff/SKILL.md\` を参照。` → `現状の正は \`skills/session-handoff/references/op-finalize.md\` 手順 4 を参照。`
2. `2026-08-06-handoff-pruning-and-status-design.md` L44: `現状の正は \`docs/current/specs/2026-08-13-handoff-bloat-control/01-relocation-standard.md\` §3 と \`skills/session-handoff/SKILL.md\` を参照。` → `…§3 と \`skills/session-handoff/references/op-finalize.md\` を参照。`（同ファイル内に同一文型の生きたポインタが 2 つある。L44 が指す「finalize の現行の手順構成」は全量が `op-finalize.md` へ出る）
3. `2026-04-25-record-strengthening-design.md` L144: `\`decision-log\` の「承認の昇格」手順に含まれる粒度点検が先に走る` → `\`decision-log\` の \`references/status-updates.md\`「承認の昇格」手順に含まれる粒度点検が先に走る`
4. `2026-04-25-record-strengthening-design.md` L225: `記録対象・形式・値の定義は \`session-handoff\` スキルのフォーマット節が正` → `記録対象・形式は \`session-handoff\` スキルのフォーマット節が、\`review=\` / \`cyclecheck=\` の値の定義はそれぞれ \`references/review-field-values.md\` と \`decision-log\` の \`references/cycle-consistency-check.md\` が正`（分割後は「値の定義もフォーマット節が正」が部分的に偽になる）
5. `2026-08-07-overfitting-check-for-extensions-design.md` L27（CONTRIBUTING L28 のスナップショット。同期して張り替える）: `および \`decision-log\`（サイクル全体整合検査の再点検規定）から参照される。` → `および \`decision-log\`（\`references/cycle-consistency-check.md\` の再点検規定）から参照される。`
6. `2026-08-25-codex-support-design.md` L46: `書式は decision-log「ステータス変更」の部分修正の型` → `書式は decision-log の \`references/status-updates.md\`「ステータス変更」の部分修正の型`

（3・5・6 は Step 3-7 の検証 grep を分割前の実体で試走したときに、2・4 は確定前レビューで検出された。計画作成時の初期走査では 2026-04-25 は注記のみの対象と見ていたが、L144・L225 は現在の正本を指す生きたポインタなので R2 を適用する）

- [ ] **Step 3-6: 現用 spec 3 件と open 課題 1 件へ所在の注記を置く（R6・決定 6 末尾）**

`docs/current/specs/2026-08-13-handoff-bloat-control/00-overview.md`「## 3. 変更対象一覧」の表の直後（最終行 `| ADR-0086/0087/0088/0089 | …` の次の空行の後、「スコープ外:」の段落の前）へ:

```markdown
> **注記（ADR-0122）**: 上表が `skills/session-handoff/SKILL.md` へ置くとした内容のうち、節別の記載規範は `references/section-volume-norms.md`、独立手順「移設」は `references/relocation-map.md`（導入と種類別対応表）と `references/relocation-procedure.md`（手順 1〜6）、read / update / finalize / cycle-reset の各操作は `references/op-<操作名>.md` へ、ADR-0122 の references 型分割により移った。規定内容は不変。「本サイクル」の定義とフォーマット節は SKILL.md 本文に残る。
```

`docs/current/specs/2026-08-28-start-work-responsibility-split-design.md`「### 「確定前レビューの提示規則」→ pre-finalization-review 提示操作へ」の表の直後（`0107-…` 行の次の空行の後、次の `###` の前）へ:

```markdown
- **部分修正（ADR-0122）**: 上表の `skills/decision-log/SKILL.md` 3 箇所は、それぞれ `references/adr-authoring.md`（コミットのタイミング）・`references/status-updates.md`（改訂記録規定）・`references/cycle-consistency-check.md`（規範・手順文書の型の参照）へ、`skills/session-handoff/SKILL.md` 3 箇所のうち `review=` 値定義は `references/review-field-values.md`、update 手順 3 は `references/op-update.md` へ、ADR-0122 の references 型分割により移った（「本サイクル」定義は SKILL.md 本文に残る）。張り替え済みの参照内容は不変。
```

`docs/current/specs/2026-04-25-record-strengthening-design.md`:

- 「### 6.4 操作」見出し行の直後の空行の次へ:

```markdown
> **注記（ADR-0122）**: 本節の 5 操作の手順は、ADR-0122 の references 型分割により `skills/session-handoff/references/op-<操作名>.md` へ移った。SKILL.md 本文には操作ディスパッチ表が残る。
```

- 「## 7. 既存スキル拡張: `decision-log`」見出し行の直後の空行の次へ:

```markdown
> **注記（ADR-0122）**: 本節が `skills/decision-log/SKILL.md` へ置くとした内容のうち、検出トリガー一覧（7.1・7.3）は SKILL.md 本文に残り、ADR 作成手順・ユーザーへの確認（7.2）と粒度の注記（7.4）は `references/adr-authoring.md`、承認の昇格（7.4）は `references/status-updates.md` へ、ADR-0122 の references 型分割により移った。規定内容は不変。
```

`docs/working/issues/flow/0085-digest-field-extension-lacks-checklist.md` の「課題内容」節の当該段落（L10。「session-handoff の様式 8 箇所」を列挙する段落）の直後へ 1 行追加する。**open 課題のうち唯一の追従対象**（同 L16 がこの 8 箇所を対策の初期値として使うため、経緯記述ではなく生きた運用データ。ADR-0122 決定 6 末尾「open 課題は出所の名指しに限り必要に応じて現状へ合わせる」の適用）:

```markdown
> **注記（ADR-0122・2026-09-03）**: 上記 8 箇所のうち 5 箇所は references 型分割で所在が変わった——節別記載規範 → `skills/session-handoff/references/section-volume-norms.md`、update → `references/op-update.md`、read → `references/op-read.md`、finalize 削除例外と「圧縮しないもの」保護リスト → `references/op-finalize.md` 手順 4。形式行・書式例・記載条件/命名規約の 3 箇所は SKILL.md 本文に残る。連動改定チェックリストの初期値として使う際はこの所在で読むこと。
```

- [ ] **Step 3-7: 検証**

```bash
LANG=C.UTF-8 grep -rnF -e 'decision-log「ステータス変更」' -e 'decision-log` の「承認の昇格」' -e 'decision-log` の「ステータス変更」' -e 'session-handoff「`review=` の値定義」' -e '`session-handoff`「`review=` の値定義」' -e 'および「承認の昇格」節が正' -e 'decision-log` の採番ステップ' -e '（サイクル全体整合検査の再点検規定）' -e '（ADR 作成手順の注記）' -e '独立手順「移設」（`skills/session-handoff/SKILL.md`）' -e '現状の正は `skills/session-handoff/SKILL.md` を参照' -e '§3 と `skills/session-handoff/SKILL.md` を参照' -e '値の定義は `session-handoff` スキルのフォーマット節が正' skills/ CONTRIBUTING.md README.md docs/reference/ docs/current/specs/
```

Expected: 0 件（references を経由しない旧形式の外部参照が現用文書に残っていないこと）。

**検出力の確認済み事項**: 本 Step の対象は **Step 3-1〜3-5 の 18 箇所**（3-1: 3／3-2: 2／3-3: 6／3-4: 1／3-5: 6）。**張り替え前の状態で本コマンドを試走し、対象が全数検出されることを確認してから張り替えること**——空振り検証の防止。計画作成時に初版の 9 パターンで試走したところ 15 件を検出したが、その集合は Task 3 の対象と一致していなかった（Task 3 の対象でない `decision-log/SKILL.md:186`〈Task 2 で解消〉を含み、Task 3 の対象である `iteration-norms.md:7`・`2026-08-06:40`・`2026-08-06:44`・`2026-04-25:225` を欠いていた）。上の 13 パターンは 4 件の取りこぼしを塞いだもので、分割前の試走では **19 件**（Task 3 の 18 ＋ Task 2 で解消される decision-log L186）を返す。実装時（Task 2 完了後）に Task 3 着手前で試走すると 18 件になる

```bash
grep -c "注記（ADR-0122）\|部分修正（ADR-0122）" docs/current/specs/2026-08-13-handoff-bloat-control/00-overview.md docs/current/specs/2026-08-28-start-work-responsibility-split-design.md docs/current/specs/2026-04-25-record-strengthening-design.md
```

Expected: `1` / `1` / `2`

```bash
grep -c "注記（ADR-0122・" docs/working/issues/flow/0085-digest-field-extension-lacks-checklist.md
```

Expected: `1`

```bash
pwsh scripts/build-dist.ps1 2>&1 | grep -E "Convention violations|Aborted|Done\."
```

Expected: `Convention violations: 0` と `Done. 38 files written to dist/, 1 to repository root.`

- [ ] **Step 3-8: コミット**

```bash
git add skills/start-work/SKILL.md skills/pre-finalization-review/references CONTRIBUTING.md docs/reference/README.md docs/current/specs/2026-08-06-handoff-pruning-and-status-design.md docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md docs/current/specs/2026-08-25-codex-support-design.md docs/current/specs/2026-08-13-handoff-bloat-control/00-overview.md docs/current/specs/2026-08-28-start-work-responsibility-split-design.md docs/current/specs/2026-04-25-record-strengthening-design.md docs/working/issues/flow/0085-digest-field-extension-lacks-checklist.md dist .agents/plugins/marketplace.json docs/working/plans/2026-09-03-adr-0122-skill-split-implementation.md && git commit -m "refactor: 分割に伴う外部参照の張り替え（skills 3 件・CONTRIBUTING 6 行・docs/reference・現用 spec 6 件・Issue-0085 の所在注記。ADR-0122 決定 6 (d)）"
```

逸脱記録: 事実誤り・期待値の陳腐化の訂正 / 採用 / Step 0-4 の括弧書き「Task 3 完了後の実測は 34」（増える向きの予測）が実体と食い違う。実測は分割前 a6991f9 で 32（Expected と一致）、Task 2 完了時 31、Task 3 完了時 30 で減少した。減少分は Step 3-2 の置換が節名表記ごと `references/review-field-values.md` へ置き換えたためで、他の置換は節名を残すため増減しない。当該値は計画自身が非ゲートの対照値と明記しており、網羅の実ゲートである Step 3-7 は 0 件で合格。是正は「34 は 30 と読み替える」の読み替えに留め、計画本文の Expected は書き換えない（Task 1 の 6,856B と同じ扱い）

---

### Task 4: ADR の部分修正注記 22 件

**Files:**
- Modify: `docs/records/decisions/0028,0030,0032,0041,0042,0060,0075,0080,0086,0087,0088,0091,0092,0096,0099,0102,0105,0107,0108,0114,0120,0121-*.md`

ADR-0122 決定 6 (e)。注記は各 ADR の `## Consequences` 節の**最後の非空行の直後**（次の `## ` 見出しの直前。Consequences が最終節なら末尾）へ、トップレベル箇条として追加する。別途の改訂記録行は書かない（ADR-0121 サイクルの Task 7 と同じ扱い）。各行の書式は `- **部分修正（ADR-0122）**: <移設内容>。規定内容は不変のため、Status は Accepted のまま維持` に揃える。

- [ ] **Step 4-0: 候補母数を 2 系統で全数走査する**

ADR-0122 決定 6 (e) が示す候補 26 件は**節名の文字列一致**で作られた判明分であり、決定が課すのは「移設対象を記載箇所として名指しする ADR」の全数である。**節名一致だけを母数にすると、ファイルパスで実装対象・反映先を名指しする型を取りこぼす**（確定前レビューの実測: 4 件）。2 系統で走査する。

```bash
cd docs/records/decisions
LANG=C.UTF-8 grep -lE '独立手順「移設」|節別の記載規範|review=. の値定義|種類別対応表|サイクル全体整合検査|承認の昇格|ステータス変更|未決事項（open questions）の扱い|ADR ?作成手順|Proposed の ADR へ決定を追記|終端ステータスの意味境界|ユーザーへの確認|コミットのタイミング|ライフサイクル|検出を報告|インデックスを更新' *.md | sort > /tmp/by-section.txt
LANG=C.UTF-8 grep -lF -e 'skills/session-handoff' -e 'skills/decision-log' *.md | sort > /tmp/by-path.txt
comm -13 /tmp/by-section.txt /tmp/by-path.txt
cd ../../..
```

**節名パターンの設計根拠と限界**: ADR-0122 決定 6 (e) が挙げる候補 26 件は同 ADR が使った節名一致の結果だが、そのパターンは移設 13 ファイルの節名を覆っていない。上の式は `コミットのタイミング` / `ライフサイクル` / `検出を報告` / `インデックスを更新` を補ったが、**なお全数ではない**——`起票` / `注意`（`open-questions.md` の 2 節）と、**session-handoff の操作 5 節（`### 1. read` 〜 `### 5. cycle-reset`）・`### 手順`（移設手順）** は語として広すぎるため入れていない。したがって 2 系統の和集合からも漏れる ADR がある（実測 18 件）。

- [ ] **Step 4-0b: 和集合から漏れる ADR を第 3 系統で拾う**

節名・パスのいずれでも返らない ADR を洗い出し、R7 で判定する。

```bash
cd docs/records/decisions
LANG=C.UTF-8 grep -lE 'session-handoff|decision-log' *.md | sort > /tmp/by-name.txt
sort -u /tmp/by-section.txt /tmp/by-path.txt > /tmp/known.txt
comm -13 /tmp/known.txt /tmp/by-name.txt
cd ../../..
```

Expected（実測）: **18 件**（0004 / 0005 / 0006 / 0010 / 0015 / 0024 / 0047 / 0058 / 0076 / 0077 / 0079 / 0087 / 0089 / 0090 / 0097 / 0115 / 0116 / 0119）。**このうち該当は ADR-0087 の 1 件**（決定 1 が「`session-handoff` の **read**（対象ファイルの存在確認の直後）と **finalize**（手順冒頭）で…サイズを実測する」、決定 4・5 が read / finalize 超過時の移設手順の実施を定める＝**手順の位置を実装対象として名指し**しており、R1 の「操作名のみ」ではない。形は該当と判定した ADR-0120 L47 と同型）。残る 17 件は非該当——0076 / 0077（フォーマット節・Status＝本文残留 R4）・0006 / 0010 / 0119（検出トリガー一覧 R4）・0004 / 0015 / 0024 / 0079 / 0089 / 0090（スキル名のみ R1）・0047 / 0058（呼び出し契機 R1）・0005 / 0097（責務・規範名のみ R1）・0115 / 0116（本サイクルで close する当事者）。

Expected（2026-09-03 実測。補強後のパターン）: **`by-section.txt` 30 行**（`0122` 自身と `README.md` を含むので候補 ADR は 28 件）、**`by-path.txt` 19 件**、**`comm -13` は 9 件**（0016 / 0021 / 0030 / 0032 / 0057 / 0082 / 0098 / 0114 / 0120）。`comm` の出力を 1 件ずつ開き、その名指しが**移設対象節を記載箇所として指しているか**（R7）を判定する。判定済みの結果は下記に反映済みで、本 Step は再現の確認と取りこぼしの検出にあたる。

**判定結果（全数走査）**: 該当 **22 件**。由来の内訳は 節名一致 **17 件**（0028 / 0041 / 0042 / 0060 / 0075 / 0080 / 0086 / 0088 / 0091 / 0092 / 0096 / 0099 / 0102 / 0105 / 0107 / 0108 / 0121）＋ パス名指し **4 件**（**0030 / 0032 / 0114 / 0120**）＋ **第 3 系統（Step 4-0b）由来 1 件（0087）**。

**非該当の判定**:

- **ADR-0059 は非該当**（第 2 巡で訂正。当初は該当としていた）。実証: 同 ADR に `skills/decision-log` というパス表記は無く（Step 4-0 の `by-path.txt` にも現れない）、`decision-log` の言及は **Context L8 の 1 箇所のみ**で、内容は「`decision-log` の ADR 作成手順には…判定する観点が**ない**」＝規範の**不在の指摘**。Decision・Consequences のいずれにも反映先・実装対象・正本の所在の宣言が無い。R7 の但し書き「規範の適用先・例え・実測の言及のみは非該当」に該当する（実体側 `skills/decision-log/SKILL.md` の粒度注記に `（ADR-0059）` タグが付いているのは事実だが、それは ADR 本文の主張ではなく実装からの逆算であり、R7 の判定材料にしない）
- **ADR-0028 は該当**（第 2 巡で追加）。実証: 同 ADR L36（Consequences）が `` 波及更新: …`skills/decision-log/SKILL.md`（未決事項の起票手順のパス） `` と、パス＋節内手順名で記載箇所を名指しする。形は該当と判定した ADR-0030 L30 と同型
- そのほかの非該当: 節名一致側の 0019 / 0025 / 0031 / 0045 / 0056 / 0095 / 0100 / 0103 / 0109 / 0111（規範の適用・例え・実測の言及のみ。0031・0045 は worklog のライフサイクル文脈での語の一致）と、`comm` 出力のうち 0016 / 0021 / 0057（スキル名・ディレクトリ名のみ）・**0082**（`skills/session-handoff/SKILL.md` の「ハンドオフ書式テンプレート内にある 2 箇所」＝本文残留のフォーマット節を指すため R4 据え置き）・**0098**（`skills/decision-log/SKILL.md` 152 行目が…複写していた構造**だった**＝過去の欠陥の実測）

- [ ] **Step 4-1: 22 件へ注記を追加**

| ADR | 注記本文（`- **部分修正（ADR-0122）**: ` に続ける） |
|---|---|
| 0028 | 決定の波及更新先とした `skills/decision-log/SKILL.md` の未決事項の起票手順は、ADR-0122 の references 型分割により `skills/decision-log/references/open-questions.md` へ移った。手順の内容は不変のため、Status は Accepted のまま維持 |
| 0030 | 決定 4 が反映先とした `skills/decision-log/SKILL.md` の「手順のコミット規定と承認プロンプト前後の記述」は、ADR-0122 の references 型分割により `skills/decision-log/references/adr-authoring.md`（コミットのタイミング・ユーザーへの確認）へ移った。規定内容は不変のため、Status は Accepted のまま維持 |
| 0032 | 決定 2 が反映先とした `skills/decision-log/SKILL.md` の記述規律の 1 項（実行可能性チェックの注記）は、ADR-0122 の references 型分割により `skills/decision-log/references/adr-authoring.md` の ADR ファイル作成手順へ移った。規定内容は不変のため、Status は Accepted のまま維持 |
| 0041 | 決定 2 が記載箇所とした `skills/decision-log/SKILL.md`「ユーザーへの確認」は `skills/decision-log/references/adr-authoring.md` へ、終端ステータスの意味境界と Rejected 経路は `references/status-updates.md` へ、ADR-0122 の references 型分割により移った。規定内容は不変のため、Status は Accepted のまま維持 |
| 0042 | 決定が追加した ADR 作成手順の採番ステップ（置換対象の特定）は、ADR-0122 の references 型分割により `skills/decision-log/references/adr-authoring.md` へ移った。台帳監査の所在（`CONTRIBUTING.md`）は不変。規定内容は不変のため、Status は Accepted のまま維持 |
| 0060 | 決定 1 の「Proposed の ADR へ決定を追記するとき」は `skills/decision-log/references/adr-authoring.md` へ、決定 2 の「承認の昇格」手順は `references/status-updates.md` へ、ADR-0122 の references 型分割により移った。規定内容は不変のため、Status は Accepted のまま維持 |
| 0075 | 決定が定めた finalize の基準付き圧縮と「圧縮しないもの」の規定は `skills/session-handoff/references/op-finalize.md` へ、cycle-reset は `references/op-cycle-reset.md` へ、ADR-0122 の references 型分割により移った。落とした情報の受け皿の条文は SKILL.md「完了済みハンドオフの扱い」へ一本化し他は参照とした。規定内容は不変のため、Status は Accepted のまま維持 |
| 0080 | 決定 5 の `review=` 値の定義は `skills/session-handoff/references/review-field-values.md` へ、update の記載手順は `references/op-update.md` へ、read の欠落検査は `references/op-read.md` へ、ADR-0122 の references 型分割により移った。形式行と書式例は SKILL.md 本文に残る。規定内容は不変のため、Status は Accepted のまま維持 |
| 0086 | 決定 1 の種類別対応表と決定 2 の独立手順「移設」は、ADR-0122 の references 型分割により `skills/session-handoff/references/relocation-map.md`（導入と対応表）と `references/relocation-procedure.md`（手順 1〜6）へ分かれて移った（対応表を判定材料として読む経路と手順が走る経路が一致しないため）。3 起点の各操作は `references/op-<操作名>.md`。規定内容は不変のため、Status は Accepted のまま維持 |
| 0087 | 決定 1 が実装対象とした `session-handoff` の read（手順 4）・finalize（手順 1）のサイズ実測と、決定 4・5 の超過時の移設手順の実施は、ADR-0122 の references 型分割によりそれぞれ `skills/session-handoff/references/op-read.md`・`references/op-finalize.md`・`references/relocation-procedure.md` へ移った。トリガーの発火条件・目安値・手順の内容は不変のため、Status は Accepted のまま維持 |
| 0088 | 決定の節別の記載規範は、ADR-0122 の references 型分割により `skills/session-handoff/references/section-volume-norms.md` へ移った。あわせて 1 行 200 字の上限は同ファイルの表を正本 1 箇所とし、`review=` 値定義の縮退規定・update 手順 3・種類別対応表の 3 箇所は参照へ置換した。規定内容は不変のため、Status は Accepted のまま維持 |
| 0091 | 決定 1・2 が改めた独立手順「移設」の起点列挙と finalize 手順 3 は `skills/session-handoff/references/relocation-map.md` と `references/op-finalize.md` へ、決定 4 の対応表の標準パス併記は `references/relocation-map.md` へ、ADR-0122 の references 型分割により移った。規定内容は不変のため、Status は Accepted のまま維持 |
| 0092 | 決定が工程を追加した「承認の昇格」は `skills/decision-log/references/status-updates.md` へ、新設節「サイクル全体整合検査」は `references/cycle-consistency-check.md` へ、session-handoff 側の update / read / finalize の各改定は `skills/session-handoff/references/op-<操作名>.md` へ、ADR-0122 の references 型分割により移った。形式行・書式例・命名規約は session-handoff SKILL.md 本文に残る。規定内容は不変のため、Status は Accepted のまま維持 |
| 0096 | 改定対象が名指しする `skills/decision-log/SKILL.md` ライフサイクル節の close 手順は `skills/decision-log/references/open-questions.md` へ、`skills/session-handoff/SKILL.md` の既存課題追記行は `skills/session-handoff/references/relocation-procedure.md` 手順 3 へ、ADR-0122 の references 型分割により移った。規定内容は不変のため、Status は Accepted のまま維持 |
| 0099 | 決定 1 が書き換えたサイクル全体整合検査の観点 5 は、ADR-0122 の references 型分割により `skills/decision-log/references/cycle-consistency-check.md` へ移った。規定内容は不変のため、Status は Accepted のまま維持 |
| 0102 | 実装対象が名指しする `skills/decision-log/SKILL.md` の ADR 作成手順の注記部（評価可能性のゲート付きポインタ）は、ADR-0122 の references 型分割により `skills/decision-log/references/adr-authoring.md` へ移った。規定内容は不変のため、Status は Accepted のまま維持 |
| 0105 | C-11 の session-handoff update は `skills/session-handoff/references/op-update.md` へ、D-11 の decision-log 承認の昇格は `skills/decision-log/references/status-updates.md` へ、ADR-0122 の references 型分割により移った。「本サイクル」の定義は SKILL.md 本文の独立節として維持され、配置指定「独立手順「移設」節の直前」は当該節が references へ出たため位置関係としては解消（独立節である点は不変）。規定内容は不変のため、Status は Accepted のまま維持 |
| 0107 | 実装対象のうち session-handoff の「`review=` の値定義」小節は `skills/session-handoff/references/review-field-values.md` へ、update 手順 2・3 への追記は `references/op-update.md` へ、節別記載規範表への 1 句は `references/section-volume-norms.md` へ、ADR-0122 の references 型分割により移った。形式行の値スロット・書式例・記載条件文は SKILL.md 本文に残る。規定内容は不変のため、Status は Accepted のまま維持 |
| 0108 | 正本とした decision-log「ステータス変更」節は、ADR-0122 の references 型分割により `skills/decision-log/references/status-updates.md` へ移った。発火点の「意思決定を伴わない起動契機」1 行は SKILL.md 本文に残り、同行の節参照は references パスへ張り替えた。規定内容は不変のため、Status は Accepted のまま維持 |
| 0114 | 決定 4 が名指しする `skills/session-handoff/SKILL.md` の当該行（節別の記載規範の第 1 段落。現行 L113）は、ADR-0122 の references 型分割により `skills/session-handoff/references/section-volume-norms.md` へ移った。限定句を削った編集結果は不変のため、Status は Accepted のまま維持 |
| 0120 | 実装対象が名指しする `skills/session-handoff/SKILL.md` の update 手順（反復継続記載への独立項目「成果物の型」の追加）は、ADR-0122 の references 型分割により `skills/session-handoff/references/op-update.md` へ移った。`skills/pre-finalization-review/` 側の記載箇所は本 ADR の対象外。規定内容は不変のため、Status は Accepted のまま維持 |
| 0121 | 決定 5 が `scripts/build-dist.ps1` の例外テーブルへ暫定登録した 2 行（session-handoff 31169・decision-log 26837）は、ADR-0122 決定 7 により削除され、両スキルは通常の目安値判定へ戻った。決定の内容は不変のため、Status は Accepted のまま維持 |

挿入位置の目安（いずれも Consequences の最後の非空行の直後。実測値）: **Consequences が最終節**なのは 0030・0032・0060（各 `- **部分修正（ADR-0105）**:` の直後）/ 0075（`- **部分修正（ADR-0086）**:` の直後）/ 0086（`- 部分修正（ADR-0091・2026-08-14）:` の直後）/ 0088（`- **部分修正（ADR-0107）**:` の直後）/ 0114（「同種の見落とし…」の直後）の **7 件**。**`## Related` が続く**のは **0028 / 0041 / 0042** の 3 件（0028 の Consequences 最終非空行は `- **部分修正（ADR-0105）**:`）。**`## 過剰適合点検（ADR-0079）` が続く**のは 0080 / 0087 / 0091 / 0092 / 0096 / 0099 / 0102 / 0105 / 0107 / 0108 / 0120 / 0121 の **12 件**。いずれも手順文「Consequences 節の最後の非空行の直後」に従えば正しく入る（本目安は確認用）。**22 件すべてで Consequences 内にコードフェンスが無いことを実測済み**のため、Step 4-2 の awk が `^## ` の誤検出で早期に節を抜ける懸念はない。

- [ ] **Step 4-2: 検証**

```bash
grep -c "部分修正（ADR-0122）" docs/records/decisions/*.md | grep -v ":0"
```

Expected: 22 ファイルがそれぞれ `:1`（0028 / 0030 / 0032 / 0041 / 0042 / 0060 / 0075 / 0080 / 0086 / 0087 / 0088 / 0091 / 0092 / 0096 / 0099 / 0102 / 0105 / 0107 / 0108 / 0114 / 0120 / 0121）

```bash
for f in 0028 0030 0032 0041 0042 0060 0075 0080 0086 0087 0088 0091 0092 0096 0099 0102 0105 0107 0108 0114 0120 0121; do file=$(ls docs/records/decisions/${f}-*.md); awk -v F="$file" '/^## Consequences/{c=1;next} /^## /{c=0} c && /部分修正（ADR-0122）/{print F": in Consequences"}' "$file"; done | wc -l
```

Expected: `22`（全件が Consequences 節の内側にあること）

- [ ] **Step 4-3: コミット**

```bash
git add docs/records/decisions docs/working/plans/2026-09-03-adr-0122-skill-split-implementation.md && git commit -m "adr: 分割に伴う部分修正注記 22 件を追記（ADR-0122 決定 6 (e)）"
```

逸脱記録: 事実誤り・期待値の陳腐化の訂正 / 採用 / Step 4-1 末尾の「挿入位置の目安」（実測値と称する分類）が ADR-0087 を「`## 過剰適合点検（ADR-0079）` が続く 12 件」に入れているが、実体の 0087 は Context・Considered Alternatives・Decision・Consequences の 4 節のみで点検節を持たず Consequences が最終節。正しい内訳は 最終節 8 件、`## Related` 3 件、過剰適合点検 11 件。計画自身が「本目安は確認用」「手順文に従えば正しく入る」と明記しており挿入結果は不変で、Step 4-2 の 2 本の検証も 22 件で通過。是正は読み替えに留め計画本文は書き換えない（Task 1・3 と同じ扱い）

---

### Task 5: 例外テーブルの暫定行 2 件の削除と spec 02 の件数追従

**Files:**
- Modify: `scripts/build-dist.ps1`（L213〜L216 の例外テーブル）
- Modify: `docs/current/specs/2026-08-07-distributed-artifact-generation/02-distribution-generator.md`（L57・L59・L60・L63・L85・L87）

ADR-0122 決定 7 と Consequences（件数の陳腐化）。

- [ ] **Step 5-1: 例外テーブルの 2 行を削除**

`scripts/build-dist.ps1` L213〜L216:

旧:
```powershell
$skillSizeExceptions = @{
    'session-handoff' = 31169   # 分割待ちの暫定行。根拠と追跡は起票済みの課題（Issue-0115）
    'decision-log'    = 26837   # 分割待ちの暫定行。根拠と追跡は起票済みの課題（Issue-0116）
}
```

新:
```powershell
$skillSizeExceptions = @{
}
```

（L210〜L212 の説明コメントは残す。空のハッシュテーブルでも `ContainsKey` は動作する）

- [ ] **Step 5-2: spec 02 の数値 6 箇所を実測へ追従**

1. L57: `[build-dist] Scanning 23 source files...` → `[build-dist] Scanning 36 source files...`
2. L63: `[build-dist] Done. 25 files written to dist/, 1 to repository root.` → `[build-dist] Done. 38 files written to dist/, 1 to repository root.`
3. L85: `配布対象ソースは計 32 ファイルで` → `配布対象ソースは計 45 ファイルで`
4. L87: `` `skills/` 配下の全ファイル（23） `` → `` `skills/` 配下の全ファイル（36） ``
5. L59・L60（標準出力サンプルの `✓` 行）: `  ✓ skills/start-work/SKILL.md (28 identifiers removed)` → `  ✓ skills/start-work/SKILL.md (23 identifiers removed)` / `  ✓ skills/session-handoff/SKILL.md (34 identifiers removed)` → `  ✓ skills/session-handoff/SKILL.md (4 identifiers removed)`（**値は Step 5-3 の 2 本目の実行出力で確認してから書く**。`skills/` は Task 5 と Task 7 の間で変化しないので Task 7 を待つ必要はない。session-handoff 側は本サイクルの分割で 34 → 4 へ変わる。**start-work 側の 28 → 23 は本サイクルと無関係な既存の陳腐化**で、同じ行の是正としてついでに直す）

- [ ] **Step 5-3: 検証**

```bash
grep -c "Issue-0115\|Issue-0116\|session-handoff\|decision-log" scripts/build-dist.ps1
```

Expected: `0`

```bash
pwsh scripts/build-dist.ps1 2>&1 | grep -E "Scanning|Convention violations|Aborted|Done\.|WARNING|警告|✓ skills/(start-work|session-handoff)/SKILL"
```

Expected: `[build-dist] Scanning 36 source files...` / `Convention violations: 0` / `Done. 38 files written to dist/, 1 to repository root.`、および `✓` 行 2 本（`skills/start-work/SKILL.md (23 identifiers removed)` / `skills/session-handoff/SKILL.md (4 identifiers removed)`。**この 2 値を項目 5 へ書く**）。**警告行が 1 件も出ないこと**（例外テーブルを空にしても両スキルの本文が目安値 20000 を下回るため。`retrospective/SKILL.md` 19,042B も未超過）

```bash
grep -n "Scanning 36\|Done. 38\|計 45 ファイル\|（36）\|(23 identifiers removed)\|(4 identifiers removed)" docs/current/specs/2026-08-07-distributed-artifact-generation/02-distribution-generator.md | wc -l
```

Expected: `6`（件数 4 箇所＋`✓` 行 2 箇所）

- [ ] **Step 5-4: コミット**

```bash
git add scripts/build-dist.ps1 docs/current/specs/2026-08-07-distributed-artifact-generation/02-distribution-generator.md docs/working/plans/2026-09-03-adr-0122-skill-split-implementation.md && git commit -m "chore: 例外テーブルの暫定行 2 件を削除し spec 02 の件数を実測へ追従（ADR-0122 決定 7・Consequences）"
```

（`dist/` は本タスクで変化しない——スクリプト自身は配布対象外。`git status --short` で `dist/` に差分が無いことを確認してからコミットする）

---

### Task 6: ADR-0122 決定 6 の判明分を全数走査の実測へ更新

**Files:**
- Modify: `docs/records/decisions/0122-split-session-handoff-and-decision-log-by-firing-unit.md`（決定 6）

ADR-0122 は Proposed（コミット済み）であり本文の書き直しは自由（ADR-0030。改訂記録の義務なし＝decision-log「ステータス変更」対象外 (2)）。決定 6 が「判明分の各件数は実装計画の全数走査で実測へ更新する」と定めた更新を行う。

- [ ] **Step 6-1: 決定 6 の (d)〜(g) の判明分を実測へ書き換える**

決定 6 の当該記述は**独立した段落ではなく、L79（`6. **参照の張り替えは現役文書に限る**: …` の 1 行）の末尾に続く文**である（実測: L79 は 2,038 バイトの 1 行で、`判明分——(d)` はその 1,106 バイト目から始まる。後続の L83・L85 は 3 スペース字下げの継続段落）。したがって**L79 内の `判明分——(d):` から行末までの部分文字列を置換する**（行頭の字下げは付けない。字下げを付けると行中に空白が混入する）。置換後の本文:

```markdown
   実測（本サイクルの実装計画 `docs/working/plans/2026-09-03-adr-0122-skill-split-implementation.md` の全数走査。判定規則は同計画「張り替え判定規則」R1〜R7）——(d): **張り替え 18 箇所・所在注記 5 行**、ほかは据え置き（据え置きの内訳は同計画「変更しないもの（判定済み）」が正本で、ここには総数を書かない——参照の粒度がファイル単位と行単位で混在するため）。張り替え 18 箇所の内訳: `start-work` 3・`pre-finalization-review`（`references/iteration-norms.md`・`references/review-procedure.md`）各 1・`CONTRIBUTING.md` 6 行（節名を指す 7 行のうち 6 行。検出トリガー一覧を指す 1 行は本文残留のため据え置き）・`docs/reference/README.md` 1・現用 spec 6（`2026-08-06-handoff-pruning-and-status-design.md` 2・`2026-04-25-record-strengthening-design.md` 2・`2026-08-07-overfitting-check-for-extensions-design.md` 1・`2026-08-25-codex-support-design.md` 1）。**(c) の相互参照 3 箇所**（`session-handoff` ⇄ `decision-log`）は分割作業と同一タスクで処理するため (d) の計数に含めない。所在注記 5 行は `2026-08-13-handoff-bloat-control/00-overview.md` 1・`2026-08-28-start-work-responsibility-split-design.md` 1・`2026-04-25-record-strengthening-design.md` 2・open 課題 `flow/0085` 1（決定 6 末尾の「open 課題は出所の名指しに限り現状へ合わせる」の唯一の該当）。**候補の生成は節名の文字列一致だけでは足りず、ファイルパスで実装対象・反映先を名指しする型を 2 系統目として走査した**（前者のみでは 4 件を取りこぼす。(e) 参照）。(e): 部分修正注記 **22 件**（0028/0030/0032/0041/0042/0060/0075/0080/0086/0087/0088/0091/0092/0096/0099/0102/0105/0107/0108/0114/0120/0121）。由来は節名一致 17 件＋パス名指し 4 件（0030/0032/0114/0120）＋第 3 系統（両パターンの和集合外）1 件（0087）。**ADR-0059 は非該当**（Context が「ADR 作成手順には観点がない」と規範の不在を指摘するのみで、反映先・実装対象の宣言を持たない）。ほかの非該当は 0019/0025/0056/0095/0100/0103/0109/0111 と、パス名指しのみに現れる 0016/0021/0057/0082/0098。
```

- [ ] **Step 6-2: (f)・(g) の判明分へ実測を追記する**

(f) の段落末尾（`…現行の update 手順 4 は対応表への参照しか持たない。` の直後）へ:

```markdown
 実測: 13 ファイルの列挙は実装計画「(f) 分割後 13 ファイルの、単独では意味が確定しない語・手順・数値」（13 行・空の行なし。要素の判定は**新設 36 箇所・据え置き 19 箇所・明示参照あり 22 箇所**。数え方は表 13 行に現れる `（新設` / `（据え置き` / `（明示参照あり` の出現数とし、`（新設 2 箇所` は 2 と数える）。
```

(g) の段落末尾（`…別の規定である点を保つこと。` の直後）へ:

```markdown
 実測: クラスタは **5 件**を検出し、**一本化するのは git 履歴クラスタ 1 件のみ**（4 箇所。正本は本文残留「完了済みハンドオフの扱い」。正本が本文にあるため参照側に追加の読み込みが発生しない）。**残る 4 件は非該当と裁定した**。うち 2 件は本決定 (g) が判明分として挙げた 200 字上限クラスタと、本サイクルの走査で見つかったサイズ実測の目安値 40KB である。**判明分の一方を非該当へ振り替えたのは、本項 (g) の上位にあたる ADR-0121 決定 4 ②「発火時に毎回必要な内容の退避は認めない」に触れるため**——200 字上限は `op-update.md` 手順 3（消化記録行を書くたびに要る）に、40KB は `op-finalize.md` 手順 1（サイズ実測のたびに要る）にあり、参照化すると最頻経路と finalize が毎回別ファイルを読む。加えて 200 字の参照化は決定 1 が定める素経路の定義（「節別の記載規範の参照…を伴わないもの」）を実体から消し、完了条件 (b) の測定基盤を壊す。40KB については **ADR-0105 L48 (d) が「ファイル内の一本化（C-14 が read 手順 4 を参照する形）は現状で達成済み」と認定済み**であり、再掲の除去は同 ADR の判断を覆す。残る 2 件——移設で作成・更新した正本ファイルの add 規定（`relocation-procedure.md` 手順 6 が全起点を統べる正本として既に一本化済みで、他 2 箇所は規定内容が異なる操作手順）と課題ファイルの目安値 10KB（監査台帳 J-09。ADR-0105 が統合先案を覆し Issue-0099 が受容済みとして追跡中）——も同様に射程外とした。**非該当 4 件のうち数値定数の複写が残る 3 件（200 字・40KB・10KB）は実装計画の「跨り残存の同期対象」へ載せ、変更時の同期対象とする**。
```

- [ ] **Step 6-3: 検証**

```bash
grep -c "実測（本サイクルの実装計画\|実測: 13 ファイルの列挙\|実測: クラスタは" docs/records/decisions/0122-*.md
```

Expected: `3`（3 行に分かれて各 1 ヒット。**3 本目のパターンは (g) 追記の書き出し「実測: クラスタは 5 件を検出し…」に合わせてある**——`実測: 200 字上限クラスタ` では一致せず 2 が返る。**検証パターンに日付を入れない** — 「日付リテラルの一般規定」により Step 6-1 が書く日付は実装当日へ読み替わるため、日付を含むパターンは実装が翌日以降にずれた時点で空振りする）

```bash
grep -oE "張り替え [0-9]+ 箇所|所在注記 [0-9]+ 行|据え置き [0-9]+ 箇所|新設 [0-9]+ 箇所|明示参照あり [0-9]+ 箇所|注記 \*\*[0-9]+ 件\*\*" docs/records/decisions/0122-*.md
```

Expected（**literal で照合する**。「一致すること」とだけ書くと目標値が無く検証にならない）: **出力 9 行・7 種**——`張り替え 18 箇所`（2 回。Step 6-1 が総数と内訳見出しで各 1 回書く）／`所在注記 5 行`（2 回。同上）／`注記 **22 件**`／`新設 36 箇所`／`据え置き 19 箇所`／`明示参照あり 22 箇所`／**`新設 2 箇所`**（(f) 追記の計数根拠の説明文「`（新設 2 箇所` は 2 と数える」に由来。目標値ではないが同じパターンに一致する）。**書き込む前に本計画側を機械計数して突き合わせる**:

```bash
P=docs/working/plans/2026-09-03-adr-0122-skill-split-implementation.md
ST=$(grep -n '^| `decision-log/references/adr-authoring.md`' $P | cut -d: -f1)
EN=$(grep -n '^| `session-handoff/references/section-volume-norms.md`' $P | cut -d: -f1)
sed -n "${ST},${EN}p" $P > /tmp/ft.txt
echo "rows=$(wc -l < /tmp/ft.txt)"
for m in 新設 据え置き 明示参照あり; do printf "%s=%s\n" "$m" "$(grep -oF "（$m" /tmp/ft.txt | wc -l)"; done
grep -oF '（新設 2 箇所' /tmp/ft.txt
```

Expected: `rows=13` / `新設=35`（＋`（新設 2 箇所` 1 件で要素 36）/ `据え置き=19` / `明示参照あり=22`。**表の直前の凡例文を計数範囲に含めないこと**（含めると 3 値とも過大になる）

```bash
grep -c "判明分の各件数は実装計画の全数走査で実測へ更新する" docs/records/decisions/0122-*.md
```

Expected: `0`

- [ ] **Step 6-4: コミット**

```bash
git add docs/records/decisions/0122-split-session-handoff-and-decision-log-by-firing-unit.md docs/working/plans/2026-09-03-adr-0122-skill-split-implementation.md && git commit -m "adr: 0122 決定 6 の判明分を実装計画の全数走査の実測へ更新（Proposed 維持）"
```

---

### Task 7: version bump と執行点 4 手順

**Files:**
- Modify: `.claude-plugin/plugin.json`（`version`）
- Modify: `.claude-plugin/marketplace.json`（`plugins[].version`）
- 生成: `dist/**`、`.agents/plugins/marketplace.json`

配布対象ソース（`skills/`）を変更したため、CONTRIBUTING「全シナリオ共通: 配布対象ソースの記法規約」の執行点 4 手順と plugin version bump（ADR-0090）を行う。`scripts/sync-template.ps1` は書き込みモードでは実行しない（冒頭 Tech Stack の根拠。安全網は Step 7-3 の `-Check`）。

- [ ] **Step 7-1: version を 0.1.18 へ上げる**

`.claude-plugin/plugin.json`: `"version": "0.1.17"` → `"version": "0.1.18"`
`.claude-plugin/marketplace.json`: `"version": "0.1.17"` → `"version": "0.1.18"`

- [ ] **Step 7-2: 執行点 手順 1 — 生成器を実行**

```bash
pwsh scripts/build-dist.ps1 2>&1 | grep -E "Scanning|Convention violations|Aborted|Done\.|WARNING|警告|version"
```

Expected: `Scanning 36 source files` / `Convention violations: 0` / `Done. 38 files written to dist/, 1 to repository root.`。version 不一致の中断・警告行が無いこと

- [ ] **Step 7-3: 執行点 手順 2 — `-Check` で両生成器を回す**

```bash
pwsh scripts/build-dist.ps1 -Check; echo "build-dist exit=$?"
```

Expected: `[build-dist] Up to date.` と `build-dist exit=0`

```bash
pwsh scripts/sync-template.ps1 -Check; echo "sync-template exit=$?"
```

Expected: `sync-template exit=0`（落ちた場合は前提が崩れている——`skills/` は template 対象外なので原因は他にある）

- [ ] **Step 7-4: 執行点 手順 3 — 生成物を同じコミットに含める**（Step 7-6 の `git add` で行う）

- [ ] **Step 7-5: 執行点 手順 4 — 配布物を目視**

Task 1・2 で目視済みの 14 ファイルに加え、version の反映を確認する:

```bash
grep -h '"version"' dist/.claude-plugin/plugin.json dist/.codex-plugin/plugin.json .agents/plugins/marketplace.json
```

Expected: 3 行とも `0.1.18`（`.agents/plugins/marketplace.json` は version を持たない場合がある。持たなければ 2 行）

```bash
ls dist/skills/session-handoff/references dist/skills/decision-log/references | grep -c "\.md$"
```

Expected: `13`

- [ ] **Step 7-6: コミット**

```bash
git add .claude-plugin dist .agents/plugins/marketplace.json docs/working/plans/2026-09-03-adr-0122-skill-split-implementation.md && git commit -m "chore: plugin version 0.1.18（session-handoff / decision-log の references 型分割の配布反映。ADR-0122）"
```

---

### Task 8: 課題 close と ADR-0122 の Accepted 昇格

**Files:**
- Modify: `docs/working/issues/flow/0115-session-handoff-size-split-candidate.md`（close）
- Modify: `docs/working/issues/flow/0116-decision-log-size-split-candidate.md`（close）
- Modify: `docs/working/issues/README.md`（Status 2 件）
- Modify: `docs/records/decisions/0122-*.md`（Consequences の実読み込み量表を実測へ・Status）
- Modify: `docs/records/decisions/README.md`（Status）

昇格は `decision-log` の `references/status-updates.md`「承認の昇格」の手順（**分割後のファイルを読む**）に従い、サイクル全体整合検査（`references/cycle-consistency-check.md`）を含める。本タスクは分割後の decision-log を初めて実運用で通す機会でもあり、ディスパッチの追随失敗があれば課題起票する（ADR-0122 Consequences の受け皿）。

- [ ] **Step 8-0: 昇格ガードを先に評価する**

**Issue の close（Step 8-1〜8-3）より前に評価する。** ガードが成立したまま close だけが進むと「課題は closed・ADR は Proposed」という定義されていない中間状態になり、ADR-0122 決定 7（「Issue-0115 / Issue-0116 は本 ADR の Accepted 昇格時に close する」）とも食い違うため。

Task 1・2 の実測から次の 2 条件を判定する（各経路の合計は `SKILL.md` 本文＋当該経路が読む references）:

```bash
S=skills/session-handoff; D=skills/decision-log
b(){ wc -c < "$1"; }
echo "update 素経路   = $(( $(b $S/SKILL.md) + $(b $S/references/op-update.md) ))  （≤15600 なら (i) 非発火）"
echo "新規ドラフト作成 = $(( $(b $D/SKILL.md) + $(b $D/references/adr-authoring.md) ))  （≤13400 なら (i) 非発火）"
echo "update＋節別＋移設判定 = $(( $(b $S/SKILL.md) + $(b $S/references/op-update.md) + $(b $S/references/section-volume-norms.md) + $(b $S/references/relocation-map.md) ))  （>16800 なら (ii) 発火）"
echo "同＋移設実行           = $(( $(b $S/SKILL.md) + $(b $S/references/op-update.md) + $(b $S/references/section-volume-norms.md) + $(b $S/references/relocation-map.md) + $(b $S/references/relocation-procedure.md) ))  （>19300 なら (ii) 発火）"
```

Expected（実測見込み）: 12,684 / 12,823 / **18,985** / **21,797**。すなわち **(i) は非発火・(ii) は発火する**。

- **(i) 完了条件 (b) の最頻経路の半減が成立しない**（素経路 > 15,600B または新規ドラフト作成 > 13,400B）→ **昇格しない**。ADR-0122 決定 1 の完了条件そのものが未達なので、分割構成の見直しをユーザーへ提示する
- **(ii) 決定 1 が明示的に受容した 2 経路の実測が受容値（16.8KB・19.3KB）を上回る** → **その時点では昇格しない**。この 2 値はユーザーが受容したものであり、悪化した実測へ黙って差し替えない

**(ii) 発火時の分岐（既定経路）**: 上回った幅（見込み +2.2KB＝+7 ポイント／+2.5KB＝+8 ポイント）と原因（ディスパッチ表の実測が ADR の概算より大きい。設計ではなく見積りのずれで、完了条件 (b) は成立している）を添えてユーザーへ提示し、次を選んでもらう。

1. **受容値を実測へ更新して続行** → 決定 1 の 2 値を実測へ改め（Proposed のため改訂記録は不要）、Step 8-1 以降を通常どおり進める
2. **受容しない** → Task 8 を中断する。Task 1〜7 のコミットはそのまま残し、Issue-0115 / 0116 は **open のまま**（close は昇格と対で行う）、課題を起票して handoff へ申し送る。**中断時の完了後の次手**は下記「完了後の次手」を次のとおり読み替える: (a) `session-handoff` update のマイルストーン名に `Accepted 昇格` を含めず、`cyclecheck=` は `非該当（Task 8 中断により整合検査未実施）` と書く（Step 8-5 が走らないため） (b) **feature ブランチはマージせず保持する**（Proposed の ADR を実装済みでマージすると、次サイクルの起点が「決定は未確定・実装は済み」という読みにくい状態になる） (c) Issue-0115 / 0116 の「検討状況」へ「例外テーブルの暫定行は Task 5 で削除済みだが、課題内容の『分割候補のまま暫定登録されている』は実体と乖離している」旨を 1 行残す（Task 5 で削除済みのため課題文が実体と食い違うため）

**(i)(ii) いずれも非発火なら** Step 8-1 へ進む。

- [ ] **Step 8-1: Issue-0115 を close**

- `- **Status**: open` → `- **Status**: closed`
- `- **Opened**: 2026-09-01` の直後へ `- **Closed**: 2026-09-03`
- 「検討状況」末尾へ:

```markdown
- 2026-09-03: ADR-0122 で references 型分割を実装。本文 31,169B → 8,248B（操作 5 種と横断規範 4 種を `references/` 9 ファイルへ）。update 素経路の実読み込み量は 12,684B（現行比 41%）。例外テーブルの暫定行を削除
```

- 「結論」を `（open）` から `ADR-0122。` へ置換

- [ ] **Step 8-2: Issue-0116 を close**

- `- **Status**: open` → `- **Status**: closed`、`- **Closed**: 2026-09-03` を追加
- 「検討状況」末尾へ:

```markdown
- 2026-09-03: ADR-0122 で references 型分割を実装。本文 26,837B → 4,073B（ADR 作成手順・未決事項・ステータス更新・サイクル全体整合検査を `references/` 4 ファイルへ）。新規ドラフト作成経路の実読み込み量は 12,823B（現行比 48%）。例外テーブルの暫定行を削除
```

- 「結論」を `ADR-0122。` へ置換

（上記の数値は実測見込み。Task 1 Step 1-6・Task 2 Step 2-8・Step 8-0 で測った実値へ読み替えて書く）

- [ ] **Step 8-3: 課題インデックスの Status を更新**

`docs/working/issues/README.md` の Issue-0115 行と Issue-0116 行の `open` を `closed` へ。

- [ ] **Step 8-4: ADR-0122 Consequences の実読み込み量表と総量参考値を実測へ更新**

Proposed のため書き直し自由。次を実測へ置き換える:

1. **実読み込み量表 13 行の「分割後」列**——各行を「`SKILL.md` 本文＋当該経路が読む references の合計バイト数」で再計算する。どの経路がどの references を読むかは ADR-0122 決定 4・5 とディスパッチ表に従う（例: `update`（＋節別の記載規範＋移設判定）＝ `SKILL.md` ＋ `op-update.md` ＋ `section-volume-norms.md` ＋ `relocation-map.md`）。（第 3 巡の設計縮小により **(g) の一本化は git 履歴クラスタ 1 件のみ**となり、正本が SKILL.md 本文にあるため参照側に追加の読み込みは発生しない。したがって**ディスパッチ表以外の例外は無い**）。表の導入文の「概算 7.0KB」も実測へ改める
2. **決定 1 の受容記述**（16.8KB＝54%・19.3KB＝62%）
3. **Consequences 第 2 箇条**（「最も削減幅が小さいのは session-handoff の update の移設実行経路（19.3KB＝62%）・finalize（60%）と decision-log の Accepted 昇格（62%）である」）——3 数値がすべて動くうえ、「最も削減幅が小さいのは」という順序主張も再検証が要る（本文が 7.0KB → 8.2KB へ増えるため全経路が同時に動く）
4. **決定 4 の「本文（約 7KB）」・決定 5 の「本文（約 3.4KB）」**と、Consequences 表の導入文にある「対応表 約 3.2KB・手順 約 2.5KB」——実測は 8,248B / 4,073B / 3,698B / 2,812B。Proposed のうちに直さないと誤った概算が確定記録になる
5. **Consequences の総量参考値**（「build-dist.ps1 が併記する総量参考値は session-handoff 約 31KB・decision-log 約 27KB のまま推移する」）——**分割で増える**。4 行ヘッダ×13・ディスパッチ表・新設ポインタのぶん、実測見込みは session-handoff 約 **35.2KB**・decision-log 約 **29.3KB**。「分割前後で変わらない」という記述は偽になるので、増分の理由を添えて実測へ改める

**昇格ガードの判定は Step 8-0 で済んでいる**（本 Step では再評価しない）。Step 8-0 の分岐 1 が選ばれた場合は、上記 2 の受容記述を実測へ改める作業がここに含まれる。

- [ ] **Step 8-5: サイクル全体整合検査を実施**

`skills/decision-log/references/cycle-consistency-check.md` を開き、固定 5 観点とそのサブ基準・完了基準を**全項目そのまま実施する**（計画側で再列挙しない——前サイクルの教訓）。計画側が足す本サイクル固有の突合材料:

- **観点 1（仕様のスナップショット性）の対象**: Task 5 で追従させた spec 02、Task 3 で注記・張り替えした現用 spec 6 件
- **観点 2（規範の書き戻し）の対象**: 本サイクルは規範を新設しない（配置と参照の整備のみ）。ADR-0122 決定 1・3 の「一般規範として新設しない」が実装で守られているか（`AGENTS.md`・`CONTRIBUTING.md`・`skills/` 本体へ拘束的な文を書き足していないこと）
- **観点 3（数値・完了基準の整合）の対象数値**: 完了条件 (a)(b) の実測値（本文サイズ・素経路合計）／spec 02 の件数 36・38・45 と `✓` 行の除去数／ADR-0122 Context の節サイズ実測・Consequences 表 13 行・総量参考値・決定 1 の受容値／**Task 6 が ADR へ書いた (d)(e)(f)(g) の各件数の突合**——**(f) の 36/19/22 は Step 6-3 の 3 本目が計画側を機械計数して照合するため本観点では省く**。それ以外は独立に数え直す: **(d) の張り替え 18・所在注記 5**（Step 6-3 の 2 本目は ADR に書かれた文字列を読むだけで、Task 3 の実作業との突合経路は他に無い）／**(g) のクラスタ数（一本化 1 ＋非該当 4）**／**Task 4 の 22 件**／Issue-0115/0116 の記載値／(g) の一本化が git 履歴クラスタ 1 件に閉じ、200 字が 4 ファイル・40KB が 2 ファイルに残っていること／跨り残存の同期対象 7 項目（うち item 4 は 5 ファイル、item 5〜7 は (g) 非該当由来の数値定数）／Issue-0099 が再判定対象に挙げるサイズ実測トリガー 4 行（本サイクルは当該箇所を編集するため、同 Issue が「編集するサイクルの整合検査が乖離を検査する」と定めた発火にあたる）
- **観点 4（経路の閉じ）の材料**: 到達経路は「session-handoff の 5 操作 × ディスパッチ表」「decision-log の 4 用途 × ディスパッチ表」「横断規範 4 ファイルへの到達（各操作ファイルからの名指し）」「相互参照（session-handoff ⇄ decision-log ⇄ pre-finalization-review）」。二重発火の候補は無し（配置のみ）。イベント依存の候補は「update で正本へ書いた場合にのみ `relocation-procedure.md` を読む」経路（Step 2-3 の項目 21 で配線）。完了基準どおり各経路の発火有無を 1 行ずつ書き出す
- **観点 5（引用の整合）の突合対象**: ADR-0122 Context の節サイズ実測 × Considered Alternatives 2・3 の本文サイズ試算 × Decision 1 の受容値、ADR-0121 決定 4 ②（毎回必要な内容の退避は認めない）の引き写し、ADR-0116 決定 3（条文複写の禁止）の引き写し

検査結果は handoff の消化記録へ `cyclecheck=` として残す。

- [ ] **Step 8-6: 粒度を点検する**

現行タイトル「session-handoff と decision-log は発火単位で references へ分割し、SKILL.md 本文を共通部とディスパッチ表に絞る」に対し、決定 1（完了条件）・2（責務帰属型の判定）・3（分割の軸）・4・5（分割構成）・6（参照の張り替え）・7（例外テーブルの削除）が答えられているかを突合する。決定 1・6・7 は「分割する」の付随（完了判定・配線・後始末）として読めるか判断し、読めなければ分割を提案してから昇格する。

- [ ] **Step 8-7: ADR-0122 を Accepted へ昇格**

`docs/records/decisions/0122-*.md`: `- **Status**: Proposed` → `- **Status**: Accepted`。`docs/records/decisions/README.md` の ADR-0122 行の Status も `Accepted` へ。

- [ ] **Step 8-8: 検証**

```bash
grep -m1 "Status" docs/records/decisions/0122-*.md; grep -m1 "Status" docs/working/issues/flow/0115-*.md docs/working/issues/flow/0116-*.md; grep "0122\|0115\|0116" docs/records/decisions/README.md docs/working/issues/README.md
```

Expected: `Accepted` / `closed` / `closed`。**3 本目の grep は 6 行を返す**——`docs/records/decisions/README.md` には ADR-0115・ADR-0116（start-work 関連の別 ADR。Issue 番号と衝突する）と ADR-0121 の行が既にあるため。確認するのは `decisions/README.md` の **0122 行**が `Accepted`、`issues/README.md` の **0115・0116 行**が `closed` であることの 3 点（編集対象はファイルで分離しているので誤編集の危険は低いが、Expected を「3 行」にすると必ず外れる）

```bash
for f in docs/working/issues/flow/0115-*.md docs/working/issues/flow/0116-*.md; do echo "$(wc -c < $f) $f"; done
```

Expected: 両ファイルとも 10000 未満（課題管理定義の追記時サイズ確認）

- [ ] **Step 8-9: コミット**

```bash
git add docs/records/decisions docs/working/issues docs/working/plans/2026-09-03-adr-0122-skill-split-implementation.md && git commit -m "adr: 0122 Accepted 昇格 - Issue-0115/0116 close・サイクル全体整合検査実施"
```

---

## 完了後の次手

1. `session-handoff` update（マイルストーン名に `ADR-0122 Accepted 昇格` を含め、`cyclecheck=` を記入）
2. `superpowers:finishing-a-development-branch`（実行直前に `skills/start-work/references/merge-practice.md` を読む。master handoff の慣行は `--no-ff`）
3. マージ後に `retrospective`（`docs/records/retrospectives/system/` へ）→ cycle-reset → push（配布 0.1.18 の反映）

## 自己レビュー結果（writing-plans の 3 点）

1. **Spec coverage（ADR-0122 決定 1〜7 と Consequences）**: 決定 1 → Task 1 Step 1-6・Task 2 Step 2-8 の完了条件 (a)(b) の実測と **Task 8 Step 8-0** の昇格ガード 2 条件＋2 分岐。決定 2 → 実装対象外（判定のみ）。決定 3 → Task 1・2 のディスパッチ表。決定 4 → Task 2（9 ファイル・跨り残存の同期対象 7 項目）。決定 5 → Task 1（4 ファイル）。決定 6 (a) → Step 1-5・2-6（フェンス内を含む）、(b)(c) → Step 1-3・2-3、(d) → Task 3（張り替え 18・所在注記 5）、(e) → Task 4（Step 4-0 の 2 系統走査＋Step 4-0b の第 3 系統＋注記 22 件）、(f) → 本計画の表と Step 2-3 の (f) 印、(g) → 本計画の表 一本化 1 クラスタ＋非該当 4 件と Step 2-3 の (g) 印、壊れ許容・open 課題の名指し → 「変更しないもの」。決定 7 → Task 5。Consequences の spec 02 陳腐化 → Task 5、総量参考値 → Task 8 Step 8-4、執行点と version bump → Task 7、Accepted 昇格と Issue close → Task 8、ディスパッチ追随失敗の受け皿 → Task 8 前文。**ギャップなし**
2. **Placeholder scan**: 「TBD」「後で」「適宜」の類は無い。各 Step は旧文字列と新文字列、または挿入本文を持つ
3. **Type consistency**: ファイル名は ADR-0122 決定 4・5 の 13 名と一致（`op-read.md` / `op-create.md` / `op-update.md` / `op-finalize.md` / `op-cycle-reset.md` / `relocation-map.md` / `relocation-procedure.md` / `review-field-values.md` / `section-volume-norms.md` / `adr-authoring.md` / `open-questions.md` / `status-updates.md` / `cycle-consistency-check.md`）。件数は Task 1（29）→ Task 2（38）→ Task 5・7（38）で単調。切り出し範囲の行番号は Step 0-2 の実測に対応。第 3 巡の反映後、張り替え 18・所在注記 5・ADR 注記 22・(f) マーカー 36/19/22・(g) 一本化 1 クラスタ＋非該当 4 件の各数値が Task 3・4・6 と Step 8-5 観点 3 で一貫していることを機械計数で確認済み

## 確定前レビューの記録

**確定点**: plan 確定点。**成果物の型**: 規範改定型（迷い判定。閾値は通常型の値 4 巡）。**改訂前退避**: `~/.ai-dev-review-snapshots/MakeAiInstructions/2026-09-03-adr-0122-plan/`（r1 = 第 1 巡前の草稿）。

### 第 1 巡（フル巡・4 観点分離 4 体・claude-opus-5）

隔離コピー 4 つ（`git -c core.longpaths=true clone --local --no-hardlinks` ＋未追跡ファイルの複製。コピー元との `diff -r` で同一性を確認。既知差異は空ディレクトリ 1 件と改行コード 1 件のみ）を各体へ供与。4 体とも作業前後のハッシュ比較で ISO 改変ゼロを報告（うち 2 体は計画の Task 1・2・3・5 を ISO 内で完走し、検証後に baseline へ復元）。

指摘は Critical 4・Important 16・Minor 18（重複を含む延べ）。独立検出の重なりが大きく、実体は 20 件。前提検査（`pre-finalization-review` 手順 5）を 1 件ずつ実施し、**採用 18 件・不採用 2 件**とした。

**採用（主なもの）**:

| # | 指摘 | 反映先 |
|---|---|---|
| 1 | Step 2-8・Step 3-7 の検証 grep が `` `session-handoff` `` のバッククォート有無で `iteration-norms.md` に構造的に一致せず、張り替え漏れがあっても緑を返す空振り検証だった | Step 2-8 のパターンを 2 本立て化・Expected 訂正、Step 3-7 を 13 パターンへ拡張し 19 件の検出を実測で確認 |
| 2 | Task 6 が ADR-0122 へ書き戻す実測値 5 種が計画自身の列挙と不一致（張り替え 15 対 18、(f) の 28/14/17 対 38/19/22 ほか） | Step 6-1・6-2 を機械計数で書き直し、総数を書かない箇所を明示。Step 6-3 に内訳との突合 grep を追加 |
| 3 | 本計画ファイル自身がどのタスクでも `git add` されず、Task 6 が未追跡パスを Accepted ADR の判定規則の正本として書き込む | Step 0-1 の Expected 訂正、ファイル構成表へ追加、Task 1・2・4・8 の `git add` へ明記 |
| 4 | Step 0-3 の版一致ゲートが構造上必ず失敗する（plugin キャッシュは出所識別子を除去した `dist/` 由来で、`skills/` 側と一致しないのが設計どおり。実測 12,195B 対 12,459B） | 比較対を `dist/` へ変更し、理由を明記 |
| 5 | (g) の一本化クラスタに **40KB 目安値**（現行 L180・L219 に数値とフォールバック句が分散）が漏れている。ADR が 200 字に与えた論法と同型 | (g) 表へ 3 クラスタ目を追加、Step 2-3 項目 25 を再掲の削除へ改め、Step 2-8 へ検証 grep を追加 |
| 6 | Task 4 の候補母数が節名一致 26 件に固定され、ファイルパスで実装対象を名指しする 4 件（0030 / 0032 / 0114 / 0120）を取りこぼす | Step 4-0（2 系統の全数走査）を新設、注記を 21 件へ拡張 |
| 7 | 現用 spec の生きた正本ポインタ 2 件（`2026-08-06` L44・`2026-04-25` L225）が張り替え対象にも据え置きにも現れない | Step 3-5 を 6 箇所へ拡張 |
| 8 | ADR-0122 決定 1 がユーザー受容値として持つ 16.8KB・19.3KB が実測で 7〜8 ポイント悪化するのに、Step 8-4 の昇格ガードは最頻経路の半減しか見ない | Step 8-4 のガードを 2 条件へ拡張（受容値を上回ったら昇格せず提示） |
| 9 | `op-*.md` 5 件の導入 1 文が、結合される本体第 1 行（`呼ばれるタイミング: …`）を言い直しており、計画自身の「導入文を直後の条文と重複させない」規定に反する | Step 2-2 の導入文を「本ファイルが何の正本か」だけに縮小 |
| 10 | サイズ Expected（3,000〜3,800B / 7,000〜7,900B）がディスパッチ表の実測で達成不能（実測 4,074B / 8,248B。設計ではなく見積りのずれ） | Expected を実測レンジへ訂正、完了条件 (b) の見込みを実測値へ |
| 11 | ADR-0122 Consequences の総量参考値「分割前後で変わらない」が偽になる（実測 約 35.7KB / 約 29.3KB へ増える） | Step 8-4 の更新対象へ追加 |
| 12 | 決定 6 末尾「open 課題は出所の名指しに限り現状へ合わせる」に対応する走査結果が無い | 「変更しないもの」へ open 課題 3 件（0102 / 0099 / 0085）の判定を実証つきで追記 |
| 13 | Step 6-3 の検証 grep が日付リテラルを含み、実装が翌日以降にずれると空振りする（計画自身の日付読み替え規定と衝突） | パターンから日付を除去 |
| 14 | Step 6-1 の「段落全体を置換」が実体と合わない（対象は L79 の行内 1,106 バイト目以降の部分文字列。字下げを付けると行中に空白が混入） | 置換の位置指定を実測つきで書き直し |
| 15 | Step 1-8・Step 2-10 の Expected「除去残骸 0 件」は正当な入れ子括弧が 5 件・10 件ヒットするためゲートとして機能しない | 既知の正当ヒット数を Expected に書き、総数 0 を期待しない形へ |
| 16 | Step 0-1（未追跡 5 件）・Step 0-2（decision-log 側のフェンス内見出し 4 行）・Step 8-8（索引 grep は 6 行）の Expected が実測と不一致 | 3 件とも実測へ訂正 |
| 17 | 逸脱判断の既定の宣言欄に、`plan-deviation-defaults.md`「検出層」が要求する宣言（タスク別レビューを置かない工程型での「逸脱突合」1 行）が無い | 宣言欄へ 1 項目追加 |
| 18 | (f) 表の粒度が不揃い（`op-update.md` / `op-cycle-reset.md` 行に handoff 雛形の節名依存が無い）／Task 4 の 0096 の挿入位置表現が実体と異なる／`.body` 中間ファイルは規約違反を出さずに配布物へ載る（実測） | (f) 表へ 2 行追加・跨り残存へ 4 項目目を追加、挿入位置を 3 分類の実測へ、Step 1-1・2-1 へ既存 `.body` のガードを追加 |

**不採用 2 件**（実装時レビューへの引き継ぎ対象。`plan-deviation-defaults.md` 前処理 2. の突合対象）:

1. **(g) へ「移設で作成・更新した正本ファイルの add 規定」（現行 L166・L234・L255）をクラスタとして加える**（仕様適合観点）— 不採用。実証: `relocation-procedure.md` へ移る手順 6 が「どの操作を起点とする移設でも同じ。finalize では…read・cycle-reset 起点では…update の移設判定の手順を契機に…」と全起点を統べる正本として既に一本化されており、`op-finalize.md` 手順 7 と `op-cycle-reset.md` 手順 6 は規定内容の異なる操作手順（前者は add してコミット、後者は add してコミットしない）。同一条文の複写ではない。**引き継ぎ先: Task 2 Step 2-10 の配布物目視**（分割後の 3 ファイルを読み、条文複写になっていないかを実体で確認する）
2. **`docs/current/specs/2026-04-12-meta-guidelines-design.md` を張り替え対象に加える**（仕様適合観点）— 不採用。実証: L61・L128・L136・L202・L243 はいずれもスキル名・ディレクトリ名のみで移設対象節を指さない（R1 据え置き）。**引き継ぎ先: Task 8 Step 8-5 の観点 1**（仕様のスナップショット性の検査で、現用 spec 全数のうち未処理のものが残っていないかを再確認する）

### 第 2 巡（フル巡・4 観点分離 4 体・claude-opus-5・新規レビュアー・重点指定あり）

改訂差分 543 行（r1→r2）を重点検証項目として各体へ渡し、フル走査と併用させた。隔離コピーは改訂後の状態で作り直し（r5〜r8）、4 体とも前後ハッシュ比較で ISO 改変ゼロを報告（うち 3 体は Task 1・2・3・5・7 まで ISO 内で完走してから baseline へ復元）。

指摘は Critical 4・Important 21・Minor 17（延べ）。実体は 19 件で、**うち 14 件が「第 1 巡の是正そのものに混入した誤り」**だった（Expected の訂正値がまた外れる／改訂で機構を増やした結果の副作用／件数の数え直しの誤り）。前提検査を 1 件ずつ実施し、**採用 17 件・不採用 2 件**とした。

**採用（骨格に触れるもの 3 件）**:

| # | 指摘 | 反映先 |
|---|---|---|
| 1 | **Step 8-4 の昇格ガードが Issue close（8-1〜8-3）より後にあり、計画自身が「成立する見込みが高い」と書いた (ii) が発火すると「課題は closed・ADR は Proposed」という定義されていない中間状態になる**。ADR-0122 決定 7 が両者を結び付けているため、close だけ先行するのは決定と食い違う。発火後の分岐も計画に無い | **Step 8-0 を新設**して Task 8 の冒頭でガードを評価し、(ii) 発火時の 2 分岐（受容値を実測へ更新して続行／受容せず中断し課題起票）を明記。Step 8-4 からはガード判定を外した |
| 2 | **(g) の 40KB 一本化は finalize に毎回の他ファイル依存を作る**（現行は `op-finalize.md` だけで値が確定する）。ADR-0121 決定 4 ② の禁止は SKILL.md → references の退避が射程で規定違反ではないが、Step 8-4 の実読み込み量の算定規則（ディスパッチ表に従う）が破れ、finalize 行が約 2.4KB 過少になる | (g) 表へ「副作用の受容」を明記し、Step 8-4 項目 1 へ「finalize 経路は `op-read.md` を含める」という例外を追加 |
| 3 | **Step 1-1・2-1 の `.body` ガードが守る経路と噛み合わない**（危険なのは Step 1-2 からの再開だがガードは 1-1 の先頭にあり、抽出は `>` で冪等。混入自体は Step 1-7 のファイル数 Expected が既に検出。`exit 1` が対話シェルを終了させる副作用もある） | ガード 2 件を削り、「再開は必ず Step 1-1 / 2-1 から」の注記へ置き換え |

**採用（判定の訂正 5 件）**:

| # | 指摘 | 反映先 |
|---|---|---|
| 4 | **ADR-0059 は R7 非該当**（Context が「ADR 作成手順には観点がない」と規範の**不在**を指摘するのみで、反映先・実装対象の宣言を持たない。実体側の `（ADR-0059）` タグは実装からの逆算であり ADR 本文の主張ではない） | Task 4 から外し、非該当の理由を実証つきで記録 |
| 5 | **ADR-0028 は R7 該当**（L36 が `` 波及更新: …`skills/decision-log/SKILL.md`（未決事項の起票手順のパス） `` とパス＋節内手順名で名指し。該当と判定した ADR-0030 L30 と同型） | Task 4 へ 22 件目として追加（0059 の除外と差し引き **21 件**を維持） |
| 6 | **Step 4-0 の節名パターンが移設 13 ファイルの節名を全数覆っていない**（`コミットのタイミング` / `ライフサイクル` / `検出を報告` / `インデックスを更新` を欠き、0028・0096 が節名一致側で返らない）。結果、Expected「26 件前後」も由来の帰属も再現しない | パターンへ 4 語を追加し設計根拠を明記。Expected を実測（by-section 30 行・comm 9 件）へ、由来を「節名一致 17＋パス 4」へ訂正（**補強後は第 1 巡の帰属が正しくなる**） |
| 7 | **10KB フォールバック句は一本化してはならない**（同一句が 4 箇所にあり、うち 2 件が本サイクルの移設対象。ただし ADR-0105 が共通規範への統合を検討のうえ**覆し**、Issue-0099 が「存置・受容済み・常設の監視経路なし」として再判定を待つ状態にある。一本化は ADR-0105 を覆すことになる） | (g) の「非該当」へ 2 件目として実証つきで記録し、Issue-0099 の再判定へ委ねる |
| 8 | **open 課題の走査結果 3 件が実体と合わない**（0053・system/0071 が漏れ、0099 の据え置き理由は L12 前半のみを説明。逆に **Issue-0085 L10 の「session-handoff の様式 8 箇所」は L16 が対策の初期値として使う生きた運用データ**で、5 箇所が references へ移る） | 走査結果を 6 件へ。0085 を「現状へ合わせる」唯一の対象とし、Task 3 Step 3-6 へ所在注記 1 行を追加 |

**採用（数値・Expected の訂正 9 件）**: (f) のマーカー計数 38/19/22 の根拠を「表 13 行のみを数える」と固定（凡例文を含めると過大になる）／Step 6-1 の (d) 内訳合計 21 と総数 18 の矛盾を解消（相互参照 3 は (c) 側の作業なので (d) に数えない。所在注記は 0085 を加えて 5 行）／Step 6-3 の 2 本目に **literal の期待値 6 値**を与える（「一致すること」だけでは目標値が無く検証にならない）／Step 2-8 の完了条件見込みを 12,670B・references 合計 26,858B へ（第 1 巡で導入文を 91B 縮めた差が未反映だった）／Step 2-10 の Expected を 9 件へ（根拠に挙げた `）に従い` は分割後どこにも存在せず、入れ子括弧の 10 件目は改訂 1 が消していた）／Step 5-2 項目 5 の取得元を Step 5-3 へ（Task 7 は Task 5 より後で、しかも Step 7-2 の grep は `✓` 行を落とす）／Step 8-1・8-2 の close 追記を実測へ／Step 8-4 の更新対象へ **Consequences 第 2 箇条・決定 4/5 の本文サイズ・L92 の対応表と手順の増分**を追加、総量参考値を 35.1KB へ／Step 0-2 の「計 21 行」を実測 26 行へ・Step 0-4 の用途説明を訂正・Step 1-6 の内訳を 4,073B / 12,823B へ・Task 3 の Files を 2 箇所へ・8 タスクすべての `git add` へ計画ファイルを追加。

**不採用 2 件**（実装時レビューへの引き継ぎ対象。第 1 巡の 2 件とあわせて計 4 件が引き継ぎ対象）:

1. **Step 6-3 の 2 本目の grep を削る（Step 8-5 観点 3 と重複）**（前提実在観点）— 不採用。実証: 重複は事実だが、Step 6-3 は Task 6 の時点で誤りを直せる早期検出の便益がある（Step 8-5 は Task 8 で、直すには ADR の再編集が要る）。代わりに **Step 8-5 観点 3 の側で重複範囲を切り分けた**（(d)(f) は Step 6-3 で照合済みとし、観点 3 では (g) のクラスタ数と Task 4 の 22 件のみを数え直す）。**引き継ぎ先: Task 8 Step 8-5**（実施時に二度手間が生じていないかを観察する）
2. **(g) の 40KB クラスタを撤回し両方に残す**（前提実在観点の代替案）— 不採用。実証: ADR-0122 決定 6 (g) は 200 字クラスタに対し「数値定数は正本 1 箇所に置き他は参照とする」と明記しており、40KB は同型。撤回は決定 6 (g) の適用を狭める側の変更になる。代わりに**副作用（finalize の毎回の他ファイル依存）を (g) 表へ明記し、Step 8-4 の算定へ例外を配線**した。**引き継ぎ先: Task 2 Step 2-10 の配布物目視と Task 8 Step 8-4**（finalize の実読み込み量が受容できる水準かを実測で確認する）

**計画へ反映しなかった報告 1 件**（本計画の射程外・別途対応）: `docs/working/handoff/master.md` の申し送り「**この環境に Python は無い**（実測: exit 49）」が実態と異なる（実測 `Python 3.12.1` が動作し、配布対象ソースにも `.py` が 1 件ある）。本計画は Python を使わないため影響しないが、誤った申し送りが伝播している。

### 第 3 巡（フル巡・4 観点を 2 体へ兼務・claude-opus-5・新規レビュアー・重点指定あり）

改訂差分 516 行（r2→r3）を重点検証項目として渡し、フル走査と併用させた。体 1＝敵対的＋実装整合性、体 2＝仕様適合＋前提実在（`pre-finalization-review`「反復の実施」のフル巡は 4 観点を維持し体数のみ 1〜4 体へ縮小してよいという規定に従い、観点は減らさず兼務で 2 体とした）。隔離コピーは改訂後の状態で作り直し（r9・r10）、2 体とも前後ハッシュ比較で ISO 改変ゼロ（体 1 は Task 1・2・3・5 を 2 度完走してから復元）。

**第 2 巡が訂正した Expected 値 14 件はすべて実測と一致**した（1,467B / 4,073B / 12,823B / 8,248B / 12,670B / 26,858B / 9 件 / 23・4 identifiers / by-section 30・by-path 19・comm 9 / rows 13・37+1/19/22 / 26 行 ほか）。数値層は収束している。指摘は Critical 3（うち 1 件は両体が独立検出）・Important 10・Minor 7 で、**採用 13 件・不採用 0 件**。

**設計縮小 1 件（ユーザー承認のうえ適用）**:

| 指摘 | 反映 |
|---|---|
| **(g) の 200 字クラスタの一本化が、完了条件が測る「update 素経路」に毎回の他ファイル依存を作る**（両体が独立検出）。置き換える規定は `op-update.md` 手順 3 の地の文にあり、消化記録行は update のたびに書く。素経路は 12,670B ではなく 15,273B になり、決定 1 の素経路の定義（「節別の記載規範の参照…を伴わないもの」）が実体から消える。40KB について書いた「唯一の例外」も偽になる | **(g) の一本化を git 履歴クラスタ 1 件に絞る設計縮小**を適用。200 字・40KB とも非該当へ振り替え、跨り残存の同期対象（item 5・6）へ回した。根拠は (a) ADR-0121 決定 4 ②（(g) の上位規範）「発火時に毎回必要な内容の退避は認めない」に両者とも触れる (b) ADR-0105 L48 (d) が 40KB について「ファイル内の一本化は現状で達成済み」と判定しており、**除去を積極的に要求する根拠が上流に無い**（同 (d) は ADR-0121 L50 が「C-14 固有の判定」と限定して読んでおり、再掲の保持を命じるものでもない） (c) 決定 1 の測定基盤が保たれる。これに伴い副作用の受容・Step 8-4 の算定例外・Step 2-8 の 40KB 検証・Step 2-3 の 3 項目が不要になり計画が縮んだ（列挙 32 → 29 項目・変更行 28 → 27 行）。ADR-0122 決定 6 (g) の適用を狭める判断のため Task 6 で ADR へ理由を記録する |

**採用（判定・検証の訂正 12 件）**:

| # | 指摘 | 反映先 |
|---|---|---|
| 1 | **ADR-0087 が候補母数から漏れている**。Step 4-0 の「13 ファイルの節名を全数含む」は偽で、`起票` / `注意` と session-handoff の操作 5 節名・移設手順の節名を欠く。2 系統の和集合外に 18 ADR が残り、うち ADR-0087（決定 1 が read 手順 4・finalize 手順 1 のサイズ実測を、決定 4・5 が超過時の移設手順の実施を実装対象として名指し）が該当 | **Step 4-0b（第 3 系統の走査）を新設**し 18 件の判定を実証つきで記録。Task 4 を 22 件へ。節名パターンの限界も明記 |
| 2 | (g) の 10KB 非該当の実証で監査台帳 ID を取り違え（C-07 / C-14 は 40KB そのもので、10KB に対応するのは **J-09** のみ）。自ら「40KB とは別値・別規定であり混同しないこと」と警告しながら混同していた | J-09 へ訂正 |
| 3 | Step 8-5 観点 3 の「重複範囲の切り分け」が **(d) の照合経路を消していた**。Step 6-3 の 2 本目は ADR に書かれた文字列を読むだけで、Task 3 の実作業との突合は 3 本目の (f) 表計数に限られる | (d) の除外を撤回し、(f) のみを Step 6-3 へ委ねる形へ |
| 4 | Step 6-3 の 1 本目のパターン `実測: 200 字上限クラスタ` が (g) 追記の実文（`実測: クラスタは 2 件ではなく…`）と一致せず、Expected `3` に対し `2` を返す | パターンを実文へ合わせた（設計縮小後は `実測: クラスタは` で一致） |
| 5 | Step 6-3 の 2 本目の literal Expected「6 値」が実際には **9 行・7 種**（`張り替え` と `所在注記` は Step 6-1 が総数と内訳見出しで各 2 回書き、(f) 追記の計数根拠の説明文にある `新設 2 箇所` も同じパターンに一致する） | Expected を実測どおり 9 行・7 種へ |
| 6 | Step 4-1 の挿入位置の目安で **ADR-0028 が誤分類**（`## Related` が続くのに「Consequences が最終節」へ置いていた）。第 1 巡で ADR-0059 が入っていた枠に、性質を確かめずに 0028 を置いた | 7 件 / 3 件 / 12 件へ訂正 |
| 7 | **Step 8-0 の分岐 2（受容せず中断）が「完了後の次手」と接続していない**。`cyclecheck=` に書く値・ブランチをマージするか・Task 5 で例外テーブル行を削除済みのため課題文が実体と乖離する点が未定義 | 分岐 2 へ中断時の次手 3 点（(a)〜(c)）を明記 |
| 8 | 自己レビュー結果が第 2 巡の訂正に追随せず、「機械計数で確認済み」が偽になっていた（所在注記 4 → 5・(g) 非該当 1 → 2・ガードの所在） | 3 値を訂正し、第 3 巡の値へ更新 |
| 9 | ADR-0059 非該当の実証文「`skills/decision-log` の名指しは Context L8 の 1 箇所のみ」が実体と不一致（同 ADR にパス表記は無く `by-path.txt` にも現れない） | 「`decision-log` の言及」へ訂正し by-path 側の不在も実証に加えた |
| 10 | Tech Stack の「この環境に Python は無い」が実態と異なる（`python3` はストアのスタブで exit 49 だが `python` は 3.12.1 が動作。配布対象ソースにも `.py` が 1 件） | 実態へ訂正（第 2 巡では「計画の射程外」として保留していた） |
| 11 | 現用 spec 45 ファイル中、`session-handoff` / `decision-log` を含む 29 ファイルのうち 11 件が計画の 3 分類のいずれにも現れない（判定はすべて据え置きで正しいが、走査の全数性が示されていない）／open 課題の「名指し行 6 件」の絞り込み条件が未明示 | 全数 45 への帰属を明記し、`00-overview.md` L40 を据え置き列挙へ追加。open 課題は「出所の名指しと判定した 6 件・経緯記述は R5 で計数外」と条件を明記 |
| 12 | Step 0-2 の Expected が decision-log 側にだけ総数を持ち、session-handoff 側（フェンス内 9 行）が片手落ち | 「節見出し 18 行＋フェンス内 9 行＝計 27 行」を追加 |

**不採用 0 件**（第 3 巡では全指摘を採用した。通算の不採用は第 1・2 巡の 4 件のまま）。

**第 3 巡で「問題なし」と確認された主な項目**: (g) の 4 クラスタ目は存在しない（13 ファイルの全 78 ペアを 28 字・20 字一致で全数探索）／Step 8-0 の判定コマンドは正しく動作し 4 値とも Expected 一致／`.body` ガードの削除で守れなくなった経路は無い（ISO で `.body` 残置を再現し、`Convention violations: 0` のままファイル数だけ増えることと Step 1-7 が捕捉することを確認）／Step 3-7 の 13 パターンは分割前 19 件・Task 2 完了後 18 件・Task 3 完了後 0 件／Task 1・2 の抽出行数・diff 差分・サイズ・見出し数・記法規約はすべて Expected 一致／`build-dist -Check`・`sync-template -Check` とも exit 0。

### 第 4 巡（差分確認巡・1 体・claude-opus-5・新規レビュアー）

第 3 巡の指摘 13 件 → 改訂箇所の**対応表 42 項目**（A 設計縮小 23・B 判定と検証の訂正 12・C 全体整合 7）を委譲側が作って渡し、4 値判定（反映済み／未反映／部分反映／過剰）で全数を検証させた。改訂差分は 330 行・16 ハンク。**継続レビュアーは用いず新規レビュアーを立てた**（骨格安定と判断しておらず、かつ改訂が設計骨格に触れる設計縮小であるため。`pre-finalization-review`「反復の実施」の継続レビュアー規定の例外条件を満たさない）。ISO 改変ゼロ。

**判定結果: 反映済み 35・部分反映 7・未反映 0・過剰 0。** 加えて削り残し 4 件と、設計縮小の根拠 (b) の引用過剰 1 件を検出。**対応表外の新規指摘は 0 件**。

**サイズは全数実測一致**——references 9 ファイル（723 / 1,879 / 3,838 / 2,356 / 4,436 / 3,698 / 2,812 / 4,611 / 2,603）と合計 26,956B、両 SKILL.md（8,248 / 4,073）、Step 8-0 の 4 値（12,684 / 12,823 / 18,985 / 21,797）、Step 2-4 の diff 9 値、Step 1-4 の 4 値、総量参考値（35,204 / 29,319）が**すべて差 0**。設計縮小に伴う依存計算（`op-finalize` 3,653＋185・`relocation-map` 3,743−45・`review-field-values` 4,667−56・`op-update` 4,422＋15−1）も帰結値として正しいことが確認された。Step 2-3 の 29＋8＋1＋2 の置換もすべて旧文字列が一意に 1 件ヒットして成功している。

**採用 12 件（全件。不採用 0）**——いずれも設計縮小に伴う記述の追随漏れで、設計骨格には触れない:

| # | 指摘 | 反映 |
|---|---|---|
| 1 | Step 2-3 の「L210 に 4 項目〈20〜23〉」「L210 は 1 行に 4 箇所」が旧番号のまま（旧項目 21 の取り下げで 4→3。算術的にも 29 項目と矛盾） | 「3 項目〈18〜20〉」「1 行に 3 箇所」へ |
| 2 | (f) 表 `relocation-map` 行が「(g) 200 字クラスタの **4 箇所目**」のまま。かつ「1 件 200 字以内」を新設ポインタ扱いしているのに、対応する新設は Step 2-3 から取り下げ済みで**宙に浮いていた** | 2 要素を分離し、「1 件 200 字以内」は値を自ファイルに残す（跨り残存 item 5）旨へ |
| 3 | 自己レビュー結果 1 が「所在注記 4」「同期対象 4 項目」のまま（第 3 巡の指摘 8 は結果 1・3 の追随を求めたが 3 のみ入っていた） | 5・7 へ |
| 4 | Step 8-5 観点 3 の「(f) の 38/19/22」が旧値（Step 6-2・6-3 は 36 へ直っていた） | 36/19/22 へ |
| 5 | Step 6-3 の Expected 説明が**削除済みの旧稿**「実測: クラスタは 2 件ではなく…」を引用 | 実文「実測: クラスタは 5 件を検出し…」へ |
| 6 | **Step 2-10 の Expected「ヒット 9 件」が旧設計の値**（計画自身が「40KB の一本化をしない設計なら 10 件になる」と書いており、設計縮小でまさにその設計になった。内訳の `op-finalize` 0 も誤り） | **10 件**へ。内訳に `op-finalize` 1 を追加し、9→10 の経緯を注記 |
| 7 | Step 8-4 項目 4 のサイズ実測値 3,743B が旧値（Step 2-8 は 3,698 へ直っていた） | 3,698B へ |
| 8 | Step 8-5 観点 4 の「Step 2-3 の 24 で配線」が旧番号（新番号 21） | 項目 21 へ |
| 9 | 逸脱判断の既定の**不採用 4 件が実質 3 件**（(4)「40KB クラスタを撤回して両方に値を残すか」は第 3 巡で**採用へ転じた**）。しかも引き継ぎ先の Step 8-4 の算定例外は削除済みで宙に浮いていた | 3 件へ。(4) が採用へ転じた旨を注記 |
| 10 | **設計縮小の根拠 (b) が引用過剰**——「ADR-0105 L48 (d) が…認定済みであり、再掲の除去は同 ADR の判断を覆す」は強すぎる。(d) が認定したのは *ファイル内* の一本化で、分割後はファイル間になり同じ認定は引き継がれない。さらに **ADR-0121 L50 が「(d)〈ファイル内一本化の既達成〉は C-14 固有の判定」と限定して読んでいる**。(d) が支えるのは「文書側へ共通規範ノードを新設する統合先案」の否定であって再掲の除去ではない | 4 箇所（(g) 表・跨り残存 item 6・Task 6 の追記文・第 3 巡記録）を「(d) は再掲の保持を命じないが、除去の必然性も生まない」へ弱めた。**40KB を非該当とする結論は理由 2（finalize が毎回値を要する＝根拠 (a) の系）で独立に支えられるため、設計縮小そのものは崩れない** |

**根拠 (a)(c) は成立を確認**——(a) ADR-0121 決定 4 ②「発火時に毎回必要な内容の退避は認めない」の引用は逐語一致でゲート脱落なし（references→references への拡張適用は ADR-0122 決定 1 自身が同じ拡張をしている先例がある）。(c) 決定 1 の素経路定義「節別の記載規範の参照…を伴わないもの」の引用も逐語一致で、数値も自己整合（12,670＋2,603＝15,273、閾値との余裕 327）。

**削り残しの走査で「見つからなかった」もの**（＝問題なし）: 旧「40KB の副作用」段落と、それを指す語（`受容の明示` / `本項がその例外` / `唯一の例外`）は 0 件。`40KB を一本化` / `3 クラスタ＋` / `非該当 2 件` / 旧サイズ `4,422`・`4,667` / `32 項目` もすべて 0 件。Step 2-3 の項目番号 1〜29 に欠番・重複なし。ADR 注記表 22 行に欠番・重複なし。8 コミットの `git add` はすべて本計画ファイルを含む。

### 反復の終了（2026-09-03）

**終了状態: 実質収束**（`pre-finalization-review`「指摘反映後の反復」の停止判定・第 1 経路）。第 4 巡が「成果物の実体への新規の設計欠陥がゼロ、かつ残指摘が直前の修正に由来する機械検証可能な型のみ」を満たした（対応表外の新規指摘 0 件。部分反映 7 件と削り残し 4 件はいずれも設計縮小の追随漏れ）。第 4 巡の指摘 12 件は全件採用して反映済みで、反映は委譲元が grep で全数確認した。

**通算 4 巡**（フル巡 3・差分確認巡 1。全巡 claude-opus-5・新規レビュアー）。**通算巡数の分布外検知は発火した**（成果物の型＝規範改定型〈迷い判定・閾値は通常型の値 4 巡〉に到達）。発火時の提示を行ったうえでユーザーが確定を選択した。

**巡ごとの収量**: 第 1 巡 採用 18・不採用 2 ／ 第 2 巡 採用 17・不採用 2 ／ 第 3 巡 採用 13・不採用 0（うち設計縮小 1 件をユーザー承認のうえ適用） ／ 第 4 巡 採用 12・不採用 0。**4 巡を通じて、前巡の是正に混入した誤りが毎回の主要な収穫だった**（第 2 巡 14 件・第 4 巡 12 件が該当）。

**改訂前退避**: `~/.ai-dev-review-snapshots/MakeAiInstructions/2026-09-03-adr-0122-plan/`（r1＝第 1 巡前・r2＝第 1 巡反映後・r3＝第 2 巡反映後・r4＝第 3 巡前・r5＝第 3 巡反映後・r6＝第 4 巡反映後＝確定版。巡間差分は同ディレクトリの `diff-*.patch` 4 件）。

**実装時レビューへの引き継ぎ（不採用 3 件）**: 冒頭「逸脱判断の既定」の宣言欄が正本。`plan-deviation-defaults.md` 前処理 2. の突合対象である。
