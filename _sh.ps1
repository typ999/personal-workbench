$p = Join-Path $PSScriptRoot 'workbench-desktop.html'
$c = Get-Content -Raw -Encoding UTF8 $p
$pos = 0
$code = ''
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
$target_i = 243674
# find line number by scanning up to target_i
$line=1
for($i=0; $i -lt $target_i; $i++){ if($code[$i] -eq "`n"){$line++} }
Write-Host "target line=$line"
# print lines 4185..4210 of the code
$lines = $code -split "`r?`n"
$startLine = [Math]::Max(0, $line-20)
$endLine = [Math]::Min($lines.Length-1, $line+20)
for($i=$startLine; $i -le $endLine; $i++){
  $ln = $i+1
  Write-Host ("[$ln] "+ $lines[$i])
}
