$p = Join-Path $PSScriptRoot 'workbench-desktop.html'
$c = Get-Content -Raw -Encoding UTF8 $p
$re = [regex]::Matches($c, '<script(?![^>]*src=)[^>]*>([\s\S]*?)</script>', 'IgnoreCase')
$parts = @()
foreach ($m in $re) { $parts += $m.Groups[1].Value }
$code = $parts -join "`n"

# line numbers: map char -> line/col for ~first negative brace depth
$s = $code
$d=0; $inS=$false; $inD=$false; $inBt=$false; $esc=$false; $inLine=$false; $inBlock=$false
$line=1; $col=0; $lastLine=1; $lastCol=0
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
      $start=[Math]::Max(0,$i-120)
      Write-Host "brace d=$d at i=$i line=$line col=$col"
      Write-Host ("context: "+ $s.Substring($start, [Math]::Min(400,$s.Length-$start)))
      break
    }
  }
}
Write-Host "final d=$d ended at line=$line col=$col"
