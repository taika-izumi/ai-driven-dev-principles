# ADR-0055: start-work Phase -1 にスキル availability の AI 側判定規範を追加する

- **Status**: Accepted
- **Date**: 2026-07-18

## Context

`start-work` の Phase -1（依存検出）は superpowers スキルの利用可否を確認するが、**本セッションで新規追加・改定した `ai-driven-dev-principles` スキルの availability 判定手順**を持たない。

worklog パイプライン初回実装サイクル（2026-07-17）およびスキーマ v2 改訂サイクル（2026-07-18 再発）で、プラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）後に新規/改定スキルの反映確認が必要になった。このとき、AI 側の availability（system-reminder の available-skills 一覧・Skill ツール呼び出し可否）にはセッション内で反映済みだったが、Claude Code の UI `/skills` 表示には反映されておらず、経路差があった。最初に UI 表示でユーザーに確認依頼したため一往復のやりとりが無駄になった（Issue-0024）。プラグイン更新→スキル追加のたびにこの確認往復が積み上がる。

なお、プラグイン更新コマンド自体は AI 側から実行・反映確認ができない環境制約がある。

## Considered Alternatives

- **現状維持（Phase -1 は superpowers のみ確認）**: 反映確認の往復が毎回発生する
- **UI `/skills` 表示で判定する**: UI は反映が遅れる経路であり、往復を増やす方向。棄却
- **AI 側 availability で判定する（採用）**: system-reminder の available-skills 一覧・Skill ツール呼び出し可否は UI とは別経路でセッション内に反映される。AI が観測できる事実（ADR-0032）で判定でき、UI 経路差に惑わされない
- **さらに skills/ 改定検出→毎回プラグイン更新プロンプトも追加する**: Phase -1 が重くなる。availability 判定の規範化で足りるため、この段階では過剰（YAGNI）

## Decision

`start-work` の Phase -1 に手順を追加する:

> 本セッションで新規追加/改定した `ai-driven-dev-principles` スキルの availability は、**AI 側の system-reminder（available-skills 一覧）または Skill ツール呼び出し可否**で判定する。UI の `/skills` 表示には依存しない。反映が確認できない場合は、ユーザーへ `/plugin marketplace update ai-driven-dev-principles` の実行を依頼する（AI からは実行不可）。

判定条件はすべて AI が観測可能な事実（available-skills 一覧・Skill 呼び出しの成否）で書き、実行不能なプラグイン更新は判断・実行主体をユーザーへ明示的に移す（ADR-0032）。

## Consequences

- **良い影響**: 反映確認の往復を削減できる。UI 経路差に惑わされない。プラグイン更新→スキル追加のたびの運用オーバーヘッドが下がる
- **コスト・留意**: Phase -1 の手順が1つ増える。プラグイン更新自体は AI 実行不可のため、未反映時のユーザー依頼は環境制約として残る
- Issue-0024 は本 ADR で close する
