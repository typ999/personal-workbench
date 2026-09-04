const CACHE="workbench-v5";
const ASSETS=["./workbench.html","./workbench-desktop.html","./workbench-mobile.html","./manifest.json"];

/* ===== Phase 2 · Service Worker 升级：系统级 Web Push + 通知点击跳转 ===== */
self.addEventListener("install",e=>{e.waitUntil(caches.open(CACHE).then(c=>c.addAll(ASSETS)).catch(()=>{}));self.skipWaiting();});
self.addEventListener("activate",e=>{e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==CACHE).map(k=>caches.delete(k)))));self.clients.claim();});

/* ===== 1) Web Push：收到推送 → 显示锁屏/状态栏通知 ===== */
self.addEventListener("push", e => {
  try {
    const data = e.data ? safeParse(e.data.text()) : null;
    if (!data) return;
    const payload = normalizePush(data);
    const opts = {
      body: payload.body || "个人工作台",
      icon: payload.icon || notificationIcon(),
      badge: payload.badge || notificationBadge(),
      image: payload.image || "",
      tag: payload.tag || ("wb-notif-" + Date.now()),
      renotify: !!payload.renotify,
      requireInteraction: !!payload.requireInteraction,
      silent: !!payload.silent,
      timestamp: Date.now(),
      vibrate: payload.vibrate || [200,80,200,80,200],
      data: {
        url: payload.url || "./workbench-mobile.html",
        type: payload.type || "general",
        payload: payload || null
      },
      actions: Array.isArray(payload.actions) ? payload.actions.slice(0,3) : []
    };
    e.waitUntil(self.registration.showNotification(payload.title || "个人工作台", opts));
  } catch(err) {
    // 兜底：至少显示一条文本通知
    try {
      e.waitUntil(self.registration.showNotification("个人工作台",{
        body: (e.data && e.data.text) ? String(e.data.text()).slice(0,140) : "你有一条新消息",
        icon: notificationIcon(), tag:"wb-fallback", data:{url:"./workbench-mobile.html"},
        vibrate:[150,60,150]
      }));
    } catch(_){}
  }
});

/* ===== 2) 点击通知：打开 URL / 聚焦已开窗口；点击 Action 按钮触发对应 URL ===== */
self.addEventListener("notificationclick", e => {
  try {
    e.notification.close();
    const data = (e.notification && e.notification.data) || {};
    const openUrl = e.action && data && data.payload && data.payload.actions
      ? pickActionUrl(data.payload.actions, e.action)
      : (data.url || "./workbench-mobile.html");
    if (!openUrl) return;
    e.waitUntil((async () => {
      // 优先：已打开的客户端（main page）→ 聚焦并 postMessage
      try {
        const all = await self.clients.matchAll({type:"window",includeUncontrolled:true});
        for (const c of all) {
          if (c.url && ("focus" in c)) {
            try { await c.focus(); if("postMessage" in c) c.postMessage({type:"wb:notification-click",action:e.action||null,data:data.payload||null}); return; } catch(_){}
          }
        }
      } catch(_){}
      // 次选：新开窗口
      try { if(self.clients.openWindow){ await self.clients.openWindow(absoluteUrl(openUrl)); } } catch(_){}
    })());
  } catch(_){}
});

self.addEventListener("notificationclose", e => {
  /* 通知关闭：可上报统计；为避免隐私/网络依赖这里默认什么都不做 */
});

/* ===== Fetch（Phase 1 原逻辑保留 + API 请求绕过 cache） ===== */
self.addEventListener("fetch",e=>{
  if(e.request.method!=="GET")return;
  const url=new URL(e.request.url);
  if(url.pathname.startsWith("/api/")) return; /* Vercel Functions 永远走网络，不能 cache */
  if(url.hostname && url.origin !== location.origin) return; /* 外部资源不参与 cache */
  // HTML 文件用 network-first，确保拿到最新版本
  const isHTML=url.pathname.endsWith(".html")||url.pathname==="/";
  if(isHTML){
    e.respondWith(fetch(e.request).then(r=>{if(r.ok&&e.request.url.startsWith(location.origin)){const rc=r.clone();caches.open(CACHE).then(cache=>cache.put(e.request,rc));}return r;}).catch(()=>caches.match(e.request).then(c=>c||Response.error())));
    return;
  }
  // 其他资源 cache-first
  e.respondWith(caches.match(e.request).then(c=>c||fetch(e.request).then(r=>{if(r.ok&&e.request.url.startsWith(location.origin)){const rc=r.clone();caches.open(CACHE).then(cache=>cache.put(e.request,rc));}return r;}).catch(()=>c)));
});

/* ============== 工具函数 ============== */
function safeParse(t){ try{ return JSON.parse(t); }catch(_){ return {title:String(t||"").slice(0,60), body:String(t||"").slice(0,180)}; } }
function normalizePush(d){
  // 兼容后端 4 类模板：morning(晨间套餐)/reminder(到期提醒)/coin(金币)/weekly(周报) — 传入 template 参数时自动拼文案
  if(d && typeof d === "object" && d.template && !d.title){
    switch(d.template){
      case "morning": return {
        title: d.title || "🌅 今日晨间套餐",
        body: d.body || "点击查看今日天气 + 3 条最重要待办",
        type: "morning", tag: "wb-morning", renotify: true, requireInteraction: false,
        url: d.url || "./workbench-mobile.html", vibrate:[220,120,220],
        icon: notificationIcon(), actions: [{action:"open",title:"查看今日"}]
      };
      case "reminder": return {
        title: d.title || "🔔 提醒到期",
        body: d.body || "有一条提醒事项今天到期",
        type: "reminder", tag: "wb-reminder-"+(d.id||""), renotify: true, requireInteraction: true,
        url: d.url || "./workbench-mobile.html#reminders", vibrate:[300,100,300,100,300],
        icon: notificationIcon(), actions: [{action:"done",title:"标记完成"},{action:"open",title:"查看详情"}]
      };
      case "coin": return {
        title: d.title || "🏆 金币里程碑达成",
        body: d.body || "点击查看当前余额与下一个里程碑",
        type: "coin", tag: "wb-coin", renotify: true, requireInteraction: false,
        url: d.url || "./workbench-mobile.html#coins", vibrate:[150,60,150,60,150,60,150],
        icon: notificationIcon()
      };
      case "weekly": return {
        title: d.title || "📊 本周周报已生成",
        body: d.body || "6 大板块总结已就绪，点击查看",
        type: "weekly", tag: "wb-weekly", renotify: true, requireInteraction: false,
        url: d.url || "./workbench-mobile.html#weekly", vibrate:[180,80,180,80,180],
        icon: notificationIcon(), actions: [{action:"open",title:"查看周报"}]
      };
    }
  }
  return d || {title:"个人工作台", body:""};
}
function pickActionUrl(actions, actionId){
  if(!Array.isArray(actions)||!actionId) return null;
  const found = actions.find(a => a && a.action===actionId);
  return found && found.url ? found.url : null;
}
function absoluteUrl(relOrAbs){
  if(!relOrAbs) return location.origin + "/workbench-mobile.html";
  if(/^https?:\/\//i.test(relOrAbs)) return relOrAbs;
  if(relOrAbs.charAt(0)==="/") return location.origin + relOrAbs;
  return location.origin + "/" + String(relOrAbs).replace(/^\.\//,"");
}
/* 通知图标：用主色卡片 + 🌿 小 logo（192×192，base64 SVG data url，保证离线/无网络也能显示） */
function notificationIcon(){
  try {
    return "data:image/svg+xml;utf8," + encodeURIComponent(
      "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 192 192'>"
      + "<rect width='192' height='192' rx='44' fill='%236BA88F'/>"
      + "<text x='96' y='126' font-size='92' text-anchor='middle' fill='white' font-family='Segoe UI Emoji,Apple Color Emoji,Arial' dominant-baseline='middle'>🌿</text>"
      + "</svg>"
    );
  } catch(_) { return ""; }
}
function notificationBadge(){
  try {
    return "data:image/svg+xml;utf8," + encodeURIComponent(
      "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'>"
      + "<circle cx='12' cy='12' r='12' fill='%236BA88F'/>"
      + "<text x='12' y='16' font-size='14' text-anchor='middle' fill='white' font-family='Segoe UI Emoji,Apple Color Emoji,Arial' dominant-baseline='middle'>🌿</text>"
      + "</svg>"
    );
  } catch(_){ return ""; }
}
