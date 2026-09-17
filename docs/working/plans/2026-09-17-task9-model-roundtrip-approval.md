# タスク9: Codex主担当からの最小モデル往復の操作案

- 実施結果: 2026-09-17、新規1台ab0a2b42でCodex未収録を検出して停止。モデル0セッション・全9台stopped。旧画像で継続せず、2026-09-17-task9-codex-template-amendment.mdで変更を提案中。

- 状態: 2026-09-17、利用者が本案へ「1で」と回答し個別承認済み。gpt-5.6-sol/medium、限定したOpenAI宛送信、Codex2セッション、新規最大5VM、合成calc.pyへの候補反映とrecheckを含む。同じ承認を再質問しない。
- 基点: 6528786。443番限定の修正352499c、11群と対象試験、独立レビュー、新規2台の実機試験は完了済み。
- 目的: 隔離VM内のCodexが作ったテストと修正候補を、別の通信なしVMで検証し、主担当が合成題材へ修正を反映して再検証できることを、公開CLIから実証する。

## モデルと送信内容

提案するモデルは `gpt-5.6-sol`、reasoning effortはmedium。このアカウントのホスト側レビューで同モデルを実行できた実績を使い、初回試験で変える要素を減らす。画像内CLI/OAuth経路での利用可能性は未確認なので、最初の起動確認で実測する。公式モデル資料はmediumをサポートするとしているが、API資料だけでこのOAuth経路の利用可否を保証しない。

利用者が登録済みのOAuthを使用する。APIキーの追加投入は求めない。Codex/ChatGPTの利用枠を消費する。1セッション内のツール利用は複数のモデル応答を伴うため、「Codex実行2セッション」はHTTP要求2回や固定トークン数を意味しない。

送信先はOpenAI。既定キットの認証更新先auth.openai.com:443とモデル接続先chatgpt.com:443の2件だけを許可し、他11ホストは拒否する。今回Anthropicへは送信しない。

送信可能な内容は以下に限定する。

1. 起動確認の短い指示文（startup-prompt.txt）、Codexが自動で付ける実行環境情報、指定マーカーを作るためのツール入出力。
2. 合成題材calc.py（270バイト、SHA256 `E40D22A2B4FD4ADD9465412538146029101FFF844DC0916D051C3FDBBF904DD8`）、それだけを登録した合成Git履歴1コミット、request.jsonの目的/合格条件とProposal.psm1が付加する固定の書式/禁止事項/残り時間。
3. 上記の調査・提案の過程で生成するテスト・修正候補・ツール出力。ファイルは最大100件、各1MiB、合計8MiB、回収と実行出力は各16MiBの上限を維持する。

本リポジトリ全体・会話履歴・他プロジェクト・ホスト認証ファイル・秘密値は搬入しない。VMへホスト作業ツリーやスキルを共有しない。ホスト側の今回用原本も、固定題材から作る独立したGit作業ツリーだけである。

## 新規VMの内訳と上限

新規VMは最大5台、同時に1台だけ。各CPU2・メモリ2GiB。既存8台は停止のまま保全し、exec/cp/run/削除を発行しない。新規VMも終了後は停止して残す。VM名はそれぞれ新しいrunIdの `iv-<先頭8桁>-proposal|before|after` とし、既存名と衝突すれば作成しない。

| 段階 | 新規VM | Codex実行 | 内容 |
|---|---:|---:|---|
| 起動条件の確認 | 1 | 1セッション | 画像内の実行ファイル・版・ヘルプを確認し、固定stdinからマーカーファイルと最終応答を得る。実効条件確認後、外側停止 |
| 共通CLIでの候補比較 | 3 | 1セッション | proposalで提案、before/afterの通信なしVMで同じテストを実行し、candidate-supportedを確認 |
| 主担当による反映とrecheck | 1 | 0 | 採用候補を今回の合成原本calc.pyだけへ反映し、同じテストを通信なしVMで再実行、current-passを確認 |

各段階の全体上限3600秒、Codexの実行は各600秒、各テストは120秒、照会/stopは60秒、作成/搬入は240秒、停止猶予は1台30秒。合計所要は15〜30分程度の概算。上限は短いモデルの返信を保証せず、失敗/無応答なら上限まで待つ場合がある（Issue-0148）。再試行や6台目の作成をこの案に含めない。

## 起動条件の確認

仕様02は、対象画像でstdin・終了・出力を実証したstartupArgvと実行ファイル絶対パスを要求する。ホストCLIのヘルプだけでverifiedにはしない。

最初の新規VMは既存の固定create argv（codex、CPU2、2g、no-share-skills、11件deny、固定digest）で作る。作成直後のagent/session、実効規則・認証・共有・資源を確認し、保持execを張る。

VM内で実行する追加の読取りは `command -v codex`、そのパスの`readlink -f`とSHA256、`codex --version`、`codex --help`、`codex exec --help`。設定全文や環境変数全体は出力しない。必要な書込み先は `/home/agent/workspace/source` と `/home/agent/workspace/proposal`。既存のVM内固定作業領域だけを使う。

候補argv（先頭は実測した絶対パスへ置換する）:

```json
["<実測したcodexの絶対パス>","--ask-for-approval","never","exec","--json","--sandbox","workspace-write","--cd","/home/agent/workspace","--skip-git-repo-check","--model","gpt-5.6-sol","-c","model_reasoning_effort=\"medium\"","-"]
```

VM内生成済みの認証provider設定を使うため、ignore-user-configは付けない。CLI側の作業領域はVM内のworkspaceに限定し、sandbox bypassは使わない。ヘルプで上記引数を確認できない、モデルが利用できない、認証や通信範囲が成立しない場合は停止して報告する。CLI更新・別モデル・別接続先へ黙って変更しない。

startup-prompt.txtは、指定したマーカー1件を作り、固定の最終応答を返す短文。終了0、JSONLの最終応答、マーカー内容を外側から確認する。成功したargv/版/絶対パスを記録してから、既存2台の証拠と合わせてproposal profileを生成し、公開のprofile検査に通す。未取得の値を仮のverifiedで埋めない。

## 共通CLIでの往復

request.json、settings.json、合成source、固定入力manifestを `.tmp/m9/` に準備する。承認前のpilot-input案は承認済みと見なさず、承認回答と資料版を記録してから実行する。

準備した実体（2026-09-17）:

- `.tmp/m9/source/calc.py`。独立GitのHEADは`e9a7fadc2bac33399c5a76f4aaa279fd45d8602a`で、登録ファイルはcalc.pyだけ。
- `.tmp/m9/cfg/request.json`、settings.json、startup-prompt.txt、startup-candidate.json、proposal-prompt-preview.txt。起動候補はconfirmed=falseで保存し、実行設定へ未登録。
- source-manifest.jsonの正規化SHA256は`23CA3C6F39068A672C76665CADE97D1383A6C1C18062A2883DA61B49A7E03234`。pilot-input.proposed.jsonは承認未取得と明記した案で、実行設定が指すpilot-input.jsonはまだ作らない。
- request/settings/pilot-input案は対応する既存スキーマで検査済み。startupArgv・モデル利用・往復成功の実測を、このローカル検査で代替していない。

1. 公開CLI `Invoke-IsolatedVerification.ps1 -RequestPath ... -SettingsPath ...` をCodex主担当が実行。caller文字列の変更だけを主担当の実証にしない。
2. proposalがready、beforeは非0、afterは0、transportVerified・停止・入力不変が成立し、結果がcandidate-supportedになることを確認。モデル出力の自己申告だけでは判定しない。
3. 主担当が生成したテストの意味と候補を読み、加算の修正として妥当なら合成sourceのcalc.pyだけへ採用する。実プロジェクトには適用しない。
4. 前回resultと選択したテストのパス/ハッシュを固定したrecheck依頼、変更後sourceの固定入力記録を作り、公開CLIで再実行。モデルを再呼出しせずcurrent-passと停止を確認する。
5. 原文・最終結果・新規5台までの名前/ID/停止と、既存8台の不変を保存する。

Claude Code主担当からの同じ往復はTask9の残件として維持する。今回はCodex側を先に成立させる操作案であり、Claude側の実証やAnthropic送信を完了扱いにはしない。

## 参照

- 正本: `docs/current/specs/2026-09-09-isolated-verification/02-isolated-execution.md`、実装計画Task9、ADR-0158/0199。
- [OpenAI公式: GPT-5.6 Sol](https://developers.openai.com/api/docs/models/gpt-5.6-sol)（2026-09-17取得、モデル名とmedium対応）。
- [OpenAI公式: 非対話実行](https://learn.chatgpt.com/docs/non-interactive-mode)（同日取得、stdin、JSONL、workspace-write。画像内の対応版の実測を代替しない）。
- 操作承認を必要とする理由: ADR-0158は「モデル認証・利用費・送信範囲」を個別相談とし、実装計画Task9は実モデル往復のモデル・送信範囲・VM数・時間を個別承認の項目にしている。これまでの2台試験の承認はモデル実行を含まなかった。
