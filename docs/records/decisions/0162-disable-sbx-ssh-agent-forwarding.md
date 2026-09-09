# ADR-0162: ローカルsbxのSSHエージェント転送を無効化する

- **Status**: Proposed
- **Date**: 2026-09-10

## Context

確定仕様のSSH転送拒否に対し、既存sbxのssh.agentForwardingEnabledはtrueだった。`docs/records/experiments/2026-09-10-v3-capability-followup.md`の操作案と直前の回答で、daemon全体への影響、設定変更・停止・利用者の通常PowerShell起動・再照会を提示した。ユーザーは2026-09-10 00:49の作業開始前に「1で」と回答し、同操作を個別承認した。

## Considered Alternatives

1. 転送をfalseへ変更し、daemonを停止、通常PowerShellから起動して反映を確認する。
2. 設定を維持して残る試験方法の調査を続ける。

## Decision

案1を選択する。AIは通常ユーザー側でdaemon running・全VM stoppedを再確認し、ssh.agentForwardingEnabledだけをfalseへ変更、読み直した後にdaemonを停止する。利用者が通常PowerShellで既存sbxのdaemon start -dを実行した後、AIが状態・設定・既存VMを再照会する。過去の内部socket障害の保全条件を維持し、AI内部から起動を代行しない。

## Consequences

- 同daemonの全sandboxでホストSSHエージェントを使う認証・署名が無効となる。既存VMを将来再開した場合にも適用される。
- 既存VM・イメージ・状態退避・ログを保全する。起動失敗時にreset・削除・自動復旧をしない。転送を自動でtrueへ戻さない。
- 本承認は新規VM作成、負荷試験、モデル認証・実行を含まない。設定変更と転送拒否の動的実証は区別する。
- ADR-0157/0158/0160/0161の仕様を実行環境へ適用する操作決定で、これらを置換しない。2026-09-10 00:53、通常起動後も転送false、既存VM同一ID/stoppedを確認して操作を完了。Proposedで個別承認と結果を保存し、サイクル全体整合検査を伴う次の確定チェックポイントで昇格する。承認回答は再取得しない。
