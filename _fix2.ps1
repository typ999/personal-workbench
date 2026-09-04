$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$f = Join-Path $PWD 'workbench.html'
$c = [System.IO.File]::ReadAllText($f)
Write-Host "Loaded: $($c.Length) chars"

# Find broken area and show it
$idx = $c.IndexOf("st.nickname||")
Write-Host "Found st.nickname|| at idx: $idx"
if($idx -ge 0){
  Write-Host "Context: $($c.Substring($idx, 80))"
}

# Replace the entire broken section by finding it precisely
# Strategy: replace the full nk.textContent and sub.textContent lines
# Find nk.textContent line
$idx1 = $c.IndexOf("nk.textContent", $c.IndexOf("// avatar/nickname"))
Write-Host "nk.textContent at: $idx1"

# Let's read a bigger chunk and find what to replace
$chunkStart = $c.LastIndexOf("nk.textContent", $idx1)
if($chunkStart -lt 0){ $chunkStart = $idx1 }
$chunk = $c.Substring($chunkStart, 200)
Write-Host "Raw chunk:"
Write-Host $chunk

# The broken pattern - let's match by position and replace
# We know it should be: nk.textContent=st.nickname||'个人工作台';
# and: sub.textContent='今日 '+dateStr();

# Let's just do a direct string replace on the known broken sequences
# First let's find EXACTLY what the broken strings are
$match = [regex]::Match($c, "nk\.textContent\s*=\s*st\.nickname\|\|\s*'\S+")
if($match.Success){
  Write-Host "Matched broken: [$($match.Value)]"
  $old = $match.Value
  $new = "nk.textContent=st.nickname||'个人工作台'"
  $c = $c.Replace($old, $new)
  Write-Host "Fixed nk.textContent line"
}

# Now sub.textContent
$match2 = [regex]::Match($c, "sub\.textContent\s*=\s*'\S+\s*\+dateStr")
if($match2.Success){
  Write-Host "Matched broken sub: [$($match2.Value)]"
  $old2 = $match2.Value
  $new2 = "sub.textContent='今日 '+dateStr()"
  $c = $c.Replace($old2, $new2)
  Write-Host "Fixed sub.textContent line"
}

[System.IO.File]::WriteAllText($f, $c, [System.Text.UTF8Encoding]::new($false))
Write-Host "Saved. Size: $($c.Length)"

# Verify
$c2 = [System.IO.File]::ReadAllText($f)
$chk = [regex]::Match($c2, "nk\.textContent.{0,60}?;")
Write-Host "nk verification: $($chk.Value)"
$chk2 = [regex]::Match($c2, "sub\.textContent.{0,60}?;")
Write-Host "sub verification: $($chk2.Value)"
