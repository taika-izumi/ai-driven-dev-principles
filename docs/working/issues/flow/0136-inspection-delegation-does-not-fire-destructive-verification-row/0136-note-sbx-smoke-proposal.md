# Docker SandboxesのAIなし搬入・回収試験案

2026-09-09。導入済みsbx 0.42.1で、最初の実機試験を具体化した。ユーザーが「ログインと、この範囲の試験を進める（推奨）」へ「1で」と回答し、下記範囲のDockerログイン・固定イメージ取得・VM1台の作成と停止を承認。本試験はVM全体の隔離・Codex認証の最終検証ではない。

## 解消した点と残る前提

`sbx create shell --no-share-skills --help`と`sbx create codex --no-share-skills --help`は終了0。架空の`--verification-invalid-flag`は終了1でunknown flag。公開資料と導入版の差は「通常ヘルプに表示されないが引数は受理される」まで確認できた。出力は`.tmp/sbx-preflight-20260909/{shell,codex}-no-share-skills-help.txt`と`invalid-flag-help.txt`。マウントの実効性は起動後に確認する。

`sbx ls --json`はDocker未認証で終了1。次はDockerへのブラウザーログインが必要。OpenAI認証やAPIキーの登録は本試験では行わない。ユーザーにパスワード・トークンの転記を求めない。

## 固定する対象

- VM名: `iv-sbx-smoke-20260909-01`。ログイン後の一覧で同名が存在したら上書き・再利用せず停止する。
- テンプレート: `docker.io/docker/sandbox-templates@sha256:16a88c7321c130de9aa8410ffd0865ea22dd051ebb7f58103fbf41ec50057476`（shell、linux/amd64）。公式レジストリのshellタグを`docker buildx imagetools inspect`で照合した。イメージ自体は未取得。
- ホスト入力: 当該worktreeの`.tmp/sbx-smoke-20260909-01/source`。合成ファイル1件と独立したGit履歴だけ。
- 合成HEAD: `bd29b0fc8c1cc68886e69c98935f854afae40f37`。コミット内容はtracked.txt=`baseline`、現在内容は`working-copy`（いずれも末尾LF）。現在ファイルSHA256は`41E87C168EE4DDE956DAAC25B65CE646CF6EBA54CBC4DD80DF7A2B52F106D3F6`。
- VM内入力先: `/home/agent/workspace/source`。ホストworkspaceは共有せずcpで搬入する。
- 回収先: `.tmp/sbx-smoke-20260909-01/returned.txt`。既存なら上書きしない。
- CPU2、メモリ2GiB。VM作成と試験の待機を外側で監督し、10分を超えた場合は名指しでstopを試みて状態を照会する。停止未確認は失敗とする。
- 共有スキルなし、ポート公開なし、追加MCPなし、秘密値の受渡しなし。VM外向き通信には当該VMだけのdeny規則を作成時に指定する。ホスト側のログイン・公式イメージ取得の通信は別に発生する。

## 承認後の手順

1. `sbx login`でDockerのブラウザー認証を開始する。ブラウザーでのログインはユーザーが行う。認証完了後に`sbx ls --json`を保存して既存VMを確認する。
2. 次のargvでshell VMを作成する。未知フラグ・テンプレートエラー・認証エラーなら引数を削って再試行せず報告する。

```powershell
sbx create shell --name iv-sbx-smoke-20260909-01 --cpus 2 --memory 2g --no-share-skills --deny-network '*' --template docker.io/docker/sandbox-templates@sha256:16a88c7321c130de9aa8410ffd0865ea22dd051ebb7f58103fbf41ec50057476
```

3. `sbx ls --json`、当該VMの`sbx policy ls`、`sbx exec <VM名> cat /proc/mounts`で、状態・共有先・通信規則を確認する。ホストworkspaceや共有スキル等の予定外の共有を認めた場合は入力搬入前に停止する。秘密値を出す環境変数一覧や認証ファイルは読まない。
4. `sbx cp`で合成sourceを指定先へ搬入する。`sbx exec -w /home/agent/workspace/source <VM名> git show HEAD:tracked.txt`でbaseline、同じ場所のtracked.txtでworking-copyを確認する。Git所有者確認に阻まれたら当該合成コピーだけを対象として原因を調べ、広いホスト設定を変えない。
5. 固定の`python3 -c`でsource/returned.txtへ`roundtrip-ok\n`を書き、別の固定コマンドで終了7を返してCLIの実終了コードを確認する。Pythonが無ければ依存をその場で追加せず失敗を記録する。Codex等のモデルは呼ばない。
6. `sbx cp <VM名>:/home/agent/workspace/source/returned.txt <新規ホスト回収先>`で回収し、内容・SHA256と合成原本の保全を確認する。回収ファイルをホストで実行しない。
7. `sbx stop iv-sbx-smoke-20260909-01`後に`sbx ls --json`で停止状態を確認する。停止後にexecを呼ぶと自動起動するため、停止検証へexecを使わない。VMと取得イメージ・試験ログは残し、削除しない。

## 成功基準と含まない検証

合成履歴と作業中ファイルを区別して搬入でき、固定コマンドの結果・終了コード・出力ファイルを回収し、合成原本が変わらず、VMを停止確認できること。作成・exec・cp・stopの各段階と終了コードはホスト側へ保存する。

テスト専用の通信なしとモデル通信の両立、コピー内Gitへの強制的な変更拒否、Codexの任意操作と信頼側の実行記録の対応、別VMの継続、両主担当からの往復は後続。この試験の合格だけでv2の完了基準V1〜V7を満たしたと扱わない。

## 操作前レビュー

新規に行うのはDockerログイン、上記公式イメージ取得、ローカルVM1台の作成・固定試験・停止。Dockerの認証状態、sbx専用保存領域、指定の試験領域と当該VM限定のポリシーに影響する。イメージ・VMにディスク容量を使う。既存Docker Desktop・LoopForAlpha・他VM・実プロジェクトを変更しない。秘密値の手動入力が必要ならユーザーのブラウザーで行う。モデル利用料は発生させない。

停止で実行を止められるが、VM・イメージ・ログ・認証状態は残る。削除やログアウトは他VMにも影響する場合があるため自動で行わない。今回の作成・停止とログインは個別承認を得てから実行する。
