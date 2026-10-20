-- HSE CONTROL shared manager/officer review workflow.
-- Apply only to the dedicated HSE-CONTROL Supabase project.
-- Never apply this migration to Salakni or dar-al-salatin.

create table if not exists public.hse_submissions (
  id uuid primary key default gen_random_uuid(),
  submission_type text not null check (submission_type in ('report','incident','observation','disciplinary_action')),
  title text not null,
  details text not null default '',
  worker_id text,
  worker_name text,
  attachment_paths text[] not null default '{}',
  status text not null default 'pending' check (status in ('pending','approved','rejected','in_progress','resolved')),
  submitted_by uuid not null references auth.users(id) on delete restrict,
  submitted_at timestamptz not null default now(),
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  review_comment text,
  updated_at timestamptz not null default now()
);

create index if not exists hse_submissions_status_submitted_at_idx
  on public.hse_submissions (status, submitted_at desc);
create index if not exists hse_submissions_submitted_by_idx
  on public.hse_submissions (submitted_by, submitted_at desc);

alter table public.hse_submissions enable row level security;

-- Only the authenticated submitter and users whose trusted app_metadata role is
-- manager may read a submission. Do not use user-editable user_metadata for roles.
drop policy if exists "hse_submitter_or_manager_read" on public.hse_submissions;
create policy "hse_submitter_or_manager_read"
  on public.hse_submissions for select
  to authenticated
  using (
    submitted_by = (select auth.uid())
    or (select auth.jwt() -> 'app_metadata' ->> 'role') = 'manager'
  );

drop policy if exists "hse_officers_submit" on public.hse_submissions;
create policy "hse_officers_submit"
  on public.hse_submissions for insert
  to authenticated
  with check (
    submitted_by = (select auth.uid())
    and (select auth.jwt() -> 'app_metadata' ->> 'role') in ('hse_officer','manager')
  );

drop policy if exists "hse_managers_review" on public.hse_submissions;
create policy "hse_managers_review"
  on public.hse_submissions for update
  to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'manager')
  with check ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'manager');

grant select, insert, update on public.hse_submissions to authenticated;

