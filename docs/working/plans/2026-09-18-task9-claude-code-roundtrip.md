# タスク9: Claude Code主担当からの往復実証の操作案

- 完了: 2026-09-18、新規4台・Codex 1セッションで候補比較 candidate-supported、採用、recheck current-pass。全19台 stopped。正本は `docs/records/experiments/2026-09-18-task9-claude-code-roundtrip.md`。
- 状態: 承認済み（2026-09-18、利用者の「1で」。本書の準備・新規最大4VM・Codex 1セッション・OpenAI/Anthropicへの記載範囲の送信を承認）。
- 前提: Codex主担当の往復は2026-09-17に完了（`docs/records/experiments/2026-09-17-task9-codex-roundtrip.md`）。その承認（`2026-09-17-task9-codex-template-amendment.md`）はClaude Code側の実機操作とAnthropicへの送信を含まないため流用しない。

## 目的

Claude Code自身が主担当として公開CLI `scripts/verification/Invoke-IsolatedVerification.ps1` を実行し、候補比較 → 主担当による確認と合成原本への採用 → 同じテストでのrecheck を通す。`caller` の文字列を変えるだけの試験にはしない。VM内の提案担当はCodexのまま。

## 開始前の確認結果（2026-09-18、読取りのみ）

- `sbx daemon status`: running。PID 25888、起動世代 2026-09-16T08:59:47+09:00、sbx v0.42.1（更新通知 v0.43.0 は適用しない）。
- `sbx ls`: 既存15台すべて stopped（前回 `.tmp/m9/final-vms.json` と同じ名前）。
- 合成題材の原本 `scripts/verification/tests/fixtures/pilot-source/source/calc.py` は SHA256 `E40D22A2...`（前回の修正前と同一）。

## 準備（ローカルのみ、VM作成・モデル送信なし）

1. 新しい短いパス `.tmp/c9/` を作る（Issue-0146 のパス長対策）。`.tmp/m9/` の既存資材は変更しない。
2. `.tmp/c9/source` に独立した Git を新規作成し、fixture の calc.py だけを1コミットする。
3. 製品モジュールの関数で source manifest の hash を算出し、`request.json`（caller=claude-code、目的・合格条件は前回と同じ文面）・`settings.json`・`pilot-input.json`（approvalReference は本書）を作る。スキーマ検査と `Test-VerificationRuntimeProfile` による profile 検査を行う。
4. 実行設定は前回と同一: proposal/replay profile、gpt-5.6-sol/medium、登録済み OAuth、pwshPath と limits（全体3600秒・モデル600秒・テスト120秒・停止猶予30秒・CPU2/2GiB・同時1台・出力上限）も同一。

## 実機操作（承認対象）

| 段階 | 新規VM | 内容 |
|---|---:|---|
| 候補比較 | 3 | proposal（codex固定テンプレート b387e913...）で Codex が 1 セッションでテストと修正候補を作成。before/after（shell固定テンプレート 16a88c...）で通信なしに再実行 |
| 主担当の採用 | 0 | Claude Code が候補とテストの全文を読み、妥当と判断した場合だけ `.tmp/c9/source/calc.py` へ反映する。不適切なら採用せず記録して止める |
| recheck | 1 | 採用後の原本で、前回と同じテストを shell テンプレートで再実行。model/proposalProfile は null とし、モデルを再度呼び出さない |

- 新規VMは最大4台（完了後は合計19台、すべて停止して残す）。モデル送信は Codex 1 セッションのみ。再試行・5台目・モデル変更・通信先の拡張は含めない。失敗したら停止を確認して後続を行わず、報告する。
- CLI は長時間になるため、Claude Code の背景実行で起動し、終了値・stdout の結果・`control/result.json`・停止状態を照合する。異常終了したら README の `-StopRecorded` で記録済み VM だけを停止する。
- OpenAI への送信: 前回と同じ種類のもの（固定の目的・合格条件・書式、270バイトの合成 calc.py、合成 Git の履歴1件）。認証の秘密値・本リポジトリの本文・他プロジェクトは搬入しない。
- Anthropic への送信（今回新たに発生）: Claude Code の会話を通じて、合成題材・生成されたテストと修正候補・実行結果の JSON・ログの要約が送られる。秘密値・ホストの認証ファイルは読まない・出力しない。
- 所要時間の目安: 候補比較 10〜30 分、recheck 数分（概算）。

## 行わないこと

daemon の start/restart/reset、sbx や画像の更新、既存 VM や画像の削除、停止済み VM への exec/cp、OAuth の再登録、`.tmp/m9` や fixture の書き換え、master への統合。

## 完了後

結果を `docs/records/experiments/2026-09-18-task9-claude-code-roundtrip.md` と同名ディレクトリの要約 JSON に記録し、handoff を更新する。その後、サイクル全体整合検査・最終レビュー・ADR-0162・0192〜0201 の状態判定へ進む（別の節目）。
