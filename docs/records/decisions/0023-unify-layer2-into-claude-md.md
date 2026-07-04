# ADR-0023: Layer 2 指示ファイルを CLAUDE.md に一本化し Claude Code / Copilot CLI 両対応にする

- **Status**: Accepted
- **Date**: 2026-06-16

## Context

本リポジトリの Layer 2（AIエージェント向け行動指示）は `.github/copilot-instructions.md` に置かれ、GitHub Copilot CLI 専用に書かれてきた。今後 Claude Code でも本ガイドラインを利用する想定が生まれ、対応要否を調査した。

公式ドキュメントで確認した各ツールの既定読み込み挙動は以下のとおり:

| ファイル | GitHub Copilot CLI | Claude Code |
|---|---|---|
| `.github/copilot-instructions.md` | 読む | 読まない |
| `AGENTS.md`（ルート） | 読む（primary 扱い） | ネイティブには読まない |
| `CLAUDE.md`（ルート） | 読む（"Alternatively, you can use CLAUDE.md … at the root"） | 読む |

調査の結果、プラグイン梱包（`.claude-plugin/`）とスキル（`skills/<name>/SKILL.md` の YAML フロントマター形式）は元々 Claude Code ネイティブ形式であり、両ツールでそのまま機能することが分かった。対応が必要なのは Layer 2 指示ファイルのみだった。

`CLAUDE.md`（リポジトリルート）は Copilot CLI と Claude Code の双方が既定で読むため、これを単一の Layer 2 ファイルにできる。

## Considered Alternatives

| # | 案 | 評価 |
|---|---|---|
| 1 | sync-template.ps1 で copilot-instructions.md から CLAUDE.md を変換生成（マーカー区切り＋fail-fast 検証） | 両ファイルを維持できるがビルド工程と置換保守が必要。CLAUDE.md が両ツール対応と判明したため過剰 |
| 2 | AGENTS.md を単一ソース＋CLAUDE.md は `@AGENTS.md` インポート | ベンダー中立の標準名で拡張性が高いが、Claude Code は AGENTS.md をネイティブに読まずインポート経由の間接依存とファイル2つが残る |
| 3 | **CLAUDE.md 一本化（採用）** | 両ツールが既定で読む単一ファイル。生成スクリプト不要・重複ゼロ・最も単純 |

## Decision

**Layer 2 を単一ファイル `CLAUDE.md`（リポジトリルート）に一本化する（案3）。** 具体的には:

1. `.github/copilot-instructions.md` を廃止し、内容をルート `CLAUDE.md` へ移す。両方を残すと Copilot CLI が二重読み込みするため、Layer 2 ファイルは1つに統一する。
2. ツール固有の文言を中立化する。タイトル `# Copilot Instructions` を中立名にし、「前提条件: Copilot CLI プラグインのインストール」節を両ツール（Copilot CLI / Claude Code）向けの記述に改める。インストール手順は README の各ツール節へ参照させる。
3. 本文（5原則の行動指示）は既にツール非依存のため変更しない。
4. `template.manifest` の `.github/copilot-instructions.md` エントリを `CLAUDE.md` に差し替え、`template/` 側も同様に置き換える。
5. README に「Claude Code へのインストール」節を追加し、Layer 2 表記を CLAUDE.md に更新する。
6. `CONTRIBUTING.md` と各スキル（`start-work`, `extend-guidelines`）の `copilot-instructions.md` 参照を CLAUDE.md ベースへ更新する。
7. AGENTS.md は Claude Code がネイティブに読まないため採用しない。

当初検討していた「sync-template.ps1 への CLAUDE.md 生成ロジック組み込み」は、CLAUDE.md が両ツール対応と判明したため不要となり、方針を転換した。

## Consequences

### 良い影響

- Copilot CLI と Claude Code の双方で、追加の変換・生成工程なしに同一の Layer 2 指示が機能する。
- Layer 2 ファイルが1つになり、二重管理・置換保守・ビルド工程が一切不要（原則1 追跡可能性と整合）。
- template が単一の CLAUDE.md を配るだけで両ツール対応のプロジェクトを作れる。

### 悪い影響 / 留意点

- `.github/copilot-instructions.md` という Copilot の正式機構を手放す。GitHub.com の Copilot コーディングエージェント（CLI 以外）はルート `CLAUDE.md` を読まない可能性があり、その用途が必要になれば別途 AGENTS.md 等の再検討が要る。
- Layer 2 ファイル名が `CLAUDE.md` であり、Copilot CLI 利用者には名称上の違和感が残る（機能上は問題なし）。
- ADR-0016 等が前提としていた「Layer 2 = copilot-instructions.md」という記述は歴史的記録として残るが、本 ADR 以降の正は CLAUDE.md である。

### 派生する将来 ADR 候補

- GitHub.com Copilot コーディングエージェント対応が必要になった場合の Layer 2 配布方式（AGENTS.md 併設の再検討）。
