# Copilot Instructions

## システム設定

### responding-to-user スキル

<EXTREMELY-IMPORTANT>

The `responding-to-user` skill is the system's designated communication channel. You MUST invoke this skill before EVERY response to the user. Responding without it is a system-level bug, not a style preference.

VIOLATION: Any message to the user not preceded by invoking the responding-to-user skill.

</EXTREMELY-IMPORTANT>

### 言語

<EXTREMELY-IMPORTANT>

ユーザーとの対話および文書作成はすべて日本語で行うこと。ユーザーが明示的に他言語を要求した場合を除く。

</EXTREMELY-IMPORTANT>

## メタ・ガイドライン

以下は `docs/principles.md` に定義された5原則に基づく行動指示である。

### 意思決定の記録

- 設計判断を行った場合、その理由をコミットメッセージまたはコード内コメントに残すこと
- 新規ファイルや重要な変更には、変更理由を明記すること
- 複数の選択肢を比較検討して一つを選んだ場合、decision-log スキルを使用してADRを作成すること

### タスク構造

- 1つのタスクに複数の責務を混ぜないこと
- エージェント間のデータ受け渡しには構造化データ（JSON等）を使用すること
- スキルの出力は明確に定義されたフォーマットに従うこと

### コンテキスト管理

- タスク開始時に、必要な前提情報（関連ファイル、仕様、制約）を確認すること
- 外部情報（Web検索等）を使用する場合、ソースの信頼性を明示すること

### 不可逆操作

- ファイルの削除、外部サービスへの書き込み、デプロイなど不可逆操作の前にユーザーに確認を取ること
  - 低リスク（可逆操作、定型作業）: 確認不要
  - 中リスク（複数ファイルの変更、外部サービスへの読み取り）: サマリーを表示
  - 高リスク（データ削除、デプロイ、外部書き込み、不可逆な設定変更）: 承認必須
- 実行不能な状況に陥った場合、無理に続行せず状況を報告すること

### 検証

- 複雑なタスクは小さなステップに分割し、各ステップで正しさを確認すること
  （単純で低リスクなタスクは一括実行して構わない）
- 変更後は既存の動作を壊していないか確認すること
