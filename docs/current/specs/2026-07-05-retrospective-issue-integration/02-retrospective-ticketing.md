# ブロック02: retrospective-ticketing — 振り返りからの起票統合

## 1. 対象ファイル

- `skills/retrospective/SKILL.md` — Phase 2（ドラフト保存）の拡張
- `skills/retrospective/template.md` — Issues セクションの課題項目に issue 番号行を追加
- `skills/retrospective/flow-template.md` — 課題項目に issue 番号行を追加

## 2. 責務

retrospective スキルが抽出・分類した課題を、その場で全件 `docs/working/issues/` に起票し、振り返りファイルと issue の双方向参照を成立させる。

## 3. インターフェース（Phase 2 の拡張手順）

Phase 2（ドラフト保存）の手順に、課題の分類確定後の起票ステップを追加する:

1. 課題ごとに採番する（採番・起票の定義は課題管理定義 `docs/overview/issue-management.md`「3. 起票・採番・粒度」が正。スキル側はこれを参照する）
2. 分類に応じて `docs/working/issues/system|flow/NNNN-<slug>.md` を起票する（Status: open）
   - 課題内容は**要約のみ**。事象/原因/影響の詳細は振り返りファイルを正とし、「起票元」フィールドに `retrospectives/system|flow/YYYY-MM-DD-<topic>.md 課題#N` を記載する
3. インデックスの対応セクションに1行追加する
4. 振り返りファイル側の各課題項目に「**起票**: Issue-NNNN」行を含めて書き出す（初回書き込み時点で記載するため、上書き禁止規約 ADR-0011 と衝突しない）

起票は**記録行為であり、対策の設計・採否判断ではない**。抽出限定スコープ（ADR-0021）はこの拡張後も維持されることを SKILL.md のスコープ節に明記する。

## 4. テンプレート変更

`template.md`（Issues セクション）と `flow-template.md` の課題項目に、以下の1行を追加する:

```markdown
- **課題 #N**: <一文タイトル>
  - **事象**: ...
  - **原因**: ...
  - **影響**: ...
  - **起票**: Issue-NNNN（`../../working/issues/system|flow/NNNN-<slug>.md`）
```

（`flow-template.md` は「なぜフロー課題か」「関連」行も従来どおり維持する）

あわせて `template.md` の Handoff Forward セクションの課題バックログ記述を「課題は issues に起票済み（Issue-NNNN〜）。着手の要否・時期はユーザー判断」の形に更新する。

## 5. SKILL.md のその他の更新箇所

- frontmatter の description: 「抽出した課題は全件 docs/working/issues/ に起票する」旨を追記
- 「出力ファイル」節: 起票される issue ファイルとインデックス更新を追加
- Phase 4（ハンドオフ更新）: 課題バックログの参照先を issue 番号ベースに更新

## 6. このブロック固有の制約・前提

- スキル変更はプラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）まで実行環境に反映されない（ブロック04で案内）
- rubber-duck レビュー（Phase 3）で課題の分類が変わった場合は、起票済み issue のファイル移動＋インデックス行移動で追随する（Phase 3 の後に起票する順序も検討したが、ドラフト保存時点で番号を振り返りファイルに書き込む必要があるため Phase 2 で起票する。分類変更は稀であり移動コストを許容する）

## 7. 関連 ADR

- ADR-0028（起票統合の決定）/ ADR-0021（抽出限定スコープ・分類の維持）/ ADR-0011（追記型規約との整合方法）
