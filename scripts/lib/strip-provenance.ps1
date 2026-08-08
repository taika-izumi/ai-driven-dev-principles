# scripts/lib/strip-provenance.ps1
# 配布対象ソースの出所識別子を判定・除去する共有ライブラリ。
# build-dist.ps1 と sync-template.ps1 が dot-source して使う唯一の実装（ADR-0083）。

Set-StrictMode -Version Latest

# --- 正規表現（spec 02「判定に用いる正規表現」と一致させること） ---
$script:ReType13    = '(?<![A-Za-z0-9])(?:[A-Za-z][A-Za-z0-9]*#)?(?:ADR|Issue)-\d{4}'
$script:ReType4     = '(?<![A-Za-z0-9])(?:[A-Za-z][A-Za-z0-9]*)?-20\d\d-\d\d-\d\d(?:-\d\d)?'
$script:ReType5     = '（出所[:：][^）]*）'
# 中立名の許可リスト。`<project>` は入れない（種別 4 の正規表現がプロジェクト名部に
# 英数字始まりを要求するため `<project>-2026-01-01-01` は接頭辞なしと解釈され、
# ここへ来る値が空文字列になる。書いても到達しない。実測で確認済み）
$script:ReNeutral   = '^(?:X|Proj)$'
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

function Remove-ProvenanceFromLine {
    param([string]$Line)

    # 行頭のインデントは掃除規則の対象外にする（Markdown のネストが潰れるため）
    $indent = [regex]::Match($Line, '^[ 　\t]*').Value
    $body   = $Line.Substring($indent.Length)

    # 種別 5: 括弧を中身ごと削除
    $out = [regex]::Replace($body, $script:ReType5, '')

    # 種別 1〜4: **バッククォートで囲まれた識別子は囲みごと除去する。**
    # 識別子だけを外すと空の対（`` の 2 連）が残り、後段の掃除では消せない。
    # PowerShell の単一引用符内ではバッククォートがエスケープにならないため、
    # '``(?=`)' のような書き方は「2 連＋直後にもう 1 つ」を要求してしまい意図どおり動かない
    # （実測。むしろコードフェンスの 3 連に一致する）。[char]96 で組み立てること。
    $bt = [char]96
    # 桁のみの継続形（ADR-0048/0049/0051 の 2 件目以降）は ReListColon と同じ形で吸収する。
    # 付けないと裸の 4 桁（0049/0051）が残る（実測）。
    $pattern13 = $script:ReType13 + '(?:\s*[/〜]\s*\d{4})*' + '(?:\s*項目[\d/]+)?'
    $out = [regex]::Replace($out, "$bt$pattern13$bt", '')
    $out = [regex]::Replace($out, "$bt$($script:ReType4)$bt", { param($m)
        $prefix = (($m.Value.Trim([char]96)) -split '-20')[0]
        if ($prefix -match $script:ReNeutral) { return $m.Value }   # 中立名は残す
        return ''
    })

    # 続いて、囲まれていない識別子を除去する
    $out = [regex]::Replace($out, $pattern13, '')
    $out = [regex]::Replace($out, $script:ReType4, { param($m)
        $prefix = ($m.Value -split '-20')[0]
        if ($prefix -match $script:ReNeutral) { return $m.Value }   # 中立名は残す
        return ''
    })

    # 除去で生じた区切りの残骸を掃除（行頭インデントは $body に含まれないので影響しない）
    # 括弧に隣接する区切りは反復で落とす。1 個しか落とさないと括弧内に識別子が 2 つ以上あるとき
    # 残骸が出て、冪等性も壊れる（実測）。
    # 識別子の間に取り残された区切りの連続（`。 / 。` `。。` など）を先頭 1 個へ畳む。
    # 先頭の `(?<!:[。、・/〜])` は URL の `://` を守るためのもの（skills/ に URL は無いが、
    # sync-template.ps1 は docs/ 配下へも同じ変換を掛けるため）。
    $out = [regex]::Replace($out, '(?<!:[。、・/〜])(?<=[。、・/〜])\s*(?:[。、・/〜]\s*)+', '')
    # 量化子は `+` ではなく `*`。`+` にすると区切りを伴わない残骸（`（Issue-0034 の…` →
    # `（ の…` の先頭空白）が落ちなくなる。旧実装の `?` はこれを落としていたので `+` は退行になる（実測）。
    $out = [regex]::Replace($out, '（\s*(?:[。、・/〜]\s*)*', '（')
    $out = [regex]::Replace($out, '\s*(?:[。、・/〜]\s*)*）', '）')
    $out = $out -replace '（）', ''
    return ($indent + $out.TrimEnd())
}

function ConvertTo-LfContent {
    param([string]$Content)
    return ($Content -replace "`r`n", "`n" -replace "`r", "`n")
}

function Test-ProvenanceConvention {
    param([string]$Content, [string]$Path)
    $Content = ConvertTo-LfContent -Content $Content   # ソース側の CRLF に依存しない（ADR-0033）
    $violations = New-Object System.Collections.Generic.List[object]
    $isScript = $Path -match '\.(py|ps1)$'
    $inFence = $false
    $i = 0
    foreach ($line in ($Content -split "`n")) {
        $i++
        if (-not $isScript -and $line.TrimStart().StartsWith('```')) { $inFence = -not $inFence; continue }
        if ($isScript -and -not $line.TrimStart().StartsWith('#')) { continue }
        $v = Get-LineVerdict -Line $line -InFence:$inFence
        if ($v -in @('R2','R3','R4')) {
            $violations.Add([pscustomobject]@{ Line=$i; Rule=$v; Text=$line.Trim() })
        }
    }
    # `,@($violations)` と書かないこと。List に `@()` を掛けたものへ単項カンマを適用すると
    # 「Argument types do not match」で失敗する（実測）。`.ToArray()` が最も曖昧さがない。
    # 呼び出し側も `@(Test-ProvenanceConvention ...)` と書かないこと。単項カンマで包んだ戻り値へ
    # さらに `@()` を掛けると二重配列になり、`.Count` が要素数によらず常に 1 になる。単純代入で受けること。
    return ,$violations.ToArray()
}

# 残存識別子の検査（build-dist.ps1 の自己検査・-Check の共通実装。ADR-0083）。
# Test-ProvenanceConvention と同じ適用範囲（.py/.ps1 はコメント行のみ、それ以外はフェンス外のみ）
# を使うが、検出対象は種別 1〜4（Get-IdentifierMatch。中立名除外込み）に加えて種別 5
# （`（出所: …）`）も含める。自己検査が種別 5 を見ていないと、掃除規則の対象外（変換しない）
# 行に残った `（出所: …）` が exit=0 のまま出荷される（実測）。
function Get-ProvenanceLeak {
    param([string]$Content, [string]$Path)
    $Content = ConvertTo-LfContent -Content $Content
    $leaks = New-Object System.Collections.Generic.List[object]
    $isScript = $Path -match '\.(py|ps1)$'
    $inFence = $false
    $i = 0
    foreach ($line in ($Content -split "`n")) {
        $i++
        if (-not $isScript -and $line.TrimStart().StartsWith('```')) { $inFence = -not $inFence; continue }
        if ($inFence -or ($isScript -and -not $line.TrimStart().StartsWith('#'))) { continue }
        $hasType5 = [regex]::IsMatch($line, $script:ReType5)
        if ((Get-IdentifierMatch -Line $line).Count -gt 0 -or $hasType5) {
            $leaks.Add([pscustomobject]@{ Line=$i; Text=$line.Trim() })
        }
    }
    # Test-ProvenanceConvention と同じ理由で `.ToArray()` に単項カンマを掛ける（`,@(...)` は不可）。
    return ,$leaks.ToArray()
}

function Remove-ProvenanceNotation {
    param([string]$Content, [string]$Path = '')
    $Content = ConvertTo-LfContent -Content $Content
    $isScript = $Path -match '\.(py|ps1)$'
    $out = New-Object System.Collections.Generic.List[string]
    $droppedAfter = New-Object System.Collections.Generic.HashSet[int]   # 出所リスト行を削除した直前の出力位置
    $inFence = $false
    $lines = $Content -split "`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if (-not $isScript -and $line.TrimStart().StartsWith('```')) { $inFence = -not $inFence; $out.Add($line); continue }
        if ($inFence -or ($isScript -and -not $line.TrimStart().StartsWith('#'))) { $out.Add($line); continue }
        $verdict = Get-LineVerdict -Line $line -InFence:$false
        if ($verdict -eq 'listline') {
            [void]$droppedAfter.Add($out.Count)   # この位置の直後で 1 行落ちた
            continue
        }
        # 変換は識別子を含む行（'ok'）だけに限定する。掃除規則は spec 02 §4 の
        # 「括弧内の識別子はトークンと隣接する区切りとともに除去する」文脈でのみ働くべきもので、
        # 識別子と無関係な行へ掛けると表の桁揃え・末尾スラッシュ・行末 2 空白の強制改行が壊れる（実測）。
        if ($verdict -eq 'ok') { $out.Add((Remove-ProvenanceFromLine -Line $line)) }
        else                   { $out.Add($line) }
    }
    # 以降 2 パスは Markdown の整形であり、スクリプトへは掛けない
    # （PEP 8 の二重空行を潰すため。check-store-health.py で 8 箇所の実害を確認）
    if ($isScript) { return ($out -join "`n") }

    # 出所リスト行を実際に削除した節に限り、空になった見出しを畳む
    # （無条件に「見出しの次が見出しなら削除」とすると、もともと見出しが連続する箇所を壊す）
    $final = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $out.Count; $i++) {
        if ($out[$i] -match '^#{2,}\s') {
            $j = $i + 1
            while ($j -lt $out.Count -and $out[$j].Trim() -eq '') { $j++ }
            $sectionLostLine = $false
            for ($k = $i + 1; $k -le $j; $k++) { if ($droppedAfter.Contains($k)) { $sectionLostLine = $true; break } }
            if ($sectionLostLine -and ($j -ge $out.Count -or $out[$j] -match '^#{2,}\s')) { $i = $j - 1; continue }
        }
        $final.Add($out[$i])
    }
    # 連続空行を 1 行へ（フェンス内は対象外。コードフェンス内の二重空行（PEP 8 的な空行など）を
    # 無条件に保持するため、フェンス状態を追跡してフェンス内・フェンス境界行はそのまま通す。
    # これを追跡しないと、識別子を含まない .md のフェンス内二重空行まで畳まれる（実測）。
    $collapsed = New-Object System.Collections.Generic.List[string]
    $prevBlank = $false
    $inFence2 = $false
    foreach ($l in $final) {
        if ($l.TrimStart().StartsWith('```')) { $inFence2 = -not $inFence2; $collapsed.Add($l); $prevBlank = $false; continue }
        if ($inFence2) { $collapsed.Add($l); $prevBlank = $false; continue }
        $blank = ($l.Trim() -eq '')
        if ($blank -and $prevBlank) { continue }
        $collapsed.Add($l); $prevBlank = $blank
    }
    return ($collapsed -join "`n")
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
    $convert = @(
        @{ In='記録先へ1行残す（ADR-0057）。';                         Out='記録先へ1行残す。' }
        @{ In='規範（ADR-0073。条件の追加は観測が根拠）を守る';          Out='規範（条件の追加は観測が根拠）を守る' }
        @{ In='…出所のため（出所: LoopForAlpha）';                     Out='…出所のため' }
        @{ In='- **関連**: ADR-NNNN 等（あれば）';                     Out='- **関連**: ADR-NNNN 等（あれば）' }
        # バッククォートで囲まれた識別子（囲みごと消えること。空の対が残らないこと）
        @{ In=('（実測: 取り逃していた。' + [char]96 + 'LoopForAlpha-2026-07-19-05' + [char]96 + '）'); Out='（実測: 取り逃していた）' }
        @{ In=('サンプル ' + [char]96 + 'X-2026-01-01-01' + [char]96 + ' は中立名なので残す');          Out=('サンプル ' + [char]96 + 'X-2026-01-01-01' + [char]96 + ' は中立名なので残す') }
    )
    foreach ($c in $convert) {
        $actual = Remove-ProvenanceFromLine -Line $c.In
        if ($actual -ne $c.Out) {
            Write-Host "  FAIL convert expect=[$($c.Out)] actual=[$actual]"
            $fail++
        }
    }

    # Get-ProvenanceLeak（種別 5 を含めた残存検査。フェンス内は対象外であること）
    $leakCases = @(
        @{ Content='本文（出所: LoopForAlpha）';                         Path='x.md'; Expect=1 }
        @{ Content='X-2026-01-01-01';                                  Path='x.md'; Expect=0 }
        @{ Content=('```' + "`n" + 'ADR-0001 in fence' + "`n" + '```'); Path='x.md'; Expect=0 }
    )
    foreach ($c in $leakCases) {
        $actual = (Get-ProvenanceLeak -Content $c.Content -Path $c.Path).Count
        if ($actual -ne $c.Expect) {
            Write-Host "  FAIL leak expect=$($c.Expect) actual=$actual :: $($c.Content)"
            $fail++
        }
    }

    # Remove-ProvenanceNotation（内容レベル）: フェンス内の二重空行は識別子ゼロなら完全不変であること
    # （I-4: フェンス外専用だった連続空行の畳み込みがフェンス内へ誤って効いていた問題の対照）
    $fencedDoubleBlank = @'
```
code1


code2
```
'@
    $contentCases = @(
        @{ In=$fencedDoubleBlank; Path='x.md' }
    )
    foreach ($c in $contentCases) {
        $actual = Remove-ProvenanceNotation -Content $c.In -Path $c.Path
        if ($actual -ne $c.In) {
            Write-Host "  FAIL content-unchanged expect=[$($c.In)] actual=[$actual]"
            $fail++
        }
    }

    if ($fail -gt 0) { Write-Host "[strip-provenance] self-test: $fail case(s) failed"; return $false }
    Write-Host "[strip-provenance] self-test: all $($cases.Count + $convert.Count + $leakCases.Count + $contentCases.Count) cases passed"
    return $true
}
