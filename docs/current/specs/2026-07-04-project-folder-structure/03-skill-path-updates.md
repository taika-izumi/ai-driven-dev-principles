# ブロック03: skill-path-updates — 既存スキルのパス参照更新と未決事項運用の改訂

## 1. 対象ファイル

- `skills/session-handoff/SKILL.md`
- `skills/decision-log/SKILL.md`
- `skills/retrospective/SKILL.md`（`template.md` / `flow-template.md` 内のパス表記があれば含む）
- `skills/feature-block-design/SKILL.md`
- `skills/start-work/SKILL.md`（パス参照のみ。inbox 検知の追加はブロック02。適用順序は 03 → 02）

## 2. 責務

全スキルのパス参照を新フォルダレイアウトへ更新し、decision-log の「未決事項 → `docs/open-questions.md`」運用を「未決事項 → 課題（`docs/working/issues/`）」へ改訂する。

## 3. インターフェース（パス対応表）

全スキル共通で以下の置き換えを適用する:

| 旧パス | 新パス |
|--------|--------|
| `docs/handoff/<branch>.md` | `docs/working/handoff/<branch>.md` |
| `docs/plans/...` | `docs/working/plans/...` |
| `docs/specs/YYYY-MM-DD-<topic>/` | `docs/current/specs/YYYY-MM-DD-<topic>/` |
| `docs/decisions/NNNN-*.md`, `docs/decisions/README.md` | `docs/records/decisions/NNNN-*.md`, `docs/records/decisions/README.md` |
| `docs/retrospectives/system/`, `docs/retrospectives/flow/`, `docs/retrospectives/README.md` | `docs/records/retrospectives/system/`, `docs/records/retrospectives/flow/`, `docs/records/retrospectives/README.md` |
| `docs/open-questions.md` | 廃止（課題管理へ統合） |

## 4. サブ機能 / 内部構成（スキル別の変更内容）

### session-handoff

- ファイル配置を `docs/working/handoff/<branch-name>.md` に変更（それ以外の操作・フォーマットは不変）

### decision-log

- ADR 配置を `docs/records/decisions/` に変更
- 「未決事項（open questions）の扱い」セクションを全面改訂:
  - 分離先を `docs/working/issues/system|flow/NNNN-<slug>.md`（課題ファイル。フォーマットはブロック01 の定義に従う。system/flow 分割は ADR-0028）に変更
  - ライフサイクル: 未決事項を検出したら課題ファイルを起票（Status: open）→ 意思決定したら ADR を作成し課題を close（該当課題の「結論」に ADR 番号を記載）
  - スナップショット型 open-questions.md の「解決したら行を削除」規約は廃止。課題は closed のままその場に残る（追跡可能性の向上）
  - 課題インデックス `docs/working/issues/README.md` の行追加・Status 更新を手順に含める

### retrospective

- 出力先を `docs/records/retrospectives/system/` / `docs/records/retrospectives/flow/` に変更
- インデックス参照 `docs/records/retrospectives/README.md` に変更

### feature-block-design

- 出力ディレクトリ構造を `docs/current/specs/YYYY-MM-DD-<topic>/` に変更

### start-work

- セッション終了処理・Phase 内の `docs/retrospectives/...` `docs/handoff/...` 等の参照を新パスへ更新

## 5. データモデル

なし（課題ファイルのフォーマット定義はブロック01 が持つ。本ブロックは参照のみ）。

## 6. このブロック固有の制約・前提

- パス変更以外の手順・フォーマット・責務分担を変えない（機能変更を混ぜない）。唯一の例外は decision-log の未決事項セクション（ADR-0025 で決定済みの運用統合）
- CONTRIBUTING.md / CLAUDE.md 側の同種の記述更新はブロック04 の責務
- 本リポジトリの実フォルダ移行（ブロック06）と同一サイクル内で完了させる（スキルと実フォルダの不整合期間を作らない）

## 7. 関連 ADR

- ADR-0025（全面再配置・open-questions の課題統合）
- ADR-0019（未決事項の分離規律。分離先の変更後も規律は維持）
- ADR-0005（handoff 方式）、ADR-0008（spec ディレクトリ分割）、ADR-0011/0021（retrospective 保管規約）— いずれもパスのみ変更、規約自体は維持
