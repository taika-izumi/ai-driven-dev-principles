# Claudeから固定検査を呼ぶ接続の実証

Issue-0136・ADR-0142の試験補助。プラグインへ配布する汎用MCPサーバーではない。任意コマンドを実行する機能、動的なパスや権限の指定、インストール機能を持たない。

`server.ps1` はstdioのMCP接続で、引数なしの `run_inspection` だけを公開する。`probe.ps1` は呼び出しごとにrun内へ新しいattemptフォルダを作り、加算関数とPester検査で正常→減算への変異→復元を検査する。実物を変更せず、原本・共有ツール・既存記録・接続プログラムの代用品への拒否も検査する。

再現する場合は、新しい試験ルートに `run`・`protected`・`controller` を作る。実物を入れない。`protected/original.txt`・`protected/shared-tool.txt`・`run/session-log.json` に代用品を用意し、2スクリプトはcontrollerへコピーする。既存物があるルートへ上書きで準備しない。

controller内のmanifest JSONには `fixtureRoot`（試験ルートの絶対パス）、`codex`・`pwsh`（既存実行ファイルの絶対パス）、`probeSha256`（コピーしたprobe.ps1のSHA256）を指定する。ClaudeのMCP構成で、pwshの `-NoProfile -NonInteractive -File <controller/server.ps1> -Manifest <manifest.json>` をstdio接続として登録する。MCPの識別名はinspectionとした。

子プロセス検査はWindows PowerShell 5.1の既定パス `C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe` を使用する。接続側のTEMPとlast-result.jsonはconnectionArtifactsに作成有無を記録し、自動削除候補へは合流させない。

事前にMCPの `tools/list` が1件、未知のツール名・追加引数が拒否、引数なしの固定検査が成功することを確認する。通常環境の対照は `probe.ps1 -FixtureRoot <root> -NormalOnly` で、正常・変異・復元だけを実行する。通常環境で保護拒否を試すモードを実行しない。

Claudeの起動条件は `skills/subagent-dispatch/references/inspection-isolation.md` の「Claudeから固定検査を呼んだ確認例」を参照。入力は `claude-prompt.txt`。開始イベントのツール2件を確認し、固定操作の出力と保護対象の前後ハッシュを委譲元が照合する。出力はcontroller/last-result.jsonにも残るため、呼び出しごとに別の記録へ保存する。生ログの上書きを継続的な監査方式には使わない。

正常1件成功、変異1件失敗、復元1件成功、保護4件の拒否、子の正常書き込みと拒否、元の保護内容の一致が期待値。後片付けは候補を名指しするだけで、実際の削除はしない。

結果と限界は `docs/records/experiments/2026-09-08-claude-codex-limited.json` とIssue-0136の実装検証ノートを参照。別のOS・版・固定検査への一般化には別の確認が必要。
