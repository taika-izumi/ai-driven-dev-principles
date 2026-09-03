# Issue-0117: references 型分割の完了基準に参照表の到達元の実在確認が無い

- **Status**: open
- **Opened**: 2026-09-03
- **起票元**: `retrospectives/system/2026-09-03-adr-0122-skill-split.md` 課題#1
- **関連**: ADR-0122（本サイクルの分割）、ADR-0121（サイズ規範と分割判断の型）、ADR-0092（サイクル全体整合検査 観点 4）、`CONTRIBUTING.md`「全シナリオ共通: SKILL.md のサイズと分割」

## 課題内容

references 型分割で SKILL.md へ置く参照表（ディスパッチ表・横断規範の参照表）について、表の各行に到達元が実在するかを確認する完了基準が、`CONTRIBUTING.md` の分割手順にも `decision-log` の `references/cycle-consistency-check.md` 観点 4 の完了基準にも無い。ADR-0122 サイクルでは横断規範の参照表 4 行のうち 1 行が操作 5 ファイルのいずれからも名指しされず、表の導入文が定めた発動条件が恒常的に偽になっていた（詳細・事象・原因・影響は起票元を参照）。

## 検討状況

- 2026-09-03: 起票。対策の着手はユーザー判断。当該サイクルの欠陥自体は Accepted 昇格前に修正済み（db565f2）で、本課題が残すのは「同型を次の分割で再発させない完了基準の欠落」である。対策の候補は 2 つ——(a) `CONTRIBUTING.md` の references 型の手順へ完了基準を足す、(b) `cycle-consistency-check.md` 観点 4 の完了基準へ足す。前者は分割の実施時点で、後者は昇格時点で発火する

## 結論

（open）
