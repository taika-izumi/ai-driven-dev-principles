# ADR-0047: worklog-record（スキル1）は start-work の Post ラッパーに組み込み全プロジェクトへ伝播させる

- **Status**: Accepted
- **Date**: 2026-07-17

## Context

ADR-0044 および spec で worklog-record（スキル1）は「handoff マイルストーンと同じ節目で起動」と定めたが、その節目で実際にどう発火させるかの配線は未決定だった。複数プロジェクト横断で確実に記録が溜まることが本パイプラインの前提であり、発火が不確実だと記録が欠落してスキル2の抽出母数が痩せる。

## Considered Alternatives

- **A: start-work の Post ラッパーに組み込む**: 横断ラッパー Post のマイルストーン処理（現在 session-handoff update・ADR 候補検出を行う箇所）に worklog-record の実行判定を追加する。start-work はプラグイン提供のため全プロジェクトへ自動伝播する。記録ゲート（D4）がノイズを filter する
- **B: start-work 無変更・規範ベース**: CLAUDE.md か skill description に「節目で worklog-record を呼ぶ」規範を置く。軽量だがエージェントの記憶依存で発火が不確実。CLAUDE.md 追加は事前判定必須（ADR-0040）
- **C: 完全手動**: ユーザーが `/worklog-record` を明示実行する。最小実装だが記録が場当たり的になり、継続捕捉という目的が弱まる

## Decision

選択肢A を採用する。`start-work` の Post ラッパー（マイルストーン到達時に session-handoff update と ADR 候補検出を行う箇所）に **worklog-record の実行判定ステップ**を追加する。session-handoff update と同じマイルストーン契機で発火し、記録ゲート（(a) 既存スキルで実施済みでない かつ (b) AI 自律で毎回再現できない、かつ delta が存在する）を通ったものだけ記録する。start-work はプラグイン配信のため、同じ配線が全プロジェクトで効く。

スキル名は **worklog-record / worklog-extract / worklog-skillify** で確定する。

## Consequences

- **良い影響**: 全プロジェクトで記録が確実に溜まる（多プロジェクト捕捉が start-work 経由で「無料」で得られる）。session-handoff update と対称の配線で理解しやすい
- **コスト・留意**: start-work skill を編集するためプラグイン更新が必要（skills/ は template 非同期）。全プロジェクトのマイルストーンで worklog-record のゲート判定が走る（ゲートが大半を弾くため実記録は少量）。start-work の Post 手順が1ステップ増える
- 本決定は start-work（既存スキル）の挙動変更を伴う。実装完了・検証後に Accepted へ昇格する（ADR-0019）
- **部分修正（ADR-0105）**: start-work Post 項目 3 の記録ゲート・契機のインライン記述は worklog-record への参照に置換された（配線自体は現役）
