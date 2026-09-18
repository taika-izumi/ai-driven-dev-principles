# タスク8b の足場の雛形

`tests/Invoke-SbxPublicOperationProbe.ps1` が実行時に読み、`{{…}}` の差込み記号を絶対パス・ハッシュへ置き換えて
runsRoot の外の一時領域へ実体化する。仕様01が「各パスは絶対」と定めるため、追跡するファイルに絶対パスを書かず雛形として置く。

| ファイル | 検査 schema | 差込み記号 |
|---|---|---|
| `request.json` | `request.schema.json`（schemaVersion=3） | `{{sourceRoot}}` |
| `settings.json` | `settings.schema.json` | `{{sbxPath}}`・`{{pwshPath}}`・`{{runsRoot}}`・`{{proposalProfilePath}}`・`{{replayProfilePath}}`・`{{pilotInputPath}}` |
| `pilot-input.json` | `pilot-input.schema.json` | `{{sourceRoot}}`・`{{sourceManifestHash}}` |

- `sourceRoot` は `fixtures/pilot-source/source/` を複製した独立した Git 作業ツリー（初期コミット1件）で、runsRoot の外に置く
  （仕様01「runsRoot が sourceRoot を包含する設定を拒否する」と「sourceRoot must be Git worktree root」のため）。
- `sourceManifestHash` は `Get-VerificationSourceManifest` の正規化JSONの SHA256。`New-VerificationRun` が
  `control/source-manifest.json` に書くバイト列と同じものなので、固定入力照合（`Test-VerificationPilotInputUnchanged`）が成立する。
- `replayProfilePath` は `profiles/replay/profile.json`（**ディレクトリではなくファイル**）。profile 内の相対パスは
  このファイルのディレクトリから解決されるため（`Test-VerificationRuntimeProfile`）。
- `proposalProfilePath` はタスク9まで未生成の固定パス `profiles/proposal/profile.json`。8b は proposal 役の profile 検査を
  呼ばないので存在しなくてよい（設定検査はパスの形だけを見る）。
- `model` は 8b で使わない固定の識別子。proposal 役を作らないので照合されない。
