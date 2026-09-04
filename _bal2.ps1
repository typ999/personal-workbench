$p = Join-Path $PSScriptRoot 'workbench-desktop.html'
$c = Get-Content -Raw -Encoding UTF8 $p
# Use string find instead regex (which might break on nested)
$code = ''
$pos = 0
while($true){
    $s = $c.IndexOf('<script', $pos, [StringComparison]::OrdinalIgnoreCase)
    if($s -lt 0){ break }
    $gt = $c.IndexOf('>', $s+7)
    if($gt -lt 0){ break }
    $tag = $c.Substring($s, $gt-$s+1)
    if($tag -match 'src\s*='){ $pos = $gt+1; continue }
    $e = $c.IndexOf('</script>', $gt+1, [StringComparison]::OrdinalIgnoreCase)
    if($e -lt 0){ break }
    $len = $e - ($gt+1)
    if($len -gt 0){ $code += $c.Substring($gt+1, $len) + "`n" }
    $pos = $e + 9
}
Write-Host "extracted code len: $($code.Length)"

# balance function same as before
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

# find first depth<0 of braces
$s=$code
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
      Write-Host "negative brace d=$d at i=$i line=$line col=$col"
      Write-Host ("context: "+ $s.Substring($start, [Math]::Min(400,$s.Length-$start)))
      # also show line text
      break
    }
  }
}
Write-Host "final d=$d"
