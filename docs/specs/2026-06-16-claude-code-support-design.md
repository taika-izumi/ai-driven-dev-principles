# 設計仕様: Claude Code 対応（Layer 2 を CLAUDE.md に一本化）

- **日付**: 2026-06-16
- **関連 ADR**: ADR-0023
- **対象ブランチ**: feature/claude-code-support

## 目的

本リポジトリのガイドライン／スキルは GitHub Copilot CLI 向けに作られてきたが、今後 Claude Code でも利用する。両ツールで同一のガイドラインが機能する状態にする。

## 背景と調査結果

公式ドキュメントで確認した各ツールの既定読み込み挙動:

| ファイル | Copilot CLI | Claude Code |
|---|---|---|
| `.github/copilot-instructions.md` | 読む | 読まない |
| `AGENTS.md`（ルート） | 読む（primary） | ネイティブには読まない |
| `CLAUDE.md`（ルート） | 読む | 読む |

- プラグイン梱包（`.claude-plugin/plugin.json` + `marketplace.json`）とスキル（`skills/<name>/SKILL.md`）は元々 Claude Code ネイティブ形式であり、両ツールでそのまま動作する。**対応が必要なのは Layer 2 指示ファイルのみ**。
- `CLAUDE.md`（ルート）は両ツールが既定で読むため、Layer 2 をこれ1つに一本化する。

## スコープ

### 対象（変更する）

1. **Layer 2 ファイルの移設**
   - `.github/copilot-instructions.md` を削除し、内容をルート `CLAUDE.md` に移す。
   - Layer 2 ファイルは1つに統一する（両方残すと Copilot CLI が二重読み込みするため）。

2. **CLAUDE.md の文言中立化**
   - タイトル `# Copilot Instructions` → 中立名 `# プロジェクトエージェント指示`。
   - 「前提条件: Copilot CLI プラグインのインストール」節 → 両ツール向けの中立記述。プラグイン導入が必要な旨は共通とし、インストール手順は README の各ツール節（Copilot CLI / Claude Code）を参照させる。
   - 本文（システム設定〜5原則の行動指示、現行 15 行目以降）は既にツール非依存のため**変更しない**。

3. **`template.manifest` の更新**
   - `.github/copilot-instructions.md` エントリを `CLAUDE.md` に差し替える。
   - `template/.github/copilot-instructions.md` を削除し、`template/CLAUDE.md` を配置する（`sync-template.ps1` 実行で反映）。

4. **README の更新**
   - Layer 2 の表記を `CLAUDE.md` に更新（構造表・該当記述）。
   - 「Claude Code へのインストール」節を新設（既存の「Copilot CLI へのインストール」節は維持）。Claude Code のプラグイン導入手順（`/plugin marketplace add`、`/plugin install` 等）を記載。
   - 「新しいプロジェクトでの使い方」の前提条件・手順で、コピー対象が `CLAUDE.md` であることを反映。

5. **`CONTRIBUTING.md` の更新**
   - 設計思想の Layer 2 行（`.github/copilot-instructions.md` → `CLAUDE.md`）。
   - シナリオ見出し「copilot-instructions.md を更新するとき」を「CLAUDE.md を更新するとき」に変更し、本文中の参照・「Copilot固有」表現を両ツール対応の表現に更新。

6. **スキルの更新**
   - `skills/start-work/SKILL.md`: 「`copilot-instructions.md` でも宣言されている」→ `CLAUDE.md`。
   - `skills/extend-guidelines/SKILL.md`: description と本文の `copilot-instructions.md` 参照、テンプレート同期案内の判定条件を `CLAUDE.md` ベースに更新。

7. **`sync-template.ps1` の確認**
   - CLAUDE.md は通常の manifest 同期対象になるため、生成ロジックの追加は不要。manifest 更新のみで動作することを確認する（必要なら軽微修正）。

### 対象外（変更しない）

- 既存の ADR（0001〜0022）。歴史的記録として保持。
- 過去の `docs/specs/`・`docs/plans/`（日付付きの歴史的設計記録）。
- `docs/principles.md`（Layer 1、ツール非依存。原則自体に変更なし）。
- `.claude-plugin/`、`skills/<name>/SKILL.md` のプラグイン／スキル形式（既に両ツール互換）。

## 影響を受けるファイル一覧

| ファイル | 操作 |
|---|---|
| `CLAUDE.md`（新規・ルート） | 作成（旧 copilot-instructions.md の内容＋中立化） |
| `.github/copilot-instructions.md` | 削除 |
| `template.manifest` | エントリ差し替え |
| `template/CLAUDE.md` / `template/.github/copilot-instructions.md` | sync-template 実行で置換 |
| `README.md` | Layer 2 表記更新＋Claude Code 節追加 |
| `CONTRIBUTING.md` | Layer 2 行・シナリオ更新 |
| `skills/start-work/SKILL.md` | 参照更新 |
| `skills/extend-guidelines/SKILL.md` | description・本文・同期案内更新 |
| `docs/decisions/0023-*.md` | 既に作成済（実装完了後に Accepted 昇格） |

## 検証

1. **網羅性チェック**: リポジトリ全体（ADR・過去 spec/plan を除く現行ドキュメントとスキル）に `copilot-instructions` 参照が残っていないことを `grep` で確認する。
2. **template 同期**: `pwsh scripts/sync-template.ps1` を実行し、`template/CLAUDE.md` が生成され `template/.github/copilot-instructions.md` が存在しないことを確認する。
3. **読み込み確認**: Copilot CLI がルート `CLAUDE.md` を Layer 2 として読むことを動作確認する（公式記載済みだが念のため。可能な範囲で）。
4. **内容同一性**: CLAUDE.md の本文（5原則の行動指示）が旧 copilot-instructions.md と意味的に同一であることを確認する。

## 完了条件

- ルート `CLAUDE.md` が存在し、`.github/copilot-instructions.md` が削除されている。
- README に Claude Code インストール節があり、Layer 2 表記が CLAUDE.md に統一されている。
- CONTRIBUTING・start-work・extend-guidelines の参照が更新されている。
- `sync-template.ps1` 実行後、`template/` に CLAUDE.md が配置されている。
- 現行ドキュメント・スキルに `copilot-instructions` の残留参照がない（歴史的記録を除く）。
- ADR-0023 が Accepted に昇格している。
