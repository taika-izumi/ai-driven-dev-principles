# Handoff: 過剰適合点検の導入サイクル完了・次サイクル待ち

- **Branch**: master（feature/overfitting-check-for-extensions を merge `4388280` として取り込み・feature ブランチ削除済み）
- **Last Updated**: 2026-08-07 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: 全フェーズ完了。次サイクル着手はユーザー判断

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AI駆動開発ガイドライン（5原則 + スキル群 + ADR。AIエージェントと協働して開発を進めるための、原則・行動指示・スキルの体系）を整備するプロジェクト。

**直近サイクル（2026-08-07: 過剰適合点検の導入）**: 「拡張が特定のシステム種別・特定の AI モデルへ過剰適合してはならない」という設計前提を初めてルール化した（ADR-0079・Accepted）。CONTRIBUTING.md に横断節「全シナリオ共通: 過剰適合の点検」を新設して 9 シナリオへ配線し、`extend-guidelines` に確定前点検工程、`worklog-skillify` に出所点検を追加した。点検は 4 観点（出所の偏り / システム種別依存性 / AIモデル・ツール依存性 / 退役経路）、是正 4 型、記録先の固定、コミット直前の執行点からなる。本サイクルで `pre-finalization-review` が初回実運用に到達し、spec の Critical 3 件・Major 8 件を検出して設計骨格を全面改訂させた。次サイクル着手はユーザー判断待ち。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open: system 7 件 = 0003/0008/0028/0036/0055/0058/0064、flow 24 件 = 0006/0015/0020/0021/0038/0039/0042〜0048/0050/0052〜0054/0056/0057/0059〜0063。計 31 件）
- 直近サイクルの retrospective: `docs/records/retrospectives/system/2026-08-07-overfitting-check-for-extensions.md` と `flow/2026-08-07-overfitting-check-for-extensions.md`
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0079。Rejected 3件）
- worklog スキーマ正典: `skills/worklog-record/references/store-format.md`（v2）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] 過去サイクルは retrospective（`docs/records/retrospectives/README.md`）/ git 履歴参照

## 進行中のタスク

（なし。サイクル完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化。次サイクルの候補として目安を示す:

1. [ ] **Issue-0062**（flow・今サイクル起票）: 確定前レビューの次手提示が成果物の安全網の有無を考慮しない。**ユーザーが早期対処を明示した唯一の課題**。一次資料（独立レビューでしか捕まらない欠陥クラス 3 種と実例）は起票元の振り返りファイルにあり、issue の「留意」から参照済み。対策先は ADR-0072 と `pre-finalization-review`
2. [ ] **Issue-0056/0057 のペア**（flow・前サイクル起票）: 計画の検証コマンドの実行可能性検査 / サブエージェント報告識別子の検証。**今サイクルで両方とも対策を手動先行適用し、有効性と限界を実測済み**（0056 は「実行できるか」だけでは足りず出力形式と検出力が残る、0057 はコマンド 1 本で不一致ゼロ）。対策設計の材料が揃っている
3. [ ] **Issue-0064**（system・今サイクル起票）: 点検ブロックの見出しレベルが 2 通りで存在確認を単一 grep で書けない。ADR-0079 の執行点の機械化に直結し、規模は小さい
4. [ ] **Issue-0044**（flow）: 切り分け完了済み（update を挟めば反映・挟まなければ未反映）。今サイクルで運用対処を 2 度実践し機能を確認。残るのは規範化の採否のみで、運用規範 1 行で足りる可能性
5. [ ] **Issue-0045**（flow）: 既存 open 課題の対策方針の実行可能性点検。open 31 件（system 7 + flow 24）に増加し、棚卸しの価値がさらに上昇
6. [ ] **Issue-0061/0058**（Skill 改定シナリオの手順整備 / 2026-04-13 仕様書の陳腐化）: 0058 は Issue-0008（旧型式 spec の維持方針）と同時に扱うと判断が一度で済む
7. [ ] **Issue-0042/0043**（flow）: 検出器の検出力 / 意思決定要求の front-load。0042 は今サイクルで再発を記録
8. [ ] **Issue-0059/0060/0063**（flow）ほか低優先課題群 / **Issue-0028**（system・v2 テーマ）/ ループプロファイル抽出（ADR-0043）

## 既知のブロッカー・懸念

- **`pre-finalization-review` は初回実運用に到達**（2026-08-07）。spec に対する 3 観点の独立レビューが Critical 3・Major 8 を検出し、設計骨格の全面改訂に至った。**ルール・規範・文書型の成果物にはコードのような「最初の実行」の安全網が無い**ため、この型の成果物ではレビューの費用対効果が高い（詳細と欠陥クラスの分類は Issue-0062 の起票元ファイル参照）。`subagent-dispatch` は 2 サイクル連続で実運用（ADR-0070 の効き目測定は worklog の同型 delta 再発の有無で継続）
- **スキルを改定したら、そのスキルを同セッションで使う前にユーザーへ `/plugin marketplace update` の実行を依頼すること**: update を挟まないと改定前の本文が供給される（2026-08-06 / 08-07 に 2 度実測。Issue-0044）。プラグインキャッシュを読んでも供給内容は判定できない。確認は「起動して返った本文と repo 実ファイルの突合」で行う。update 直後は available-skills 一覧の description も更新されるため、第一次シグナルとして使える
- **`Add-Content` は使わないこと**。中央ストアへの追記は Python `open(path, "a", encoding="utf-8", newline="\n")`（ADR-0064）
- **クロス repo の課題参照は `<repo>#Issue-NNNN` で修飾**（ADR-0068）
- **PowerShell の検索・集計の落とし穴**（いずれも実測）:
  - `Select-String` に `-Recurse` は無い。再帰検索は `Get-ChildItem -Recurse -File` とのパイプで書く
  - `Get-ChildItem -Path <ファイル名> -Recurse` はファイル名をフィルタ解釈して同名ファイルを全て拾う。ルート直下ファイルは `Get-Item`、ディレクトリは `Get-ChildItem -Recurse -File` で別々に集めてパイプする（Issue-0056 / worklog `MakeAiInstructions-2026-08-07-02`）
  - `Group-Object Filename` は basename で束ねるため、同名ファイル（`SKILL.md` 等）のファイル別集計に使えない。`Group-Object Path` を使うか、最初からファイルごとに個別実行する（worklog `MakeAiInstructions-2026-08-07-05`）
- **中央ストアの現状**: 本repo 32 件（〜`MakeAiInstructions-2026-08-07-06`）＋ LoopForAlpha 106 件。台帳 33 行。`projects.json` lastSeen 更新済み（2026-08-07）
- **inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定**。organize-inbox 提案は不要。`git add <ディレクトリ>` で巻き込まないこと（Issue-0020）
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` は確認済み（構造化質問ツール使用前に毎回確認。ADR-0036）
- ADR-0023 の留意（継続）: GitHub.com の Copilot コーディングエージェントがルート `CLAUDE.md` を読まない可能性

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。直近サイクル中の分は `feature_overfitting-check-for-extensions.md` 参照（retrospective Phase 3 で突合済み・未消化なし）。

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **直近サイクルは完了**: 追加作業不要。抽出した課題は issues に起票済み（Issue-0058〜0064。着手はユーザー判断）。delta 型 1 件は worklog 送り（`MakeAiInstructions-2026-08-07-05`）
3. **次サイクルの候補（着手はユーザー判断）**: 優先の目安は上記「未着手のタスク」の順。**Issue-0062** がユーザーの早期対処指示を受けた唯一の課題で最有力。次いで **Issue-0056/0057 のペア**（対策設計の材料が実測で揃っている）、**Issue-0064**（小規模・ADR-0079 の実効性に直結）
4. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **ガイドライン拡張時は過剰適合点検が必須**（ADR-0079。CONTRIBUTING.md「全シナリオ共通: 過剰適合の点検」）。点検ブロックの無い拡張 spec / 拡張 ADR はコミットしない
   - サブエージェント委譲時は `subagent-dispatch` を呼ぶ / plan・spec 確定時は `pre-finalization-review` を毎回提示する（ルール・文書型の成果物では実施の価値が高い）
   - サブエージェントの報告する識別子（コミットハッシュ等）は後続へ転記する前に `git cat-file -t` 等で実体検証する（Issue-0057）
   - Post ラッパーは1項目ずつ消し込み、結果を消化記録へ書く（ADR-0057）。worklog id は省略せず全体を書く
   - コミット前に `git status --short` を確認し、untracked の巻き込みとステージ済み別件の混入を見る（Issue-0020）。コミットはパス指定（`git commit -F <msg> -- <paths>`）が安全
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行（skills / CONTRIBUTING.md の改定では不要）
   - コミット・マージのマルチライン文字列は `git commit -F <絶対パスの一時ファイル>`（Issue-0015）
   - ハンドオフの剪定は finalize で基準付き圧縮、サイクル完了時に cycle-reset（`skills/session-handoff/SKILL.md` 操作 4・5。ADR-0075）

## 重要な意思決定の履歴

- ADR-0079: 直近サイクル（ガイドライン拡張の全経路に過剰適合点検を課し、点検結果の記録を義務化）
- （ADR-0001〜0078 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
