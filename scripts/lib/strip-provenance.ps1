# scripts/lib/strip-provenance.ps1
# 配布対象ソースの出所識別子を判定・除去する共有ライブラリ。
# build-dist.ps1 と sync-template.ps1 が dot-source して使う唯一の実装（ADR-0083）。

Set-StrictMode -Version Latest

# --- 正規表現（spec 02「判定に用いる正規表現」と一致させること） ---
$script:ReType13    = '(?<![A-Za-z0-9])(?:[A-Za-z][A-Za-z0-9]*#)?(?:ADR|Issue)-\d{4}'
$script:ReType4     = '(?<![A-Za-z0-9])(?:[A-Za-z][A-Za-z0-9]*)?-20\d\d-\d\d-\d\d(?:-\d\d)?'
$script:ReType5     = '（出所[:：][^）]*）'
$script:ReNeutral   = '^(?:X|Proj|<project>)$'
$script:ReListColon = '^\s*[-*]\s*(?:[A-Za-z][A-Za-z0-9]*#)?(?:ADR|Issue)-\d{4}(?:\s*[/〜]\s*\d{4})*\s*[:：]'
$script:ReListHead  = '^\s*[-*]\s*(?:[A-Za-z][A-Za-z0-9]*#)?(?:ADR|Issue)-\d{4}'

function Get-IdentifierMatch {
    param([string]$Line)
    $result = New-Object System.Collections.Generic.List[object]
    foreach ($m in [regex]::Matches($Line, $script:ReType13)) {
        $result.Add([pscustomobject]@{ Start=$m.Index; Length=$m.Length; Text=$m.Value })
    }
    foreach ($m in [regex]::Matches($Line, $script:ReType4)) {
        $prefix = ($m.Value -split '-20')[0]
        if ($prefix -match $script:ReNeutral) { continue }   # 中立名は対象外（spec 01）
        $result.Add([pscustomobject]@{ Start=$m.Index; Length=$m.Length; Text=$m.Value })
    }
    # `,(...)` ではなく `,@(...)` にすること。空パイプラインを `,(...)` で包むと関数の戻り値が
    # $null になり、呼び出し側の .Count が Set-StrictMode 下で PropertyNotFoundException を投げる。
    return ,@($result | Sort-Object Start)
}

function Test-InsideParen {
    param([string]$Line, [int]$Index)
    $before = $Line.Substring(0, $Index)
    return ($before.LastIndexOf('（') -gt $before.LastIndexOf('）'))
}

# 判定順序は spec 02「判定順序」と一致させること。
# 戻り値: 'none' | 'ok' | 'listline' | 'R2' | 'R3' | 'R4'
function Get-LineVerdict {
    param([string]$Line, [bool]$InFence)

    # 種別 5 は括弧そのものが識別子。ステップ 5 の内側判定のためマスクする。
    $masked = [regex]::Replace($Line, $script:ReType5, { param($m) '（' + ('x' * ($m.Value.Length - 2)) + '）' })
    $ids = Get-IdentifierMatch -Line $masked
    $hasType5 = [regex]::IsMatch($Line, $script:ReType5)

    if ($ids.Count -eq 0 -and -not $hasType5) { return 'none' }
    if ($InFence) { return 'R4' }
    if ($Line -match $script:ReListColon) { return 'listline' }
    if ($Line -match $script:ReListHead)  { return 'R3' }
    foreach ($id in $ids) {
        if (-not (Test-InsideParen -Line $masked -Index $id.Start)) { return 'R2' }
    }
    return 'ok'
}

function Invoke-StripProvenanceSelfTest {
    $cases = @(
        # 判定（適合）
        @{ Kind='judge'; Line='記録先へ1行残す（ADR-0057）';                                  Expect='ok' }
        @{ Kind='judge'; Line='- ADR-0044: 記録ゲート・スキル1/2 責務境界';                    Expect='listline' }
        @{ Kind='judge'; Line='- ADR-0048/0049/0051: 読み側互換（model 材料）';               Expect='listline' }
        @{ Kind='judge'; Line='…テスト運用出所のため（出所: LoopForAlpha）';                   Expect='ok' }
        # 判定（違反）
        @{ Kind='judge'; Line='出力ファイルは ADR-0011（時系列追記型）に従い';                  Expect='R2' }
        @{ Kind='judge'; Line='- ADR-0006（意思決定の継続検出ルール）は常時適用される';          Expect='R3' }
        # プレースホルダ・中立名（対象外）
        @{ Kind='judge'; Line='- **関連**: ADR-NNNN 等（あれば）';                            Expect='none' }
        @{ Kind='judge'; Line='- 書式: `<repo>#Issue-NNNN`（例: `OtherProject#Issue-NNNN`）'; Expect='none' }
        @{ Kind='judge'; Line='{"v":2,"id":"X-2026-07-16-01","outcome":"adopted"}';           Expect='none' }
        # 種別 4（省略形を含む）
        @{ Kind='judge'; Line='（指示が 2 回。LoopForAlpha-2026-07-22-09 / -2026-08-01-03）'; Expect='ok' }
        @{ Kind='judge'; Line='2026-08-05 の走査委譲（118 件全数）で有効性を実測';              Expect='none' }
    )
    $fail = 0
    foreach ($c in $cases) {
        $actual = Get-LineVerdict -Line $c.Line -InFence:$false
        if ($actual -ne $c.Expect) {
            Write-Host "  FAIL expect=$($c.Expect) actual=$actual :: $($c.Line)"
            $fail++
        }
    }
    if ($fail -gt 0) { Write-Host "[strip-provenance] self-test: $fail case(s) failed"; return $false }
    Write-Host "[strip-provenance] self-test: all $($cases.Count) cases passed"
    return $true
}
