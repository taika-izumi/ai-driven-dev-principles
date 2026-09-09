# Docker Sandboxes導入前の確認

- 日付: 2026-09-09。
- 対象: ADR-0154とIssue-0136の既存基盤比較を受けた、ローカルsbxの導入前確認。
- ユーザー指示: 比較結果と最小実証の提案に対する「ありがとうございます。次へ進みましょう」。読み取り確認と導入物の準備を実施。インストール・ログイン・VM/モデル起動は未実施。

## OSと仮想化

通常の制限付き実行ではCIMへのアクセスが拒否された。制限外の読み取り実行でWin32_OperatingSystemを取得し、`Microsoft Windows 11 Home`、`10.0.26200`、64bitを確認した。前回レジストリのProductNameに残っていたWindows 10表記ではなく、このOS情報を採用する。

Get-WindowsOptionalFeatureは制限外でも管理者権限を要求した。管理者昇格やOS機能変更は行わず、[MicrosoftのWHvGetCapability](https://learn.microsoft.com/en-us/virtualization/api/hypervisor-platform/funcs/whvgetcapability)を呼んで`WHvCapabilityCodeHypervisorPresent=0`を照会した。結果はHRESULT=0、capability=1、writtenBytes=4。API経由でハイパーバイザーの利用可能状態を確認した。DISMによるOptionalFeature状態の取得や、実VMの起動成功とは区別する。

## 導入物

WinGetの`Docker.sbx`を読み取り照会したが0.42.1は未掲載で、一覧の最新は0.39.0だった。workspace省略機能が0.42.0以降という[構成説明](https://docs.docker.com/ai/sandboxes/architecture/)に合わせ、[公式リリース0.42.1](https://github.com/docker/sbx-releases/releases/tag/v0.42.1)のユーザー向け`DockerSandboxes.msi`を取得した。

- 保存先: `.tmp/sbx-preflight-20260909/DockerSandboxes-0.42.1.msi`（当該worktree内）。
- 取得元: `https://github.com/docker/sbx-releases/releases/download/v0.42.1/DockerSandboxes.msi`。
- サイズ: 82,444,288バイト。
- SHA256: `7889FB867090AB81EBBCC950D734E76976C2E7B52AB4CA359CB205B0C51E25D3`。公式配布物一覧と一致。
- Authenticode: Valid、署名者Docker Inc。
- MSIを読み取り専用で開いて確認: ProductName=Docker Sandboxes、ProductVersion=0.42.1、Manufacturer=Docker Inc、ProductCode=`{B3A1F716-144E-4BCA-8FC1-2AA6EB1DEA79}`。

取得と検査のみ。MSIの実行、既存Docker Desktopの変更、認証情報の読取・移送は行っていない。

## 次の操作前レビュー

提案する操作は、検証済みMSIをユーザー`d12an`へインストールし、導入されたsbxの版とヘルプを確認すること。全ユーザー用MSIは使わない。公式案内による配置先は`%LOCALAPPDATA%/DockerSandboxes`で、ユーザーPATHへbinが追加される。インストールログは当該worktreeの`.tmp/sbx-preflight-20260909/install.log`へ保存する。

実行時は`msiexec.exe /i <検証済みMSI絶対パス> /qn /norestart /L*v <ログ絶対パス>`を明示的な引数で呼ぶ。戻り値とインストール実体を確認し、非ゼロ・再起動要求・想定外の管理者要求は報告する。`/norestart`により自動再起動しない。Windows Installerの標準アンインストールでプログラムを戻せるが、作成された設定・ログ等の残存物を無断削除しない。

ユーザーPATHが変わるためpre-action-reviewの確認対象とする。この段階の承認はDockerログイン、OpenAI認証、イメージ取得、VM作成、モデル起動、クラウド利用には拡張しない。

## AIなしの最小実証で確認する内容

導入版のヘルプで契約を照合後、試験案を確定する。公式CLIにcreate shell、exec、cp、stopがあることは確認済み。今回の実機ではまだ使っていない。

- 試験用shell環境。Codexモデルを呼ばず、ホストworkspaceを共有しない。共有スキル、MCP接続、ポート公開、秘密情報を追加しない。
- 合成Gitリポジトリだけをコピーし、固定コマンドによる編集・出力回収を対照にする。実プロジェクトは渡さない。
- 資源案はCPU2・メモリ2GiB。ローカルの時間監督とstop状態の確認方法を導入版で特定する。クラウド専用TTLを流用しない。
- 受付側の記録と、コピー境界・Git保護・通信拒否・停止を確認する。第1段階のshell試験だけでCodexの認証・ツール経路・実往復を検証済みとしない。
- 終了は名指しの停止。VMや既存試験領域の自動削除は行わない。

この試験は別の実行対象・イメージ取得とDockerログインを必要とするため、導入後の確認結果を含めて具体化する。公式文書にあるだけのオプションを使える前提で起動しない。

## 追記: ユーザー承認後のインストールと確認

2026-09-09 19:28、ユーザーが「インストールして確認へ進む（推奨）」へ「1で」と回答したため、検証済みMSIを再ハッシュ・署名確認後、d12anユーザーで実行した。msiexecの終了コードは0。`/qn /norestart`で実行し、自動再起動は行っていない。

- 実体: `C:/Users/d12an/AppData/Local/DockerSandboxes/bin/sbx.exe`。
- 版: `v0.42.1 cc6e400a4a3ce3ce5e0b2b77b8ee352aac854c64`。
- バイナリSHA256: `332736555707E52B284F6F1431A23C14FF62C6B69CFA200AF3DDF748E2B56ECA`。
- ユーザーPATHに同binディレクトリが登録されたことを確認。
- インストールログ: `.tmp/sbx-preflight-20260909/install.log`。
- 確認manifest: 同ディレクトリの`installed-verification.json`。版と7ヘルプ（create shell、create codex、exec、cp、stop、ls、login）の計8コマンドがすべて終了コード0。各出力のSHA256も保存した。

導入版のcreate shellはworkspace省略、CPU・メモリ指定、`:ro`を説明。execは停止済み環境を自動起動するため、停止確認用には呼ばずlsのJSONを使う候補とする。stopは状態を残し削除しない。これらはヘルプの契約確認で、VMの動作実証ではない。

公開文書にある`--no-share-skills`は、今回取得したcreate shell・create codexヘルプでは確認できなかった。フラグ不存在を完全に断定せず、実行前に共有スキルの適用範囲と無効化手段を追加確認する。知らないフラグを外して保護条件を緩めた状態で再試行しない。

Dockerログイン、OpenAI認証、イメージ取得、VM作成・起動、モデル起動は未実施。インストール成功を保護・検証成功と読み替えない。
