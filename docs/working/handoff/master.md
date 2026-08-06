# Handoff: 体系呼称の改名サイクル完了・次サイクル待ち

- **Branch**: master（feature/rename-to-ai-driven-dev-guideline を merge `992a49f` として取り込み・feature ブランチ削除済み）
- **Last Updated**: 2026-08-07 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: 全フェーズ完了。次サイクル着手はユーザー判断

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AI駆動開発ガイドライン（5原則 + スキル群 + ADR。AIエージェントと協働して開発を進めるための、原則・行動指示・スキルの体系）を整備するプロジェクト。

**直近サイクル（2026-08-07: 体系呼称の改名）**: 体系の正式呼称を「メタ・ガイドライン」から「AI駆動開発ガイドライン」へ改め（ADR-0078・Accepted）、規範文書・仕様書・プラグインメタデータの日本語 37 箇所＋英語 2 箇所を書き換えた。初出 3 文書には一行定義を添えた。追記型の記録は ADR-0011 に従い据え置き、`docs/current/specs/` はファイル名を維持して本文のみ更新。`subagent-dispatch` を初めて実運用し（全 8 回の委譲に B 群判定行を付与）、`superpowers:subagent-driven-development` の二段レビューが実欠陥 1 件を捕捉した。次サイクル着手はユーザー判断待ち。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open: system 0003/0008/0028/0036/0055 の 5 件、flow 0006/0015/0020/0021/0038/0039/0042〜0048/0050/0052〜0054/0056/0057 の 19 件、計 24 件）
- 直近サイクルの retrospective: `docs/records/retrospectives/system/2026-08-07-rename-to-ai-driven-dev-guideline.md` と `flow/2026-08-07-rename-to-ai-driven-dev-guideline.md`
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0078。Rejected 3件）
- worklog スキーマ正典: `skills/worklog-record/references/store-format.md`（v2）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] 過去サイクルは retrospective（`docs/records/retrospectives/README.md`）/ git 履歴参照

## 進行中のタスク

（なし。サイクル完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化。次サイクルの候補として目安を示す:

1. [ ] **Issue-0056/0057**（flow・今サイクル起票）: 計画の検証コマンドを確定前に実行可能性検査する工程がない / サブエージェントの報告識別子を検証せず転記する経路がある。**どちらも今サイクルで実害が出た構造欠落**で、対策先はいずれも既存スキル（`writing-plans` の Self-Review・`pre-finalization-review` / `subagent-dispatch`）。2 件まとめて 1 サイクルにできる
2. [ ] **Issue-0044**（flow）: **切り分け完了**（update を挟めば反映・挟まなければ未反映。キャッシュ参照では判定不能）。残るのは対処方針の採否のみで、運用規範 1 行で足りる可能性がある
3. [ ] **Issue-0045**（flow）: 既存 open 課題の対策方針の実行可能性点検。open 24 件（system 5 + flow 19）に増えており、棚卸しの価値は上がっている。0046×0050（規模とカデンス）のグルーピング示唆あり
4. [ ] **Issue-0042/0043**（flow）: 検出器の検出力 / 意思決定要求の front-load
5. [ ] **Issue-0020**（flow）: ステージング内容確認の機械 gate 調査。**今サイクルは再発せず**（全 12 コミットで untracked 混入ゼロ。委譲プロンプトへの明記が効いた）
6. [ ] **Issue-0047/0048**（flow）: フックによる A 群機械注入 / 退役候補の機械検出（0048 は worklog 数サイクル蓄積後が安い）
7. [ ] **Issue-0055**（system・今サイクル起票）: 仕様書内の ADR 相対リンク切れ。他の仕様書にも同種があるかは未調査
8. [ ] **Issue-0008**（system）ほか低優先課題群 / **Issue-0028**（system・v2 テーマ）/ ループプロファイル抽出（ADR-0043）

## 既知のブロッカー・懸念

- **`pre-finalization-review` は依然として実運用ゼロ**: 今サイクルでも writing-plans 完了時に提示したがユーザーは実装直行を選択（ADR-0072 の提示義務は履行済み）。`subagent-dispatch` は今サイクルで初回実運用に到達（全 8 回の委譲に B 群判定行を付与。ADR-0070 の効き目測定は worklog の同型 delta 再発の有無で継続）
- **スキルを改定したら、そのスキルを同セッションで使う前にユーザーへ `/plugin marketplace update` の実行を依頼すること**: update を挟まないと改定前の本文が供給される（2026-08-07 実測。Issue-0044）。プラグインキャッシュを読んでも供給内容は判定できないため、確認は「起動して返った本文と repo 実ファイルの突合」で行う
- **`Add-Content` は使わないこと**。中央ストアへの追記は Python `open(path, "a", encoding="utf-8", newline="\n")`（ADR-0064）
- **クロス repo の課題参照は `<repo>#Issue-NNNN` で修飾**（ADR-0068）
- **PowerShell の検索スコープ指定**: `Select-String` に `-Recurse` は無い。また `Get-ChildItem -Path <ファイル名> -Recurse` はファイル名をフィルタ解釈して同名ファイルを全て拾う。ルート直下ファイルは `Get-Item`、ディレクトリは `Get-ChildItem -Recurse -File` で別々に集めてパイプする（Issue-0056 / worklog `MakeAiInstructions-2026-08-07-02`）
- **中央ストアの現状**: 本repo 29 件（〜`MakeAiInstructions-2026-08-07-03`）＋ LoopForAlpha 106 件。台帳 33 行。`projects.json` lastSeen 更新済み（2026-08-07）
- **inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定**。organize-inbox 提案は不要。`git add <ディレクトリ>` で巻き込まないこと（Issue-0020）
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` は確認済み（構造化質問ツール使用前に毎回確認。ADR-0036）
- ADR-0023 の留意点（継続）: GitHub.com の Copilot コーディングエージェントがルート `CLAUDE.md` を読まない可能性

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。直近サイクル中の分は `feature_rename-to-ai-driven-dev-guideline.md` 参照（retrospective Phase 3 で突合済み・未消化なし）。

- 2026-08-07 master merge（`992a49f`）+ retrospective 完了（`f707ab3`）: ADR=なし（振り返りは課題抽出のみ。ADR-0021） / worklog=`MakeAiInstructions-2026-08-07-03`（総ざらいでスキル反映の実測を記録。未消化なし）
- 2026-08-07 セッション終了（切り替え直前。ADR-0058）: ADR=なし（Proposed 残なし・未コミットドラフトなしを確認。終了処理に意思決定なし） / worklog=棄却（`-03` 以降に新規 delta なし。ユーザー指示の注入も躓きも発生していない）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **直近サイクルは完了**: 追加作業不要。抽出した課題は issues に起票済み（Issue-0055 / 0056 / 0057。着手はユーザー判断）。delta 型 3 件は worklog 送り（`MakeAiInstructions-2026-08-06-05` / `-08-07-01` / `-02`）
   - **保留中のユーザー判断 1 件**: 振り返りの system 課題 #2（`docs/records/retrospectives/system/2026-08-07-rename-to-ai-driven-dev-guideline.md`）— 改名後に `docs/current/specs/2026-04-12-meta-guidelines-design.md` のファイル名と本文の呼称が乖離した件。ADR-0078 の決定どおりの意図的な状態のため、そもそも課題として扱うかを含めて未起票のまま保留した。次サイクルで要否を判断する
3. **次サイクルの候補（着手はユーザー判断）**: 優先の目安は上記「未着手のタスク」の順。**Issue-0056/0057 のペア**（今サイクルで実害が出た構造欠落。対策先はどちらも既存スキルで 2 件まとめて 1 サイクルにできる）が最有力。次いで **Issue-0044**（切り分け完了済みで運用規範 1 行で足りる可能性）、**Issue-0045**（open 24 件に増え棚卸しの価値が上昇）
4. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - サブエージェント委譲時は `subagent-dispatch` を呼ぶ（初回実運用済み）/ plan・spec 確定時は `pre-finalization-review` を毎回提示する（まだ実運用ゼロ）
   - Post ラッパーは1項目ずつ消し込み、結果を消化記録へ書く（ADR-0057）。worklog id は省略せず全体を書く
   - コミット前に `git status --short` を確認し、untracked の巻き込みとステージ済み別件の混入を見る（Issue-0020）。コミットはパス指定（`git commit -F <msg> -- <paths>`）が安全
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行（skills 改定では不要）
   - コミット・マージのマルチライン文字列は `git commit -F <絶対パスの一時ファイル>`（Issue-0015）
   - ハンドオフの剪定は新規約に従う: finalize で基準付き圧縮、サイクル完了時に cycle-reset（`skills/session-handoff/SKILL.md` 操作 4・5。ADR-0075）

## 重要な意思決定の履歴

- ADR-0078: 直近サイクル（体系呼称を「AI駆動開発ガイドライン」へ改名）
- （ADR-0001〜0077 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
