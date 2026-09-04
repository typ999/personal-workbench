$f = 'c:\Users\59643\Desktop\个人工作台\workbench.html'
$c = [System.IO.File]::ReadAllText($f)
$pattern = '(?s)<!-- Mobile: 底部 Tabbar -->.*?</div>\s*\s*<script>'
$new = @"
  <!-- Mobile: 底部 Tabbar -->
  <div class="nav" id="tabbar">
  <div class="n active" data-nav="home"><svg viewBox="0 0 24 24" width="21" height="21" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 11.5 12 5l8 6.5"></path><path d="M6 10.5V19h12v-8.5"></path></svg><span>首页</span></div>
  <div class="n" data-nav="drawer"><svg viewBox="0 0 24 24" width="21" height="21" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="4" width="7" height="7" rx="1.6"></rect><rect x="13" y="4" width="7" height="7" rx="1.6"></rect><rect x="4" y="13" width="7" height="7" rx="1.6"></rect><rect x="13" y="13" width="7" height="7" rx="1.6"></rect></svg><span>模块</span></div>
  <div class="n" data-nav="insight"><svg viewBox="0 0 24 24" width="21" height="21" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20V4"></path><path d="M4 20h16"></path><path d="M8 16v-4"></path><path d="M12 16v-7"></path><path d="M16 16v-2"></path></svg><span>洞察</span></div>
  </div>

<script>
"@
$m = [regex]::Match($c, $pattern)
Write-Output "MATCH=$($m.Success)"
if ($m.Success) {
    $c = [regex]::Replace($c, $pattern, $new)
    [System.IO.File]::WriteAllText($f, $c)
    Write-Output "DONE - tabbar fixed"
} else {
    Write-Output "NO MATCH - keeping original"
}
