# v3実装前のsbx能力確認

2026-09-09 23:47。ユーザーの作業継続指示を受け、v3確定仕様の起動条件を読み取り確認した。製品設定・daemon・VMを変更せず、実モデルも起動していない。

## 実測

sbx 0.42.1のcreate/exec/settings/settings list/policy denyのヘルプを取得。settings list --all --jsonは、通常起動済みdaemonがrunningであることを確認してから実行した。抽出対象はclipboard、pids、ssh.agent、自動起動に関連する項目だけ。元のsecretストアや認証値は読んでいない。

| 要件 | 読み取りで確認できたこと | 判定 |
|---|---|---|
| ホストの画像clipboardを読まない | clipboard.imagePaste=false（既定） | 設定確認済み。動的な拒否試験は未実施 |
| ホストclipboardへの文字列書込拒否 | 書込は公式機能。全設定の関連抽出では画像読取設定だけ | 拒否機構を確認できずblocked |
| 子が緩和できないpids128 | createヘルプ、全設定でpids制御を確認できない | 外側強制機構が未確認でblocked |
| SSH転送拒否 | ssh.agentForwardingEnabled=true、socketPath空、再起動を要するメタデータあり | 現設定は許可。実転送の存在は未確認、変更未実施 |
| 停止後の自動起動防止 | settingsはdaemonを、execは停止VMを自動起動する旨がヘルプにある | 競合を含む制御方法の実証が必要 |
| 既存環境保全 | daemon running、VM iv-sbx-smoke-20260909-01/id de1ba0ac-ebb0-4cc4-a5f6-009dffd8baaeはstopped | 今回の読み取り前後で起動・設定変更操作なし |

## 提供元の根拠

- [隔離の説明](https://docs.docker.com/ai/sandboxes/security/isolation/): VM内プロセスからホストclipboardへ文字列を書けることを説明。
- [FAQ](https://docs.docker.com/ai/sandboxes/faq/): clipboard.imagePasteは画像読取のopt-in。これをfalseにしても文字列書込を拒否できるという根拠にはならない。
- [create参照](https://docs.docker.com/reference/cli/sbx/create/): CPU/メモリ等の操作を確認。pids制御は確認できない。
- [リリースノート](https://docs.docker.com/ai/sandboxes/release-notes/): 0.42.0にホストclipboardへの文字列コピー機能を記載。

すべて提供元の一次資料。検索と公開ヘルプにないことは、非公開機能まで含む不存在の証明ではない。Docker Engineの--pids-limitは別製品の実行契約なので、sbxにも使えると推定しない。

## 結論

先行計画2026-09-09-isolated-verification-v3-preflight.mdのタスク0〜2を実施したが、現仕様を満たすruntime profileはまだ作れない。主要な不足はclipboard文字列書込拒否とpidsの外側強制。SSH転送も許可設定のままで、変更するには影響を具体化した判断が必要。

現行仕様の起動前条件に従ってblockedとする。これは実装バグの検出でも、sbxが全面的に使用不能という証明でもない。保護要件・基盤変更や設定緩和はしていない。
