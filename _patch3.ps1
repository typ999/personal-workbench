$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$f = Join-Path $PWD 'workbench.html'
$c = [System.IO.File]::ReadAllText($f)
Write-Host "Loaded: $($c.Length) chars"

$drawerJS = @"


// ========== Mobile Drawer & Tabbar ==========
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
  (window.navItems||[]).forEach(it=>{
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
  if(av && st.avatar) av.src=st.avatar;
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

$old = "}else{`ntry{`n  buildNav();"
$idx = $c.LastIndexOf($old)
if ($idx -lt 0) { Write-Error "Pattern not found!"; exit 1 }
Write-Host "Inserting drawer JS at char $idx"
$c = $c.Insert($idx, $drawerJS)

[System.IO.File]::WriteAllText($f, $c, [System.Text.UTF8Encoding]::new($false))
Write-Host "DONE. New size: $($c.Length)"

# Verify
$c2 = [System.IO.File]::ReadAllText($f)
$checks = @('btn-menu','id="scrim"','class="drawer"','id="tabbar"','function buildDrawer','function openDrawer','function closeDrawer','drawerOpen','id="drawerList"','id="drawerClose"')
foreach($ch in $checks){
  $ok = $c2.Contains($ch)
  Write-Host "  $ch : $(if($ok){'OK'}else{'MISSING'})"
}
