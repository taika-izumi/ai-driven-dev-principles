# Retrospective: 隔離検証の共通起動処理（v3）

- **Subject**: Codexの提案と通信なし再実行による隔離検証の共通CLI（v3、synthetic-pilot）
- **Branch**: codex/isolated-verification（取り込み方式: マージコミット f8bce07）
- **Period**: 2026-09-09 〜 2026-09-18
- **Plan**: docs/working/plans/2026-09-14-isolated-verification-v3-implementation.md
- **Spec**: docs/current/specs/2026-09-09-isolated-verification/
- **Related ADRs**: ADR-0149〜0162, ADR-0192〜0201
- **Facilitator**: メインエージェント (claude-opus-5)

## 1. 達成サマリ

- 設計: 提案と採否用の再実行の分離（ADR-0157）、4責務への分割（ADR-0158）、合成題材に限定した試作条件（ADR-0160・0161）。仕様確定 5259d22。
- 実装: v3の準備・提案・再実行・照合・共通CLI・復旧操作（計画タスク1〜7、偽sbxによる独立試験11群）。最終レビュー修正 9f4ce11 まで。
- 実機検証: replay/proposal両profileの能力証拠（タスク8a・8b・9）、443番限定への訂正（352499c、Issue-0150）、Codex収録済みテンプレートへの変更（ADR-0201、Issue-0151）。
- 往復の実証: Codex主担当（539e100、2026-09-17）とClaude Code主担当（54566c8、2026-09-18）から、候補比較→採用→recheckまで。
- 仕上げ: サイクル全体整合検査（1a0c4f5）、ADR-0162・0192〜0201のAccepted昇格（405c000）、繰り延べ指摘の起票（Issue-0152〜0154、7d3c533）。

## 2. 課題（対象システム固有）

- **課題 #1**: Claude Code主担当から独立試験を回すと、v1の起動検査がPATH上のcodexのリンクで失敗する
  - **事象**: 2026-09-18、Claude Codeのセッションから `Run-IndependentTests.ps1` を実行すると、最初の RequestCopy 群が `reparse point rejected: C:\Users\d12an\AppData\Local\Programs\OpenAI\Codex\bin` で失敗した。リンクを含まない実体パス（`.codex/packages/standalone/releases/0.153.4-.../bin`）をPATHの先頭に足すと11群とも合格した。
  - **原因**: v1の試験はPATH上の `codex` 実行ファイルを前提にし、製品の起動検査はリンク（再解析ポイント）を祖先に持つパスを拒否する。このPCのCodexは standalone 方式で、PATH上の `bin` がジャンクションになっている。9/16の実行はCodexセッション（別のPATH）からだった。
  - **影響**: 共通CLIは両主担当から使う前提だが、独立試験は主担当の環境によって失敗しうる。READMEの前提（「codexがPATHにあること」）だけでは再現できない。
  - **起票**: Issue-0155（`../../../working/issues/system/0155-independent-tests-fail-when-path-codex-is-a-junction.md`）
- **課題 #2**: SbxRuntimeV3 群の所要時間が約11分から約77分に延びた
  - **事象**: 2026-09-18 の11群の実行で SbxRuntimeV3 が4593秒かかった（READMEの記載は約11分、2026-09-16実測）。他の群は同程度か数倍（ProposalV3 320秒、ReplayV3 360秒）。
  - **原因**: 未調査。実行したセッション（Claude CodeのPowerShellツール経由）の違い、偽sbxの1呼び出しあたりの起動時間、ホストの負荷などが候補。
  - **影響**: 独立試験1回が約1時間40分になり、修正ごとの再実行の費用が増える。統合後の再実行を省略する判断にもつながった。
  - **起票**: Issue-0156（`../../../working/issues/system/0156-sbxruntimev3-suite-runtime-grew-sevenfold.md`）
- **課題 #3**: 試作で作った停止VM・全体保存のOAuth・VMごとの通信規則の後片付けが未実施
  - **事象**: 統合時点で、停止中のVM19台、`sbx secret` に全体保存したOpenAIのOAuth、VMごとの通信規則が残っている。
  - **原因**: ADR-0199は後片付けを「本サイクルの終了時に扱う」とし、VMの削除・秘密の削除は利用者の個別承認を要するため、統合までに実施しなかった。
  - **影響**: OAuthは同じデーモン上の全サンドボックスで使える状態のまま残る。VMと規則は証跡として有用な一方、ディスクを占め、次の試験で一覧の確認対象が増える。
  - **起票**: Issue-0157（`../../../working/issues/system/0157-pilot-vms-oauth-and-policies-not-cleaned-up.md`）

> 開発フロー課題の起票はなし。worklog送りとしたdelta型候補2件（起票なし。振り分け規則による）: masterでのstart-workがworktree側の新しいhandoffを読まなかった件（記録済み `MakeAiInstructions-2026-09-15-03`）、繰り延べ指摘の起票件数の推奨を利用者の問いで訂正した件（Phase 3で記録）。
>
> ADR-0153〜0156がProposedのまま残っている件は、課題ではなくセッション終了処理での状態判定の対象とした。

## 3. 既存課題の再発・進展

- Issue-0136: 専用Issueを持たない隔離検証worktreeの再開経路として開いたままにしていたが、f8bce07でmasterへ統合されたため、その役目を終えた旨を「検討状況」へ追記した。クローズの判断は利用者に委ねる。
