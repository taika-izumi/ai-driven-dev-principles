# 設計仕様: retrospective スキル（サイクル末尾の課題抽出記録）

- **Status**: Current（2026-07-31 に ADR-0056 の役割再定義を反映して全面書き換え。初版は 2026-05-01 のサブプロジェクトC設計）
- **Author**: メインエージェント + ユーザー
- **Related ADRs**: ADR-0010, ADR-0011, ADR-0012, ADR-0021, ADR-0028, ADR-0031, ADR-0056
- **Related Issues**: Issue-0035（起票元）, Issue-0021（解消方向）

## 1. 概要・目的・スコープ

### 1.1 役割

`retrospective` スキルは、サブプロジェクト 1 サイクル完了直後（feature ブランチを master へマージ後、handoff finalize 前）に、**サイクル末尾の課題抽出記録（issue 詳細の正本）**を作成するスキルである。

残す情報は次の 2 つに限定する（ADR-0056）:

1. **課題の詳細記録**（事象 / 原因 / 影響、および system / flow 分類）— issue が「要約＋ライフサイクル管理」、retrospective ファイルが「詳細の正」という分担（ADR-0028）
2. **最小のサイクル文脈**（対象サブプロジェクト・期間・merge コミット・関連 plan / ADR へのポインタ）— 課題詳細を将来単独で読んで理解するためのヘッダ

旧 5 観点（Done / Went Well / Struggled / Tech Notes / Issues）のうち Went Well / Tech Notes は観点として廃止した。スキル化に有用な知見（躓き・人間の指示＝ delta）は worklog パイプライン（worklog-record → worklog-extract → worklog-skillify）が捕捉・再利用する（ADR-0056）。

### 1.2 スコープ（ADR-0021 を維持）

- retrospective は「課題の抽出と分類」までに限定する。対策の設計・採否判断・ADR 化は行わない（次サイクルでユーザーが判断）
- 抽出した課題はバックログとして記録・起票するのみ。着手の要否・時期はユーザー判断
- 実行は手動トリガーのみ（自動起動なし）
- 形式は単一。開始時の形式選択（完全版 / 簡易版）は設けない（ADR-0056）
- rubber-duck 独立レビューは既定では実施せず、ユーザーが求めた場合のみのオプション工程（ADR-0056）

## 2. worklog パイプラインとの棲み分け

`docs/working/issues/README.md` を唯一のバックログとして、2 つの経路が合流する。

| | retrospective 由来の issue | worklog-extract 由来の issue |
|---|---|---|
| 記録するもの | そのサイクルで観測された未解決の問題（バグ、設計負債、未定義の規約、プロセスの欠落） | 横断走査で再発が裏付けられた「AI デフォルト挙動との差分」のスキル化・ルール化候補 |
| 証拠 | そのサイクルの成果物（plan / git log / 対話での気づき） | 中央ストアの根拠エントリ id・再発数・プロジェクト数・モデル分布 |
| 範囲と時間軸 | 単一プロジェクト・サイクル末尾に毎回 | 全プロジェクト横断・オンデマンド実行時 |
| 出口 | 対策の要否・時期はユーザー判断 | 採用判断済みで worklog-skillify へ直結 |

### 2.1 フロー課題の振り分け規則（ADR-0056 決定 6）

フロー課題候補ごとに「作業時点の delta（躓き・人間の指示）として worklog に記録済み／記録可能か」を判定する:

- **delta 型 かつ 急がない** → issue は起票しない。worklog 記録の有無を確認し、未記録なら Phase 3 の worklog 総ざらいで記録する。仕組み化の要否は worklog-extract の再発裏付けに委ねる
- **delta 型 だが ユーザーが早期対処を要すると判断** → 即起票する（後日 worklog-extract が同クラスタを検出したら既存 issue へ統合される）
- **構造観察型（delta として表現できない。例: 「記録に読み手がいない」等、体系の俯瞰で初めて見える欠落）** → issue 経路で扱う。ただし発見の主経路はサイクル中の随時起票（decision-log の未決事項起票・作業中の気づきの即時起票）であり、retrospective は「起票漏れの最終チェックポイント」にとどまる

対象システム固有の課題は無条件で retrospective が起票する（worklog-extract はスキル化候補のみを扱い、対象システムのバグ・設計負債は扱わない）。

### 2.2 重複防止（両方向）

- retrospective → 起票前に既存 open 課題（worklog-extract 由来を含む）と突合し、既存があれば「検討状況」へ追記する（ADR-0031）
- worklog-extract → Issue 草案化時に retrospective 由来のバックログと重複排除する（worklog-extract 手順 8。唯一の合流点）

## 3. スキル手順

### Phase 0: 前提収集（メイン実行）

1. 対象サブプロジェクト名・feature ブランチ名・対応 plan/spec パスをユーザーから受け取る（merge コミットから推定する場合は必ずユーザー確認）
2. 対応 plan / spec / merge コミット範囲の git log / handoff 現行版 / 期間中に追加・変更された ADR を読み込む
3. `docs/records/retrospectives/` に同一トピックの既存ファイルが無いことを確認する

### Phase 1: 課題案の一括提示（メイン実行）

1. AI が Phase 0 の材料から課題候補を一括提示する。各候補に以下を添える:
   - 事象 / 原因 / 影響
   - system / flow 分類
   - flow 候補には delta 型 / 構造観察型の判定と worklog 記録状況、および起票要否の提案（振り分け規則 §2.1）
   - 既存 open 課題の再発・進展は新規候補とせず「検討状況」追記対象として提示（ADR-0031）
2. ユーザーが修正・追加・削除と起票判断を行う
3. 末尾に確認 1 問: 「このサイクル中に言語化されたが未起票の気づき（会話中の指摘・見送った論点など）はないか」（体系全体を走査する構造チェック工程は設けない）

### Phase 2: 記録保存と起票（メイン実行）

1. `docs/records/retrospectives/system/YYYY-MM-DD-<topic>.md`（メイン記録）と、フロー課題があれば `flow/YYYY-MM-DD-<topic>.md` を書き出す（ADR-0021。テンプレートは §4）
2. 起票対象の課題を全件 `docs/working/issues/system|flow/NNNN-<slug>.md` へ起票し、インデックスへ行追加する（ADR-0028。採番は両セクション通し連番）
3. ADR-0031 の追記（再発・進展）を実施する
4. **`docs/records/retrospectives/README.md` の一覧へ行追加する（省略不可）**
5. ユーザーへ提示し確認を得る

### Phase 3: 仕上げ（メイン実行）

1. **（オプション）rubber-duck 独立レビュー**: ユーザーが求めた場合のみ 1 回実施する。観点は「課題の抽出漏れがないか・system / flow 分類が妥当か」に絞る。結果は記録ファイルの「Independent Review Notes」節（実施時のみ追加）に記録する
2. **worklog 総ざらい確認（マイルストーン突合。ADR-0057）**: サイクル中のマイルストーンと中央ストアのエントリを突合し、Post ラッパーの消化漏れを回収する。手順:
   1. サイクル中のマイルストーンを列挙する。情報源はハンドオフの「Post ラッパー消化記録」と「完了済みタスク」、および当該ブランチの `git log`
   2. 各マイルストーンについて、消化記録に `worklog=` の記載（エントリ id または棄却）があるかを検査する。**記載が無いマイルストーンを未消化として洗い出す**
   3. 中央ストア `<home>/.ai-dev-worklog/<project>/log.jsonl` から当該サイクル分のエントリを数え、消化記録に記載された id と突合する
   4. 未消化のマイルストーンについて delta（躓き・人間の指示）の有無を検討し、あれば `worklog-record` を呼んで記録する。delta が無ければ消化記録へ棄却として1行補う
   5. §2.1 で「worklog 送り」と判定した課題候補の記録漏れもここで拾う

   本工程は、Post ラッパーに完全に入らなかった場合（消化記録の行そのものが無い）を回収する唯一の経路である。書かれなかったものは即時には検出できないため、外形的に必ず残る `git log` との事後突合で拾う設計になっている
3. `session-handoff` の cycle-reset 操作を呼ぶ（剪定・書き換えの手順は session-handoff 側の定義に従う。ADR-0075）。「次セッション開始時のアクション」に起票済み issue 番号を記載し、Status を `in_progress` から `ready-for-next-cycle` へ遷移する（ADR-0076）

コミットはスキル内では行わない（ユーザーまたは通常フローに委ねる）。

## 4. 出力ファイル仕様

### 4.1 メイン記録（`system/YYYY-MM-DD-<topic>.md`）

```markdown
# Retrospective: <サブプロジェクト名>

- **Subject**: <正式名>
- **Branch**: feature/<name>（merge済み: <sha>）
- **Period**: <開始日> 〜 <完了日>
- **Plan**: docs/working/plans/<...>
- **Spec**: docs/current/specs/<...>
- **Related ADRs**: ADR-NNNN, ...
- **Facilitator**: メインエージェント (<モデル名>)

## 1. 達成サマリ

<3〜5 行の箇条書き。課題詳細を将来単独で読むための最小文脈>

## 2. 課題（対象システム固有）

- **課題 #N**: <一文タイトル>
  - **事象**: / **原因**: / **影響**:
  - **起票**: Issue-NNNN

> 開発フロー課題 N 件は flow/<同名>.md 参照。／ worklog 送りとした delta 型候補 N 件（起票なし）

## 3. 既存課題の再発・進展

- Issue-NNNN: <検討状況へ追記した内容の要約>（ADR-0031）

## 4. (任意) Independent Review Notes

<rubber-duck 実施時のみ。指摘 / メインの応答 / 反映先>
```

### 4.2 フロー課題記録（`flow/YYYY-MM-DD-<topic>.md`）

現行構成を維持（課題詳細 + 起票 Issue 番号 + 「なぜフロー課題か」）。ヘッダに振り分け判定（delta 型・早期対処 / 構造観察型）を 1 行追記する。フロー課題の起票が 0 件ならファイルを作成しない。

### 4.3 保管規約（ADR-0011 を維持）

- 一度書いたら原則上書き禁止（typo 修正のみ例外）
- `docs/records/retrospectives/README.md` は行追加のみ・過去行の編集禁止
- 過去の retrospective ファイル（7 セクション形式・非定型の簡易形式）は改変しない。新形式は ADR-0056 以降に作成するファイルから適用する

## 5. 既存ドキュメントへの波及

| 対象 | 内容 |
|---|---|
| `skills/retrospective/SKILL.md` | 本仕様の手順（§3）・棲み分け（§2）で全面改訂。frontmatter description も新役割へ更新 |
| `skills/retrospective/template.md` | §4.1 の構成へ書き換え |
| `skills/retrospective/flow-template.md` | ヘッダ微調整（§4.2） |
| `docs/records/retrospectives/README.md` | 運用規約の説明を新形式へ更新（一覧テーブルの過去行は不変）+ 欠落 2 行（2026-07-18 の 2 件）の追加 |
| `skills/start-work/SKILL.md` / `CLAUDE.md` | 起動タイミング・スコープ記述は不変のため原則変更不要。実装時に 5観点への言及がないことを grep で確認し、あれば修正（CLAUDE.md 変更時は `scripts/sync-template.ps1` 実行） |
| `docs/working/issues/` | Issue-0035 close（結論に ADR-0056）。Issue-0021 検討状況へ解消方向を追記（close 判断はユーザー） |
| プラグイン反映 | skills/ 改定後、ユーザーへ `/plugin marketplace update ai-driven-dev-principles` を依頼（ADR-0055） |

## 6. 対応する原則

- **原則1（追跡可能性）**: 課題の事象・原因・影響がサイクル単位で永続化され、issue の正本として参照される
- **原則2（関心の分離）**: 課題抽出（retrospective）と知見の再利用（worklog パイプライン）を消費経路で分離。対策の決定・実装は次サイクル
- **原則3（コンテキスト管理）**: 最小サイクル文脈により課題詳細が単独で理解可能。重複記録の排除でトークン消費を抑制
- **原則4（人間の関与）**: 起票判断・振り分けの早期対処判断・rubber-duck 実施判断はユーザー
- **原則5（漸進的検証）**: サイクル単位の課題抽出で AI駆動開発ガイドライン自体の検証ループを回す
