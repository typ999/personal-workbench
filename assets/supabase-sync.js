/* =============================================================================
 *  assets/supabase-sync.js —— 个人工作台 多端同步 & 邮箱登录适配层
 *  架构：GitHub Pages 纯静态前端 + Supabase JS SDK v2（客户端直连）
 *  安全原则（经验 2321696）：此文件仅包含 Project URL + anon public key
 *    绝对禁止写入 service_role key / 数据库密码 / 任何带写全表权限的凭据
 *    数据行级权限由 PostgreSQL RLS 保护（auth.uid() = owner / id），
 *    anon key 是 Supabase 官方推荐前端架构，公开可见不影响安全。
 *  合并策略（经验 1469941）：LWW —— Last Write Wins（基于 profiles.updated_at_ms）
 *    离线写入排队（localStorage __sync_pending），下次联网 flush。
 *  依赖：在 HTML 中先引入：
 *    <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
 * =========================================================================== */
(function () {
  "use strict";

  /* ============= 🔐 用户部署前必须替换成自己项目的值（Project Settings → API） ============= */
  const SUPABASE_URL = "https://dfurltpxfgmpvucqtylg.supabase.co";   // ← 替换成你自己的 Project URL
  const SUPABASE_ANON_PUBLIC_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRmdXJsdHB4ZmdtcHZ1Y3F0eWxnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg0NjQwNTgsImV4cCI6MjEwNDA0MDA1OH0.hf5euqq1IRsQB6xt70T0iqcsDPkPGdT4rPQLuM6NQKc"; // anon public key（RLS 保护，公开安全）
  /* ============= 🔐 END 可替换区域 =========================================================== */

  const LS_PENDING_KEY = "__sync_pending_queue";
  const LS_LAST_PUSH_MS = "__sync_last_push_ms";
  const LS_LAST_PULL_MS = "__sync_last_pull_ms";

  // ---------------- 基础工具 ----------------
  const nowMs = () => Date.now();
  const readLS = (k, fallback) => {
    try { const v = localStorage.getItem(k); return v ? JSON.parse(v) : fallback; } catch (e) { return fallback; }
  };
  const writeLS = (k, v) => { try { localStorage.setItem(k, JSON.stringify(v)); } catch (e) {} };
  const removeLS = (k) => { try { localStorage.removeItem(k); } catch (e) {} };

  // ---------------- Supabase 客户端（延迟加载 + 降级） ----------------
  let supabase = null;
  let sdkReady = false;
  let lastError = null;
  const initSupabase = () => {
    if (sdkReady) return supabase;
    if (typeof window.supabase !== "undefined" && typeof window.supabase.createClient === "function") {
      try {
        supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_PUBLIC_KEY, {
          auth: {
            persistSession: true,
            autoRefreshToken: true,
            detectSessionInUrl: true, // 默认从 URL hash 解析 OTP 登录回调
            storage: localStorage
          }
        });
        sdkReady = true;
        // 监听认证状态变化（首次登录 / OTP 回调 / 切换账号）
        supabase.auth.onAuthStateChange((evt, session) => {
          if (evt === "SIGNED_IN" && session && session.user) {
            // 登录成功后 500ms 拉一次云端同步
            setTimeout(() => pullCloud(true), 500);
          }
          if (evt === "SIGNED_OUT") {
            // 退出登录时清空本地同步时间戳，下次登录时强制对比一次
            removeLS(LS_LAST_PUSH_MS);
            removeLS(LS_LAST_PULL_MS);
          }
          // 触发 UI 刷新（设置页卡片会监听）
          document.dispatchEvent(new CustomEvent("sync:auth-change", { detail: { evt, session } }));
        });
      } catch (e) {
        lastError = "初始化失败：" + e.message;
        sdkReady = true;
      }
    }
    return supabase;
  };

  // 尝试初始化（CDN 未加载成功就静默降级，不影响本地使用）
  window.addEventListener("DOMContentLoaded", () => {
    try { initSupabase(); } catch (e) { lastError = e.message; }
  });

  // ---------------- 登录状态 ----------------
  async function currentUser() {
    initSupabase();
    if (!supabase) return null;
    try {
      const { data: { user } } = await supabase.auth.getUser();
      return user || null;
    } catch (e) { return null; }
  }

  // ---------------- UI：登录弹层 ----------------
  function openLoginModal() {
    initSupabase();
    const isLoggedIn = !!supabase && !!getCachedSession();
    // 已登录：显示退出登录 + 同步状态
    showSyncModal(isLoggedIn ? "logged" : "login");
  }

  function getCachedSession() {
    try { return readLS("sb-" + SUPABASE_URL.split("https://")[1].split(".")[0] + "-auth-token", null); }
    catch (e) { return null; }
  }

  // 创建弹层 DOM（用内联样式，不依赖 HTML 里已有的 overlay 结构，跨 desktop/mobile 都能用）
  function ensureSyncModal() {
    let m = document.getElementById("__sync_modal_mask");
    if (m) return m;
    m = document.createElement("div");
    m.id = "__sync_modal_mask";
    m.style.cssText = "position:fixed;inset:0;background:rgba(0,0,0,0.45);z-index:9999999;display:grid;place-items:center;padding:20px;";
    m.onclick = (e) => { if (e.target === m) m.style.display = "none"; };
    document.body.appendChild(m);
    return m;
  }

  function showSyncModal(mode) {
    const mask = ensureSyncModal();
    mask.style.display = "grid";
    let html = "";
    if (mode === "login") {
      html = `
        <div style="background:#fff;border-radius:14px;padding:20px 20px 16px;max-width:380px;width:100%;box-shadow:0 20px 60px rgba(0,0,0,0.2);color:#1c1c1e;font-family:system-ui,-apple-system,PingFang SC,sans-serif;">
          <div style="display:flex;align-items:center;gap:10px;margin-bottom:12px;">
            <div style="font-size:22px">📧</div>
            <div style="font-size:17px;font-weight:700;">邮箱登录 · 多端同步</div>
          </div>
          <div style="font-size:12px;color:#888;margin-bottom:16px;line-height:1.6">
            登录后，你的记账/待办/灵感/运动等全部数据将自动同步到云端，
            换手机/新电脑登录同一邮箱即可看到完全相同的数据。
          </div>
          <label style="font-size:13px;color:#333;display:block;margin-bottom:6px;">邮箱地址</label>
          <input id="__sync_email" type="email" placeholder="you@example.com" autocomplete="email"
                 style="width:100%;box-sizing:border-box;padding:10px 12px;border:1px solid #ddd;border-radius:10px;font-size:14px;margin-bottom:12px;outline:none;">
          <button id="__sync_send_otp"
                  style="width:100%;padding:11px;border:none;border-radius:10px;background:#6BA88F;color:#fff;font-weight:600;font-size:14px;cursor:pointer;">
            发送登录验证码
          </button>
          <div id="__sync_msg" style="margin-top:12px;font-size:12px;color:#888;line-height:1.6;min-height:1.5em;"></div>
          <div style="margin-top:16px;border-top:1px solid #eee;padding-top:12px;text-align:right;">
            <button id="__sync_close" style="background:none;border:none;color:#888;font-size:13px;cursor:pointer;">关闭</button>
          </div>
        </div>`;
    } else {
      const sess = getCachedSession();
      const email = (sess && sess.user && sess.user.email) || "已登录用户";
      const lastPush = readLS(LS_LAST_PUSH_MS, 0);
      const lastPull = readLS(LS_LAST_PULL_MS, 0);
      const fmt = (ms) => ms ? new Date(ms).toLocaleString("zh-CN") : "还没同步过";
      html = `
        <div style="background:#fff;border-radius:14px;padding:20px 20px 16px;max-width:380px;width:100%;box-shadow:0 20px 60px rgba(0,0,0,0.2);color:#1c1c1e;font-family:system-ui,-apple-system,PingFang SC,sans-serif;">
          <div style="display:flex;align-items:center;gap:10px;margin-bottom:12px;">
            <div style="font-size:22px">🔐</div>
            <div style="font-size:17px;font-weight:700;">已登录 · 云端同步</div>
          </div>
          <div style="background:#f7f8f7;border-radius:10px;padding:10px 12px;margin-bottom:12px;">
            <div style="font-size:12px;color:#888;">当前账号</div>
            <div style="font-size:14px;color:#333;font-weight:600;margin-top:2px;">${email}</div>
          </div>
          <div style="font-size:12px;color:#555;line-height:1.9;margin-bottom:12px;">
            <div>☁️ 上次从云端拉取：<b>${fmt(lastPull)}</b></div>
            <div>💾 上次推送到云端：<b>${fmt(lastPush)}</b></div>
          </div>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:12px;">
            <button id="__sync_pull_now" style="padding:10px;border:1px solid #6BA88F;background:#f2f7f4;color:#4f8370;border-radius:10px;font-size:13px;cursor:pointer;font-weight:600;">🔽 立即拉取</button>
            <button id="__sync_push_now" style="padding:10px;border:1px solid #6BA88F;background:#6BA88F;color:#fff;border-radius:10px;font-size:13px;cursor:pointer;font-weight:600;">🔼 立即推送</button>
          </div>
          <button id="__sync_signout"
                  style="width:100%;padding:10px;border:1px solid #f3c3c3;background:#fff;color:#c05050;border-radius:10px;font-weight:600;font-size:13px;cursor:pointer;">
            退出登录（仅退出本设备，云端数据保留）
          </button>
          <div id="__sync_msg" style="margin-top:12px;font-size:12px;color:#888;line-height:1.6;min-height:1.5em;"></div>
          <div style="margin-top:16px;border-top:1px solid #eee;padding-top:12px;text-align:right;">
            <button id="__sync_close" style="background:none;border:none;color:#888;font-size:13px;cursor:pointer;">关闭</button>
          </div>
        </div>`;
    }
    mask.innerHTML = html;
    // 绑定事件
    const $ = (id) => mask.querySelector(id);
    $("#__sync_close").onclick = () => mask.style.display = "none";

    if (mode === "login") {
      $("#__sync_send_otp").onclick = async () => {
        const email = $("#__sync_email").value.trim();
        const msg = $("#__sync_msg");
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) { msg.style.color = "#c05050"; msg.textContent = "请输入正确的邮箱地址"; return; }
        initSupabase(); if (!supabase) { msg.style.color = "#c05050"; msg.textContent = lastError || "Supabase SDK 加载失败（可能是网络问题，尝试开启 WARP 或刷新）"; return; }
        msg.style.color = "#888"; msg.textContent = "正在发送登录链接到你的邮箱…";
        const redirectTo = location.origin + location.pathname.replace(/[^/]*$/, "") + "workbench.html";
        try {
          const { error } = await supabase.auth.signInWithOtp({
            email,
            options: {
              emailRedirectTo: redirectTo,
              shouldCreateUser: true
            }
          });
          if (error) throw error;
          msg.style.color = "#4f8370";
          msg.innerHTML = "✅ 已发送，请打开邮箱点击邮件内的 <b>“Log in / 登录链接”</b>，会自动跳回本页面并登录。<br><span style=\"color:#888;font-size:11px\">💡 没收到邮件？1）检查垃圾箱 / 推广邮件；2）免费版邮件每天约 100 封限额，可能发送过多需要次日重试。</span>";
        } catch (e) {
          msg.style.color = "#c05050"; msg.textContent = "发送失败：" + e.message;
        }
      };
    } else {
      $("#__sync_pull_now").onclick = async () => { const msg = $("#__sync_msg"); msg.style.color = "#888"; msg.textContent = "正在从云端拉取…"; try { await pullCloud(true); msg.style.color = "#4f8370"; msg.textContent = "✅ 拉取完成，已合并到本地。如果有覆盖，数据以后写入时间为准。"; } catch (e) { msg.style.color = "#c05050"; msg.textContent = "拉取失败：" + e.message; } };
      $("#__sync_push_now").onclick = async () => { const msg = $("#__sync_msg"); msg.style.color = "#888"; msg.textContent = "正在推送到云端…"; try { await pushLocal(true); msg.style.color = "#4f8370"; msg.textContent = "✅ 推送完成，其他设备登录同一邮箱即可看到最新数据。"; } catch (e) { msg.style.color = "#c05050"; msg.textContent = "推送失败：" + e.message; } };
      $("#__sync_signout").onclick = async () => {
        if (!confirm("确定退出登录吗？\n\n退出后本设备的数据仍保留在本地，云端数据不会删除。下次登录同一邮箱会自动同步。")) return;
        try { await supabase.auth.signOut(); mask.style.display = "none"; alert("已退出登录。"); document.dispatchEvent(new CustomEvent("sync:auth-change")); }
        catch (e) { alert("退出失败：" + e.message); }
      };
    }
  }

  // ---------------- 同步核心：拉云端 + 推送本地 ----------------
  // 存储位置：public.profiles.settings.sync_blob（jsonb），profiles.updated_at_ms 做 LWW
  async function pullCloud(force) {
    initSupabase(); if (!supabase) throw new Error("Supabase SDK 未就绪");
    const user = await currentUser(); if (!user) throw new Error("未登录");
    const { data: profile, error } = await supabase
      .from("profiles")
      .select("updated_at_ms, settings")
      .eq("id", user.id)
      .limit(1)
      .maybeSingle();
    if (error) throw error;
    if (!profile || !profile.settings || !profile.settings.sync_blob) {
      // 云端还没有任何数据 → 推送一次本地数据上去初始化
      writeLS(LS_LAST_PULL_MS, nowMs());
      await pushLocal(false);
      return;
    }
    const cloudMs = profile.updated_at_ms || 0;
    const localMs = readLS(LS_LAST_PUSH_MS, 0) || (window.data && window.data.__updatedAtMs) || nowMs();
    const blob = profile.settings.sync_blob || {};
    // LWW：云端新 → 覆盖本地；本地新 → 推送本地
    if (!force && cloudMs <= localMs) {
      writeLS(LS_LAST_PULL_MS, nowMs());
      return;
    }
    // 覆盖本地：把 blob 写入 CONFIG.storageKey 的 localStorage
    const storageKey = (window.CONFIG && window.CONFIG.storageKey) || "workbench-personal-v2";
    try {
      localStorage.setItem(storageKey, JSON.stringify(blob));
      // 重新触发加载：调用原 store.load + 刷新 UI（调用 renderHome 若存在）
      if (window.store && typeof window.store.load === "function") {
        const newData = window.store.load();
        window.data = newData;
        if (typeof window.renderHome === "function") window.renderHome();
        if (typeof window.renderModule === "function" && window.lastModule) window.renderModule(window.lastModule);
      }
      writeLS(LS_LAST_PULL_MS, nowMs());
    } catch (e) { throw new Error("写入本地失败：" + e.message); }
  }

  async function pushLocal(force) {
    initSupabase(); if (!supabase) throw new Error("Supabase SDK 未就绪");
    const user = await currentUser(); if (!user) throw new Error("未登录");
    const storageKey = (window.CONFIG && window.CONFIG.storageKey) || "workbench-personal-v2";
    const raw = localStorage.getItem(storageKey);
    if (!raw) throw new Error("本地数据为空，先正常使用一次工作台再推送");
    let blob; try { blob = JSON.parse(raw); } catch (e) { throw new Error("本地 JSON 解析失败"); }
    const newMs = nowMs();
    const { error } = await supabase.rpc("fn_upsert_sync_blob", {
      p_user_id: user.id,
      p_sync_blob: blob,
      p_updated_at_ms: newMs
    });
    // 如果 RPC 没建（0003 还没运行），退化成前端 upsert profiles
    if (error && /function.*fn_upsert_sync_blob.*does not exist|does not exist/i.test(error.message || "")) {
      const payload = {
        id: user.id,
        settings: { sync_blob: blob },
        updated_at_ms: newMs
      };
      const { error: err2 } = await supabase.from("profiles").upsert(payload, { onConflict: "id" });
      if (err2) throw err2;
    } else if (error) {
      throw error;
    }
    writeLS(LS_LAST_PUSH_MS, newMs);
  }

  // ---------------- store 包装：每次保存自动双写云端（失败则排队） ----------------
  function hookStore(originalStore) {
    const origSave = originalStore.save.bind(originalStore);
    originalStore.save = function syncWrappedSave() {
      const ret = origSave.apply(originalStore, arguments);
      // 异步尝试推送（不阻塞 UI）
      (async () => {
        try {
          const u = await currentUser();
          if (u) await pushLocal(false);
        } catch (e) {
          // 网络失败：放入 pending 队列，下次 online 事件 flush
          const pending = readLS(LS_PENDING_KEY, []);
          pending.push({ t: nowMs(), e: e.message });
          // 只保留最近 20 条避免无限增长
          writeLS(LS_PENDING_KEY, pending.slice(-20));
        }
      })();
      return ret;
    };
    return originalStore;
  }

  // flush 队列
  async function flushPending() {
    const pending = readLS(LS_PENDING_KEY, []);
    if (!pending.length) return;
    try { const u = await currentUser(); if (u) { await pushLocal(false); writeLS(LS_PENDING_KEY, []); } }
    catch (e) { /* 下次再试 */ }
  }
  window.addEventListener("online", () => setTimeout(flushPending, 1500));
  // 页面加载 3s 后尝试 flush 一次
  setTimeout(flushPending, 3000);

  // ---------------- 设置页卡片 HTML（Mobile / Desktop 设置页会拼入此卡片） ----------------
  function settingsCardHTML() {
    // 登录状态异步取，这里先返回一个静态壳，点击按钮弹层
    return `<div class="settings-section" style="background:linear-gradient(135deg, color-mix(in srgb, #6BA88F 10%, var(--surface-card)), var(--surface-card) 60%);border:1px solid color-mix(in srgb, #6BA88F 22%, var(--border));border-radius:14px;padding:14px 14px 12px;margin-bottom:12px">
      <div style="display:flex;align-items:flex-start;gap:10px">
        <div style="font-size:22px;line-height:1.2">☁️</div>
        <div style="flex:1;min-width:0">
          <div style="font-size:15px;font-weight:700;color:var(--text)">邮箱登录 · 多端自动同步</div>
          <div style="font-size:12px;color:var(--text-secondary);line-height:1.6;margin-top:4px">
            登录后，你的记账/待办/灵感/运动/金币等全部数据会自动同步云端；换手机或新电脑登录同一邮箱 → 自动看到完全相同的数据。
          </div>
          <button id="__sync_open_btn" class="btn" style="margin-top:10px;padding:9px 14px;background:#6BA88F;color:#fff;border:none;border-radius:10px;font-weight:600;font-size:13px;cursor:pointer">
            📧 打开登录 / 同步管理
          </button>
        </div>
      </div>
    </div>`;
  }

  // 绑定设置页按钮（render 设置后事件委托）
  document.addEventListener("click", (e) => {
    const btn = e.target.closest("#__sync_open_btn");
    if (btn) { e.preventDefault(); openLoginModal(); }
  });

  // ---------------- 导出到全局 ----------------
  window.Sync = {
    open: openLoginModal,
    hookStore,
    pullCloud,
    pushLocal,
    currentUser,
    settingsCardHTML,
    getError: () => lastError
  };
})();
