# 課題（Issues）

進行中・クローズ済みの課題のインデックス。運用ルールは `../../overview/folder-structure.md` の「課題（issue）管理」を参照。
採番は両セクション通しの連番（インデックス全体の最大番号+1）。

## 対象システム固有の課題（system/）

| # | タイトル | Status | Opened |
|---|---------|--------|--------|
| [0001](system/0001-template-sync-asymmetry.md) | template 同期の非対称性 | closed | 2026-06-15 |
| [0002](system/0002-sync-template-line-endings.md) | sync-template.ps1 の改行コード非決定性 | closed | 2026-07-05 |
| [0003](system/0003-conversation-log-classification.md) | docs/conversation_log.md の分類・扱いが未定 | open | 2026-07-05 |
| [0008](system/0008-legacy-single-file-spec-policy.md) | 旧型式の単一ファイル spec の維持・アーカイブ方針が未定義 | open | 2026-07-05 |
| [0014](system/0014-missing-gitattributes.md) | .gitattributes がなく改行正規化が各自の core.autocrlf 設定任せ | closed | 2026-07-05 |
| [0025](system/0025-worklog-entry-model-field.md) | worklog エントリに delta 発生元モデルの記録フィールドがない | closed | 2026-07-17 |
| [0026](system/0026-worklog-schema-version-field.md) | worklog エントリ・台帳にスキーマバージョンフィールドがない | closed | 2026-07-17 |
| [0027](system/0027-worklog-id-collision-concurrent-sessions.md) | 並行セッションで worklog の id 採番が衝突しうる | closed | 2026-07-17 |
| [0028](system/0028-worklog-multi-user-org-deployment.md) | worklog のマルチユーザー・組織展開対応が未設計 | open | 2026-07-17 |
| [0029](system/0029-worklog-entry-schema-refinements.md) | worklog エントリスキーマの細部改善（corrections 誤答側・型非対称・損失規模） | closed | 2026-07-17 |
| [0030](system/0030-worklog-store-encoding-eol-contract.md) | 中央ストアの文字コード・改行コード規約と追記手段が未定義 | closed | 2026-07-18 |
| [0031](system/0031-worklog-model-field-delta-origin-vs-record-time.md) | worklog の model フィールドが「記録時」定義でモデルまたぎセッションで delta を誤帰属 | closed | 2026-07-18 |
| [0032](system/0032-worklog-extract-store-validation-detection-means.md) | worklog-extract のストア健全性検証の具体的検出手段が未定義 | closed | 2026-07-18 |
| [0036](system/0036-worklog-extract-unclustered-singleton-ledger-handling.md) | worklog-extract でクラスタ化されなかった単発エントリの台帳上の扱いが未定義 | open | 2026-07-31 |

## 開発フロー/ガイドライン課題（flow/）

配布先のシステム開発 repo では、このセクションの open 課題がガイドライン repo への申し送り対象になる。

| # | タイトル | Status | Opened |
|---|---------|--------|--------|
| [0004](flow/0004-question-tool-display-norm.md) | 質問ツールの表示特性が選択肢提示規範に織り込まれていない | closed | 2026-07-05 |
| [0005](flow/0005-selection-ui-misclick-confirmation.md) | 選択UIの誤操作が即「方針確定」として扱われる | closed | 2026-07-05 |
| [0006](flow/0006-cross-cutting-change-plan-coverage.md) | 横断的なパス変更で実装計画に網羅漏れが出る | open | 2026-07-05 |
| [0007](flow/0007-retrospective-issue-integration.md) | retrospective の課題バックログと issue 管理の関係が未定義 | closed | 2026-07-05 |
| [0009](flow/0009-adr-draft-timing.md) | ADR ドラフトの起票タイミングが「即時」ルールと議論の収束度で緊張する | closed | 2026-07-05 |
| [0010](flow/0010-issue-recurrence-recording.md) | 既存 open 課題が再発した場合の記録方法が未定義 | closed | 2026-07-05 |
| [0011](flow/0011-norm-executability-check.md) | 規範・ADR のエージェント実行可能性を確認する観点が定式化されていない | closed | 2026-07-05 |
| [0012](flow/0012-question-tool-timeout-autonomy.md) | 構造化質問ツールのタイムアウト時にエージェントがどこまで自走してよいかの基準がない | closed | 2026-07-05 |
| [0013](flow/0013-plan-verification-consistency-check.md) | plan のセルフレビューに「検証手順と編集内容の整合」を見る観点がない | closed | 2026-07-05 |
| [0015](flow/0015-multiline-string-shell-syntax-mismatch.md) | マルチライン文字列をツールのシェル種別に合わせる規範・チェックがない | open | 2026-07-05 |
| [0016](flow/0016-tool-result-independent-verification.md) | ツール適用結果を独立確認せず既遂とみなすと記録と実体が乖離する | closed | 2026-07-05 |
| [0017](flow/0017-environment-solution-survey-before-norms.md) | 対策検討の初手に「環境・ツール設定による構造的解決の調査」を促す観点がない | closed | 2026-07-05 |
| [0018](flow/0018-claude-md-norm-growth-monitoring.md) | CLAUDE.md 常時指示の肥大化を監視・棚卸しする仕組みがない | closed | 2026-07-05 |
| [0019](flow/0019-adr-rejected-status-path.md) | コミット済み Proposed ADR を不採用で終える経路（Rejected）が未定義 | closed | 2026-07-06 |
| [0020](flow/0020-staged-content-check-before-commit.md) | コミット直前の確認観点に「ステージング内容の確認」が含まれていない | open | 2026-07-06 |
| [0021](flow/0021-tech-notes-cross-cycle-reuse.md) | Tech Notes の横断再利用（知見の蒸留・集約）の仕組みがない | open | 2026-07-07 |
| [0022](flow/0022-adr-granularity-check.md) | ADR 起票時に粒度（1決定=1ADR）を確認する観点がない | closed | 2026-07-07 |
| [0023](flow/0023-worklog-record-entry-count-and-priority-norm.md) | worklog-record の記録件数規範と複数 delta 候補時の優先順位付けが未明示 | closed | 2026-07-17 |
| [0024](flow/0024-plugin-skill-availability-check-in-start-work.md) | プラグイン更新後の新規スキル availability 確認手順が start-work Phase -1 に未組み込み | closed | 2026-07-17 |
| [0033](flow/0033-subagent-dispatch-prompt-boilerplate.md) | サブエージェント委譲の起動プロンプトに入れるべき定型項目が未定義 | closed | 2026-07-31 |
| [0034](flow/0034-independent-review-with-proof-for-non-code-artifacts.md) | 計画・仕様など非コード成果物の確定前に「実証を課した独立レビュー」を挟む工程がない | closed | 2026-07-31 |
| [0035](flow/0035-retrospective-lightweight-mode.md) | retrospective の簡易モードが正式な選択肢として未定義 | closed | 2026-07-31 |
| [0037](flow/0037-worklog-record-post-wrapper-not-firing.md) | start-work Post ラッパーの消化漏れが検出できない（worklog-record の発火が確率的） | closed | 2026-07-31 |
| [0038](flow/0038-retrospective-phase3-findings-no-path-to-record.md) | retrospective の Phase 3 で得た知見を記録へ反映する経路がない | open | 2026-07-31 |
| [0039](flow/0039-guideline-reliance-on-invisible-tool-memory.md) | ガイドライン遵守が Claude Code プロジェクトメモリという不可視機構に依存しうる | open | 2026-08-03 |
| [0040](flow/0040-contributing-template-sync-instruction-stale.md) | CONTRIBUTING.md のテンプレート同期指示が現行構成と矛盾している | closed | 2026-08-04 |
| [0041](flow/0041-distributed-issue-handover-path-and-cross-repo-reference.md) | 配布先からの申し送り経路と、クロスリポジトリの Issue 参照形式が未定義 | closed | 2026-08-05 |
| [0042](flow/0042-detector-detection-power-not-proven.md) | 検査・検出器の「検出力」を実証してから「守られている」と言う規律がない | open | 2026-08-05 |
| [0043](flow/0043-decision-request-premises-not-front-loaded.md) | 意思決定要求の前提・用語・推奨理由・出典・被害規模を先に置く規範が、存在するのに効いていない | open | 2026-08-05 |
| [0044](flow/0044-skill-revision-unverifiable-in-same-session.md) | スキルを改定したサイクルでは、その改定を同一セッション内で検証できない | open | 2026-08-05 |
| [0045](flow/0045-issue-countermeasure-feasibility-unchecked.md) | 既存 open 課題の対策方針が実行可能かを点検する工程がない | open | 2026-08-05 |
| [0046](flow/0046-cycle-scale-re-estimation-checkpoint-missing.md) | サイクル規模の再見積もりチェックポイントがない | open | 2026-08-05 |
| [0047](flow/0047-dispatch-constraint-injection-via-hook.md) | サブエージェント委譲の常時制約を、規範文ではなくフックで機械注入できる | open | 2026-08-05 |
| [0048](flow/0048-norm-item-retirement-detection-in-worklog-extract.md) | 規範項目の退役候補を worklog-extract の走査で機械検出できない | open | 2026-08-05 |
| [0049](flow/0049-handoff-single-file-growth-no-pruning-rules.md) | ハンドオフが単一ファイルへの時系列追記で肥大し、完了情報の剪定規約がない | closed | 2026-08-05 |
| [0050](flow/0050-retrospective-cadence-bound-to-subproject-granularity.md) | 振り返りの契機がサブプロジェクト粒度に従属し、長期化すると 1 回で扱う材料が過大になる | open | 2026-08-05 |
| [0051](flow/0051-handoff-status-value-mismatch-between-skills.md) | retrospective が要求するハンドオフ Status 値を session-handoff が定義していない | closed | 2026-08-05 |
| [0052](flow/0052-retrospective-exemption-and-deferral-conditions-undefined.md) | マージ直後 retrospective の免除・繰り延べ・規模による裁量条件が未定義 | open | 2026-08-05 |
| [0053](flow/0053-retrospective-material-loss-across-session-restart.md) | セッション再起動を挟むと retrospective の素材（定性的な学び）が失われる | open | 2026-08-05 |
| [0054](flow/0054-fallback-norm-ignores-transient-outage.md) | pre-action-review の撤退規範が一時的なインフラ障害と恒常的な失敗を区別しない | open | 2026-08-06 |
