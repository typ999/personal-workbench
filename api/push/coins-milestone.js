// /api/push/coins-milestone.js — Cron 每日 10:00 / 18:00 / 02:05(UTC) 扫所有 owner 的累计金币余额，首次达到 10/20/50/100 推送
import webpush from "web-push";
import { createClient } from "@supabase/supabase-js";
const MILESTONES = [10,20,50,100];
export default async function handler(req, res){
  try {
    const requiredEnv = ["WEB_PUSH_VAPID_PUBLIC_KEY","WEB_PUSH_VAPID_PRIVATE_KEY","WEB_PUSH_SUBJECT","SUPABASE_URL","SUPABASE_SERVICE_ROLE_KEY"];
    const m = requiredEnv.filter(e=>!process.env[e]); if(m.length>0) return res.status(501).json({ok:false,missing:m});
    webpush.setVapidDetails(process.env.WEB_PUSH_SUBJECT, process.env.WEB_PUSH_VAPID_PUBLIC_KEY, process.env.WEB_PUSH_VAPID_PRIVATE_KEY);
    const sb = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, { auth:{persistSession:false} });
    const { data: accounts, error } = await sb.from("accounts").select("owner,coins");
    if(error) return res.status(500).json({ok:false,err:error.message});
    let totalScanned=0, milestoneHits=0, sent=0, gone=0;
    for(const a of (accounts||[])){
      totalScanned++;
      const coins = Math.max(0, +a.coins||0);
      const nextMs = MILESTONES.find(ms => coins >= ms);
      if(!nextMs) continue;
      milestoneHits++;
      const { data: rows } = await sb.from("push_subscriptions").select("id,endpoint,p256dh,auth").eq("owner", a.owner).eq("active", true);
      const bodyMsg = nextMs>=100
        ? `🎉 恭喜！金币已累计满 100，可以购买旭平首饰啦！点击查看成就殿堂兑换流程`
        : `🏆 已累计 ${coins} 金币，达成 ${nextMs} 金币里程碑！继续加油 → 下一个目标 = ${MILESTONES.find(x=>x>coins) || "旭平首饰"}`;
      for(const row of (rows||[])){
        try {
          await webpush.sendNotification(
            { endpoint:row.endpoint, keys:{p256dh:row.p256dh,auth:row.auth} },
            JSON.stringify({ template:"coin", title:`🏆 ${nextMs} 金币里程碑达成`, body:bodyMsg, url:"./workbench-mobile.html#coins", tag:`wb-coin-milestone-${nextMs}`, vibrate:[150,60,150,60,150,60,150] }),
            { TTL: 86400*3 }
          );
          sent++;
        } catch(e){ if(e?.statusCode===410){ gone++; try{await sb.from("push_subscriptions").update({active:false,last_error_code:410}).eq("id",row.id);}catch(_){} } }
      }
    }
    return res.status(200).json({ ok:true, cron:"coins-milestone", totalOwners:totalScanned, milestoneHits, sent, gone410:gone, milestones:MILESTONES });
  } catch(err){
    return res.status(500).json({ ok:false, error:err?.name||"ERR", message:String(err?.message||err) });
  }
}
