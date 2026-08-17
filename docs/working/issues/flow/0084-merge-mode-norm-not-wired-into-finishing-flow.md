# Issue-0084: マージ方式の規範（--no-ff）が完了フローに配線されておらず fast-forward マージが発生した

- **Status**: closed
- **Opened**: 2026-08-14
- **Closed**: 2026-08-17
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
- 2026-08-16: Issue-0092 監査サイクルでも手動適用（`cbda17c`。6 サイクル連続。配線は未対応のまま。なお同監査の台帳では本規範に相当する行は正本群外〈superpowers 側スキル〉のため対象外）
- 2026-08-17: Issue-0096 サイクルでも手動適用（`edc70b1`。7 サイクル連続）
- 2026-08-17: **Issue-0093/0094 サイクルで再発**。finishing-a-development-branch の既定どおり fast-forward マージを実行してしまい、retrospective 中に本 issue の慣行記録を読んで気づき、push 前に master を分岐点へ戻して `--no-ff` でやり直した（`be8d6bd`）。手動適用の連鎖は担い手のコンテキスト（本 issue を読んでいるか）に依存することが実証された。配線は未対応のまま
- 2026-08-17: 検討状況の記載漏れ補正 — 2026-08-15 の Issue-0076 対応サイクルでも手動適用していた（`faa9187`）。当時の行が漏れていたため本行で補う（連番表現「4 サイクル連続」等は当時から faa9187 を数えており計数は正）

## 結論

ADR-0106（Accepted・2026-08-17）で対策を確定・実装した。予防（`start-work` Phase 2 の完了処理行と「完了処理のマージ方式確認」節・横断的ラッパー Pre 条項）と検出（`retrospective` Phase 0 の取り込み方式検証・fast-forward やり直し手順・template の取り込み方式欄）の 2 層を配布スキルへ配線し、本リポジトリには `branch.master.mergeoptions "--no-ff"` と `pull.ff true` を設定した（plugin 0.1.9・`082e1fb`）。スモーク検証 13 項目全合格。フォルダ未昇格のため close 時移設判定は非該当。
