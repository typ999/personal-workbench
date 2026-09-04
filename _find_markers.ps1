[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$path = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "workbench.html"
$src = Get-Content $path -Raw -Encoding UTF8

Write-Output "Total length: $($src.Length)"

$m1 = $src.IndexOf('<div class="foot" id="foot">')
Write-Output "foot marker index: $m1"

# 找 </nav>  </aside> 在 foot 之后
$after = $src.Substring($m1, [Math]::Min(10000, $src.Length - $m1))
$n1 = $after.IndexOf("</nav>")
Write-Output "First </nav> after foot (within after substring): $n1"
# 看看紧随 </nav> 之后有什么
$ctx1 = $after.Substring($n1, [Math]::Min(200, $after.Length - $n1))
Write-Output "Context after </nav>: $(($ctx1 -replace "`r?`n",' ').Substring(0,[Math]::Min(180,$ctx1.Length)))"

$m2 = $src.IndexOf("button#btn-menu { display: none; position: fixed;")
Write-Output "old btn-menu CSS start: $m2"

$teMarker = "</style>"
$m3 = $src.IndexOf($teMarker, [Math]::Max(0,$m2))
Write-Output "First </style> after btn-menu CSS: $m3"
if ($m3 -gt 0) {
    $ctx2 = $src.Substring($m3, [Math]::Min(200, $src.Length - $m3))
    Write-Output "Context after </style>: $(($ctx2 -replace "`r?`n",' ').Substring(0,[Math]::Min(180,$ctx2.Length)))"
}
