$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$f = Join-Path $PWD 'workbench.html'
$c = [System.IO.File]::ReadAllText($f)
Write-Host "Loaded: $($c.Length) chars"

# Use ASCII-safe replacement with no Chinese characters
# Unicode escapes in JS will render as Chinese at runtime
$replacement = "  // avatar/nickname`n  const nk=document.getElementById('drawer-nick');`n  const av=document.getElementById('drawer-ava');`n  const sub=document.getElementById('drawer-sub');`n  const st=store?store.get('__settings')||{}:{};`n  if(nk) nk.textContent=st.nickname||'\u4E2A\u4EBA\u5DE5\u4F5C\u53F0';`n  if(av && st.avatar) av.src=st.avatar;`n  if(sub) sub.textContent='\u4ECA\u65E5 '+dateStr();`n"

$startMarker = "  // avatar/nickname"
$endMarker = "  // wire close"
$startIdx = $c.IndexOf($startMarker)
$endIdx = $c.IndexOf($endMarker)

if($startIdx -ge 0 -and $endIdx -gt $startIdx){
  Write-Host "Replacing from $startIdx to $endIdx"
  $broken = $c.Substring($startIdx, $endIdx - $startIdx)
  $c = $c.Replace($broken, $replacement)
  Write-Host "Replaced!"
} else {
  Write-Error "Markers not found!"; exit 1
}

[System.IO.File]::WriteAllText($f, $c, [System.Text.UTF8Encoding]::new($false))
Write-Host "Saved. Size: $($c.Length)"

# Verify
$c2 = [System.IO.File]::ReadAllText($f)
Write-Host "`nVerifying unicode escapes present:"
Write-Host "u4E2A: $($c2.Contains('\u4E2A'))"
Write-Host "u4ECA: $($c2.Contains('\u4ECA'))"

# Quick quote check
$startIdx2 = $c2.IndexOf($startMarker)
$endIdx2 = $c2.IndexOf($endMarker)
Write-Host "`nFixed block:"
Write-Host $c2.Substring($startIdx2, [Math]::Min(300, $endIdx2 - $startIdx2))
