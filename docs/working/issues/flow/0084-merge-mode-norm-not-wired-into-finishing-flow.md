# Issue-0084: マージ方式の規範（--no-ff）が完了フローに配線されておらず fast-forward マージが発生した

- **Status**: open
- **Opened**: 2026-08-14
- **起票元**: retrospectives/flow/2026-08-14-handoff-bloat-control.md 課題#1
- **関連**: `skills/retrospective/SKILL.md`「いつ使うか」、`superpowers:finishing-a-development-branch`

## 課題内容

retrospective スキルは「feature ブランチを master へ `--no-ff` マージ」した直後の実施を前提と記すが、マージを実際に実行する完了フロー（finishing-a-development-branch）にはこの規範が配線されておらず、2026-08-14 の handoff 肥大化制御サイクルで fast-forward マージが発生した（マージコミット不在。振り返り一覧の merge SHA 慣行が崩れ、`git log --merges` でサイクル境界を辿れない）。詳細は起票元の振り返りファイルが正。

## 検討状況

- 2026-08-14: 起票。対策の採否・設計は次サイクル（ユーザー判断）
- 2026-08-14: Issue-0083 対応サイクルでは手動判断で `--no-ff` を適用しマージコミットを残した（`f557a04`）。配線自体は未対応のまま
- 2026-08-15: Issue-0074/0065 対応サイクルでも同様に手動適用（`beb52fa`。finishing-a-development-branch の選択肢 1 の提示文へプロジェクト慣行として注記して回避）。配線は未対応のまま
- 2026-08-15: Issue-0088 対応サイクルでも手動適用（`e4590bf`。4 サイクル連続。配線は未対応のまま）
- 2026-08-16: Issue-0086/0066 対応サイクルでも手動適用（`598b279`。5 サイクル連続。配線は未対応のまま）

## 結論

（open）
