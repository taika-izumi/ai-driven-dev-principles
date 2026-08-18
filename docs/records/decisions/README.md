# Architecture Decision Records

このプロジェクトにおける重要な意思決定の記録。

ADRの判断基準: 「迷って選んだもの」はすべてADR候補。迷わなかったもの（自明な選択）はADR不要。

| # | タイトル | ステータス | 日付 |
|---|---------|-----------|------|
| [0001](0001-adopt-layered-guidelines.md) | レイヤード方式のガイドライン構成を採用 | Accepted | 2026-04-12 |
| [0002](0002-add-contributing-and-gateway-skill.md) | コンテキスト継続性のためのCONTRIBUTING.mdとゲートウェイSkillの追加 | Accepted | 2026-04-13 |
| [0003](0003-template-folder-and-manifest-sync.md) | テンプレートフォルダとマニフェスト同期方式の採用 | Accepted | 2026-04-13 |
| [0004](0004-introduce-start-work-skill.md) | ワークフロー起点スキル（start-work）の導入 | Accepted | 2026-04-27 |
| [0005](0005-adopt-handoff-file-scheme.md) | セッション継続のためのハンドオフファイル方式の採用 | Accepted | 2026-04-27 |
| [0006](0006-continuous-adr-detection-rule.md) | 意思決定の継続検出ルールの導入 | Accepted | 2026-04-27 |
| [0007](0007-introduce-feature-block-design-skill.md) | 機能ブロック駆動の設計スキル（feature-block-design）の導入 | Accepted | 2026-05-01 |
| [0008](0008-adopt-spec-directory-split-and-snapshot-rule.md) | 仕様書のディレクトリ分割形式とスナップショット規約の採用 | Accepted | 2026-05-01 |
| [0009](0009-extend-principle-2-scope.md) | 原則2「関心の分離」の適用範囲拡張 | Accepted | 2026-05-01 |
| [0010](0010-introduce-retrospective-phase.md) | 開発サイクル末尾の振り返りフェーズ導入 | Accepted | 2026-05-01 |
| [0011](0011-retrospective-storage-policy.md) | 振り返り出力の保管規約（時系列追記型） | Accepted | 2026-05-01 |
| [0012](0012-domain-knowledge-out-of-scope-for-c.md) | ドメイン知識抽出は次サイクル課題 | Accepted | 2026-05-01 |
| [0013](0013-introduce-knowledge-distillation-skill.md) | knowledge-distillation スキル新設 | Rejected | 2026-05-01 |
| [0014](0014-parent-dir-check-before-file-create.md) | 新規ファイル作成時の親ディレクトリ先行確認 | Rejected | 2026-05-01 |
| [0015](0015-distribute-skills-as-copilot-cli-plugin.md) | スキル群を Copilot CLI プラグインとして配布（公式プラグイン化 + dev-link ハイブリッド） | Accepted | 2026-05-04 |
| [0016](0016-redesign-template-workflow-plugin-only.md) | template ワークフローの再設計（skills/ を除外し、プラグイン一本化） | Accepted | 2026-05-04 |
| [0017](0017-correct-local-marketplace-registration.md) | ローカル開発時のプラグイン登録方式を `copilot plugin marketplace add <path>` に修正 | Accepted | 2026-05-04 |
| [0018](0018-mandate-brainstorming-for-medium-or-multi-option-work.md) | 中規模以上 / 複数解決策の作業着手前に brainstorming skill 必須化 | Rejected | 2026-05-05 |
| [0019](0019-adr-authoring-discipline.md) | ADR記述規律 — 決定のみ記載・未決事項の分離・承認の遅延昇格 | Accepted | 2026-06-15 |
| [0020](0020-retire-responding-to-user-enforcement.md) | responding-to-user スキルの必須化を廃止し ask-user-enforcer プラグインを撤去 | Accepted | 2026-06-15 |
| [0021](0021-retrospective-issue-extraction-only.md) | retrospective を課題抽出に限定し、出力を system/flow に分割 | Accepted | 2026-06-15 |
| [0022](0022-naming-clarity-discipline.md) | AIの言葉遣いの明確性規範を copilot-instructions に追加 | Accepted | 2026-06-15 |
| [0023](0023-unify-layer2-into-claude-md.md) | Layer 2 指示ファイルを CLAUDE.md に一本化し Claude Code / Copilot CLI 両対応にする | Accepted | 2026-06-16 |
| [0024](0024-choice-with-recommendation-norm.md) | ユーザーへの質問・意思決定要求時に選択肢と推奨を提示する規範を追加 | Accepted | 2026-06-16 |
| [0025](0025-five-class-information-taxonomy.md) | 情報の5分類体系を導入し、ドキュメント構成を全面再配置する | Accepted | 2026-07-04 |
| [0026](0026-inbox-and-organize-inbox-skill.md) | inbox フォルダと organize-inbox スキルによる情報分類の仕組みを導入する | Accepted | 2026-07-04 |
| [0027](0027-template-seed-criteria.md) | テンプレート初期セットの基準を定義し、インデックス空生成を一般化する | Accepted | 2026-07-04 |
| [0028](0028-retrospective-issue-ticketing-integration.md) | 振り返り課題を issue 管理へ全件起票し、issues を system/flow フォルダに分割する | Accepted | 2026-07-05 |
| [0029](0029-question-tool-display-countermeasure.md) | 質問ツールの表示特性への対処規範をモデル条件付きで追加 | Superseded by ADR-0085 | 2026-07-05 |
| [0030](0030-adr-draft-commit-deferral.md) | ADR ドラフトは即時作成・コミットは論点収束チェックポイントまで遅延可能とする | Accepted | 2026-07-05 |
| [0031](0031-issue-recurrence-recording.md) | 既存 open 課題の再発・進展は issue ファイルの「検討状況」へ一次記録する | Accepted | 2026-07-05 |
| [0032](0032-agent-executability-check.md) | 規範・ADR の判定条件はエージェントが観測・実行可能な事実で書く | Accepted | 2026-07-05 |
| [0033](0033-sync-template-lf-output.md) | sync-template.ps1 の生成ファイルは LF 改行で書き出す | Accepted | 2026-07-05 |
| [0034](0034-plan-verification-edit-consistency-check.md) | 実装計画の検証ステップ期待値と編集内容の整合を確認する規範を追加 | Accepted | 2026-07-05 |
| [0035](0035-question-tool-timeout-stop-norm.md) | 構造化質問ツールのタイムアウト時は一律で停止・待機する規範を追加 | Accepted | 2026-07-05 |
| [0036](0036-selection-ui-env-setting-and-text-fallback.md) | 選択UI誤操作対策は環境側の誤操作防止設定とテキスト提示フォールバック規範の両輪とする | Superseded by ADR-0109 | 2026-07-05 |
| [0037](0037-gitattributes-eol-normalization.md) | .gitattributes で改行正規化を git 側に固定し、template へは配布しない | Accepted | 2026-07-05 |
| [0038](0038-read-back-verification-norm.md) | ツール適用結果はリスク比例で実体の読み直しにより独立確認する規範を追加 | Accepted | 2026-07-05 |
| [0039](0039-environment-solution-survey-first.md) | 課題対策手順に環境・ツール設定による構造的解決の先行調査ステップを追加する | Accepted | 2026-07-05 |
| [0040](0040-claude-md-growth-governance.md) | CLAUDE.md 肥大化ガバナンスを計測スクリプト連動と CONTRIBUTING.md 手順で導入する | Accepted | 2026-07-06 |
| [0041](0041-adr-rejected-status-and-ledger-audit.md) | コミット済み Proposed ADR の不採用経路（Rejected）を定義しステータス体系を完成させる | Accepted | 2026-07-07 |
| [0042](0042-superseded-identification-and-ledger-audit.md) | Superseded の置換対象は変更箇所起点で特定し、網羅は台帳監査を保険とする | Accepted | 2026-07-07 |
| [0043](0043-loop-engineering-poc-first-direction.md) | ループエンジニアリング環境は実証先行で構築し、現行体系は対話モード専用として無変更維持する | Accepted | 2026-07-08 |
| [0044](0044-worklog-skill-pipeline-central-aggregation.md) | 作業記録→候補抽出→スキル化の3スキルパイプラインを中央集約アーキテクチャで新設する | Accepted | 2026-07-16 |
| [0045](0045-worklog-entry-schema-and-lifecycle.md) | スキル1のログは delta 核心スキーマ・JSONL・追記専用ライフサイクルで設計する | Accepted | 2026-07-17 |
| [0046](0046-skill3-engine-borrowing-and-env-guard.md) | スキル3は writing-skills を既定エンジンとし、Skill Creator 技術は設計時抽出で借用、実行環境ガードを設ける | Accepted | 2026-07-16 |
| [0047](0047-worklog-record-wired-into-start-work-post.md) | worklog-record（スキル1）は start-work の Post ラッパーに組み込み全プロジェクトへ伝播させる | Accepted | 2026-07-17 |
| [0048](0048-worklog-entry-model-field-required.md) | worklog エントリに delta 発生元モデル ID の必須フィールド model を追加する | Accepted | 2026-07-17 |
| [0049](0049-worklog-schema-version-field.md) | worklog の log.jsonl / processed.jsonl 両方にスキーマバージョン v を必須導入する | Accepted | 2026-07-17 |
| [0050](0050-worklog-id-collision-recount-and-readback.md) | worklog の id 採番衝突は追記直前の再カウントと追記後の読み直し検証で対処する | Accepted | 2026-07-17 |
| [0051](0051-worklog-friction-array-symmetry.md) | worklog の friction を string[] 化して delta ペアの型を対称にする | Accepted | 2026-07-17 |
| [0052](0052-worklog-qualitative-material-guides-over-fields.md) | worklog の定性材料（AI の誤答側・損失規模）はフィールド追加でなく運用ガイドで扱う | Accepted | 2026-07-17 |
| [0053](0053-worklog-entry-unit-theme-based.md) | worklog の記録単位は「同一 context の delta 束」とし、節目のテーマ単位で複数記録を許す | Accepted | 2026-07-17 |
| [0054](0054-worklog-store-encoding-eol-contract.md) | 中央ストアのエンコーディング・EOL 契約と追記手段・読み側検証を定める | Accepted | 2026-07-18 |
| [0055](0055-start-work-skill-availability-ai-side-check.md) | start-work Phase -1 にスキル availability の AI 側判定規範を追加する | Accepted | 2026-07-18 |
| [0056](0056-retrospective-issue-extraction-core-worklog-delegation.md) | retrospective を課題抽出記録に純化し、Went Well / Tech Notes 観点を worklog パイプラインへ委譲する | Accepted | 2026-07-31 |
| [0057](0057-post-wrapper-consumption-visibility-and-reconciliation.md) | Post ラッパーの消化結果を handoff に残し、未入場は事後突合で回収する | Accepted | 2026-08-01 |
| [0058](0058-worklog-record-session-switch-trigger.md) | worklog-record の発火契機にセッション切り替え直前を追加する | Accepted | 2026-08-01 |
| [0059](0059-adr-granularity-by-question-not-length.md) | ADR の粒度は「後から探しに来るときの問い」で決め、文章量は基準にしない | Accepted | 2026-08-03 |
| [0060](0060-adr-granularity-check-on-append.md) | ADR 粒度の点検を決定追記の手順に組み込み、昇格前の一括点検を受け皿とする | Accepted | 2026-08-03 |
| [0061](0061-distributed-flow-issue-intake-routing.md) | 配布先の flow 課題は delta 型を worklog 経路へ委ね、構造観察型のみ手で取り込む | Accepted | 2026-08-05 |
| [0062](0062-cycle-scope-worklog-pipeline-throughput-first.md) | 今サイクルは worklog パイプラインの疎通を優先し、構造観察型の取り込みは次サイクルへ送る | Accepted | 2026-08-05 |
| [0063](0063-distributed-issue-handover-path.md) | 配布先からの申し送りを起票経路として定義し、受け皿の実在確認を close トリガーとする | Accepted | 2026-08-05 |
| [0064](0064-worklog-store-write-api-and-health-check.md) | 中央ストアの書き込みは行終端を明示できる API に限定し、健全性検査は正負の対照を同梱する | Accepted | 2026-08-05 |
| [0065](0065-skillify-requires-applicability-design-first.md) | 採用した worklog 候補は、根拠一覧をそのまま規範に写さず、適用条件の設計を挟んでからスキル化する | Accepted | 2026-08-05 |
| [0066](0066-subagent-dispatch-items-split-by-workload-cost.md) | サブエージェント委譲の定型項目は「委譲先の作業量を増やすか」で常時適用と条件発火に分ける | Accepted | 2026-08-05 |
| [0067](0067-pre-finalization-review-as-new-skill.md) | 非コード成果物の確定前レビューは新規スキルとして立て、start-work から配線する | Accepted | 2026-08-05 |
| [0068](0068-cross-repo-issue-reference-format.md) | 他リポジトリの課題は `<repo>#Issue-NNNN` で修飾して参照する | Accepted | 2026-08-05 |
| [0069](0069-general-skill-extension-target-own-repo-only.md) | 汎用スキルの拡張先は自リポジトリの `skills/` に限り、third-party プラグインのスキルは編集しない | Accepted | 2026-08-05 |
| [0070](0070-dispatch-constraints-as-norm-not-hook-injection.md) | サブエージェント委譲の常時制約は規範文で実装し、フックによる機械注入は採らない | Accepted | 2026-08-05 |
| [0071](0071-b-group-firing-check-as-mandatory-table-walk.md) | B 群の発火判定は、行数の固定された表を毎回読み下ろす手順として担保する | Accepted | 2026-08-05 |
| [0072](0072-pre-finalization-review-triggered-by-user-only.md) | 確定前レビューの発動はユーザーの指示に限り、AI は次手として提示するにとどめる | Accepted | 2026-08-05 |
| [0073](0073-dispatch-norms-carry-provenance-and-sunset-path.md) | 委譲制約の規範項目には根拠と世代を添え、実測にもとづく退役経路を持たせる | Accepted | 2026-08-05 |
| [0074](0074-handoff-pruning-recovery-via-git-history-only.md) | ハンドオフ剪定で落とした情報の受け皿は git 履歴のみとし、明示アーカイブを設けない | Accepted | 2026-08-06 |
| [0075](0075-handoff-two-stage-pruning-discipline.md) | ハンドオフの剪定は二段階で行う（セッション境界で基準付き圧縮、サイクル境界で初期状態への書き換え） | Accepted | 2026-08-06 |
| [0076](0076-handoff-status-add-ready-for-next-cycle.md) | handoff の Status に `ready-for-next-cycle` を正式追加する | Accepted | 2026-08-06 |
| [0077](0077-handoff-external-references-use-stable-identifiers.md) | handoff の外部参照は安定識別子で書く | Accepted | 2026-08-06 |
| [0078](0078-rename-meta-guidelines-to-ai-driven-dev-guidelines.md) | 体系の呼称を「メタ・ガイドライン」から「AI駆動開発ガイドライン」へ改める | Accepted | 2026-08-06 |
| [0079](0079-overfitting-check-required-for-guideline-extensions.md) | ガイドライン拡張の全経路に過剰適合点検を課し、点検結果の記録を義務化する | Accepted | 2026-08-07 |
| [0080](0080-review-presentation-scaled-by-unreviewed-normative-content.md) | 確定前レビューは spec/plan 確定点で提示し、未レビューの規範・手順文書の変更を含む成果物では推奨側に倒す | Accepted | 2026-08-07 |
| [0081](0081-distributed-artifact-adr-reference-scope.md) | 配布物から除くのは「配布先で解決できない参照」であり、決定記録番号に限らない | Accepted | 2026-08-07 |
| [0082](0082-distribute-generated-artifact-not-source.md) | 保守者向けの根拠注記はソースに残し、注記を除去した生成物を配布する | Accepted | 2026-08-07 |
| [0083](0083-provenance-notation-convention-enforced-by-generator.md) | 配布対象ソースの出所識別子は位置で規約化し、生成器が規約適合の検査を兼ねる | Accepted | 2026-08-07 |
| [0084](0084-convention-scope-exceeds-machine-check-scope.md) | 記法規約の適用範囲は機械判定の範囲より広く取り、差分は書き手が守る | Accepted | 2026-08-08 |
| [0085](0085-no-structured-question-tool-on-affected-models.md) | 事象確認済みモデルでは構造化質問ツールを使用せず、テキストの番号付き選択肢に一本化する | Superseded by ADR-0109 | 2026-08-13 |
| [0086](0086-handoff-canonical-relocation-standard.md) | handoff に溜まる情報の正本置き場を種類別対応表で定め、移設を独立手順として組み込む | Accepted | 2026-08-13 |
| [0087](0087-handoff-pruning-trigger-system.md) | handoff の剪定・移設はサイズ実測トリガーで発火させる | Accepted | 2026-08-13 |
| [0088](0088-handoff-section-volume-norms.md) | handoff の節別記載規範を定める（内容限定・字数目安・列挙外の節への既定規則・圧縮記録の残置禁止） | Accepted | 2026-08-13 |
| [0089](0089-placement-definition-vs-skill-procedure-boundary.md) | 情報の配置定義は folder-structure.md を正本とし、スキルは分類名で参照する | Accepted | 2026-08-13 |
| [0090](0090-version-bump-required-for-plugin-redistribution.md) | スキル改定の配布反映にはプラグインのバージョン更新を必須手順とする | Accepted | 2026-08-14 |
| [0091](0091-session-handoff-doc-clarity-fixes.md) | session-handoff 文書の解釈揺れ 5 点は規範を変えない明確化改定として解消する | Accepted | 2026-08-14 |
| [0092](0092-cycle-wide-consistency-check-before-adr-promotion.md) | 仕様・規範文書を編集したサイクルでは、決定の Accepted 昇格前に AI 自身によるサイクル全体整合検査を必須とする | Accepted | 2026-08-14 |
| [0093](0093-destructive-verification-dispatch-isolation-constraints.md) | 破壊的検証の委譲には、隔離の作り方の指定・絶対パスの使用・前後状態比較・委譲側の独立確認を課す | Accepted | 2026-08-15 |
| [0094](0094-artifact-bloat-addressed-as-growth-pattern.md) | 成果物の肥大化（Issue-0088）は用途別対応ではなく成長様式への対策として扱う | Accepted | 2026-08-15 |
| [0095](0095-issue-materials-lifecycle-split-colocation.md) | 長期化した Issue の関連情報は「検討中はフォルダ集約・close で性質別置き場へ移設」で配置する | Accepted | 2026-08-15 |
| [0096](0096-issue-folder-promotion-trigger-and-role-system.md) | Issue のフォルダ昇格は観測可能な条件で提案し、フォルダ内は 4 役割・番号接頭辞の固定体系とする | Accepted | 2026-08-15 |
| [0097](0097-issue-granularity-one-problem-many-questions.md) | Issue の粒度は「1 Issue ＝ 1 問題」とし、複数の問いの内包を認める | Accepted | 2026-08-15 |
| [0098](0098-norm-placement-behavior-in-skills-structure-in-docs.md) | 規範の記載先は「発火条件・手順はスキル、構造・命名・分量の定義はプロジェクト文書」で分け、境界をまたぐ複写を禁止する | Accepted | 2026-08-15 |
| [0099](0099-citation-consistency-via-existing-checkpoint-wording.md) | 引用元との突合（条件保存・主張の向き）は新工程を設けず既存検査観点の文言拡張で行い、残余リスクを受容する | Accepted | 2026-08-16 |
| [0100](0100-one-shot-guideline-audit-with-two-track-judgment.md) | ガイドライン全体棚卸し（Issue-0092）は、常時発火規範の全数台帳と二トラック判定による一回限りの監査として実施する | Accepted | 2026-08-16 |
| [0101](0101-audit-verdict-keep-integrate-hold-and-weak-brake.md) | 全数監査の判定を keep 72・統合 22・保留 44・簡素化 3・退役 0 で確定し、増設の歯止めは評価可能性の義務化（弱い形）とする | Accepted | 2026-08-16 |
| [0102](0102-codify-evaluability-mandate-in-contributing.md) | 評価可能性の義務化（弱い形）は CONTRIBUTING「全シナリオ共通」新節と発火フックの配線で規範化する | Accepted | 2026-08-16 |
| [0103](0103-single-cycle-scope-for-integration-and-simplification.md) | Issue-0093 の統合 22 行（全 13 クラスタ）と Issue-0094 の簡素化 3 行を単一サイクルで実施する | Accepted | 2026-08-17 |
| [0104](0104-integration-design-by-source-collation-with-audit-proposal-as-default.md) | 統合仕様は監査の統合先案を既定とし、正本読み合わせで重複側固有の条件を写像してから確定する | Accepted | 2026-08-17 |
| [0105](0105-integration-design-wiring-two-commons-and-simplification.md) | 統合 22 行は配線化（共通規範の新設は見送り、7 行は統合先案を覆し現状維持）で、簡素化 3 行は手順の束ね直しと起票手順の参照化で実装する | Accepted | 2026-08-17 |
| [0106](0106-two-layer-wiring-for-merge-mode-norm.md) | マージコミットを残す規範の再発防止は予防・検出の 2 層配線とローカル git 設定の併用で行い、検出した fast-forward は履歴のやり直しで是正する | Accepted | 2026-08-17 |
| [0107](0107-iterative-review-recommendation-by-revision-nature.md) | 指摘反映後の再レビューは改訂の性質で推奨を切り替え、収束は指摘の分類で判定する | Accepted | 2026-08-18 |
| [0108](0108-accepted-adr-revision-status-handling.md) | Accepted 昇格後の ADR 本文改訂は決定内容の変更有無でステータス運用を分ける | Accepted | 2026-08-18 |
| [0109](0109-retire-structured-question-tool-unconditionally.md) | 構造化質問ツールを全ツール・全モデルで廃止しテキスト選択肢に一本化、クリック操作を再有効化する | Accepted | 2026-08-18 |
