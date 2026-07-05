# ブロック01: issue-management-structure — 課題管理の構造規約

## 1. 対象ファイル

- `docs/overview/folder-structure.md` — §2 分類表・§4 ディレクトリツリー・§6 配置表・§7 課題（issue）管理・§8 運用例の該当箇所（template 対象）
- `docs/working/issues/README.md` — インデックスの2セクション化（実データの移行はブロック04）

## 2. 責務

課題管理の物理構造（フォルダ・ファイル・インデックス）と記述規約を定義する。他ブロックはすべて本ブロックの規約を参照する。

## 3. インターフェース（規約）

### 3.1 フォルダ構造

```
docs/working/issues/
  README.md          # インデックス（唯一）。system / flow の2セクション
  system/            # 対象システム固有の課題
    NNNN-<slug>.md
    NNNN-<slug>/     # フォルダ昇格時（課題ファイルをフォルダ内 README.md にする。従来どおり）
  flow/              # 開発フロー/ガイドライン課題
    NNNN-<slug>.md
    NNNN-<slug>/
```

- フォルダ名は振り返り記録の2フォルダ（`retrospectives/system|flow/`、ADR-0021）と揃える
- `flow/` は、配布先のシステム開発 repo ではガイドライン repo への申し送り対象を表す
- 課題ファイルに分類フィールドは設けない（フォルダが分類を表す）。分類を変える場合はファイル移動＋インデックスの行移動

### 3.2 採番

- NNNN は4桁ゼロ埋め連番。**両フォルダ通し**で一意（Issue-NNNN の参照が repo 内で一意になる）
- 採番はインデックス `README.md` 全体（両セクション）の最大番号+1

### 3.3 課題ファイルのフォーマット

```markdown
# Issue-NNNN: <タイトル>

- **Status**: open | closed
- **Opened**: YYYY-MM-DD
- **Closed**: YYYY-MM-DD（closed 時のみ）
- **起票元**: <起票のきっかけへの参照>（任意。振り返り由来なら「retrospectives/flow/YYYY-MM-DD-<topic>.md 課題#N」の形式）
- **関連**: ADR-NNNN 等（あれば）

## 課題内容

（振り返り由来: 要約のみ書き、事象/原因/影響の詳細は起票元の振り返りファイルを正とする。
　議論由来: 何が問題か・なぜケアが必要かを直接書く。TBD を積極的に使ってよい）

## 検討状況

（対策検討の経過。長期化したらフォルダ昇格を検討）

## 結論

（closed 時: 下した決定への参照。決定内容自体は ADR に書く。
　配布先 repo の flow 課題は「ガイドライン repo へ申し送り済み（または対応済み）」の旨を書く）
```

### 3.4 インデックス形式

`docs/working/issues/README.md` はフォルダに対応する2セクション構成。テーブル列は従来どおり（# / タイトル / Status / Opened）。リンク先は `system/NNNN-<slug>.md` 形式。

```markdown
# 課題（Issues）

進行中・クローズ済みの課題のインデックス。運用ルールは `../../overview/folder-structure.md` の「課題（issue）管理」を参照。
採番は両セクション通しの連番（全体の最大番号+1）。

## 対象システム固有の課題（system/）

| # | タイトル | Status | Opened |
|---|---------|--------|--------|

## 開発フロー/ガイドライン課題（flow/）

配布先のシステム開発 repo では、このセクションの open 課題がガイドライン repo への申し送り対象になる。

| # | タイトル | Status | Opened |
|---|---------|--------|--------|
```

### 3.5 close 条件

- system 課題: 対策方針の決定 → ADR 作成 → 「結論」に ADR 番号を記載して close（従来どおり）
- flow 課題（ガイドライン repo 自身）: 同上
- flow 課題（配布先 repo）: ガイドライン repo へ申し送り済み（または対応済み）で close

## 4. folder-structure.md の更新箇所

- §4 ディレクトリツリー: `issues/` の下に `system/` `flow/` を追記
- §6 配置表: 「課題・未決事項」行の配置先を `docs/working/issues/system|flow/` に更新
- §7 課題（issue）管理: 本ブロック 3.1〜3.5 の内容へ全面書き換え（フォーマット・インデックス例を含む）
- §8 運用例: 課題起票のパス表記を新構造に合わせる（フローは不変）
- §11 関連 ADR: ADR-0028 を追加

## 5. このブロック固有の制約・前提

- `scripts/sync-template.ps1` の空インデックス生成は汎用実装（全テーブルのデータ行を除去、見出し・セクションは保持）のため、2セクション形式に**変更不要で対応済み**（確認済み）。配布先 repo は空の2セクションインデックスから始まる
- folder-structure.md は template 対象。変更後にブロック04で同期する

## 6. 関連 ADR

- ADR-0028（本設計の決定）/ ADR-0025（課題管理の導入元）/ ADR-0021（system/flow 分類の由来）/ ADR-0019（未決事項の分離先）
