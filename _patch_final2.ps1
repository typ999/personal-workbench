[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path
$path = Join-Path $PSScriptRoot "workbench.html"
$src = Get-Content $path -Raw -Encoding UTF8

# ========== 1) 替换 HTML：foot 后面的 mobile 乱码元素 + sidebar 闭合 ==========
$footMarker = '<div class="foot" id="foot">数据仅存在本机 · 每日更新</div>'
$footStart  = $src.IndexOf($footMarker)
# 取 foot 后 20,000 字的片段
$snippet = $src.Substring($footStart, [Math]::Min(25000, $src.Length - $footStart))
# 找 <nav id="tabbar">（tabbar 起点）
$tabStart = $snippet.IndexOf('<nav id="tabbar"')
Write-Output "tabbar start in snippet: $tabStart"
# 然后找 tabbar 之后的第一个 </nav>（这是 tabbar 的闭合）
$tabNavClose = $snippet.IndexOf('</nav>', $tabStart)
Write-Output "tabbar </nav> in snippet: $tabNavClose"
# 再找这个 </nav> 后的 </aside>（sidebar 的 closing）
$sideClose  = $snippet.IndexOf('</aside>', $tabNavClose)
Write-Output "sidebar </aside> in snippet: $sideClose"
$absStart = $footStart
$absEnd   = $footStart + $sideClose + 8  # include </aside> length 8
Write-Output "Final replace: abs $absStart ~ $absEnd (len $($absEnd - $absStart))"

$newHtml = @"
<div class="foot" id="foot">数据仅存在本机 · 每日更新</div>
  </aside>

  <!-- ===== Mobile专属结构（Topbar + Scrim + Drawer + 3项底栏 Nav）【对齐 workbench-mobile】 ===== -->
  <!-- Mobile: Topbar（<900px显示） -->
  <div class="mobile-topbar">
    <button class="menu-btn" id="btn-menu" aria-label="菜单"><svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 7h16"></path><path d="M4 12h16"></path><path d="M4 17h16"></path></svg></button>
    <div class="mobile-title"><span>个人工作台</span><small>全场景生活效率整合平台</small></div>
    <span class="date-chip"><svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="5" width="16" height="16" rx="2.5"></rect><path d="M4 9.5h16"></path><path d="M8 3v4"></path><path d="M16 3v4"></path></svg><span id="dateChipText">今日</span></span>
  </div>

  <!-- Mobile: Scrim -->
  <div class="scrim" id="scrim"></div>

  <!-- Mobile: Drawer（dh/dclose/ditem/dsep/dfoot 类 对齐 workbench-mobile） -->
  <aside class="drawer" id="drawer">
    <div class="dh">
      <div class="brand" id="drawerBrand">
        <img id="drawer-ava" alt="头像">
        <span class="brand-cam"><svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 8.5h3l1.5-2h7L17 8.5h3v10H4z"></path><circle cx="12" cy="13" r="3.2"></circle></svg></span>
      </div>
      <div>
        <h2 id="drawer-nick">个人工作台</h2>
        <p id="drawer-sub">记录每一天</p>
      </div>
      <button class="dclose" id="drawerClose" aria-label="关闭"><svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M6 6l12 12M18 6L6 18"></path></svg></button>
    </div>
    <div class="dsep"></div>
    <nav id="drawerList"></nav>
    <div class="dfoot">
      <button class="drawer-foot-btn" id="drawer-settings">&#x2699; 设置</button>
      <button class="drawer-foot-btn" id="drawer-export">&#x1F4E6; 导出</button>
      <div class="dfoot-tip">数据仅存在本机</div>
    </div>
  </aside>

  <!-- Mobile: 3项底栏 Nav（对齐 workbench-mobile：首页 / 模块 / 洞察） -->
  <div class="mobile-nav" id="mobileNav">
    <div class="n active" data-nav="home"><svg viewBox="0 0 24 24" width="21" height="21" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 11.5 12 5l8 6.5"></path><path d="M6 10.5V19h12v-8.5"></path></svg><span>首页</span></div>
    <div class="n" data-nav="drawer"><svg viewBox="0 0 24 24" width="21" height="21" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="4" width="7" height="7" rx="1.6"></rect><rect x="13" y="4" width="7" height="7" rx="1.6"></rect><rect x="4" y="13" width="7" height="7" rx="1.6"></rect><rect x="13" y="13" width="7" height="7" rx="1.6"></rect></svg><span>模块</span></div>
    <div class="n" data-nav="insight"><svg viewBox="0 0 24 24" width="21" height="21" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20V4"></path><path d="M4 20h16"></path><path d="M8 16v-4"></path><path d="M12 16v-7"></path><path d="M16 16v-2"></path></svg><span>洞察</span></div>
  </div>
"@

$src2 = $src.Remove($absStart, $absEnd - $absStart).Insert($absStart, $newHtml)
Write-Output "1) HTML replaced OK ($($newHtml.Length) chars)"

# ========== 2) 替换旧 btn-menu 开头的 CSS 到 </style> 结尾的区间 ==========
$cssStart = $src2.IndexOf("button#btn-menu { display: none; position: fixed;")
Write-Output "cssStart: $cssStart"
# 结尾：</style>后面跟 <style data-trae-edit-ui （中间可能有一个换行或空格）
# 用 </style> + 空白 + <style data-trae-edit-ui 找
$traeTag = '<style data-trae-edit-ui'
$cssEndPos = $src2.IndexOf($traeTag, $cssStart) - 1  # 指回 </style> 后面的字符前
# 从 cssEndPos 往回找最近的 </style> 的 > 位置
while ($cssEndPos -lt $src2.Length -and $cssEndPos -gt 0) {
    if ($src2[$cssEndPos] -eq '>') { break }
    $cssEndPos--
}
$cssEndPos++  # 指向 > 之后
Write-Output "cssEndPos (after </style>>): $cssEndPos"

$newCss = @"
/* ============================================================
   Mobile 专属样式【对齐 workbench-mobile.html】
   ============================================================ */
/* --- Mobile Topbar --- */
.mobile-topbar { display: none; position: fixed; top: 0; left: 0; right: 0; height: 54px; background: rgba(252, 251, 248, 0.92); backdrop-filter: blur(14px); border-bottom: 1px solid var(--border); z-index: 35; align-items: center; padding: 0 14px; gap: 12px; }
.mobile-topbar .menu-btn { width: 40px; height: 40px; border-radius: 12px; border: none; background: var(--surface-nested, rgba(107,168,143,.08)); color: var(--text); display: grid; place-items: center; cursor: pointer; flex: 0 0 auto; }
.mobile-topbar .mobile-title { flex: 1 1 auto; min-width: 0; display: flex; flex-direction: column; gap: 2px; }
.mobile-topbar .mobile-title span { font-size: 15px; font-weight: 800; line-height: 1.1; }
.mobile-topbar .mobile-title small { font-size: 10.5px; opacity: .55; letter-spacing: .05em; }
.mobile-topbar .date-chip { display: inline-flex; align-items: center; gap: 5px; padding: 6px 10px; border-radius: 999px; background: var(--surface-nested, rgba(107,168,143,.08)); color: var(--text-secondary); font-size: 11.5px; font-weight: 700; flex: 0 0 auto; }

/* --- Scrim --- */
.scrim { position: fixed; inset: 0; background: color-mix(in srgb, var(--text) 42%, transparent); backdrop-filter: blur(2px); z-index: 40; opacity: 0; pointer-events: none; transition: opacity 0.22s; display: none !important; }
.scrim.show { opacity: 1; pointer-events: auto; display: block !important; }

/* --- Drawer（workbench-mobile dh/dclose/ditem/dsep/dfoot） --- */
.drawer { position: fixed; top: 0; bottom: 0; left: 0; width: 296px; max-width: 82vw; z-index: 50; transform: translateX(-104%); transition: transform 0.26s cubic-bezier(0.2, 0.8, 0.25, 1); overflow-y: auto; background: linear-gradient(180deg, var(--drawer-bg-top, #f4f8f6), var(--drawer-bg, #eef4f1)); color: var(--drawer-text, #2a3a32); display: none !important; }
.drawer.show, .drawer.open { transform: translateX(0); display: flex !important; flex-direction: column; }
.drawer .dh { padding: 26px 22px 18px; display: flex; align-items: center; gap: 12px; position: relative; }
.drawer .dh .brand { position: relative; width: 44px; height: 44px; border-radius: 12px; overflow: hidden; flex: 0 0 auto; background: var(--drawer-hover, rgba(42,58,50,.06)); box-shadow: 0 0 0 1px var(--drawer-active, rgba(107,168,143,.2)); cursor: pointer; }
.drawer .dh .brand img { width: 100%; height: 100%; object-fit: cover; display: block; }
.drawer .dh .brand .brand-cam { position: absolute; inset: 0; display: grid; place-items: center; opacity: 0; background: color-mix(in srgb, var(--text) 50%, transparent); color: #fff; transition: opacity 0.15s; }
.drawer .dh .brand:active .brand-cam { opacity: 1; }
.drawer .dh h2 { font-size: 17px; font-weight: 800; margin: 0; }
.drawer .dh p { font-size: 11px; opacity: 0.55; margin: 3px 0 0; letter-spacing: 0.05em; }
.drawer .dclose { position: absolute; top: 18px; right: 16px; width: 32px; height: 32px; border-radius: 12px; border: none; cursor: pointer; background: var(--drawer-hover, rgba(42,58,50,.06)); color: var(--drawer-text, #2a3a32); display: grid; place-items: center; }
.drawer .dsep { height: 1px; background: var(--drawer-active, rgba(107,168,143,.2)); margin: 6px 22px 8px; }
.drawer #drawerList { padding: 4px 0 10px; display: flex; flex-direction: column; }
.drawer .ditem { display: flex; align-items: center; gap: 13px; padding: 12px 22px; cursor: pointer; font-size: 15px; font-weight: 500; color: rgba(42,58,50,.82); }
.drawer .ditem svg, .drawer .ditem .di-icon { color: var(--drawer-text-mute, #6a8579); font-size: 18px; }
.drawer .ditem.active { background: var(--drawer-active, rgba(107,168,143,.18)); color: var(--drawer-text, #2a3a32); font-weight: 700; }
.drawer .ditem.active svg, .drawer .ditem.active .di-icon { color: var(--drawer-text, #2a3a32); }
.drawer .dfoot { padding: 20px 22px 28px; display: flex; flex-direction: column; gap: 8px; margin-top: auto; }
.drawer .drawer-foot-btn { padding: 11px 14px; border-radius: 12px; border: 1px solid var(--drawer-active, rgba(107,168,143,.2)); background: var(--drawer-hover, rgba(42,58,50,.04)); color: var(--drawer-text, #2a3a32); font-size: 13.5px; font-weight: 600; cursor: pointer; text-align: left; }
.drawer .drawer-foot-btn:hover, .drawer .drawer-foot-btn:active { background: var(--drawer-active, rgba(107,168,143,.18)); }
.drawer .dfoot-tip { font-size: 11px; opacity: 0.45; margin-top: 6px; }

/* --- Mobile 3项底栏 Nav --- */
.mobile-nav { position: fixed; left: 50%; transform: translateX(-50%); bottom: 0; width: 100%; max-width: 480px; height: 56px; background: rgba(252, 251, 248, 0.92); backdrop-filter: blur(14px); border-top: 1px solid var(--border); display: none; grid-template-columns: repeat(3, 1fr); align-items: center; z-index: 30; padding-bottom: env(safe-area-inset-bottom); }
.mobile-nav .n { display: flex; flex-direction: column; align-items: center; gap: 4px; cursor: pointer; color: var(--text-tertiary); font-size: 10px; font-weight: 500; }
.mobile-nav .n.active { color: var(--accent, #6BA88F); font-weight: 700; }

/* --- Overlay + Sheet Modal（底部 sheet + grabber） --- */
.overlay { position: fixed; inset: 0; background: color-mix(in srgb, var(--text) 44%, transparent); backdrop-filter: blur(3px); z-index: 60; display: none; align-items: flex-end; justify-content: center; }
.overlay.open { display: flex; }
.overlay .modal { background: var(--surface-card); border-radius: 24px 24px 0 0; padding: 22px 20px calc(22px + env(safe-area-inset-bottom)); width: 100%; max-width: 480px; box-shadow: 0 -20px 50px color-mix(in srgb, var(--text) 24%, transparent); max-height: 88vh; overflow-y: auto; }
.overlay .modal .grab { width: 40px; height: 4px; border-radius: 999px; background: var(--border-input); margin: 0 auto 16px; }

/* --- Breakpoint 900px --- */
@media (max-width: 900px) {
  aside.sidebar, aside#nav, nav.nav { display: none !important; }
  .mobile-topbar { display: flex !important; }
  .scrim { display: block !important; }
  .drawer { display: flex !important; }
  .mobile-nav { display: grid !important; }
  .layout, main.main, .main { margin-left: 0 !important; padding: 64px 12px 70px 12px !important; }
  #screen { padding-top: 8px; }
  #tabbar { display: none !important; }
}
@media (min-width: 901px) {
  .mobile-topbar, .mobile-nav, .scrim, .drawer { display: none !important; }
  #tabbar { display: none !important; }
  button#btn-menu { display: none !important; }
  aside.sidebar { display: block !important; }
}
"@

$src3 = $src2.Remove($cssStart, $cssEndPos - $cssStart).Insert($cssStart, $newCss)
Write-Output "2) CSS replaced OK ($($newCss.Length) chars)"

[System.IO.File]::WriteAllText($path, $src3, [System.Text.Encoding]::UTF8)
Write-Output "Saved OK, new size: $((Get-Item $path).Length)"
