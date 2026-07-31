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

ADR-0008 のスナップショット規約（spec / handoff 用）は適用しない。retrospective は時系列の学習素材として永続保管する。

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

> 注: 2026-06-15 以前の振り返りは旧フラット配置（`docs/records/retrospectives/YYYY-MM-DD-<topic>.md`）で作成されており、移動していない。当時は「採用提案を ADR ドラフト化する」方式だったが、これは ADR-0021 で廃止された。`system/` `flow/` への2フォルダ分割と課題抽出限定スコープは、ADR-0021 以降に作成する振り返りから適用する。

## 関連

- スキル: `skills/retrospective/SKILL.md`
- テンプレート: `skills/retrospective/template.md`（メイン）/ `skills/retrospective/flow-template.md`（フロー）
- ADR-0021: retrospective を課題抽出に限定し、出力を system/flow に分割
- ADR-0056: 課題抽出記録への純化・worklog 委譲・振り分け規則（2026-07-31 以降の形式）
- ADR-0010: 振り返りフェーズ導入
- ADR-0011: 振り返り出力の保管規約
