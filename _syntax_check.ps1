Param([string]$file='workbench-desktop.html')
$ErrorActionPreference='Stop'
$path = Join-Path $PSScriptRoot $file
$c = [System.IO.File]::ReadAllText($path)
$lines = $c -split "`n"
Write-Host "File: $file  lines=$($lines.Count)  chars=$($c.Length)"

# Extract each <script> block content
$opens = [regex]::Matches($c, '<script(?![^>]*\bmodule\b)[^>]*>') | ForEach-Object { [PSCustomObject]@{Index=$_.Index; Length=$_.Length} }
$closes = [regex]::Matches($c, '</script>') | ForEach-Object { $_.Index }
Write-Host "Script blocks: $($opens.Count) opens, $($closes.Count) closes"

$addType = $null
try {
  $addType = Add-Type -AssemblyName 'Microsoft.JScript' -ErrorAction SilentlyContinue
} catch {}

for($i=0; $i -lt $opens.Count; $i++){
  $start = $opens[$i].Index + $opens[$i].Length
  $endIdx = if($i -lt $closes.Count){ $closes[$i] } else { $c.Length }
  $len = $endIdx - $start
  $inner = if($len -gt 0){ $c.Substring($start, $len) } else { '' }
  $lineNo = ($c.Substring(0, $opens[$i].Index) -split "`n").Count
  Write-Host "`nBlock #$($i+1)  lines $lineNo~...  chars=$len"
  if($inner.Length -eq 0){ Write-Host "  (empty, OK)"; continue }
  try {
    $ps = [System.Management.Automation.Language.Parser]::ParseInput(('function __dummy__(){}; ' + $inner), [ref]$null, [ref]$null)
    # PowerShell parser != JS; skip direct test
    Write-Host "  PowerShell parse length: ok (not JS)"
  } catch {
    Write-Host "  (PS parse fail not meaningful for JS)"
  }
  # Balanced parens/braces check
  $paren = 0; $brace = 0; $brack = 0;
  $inStr = $false; $strCh = ''; $escape = $false;
  $inLineComment = $false; $inBlockComment = $false;
  $inTemplate = $false;
  $bad = $false
  for($j=0; $j -lt $inner.Length; $j++){
    $ch = $inner[$j]
    $nx = if($j+1 -lt $inner.Length){$inner[$j+1]} else {[char]0}
    if($inLineComment){ if($ch -eq "`n"){ $inLineComment = $false } continue }
    if($inBlockComment){ if($ch -eq '*' -and $nx -eq '/'){ $inBlockComment=$false; $j++ } continue }
    if($escape){ $escape=$false; continue }
    if($inStr -or $inTemplate){
      if($ch -eq '\'){ $escape=$true; continue }
      if($inStr){
        if($ch -eq $strCh){ $inStr=$false }
      } else {
        if($ch -eq '`'){ $inTemplate=$false }
      }
      continue
    }
    if($ch -eq '/' -and $nx -eq '/'){ $inLineComment=$true; $j++; continue }
    if($ch -eq '/' -and $nx -eq '*'){ $inBlockComment=$true; $j++; continue }
    if($ch -eq '"' -or $ch -eq "'"){ $inStr=$true; $strCh=[string]$ch; continue }
    if($ch -eq '`'){ $inTemplate=$true; continue }
    switch($ch){
      '(' { $paren++ }
      ')' { $paren--; if($paren -lt 0){$bad=$true; Write-Host "  ) imbalance near char $j"; break} }
      '{' { $brace++ }
      '}' { $brace--; if($brace -lt 0){$bad=$true; Write-Host "  } imbalance near char $j"; break} }
      '[' { $brack++ }
      ']' { $brack--; if($brack -lt 0){$bad=$true; Write-Host "  ] imbalance near char $j"; break} }
    }
    if($bad){ break }
  }
  Write-Host "  Balance: paren=$paren  brace=$brace  brack=$brack   bad=$bad"
}
