# スキル1 エントリ・スキーマ（改訂版・精査中）

- **位置づけ**: brainstorming の設計素材。第三者レビュー反映済み・**スキーマ確定**（2026-07-16）
- **⚠ 保留中の追補**: ログ・ライフサイクル対策として **`id` フィールドの必須追加**が提案されたが**ユーザー承認前に中断**。詳細は state メモの「■ 再開ポイント（未確定論点）」参照。承認されればここに `id`（`<project>-<date>-<NN>`）を追記する
- **関連**: `docs/working/handoff/skill-pipeline-brainstorming-state.md`（決定 D1〜D14 ＋ 未確定論点）

## 核心の設計原理（レビューで確立）

スキル2が見たい信号は **delta**＝「AIがデフォルトでやること」と「実際に必要だったこと」の差分。発生源は2種類:

- **躓き型（friction）**: エラー・手戻り・非自明な試行錯誤
- **注入型（corrections）**: 人間が与えた指示・修正・好み（AIが自力では推測できない規約の注入）

この2つの**少なくとも一方が存在すること**が「スキル化する価値がある（D4(b)）」の構造的な実装になる。両方空＝AIが自律で毎回同じに再現できた作業＝記録不要。

## 設計上の綱引き

1. コンパクト（D3）: 節目で1回追記。各フィールド原則1〜2行
2. スキル2が機械走査で分析できる（D6）
3. 記録ゲートの根拠が残る（D4）— delta の存在で担保
4. 追跡可能性（原則1）

---

## 必須フィールド（空だと記録を弾く）

| フィールド | 型 | 役割 |
|---|---|---|
| `date` | string | 記録日。スキル2の時系列・頻度分析 |
| `project` | string | 出所プロジェクト名。**連結後も各行で出所が分かる**（フォルダ分割は物理配置、これは行内属性） |
| `scope` | enum | `project-specific` / `general-candidate`（D6。振り分け D5 の起点。record 時は暫定、スキル2が最終確定） |
| `title` | string | 識別子。**動詞句で15文字程度**に書式を縛る（一覧・重複目視用。context と役割が別） |
| `context` | string | 状況記述: 何をしていて、なぜこの作業が発生したか |
| `procedure` | string[] | 実際に踏んだ手順（**文字列配列**で構造保持＝1行のまま可読性確保。スキル本体の種） |

### delta ペア（`friction` または `corrections` の**少なくとも一方が必須**）

| フィールド | 型 | 役割 |
|---|---|---|
| `friction` | string | 躓き型 delta。躓き・手戻り・非自明な試行錯誤（落とし穴系スキルの種） |
| `corrections` | string[] | 注入型 delta。人間が与えた指示・修正を**発言に近い形**で1〜2行（規約・好み系スキルの種。NFD の核心＝修正発言がスキルの原文になる） |

---

## 任意フィールド（空可。スキル2が価値判定・再導出）

| フィールド | 型 | 役割 |
|---|---|---|
| `skillification_hint` | string | なぜスキル化価値があるかの主張（1行）。仮説。スキル2が friction/corrections から再導出・上書き可 |
| `outcome` | enum | `success` / `partial` / `failed`。failed をそのままスキル化すると事故→スキル2のフィルタ。failed はアンチパターン集の種 |
| `tools` | string[] | 使ったツール・コマンド。横断で「このツール操作が頻出」を機械的にクラスタリング |
| `applied_rules` | string[] | 適用した明示ルール（ADR/CLAUDE.md）。**逸脱注記可**（例 `"ADR-0033 (逸脱)"`）→ スキル2の第3出力＝既存スキルの改訂候補発見 |
| `refs` | string[] | 関連 ADR・コミット・ファイルパス（原則1 追跡可能性） |

---

## 形式: JSONL（1行1エントリ）で確定

- 複数プロジェクトのファイルを**単純連結して1パス走査**できる（仕組みの根幹）
- 人間可読性は書き込み形式でなく**表示側（jq 整形）の問題**として切り離す

## 具体例

```jsonl
{"date":"2026-07-16","project":"MakeAiInstructions","scope":"general-candidate","title":"未追跡ファイルのパス指定コミット回避","context":"handoff更新をコミットしようとしたが対象が未追跡でgit commit -Fにパス指定して失敗","procedure":["git add <file> で先にステージ","git commit -F <msgfile> でメッセージ渡し"],"friction":"未追跡ファイルへ直接パス指定コミットが不可でエラー。原因特定に試行錯誤","outcome":"success","applied_rules":["Issue-0015"],"refs":["docs/working/handoff/master.md"],"tools":["git"]}
{"date":"2026-07-16","project":"MakeAiInstructions","scope":"general-candidate","title":"走り書きメモを規約付きで分類整理","context":"複数の走り書きファイルを人間の分類方針に従って整理させたかった。躓きは無い","procedure":["ファイル群を内容で分類","指定された分類軸でフォルダへ振り分け"],"corrections":["分類はflowとsystemで分けて","READMEには1行インデックスだけ足して"],"outcome":"success","skillification_hint":"AIが自力では推測できない分類規約を毎回注入している。規約化すれば再注入不要"}
```

2つ目は **friction が空でも corrections があるので記録成立** — 注入型を取りこぼさない。

---

## 決着済み

- **純粋判断型の割り切り**: friction も corrections も無く hint だけのエントリは**弾く**で確定（最も弱い候補・ノイズ防止）
- **overlap 対応（retrospective との重複）**: skill2 の本 repo 向け汎用候補も **Issue 草案として起票 → `docs/working/issues/` バックログで重複排除**（唯一の合流点）。skill3 汎用パスは既存「Issue → extend-guidelines → スキル作成」への橋渡し（薄い）。逸脱注記は**データのみ捕捉**し、skill2 出力3（ルール改訂候補）は **v2 へ延期**（コア目的＝スキル化とは別関心のためv1スコープを絞る。他プロジェクトの逸脱は手動 Issue 移行の経路があるが面倒で未使用＝将来 v2 が自動化し得る）

→ 論点3以降（保存レイアウト）は state メモ D13/D14 で解決済み。**残る唯一の未確定＝ログ・ライフサイクル対策**（id 追加・processed.jsonl。state メモ「■ 再開ポイント（未確定論点）」参照）
