# ADR-0054: 中央ストアのエンコーディング・EOL 契約と追記手段・読み側検証を定める

- **Status**: Accepted
- **Date**: 2026-07-18

## Context

worklog パイプラインの中央ストア（`<home>/.ai-dev-worklog/<folderName>/log.jsonl`・集約 `processed.jsonl`・`projects.json`）は、以下の固有性を持つ:

- **リポジトリ外**にある。`.gitattributes` による改行正規化（ADR-0037）はリポジトリ内ファイルにしか効かず、このストアは管轄外
- **全プロジェクト・全プラットフォーム・全ツール共有**。別 OS・別ツールの既定追記が混ざりうる（例: Windows PowerShell 5.1 の `Add-Content`/`Out-File` 既定は UTF-16 や BOM 付き UTF-8）
- **追記専用 JSONL** を「単純連結して1パスで機械走査する」ことが設計根幹（ADR-0045）。BOM・CRLF・非 UTF-8 の混入はこの走査を壊す

現行の `worklog-record` は「1行 append」とだけ書き、ストアの文字コード・改行コード・具体的な追記手段を規定していない。`store-format.md` にもストアファイルのエンコーディング契約がない。worklog v1.1 のスモークテストでは BOM/CRLF 混入を避けるため `Add-Content -Encoding utf8NoBOM` を都度判断で選んだ（結果は正しかったが規約に基づく選択ではなかった）。この未定義が Issue-0030 として起票された。

追記専用ゆえ、外部ツールが不正エンコーディングで追記すると BOM は**ファイル頭ではなく追記チャンクの先頭（＝ファイル中途）に混入**しうる。被害はエントリ喪失ではなく「`worklog-extract` の1パス機械走査が誤パース/失敗する」までで回復可能だが、オンデマンド実行のため次回 extract まで**サイレントに滞留**する。

## Considered Alternatives

- **契約明記のみ（書き側規律のみ）**: 最小コスト。`worklog-record` 自身の書き込みはこれで抑えられるが、このスキルを経由しない外部ツール・別 OS の混入は検知できない。被害は回復可能だが滞留する
- **読み側で silent tolerance（黙って BOM 除去・CRLF 許容）**: 契約違反を隠し、混入源の検知を遅らせる。かつ追記専用で BOM は中途混入しうるため「頭 BOM 除去」では捕捉できない。**却下**（Issue-0030 検討時 Q2 で棄却）
- **読み側 loud validation（採用）**: `worklog-extract` の走査直前に検出し、あれば大きく報告して停止する。extract はユーザーがオンデマンド実行するため、人がいる場で違反を surface できる。silent tolerance と異なり違反を隠さない
- **独立監査スクリプトのみ**: 人が実行を覚えている必要があり、契約と同じ規律依存の失敗モードを持つ。明確な監査ツール要望が出るまでは YAGNI

## Decision

1. **契約明記**: ストアファイル（`log.jsonl` / `processed.jsonl` / `projects.json`）は **UTF-8・BOM なし・改行 LF 固定**。`store-format.md` に契約として明記する
2. **書き側手段の注記**: `worklog-record` の追記手順に、プラットフォーム別の安全な追記手段を注記する（PowerShell は `Add-Content -Encoding utf8NoBOM` で LF を明示、POSIX は `>>` リダイレクト）
3. **読み側 loud validation**: `worklog-extract` の1パス走査直前に、BOM・CRLF・非 UTF-8 を検出する検証ステップを置く。検出時は**報告して停止**し、既存行の正規化（BOM 除去・CRLF→LF）は**ユーザーの明示 opt-in でのみ**実行する。silent tolerance は採らない。正規化はエンコーディング/EOL のバイト正規化に限り、エントリ内容は不変とする（追記専用の内容不変原則・v1 行非書き換えと整合）

## Consequences

- **良い影響**: 外部混入を唯一のチョークポイント（extract の1パス走査）で自動捕捉できる。書き側は契約と手段注記で固定される。機械走査破損を予防できる
- **コスト・留意**: extract に検証ステップが1つ増える。既存行の正規化はバイト書き換えを伴うため明示 opt-in に限定する（黙って書き換えない）。ADR-0037（repo 内 EOL 固定）とは管轄が異なる（本 ADR は repo 外ストア）。ADR-0050 の「追記後の読み直し検証」と同じ実体確認の哲学の延長にある
- Issue-0030 は本 ADR で close する
