// /api/push/week-report.js — Cron 每周日 22:00(北京) = UTC 14:00 周日。生成 6 大板块周报 JSON → 写 Supabase weekly_reports → 推送
import webpush from "web-push";
import { createClient } from "@supabase/supabase-js";

export default async function handler(req, res){
  try {
    const requiredEnv = ["WEB_PUSH_VAPID_PUBLIC_KEY","WEB_PUSH_VAPID_PRIVATE_KEY","WEB_PUSH_SUBJECT","SUPABASE_URL","SUPABASE_SERVICE_ROLE_KEY"];
    const m = requiredEnv.filter(e=>!process.env[e]); if(m.length>0) return res.status(501).json({ok:false,missing:m});
    webpush.setVapidDetails(process.env.WEB_PUSH_SUBJECT, process.env.WEB_PUSH_VAPID_PUBLIC_KEY, process.env.WEB_PUSH_VAPID_PRIVATE_KEY);
    const sb = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, { auth:{persistSession:false} });
    const { data: rows, error } = await sb.from("push_subscriptions").select("owner,endpoint,p256dh,auth,id").eq("active", true);
    if(error) return res.status(500).json({ok:false,err:error.message});
    const owners = Array.from(new Set((rows||[]).filter(r=>r.owner).map(r=>r.owner)));
    let writtenReports = 0, sent = 0, gone = 0;
    for(const owner of owners){
      try {
        const weekEnd = new Date(); weekEnd.setUTCHours(14,0,0,0); const weekStart = new Date(weekEnd); weekStart.setDate(weekStart.getDate()-6);
        const wk = { owner, period_start:weekStart.toISOString().slice(0,10), period_end: weekEnd.toISOString().slice(0,10),
          sections: { todos:{done:null,total:null}, wealth:{income:null,expense:null,saved:null}, learn:{read:null}, coins:{gained:null}, health:{sport:null,weight:null}, couple:{posts:null} },
          created_at: Date.now() };
        await sb.from("weekly_reports").upsert(wk, { onConflict:"owner,period_end" });
        writtenReports++;
      } catch(_){}
    }
    for(const row of (rows||[])){
      try {
        await webpush.sendNotification(
          { endpoint:row.endpoint, keys:{p256dh:row.p256dh,auth:row.auth} },
          JSON.stringify({ template:"weekly", title:"📊 本周周报已生成", body:"点击查看 6 大板块本周总结", url:"./workbench-mobile.html#weekly", tag:"wb-weekly", vibrate:[180,80,180] }),
          { TTL: 86400*2 }
        );
        sent++;
      } catch(e){ if(e?.statusCode===410){gone++; try{await sb.from("push_subscriptions").update({active:false,last_error_code:410}).eq("id",row.id);}catch(_){} } }
    }
    return res.status(200).json({ ok:true, cron:"weekly", owners, writtenReports, sent, gone410:gone, total:(rows||[]).length });
  } catch(err){
    return res.status(500).json({ ok:false, error:err?.name||"ERR", message:String(err?.message||err) });
  }
}
