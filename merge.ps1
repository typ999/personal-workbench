# ============================================================
# 合并脚本: workbench-desktop.html + workbench-mobile.html → workbench.html
# ============================================================

$desktopPath = 'c:\Users\59643\Desktop\个人工作台\workbench.html'
$mobilePath  = 'c:\Users\59643\Desktop\个人工作台\workbench-mobile.html'
$outputPath  = 'c:\Users\59643\Desktop\个人工作台\workbench.html'

Write-Output "读取 desktop 基底..."
$desk = [System.IO.File]::ReadAllText($desktopPath, [System.Text.Encoding]::UTF8)
Write-Output "Desktop 长度: $($desk.Length)"

Write-Output "读取 mobile ..."
$mob = [System.IO.File]::ReadAllText($mobilePath, [System.Text.Encoding]::UTF8)
Write-Output "Mobile 长度: $($mob.Length)"

# ============================================================
# 1. 从 mobile 提取 HTML 片段
# ============================================================

# --- 汉堡按钮 ---
$btnMenuMatch = [regex]::Match($mob, '<button class="menu-btn" id="btn-menu">.*?</button>')
$btnMenuHTML = if ($btnMenuMatch.Success) { $btnMenuMatch.Value } else { '' }
Write-Output "汉堡按钮: $($btnMenuHTML.Length) chars"

# --- scrim ---
$scrimMatch = [regex]::Match($mob, '<div class="scrim" id="scrim"></div>')
$scrimHTML = if ($scrimMatch.Success) { $scrimMatch.Value } else { '<div class="scrim" id="scrim"></div>' }

# --- drawer ---
$drawerStart = $mob.IndexOf('<aside class="drawer" id="drawer">')
$drawerEnd   = $mob.IndexOf('</aside>', $drawerStart) + '</aside>'.Length
$drawerHTML  = $mob.Substring($drawerStart, $drawerEnd - $drawerStart)
Write-Output "Drawer: $($drawerHTML.Length) chars"

# --- bottom nav ---
$navStart = $mob.IndexOf('<div class="nav" id="nav">', $mob.IndexOf('<!-- bottom nav -->'))
$navEnd   = $mob.IndexOf('</div>', $navStart) + '</div>'.Length
$navHTML  = $mob.Substring($navStart, $navEnd - $navStart)
# 改 id 避免冲突
$tabbarHTML = $navHTML -replace 'id="nav"', 'id="tabbar"'
Write-Output "Tabbar: $($tabbarHTML.Length) chars"

# ============================================================
# 2. 定位 desktop 中的插入点
# ============================================================

$styleEndMarker = '</style></head>'
$styleEndIdx = $desk.IndexOf($styleEndMarker)
if ($styleEndIdx -lt 0) { Write-Error '找不到 </style></head>'; exit 1 }

$sidebarStartIdx = $desk.IndexOf('<aside class="sidebar">')
$sidebarEndIdx = $desk.IndexOf('  </aside>', $sidebarStartIdx)
if ($sidebarEndIdx -lt 0) { Write-Error '找不到 sidebar </aside>'; exit 1 }

$mainEndIdx = $desk.IndexOf('</main>')
if ($mainEndIdx -lt 0) { Write-Error '找不到 </main>'; exit 1 }

$buildNavIdx = $desk.IndexOf('function buildNav()')
if ($buildNavIdx -lt 0) { Write-Error '找不到 function buildNav()'; exit 1 }

Write-Output ''
Write-Output "位置确认: styleEnd=$styleEndIdx sidebarEnd=$sidebarEndIdx mainEnd=$mainEndIdx buildNav=$buildNavIdx"

# ============================================================
# 3. 准备 CSS（单引号 here-string，不做插值）
# ============================================================

$mobileCSS = @'

  /* ============ Mobile-only CSS ============ */
  :root { --nav-h: 56px; }
  
  button#btn-menu {
    position: fixed; top: 14px; left: 14px; z-index: 60;
    width: 40px; height: 40px; border: none; border-radius: 12px;
    background: var(--surface-card, #fff); box-shadow: 0 2px 10px rgba(0,0,0,.12);
    display: none; place-items: center; cursor: pointer; color: var(--text, #232220);
  }
  button#btn-menu:active { transform: scale(.94); }
  
  .scrim { position: fixed; inset: 0; background: color-mix(in srgb, var(--text) 42%, transparent); backdrop-filter: blur(2px); z-index: 40; opacity: 0; pointer-events: none; transition: opacity .22s; display: none; }
  .scrim.show { opacity: 1; pointer-events: auto; display: block; }
  
  .drawer { position: fixed; top: 0; bottom: 0; left: 0; width: 296px; max-width: 82vw; z-index: 50; transform: translateX(-104%);
    transition: transform .26s cubic-bezier(.2,.8,.25,1); overflow-y: auto; display: none;
    background: linear-gradient(180deg, var(--drawer-bg-top), var(--drawer-bg)); color: var(--drawer-text); }
  .drawer.show { transform: translateX(0); }
  .drawer .dh { padding: 26px 22px 18px; display: flex; align-items: center; gap: 12px; position: relative; }
  .drawer .dh .brand { position: relative; width: 44px; height: 44px; border-radius: var(--radius-tile); overflow: hidden; flex: 0 0 auto;
    background: var(--drawer-hover); box-shadow: 0 0 0 1px var(--drawer-active); cursor: pointer; }
  .drawer .dh .brand img { width: 100%; height: 100%; object-fit: cover; display: block; }
  .drawer .dh .brand .brand-cam { position: absolute; inset: 0; display: grid; place-items: center; opacity: 0;
    background: color-mix(in srgb, var(--text) 50%, transparent); color: var(--drawer-text); transition: opacity .15s; }
  .drawer .dh .brand:active .brand-cam { opacity: 1; }
  .drawer .dh h2 { font-size: 17px; font-weight: 800; }
  .drawer .dh p { font-size: 11px; opacity: .55; margin-top: 3px; letter-spacing: .05em; }
  .drawer .dclose { position: absolute; top: 18px; right: 16px; width: 32px; height: 32px; border-radius: var(--radius-tile); border: none; cursor: pointer;
    background: var(--drawer-hover); color: var(--drawer-text); display: grid; place-items: center; }
  .drawer .dsep { height: 1px; background: var(--drawer-active); margin: 6px 22px 8px; }
  .drawer .ditem { display: flex; align-items: center; gap: 13px; padding: 12px 22px; cursor: pointer; font-size: 15px; font-weight: 500; color: color-mix(in srgb, var(--drawer-text) 82%, transparent); }
  .drawer .ditem svg { color: var(--drawer-text-mute); }
  .drawer .ditem.active { background: var(--drawer-active); color: var(--drawer-text); font-weight: 700; }
  .drawer .ditem.active svg { color: var(--drawer-text); }
  .drawer .dfoot { font-size: 11px; opacity: .45; padding: 20px 22px 28px; }
  
  #tabbar { position: fixed; left: 50%; transform: translateX(-50%); bottom: 0; width: 100%; max-width: 480px; height: var(--nav-h, 56px);
    background: rgba(252, 251, 248, .92); backdrop-filter: blur(14px); border-top: 1px solid var(--border);
    display: none; grid-template-columns: repeat(3, 1fr); align-items: center; z-index: 30; padding-bottom: env(safe-area-inset-bottom); }
  #tabbar .n { display: flex; flex-direction: column; align-items: center; gap: 4px; cursor: pointer; color: var(--text-tertiary); font-size: 10px; font-weight: 500; }
  #tabbar .n.active { color: var(--accent); font-weight: 700; }
  
  /* ============ 响应式断点 ============ */
  @media (max-width: 900px) {
    aside.sidebar { display: none !important; }
    button#btn-menu { display: grid !important; }
    .drawer { display: block !important; }
    .scrim { display: block !important; }
    #tabbar { display: grid !important; }
    .layout { margin-left: 0 !important; padding-bottom: calc(var(--nav-h, 56px) + 10px) !important; }
    .main { margin-left: 0 !important; padding: 60px 12px 16px 12px !important; }
  }
  @media (min-width: 901px) {
    aside.sidebar { display: flex !important; }
    button#btn-menu { display: none !important; }
    .drawer { display: none !important; transform: translateX(-104%) !important; }
    .scrim { display: none !important; }
    #tabbar { display: none !important; }
  }
'@

# ============================================================
# 4. 准备 JS（单引号 here-string）
# ============================================================

$mobileJS = @'

/* ============ Mobile Drawer & Tabbar ============ */
function buildDrawer(){
  var dn = document.getElementById('drawerName'); if(dn) dn.textContent = (window.CONFIG && CONFIG.owner) ? CONFIG.owner : '个人工作台';
  var ds = document.getElementById('drawerSlogan'); if(ds) ds.textContent = (window.CONFIG && CONFIG.slogan) ? CONFIG.slogan : '';
  var iconFn = window.icon || function(n,w){ return '<span>'+n+'</span>'; };
  var mods = (window.CONFIG && CONFIG.modules) ? CONFIG.modules : [];
  var items = ['<div class="ditem" data-go="home">' + iconFn('home',20) + '首页</div>']
    .concat(mods.map(function(m){ return '<div class="ditem" data-go="' + m.key + '">' + iconFn(m.icon,20) + m.name + '</div>'; }))
    .concat(['<div class="ditem" data-go="insight">' + iconFn('chart',20) + '洞察</div>']);
  var dl = document.getElementById('drawerList');
  if(dl){
    dl.innerHTML = items.join('');
    dl.querySelectorAll('[data-go]').forEach(function(el){ el.onclick = function(){ if(window.go) window.go(el.dataset.go); }; });
  }
}
function openDrawer(){
  var view = window.view || 'home';
  var dl = document.getElementById('drawerList'); if(dl) dl.querySelectorAll('.ditem').forEach(function(el){ el.classList.toggle('active', el.dataset.go === view); });
  var d = document.getElementById('drawer'); if(d) d.classList.add('show');
  var sc = document.getElementById('scrim'); if(sc) sc.classList.add('show');
}
function closeDrawer(){ var d = document.getElementById('drawer'); if(d) d.classList.remove('show'); var sc = document.getElementById('scrim'); if(sc) sc.classList.remove('show'); }

(function(){
  var btnMenu = document.getElementById('btn-menu'); if(btnMenu) btnMenu.onclick = openDrawer;
  var dc = document.getElementById('drawerClose'); if(dc) dc.onclick = closeDrawer;
  var scrimEl = document.getElementById('scrim'); if(scrimEl) scrimEl.onclick = closeDrawer;
  var tabbar = document.getElementById('tabbar');
  if(tabbar) tabbar.querySelectorAll('.n').forEach(function(n){
    n.onclick = function(){
      var t = n.dataset.nav;
      if(t === 'drawer') openDrawer();
      else if(window.go) window.go(t);
    };
  });
  var bc = document.getElementById('brandCam'); if(bc && window.icon) bc.innerHTML = icon('camera',18);
  var db = document.getElementById('drawerBrand'); if(db) db.onclick = function(){ var ai = document.getElementById('avatarInput'); if(ai) ai.click(); };
})();
/* ============ END Drawer & Tabbar ============ */
'@

# ============================================================
# 5. 从后往前插入，避免位置偏移
# ============================================================

$result = $desk

# --- 5a. 先插入 JS（在 buildNav() 之前） ---
$result = $result.Insert($buildNavIdx, $mobileJS)
Write-Output '5a. JS 已插入 buildNav() 之前'

# 重新定位（因为插入后位置变了）
$buildNavIdx2 = $result.IndexOf('function buildNav()')
$mainEndIdx2 = $result.IndexOf('</main>')
$sidebarEndIdx2 = $result.IndexOf('  </aside>', $result.IndexOf('<aside class="sidebar">'))
$styleEndIdx2 = $result.IndexOf($styleEndMarker)

# --- 5b. 修改初始化链: buildNav(); render(); → buildNav(); buildDrawer(); startClock(); render(); ---
$oldInit = "buildNav();`r`n  render();"
$newInit = "buildNav();`r`n  buildDrawer();`r`n  startClock();`r`n  render();"
$initIdx = $result.IndexOf($oldInit)
if ($initIdx -lt 0) {
  $oldInit = "buildNav();`n  render();"
  $newInit = "buildNav();`n  buildDrawer();`n  startClock();`n  render();"
  $initIdx = $result.IndexOf($oldInit)
}
if ($initIdx -ge 0) {
  $result = $result.Substring(0, $initIdx) + $newInit + $result.Substring($initIdx + $oldInit.Length)
  Write-Output '5b. 初始化链已更新'
} else {
  Write-Output '5b. WARNING: 找不到初始化链，手动检查'
}

# 重新定位
$mainEndIdx3 = $result.IndexOf('</main>')
$sidebarEndIdx3 = $result.IndexOf('  </aside>', $result.IndexOf('<aside class="sidebar">'))
$styleEndIdx3 = $result.IndexOf($styleEndMarker)

# --- 5c. 在 sidebar </aside> 之后插入 汉堡按钮+scrim+drawer ---
$afterSidebar = $sidebarEndIdx3 + '  </aside>'.Length
$htmlToInsert = "`r`n  <!-- Mobile: btn-menu + scrim + drawer -->`r`n  $btnMenuHTML`r`n  $scrimHTML`r`n  $drawerHTML`r`n"
$result = $result.Insert($afterSidebar, $htmlToInsert)
Write-Output '5c. 汉堡按钮+scrim+drawer 已插入 sidebar 之后'

# 重新定位
$mainEndIdx4 = $result.IndexOf('</main>')
$styleEndIdx4 = $result.IndexOf($styleEndMarker)

# --- 5d. 在 </main> 之后插入 tabbar ---
$afterMain = $mainEndIdx4 + '</main>'.Length
$tabbarInsert = "`r`n`r`n  <!-- Mobile: 底部 Tabbar -->`r`n  $tabbarHTML`r`n"
$result = $result.Insert($afterMain, $tabbarInsert)
Write-Output '5d. Tabbar 已插入 </main> 之后'

# 重新定位
$styleEndIdx5 = $result.IndexOf($styleEndMarker)

# --- 5e. 在 </style></head> 之前插入 CSS ---
$result = $result.Insert($styleEndIdx5, $mobileCSS)
Write-Output '5e. CSS + 媒体查询 已插入 </style> 之前'

# ============================================================
# 6. 写回
# ============================================================

Write-Output ''
Write-Output "写入输出文件 ($($result.Length) chars)..."
[System.IO.File]::WriteAllText($outputPath, $result, [System.Text.Encoding]::UTF8)

# ============================================================
# 7. 自检
# ============================================================

Write-Output ''
Write-Output '========== 自检 =========='
$final = [System.IO.File]::ReadAllText($outputPath, [System.Text.Encoding]::UTF8)
Write-Output "最终文件大小: $($final.Length) chars"

$checks = @(
  @{name='drawer id=drawer';    pattern='id="drawer"'},
  @{name='drawerClose';         pattern='id="drawerClose"'},
  @{name='btn-menu';            pattern='id="btn-menu"'},
  @{name='scrim';               pattern='id="scrim"'},
  @{name='tabbar';              pattern='id="tabbar"'},
  @{name='drawerName';          pattern='id="drawerName"'},
  @{name='drawerList';          pattern='id="drawerList"'},
  @{name='buildDrawer()';       pattern='function buildDrawer'},
  @{name='openDrawer()';        pattern='function openDrawer'},
  @{name='closeDrawer()';       pattern='function closeDrawer'},
  @{name='buildNav()';          pattern='function buildNav'},
  @{name='startClock()';        pattern='function startClock'},
  @{name='drawer 媒体查询';     pattern='@media (max-width: 900px)'},
  @{name='sidebar 隐藏';        pattern='aside\.sidebar \{ display: none !important'},
  @{name='drawer 隐藏规则';     pattern='\.drawer \{ display: none !important'},
  @{name='tabbar JS 绑定';      pattern="getElementById\('tabbar'\)"}
)

$allOk = $true
foreach ($c in $checks) {
  $found = $final.Contains($c.pattern)
  $status = if ($found) { 'OK' } else { 'MISSING!' }
  if (-not $found) { $allOk = $false }
  Write-Output "  [$status] $($c.name)"
}

# 函数重复
Write-Output ''
Write-Output '函数重复:'
foreach ($fn in @('buildNav','buildDrawer','startClock','openDrawer','closeDrawer')) {
  $count = ([regex]::Matches($final, "function $fn\b")).Count
  Write-Output "  $fn : $count (应为 1)"
}

# 初始化链检查
Write-Output ''
Write-Output '初始化链:'
Write-Output "  buildDrawer 调用: $(if($final.Contains('buildDrawer();')){'OK'}else{'MISSING'})"
Write-Output "  startClock 调用: $(if($final.Contains('startClock();')){'OK'}else{'MISSING'})"

Write-Output ''
if ($allOk) {
  Write-Output '========== 全部通过! =========='
} else {
  Write-Output '========== 有项目缺失，检查上方 =========='
}
Write-Output "输出: $outputPath"
