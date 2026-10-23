-- HSE-CONTROL multi-officer isolation foundation
-- Each HSE officer receives a separate state row. Never store multiple officers'
-- operational data in one shared app_state payload.
create table if not exists public.officer_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null default '{"workers":[],"rooms":[],"shifts":[],"incidents":[],"settings":{"site":"الموقع الرئيسي"}}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.officer_state enable row level security;

drop policy if exists "officers read own state" on public.officer_state;
create policy "officers read own state"
  on public.officer_state for select to authenticated
  using (user_id = (select auth.uid())
    and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'hse_officer');

drop policy if exists "officers create own state" on public.officer_state;
create policy "officers create own state"
  on public.officer_state for insert to authenticated
  with check (user_id = (select auth.uid())
    and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'hse_officer');

drop policy if exists "officers update own state" on public.officer_state;
create policy "officers update own state"
  on public.officer_state for update to authenticated
  using (user_id = (select auth.uid())
    and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'hse_officer')
  with check (user_id = (select auth.uid())
    and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'hse_officer');

drop policy if exists "managers read officer states" on public.officer_state;
create policy "managers read officer states"
  on public.officer_state for select to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'manager');

grant select, insert, update on public.officer_state to authenticated;

-- Do not grant managers write access to officers' operational payloads.
