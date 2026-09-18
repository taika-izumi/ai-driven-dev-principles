# タスク9: モデル起動前の画像不一致検出

## 結果

利用者がモデル往復案へ「1で」と回答した後、新規1台で起動確認を開始した。通信・認証・共有/SSH・資源の確認は成立したが、`command -v codex`が終了127・出力空で失敗した。失敗時停止を実行し、同一IDのstoppedを確認。モデルへの送信は0セッション、stdinの往復確認にも未到達で、後続VMを作っていない。

調査で、固定digestの画像ラベルが`com.docker.sandboxes.flavor=shell`であることを公開レジストリのconfigから確認した。Codexキットの認証・通信設定を作れても、shell画像へCodex実行ファイルが追加されるわけではなかった。提案側にもエージェント未収録の画像を流用した主担当側の設定確認漏れであり、OAuth登録や通信制限が原因ではない。

## 実測

- 実行足場: `.tmp/m9/Invoke-Startup.ps1`。既存probeの関数だけをASTから読み込み、入口を実行せず作成/保持/観測/停止を再利用。元probeのSHA256を固定し、実行前の読込み確認はVM/モデルなしで通過した。
- runId: `ab0a2b42-cbda-443e-8346-3bd6c6d93c82`。
- VM: `iv-ab0a2b42-proposal`、ID `11b2753a-c73a-404e-8c2e-2cd5b81c85f5`。
- 原文: `.tmp/m9/b/ab0a2b42/`のprobe-state.json、calls.jsonl、obs/、cli/。起動ログは`.tmp/m9/startup.log`。
- 失敗コマンド: `sbx exec iv-ab0a2b42-proposal sh -c "command -v codex"`。2026-09-17 10:53:55 JST、終了127、stdout/stderr空。
- 停止要求10:53:57、一覧による停止確認10:54:03。全9台stopped、元の8台の名前/ID/状態は不変。`.tmp/m9/vms-after-startup-failure.json`。
- `.tmp/m9/b/ab0a2b42/obs/12-model-call.json`は存在せず、calls.jsonlにもモデル起動はない。作成した1台を承認済み5台の消費として数える。

## 画像の読取り調査

Docker公開レジストリへ匿名のpull用トークンでmanifest/configだけをGETし、内容のSHA256を照合した。トークンは保存/表示せず、ユーザーのDocker資格情報は使用していない。画像レイヤーの取得・導入・既存VM再起動は行っていない。取得プログラムは`.tmp/m9/registry-metadata.py`、抽出結果はregistry-metadata.json。

| 項目 | 使用していた画像 | 修正候補の公式Codex画像 |
|---|---|---|
| Linux amd64 manifest digest | `sha256:16a88c7321c130de9aa8410ffd0865ea22dd051ebb7f58103fbf41ec50057476` | `sha256:b387e913db629ca4370970076162d5bc06d1073059940f2f6326448c47143183` |
| flavorラベル | shell | codex |
| config digest | `sha256:dd4dd63eeb4709a7fec5e43ef4df72852cd9c27dca1115c57b089f34abd2053b` | `sha256:4fa9c42daaa4904966228dac0930c4a16f89deaa14f442f3cb0637ce2eb433b8` |
| config CMD | bash | codex |
| 作成日 | 2026-08-26 | 2026-08-26 |
| 圧縮レイヤー合計 | 537,366,041バイト | 795,079,331バイト |

Codex候補のbuild historyには`corepack npm install -g @openai/codex@latest`のビルド時実行が含まれる。ただし実行時の最新版追随は採らず、上記のmanifest digestで固定する。具体的なCodex版と起動argvは新画像での実測が必要。

導入版sbx 0.42.1の埋込みcodexキットが指定する既定画像はcodex-docker。現在の公式資料ではcodexとcodex-dockerが区別される。今回候補はDocker Engineを追加しないcodex版とし、既存のshellも非Docker版であったことと揃える。実行時は必ず完全なdocker.io/...@sha256参照を渡し、タグには追随しない。

ローカル`template ls --json`はimages=[]だった。これを「必要レイヤーが全て未保存」の証拠とはせず、ダウンロード削減量は未確定とする。registryの圧縮サイズは展開後ディスク使用量でもない。

## 次の判断

Issue-0151へ分離した。推奨は提案側を公式codex画像へ切り替え、その画像で保護条件と起動を取り直すこと。再実行側は既存のshell画像のままにする。前のshell画像での提案用2台の証拠は、新画像のverified証拠へ流用しない。新しい画像取得と台数の変更は未承認のため、追加実機操作は止めている。

## 公式資料

- [Docker Shell](https://docs.docker.com/ai/sandboxes/agents/shell/): shell画像にはエージェントが事前導入されていない。
- [Docker Codex](https://docs.docker.com/ai/sandboxes/agents/codex/): Codex向けの画像を案内。
- [Docker Templates](https://docs.docker.com/ai/sandboxes/customize/templates/): codex/shell、非Docker版と-docker版の区別。いずれも2026-09-17に取得した一次資料。
