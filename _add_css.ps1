$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$f = Join-Path $PWD 'workbench.html'
$c = [System.IO.File]::ReadAllText($f)
Write-Host "Loaded: $($c.Length) chars"

# Find media query boundaries
$mediaStart = $c.IndexOf('@media (max-width: 900px)')
Write-Host "Media query start: $mediaStart"

# Find matching closing brace
$braceCount = 0
$searchStart = $c.IndexOf('{', $mediaStart)
$endPos = -1
for($i = $searchStart; $i -lt $c.Length; $i++){
  $ch = $c[$i]
  if($ch -eq '{') { $braceCount++ }
  elseif($ch -eq '}') { 
    $braceCount-- 
    if($braceCount -eq 0){ $endPos = $i; break }
  }
}
Write-Host "Media query end: $endPos"
Write-Host "Media query content length: $($endPos - $mediaStart)"

$oldMedia = $c.Substring($mediaStart, $endPos - $mediaStart + 1)
Write-Host "Old media query first 300 chars:"
Write-Host $oldMedia.Substring(0, [Math]::Min(300, $oldMedia.Length))

# New complete mobile CSS
$newMedia = @"
/* ============ Mobile responsive (<=900px) ============ */
button#btn-menu { display: none; position: fixed; top: 14px; left: 14px; z-index: 100; width: 42px; height: 42px; border-radius: 12px; border: none; background: var(--card-bg); box-shadow: 0 2px 8px rgba(0,0,0,.1); color: var(--text); cursor: pointer; align-items: center; justify-content: center; }
button#btn-menu:hover { background: var(--hover); }
.drawer { position: fixed; top: 0; left: 0; width: 82%; max-width: 320px; height: 100vh; background: linear-gradient(180deg, #f4f8f6, #eef4f1); color: #2a3a32; z-index: 99; transform: translateX(-100%); transition: transform .28s cubic-bezier(.4,0,.2,1); display: flex; flex-direction: column; box-shadow: 4px 0 20px rgba(0,0,0,.12); }
.drawer.open { transform: translateX(0); }
.drawer .drawer-head { padding: 24px 20px 16px; border-bottom: 1px solid rgba(42,58,50,.08); display: flex; justify-content: space-between; align-items: flex-start; }
.drawer .drawer-head .brand { display: flex; gap: 12px; align-items: center; }
.drawer .drawer-head .ava { width: 48px; height: 48px; border-radius: 12px; overflow: hidden; background: #d8e5de; }
.drawer .drawer-head h1 { font-size: 16px; font-weight: 700; margin: 0; }
.drawer .drawer-head p { font-size: 11px; opacity: .6; margin: 2px 0 0; }
.drawer .drawer-head button { background: none; border: none; font-size: 20px; cursor: pointer; color: #2a3a32; padding: 4px; }
.drawer .drawer-nav { flex: 1; overflow-y: auto; padding: 8px 0; }
.drawer .drawer-item { display: flex; align-items: center; gap: 12px; padding: 12px 20px; color: #3d5148; text-decoration: none; font-size: 14px; border-radius: 0; transition: background .15s; }
.drawer .drawer-item:hover { background: rgba(42,58,50,.06); }
.drawer .drawer-item .di-icon { width: 28px; font-size: 16px; text-align: center; }
.drawer .drawer-foot { padding: 12px 20px 24px; border-top: 1px solid rgba(42,58,50,.08); display: flex; gap: 10px; }
.drawer .drawer-btn { flex: 1; padding: 10px; border: 1px solid rgba(42,58,50,.15); background: rgba(255,255,255,.6); border-radius: 10px; font-size: 12px; cursor: pointer; color: #3d5148; }
.drawer .drawer-btn:hover { background: #fff; }
.scrim { position: fixed; inset: 0; background: rgba(0,0,0,.35); z-index: 98; opacity: 0; visibility: hidden; transition: opacity .2s, visibility .2s; }
.scrim.show { opacity: 1; visibility: visible; }
#tabbar { position: fixed; bottom: 0; left: 0; right: 0; height: 56px; background: var(--card-bg); border-top: 1px solid var(--border); display: none; grid-template-columns: repeat(5, 1fr); z-index: 97; box-shadow: 0 -2px 12px rgba(0,0,0,.06); }
#tabbar .tab-btn { display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 2px; background: none; border: none; cursor: pointer; color: var(--text-mute); padding: 4px 0; font-size: 10px; }
#tabbar .tab-btn .ti { font-size: 20px; line-height: 1; }
#tabbar .tab-btn .tl { font-size: 10px; }
#tabbar .tab-btn.active { color: var(--primary, #6BA88F); }
#tabbar .tab-btn:hover { color: var(--primary, #6BA88F); }

@media (max-width: 900px) {
  aside.sidebar, aside#nav { display: none !important; }
  button#btn-menu { display: grid !important; }
  .scrim { display: block !important; }
  #tabbar { display: grid !important; }
  .layout { margin-left: 0 !important; padding-bottom: calc(var(--nav-h, 56px) + 10px) !important; }
  .main, main#content { margin-left: 0 !important; padding: 60px 12px 70px 12px !important; }
  .drawer { display: flex !important; }
}
"@

$c = $c.Replace($oldMedia, $newMedia)
Write-Host "`nReplaced media query block"

[System.IO.File]::WriteAllText($f, $c, [System.Text.UTF8Encoding]::new($false))
Write-Host "Saved. Size: $($c.Length)"

# Verify
$c2 = [System.IO.File]::ReadAllText($f)
Write-Host "`n=== CSS Verification ==="
Write-Host ".drawer.open: $($c2.Contains('.drawer.open'))"
Write-Host ".scrim.show: $($c2.Contains('.scrim.show'))"
Write-Host ".drawer-nav: $($c2.Contains('.drawer-nav'))"
Write-Host ".drawer-item: $($c2.Contains('.drawer-item'))"
Write-Host ".drawer-head: $($c2.Contains('.drawer-head'))"
Write-Host ".drawer-foot: $($c2.Contains('.drawer-foot'))"
Write-Host "#tabbar: $($c2.Contains('#tabbar'))"
Write-Host ".tab-btn: $($c2.Contains('.tab-btn'))"
Write-Host "btn-menu: $($c2.Contains('btn-menu'))"
