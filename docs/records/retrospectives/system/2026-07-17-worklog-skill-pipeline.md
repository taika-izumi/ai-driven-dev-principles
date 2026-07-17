# Retrospective: 3スキルパイプライン（作業記録→候補抽出→スキル化）の設計・実装完了

- **Subject**: 対話モードのガイドライン拡張として、AI に作業させた後の delta を継続的に記録・横断抽出・スキル化する3スキル（worklog-record / worklog-extract / worklog-skillify）と中央ストア共有契約の新規追加
- **Branch**: feature/worklog-skill-pipeline（merge済み: 7ed7b32）
- **Period**: 2026-07-16 〜 2026-07-17
- **Plan**: `docs/working/plans/2026-07-17-worklog-skill-pipeline.md`
- **Spec**: `docs/current/specs/2026-07-17-worklog-skill-pipeline/`（00-overview ＋ 01〜04）
- **Related ADRs**: ADR-0044, ADR-0045, ADR-0046, ADR-0047
- **Facilitator**: メインエージェント (Claude Opus 4.7 / Claude Code)
- **Independent Reviewer**: rubber-duck (Claude Opus 4.7)

## 1. Done（達成サマリ）

- **実装フェーズ**: 実装計画 Task 1〜7 完了
  - Task 1: `skills/worklog-record/references/store-format.md`（共有ストア契約）
  - Task 2: `skills/worklog-record/SKILL.md`
  - Task 3: `skills/start-work/SKILL.md` Post ラッパーへ worklog-record 配線
  - Task 4: `skills/worklog-extract/SKILL.md`
  - Task 5: `skills/worklog-skillify/references/skill-authoring-techniques.md`（Skill Creator 借用技術）
  - Task 6: `skills/worklog-skillify/SKILL.md`
  - Task 7: 統合検証・プラグイン更新・ADR 昇格
- **レビュー指摘対処**: 重大 1 件（ADR-0045 の `adopted` 状態追補・skill2 採用〜skill3 完了前の窓を厳密層で捕捉）＋軽微 5 件（deferred クラスタ再同定・Issue ルーティング/dedup 合流点・id 採番の改善版注記・初回ファイル生成 lastSeen 明示・スモークテストのシェル前提注記）を計画/spec/skill doc に反映（コミット 8a0f982）
- **ADR 昇格**: 0044/0045/0046/0047 を Accepted へ昇格（実装完了チェックポイント。ADR-0019）
- **スモークテスト合格**: worklog-record 経由で 1 エントリ実追記（`$HOME/.ai-dev-worklog/MakeAiInstructions/log.jsonl`、id `MakeAiInstructions-2026-07-17-01`）→ worklog-extract で候補リスト提示 → 採否「保留」で end-to-end 確認
- **master merge・cleanup**: `--no-ff` マージ（7ed7b32）、feature ブランチ削除
- **完了基準**（spec 00-overview.md）: 8/8 達成
- **中央ストア初回動作確認**: `$HOME/.ai-dev-worklog/` 配下のディレクトリ・`projects.json`・`log.jsonl` の初回作成が spec 通り動作

## 2. Went Well（うまくいったこと）

- **レビュー指摘対処を実装着手前に完了**: 実装フェーズで grep 検証整合の後戻りなし。計画側の grep キーワード追加（初回/lastSeen/adopted）と SKILL.md 本文執筆を同期させる ADR-0034 の実運用がスムーズ
- **ADR-0045 追補を Proposed 期間中の書き直しで扱った判断**: 新 ADR を作らず、決定範囲（スキル1ログのスキーマ・ライフサイクル）を単一 ADR に集約して情報密度維持。ADR-0030（Proposed 期間中は書き直し自由）と ADR-0041（Superseded は Accepted 後の置換）の適用境界が実運用で機能
- **Inline 実行方式（executing-plans）が本タスクの規模に適合**: skill markdown 中心・全 7 Task を私（メイン）が一貫して書けたため、adopted 状態の反映など横断的整合が保ちやすかった
- **各 Task の grep 受入チェックが観測可能な検証として機能**: SKILL.md 本文執筆と検証が同一フェーズで完結（ADR-0034 の趣旨通り）
- **コミット粒度が Task 単位で綺麗**: レビュー指摘対処＝1コミット / Task ごと1コミット / Task 7 の統合＝1コミット、と履歴が追跡しやすい構成
- **スモークテストを本セッション内で通し切った**: プラグイン更新後、AI エージェント側の Skill ツール availability にはセッション内で反映済みで、end-to-end 検証を先送りせずに済んだ（`/skills` UI との経路差は回避策で対処したが、根本課題は Issue-0024 で起票）
- **`git merge --no-ff -F <file>` + scratchpad マージメッセージ運用**: handoff の留意点通りに実行し、履歴にサブプロジェクトの塊が残った

## 3. Struggled（苦労したこと・手戻り）

- **事象**: spec 00-overview.md の完了基準を [x] へ更新する Edit で、私が old_string に半角「()」を書いたが元ファイルは全角「（）」でミスマッチ → 1 回目 Edit エラー
  - **原因**: Grep で目視した内容から Edit テキストを構成する経路で、脳内転記時に括弧種別を無意識変換してしまった。ADR-0038 は Read 段階の実体確認を規定するが、Edit の old_string 生成段階の規範は未整備
  - **影響**: 即座に全角で再送信して復旧、実害小。記憶メモ [[tool-call-anomaly-stop-and-checkpoint]] の前兆パターンに近く、頻発するとリスク
  - **対処**: 全角括弧で old_string を再送信して修正。今回は起票見送り（5. Issues 参照）
- **事象**: worklog-record スモークテストで delta 候補の絞り込みに一瞬迷った
  - **原因**: worklog-record スキル doc は「1 エントリ記録」を前提とするが、複数候補時の優先順位付けを明示していない
  - **影響**: 候補を洗い出して 1 件選ぶことで解決したが、判断に時間を要した
  - **対処**: 「Proposed ADR の追補を内容改訂で扱う」判断（本セッションで最も強い delta）を 1 件選択して記録。課題化して起票（Issue-0023）
- **事象**: ADR-0045 初版で「skill2 採用〜skill3 完了前の窓（`adopted` 状態）」が抜け落ち、実装計画のラバーダックレビュー時点まで検出されなかった
  - **原因**: brainstorming/spec/plan の各段階で状態遷移のケース網羅（skill3 が中断・別セッション持ち越し・環境ガード発火などで完結しないパターン）を辿らなかった。ADR-0045 の Considered Alternatives にも「レビュー指摘（ラバーダック）で判明」と後追いで注記
  - **影響**: 実装計画の一部書き直しと ADR-0045 の内容改訂（コミット 8a0f982）。実装着手前に修正できたため後戻り最小。ただしレビューが無ければ adopted 窓の穴が残ったまま実装されていた可能性
  - **対処**: ラバーダック指摘を受けて即対処（ADR-0045 追補・spec/計画反映）。起票は見送り（実装計画レビューで拾える仕組みが機能した実績があり、brainstorming 段階の状態遷移ケース網羅チェック強化は Handoff Forward の継続観察へ）

## 4. Tech Notes（古びない技術知見）

> **スコープ（ADR-0021 / ADR-0012）**
> - **含める**: ツール挙動・環境の罠・回避策・推奨手順など、開発フローやプロジェクトに依存せず古びない汎用技術知見
> - **除外**: 開発対象システムの仕様・ドメイン知識（ビジネスルール・用語・業務制約など）。これらは当該システムの仕様書に記載すること

- **Edit の old_string は Grep 目視から書き起こすのではなく Read で読んだ行から直接転記する**
  - **コンテキスト**: AI エージェントによるファイル編集全般
  - **知見**: 全角/半角括弧・空白の差異など微妙な差異は目視で認識しにくく、脳内転記時に無意識変換されるリスクがある。Grep のパターンマッチ自体は正確だが、Grep 出力→Edit の old_string への転記経路にリスクがある
  - **推奨**: Edit の old_string は Read で読んだ行を（脳内変換せず）そのまま貼り付ける

- **`git merge --no-ff -F <file>` はマルチライン message の両シェル対応で堅牢**
  - **コンテキスト**: Windows/Unix 両対応の git 運用
  - **知見**: Bash（POSIX sh）でも PowerShell でも動く（PowerShell の here-string や Bash の here-doc に依存しない）。scratchpad にメッセージファイルを書いてパス指定するパターンが堅牢
  - **参照**: handoff の留意点の実運用

- **JSONL の 1 行エントリは長くても改行なしで literal 書き込み系ツールで直接書ける**
  - **コンテキスト**: 構造化データファイル操作全般
  - **知見**: 1000 文字前後の JSONL 1 行をエスケープ処理なしで書き込み、Bash の `cat | tail -1` で 1 行取得できた。literal 書き込み系ツール（内容をそのまま書く系。escape 処理をしない）では改行エスケープ不要。scratchpad 経由も不要

## 5. Issues（課題抽出）

振り返りで見えた課題を抽出する。各課題について `事象 / 原因 / 影響` を記録し、`対象システム固有` か `開発フロー/ガイドライン関連` に分類する。**ここでは抽出と分類までにとどめ、対策の設計・採用/保留/却下・ADR 化は行わない**（次サイクルの責務。ADR-0021）。

対象システム固有の課題: なし。

**課題化を検討したが見送ったもの**: 「Edit の old_string を Grep 出力から転記する経路で括弧種別（全角/半角）が無意識変換される」— 1 回のエラーは即修復可能で実害小。記憶メモ [[tool-call-anomaly-stop-and-checkpoint]] で既にカバーされている。頻発するようになった時点で改めて課題化する（ユーザー判断）。

> 開発フロー課題 2 件（Issue-0023, Issue-0024）は `flow/2026-07-17-worklog-skill-pipeline.md` 参照。

## 6. Independent Review Notes（rubber-duck 指摘）

サブエージェント（general-purpose、Claude Opus 4.7）による独立視点レビュー。指摘は 9 件（高 1 / 中 4 / 低 4）。

- **指摘 #1**（medium）: brainstorming/writing-plans 段階で `adopted` 状態が抜け落ちた上流ギャップが Struggled/Issues に未記載
  - **メインの応答**: 採用
  - **反映先**: 「3. Struggled」に事象1件追加
- **指摘 #2**（low）: Skill Creator 参照可否の分岐結果が未記録
  - **メインの応答**: 部分採用（Tech Notes ではなく Handoff Forward の継続観察に配置。次に Skill Creator が available になった時に借用元スキルの実効性を確認する継続観察課題として扱う）
  - **反映先**: 「7. Handoff Forward」に追記
- **指摘 #3**（low）: `deferred` の end-to-end 検証未記録（採否「保留」で `processed.jsonl` 未追記）
  - **メインの応答**: 採用
  - **反映先**: 「7. Handoff Forward」の継続観察に追記
- **指摘 #4**（high）: Went Well #6 と Issue-0024 が同一事象の二重計上
  - **メインの応答**: 採用
  - **反映先**: 「2. Went Well」の該当項目を修正し、根本課題は Issue-0024 で起票済み旨を明記
- **指摘 #5**（medium）: Issue-0023 のフロー課題分類の根拠が弱い（本 repo=meta-repo で system/flow 境界が曖昧）
  - **メインの応答**: 部分採用。ユーザー判断で「本プロジェクトはガイドライン改善作業なので system と flow は本質的に区別できず、すべての課題が両方の性格を持つ」との認識を得た。Issue-0023 は分類変更せず flow のまま維持（最小変更）。**meta-repo における system/flow 分類軸の妥当性そのもの**を継続観察対象とする
  - **反映先**: 「7. Handoff Forward」の継続観察に追記
- **指摘 #6**（low）: Issue-0024 の分類は妥当（指摘なし）
- **指摘 #7**（medium）: Tech Note #2 は Claude Code UI 固有で古びリスク・Issue-0024 と二重計上気味
  - **メインの応答**: 採用
  - **反映先**: 「4. Tech Notes」の該当項目を削除（Issue-0024 に一元化）
- **指摘 #8**（low）: Tech Note #4 の表現を汎化推奨
  - **メインの応答**: 採用
  - **反映先**: 「4. Tech Notes」の該当項目を「literal 書き込み系ツール全般」に汎化
- **指摘 #9**（low）: Tech Note #1/#3 は妥当（指摘なし）

## 7. Handoff Forward（次サイクルへの申し送り）

- **課題バックログ**: 抽出した課題は issues に起票済み（Issue-0023, Issue-0024。詳細は `flow/2026-07-17-worklog-skill-pipeline.md`）。着手の要否・時期はユーザー判断
- **継続観察**:
  - **worklog パイプラインの実運用**: 本サイクルはスモークテストで採否「保留」を選んだため `processed.jsonl` は未作成。次サイクル以降の実運用で、`adopted` / `skillified` / `merged` / `rejected` / `deferred` の各 outcome 実追記の end-to-end を確認する（特に `deferred` の再浮上判定の実効性）
  - **Skill Creator の availability と設計時借用の実効性**: 本サイクルでは Anthropic Skill Creator スキルは available-skills 一覧になく、蒸留内容（`skills/worklog-skillify/references/skill-authoring-techniques.md`）で v1 成立。将来 Skill Creator が available になった時点で、借用元スキルとの実効性差を確認して蒸留リファレンスを更新するか判断する（ADR-0046 の設計時借用の運用検証）
  - **brainstorming 段階の状態遷移ケース網羅チェック**: 本サイクルでは ADR-0045 初版で `adopted` 状態が抜け落ちラバーダックレビューで検出された（Struggled 参照）。実装計画レビューの仕組みは機能したが、brainstorming/spec 段階で状態遷移の完結しないパターン（skill3 中断・持ち越し・環境ガード発火など）を辿るチェック観点を強化する余地あり
  - **meta-repo における system/flow 分類軸の妥当性**: 本 repo はガイドライン改善プロジェクトの性格上、すべての課題が「対象システム固有」と「開発フロー」の両方の性格を持つ（ユーザー認識・rubber-duck 指摘 #5）。ADR-0021 の分類軸を meta-repo で運用する際の妥当性・境界規範の明確化が長期的な課題として残る
- **プラグイン更新済み**: 本サイクル成果物（worklog-* 3 スキル・start-work Post 配線・skill authoring 借用技術）は skills/ の変更のため、プラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）まで実行環境に反映されない。本サイクルで実施済み（`√ Updated 1 marketplace`）。次サイクル開始時に新規スキルが必要になったら再度更新
- **次サブプロジェクト候補**: Issue-0006（横断変更の計画網羅漏れ）・Issue-0021（Tech Notes 横断再利用）などの既存 open 課題が主要バックログ。新規 Issue-0023/0024 は worklog パイプライン運用開始後の実感で優先度判断
