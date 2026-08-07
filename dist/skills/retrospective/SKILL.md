---
name: retrospective
description: "サブプロジェクト1サイクル完了直後（feature ブランチを master へマージ後、handoff finalize 前）に実施する、サイクル末尾の課題抽出記録スキル。AI が plan / git log / handoff から課題候補（事象/原因/影響、system/flow 分類つき）を一括提示し、ユーザーが修正と起票判断を行う。フロー課題は delta 型（worklog で捕捉可能）か構造観察型かを振り分け、delta 型で急がないものは worklog パイプラインへ委ねる。抽出課題は docs/working/issues/system|flow/ へ起票し、対策の採否・設計・ADR化は次サイクルへ委ねる。rubber-duck 独立レビューはユーザー要求時のみのオプション。"
---

# retrospective

サイクル末尾に「課題抽出記録（issue 詳細の正本）」を作成するスキル。残す情報は次の2つに限定する:

1. **課題の詳細記録**（事象 / 原因 / 影響、system / flow 分類）— issue が「要約＋ライフサイクル管理」、本記録が「詳細の正」
2. **最小のサイクル文脈**（対象・期間・merge コミット・関連 plan / ADR へのポインタ）— 課題詳細を将来単独で読むためのヘッダ

旧5観点のうち Went Well / Tech Notes は観点として廃止した。スキル化に有用な知見（躓き・人間の指示＝ delta）は worklog パイプライン（worklog-record → worklog-extract → worklog-skillify）が捕捉・再利用する。

## いつ使うか

サブプロジェクトの feature ブランチを master へ `--no-ff` マージし、対応 handoff を completed 状態へ遷移させる**直前**。`start-work` Phase 2 マッピング表の「サブプロジェクト完了直後の振り返り」行から推奨される。

実行は **手動トリガー**のみ。merge 検知などの自動起動は導入していない。形式は単一で、開始時の形式選択（完全版 / 簡易版）は設けない。

## スコープ（決定を維持）

retrospective は **「課題の抽出と分類」までに限定**する。対策の設計・採否判断（採用/保留/却下）・即時 ADR ドラフト化は**行わない**。それらは次の作業サイクルの責務。

抽出した課題は**バックログとして記録・起票するのみ**。着手の要否・時期はユーザーの判断に委ねる。ユーザーが対策を要すると判断した時点で、その課題を起点に通常フロー（`start-work` →（規模に応じ brainstorming）→ 対策決定で ADR 起票）を開始する。

課題の issue 起票（Phase 2）は**記録行為であり、対策の設計・採否判断ではない**。

## worklog パイプラインとの棲み分け

`docs/working/issues/README.md` を唯一のバックログとして、2つの起票経路が合流する:

- **retrospective 由来**: そのサイクルで観測された未解決の問題（バグ、設計負債、未定義の規約、プロセスの欠落）。証拠はサイクルの成果物。1回の観測でも起票できる
- **worklog-extract 由来**: 横断走査で再発が裏付けられた「AI デフォルト挙動との差分」のスキル化・ルール化候補。証拠は中央ストアの根拠エントリ

### フロー課題の振り分け規則

フロー課題候補ごとに「作業時点の delta（躓き・人間の指示）として worklog に記録済み／記録可能か」を判定する:

- **delta 型 かつ 急がない** → issue は起票しない。worklog 記録の有無を確認し、未記録なら Phase 3 の worklog 総ざらいで記録する。仕組み化の要否は worklog-extract の再発裏付けに委ねる
- **delta 型 だが ユーザーが早期対処を要すると判断** → 即起票する（後日 worklog-extract が同クラスタを検出したら既存 issue へ統合される。worklog-extract 手順8）
- **構造観察型**（delta として表現できない。例:「記録に読み手がいない」等、体系の俯瞰で初めて見える欠落）→ issue 経路で扱う。発見の主経路はサイクル中の随時起票（decision-log の未決事項起票・気づきの即時起票）であり、retrospective は起票漏れの最終チェックポイントにとどまる

対象システム固有の課題は無条件で retrospective が起票する（worklog-extract はスキル化候補のみを扱う）。

### 重複防止（両方向）

- retrospective 側: 起票前に既存 open 課題（worklog-extract 由来を含む）と突合し、既存があれば「検討状況」へ追記する
- worklog-extract 側: Issue 草案化時に retrospective 由来のバックログと重複排除する（worklog-extract 手順8。唯一の合流点）

## 重要な前提

- 意思決定の即時記録（継続適用）のルールは本スキル中も常時適用される。ただし retrospective 内では対策の採否を決めないため、retrospective 起因の ADR 起票は発生しない
- 出力ファイルは時系列追記型に従い、一度書いたら原則上書き禁止（typo 修正のみ例外）
- スキル内ではコミットしない。コミットはユーザーまたは通常フローに委ねる

## 手順

### Phase 0: 前提収集（メイン実行）

1. 対象サブプロジェクト名・feature ブランチ名・対応 plan/spec パスをユーザーから受け取る。直近 merge コミットから推定する場合は必ずユーザー確認を取る
2. 以下を読み込む:
   - 対応 plan ファイル（`docs/working/plans/...`）
   - 対応 spec ディレクトリ or ファイル（`docs/current/specs/...`）
   - 該当ブランチの merge コミット範囲の `git log --oneline`
   - `docs/working/handoff/master.md` 現行版
   - 該当期間に追加・変更された ADR
3. 既存 `docs/records/retrospectives/` に同一トピックの既存ファイルが無いことを確認する。あれば中止し、扱いをユーザーに確認する

### Phase 1: 課題案の一括提示（メイン実行）

1. Phase 0 の材料から課題候補を**一括提示**する。各候補に添えるもの:
   - 事象 / 原因 / 影響
   - system / flow 分類
   - flow 候補には delta 型 / 構造観察型の判定・worklog 記録状況・起票要否の提案（振り分け規則）
   - 既存 open 課題の再発・進展は新規候補とせず「検討状況」追記対象として提示
2. ユーザーが修正・追加・削除と起票判断を行う
3. 末尾に確認1問:「このサイクル中に言語化されたが未起票の気づき（会話中の指摘・見送った論点など）はありませんか？」（体系全体を走査する構造チェック工程は設けない）

### Phase 2: 記録保存と起票（メイン実行）

1. `docs/records/retrospectives/system/YYYY-MM-DD-<topic>.md`（メイン記録。テンプレートは `skills/retrospective/template.md`）と、起票したフロー課題があれば `flow/YYYY-MM-DD-<topic>.md`（`skills/retrospective/flow-template.md`）を書き出す（両フォルダで同名。フォルダ・ファイルはオンデマンド作成）
2. 起票対象の課題を**全件** `docs/working/issues/` へ起票する:
   1. インデックス `docs/working/issues/README.md` 全体（両セクション）の最大番号+1 で採番する
   2. `docs/working/issues/system|flow/NNNN-<slug>.md` を起票する（Status: open。課題内容は要約のみとし、「起票元」に `retrospectives/system|flow/YYYY-MM-DD-<topic>.md 課題#N` を記載）
   3. インデックスの対応セクションに1行追加する
   4. 振り返りファイル側の各課題項目に「**起票**: Issue-NNNN」行を記載する
3. 既存 open 課題の再発・進展の「検討状況」追記（`YYYY-MM-DD: 事象の要約`）を実施する
4. **`docs/records/retrospectives/README.md` の一覧へ行追加する（省略不可）**
5. ユーザーへ提示し確認を得る

### Phase 3: 仕上げ（メイン実行）

1. **（オプション）rubber-duck 独立レビュー**: ユーザーが求めた場合のみ、サブエージェント `rubber-duck` を1回呼び出す。プロンプトに含めるもの:
   - ドラフト全文（system/ と flow/ の両方）と対応 plan の内容・ADR 一覧
   - 「独立視点レビューであり、再生成や書き換えではない」旨
   - レビュー観点は「課題の抽出漏れがないか・system / flow 分類が妥当か」の2点に限定
   - 出力フォーマット指定（短い指摘のリスト形式、優先度タグ付き）

   結果はメインが受け取り、ユーザーと相談の上で反映する。やり取りは記録ファイルの「Independent Review Notes」節（実施時のみ追加）に記録する
2. **worklog 総ざらい確認（マイルストーン突合）**: サイクル中のマイルストーンと中央ストアのエントリを突合し、Post ラッパーの消化漏れを回収する:
   1. サイクル中のマイルストーンを列挙する。情報源は handoff の「Post ラッパー消化記録」と「完了済みタスク」、および当該ブランチの `git log`
   2. 各マイルストーンについて、消化記録に `worklog=` の記載（エントリ id または棄却）があるかを検査し、記載が無いものを未消化として洗い出す
   3. 中央ストア `<home>/.ai-dev-worklog/<project>/log.jsonl` の当該サイクル分エントリと、消化記録に記載された id を突合する
   4. 未消化のマイルストーンに delta（躓き・人間の指示）があれば `worklog-record` を呼んで記録し、無ければ消化記録へ棄却として1行補う
   5. 振り分け規則で「worklog 送り」とした delta 型候補の記録漏れもここで拾う

   本工程は、Post ラッパーに完全に入らなかった場合（消化記録の行そのものが無い）を回収する唯一の経路である（設計意図は `docs/current/specs/2026-05-01-retrospective-design.md` Phase 3 参照）
3. `session-handoff` の **cycle-reset** 操作を呼ぶ（剪定・書き換えの手順は session-handoff 側の定義に従う）:
   - Status は `in_progress` → `ready-for-next-cycle` へ遷移する
   - 「次セッション開始時のアクション」に「抽出した課題は issues に起票済み（Issue-NNNN〜。着手はユーザー判断）」旨を記す
   - 課題が複数ある場合は優先順位の目安を併記してよい（着手の決定はユーザー）

## 出力ファイル

- メイン記録: `docs/records/retrospectives/system/YYYY-MM-DD-<topic>.md`
- フロー課題記録: `docs/records/retrospectives/flow/YYYY-MM-DD-<topic>.md`（起票したフロー課題がある場合のみ）
- 課題起票: `docs/working/issues/system|flow/NNNN-<slug>.md` + `docs/working/issues/README.md` への行追加
- インデックス更新: `docs/records/retrospectives/README.md` に行追加（過去行の編集は禁止）
- テンプレ参照: `skills/retrospective/template.md`（メイン）/ `skills/retrospective/flow-template.md`（フロー）

## 対応する原則

- **原則1（追跡可能性）**: 課題の事象・原因・影響がサイクル単位で永続化され、issue の正本として参照される
- **原則2（関心の分離）**: 課題抽出（retrospective）と知見の再利用（worklog パイプライン）を消費経路で分離。対策の決定・実装は次サイクル
- **原則3（コンテキスト管理）**: 最小サイクル文脈により課題詳細が単独で理解可能。重複記録の排除でトークン消費を抑制
- **原則4（人間の関与）**: 起票判断・早期対処判断・rubber-duck 実施判断はユーザー / 自動トリガー禁止
- **原則5（漸進的検証）**: サイクル単位の課題抽出で AI駆動開発ガイドライン自体の検証ループを回す

## 関連

- 関連スキル: start-work, decision-log, session-handoff, worklog-record, worklog-extract
