$c = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot 'workbench.html'))
$s = $c.IndexOf('// ========== Mobile Drawer')
$e = $c.IndexOf('}else{', $s)
Write-Host "Drawer JS: $s to $e (len: $($e-$s))"
$block = $c.Substring($s, $e - $s)
Write-Host "`n=== LAST 400 CHARS ==="
Write-Host $block.Substring([Math]::Max(0, $block.Length - 400))
Write-Host "`n=== BRACE COUNT ==="
$opens = ([regex]::Matches($block, '\{')).Count
$closes = ([regex]::Matches($block, '\}')).Count
Write-Host "Open: $opens, Close: $closes, Diff: $($opens-$closes)"
Write-Host "`n=== SEMICOLON COUNT ==="
Write-Host "Total semicolons: $(([regex]::Matches($block, ';')).Count)"
Write-Host "`n=== function declarations ==="
[regex]::Matches($block, 'function (\w+)') | ForEach-Object { Write-Host "  function $($_.Groups[1].Value)" }
