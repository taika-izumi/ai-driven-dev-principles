# タスク9: Codex主担当からの提案・候補比較・再検証の実証

## 結果

2026-09-17、承認済みのテンプレート変更案とADR-0201に基づき、Codex主担当から公開CLIを実行した。合成題材について、隔離されたCodexの提案を通信なしの別VMで比較し、主担当が妥当性を確認して合成原本へ反映し、同じテストで再検証する往復が成立した。

| 段階 | 結果 |
|---|---|
| 画像内Codexの最小起動 | codex-cli 0.149.1、gpt-5.6-sol/medium、stdin入力・指定ファイル生成・固定応答・終了0を確認 |
| 提案 | ready。テスト1ファイルと修正候補1ファイルを回収・検査。提案VM停止確認後に採用判断へ渡した |
| 修正前 | unittest 3件、3件失敗、終了1、transportVerified=true |
| 修正後 | 同じunittest 3件が成功、終了0、transportVerified=true |
| 外側の候補比較 | status=completed、replayVerdict=candidate-supported、CLI終了0、source/baselineともunchanged |
| 主担当の採用 | addの実行可能な変更がa-bからa+bへの訂正だけと全文で確認。正数・ゼロ・負数のテストも確認し、今回用の合成原本calc.pyだけへ反映 |
| recheck | 前回と同じ477バイトのテストを使用し3件成功。current-pass、CLI終了0。proposalCreated=false、model/profile=nullの設定でモデル再呼出しなし |
| 最終状態 | 今回の新規6台を含む全15台stopped。元の9台の名前・ID・状態は不変 |

callerの文字列だけを書き換えた試験ではなく、Codex主担当が`Invoke-IsolatedVerification.ps1`を候補比較とrecheckの両方で実行し、終了値・保存済み結果・実コマンド記録を照合した。Claude Code主担当からの実証はまだ行っていない。

## 固定条件と設定

提案用テンプレートはCodex収録済みの非Docker版、固定digest `sha256:b387e913db629ca4370970076162d5bc06d1073059940f2f6326448c47143183`。replayは既存のshell版`sha256:16a88c7321c130de9aa8410ffd0865ea22dd051ebb7f58103fbf41ec50057476`。モデル名はgpt-5.6-sol、reasoning medium。既存OAuthを使い、モデル通信はauth.openai.com:443とchatgpt.com:443だけを許可した。

各VM CPU2/2GiB、同時1台。全体3600秒・モデル600秒・テスト120秒等の承認済み上限を維持した。新規Codex実行は起動確認と提案生成の2セッション。1セッションは複数のモデル要求・ツール往復を含み、HTTP要求が2回という意味ではない。

新テンプレートの能力証拠は`2026-09-17-task9-codex-template-evidence.md`。同ファイルはprofileからハッシュ固定したため以後変更しない。記載のdaemon世代`09/15/2026 23:59:47`は、元のprobe-state.jsonのUTC値`2026-09-15T23:59:47.2777504Z`をPowerShellが書式化したもので、JSTの日時ではない。

- proposal profileHash: `D25BFBB4C2BCAA3BFCAFD1927610A50CF310BE5FA392AB7847FB5F6595129F38`
- proposal activationEvidenceHash: `AD396358C5D41FB2F38B04D2BD03678EA890A6CD10E4426032DDA156C4DB11CE`
- 能力証拠md SHA256: `7F243BBE9E49711D3374C95F270DFB19FB02D358C6B12BE241C7D1304A194723`
- replay profileHash: `66A6A4B01BA9456AC4472BA813681FE1D3760D00EECF4F2E352E2C73E3740DD9`

profileと証拠・標準ライブラリ一覧のハッシュを、公開のTest-VerificationRuntimeProfileでモデル往復前後に確認した。製品スクリプトの処理は変更せず、実測したprofileと証拠を追加した。既存11群の成功を再実行したと装わず、この変更では設定検査と実機の公開CLIによる統合確認を行った。

## 合成題材と採用理由

今回用の独立Git作業ツリーは`.tmp/m9/source`。基準コミットは`e9a7fadc2bac33399c5a76f4aaa279fd45d8602a`で、実プロジェクトの履歴を含めずcalc.pyだけを持つ。

- 修正前calc.py: 270バイト、SHA256 `E40D22A2B4FD4ADD9465412538146029101FFF844DC0916D051C3FDBBF904DD8`
- 修正候補/反映後calc.py: 97バイト、SHA256 `5AF29BA9264C17F9F9E6262CA4503C239AFF91724546E7016BB138DE0221FBEE`
- 固定テストtests/test_calc.py: 477バイト、SHA256 `31E03B3A6A311A84529EA4948DDA70909D0B21F53D1135E2E861B5672DBB18CD`

テストはadd(1,2)、(0,0)、(5,0)、(0,5)、(-1,-2)、(-5,3)を3つのunittestメソッドで確認する。修正前で3メソッドすべてが失敗し、修正候補の適用後とrecheckではすべて成功した。変更は次の演算と、欠陥を説明していたコメントの整理である。

```python
def add(a, b):
    return a + b
```

candidate-supportedは観測結果であり、モデルの提案を自動承認したものではない。主担当が候補とテストを読み、今回の目的に合うことを確認した後、承認済み範囲の合成原本1ファイルへ反映した。元の合成ファイルはcfg/source-before-adoption.pyへ保存し、リポジトリのfixture原本は元のSHA256のまま確認した。

## 実行IDとVM

| 役割 | VM名 | VM ID |
|---|---|---|
| 新画像の条件・起動確認 | iv-0fa7ef20-proposal | c0e1648d-0dc5-4ba4-9651-71074e5229c2 |
| 新画像の異常終了・復旧 | iv-da12b0e8-proposal | 29fd1a6e-4430-4c91-8dc9-3ac72d6b197c |
| 候補の提案 | iv-7768af9c-proposal | 4367f48f-ce38-449e-a238-02ed8c41093c |
| 候補比較before | iv-7768af9c-before | 19a0a832-6b2d-4b65-9826-139ed5c9524d |
| 候補比較after | iv-7768af9c-after | 9798a385-c170-4bf2-abbd-605f129b4c15 |
| 修正反映後recheck | iv-9c48b237-after | 43096de5-f5b3-4a69-8ae7-42f5b984440f |

候補比較runIdは`7768af9c-73f3-4e79-a1c4-c032c243c64c`、recheck runIdは`9c48b237-75d1-4dc6-872f-828e2503da3f`。候補比較の受付は2026-09-17T02:28:41.1454392Z、recheckの受付は02:34:49.3826880Z。

## 証拠の所在

- 追跡する要約データ: 同名ディレクトリ`2026-09-17-task9-codex-roundtrip/`のcandidate-result.json、recheck-result.json、adoption.json、final-state.json、artifacts.json。
- 実行設定/依頼: `.tmp/m9/cfg/`。候補比較のsettings/request/pilot-inputとrecheck用の3ファイルを区別する。
- 公開CLIのstdout/stderr: `.tmp/m9/candidate.stdout.json`、candidate.stderr.log、recheck.stdout.json、recheck.stderr.log。
- 各runの生データ: `.tmp/m9/runs/<runId>/`のcontrol、quarantine、accepted。各結果のrecordPath/Hashを主担当が実体と照合した。stdoutの結果とcontrol/result.jsonも正規化ハッシュで一致。
- 主担当の最終照合: `.tmp/m9/final-summary.json`、final-vms.json、final-daemon.json、adoption.json。新規6台、旧9台不変、全15台停止、recheckのテストハッシュ一致を確認した。

## 残作業・限界

Codex側の合成題材1往復の成立を確認した結果であり、任意プロジェクト・通常運用・Claude Code主担当の実証まで完了したものではない。Claude Code側からの同じ往復、サイクル全体整合検査、最終レビュー、統合が残る。

受容済みのclipboard文字列書込の可能性、プロセス数の厳密上限なし、daemon切断未実証という制限は維持する。稼働中の他VMの非停止を今回実証したとも扱わない。既存9台はすべて停止中のものを保全した。OAuth登録と停止VMは保持し、後片付けは別の承認点で扱う。
