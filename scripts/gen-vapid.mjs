#!/usr/bin/env node
/* scripts/gen-vapid.mjs — 生成 VAPID public/private keys（只生成一次；结果写入 .vapid.json（已被 .gitignore 禁止上传）并在控制台输出 copy-paste 到 Vercel Env 的两条值）
 * 用法：
 *   cd 项目根
 *   node scripts/gen-vapid.mjs
 * 输出：WEB_PUSH_VAPID_PUBLIC_KEY / WEB_PUSH_VAPID_PRIVATE_KEY / WEB_PUSH_SUBJECT
 */
import webpush from "web-push";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const OUT = path.join(root, ".vapid.json");

const keys = webpush.generateVAPIDKeys();
const subject = process.env.WEB_PUSH_SUBJECT || "mailto:your@email.example.com";
const payload = {
  generatedAt: new Date().toISOString(),
  subject,
  publicKey: keys.publicKey,
  privateKey: keys.privateKey
};
fs.writeFileSync(OUT, JSON.stringify(payload, null, 2), "utf8");
fs.chmodSync(OUT, 0o600);

console.log("✅ VAPID keys 生成成功，已写入 .vapid.json（chmod 600，不会被 git 追踪）\n");
console.log("— 在 Vercel Project Settings → Environment Variables 中粘贴以下 3 条（三个复选框：Development / Preview / Production 都打勾）——\n");
console.log("  WEB_PUSH_SUBJECT            =", subject);
console.log("  WEB_PUSH_VAPID_PUBLIC_KEY   =", keys.publicKey);
console.log("  WEB_PUSH_VAPID_PRIVATE_KEY  =", keys.privateKey);
console.log("\n— 在浏览器端设置页开启系统级推送时，前端会先 GET /api/push/vapid-public-key 获取 PUBLIC KEY 做 PushManager.subscribe({applicationServerKey})。\n");
console.log("— 如需更换邮箱：运行 WEB_PUSH_SUBJECT=\"mailto:you@real.domain\" node scripts/gen-vapid.mjs\n");
