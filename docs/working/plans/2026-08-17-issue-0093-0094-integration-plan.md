# Issue-0093/0094 統合・簡素化 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 全数監査で「統合」に分類された二重定義 22 行（実変更 15 行＋覆し 7 行）と「簡素化」3 行を、ADR-0105 の設計どおり配線化・束ね直しで実装する。

**Architecture:** 重複側の詳細を削り「定義は統合先が正」の配線行へ置換する（共通規範の新設はしない）。固有条件は削除前に統合先へ吸収する。編集はクラスタ単位のタスクに分割し、配布対象ソースを触るコミットは毎回生成器＋`-Check` を通す。

**Tech Stack:** Markdown 文書編集のみ（コード変更なし）。生成器 `scripts/build-dist.ps1` / `scripts/sync-template.ps1`（PowerShell）。

---

## 前提・実装原則（全タスク共通）

1. **実体読みで対象特定**: 監査台帳の行番号アンカーは使わない（CONTRIBUTING 最大 +23 行の陳腐化済み。ADR-0105 Consequences）。各タスクの old_string は本計画作成時（2026-08-17）の実体読みに基づく。編集前に Read で対象箇所を確認し、ずれていれば実体に合わせる
2. **配線行の規律**（本サイクル限りの作業方式。ADR-0105）: 配線行に統合先の改定で変わりうる数値（件数・閾値・手順数）を書かない（「5分類」のような分類体系の名称の一部は数値に数えない）。配線行を出所リスト行の形（`- ADR-NNNN: 説明`）で書かない
3. **フォールバック規律**（ADR-0098）: スキルから文書側の定義を参照する箇所には「定義が見つからない場合の既定動作」を残す。スキル間（プラグイン内）参照にはフォールバック不要。文書側の被参照定義には「参照される」旨の注記を付ける
4. **執行点**: 配布対象ソース（skills/ 配下、template.manifest 記載の CLAUDE.md / principles.md / folder-structure.md / issue-management.md / docs/inbox/README.md、および空インデックス生成対象の docs/records/decisions/README.md / docs/records/retrospectives/README.md / docs/working/issues/README.md）を変更したコミットは、コミット前に (1) 変更した側の生成器を実行（skills/ → `./scripts/build-dist.ps1`、それ以外の配布対象ソース〈manifest 記載・空インデックス生成対象とも〉 → `./scripts/sync-template.ps1`）、(2) 両方を `-Check` で実行、(3) 生成された `dist/` と `template/` を同じコミットに含める、(4) 変更した配布物ファイルを CONTRIBUTING「機械判定が届かない領域」の 5 点で目視する
5. **コミットは pathspec 付き**: `git add <明示パス>` のみ。`docs/inbox/` と `docs/conversation_log.md`（ユーザーが手動移動予定）を巻き込まない（Issue-0020）
6. **編集後の実体確認**: 各タスクの検証ステップは grep / Read の実体読みで行う（ツール戻り値で代替しない）
7. **本 plan 自体のコミット**: 確定した本 plan ファイルは、実装開始前（Task 1 の前）に単独でコミットする: `git add docs/working/plans/2026-08-17-issue-0093-0094-integration-plan.md` → `git commit -m "plan: Issue-0093/0094 統合・簡素化の実装計画（確定前レビュー 3 観点反映済み）"`

## ファイル構成（変更対象の全体像）

| ファイル | 変更内容（タスク） |
|---|---|
| `skills/decision-log/SKILL.md` | 強トリガー 5 へ「削除」吸収（T1）/ サイクル定義の参照先張り替え（T3）/ 昇格 5→3 ステップ（T10）/ 未決事項起票の採番参照化（T11） |
| `CONTRIBUTING.md` | 「ADRを記録するとき」判定基準・記述規律の参照化（T1）/ 過剰適合節へ被参照注記（T7） |
| `CLAUDE.md` | A-04 即時記録・A-05 意思決定の記録（T2）/ A-08 不可逆操作・A-14 retrospective・A-06 feature-block-design（T5）/ A-15 ドキュメント運用（T6） |
| `skills/start-work/SKILL.md` | 冒頭ブロック・B-12・B-13（T2）/ 提示規則 4 削除・規則 2/3 修正・B-20 参照化（T3）/ B-15・B-18 手順 3（T4）/ 提示規則 intro へ H-01 固有条項吸収（T8） |
| `skills/session-handoff/SKILL.md` | 「本サイクル」定義の独立節新設・finalize 手順 4 参照化（T3）/ update 手順 10→5・「update 手順 9」参照 2 箇所の番号非依存化（T9） |
| `skills/worklog-record/SKILL.md` | F-03 の 1 行参照化（T3） |
| `docs/overview/folder-structure.md` | 節 7「仕様書の運用規約」新設・節番号繰り上がり・J-18 目的宣言・関連 ADR 行追加（T6） |
| `skills/extend-guidelines/SKILL.md` | 手順 5 の配線化（T7） |
| `skills/pre-finalization-review/SKILL.md` | H-01「いつ使うか」・frontmatter description（T8） |
| `README.md` | pre-finalization-review 説明行の同期（T8） |
| `skills/retrospective/SKILL.md` | Phase 2 起票サブ手順の参照化（T11） |
| `docs/overview/issue-management.md` | 冒頭参照契約へ「起票・採番」追加（T11） |
| `docs/records/decisions/`（21 ファイル） | 部分修正注記（T12） |
| `.claude-plugin/plugin.json` / `.claude-plugin/marketplace.json` | version 0.1.7 → 0.1.8（T13） |
| `docs/current/specs/`（判明済み 10 エントリの該当分） | 逐語複写の追従（T14。整合検査観点 1 で判定） |
| `docs/working/issues/`（0093 / 0094 / 0060） | close 処理（T15） |
| `dist/` / `template/` | 生成器による再生成（各タスクのコミットに同梱） |

## plan 作成時に確定した事項（ADR-0105 が plan へ委ねた 2 走査の結果）

### (A) 部分修正注記の対象 ADR（全数走査の確定結果）

台帳の導入 ADR 欄 union 36 本＋(ii) 付随編集の導入元＋(iii) 追従編集の導入元を走査した。**注記対象は次の 21 本**（すべて Accepted であることを T12 で確認する）:

0005, 0006, 0019, 0028, 0030, 0031, 0032, 0041, 0047, 0057, 0058, 0060, 0068, 0072, 0079, 0080, 0087, 0091, 0092, 0096, 0102

残余の非該当判定（plan 作成時に実施済み）:

- **ADR-0011**（I-17 の導入 ADR 欄）: Decision が名指しするのは振り返り出力ファイルの配置・粒度・編集ポリシー・インデックスであり、本サイクルの I-17 変更（起票サブ手順の参照化）はこれらを変更しない（保存・README 行追加は維持）→ 非該当
- **ADR-0056**（同上）: Decision が名指しするのは worklog 総ざらい（Phase 3）・単一形式・振り分け規則で、本サイクルで不変 → 非該当
- **ADR-0004 / 0040 / 0066 / 0071 / 0074 / 0075 / 0077 / 0086 / 0094**: 覆し行（C-07 / C-14 / J-09 / E-07 / C-04 / B-05 / B-11 = 現状維持）のみに由来 → 非該当（ADR-0105 の規定）
- **ADR-0059**: Decision が記載箇所を名指ししない → 非該当（ADR-0105 判定済み）
- **ADR-0098**（(ii) 付随編集の導入元として走査で浮上）: T6・T7・T11 が編集・新設する被参照注記・参照契約の列挙は同 ADR 由来だが、変更は「列挙への追加・注記の新設」であり削除・移設・参照化・束ね直しに当たらない（同 ADR の Decision はファイル・節を名指ししない一般則のみ）→ 非該当
- ADR-0007 / 0008 / 0009 / 0010 / 0021 / 0025 / 0026: 非該当（ADR-0105 判定済み。ADR-0008 は folder-structure 関連 ADR 行で到達経路を維持 = T6）

### (B) 台帳非掲載複写の掃き出し（14 系統の逐語 grep の確定結果）

2026-08-17 に全リポジトリ（`dist/`・`template/` 除外）で 14 系統の逐語 grep を実施した。結果:

- **配布対象ソース内の複写**: start-work 冒頭ブロック（T2 で処置）、pre-finalization-review frontmatter description（T8）、README.md スキル一覧行（T8）のみ。新規検出なし
- **旧 spec の逐語複写**: 判明済み 10 エントリの範囲に収まる（新規の spec ファイル検出なし）。追従は T14（整合検査観点 1）で判定・実施
- **open 課題内の帰属つき引用**: `docs/working/issues/flow/0052-...md`（A-14 引用）・`docs/working/issues/flow/0082-...md`（スナップショット規約引用）・`docs/working/issues/system/0055-...md`（スナップショット規約を CLAUDE.md 帰属で引用）の 3 件 → T14 で個別判定（既定: 記述は残し、出所の名指しのみ現状に合わせて更新）。このほか出所名指しの無い逐語引用 `docs/working/issues/system/0008-...md` は更新不要の判定のみ記録する。closed 課題（`flow/0074` 等）は確定済みの記録に準じて追従しない（帰属つき名指しの陳腐化は許容。安定識別子で辿れるため）
- `docs/working/plans/` 配下の旧 plan・`docs/records/`（監査台帳・retrospective・確定済み ADR）・handoff 内の消化記録実データ: 遡及同期しない / 確定後不変のため対象外
- `docs/working/issues/README.md` 冒頭の採番規則 1 行: issue-management 節 10 が「採番規則を冒頭に明記する」と定める公認の記載のため対象外
- Issue-0099 への「同旨 2 箇所（判定側・記録側）併存」の併記: **既に記載済み**（起票時に反映済みであることを確認した）→ 追記不要

---

### Task 1: K2/E-09 — ADR 判定基準・記述規律を decision-log へ一本化

**Files:**
- Modify: `skills/decision-log/SKILL.md`（強トリガー 5）
- Modify: `CONTRIBUTING.md`（「シナリオ: ADRを記録するとき」の判定基準・記述規律）

- [ ] **Step 1-1: decision-log 強トリガー 5 へ「削除」を吸収する**（E-09 側にのみあった条件の先行吸収）

old_string:
```
5. **ガイドライン・ルールの追加・変更**
```
new_string:
```
5. **ガイドライン・ルールの追加・変更・削除**
```

- [ ] **Step 1-2: CONTRIBUTING 判定基準を D-01 への参照にする**

old_string:
```
### 判定基準

以下のいずれかに該当する場合、ADRを作成する:

- 原則の追加・変更・削除
- アーキテクチャ（層構成）に影響する変更
- 既存の方針を覆す判断をしたとき
- 複数の選択肢を検討し、選択理由を残す価値があるとき
```
new_string:
```
### 判定基準

ADR を作成するかどうかは `decision-log` スキルの検出トリガー一覧（強トリガー・弱トリガー・呼ぶ必要がない場面）で判定する。ガイドライン・ルール（原則を含む）の追加・変更・削除は強トリガーに含まれる。
```

- [ ] **Step 1-3: CONTRIBUTING 記述規律を参照化する**（台帳監査節は無変更で維持）

old_string:
```
### 記述規律（ADR-0019）

- ADRには「下した決定」のみを記載する。仕様検討の途中で生じた**未解決の論点（未決事項）は ADR に書かない**。未決事項は次のシナリオに従って課題（`docs/working/issues/`）に分離する。
- ADRは**原則 Proposed で作成し、決定が確定したチェックポイントで Accepted に昇格**させる（brainstorming起点なら設計承認時、実装を伴うなら実装完了後）。作成直後の即 Accepted 化はしない。
- 撤去基準・発動条件・適用条件などの判定条件は、実行主体であるエージェントが**観測・実行できる事実**で書く。エージェントが判定できない条件は「ユーザーが判断し指示した時点」のように判断主体をユーザーへ明示的に移す（ADR-0032）。
- spec を作らない拡張（規範・手順・観点の追加または強化）の ADR には、末尾に独立節「## 過剰適合点検（ADR-0079）」として点検ブロックを含める（「下した決定」ではない付随記録の例外配置。Context / Consequences には書かない）。
- 規範・手順・観点の新設を含む ADR の記載要件（比較・期待検出量・退役条件）は「全シナリオ共通: 新設の評価可能性」に従う（ADR-0102。退役条件について判断主体の移譲のみの記載を認めない点は、判定条件の実行可能性に関する上記の一般則〈ADR-0032〉に対する特則）。
```
new_string:
```
### 記述規律（ADR-0019）

- ADR の記述規律（「下した決定」のみの記載と未決事項の課題分離・原則 Proposed 起票と確定チェックポイントでの昇格・判定条件の実行可能性）は `decision-log` スキルの各注記（ADR-0019 / ADR-0032）が正である。
- spec を作らない拡張（規範・手順・観点の追加または強化）の ADR に点検ブロックを独立節として含める義務・配置は「全シナリオ共通: 過剰適合の点検」の記録義務に従う。
- 規範・手順・観点の新設を含む ADR の記載要件（比較・期待検出量・退役条件）は「全シナリオ共通: 新設の評価可能性」に従う（ADR-0102。退役条件について判断主体の移譲のみの記載を認めない点は、判定条件の実行可能性に関する一般則〈ADR-0032〉に対する特則）。
```

- [ ] **Step 1-3b: CONTRIBUTING「過剰適合の点検」記録義務内の強トリガー名の引用を改名へ追従させる**（Step 1-1 の改名の引用整合）

old_string:
```
`decision-log` の強トリガー（ガイドライン・ルールの追加・変更）により ADR が必ず存在する
```
new_string:
```
`decision-log` の強トリガー（ガイドライン・ルールの追加・変更・削除）により ADR が必ず存在する
```

- [ ] **Step 1-4: 検証**

```powershell
(Select-String -Path skills/decision-log/SKILL.md -Pattern 'ガイドライン・ルールの追加・変更・削除').Count   # 期待: 1
(Select-String -Path CONTRIBUTING.md -Pattern 'ガイドライン・ルールの追加・変更・削除').Count                  # 期待: 1（記録義務内の引用）
(Select-String -Path CONTRIBUTING.md -Pattern '原則の追加・変更・削除').Count                                  # 期待: 0
(Select-String -Path CONTRIBUTING.md -Pattern '検出トリガー一覧').Count                                        # 期待: 1
```

- [ ] **Step 1-5: 生成器＋コミット**

```powershell
./scripts/build-dist.ps1; ./scripts/build-dist.ps1 -Check; ./scripts/sync-template.ps1 -Check
# dist/skills/decision-log/SKILL.md の変更箇所を 5 点目視
git add skills/decision-log/SKILL.md CONTRIBUTING.md dist/
git commit -m "feat: K2/E-09 - ADR 判定基準・記述規律を decision-log へ一本化（強トリガーへ削除を吸収。ADR-0105）"
```

### Task 2: K2/K6 — CLAUDE.md A-04/A-05 と start-work 冒頭・B-12・B-13 の配線化

**Files:**
- Modify: `CLAUDE.md`（「意思決定の即時記録（継続適用）」「意思決定の記録」）
- Modify: `skills/start-work/SKILL.md`（冒頭ブロック・Post 項目 1）

- [ ] **Step 2-1: CLAUDE.md A-04（即時記録節）のトリガー定義列挙を参照化する**（節見出しと EXTREMELY-IMPORTANT タグは維持）

old_string:
```
実行中のスキル・タスクに関わらず、以下を検出した瞬間に `decision-log` スキルを呼んでADRドラフトを作成すること:

- 複数の選択肢を比較して1つを選んだ
- 当初の方針を変更した
- スコープ・優先度を判断した
- アーキテクチャや構造に影響する決定をした

「スキルの途中だから後で」は禁止。検出 → 即ドラフト作成 → ユーザー承認 → 元のスキルへ復帰。ただしドラフトのコミットは、関連論点が収束したチェックポイントまで遅延してよい（収束までドラフトは書き直し自由。`decision-log` スキルの手順に従う）。
```
new_string:
```
実行中のスキル・タスクに関わらず、意思決定（複数案からの選択、方針の変更、スコープ・優先度の判断、アーキテクチャや構造に影響する決定など）を検出した瞬間に `decision-log` スキルを呼んでADRドラフトを作成すること。検出トリガーの定義一覧は `decision-log` スキルが正である。

「スキルの途中だから後で」は禁止。検出 → 即ドラフト作成 → ユーザー承認 → 元のスキルへ復帰。ドラフトのコミットのタイミング（関連論点が収束したチェックポイントまでの遅延を含む）は `decision-log` スキルの手順に従うこと。
```

- [ ] **Step 2-2: CLAUDE.md A-05（意思決定の記録）を非重複 2 箇条＋参照 1 行にする**

old_string:
```
- 設計判断を行った場合、その理由をコミットメッセージまたはコード内コメントに残すこと
- 新規ファイルや重要な変更には、変更理由を明記すること
- ADR作成のトリガーは「システム設定 / 意思決定の即時記録（継続適用）」を参照すること
- ADRには「下した決定」のみを記載すること。未解決の論点（未決事項）は ADR に書かず、課題（`docs/working/issues/`）として起票すること
- ADRは原則 Proposed で作成し、決定が確定したチェックポイント（brainstorming起点なら設計承認時、実装を伴うなら実装完了後）で Accepted に昇格させること。作成直後の即 Accepted 化はしないこと
```
new_string:
```
- 設計判断を行った場合、その理由をコミットメッセージまたはコード内コメントに残すこと
- 新規ファイルや重要な変更には、変更理由を明記すること
- ADR 作成のトリガーは「システム設定 / 意思決定の即時記録（継続適用）」を、記述規律（未決事項の課題分離を含む）とステータス運用（Proposed 起票・確定チェックポイントでの昇格）は `decision-log` スキルを正とすること
```

- [ ] **Step 2-3: start-work 冒頭の継続的 ADR 検出ルール引用ブロックを短い参照にする**（台帳非掲載複写の処置）

old_string:
```
このスキルから始まる全ての作業期間中、以下のルールが常時適用される（`CLAUDE.md` でも宣言されている）:

> 実行中のスキル・タスクに関わらず、以下を検出した瞬間に `decision-log` スキルを呼んでADRドラフトを作成すること:
>
> - 複数の選択肢を比較して1つを選んだ
> - 当初の方針を変更した
> - スコープ・優先度を判断した
> - アーキテクチャや構造に影響する決定をした
>
> 「スキルの途中だから後で」は禁止。検出 → 即ドラフト作成 → ユーザー承認 → 元のスキルへ復帰。ただしドラフトのコミットは、関連論点が収束したチェックポイントまで遅延してよい（収束までドラフトは書き直し自由。`decision-log` スキルの手順に従う）。
```
new_string:
```
このスキルから始まる全ての作業期間中、意思決定を検出した瞬間に `decision-log` スキルを呼んで ADR ドラフトを作成する継続ルールが常時適用される（`CLAUDE.md` でも宣言されている）。「スキルの途中だから後で」は禁止。検出トリガーの定義一覧とドラフトのコミットのタイミングは `decision-log` スキルが正である。
```

- [ ] **Step 2-4: start-work B-12（Post 項目 1 のトリガー列挙）を参照化する**（spec 確定点 (c) 段落は無変更で維持）

old_string:
```
1. **ADR候補検出**: 実行中に行われた意思決定が以下のいずれかに該当するか自己評価する:
   - 複数の選択肢を比較して1つを選んだ
   - 当初の方針を変更した
   - スコープ・優先度を判断した
   - アーキテクチャや構造に影響する決定をした

   該当すれば `decision-log` スキルを呼ぶ（実行中に既に作成済みのものは除く）。
```
new_string:
```
1. **ADR候補検出**: 実行中に行われた意思決定が `decision-log` の検出トリガー一覧に該当するか自己評価し、該当すれば `decision-log` スキルを呼ぶ（実行中に既に作成済みのものは除く。トリガーの定義は同スキルが正）。
```

- [ ] **Step 2-5: start-work B-13（Post 項目 1 後段の昇格処理）を参照化する**（K6）

old_string:
```
   また、設計承認・実装完了などのチェックポイントを通過した場合、Proposed のまま据え置かれているADRのうち決定が確定したものを Accepted へ昇格させ、議論の結果不採用が確定したものを Rejected へ更新する（`decision-log` の「承認の昇格」「ステータス変更」に従う。ADR-0041）。昇格の手順にはサイクル全体整合検査・粒度の点検を含む点検工程が含まれる（点検の規範は `decision-log` の「承認の昇格」「サイクル全体整合検査」側にあり、ここには重複して書かない。ADR-0059 / ADR-0060 / ADR-0092）。あわせて、未コミットの ADR ドラフトのうち関連論点が収束したものをコミットする（ADR-0030）。
```
new_string:
```
   また、設計承認・実装完了などのチェックポイントを通過した場合、Proposed のまま据え置かれている ADR のうち決定が確定したものの Accepted 昇格、不採用が確定したものの Rejected 更新、未コミットドラフトのうち関連論点が収束したもののコミットを行う（ADR-0041 / ADR-0030）。手順は `decision-log` の「承認の昇格」（サイクル全体整合検査・粒度の点検を含む）「ステータス変更」「コミットのタイミング」が正であり、ここには重複して書かない（ADR-0059 / ADR-0060 / ADR-0092）。
```

- [ ] **Step 2-6: 検証**

```powershell
(Select-String -Path CLAUDE.md,skills/start-work/SKILL.md -Pattern '複数の選択肢を比較して1つを選んだ').Count  # 期待: 0
(Select-String -Path skills/decision-log/SKILL.md -Pattern '2つ以上の選択肢を比較し1つを選んだとき').Count      # 期待: 1（定義は統合先に実在）
(Select-String -Path CLAUDE.md -Pattern '作成直後の即 Accepted 化').Count                                       # 期待: 0
```

- [ ] **Step 2-7: 生成器＋コミット**

```powershell
./scripts/build-dist.ps1; ./scripts/sync-template.ps1; ./scripts/build-dist.ps1 -Check; ./scripts/sync-template.ps1 -Check
# dist/skills/start-work/SKILL.md と template/CLAUDE.md の変更箇所を 5 点目視
git add CLAUDE.md skills/start-work/SKILL.md dist/ template/
git commit -m "feat: K2/K6 - CLAUDE.md と start-work の ADR トリガー・昇格処理を decision-log への配線に置換（ADR-0105）"
```

### Task 3: K1＋固有条件移設 — 消化記録の参照化と「本サイクル」定義の移設

**Files:**
- Modify: `skills/session-handoff/SKILL.md`（独立節新設・finalize 手順 4）
- Modify: `skills/start-work/SKILL.md`（提示規則 2/3/4）
- Modify: `skills/decision-log/SKILL.md`（サイクルの定義）
- Modify: `skills/worklog-record/SKILL.md`（F-03）

- [ ] **Step 3-1: session-handoff へ「本サイクル」の定義を独立節（`##`）として新設する**（「独立手順「移設」」節の直前。コードフェンス外）

old_string:
```
## 独立手順「移設」（ADR-0086）
```
new_string:
```
## 「本サイクル」の定義

「本サイクル」とは、前回 cycle-reset から次の cycle-reset までの作業単位を指す（ADR-0087）。本スキルのほか `start-work`（確定前レビューの提示規則）と `decision-log`（サイクル全体整合検査）がこの定義を参照する（各所で再定義しない）。

## 独立手順「移設」（ADR-0086）
```

- [ ] **Step 3-2: session-handoff finalize 手順 4 のインライン定義を参照化する**

old_string:
```
**ただし本サイクル（＝前回 cycle-reset から次の cycle-reset までの作業単位）の `review=` または `cyclecheck=` を含む行は、過去セッションのものでも残す**
```
new_string:
```
**ただし本サイクル（定義は「「本サイクル」の定義」節）の `review=` または `cyclecheck=` を含む行は、過去セッションのものでも残す**
```

- [ ] **Step 3-3: start-work 提示規則 4（判定材料の記録）を削除する**（B-10。記録先・記録内容は session-handoff が正）

old_string:
```
**4. 判定材料の記録**

確定点を通過したら、提示結果（フル実施 / 差分再確認 / 見送り / 非発火＝推奨判定が偽）を `session-handoff` update が「Post ラッパー消化記録」の当該マイルストーン行へ併記する。記録が確認できない場合は**未レビューとみなす**（安全側へ倒れる）。「本サイクル」とは前回 cycle-reset から次の cycle-reset までの作業単位を指す。

### 横断的ラッパー（全スキル実行の前後で適用）
```
new_string:
```
### 横断的ラッパー（全スキル実行の前後で適用）
```

- [ ] **Step 3-4: start-work 規則 2 の但し書きへ判定側 1 行を残置する**（固有条件の残置。「上流の spec が…」の但し書きの直後に挿入）

old_string:
```
- 上流の spec がその確定時点で独立レビューを受けている場合、そこから写像された内容はレビュー済みとして扱う（サイクル・セッションを跨いでよい）
- 判定に迷う場合は「未レビューの規範内容を含む」側（フル推奨）へ倒す
```
new_string:
```
- 上流の spec がその確定時点で独立レビューを受けている場合、そこから写像された内容はレビュー済みとして扱う（サイクル・セッションを跨いでよい）
- 過去の確定点でのレビュー実施・見送りは handoff の「Post ラッパー消化記録」で確認する。記録が確認できない場合は**未レビューとみなす**（安全側へ倒れる。記録の経路・形式は `session-handoff` update が正）
- 判定に迷う場合は「未レビューの規範内容を含む」側（フル推奨）へ倒す
```

- [ ] **Step 3-5: start-work 規則 3 へ「本サイクル」定義の参照を追加する**

old_string:
```
推奨判定が真になったサイクルの各確定点では、「本サイクルで何がレビュー済みで、この成果物の何が未レビューか」を提示に含める（実施判断はユーザーに残るため、その判断材料を供給する）。
```
new_string:
```
推奨判定が真になったサイクルの各確定点では、「本サイクルで何がレビュー済みで、この成果物の何が未レビューか」を提示に含める（実施判断はユーザーに残るため、その判断材料を供給する。「本サイクル」の定義は `session-handoff` スキルの「「本サイクル」の定義」節を参照）。
```

- [ ] **Step 3-6: decision-log「サイクルの定義」の参照先を張り替える**

old_string:
```
**サイクルの定義**: `start-work`「確定前レビューの提示規則」にある「本サイクル」の既存定義に従う。ここでは再定義しない。
```
new_string:
```
**サイクルの定義**: `session-handoff` スキルの「「本サイクル」の定義」節に従う。ここでは再定義しない。
```

- [ ] **Step 3-7: worklog-record F-03 を 1 行参照にする**

old_string:
```
発火結果（記録したエントリ id、または記録ゲートによる棄却の旨）は、handoff の「Post ラッパー消化記録」へ1行残す（ADR-0057。棄却を明示しない限り未発火と外形的に区別できないため、棄却時も記載する）。
```
new_string:
```
発火結果（記録したエントリ id、または記録ゲートによる棄却の旨）は、handoff の「Post ラッパー消化記録」へ1行残す（ADR-0057。記載の形式と棄却時の記載義務は `session-handoff` update の消化記録手順が正）。
```

- [ ] **Step 3-8: B-20（Post 前文）の記録対象・形式を参照化する**（ADR-0105 K1「記録の形式・内容を参照化」。現行の inline 列挙は統合先が持つ `cyclecheck=` を欠く片側乖離が実在するため、列挙ごと参照化して乖離を解消する。「1 つずつ明示的に消し込む」「項目 2 は項目 3 の免除にならない」は維持）

old_string:
```
以下の項目を**1つずつ明示的に消し込む**（ADR-0057）。項目1と3の判定結果と、確定点（Phase 2「確定前レビューの提示規則」）を通過した場合の確定前レビュー提示結果は、`session-handoff` update が handoff の「Post ラッパー消化記録」へ1行で残す（形式は session-handoff スキル参照）。ハンドオフ更新（項目2）の完了は worklog-record（項目3）の免除にならない。
```
new_string:
```
以下の項目を**1つずつ明示的に消し込む**（ADR-0057）。消し込みの結果は `session-handoff` update が handoff の「Post ラッパー消化記録」へ1行で残す（記録対象・形式・値の定義は session-handoff スキルが正）。ハンドオフ更新（項目2）の完了は worklog-record（項目3）の免除にならない。
```

- [ ] **Step 3-9: 検証**

```powershell
(Select-String -Path skills/start-work/SKILL.md -Pattern '前回 cycle-reset から次の cycle-reset').Count   # 期待: 0
(Select-String -Path skills/session-handoff/SKILL.md -Pattern '前回 cycle-reset から次の cycle-reset').Count  # 期待: 1（新設節のみ）
(Select-String -Path skills/start-work/SKILL.md -Pattern '判定材料の記録').Count                          # 期待: 0
(Select-String -Path skills/start-work/SKILL.md -Pattern '未レビューとみなす').Count                       # 期待: 1（規則 2 但し書き）
(Select-String -Path skills/start-work/SKILL.md -Pattern '形式は session-handoff スキル参照').Count        # 期待: 0（B-20 参照化済み）
(Select-String -Path skills/decision-log/SKILL.md -Pattern '「本サイクル」の定義').Count                   # 期待: 1
```

- [ ] **Step 3-10: 生成器＋コミット**

```powershell
./scripts/build-dist.ps1; ./scripts/build-dist.ps1 -Check; ./scripts/sync-template.ps1 -Check
# dist/skills/{start-work,session-handoff,decision-log,worklog-record}/SKILL.md の変更箇所を 5 点目視
git add skills/start-work/SKILL.md skills/session-handoff/SKILL.md skills/decision-log/SKILL.md skills/worklog-record/SKILL.md dist/
git commit -m "feat: K1 - 消化記録の参照化と「本サイクル」定義の session-handoff への移設（ADR-0105）"
```

### Task 4: K8 — worklog 配線の参照化（B-15・B-18 手順 3）

**Files:**
- Modify: `skills/start-work/SKILL.md`

- [ ] **Step 4-1: B-15（Post 項目 3）を参照化する**

old_string:
```
3. **作業記録の追記**: マイルストーン到達時、`worklog-record` スキルを呼ぶ。worklog-record が記録ゲート（既存スキルで実施済みでない かつ AI 自律で毎回再現できない＝delta が存在する）を自己判定し、満たさなければ記録しない。session-handoff update と同じ契機（スキル完了 / plan の1タスク完了 / 重要な分岐通過）で発火する（ADR-0047）。記録した場合はエントリ id を、記録ゲートで棄却した場合は棄却の旨を「Post ラッパー消化記録」へ書く（未発火と棄却を外形的に区別するため。ADR-0057）
```
new_string:
```
3. **作業記録の追記**: マイルストーン到達時、`worklog-record` スキルを呼ぶ。マイルストーン契機・記録ゲートの判定・発火結果の「Post ラッパー消化記録」への記載は同スキルが正である（ADR-0047 / ADR-0057）
```

- [ ] **Step 4-2: B-18 手順 3（セッション終了処理）を同じ参照形へ揃える**（付随編集）

old_string:
```
3. `worklog-record` を呼ぶ（ADR-0058）。セッション切り替え直前は節目かどうかを問わず発火契機となる（切り替え後は delta を保持する文脈が失われるため、ここが記録の最終機会）。記録ゲートの判定は通常どおり行い、結果を「Post ラッパー消化記録」へ書く
```
new_string:
```
3. `worklog-record` を呼ぶ（ADR-0058）。セッション切り替え直前の発火契機（節目かどうかを問わない）・記録ゲートの判定・発火結果の「Post ラッパー消化記録」への記載は同スキルが正である
```

- [ ] **Step 4-3: 検証**

```powershell
(Select-String -Path skills/start-work/SKILL.md -Pattern '既存スキルで実施済みでない').Count   # 期待: 0
(Select-String -Path skills/worklog-record/SKILL.md -Pattern '既存スキルで実施済みでない').Count  # 期待: 1（frontmatter。記録ゲート節本体は「既存スキル・原則・CLAUDE.md で既に実施している」の表現で定義が実在）
```

- [ ] **Step 4-4: 生成器＋コミット**

```powershell
./scripts/build-dist.ps1; ./scripts/build-dist.ps1 -Check; ./scripts/sync-template.ps1 -Check
git add skills/start-work/SKILL.md dist/
git commit -m "feat: K8 - start-work の worklog 配線を worklog-record への参照に統一（ADR-0105）"
```

### Task 5: K5/K7/K18 — CLAUDE.md 単独 3 箇条の配線化

**Files:**
- Modify: `CLAUDE.md`（不可逆操作・検証第 5 箇条・タスク構造末尾箇条）

- [ ] **Step 5-1: A-08（不可逆操作）— 段階名と対応の 1 行を残し、該当条件の定義をスキルへ**

old_string:
```
- ファイルの削除、外部サービスへの書き込み、デプロイなど不可逆操作の前にユーザーに確認を取ること
  - 低リスク（可逆操作、定型作業）: 確認不要
  - 中リスク（複数ファイルの変更、外部サービスへの読み取り）: サマリーを表示
  - 高リスク（データ削除、デプロイ、外部書き込み、不可逆な設定変更）: 承認必須
- 実行不能な状況に陥った場合、無理に続行せず状況を報告すること
```
new_string:
```
- ファイルの削除、外部サービスへの書き込み、デプロイなど不可逆操作の前にユーザーに確認を取ること。確認の粒度は「低リスク=確認不要 / 中リスク=サマリー表示 / 高リスク=承認必須」とし、各リスク段階の該当条件の定義は `pre-action-review` スキルを正とすること
- 実行不能な状況に陥った場合、無理に続行せず状況を報告すること
```

- [ ] **Step 5-2: A-14（検証第 5 箇条）— 起動義務の 1 行＋詳細参照**（調停注記: 起動を課すのは本箇条＝運用規範、スキル側の「手動トリガーのみ」は自動起動機構の不在で矛盾しない）

old_string:
```
- サブプロジェクトを master へマージした直後に `retrospective` スキルを起動し、フロー・ガイドライン自体の振り返りを実施すること（`docs/records/retrospectives/system/YYYY-MM-DD-<topic>.md` と、開発フロー課題は `docs/records/retrospectives/flow/YYYY-MM-DD-<topic>.md`）。振り返りは課題の抽出と分類までにとどめ、対策の採否・設計・ADR化は行わない。ユーザーが対策を要すると判断した時点で次サイクルで着手する
```
new_string:
```
- サブプロジェクトを master へマージした直後に `retrospective` スキルを起動すること（起動を課すのはこの箇条であり、スキル側に自動起動機構はない）。振り返りのスコープ・出力先・課題分類・対策着手の判断は同スキルを正とすること
```

- [ ] **Step 5-3: A-06（タスク構造末尾箇条）— しきい値の定義をスキルへ（義務動詞は保持）**

old_string:
```
- 中規模以上のシステム（主要機能が2つ以上、または想定モジュール/コンポーネントが3つ以上）を設計する際は、brainstorming と writing-plans の間に `feature-block-design` スキルを使うこと
```
new_string:
```
- システムを設計する際は、brainstorming と writing-plans の間に `feature-block-design` の適用要否判定を通し、該当した場合に同スキルを適用すること（適用しきい値の定義は同スキルが正）
```

- [ ] **Step 5-4: 検証**（統合先の定義の実在確認を含む）

```powershell
(Select-String -Path CLAUDE.md -Pattern '主要機能が2つ以上').Count                       # 期待: 0
(Select-String -Path CLAUDE.md -Pattern '低リスク（可逆操作').Count                       # 期待: 0
(Select-String -Path skills/pre-action-review/SKILL.md -Pattern '低リスク|中リスク|高リスク').Count  # 期待: 4 以上（定義の実在）
(Select-String -Path skills/feature-block-design/SKILL.md -Pattern '適用要否判定（しきい値）').Count  # 期待: 1
```

- [ ] **Step 5-5: 生成器＋コミット**

```powershell
./scripts/sync-template.ps1; ./scripts/build-dist.ps1 -Check; ./scripts/sync-template.ps1 -Check
# template/CLAUDE.md の変更箇所を 5 点目視
git add CLAUDE.md template/
git commit -m "feat: K5/K7/K18 - CLAUDE.md の不可逆操作・retrospective 起動・feature-block-design 箇条を配線化（ADR-0105）"
```

### Task 6: K9 — 仕様書運用 4 箇条の folder-structure 移設

**Files:**
- Modify: `docs/overview/folder-structure.md`（新設節・節番号繰り上がり・目的宣言・関連 ADR）
- Modify: `CLAUDE.md`（ドキュメント運用）

- [ ] **Step 6-1: folder-structure の目的宣言（J-18）を更新する**（「唯一」は配置判断側に限定して保持）

old_string:
```
プロジェクトで発生する情報・ドキュメントを「どこに置くか」の判断基準を定義する。本文書は情報分類と配置判断の唯一の参照元であり、プロジェクト参画直後に読むべき文書として `docs/overview/` に置かれている（課題（issue）の運用詳細は `docs/overview/issue-management.md` が正）。
```
new_string:
```
プロジェクトで発生する情報・ドキュメントを「どこに置くか」の判断基準を定義する。本文書は情報分類と配置判断の唯一の参照元であり、あわせて文書運用規約（仕様書の運用）を定める。プロジェクト参画直後に読むべき文書として `docs/overview/` に置かれている（課題（issue）の運用詳細は `docs/overview/issue-management.md` が正）。
```

- [ ] **Step 6-2: 節 6（配置表）の直後に新設節「7. 仕様書の運用規約」を挿入し、旧節 7 を 8 へ繰り上げる**（4 箇条の条件節はそのまま移す。無条件化しない）

old_string:
```
## 7. 課題（issue）管理
```
new_string:
```
## 7. 仕様書の運用規約

本節は `CLAUDE.md`（ドキュメント運用）から参照される。

- 仕様書は、それを読むだけで現時点のシステム全容が分かるスナップショットとして維持すること
- 既存仕様書を改修する場合は、変更差分のみの別ファイルを作らず、既存仕様書を**書き換えで更新**すること
- 「なぜ変更したか」は ADR に記録し、仕様書には「今どうなっているか」のみを書くこと
- 中規模以上のシステムでは、仕様書は `docs/current/specs/YYYY-MM-DD-<topic>/` 配下にディレクトリ分割形式（`00-overview.md` + `NN-<block>.md`）で配置すること

## 8. 課題（issue）管理
```

- [ ] **Step 6-3: 残りの節番号を繰り上げる**（4 見出し。各 1 箇所ずつ Edit。old/new はいずれも見出し行全体で一意）

1. old_string `## 8. 運用例: チーム開発での大規模リファクタリング` → new_string `## 9. 運用例: チーム開発での大規模リファクタリング`
2. old_string `## 9. コード領域の配置原則` → new_string `## 10. コード領域の配置原則`
3. old_string `## 10. inbox` → new_string `## 11. inbox`
4. old_string `## 11. 関連 ADR` → new_string `## 12. 関連 ADR`

- [ ] **Step 6-4: 同一ファイル内の節番号参照 1 箇所を追従させる**（節 5 運用規約の箇条）

old_string:
```
- **コードを docs/ に置かない** — コード領域との分離は「9. コード領域の配置原則」を参照
```
new_string:
```
- **コードを docs/ に置かない** — コード領域との分離は「10. コード領域の配置原則」を参照
```

- [ ] **Step 6-5: 関連 ADR 節へ ADR-0008 の行を追記する**（移設 4 箇条の導入元。到達経路の維持。注: 出所リスト行のため template では見出しごと除去される仕様どおりの挙動であり、到達経路の維持は配信元リポジトリ内に限られる——既存の関連 ADR 節と同じ扱い）

old_string:
```
- ADR-0025: 情報の5分類体系の導入
```
new_string:
```
- ADR-0008: 仕様書のディレクトリ分割形式とスナップショット規約（「7. 仕様書の運用規約」の 4 箇条の導入元）
- ADR-0025: 情報の5分類体系の導入
```

- [ ] **Step 6-6: CLAUDE.md ドキュメント運用を配線 1 行＋inbox 1 行＋plans 優先則にする**（plans 優先則は CLAUDE.md に残す＝統合先案の部分的な覆し。ADR-0105）

old_string:
```
- ドキュメントの配置は `docs/overview/folder-structure.md` の情報分類体系（5分類）と配置判断基準に従うこと
- 配置に迷った情報は `docs/inbox/` に置き、`organize-inbox` スキルで整理すること
- 仕様書は、それを読むだけで現時点のシステム全容が分かるスナップショットとして維持すること
- 既存仕様書を改修する場合は、変更差分のみの別ファイルを作らず、既存仕様書を**書き換えで更新**すること
- 「なぜ変更したか」は ADR に記録し、仕様書には「今どうなっているか」のみを書くこと
- 中規模以上のシステムでは、仕様書は `docs/current/specs/YYYY-MM-DD-<topic>/` 配下にディレクトリ分割形式（`00-overview.md` + `NN-<block>.md`）で配置すること
- 実装計画は `docs/working/plans/` に配置すること（利用スキルのデフォルト出力先が異なる場合もこちらを優先する）
```
new_string:
```
- ドキュメントの配置と文書運用（仕様書のスナップショット運用を含む）は `docs/overview/folder-structure.md` の情報分類体系（5分類）・配置判断基準・仕様書の運用規約に従うこと
- 配置に迷った情報は `docs/inbox/` に置き、`organize-inbox` スキルで整理すること
- 実装計画は `docs/working/plans/` に配置すること（利用スキルのデフォルト出力先が異なる場合もこちらを優先する）
```

- [ ] **Step 6-7: 検証**

```powershell
(Select-String -Path CLAUDE.md -Pattern 'スナップショットとして維持').Count               # 期待: 0
(Select-String -Path docs/overview/folder-structure.md -Pattern 'スナップショットとして維持').Count  # 期待: 1
(Select-String -Path docs/overview/folder-structure.md -Pattern '^## ').Count             # 期待: 12（1〜12 の連番を目視確認）
(Select-String -Path docs/overview/folder-structure.md -Pattern '「10. コード領域の配置原則」').Count  # 期待: 1
(Select-String -Path CLAUDE.md -Pattern '仕様書のスナップショット運用を含む').Count        # 期待: 1
```

- [ ] **Step 6-8: 生成器＋コミット**

```powershell
./scripts/sync-template.ps1; ./scripts/build-dist.ps1 -Check; ./scripts/sync-template.ps1 -Check
# template/CLAUDE.md・template/docs/overview/folder-structure.md の変更箇所を 5 点目視
git add CLAUDE.md docs/overview/folder-structure.md template/
git commit -m "feat: K9 - 仕様書運用 4 箇条を folder-structure 新設節へ移設し CLAUDE.md を配線化（ADR-0105）"
```

### Task 7: K10 — 過剰適合点検の配線（I-03）と被参照注記

**Files:**
- Modify: `skills/extend-guidelines/SKILL.md`（手順 5）
- Modify: `CONTRIBUTING.md`（過剰適合節へ参照元注記）

- [ ] **Step 7-1: extend-guidelines 手順 5 を 1〜2 行配線にする**（CONTRIBUTING 不在時は手順 1 の中断規定が実質フォールバック）

old_string:
```
### 5. 確定前の過剰適合点検

設計承認の前に、CONTRIBUTING.md「全シナリオ共通: 過剰適合の点検」を実施し、点検結果の定型ブロックを spec（spec を作らない場合は ADR 末尾の独立節「## 過剰適合点検（ADR-0079）」）へ記録する。点検ブロックの無い拡張 spec / 拡張 ADR はコミットしないこと（ADR-0079）。新設（規範・手順・観点）を含む拡張では、CONTRIBUTING.md「全シナリオ共通: 新設の評価可能性」の記載要件もあわせて確認すること（ADR-0102）。
```
new_string:
```
### 5. 確定前の過剰適合点検

設計承認の前に、CONTRIBUTING.md の次の共通節（「全シナリオ共通: 過剰適合の点検」、新設を含む拡張では「全シナリオ共通: 新設の評価可能性」もあわせて）を実施・確認し、各節の記録義務・執行点に従って点検結果を記録すること（ADR-0079 / ADR-0102）。点検の観点・記録先・執行点の定義は CONTRIBUTING.md 側が正である。
```

- [ ] **Step 7-2: CONTRIBUTING「過剰適合の点検」節へ参照元を全列挙した注記を付ける**（配置は見出し直後とする——本節は小節が多く長いため契約を先頭で提示する。姉妹節「新設の評価可能性」の注記と場所は異なるが趣旨は同一。列挙には ADR-0105 の名指す 2 件に加え、実測で同節の再点検規定を参照している `decision-log` を含める——非網羅の列挙は ADR-0091 が是正した欠陥型のため）

old_string:
```
## 全シナリオ共通: 過剰適合の点検

### 背景
```
new_string:
```
## 全シナリオ共通: 過剰適合の点検

本節は `extend-guidelines`（手順 5）と `worklog-skillify`（是正パターンの提示）、および `decision-log`（サイクル全体整合検査の再点検規定）から参照される。

### 背景
```

- [ ] **Step 7-3: 検証**

```powershell
(Select-String -Path skills/extend-guidelines/SKILL.md -Pattern 'ADR 末尾の独立節').Count   # 期待: 0（記録先詳細は統合先が正）
(Select-String -Path CONTRIBUTING.md -Pattern '是正パターンの提示').Count  # 期待: 1（注記のみ。現状 0 件を実測済み——「是正パターン」節見出しはこの句を含まない）
```

- [ ] **Step 7-4: 生成器＋コミット**

```powershell
./scripts/build-dist.ps1; ./scripts/build-dist.ps1 -Check; ./scripts/sync-template.ps1 -Check
# dist/skills/extend-guidelines/SKILL.md の変更箇所を 5 点目視
git add skills/extend-guidelines/SKILL.md CONTRIBUTING.md dist/
git commit -m "feat: K10 - extend-guidelines 手順 5 を CONTRIBUTING 共通節への配線にし被参照注記を追加（ADR-0105）"
```

### Task 8: K12 — レビュー発動規則の正本一意化（H-01）＋frontmatter/README 同期

**Files:**
- Modify: `skills/start-work/SKILL.md`（提示規則 intro へ固有条項吸収）
- Modify: `skills/pre-finalization-review/SKILL.md`（いつ使うか・frontmatter description）
- Modify: `README.md`（スキル一覧の説明行）

- [ ] **Step 8-1: start-work 提示規則 intro へ「自動必須化はしない」を吸収する**（発動ゲートの意味を変えない: 提示は毎回・発動はユーザーのみ）

old_string:
```
確定前レビュー（`pre-finalization-review`）の提示は、以下の 2 種類の確定点——spec 確定点（到達経路により (a)〜(c) の 3 通り）と plan 確定点——で**毎回**行う（発動の判断はユーザーに残す。ADR-0072）。以下は提示内の**推奨順位**の規則である。
```
new_string:
```
確定前レビュー（`pre-finalization-review`）の提示は、以下の 2 種類の確定点——spec 確定点（到達経路により (a)〜(c) の 3 通り）と plan 確定点——で**毎回**行う（発動の判断はユーザーに残す。発動はユーザーの指示のみであり、規模・不可逆性による自動必須化はしない。ADR-0072）。以下は提示内の**推奨順位**の規則である。
```

- [ ] **Step 8-2: pre-finalization-review「いつ使うか」を配線化する**（発動主体の 1 行は直接呼び出し経路のため残す）

old_string:
```
## いつ使うか

- **発動はユーザーの指示のみ**（ADR-0072）。規模・不可逆性による自動必須化はしない
- ただし AI 側は、spec 確定点と plan 確定点で本スキルの実施を**毎回提示する**。発動の判断はユーザーに残るが、判断の機会を作る責務は AI 側にある（ADR-0072）
- **確定点の定義と推奨順位の規則の正本は `start-work` の「確定前レビューの提示規則」にある**（判定はそこで行われるため。ADR-0080）。本スキルは提示後の実施手順を担う
```
new_string:
```
## いつ使うか

- **発動はユーザーの指示のみ**（`start-work` を経由しない直接呼び出しでも同じ。ADR-0072）。発動・提示の規則（確定点の定義・毎回提示・推奨順位・自動必須化はしないこと）の正本は `start-work` の「確定前レビューの提示規則」にある（ADR-0080）
- 本スキルは提示後の実施手順を担う
```

- [ ] **Step 8-3: frontmatter description を本文と同期する**（台帳非掲載複写の処置）

old_string:
```
description: "計画・仕様など非コード成果物の確定前に、実証を課した独立レビューを実施するスキル。3 観点（敵対的・実装整合性・仕様適合）を独立サブエージェントへ委譲し、成果物中のコードはスクラッチで実際に実行させる。発動はユーザーが実施を指示したときのみ。spec 確定点と plan 確定点で start-work から毎回提示され、未レビューの規範・手順文書の変更を含む成果物では推奨側に置かれる。"
```
new_string:
```
description: "計画・仕様など非コード成果物の確定前に、実証を課した独立レビューを実施するスキル。3 観点（敵対的・実装整合性・仕様適合）を独立サブエージェントへ委譲し、成果物中のコードはスクラッチで実際に実行させる。発動はユーザーが実施を指示したときのみ。確定点での提示・推奨順位の規則は start-work の「確定前レビューの提示規則」が正。"
```

- [ ] **Step 8-4: README.md のスキル一覧行を同期する**（非配布の人間向け索引）

old_string:
```
| [`pre-finalization-review`](skills/pre-finalization-review/) | 計画・仕様など非コード成果物の確定前に、実証を課した 3 観点の独立レビューを実施する。発動はユーザー指示のみ。spec 確定点と plan 確定点で毎回提示され、未レビューの規範・手順文書の変更を含む成果物では推奨側に置かれる（ADR-0067 / ADR-0072 / ADR-0080） |
```
new_string:
```
| [`pre-finalization-review`](skills/pre-finalization-review/) | 計画・仕様など非コード成果物の確定前に、実証を課した 3 観点の独立レビューを実施する。発動はユーザー指示のみ。確定点での提示・推奨順位の規則は start-work の「確定前レビューの提示規則」が正（ADR-0067 / ADR-0072 / ADR-0080） |
```

- [ ] **Step 8-5: 検証**

```powershell
(Select-String -Path skills/start-work/SKILL.md -Pattern '自動必須化はしない').Count            # 期待: 1
(Select-String -Path skills/pre-finalization-review/SKILL.md -Pattern '自動必須化はしない').Count  # 期待: 1（「いつ使うか」の配線行内のみ）
(Select-String -Path skills/pre-finalization-review/SKILL.md,README.md -Pattern '推奨側に置かれる').Count  # 期待: 0
```

- [ ] **Step 8-6: 生成器＋コミット**

```powershell
./scripts/build-dist.ps1; ./scripts/build-dist.ps1 -Check; ./scripts/sync-template.ps1 -Check
# dist/skills/{start-work,pre-finalization-review}/SKILL.md の変更箇所を 5 点目視
git add skills/start-work/SKILL.md skills/pre-finalization-review/SKILL.md README.md dist/
git commit -m "feat: K12 - 確定前レビュー発動・提示規則の正本を start-work に一意化（ADR-0105）"
```

### Task 9: 簡素化 C-11 — session-handoff update 手順の束ね直し（10 → 5）

**Files:**
- Modify: `skills/session-handoff/SKILL.md`

- [ ] **Step 9-1: update 手順を 5 手順に再編する**（手順 3 = 現行手順 8 の本文は無変更で維持。並び順: 読込 → 各節最新化 → 消化記録追記 → 移設判定 → 保存）

old_string:
```
手順:
1. 既存ファイルを読み込む
2. Last Updated を現在時刻（Asia/Tokyo）に更新する
3. Current Phase を最新の状態に更新する
4. 完了したタスクを「完了済みタスク」セクションに移動する
5. 進行中のタスクの「状態」「残り」を最新化する
6. 重要な意思決定があれば「重要な意思決定の履歴」に ADR 番号を追記する
7. 既知のブロッカーがあれば追記する
8. 「Post ラッパー消化記録」へ当該マイルストーンの1行を追記する（ADR-0057）。
```
new_string:
```
手順:
1. 既存ファイルを読み込む
2. 各節を最新化する。更新対象: ヘッダ（Last Updated を現在時刻（Asia/Tokyo）へ、Current Phase を最新の状態へ）/ 完了したタスクの「完了済みタスク」への移動 / 進行中のタスクの「状態」「残り」の最新化 / 重要な意思決定があれば「重要な意思決定の履歴」へ ADR 番号を追記 / 既知のブロッカーがあれば追記
3. 「Post ラッパー消化記録」へ当該マイルストーンの1行を追記する（ADR-0057）。
```

（続けて現行手順 9・10 の行頭番号を変更する。各行の本文は無変更）:

old_string `9. 各節への追記で詳細を書きたくなったら` → new_string `4. 各節への追記で詳細を書きたくなったら`
old_string `10. ファイルを上書き保存する` → new_string `5. ファイルを上書き保存する`

- [ ] **Step 9-2: 独立手順「移設」節の「update 手順 9」参照 2 箇所を番号非依存の表現へ追従させる**

old_string:
```
このほか、種類別対応表は update 手順 9・節別の記載規範（既知のブロッカー・懸念の行、列挙外の節への既定規則）・finalize 手順 4 の「圧縮しないもの」規定からも書き分けの判定に参照される。
```
new_string:
```
このほか、種類別対応表は update の移設判定の手順・節別の記載規範（既知のブロッカー・懸念の行、列挙外の節への既定規則）・finalize 手順 4 の「圧縮しないもの」規定からも書き分けの判定に参照される。
```

old_string:
```
update 手順 9 を契機に正本へ書いた場合も、次のコミット時に handoff と同時に add する。
```
new_string:
```
update の移設判定の手順を契機に正本へ書いた場合も、次のコミット時に handoff と同時に add する。
```

- [ ] **Step 9-3: 検証**

```powershell
(Select-String -Path skills/session-handoff/SKILL.md -Pattern 'update 手順 9').Count   # 期待: 0
# update 操作の手順数を実体読みで確認: 「### 3. update」節の番号付き手順が 1〜5 の 5 個であること
# 消化記録追記（新手順 3）の本文が現行手順 8 と一致していること（無変更の確認）
```

- [ ] **Step 9-4: 生成器＋コミット**

```powershell
./scripts/build-dist.ps1; ./scripts/build-dist.ps1 -Check; ./scripts/sync-template.ps1 -Check
# dist/skills/session-handoff/SKILL.md の変更箇所を 5 点目視
git add skills/session-handoff/SKILL.md dist/
git commit -m "feat: C-11 - session-handoff update 手順を 10 から 5 へ束ね直し（証跡の様式・義務は不変。ADR-0105）"
```

### Task 10: 簡素化 D-11 — decision-log 昇格手順の束ね直し（5 → 3）

**Files:**
- Modify: `skills/decision-log/SKILL.md`

- [ ] **Step 10-1: 昇格手順を 3 ステップに再編する**（ステップ 1・2 は無変更。3〜5 を 1 ステップへ）

old_string:
```
昇格手順:

1. **サイクル全体整合検査を実施する（ADR-0092）**: 手順は次節「サイクル全体整合検査」に従う。検査での修正・書き戻しを終えてから次のステップへ進む
2. **粒度を点検する（ADR-0059 / ADR-0060）**: 昇格対象 ADR のタイトルが本文の全決定に答えているかを突合する。答えていない決定があれば分割を提案し、分割してから昇格する
3. 該当ADRファイルの `Status` を `Accepted` に更新する
4. `docs/records/decisions/README.md` のテーブルのステータスも更新する
5. コミットする
```
new_string:
```
昇格手順:

1. **サイクル全体整合検査を実施する（ADR-0092）**: 手順は次節「サイクル全体整合検査」に従う。検査での修正・書き戻しを終えてから次のステップへ進む
2. **粒度を点検する（ADR-0059 / ADR-0060）**: 昇格対象 ADR のタイトルが本文の全決定に答えているかを突合する。答えていない決定があれば分割を提案し、分割してから昇格する
3. **Status・インデックスを更新しコミットする**: 該当ADRファイルの `Status` を `Accepted` に更新し、`docs/records/decisions/README.md` のテーブルのステータスも更新して、コミットする
```

- [ ] **Step 10-2: 検証**

```powershell
(Select-String -Path skills/decision-log/SKILL.md -Pattern '「承認の昇格」の第 1 ステップとして実施する').Count  # 期待: 1（サイクル全体整合検査節の参照はステップ 1 のまま有効）
# 昇格手順の番号付きステップが 1〜3 の 3 個であることを実体読みで確認
```

- [ ] **Step 10-3: 生成器＋コミット**

```powershell
./scripts/build-dist.ps1; ./scripts/build-dist.ps1 -Check; ./scripts/sync-template.ps1 -Check
git add skills/decision-log/SKILL.md dist/
git commit -m "feat: D-11 - decision-log 昇格手順を 5 から 3 ステップへ束ね直し（点検工程は不変。ADR-0105）"
```

### Task 11: 簡素化 I-17 — retrospective 起票サブ手順の参照化＋起票・採番の正本一意化

**Files:**
- Modify: `skills/retrospective/SKILL.md`（Phase 2 手順 2）
- Modify: `docs/overview/issue-management.md`（冒頭の参照契約）
- Modify: `skills/decision-log/SKILL.md`（未決事項起票節の採番複写）

- [ ] **Step 11-1: retrospective Phase 2 手順 2 のサブ手順（採番・起票・インデックス行追加）を課題管理定義への参照に置換する**（フォールバックは要点 1 文。手順 2-4 の振り返り側起票行・手順 3〜5 は維持）

old_string:
```
2. 起票対象の課題を**全件** `docs/working/issues/` へ起票する（ADR-0028）:
   1. インデックス `docs/working/issues/README.md` 全体（両セクション）の最大番号+1 で採番する
   2. `docs/working/issues/system|flow/NNNN-<slug>.md` を起票する（Status: open。課題内容は要約のみとし、「起票元」に `retrospectives/system|flow/YYYY-MM-DD-<topic>.md 課題#N` を記載）
   3. インデックスの対応セクションに1行追加する
   4. 振り返りファイル側の各課題項目に「**起票**: Issue-NNNN」行を記載する
```
new_string:
```
2. 起票対象の課題を**全件** `docs/working/issues/` へ起票する（ADR-0028）。採番・起票ファイルの作成・インデックスへの行追加は課題管理定義（標準: `docs/overview/issue-management.md`）の起票・採番の定義に従う。課題内容は要約のみとし、「起票元」に `retrospectives/system|flow/YYYY-MM-DD-<topic>.md 課題#N` を記載する（定義が見つからない場合は、インデックス `docs/working/issues/README.md` 全体の最大番号+1 で採番し、`docs/working/issues/system|flow/NNNN-<slug>.md` へ要約＋起票元参照で起票してインデックスへ 1 行追加することを既定として提案し、その旨をユーザーへ報告する）。起票後、振り返りファイル側の各課題項目に「**起票**: Issue-NNNN」行を記載する
```

- [ ] **Step 11-2: issue-management 冒頭の参照契約へ「起票・採番」を追加する**

old_string:
```
> **スキルからの参照について**: 本文書の定義（昇格条件・フォルダ内の役割と命名・close 時の移設判定・記載規範）は、プラグイン配布のスキル（decision-log / retrospective / session-handoff / worklog-extract）から参照される。
```
new_string:
```
> **スキルからの参照について**: 本文書の定義（起票・採番、昇格条件・フォルダ内の役割と命名・close 時の移設判定・記載規範）は、プラグイン配布のスキル（decision-log / retrospective / session-handoff / worklog-extract）から参照される。
```

- [ ] **Step 11-3: decision-log 未決事項起票節の採番定義の複写を参照形へ揃える**（掃き出し規定の処置）

old_string:
```
1. 未決事項を検出したら `docs/working/issues/system|flow/NNNN-<slug>.md` を起票する（Status: open）。分類は、対象システム固有の課題なら `system/`、開発の進め方・スキル・原則・ガイドラインに関する課題なら `flow/`（議論由来の未決事項は大半が `system/`）。連番はインデックス `docs/working/issues/README.md` 全体（両セクション）の最大番号+1。フォーマットは課題管理定義（標準: `docs/overview/issue-management.md`）を参照
```
new_string:
```
1. 未決事項を検出したら `docs/working/issues/system|flow/NNNN-<slug>.md` を起票する（Status: open）。分類は、対象システム固有の課題なら `system/`、開発の進め方・スキル・原則・ガイドラインに関する課題なら `flow/`（議論由来の未決事項は大半が `system/`）。採番・フォーマットは課題管理定義（標準: `docs/overview/issue-management.md`）の起票・採番の定義を参照（定義が見つからない場合は、インデックス `docs/working/issues/README.md` 全体（両セクション）の最大番号+1 で採番することを既定として提案し、その旨をユーザーへ報告する）
```

- [ ] **Step 11-4: 検証**

```powershell
(Select-String -Path skills/retrospective/SKILL.md -Pattern '最大番号\+1').Count      # 期待: 1（フォールバック内のみ）
(Select-String -Path skills/decision-log/SKILL.md -Pattern '最大番号\+1').Count       # 期待: 2（ADR 採番の手順 1〈decisions README。対象外〉＋未決事項起票のフォールバック）
(Select-String -Path docs/overview/issue-management.md -Pattern '起票・採番、昇格条件').Count  # 期待: 1
```

- [ ] **Step 11-5: 生成器＋コミット**

```powershell
./scripts/build-dist.ps1; ./scripts/sync-template.ps1; ./scripts/build-dist.ps1 -Check; ./scripts/sync-template.ps1 -Check
# dist/skills/{retrospective,decision-log}/SKILL.md・template/docs/overview/issue-management.md の変更箇所を 5 点目視
git add skills/retrospective/SKILL.md skills/decision-log/SKILL.md docs/overview/issue-management.md dist/ template/
git commit -m "feat: I-17 - 起票・採番手順の正本を issue-management に一意化（retrospective/decision-log を参照化。ADR-0105）"
```

### Task 12: 部分修正注記（21 ADR）

**Files:**
- Modify: `docs/records/decisions/` 配下の 21 ファイル（0005 / 0006 / 0019 / 0028 / 0030 / 0031 / 0032 / 0041 / 0047 / 0057 / 0058 / 0060 / 0068 / 0072 / 0079 / 0080 / 0087 / 0091 / 0092 / 0096 / 0102）

- [ ] **Step 12-1: 各 ADR の Status が Accepted であることを確認する**（Accepted でないものがあれば注記対象から外し、理由を記録してユーザーへ報告する）

- [ ] **Step 12-2: 各 ADR の Consequences 末尾へ「部分修正（ADR-0105）」注記を 1 行追記する**。書式と各 ADR の説明句:

`- **部分修正（ADR-0105）**: <説明>`

| ADR | 説明句 |
|---|---|
| 0005 | session-handoff update 手順の構成は 5 手順へ束ね直された（証跡の様式・義務は不変） |
| 0006 | CLAUDE.md 即時記録節・start-work のトリガー定義列挙は decision-log への参照に置換された（トリガー定義の正本は decision-log） |
| 0019 | CLAUDE.md「意思決定の記録」の記述規律・Proposed 運用の箇条は decision-log への参照に置換され、昇格手順は 3 ステップへ束ね直された |
| 0028 | retrospective Phase 2 の起票サブ手順（採番・起票・インデックス行追加）は課題管理定義への参照に置換された |
| 0030 | 決定 4 の反映先（CLAUDE.md 即時記録節・start-work 冒頭ブロック）のコミット遅延の定義列挙は decision-log への参照に置換された（コミット遅延の規範本体は decision-log 側で現役） |
| 0031 | 既存課題への追記の一次記録規範は維持。retrospective の起票手順は課題管理定義への参照になり、folder-structure の節番号は「7. 仕様書の運用規約」新設で繰り上がった |
| 0032 | CONTRIBUTING「ADRを記録するとき」の実行可能性条項は decision-log への参照に置換された（条項本体は decision-log 側で現役） |
| 0041 | start-work Post の昇格漏れ確認（決定 3 の対称化箇所）は decision-log の手順への参照形に置換された |
| 0047 | start-work Post 項目 3 の記録ゲート・契機のインライン記述は worklog-record への参照に置換された（配線自体は現役） |
| 0057 | start-work Post 前文・worklog-record 側の消化記録の記録対象・様式の記述は session-handoff への参照に置換された（記録義務・棄却明示の規範は session-handoff 側で現役） |
| 0058 | start-work セッション終了処理の worklog ステップは worklog-record への参照形に置換された（発火契機は worklog-record 側で現役） |
| 0060 | 昇格手順は粒度点検を含む 3 ステップへ束ね直された（点検の実施位置・内容は不変） |
| 0068 | 名指しする folder-structure の節番号は「7. 仕様書の運用規約」新設で繰り上がった（規範内容は不変） |
| 0072 | pre-finalization-review 固有の「自動必須化はしない」条項は start-work 提示規則へ吸収された（発動ゲートの意味は不変） |
| 0079 | extend-guidelines 手順 5 の点検記載は CONTRIBUTING 共通節への配線に置換された（点検の規範本体は CONTRIBUTING 側で現役） |
| 0080 | Decision 5「判定材料の記録」の start-work 側記載（提示規則 4）は削除され、記録は session-handoff update、判定側の安全既定は提示規則 2 但し書きへ移設された |
| 0087 | 決定 6「本サイクル」定義の所在は session-handoff の独立節「「本サイクル」の定義」へ移設された |
| 0091 | 決定 1・手順 6 が名指しする「update 手順 9」の 2 文は番号非依存の表現へ追従され、決定 5 が名指しする「update 手順 8」（消化記録追記）は束ね直しにより update 手順 3 へ移った |
| 0092 | サイクルの定義の参照先は start-work から session-handoff「「本サイクル」の定義」へ張り替えられた |
| 0096 | Decision が名指しする folder-structure の節番号（課題管理早見表ほか）は「7. 仕様書の運用規約」新設で繰り上がった（規範内容は不変。retrospective 側のサイズ実測記載は既に参照形のため不変） |
| 0102 | extend-guidelines 手順 5 の評価可能性確認の記載は CONTRIBUTING 共通節への配線に置換され、CONTRIBUTING「ADRを記録するとき」記述規律の文脈語が追従修正された（要件本体は「新設の評価可能性」節で現役） |

- [ ] **Step 12-3: 検証**

```powershell
(Select-String -Path docs/records/decisions/*.md -Pattern '部分修正（ADR-0105）').Count  # 期待: 22（注記 21 件＋ADR-0105 本文が注記の書式を規定する 1 箇所）
```

- [ ] **Step 12-4: コミット**（ADR は非配布のため生成器不要）

```powershell
git add docs/records/decisions/0005-*.md docs/records/decisions/0006-*.md docs/records/decisions/0019-*.md docs/records/decisions/0028-*.md docs/records/decisions/0030-*.md docs/records/decisions/0031-*.md docs/records/decisions/0032-*.md docs/records/decisions/0041-*.md docs/records/decisions/0047-*.md docs/records/decisions/0057-*.md docs/records/decisions/0058-*.md docs/records/decisions/0060-*.md docs/records/decisions/0068-*.md docs/records/decisions/0072-*.md docs/records/decisions/0079-*.md docs/records/decisions/0080-*.md docs/records/decisions/0087-*.md docs/records/decisions/0091-*.md docs/records/decisions/0092-*.md docs/records/decisions/0096-*.md docs/records/decisions/0102-*.md
git commit -m "docs: 21 の既存 Accepted ADR へ部分修正注記を追記（ADR-0105）"
```

### Task 13: version bump ＋執行点総ざらい

**Files:**
- Modify: `.claude-plugin/plugin.json` / `.claude-plugin/marketplace.json`（version 0.1.7 → 0.1.8）

- [ ] **Step 13-1: version を 0.1.8 へ更新する**（両ファイルの `"version": "0.1.7"` → `"0.1.8"`）
- [ ] **Step 13-2: 生成器を両方実行し、両方 `-Check` を通す**（exit 0 を確認）
- [ ] **Step 13-3: 配布物目視の総ざらい**: 本サイクルで変更した配布物（`dist/skills/` 7 スキル・`template/CLAUDE.md`・`template/docs/overview/folder-structure.md`・`template/docs/overview/issue-management.md`）を通読し、CONTRIBUTING「機械判定が届かない領域」の 5 点（括弧内同居・半角括弧・実在固有名・自己参照・docstring/メッセージ）を確認する。目視は 1 回で終わらせず、生成後の配布物を読む工程として実施する
- [ ] **Step 13-4: コミット**

```powershell
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json dist/ template/
git commit -m "chore: plugin version 0.1.8（Issue-0093/0094 統合・簡素化サイクル）"
```

### Task 14: サイクル全体整合検査（旧 spec 追従の判定を含む）

decision-log「承認の昇格」手順 1 として実施する（発動条件: 本サイクルは規範・手順文書を変更しているため検査必須）。

- [ ] **Step 14-1: 変更ファイルを列挙する**: `git diff --name-only $(git merge-base master HEAD) HEAD` ＋ `git status --porcelain` の併合
- [ ] **Step 14-2: 観点 1（仕様のスナップショット性）で旧 spec の逐語複写を判定・追従する**。対象は判明済み 10 エントリ:
  - `docs/current/specs/2026-04-12-meta-guidelines-design.md`（リスク 3 段階・起票採番の複写）
  - `docs/current/specs/2026-04-25-record-strengthening-design.md`（4 トリガー×2・消化記録様式の複写）
  - `docs/current/specs/2026-05-01-feature-block-design/`（仕様書運用 4 箇条・しきい値の複写）
  - `docs/current/specs/2026-05-01-retrospective-design.md`
  - `docs/current/specs/2026-07-04-project-folder-structure/`
  - `docs/current/specs/2026-07-05-retrospective-issue-integration/`（起票・採番手順の複写）
  - `docs/current/specs/2026-07-17-worklog-skill-pipeline/`（記録ゲートの複写）
  - `docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md`（レビュー発動規則の複写）
  - `docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md`（点検配線の複写）
  - `docs/current/specs/2026-08-13-handoff-bloat-control/`（本サイクル定義・update/finalize 手順構成の複写）

  処置の切り分け（ADR-0105）: **逐語複写（競合する定義）は本サイクルの統合後の形へ追従させる**（複写の内側にある旧番号ポインタも追従に含める）。**独立した旧節番号・旧手順番号のポインタは壊れを許容する**。spec がスナップショットとして参照する定義が統合先へ移った場合は、spec 側の記述を統合先参照へ更新する
- [ ] **Step 14-3: open 課題内の帰属つき引用 3 件＋未帰属引用 1 件を個別判定する**（既定: 記述は残し、出所の名指しのみ現状に合わせて更新）:
  - `docs/working/issues/flow/0052-...md`: A-14 の引用。CLAUDE.md に起動義務の箇条は残るため、名指しの更新要否のみ確認
  - `docs/working/issues/flow/0082-...md`: スナップショット規約の引用。規約の正本が folder-structure「7. 仕様書の運用規約」へ移ったため、出所の名指しを更新する
  - `docs/working/issues/system/0055-...md`: スナップショット規約を CLAUDE.md 帰属で引用（関連欄）。出所の名指しを folder-structure「7. 仕様書の運用規約」へ更新する
  - `docs/working/issues/system/0008-...md`: スナップショット規約の逐語引用だが出所の名指しが無い。更新不要の判定のみ記録する
- [ ] **Step 14-4: 検査観点 2〜5 を実施する**（規範の書き戻し / 数値・完了基準の整合 / 経路の閉じ〈新設配線行の 1 サイクル机上実行。到達経路の全列挙と発火有無の 1 行書き出し〉 / 引用の整合〈配線行が統合先のゲートを落としていないかの突合〉）
- [ ] **Step 14-5: 追従・修正があればコミットする**（decision-log「検査結果の扱い」の 2 分岐に従う: (1) 修正が規範の文言・適用範囲に及んだ場合は ADR-0105 の過剰適合点検ブロックを当該差分について再点検・更新する、(2) 修正が配布対象ソース〈前提 4 の定義〉に及んだ場合は前提 4 の執行点 4 手順を実施し、`dist/` `template/` を add 対象へ含めてから確定コミットする）

```powershell
git add docs/current/specs/<変更したファイル> docs/working/issues/<変更したファイル>
# 分岐 (2) 発火時はさらに: git add <配布対象ソース> dist/ template/
git commit -m "fix: サイクル全体整合検査 観点 1 - 旧 spec の逐語複写を統合後の形へ追従（ADR-0105）"
```

### Task 15: Accepted 昇格・Issue close

- [ ] **Step 15-1: ADR-0103 / 0104 / 0105 の粒度を点検し、Status を Accepted へ更新する**（`docs/records/decisions/README.md` のステータスも更新）
- [ ] **Step 15-2: Issue-0093 を close する**: Status: closed・Closed 日付・結論に「実変更 15 行＋覆し 7 行（覆しの正本は ADR-0105、存置分の backlog は Issue-0099）。ADR-0103〜0105」を記録。インデックス更新
- [ ] **Step 15-3: Issue-0094 を close する**: 結論に「C-11（10→5 手順）/ D-11（5→3 ステップ）/ I-17（起票手順の参照化・正本の一意化）。証跡の様式と義務は不変（ADR-0105）」を記録。インデックス更新
- [ ] **Step 15-4: Issue-0060 の close 判定**: K2 の D-01 一本化（「削除」吸収）で欠落論点が実質解消されたことを確認し、close の可否をユーザーへ提示する（close する場合は結論に ADR-0105 K2 を記載）
- [ ] **Step 15-5: コミット**（`docs/records/decisions/README.md`・`docs/working/issues/README.md` は空インデックス生成対象＝配布対象ソースのため、コミット前に `./scripts/sync-template.ps1` と両 `-Check` を実行する。Status 列の書き換えのみでは `template/` 出力は不変だが、規約どおり実行して確認する）

```powershell
./scripts/sync-template.ps1; ./scripts/build-dist.ps1 -Check; ./scripts/sync-template.ps1 -Check
git add docs/records/decisions/0103-*.md docs/records/decisions/0104-*.md docs/records/decisions/0105-*.md docs/records/decisions/README.md docs/working/issues/flow/0093-*.md docs/working/issues/flow/0094-*.md docs/working/issues/README.md template/
git commit -m "adr: 0103-0105 を Accepted へ昇格（Issue-0093/0094 close。サイクル全体整合検査 実施）"
```

（Issue-0060 を close する場合は該当ファイルとインデックスを同コミットに含める。cyclecheck= / review= の消化記録は start-work Post の運用に従い handoff へ記録する）

---

## 完了基準（サイクル全体）

1. 実変更 15 行（B-20 の参照化を含む）＋付随編集 4 件＋簡素化 3 行がすべて配線化・束ね直し済みで、各タスクの検証 grep が期待値どおり
2. `./scripts/build-dist.ps1 -Check` と `./scripts/sync-template.ps1 -Check` がともに exit 0
3. plugin version 0.1.8
4. 部分修正注記 21 件（`部分修正（ADR-0105）` の decisions 配下 grep が 22 件＝注記 21＋ADR-0105 本文の書式規定 1）
5. サイクル全体整合検査の 5 観点消化（観点 1 で旧 spec 追従済み）
6. ADR-0103〜0105 Accepted、Issue-0093/0094 close（Issue-0060 はユーザー判定）
7. 全コミットが pathspec 付きで、`docs/inbox/`・`docs/conversation_log.md` を含まない
