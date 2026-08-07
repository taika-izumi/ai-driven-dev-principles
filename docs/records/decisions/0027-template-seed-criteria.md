# ADR-0027: テンプレート初期セットの基準を定義し、インデックス空生成を一般化する

- **Status**: Accepted
- **Date**: 2026-07-04

## Context

新フォルダレイアウト（ADR-0025）では種別サブフォルダのオンデマンド作成を規約とするが、これを template にそのまま適用すると、新規プロジェクトのセットアップ直後に docs/ の骨格がほとんど存在しない状態になる。ユーザーから「どのようなタイプのプロジェクトでも使う可能性が高いフォルダはテンプレートに含めたい（decisions、issues など）」との要望があった。

また、既知課題として「インデックス同期の非対称性」がある: `sync-template.ps1` は ADR インデックスを空生成する一方、retrospectives の README は repo 固有の履歴行ごと verbatim コピーしてしまう（旧 `docs/open-questions.md` 記載、2026-06-15 検出）。

## Considered Alternatives

1. **オンデマンド規約を template にも厳格適用（シードなし）** — 一貫性はあるが、新規プロジェクトで各スキルが初回実行されるまで骨格が見えず、ユーザーが直接使うフォルダ（issues, inbox）の存在に気づけない
2. **全分類フォルダを .gitkeep で先行作成** — 骨格は見えるが、使われないフォルダも量産され、オンデマンド規約と全面的に矛盾する
3. **基準を設けて選択的にシード** — ユーザーが直接操作するフォルダと、インデックスの継続性が必要なフォルダのみ含める

## Decision

案3を採用し、テンプレート初期セットの基準を以下と定める:

- **シードする**: (a) ユーザーが直接ファイルを置く・参照するフォルダ（`docs/working/issues/`、`docs/inbox/`）、(b) 空のインデックスが最初から必要なフォルダ（`docs/records/decisions/`、`docs/records/retrospectives/`）
- **シードしない**: スキルが実行時に自動作成するフォルダ（`docs/working/handoff/`、`docs/working/plans/`、`docs/current/specs/` 等）

実現方法:

- `template.manifest` は verbatim コピー対象（`CLAUDE.md`、`docs/overview/principles.md`、`docs/overview/folder-structure.md`、`docs/inbox/README.md`）のみを列挙する
- `sync-template.ps1` の空インデックス生成ロジックを一般化し、`docs/records/decisions/README.md`・`docs/records/retrospectives/README.md`・`docs/working/issues/README.md` の3ファイルに適用する（説明文は保持し、インデックス行のみ除去）。これにより retrospectives の非対称性（既知課題）も解消する
- `docs/inbox/README.md` は inbox の使い方（迷ったらここに置く、organize-inbox が処理する）を説明する汎用文書としてリポジトリに実体を持ち、verbatim コピーする

## Consequences

- 新規プロジェクトのセットアップ直後から、課題管理・ADR・振り返り・inbox の受け皿が見える状態になる
- 3つのインデックスすべてが新規プロジェクトで空から始まり、既知課題「インデックス同期の非対称性」が解消される（該当課題は closed として記録する）
- シード判断に迷う新フォルダが将来増えた場合は、本ADRの基準（ユーザー直接操作 or インデックス継続性）で判定する
- sync-template.ps1 の空生成ロジックが対象ファイルの構造（インデックス表・リスト）に依存するため、インデックスのフォーマット変更時はスクリプトの追従が必要になる

- **部分修正（2026-08-08・ADR-0083）**: 本 ADR の実現方法のうち、**同期が内容を変えないことを前提にした 2 つの記述が適用されなくなった**。配布先で解決できない参照を配布物へ残さないため、`sync-template.ps1` は同期の全対象へ出所識別子の除去を適用する。
  - 「説明文は保持し、インデックス行のみ除去する」— 保持した説明文からも出所識別子を除去する。除去はトークン単位に限らず、**出所リスト行は行ごと削除され、節が空になれば見出しも消える**
  - 「verbatim コピー対象」「verbatim コピーする」— `template.manifest` 記載ファイルも変換を通る（2026-08-08 実測では 4 ファイル中 `docs/overview/folder-structure.md` の 1 件が実際に変化し、末尾の関連決定の節が見出しごと除去された）
  
  **シード基準（何をテンプレートに含めるか）と空インデックス生成そのものの規約は変わらない**。除去は空インデックス化の後段で行われるため、判定・変換の対象は空インデックス化後の内容である。Status は Accepted のまま維持する（本体は現役で、変わったのは実現方法の適用範囲のみ）
