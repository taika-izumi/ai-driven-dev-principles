# 提案側へshell画像を流用し、Codex起動が成立しない

- **Status**: open
- **Created**: 2026-09-17
- **起票元**: Task9の承認済みモデル起動前確認、run ab0a2b42。
- **関連**: ADR-0200、2026-09-17-task9-model-roundtrip-approval.md、2026-09-17-task9-startup-image-mismatch.md。

## 課題

再実行用に確定したshell画像のdigestを提案側にも使っていた。Codexキットの認証・通信設定が成立しても、実行ファイルは画像に入らない。実VMのcommand -v codexが終了127、公開レジストリのflavorラベルがshellであることを確認した。

画像が異なれば能力証拠の固定対象も変わるため、先の提案VM2台の観測を新画像の検証済み証拠として使えない。起動確認をすべての試験の最初に置かなかったため、追加試験と利用者確認が必要になった。

## 修正候補

公式codex版をLinux amd64の固定digest b387e913...で指定し、新画像で保護条件と起動を確認する。replayは既存shell版を維持する。詳細な操作変更案は`docs/working/plans/2026-09-17-task9-codex-template-amendment.md`。画像取得・追加VMの承認は未取得。

## 完了条件

提案画像の版/実行ファイル、認証・通信・共有/SSH・資源・停止/復旧、非対話stdin/終了/出力の実測が揃い、proposal profileを推測のverifiedなしで生成できること。モデル往復全体の成功とは別に判定する。
