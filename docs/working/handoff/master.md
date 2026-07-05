# Handoff: Issue-0002 対策サイクル完了・次サイクル待機

- **Branch**: master
- **Last Updated**: 2026-07-05 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: Issue-0002 対策サイクル完了（merge: d9329d8、retrospective 実施済み・Issue-0014 起票）/ 次サイクル未着手

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

直近サイクルは「Issue-0002: sync-template.ps1 の改行コード非決定性」の対策。空インデックス生成の書き出しを LF 固定（行を LF 連結 + 末尾改行 + WriteAllText）に変更し（ADR-0033, Accepted）、旧実装での再現（3ファイルが見かけの modified・CRLF 混入）と修正版でのクリーン維持（PowerShell 5.1 / 7 両方、再実行含む）を検証済み。Issue-0002 は close。feature ブランチは merge 後削除済み。skills/ は未変更のためプラグイン更新は不要。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open 7件 / closed 7件）
- 直近サイクルの ADR: ADR-0033（Accepted）
- 直近サイクルの retrospective: `docs/records/retrospectives/system/2026-07-05-sync-template-line-endings.md`（フロー課題なしのため flow/ は作成せず）
- 前サイクルの spec/plan/retrospective: `docs/current/specs/2026-07-05-record-process-norms-design.md` / `docs/working/plans/2026-07-05-record-process-norms-plan.md` / `docs/records/retrospectives/system|flow/2026-07-05-record-process-norms.md`
- 課題管理の規約: `docs/overview/folder-structure.md` §7
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0033）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] **Issue-0002 対策サイクル**: sync-template.ps1 の LF 固定書き出し（ADR-0033）。merge `d9329d8`、Issue-0002 close、赤緑検証済み（PS 5.1/7）、retrospective 実施済み（システム課題1件を Issue-0014 として起票）（2026-07-05）
- [x] **記録プロセス規範一括対策サイクル**: Issue-0009/0010/0011 を ADR-0030/0031/0032 として規範化・実装。merge `71d383c`、retrospective 実施済み（2026-07-05）
- [x] **Issue-0004 対策サイクル**: 質問ツール表示特性への対処規範（ADR-0029）。merge `18e0c85`（2026-07-05）
- [x] **振り返り課題×issue管理統合サイクル**: ADR-0028。merge `b418d5d`（2026-07-05）

## 進行中のタスク

なし（Issue-0002 対策サイクルは retrospective・handoff finalize まで完了）

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化済み（open 7件）。

**エージェント所見: 全件の優先順位付け（2026-07-05 Issue-0002 サイクル担当エージェント。採否・着手時期はユーザー判断）**

1. [ ] **Issue-0012**（flow）: 質問ツールタイムアウト時の自走基準がない — **最優先を推奨**。merge 等の不可逆な節目操作がユーザー不在時に確認なしで実行されうる構造的リスクで、実際に発生実績がある。全サイクルの安全性に関わるため、他の作業より先に規範を固める価値が高い
2. [ ] **Issue-0014**（system）: .gitattributes 未導入で改行正規化が各自の core.autocrlf 任せ — **2番手（即効の小規模対策）を推奨**。`.gitattributes` 追加 + 一度の `git add --renormalize .` で解消でき、作業は数分規模。ADR-0033 の残存リスク（別環境貢献者の CRLF コミット）を塞ぎ、改行問題を完全終息できる。唯一の設計判断は「template 配布物に .gitattributes を含めるか」（issue 参照）。Issue-0012 と同日に連続実施も現実的
3. [ ] **Issue-0013**（flow）: plan 検証手順と編集内容の整合観点 — 3番手。writing-plans 運用規範への1行追加程度で軽微だが、plan を使う次の中規模サイクルの前に済ませておくと効果が出る
4. [ ] **Issue-0005 / 0006**（flow）: 選択UIの誤操作の即確定 / 横断変更の計画網羅漏れ — 4番手。実害が散発的で、0005 は Issue-0012 の対策（確認規範の整備）と論点が隣接するため、0012 の設計時に併せて扱えるか検討してからでよい
5. [ ] **Issue-0003**（system）: conversation_log.md の分類 / **Issue-0008**（system）: 旧型式 spec 8本の維持方針 — 5番手。どちらも技術作業より「ユーザーの方針決め」が主で、エージェント側で先行準備できることが少ない。ユーザーが方針を決めた時に短時間で処理する類
6. [ ] **Theme C 問題A**「プロジェクト固有用語集（ユビキタス言語）の仕組み」: 6番手（課題ではなく作業テーマのため issues 対象外）。価値は高いが規模が大きく brainstorming からの本格サイクルが必要。上記の小粒課題を掃除してから着手する方が集中できる。推奨フロー: `start-work` → `extend-guidelines` → brainstorming
7. [ ] **ADR-0013 / 0014 / 0018 の Proposed 据え置き解消**: 最後尾。実害はないが、どこかのサイクルの Post チェックで昇格/棚卸しの判断だけ済ませると台帳が締まる

順位付けの考え方: (1) フローの安全性に関わる構造的リスクを最優先、(2) 数分で終わる即効修正は早めに掃除、(3) ユーザーの方針決めが主の課題は方針が出るまで寝かせる、(4) 大テーマは小粒を片付けてから。

## 既知のブロッカー・懸念

- AskUserQuestion の無応答タイムアウト（約60秒で自走指示）: Issue-0012 として起票済み（未対策）
- ADR-0023 の留意点（継続）: GitHub.com の Copilot コーディングエージェント（CLI 以外）がルート `CLAUDE.md` を読まない可能性
- `docs/conversation_log.md` は untracked のまま docs/ 直下に残置（Issue-0003。ユーザー判断待ち）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **最初に確認すべきファイル**: 本ファイル、`docs/working/issues/README.md`
3. **次に走らせる作業（候補）**: 「未着手のタスク」セクションの優先順位付け（1: Issue-0012 → 2: Issue-0014 → 3: Issue-0013 → …）を参考にユーザーが選択（着手はユーザー判断。必ず次サイクルではない）。抽出課題は issues に起票済み（Issue-0014、起票元: `docs/records/retrospectives/system/2026-07-05-sync-template-line-endings.md` 課題#1）
4. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行（ADR-0033 により改行のみ差分は解消済み。再発したら Issue-0002 を reopen せず新規事象として確認）
   - skills/ を編集したらプラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）まで反映されない
   - ADR-0019（決定のみ記載・遅延昇格）、ADR-0021（retrospective は課題抽出のみ）、ADR-0022（説明的な用語）、ADR-0024（選択肢＋推奨）、ADR-0028（課題の全件起票）、ADR-0029（質問の自己完結）、ADR-0030（ADR コミットは収束チェックポイント）、ADR-0031（再発は検討状況へ追記）、ADR-0032（判定条件は観測可能な事実）を守る

## 重要な意思決定の履歴

- ADR-0033: sync-template.ps1 の生成ファイルは LF 改行で書き出す（2026-07-05, Accepted）
- ADR-0030/0031/0032: 記録プロセス規範一括対策（2026-07-05, Accepted）
- ADR-0029: 質問ツールの表示特性への対処規範をモデル条件付きで追加（2026-07-05, Accepted）
- ADR-0028: 振り返り課題を issue 管理へ全件起票し、issues を system/flow フォルダに分割する（2026-07-05, Accepted）
- （ADR-0001〜0027 は `docs/records/decisions/README.md` 参照）
