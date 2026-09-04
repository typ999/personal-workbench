-- ============================================================
-- Supabase Migration 0001 · 初始化 Phase 2 核心 schema（32 张业务表 + profiles + 3 个基础 RPC）
--  部署顺序：supabase db reset → supabase db push
--  注意：执行前确保已开启 RLS（默认打开）。
-- ============================================================

-- 0) 扩展
create extension if not exists "pgcrypto";
create extension if not exists "pgjwt";
create extension if not exists "pg_cron";
create extension if not exists "pg_trgm";

-- 1) profiles 主表（和 Supabase auth.users 1:1）
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at_ms bigint not null default (extract(epoch from now())*1000)::bigint,

  nickname text,
  avatar text,
  counters jsonb not null default '{}'::jsonb,
  couple jsonb not null default '{}'::jsonb,
  body_goal jsonb not null default '{}'::jsonb,
  review jsonb not null default '{}'::jsonb,
  settings jsonb not null default '{}'::jsonb,
  inspirit_read jsonb not null default '{}'::jsonb,
  goals_done int not null default 0,
  read_count int not null default 0
);
alter table public.profiles enable row level security;
drop policy if exists profiles_self_select on public.profiles;
create policy profiles_self_select on public.profiles for select using (auth.uid() = id);
drop policy if exists profiles_self_modify on public.profiles;
create policy profiles_self_modify on public.profiles for all using (auth.uid()=id) with check (auth.uid()=id);
-- auth.users insert 触发器自动建 profiles
drop trigger if exists on_auth_user_created on auth.users;
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id,nickname) values (new.id, coalesce(new.raw_user_meta_data->>'nickname',new.raw_user_meta_data->>'name',new.email)) on conflict (id) do nothing;
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

-- 2) 通用模板：owner + updated_at_ms + _deleted 三张 RLS policy 辅助宏（所有业务表相同）
--    下面统一使用 PL/pgSQL 循环建表避免手写出错

do $$
declare
  t text;
  tables text[] := array[
    'todos','daily_learn','daily_read_time','inspirations','quotes','plants','goals',
    'wealth_tx','accounts','fixed_expenses','purchase_list','coins_log','badges','badge_log',
    'couple_posts','memos','checkins','sport_types','sport_logs','body_logs','foods','recipes',
    'shopping','nutrition_logs','reminders','shop_orders','weekly_reports',
    'board_columns','board_tasks','notebooks','notes','work_memos'
  ];
begin
  foreach t in array tables loop
    execute format('create table if not exists public.%I (
      id bigserial primary key,
      owner uuid not null default auth.uid() references public.profiles(id) on delete cascade,
      created_at timestamptz not null default now(),
      updated_at_ms bigint not null default (extract(epoch from now())*1000)::bigint,
      _deleted bool not null default false,
      payload jsonb not null default ''{}''::jsonb
    );', t);
    execute format('create index if not exists %I_owner_date_idx on public.%I(owner, created_at desc) where not _deleted;', t, t);
    execute format('alter table public.%I enable row level security;', t);
    execute format('drop policy if exists %I_self on public.%I;', t, t);
    execute format('create policy %I_self on public.%I for all using (auth.uid() = owner) with check (auth.uid() = owner);', t, t);
  end loop;
end $$;

-- 3) Storage bucket & policy
insert into storage.buckets(id,name,public,avif_autodetection,file_size_limit,allowed_mime_types)
values ('wb-media','wb-media',false,true,5242880,'{image/*,video/*,audio/*,application/pdf,text/plain,application/json}')
on conflict(id) do nothing;
drop policy if exists wb_media_owner_access on storage.objects;
create policy wb_media_owner_access on storage.objects for all
  using (bucket_id='wb-media' and (auth.uid() is not null) and ((storage.foldername(name))[1] = auth.uid()::text))
  with check (bucket_id='wb-media' and (storage.foldername(name))[1] = auth.uid()::text);

-- 4) RPC 1：每月 1 号清理 30 天前软删记录（pg_cron 调用）
create or replace function public.fn_prune_deleted(before_ms timestamptz default (now() - interval '30 days'))
returns void language plpgsql security definer set search_path = public as $$
declare t text;
begin
  for t in select tablename from pg_tables where schemaname='public' and tablename in ('todos','daily_learn','daily_read_time','inspirations','quotes','plants','goals','wealth_tx','accounts','fixed_expenses','purchase_list','coins_log','badges','badge_log','couple_posts','memos','checkins','sport_types','sport_logs','body_logs','foods','recipes','shopping','nutrition_logs','reminders','shop_orders','weekly_reports','board_columns','board_tasks','notebooks','notes','work_memos') loop
    execute format('delete from public.%I where _deleted=true and to_timestamp(updated_at_ms/1000) <= %L returning 1;', t, before_ms);
  end loop;
  delete from storage.objects where bucket_id='wb-media' and created <= before_ms;
end $$;

-- 5) RPC 2：coins_no_dup_award() 防重复金币 trigger
create or replace function public.fn_coins_no_dup_award() returns trigger language plpgsql security definer set search_path=public as $$
declare
  dup_count int;
begin
  if (new.payload->>'source') is null then return new; end if;
  select count(1) into dup_count from public.coins_log
    where owner = new.owner
      and payload->>'source' = (new.payload->>'source')
      and payload->>'date'   = coalesce(new.payload->>'date',to_char(now(),'YYYY-MM-DD'));
  if dup_count > 0 then
    raise exception 'COIN_DUP_AWARD source=%, date=% — 触发防重复发奖触发器', (new.payload->>'source'),(new.payload->>'date');
  end if;
  return new;
end $$;

do $$ declare t text; begin
  t := 'coins_log';
  execute format('drop trigger if exists coins_no_dup on public.%I;', t);
  execute format('create trigger coins_no_dup before insert on public.%I for each row execute function public.fn_coins_no_dup_award();', t);
end $$;

-- 6) RPC 3：每周周报生成（pg_cron 每周日 22:00 北京时间调用）
create or replace function public.fn_weekly_report_cron() returns void language plpgsql security definer set search_path=public as $$
declare row record;
begin
  for row in select id from public.profiles loop
    -- ✅ 修复原 ON CONFLICT (payload->>'period_end') 语法错误：
    --    PostgreSQL ON CONFLICT 只能引用实际列/已存在 UNIQUE 约束名，不能用 jsonb 即时推导表达式。
    --    改为 NOT EXISTS 子查询（引用 weekly_reports 的真实 period_end 列），对空 profiles / 已存在记录都安全，且无语法限制。
    insert into public.weekly_reports(owner, period_start, period_end, payload, _deleted, updated_at_ms)
    select
      row.id,
      to_char(now()-interval '6 days','YYYY-MM-DD'),
      to_char(now(),'YYYY-MM-DD'),
      jsonb_build_object('auto','true','generatedAt',extract(epoch from now())*1000),
      false,
      (extract(epoch from now())*1000)::bigint
    where not exists (
      select 1 from public.weekly_reports w
      where w.owner = row.id
        and w._deleted = false
        and w.period_end = to_char(now(),'YYYY-MM-DD')
    );
  end loop;
end $$;

-- 7) pg_cron 计划：每月 1 号凌晨清软删；每周日 22:00(北京)=UTC 14:00 周报
--    ✅ 兼容部分免费 Supabase 未启用 pg_cron / 无 cron 权限场景：包进 DO + EXCEPTION，失败只 raise NOTICE 不阻断整个 migration（Web Push 可通过 API 手动触发仍然可用）
do $$
declare
  has_pg_cron boolean;
begin
  select exists(select 1 from pg_extension where extname='pg_cron') into has_pg_cron;
  if not has_pg_cron then
    raise notice 'SKIP: pg_cron extension not available on this instance. You can still trigger Web Push via endpoints /api/push/*. (free-tier Supabase compatibility)';
    return;
  end if;
  begin
    perform cron.schedule('wb-prune-deleted-monthly','0 4 1 * *','select public.fn_prune_deleted();')
      where not exists (select 1 from cron.job where jobname='wb-prune-deleted-monthly');
  exception when others then
    raise notice 'cron.schedule(wb-prune-deleted-monthly) skipped: %', SQLERRM;
  end;
  begin
    perform cron.schedule('wb-weekly-report-sun22','0 14 * * 0','select public.fn_weekly_report_cron();')
      where not exists (select 1 from cron.job where jobname='wb-weekly-report-sun22');
  exception when others then
    raise notice 'cron.schedule(wb-weekly-report-sun22) skipped: %', SQLERRM;
  end;
end $$;
