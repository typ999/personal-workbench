$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$f = Join-Path $PWD 'workbench.html'
$c = [System.IO.File]::ReadAllText($f)
Write-Host "Loaded: $($c.Length) chars"

# Fix sub.textContent line - find by pattern
$pattern = "sub\.textContent\s*=\s*'[^']*'\s*\+\s*dateStr\(\)"
$m = [regex]::Match($c, $pattern)
Write-Host "Match: $($m.Success)"
if($m.Success){
  Write-Host "Old: [$($m.Value)]"
  $new = "sub.textContent='今日 '+dateStr()"
  $c = $c.Replace($m.Value, $new)
  Write-Host "Replaced with: [$new]"
}

# Also check if nk.textContent needs fix still
$pattern2 = "nk\.textContent\s*=\s*st\.nickname\|\|\s*'[^']*'"
$m2 = [regex]::Match($c, $pattern2)
Write-Host "nk.textContent match: $($m2.Success)"
if($m2.Success){
  Write-Host "nk old: [$($m2.Value)]"
  $new2 = "nk.textContent=st.nickname||'个人工作台'"
  $c = $c.Replace($m2.Value, $new2)
  Write-Host "nk replaced with: [$new2]"
}

# Also check av line for completeness (maybe it also has issues)
$idx3 = $c.IndexOf("av && st.avatar")
if($idx3 -ge 0){
  Write-Host "av line context: $($c.Substring($idx3-20, 60))"
}

[System.IO.File]::WriteAllText($f, $c, [System.Text.UTF8Encoding]::new($false))
Write-Host "Saved. Size: $($c.Length)"

# Final check
$c2 = [System.IO.File]::ReadAllText($f)
$idx = $c2.IndexOf("// avatar/nickname")
if($idx -ge 0){
  Write-Host "`nFinal context around avatar/nickname:"
  Write-Host $c2.Substring($idx, 300)
}
