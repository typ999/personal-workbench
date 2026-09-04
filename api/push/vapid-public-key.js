// /api/push/vapid-public-key.js — 返回 VAPID public key（只暴露 public；前端启动时先拉一次判断能否走推送链路）
// 运行环境：Vercel Node.js Runtime（>=18.18）；必填 env：WEB_PUSH_VAPID_PUBLIC_KEY
export default async function handler(req, res) {
  try {
    // 允许 CORS 预检
    if(req.method === "OPTIONS") return res.status(204).end();
    const pub = process.env.WEB_PUSH_VAPID_PUBLIC_KEY;
    if(!pub){
      return res.status(501).json({ ok:false, error:"MISSING_VAPID_PUBLIC_KEY", message: "WEB_PUSH_VAPID_PUBLIC_KEY 未配置在 Vercel Environment Variables。请按部署手册 Step B5~B6 生成并填入。" });
    }
    return res.status(200).json({ ok:true, publicKey: pub, generatedAt: process.env.VAPID_GENERATED_AT || "" });
  } catch(err){
    return res.status(500).json({ ok:false, error: err && err.name ? err.name : "INTERNAL", message: String(err && err.message || err) });
  }
}
