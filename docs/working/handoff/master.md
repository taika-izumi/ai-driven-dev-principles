# Handoff: Issue-0086/0066 対策サイクル完了・次サイクル待ち

- **Branch**: master（feature/issue-0086-citation-consistency を --no-ff で取り込み。マージコミット `598b279`）
- **Last Updated**: 2026-08-16 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: サイクル完了（retrospective・cycle-reset 済み）。push と配布反映、次サイクル着手はユーザー判断

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AI駆動開発ガイドライン（5原則 + スキル群 + ADR。AIエージェントと協働して開発を進めるための、原則・行動指示・スキルの体系）を整備するプロジェクト。

**直近サイクル（2026-08-16: Issue-0086/0066 対応）**: 「引用元の文書・実測と引いた側の記述との突合」欠落の 2 型への対策を、ユーザー提起の複雑化抑制制約（新工程・新観点・新規則を作らない。対策は既存工程の文言拡張かリスク受容に限定）の下で導入（ADR-0099）。サイクル全体整合検査の観点 5 を「引用の整合」へ拡張し、過剰適合点検へ観点 2・3 共通の突合注記と雛形根拠欄を追加。ADR-0092/0079 へ部分修正追記、plugin 0.1.6。spec 確定点で 3 観点フルレビュー（claude-opus-5・13 件全採用）。残余リスク（検査非発動サイクル等）は ADR-0099 決定 3 に受容として明記。Issue-0086/0066 close。配布反映と次サイクル着手はユーザー判断待ち。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open 計 44 件。2026-08-16 実測: 前回 45 − close 2 ＋ 起票 1）
- 課題管理の運用規範の正本: `docs/overview/issue-management.md`（課題管理定義）
- 直近サイクルの retrospective: `docs/records/retrospectives/system/2026-08-16-issue-0086-0066-citation-consistency.md`（flow 新規起票なし）
- 直近サイクルの決定: ADR-0099（設計文書を兼ねる。実装計画は `docs/working/plans/2026-08-16-adr-0099-citation-consistency-plan.md`）
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0099。Rejected 3件）
- 記法規約と執行点: `CONTRIBUTING.md`「全シナリオ共通: 配布対象ソースの記法規約」
- worklog スキーマ正典: `skills/worklog-record/references/store-format.md`（v2）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`
- PowerShell / .NET API の落とし穴集: `docs/reference/powershell-pitfalls.md`

## 完了済みタスク

- [x] 過去サイクルは retrospective（`docs/records/retrospectives/README.md`）/ git 履歴参照

## 進行中のタスク

（なし。サイクル完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化。次サイクルの候補として目安を示す:

1. [ ] **Issue-0092**（flow・本命。ユーザー指名）: 「確率的逸脱は残る」前提でのガイドライン全体棚卸し（過剰手順の検出実績ベース監査）。フル 1 サイクル規模。**留意: 検出実績なし＝不要ではない。発火機会数との比で判定し、配布先実運用に晒されていない規範は保留側へ**（起票時のユーザー指摘。Issue-0092 の留意節が正）
2. [ ] **Issue-0084**（flow）: マージ方式 --no-ff の完了フロー未配線。**5 サイクル連続で手動適用**（直近 `598b279`）。配線価値が高いが、Issue-0092 の監査で完了フロー自体が見直される可能性があるため、同サイクルか後に扱うのが安全
3. [ ] **Issue-0089**（flow・新規）: 指定席（議事録・インシデント報告等）の命名・索引規約が未定義（Issue-0088 系の続き）
4. [ ] **Issue-0073**（flow）: 計画の検証期待値の陳腐化（累計 6 件観測。直近サイクルでは発生なし）。Issue-0056・0042 と同時対策の候補
5. [ ] **Issue-0072**（system）: 半角括弧の同一視。1 行修正で塞げることまで確認済み（軽量に畳む候補）
6. [ ] **Issue-0075**（flow）: 規範文書の実効性観点がレビューにない
7. [ ] **Issue-0090**（flow）: インデックス 3 種・plans 残置・worklog 台帳の抑制未検討（実害の観測が再検討条件）
8. [ ] **Issue-0070/0072 のペア**（system）: 機械判定の届かない散文 / **Issue-0071/0077 のペア**（system）: 配布物の置き場非対称
9. [ ] **Issue-0085**（flow）: 消化記録フィールド新設のチェックリスト無し / **Issue-0087**（flow・低優先）: 発火表の統廃合契機
10. [ ] **Issue-0091**（system・低優先）: 完了済み移行 spec の乖離（Issue-0008 の一般形と同時に扱える）
11. [ ] **Issue-0057**（flow）: サブエージェント報告識別子の検証 / **Issue-0020**（flow）: ステージ内容確認 / **Issue-0044**（flow）: スキル改定の同セッション反映 / **Issue-0045**（flow）: open 課題の実行可能性点検（open 44 件・棚卸し価値高。Issue-0092 の監査と重なる）
12. [ ] **Issue-0064**（system）/ **Issue-0061/0058/0008** ほか低優先課題群 / **Issue-0028**（system・v2 テーマ）/ ループプロファイル抽出（ADR-0043）

## 既知のブロッカー・懸念

- **配布元が `dist/` へ切り替わっている**（ADR-0082）。`skills/` を編集しただけでは動くスキルは変わらない。`scripts/build-dist.ps1` で再生成し、生成物も同じコミットへ。手順は `CONTRIBUTING.md` の執行点（4 手順）
- **規約に適合していても配布物が壊れる型が 5 つある**（ADR-0084）。生成後の配布物を読む工程を別に置くこと
- **確定前レビューの提示規則**（ADR-0080）と**サイクル全体整合検査**（ADR-0092。観点 5 は ADR-0099 で「引用の整合」へ拡張済み）が稼働中。確定点で `review=`、Accepted 昇格で `cyclecheck=` を消化記録へ
- **Issue 運用の新規範が稼働中**（ADR-0095〜0098）: 課題ファイルへ追記したらサイズ実測（目安 10KB）、超過なら昇格提案。フォルダ昇格済み課題の close 時は移設判定必須。正本は `docs/overview/issue-management.md`
- **decision-log の昇格条件要約は、課題管理定義の改定時に同時更新が必要**（意図された配線。ADR-0098 の複写乖離型の監視点）
- **plugin 0.1.6 の配布反映は実施済み**（2026-08-16 ユーザー実施）。次セッションで改定スキル（decision-log）の本文と repo 実ファイルの突合を推奨（Issue-0044 の運用知見）。前サイクル分の**課題管理定義 `docs/overview/issue-management.md` の既存配布先への手動コピー**は未実施のままなら合わせて
- **リモート同期**: `origin/master` へ push 済み（2026-08-16。Issue-0092 起票分まで同期）。以後の push は自動では行わないため、必要な区切りでユーザーが指示すること
- **クロス repo の課題参照は `<repo>#Issue-NNNN` で修飾**（ADR-0068）
- **PowerShell / .NET API の実測済み落とし穴は `docs/reference/powershell-pitfalls.md` を参照**
- **中央ストアの現状**: 本 repo 68 件（〜`MakeAiInstructions-2026-08-16-02`）＋ LoopForAlpha 106 件。`projects.json` lastSeen 2026-08-16
- **検証用プラグイン `ai-driven-dev-principles-probe` の記録が残っている**（実体なし。片付けはユーザースコープのアンインストール）
- **inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定**。organize-inbox 提案は不要。`git add <ディレクトリ>` で巻き込まないこと（Issue-0020）
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` は確認済みだが、事象確認済みモデル（Fable 5）では構造化質問ツール自体を使用しない（ADR-0085）
- ADR-0023 の留意（継続): GitHub.com の Copilot コーディングエージェントがルート `CLAUDE.md` を読まない可能性

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。形式は `skills/session-handoff/SKILL.md` のフォーマット節を参照。直近サイクル中の分は `feature_issue-0086-citation-consistency.md` 参照（retrospective Phase 3 で突合済み・未消化なし）。

- 2026-08-16 セッション終了処理（retrospective・cycle-reset 後）: ADR=なし（新規決定なし） / worklog=`MakeAiInstructions-2026-08-16-02`

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **未完の後始末**: 改定スキル（decision-log 観点 5）の本文と repo 実ファイルの突合（0.1.6 は反映済み。Issue-0044 の運用知見）。前サイクル分の課題管理定義の配布先手動コピーが未了なら合わせて
3. **次サイクルの候補（着手はユーザー判断）**: 本命は **Issue-0092**（ユーザー指名。「確率的逸脱は残る」前提での全体棚卸し。留意節の「発火機会数との比で判定」を必ず監査設計に含める）。次点 **Issue-0084**（5 サイクル連続の手動 --no-ff。監査と同サイクルか後に）。軽量なら **Issue-0072**
4. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **配布対象ソースを変更したら執行点 4 手順**（`CONTRIBUTING.md`）。スキル改定は version bump も必須（ADR-0090）
   - **ガイドライン拡張時は過剰適合点検が必須**（ADR-0079。観点 2・3 は引用突合注記と雛形の列挙証跡が追加済み。ADR-0099）
   - **確定点（spec / plan）で確定前レビューを提示し `review=` を記録**（ADR-0080）。**Accepted 昇格前はサイクル全体整合検査**（ADR-0092/0099。マイルストーン名に `Accepted 昇格` を含める）
   - **Issue へ追記したらサイズ実測・close 時は移設判定**（課題管理定義 `docs/overview/issue-management.md` が正）
   - サブエージェント委譲時は `subagent-dispatch`（判定行必須）。**再委譲・再レビューでは前提値を委譲直前に再実測して渡す**（worklog `MakeAiInstructions-2026-08-15-06`）
   - Post ラッパーは1項目ずつ消し込み、結果を消化記録へ（ADR-0057）。worklog id は全体を書く
   - コミット前に `git status --short` と staged 確認。**コミットは pathspec 付き `git commit -- <paths>` が安全**（Issue-0020）
   - マルチライン文字列は `git commit -F <絶対パス>`（Issue-0015）。**-F のパスはコピーで再利用し打ち直さない**（本サイクルでパス打ち間違いの手戻り実測）
   - インデックス・台帳へ行を追加する前に挿入位置（表の終端・並び順）を実体確認（worklog `MakeAiInstructions-2026-08-15-03`。**本サイクルで再発**: retrospectives README へ時系列順に反する位置へ挿入し 1 往復の修正）
   - ハンドオフの剪定は finalize で基準付き圧縮、サイクル完了時に cycle-reset（ADR-0075）

## 重要な意思決定の履歴

- ADR-0099: 引用元との突合（条件保存・主張の向き）は新工程を設けず既存検査観点の文言拡張で行い、残余リスクを受容する。2026-08-16 Accepted
- （ADR-0001〜0098 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は Rejected）
