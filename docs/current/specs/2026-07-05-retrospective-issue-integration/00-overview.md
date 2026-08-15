# 振り返り課題と issue 管理の統合 — 概要

- **Date**: 2026-07-05
- **Branch**: feature/retrospective-issue-integration
- **Related ADR**: ADR-0028（起点: フロー課題 #4、`docs/records/retrospectives/flow/2026-07-05-project-folder-structure.md`）

## 1. このドキュメントの読み方

| ファイル | 内容 |
|---------|------|
| `00-overview.md`（本ファイル） | 背景、全体アーキテクチャ、処理フロー、意思決定、スコープ外、完了基準 |
| `01-issue-management-structure.md` | issues の system/flow フォルダ構造・課題ファイルフォーマット・インデックス形式の規約 |
| `02-retrospective-ticketing.md` | retrospective スキルへの起票手順の統合 |
| `03-related-doc-consistency.md` | 課題管理を参照する周辺文書の整合更新 |
| `04-migration-and-sync.md` | 本 repo の既存課題の移行と template 同期 |

## 2. 背景・動機

課題の置き場が「振り返り記録（`docs/records/retrospectives/system|flow/`、追記型・ライフサイクル管理なし）」と「課題管理（`docs/working/issues/`、open/closed 管理あり・分類構造なし）」の2系統に分かれ、起票基準・分類表現・相互参照が未定義だった（フロー課題 #4）。このため振り返り由来の課題に open/closed 管理が適用されず、見落とし・二重管理のリスクがあった。

本サイクルで、振り返り課題を全件 issue として起票する統合ルールと、issues の system/flow フォルダ分割を導入する（ADR-0028）。

## 3. 全体アーキテクチャ

### 機能ブロック一覧

| # | ブロック | 責務 | 依存 |
|---|---------|------|------|
| 01 | issue-management-structure | issues のフォルダ構造・フォーマット・インデックス規約の定義 | なし |
| 02 | retrospective-ticketing | retrospective スキルのドラフト保存段階への起票手順の統合 | 01 |
| 03 | related-doc-consistency | 課題管理を参照する周辺文書（スキル・シナリオ・spec）の整合 | 01 |
| 04 | migration-and-sync | 本 repo の既存課題の移行起票と template 同期 | 01 |

### ブロック間関係

```
01 issue-management-structure（規約の定義）
 ├─→ 02 retrospective-ticketing（規約に従って起票する側）
 ├─→ 03 related-doc-consistency（規約を参照する文書群）
 └─→ 04 migration-and-sync（規約に従って既存課題を移行）
```

依存は 01 からの一方向のみ。02/03/04 は相互に独立。

## 4. 主要な処理フロー

### 4.1 振り返り由来の課題（新規メインフロー）

1. retrospective スキルが課題を抽出し「対象システム固有 / 開発フロー」に分類する（従来どおり。ADR-0021）
2. 分類確定後その場で、インデックス最大番号+1 で採番し、`docs/working/issues/system|flow/NNNN-<slug>.md` を起票する（課題内容は要約＋起票元参照）
3. インデックス `docs/working/issues/README.md` の対応セクションに1行追加する
4. 振り返りファイルの各課題に「起票: Issue-NNNN」行を初回書き込み時点で記載する（上書き禁止規約 ADR-0011 と衝突しない）

### 4.2 議論由来の課題（従来フロー、パスのみ変更）

ADR 検討中の未決事項などは従来どおり `decision-log` スキルの手順で起票する。配置先が `system|flow` フォルダになる点のみ変わる（大半は system）。課題内容は本文に直接書く。

### 4.3 close フロー

- system 課題: 対策方針の決定 → ADR 作成 → 課題の「結論」に ADR 番号を記載して close（従来どおり）
- flow 課題（本 repo = ガイドライン repo）: 同上
- flow 課題（配布先システム開発 repo）: ガイドライン repo へ申し送り済み（または対応済み）で close

## 5. 設計上の主要な意思決定

すべて ADR-0028 に記録済み。要点:

- 振り返り時に全件起票（issues が唯一の課題一覧になる）
- `docs/working/issues/` を `system/` `flow/` に分割（振り返り記録の2フォルダ ADR-0021 と対称）
- 採番は両フォルダ通し連番、インデックスはルート README 1つ（2セクション）
- 振り返り由来の課題は要約＋起票元参照（詳細は振り返りファイルが正）
- 配布先 repo でも全件ローカル起票で統一

関連する既存決定: ADR-0011（追記型規約）/ ADR-0019（未決事項の分離）/ ADR-0021（抽出限定スコープ — 本設計でも維持）/ ADR-0025（課題管理の導入元）

## 6. スコープ外（YAGNI）

- 旧型式の単一ファイル spec（`2026-05-01-retrospective-design.md` 等）の書き換え・整理方針の設計（未定義であることの課題起票のみブロック04で行う）
- handoff にのみあるバックログ（Theme C 用語集など「未着手の作業テーマ」）の issue 化 — 課題ではないため対象外
- 2026-06-15 以前の旧方式振り返り（採用提案方式）からの遡及起票
- 課題のアーカイブ機構（closed のまま残す現行方針を維持）
- sync-template.ps1 の改行コード非決定性の修正（システム課題 #2。独立課題として扱う）

## 7. 完了基準

1. `docs/overview/folder-structure.md` §7 が課題管理定義（`docs/overview/issue-management.md`）への早見表を持ち、同定義が新構造（system/flow・起票元フィールド・2セクションインデックス・通し採番）を定義している
2. `skills/retrospective/SKILL.md` と2テンプレートに起票手順が統合され、抽出限定スコープ（ADR-0021）の記述が維持されている
3. `skills/decision-log/SKILL.md`・`CONTRIBUTING.md`・`docs/records/retrospectives/README.md`・`docs/current/specs/2026-07-04-project-folder-structure/01-folder-structure-definition.md` の課題管理参照が新構造と一致している
4. 既存課題 Issue-0001 が `system/` に移動し、2026-07-05 振り返りの6課題＋旧型式 spec 方針の課題1件が起票済み（0007 は本サイクル完了時に ADR-0028 で close）
5. `scripts/sync-template.ps1` 実行後の `template/` が新構造を反映している（issues インデックスは2セクションの空テーブルで生成される）
6. リポジトリ全体 grep で旧構造（`docs/working/issues/NNNN` 直下形式）への参照が残っていない
