[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'
$base = Join-Path $PSScriptRoot "workbench-mobile.html"
$tgt  = Join-Path $PSScriptRoot "workbench.html"
$mb = Join-Path $PSScriptRoot "_mobile_html.txt"
$mc = Join-Path $PSScriptRoot "_mobile_css.txt"
$mj = Join-Path $PSScriptRoot "_mobile_js.txt"
$mh = Get-Content $base -Raw -Encoding UTF8

# 1. 移动端 HTML 结构：body 内从 .topbar 到 .drawer 关闭（含 .nav 和 .scrim）
# 起点 <div class="app">
$appStart   = $mh.IndexOf('<div class="app">')
# 终点 </aside><!-- end drawer -->，取到 drawer 闭合
$drawerAsid = $mh.IndexOf('</aside>', $appStart)
$afterDraw  = $mh.IndexOf("`n", $drawerAsid)  # 行尾
# 包含 nav (底部 3 按钮) + scrim + drawer 全部（它们在 app 外 / app 内都算 mobile 主体）
# 取：从 .app 开头 到 .drawer 的 </aside> + 后续所有 body 内的 drawer/scrim/nav 附件
# 简化：取 body 内部的所有内容直到 </body>
$bodyStart = $mh.IndexOf('<body>') + 6
$bodyEnd   = $mh.LastIndexOf('</body>')
$mobileBody = $mh.Substring($bodyStart, $bodyEnd - $bodyStart)
# 去掉 trae 注入的最后那个 <div data-trae-edit-ui=...>
$teTag = $mobileBody.IndexOf('<div data-trae-edit-ui="true"')
if ($teTag -gt 0) { $mobileBody = $mobileBody.Substring(0, $teTag) }
$mobileBody.TrimEnd() | Out-File -FilePath $mb -Encoding UTF8
Write-Output "HTML body extracted: $($mobileBody.Length) chars -> $mb"

# 2. 移动端 CSS 片段：从 .nav fixed 底栏块开始（L1998左右），含 scrim/.drawer/.tile/.overlay/.modal 等一直到 Phase 2 前（约 ~L2080）
$cssStart = $mh.IndexOf('.nav { position: fixed; left: 50%;')
$cssEnd   = $mh.IndexOf('/* ===== Phase 2: 每日计划', $cssStart)
$mobileCss = $mh.Substring($cssStart, $cssEnd - $cssStart)
$mobileCss.Trim() | Out-File -FilePath $mc -Encoding UTF8
Write-Output "Mobile CSS block: $($mobileCss.Length) chars -> $mc"

# 3. 移动端 JS：buildDrawer + openDrawer + closeDrawer + 底部 nav 绑定 + touch 滑动
$jsStart = $mh.IndexOf('function buildDrawer(){')
# 找 buildDrawer 函数结束（下一个 function 之前的函数结束大括号）
# 简单处理：取到 closeDrawer 函数后的闭合（后面是 exportJSON 等其他函数的起点）
$afterClose = $mh.IndexOf('function exportJSON(){', $jsStart)
if ($afterClose -eq -1) { $afterClose = $mh.IndexOf('function render(){', $jsStart) }
$mobileJs = $mh.Substring($jsStart, $afterClose - $jsStart)
$mobileJs.Trim() | Out-File -FilePath $mj -Encoding UTF8
Write-Output "Mobile JS block: $($mobileJs.Length) chars -> $mj"

Write-Output "--- HTML length: $((Get-Item $mb).Length) ---"
Write-Output "--- CSS length:  $((Get-Item $mc).Length) ---"
Write-Output "--- JS length:   $((Get-Item $mj).Length) ---"
