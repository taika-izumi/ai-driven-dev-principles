# ADR-0155: Docker Sandboxesの全体ネットワーク初期方針をdeny-allにする

- **Status**: Proposed
- **Date**: 2026-09-09

## Context

AIなし試験のVM作成は、sbx全体ネットワーク方針が未初期化のため停止した。試験VMだけの規則とは異なり、初期化は今後の全ローカルsbxにも適用されると説明したうえで、ユーザーは「deny-allで初期化し、試験を再開する（推奨）」へ「1で」と回答した。

## Considered Alternatives

1. deny-all: 試験に不要なVM外向き通信を既定で拒否し、必要な用途が生じた時に許可を検討する。
2. balanced: AIサービスやパッケージレジストリ等を初期状態から許可する。
3. allow-all: 外向き通信を広く許可する。
4. 初期化を保留する: VM試験も停止したままになる。

## Decision

ユーザーの個別承認に基づき、`sbx policy init deny-all`を実行する。実行後の`sbx policy ls --json`で、scope=global、resource_type=network、decision=deny、resources=["**"]、status=activeを確認した。

## Consequences

- このPCの今後のローカルsbxにも影響する。モデル等への接続が必要な用途では、実効規則と必要な許可を別途確認する。
- ホストの通常通信やDocker Desktop/LoopForAlphaのネットワーク設定を変更する決定ではない。
- 個別VMやkitの規則が重なるため、初期化だけで全VMの実効拒否を検証済みとはしない。
- 既存VMは0台であることを前後で確認した。証拠は`.tmp/sbx-smoke-20260909-01/policy-init.txt`と`global-policy.json`。
