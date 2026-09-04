// /api/push/subscribe.js — 接收前端 PushManager.subscribe() 返回的订阅对象，写进 Supabase push_subscriptions 表
// Phase 2 要求：全站 HTTPS，VAPID 验证。
import webpush from "web-push";
import { createClient } from "@supabase/supabase-js";

function cors(res){
  res.setHeader("Access-Control-Allow-Origin","*");
  res.setHeader("Access-Control-Allow-Methods","POST,GET,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers","Content-Type, Authorization");
}

export default async function handler(req, res) {
  cors(res);
  if(req.method === "OPTIONS") return res.status(204).end();
  try {
    if(req.method !== "POST") return res.status(405).json({ ok:false, error:"METHOD_NOT_ALLOWED" });

    /* ===== 环境 & 入参校验 ===== */
    const requiredEnv = ["WEB_PUSH_VAPID_PUBLIC_KEY","WEB_PUSH_VAPID_PRIVATE_KEY","WEB_PUSH_SUBJECT","SUPABASE_URL","SUPABASE_SERVICE_ROLE_KEY"];
    const missingEnv = requiredEnv.filter(e=>!process.env[e]);
    if(missingEnv.length>0){
      return res.status(501).json({ ok:false, error:"MISSING_ENV", missing: missingEnv,
        message:"Vercel Env 缺少："+missingEnv.join(", ")+"。请按部署操作手册 Step B5-B7 填入。" });
    }
    const body = (typeof req.body === "string") ? JSON.parse(req.body||"{}") : (req.body || {});
    const { endpoint, keys, ua, createdAt } = body || {};
    if(!endpoint || typeof endpoint !== "string" || !/^https?:\/\//i.test(endpoint)){
      return res.status(400).json({ ok:false, error:"BAD_ENDPOINT", message:"订阅缺少有效 endpoint 字段" });
    }
    if(!keys || typeof keys !== "object" || !keys.p256dh || !keys.auth){
      return res.status(400).json({ ok:false, error:"BAD_KEYS", message:"订阅缺少 p256dh / auth 密钥" });
    }
    // VAPID 提前校验：如果公私钥不匹配，web-push 会在 send 时抛 "invalid curve point"，这里先预热避免静默失败
    try {
      webpush.setVapidDetails(
        process.env.WEB_PUSH_SUBJECT || "mailto:webpush@example.local",
        process.env.WEB_PUSH_VAPID_PUBLIC_KEY,
        process.env.WEB_PUSH_VAPID_PRIVATE_KEY
      );
    } catch(e){
      return res.status(500).json({ ok:false, error:"VAPID_INVALID", message: "VAPID keys 校验失败："+(e&&e.message||e) });
    }

    /* ===== 写 Supabase ===== */
    const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, { auth: { persistSession:false, autoRefreshToken:false } });
    const fingerprint = String(endpoint).slice(-28); // 后端唯一键：endpoint；前端可能多次订阅，做 upsert 去重
    const now = Date.now();
    const payload = {
      endpoint: String(endpoint),
      p256dh: String(keys.p256dh),
      auth: String(keys.auth),
      ua: String(ua || "").slice(0, 400),
      user_agent_header: String((req.headers && req.headers["user-agent"]) || "").slice(0, 400),
      fingerprint,
      last_seen_at: now,
      subscribed_at: createdAt || now,
      active: true,
      device_type: guessDeviceType(ua || (req.headers && req.headers["user-agent"] || "")),
      locale: String((req.headers && req.headers["accept-language"]) || "zh-CN").slice(0, 20)
    };
    const { error: writeErr } = await supabase.from("push_subscriptions").upsert(payload, { onConflict:"endpoint", ignoreDuplicates:false });
    if(writeErr){
      return res.status(500).json({ ok:false, error:"SUPABASE_WRITE_ERR", message: writeErr.message || String(writeErr),
        hint: "请先执行 Supabase Migration 0002_push_subscriptions.up.sql 创建表和 RLS。" });
    }
    return res.status(200).json({ ok:true, id: fingerprint, message:"已保存订阅对象。可点击设置内「⚡ 发测试推送」验证。" });
  } catch(err){
    return res.status(500).json({ ok:false, error: err && err.name ? err.name : "INTERNAL", message: String(err && err.message || err) });
  }
}

function guessDeviceType(ua){
  const s = String(ua).toLowerCase();
  if(/iphone|ipad|ipod|ios/.test(s)) return "ios";
  if(/android/.test(s)) return "android";
  if(/windows/.test(s)) return "windows";
  if(/mac os x|macintosh/.test(s)) return "macos";
  if(/linux/.test(s)) return "linux";
  return "other";
}
