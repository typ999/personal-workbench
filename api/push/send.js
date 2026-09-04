// /api/push/send.js — 向后端请求：给指定 endpoint 立即发一条推送（测试用 + 前端手动触发）
// Phase 2：所有 4 种模板（morning / reminder / coin / weekly）+ 自定义 title/body 都走这里统一分发 web-push.sendNotification
import webpush from "web-push";
import { createClient } from "@supabase/supabase-js";

export default async function handler(req, res){
  res.setHeader("Access-Control-Allow-Origin","*");
  if(req.method === "OPTIONS") return res.status(204).end();
  if(req.method !== "POST") return res.status(405).json({ ok:false, error:"METHOD_NOT_ALLOWED" });

  const requiredEnv = ["WEB_PUSH_VAPID_PUBLIC_KEY","WEB_PUSH_VAPID_PRIVATE_KEY","WEB_PUSH_SUBJECT","SUPABASE_URL","SUPABASE_SERVICE_ROLE_KEY"];
  const missingEnv = requiredEnv.filter(e=>!process.env[e]);
  if(missingEnv.length>0) return res.status(501).json({ ok:false, error:"MISSING_ENV", missing:missingEnv });

  webpush.setVapidDetails(
    process.env.WEB_PUSH_SUBJECT,
    process.env.WEB_PUSH_VAPID_PUBLIC_KEY,
    process.env.WEB_PUSH_VAPID_PRIVATE_KEY
  );

  const body = (typeof req.body === "string") ? JSON.parse(req.body||"{}") : (req.body || {});
  const { endpoint, template, title, body: desc, url, vibrate, actions, tag, toAll } = body || {};

  /* ===== 根据 endpoint / toAll 查订阅对象们 ===== */
  const sb = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, { auth:{persistSession:false} });
  let subsRows = [];
  try {
    if(toAll){
      const { data, error } = await sb.from("push_subscriptions").select("endpoint,p256dh,auth,id").eq("active", true);
      if(error) throw error;
      subsRows = data || [];
    } else if(endpoint){
      const { data, error } = await sb.from("push_subscriptions").select("endpoint,p256dh,auth,id").eq("endpoint", String(endpoint)).eq("active", true).limit(1);
      if(error) throw error;
      subsRows = data || [];
    }
  } catch(e){
    return res.status(500).json({ ok:false, error:"SUPABASE_READ_ERR", message: e.message || String(e) });
  }
  if(subsRows.length===0) return res.status(404).json({ ok:false, error:"NO_ACTIVE_SUBSCRIPTIONS", message:"没找到符合条件的 active=true 的订阅。先去设置页开启系统级推送。" });

  /* ===== 构建推送 payload ===== */
  const payload = JSON.stringify({
    template: template || "general",
    title: title || "个人工作台",
    body: desc || "有一条新消息",
    url: url || "./workbench-mobile.html",
    vibrate: vibrate || null,
    actions: Array.isArray(actions) ? actions : null,
    tag: tag || null
  });
  const opts = { TTL: 86400 };

  /* ===== 逐个发；失败 410 (Gone) 时把 Supabase 订阅置 inactive ===== */
  const results = [];
  for (const row of subsRows){
    if(!row || !row.endpoint || !row.p256dh || !row.auth) continue;
    const pushSubscription = { endpoint: row.endpoint, keys: { p256dh: row.p256dh, auth: row.auth } };
    try {
      await webpush.sendNotification(pushSubscription, payload, opts);
      results.push({ id: row.id, ok:true });
    } catch(err){
      const statusCode = (err && err.statusCode) || 0;
      results.push({ id: row.id, ok:false, statusCode, message:String(err && err.message || err) });
      if(statusCode === 410){
        try {
          await sb.from("push_subscriptions").update({ active:false, last_error_code: 410, unsubscribed_at: Date.now() }).eq("id", row.id);
        } catch(_){ /* ignore */ }
      }
    }
  }
  const okCount = results.filter(r=>r.ok).length;
  const fail410 = results.filter(r=>!r.ok && r.statusCode===410).length;
  const failOther = results.length - okCount - fail410;
  return res.status(200).json({
    ok: okCount>0,
    summary: { total:results.length, ok:okCount, gone410:fail410, otherFail:failOther },
    results: results.slice(0, 10)
  });
}
