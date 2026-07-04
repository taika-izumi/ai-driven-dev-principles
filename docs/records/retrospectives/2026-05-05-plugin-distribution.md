# Retrospective: Copilot CLI プラグイン配布化

- **Subject**: skills を Copilot CLI プラグインとして配布する仕組みの確立
- **Branch**: feature/plugin-distribution（merge済み: `a92dc81`）
- **Period**: 2026-05-04 〜 2026-05-05
- **Plan**: なし（systematic-debugging を起点とする探索型サブプロジェクト）
- **Spec**: なし
- **Related ADRs**: ADR-0015, ADR-0016, ADR-0017
- **Facilitator**: メインエージェント (Claude Opus 4.7)
- **Independent Reviewer**: rubber-duck (default model)

## 1. Done（達成サマリ）

- ADR-0015 起票・実装: 6案比較の上で「Copilot CLI プラグインとして配布」方針を選定、`.claude-plugin/{plugin,marketplace}.json` 追加（`610b2b1`, `ed06ff3`）
- ADR-0016 起票・実装: template/ から skills/ を削除（7 SKILL.md + 1 template ファイル削除）、プラグイン専売へ再設計、template.manifest を 10 → 3 ファイルに削減、CONTRIBUTING.md にスキル変更手順追加（`577c029`, `95eb4c2`）
- ADR-0017 起票・実装: dev-link junction 方式を廃止、`copilot plugin marketplace add <path>` の正規手順へ修正。dev-link.{ps1,sh} 削除、ADR-0015 を `Accepted (amended by ADR-0017)` に更新（`6dc9da8`, `72db1ac`）
- README に private リポジトリ前提のインストール手順整備（A: GitHub source / B: ローカル directory）（`00fc006`）
- master へ `--no-ff` マージ → push 完了（merge: `a92dc81`）
- 環境を「GitHub source 経由 install」へ切替: `marketplace remove --force` → `marketplace add taika-izumi/ai-driven-dev-principles` → `install` を実行し、ソースフォルダから完全独立した状態を達成

## 2. Went Well（うまくいったこと）

- **systematic-debugging の効用**: dev-link が動かない問題で Phase 1 のログ精読を踏んだ結果、`Marketplace "local" not found` を即特定し、`copilot plugin --help` で正規手順 (`marketplace add`) に到達できた。当てずっぽうの修正を回避できた
- **ADR の即時起票運用（ADR-0006 準拠）**: 方針転換時（dev-link → marketplace add）に ADR-0017 を即起票し、ADR-0015 の Status を `Accepted (amended by ADR-0017)` へ更新。判断経緯を喪失せず追跡可能性を維持
- **段階的なユーザー確認による方向修正**: 「マーケットプレイス登録 = 公開？」「private リポ前提だが？」など、こちらの暗黙仮定をユーザーが都度補正してくれたことで、README を A（GitHub）/ B（ローカル directory）両方式に整理できた
- **インストール独立性の活用**: Copilot CLI の install がコピー方式と判明した時点で「ソース移動しても skill は動く」と整理でき、移行手順がシンプルになった
- **handoff コミット運用の機能**: 本サイクルはセッション跨ぎ（前セッション dev-link 失敗 → 本セッション軌道修正）が発生したが、`13bcabe` / `085a111` の handoff コミットにより文脈喪失なく作業を再開できた。原則3（コンテキスト管理）の運用効果を実証
- **方式 A の動作検証成功**: master push 後に `marketplace add taika-izumi/ai-driven-dev-principles` を実行し、private リポでも `copilot login` 認証経由で GitHub source インストールが動作することを実証（ADR-0017 起票時点では未検証だった項目）

## 3. Struggled（苦労したこと・手戻り）

- **事象**: dev-link 方式（`installed-plugins/local/` への junction）を採用して実装したが、skill が認識されなかった
  - **原因**: Copilot CLI は marketplace 登録を経由する設計で、暗黙の `local` marketplace は存在しない。ファイルが物理的に置いてあっても認識されない
  - **影響**: 前セッションの実装は丸ごと廃棄、ADR-0015 を amend するための ADR-0017 起票が必要に。dev-link スクリプトと junction を削除
  - **対処**: systematic-debugging Phase 1 でログを精読、`copilot plugin --help` を確認して正規手順を発見

- **事象**: 「private リポジトリ前提」という制約が後から判明し、README 全面改訂が発生
  - **原因**: 初版 README は public 配布前提で書かれており（GitHub source のみ）、要求の深堀りが不足していた
  - **影響**: README 全面改訂、ADR-0017 に補足セクション追加
  - **対処**: ユーザー補足を受け A（GitHub + login）/ B（ローカル directory）両方式に再整理

- **真因（メタ）**: 上記の手戻りはいずれも **要求整理の不足** に起因する。真因は A → B → C の連鎖関係にある:
  - **真因 A（前提制約）**: ユーザーに Copilot CLI の install 仕組みに関するドメイン知識がなく、メイン提案の妥当性を判断・修正できなかった。**真因の本質は「ドメイン知識ギャップを検知・補完する仕組みがメイン側に無かった」こと**（ユーザーのスキルセット自体は変えられない前提制約）。ADR-0006（意思決定の継続検出）は呼ばれていたが、要求整理段階でのギャップ検知には作用しなかった
  - **真因 B（上流原因）**: メインから「要求を深堀りする質問」が不足していた。**真因の本質は「brainstorming skill 必須化ルールがガイドラインに明記されていなかった」こと**（superpowers の brainstorming skill 自体は存在するがメタ・ガイドラインで起動義務が定義されていなかったため、現状は設定通りの動作）
  - **真因 C（下流原因）**: 動作確認のために CLI 再起動（セッション跨ぎ）が必要だが、メインは「落とし穴チェック」を行わずにセッション即終了を急ごうとしてしまった。**真因の本質は「サイクル完了 = ハンドオフ作成」と誤認する構造的問題**であり、`verification-before-completion` の skill が「セッション内で確認可能な事項の洗い出し」をハンドオフ前に強制する仕組みになっていなかった
  - **対応**: 提案 #1 が B（上流）への対処、提案 #2 が C（下流）への対処、提案 #3 が A（前提制約）への補完となる対応関係

## 4. Tech Notes（古びない技術知見）

> **時点情報**: 以下は 2026-05 時点の **GitHub Copilot CLI 1.0.40** での挙動に基づく。CLI 仕様は将来変更され得るため、再利用時は最新版での挙動を確認すること。

- **Copilot CLI のプラグイン認識は marketplace 経由必須**
  - **コンテキスト**: ローカルで開発したプラグインを Copilot CLI に認識させたい時
  - **知見**: `installed-plugins/<dir>/` に直置き or junction しても認識されない。暗黙の `local` marketplace は存在しない（実証済: 前セッションで `installed-plugins/local/` junction 方式は完全に空振り）
  - **回避策・代替**: 正規手順 — `copilot plugin marketplace add <github-repo|local-path>` → `copilot plugin install <plugin>@<marketplace>`
  - **参照**: ADR-0017, `.copilot/logs/` の `Marketplace "local" not found` ログ

- **`copilot plugin install` はファイルコピー方式**
  - **コンテキスト**: プラグインのインストール後、ソースを編集した時の挙動
  - **知見**: junction ではなく実体コピー。ソース編集後は `copilot plugin update` が必要（即時反映されない）。一方で、ソースフォルダを移動・削除しても install 済み skill は動き続ける（独立性）
  - **回避策・代替**: 開発時の即時反映が欲しい場合でも junction 方式は不可能。`update` を都度実行する運用が必要
  - **参照**: `~/.copilot/installed-plugins/<marketplace>/<plugin>/` のハッシュ確認結果

- **marketplace 登録は絶対パス参照、ソース移動時は再登録必要**
  - **コンテキスト**: ローカル directory marketplace 登録後にソースフォルダを移動・削除する時
  - **知見**: install 済み skill は動くが、`copilot plugin update` は失敗する。CLI 起動時に警告が出る可能性
  - **回避策・代替**: 移動時は `copilot plugin marketplace remove <name> --force` → `copilot plugin marketplace add <新パス>` → `copilot plugin install` を再実行
  - **参照**: ADR-0017 補足セクション

- **`marketplace remove` は install 済みプラグインがあると拒否される**
  - **コンテキスト**: marketplace を別 source に切替えたい時
  - **知見**: 通常の `remove` はエラーで止まる。`--force` で強制削除可能（プラグインも uninstall される）
  - **回避策・代替**: 切替手順は force remove → add → install の順で実行

- **available_skills のセッション固定（現行 CLI の設計上の制約）**
  - **コンテキスト**: プラグインを install / update した直後に skill を使いたい時
  - **知見**: スキル一覧はセッション開始時に確定する。install / update 後は CLI 再起動（新セッション起動）まで反映されない。これは現行 CLI の設計上の制約で、将来 hot-reload 機能が追加されると陳腐化する可能性あり
  - **回避策・代替**: 検証が必要な場合はハンドオフして次セッションで確認、ただし「検証前のセッション内チェック」は本サイクルで実施漏れあり（§3 真因 C 参照）

- **marketplace 名は `marketplace.json` の `plugins[].name` で決まる**
  - **コンテキスト**: `<plugin>@<marketplace>` 表記を組み立てる時、または `marketplace add` 後に install する時
  - **知見**: install 時の `<marketplace>` 部分は `.claude-plugin/marketplace.json` 内の `plugins[].name` 値が使われる。ファイル名やディレクトリ名ではない。本リポでは `ai-driven-dev-principles` のため `install ai-driven-dev-principles@ai-driven-dev-principles` という同名表記になる
  - **回避策・代替**: marketplace の `plugins[].name` と plugin 名を一致させると `<x>@<x>` の冗長表記になる。混乱を避けるなら別名にするか、ドキュメントで明示すべき
  - **参照**: ADR-0017

- **探索型サブプロジェクトでは ADR 連鎖が plan の代替になる**
  - **コンテキスト**: 事前に plan / spec を書ききれない探索型・debug 起点のサブプロジェクトを進める時
  - **知見**: 本サイクルでは plan / spec を作成しなかったが、ADR-0015 → 0016 → 0017 の起票連鎖が事実上の進行記録として機能した。各 ADR が「次に何をするか」を規定し、追跡可能性も保たれた
  - **回避策・代替**: 探索型でも最低限「ADR-NNNN を起票したら次は何を起票するか」の見通しは Phase 0 で書くと混乱が減る

## 5. Improvement Drafts（ガイドライン・フロー改善提案）

- **提案 #1**: 中規模以上の作業着手前に **brainstorming skill を必須実行**するルール明記
  - **背景**: 今回 dev-link 方式を「思いついた解決策」として実装着手したが、要求の深堀り（「そもそもなぜプラグイン化したいのか」「private を維持したいのか」「複数 PC で使うのか」等）が不足していた。superpowers の brainstorming skill が活用されていなかった（原則3：コンテキスト管理 / 原則4：人間の関与）
  - **提案内容**:
    - `.github/copilot-instructions.md` の「メタ・ガイドライン」セクションに「中規模以上の作業／複数の解決策が想定される作業では、`start-work` Phase 0 内で brainstorming skill を必ず呼ぶ」と明記
    - `skills/start-work/SKILL.md` の Phase 2 マッピング表に「中規模以上 / 複数選択肢あり」行を追加し brainstorming を割当
    - **「中規模以上」の定義**: 既存の `feature-block-design` skill の閾値（主要機能2つ以上、または想定モジュール/コンポーネント3つ以上）を流用する。ただし「複数の解決策が想定される作業」は規模に関係なく対象とする
  - **判断**: 採用
  - **理由**: 今回の手戻りの真因 B に直接対応。原則4「人間の関与」の具体的運用ルールとして必要
  - **採用の場合**: 起票 ADR-0018（Proposed）/ 影響範囲: `.github/copilot-instructions.md`（メタ・ガイドライン）+ `skills/start-work/SKILL.md`（Phase 2 マッピング表）

- **提案 #2**: 検証ステップ（特に CLI 再起動などセッション跨ぎ）の **明示的なチェックリスト化**
  - **背景**: 私（メイン）が「次セッションで検証してください」と即座にハンドオフしようとしたが、ユーザー側に「落とし穴チェックの機会」が無かった（真因 C）
  - **提案内容**: `verification-before-completion` skill またはハンドオフ手順に「セッション跨ぎ検証が必要な場合、ハンドオフ前に『今のセッションで確認できる事項』をユーザーと洗い出すフェーズを追加」
  - **判断**: 保留
  - **理由**: 改善の必要性は認識するが、`verification-before-completion` への組み込みか `session-handoff` への組み込みか、または別スキル新設かの設計検討が必要
  - **保留の場合**: 再検討タイミング — 次回セッション跨ぎ検証が再度問題化したサイクル、または専用のメタサブプロジェクトを起こす時
  - **保留リスク**: 提案 #1（brainstorming 必須化）採用だけでは真因 C はカバーされない。本提案を保留する間、真因 C 起因の事故（セッション内検証漏れ → ハンドオフ後に発覚）が再生産される可能性がある。次サイクルで再発した場合は採用判断へ昇格させる

- **提案 #3**: ユーザーの **ドメイン知識ギャップを早期検知する質問**を pre-action-review skill に組み込む
  - **背景**: ユーザーが Copilot CLI 内部の知識を持たないため、メインの提案が技術的に妥当か判断できず、誤った方向性を止められなかった（真因 A）
  - **提案内容**: pre-action-review で「ユーザーがこの提案の妥当性を判断するために必要な前提知識を持っているか確認する」ステップを追加
  - **判断**: 保留
  - **理由**: pre-action-review skill の発動タイミングと、ドメイン知識ギャップ検知が必要なタイミングが一致しているのかが現状不明瞭。組み込み先の妥当性検討が先
  - **保留の場合**: 再検討タイミング — pre-action-review skill の発動条件を整理する別サブプロジェクト、または brainstorming（提案 #1）導入後に統合検討
  - **バックログ化**: 「pre-action-review skill の発動条件整理」を独立タスクとして §7 Handoff Forward に明記し、放置されないようにする

- **提案 #4**: ADR ステータス語彙に **`Amended` を追加**するか、または `Accepted (amended by ADR-NNNN)` 表記の運用ルールを正式化する
  - **背景**: 本サイクルで ADR-0015 を ADR-0017 で部分修正した際、既存の Status 語彙（Proposed / Accepted / Deprecated 等）に「他 ADR で修正された Accepted」を表現する語彙が無く、`Accepted (amended by ADR-0017)` という独自表記を採用した。ADR-0017 自身が「派生する将来 ADR 候補」として課題提起していた
  - **提案内容**: いずれかを正式化する:
    - 案 A: `Amended` Status を新設（旧 ADR が他 ADR で修正された状態）
    - 案 B: `Accepted (amended by ADR-NNNN)` の表記ルールを ADR テンプレ／運用ガイドに明文化
  - **判断**: 保留
  - **理由**: 設計検討が必要（案 A は Status 語彙の追加、案 B は表記ルール整備で粒度が異なる）。本サイクルでは独自表記で実害は出ていない
  - **保留の場合**: 再検討タイミング — 次回 ADR amend が発生したサイクル、または ADR 運用ガイド整備のメタサブプロジェクトを起こす時

## 6. Independent Review Notes（rubber-duck 指摘）

rubber-duck（Phase 3 独立レビュアー）から計 17 件の指摘を受領。優先度別に対応:

- **指摘 #1（high）**: §1 Done に「方式 A 動作検証成功」が抜けている
  - **メインの応答**: 採用
  - **反映先**: §2 Went Well に「方式 A の動作検証成功」項目を追加（§1 ではなく Went Well が適切と判断、ADR-0017 補足セクション更新は Handoff Forward の継続観察に追加）

- **指摘 #2（high）**: ADR-0017 派生課題「ADR ステータス語彙に Amended 追加」が拾われていない
  - **メインの応答**: 採用
  - **反映先**: §5 提案 #4 として新規追加（保留判定）

- **指摘 #3（medium）**: ADR-0016 の CONTRIBUTING.md 追記の有無が不明
  - **メインの応答**: 反論
  - **理由**: `git log` 確認の結果、`95eb4c2` 内に CONTRIBUTING.md 更新が含まれていることを検証済み。漏れではない

- **指摘 #4（medium）**: marketplace 名 = `plugins[].name` の知見が Tech Notes に無い
  - **メインの応答**: 採用
  - **反映先**: §4 Tech Notes に新規項目追加

- **指摘 #5（medium）**: handoff コミット運用の評価が無い
  - **メインの応答**: 採用
  - **反映先**: §2 Went Well に「handoff コミット運用の機能」項目を追加

- **指摘 #6（low）**: §1 Done に template.manifest 削減量・skills 削除量の定量成果が無い
  - **メインの応答**: 採用
  - **反映先**: §1 Done のADR-0016 行に定量情報追記

- **指摘 #7（low）**: ADR-0015 の 6 案比較プロセスが Went Well に出てこない
  - **メインの応答**: 部分採用
  - **反映先**: §1 Done のADR-0015 行に「6案比較の上で」を追記（Went Well への独立項目化は冗長と判断）

- **指摘 #8（high）**: 提案 #1 の影響範囲が「A または B」と曖昧
  - **メインの応答**: 採用
  - **反映先**: §5 提案 #1 を「A + B 両方」に確定し役割分担を明示

- **指摘 #9（high）**: 提案 #1 の「中規模以上」定義が不明
  - **メインの応答**: 採用
  - **反映先**: §5 提案 #1 に feature-block-design の閾値流用を明記

- **指摘 #10（medium）**: 提案 #2 保留時の真因 C 再発リスク
  - **メインの応答**: 採用
  - **反映先**: §5 提案 #2 に「保留リスク」項目追加

- **指摘 #11（medium）**: 提案 #3 を継続観察ではなくバックログ化すべき
  - **メインの応答**: 採用
  - **反映先**: §5 提案 #3 に「バックログ化」項目追加、§7 で独立タスク化

- **指摘 #12（low）**: 提案 #1 採用判断は妥当
  - **メインの応答**: 確認のみ（変更なし）

- **指摘 #13（high）**: §4 全項目に CLI バージョン注記が無い
  - **メインの応答**: 採用
  - **反映先**: §4 冒頭に「Copilot CLI 1.0.40 時点」の注記追加

- **指摘 #14（medium）**: available_skills 固定は将来 hot-reload で陳腐化する可能性
  - **メインの応答**: 採用
  - **反映先**: §4 該当項目に「現行 CLI の設計上の制約」と明記

- **指摘 #15（low）**: marketplace remove --force の挙動も今後変わり得る注記
  - **メインの応答**: 反論
  - **理由**: §4 冒頭の時点情報注記でカバーされる。個別注記は冗長

- **指摘 #16（low）**: 廃止された dev-link 知見を Tech Notes に含めない判断は正しい
  - **メインの応答**: 確認のみ（変更なし）

- **指摘 #17（high）**: 真因 B「brainstorming が呼ばれなかった」はメインの怠慢に読める
  - **メインの応答**: 採用
  - **反映先**: §3 真因 B を「ガイドライン未整備が真因」と再定義

- **指摘 #18（high）**: 真因 C「セッション即終了を急いだ」は表層的、メタ真因まで掘れていない
  - **メインの応答**: 採用
  - **反映先**: §3 真因 C を「サイクル完了 = ハンドオフ作成と誤認する構造的問題」と掘り下げ

- **指摘 #19（medium）**: 真因 A は前提制約に近い、再定義必要
  - **メインの応答**: 採用
  - **反映先**: §3 真因 A を「ドメイン知識ギャップを検知・補完する仕組みがメイン側に無かった」と再定義

- **指摘 #20（medium）**: 真因 A/B/C の連鎖関係を明示すべき
  - **メインの応答**: 採用
  - **反映先**: §3 に「真因は A → B → C の連鎖関係」と明記、提案 #1/#2/#3 との対応関係も明示

- **指摘 #21（low, 観点外）**: 「探索型サブプロジェクトでは ADR 連鎖が plan の代替になる」は Tech Notes に値する
  - **メインの応答**: 採用
  - **反映先**: §4 Tech Notes に新規項目追加

## 7. Handoff Forward（次サイクルへの申し送り）

- **着手予定**: ADR-0018（提案 #1: brainstorming skill 必須化）の実装 — 次セッションで `start-work` から開始
  - 影響範囲: `.github/copilot-instructions.md`（メタ・ガイドライン追加）+ `skills/start-work/SKILL.md`（Phase 2 マッピング表更新）
  - 「中規模以上」の定義は `feature-block-design` の閾値を流用
- **継続観察**:
  - 提案 #2（セッション跨ぎ検証チェックリスト化）— 次回類似事象発生時に再検討、再発時は採用昇格
  - 提案 #4（ADR ステータス語彙に Amended 追加）— 次回 ADR amend 発生時に再検討
  - **ADR-0017 補足セクション更新タスク**: 「方式 A は未検証」と書かれている記述を、本サイクルで動作実証済みである旨に更新する（次サイクル冒頭で実施）
- **バックログ**:
  - 提案 #3（pre-action-review への組み込み妥当性検討）— pre-action-review skill の発動条件整理サブプロジェクトとして起票候補。brainstorming（提案 #1）導入後に統合検討
- **次サブプロジェクト候補**: ADR-0018（brainstorming 必須化）が最有力
