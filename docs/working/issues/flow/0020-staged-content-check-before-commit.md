# Issue-0020: コミット直前の確認観点に「ステージング内容の確認」が含まれていない

- **Status**: open
- **Opened**: 2026-07-06
- **起票元**: `docs/records/retrospectives/flow/2026-07-06-claude-md-growth-governance.md` 課題#1
- **関連**: ADR-0038、CLAUDE.md「検証」節、原則5（漸進的検証）

## 課題内容

read-back verification（ADR-0038）は「ファイル内容が意図どおりか」の確認であり、「コミットに何が含まれるか」（ステージング状態）の確認は観点として定式化されていない。別目的で `git add` 済みのファイルがステージに残っていると、コミットメッセージと実際のコミット内容が一致しないコミットが生まれる（実例: ADR-0040 の初回コミット 8a0f0a7 に handoff ファイルが同乗）。詳細は起票元の振り返りファイルが正。

## 検討状況

- 2026-08-05: **再発 2 回**（ADR-0031）。範囲の広い `git add docs/` が、ユーザーが手動管理している untracked ファイル 4 件（`docs/inbox/` 3 件と `docs/conversation_log.md`）を巻き込んだ。1 回目は commit 直前の `git status --short` で気づき `git restore --staged` で回避したが、**2 回目は気づかずコミットまで通し**、`git rm --cached` ＋ `git commit --amend` で修復した（`36980d7` → `6f2c1fb`）
- 2026-08-05: **1 回目の直後に再発防止手順を worklog へ記録していた**（`MakeAiInstructions-2026-08-05-03` の procedure 項目3「`git add <ディレクトリ>` を使わず変更したファイルを列挙する」）。**記録した直後に同じ操作で再発している**ため、記述による規律では防げないことの実測になる。`docs/reference/` 系の知見「記述による規律は再発を防がず、実効的なのは機械検査である」と整合する。対策設計時は、コミット直前のステージ内容確認を**機械的な gate**（フック等）として置けるかを先に調べること（ADR-0039 の「環境・ツール設定による構造的解決を規範追加より優先する」に従う）。関連 worklog: `MakeAiInstructions-2026-08-05-05`

## 結論

（open）
