[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$content = Get-Content ".\workbench.html" -Raw -Encoding UTF8
$lastScriptStart = $content.LastIndexOf('<script>')
$lastScriptEnd = $content.LastIndexOf('</script>')
Write-Output "Script block from char $lastScriptStart to $lastScriptEnd"

$script = $content.Substring($lastScriptStart + 8, $lastScriptEnd - $lastScriptStart - 8)
$lines = $script -split "`r?`n"
Write-Output "Total script lines: $($lines.Length)"
$depth = 0
for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    $opens = ([regex]::Matches($line, '\{')).Count
    $closes = ([regex]::Matches($line, '\}')).Count
    $prev = $depth
    $depth += $opens - $closes
    if ($depth -lt 0) {
        Write-Output "!!! NEGATIVE DEPTH at script-line $i (html L$($i+$lastScriptStart+8))"
        Write-Output "    prev=$prev opens=$opens closes=$closes"
        Write-Output "    content: $($line.Trim().Substring(0,[Math]::Min(150,$line.Trim().Length)))"
        break
    }
}
Write-Output "Final depth: $depth"
if ($depth -ne 0) { Write-Output "!!! BRACE MISMATCH DETECTED" }
