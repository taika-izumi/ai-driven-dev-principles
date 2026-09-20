# Handoff: 不在中の判断要請を減らす（隔離検証は終了・後片付け完了）

- **Branch**: master
- **Last Updated**: 2026-09-20 13:45 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: AI組織は今は導入しない（ADR-0205）、隔離検証は試作で止める（ADR-0206）と決定し、後片付け（Issue-0157）も完了。次の主題「不在中の判断要請を減らす」は未着手。

## 作業の目的・背景

直近サイクルでは、隔離検証統合後の整理作業（push、ADR-0153〜0156のAccepted昇格、Issue-0136のクローズ、inbox 3件の整理とIssue-0158の起票）を行ったうえで、worktree使用を踏まえた開始時の検出を設計・実装した。worktreeは禁止も全面標準化もせず、作成の合意はsuperpowersに委ね、session-handoffのread操作で他のworktreeの進行中・中断中のhandoffを検出する（ADR-0202）。追記でstart-workのSKILL.mdがサイズ目安を超えたため、インラインフォールバックの内容をreferencesへ移した（ADR-0203）。配布0.1.30として公開済み（5adfecc）。振り返りは `docs/records/retrospectives/system/2026-09-19-worktree-start-detection.md`・`flow/` 同名（Issue-0159を起票）。0.1.30の導入確認は2026-09-19に完了。2026-09-20、隔離検証の方針は保留し、AI組織の必要性の検討を先に行うと決めた（ADR-0204）。

## 関連ドキュメント

- 目的・方針の正本: docs/overview/project-purpose.md。対象ルートD:/Dev/002_AiDev/MakeAiInstructions、参照内容は5350b9fの同パス（2026-09-18の開始時に読取りと版照合が成立）。判断根拠はADR-0130・0183・0190。
- 直近サイクル: 振り返り `docs/records/retrospectives/system/2026-09-19-worktree-start-detection.md`、設計 ADR-0202（`docs/records/decisions/0202-handle-worktrees-by-agreement-and-start-time-detection.md`）、実装計画 `docs/working/plans/2026-09-19-worktree-start-detection.md`（Task 6の確認と削除が次セッションに残る）。
- 隔離検証の方針決定の材料: 振り返り `docs/records/retrospectives/system/2026-09-18-isolated-verification.md`、仕様 `docs/current/specs/2026-09-09-isolated-verification/`（00に現状の制約）、課題 Issue-0152〜0157。
- 課題の一覧: docs/working/issues/README.md。
- 継続判断の検討材料: docs/reference/stage-three-preparation-and-delegation.md「2026-09-12の再照合」。ADR-0184の旧案は中断・未採用。原因切り分けの過去承認は新しい検討・実装の許可へ流用しない。
- 初期比較と終了判断: docs/current/development-roadmap.md、ADR-0183、docs/records/experiments/2026-09-10-model-discretion-comparison.md。長期保守・ADRの便益は未評価。追加比較は自動再開しない。

## 完了済みタスク

過去サイクルは docs/records/retrospectives/ と git 履歴を参照。

- [x] 0.1.30の導入確認とメモリ `check-worktree-handoffs-at-start` の削除（2026-09-19 完了。結果は計画 `docs/working/plans/2026-09-19-worktree-start-detection.md` Task 6）

## 進行中のタスク

- [ ] **現在の作業**: 次の主題「不在中の判断要請を減らす」の設計（ADR-0205）
  - 状態: 未着手。隔離検証の後片付け（Issue-0157）は2026-09-20に完了・クローズ済み。
  - 残り: 設計の進め方を利用者と決める。規範・スキルの変更を伴うなら `extend-guidelines` から入る。

## 未着手のタスク

- [ ] 次の主題「不在中の判断要請を減らす」の設計（ADR-0205。判断の分担の事前合意、範囲外の判断を保留して別の作業を進める動き、不在時間帯への作業の割り当て、ガイドラインの確認点の見直し）。未着手。
- [ ] 隔離検証は試作で止めた（ADR-0206）。Issue-0152〜0156は再開時まで保留。以下は旧記載: 方針に応じて、後片付け（Issue-0157）、独立試験の環境差（Issue-0155）・所要時間（Issue-0156）、繰り延べ指摘（Issue-0152〜0154）の扱いが決まる。
- [ ] Issue-0159（最初の推奨・採否が前提確認を欠き問い直しで覆る）、Issue-0158（セッション継続/切替の判断基準）、Issue-0145の対策設計・着手は未承認。
- [ ] Issue-0075は実際の初見利用、0144は履歴アクセス・書き込み要求の実行時拒否等が未確認。ADR-0189の実装後3件の運用評価と4体分担の効果も未評価。
- 目的参照の実運用評価は、2026-09-14・09-15・09-18の開始で3件とも正本の読取りと版照合が成立した（予定件数に到達）。評価のまとめ方は未定。

## 既知のブロッカー・懸念

- `.worktrees/isolated-verification` とブランチ `codex/isolated-verification` は統合済みだが、未追跡の試験証跡（`.tmp/m9/`・`.tmp/c9/`・`.superpowers/sdd/` 等）を保持するため残している。削除しない。
- sbx: 後片付けは2026-09-20に完了（Issue-0157 closed）。VM 0台・秘密0件・全体規則3件（filesystem read/write allow、network default-deny-all）を削除後の読取りで確認。daemonのstart/restart/reset、sbx・画像の更新はAIから行わない。詳細は `docs/reference/sbx-sandbox-runtime-facts.md`。
- 今回のHypervisorPlatform=2と、9月9日のWHvGetCapability成功・実VM起動成功がある。現在の利用可否を先に照合し、観測差だけでWindows設定を変えない。
- .worktrees/issue-0143-review-questions・issue-0140-review-cost・issue-0124-cost-comparison と各ブランチは統合済みだが、未追跡のレビュー証跡のため保全する。各.tmp/issue-0143-*の資材を再起動・削除しない。
- 他のissue-0122 worktreeとstash `6e959892b6e00600006456172237f27d7957fa01`、stash `0253b7cd8367fc09782674fdbe130102f0677eba`（Issue-0124統合前の草稿、退避コピーは `.tmp/issue-0124-merge/manifest.json`）は操作しない。古い草案を一括適用しない。
- ADR-0179の通常起動で.claude.jsonの9項目が変化し、指定session-envが作成された。値の転記・自動復元なし。通常領域全体の不変や比較の保護成立とは扱わない（詳細は docs/records/experiments/2026-09-10-model-discretion-preflight-results.md 最終節）。
- C:/Users/d12an/.claude/session-env/298b62c9-3d37-48aa-8a04-420b5d049e60はADR-0176で作成した試験用領域。勝手に削除・一般化せず、固定セッションIDや承認済みパケットを無条件で再利用しない。
- ClaudeのWriteはフック正常でもsensitive file拒否の事例あり（原因未特定）。Windows直接起動の引数一式で1783、Python中継では成功（原因未特定、試験資材runtime-temp/argv-relay保持）。元.venvの拒否は未解除（ADR-0171の別配置で回避）。いずれも事前確認結果を参照。
- Issue-0135の起動・操作承認の制約を確認してから実機検証を組む。子の書き込みで承認プロンプトが出ない場合があり、許可を保護成立の証拠にしない。
- 過去の比較では開始時一覧が0.1.24でもディスクの0.1.26を読み込んだ例がある。開始時の一覧だけで導入版を推定しない（0.1.30の導入確認でも同じ）。
- ADR-0139・0140・0163はProposed、0166は比較先行の方針としてAccepted。ロードマップ全体の実装・公開は未承認。保留事項はADR-0135／Issue-0131、ADR-0138／Issue-0132を参照。旧編集前コピー `.tmp/model-discretion-roadmap/development-roadmap.before.md` は保全する。
- `.tmp/`（issue-0136-interactive-20260914、issue-0136-claude-native-20260908 等を含む）、`.claude/agents/`の試験定義、`docs/conversation_log.md`を保全。一括ステージ・削除しない。

## 節目ごとの確認記録

- 2026-09-19 セッション終了・次サイクルの主題の合意（振り返り完了後）: ADR=なし（次サイクルの作業順の合意で、方針の決定は次セッションで行う） / worklog=棄却（delta なし）
- 2026-09-19 0.1.30導入確認とメモリ削除（計画Task 6完了）: ADR=なし（合意済み手順の実行） / worklog=棄却（delta なし）
- 2026-09-20 主題をAI組織の必要性の検討へ変更・ADR-0204 Accepted 昇格: ADR=0204 / worklog=棄却（delta なし） / cyclecheck=非該当（対象文書の変更なし）
- 2026-09-20 AI組織の必要性の検討の結論・ADR-0205 Accepted 昇格: ADR=0205 / worklog=`MakeAiInstructions-2026-09-20-01` / cyclecheck=非該当（対象文書の変更なし）
- 2026-09-20 隔離検証の方針決定・ADR-0206 Accepted 昇格: ADR=0206 / worklog=棄却（delta なし） / cyclecheck=非該当（対象文書の変更なし）
- 2026-09-20 後片付けの範囲の決定（3種類とも削除・手順作成）: ADR=なし（ADR-0206の帰結の実行範囲。Issue-0157に記録） / worklog=棄却（delta なし）
- 2026-09-20 後片付けの実行完了・Issue-0157 クローズ: ADR=なし（合意済み範囲の実行） / worklog=棄却（delta なし）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: ADR-0205・ADR-0206（`docs/records/decisions/`）、Issue-0157（`docs/working/issues/system/0157-pilot-vms-oauth-and-policies-not-cleaned-up.md`）。
2. 後片付け（Issue-0157）は完了・クローズ済み。再確認は不要。削除（`sbx secret`・`sbx rm`・通信規則）は利用者の操作と個別承認が前提で、AIからdaemonの起動・再起動やVM/画像の削除を行わない。証跡として残すVMを先に区別する。
3. 次の主題「不在中の判断要請を減らす」の設計へ進む（規範の変更を伴うなら `extend-guidelines` から）。材料: ADR-0205、`skills/start-work/references/decision-delegation.md`、Issue-0159・0158。
4. 留意点: 利用者は仕事中にリモートコントロールで応答していることがある。承認プロンプトを伴う操作を避け、判断要請はまとめて少なくする。Git Bashの `TZ=Asia/Tokyo date` はUTCを返すため、時刻はPowerShellの `Get-Date` で取る。Git Bashでは `git show <ref>:<.で始まるパス>` が失敗するためPowerShellで実行する。

## 重要な意思決定の履歴

- ADR-0206: 隔離検証は試作で止め、追加投資をしない。2026-09-20 Accepted。
- ADR-0205: AI組織は今は導入せず、先に不在中の判断要請を減らす。再検討条件つき。2026-09-20 Accepted（b1361dc）。
- ADR-0204: 隔離検証の今後の方針は、AI組織の必要性の検討を先に行い、その結論まで保留する。2026-09-20 Accepted。
- ADR-0202: worktreeは禁止も全面標準化もせず、作成の合意はsuperpowersに任せ、開始時に読む側で検出する。2026-09-19 Accepted（4e3a9f7）。
- ADR-0203: start-workのインラインフォールバックの内容をreferencesへ移す（サイズ警告への対応）。2026-09-19 Accepted。
- ADR-0153〜0156: 隔離検証の再検討方向・既存基盤比較・sbx通信deny-all初期化・sbx状態退避。2026-09-18 Accepted。
- ADR-0162・0192〜0201: 隔離検証の試作条件と実現手段。2026-09-18 Accepted、f8bce07で統合。
- ADR-0190: 目的の正本を開始・再開・委譲へ届ける。Accepted。
- ADR-0189: レビュー観点再編。正本: docs/records/decisions/0189-organize-review-questions-and-independent-challenge.md。
- ADR-0183: 初期比較と終了判断。正本: docs/records/decisions/0183-place-targeted-evaluation-before-stage-three-adoption.md。
