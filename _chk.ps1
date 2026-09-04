$p = Join-Path $PSScriptRoot '_extracted_script.js'
$lines = Get-Content $p
# Find first ?. usage
for($i=0;$i -lt $lines.Count;$i++){
  if($lines[$i] -match '\?\.(?!\.)' -or $lines[$i] -match '\?\?'){
    # Print context
    $start=[Math]::Max(0,$i-1)
    $end=[Math]::Min($lines.Count-1,$i+1)
    Write-Host "---- line $($i+1) (first ??/?: context) ----"
    for($j=$start;$j -le $end;$j++){ Write-Host ("[$($j+1)] "+ $lines[$j]) }
    break
  }
}
Write-Host "---- scanning for ?. in new edits ----"
# Look at lines 4190..4300 for any ?.
for($i=4189;$i -lt [Math]::Min(4350,$lines.Count);$i++){
  if($lines[$i] -match '\?\.'){ Write-Host "[$($i+1)] ??: $($lines[$i].Trim().Substring(0,[Math]::Min(180,$lines[$i].Trim().Length)))" }
}
