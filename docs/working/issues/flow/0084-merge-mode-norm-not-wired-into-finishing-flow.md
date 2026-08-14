# Issue-0084: マージ方式の規範（--no-ff）が完了フローに配線されておらず fast-forward マージが発生した

- **Status**: open
- **Opened**: 2026-08-14
- **起票元**: retrospectives/flow/2026-08-14-handoff-bloat-control.md 課題#1
- **関連**: `skills/retrospective/SKILL.md`「いつ使うか」、`superpowers:finishing-a-development-branch`

## 課題内容

retrospective スキルは「feature ブランチを master へ `--no-ff` マージ」した直後の実施を前提と記すが、マージを実際に実行する完了フロー（finishing-a-development-branch）にはこの規範が配線されておらず、2026-08-14 の handoff 肥大化制御サイクルで fast-forward マージが発生した（マージコミット不在。振り返り一覧の merge SHA 慣行が崩れ、`git log --merges` でサイクル境界を辿れない）。詳細は起票元の振り返りファイルが正。

## 検討状況

- 2026-08-14: 起票。対策の採否・設計は次サイクル（ユーザー判断）

## 結論

（open）
