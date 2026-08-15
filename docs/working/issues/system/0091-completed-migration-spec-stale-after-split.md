# Issue-0091: 完了済み移行 spec のひな形パス言及が課題管理定義の分離後と乖離している

- **Status**: open
- **Opened**: 2026-08-15
- **起票元**: retrospectives/system/2026-08-15-issue-0088-bloat-control.md 課題#1
- **関連**: Issue-0008（旧型式 spec の維持・アーカイブ方針が未定義。「完了済み spec の維持方針」として一般形が隣接）、ADR-0096

## 課題内容

`docs/current/specs/2026-08-07-distributed-artifact-generation/05-source-migration.md` 153 行目の書式例のパス言及（folder-structure.md の課題ファイルひな形）が、課題管理定義（`docs/overview/issue-management.md`）への分離後の実態と乖離している。詳細は起票元の振り返りファイルが正。

対処時は、個別修正だけでなく「完了済み・一回限りの移行手順 spec をスナップショット追従の対象に含めるか、アーカイブ扱いにするか」の一般方針（Issue-0008 と同時に扱える）も検討候補とする。

## 検討状況

- 2026-08-15: 起票（実装全体の最終レビューが検出。実害小・低優先）
