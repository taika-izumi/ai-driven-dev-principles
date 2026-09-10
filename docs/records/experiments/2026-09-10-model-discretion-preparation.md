# モデル裁量比較の入力・固定検査・事前確認

- 日付: 2026-09-10
- 計画: `docs/working/plans/2026-09-10-model-discretion-comparison.md`。ユーザーが追加レビュー見送り・計画確定・準備開始を「1で。」と承認。
- 作成先: `D:/Dev/002_AiDev/WorkflowTrials/model-discretion-20260910`。既存run-*と元プロジェクトは変更していない。
- 状態: 入力・固定検査の準備完了、起動条件の確認は未完了。比較モデルの起動0回。

## 作成と確認

| 対象 | 結果 |
|---|---|
| 固定開始版 | `86d89a8091de8366161569a7771affb0ff279607`からコード8・テスト3を取得し、Gitの実ファイル一覧と一致 |
| template | 公開時コミット`f5229a836156e9a502f2fbde5a5ffddcb2509256`から10ファイルを取得 |
| プラグイン | ai-driven-dev-principles 0.1.26の40ファイル、superpowers 6.3.0の195ファイルを複製し、元キャッシュとのSHA256一致を確認。Git管理領域は除外 |
| 共通入力 | 公開人工ログ8ファイル、依頼文4ファイルを作成しハッシュ固定 |
| 基準テスト | 通常ユーザー環境の既存Pythonで固定開始版の23件成功 |
| 固定検査 | 保護対象側に検査・非公開人工ログ・goldenを作成。検査IDは11。原版は両題材で不合格、正常例は両題材で必要項目全て合格 |
| 誤実装の識別 | UTC補完、時刻不明レコード破棄、未知IDで成功・空出力、選択無視、本文漏出の5例すべて、指定した検査項目で不合格にできた |

資材の正本は作成先の `control/manifest.json`、固定検査の正本は `control/checks-manifest.json`。非公開人工ログ16ファイルと、検査・既存テスト・goldenを合わせた23ファイルをハッシュ固定した。正常例・誤実装例は採点側のコピーだけで、比較対象モデルへは渡さない。

## 起動経路の確認

Codex 0.153.4が複数箇所に存在した。通常ユーザーのCLIは `C:/Users/d12an/AppData/Local/Programs/OpenAI/Codex/bin/codex.exe`。以後の候補はこの絶対パスで固定した。同版の別配置で以前失敗した原因を、今回の結果だけで断定しない。

| 確認 | 結果と限界 |
|---|---|
| Codexの入力表示 | `debug prompt-input`で、project_doc_max_bytes=0だけではガイドラインスキルが残った。プロセス限定のplugins.<id>.enabled=falseで除外でき、必要な2つだけ有効にした側では固定templateとスキルが現れた |
| 設定キーの実体 | CLIの上書きキーはプラグインID等を余分な引用符で囲むと別キーになった。引用符を除いたキー表記で成功。通常config.tomlの変更操作は行っていない |
| コピーと実ロード | 診断で有効になったプラグインは導入済みキャッシュを参照。複製したパスへ実ロードを固定する方法、または同一ハッシュ確認を伴う既存キャッシュ利用の扱いは未確定。ここを確認済みとはしない |
| ファイル境界 | 公式の名前付きプロファイルで新規preflight-workだけを書き込み可にし、control・元ガイドラインリポジトリ・製品.envを読み取り拒否として入力へ反映。管理側設定も含めたcodex sandboxで、親・子の許可内書き込み成功、許可外代用品への拒否と内容不変を確認 |
| ローカル停止 | 固定スクリプトが作った待機用の子・孫だけをプロセスハンドルで停止し、両方の終了を確認。ネイティブのモデル担当の中断・終了を確認した結果ではない |
| Claudeの認証 | 同じ保護下の `claude auth status --json` がclaude.ai・Max契約の認証を確認。認証情報のコピーや追加ログインは行っていない |

根拠は作成先controlの `codex-doctor.json`、`codex-prompt-input-*.json`、`codex-permission-probe-input.json`、`native-sandbox-probe.json`、`local-process-stop.json`、`claude-protected-auth.json`。

CLI引数はJSON配列で保存した。現時点の保存物には診断用の引数も含み、比較を起動できる確定済みコマンド一式とは扱わない。実モデルによる入力継承・内蔵編集経路・親子停止・利用量回収・固定検査保護は未確認であり、`control/preflight.json`の該当項目はunknown、ready_for_comparisonはfalse。

一次資料として[Codex設定リファレンス](https://learn.chatgpt.com/docs/config-file/config-reference)と[設定スキーマ](https://learn.chatgpt.com/docs/config-schema.json)、[Claudeサンドボックス資料](https://code.claude.com/docs/en/sandboxing)を確認。Claudeの標準BashサンドボックスはネイティブWindows非対応だが、今回は既存Codexの保護下で非モデルの認証確認まで成功した。これをClaudeの全ツール経路やモデル実行の保護成立へ一般化しない。

## 時間枠と再開

準備開始13:40:01、実験準備の操作を止めた時点14:39:55（Asia/Tokyo）。準備・採点60分枠のうち約59.9分を使用、残り約6秒。比較側の240分枠は未使用。時間は `control/budget.json` に保存し、以後は記録整理のみ。ユーザーの回答待ちで消費を増やさず、再開時は保存済み経過時間へ次の稼働区間だけを加算する。

残る実モデル確認と本比較後の採点を、この残量で完了できる見込みはない。上限を自動変更せず、準備・採点枠の延長または保留をユーザーへ提示する。見送り済みの追加レビューは再起動しない。
