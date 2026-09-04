-- ============================================================
-- Supabase Migration 0002 · push_subscriptions（系统级推送订阅表）
--  前置：已执行 0001_init_schema.up.sql
-- ============================================================

create table if not exists public.push_subscriptions (
  id bigserial primary key,
  owner uuid references public.profiles(id) on delete cascade,  -- Phase 2 授权用户后有，未登录前为 null（测试/未登录态允许"匿名订阅"，owner null）
  endpoint text not null unique,       -- Web Push endpoint，全局唯一；upsert onConflict=endpoint
  p256dh text not null,
  auth text not null,
  fingerprint text,
  ua text,
  user_agent_header text,
  device_type text,
  locale text,
  subscribed_at bigint,
  last_seen_at bigint,
  unsubscribed_at bigint,
  last_error_code int,
  last_error_msg text,
  active bool not null default true,
  created_at timestamptz not null default now(),
  updated_at_ms bigint not null default (extract(epoch from now())*1000)::bigint
);

create index if not exists push_subs_owner_active_idx on public.push_subscriptions(owner, active) where active=true;
create index if not exists push_subs_endpoint_active_idx on public.push_subscriptions(endpoint, active) where active=true;
create index if not exists push_subs_fingerprint_idx on public.push_subscriptions using hash(fingerprint);

alter table public.push_subscriptions enable row level security;
-- ⚠️ 默认给所有业务操作走 service_role key（/api/push/*），不走 anon key；这里 RLS 仅禁止"匿名前端直接读订阅"，服务端用 service_role 自动 bypass RLS
drop policy if exists push_subs_deny_public on public.push_subscriptions;
create policy push_subs_deny_public on public.push_subscriptions for all using (false) with check (false);
