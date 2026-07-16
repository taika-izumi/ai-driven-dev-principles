# ADR-0046: スキル3は writing-skills を既定エンジンとし、Skill Creator 技術は設計時抽出で借用、実行環境ガードを設ける

- **Status**: Accepted
- **Date**: 2026-07-16

## Context

ADR-0044 のパイプラインにおけるスキル3（スキル化）は、スキル2で選ばれた候補から新規スキル作成または既存スキル拡張を行う。ここで (1) 委譲先のスキル作成エンジンの選定、(2) 参考にしたい Anthropic Skill Creator の技術をどう取り込むか、(3) 汎用パスが本 repo での実行を前提とする点の安全策、の3つを定める必要がある。

## Considered Alternatives

- **エンジン選定**（D1）: `writing-skills` / Anthropic Skill Creator / 自作 の比較。writing-skills は superpowers エコシステム内で TDD・規律思想が本 repo の ADR/検証文化と一致し、軽量で日本語 doc 運用に馴染む
- **Skill Creator を実行時にまるごとロードして一部だけ使う**（D17）: 未使用部分まで文脈に載るムダが生じ、Skill Creator の内部構成が変わると壊れる結合も抱える。却下
- **実行環境ガードを設けない**（D16）: 汎用（プラグイン配信）パスを本 repo 以外で実行すると配信先が無く、誤配置が起きる

## Decision

- **既定エンジン＝writing-skills**。スキル3自体は薄いオーケストレーション層（候補コンテキスト収集＋本 repo 規約充足の保証。汎用パスは既存「Issue → extend-guidelines → スキル作成」フローへの橋渡し）（D1/ADR-0044 D11）
- **Skill Creator の技術は「設計時抽出」で借用する**（D17）: Skill Creator の「description 自動最適化」「定量 eval ループ」の2技術を、**実装段階で一度読んで手法だけを抽出**し、スキル3自身の `references/` に自前の言葉で蒸留内包する。スキル3の**実行時には Skill Creator をロードしない**（エンジンは writing-skills のみ）。実行時依存なし・外部構成への結合なし
- **実行環境ガード**（D16）: スキル3冒頭で実行環境が本 repo（ai-driven-dev-principles）かを安定マーカー（git remote URL に `ai-driven-dev-principles`、またはプラグイン manifest 等の固有ファイル存在。実装時に確定）で判定する。**汎用（プラグイン配信）パス かつ 本 repo でない**場合は警告＋ユーザー確認を出す（選択肢: ①この場のプロジェクトローカルスキルとして作成 ②配信元 repo へ移動して実行 ③中止）。固有パス（ローカルスキル / CLAUDE.md）はガード不要でそのまま実行する

## Consequences

- **良い影響**: エンジンを writing-skills に統一することで規律が一貫する。ムダな読み込み・外部結合が無い（高凝集・疎結合）。汎用パスの誤配置を人間確認で予防できる
- **コスト・留意**: 設計時抽出のため Skill Creator の将来改良に自動追従しない（手法は安定で実害は小さい＝YAGNI）。環境判定マーカーの具体は実装時に確定する必要がある
