$c = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot 'workbench.html'))
$lines = $c -split "`n"
$sLine = ($c.Substring(0, $c.IndexOf('// ========== Mobile Drawer')) -split "`n").Count
Write-Host "Drawer JS starts at line ~$sLine"

# Find script boundaries
$scriptStarts = [regex]::Matches($c, '<script[^>]*>') | ForEach-Object { ($c.Substring(0, $_.Index) -split "`n").Count }
$scriptEnds = [regex]::Matches($c, '</script>') | ForEach-Object { ($c.Substring(0, $_.Index) -split "`n").Count }
Write-Host "`nScript starts:"
$scriptStarts | ForEach-Object { Write-Host "  line $_" }
Write-Host "Script ends:"
$scriptEnds | ForEach-Object { Write-Host "  line $_" }

# Check which script block contains drawer JS
for($i = 0; $i -lt $scriptStarts.Count; $i++){
  $start = $scriptStarts[$i]
  $end = if($i -lt $scriptEnds.Count){ $scriptEnds[$i] } else { $lines.Count }
  if($sLine -ge $start -and $sLine -le $end){
    Write-Host "`n>>> Drawer JS is INSIDE script block #$i (lines $start - $end) <<<"
    break
  }
}

# Check init chain location  
$initLine = ($c.Substring(0, $c.IndexOf("  buildDrawer();")) -split "`n").Count
Write-Host "`nbuildDrawer() call at line ~$initLine"
for($i = 0; $i -lt $scriptStarts.Count; $i++){
  $start = $scriptStarts[$i]
  $end = if($i -lt $scriptEnds.Count){ $scriptEnds[$i] } else { $lines.Count }
  if($initLine -ge $start -and $initLine -le $end){
    Write-Host ">>> buildDrawer() call is INSIDE script block #$i (lines $start - $end) <<<"
  }
}
