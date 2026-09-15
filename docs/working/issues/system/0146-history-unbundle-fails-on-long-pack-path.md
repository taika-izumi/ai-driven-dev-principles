# Issue-0146: 独立履歴の復元（git bundle unbundle）が run 配下のパックファイルパスが 260 文字に達すると失敗し、runsRoot の深さの制約が明文化されていない

- **Status**: open
- **Opened**: 2026-09-15
- **起票元**: 隔離検証 v3 実装計画のタスク1 実装時の実装者報告（計画逸脱判断の既定「計画の範囲外の既存欠陥」として起票。`docs/working/plans/2026-09-14-isolated-verification-v3-implementation.md` タスク1 の逸脱記録行）
- **関連**: `scripts/verification/RequestCopy.psm1` の `Initialize-VerificationHistory` / `Invoke-VerificationGit`（v1 共有経路）/ ADR-0150（Git 履歴の独立コピー）/ `scripts/verification/tests/RequestCopyV3.Tests.ps1`（試験名を 8 文字以下に制限して回避）

## 課題内容

`Initialize-VerificationHistory` は原本の Git 履歴を bundle → unbundle で baseline へ復元する。unbundle が書く `baseline/.git/objects/pack/pack-<40hex>.pack` の絶対パスが Windows の既定上限 260 文字に達すると、`git bundle unbundle` が `Filename too long` で失敗し、準備が `history import failed` で止まる。

2026-09-15 の実測: worktree `D:\Dev\002_AiDev\MakeAiInstructions\.worktrees\isolated-verification\.tmp\verification-tests\`（93 文字）を runsRoot にした試験で、試験名（run ディレクトリ名の一部）が 9 文字以上だと再現し、8 文字以下で通った。既存 v1 試験の `history`（257 文字）・`attached`（258 文字）も上限の直前にある。master 直下（`.worktrees/…` を含まない約 60 文字）では余裕がある。

利用者が設定する `runsRoot` が深い場合、v1・v3 のどちらでも同じ失敗が起きる。仕様01・README には runsRoot の深さの制約が書かれていない。

## 対策候補（未採用）

- `Invoke-VerificationGit` の固定引数に `-c core.longpaths=true` を足す（v1 共有経路の変更。Git 側の長パス対応に依存し、PowerShell 側の `File.Copy` 等が同じ上限に触れないかは別に確認が要る）
- README に runsRoot の深さの制約（目安の文字数）を既知の制約として書く
- run 配置の深さを浅くする（仕様01 の配置の変更を伴う）

## 検討状況

- 2026-09-15: 起票。計画逸脱判断の既定に従い、実装サイクル中は製品を変えず試験側の回避（試験名 8 文字以下）と記録にとどめた。v3 の後続タスク（`replay-inputs/after/.verification-tests/…`、`control/replay/<role>/<commandId>.json`）でも同じ上限に触れうるため、各タスクの試験は短い run 名を使う。対策の採否・設計は次サイクル以降のユーザー判断

## 結論

（open）
