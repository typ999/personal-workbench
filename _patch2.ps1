$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$f = Join-Path $PWD 'workbench.html'
$c = [System.IO.File]::ReadAllText($f)
Write-Host "File loaded: $($c.Length) chars"

# ==================== STEP 1: Insert mobile HTML between </aside> and <!-- main --> ====================
$old1 = "  </aside>`n  <!-- main -->"
$idx1 = $c.IndexOf($old1)
if ($idx1 -lt 0) { Write-Error "OLD1 not found"; exit 1 }
Write-Host "OLD1 found at char $idx1"

$mobileHtml = @"

  <!-- Mobile: hamburger button -->
  <button id="btn-menu" aria-label="菜单">
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
  </button>
  <!-- Mobile: scrim (overlay) -->
  <div class="scrim" id="scrim"></div>
  <!-- Mobile: drawer sidebar -->
  <aside class="drawer" id="drawer">
    <div class="drawer-head">
      <div class="brand">
        <div class="ava"><img id="drawer-ava" alt="头像"><canvas width="92" height="92"></canvas></div>
        <div>
          <h1 id="drawer-nick">个人工作台</h1>
          <p id="drawer-sub">记录每一天</p>
        </div>
      </div>
      <button id="drawerClose" aria-label="关闭">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
    </div>
    <nav class="drawer-nav" id="drawerList"></nav>
    <div class="drawer-foot">
      <button class="drawer-btn" id="drawer-settings">⚙ 设置</button>
      <button class="drawer-btn" id="drawer-export">📦 导出</button>
    </div>
  </aside>
  <!-- Mobile: bottom tabbar -->
  <nav id="tabbar">
    <button class="tab-btn" data-key="home"><span class="ti">🏠</span><span class="tl">首页</span></button>
    <button class="tab-btn" data-key="todo"><span class="ti">✅</span><span class="tl">待办</span></button>
    <button class="tab-btn" data-key="progress"><span class="ti">📈</span><span class="tl">进度</span></button>
    <button class="tab-btn" data-key="wealth"><span class="ti">💰</span><span class="tl">记账</span></button>
    <button class="tab-btn" data-key="me"><span class="ti">👤</span><span class="tl">我的</span></button>
  </nav>
"@

$c = $c.Insert($idx1, $mobileHtml)
Write-Host "STEP 1 OK: mobile HTML inserted"

# ==================== STEP 2: Insert drawer JS functions after buildNav ====================
$old2 = "function buildNav(){ var el=document.querySelector('aside.sidebar .nav'); if(!el) return; el.innerHTML='';"
$idx2 = $c.IndexOf($old2)
if ($idx2 -lt 0) { Write-Error "OLD2 (buildNav) not found"; exit 1 }
Write-Host "STEP 2: found buildNav at char $idx2"

# Find end of buildNav function - after renderNav(el) call and closing brace
$afterBuildNav = $c.IndexOf('buildNav();', $idx2)
if ($afterBuildNav -lt 0) { Write-Error "after-buildNav marker not found"; exit 1 }
# The function body ends before the call site... wait, let's find the real function end
# Actually let's find the pattern right after the function definition
# Pattern: after the function closing brace and before next function
$nextFn = $c.IndexOf("`nfunction ", $idx2 + 100)
if ($nextFn -lt 0) { Write-Error "next function marker not found"; exit 1 }
# Move back to find the } that closes buildNav
$braceEnd = $c.LastIndexOf('}', $nextFn)
Write-Host "  buildNav ends approx at char $braceEnd"

$drawerJS = @"


// ========== Mobile Drawer ==========
let drawerOpen=false;
function openDrawer(){
  drawerOpen=true;
  document.getElementById('drawer')?.classList.add('open');
  document.getElementById('scrim')?.classList.add('show');
  document.body.style.overflow='hidden';
}
function closeDrawer(){
  drawerOpen=false;
  document.getElementById('drawer')?.classList.remove('open');
  document.getElementById('scrim')?.classList.remove('show');
  document.body.style.overflow='';
}
function buildDrawer(){
  const list=document.getElementById('drawerList');
  if(!list) return;
  list.innerHTML='';
  navItems.forEach(it=>{
    const a=document.createElement('a');
    a.className='drawer-item';
    a.href='#';
    a.dataset.key=it.key;
    a.innerHTML='<span class="di-icon">'+it.icon+'</span><span class="di-label">'+it.label+'</span>';
    a.onclick=(e)=>{ e.preventDefault(); goto(it.key); closeDrawer(); };
    list.appendChild(a);
  });
  // avatar/nickname
  const nk=document.getElementById('drawer-nick');
  const av=document.getElementById('drawer-ava');
  const sub=document.getElementById('drawer-sub');
  const st=store?store.get('__settings')||{}:{};
  if(nk) nk.textContent=st.nickname||'个人工作台';
  if(av) {
    if(st.avatar) av.src=st.avatar;
    else {
      const can=av.nextElementSibling;
      if(can && can.tagName==='CANVAS') drawAvatarCanvas(can, st.nickname||'工作台');
    }
  }
  if(sub) sub.textContent='今日 '+dateStr();
  // wire close
  const dc=document.getElementById('drawerClose');
  if(dc) dc.onclick=closeDrawer;
  const sc=document.getElementById('scrim');
  if(sc) sc.onclick=closeDrawer;
  const bm=document.getElementById('btn-menu');
  if(bm) bm.onclick=openDrawer;
  const ds=document.getElementById('drawer-settings');
  if(ds) ds.onclick=()=>{ closeDrawer(); openSettings(); };
  const de=document.getElementById('drawer-export');
  if(de) de.onclick=()=>{ closeDrawer(); exportData(); };
  // wire tabbar
  document.querySelectorAll('#tabbar .tab-btn').forEach(btn=>{
    btn.onclick=()=>{
      const k=btn.dataset.key;
      if(k==='home') goto('home');
      else if(k==='me') goto('settings');
      else goto(k);
    };
  });
}
function updateTabbar(key){
  document.querySelectorAll('#tabbar .tab-btn').forEach(b=>{
    b.classList.toggle('active', b.dataset.key===key);
  });
}
"@

$c = $c.Insert($braceEnd + 1, $drawerJS)
Write-Host "STEP 2 OK: drawer JS inserted after buildNav"

# ==================== STEP 3: Write back ====================
[System.IO.File]::WriteAllText($f, $c, [System.Text.UTF8Encoding]::new($false))
Write-Host "DONE. New size: $($c.Length) chars"
