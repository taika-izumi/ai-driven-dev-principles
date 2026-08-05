# Handoff: 配布先 flow 課題の取り込みサイクル完了・次サイクル待ち

- **Branch**: master（feature/flow-issue-intake-and-worklog-pipeline を merge `a0b16c9` として取り込み・feature ブランチ削除済み）
- **Last Updated**: 2026-08-05 (Asia/Tokyo)
- **Status**: ready-for-next-cycle（実装・master merge・retrospective・worklog 記録まで完了。次サイクル着手はユーザー判断）
- **Current Phase**: 全フェーズ完了。次サイクル着手はユーザー判断

> 注: `ready-for-next-cycle` は `retrospective` スキル Phase 3 が指定する値だが、`session-handoff` スキルが定義する Status（`in_progress` / `paused` / `completed`）には含まれない。この不整合は `LoopForAlpha#Issue-0087` として配布先で起票済み、本リポジトリへの取り込みは次サイクル（ADR-0062 で構造観察型として繰り延べ）。より具体的な指示である `retrospective` 側に従っている。

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

**直近サイクル（2026-08-05: 配布先 flow 課題の取り込みと worklog パイプラインの疎通）**: 配布先 LoopForAlpha の flow 課題 20 件（最古 2026-07-11）を取り込む経路を規範として成立させ、その主経路である worklog パイプラインを疎通させた（ADR-0061〜0069 の 9 本、merge `a0b16c9`）。

- **取り込み経路**: issue 自身の振り分け判定に従い、delta 型は `worklog-extract` の再走査へ委ね、構造観察型のみ手で取り込む（ADR-0061）。**手でのクラスタ化は `worklog-extract` の仕事と重複していた**ことが着手後に判明し、方針を差し替えた
- **申し送りの運用**: 起票経路を 2→4 へ拡張し、close トリガーを「受け皿の実在確認」と定義（ADR-0063）。クロスリポジトリ参照を `<repo>#Issue-NNNN` に固定（ADR-0068）
- **中央ストアの契約是正**: `Add-Content` は Windows で CRLF を書き契約（LF 固定）を満たせない。書き側を行終端の明示できる API へ限定し、読み側に `check-store-health.py` を新設（ADR-0064）。**検査には正の対照 5 種・負の対照 2 種を同梱**し、実ストアで既知の CR 5 個を検出することを実測した
- **パイプライン疎通**: 3 サイクル起動していなかった経路を動かし、118 件を全数走査して 14 クラスタを検出。Issue-0042 / 0043 起票、台帳 18→31 行
- **設計の確定**: 根拠一覧をそのまま規範へ写さず適用条件の設計を挟む方針（ADR-0065）のもと、委譲の定型項目を A 群 4 件（常時適用）と B 群 8 件（条件発火）へ分割（ADR-0066）、確定前レビューは新規スキルとする方式を決定（ADR-0067）

その前のサイクル（2026-08-04）は ADR 粒度・文章量の規範整備（ADR-0059/0060）。さらに前は Post ラッパー消化の可視化（ADR-0057/0058）、retrospective の役割再定義（ADR-0056）。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open: system 0003/0008/0028/0036、flow 0006/0015/0020/0021/0033/0034/0038/0039/0042/0043/0044/0045/0046）
- 直近サイクルの retrospective: `docs/records/retrospectives/system/2026-08-05-flow-issue-intake-and-worklog-pipeline.md` / `flow/` 同名
- 直近サイクルの plan: `docs/working/plans/2026-08-05-flow-issue-intake-and-worklog-pipeline.md`（Task 1〜8 全完了）
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0069。Rejected 3件）
- worklog スキーマ正典: `skills/worklog-record/references/store-format.md`（v2）
- ストア健全性検査: `skills/worklog-extract/scripts/check-store-health.py`（`--self-test` で正負の対照）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] **配布先 flow 課題の取り込みと worklog パイプライン疎通サイクル**: ADR-0061〜0069（Accepted）。スキル 3 件改定・スクリプト 1 件新設・規範文書 2 件改定。Issue-0032/0040/0041 close、Issue-0042〜0046 起票。配布先 5 件 close。merge `a0b16c9`（2026-08-05）
- [x] **ADR 粒度・文章量の規範整備サイクル**: ADR-0059/0060。merge `9a3f70e`（2026-08-03〜04）
- [x] **Post ラッパー消化可視化サイクル**: ADR-0057/0058。merge `9464574`（2026-08-01〜03）
- [x] （以前のサイクルは過去の handoff / retrospective 参照）

## 進行中のタスク

（なし。サイクル完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化。次サイクルの候補として目安を示す:

1. [ ] **Issue-0033 / 0034 のスキル authoring** — **設計は ADR-0065/0066/0067 で確定済み**。`adopted` のまま 4 サイクル目に入っており、パイプラインの出口は未到達。着手コストは最も低い
2. [ ] **構造観察型の配布先課題の取り込み**（ADR-0062 で繰り延べ）: `LoopForAlpha#Issue-0085`（ハンドオフ肥大 573行77KB）/ `#0086`（振り返りカデンス）/ `#0087`（Status 値の不整合）/ `#0042`（規模再見積もり。本repo Issue-0046 と同一主題）/ `#0008`（免除条件）/ `#0013`（素材消失）
3. [ ] **Issue-0045**（新規・flow）: 既存 open 課題の対策方針が実行可能かを点検する工程がない。**棚卸し 1 回で相当数が片付く可能性がある**
4. [ ] **Issue-0044**（新規・flow）: スキル改定の同セッション検証不可。ADR-0039 に従い環境側の構造的解決を先に調べること
5. [ ] **Issue-0046**（新規・flow）: サイクル規模の再見積もり不在。`LoopForAlpha#Issue-0042` と同一主題で、まとめて扱える
6. [ ] **Issue-0042**（flow）: 検出器の検出力。走査で根拠 16 件・両プロジェクト出所の最上位クラスタ。**一部は ADR-0064 で先行実装済み**
7. [ ] **Issue-0043**（flow）: 意思決定要求の front-load。`corrections` が `friction` を上回る唯一の大型クラスタ＝**ユーザーの負担が最大**
8. [ ] **Issue-0008**（system）: 旧型式 spec の維持/アーカイブ方針 — 3 サイクル連続で顕在化
9. [ ] **Issue-0020**（flow）: ステージング内容の確認 — 本サイクルで 2 回再発。記述による規律では防げないことが実測された
10. [ ] **Issue-0021**（flow）: Tech Notes の横断再利用 — ADR-0056 で解消方向。**close 判断がユーザー待ち**
11. [ ] **Issue-0003 / 0036**（system）/ **Issue-0006 / 0015 / 0038 / 0039**（flow）: 低優先課題群
12. [ ] **Issue-0028**（system）: worklog マルチユーザー・組織展開 — v2 テーマ
13. [ ] **ループプロファイル抽出サイクル**（ADR-0043）: LoopForAlpha での実証完了後に着手する大テーマ

## 既知のブロッカー・懸念

- **プラグイン更新が必要（未実施）**: 本サイクルで `skills/worklog-extract`（SKILL.md + scripts 新設）と `skills/worklog-record`（SKILL.md + store-format.md）を改定したため、`/plugin marketplace update ai-driven-dev-principles` をユーザーが実行するまで実行環境へ反映されない（AI からは実行不可。ADR-0055）。**次サイクル開始前に実行すること**
- **改定したスキルは同セッション内で検証できていない**（Issue-0044）。本サイクルで改定した 2 スキルは動作未確認のまま。次セッション冒頭で `worklog-extract` の手順2（`check-store-health.py` 呼び出し）が反映されているか確認すること
- **`Add-Content` は使わないこと**。Windows で CRLF を書き中央ストアの契約に違反する。Python は `open(path, "a", encoding="utf-8", newline="\n")`（ADR-0064）
- **クロス repo の課題参照は `<repo>#Issue-NNNN` で修飾すること**（ADR-0068）。LoopForAlpha `flow/0034` と本repo `flow/0034` は番号が同じで内容が異なる
- **消化記録の worklog id は省略形で書かないこと**。本サイクルで `-04` と略記したため Phase 3 の機械突合が拾えなかった（実体は記録済み・漏れなし）
- **中央ストアの現状**: 本repo 18 件（`2026-07-17-01`〜`2026-08-05-05`）＋ LoopForAlpha 106 件。台帳 31 行（adopted 7 / deferred 11 / rejected 2 / merged 1）。健全性は `check-store-health.py` で検証（`exit=0` を確認済み）
- **inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定**。organize-inbox 提案は不要。`git add <ディレクトリ>` で巻き込まないこと（本サイクルで 2 回発生。Issue-0020）
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` は確認済み（構造化質問ツール使用前に毎回確認。ADR-0036）
- ADR-0023 の留意点（継続）: GitHub.com の Copilot コーディングエージェントがルート `CLAUDE.md` を読まない可能性

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。直近サイクル中の分は `feature_flow-issue-intake-and-worklog-pipeline.md` 参照（Phase 3 で両方向の突合済み・未消化なし）。

- 2026-08-05 master merge + retrospective 完了: ADR=なし（振り返りは課題抽出のみで意思決定を行わない。ADR-0021） / worklog=棄却（本工程に delta なし。サイクル中の delta は 5 件すべて記録済み）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **最初にユーザーへ依頼すること**: `/plugin marketplace update ai-driven-dev-principles`（本サイクルで skills/ を 2 件改定・スクリプト 1 件新設。ADR-0055）
3. **更新後に確認すること**: `worklog-extract` の手順2 に `check-store-health.py` の呼び出しが含まれているか（Issue-0044 の実地確認を兼ねる）
4. **直近サイクルは完了**: 追加作業不要
5. **次サイクルの候補（着手はユーザー判断）**: 上記「未着手のタスク」の 1〜5 が目安。**Issue-0033/0034 の authoring は設計確定済みで最も安い**。Issue-0045 は棚卸し 1 回で相当数が片付く可能性がある
6. **最初に確認すべきファイル**: 本ファイル、`docs/records/retrospectives/system/2026-08-05-flow-issue-intake-and-worklog-pipeline.md`、`docs/working/issues/README.md`
7. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - ADR の起票・追記・昇格には粒度規範が適用される（ADR-0059/0060）。**本サイクルでは昇格前の点検が実際に発火し 2 本を分割した**（0063→0068 / 0065→0069）
   - Post ラッパーは1項目ずつ消し込み、結果を消化記録へ書く（ADR-0057）。**worklog id は省略せず全体を書く**
   - コミット前に `git status --short` でステージ内容を確認する（Issue-0020。本サイクルで 2 回再発）
   - 件数を文書へ書く前に機械カウントで取る（本サイクルで目視カウントの誤りが 14 箇所へ波及した）
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行（skills 改定では不要。Issue-0040 で CONTRIBUTING.md も是正済み）
   - コミット・マージのマルチライン文字列は `git commit -F <絶対パスの一時ファイル>`（Issue-0015）

## 重要な意思決定の履歴

- ADR-0061: 配布先の flow 課題は delta 型を worklog 経路へ委ね、構造観察型のみ手で取り込む（2026-08-05, **Accepted**）
- ADR-0062: 今サイクルは worklog パイプラインの疎通を優先し、構造観察型の取り込みは次サイクルへ送る（2026-08-05, Accepted）
- ADR-0063: 配布先からの申し送りを起票経路として定義し、受け皿の実在確認を close トリガーとする（2026-08-05, **Accepted**）
- ADR-0064: 中央ストアの書き込みは行終端を明示できる API に限定し、健全性検査は正負の対照を同梱する（2026-08-05, **Accepted**）
- ADR-0065: 採用した worklog 候補は、根拠一覧をそのまま規範に写さず、適用条件の設計を挟んでからスキル化する（2026-08-05, **Accepted**）
- ADR-0066: サブエージェント委譲の定型項目は「委譲先の作業量を増やすか」で常時適用と条件発火に分ける（2026-08-05, **Accepted**）
- ADR-0067: 非コード成果物の確定前レビューは新規スキルとして立て、`start-work` から配線する（2026-08-05, **Accepted**）
- ADR-0068: 他リポジトリの課題は `<repo>#Issue-NNNN` で修飾して参照する（2026-08-05, **Accepted**）
- ADR-0069: 汎用スキルの拡張先は自リポジトリの `skills/` に限り、third-party プラグインのスキルは編集しない（2026-08-05, **Accepted**）
- ADR-0059/0060: ADR の粒度は「後から探しに来るときの問い」で決める / 点検は追記時と昇格前（2026-08-03, Accepted）
- ADR-0056: retrospective を課題抽出記録に純化し worklog へ委譲（2026-07-31, Accepted）
- （ADR-0001〜0058 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
