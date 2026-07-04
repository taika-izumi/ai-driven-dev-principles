# ADR-0020: responding-to-user スキルの必須化を廃止し ask-user-enforcer プラグインを撤去

- **Status**: Accepted
- **Date**: 2026-06-15

## Context

これまで本ガイドラインは、ユーザーへのすべての応答の前に `responding-to-user` スキルを呼び出すことを必須としていた（`.github/copilot-instructions.md` の「システム設定 / responding-to-user スキル」節）。このスキルと「毎ターンの強制ルール注入」は、本リポジトリのプラグインではなく別プラグイン `ask-user-enforcer`（marketplace: arche-plugins, v4.0.0）の session-start フックおよびスキルが提供している。

この強制が不要になったため、ガイドラインからの指示削除とプラグイン自体の撤去を行う。

## Considered Alternatives

- **ガイドライン指示だけ削除し、プラグインは残す**: プラグインの session-start フックが毎ターン強制ルールを注入し続けるため、指示を消しても実効的に強制が残り不徹底。却下。
- **スキルディレクトリだけ手動削除する**: `config.json` の `installedPlugins` 登録やフックと不整合になり、環境が壊れるおそれ。却下。
- **CLI でプラグインをアンインストール ＋ ガイドライン節を削除（採用）**: `copilot plugin uninstall ask-user-enforcer` で正規に撤去し、`.github/copilot-instructions.md`（＋ template）から該当節を削除する。整合的で再インストールも可能。

## Decision

1. `.github/copilot-instructions.md` の「### responding-to-user スキル」節を削除し、`scripts/sync-template.ps1` で `template/` に反映する。
2. `ask-user-enforcer` プラグインを `copilot plugin uninstall ask-user-enforcer` で撤去する。

## Consequences

- **良い影響**: 応答ごとの必須スキル呼び出しが不要になり、フローが簡潔になる。
- **コスト・悪い影響**: プラグイン撤去は本プロジェクトに限らず**全リポジトリ・全セッションに影響する環境変更**である（`ask_user` 強制を含む ask-user-enforcer の機能がすべて無効化される）。必要になれば再インストール可能。
- **適用タイミング**: 本セッションでは既に注入済みの強制ルールが残るため、撤去の効果は次セッション以降に現れる。
- 過去サイクルの plan / spec（2026-04-12, 2026-05-01）に残る responding-to-user への言及は、日付付きの歴史的記録として書き換えずに残す。
