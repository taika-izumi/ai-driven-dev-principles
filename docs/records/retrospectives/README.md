# Retrospectives

サブプロジェクトクローズ時に `retrospective` スキルで作成された課題抽出記録の一覧。

## 運用規約（ADR-0011 / ADR-0021 / ADR-0056）

- **配置**: 課題の分類に応じて2フォルダに分割する（ADR-0021）
  - `docs/records/retrospectives/system/YYYY-MM-DD-<topic>.md` — メイン振り返り記録（対象システム固有の課題を含む）
  - `docs/records/retrospectives/flow/YYYY-MM-DD-<topic>.md` — 開発フロー/ガイドライン関連の課題（フロー課題がある場合のみ作成）
  - YYYY-MM-DD は振り返り実施日、`<topic>` はサブプロジェクト識別子。同一サイクルは両フォルダで同名ファイル
- **粒度**: 1ファイル = 1サブプロジェクト（フォルダごと）
- **スコープ**: retrospective は課題の抽出と分類までにとどめる。対策の採否・設計・ADR化は行わない（次サイクルでユーザー判断。ADR-0021）
- **編集ポリシー**: 一度書いたら原則上書き禁止。例外は typo / リンク切れ修正のみ。事象や判断の改変は禁止
- **インデックス（本ファイル）**: **行追加のみ**、過去行の編集は禁止
- **課題の起票**: 抽出した課題は retrospective 実行時に全件 `docs/working/issues/system|flow/` へ起票される（ADR-0028）。振り返りファイルの課題詳細が正であり、issue は open/closed のライフサイクル管理を担う
- `flow/` フォルダ全体が、配布先システム開発repoではガイドラインrepo（ai-driven-dev-principles）への申し送りバックログになる
- **形式（ADR-0056、2026-07-31 以降）**: 記録は「最小サイクル文脈（達成サマリ）＋課題詳細（事象/原因/影響）＋既存課題の再発・進展」で構成する。旧5観点の Went Well / Tech Notes は観点として廃止（知見は worklog パイプラインが捕捉）。rubber-duck レビューはユーザー要求時のみ（実施時に「Independent Review Notes」節を追加）。フロー課題は delta 型 / 構造観察型の振り分け規則に従う（詳細は `skills/retrospective/SKILL.md`）
- それ以前の記録（7セクション形式・非定型の簡易形式）は当時の形式のまま改変しない
- 訂正が必要な場合は次回 retrospective 内で「前回振り返りの訂正」として記述する

スナップショット規約（ADR-0008。spec / handoff 用）は適用しない。retrospective は時系列の学習素材として永続保管する。

## 一覧

| 実施日 | サブプロジェクト | 配置 | Branch | 備考 |
|--------|----------------|------|--------|------|
| 2026-05-01 | C: 振り返りフェーズ導入 | 旧フラット配置 | feature/retrospective-phase (merge: 49906e8) | 初回ドッグフーディング。採用提案2件 → ADR-0013/0014 起票 |
| 2026-05-05 | Copilot CLI プラグイン配布化 | 旧フラット配置 | feature/plugin-distribution (merge: a92dc81) | 採用提案1件 → ADR-0018 起票。ADR-0015→0017 連鎖が事実上の plan として機能 |
| 2026-07-05 | 開発プロジェクトのフォルダ構成定義 | system/ + flow/ | feature/project-folder-structure (merge: a9c2fd1) | 5分類体系・inbox 導入サイクル。フロー課題4件・システム課題2件を抽出 |
| 2026-07-05 | 振り返り課題×issue管理統合 | system/ + flow/ | feature/retrospective-issue-integration (merge: b418d5d) | ADR-0028 サイクル。フロー課題2件を抽出し Issue-0009/0010 起票（新起票フロー初回実運用） |
| 2026-07-05 | 質問ツール表示特性への対処規範（Issue-0004 対策） | system/ + flow/ | feature/question-tool-display-norm (merge: 18e0c85) | ADR-0029 サイクル。フロー課題1件を抽出し Issue-0011 起票 |
| 2026-07-05 | 記録プロセス規範の一括対策（Issue-0009/0010/0011 対策） | system/ + flow/ | feature/record-process-norms (merge: 71d383c) | ADR-0030/0031/0032 サイクル。フロー課題2件を抽出し Issue-0012/0013 起票。ADR-0031 を同サイクル内で初適用（Issue-0002 再発記録） |
| 2026-07-05 | sync-template.ps1 の LF 固定書き出し（Issue-0002 対策） | system/ のみ | feature/sync-template-line-endings (merge: d9329d8) | ADR-0033 サイクル。システム課題1件を抽出し Issue-0014 起票。フロー課題なし |
| 2026-07-05 | plan 検証整合規範の追加（Issue-0013 対策） | system/ + flow/ | feature/plan-verification-consistency-check (merge: afef02a) | ADR-0034 サイクル。フロー課題1件を抽出し Issue-0015 起票（rubber-duck 指摘で Tech Notes 止まりから起票へ）。Issue-0012 の再発を検討状況へ追記（ADR-0031） |
| 2026-07-05 | 質問ツールのタイムアウト時の停止規範（Issue-0012 対策） | system/ のみ | feature/question-tool-timeout-autonomy (merge: a13e796) | ADR-0035 サイクル。新規課題なし。Issue-0005 の実例（再発）を検討状況へ追記（ADR-0031）。フロー課題の新規抽出なし |
| 2026-07-05 | 選択UI誤操作対策（Issue-0005 対策） | system/ + flow/ | feature/selection-ui-text-choice (merge: 5012033) | ADR-0036 サイクル。環境設定＋環境ベース2分岐規範。フロー課題1件を抽出し Issue-0017 起票 |
| 2026-07-05 | .gitattributes による改行正規化（Issue-0014 対策） | system/ のみ | feature/gitattributes-eol-normalization (merge: cc67f73) | ADR-0037 サイクル。新規課題なし。Issue-0016/0017 の進展を検討状況へ追記（ADR-0031）。ADR-0036 規範の初運用と環境変数の実機検証を完了 |
| 2026-07-06 | 進め方チェック観点の規範化（Issue-0016/0017 対策） | system/ のみ | feature/process-check-norms (merge: d6b50c8) | ADR-0038/0039 サイクル。retrospective 起点の新規課題なし（設計議論で Issue-0018 をサイクル内起票）。CLAUDE.md 規模拡大の抑制方針を初適用 |
| 2026-07-06 | CLAUDE.md 肥大化ガバナンス（Issue-0018 対策） | system/ + flow/ | feature/claude-md-growth-governance (merge: e3e6768) | ADR-0040 サイクル。フロー課題1件を抽出し Issue-0020 起票。Issue-0015 の進展を検討状況へ追記（ADR-0031）。環境解決の先行調査ステップ（ADR-0039）初発動 |
| 2026-07-07 | ADR ステータス体系の完成と台帳監査（Issue-0019 対策） | system/ + flow/ | feature/adr-rejected-status-path (merge: a9c7a5a) | ADR-0041/0042 サイクル。初回台帳監査（40件: 置換・廃止0件、部分修正注記7件）、Proposed 3件を Rejected 化（0013 のテーマは Issue-0021 へ再起票）。フロー課題1件を抽出し Issue-0022 起票 |
| 2026-07-17 | 3スキルパイプライン（作業記録→候補抽出→スキル化） | system/ + flow/ | feature/worklog-skill-pipeline (merge: 7ed7b32) | ADR-0044/0045/0046/0047 サイクル。ADR-0045 に adopted 状態を追補（ラバーダック指摘対処）してから Accepted 昇格。スモークテストで中央ストア初回動作確認。フロー課題2件を抽出し Issue-0023/0024 起票 |
| 2026-07-18 | worklog パイプライン スキーマ v2 改訂 | system/ のみ | feature/worklog-v1.1 (merge: ba7e81d) | ADR-0048〜0053 サイクル。簡易形式で実施（当時未定型）。Issue-0030/0031 起票。※本行は 2026-07-31 に追記（作成時の記載漏れ） |
| 2026-07-18 | worklog 実運用堅牢化 | system/ のみ | feature/worklog-operational-hardening (merge: 50bef04) | ADR-0054/0055 サイクル。簡易形式で実施（当時未定型）。Issue-0032 起票、課題 A/C は不起票。※本行は 2026-07-31 に追記（作成時の記載漏れ） |
| 2026-07-31 | retrospective の役割再定義 | system/ + flow/ | feature/retrospective-mode-review (merge: 066b4e0) | ADR-0056 サイクル。**新形式（課題抽出記録）の初回適用＝改訂スキル自身のドッグフーディング**。フロー課題2件を起票（Issue-0037 / Issue-0038。後者は新形式の欠陥をドッグフーディングで検出）、delta 型1件は worklog 送り、Issue-0008/0032/0034 へ再発・進展を追記、Issue-0035 close |
| 2026-08-03 | Post ラッパー消化の可視化（Issue-0037 対処） | system/ + flow/ | feature/worklog-record-firing-reliability (merge: 9464574) | ADR-0057/0058 サイクル。着手時の実データ調査で起票時前提を反証し課題を再定義（Issue-0037 を書き換えて close）。フロー課題1件を起票（Issue-0039: メモリ依存の不可視性）、delta 型1件は worklog 済み、Issue-0008/0022/0038 へ再発・進展を追記。消化記録のドッグフーディングを同サイクルで開始 |
| 2026-08-04 | ADR 粒度・文章量の規範整備（Issue-0022 対処） | system/ + flow/ | feature/adr-granularity-and-size (merge: 9a3f70e) | ADR-0059/0060 サイクル。配布先 LoopForAlpha の実測で設計を根拠づけ、文章量を粒度の基準から明示的に棄却。system 固有の新規課題なし。フロー課題1件を起票（Issue-0040: CONTRIBUTING のテンプレート同期指示の陳腐化）、delta 型1件は worklog 送り（`MakeAiInstructions-2026-08-04-01`）、Issue-0008 へ再発を追記、Issue-0022 close |
| 2026-08-05 | 配布先 flow 課題の取り込みと worklog パイプラインの疎通 | system/ + flow/ | feature/flow-issue-intake-and-worklog-pipeline (merge: a0b16c9) | ADR-0061〜0069 サイクル（9本）。**配布先課題の取り込み経路を初めて規範化し、3サイクル停止していた worklog パイプラインを疎通**。118件を全数走査し Issue-0042/0043 起票、配布先20件中5件を close（規範7.3の初回適用）。system 固有の新規課題なし。フロー課題3件を起票（Issue-0044: スキル改定の同セッション検証不可 / Issue-0045: 対策方針の実行可能性未点検 / Issue-0046: サイクル規模の再見積もり不在）、delta 型2件は worklog 送り、Issue-0020/0042 へ再発・進展を追記、Issue-0032/0040/0041 close。ADR 昇格前の粒度点検で2本を分割（0068/0069 新設）|
| 2026-08-05 | Issue-0033/0034 のスキル化（subagent-dispatch / pre-finalization-review） | system/ のみ | feature/skillify-subagent-dispatch-and-pre-review (merge: da2d351) | ADR-0070〜0073 サイクル（4本）。**4サイクル滞留していた 2 課題が worklog パイプラインの出口（skillified）へ初到達**。スキル2件新設・start-work 配線・README 補完（worklog 3件の記載漏れ）。設計承認後のユーザーレビューで過剰適合の芽3点を修正（ADR-0073: 根拠・世代の記録と退役規範）、Issue-0047/0048 起票（サイクル中）。新規起票なし、delta 型1件は worklog 送り（`MakeAiInstructions-2026-08-05-07`）、Issue-0044/0020 へ進展・再発を追記 |
| 2026-08-06 | LoopForAlpha 構造観察型 flow 課題の取り込み | system/ + flow/ | feature/intake-structural-flow-issues (merge: 116f2f1) | 新規 ADR なし（ADR-0061/0062/0068 の適用のみ）。**ADR-0062 で 2 サイクル繰り延べていたクラスタ C を解消し、LoopForAlpha の flow 課題が全件処理済み（open 0 件）に**。Issue-0049〜0053 起票＋Issue-0046 追記、配布先 6 件を申し送り済み close。plan なしのアドホック実行。フロー課題1件を起票（Issue-0054: 撤退規範が一時障害を区別しない）、delta 型1件は worklog 送り（`MakeAiInstructions-2026-08-06-01`）、Issue-0044 へ進展を追記 |
| 2026-08-06 | ハンドオフ剪定規約と Status 整合（Issue-0049/0051 対処） | system/ のみ | feature/handoff-pruning-and-status (merge: 1eba4c3) | ADR-0074〜0077 サイクル（4本）。**ハンドオフに剪定の許可と基準を初めて明文化**（二段階剪定・受け皿は git 履歴のみ・Status 4 値化・外部参照の安定識別子）。session-handoff に cycle-reset 新設、retrospective Phase 3 を接続。Issue-0049/0051 close。**Issue-0044 の核心を実測**（plugin update を挟めば同セッション検証可能）。新規起票なし、delta 型2件は worklog 送り（`MakeAiInstructions-2026-08-06-02` / `-03`） |
| 2026-08-07 | 体系呼称の改名（AI駆動開発ガイドライン） | system/ + flow/ | feature/rename-to-ai-driven-dev-guideline (merge: 992a49f) | ADR-0078 サイクル（1本）。**体系の正式呼称を「メタ・ガイドライン」から「AI駆動開発ガイドライン」へ改名**し、規範文書・仕様書・プラグインメタデータの日本語 37 箇所＋英語 2 箇所を書き換え（追記型の記録は ADR-0011 に従い据え置き）。初出 3 文書へ一行定義を追加。**`subagent-dispatch` の初回実運用**（全 8 回の委譲に B 群判定行を付与）と `superpowers:subagent-driven-development` による二段レビューを実施し、レビューが実欠陥 1 件（specs L38 の半角スペース欠落）を捕捉。**Issue-0044 の残る未実測を解消**（plugin update を挟まなければ同セッションに反映されない／キャッシュ参照では判定不能）。system 課題 2 件・flow 課題 2 件を抽出、delta 型 3 件は worklog 送り（`MakeAiInstructions-2026-08-06-05` / `-08-07-01` / `-02`） |
| 2026-08-07 | ガイドライン拡張の過剰適合点検の導入 | system/ + flow/ | feature/overfitting-check-for-extensions (merge: 4388280) | ADR-0079 サイクル（1本）。**拡張が特定のシステム種別・特定の AI モデルへ過剰適合することを防ぐ点検を、拡張の全経路に初めて義務化**（4 観点・是正 4 型・記録先の固定・コミット前の執行点）。CONTRIBUTING.md へ横断節を新設し 9 シナリオへ配線、extend-guidelines / worklog-skillify へ工程を追加。**`pre-finalization-review` の初回実運用**（3 観点独立レビュー・レビュアーは別モデル）が spec の Critical 3 件・Major 8 件を検出し、spec を v2 へ全面改訂（観点 3→4 点ほか設計骨格に及ぶ）。各レビューで発見した既存の穴を Issue-0058〜0061 としてサイクル中に起票。system 課題 1 件（Issue-0064）・flow 課題 2 件（Issue-0062: レビュー推奨が成果物の安全網の有無を考慮しない / Issue-0063: plan への文言同期規約が未定義）を抽出、delta 型 1 件は worklog 送り（`MakeAiInstructions-2026-08-07-05`）、Issue-0042/0044/0056/0057 へ再発・進展を追記 |
| 2026-08-07 | 確定前レビューの提示規則の導入 | system/ + flow/ | feature/review-recommendation-by-artifact-type (merge: afed223) | ADR-0080 サイクル（1本）。Issue-0062 の対策として、**確定前レビューの提示点を「spec 確定点（3 通り）＋ plan 確定点」へ一般化し、未レビューの規範・手順文書の変更を含む成果物ではフルレビューを推奨側に置く片方向規範**を導入（ADR-0072 の骨格は維持）。判定規則の正本は `start-work` Phase 2 に置き、判定材料の記録経路を `session-handoff` の read / update / finalize へ配線（記録欠落時は安全側へ倒す）。**推奨の由来の明示と反対材料の併記を義務化**（片側だけの提示は本 ADR が塞ぐ偏りと同型のため。Decision 3-2）。設計段階で採用しかけた軽量レビュー枝は、独立レビューで根拠の崩壊が実証され撤回（直接実測ゼロの機構は規範化しない）。**5 段階のレビューを実施**（設計に 3 観点フル / 計画に 2 本 / 各タスクに spec 準拠＋品質 / 実装全体に最終レビュー）し、最終レビューが Major 4 件——うち 2 件は ADR の中核経路の空転——を検出。ADR-0067/0072/0075 へ部分修正を追記。flow 課題 2 件（Issue-0065: タスク単位レビューの射程 / Issue-0066: 過剰適合点検がゲートの脱落を見ない）を抽出、delta 型 1 件は worklog 送り（`MakeAiInstructions-2026-08-07-11`）、Issue-0042/0020 の再発と Issue-0056/0057/0044 の進展を追記 |

> 注: 2026-06-15 以前の振り返りは旧フラット配置（`docs/records/retrospectives/YYYY-MM-DD-<topic>.md`）で作成されており、移動していない。当時は「採用提案を ADR ドラフト化する」方式だったが、これは ADR-0021 で廃止された。`system/` `flow/` への2フォルダ分割と課題抽出限定スコープは、ADR-0021 以降に作成する振り返りから適用する。

## 関連

- スキル: `skills/retrospective/SKILL.md`
- テンプレート: `skills/retrospective/template.md`（メイン）/ `skills/retrospective/flow-template.md`（フロー）
- ADR-0021: retrospective を課題抽出に限定し、出力を system/flow に分割
- ADR-0056: 課題抽出記録への純化・worklog 委譲・振り分け規則（2026-07-31 以降の形式）
- ADR-0010: 振り返りフェーズ導入
- ADR-0011: 振り返り出力の保管規約
