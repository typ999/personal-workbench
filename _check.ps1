[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path
$p = Join-Path $PSScriptRoot "workbench.html"
Write-Output "Path: $p"
Write-Output "Exists: $(Test-Path $p)"
$s = [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8)
Write-Output "Size: $($s.Length)"
Write-Output "<style>: $([regex]::Matches($s,'<style\b').Count)  </style>: $([regex]::Matches($s,'</style>').Count)"
Write-Output "<script>: $([regex]::Matches($s,'<script\b').Count)  </script>: $([regex]::Matches($s,'</script>').Count)"
Write-Output "<body>: $([regex]::Matches($s,'<body\b').Count)  </body>: $([regex]::Matches($s,'</body>').Count)"
Write-Output "<head>: $([regex]::Matches($s,'<head\b').Count)  </head>: $([regex]::Matches($s,'</head>').Count)"
Write-Output "<html>: $([regex]::Matches($s,'<html\b').Count)  </html>: $([regex]::Matches($s,'</html>').Count)"
$ob = ([char[]]$s | Where-Object { $_ -eq '{' }).Count
$cb = ([char[]]$s | Where-Object { $_ -eq '}' }).Count
Write-Output "{ count: $ob  } count: $cb  diff: $($ob - $cb)"
$op = ([char[]]$s | Where-Object { $_ -eq '(' }).Count
$cp = ([char[]]$s | Where-Object { $_ -eq ')' }).Count
Write-Output "( count: $op  ) count: $cp  diff: $($op - $cp)"
