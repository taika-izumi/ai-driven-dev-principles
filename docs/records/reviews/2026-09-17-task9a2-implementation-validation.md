# タスク9(a-2): 選択肢2の実装・検証記録

- 検証完了: 2026-09-17
- 状態: 実装・独立試験11群・独立レビューと修正後の差分再確認を完了。実機操作は未実施。
- 基点: codex/isolated-verification のc2c2656と、その後の本タスクの作業差分。
- 判断: 利用者の選択肢2の明示回答をADR-0199へ反映。提案用はauth.openai.com・chatgpt.comの全ポートを許可し、残る11ホストを全ポート拒否。再実行用は全面拒否を維持する。

## 実装した内容

- 役割別のprofile検査・固定作成argv・通信規則一覧と代表ポートの対照・許可する資格情報のサービス名の検査を整合させた。未知の追加allow・ワイルドカード・拒否漏れを受理しない。
- proposal用probeを2台の確認手順へ対応させ、起動直後の観測、ゲスト側の否定確認と資源値、認証値を出力しない一致確認、失敗時停止、失敗したrunの再開拒否を追加した。
- 共有fixtureとProposalV3専用fixtureを更新し、probeの回帰確認を既存SbxRuntimeV3群へ組み込んだ。
- 起動直後の記録は観測時点のプロセス・session・コマンド列を示す。過去全域の未起動を保証せず、実機の順序整合は最初の実機試験で主担当が照合する。

## 検証

全11群を順番に実行し、失敗した箇所の試験側修正後は当該群から再開した。前半の成功を再利用した際、製品コードが変わっていないことをハッシュで確認した。単一の一括実行が最初から最後まで成功したという記録ではなく、下表の各群の最新実行がすべて終了0である。

| 群 | 最新結果 | 秒 | 原文ログ（SDDディレクトリ内） |
|---|---|---:|---|
| RequestCopy.Tests.ps1 | 合格（終了0） | 5 | task-9a2-independent-tests-attempt2.log |
| History.Tests.ps1 | 合格（終了0） | 9 | task-9a2-independent-tests-attempt2.log |
| Execution.Tests.ps1 | 合格（終了0） | 11 | task-9a2-independent-tests-attempt2.log |
| Result.Tests.ps1 | 合格（終了0） | 15 | task-9a2-independent-tests-attempt2.log |
| RequestCopyV3.Tests.ps1 | 合格（終了0） | 30 | task-9a2-independent-tests-attempt2.log |
| ExecutionV3.Tests.ps1 | 合格（終了0） | 25 | task-9a2-independent-tests-attempt2.log |
| SbxRuntimeV3.Tests.ps1 | 合格（終了0） | 841 | task-9a2-independent-tests-continuation.log |
| ProposalV3.Tests.ps1 | 合格（終了0） | 308 | task-9a2-independent-tests-final4.log |
| ReplayV3.Tests.ps1 | 合格（終了0） | 350 | task-9a2-independent-tests-final4.log |
| ResultV3.Tests.ps1 | 合格（終了0） | 50 | task-9a2-independent-tests-final4.log |
| CliV3.Tests.ps1 | 合格（終了0） | 305 | task-9a2-independent-tests-final4.log |
使用した起動経路は、通常権限のbundled PowerShellと、試験プロセス内だけに設定したPATHである。Codexパスのリンク検査に当たる既知の環境差は、`.tmp/task9a2-test-cli/codex.cmd` を存在確認用に使って処理した。このファイルは実行されれば終了97で失敗するため、実Codexを起動して成功に見せる代替ではない。リンク拒否の検査や製品の保護条件は変更していない。

検出して修正した試験側の不備:

1. probeのケースを既存allCasesへ追加するときcontrolRootが欠け、後段のJoin-Pathが失敗した。実体のrun/controlを持つ文脈に揃えて修正した。修正後のSbxRuntimeV3は27ケース合格。
2. ProposalV3専用のprofile生成が旧deny *のままだった。新しいprofile検査が拒否したため、対象を全数列挙して当該1か所を改訂ADRへ合わせた。修正後のProposalV3は16ケース合格。

ログの作成失敗・不正入力等の診断には、異常系を確かめるため意図的に発生させたものが含まれる。合否は各群の終了コードと最終出力で判断した。焦点試験の実コマンド・RED/GREEN・作成した一時パスは `task-9a2-report.md` を参照する。

## 未完了・限界

- 実sbxの設定変更・認証登録・VM作成・モデル呼出しは行っていない。偽sbxでの成功を実機での保護・認証・通信・起動順の成立へ読み替えない。
- 独立レビューは未実施。自動承認レビューが、具体的な内部コードと宛先への明示的な送信承認がないとして、Claude Codeの起動要求を拒否した。拒否後の迂回送信・再試行はしていない。
- 送信承認の対象は `2026-09-16-task9a2-review-export-request.md`。レビューと必要な是正を終え、その後にタスク9の実機操作の個別承認へ進む。
## 独立レビュー後の更新

37ファイルの外部送信を利用者が明示承認し、ReadのみのClaude Codeでレビューを実施した。F1/F2の修正後は影響する対象試験を実行し、差分再確認で両件解消・新規指摘なし。詳細は2026-09-17-task9a2-independent-review.md。上の未実施記述は最初の検証時点の履歴であり、レビューの現在状態はこの更新を正とする。
