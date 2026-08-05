# Issue-0044: スキルを改定したサイクルでは、その改定を同一セッション内で検証できない

- **Status**: open
- **Opened**: 2026-08-05
- **起票元**: `retrospectives/flow/2026-08-05-flow-issue-intake-and-worklog-pipeline.md` 課題#1
- **関連**: ADR-0055（スキル availability の AI 側判定規範）、Issue-0039（ガイドライン遵守が不可視機構に依存しうる）、`start-work` Phase -1、worklog `MakeAiInstructions-2026-08-05-04`

## 課題内容

スキル本文はセッション開始時点の内容で提供され、**セッション中のファイル編集は同セッションの Skill 起動に反映されない**。

ADR-0055 は「スキルが使えるか（availability）」の AI 側判定規範を定めているが、「**改定内容が反映されているか**」は扱っていない。両者は別の問いである。

詳細（事象/原因/影響）は起票元の振り返りファイルが正。

## 検討状況

- 2026-08-05: 起票。本サイクルで `worklog-extract` / `worklog-record` を改定し、同セッションで起動したところ改定前の本文が返った。ディスクと `git show HEAD:<path>` の両方に編集があることを確認して判明した
- 対処の方向（未決）: (a) スキル改定を含むサイクルでは、改定したスキルの同セッション起動を避ける運用規範 (b) 反映の有無を判定する手順（返り値に改定後の識別子が含まれるかを見る）を `start-work` Phase -1 へ追加 (c) 改定したスキルの動作検証を次セッション冒頭のタスクとして handoff へ必ず残す規範。ADR-0039 に従い、規範追加より先に環境・ツール設定による構造的解決（セッション内リロードの可否）を調べること
- 2026-08-05（スキル化サイクル）: **進展 2 点**（ADR-0031）。(a) 本環境（Claude Code）の marketplace 登録は `source: directory`・`installLocation` が本 repo 直指しで、プラグインキャッシュ（2026-06-16 版。worklog 系スキルを含まない）に存在しないスキルが available-skills 一覧に出ていた。実行時はキャッシュでなく**リポジトリの実体を直読みしている可能性が高く**、その場合「同セッション検証不可」の前提はこの環境では成立していない（`/plugin marketplace update` 直後のセッション内でも改定後の本文が返るかの実測が対処 (b)(c) の要否を左右する）。(b) 本サイクル新設の `subagent-dispatch` / `pre-finalization-review` は、一覧がスキル作成前に更新されたものであるため availability 未確認。次回 `/plugin marketplace update` 実行後に一覧掲載を確認すること

## 結論

（open）
