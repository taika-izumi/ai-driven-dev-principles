# 検査実行の隔離方法と16GB環境での負担

- 確認日: 2026-09-08
- 目的: Issue-0136の設計材料として、書き込み範囲を強制する方法の導入負担・メモリ・処理時間を比較する。利用者の現状は16GB、32GBへの増設予定。
- 範囲: 公式文書、ローカル環境照会、Codexの試験専用ファイルでの隔離確認と直列の時間計測。方式の採用・ガイドライン改定は未確定。インストール、永続設定ファイルの変更、AI呼び出しは行っていない。Codexの既存機能による試験フォルダへの権限付与とランタイムのログ更新は発生した。
- 関連: [ロードマップ](../current/development-roadmap.md)、[公式ツール調査](ai-team-tooling.md)、[Issue-0136](../working/issues/flow/0136-inspection-delegation-does-not-fire-destructive-verification-row/0136-inspection-delegation-does-not-fire-destructive-verification-row.md)

## 1. 調査結果

16GBのこのPCで、CodexのWindowsネイティブサンドボックスによる書き込み拒否と実際の配布整合検査の実行が成立した。追加VMの用意は不要だった。Windows用の検査をこの方式で設計する材料は得られたが、Claudeからの接続・Pesterの変異実験・並列実行は未確認。方式間の性能順位までは実測していない。

### 追加の実測結果（2026-09-08 10:49〜10:56）

- 試験専用の許可フォルダへの書き込みは成功。兄弟フォルダの保護ファイルへの上書きは、親PowerShellとその子PowerShellの両方で `UnauthorizedAccessException`。前後のSHA256一致、試験の終了コード0を確認。
- 1MiBのメモリ上データを128回SHA256計算する処理を通常・隔離で各5回、交互に直列実行。起動込み中央値は292.9ms対632.7ms（+339.8ms）。処理本体の中央値も121.0ms対200.8msで、差を起動だけに帰属させない。
- このリポジトリの `scripts/build-dist.ps1 -Check` をPowerShell 7で通常・隔離各3回実行。全6回で整合検査成功。中央値6.7319秒対8.8887秒（+2.1568秒、約32.0%）。通常の範囲6.65〜7.18秒、隔離8.13〜9.10秒。
- 軽い処理のPowerShell単体のピーク作業メモリは通常76.2〜76.5MiB、隔離75.6〜75.9MiB。Codexの補助プロセス等を含む合計ではなく、隔離全体のメモリ増分と解釈しない。PC全体の空きは初回照会約4.00GiB、軽い処理の計測前約4.11GiB・後約4.07GiB。途中の最低値は未測定。

結果は [実行記録JSON](../records/experiments/2026-09-08-inspection-isolation.json) に保存。通常→隔離の固定順序を各回繰り返した小規模測定であり、ユーザーの他作業・キャッシュ・ウイルス対策・電源状態を統制していない。初回セットアップ込みの所要時間や大規模ビルドの性能へ一般化しない。

先の対話で提示した「制限できる環境へ移す」案には導入・移行の負担説明が不足していた。Gitによる複製と権限制限は別であり、Windows Sandboxのような別OSの起動も必須ではない。

## 2. 方法別の比較

Codex以外の容易さ・相対負荷は公式仕様からの推定。Codexの実測は前節の対象に限定する。

| 方法 | 実現に必要な作業 | メモリ・CPU・時間 | 今回の制限 |
|---|---|---|---|
| Gitのworktree・複製だけ | 別の作業フォルダを用意 | 常駐する別OSは不要。複製時のディスクI/Oと検証本体が中心 | 範囲外の書き込みを拒否しないため単独では目的未達 [G] |
| CodexのWindowsネイティブサンドボックス | このPCでは既存セットアップを利用。試験フォルダの所有者・一時権限指定・PowerShell実行条件を調整 | 別OS起動なし。実検査は中央値+2.16秒。全プロセス合計のメモリ増分は未測定 | Windows用処理の候補。MCP等の別経路まで同一制限と仮定しない [O1][O2] |
| Claude Code＋WSL2のBashサンドボックス | Linux側のClaude・検証依存、bubblewrap・socat等を準備 | WSL2の共通負担＋各コマンドの負担。隔離自体のオーバーヘッドは公式では小さい | Windowsネイティブは非対応。内蔵ファイル編集等は別の権限機構 [A1] |
| WSL2＋Claudeプロセス全体をsandbox-runtimeで包む | 上記に加え設定・認証・ネットワーク・出力先を準備 | 担当ごとの別VMは不要。追加ランタイムと検証本体の負担は実測が必要 | 内蔵ツール・フック・子MCPも含めやすいが、ベータの研究プレビューで維持変更負担あり [A2] |
| DockerのLinuxコンテナ | イメージ、依存、読み取り専用入力、出力、資源上限を準備 | WindowsではWSL2等の基盤負担がある。複数コンテナでVMを共有できるが各検証の負担は加算 | Linuxでの検証。Windows固有挙動の代替にはならない [D1][D2][D3] |
| Windows Sandbox | 対応エディション、機能有効化、検証環境・結果回収の準備 | OSの起動・準備が必要。既定の容量上限4GB、起動に不足する指定は最低2048MBへ補正。常時使用量ではない | Home非対応。このPCでの簡単な導入候補にはできない [M1][M2] |

Windows SandboxはOSページ共有等で通常のVMよりメモリを節約するが、軽量な権限制限と同じ費用ではない。[M3]

## 3. このPCで確認できたこと

| 確認 | 結果と限界 |
|---|---|
| `codex --version` | `codex-cli 0.153.4` |
| `claude --version` | `2.1.261 (Claude Code)` |
| `Get-Command codex,claude,docker,wsl` | 4実行ファイルを確認。追加の通常ユーザー権限での照会でDocker Server 29.6.1・Linuxを確認。実行中コンテナなし。イメージ一覧にはLoopForAlpha用とhello-worldが存在 |
| OS・CPU・メモリ | 通常ユーザー権限でのCIM照会でWindows 11 Home、Core i7-12700H（14コア・20論理CPU）、可視RAM 16,395,420KiB。レジストリは25H2・build 26200 |
| `.claude/settings.local.json`のsandboxキー | なし。ユーザー・管理設定や別プロジェクトの設定は確認しておらず、実効設定なしとは断定しない |
| `Get-Process`のWorkingSet64 | 一時点でclaudeの2プロセスは約376MiB・322MiB。何の担当か、負荷状態、共有メモリ、ピークは未確認。担当1人あたりの見積もりには転用しない |
| `Get-CimInstance Win32_OperatingSystem`、`wsl --list --verbose` | 制限付きセッション内では拒否。通常ユーザー権限では成功。WSL 2.7.10.0、Ubuntuとdocker-desktopはともにWSL2、最初の一覧では停止状態。Docker照会が基盤を起動したかは未判定 |
| Codexの起動形式 | 実機ヘルプは `codex sandbox [OPTIONS] [COMMAND]...`。公式ページの `windows` サブコマンドを挟む形式とは異なる。`-C` の使用には `-P` で権限プロファイル指定が必要だった |

このセッション自身の制限と、通常ユーザー権限から起動する検証用サンドボックスを分けて確認した。実機のユーザー設定は `windows.sandbox="elevated"`。追加インストール・管理者としての再セットアップ・既存フォルダの所有者変更は実施していない。今回の試験には、通常ユーザー権限でのコマンド実行を利用した。

導入の容易さを左右した実際の調整は次の3点。実験コードは `.tmp/inspection-probe-host-20260908/run/` に保全し、実行記録にパスとハッシュを残した。

1. 最初に隔離ユーザーが作った試験フォルダでは `SetNamedSecurityInfoW failed: 5`。通常ユーザー所有の別の新規フォルダを用意すると権限付与が通った。
2. パスを含む `-c` のドット区切りキーは解析に失敗。`permissions.inspection={extends=":read-only",filesystem={"<試験runフォルダの絶対パス>"="write"},network={enabled=false}}` というTOMLインラインテーブルで一時指定した。
3. Windows PowerShell 5.1は隔離ユーザー側でスクリプト実行が禁止されていた。試験プロセスに限った `-ExecutionPolicy RemoteSigned` 指定でローカルスクリプトが実行できた。システムの実行ポリシーは変更していない。

LoopForAlphaの `loop/sandbox/Dockerfile` はPython 3.12ベースで、Windows用のPester環境ではない。既存コンテナをそのままWindows検査へ転用できるとは扱わない。Dockerのイメージ照会は途中で一度失敗したが、前後の一覧に存在した。今回はコンテナを起動せず、負荷比較も未実施。

## 4. 16GBでの実行案

以下は導入前の提案。32GBへの増設を開始条件とする根拠はなく、まず軽い構成で確認できる。

1. **取りまとめ・文書確認と、重い検証の並列数を分ける。** 初回はビルド・変異実験・ブラウザ検査などの重い処理を1件ずつ動かす。担当の人数と同時実行する重い処理の数を一致させる必要はない。
2. **Windows固有の検証ではネイティブの権限制限から確認する。** Codexの既存環境を使えるなら追加VMを避けられる。ClaudeのWindowsセッションから任意のコマンドだけをCodexのサンドボックスへ渡す接続は今回は未検証で、設定1行で済むと見積もらない。
3. **Linuxで成立する場合はWSL2を共有する案を比較する。** WSLのmemory既定値はホストRAMの50%で、16GBなら約8GBの上限となる。固定予約・常時使用量ではない。既存Docker等とも共有する設定なので、変更前に現在の使い方を確認する。[M4][D1]
4. **必要ならWSL全体の上限4GB・重い検証1件を試行の出発点にする。** 4GBは必要量の測定結果ではない。重いビルドが収まらない場合は同時実行数・対象を見直す。上限によるメモリ不足と、ディスクへの退避による遅延を区別する。CPU上限も利用可能。[M4][D2]

Dockerは無指定だとコンテナごとのCPU・メモリ上限がない。上限の設定と十分な性能は別で、上限を厳しくすると停止・遅延が起き得る。[D2] WSL2上ではDockerのResource Saverだけでメモリが返るとは限らず、メモリ回収設定も確認する。[D4]

CPU・時間への影響は、隔離機構よりもビルド、テストの子プロセス数、複製・ハッシュ比較の読み取り量に左右される可能性が高い。これは処理構成からの推測である。クラウドのモデルを利用する場合でも、CLIの会話管理と実行する検証にはローカル資源が必要。32GBへ増やしてもCPU・ディスクの競合は残るため、並列数を自動で倍にしない。

## 5. 機能上の注意点と次の小規模確認

Codexのサブエージェントは親の実効サンドボックスを引き継ぐ。親の対話中の設定が子の設定を上書きする場合もあり、定義ファイルだけで子を狭められたと判定しない。[O2] 今の親は実リポジトリへの書き込み権限を持つため、その継承だけでは実リポジトリを検証から保護できない。検証用コピーを作業領域にした別実行で、元リポジトリへの書き込みを許さないことを確認する必要がある。

ClaudeのBashサンドボックスも親子で設定を共有する。Windowsバイナリの起動はWSLの相互運用経路を使い、Unixソケット設定と任意のseccompフィルターに依存する。検索結果の古い抜粋には起動不可とあったが、実際に開いた現行ページは設定依存としている。起動を許せることとWindows側まで隔離が届くことを混同しない。[A1]

今回、試験専用ファイルで許可側・保護側・子プロセスを確認し、実際の配布整合検査も成功した。Windows用検証をCodexで実行する案の設計材料は得られた。未確認なのは、Pesterの実際の変異台本、Claudeからの呼び出し、許可したフォルダ内の既存記録の保護、リンクや別名経路、MCP等の別実行経路である。特に許可フォルダ内の誤削除は外側の書き込み制限だけでは防げない。

負荷確認では直列実行までを測定した。1件から2件へ増やすのは必要性と余裕を確認した後とする案。最大並列数は未確定だが、「16GBでは隔離機能の利用自体が難しい」という状態ではなかった。以後は方式を広く比較し続けるより、採用候補に必要な未確認項目をIssue-0136の設計・検証へ含めることを推奨する。採用決定は未実施。

## 6. 出典

すべて提供元の一次資料。機能と条件の根拠として利用し、このPCでの性能・設定反映を保証する資料とは扱わない。

- [G: Git worktree](https://git-scm.com/docs/git-worktree)
- [O1: OpenAI・Windows sandbox](https://learn.chatgpt.com/docs/windows/windows-sandbox)
- [O2: OpenAI・Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents)
- [A1: Anthropic・Bash sandbox](https://code.claude.com/docs/en/sandboxing)
- [A2: Anthropic・隔離環境の比較](https://code.claude.com/docs/en/sandbox-environments)
- [D1: Docker・WSL2 backend](https://docs.docker.com/desktop/features/wsl/)
- [D2: Docker・資源制限](https://docs.docker.com/engine/containers/resource_constraints/)
- [D3: Docker・読み取り専用マウント](https://docs.docker.com/engine/storage/bind-mounts/)
- [D4: Docker・Resource Saver](https://docs.docker.com/desktop/use-desktop/resource-saver/)
- [M1: Microsoft・Windows Sandbox対応条件](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/)
- [M2: Microsoft・Windows Sandbox設定](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-configure-using-wsb-file)
- [M3: Microsoft・Windows Sandbox構造](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-architecture)
- [M4: Microsoft・WSL設定](https://learn.microsoft.com/en-us/windows/wsl/wsl-config)

## 7. リモート操作中に進められたClaude Codeの確認

2026-09-08、ユーザーはリモート操作中でClaude Code画面を操作できないと説明した。既存CLIの認証状態はログイン済みで、画面操作なしの読み取り専用試験が成立した。`--restricted`、`--safe-mode`、`--tools Read`、空のMCP構成と `--strict-mcp-config`、MCP拒否、フック無効化、承認プロンプトなしを組み合わせた。既存セッションの再開や認証設定の変更は行っていない。

実行開始イベントの利用可能ツールはReadのみ、MCPは0件。試験ファイルの値734921をReadで取得し、前後SHA256は一致した。所要4.51秒、2ターン、利用モデルはCLI既定の `claude-opus-5[1m]`。CLI表示費用は0.0377995米ドルで、請求額や契約枠消費の実測ではない。[実行記録](../records/experiments/2026-09-08-claude-readonly.json)

これは書き込み操作を持たない静的確認の経路を試した結果であり、実行を伴う検査の保護や通常のプラグイン読み込みの実証ではない。今回使った制限モードとツール指定の意味は [AnthropicのCLI公式文書](https://code.claude.com/docs/en/cli-reference) でも確認した。

続く現行スキル本文と架空4ケースの判断試験は、最初は自動承認レビューにより外部送信の承認不足として拒否された。通常のClaudeモデル利用であることを説明し、ユーザーがこの2ファイルの送信を明示承認した後に実行した。入力は `.tmp/claude-readonly-probe-20260908/baseline-skill.md` と `cases.json`。

結果は3件合格・1件不合格。広い権限を継承する検査担当のケースでは、現行スキルの発火条件から「隔離準備は不要」として起動する判断が返り、共通改定の対象となる不足が再現した。明示的変異、時刻が近い既存記録の除外、静的確認の負担抑制は期待どおりだった。これら3件には今回の結果から改善効果を主張しない。約49.17秒・3ターン、CLI表示費用0.1666435米ドル。[現行判断試験の記録](../records/experiments/2026-09-08-inspection-dispatch-baseline.json)

試験はReadだけの机上判断であり、実際に広い権限の子を起動したりファイルを壊したりしたものではない。共通改定と実経路の確認は [実装計画](../working/plans/2026-09-08-issue-0136-inspection-protection.md) に整理した。

## 8. Claudeから既存Codexへ固定検査を渡した実証

出所: Issue-0136・ADR-0142、2026-09-08。前節までの未確認範囲を追加で検証した結果であり、過去の試験を遡って成功扱いにしない。

Claude Code 2.1.261の内蔵操作をReadだけにし、明示したstdio MCP接続1件から、引数なしの固定Pester検査だけを公開した。任意のツール名と追加コマンド引数は入口で拒否した。接続側がCodex CLI 0.153.4の `sandbox` へ固定された実行ファイル・引数を渡し、コピーだけを書き込み可、既存記録と接続プログラム・設定は読み取り専用とした。

Claudeの開始イベントに公開されたツールはReadと `mcp__inspection__run_inspection` の2件だけだった。Claudeから固定検査を実際に呼び、Pester 3.4.0で正常1件成功、加算を減算へ変えた変異1件失敗、復元1件成功を確認。変異の実エラーは期待値5に対して-1であり、起動不能や無条件throwによる失敗ではない。原本・共有ツール・既存記録・接続プログラムの代用品への4件の拒否、子PowerShellの正常書き込みと拒否も確認した。

主担当は、接続と設定を含む保護6件の前後SHA256一致、実ツール一覧、実出力を照合した。後片付けは作成物の候補を名指しするだけで、既存記録を削除していない。結果は [実行記録](../records/experiments/2026-09-08-claude-codex-limited.json)。試験補助は `scripts/experiments/inspection-dispatch/limited-execution/` にあり、常設の汎用サーバーとしてプラグインへ配布しない。

実証で必要だった調整は次の2点。いずれもユーザー環境の永続設定や権限範囲を変更していない。

- Pesterが共通TEMPへTestDriveを作ろうとして拒否された。試験プロセスのTEMP・TMPをコピー内へ指定すると通常環境と同じ正常・変異・復元が成立した。
- Claudeの `--safe-mode` は明示したMCPも無効化した。`--restricted`・Read限定・strict MCP構成・フック無効化・承認プロンプトなしで、固定操作のみを公開できた。

この成功は、既存CodexのあるWindows 11環境と固定検査への接続に限定する。Claude単独環境、任意コマンドを受け付けるMCP、別のOSや版へ一般化しない。別の検査を接続する場合は、その接続と検査の実体を起動前に確認する。

## 9. Codexの副担当への制限継承

同日、書き込み先を試験コピーへ狭めたCodex CLI起点で、副担当のAIを実際に起動した。副担当の許可先への書き込みは成功し、原本代用品へのシェルと内蔵編集の変更は拒否された。親の読み戻しと主担当のハッシュ比較でも原本の保全を確認した。[実行記録](../records/experiments/2026-09-08-codex-subagent-inheritance.json)

無効化フラグを指定していても、この実行環境では副担当が起動できた。したがって無効化の成立を証拠にせず、実際の制限継承を確認した結果として扱う。履歴を保存しない `--ephemeral` 起動では親スレッド不在で起動に失敗し、同フラグだけを外した起動では成功した。比較から起動方式の影響は示されたが、内部原因の断定や全環境での再現保証はしない。親スレッド不在エラーは保護成功の件数に含めない。

## 10. Claude標準のサブエージェント機能での確認

出所: Issue-0136・ADR-0143、2026-09-08。Claude Code 2.1.263・Windows 11で、標準のサブエージェント機能（Agent/Task ツールから子の担当を起動する仕組み）を実測した。前節までの別プロセス起動＋固定検査接続の成功とは別の確認である。[実行記録](../records/experiments/2026-09-08-claude-native-subagent.json)

親に `Bash, Edit, Read, Write` を与えた状態から子を起動し、子の利用可能ツールを許可リストで `Read` だけに絞ると、子のBash・PowerShell・Write・Editはいずれも `No such tool available` で実行できなかった。親が同じツールを持っていても子へは渡らない。許可された読み取りは成功し、値は親へ回収できた。

固定検査だけを渡した構成も成立した。セッション側に公開した検査接続1件を、子の許可リストでその1操作だけに限定した。子から実行したPesterは正常1成功・変異1失敗（期待値5に対して-1）・復元1成功、保護代用品4件は `UnauthorizedAccessException` で拒否、子プロセスは許可先にだけ書き込めた。実行そのものは既存Codexのサンドボックス内で行っており、Codexなしの環境の対応例ではない。

一方、権限モードは保護の代わりにならなかった。親を `acceptEdits` にして子に `Write` を渡すと、子は保護対象の代用品を実際に上書きした。拒否されたのは作業ディレクトリの外への書き込みだけである。承認する人がいない `--print` 実行では、`Bash` を持つ子の書き込みは許可先も含めて自動拒否され、この状態は保護の成立ではなく承認経路の不在である。

再委譲は既定で成立した。`Agent` を許可リストに含む子は孫を実起動でき、孫は自身の許可リスト（`Read` のみ）の範囲に留まった。再委譲を止める場合は子の許可リストから `Agent` を外す。

設定機構の注意点は3つある。エージェント定義ファイルは起動時に読み込まれ、実行中のセッションで新規作成しても認識されない（上位ディレクトリの定義は発見される）。`--agents` のJSONは `permissionMode` を受け付けるが `mcpServers` は受け付けない（`Invalid input`）。`--permission-mode auto` は `--print` 実行に反映されず、開始イベントは `default` だった。

未確認は、対話セッション（autoモード）での実挙動、定義ファイルのfrontmatterによる接続の限定公開と拒否リスト、親が `bypassPermissions` の場合、別OS・別版である。今回の成功をこれらへ読み替えない。
