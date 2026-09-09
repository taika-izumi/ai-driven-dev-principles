# Handoff: 隔離検証の共通起動処理

- **Branch**: codex/isolated-verification
- **Last Updated**: 2026-09-09 15:44 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: ユーザー指示でセッション中断 / Linux試作仕様確定後・v2実装計画作成前

## 作業の目的・背景

Claude CodeまたはCodexの主担当から共通CLIで検証を依頼する。子Codexはホスト上で動き、専用MCP接続を通じてLinuxコンテナ内で資料検索・Git履歴参照・編集・テストを行う。親が本文を転記せず、スクリプトでファイルと履歴を渡す。

作業場所は`D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification`。既存worktreeを継続使用する。主な保存点は履歴付きコピー`049d2eb`、Linux試作仕様確定`7e8d464`。masterへ未統合で、隔離環境全体は未完成。

## 関連ドキュメント

- 確定仕様: `docs/current/specs/2026-09-09-isolated-verification/00-overview.md`と詳細01〜03。schemaVersion=2のLinux試作。仕様確定を実装済みと扱わない。
- 最終レビュー・確定記録: `docs/records/reviews/2026-09-09-linux-pilot-spec-final.md`。第1回・第2回の採否も同ディレクトリのr1/r2記録で復元できる。
- 方針・承認範囲: ADR-0151（Linux設計先行）、ADR-0152（ホスト上の子と専用接続）。どちらもAccepted。詳細仕様までの分担・承認時点の根拠はADR-0152。
- コピー実装: ADR-0150、`scripts/verification/README.md`、`docs/records/reviews/2026-09-09-history-copy.md`。Windows側のv1先行部品は実装済み。
- 旧計画: `docs/working/plans/2026-09-09-isolated-verification.md`はv1の実施記録。未完了タスクをそのまま再開しない。v2計画は未作成。
- 課題の入口: `docs/working/issues/flow/0136-inspection-delegation-does-not-fire-destructive-verification-row/0136-inspection-delegation-does-not-fire-destructive-verification-row.md`。
- 同Issueフォルダの`0136-note-network-risk-assessment.md`（Windows通信・読取の限界）、`0136-note-loopforalpha-sandbox-reuse.md`（既存基盤との差分）、`0136-note-linux-python-pilot.md`（承認時の構成案）を必要な論点だけ読む。
- 元チェックアウトの保全指示: `docs/working/handoff/master.md`。他worktree・stash・未追跡物・inboxの扱いを維持する。

## 完了済みタスク

- [x] v1先行部品を実装。コピー26件・履歴23項目＋fsck・プロセス7ケース・結果15ケースの4群が成功。証拠は履歴レビュー記録と旧計画。共通CLIやv2の成功ではない。
- [x] Linux用Dockerサービス・既存イメージと、標準.NETによるGET /version接続を読み取り確認。詳細はLinux試作ノートと仕様レビューr1。コンテナは試作起動していない。
- [x] Linux仕様4件をフル1回・差分再確認1回・機械検証16項目で確定。ADR-0151・0152を実装前のAcceptedへ昇格。`7e8d464`と最終レビュー記録を参照。

## 進行中のタスク

- **現在の作業**: 次セッションへ引き継いで停止。v2の実装計画を作成する前の状態。
  - 再開点: 確定仕様を読み、ホストの全操作経路の取得・制限・検証方法の確認を最初に置く計画を作る。
  - 確定済み: Linux先行、子はDocker外、操作は専用接続でDocker内、リポジトリと履歴の探索、主担当2種・検証担当Codex、本文転記不要。構成や終えたレビューを再質問しない。
  - 未承認: v2計画の確定・実装の進め方、動的試験の具体的範囲、イメージ準備、コンテナと実モデルの起動、新たな外部送信、導入・公開。詳細仕様までの委任をこれらへ拡張しない。

## 未着手のタスク

- [ ] v2計画の作成。最初の成立条件を確認できなければ、自由な作業依頼を起動せず方針判断へ戻る。
- [ ] 専用MCP接続・ContainerRuntime・v2入出力と回収の実装、非rootマウント・通信・停止の実証、両主担当からの検査→回収→修正→再検証の往復、全体レビュー。
- [ ] 実装完了時のサイクル全体整合検査。設計時昇格のADR-0145〜0148・0151・0152の後追いを含む。マージ・振り返りはまだ対象段階に達していない。

## 既知のブロッカー・懸念

- ホストの全実効ツールを列挙・制限する方法は未確定。features.shell_tool=falseだけを成立根拠にしない。プロトコル定義の調査結果は仕様レビューr2。取得・制限不能ならblocked。
- Windowsの旧構成はループバック通信とコピー外の読取を許したため、実エージェントの自由な検証に使わない。Issue-0136のリスク評価ノートを参照。
- 既存Dockerイメージ内のGit等の実体、非rootの書き込み、exec証拠・停止は未実証。Dockerクライアント終了をコンテナ停止の代わりにしない。
- `.tmp/`の試験・コピー・ログ・junctionを保全する。共有一時領域の一括削除はしない。外部のレビュー退避先は各レビュー記録にある。既存LoopForAlphaのコンテナ等は変更していない。
- Claude送信承認は各回に固定した資料が対象。実施済みレビューの送信を繰り返さず、未送信の候補資料を承認済みにしない。全レビューの実行は終了済み。
- 導入済みプラグイン0.1.24とリポジトリ予定版0.1.25を区別する。ローカルの仕様・コードの保存をプラグインへの反映と扱わない。

## 節目ごとの確認記録

- 2026-09-09 spec 確定点: ADR=0151・0152 / worklog=棄却（既存の機械検証と確定手順） / review=フル実施（claude-sonnet-5・1回）＋差分再確認（claude-sonnet-5・1回）＋機械検証（1回・提示後確定（実質的な収束に至らず））
- 2026-09-09 ADR-0151・0152 Accepted 昇格: ADR=0151・0152 / worklog=棄却（既存の昇格手順） / cyclecheck=非該当（実装前昇格）
- 2026-09-09 履歴レビュー完了・ADR-0150 Accepted 昇格: ADR=0150 / worklog=棄却（既存のレビュー照合・修正・検証手順の範囲） / cyclecheck=実施（修正: Issue-0136）
- 2026-09-09 plan 確定点: ADR=なし（既存仕様と工程の選択、設計変更なし） / worklog=棄却（deltaなし） / review=見送り
- 2026-09-09 先行範囲の確認・ADR-0149 Accepted 昇格: ADR=0149 / worklog=棄却（既存の確認手順内） / cyclecheck=実施（修正: Issue-0136）
- 2026-09-09 セッション終了の引き継ぎ確定: ADR=なし（ユーザーの中断指示、方針変更なし） / worklog=棄却（通常の中断処理で新たなdeltaなし）

## 次セッション開始時のアクション

1. 本handoffと確定仕様00〜03、`docs/records/reviews/2026-09-09-linux-pilot-spec-final.md`を読む。作業場所は既存の`.worktrees/isolated-verification`、ブランチは`codex/isolated-verification`。
2. git branch/statusで`7e8d464`以降の状態を確認し、writing-plansと`skills/start-work/references/plan-deviation-defaults.md`に従ってv2計画を作る。全実効ツールの確認方法を先頭に置く。
3. 旧v1計画を再開せず、仕様確定と実動作の成功を区別する。未確認の保護を前提に実モデルを自由起動しない。実行・外部送信の承認範囲と保全対象を維持する。

## 重要な意思決定の履歴

- ADR-0145〜0149: 自律テスト作成、主担当2種・検証担当Codex、共通CLIと3責務、独立Git、AIなし部品の先行。
- ADR-0150: ファイルとGit履歴をスクリプトで独立コピーへ渡す。
- ADR-0151・0152: Linux試作を先行し、ホスト上の子の操作を専用MCP接続でコンテナ内へ限定する。設計としてAcceptedで、動的実証は後続。
