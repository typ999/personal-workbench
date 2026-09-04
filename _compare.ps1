[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$root = Split-Path $MyInvocation.MyCommand.Path
$mb   = Join-Path $root "workbench-mobile.html"
$wb   = Join-Path $root "workbench.html"
$s1   = [System.IO.File]::ReadAllText($mb, [System.Text.Encoding]::UTF8)
$s2   = [System.IO.File]::ReadAllText($wb, [System.Text.Encoding]::UTF8)

function Count-Selectors($text, $patterns){
  $out=@{}
  foreach($p in $patterns){
    $out[$p] = [regex]::Matches($text, $p, 'IgnoreCase').Count
  }
  return $out
}

$cssSelectors = @(
  '\.mobile-topbar\s*\{',
  '\.scrim\s*\{',
  '\.scrim\.show\s*\{',
  '\.drawer\s*\{',
  '\.drawer\.show\s*\{',
  '\.drawer\s*\.dh\s*\{',
  '\.drawer\s*\.dclose\s*\{',
  '\.drawer\s*\.dsep\s*\{',
  '\.drawer\s*\.ditem\s*\{',
  '\.drawer\s*\.ditem\.active\s*\{',
  '\.drawer\s*\.dfoot\s*\{',
  '\.mobile-nav\s*\{',
  '@media\s*\(\s*max-width:\s*900px\s*\)',
  '@media\s*\(\s*min-width:\s*901px\s*\)',
  'date-chip'
)

Write-Output "================ CSS Selectors ================"
Write-Output "Pattern                                    Mobile  Merged"
Write-Output "--------------------------------------------------------"
foreach($p in $cssSelectors){
  $c1 = [regex]::Matches($s1, $p, 'IgnoreCase').Count
  $c2 = [regex]::Matches($s2, $p, 'IgnoreCase').Count
  $ok = if($c2 -gt 0){"OK"}else{"MISSING"}
  Write-Output ("{0,-42} {1,5}   {2,5}   {3}" , $p, $c1, $c2, $ok)
}

Write-Output ""
Write-Output "================ HTML / ID tokens ================"
$htmlIds = @(
  'id="btn-menu"',
  'id="scrim"',
  'id="drawer"',
  'id="drawerClose"',
  'id="drawerName"',
  'id="drawerSlogan"',
  'id="drawerList"',
  'id="drawerBrand"',
  'id="drawerAva"',
  'id="dateChip"',
  'id="mobileNav"',
  'class="mobile-topbar"',
  'class="dh"',
  'class="dclose"',
  'class="dsep"',
  'class="ditem"',
  'class="dfoot"',
  'class="mobile-nav"',
  'data-nav="home"',
  'data-nav="drawer"',
  'data-nav="insight"'
)
Write-Output "Pattern                                    Mobile  Merged"
Write-Output "--------------------------------------------------------"
foreach($p in $htmlIds){
  $c1 = [regex]::Matches($s1, [regex]::Escape($p)).Count
  $c2 = [regex]::Matches($s2, [regex]::Escape($p)).Count
  $ok = if($c2 -gt 0 -or $c1 -eq 0){"OK"}else{"MISSING"}
  Write-Output ("{0,-42} {1,5}   {2,5}   {3}" , $p, $c1, $c2, $ok)
}

Write-Output ""
Write-Output "================ JS Functions ================"
$jsFns = @(
  'function\s+buildDrawer\s*\(',
  'function\s+openDrawer\s*\(',
  'function\s+closeDrawer\s*\(',
  'function\s+updateDateChip\s*\(',
  'function\s+initDrawerEvents\s*\(',
  'buildDrawer\s*\(\s*\)\s*;',
  'updateDateChip\s*\(\s*\)\s*;',
  'initDrawerEvents\s*\(\s*\)\s*;',
  'classList\.toggle\(.active.*view',
  '\.ditem.*data-go'
)
foreach($p in $jsFns){
  $c1 = [regex]::Matches($s1, $p, 'IgnoreCase').Count
  $c2 = [regex]::Matches($s2, $p, 'IgnoreCase').Count
  $ok = if($c2 -gt 0 -or $c1 -eq 0){"OK"}else{"MISSING"}
  Write-Output ("{0,-42} {1,5}   {2,5}   {3}" , $p, $c1, $c2, $ok)
}
