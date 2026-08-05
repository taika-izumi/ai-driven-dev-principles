# Issue-0051: `retrospective` が要求するハンドオフ Status 値を `session-handoff` が定義していない

- **Status**: open
- **Opened**: 2026-08-05
- **起票元**: `LoopForAlpha#Issue-0087`（構造観察型の取り込み。ADR-0061 / ADR-0062）
- **関連**: `retrospective` スキル（Phase 3）、`session-handoff` スキル（フォーマット定義）、Issue-0049（対処案 (c) が同時に扱える）

## 課題内容

`retrospective` スキルは Phase 3（仕上げ）で「handoff Status を `completed` → `ready-for-next-cycle` へ遷移」と指示しているが、`session-handoff` スキルがフォーマットとして定義する Status は **`in_progress` / `paused` / `completed` の 3 値**であり、`ready-for-next-cycle` は含まれていない。また「`completed` からの遷移」という記述も実態と合っていない（retrospective 実施時点のハンドオフは通常 `in_progress`）。

2 つのガイドラインスキルの記述が互いに整合していないため、実行するエージェントがどちらに従うかを毎回その場で判断することになる。**Status はハンドオフを読む側が最初に見る値**であり、定義外の値が入ると読み手がハンドオフ運用そのものを推測する状態になる。配布先のどのプロジェクトでも同じ齟齬が起きる。

実測（両リポジトリで顕在化）:

- LoopForAlpha（2026-08-05）: `retrospective` 側に従い `ready-for-next-cycle` を設定し、判断の記録として `LoopForAlpha#Issue-0087` を起票
- 本リポジトリ: `docs/working/handoff/master.md` が注記付きで `ready-for-next-cycle` を使用中（不整合を認識したうえで「より具体的な指示である retrospective 側」に従っている）

## 留意（対処を設計するときに参照すること）

- 決めるべきは「サイクル完了後のハンドオフをどう表現するか」であり、選択肢は少なくとも 3 つある: (a) `session-handoff` の定義に `ready-for-next-cycle` を追加する / (b) `retrospective` 側を `completed` に合わせる / (c) サイクル完了時はハンドオフをアーカイブして新規作成する（Issue-0049 のハンドオフ肥大と同時に扱える）

## 検討状況

- 2026-08-05: `LoopForAlpha#Issue-0087` を構造観察型として取り込み（ADR-0061 の経路）。詳細は起票元 issue と、その起票元 `LoopForAlpha` の `docs/records/retrospectives/flow/2026-08-05-stage4-walk-forward-driver.md` 課題#4 が正

## 結論

（open）
