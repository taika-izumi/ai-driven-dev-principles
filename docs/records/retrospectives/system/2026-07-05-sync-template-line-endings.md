# Retrospective: Issue-0002 対策（sync-template.ps1 の LF 固定書き出し）

- **Subject**: Issue-0002 対策サイクル（sync-template.ps1 の改行コード非決定性の解消）
- **Branch**: feature/sync-template-line-endings（merge済み: d9329d8）
- **Period**: 2026-07-05 〜 2026-07-05
- **Plan**: なし（小規模修正のため plan は作成せず、systematic-debugging フローで直接実施）
- **Spec**: なし（対象はスクリプト1ファイルの修正）
- **Related ADRs**: ADR-0033
- **Facilitator**: メインエージェント (Claude Fable 5)
- **Independent Reviewer**: rubber-duck (Claude Fable 5)

## 1. Done（達成サマリ）

- 着手背景: Issue-0002 は再発2回が「検討状況」に記録済み（ADR-0031 の初適用対象）で、前サイクルの handoff でも優先1位として申し送られていた
- 根本原因のバイトレベル特定: index 側は LF のみ・スクリプト生成後のワークツリーは CRLF・clean フィルタ後の内容は一致（内容差分ゼロの「見かけの modified」）であることを git hash-object / cat-file 比較で確認
- 空インデックス生成の書き出しを LF 固定（行を LF 連結 + 末尾改行 + WriteAllText）に修正（96846a2）
- 赤緑検証: 旧実装での再現（3ファイル modified・CRLF 混入）→ 修正版でのクリーン維持を PowerShell 5.1 / 7 の両方・再実行含めて確認
- ADR-0033 起票 → 実装完了・検証後に Accepted 化（f6f8798）
- Issue-0002 close（b345e2a）、master へ merge（d9329d8）、feature ブランチ削除
- 未完了の残タスクなし

## 2. Went Well（うまくいったこと）

- **プロセス（systematic-debugging）**: バイトレベルの証拠収集（git hash-object のフィルタあり/なし比較、git cat-file での index blob 検査）により、「内容差分ゼロの見かけの modified」という真の構造を修正前に特定できた
- **プロセス（赤緑検証）**: 修正前に旧実装での再現（赤）を stash 退避で取り直してから修正版の緑を確認したため、修正と解消の因果が確実になった
- **プロセス（ADR-0030 運用）**: ADR ドラフトの即時作成とコミットの収束チェックポイントまでの遅延がスムーズに機能した

## 3. Struggled（苦労したこと・手戻り）

- **事象**: 調査初期、index blob の CR を MSYS 版 grep で数えた際に誤ったカウント（実際は LF のみなのに CR ありと表示）が出て、原因の仮説が一度混乱した
  - **原因**: MSYS/Git Bash 環境のテキスト自動変換が grep のカウントに影響した
  - **影響**: 調査時間の増加のみ。手戻りなし
  - **対処**: git hash-object（フィルタあり/なし）と index blob の比較に切り替えて事実を確定した
- **事象**: 修正後も decisions/README.md の見かけ modified が1件残った
  - **原因**: 過去の CRLF 生成時に記録された index の stat キャッシュの残骸（バイト一致にもかかわらず modified 表示が残存）
  - **影響**: 追加調査が必要になった（調査時間の増加のみ）
  - **対処**: バイト一致を確認の上 git restore を1回実行して恒久解消。以後は再実行してもクリーン維持を確認

## 4. Tech Notes（古びない技術知見）

> **スコープ（ADR-0021 / ADR-0012）**
> - **含める**: ツール挙動・環境の罠・回避策・推奨手順など、開発フローやプロジェクトに依存せず古びない汎用技術知見
> - **除外**: 開発対象システムの仕様・ドメイン知識

- **.NET の WriteAllLines は改行が実行環境依存**
  - **コンテキスト**: PowerShell/.NET でテキストファイルを生成し git 管理下に置く場合
  - **知見**: `[System.IO.File]::WriteAllLines` の改行は Environment.NewLine（Windows=CRLF, Unix=LF）になり、LF 正規化されたリポジトリと食い違う
  - **回避策・代替**: 行を `-join "`n"` で連結し末尾改行を付けて `WriteAllText` で書き出す（エンコーディングと合わせて改行も明示する）
  - **参照**: scripts/sync-template.ps1（96846a2）
- **改行のみの差分は「git status は modified、git diff は空」になりうる**
  - **コンテキスト**: core.autocrlf 等の改行変換が有効な環境で、ワークツリーとコミット内容の改行だけが異なるとき
  - **知見**: 正規化予定の警告状態では status に modified が出るのに diff は内容差分を表示しない。見かけと実体の判定を表示だけで行うと誤る
  - **回避策・代替**: `git hash-object <file>`（フィルタあり）/ `git hash-object --no-filters <file>` / `git rev-parse :<path>`（index blob）の3値比較で「実体差分か、見かけだけか」を確定する
- **MSYS/Git Bash の grep で CR を数えるのは不確か**
  - **コンテキスト**: Windows の Git Bash 上で改行コードを調査するとき
  - **知見**: MSYS 環境のテキスト自動変換により、grep による CR 検出は偽陽性を出すことがある
  - **回避策・代替**: `tr -dc '\r' | wc -c` でバイト数を直接数える（tr も同じ MSYS 環境だが、本サイクルでは hash 比較と整合する正しい値を返すことを確認済み）。確定判定には環境非依存のバイトダンプ（`od -c` / `xxd`）または git hash-object と index blob の比較を用いる
- **stat キャッシュ起因の見かけ modified の解消**
  - **コンテキスト**: ワークツリーと index blob がバイト一致しているのに git status に modified が残るとき
  - **知見**: 過去の改行不一致時に記録された stat キャッシュの残骸が原因のことがある。`git update-index --refresh` では解消しないことを本サイクルで実際に確認した（refresh 後も「needs update」表示が残存）
  - **回避策・代替**: バイト一致（hash-object == index blob）を確認した上で `git restore <file>` を1回実行すると stat が張り替わり恒久解消する（内容は変わらない）

## 5. Issues（課題抽出）

振り返りで見えた課題を抽出する。ここでは抽出と分類までにとどめ、対策の設計・採用/保留/却下・ADR 化は行わない（次サイクルの責務。ADR-0021）。

- **課題 #1**（分類: 対象システム固有）: リポジトリに .gitattributes がなく改行正規化が各自の core.autocrlf 設定任せ
  - **事象**: 今回の調査で、改行の LF 維持が各貢献者のローカル git 設定（現環境では core.autocrlf=input）に依存していることを確認した
  - **原因**: リポジトリとして改行ポリシーを強制する仕組み（.gitattributes）が未導入
  - **影響**: 別環境の貢献者が CRLF のままコミットすると Issue-0002 と同種のノイズが再発しうる（ADR-0033 ではスコープ外と明記済み）
  - **起票**: Issue-0014（`../../working/issues/system/0014-missing-gitattributes.md`）

> 開発フロー課題は今回の振り返りでは抽出なし（flow/ ファイルは作成しない）。既存 open 課題の再発も今セッションでは発生していない。

## 6. Independent Review Notes（rubber-duck 指摘）

- **指摘 #1**（優先度: low）: ADR-0033 Consequences の制約「今後の生成系書き出しも LF 明示に揃える」が Handoff Forward に未反映
  - **メインの応答**: 採用
  - **反映先**: Handoff Forward「継続観察」に追記
- **指摘 #2**（優先度: low）: Issue-0002 が再発2回記録済みだった着手背景が本文に未言及
  - **メインの応答**: 採用
  - **反映先**: Done 冒頭に着手背景を追記
- **指摘 #3**（優先度: low）: Issue-0014 に「template/ 配下（配布先プロジェクトへ配布される側）にも .gitattributes を含めるか」の観点がない
  - **メインの応答**: 採用
  - **反映先**: Issue-0014 の課題内容に観点を追記
- **指摘 #4**（優先度: medium）: Tech Notes #3 の回避策 `tr` も同じ MSYS 環境であり「grep は不確かだが tr は信頼できる」根拠が示されていない
  - **メインの応答**: 採用（tr の値が hash 比較と整合したことを明記し、確定手段としてバイトダンプ／hash 比較を併記）
  - **反映先**: Tech Notes #3 の回避策・代替
- **指摘 #5**（優先度: medium）: Tech Notes #4 の「update-index --refresh でも解消しない場合がある」に裏付け記録がない
  - **メインの応答**: 反論の上で明確化採用 — 本サイクルで refresh を実行しても解消しないことを実際に観測済みのため、断定を弱めず「実際に確認した」と出所を明記
  - **反映先**: Tech Notes #4 の知見
- **指摘 #6**（優先度: low）: Tech Notes #1 の参照がプロジェクト固有で可搬性をわずかに下げる
  - **メインの応答**: 反論（出典としての記載は許容範囲。転記時のリンク切れ留意は指摘のとおりだが本文変更は不要と判断）
  - **反映先**: 変更なし

## 7. Handoff Forward（次サイクルへの申し送り）

- **課題バックログ**: 抽出した課題は全件 issues に起票済み（Issue-0014）。着手の要否・時期はユーザー判断
- **継続観察**: template 同期時の改行のみ差分が本当に出なくなったか、次回以降の sync-template 実行で確認する（再発したら Issue-0002 の reopen ではなく新規事象として調査）。また ADR-0033 の制約として、今後 sync-template.ps1 に生成系の書き出しを追加する場合は同じ方式（LF 明示）に揃えること
- **次サブプロジェクト候補**: Issue-0012（質問ツールタイムアウト時の自走基準）が前サイクルからの優先候補。Issue-0014 は小規模（`.gitattributes` 追加 + 一度の renormalize）で早期解消可能
