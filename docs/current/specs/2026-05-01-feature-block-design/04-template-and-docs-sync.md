# 機能ブロック B4: テンプレート同期と周辺ドキュメント更新

- **対象ファイル**:
  - `template/` 配下（`scripts/sync-template.ps1` 経由で同期）
  - `README.md`
  - `CONTRIBUTING.md`

## 責務

B1〜B3 の変更を `template/` に同期し、新規プロジェクトでも本サブプロジェクトの成果物（新スキル、原則拡張、instructions 追記）が利用可能な状態にする。
あわせて README / CONTRIBUTING を更新し、新スキルと運用ルールを明示する。

## 変更内容

### B4-1. `template/` の同期

実行コマンド: `powershell scripts/sync-template.ps1`

期待される同期対象（B1〜B3 の変更が反映される）:

- `template/skills/feature-block-design/SKILL.md`（新規生成）
- `template/.github/copilot-instructions.md`（B3 の追記が反映）
- `template/docs/principles.md`（B2 の修正が反映）

同期後の検証:
- `git status` で意図通りのファイルだけが変更されていること
- 差分が B1〜B3 で意図した変更と一致すること

### B4-2. `README.md` の更新

`## スキル` の表に新スキルを追加する:

```markdown
| [`feature-block-design`](skills/feature-block-design/) | brainstorming と writing-plans の間で、システムを機能ブロックに分割し分割仕様書を作成・更新する |
```

並び順は既存 5 スキルとの関連性を考慮し、`session-handoff` の下、`decision-log` の上に配置する（運用フロー順）。

### B4-3. `CONTRIBUTING.md` の更新

`## スキル追加時のチェックリスト` 等の既存セクションがあれば、新スキル追加時に踏むべき手順との整合を確認し、必要なら微修正する。
新ガイドライン追加に伴う恒常的なルールがあれば追記する（例: 「中規模以上のシステム改修時は `feature-block-design` を使うこと」）。

実際の追記要否は、現状の CONTRIBUTING.md を確認した上で plan 作成時に確定する。

## 完了基準

- `scripts/sync-template.ps1` 実行で template が完全同期されていること（再実行で差分ゼロ）
- README.md のスキル表に `feature-block-design` が追記されていること
- CONTRIBUTING.md と既存記述に矛盾がないこと
- B1〜B3 の変更を含めた全体で、`docs/handoff/master.md` の「サブプロジェクトB完了」状態に到達できること

## 関連 ADR

なし（同期作業のため、決定事項は B1〜B3 の ADR に集約）
