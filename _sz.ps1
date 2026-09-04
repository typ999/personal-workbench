# Parse only the first large script block and walk to ~i=243674, output every depth zero crossing to pinpoint which function is over-closing
$p = Join-Path $PSScriptRoot 'workbench-desktop.html'
$c = Get-Content -Raw -Encoding UTF8 $p
$re = [regex]::Matches($c, '<script(?![^>]*src=)[^>]*>([\s\S]*?)</script>', 'IgnoreCase')
Write-Host "scripts: $($re.Count)"
1..$re.Count | ForEach-Object {
    $idx = $_-1
    $len = $re[$idx].Groups[1].Value.Length
    Write-Host "script[$idx] len=$len startswith=$($re[$idx].Groups[1].Value.Substring(0, [Math]::Min(80,$len)).Replace("`r",' ').Replace("`n",' '))"
}
