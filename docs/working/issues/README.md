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
| [0014](system/0014-missing-gitattributes.md) | .gitattributes がなく改行正規化が各自の core.autocrlf 設定任せ | open | 2026-07-05 |

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
| [0016](flow/0016-tool-result-independent-verification.md) | ツール適用結果を独立確認せず既遂とみなすと記録と実体が乖離する | open | 2026-07-05 |
