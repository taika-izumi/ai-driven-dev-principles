# Issue-0102: マージ後の cycle-reset の適用先 handoff が暗黙で、マージ先ブランチの handoff が陳腐化する

- **Status**: open
- **Opened**: 2026-08-18
- **起票元**: 2026-08-18 セッション開始時の実測（start-work Phase 0 の read が陳腐化した `master.md` を提示。ユーザー指摘で判明）
- **関連**: `skills/session-handoff/SKILL.md`（cycle-reset 手順・パス解決規則）、`skills/retrospective/SKILL.md`（Phase 3 が cycle-reset を呼ぶ）、コミット `11e9beb`（誤適用の実例）・`3246e50`（正適用の実例）

## 課題内容

**事象**: Issue-0084 サイクル終了時（2026-08-17）、master ブランチ上で実行された cycle-reset（`11e9beb`）が feature 側 handoff（`feature_issue-0084-wire-no-ff-merge.md`）に適用され、`master.md` は前サイクル（Issue-0093）完了時点のまま放置された。翌セッション（2026-08-18）の start-work Phase 0 read は現在ブランチ（master）の handoff を読むため、close 済みの Issue-0084 を次サイクル候補の筆頭とする古い状態が提示された。

**原因**: session-handoff のパス解決規則は「現在ブランチ名 → `docs/working/handoff/<branch>.md`」だが、feature → master マージ直後のセッションでは「サイクル中ずっと維持してきた handoff」が feature 側にあり、cycle-reset がそちらへ引き寄せられた。スキルに「マージ後は feature 側 handoff を `completed` で閉じ、cycle-reset はマージ先ブランチ（現在ブランチ）の handoff へ当てる」という明示の配線がなく、正しい挙動がパス解決規則からの導出に依存している。実際、Issue-0093 サイクルは `master.md` を reset（正・`3246e50`）、Issue-0084 サイクルは feature 側を reset（誤・`11e9beb`）と、連続する 2 サイクルで挙動が分かれており再現性がない。Status `ready-for-next-cycle` が「長命ブランチの handoff」用と定義されながら、feature handoff に付く逸脱を検出する工程もない。

**影響**: マージ先 handoff の陳腐化。次セッションが古いバックログ・作業状態を前提に開始し、close 済み課題への再着手や状態誤認のリスク。今回はユーザー指摘で捕捉されたが、機械的な検出網はない。

**応急処置（実施済み）**: 2026-08-18 に `master.md` を最新状態へ手動同期し、feature 側 handoff を `completed` へ正規化（本課題起票と同一コミット）。

## 検討状況

- 2026-08-18: 起票。対策（cycle-reset 手順への適用先明示・feature handoff 閉鎖ステップの追加など）の採否・設計は次サイクル（ユーザー判断）

## 結論

（open）
