# Handoff: 3スキルパイプライン（作業記録→候補抽出→スキル化）・実装（Task1〜7）待機

- **Branch**: feature/worklog-skill-pipeline（master から分岐。作業中・未マージ）
- **Last Updated**: 2026-07-17 (Asia/Tokyo)
- **Status**: paused（設計・spec・実装計画まで完成しコミット済み。実装は未着手。ツールコール異常を機にユーザー指示でセッション終了）
- **Current Phase**: writing-plans 完了（`docs/working/plans/2026-07-17-worklog-skill-pipeline.md`、Task1〜7）→ **実装着手前**。ラバーダックレビュー指摘（下記）への対処が先

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

直近サイクル（2026-07-08）は「ループエンジニアリング環境（ゴールを与えると AI が作業→確認→修正を自律反復する環境）に向けたガイドライン発展の方向性検討」。現在地分析（Layer 1 は自律ループ互換 / Layer 2・3 は対話セッション前提で非互換 / 欠落要素は DoD 機械判定様式・検証オラクル規範・権限境界・ループ制御・事後監査・実行基盤の6点）を実施し、「実証先行・現行体系は対話モード専用として無変更維持・抽出先は本リポジトリ内2プロファイル構成を第一仮説」を決定（ADR-0043）。ループ環境の構築は新規トレード戦略・バックテストプロジェクト（別リポジトリ、実行基盤 Claude Code、対話型ガイドラインと併用）で行い、本リポジトリには当面何も追加しない。

その前のサイクルは「Issue-0019: コミット済み Proposed ADR を不採用で終える経路（Rejected）が未定義」への対策（ADR-0041/0042）。`decision-log` に4終端ステータスの意味境界表・Rejected 手順・却下分岐の分割（未コミット=削除 / コミット済み=Rejected 化）・置換対象特定ステップ（一次: 変更ファイルの ADR 引用、二次: 採番時のインデックスタイトル走査。網羅は追わない）を追加し、`start-work` の Post チェックとセッション終了処理を不採用方向へ対称化、`CONTRIBUTING.md`「ADRを記録するとき」に台帳監査（トリガー: ユーザー指示 or 矛盾発見＋ユーザー承認。定期実行なし）を定義した。初回台帳監査（全40件: 実質置換・廃止0件、部分修正注記7件を 0001/0003/0005/0008/0016/0019/0024 に追加）と据え置き Proposed 3件の処遇確定（0013/0014/0018 すべて Rejected。0013 のテーマは Issue-0021 へ再起票）まで同サイクルで実施。Issue-0019 close。retrospective でフロー課題1件を Issue-0022 として起票。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open 7件 / closed 15件）
- 進行中サブプロジェクトの spec: `docs/current/specs/2026-07-17-worklog-skill-pipeline/`（00-overview ＋ 01〜04）
- 進行中サブプロジェクトの plan: `docs/working/plans/2026-07-17-worklog-skill-pipeline.md`（Task1〜7）
- 進行中サブプロジェクトの ADR: ADR-0044/0045/0046/0047（Proposed）
- 直近サイクルの ADR: ADR-0043（ループエンジニアリング方向性）
- 前サイクルの ADR: ADR-0041 / ADR-0042（Accepted）
- 前サイクルの retrospective: `docs/records/retrospectives/system/2026-07-07-adr-rejected-status-path.md` ＋ `flow/` 同名ファイル（フロー課題1件 → Issue-0022）
- 前サイクルの plan: `docs/working/plans/2026-07-07-adr-rejected-status-path.md`
- 課題管理の規約: `docs/overview/folder-structure.md` §7
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0047。Rejected 3件・部分修正注記あり。0044〜0047 は本サブプロジェクトの Proposed）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] **ループエンジニアリング方向性決定サイクル**: 現行ガイドライン全体の自律ループ適性分析（対話プロトコルとしての性格の同定、資産の4分類棚卸し、欠落6要素の特定）→ extend-guidelines / brainstorming で方向性議論 → 案A「実証先行・現行無変更・2プロファイル第一仮説」を採用（ADR-0043）。実装なし・記録のみのサイクル（2026-07-08）
- [x] **Issue-0019 対策サイクル**: ADR ステータス体系の完成（Rejected 新設・意味境界表・却下分岐分割）、Superseded の変更箇所起点特定と台帳監査の定義（ADR-0041/0042）。初回台帳監査40件（置換・廃止0件、部分修正注記7件）、Proposed 3件を Rejected 化（Rejected 経路の初適用。0013 のテーマは Issue-0021 へ再起票）。brainstorming 中のユーザーレビューで ADR を1決定=1ADR に分割（Issue-0022 の起票元）。merge `a9c7a5a`、Issue-0019 close、retrospective 実施済み（フロー課題1件 → Issue-0022。rubber-duck 指摘4件: 採用3・部分採用1）（2026-07-07）
- [x] **Issue-0018 対策サイクル**: CLAUDE.md 肥大化ガバナンス導入（ADR-0040）。監視スクリプト `check-claude-md-size.ps1`（sync-template 連動・警告分岐の実機検証済み）、CONTRIBUTING.md へ事前判定手順＋棚卸しシナリオ追加。merge `e3e6768`、Issue-0018 close、retrospective 実施済み（2026-07-06）
- [x] **Issue-0016/0017 対策サイクル**: read-back verification 規範（ADR-0038）、環境解決の先行調査ステップ（ADR-0039）。merge `d6b50c8`（2026-07-06）
- [x] **Issue-0014 対策サイクル**: `.gitattributes` による改行正規化の git 側固定（ADR-0037）。merge `cc67f73`（2026-07-05）
- [x] **Issue-0005 対策サイクル**: 選択UI誤操作対策（ADR-0036）。merge `5012033`（2026-07-05）
- [x] **Issue-0012 対策サイクル**: タイムアウト時の一律停止・待機規範（ADR-0035）。merge `a13e796`（2026-07-05）
- [x] **Issue-0013 / Issue-0002 / 記録プロセス規範一括（0009/0010/0011）対策サイクル**: ADR-0034 / ADR-0033 / ADR-0030〜0032。詳細は各 retrospective 参照（2026-07-05）

## 進行中のタスク

- [ ] **新サブプロジェクト: 作業記録→候補抽出→スキル化 の3スキルパイプライン設計**（2026-07-16。brainstorming 収束・ADR ドラフト済み）
  - 状態: **brainstorming 完了（D1〜D17 全論点収束・設計承認済み）**。ライフサイクル対策を D15、スキル3実行環境ガードを D16、Skill Creator 借用の実現方式（設計時抽出・実行時依存なし）を D17 として本セッションで確定
  - **ADR 0044〜0047 作成済み（すべて Proposed・コミット済み）**: 0044＝集約アーキ / 0045＝スキル1ログのスキーマ・ライフサイクル / 0046＝スキル3エンジン・借用・環境ガード / 0047＝start-work Post 配線。実装完了後に Accepted 昇格予定（実装を伴う決定のため。ADR-0019）。コミット済み（設計バンドル `efe2d22`、plan＋ADR-0047 `23b3018`）
  - 詳細は **`docs/working/handoff/skill-pipeline-brainstorming-state.md`（D1〜D17 の自己完結メモ）**。エントリスキーマ詳細は `docs/working/skill1-entry-schema-strawman.md`
  - 確定の骨子: スキル1新規作成・記録は節目でコンパクト追記／出口像＝スコープ3分岐（汎用→プラグイン配信・固有→プロジェクトローカルスキル・固有ルール→CLAUDE.md）／保存＝`<ホーム>/.ai-dev-worklog/` にプロジェクト分割・scope はタグ・JSONL／識別子＝フォルダ名＋`projects.json`（upsert 自己修復）／エントリ核心＝delta（friction/corrections）／ライフサイクル＝id・`processed.jsonl` 台帳（skillified/rejected/merged/deferred・新根拠で再浮上）／overlap 対応＝Issue 起票先行で統合バックログ dedup・skill3 は既存 extend-guidelines フローへの橋渡し・逸脱注記データのみで出力3は v2
  - 対話モード拡張なので ADR-0043 と矛盾しない（ループ対応の改修・2プロファイル設計はしない、が境界）
  - feature ブランチ `feature/worklog-skill-pipeline` 作成済み。`feature-block-design` で4ブロック分割（01 worklog-store / 02 skill1-record / 03 skill2-extract / 04 skill3-skillify）・**spec 作成済み**（`docs/current/specs/2026-07-17-worklog-skill-pipeline/`）
  - **実装計画作成済み**: `docs/working/plans/2026-07-17-worklog-skill-pipeline.md`（Task1: store-format / Task2: worklog-record / Task3: start-work 配線 / Task4: worklog-extract / Task5: 借用技術ref / Task6: worklog-skillify / Task7: 統合検証・プラグイン更新・ADR 昇格）
  - 追加決定: **ADR-0047**（worklog-record を start-work Post に配線・全プロジェクト伝播）。スキル名確定＝worklog-record / worklog-extract / worklog-skillify
  - **次アクション: (先に)下記レビュー指摘へ対処 →(その後)実装（executing-plans）で Task1〜7 を実行**。skills/ 編集のためプラグイン更新が Task7 に含まれる。実装完了後に ADR 0044〜0047 を Accepted 昇格

### 実装着手前に対処するラバーダックレビュー指摘（2026-07-17）

計画のラバーダックレビュー（独立サブエージェント）の結果。総合判定は「実装に進める品質（要・軽微修正）」。実装着手前/着手時に対処すること:

- **[重大・要ユーザー判断] 「採用したが未スキル化」候補の台帳空白**: skill2 で「採用」した候補は Issue 草案化して skill3 へ渡すだけで `processed.jsonl` に何も書かれない。skill3 が別セッション持ち越し・環境ガードで中止・中断だと採用済みエントリが台帳未登録のまま残り、次回 skill2 で再提示される。dedup 第2層（既存スキル重複排除）はスキルが実際に作られて初めて効くため「Issue 起票済み〜スキル作成前」の窓を捕捉できない。原因は **ADR-0045/D15 のライフサイクル状態に "adopted-pending" が無い**こと（計画は ADR に忠実）。対処案: (a) skill2 採用時に `outcome:"adopted"` で即台帳記録し skill3 完了で skillified/merged へ確定 / (b) skill2 の候補提示前に既存 Issue 草案と突合（D10 dedup を skill2 側にも配線）/ 最小策=「skill2→skill3 は原則同一実行内で完結」の一文。**→ 実装着手前に ADR-0045 の追補要否をユーザー判断**（採否が決まれば decision-log で ADR 追補 or 新 ADR）
- **[軽微] deferred 再浮上のクラスタ再同定方法が未明記**: 台帳の deferred レコードは代表 id と evidence_count のみ。「代表 id を含むクラスタ＝当該 deferred クラスタ」と skill2 doc（Task4）に明示する
- **[軽微] skill2 の Issue ルーティングと D10 dedup 合流点が Task4 本文指示に未反映**: general→本 repo backlog / project-specific→当該プロジェクト の分岐と、retrospective 課題とのバックログ dedup（唯一の合流点）を Task4 の本文セクション指示に一項目追加
- **[軽微] id 採番の言い換え差（矛盾ではない）**: store-format は「同一 date のエントリ数+1」、ADR/spec は「末尾を見て採番」。前者は改善版。改善版である旨を store-format に一言添える
- **[軽微] worklog-record 手順に初回ファイル生成・lastSeen 更新を明示**（Task2 本文）
- **[軽微] スモークテスト（Task7 Step4）のシェル前提**: `$HOME` は Git Bash で解決。実行シェルの注記を添える

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化済み（open 7件: 0003, 0006, 0008, 0015, 0020, 0021, 0022）。目安:

1. [ ] **Issue-0006**（flow）: 横断変更の計画網羅漏れ — 検証・プロセス品質系の残り1件
2. [ ] **Issue-0003**（system）: conversation_log.md の分類 / **Issue-0008**（system）: 旧型式 spec 8本の維持方針 — どちらもユーザーの方針決めが主
3. [ ] **Issue-0021**（flow）: Tech Notes の横断再利用の仕組み — 中規模テーマ（ADR-0013 の Rejected 化で再起票。着手時は brainstorming から設計し直す）
4. [ ] **Issue-0015**（flow）: シェル種別依存の構文の規範・チェックがない — 低優先
5. [ ] **Issue-0020**（flow）: コミット直前のステージング内容確認の観点がない — 低優先
6. [ ] **Issue-0022**（flow）: ADR 起票時の粒度（1決定=1ADR）確認の観点がない — 低優先（実害軽微。decision-log の手順追記で済む見込み）
7. [ ] **Theme C 問題A**「プロジェクト固有用語集（ユビキタス言語）の仕組み」: 大テーマ（課題ではなく作業テーマのため issues 対象外）。brainstorming からの本格サイクルが必要
8. [ ] **ループプロファイル抽出サイクル**（ADR-0043）: トレード戦略プロジェクトでの実証完了後に着手する大テーマ。着手時は ADR-0043 と実証の学びを入力に brainstorming からやり直す。実証が完了するまで本リポジトリでは何もしない

## 既知のブロッカー・懸念

- プラグイン更新は 2026-07-08 に実施済み（`/plugin marketplace update ai-driven-dev-principles`）。以後も skills/ を改定したら同コマンドでの更新が必要
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` は 2026-07-05 に実機検証済み。以後も構造化質問ツール使用前に環境変数の値を確認すること（ADR-0036。2026-07-07 も確認・運用済み）
- ADR-0023 の留意点（継続）: GitHub.com の Copilot コーディングエージェント（CLI 以外）がルート `CLAUDE.md` を読まない可能性
- `docs/conversation_log.md` は untracked のまま docs/ 直下に残置（Issue-0003。ユーザー判断待ち）
- **未追跡の inbox ファイル2件が残置**: `docs/inbox/2026-07-11-session-continuation-criteria.md`、`docs/inbox/flow_issue_memo.md`（後者は課題起票の未処理メモの可能性）。次セッションの `start-work` Phase 1 で inbox 検知 → `organize-inbox` 提案が走る想定。拾い漏れないこと
- **本セッション終了の契機＝ツールコール異常**: メインエージェント（Opus 4.8）が自分の番でユーザー回答を生成してしまう異常が発生（AskUserQuestion の JSON 破損とは別種。ユーザー指摘で判明）。ユーザー判断で「レビュー2件＋handoff finalize を実施してからセッション終了」。無視して続行しない方針は既存メモ [[tool-call-anomaly-stop-and-checkpoint]] と一貫。実害は本 handoff への引継ぎでカバー済み
- **worklog スキルはまだ実体が存在しない**（spec/plan のみ。skills/worklog-* は未作成）。実装は Task1 から。プラグイン更新は実装後（Task7）

## 次セッション開始時のアクション

1. **セッション開始前（推奨）**: プラグイン更新 `/plugin marketplace update ai-driven-dev-principles`（skills/ 改定の反映）
2. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
3. **最優先で再開する作業**: 3スキルパイプラインの**実装**。設計・spec・実装計画は確定・コミット済み。手順:
   - (a) **まず上記「実装着手前に対処するラバーダックレビュー指摘」に対処**。特に **[重大] 台帳の adopted-pending 空白**は ADR-0045 の追補要否をユーザーに確認（採否確定後 decision-log）。軽微5件は計画/spec/skill doc へ反映
   - (b) その後、実装計画 `docs/working/plans/2026-07-17-worklog-skill-pipeline.md` の Task1〜7 を実行する。**実行方式は2択のまま未確定**＝`subagent-driven-development`（計画冒頭の推奨）／ `executing-plans`（Inline）。ユーザーは Inline を選好する意向を示したが、ツールコール異常メッセージ内の発話のため**確定ではない**。再開時に改めて確認する
   - 設計内容は `docs/working/handoff/skill-pipeline-brainstorming-state.md`（D1〜D17）と spec `docs/current/specs/2026-07-17-worklog-skill-pipeline/` を参照
4. **最初に確認すべきファイル**: 本ファイル、実装計画、spec 一式、`docs/working/handoff/skill-pipeline-brainstorming-state.md`、`docs/working/issues/README.md`
5. **最初に実行すべき確認**: 構造化質問ツールを使う前に環境変数 `CLAUDE_CODE_DISABLE_MOUSE_CLICKS` の値が `1` であることを確認（ADR-0036）
6. **バックログ（別テーマ）**: 「未着手のタスク」を参考にユーザーが選択（着手はユーザー判断）
7. **トレード戦略プロジェクト（別リポジトリ）を開始する場合の引継ぎ事項（ADR-0043 の PoC）**:
   - プロジェクト名は **LoopForAlpha**（2026-07-08 決定）。詳細な引継ぎ書を `D:\Dev\001_Trade\LoopForAlpha\HANDOVER.md` に作成済み（背景・目的・段階的ゴール・立ち上げ手順・PoC 検証項目を自己完結で記載）。以下の要約より引継ぎ書を正とする
   - プロジェクト概要: 株などのトレード戦略を検討しバックテストする完全新規プロジェクト。現行の対話型ガイドライン（template + プラグイン）を導入した上で、自律ループ環境を実証先行で構築する
   - ゴール粒度: タスク単位（例:「戦略を実装しテスト全通過＋バックテスト完走まで修正を繰り返せ」）から始め、信頼できたら探索型（例:「シャープレシオ X 以上の戦略を探索せよ」）へ段階拡大。実行基盤は Claude Code
   - PoC 検証項目: ① 対話規範（CLAUDE.md 自動読み込み。特に ADR-0035 の停止・待機）がヘッドレスのループ実行に干渉しないか ② スキル・プラグインの可視範囲をモード単位（対話セッション / ループ実行）で制御できるか ③ 汎用化候補の学びを記録する規律をどう置くか（将来の抽出サイクルの入力になる）
   - 探索型ゴールへ拡大する際は過剰最適化（カーブフィッティング）対策の設計が必要になる点に留意
8. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る（現在 `feature/worklog-skill-pipeline` 上・未マージ）
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行
   - skills/ を編集したらプラグイン更新まで反映されない
   - **コミット・マージメッセージ等のマルチライン文字列は `git commit -F <file>` / `git merge --no-ff -F <file>` で渡す**（Bash ツール=POSIX sh では PowerShell here-string が使えない。Issue-0015）。未追跡ファイルへのパス指定コミットは不可（先に `git add`。2026-07-07 Tech Notes）
   - **構造化質問ツールの使用可否は環境で判定する**（ADR-0036）
   - **CLAUDE.md への規範追加は事前判定必須**（CONTRIBUTING.md「CLAUDE.md を更新するとき」。ADR-0040）
   - **ADR 起票時は置換対象の特定を行う**（一次: 変更ファイルの ADR 引用、二次: インデックスのタイトル走査。ADR-0042）。**コミット済み Proposed の不採用は Rejected 化**（削除は未コミットドラフトのみ。ADR-0041）
   - ADR-0019（決定のみ・遅延昇格）、ADR-0021（retrospective は課題抽出のみ）、ADR-0022（説明的な用語）、ADR-0024（選択肢＋推奨）、ADR-0028（課題の全件起票）、ADR-0029（質問の自己完結）、ADR-0030（ADR コミットは収束チェックポイント）、ADR-0031（再発・進展は検討状況へ追記）、ADR-0032（判定条件は観測可能な事実）、ADR-0034（plan 検証整合の突合）、ADR-0035（タイムアウト時は停止・待機）、ADR-0036（質問ツールは環境確認が条件）、ADR-0037（改行正規化は git 側固定）、ADR-0038（節目直前は実体の読み直しで確認）、ADR-0039（環境・ツール設定による構造的解決を先行調査）、ADR-0040（CLAUDE.md 追加は事前判定・超過時は棚卸し）、ADR-0041（Rejected 経路）、ADR-0042（置換対象特定と台帳監査）を守る

## 重要な意思決定の履歴

- ADR-0044/0045/0046/0047: 3スキルパイプライン（集約アーキ / スキル1ログのスキーマ・ライフサイクル / スキル3エンジン・借用・環境ガード / start-work Post 配線）（2026-07-16〜17, **Proposed・コミット済み**。実装完了後に Accepted 昇格予定）
- ADR-0043: ループエンジニアリング環境は実証先行で構築し、現行体系は対話モード専用として無変更維持する（2026-07-08, Accepted）
- ADR-0042: Superseded の置換対象は変更箇所起点で特定し、網羅は台帳監査を保険とする（2026-07-07, Accepted）
- ADR-0041: コミット済み Proposed ADR の不採用経路（Rejected）を定義しステータス体系を完成させる（2026-07-07, Accepted）
- ADR-0040: CLAUDE.md 肥大化ガバナンスを計測スクリプト連動と CONTRIBUTING.md 手順で導入する（2026-07-06, Accepted）
- ADR-0039: 課題対策手順に環境・ツール設定による構造的解決の先行調査ステップを追加する（2026-07-05, Accepted）
- ADR-0038: ツール適用結果はリスク比例で実体の読み直しにより独立確認する規範を追加（2026-07-05, Accepted）
- ADR-0037: .gitattributes で改行正規化を git 側に固定し、template へは配布しない（2026-07-05, Accepted）
- ADR-0036: 選択UI誤操作対策は環境設定とテキスト提示フォールバック規範の両輪とする（2026-07-05, Accepted）
- ADR-0035: 構造化質問ツールのタイムアウト時は一律で停止・待機する規範を追加（2026-07-05, Accepted）
- ADR-0033/0034: sync-template の LF 書き出し / plan 検証整合（2026-07-05, Accepted）
- ADR-0030/0031/0032: 記録プロセス規範一括対策（2026-07-05, Accepted）
- （ADR-0001〜0029 は `docs/records/decisions/README.md` 参照。0013/0014/0018 は 2026-07-07 に Rejected 化）
