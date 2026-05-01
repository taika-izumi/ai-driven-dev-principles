# ADR-0010: 開発サイクル末尾の振り返りフェーズ導入

- **Status**: Accepted
- **Date**: 2026-05-01

## Context

本リポジトリではサブプロジェクトA（記録の強化）/ B（機能ブロック駆動の設計）と段階的にメタ・ガイドラインを成熟させてきた。しかし各サイクル終了時に得られる以下の知見が体系的に記録されていない:

1. 計画通りに進んだ点・うまくいったプラクティス
2. 苦労した点・手戻りの原因
3. 古びない技術ノウハウ（ツール挙動、罠など）
4. ガイドライン・スキル・原則への改善提案

これらは会話ログや handoff の片隅に断片的に残るのみで、次サイクル開始時に系統的に活用される保証がない。原則5「漸進的検証」はマイルストーン単位の検証を要求するが、サイクル全体を俯瞰する検証フェーズが欠けていた。

## Decision

`retrospective` スキルを新設し、サブプロジェクトクローズ時（feature ブランチを master へマージし handoff を completed 状態へ遷移する直前）の標準ステップとする。

スキルは以下の手順を持つ:

1. **Phase 0**: 対象 plan / spec / git log / handoff / 関連 ADR を読み込み
2. **Phase 1**: 5観点（Done / Went Well / Struggled / Tech Notes / Improvement Drafts）を1問ずつヒアリング
3. **Phase 2**: ドラフト保存
4. **Phase 3**: rubber-duck サブエージェントによる独立視点レビュー（1回）
5. **Phase 4**: 採用判断された改善提案を ADR-0006 に従い即時 ADR ドラフト化（実装は次セッション）
6. **Phase 5**: handoff 更新

実行は手動（ユーザー明示指示、または start-work が「直近 merge があり対応 retrospective 未作成」を検知して推奨）。

## Alternatives Considered

- **start-work 内蔵化（自動トリガー方式）**: merge 検知ロジックの偽陽性/陰性リスクがあり、start-work が肥大化する。原則2（関心の分離）に反する。
- **superpowers:finishing-a-development-branch 拡張**: 上流スキルへの依存が増え、本リポジトリの独立性が下がる。

## Consequences

- 各サイクル末尾に振り返りという1ステップが追加される（数十分〜1時間規模）。負担増だが、知見蓄積と次サイクル質向上の効果が上回る想定
- 振り返り出力ファイルが新たに `docs/retrospectives/` に蓄積される。保管規約は ADR-0011 で別途定義
- 振り返り中の採用判断は ADR-0006（即時検出ルール）の対象。`decision-log` スキルの検出トリガー一覧にも追記する
- start-work Phase 2 マッピング表に「サブプロジェクトクローズ直後」行が追加される

## Related

- spec: `docs/specs/2026-05-01-retrospective-design.md`
- ADR-0011: 振り返り出力の保管規約
- ADR-0012: ドメイン知識抽出は次サイクル課題
- 関連スキル: start-work, decision-log, session-handoff
