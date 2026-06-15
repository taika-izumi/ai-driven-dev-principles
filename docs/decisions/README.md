# Architecture Decision Records

このプロジェクトにおける重要な意思決定の記録。

ADRの判断基準: 「迷って選んだもの」はすべてADR候補。迷わなかったもの（自明な選択）はADR不要。

| # | タイトル | ステータス | 日付 |
|---|---------|-----------|------|
| [0001](0001-adopt-layered-guidelines.md) | レイヤード方式のガイドライン構成を採用 | Accepted | 2026-04-12 |
| [0002](0002-add-contributing-and-gateway-skill.md) | コンテキスト継続性のためのCONTRIBUTING.mdとゲートウェイSkillの追加 | Accepted | 2026-04-13 |
| [0003](0003-template-folder-and-manifest-sync.md) | テンプレートフォルダとマニフェスト同期方式の採用 | Accepted | 2026-04-13 |
| [0004](0004-introduce-start-work-skill.md) | ワークフロー起点スキル（start-work）の導入 | Accepted | 2026-04-27 |
| [0005](0005-adopt-handoff-file-scheme.md) | セッション継続のためのハンドオフファイル方式の採用 | Accepted | 2026-04-27 |
| [0006](0006-continuous-adr-detection-rule.md) | 意思決定の継続検出ルールの導入 | Accepted | 2026-04-27 |
| [0007](0007-introduce-feature-block-design-skill.md) | 機能ブロック駆動の設計スキル（feature-block-design）の導入 | Accepted | 2026-05-01 |
| [0008](0008-adopt-spec-directory-split-and-snapshot-rule.md) | 仕様書のディレクトリ分割形式とスナップショット規約の採用 | Accepted | 2026-05-01 |
| [0009](0009-extend-principle-2-scope.md) | 原則2「関心の分離」の適用範囲拡張 | Accepted | 2026-05-01 |
| [0010](0010-introduce-retrospective-phase.md) | 開発サイクル末尾の振り返りフェーズ導入 | Accepted | 2026-05-01 |
| [0011](0011-retrospective-storage-policy.md) | 振り返り出力の保管規約（時系列追記型） | Accepted | 2026-05-01 |
| [0012](0012-domain-knowledge-out-of-scope-for-c.md) | ドメイン知識抽出は次サイクル課題 | Accepted | 2026-05-01 |
| [0013](0013-introduce-knowledge-distillation-skill.md) | knowledge-distillation スキル新設 | Proposed | 2026-05-01 |
| [0014](0014-parent-dir-check-before-file-create.md) | 新規ファイル作成時の親ディレクトリ先行確認 | Proposed | 2026-05-01 |
| [0015](0015-distribute-skills-as-copilot-cli-plugin.md) | スキル群を Copilot CLI プラグインとして配布（公式プラグイン化 + dev-link ハイブリッド） | Accepted | 2026-05-04 |
| [0016](0016-redesign-template-workflow-plugin-only.md) | template ワークフローの再設計（skills/ を除外し、プラグイン一本化） | Accepted | 2026-05-04 |
| [0017](0017-correct-local-marketplace-registration.md) | ローカル開発時のプラグイン登録方式を `copilot plugin marketplace add <path>` に修正 | Accepted | 2026-05-04 |
| [0018](0018-mandate-brainstorming-for-medium-or-multi-option-work.md) | 中規模以上 / 複数解決策の作業着手前に brainstorming skill 必須化 | Proposed | 2026-05-05 |
| [0019](0019-adr-authoring-discipline.md) | ADR記述規律 — 決定のみ記載・未決事項の分離・承認の遅延昇格 | Accepted | 2026-06-15 |
| [0020](0020-retire-responding-to-user-enforcement.md) | responding-to-user スキルの必須化を廃止し ask-user-enforcer プラグインを撤去 | Accepted | 2026-06-15 |
