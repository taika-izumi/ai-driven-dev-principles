# レビュー定義変更前の15題確認の準備

2026-09-12。実装計画のタスク1として、旧定義での回答を変更前の基準値にするための資料を準備した。スキル・現行仕様・配布物の規範変更はまだ行っていない。

- 作業場所: `.worktrees/issue-0143-review-questions`、ブランチ`codex/issue-0143-review-questions`、開始コミット2875fbc。長い既存ファイル名への対応はGitコマンドのcore.longpaths=trueだけで行い、全体設定は変えていない。
- 変更前検査: build-dist -Check、sync-template -Checkは終了0、記法違反0、同期済み。展開後のGit状態はlongpaths指定で変更0件だった。
- 作成資材: `scripts/experiments/review-questions/cases.json`とexpected.json。入力15題と期待する判断を分離。Q01〜Q15の集合が一致する。
- 実行候補: 新規Claude Opus 5・mediumの1実行、最大10分。Read・Glob・Grepのみ、MCP無し・safe-mode・restricted・フック無効、通常認証・実行時保存を使用。実際の公開ツールを開始イベントで確認する。
- 送信候補: 0.1.27の配布済みpre-finalization-reviewの5文書と、人工事例15題を含むcases.jsonの計6ファイル、61,469バイト。担当が取得した原文・検索結果をAnthropicへ送信する。実プロジェクトの会話・旧ADRの原文・採点用expected.jsonは含めない。
- 入力コピー: `.tmp/issue-0143-comprehension/input/`。manifestにファイル名・サイズ・SHA256を保存。答えはこの閲覧範囲の外にある。入力のコピー一致・JSONの読込・id集合・runner構文を確認した。
- 結果回収: 同フォルダ外のbaseline/に原イベント・結果・前後ハッシュを保存する。主担当がexpected.jsonと原回答を照合し、正しい分類名だけで合格にせず、根拠の正しさと過剰断定・誤検出も確認する。

モデルはまだ起動していない。送信候補の6ファイルと1実行を明示して確認してから開始する。変更後の確認は同じ入力と設定を使う別の新規担当で行い、変更前担当の回答は渡さない。有限の理解・検出確認であり、モデル能力一般や4体の費用対効果の比較とはしない。
