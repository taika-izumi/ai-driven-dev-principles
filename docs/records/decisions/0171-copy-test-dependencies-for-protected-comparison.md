# ADR-0171: 保護下の比較で使う検査依存を試験専用フォルダへコピーする

- **Status**: Accepted
- **Date**: 2026-09-10

## Context

比較準備の保護下で、元リポジトリ内の.venvにあるPythonを参照できなかった。拒否設定が子へ継承され、起動引数の調整だけでは解消しなかった。証拠は準備実施記録とcontrol/launch-packet/python-read-denial-acl.json。

2026-09-10、ユーザーは「検査用の依存だけ別配置して続ける」に「1で」と回答した。承認範囲は、既存Python本体を使い、必要な依存と配布メタデータをコピーすること。追加ダウンロード、通常環境へのインストール、手動のACL変更、モデル起動は含まない。

## Considered Alternatives

1. 既存Python 3.12本体と検査用依存のコピーを使う。元環境の拒否設定を変えずに、読み取り専用で利用できる経路を確かめられる。
2. 比較準備を保留する。追加作業を止められるが、既存の比較資材をまだ評価に使えない。

## Decision

案1を採用する。Python本体は `C:/Users/d12an/AppData/Local/Programs/Python/Python312/python.exe`。依存の配置先は `D:/Dev/002_AiDev/WorkflowTrials/model-discretion-python-20260910`。pytest、_pytest、pluggy、iniconfig、packaging、pygments、coloramaと必要な配布メタデータだけを元の.venvからコピーする。内容とハッシュを記録し、作成・採点側から依存コピーを変更できない状態で使う。

Pythonの隔離起動オプションと明示した検索パスでコピーを読み込み、通常ユーザーのsite-packagesや追加のpytestプラグインを自動ロードしない。元ソース・製品設定・会話・認証情報はコピーしない。

## Consequences

- 配置しただけで保護成立とはしない。コピーからのpytest起動、必要な既存テスト、許可内書き込みと依存への書き込み拒否を実測する。
- 成立しなければ同じ試行を重ねず、証拠を記録して次の進路を相談する。
- モデル、題材、合格条件、比較時間、起動前の個別承認は維持する。汎用の隔離基盤は追加しない。
