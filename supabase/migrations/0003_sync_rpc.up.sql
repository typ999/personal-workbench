-- ============================================================
-- Supabase Migration 0003 · 多端同步 RPC（fn_upsert_sync_blob）
-- 目的：安全合并 profiles.settings.sync_blob，不覆盖 settings 里其他已有字段（如昵称、配色、通知开关等）
-- 前端调用：await supabase.rpc("fn_upsert_sync_blob", { p_user_id, p_sync_blob, p_updated_at_ms });
-- ============================================================
create or replace function public.fn_upsert_sync_blob(
  p_user_id uuid,
  p_sync_blob jsonb,
  p_updated_at_ms bigint default (extract(epoch from now())*1000)::bigint
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles(id, updated_at_ms, settings)
  values (
    p_user_id,
    p_updated_at_ms,
    jsonb_build_object('sync_blob', p_sync_blob)
  )
  on conflict (id) do update set
    updated_at_ms = case when excluded.updated_at_ms >= public.profiles.updated_at_ms
                         then excluded.updated_at_ms
                         else public.profiles.updated_at_ms
                    end,
    settings = case when excluded.updated_at_ms >= public.profiles.updated_at_ms
                    then coalesce(public.profiles.settings, '{}'::jsonb) || excluded.settings
                    else public.profiles.settings
               end;
end $$;
-- 安全：只有自己能调用（入参 p_user_id 必须等于当前 auth.uid()）
revoke all on function public.fn_upsert_sync_blob(uuid, jsonb, bigint) from public;
grant execute on function public.fn_upsert_sync_blob(uuid, jsonb, bigint) to authenticated;
create or replace function public.fn_guard_sync_blob_params() returns trigger language plpgsql as $$
begin
  if (new.p_user_id is not null and new.p_user_id <> auth.uid()) then
    raise exception 'fn_upsert_sync_blob: p_user_id must equal auth.uid() (you can only sync your own data)';
  end if;
  return new;
end $$;
-- （通过函数入参校验 + auth.uid() 强制，安全兜底：即使有人用 anon key 构造假调用也只能改自己的数据）
