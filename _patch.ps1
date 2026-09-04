Set-Location $PSScriptRoot
$f = Join-Path $PWD 'workbench.html'
Write-Host "Target: $f"
if(-not (Test-Path $f)) { Write-Host "FAIL: file not found"; exit 1 }
$c = [System.IO.File]::ReadAllText($f)
Write-Host "File loaded, length=$($c.Length)"

# === 修改1: 在 sidebar </aside> 后、<!-- main --> 前插入 mobile chrome HTML ===
$old1 = "  </aside>`n  <!-- main -->`n  <main class=`"main`"><div id=`"screen`">"
$new1 = @"
  </aside>
  <!-- mobile chrome -->
  <button id="btn-menu" aria-label="Open menu"><svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 7h16"></path><path d="M4 12h16"></path><path d="M4 17h16"></path></svg></button>
  <div class="scrim" id="scrim"></div>
  <aside class="drawer" id="drawer">
    <div class="dh">
      <div class="drawer-brand" id="drawerBrand"><div class="brand"><span id="drawerBrandText">W</span></div></div>
      <div><h2 id="drawerName">Workbench</h2><p id="drawerSlogan">All-in-one productivity</p></div>
      <button class="dclose" id="drawerClose" aria-label="Close"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 6l12 12M18 6 6 18"></path></svg></button>
    </div>
    <div class="dsep"></div>
    <div id="drawerList"></div>
    <div class="dsep"></div>
    <div class="dfoot" id="drawerFoot">Data stored locally</div>
  </aside>
  <div id="tabbar">
    <div class="n active" data-nav="home"><svg viewBox="0 0 24 24" width="21" height="21" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 11.5 12 5l8 6.5"></path><path d="M6 10.5V19h12v-8.5"></path></svg><span>Home</span></div>
    <div class="n" data-nav="modules"><svg viewBox="0 0 24 24" width="21" height="21" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="4" width="7" height="7" rx="1.6"></rect><rect x="13" y="4" width="7" height="7" rx="1.6"></rect><rect x="4" y="13" width="7" height="7" rx="1.6"></rect><rect x="13" y="13" width="7" height="7" rx="1.6"></rect></svg><span>Modules</span></div>
    <div class="n" data-nav="insight"><svg viewBox="0 0 24 24" width="21" height="21" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20V4"></path><path d="M4 20h16"></path><path d="M8 16v-4"></path><path d="M12 16v-7"></path><path d="M16 16v-2"></path></svg><span>Insight</span></div>
  </div>
  <!-- main -->
  <main class="main"><div id="screen">
"@

if(-not $c.Contains($old1)) { Write-Host "FAIL: old1 not found"; exit 1 }
$c = $c.Replace($old1, $new1)
Write-Host "OK1: inserted mobile HTML"

# === 修改2: 在 buildNav() 函数结束后插入 drawer JS ===
$funcStart = "function buildNav(){"
$idx2 = $c.IndexOf($funcStart)
if($idx2 -lt 0) { Write-Host "FAIL: buildNav not found"; exit 1 }
$braceCount = 0
$endIdx = -1
for($i = $idx2; $i -lt $c.Length; $i++) {
    if($c[$i] -eq '{') { $braceCount++ }
    elseif($c[$i] -eq '}') { $braceCount--; if($braceCount -eq 0) { $endIdx = $i; break } }
}
if($endIdx -lt 0) { Write-Host "FAIL: buildNav end not found"; exit 1 }

$drawerJS = @"

/* ========== Mobile Drawer + Tabbar ========== */
function buildDrawer(){
  var dn=document.getElementById('drawerName'); if(dn) dn.textContent=(window.CONFIG&&CONFIG.owner)||'个人工作台';
  var ds=document.getElementById('drawerSlogan'); if(ds) ds.textContent=(window.CONFIG&&CONFIG.slogan)||'全场景生活效率整合平台';
  var dl=document.getElementById('drawerList');
  if(dl){
    var items=['<div class="ditem" data-go="home">'+(typeof icon==='function'?icon('home',20):'')+'首页</div>'];
    if(window.CONFIG&&Array.isArray(CONFIG.modules)){
      CONFIG.modules.forEach(function(m){ items.push('<div class="ditem" data-go="'+m.key+'">'+(typeof icon==='function'?icon(m.icon,20):'')+m.name+'</div>'); });
    }
    items.push('<div class="ditem" data-go="insight">'+(typeof icon==='function'?icon('chart',20):'')+'洞察</div>');
    dl.innerHTML=items.join('');
    dl.querySelectorAll('[data-go]').forEach(function(el){ el.onclick=function(){ if(typeof closeDrawer==='function') closeDrawer(); if(typeof go==='function') go(el.dataset.go); }; });
  }
}
function openDrawer(){
  var dl=document.getElementById('drawerList'); if(dl){ dl.querySelectorAll('.ditem').forEach(function(el){ el.classList.toggle('active', el.dataset.go===window.view); }); }
  var d=document.getElementById('drawer'); if(d) d.classList.add('show');
  var sc=document.getElementById('scrim'); if(sc) sc.classList.add('show');
}
function closeDrawer(){
  var d=document.getElementById('drawer'); if(d) d.classList.remove('show');
  var sc=document.getElementById('scrim'); if(sc) sc.classList.remove('show');
}
(function wireMobileChrome(){
  var bm=document.getElementById('btn-menu'); if(bm) bm.onclick=openDrawer;
  var dc=document.getElementById('drawerClose'); if(dc) dc.onclick=closeDrawer;
  var sc=document.getElementById('scrim'); if(sc) sc.onclick=closeDrawer;
  var tb=document.getElementById('tabbar');
  if(tb){
    tb.querySelectorAll('.n').forEach(function(n){
      n.onclick=function(){
        var t=n.dataset.nav;
        tb.querySelectorAll('.n').forEach(function(x){ x.classList.remove('active'); });
        n.classList.add('active');
        if(t==='modules') openDrawer();
        else if(typeof go==='function') go(t);
      };
    });
  }
})();
"@

$c = $c.Insert($endIdx + 1, $drawerJS)
Write-Host "OK2: inserted drawer JS"

# === 修改3: 更新初始化链 ===
$old3 = "    buildNav();`n    render();"
$new3 = "    buildNav();`n    buildDrawer();`n    startClock();`n    render();"
if(-not $c.Contains($old3)) { Write-Host "FAIL: init pattern not found"; exit 1 }
$c = $c.Replace($old3, $new3)
Write-Host "OK3: updated init chain"

[System.IO.File]::WriteAllText($f, $c, (New-Object System.Text.UTF8Encoding $false))
Write-Host "DONE: saved, length=$($c.Length)"
