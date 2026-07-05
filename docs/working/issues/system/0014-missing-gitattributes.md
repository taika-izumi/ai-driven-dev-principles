# Issue-0014: .gitattributes がなく改行正規化が各自の core.autocrlf 設定任せ

- **Status**: closed
- **Opened**: 2026-07-05
- **Closed**: 2026-07-05
- **起票元**: retrospectives/system/2026-07-05-sync-template-line-endings.md 課題#1
- **関連**: ADR-0033、Issue-0002（closed）

## 課題内容

リポジトリに .gitattributes がなく、テキストファイルの改行正規化が各貢献者のローカル git 設定（core.autocrlf）に依存している。現環境（core.autocrlf=input）では LF が保たれるが、別環境の貢献者が CRLF のままコミットすると、Issue-0002 と同種の改行ノイズが再発しうる。ADR-0033 では本件をスコープ外と明記済み（要約。事象/原因/影響の詳細は起票元参照）。

改善余地の見込み（前サイクル担当エージェントの所見）: `.gitattributes` に `* text=auto` を追加し一度だけ `git add --renormalize .` を実行すれば、以後はコミット時に git 側で LF 正規化が強制される。コストは一度きりの正規化差分のみ。

検討時の追加観点（rubber-duck レビュー指摘）: template/ 配下は下流プロジェクトへ配布される側のため、「配布物としての .gitattributes を template に含めるか（= 下流プロジェクトにも同じ正規化を配るか）」も併せて判断すること。

## 検討状況

- 2026-07-05: 対策サイクル着手。現状調査で index は既に全ファイル LF であり、renormalize 差分はゼロと確認。正規化ルール3案と template 配布可否をユーザーへ提示し、`* text=auto` のみ・template へは配布しない、で確定（ADR-0037）

## 結論

ADR-0037 として決定・実装（closed）。`.gitattributes`（`* text=auto`）を追加し `git add --renormalize .` を実行（差分ゼロ）。CRLF ファイルが index で LF 正規化されることを使い捨てファイルで実機検証済み。template への配布は ADR-0027 のシード基準に該当しないため行わない。
