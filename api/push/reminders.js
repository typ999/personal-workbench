// /api/push/reminders.js — Cron 每 30 分钟扫 T-0 & T-advanceDays 到期提醒 → 推送给订阅了该 owner 的所有设备
import webpush from "web-push";
import { createClient } from "@supabase/supabase-js";

export default async function handler(req, res){
  try {
    const requiredEnv = ["WEB_PUSH_VAPID_PUBLIC_KEY","WEB_PUSH_VAPID_PRIVATE_KEY","WEB_PUSH_SUBJECT","SUPABASE_URL","SUPABASE_SERVICE_ROLE_KEY"];
    const m = requiredEnv.filter(e=>!process.env[e]); if(m.length>0) return res.status(501).json({ok:false,missing:m});
    webpush.setVapidDetails(process.env.WEB_PUSH_SUBJECT, process.env.WEB_PUSH_VAPID_PUBLIC_KEY, process.env.WEB_PUSH_VAPID_PRIVATE_KEY);
    const sb = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, { auth:{persistSession:false} });
    const todayISO = new Date().toISOString().slice(0,10);
    // Phase 2 简化：先扫 reminders 表所有 not(done)=true + 日期<= todayISO + ((todayISO-date)<=advanceDays) 的记录，给每条发"到期/即将到期"推送；
    // 推送去重键 = reminder id，防止每 30 分钟重复推。
    const { data: rems, error } = await sb.from("reminders").select("id,owner,title,type,advanceDays,date,note,repeat,done").eq("done",false);
    if(error) return res.status(500).json({ok:false,err:error.message});
    let totalRem=0, pushed=0, gone=0;
    const alreadyPushedKey = new Set();
    for(const r of (rems||[])){
      totalRem++;
      const remDate = r.date || ""; if(!remDate) continue;
      const diffDays = Math.round((new Date(todayISO+"T00:00:00") - new Date(remDate+"T00:00:00"))/86400000);
      const adv = Math.max(0, +r.advanceDays||0);
      if(diffDays<0 || diffDays>adv+0) continue; // 只提醒今日（T-0）或 advanceDays 范围内即将到期
      const pushKey = `${todayISO}::${r.id}`; if(alreadyPushedKey.has(pushKey)) continue; alreadyPushedKey.add(pushKey);
      const { data: rows2 } = await sb.from("push_subscriptions").select("id,endpoint,p256dh,auth").eq("owner", r.owner).eq("active", true);
      for(const row of (rows2||[])){
        try {
          const title = (diffDays===0) ? "🔔 今天到期提醒" : `⏰ T-${diffDays} 天提前提醒`;
          const body = `${r.title || "提醒"} · ${r.note || ""} · ${remDate}${r.repeat ? " · 重复" : ""}`;
          await webpush.sendNotification(
            { endpoint:row.endpoint, keys:{p256dh:row.p256dh,auth:row.auth} },
            JSON.stringify({ template:"reminder", title, body, id:r.id, url:`./workbench-mobile.html#reminders`, tag:`wb-reminder-${r.id}-${todayISO}`, vibrate:[300,100,300,100,300] }),
            { TTL: 86400 }
          );
          pushed++;
        } catch(e){ if(e?.statusCode===410){ gone++; try{await sb.from("push_subscriptions").update({active:false}).eq("id",row.id);}catch(_){} } }
      }
    }
    return res.status(200).json({ ok:true, cron:"reminders", todayISO, totalReminders:totalRem, totalPushesSent:pushed, gone410:gone });
  } catch(err){
    return res.status(500).json({ ok:false, error:err?.name||"ERR", message:String(err?.message||err) });
  }
}
