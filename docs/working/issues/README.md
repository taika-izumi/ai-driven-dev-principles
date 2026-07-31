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
| [0032](system/0032-worklog-extract-store-validation-detection-means.md) | worklog-extract のストア健全性検証の具体的検出手段が未定義 | open | 2026-07-18 |
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
| [0022](flow/0022-adr-granularity-check.md) | ADR 起票時に粒度（1決定=1ADR）を確認する観点がない | open | 2026-07-07 |
| [0023](flow/0023-worklog-record-entry-count-and-priority-norm.md) | worklog-record の記録件数規範と複数 delta 候補時の優先順位付けが未明示 | closed | 2026-07-17 |
| [0024](flow/0024-plugin-skill-availability-check-in-start-work.md) | プラグイン更新後の新規スキル availability 確認手順が start-work Phase -1 に未組み込み | closed | 2026-07-17 |
| [0033](flow/0033-subagent-dispatch-prompt-boilerplate.md) | サブエージェント委譲の起動プロンプトに入れるべき定型項目が未定義 | open | 2026-07-31 |
| [0034](flow/0034-independent-review-with-proof-for-non-code-artifacts.md) | 計画・仕様など非コード成果物の確定前に「実証を課した独立レビュー」を挟む工程がない | open | 2026-07-31 |
| [0035](flow/0035-retrospective-lightweight-mode.md) | retrospective の簡易モードが正式な選択肢として未定義 | closed | 2026-07-31 |
| [0037](flow/0037-worklog-record-post-wrapper-not-firing.md) | start-work Post ラッパーの worklog-record 発火が実運用で起きない | open | 2026-07-31 |
| [0038](flow/0038-retrospective-phase3-findings-no-path-to-record.md) | retrospective の Phase 3 で得た知見を記録へ反映する経路がない | open | 2026-07-31 |
