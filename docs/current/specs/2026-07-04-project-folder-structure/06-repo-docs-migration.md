# ブロック06: repo-docs-migration — 本リポジトリ既存 docs の移行

## 1. 対象ファイル

- `docs/` 配下の既存ディレクトリ・ファイル全般（移動）
- `docs/working/issues/`（新規作成: open-questions からの課題移行）
- 生きているドキュメントのリンク・パス表記（修正）

## 2. 責務

本リポジトリの既存 docs を新レイアウトへ `git mv` で移行し（履歴を維持）、`docs/open-questions.md` を課題管理へ統合し、生きているドキュメントからのリンク切れを解消する（ドッグフーディング）。

## 3. インターフェース（移行マッピング）

| 現在 | 移行先 | 方法 |
|------|--------|------|
| `docs/specs/*` | `docs/current/specs/*` | git mv |
| `docs/plans/*` | `docs/working/plans/*` | git mv |
| `docs/handoff/*` | `docs/working/handoff/*` | git mv |
| `docs/decisions/*` | `docs/records/decisions/*` | git mv |
| `docs/retrospectives/*` | `docs/records/retrospectives/*` | git mv |
| `docs/principles.md` | `docs/overview/principles.md` | git mv |
| `docs/open-questions.md` | 廃止 → 項目を `docs/working/issues/0001-template-sync-asymmetry.md` へ移行 | 下記 |

### open-questions の課題移行

現在の未解決項目は1件:

> template 同期の非対称性 — `sync-template.ps1` は ADRインデックスを空生成するが、`docs/retrospectives/README.md` は repo固有の振り返り履歴行ごと verbatim コピーしてしまう（発生源: Theme B コードレビュー, 2026-06-15）

これを課題ファイル `docs/working/issues/0001-template-sync-asymmetry.md`（Status: open, Opened: 2026-06-15）としてブロック01 のフォーマットで起票し、インデックス `docs/working/issues/README.md` を新規作成する。その後 `docs/open-questions.md` を削除する。

### 補足

- `docs/records/retrospectives/` 直下に旧形式のフラットな振り返りファイル（2026-05-01, 2026-05-05）が存在する。これらは ADR-0021 以前の形式の歴史的記録であり、移動はするが `system/` `flow/` への再分類はしない（記録の不変性）
- `docs/inbox/` は空フォルダとして先行作成しない（オンデマンド規約に従い、最初の投入時に作られる。ただし利用者への案内は folder-structure.md に記載済み）

## 4. サブ機能 / 内部構成（リンク修正の方針）

- **修正する（生きているドキュメント）**: `README.md`、`CLAUDE.md`、`CONTRIBUTING.md`（以上はブロック04 で内容更新と同時に）、本仕様書ディレクトリ、アクティブな handoff（`feature_project-folder-structure.md`）、各インデックス（`docs/records/decisions/README.md`、`docs/records/retrospectives/README.md`）
- **修正しない（不変の記録）**: 過去の ADR 本文、retrospective 本文、完了済み handoff、過去の plan / spec の本文。これらの旧パス表記は「当時の事実」として残す（追跡型の記録の不変性を優先）
- 移行後、旧パス（`docs/specs/` `docs/plans/` `docs/handoff/` `docs/decisions/` `docs/retrospectives/` `docs/open-questions.md` `docs/principles.md`）への参照が生きているドキュメントに残っていないことを grep で確認する

## 5. データモデル

課題ファイル・インデックスのフォーマットはブロック01 の定義に従う。

## 6. このブロック固有の制約・前提

- 移動は必ず `git mv` で行い、リネーム履歴を保持する
- ブロック03（スキルのパス更新）と同一サイクルで完了させる（スキルと実フォルダの不整合期間を作らない）
- ファイル削除（open-questions.md）は不可逆操作のため、実装時に pre-action-review の承認手順を経る
- 本仕様書ディレクトリ自体は最初から `docs/current/specs/` に作成されており移行不要

## 7. 関連 ADR

- ADR-0025（全面再配置・自己適用・open-questions 統合）
- ADR-0011 / ADR-0021（retrospective の追記型規約・不変性）
- ADR-0019（未決事項の分離規律）
