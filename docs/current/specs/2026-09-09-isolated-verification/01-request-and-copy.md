# 依頼・基準版・提案用コピーの準備

## 対象と責務

scripts/verification/Invoke-IsolatedVerification.ps1、RequestCopy.psm1、request.schema.json、settings.schema.json、README.mdを所有する。CLIは4ブロックの順序だけを調整する。New-VerificationRun(RequestV3, SettingsV3) -> PreparedRunV3を提供する。

既存New-VerificationRunのv1はNew-LegacyVerificationRunへ抽出し、挙動と公開契約を維持する。v3はNew-ProposalReplayRunへ分岐する。ファイル列挙・独立履歴作成の下位処理を共有し、ホストcodexPathを必要とする旧v1起動検査をv3へ流用しない。追加の型・未知キー検査はv3側が所有する。

## 依頼の契約

RequestV3はschemaVersion=3、caller、sourceRoot、objective、acceptanceCriteria、extraInputPathsを必須とし、任意キーはrecheckだけ。callerはclaude-code/codex。sourceRootはGit作業ツリーの絶対パス。目的と合格条件は空不可。extraInputPathsは原本内の相対パス配列。数字の文字列表現、未知キー、不正型、重複JSONキーを拒否する。

recheckはpreviousResultPath、testPathsを持つ。前回のホスト確定結果とテストだけを再利用する。前回の子のGit・修正候補・自己申告の実行結果は自動採用しない。主担当が通常の工程で原本を修正した後、新しいrunIdで再検証する。テストの同一性は前回結果のハッシュから固定する。

SettingsV3はschemaVersion=3、sbxPath、pwshPath、runsRoot、model、proposalProfilePath、replayProfilePath、pilotInputPath、limitsを必須とする。実行ファイルと各パスは絶対、modelは明示した空でない識別子。モデルを自動変更しない。プロファイルは外側の実行設定とその成立証拠で、02の契約に従う。認証値は設定へ含めない。

recheckのときだけmodel/proposalProfilePathはnullを許す。指定されていても提案段階を起動せず、再実行のためにモデル認証や提案profileの成立を要求しない。replayProfilePathは常に必須。

limitsはtotalSeconds、proposalSeconds、replaySeconds、cleanupSeconds、cpus、memoryMiB、maxProposalFiles、maxFileBytes、maxProposalBytes、maxWireBytes、maxOutputBytesを持つ。すべて正の整数、proposalSecondsとreplaySecondsはtotalSeconds以下。cpus=2、memoryMiB=2048を初回の基準とする。pidsは設定キーに含めず、旧設定が残る場合は未知キーとして拒否し黙って無効化しない。上限は全体1800秒、提案600秒、各再実行120秒、停止猶予30秒、100ファイル、1ファイル1MiB、合計8MiB、転送全体16MiB、1コマンドstdout/stderr合計16MiBを初期値とする。利用者が設定を明示し、上限変更を子へ委ねない。資源制約の実効性は02の成立条件で検証する。全体時間到達後は新しい作業を開始せず、停止処理だけcleanupSecondsを別枠で許す。

synthetic-pilotではcpus=2かつmemoryMiB=2048を固定し、その他の値は準備時にblocked。設定ファイルを変えただけで割当を拡張しない。将来の別値は別承認と仕様改訂が必要。

pilotInputPathは、名指しの合成題材の承認時に外側の主担当が準備する固定入力記録の絶対パス。schemaVersion=3、inputId、scope=synthetic-pilot、sourceRoot、sourceManifestHash、approvalReferenceを持つ。approvalReferenceは既存の承認記録のパスと版/ハッシュを指し、記録本文の内容を実行コマンドとして扱わない。CLIはこの記録をRequestから自動生成せず、子にも生成・編集させない。承認前の記録を有効化せず、利用者の本文転記や別の常設承認台帳を増やさない。

準備時にRequest.sourceRootの正規化パスと実際の選択版manifestを固定入力記録へ照合し、不一致ならVMを作成しない。v3のsourceManifestはキー辞書順・UTF-8・空白なしのJSONへ正規化して保存・hash計算し、v1の形式は変えない。recheckで原本版が変わる場合もその具体版に対応する固定入力記録を使い、古いhashのまま承認済み扱いしない。これはモデル試験の具体入力承認を実行へ対応付ける情報であり、新たな任意プロジェクトへの許可ではない。

## PreparedRunV3

必須キーはschemaVersion=3、runId、sourceRoot、runRoot、baselineRoot、proposalInputRoot、acceptedRoot、controlRoot、request、settings、sourceManifestPath、baselineManifestPath、recheckManifestPath。recheckManifestPathは再検証なしの場合null。他は正常準備時に存在する実体を指す。失敗時は例外のstage/status/runRootをCLIが捕捉し、03の失敗結果を返す。

追加の必須キーはstartedAt、deadlineAt、sourceManifestHash、baselineManifestHash、recheckManifestHash、recheckArtifacts。startedAtはCLI受付時、deadlineAtはstartedAt＋totalSeconds（UTC ISO8601）。準備時間も含め、後段で起点を更新しない。CLIは同時に単調増加時計で残時間を監督し、全体を継続するプロセスを再起動して期限を延長する機能は持たない。manifestHashは書込み完了後に外側が計算して呼出し状態に保持するSHA256。recheckなしならそのhashはnull、recheckArtifactsは空配列。recheckArtifactsの要素はkind=test、path（acceptedからの相対）、size、sha256、previousRunId。これらの期待値を後段でファイルから再生成して置き換えない。

pilotInputId、pilotInputPath、pilotInputHashもPreparedRunV3へ必須として保持する。元記録を検査して当該controlへコピーし、そのパスとhashを外側の呼出し状態に保持する。後段で記録を再生成・差し替えしない。

```
runsRoot/runId/
  baseline/             # 外側が保全。原本の選択ファイルと独立.git
  proposal-input/       # baselineの独立コピー。これだけ子へ搬入
  quarantine/           # 未信頼の転送データ。VMに共有しない
  accepted/             # 外側が検査した通常ファイル
  replay-inputs/        # 修正前/修正後の独立入力
  temp/                 # 外側だけの一時領域
  control/
    request.json
    source-manifest.json
    baseline-manifest.json
    recheck-manifest.json
    runtime/            # 02の成立証拠・作成したVM識別情報
    proposal/           # 外側の受信・検査記録
    replay/             # 外側の各実行記録
    result.json
```

baselineとcontrolをVMにマウントしない。ホスト側で読み取り専用属性を付けたことだけを強制隔離と扱わない。子への到達経路を渡さず、開始・終了時のハッシュ照合も行う。

## 準備手順

1. sourceRoot/runsRootの包含関係と祖先の再解析ポイントを検査。runsRootがsourceRootを包含する設定を拒否する。原本内runsRootは列挙から全除外する。UUIDの新runRootだけを作り、既存物を上書きしない。
2. 既存Get-VerificationSourceManifestで選択版を取得する。Git追跡・対象未追跡・extraInputPathsを含め、導入設定・.codex/.claude/.agents/.mcp.json・原本の.git・run出力を除外し理由を保存する。原本内の予約パス.verification-testsと.verification-controlの衝突は拒否する。
3. baselineへ実体コピーする。リンクやハードリンクによる共有はしない。Git履歴は既存Initialize-VerificationHistoryのbundle/verify/unbundle/参照復元/fsckを使う。原本のGit設定・フック・リモート接続・共有オブジェクト参照は移さない。HEAD・ブランチ・全参照と作業中ファイルを別々に保持する。
4. baseline内全通常ファイル（.gitを含む）の相対パス・サイズ・SHA256をbaseline-manifestへ保存。子や再実行環境にbaselineそのものを渡さず、ファイル単位の独立コピーを作る。提案用.gitが自分のproposalInputRoot内を指すことを検査する。
5. recheckがある場合、前回resultを現在のrunsRoot内で解決し、schemaVersion/runId/停止/掲載テスト/ハッシュを確認する。選択テストを当該runのaccepted/testsへ通常ファイルとしてコピーし、recheckManifestとrecheckArtifactsに由来とハッシュを記録する。提案用VMは使わず、proposal-inputへのテスト搬入もしない。通常の原本ファイルと区別する。
6. 原本を再列挙し、準備前後のfiles/head/headRef/historyRefsを比較。変化はsource_changed。baselineの全ファイルハッシュも照合する。コピー中の入力変更を成功扱いしない。

空履歴も扱う。浅い履歴・部分クローン・サブモジュール・入力リンクは拒否。reflogだけの履歴、到達不能オブジェクト、LFS外部実体は対象外。Git各処理30秒、対話認証・遅延取得を禁止する既存方針を維持する。

## 不変条件と検証

baseline・sourceManifest・recheckManifestは提案側から更新不能。manifest自体のSHA256を外側の呼出し状態に保持し、実行後に照合する。ハッシュは子の申告値から作らない。エラー時の作成済み領域は残し、存在しないパスを成功結果に記載しない。

V1とV6の準備側を検証する。v1既存試験に加え、版混在・未知キー・予約名衝突・入力中変更・原本内runsRoot・基準版と提案入力の独立性・再検証テスト改変/範囲外/停止未確認を扱う。対象外構成へ黙って縮退しない。

関連ADR: 0150、0157、0158。実行設定は02、結果は03、再実行入力は04を参照。
