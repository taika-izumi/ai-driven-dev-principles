# タスク9: Claude Code主担当からの提案・候補比較・再検証の実証

## 結果

2026-09-18、承認済みの操作案（`docs/working/plans/2026-09-18-task9-claude-code-roundtrip.md`）に基づき、Claude Code（claude-opus-5）が主担当として公開CLI `scripts/verification/Invoke-IsolatedVerification.ps1` を自身のツールから実行した。VM内の提案担当はCodexのまま。合成題材について、候補比較 → 主担当の確認と合成原本への採用 → 同一テストのrecheck の往復が成立した。2026-09-17のCodex主担当の実証（`2026-09-17-task9-codex-roundtrip.md`）と合わせ、両主担当からの往復が揃った。

| 段階 | 結果 |
|---|---|
| 開始前 | daemon running（PID 25888、起動世代 2026-09-16T08:59:47+09:00、sbx v0.42.1）。既存15台すべて stopped。proposal/replay profile を `Test-VerificationRuntimeProfile` で検査し、profileHash は前回と一致 |
| 提案 | ready。Codex 1セッション（thread.started 1・turn.completed 1、終了0）。テスト1ファイルと修正候補1ファイルを回収。提案VMは停止確認済み |
| 修正前 | unittest 3件すべて失敗、終了1、transportVerified=true |
| 修正後 | 同じ3件が成功、終了0、transportVerified=true |
| 外側の候補比較 | status=completed、replayVerdict=candidate-supported、CLI終了0、source/baseline とも unchanged |
| 主担当の採用 | Claude Code が候補とテストの全文を読み、実行可能な変更が add の `a - b` → `a + b` だけ（他は欠陥説明コメントの削除）であることを確認。合成原本の calc.py だけへ反映（コミットはしない） |
| recheck | 前回の477バイトのテストで3件成功、current-pass、CLI終了0。proposalCreated=false、model/proposalProfile=null でモデルを再度呼び出していない |
| 最終状態 | 今回新たに作成した4台を含め、全19台が stopped。前回までの15台は名前・状態とも不変。daemon は同じ起動世代のまま |

`caller` の値を書き換えただけの試験ではない。Claude Code のセッションが PowerShell ツールから CLI を候補比較と recheck の両方で起動し、終了値・stdout の結果・`control/result.json`（正規化hashで一致）・replay 記録（ファイルhashが結果の recordHash と一致）・VM一覧を照合した。

## 固定条件

前回と同じ条件を使った。提案用テンプレートは codex 版 `sha256:b387e913...`、replay 用は shell 版 `sha256:16a88c...`。モデルは gpt-5.6-sol/medium。既存の OAuth を使い、通信許可は auth.openai.com:443 と chatgpt.com:443 だけ。pwshPath・limits（全体3600秒・モデル600秒・テスト120秒・停止猶予30秒・CPU2/2GiB・同時1台・出力上限）も前回と同一。

- proposal profileHash: `D25BFBB4C2BCAA3BFCAFD1927610A50CF310BE5FA392AB7847FB5F6595129F38`
- replay profileHash: `66A6A4B01BA9456AC4472BA813681FE1D3760D00EECF4F2E352E2C73E3740DD9`

## 合成題材と採用理由

独立したGit作業ツリーを `.tmp/c9/source` に新しく作成した（Issue-0146 のパス長対策として短いパス）。fixture `scripts/verification/tests/fixtures/pilot-source/source/calc.py` だけを基準コミット `86b56f3e47d92991cf1710e8cdcbfca7ccd9c1fa` に置いた。前回の `.tmp/m9` とfixtureは変更していない。

- 修正前 calc.py: 270バイト、SHA256 `E40D22A2B4FD4ADD9465412538146029101FFF844DC0916D051C3FDBBF904DD8`。source manifest hash `B89B7CAC...9396`
- 修正候補/反映後 calc.py: 97バイト、SHA256 `5AF29BA9264C17F9F9E6262CA4503C239AFF91724546E7016BB138DE0221FBEE`。反映後の manifest hash `DDDF9022...D14D`
- テスト tests/test_calc.py: 477バイト、SHA256 `31E03B3A6A311A84529EA4948DDA70909D0B21F53D1135E2E861B5672DBB18CD`

生成されたテストと修正候補は、前回のCodex主担当の実証とバイト単位で同じだった（SHA256が一致）。依頼文・題材・モデル設定が同一なので、同じ出力に収束したと考えられる。ただし、キャッシュの流用ではなく新しいモデルセッションの結果であることは、上記のセッションイベントで確認した。

candidate-supported は観測結果であり、モデルの提案を自動で承認したものではない。採用前の元ファイルは `.tmp/c9/cfg/source-before-adoption.py` に保存した。

## 実行IDとVM

| 役割 | VM名 | VM ID |
|---|---|---|
| 候補の提案 | iv-e43e9aed-proposal | 84007ba7-56bc-4911-b5f8-e4d4b990e64b |
| 候補比較 before | iv-e43e9aed-before | c23ae0ad-2397-462e-a8a0-09fcb5bb9b09 |
| 候補比較 after | iv-e43e9aed-after | 44b1a258-52bc-4af2-9048-4407e851cad0 |
| 反映後の recheck | iv-26f90cbd-after | f073fe05-c841-4f9f-9df6-8159ee5a72b4 |

候補比較の runId は `e43e9aed-4926-4b3b-8022-ed0e7c7a09d7`（受付 2026-09-18T04:27:22.1834446Z）、recheck の runId は `26f90cbd-dcfd-4bfd-b1a7-906c1ab6809d`（受付 04:32:08.4066835Z）。

## 証拠の所在

- 追跡する要約データ: 同名ディレクトリ `2026-09-18-task9-claude-code-roundtrip/` の candidate-result.json、recheck-result.json、adoption.json、artifacts.json、final-state.json。
- 実行設定と依頼: `.tmp/c9/cfg/`（候補比較の request/settings/pilot-input と、recheck 用の3ファイル）。
- 公開CLIの出力: `.tmp/c9/candidate.stdout.json`・candidate.stderr.log・candidate.exit.txt、recheck の同名3ファイル。
- 各 run の生データ: `.tmp/c9/runs/<runId>/`（control、quarantine、accepted）。
- VM一覧と daemon の前後: `.tmp/c9/vms-before-candidate.txt`・vms-after-candidate.txt・vms-final.txt・daemon-before.txt・daemon-final.txt。

## 残作業・限界

合成題材1件の往復が両主担当で成立したことを確認した結果である。任意のプロジェクトや通常運用に使えることは確認していない。残りは、サイクル全体整合検査、最終レビュー、ADR-0162・0192〜0201 の状態判定、master への統合、振り返り。

受け入れ済みの制限（clipboard に文字列が書き込まれうる、プロセス数の厳密な上限がない、daemon 切断時の挙動は未実証）は維持する。停止済みの19台とOAuth登録は残し、後片付けは別の承認点で扱う。Anthropic へ送られたのは、承認範囲の合成題材・生成物・結果の要約だけである。秘密値やホストの認証ファイルは読んでいない。
