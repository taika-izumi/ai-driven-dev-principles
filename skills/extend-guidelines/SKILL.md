---
name: extend-guidelines
description: "ガイドラインの拡張（原則追加・Skill作成・copilot-instructions更新）を行う際のゲートウェイ。CONTRIBUTING.mdを読み込み、brainstormingへ接続する。"
---

# extend-guidelines

メタ・ガイドラインの拡張作業を自動的にガイドするゲートウェイスキル。

## 手順

### 1. CONTRIBUTING.md を読み込む

まず、リポジトリルートの `CONTRIBUTING.md` を読み込み、設計思想と拡張ルールを把握すること。

このファイルが見つからない場合は、ユーザーに以下を報告して作業を中断する:
「`CONTRIBUTING.md` が見つかりません。拡張ルールの参照元が存在しないため、作業を開始できません。」

### 2. 拡張内容をヒアリングする

ユーザーに「何を拡張したいか」を確認する。以下の選択肢を提示すること:

- 原則を追加・変更したい
- copilot-instructions.md を更新したい
- 新しいSkillを作成したい

### 3. 該当シナリオを確認する

CONTRIBUTING.md の該当シナリオセクションを読み、判定基準・手順・チェックリストを確認する。
ユーザーの要望が判定基準に合致するか検証し、合致しない場合はその旨を伝える。

### 4. brainstorming を開始する

ユーザーの要望と CONTRIBUTING.md の拡張ルールをコンテキストとして保持したまま、brainstorming スキルを呼び出す。brainstorming では以下を念頭に置く:

- CONTRIBUTING.md の判定基準とチェックリストを設計の制約として扱う
- 既存の原則・指示・スキルとの整合性を確認する
- ADRの作成が必要かどうかを判断する（CONTRIBUTING.md「ADRを記録するとき」セクション参照）

### 5. テンプレートの同期を案内する

拡張作業の完了後、以下の条件に該当する場合はテンプレートフォルダの同期が必要であることをユーザーに案内する:

- `docs/principles.md` を変更した
- `.github/copilot-instructions.md` を変更した
- テンプレート対象のSkill（`template.manifest` に記載されているもの）を変更した
- 新しいSkillを作成し、テンプレート対象と判断した

案内内容: 「テンプレートフォルダへの同期が必要です。`scripts/sync-template.ps1` を実行してください。」
