$p = Join-Path $PSScriptRoot 'workbench-desktop.html'
if(-not (Test-Path $p)){ Write-Host "NOT FOUND $p"; ls $PSScriptRoot | Select-Object Name | Out-Host; exit 1 }
$c = Get-Content -Raw -Encoding UTF8 $p
$re = [regex]::Matches($c, '<script(?![^>]*src=)[^>]*>([\s\S]*?)</script>', 'IgnoreCase')
$parts = @()
foreach ($m in $re) { $parts += $m.Groups[1].Value }
$code = $parts -join "`n"
Write-Host "scripts: $($re.Count), len: $($code.Length)"

function balance($s, $open, $close) {
    $d = 0; $min = 0; $inS=$false; $inD=$false; $inBt=$false; $esc=$false; $inLine=$false; $inBlock=$false
    for($i=0; $i -lt $s.Length; $i++){
        $ch = $s[$i]
        if($inLine){ if($ch -eq "`n"){$inLine=$false} continue }
        if($inBlock){
            if($ch -eq '*' -and $i+1 -lt $s.Length -and $s[$i+1] -eq '/'){ $inBlock=$false; $i++ }
            continue
        }
        if($esc){ $esc=$false; continue }
        if($ch -eq '\'){ $esc=$true; continue }
        if($inS){ if($ch -eq "'"){$inS=$false}; continue }
        if($inD){ if($ch -eq '"'){$inD=$false}; continue }
        if($inBt){ if($ch -eq '`'){$inBt=$false}; continue }
        if($ch -eq "'"){$inS=$true; continue}
        if($ch -eq '"'){$inD=$true; continue}
        if($ch -eq '`'){$inBt=$true; continue}
        if($ch -eq '/' -and $i+1 -lt $s.Length){
            if($s[$i+1] -eq '/'){ $inLine=$true; $i++; continue }
            if($s[$i+1] -eq '*'){ $inBlock=$true; $i++; continue }
        }
        if($ch -eq $open){ $d++ }
        elseif($ch -eq $close){ $d--; if($d -lt $min){$min=$d} }
    }
    return [pscustomobject]@{depth=$d; min=$min}
}
$b = balance $code '{' '}'
$pa = balance $code '(' ')'
$br = balance $code '[' ']'
Write-Host "{=$($b.depth)  min=$($b.min)}"
Write-Host "(=$($pa.depth) min=$($pa.min)}"
Write-Host "[=$($br.depth) min=$($br.min)}"
