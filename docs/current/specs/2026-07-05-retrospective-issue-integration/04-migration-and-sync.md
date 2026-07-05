# ブロック04: migration-and-sync — 既存課題の移行と template 同期

## 1. 対象ファイル

- `docs/working/issues/` 配下（既存 `0001-template-sync-asymmetry.md` の移動、新規6ファイルの起票、`README.md` のデータ行）
- `template/` 配下（`scripts/sync-template.ps1` の実行結果）

## 2. 責務

本 repo の既存課題を新構造へ移行し、2026-07-05 振り返りの未起票バックログ6件を起票する。全変更完了後に template を同期する。

## 3. 移行内容

### 3.1 既存課題の移動

- `docs/working/issues/0001-template-sync-asymmetry.md` → `docs/working/issues/system/0001-template-sync-asymmetry.md`（git mv。内容は変更しない）

### 3.2 移行起票（6件）

起票元は `docs/records/retrospectives/system|flow/2026-07-05-project-folder-structure.md`。課題内容は要約＋起票元参照。Opened は起票実施日。

| # | フォルダ | slug（案） | 対応する振り返り課題 |
|---|---------|-----------|-------------------|
| 0002 | system/ | sync-template-line-endings | system 課題 #2: sync-template.ps1 の改行コード非決定性 |
| 0003 | system/ | conversation-log-classification | system 課題 #1: conversation_log.md の分類 |
| 0004 | flow/ | question-tool-display-norm | flow 課題 #1: 質問ツールの表示特性が規範に未織り込み |
| 0005 | flow/ | selection-ui-misclick-confirmation | flow 課題 #2: 選択UIの誤操作が即「方針確定」扱い |
| 0006 | flow/ | cross-cutting-change-plan-coverage | flow 課題 #3: 横断的なパス変更で計画に網羅漏れ |
| 0007 | flow/ | retrospective-issue-integration | flow 課題 #4: 振り返り課題と issue 管理の関係が未定義（本サイクルの対象） |

- **0007 は本サイクルの対策対象そのもの**。open で起票し、実装完了・検証後（ADR-0028 の Accepted 昇格と同時）に「結論: ADR-0028」で close する
- 既存の振り返りファイルは書き換えない（ADR-0011）。移行分の参照は issue 側の「起票元」からの片方向のみ
- 番号順は起票時のインデックス採番に従う（上表の割り当ては目安。実装時にずれてよいが、通し連番・重複なしを守る）

### 3.3 インデックスの再構成

`docs/working/issues/README.md` をブロック01の2セクション形式に書き換え、0001（system, closed）と新規6件の行を配置する。

## 4. template 同期とプラグイン更新

1. 全ブロックの変更完了後に `scripts/sync-template.ps1` を実行する（対象: `docs/overview/folder-structure.md`、`docs/records/retrospectives/README.md`、空インデックス3種など）
2. 同期結果を確認する: `template/docs/working/issues/README.md` が2セクションの空テーブルになっていること
3. ユーザーへプラグイン更新を案内する: `/plugin marketplace update ai-driven-dev-principles`（skills/ の変更はこれを実行するまで実行環境に反映されない）

## 5. このブロック固有の制約・前提

- sync-template.ps1 には改行コード非決定性（CRLF 書き出し）の既知課題がある（Issue-0002 として本ブロックで起票）。同期実行時に改行差分のノイズが出る可能性があるが、その修正は本サイクルのスコープ外。差分確認時は内容差分と改行差分を区別すること
- 移行起票は1回限りの作業であり、スキル化しない
- `docs/working/issues/system/` `flow/` フォルダは Git 管理上ファイルが置かれた時点で生成される（空フォルダの placeholder は作らない。template 側も同様で、配布先では初回起票時にフォルダができる）

## 6. 関連 ADR

- ADR-0028（移行の根拠）/ ADR-0011（振り返りファイルを書き換えない根拠）
