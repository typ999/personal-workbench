# Check balance of only the newly added script portion around LEARN_POOL / studyInspirit / renderStudyView
$p = Join-Path $PSScriptRoot 'workbench-desktop.html'
$c = Get-Content -Raw -Encoding UTF8 $p
$re = [regex]::Matches($c, '<script(?![^>]*src=)[^>]*>([\s\S]*?)</script>', 'IgnoreCase')
$parts = @()
foreach ($m in $re) { $parts += $m.Groups[1].Value }
$code = $parts -join "`n"

# Substring from LEARN_POOL
$idx = $code.IndexOf('const LEARN_POOL = {')
Write-Host "LEARN_POOL at i=$idx"
$chunk = $code.Substring($idx)

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

# Check chunk depth of braces progressively and report when goes negative
$s = $chunk
$d=0; $inS=$false; $inD=$false; $inBt=$false; $esc=$false; $inLine=$false; $inBlock=$false
$line=1; $col=0
for($i=0; $i -lt $s.Length; $i++){
  $ch = $s[$i]
  if($ch -eq "`n"){ $line++; $col=0 } else { $col++ }
  if($inLine){ if($ch -eq "`n"){$inLine=$false} continue }
  if($inBlock){
    if($ch -eq '*' -and $i+1 -lt $s.Length -and $s[$i+1] -eq '/'){ $inBlock=$false; $i++; $col++ }
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
    if($s[$i+1] -eq '/'){ $inLine=$true; $i++; $col++; continue }
    if($s[$i+1] -eq '*'){ $inBlock=$true; $i++; $col++; continue }
  }
  if($ch -eq '{'){ $d++ }
  elseif($ch -eq '}'){
    $d--
    if($d -lt 0){
      $start=[Math]::Max(0,$i-80)
      Write-Host "brace NEGATIVE d=$d at chunk i=$i line=$line col=$col"
      Write-Host ("context: "+ $s.Substring($start, [Math]::Min(300,$s.Length-$start)))
      break
    }
  }
}
Write-Host "final chunk brace d=$d"
