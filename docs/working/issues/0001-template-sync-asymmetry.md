# Issue-0001: template 同期の非対称性

- **Status**: closed
- **Opened**: 2026-06-15
- **Closed**: 2026-07-04
- **関連**: ADR-0027

## 課題内容

`sync-template.ps1` は ADRインデックス（旧 `docs/decisions/README.md`）を空生成するが、振り返りインデックス（旧 `docs/retrospectives/README.md`）は repo固有の振り返り履歴行ごと verbatim コピーしてしまう。両インデックスとも新規プロジェクトでは空で始まるべきだが扱いが不揃い（発生源: Theme B コードレビュー, 2026-06-15。旧 `docs/open-questions.md` から移行）。

## 検討状況

フォルダ構成定義サイクル（2026-07-04）で、テンプレート初期セットの基準を定義する際に合わせて検討した。

## 結論

ADR-0027 で空インデックス生成ロジックを一般化し、decisions / retrospectives / issues の3インデックスすべてを空生成する方式に統一して解消した。
