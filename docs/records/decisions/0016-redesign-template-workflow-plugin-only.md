# ADR-0016: template ワークフローの再設計（skills/ を除外し、プラグイン一本化）

- **Status**: Accepted（ADR-0023 / 0027 で一部改定: Layer 2 は CLAUDE.md、manifest の内容は ADR-0027 のシード基準で再定義）
- **Date**: 2026-05-04

## Context

ADR-0015 により本リポジトリは Copilot CLI プラグインとして配信可能になり、利用者は `extraKnownMarketplaces` 経由でスキル群（`start-work`, `decision-log` ほか）を構造化呼び出しで利用できるようになった。

一方、本リポジトリは `template/` ディレクトリと `template.manifest` により「新規プロジェクトに中身をコピーして使う」テンプレート機能も提供しており、現状の `template.manifest` には以下が含まれている:

```
.github/copilot-instructions.md
docs/principles.md
skills/decision-log/SKILL.md
skills/pre-action-review/SKILL.md
skills/start-work/SKILL.md
skills/session-handoff/SKILL.md
skills/feature-block-design/SKILL.md
skills/retrospective/SKILL.md
skills/retrospective/template.md
docs/retrospectives/README.md
```

ここで問題となるのは、コピー先プロジェクトに置かれた `skills/` ファイルは Copilot CLI からは認識されないという事実である。Copilot CLI は `~/.copilot/installed-plugins/<marketplace>/<plugin>/skills/` のみを `skill:` ツール経由のスキルソースとして扱うため、コピー先のローカル `skills/` は事実上「人間の参考資料」「カスタマイズ出発点」「冗長コピー」のいずれかにしかならない。

公開インストール一本化（ADR-0015 でプラグイン化済）により、利用者は1度プラグインを有効化すればすべてのプロジェクトで同じスキル群が使えるため、`template/` 配下に `skills/` を持つことの実質的価値は低下した。同時に二重管理（本リポジトリの `skills/` と template コピー後の `skills/`）はメタ・原則1（追跡可能性）と摩擦を生む。

## Considered Alternatives

| # | 案 | 評価 |
|---|---|---|
| α | 現状維持（template に skills/ を残す） | コピー先 skills/ が冗長、二重管理コスト残存、利用者が「コピー先 skills/ を編集すれば反映される」と誤解するリスク |
| β | **skills/ を template.manifest から除外、プラグイン一本化（採用）** | 中央管理に統一、template が軽量化、誤解リスク排除。利用者にプラグインインストールを必須化 |
| γ | β と同じ + README に手厚い案内 | β と本質同じ。README 整備の度合いの違い |
| δ | 両対応（skills/ も残しつつプラグイン紹介） | 柔軟だが二重管理は残存、混乱要因 |

## Decision

**案β を採用する。** 具体的には:

1. **`template.manifest` から skills/ 関連エントリを除去**
   - 削除対象: `skills/decision-log/SKILL.md`, `skills/pre-action-review/SKILL.md`, `skills/start-work/SKILL.md`, `skills/session-handoff/SKILL.md`, `skills/feature-block-design/SKILL.md`, `skills/retrospective/SKILL.md`, `skills/retrospective/template.md`
   - 保持: `.github/copilot-instructions.md`, `docs/principles.md`, `docs/retrospectives/README.md`
2. **`template/skills/` ディレクトリを削除**（同期スクリプトでも再生成されないようにする）
3. **`copilot-instructions.md` テンプレ側に「本ガイドラインを使うには Copilot CLI プラグイン `ai-driven-dev-principles` のインストールが必要」と明記する**
4. **README に「テンプレート利用の前提条件」節を追加**
   - プラグインインストール手順への誘導
   - 「コピー先で skills/ を編集してもスキル動作には影響しない」旨の注意
5. **本リポジトリ自身の `skills/` ディレクトリは保持**（プラグインのソース実体として必要）
6. **CONTRIBUTING.md にスキル変更時の注意を追記**
   - スキル変更は本リポジトリの `skills/` のみを編集する
   - template コピー先で skills/ を編集しても本家には反映されない
   - 改善は PR で本リポジトリへ還元する

## Consequences

### 良い影響

- 二重管理が解消し、スキル定義のシングルソース化が実現
- template が軽量化（10ファイル → 3ファイル）
- 利用者は1回プラグインインストールすれば全プロジェクトで同じガイドラインが使える
- スキルのバージョンアップが利用者全員に同時反映される（プラグイン更新 1 回）
- 「コピー先 skills/ を編集して反映されない」という誤解が構造的に発生しなくなる

### 悪い影響 / 留意点

- 利用者にプラグインインストールという追加ステップを必須化する（ハードル上昇）
- プラグイン未インストール環境では `copilot-instructions.md` が指示するスキルが機能しない（明示的な前提条件として README で警告）
- 既に template をコピー済の既存プロジェクトは、次回テンプレ同期時に `skills/` が消えることになる（移行ガイドが必要）
- オフライン/隔離環境ではプラグインインストールが困難な場合がある（ローカル clone + `copilot plugin marketplace add <local-path>` で対応可、別途案内）

### 派生する将来 ADR 候補

- 既存テンプレ利用プロジェクトの移行ガイド（CONTRIBUTING に節追加で済む可能性大、ADR 不要かも）
- プラグインバージョニング規約（ADR-0015 の派生として既出）
- オフライン環境向け配布方式
