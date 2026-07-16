# ADR-0045: スキル1のログは delta 核心スキーマ・JSONL・追記専用ライフサイクルで設計する

- **Status**: Accepted
- **Date**: 2026-07-17

## Context

スキル2が価値判定に使う信号は **delta**＝「AI がデフォルトでやること」と「実際に必要だったこと」の差分である。発生源は2種類＝躓き型（friction）と注入型（corrections＝人間が注入した指示・修正）。少なくとも一方の存在が「スキル化する価値がある（ADR-0044 の記録ゲート (b)）」の構造的な実装になる。

記録はコンパクト（ADR-0044 の D3）かつ機械走査可能（同 D6）である必要がある。加えて、運用でログが積み上がると (1) スキル2の分析が重くなる、(2) スキル化済みログから既存スキルと同内容を再提案してしまう、という懸念がある（D14）。

本 ADR は ADR-0044 のパイプラインにおけるスキル1のデータ設計とログのライフサイクルを定める。

## Considered Alternatives

- **純粋判断型（friction も corrections も無く hint のみ）も記録する**: 最も弱い候補でノイズになる。弾く（D9）
- **エントリ形式を可読な整形 JSON にする**: 複数プロジェクトのファイルを単純連結して1パス走査できることが仕組みの根幹。JSONL を採用し、可読性は表示側（jq 整形）の問題として分離する（D9）
- **ライフサイクル対策を設けない**: 分析が肥大し、処理済みを再提案してしまう。追記専用の `processed.jsonl` 台帳を新設する（D15）
- **保留候補を明示状態にしない（台帳に書かない）**: 次回また分析・再提示され、分析コストも減らない。`deferred` 状態を設け、新しい根拠が増えたときのみ再浮上させる（D15）
- **保留を rejected と同じ完全除外にする**: 保留が事実上忘れられる。新根拠での再浮上を残す方式を採用（D15）
- **skill2 採用〜skill3 完了前を台帳に残さない（skillified/merged だけで足りるとする）**: レビュー指摘（ラバーダック）で判明。skill3 の別セッション持ち越し・実行環境ガード発火（仕様上の中断ケース）・中断で台帳空白のまま次回 skill2 実行を迎え、採用済みエントリが再提示される。`adopted` 状態を追加し窓を厳密層で捕捉する

## Decision

- **エントリ核心＝delta**。必須フィールド: `id` / `date` / `project` / `scope` / `title`（動詞句15字程度）/ `context` / `procedure`（string[]）、**かつ `friction`（string）または `corrections`（string[]）の少なくとも一方**（D9）
- **任意フィールド**: `skillification_hint` / `outcome`（success/partial/failed＝作業結果）/ `tools` / `applied_rules`（逸脱注記可）/ `refs`（D9）
- **形式**: JSONL（1行1エントリ、連結1パス走査が根幹）（D9）
- **保存レイアウト**（D13）: ルート `<ホーム>/.ai-dev-worklog/`（ツール中立名）、`projects.json`（`{ "<folderName>": { "path", "lastSeen" } }`）、各プロジェクト `<folderName>/log.jsonl`（追記専用1本）、集約ルート `processed.jsonl`（処理済み台帳）。git 管理は v1 ではオプション
- **ライフサイクル**（D15 + adopted-pending 対策）: `id` は人間可読で安定な `<project>-<date>-<NN>`（NN＝そのプロジェクトのその日の連番、skill1 が既存 log 末尾を見て採番）。`processed.jsonl` の `outcome` は `adopted` / `skillified` / `rejected` / `merged` / `deferred` の5種。**状態遷移**: `adopted`（skill2 採用時に即記録・Issue 草案化と同期）→ `skillified`（skill3 で新規スキル作成）または `merged`（skill3 で既存スキルへ統合）。`rejected` / `deferred` は skill2 が単独で確定させる終端状態。追記専用 JSONL のため状態遷移は**同一 id の後続レコード追記で表現**し、読み側は「最新の同一 id エントリの outcome」を採用する。スキル2は開始時に台帳を読み処理済み id（`adopted`/`skillified`/`rejected`/`merged`）を分析対象から除外する（分析コストは未処理エントリ数でスケール）。`deferred` はその時点のクラスタ根拠数を記録し、新しい該当エントリが増えたときのみ再提示する。**adopted の意義**: 二層 dedup（①台帳＝厳密・②既存スキル description 一致＝あいまい）は「スキルが作成されて初めて」あいまい層が効くため、skill2 採用〜skill3 完了までの窓で採用済みエントリが台帳未登録になる穴があった。`adopted` はこの窓を厳密層で捕捉する。再提案防止は二層＝①台帳（厳密・`adopted` 含む処理済みは丸ごと除外）②既存スキル重複排除（あいまい・未処理でも既存 description 一致で除外）
- **スキル2フロー**（D14）: ユーザーがオンデマンド実行。サブエージェントで全 `log.jsonl` を1パス走査 → 類似エントリをクラスタリング → 評価（横断再発回数・出所プロジェクト数・delta 重み・scope 再判定・既存スキル重複排除）→ ランク付き候補リストを人間に提示 → 人間が採否 → Issue 草案化。頻度はハード閾値を置かずソフトな判断材料とする
- **archive 退避は v1 では作らず v2**（物理ファイル肥大時。YAGNI、D13/D15）

## Consequences

- **良い影響**: 分析コストが未処理エントリ数でスケールする（heaviness 解決）。誤分類・保留がタグと台帳で安く扱える。delta 必須により記録ゲートの根拠が構造化される
- **コスト・留意**: エントリ側 `outcome`（作業結果 success/partial/failed）と台帳側 `outcome`（採否結果 adopted/skillified/rejected/merged/deferred）の2つの同名フィールドが並存するため、スキル doc に混同注意を明記する。id 採番のため skill1 が既存 log 末尾を読む必要がある
- **ライフサイクル状態は5種（`adopted` 追加）**: 追記専用 JSONL では同一 id の後続レコード追記で状態遷移を表現し、読み側は最新レコードの outcome を採用する（skill2 の台帳読み・skill3 の状態確定は同じ規約に従う）
- 詳細・具体例は `docs/working/skill1-entry-schema-strawman.md` を参照
