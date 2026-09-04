$content = Get-Content "c:\Users\59643\Desktop\个人工作台\workbench.html" -Raw -Encoding UTF8
$start = $content.IndexOf('<script>')
$lastScriptStart = $content.LastIndexOf('<script>')
$lastScriptEnd = $content.LastIndexOf('</script>')
Write-Output "First script: $start, Last script start: $lastScriptStart, Last end: $lastScriptEnd"

$script = $content.Substring($lastScriptStart + 8, $lastScriptEnd - $lastScriptStart - 8)
$lines = $script -split "`n"
$depth = 0
for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    $opens = ([regex]::Matches($line, '\{')).Count
    $closes = ([regex]::Matches($line, '\}')).Count
    $prev = $depth
    $depth += $opens - $closes
    if ($depth -lt 0) {
        Write-Output "NEGATIVE DEPTH at script-line $i (html ~$($i+$lastScriptStart+8))"
        Write-Output "  prev=$prev opens=$opens closes=$closes"
        Write-Output "  content: $($line.Trim().Substring(0,[Math]::Min(150,$line.Trim().Length)))"
        break
    }
    if ($opens -gt 0 -or $closes -gt 0) {
        if ($depth -le 1 -or $prev -le 1) {
            Write-Output "L$($i+$lastScriptStart+8) depth=$prev->$depth : $($line.Trim().Substring(0,[Math]::Min(80,$line.Trim().Length)))"
        }
    }
}
Write-Output "Final depth: $depth"
Write-Output "Total script lines: $($lines.Length)"
