Set-Location $PSScriptRoot
$c = [System.IO.File]::ReadAllText((Join-Path $PWD 'workbench.html'))
Write-Host "File loaded: $($c.Length) chars"

# Quote balance check
$idx = $c.IndexOf('// avatar/nickname')
$endIdx = $c.IndexOf('// wire close')
$block = $c.Substring($idx, $endIdx - $idx)
$singleQuotes = ([regex]::Matches($block, "'")).Count
Write-Host "Single quotes in block: $singleQuotes (should be even)"

$checks = @(
  'id="btn-menu"',
  'id="scrim"',
  'class="drawer"',
  'id="tabbar"',
  'function buildDrawer()',
  'function openDrawer()',
  'function closeDrawer()',
  'buildDrawer();',
  'startClock();',
  'max-width: 900px',
  'navItems',
  'goto(',
  'openSettings',
  'exportData',
  'drawer-item',
  'tab-btn',
  'drawer-open',
  'updateTabbar'
)

Write-Host ""
$allOk = $true
foreach($ch in $checks){
  $ok = $c.Contains($ch)
  $mark = if($ok){'OK'}else{'MISSING'}
  Write-Host "  $mark - $ch"
  if(-not $ok){ $allOk = $false }
}

Write-Host ""
if($allOk -and $singleQuotes % 2 -eq 0){
  Write-Host ">>> ALL CHECKS PASSED <<<"
} else {
  Write-Host ">>> SOME CHECKS FAILED <<<"
}
