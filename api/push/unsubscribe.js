// /api/push/unsubscribe.js — 用户关闭推送或点"取消订阅"时调用
import { createClient } from "@supabase/supabase-js";

export default async function handler(req, res){
  try {
    res.setHeader("Access-Control-Allow-Origin","*");
    if(req.method === "OPTIONS") return res.status(204).end();
    if(req.method !== "POST") return res.status(405).json({ ok:false, error:"METHOD_NOT_ALLOWED" });
    if(!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE_KEY){
      return res.status(501).json({ ok:false, error:"MISSING_SUPABASE_ENV" });
    }
    const body = (typeof req.body === "string") ? JSON.parse(req.body||"{}") : (req.body || {});
    const endpoint = body && body.endpoint;
    if(!endpoint) return res.status(400).json({ ok:false, error:"BAD_ENDPOINT" });
    const sb = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, { auth:{persistSession:false} });
    await sb.from("push_subscriptions").update({ active:false, unsubscribed_at: Date.now() }).eq("endpoint", String(endpoint));
    return res.status(200).json({ ok:true, message:"已标记为 inactive。如需永久删除可在 Supabase Dashboard 清空 active=false 的记录。" });
  } catch(err){
    return res.status(500).json({ ok:false, error:err?.name||"ERR", message:String(err?.message||err) });
  }
}
