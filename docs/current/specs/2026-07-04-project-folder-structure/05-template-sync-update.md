# ブロック05: template-sync-update — テンプレート配布機構の新構成対応

## 1. 対象ファイル

- `template.manifest`
- `scripts/sync-template.ps1`
- `template/`（同期スクリプトの実行結果として再生成される）

## 2. 責務

テンプレート配布機構（manifest 駆動の完全同期＋ADRインデックス空生成）を新フォルダレイアウトに対応させ、新規プロジェクトが最初から新構成でセットアップされるようにする。

## 3. インターフェース

### template.manifest（変更後の内容）

```
CLAUDE.md
docs/overview/principles.md
docs/overview/folder-structure.md
docs/records/retrospectives/README.md
```

（`docs/principles.md` → `docs/overview/principles.md` へのパス変更、`docs/overview/folder-structure.md` の新規追加、`docs/retrospectives/README.md` → `docs/records/retrospectives/README.md` へのパス変更。skills/ を含めない規約は ADR-0016 のまま維持）

### scripts/sync-template.ps1

- ADR インデックスの source / dest パスを `docs/records/decisions/README.md` / `template/docs/records/decisions/README.md` に変更（`$adrIndexSource` / `$adrIndexDest` の組み立て箇所）
- それ以外のロジック（manifest 駆動コピー、template/ の全削除→再生成、空インデックス生成、UTF-8 no BOM 出力）は変更しない

## 4. サブ機能 / 内部構成

変更なし（既存の同期フローを維持）。

## 5. データモデル

なし。

## 6. このブロック固有の制約・前提

- ブロック04（CLAUDE.md / principles.md の内容更新）とブロック06（実ファイルの移動）の完了後にスクリプトを実行し、template/ を再生成する
- 完了検証: スクリプトを2回実行して2回目が差分ゼロであること（冪等性）。`git status` で template/ 配下の意図しない残骸（旧パス `template/docs/principles.md` 等）が無いこと
- 既知の課題（同期の非対称性: ADRインデックスは空生成、retrospectives README は repo 固有行ごとコピー）の解消は本ブロックのスコープ外。ブロック06 で課題ファイルとして移行し存続させる

## 7. 関連 ADR

- ADR-0003（テンプレートフォルダとマニフェスト同期方式）
- ADR-0016（skills/ の template 除外）
- ADR-0025（新レイアウト）
