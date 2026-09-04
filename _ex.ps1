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
$lines = $code -split "`r?`n"
$N = $lines.Count
Write-Host "total script lines=$N"
# find lines that use "??" but NOT "?." — actually scan everything
# Instead, walk line by line: count braces (including strings in a more robust way)
# Use a stack-based approach but treat regex literals: / after these tokens is regex: ( [ { , ; : = ! & | ? ~ return typeof in instanceof else do case throw new void delete ++ -- + - * / % ^ & | < > == != === !== && || ?? ?: = += -= *= /= %= **= ^= &= |= <<= >>= >>>= ,
# Too complex. Instead try to find lines with suspicious patterns.
# Check every line for `??` followed by quotes for known cases
for($i=0;$i -lt $N;$i++){
  $l = $lines[$i]
  if($l -match 'String\(v\?\?' -and $l -match 'typeof v'){
    Write-Host "[L$($i+1)] matches csv pattern"
  }
}
# Write out script to a temp file and scan with line numbers
$out = Join-Path $PSScriptRoot "_extracted_script.js"
[System.IO.File]::WriteAllText($out, $code)
Write-Host "written $out"
