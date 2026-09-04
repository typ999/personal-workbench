$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$f = Join-Path $PWD 'workbench.html'
$c = [System.IO.File]::ReadAllText($f)
Write-Host "Loaded: $($c.Length) chars"

# Find and show the broken Chinese
$idx = $c.IndexOf("st.nickname||'")
Write-Host "Pattern idx: $idx"
if($idx -ge 0){
  Write-Host "Around broken code:"
  Write-Host $c.Substring([Math]::Max(0,$idx-10), 60)
}

# Fix 1: Replace broken Chinese in nickname line
# The correct version should use English fallback to avoid encoding issues
$broken1 = "st.nickname||'涓汉宸ヤ綔鍙"
$fixed1 = "st.nickname||'个人工作台'"
$c = $c.Replace($broken1, $fixed1)
Write-Host "Fix1 applied: nickname"

# Fix 2: Replace broken Chinese in sub line  
$broken2 = "'浠婃棩 '"
$fixed2 = "'今日 '"
$c = $c.Replace($broken2, $fixed2)
Write-Host "Fix2 applied: sub"

# Check if there are other broken Chinese around that area
$idx = $c.IndexOf("st.nickname||'")
if($idx -ge 0){
  $snippet = $c.Substring($idx, 80)
  Write-Host "After fix - snippet: $snippet"
  # Check for remaining ? or broken chars
  if($snippet.Contains('?;') -or $snippet.Contains('?';')) {
    Write-Host "WARNING: Still has broken chars, doing manual fix..."
    # Manual fix with full context match
    $oldLine = $c.Substring($c.LastIndexOf("nk.textContent", $idx) - 2, 60)
    Write-Host "Full line: $oldLine"
  }
}

# Check for any remaining encoding issues - search for garbled chars pattern
$garbled = [regex]::Matches($c, "[涓浠汉宸ヤ綔鍙汉汉汉汉汉]")
Write-Host "Remaining garbled char occurrences: $($garbled.Count)"

[System.IO.File]::WriteAllText($f, $c, [System.Text.UTF8Encoding]::new($false))
Write-Host "Saved. Size: $($c.Length)"

# Final verification
$c2 = [System.IO.File]::ReadAllText($f)
Write-Host "`n=== Quick syntax check ==="
$m = [regex]::Match($c2, "nk\.textContent\s*=")
if($m.Success){ 
  $v = $c2.Substring($m.Index, 60)
  Write-Host "nk.textContent line: $v"
  # Verify balanced quotes
  $quoteCount = ([regex]::Matches($v, "'")).Count
  Write-Host "Single quotes count: $quoteCount (should be even)"
  if($quoteCount % 2 -eq 0){ Write-Host "QUOTE BALANCED - OK" } else { Write-Host "QUOTE NOT BALANCED - NEEDS FIX" }
}
