# ブロック05: template-sync-update — テンプレート配布機構の新構成対応

## 1. 対象ファイル

- `template.manifest`
- `scripts/sync-template.ps1`
- `template/`（同期スクリプトの実行結果として再生成される）

## 2. 責務

テンプレート配布機構（manifest 駆動の完全同期＋ADRインデックス空生成）を新フォルダレイアウトに対応させ、新規プロジェクトが最初から新構成でセットアップされるようにする。

## 3. インターフェース

### テンプレート初期セットの基準（ADR-0027）

- **シードする**: ユーザーが直接ファイルを置く・参照するフォルダ（issues, inbox）と、空のインデックスが最初から必要なフォルダ（decisions, retrospectives）
- **シードしない**: スキルが実行時に自動作成するフォルダ（handoff, plans, specs 等）

### template.manifest（変更後の内容 = verbatim コピー対象のみ）

```
CLAUDE.md
docs/overview/principles.md
docs/overview/folder-structure.md
docs/overview/issue-management.md
docs/inbox/README.md
```

（`docs/principles.md` → `docs/overview/principles.md` へのパス変更、`docs/overview/folder-structure.md`・`docs/overview/issue-management.md`・`docs/inbox/README.md` の新規追加。`docs/retrospectives/README.md` は verbatim コピー対象から外れ、下記の空インデックス生成へ移行。skills/ を含めない規約は ADR-0016 のまま維持）

### scripts/sync-template.ps1

- 空インデックス生成ロジックを一般化し、以下の3ファイルに適用する（説明文・見出し・表ヘッダーは保持し、インデックスのデータ行と、表直後の repo 固有の注記引用ブロックを除去する）:
  - `docs/records/decisions/README.md`（従来の ADR インデックス空生成の移行）
  - `docs/records/retrospectives/README.md`（従来は verbatim コピーだったものを空生成に変更 — 既知課題「インデックス同期の非対称性」の解消）
  - `docs/working/issues/README.md`（新規）
- それ以外のロジック（manifest 駆動コピー、template/ の全削除→再生成、UTF-8 no BOM 出力）は変更しない

## 4. サブ機能 / 内部構成

変更なし（既存の同期フローを維持）。

## 5. データモデル

なし。

## 6. このブロック固有の制約・前提

- ブロック04（CLAUDE.md / principles.md の内容更新）とブロック06（実ファイルの移動）の完了後にスクリプトを実行し、template/ を再生成する
- 完了検証: スクリプトを2回実行して2回目が差分ゼロであること（冪等性）。`git status` で template/ 配下の意図しない残骸（旧パス `template/docs/principles.md` 等）が無いこと。生成された3インデックスがいずれも空（データ行ゼロ）であること
- 本ブロックの空生成一般化により、既知課題「インデックス同期の非対称性」は解消される（該当課題ファイルの扱いはブロック06 を参照）

## 7. 関連 ADR

- ADR-0003（テンプレートフォルダとマニフェスト同期方式）
- ADR-0016（skills/ の template 除外）
- ADR-0025（新レイアウト）
- ADR-0027（テンプレート初期セット基準・空インデックス生成の一般化）
