$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$f = Join-Path $PWD 'workbench.html'
$c = [System.IO.File]::ReadAllText($f)
Write-Host "Loaded: $($c.Length) chars"

# Find the exact area to replace
$startMarker = "  // avatar/nickname"
$endMarker = "  // wire close"

$startIdx = $c.IndexOf($startMarker)
$endIdx = $c.IndexOf($endMarker)
Write-Host "startIdx: $startIdx, endIdx: $endIdx"

if($startIdx -ge 0 -and $endIdx -gt $startIdx){
  Write-Host "Current broken block:"
  $broken = $c.Substring($startIdx, $endIdx - $startIdx)
  Write-Host $broken

  $replacement = @"
  // avatar/nickname
  const nk=document.getElementById('drawer-nick');
  const av=document.getElementById('drawer-ava');
  const sub=document.getElementById('drawer-sub');
  const st=store?store.get('__settings')||{}:{};
  if(nk) nk.textContent=st.nickname||'个人工作台';
  if(av && st.avatar) av.src=st.avatar;
  if(sub) sub.textContent='今日 '+dateStr();
"@

  $c = $c.Replace($broken, $replacement)
  Write-Host "`nReplaced successfully"
} else {
  Write-Error "Could not find markers!"
  exit 1
}

[System.IO.File]::WriteAllText($f, $c, [System.Text.UTF8Encoding]::new($false))
Write-Host "Saved. Size: $($c.Length)"

# Verify
$c2 = [System.IO.File]::ReadAllText($f)
$startIdx2 = $c2.IndexOf($startMarker)
$endIdx2 = $c2.IndexOf($endMarker)
if($startIdx2 -ge 0){
  Write-Host "`nFixed block:"
  Write-Host $c2.Substring($startIdx2, $endIdx2 - $startIdx2)
}
