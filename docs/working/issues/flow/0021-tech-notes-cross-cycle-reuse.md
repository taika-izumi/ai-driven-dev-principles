# Issue-0021: Tech Notes の横断再利用（知見の蒸留・集約）の仕組みがない

- **Status**: open
- **Opened**: 2026-07-07
- **起票元**: ADR-0013 の Rejected 処理（初回台帳監査、feature/adr-rejected-status-path サイクル）
- **関連**: ADR-0013（Rejected。旧設計の記録）、ADR-0021（retrospective の課題抽出限定）、ADR-0025（参照知識の分類）、handoff 未着手タスク「Theme C 問題A: プロジェクト固有用語集」（隣接テーマだが対象が異なる: 本課題は技術知見、Theme C はドメイン用語）

## 課題内容

retrospective が蓄積する Tech Notes（古びない技術知見）は各サイクルの振り返りファイル（`docs/records/retrospectives/system/`）に分散しており、サブプロジェクトを跨いで知見を再利用するための横断検索・集約のメカニズムがない。件数の増加とともに、新規サイクル着手時に過去知見を網羅参照することは事実上不可能になる。

かつて ADR-0013（knowledge-distillation スキル新設）がこのテーマの対策として起票されたが、旧プロセス（retrospective 内の採否判断）由来であり、情報分類体系の刷新（ADR-0025。「参照知識」分類の新設）を経て設計前提が失われたため、初回台帳監査（2026-07-07）で Rejected とした。テーマ自体は有効なため本課題として再起票する。

着手時は現行フロー（`start-work` → brainstorming）で設計し直すこと。ADR-0025 の「参照知識」分類（`docs/reference/` 相当）と蒸留規則（追跡型の記録から再利用知識を別ドキュメントとして蒸留してよい）が設計の出発点になる。

## 検討状況

- 2026-07-31: ADR-0056 により retrospective の Tech Notes 観点自体を廃止し、スキル化に有用な知見は worklog パイプライン（record → extract → skillify）が捕捉・再利用する構造へ委譲。「Tech Notes の横断再利用の仕組み」は worklog-extract がその役割を担うため、本課題は解消方向。close の判断はユーザーに委ねる

## 結論

（open）
