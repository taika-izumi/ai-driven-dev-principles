# Retrospective（簡易）: worklog 実運用堅牢化サイクル

- **日付**: 2026-07-18
- **対象**: feature/worklog-operational-hardening（merge `50bef04`）
- **形式**: 簡易版（Went Well / Struggled と課題抽出・分類のみ。対策設計・ADR 化は次サイクルへ委ねる。ADR-0021）

## Done

- Issue-0031: ADR-0048 の model 定義を「記録時」→「delta 発生元」へ in-place 訂正（store-format / worklog-record SKILL / spec 01・02 を統一）
- Issue-0030: 中央ストアの UTF-8/BOM なし/LF 契約・書き側手段・読み側 loud validation を追加（ADR-0054 Accepted）
- Issue-0024: start-work Phase -1 にスキル availability の AI 側判定規範を追加（ADR-0055 Accepted）
- Issue-0030/0031/0024 close

## Went Well

- 3 課題を軽量ブレストで論点 3 点に絞り、同一領域（worklog）で一括対処。対処候補が issue に既記だったため設計が速かった
- writing-plans の self-review で grep パターンの正規表現欠陥（`| open |`）を自分で発見・修正（ADR-0034 の整合チェック運用が機能）
- grep による実体確認で model 残存 0 件・issue closed・ADR Accepted を検証（ADR-0038）

## Struggled（課題抽出・分類・処遇）

- **A（flow・不起票）**: brainstorming の選択肢提示に「規範・契約だけで守る対策の被害規模／構造的 enforcement の要否」の観点が欠け、Q2 が実装中に方針転換した。Issue-0017 / ADR-0039 と隣接するが角度が異なる。ユーザー判断で今回は不起票
- **B（system・起票）**: worklog-extract の健全性検証の具体的検出手段（例コマンド）が未定義。→ **Issue-0032 起票**
- **C（flow・不起票）**: Accepted 済み ADR の in-place 改定（誤り訂正）の可否・注記フォーマットが未定義（Superseded/Rejected とは別軸）。頻度低。ユーザー判断で今回は不起票

## 処遇まとめ

- 起票: Issue-0032（system）のみ
- 不起票（ユーザー判断）: 課題 A・C。再発時に改めて検討する
