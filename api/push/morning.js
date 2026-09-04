// /api/push/morning.js — Vercel Cron 触发（UTC 00:30 = 中国 08:30）→ 给所有用户的每台 active 订阅设备发晨间套餐
// 模板：🌅 今日晨间套餐（天气 + 3 条最重要待办）
import webpush from "web-push";
import { createClient } from "@supabase/supabase-js";

export default async function handler(req, res){
  try {
    const requiredEnv = ["WEB_PUSH_VAPID_PUBLIC_KEY","WEB_PUSH_VAPID_PRIVATE_KEY","WEB_PUSH_SUBJECT","SUPABASE_URL","SUPABASE_SERVICE_ROLE_KEY"];
    const missingEnv = requiredEnv.filter(e=>!process.env[e]);
    if(missingEnv.length>0) return res.status(501).json({ ok:false, error:"MISSING_ENV", missing:missingEnv });
    webpush.setVapidDetails(process.env.WEB_PUSH_SUBJECT, process.env.WEB_PUSH_VAPID_PUBLIC_KEY, process.env.WEB_PUSH_VAPID_PRIVATE_KEY);
    const sb = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, { auth:{persistSession:false} });
    const { data, error } = await sb.from("push_subscriptions").select("endpoint,p256dh,auth,id,owner").eq("active", true);
    if(error) return res.status(500).json({ ok:false, error:"SUPABASE_ERR", message:error.message });
    const rows = data || [];
    const todayISO = new Date().toISOString().slice(0,10);
    let sent=0, gone=0;
    for(const row of rows){
      try {
        // 查该 owner 今日待办数（如无 Supabase todos 同步则为 null，默认走通用晨间文案）
        let todoCount = null, weatherText = null;
        try {
          if(row.owner){
            const [{count:tc}] = (await sb.from("todos").select("id", { count:"exact", head:true }).eq("owner", row.owner).eq("date", todayISO)).count || 0;
            todoCount = typeof tc === "number" ? tc : null;
          }
        } catch(_){}
        const body = (todoCount!=null && todoCount>0)
          ? `今日有 ${todoCount} 条待办 + 晨间套餐待完成 · 点击查看详情`
          : `点击查看今日天气 + 3 条最重要待办`;
        await webpush.sendNotification(
          { endpoint:row.endpoint, keys:{p256dh:row.p256dh,auth:row.auth} },
          JSON.stringify({ template:"morning", title:"🌅 今日晨间套餐", body, url:"./workbench-mobile.html", tag:"wb-morning-"+todayISO, vibrate:[220,120,220] }),
          { TTL: 86400 }
        );
        sent++;
      } catch(e){
        if(e?.statusCode===410){ gone++; try { await sb.from("push_subscriptions").update({active:false,last_error_code:410}).eq("id",row.id); } catch(_){} }
      }
    }
    return res.status(200).json({ ok:true, cron:"morning", total:rows.length, sent, gone410:gone });
  } catch(err){
    return res.status(500).json({ ok:false, error:err?.name||"ERR", message:String(err?.message||err) });
  }
}
