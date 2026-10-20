-- =============================================================================
-- NCV Companion: schema, Row Level Security, quota functions and storage bucket
-- Apply with: supabase db push   (or paste into the SQL editor)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Tables
-- ---------------------------------------------------------------------------

create table if not exists public.profiles (
  id                uuid primary key references auth.users (id) on delete cascade,
  full_name         text    not null default '',
  college_name      text    not null default '',
  nqf_level         int     not null default 2 check (nqf_level in (2, 3, 4)),
  vocational_stream text    not null default '',
  daily_ai_queries  int     not null default 0 check (daily_ai_queries >= 0),
  -- Extra column: the SAST calendar day the counter applies to, so it resets daily.
  ai_quota_date     date,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create table if not exists public.subjects (
  id                uuid primary key default gen_random_uuid(),
  code              text    not null,
  title             text    not null,
  nqf_level         int     not null check (nqf_level in (2, 3, 4)),
  is_fundamental    boolean not null default false,
  -- 50 = vocational, 40 = Life Orientation / First Additional Language, 30 = Maths / Maths Literacy
  pass_percentage   int     not null check (pass_percentage in (30, 40, 50)),
  -- Extra column: NULL for fundamental subjects, which are shared across streams.
  vocational_stream text,
  created_at        timestamptz not null default now(),
  unique (code, nqf_level)
);

create table if not exists public.student_icass (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references public.profiles (id) on delete cascade,
  subject_id          uuid not null references public.subjects (id) on delete cascade,
  task_scores         jsonb not null default '[]'::jsonb,
  icass_percentage    double precision not null default 0,
  target_exam_score   double precision not null default 0,
  -- Extra column: drives last-write-wins conflict resolution during sync.
  updated_at          timestamptz not null default now(),
  created_at          timestamptz not null default now(),
  unique (user_id, subject_id)
);

create table if not exists public.past_papers (
  id            uuid primary key default gen_random_uuid(),
  subject_id    uuid not null references public.subjects (id) on delete cascade,
  year          int  not null check (year between 2000 and 2100),
  paper_number  int  not null default 1 check (paper_number > 0),
  -- Object path inside the private 'past-papers' bucket, e.g. nqf2/eng-design/mat/2025_p1_qp.pdf
  file_url      text not null,
  is_memo       boolean not null default false,
  created_at    timestamptz not null default now(),
  unique (subject_id, year, paper_number, is_memo)
);

create index if not exists student_icass_user_idx on public.student_icass (user_id);
create index if not exists past_papers_subject_idx on public.past_papers (subject_id, year);

-- ---------------------------------------------------------------------------
-- 2. Generic updated_at maintenance
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists student_icass_set_updated_at on public.student_icass;
create trigger student_icass_set_updated_at
  before update on public.student_icass
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 3. Create a profile on sign-up from user metadata
--    Keeps the client free of direct inserts into profiles, so it works with
--    email confirmation on or off.
-- ---------------------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, college_name, nqf_level, vocational_stream)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(new.raw_user_meta_data ->> 'college_name', ''),
    coalesce(nullif(new.raw_user_meta_data ->> 'nqf_level', '')::int, 2),
    coalesce(new.raw_user_meta_data ->> 'vocational_stream', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- 4. AI query quota (server-enforced, atomic)
--    Called by the ai-tutor Edge Function with the learner's JWT. The counter
--    resets at midnight SAST (UTC+2, no DST). The client cannot change it.
-- ---------------------------------------------------------------------------

create or replace function public.consume_ai_query()
returns table (allowed boolean, remaining int)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid   uuid := auth.uid();
  v_limit constant int := 20;
  v_today date := (now() at time zone 'Africa/Johannesburg')::date;
  v_count int;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  -- One atomic statement: it either increments under the limit or matches nothing.
  update public.profiles p
     set daily_ai_queries = case
           when p.ai_quota_date is distinct from v_today then 1
           else p.daily_ai_queries + 1
         end,
         ai_quota_date = v_today
   where p.id = v_uid
     and (p.ai_quota_date is distinct from v_today or p.daily_ai_queries < v_limit)
  returning p.daily_ai_queries into v_count;

  if found then
    return query select true, (v_limit - v_count)::int;
  else
    return query select false, 0;
  end if;
end;
$$;

-- Give back one query when the model call fails, so a server error is not charged.
create or replace function public.refund_ai_query()
returns void
language sql
security definer
set search_path = public
as $$
  update public.profiles
     set daily_ai_queries = greatest(daily_ai_queries - 1, 0)
   where id = auth.uid()
     and ai_quota_date = (now() at time zone 'Africa/Johannesburg')::date;
$$;

revoke all on function public.consume_ai_query() from public, anon;
revoke all on function public.refund_ai_query() from public, anon;
grant execute on function public.consume_ai_query() to authenticated;
grant execute on function public.refund_ai_query() to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Row Level Security
-- ---------------------------------------------------------------------------

alter table public.profiles      enable row level security;
alter table public.subjects      enable row level security;
alter table public.student_icass enable row level security;
alter table public.past_papers   enable row level security;

-- profiles: a learner sees and edits only their own row.
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select to authenticated using (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Column-level grant: the quota counter is server-owned and cannot be edited from the app.
revoke update on public.profiles from authenticated;
grant update (full_name, college_name, nqf_level, vocational_stream) on public.profiles to authenticated;

-- subjects and past_papers: read-only reference data for signed-in learners.
-- Writes happen through the service role (admin tooling or SQL editor).
drop policy if exists "subjects_read_authenticated" on public.subjects;
create policy "subjects_read_authenticated" on public.subjects
  for select to authenticated using (true);

drop policy if exists "past_papers_read_authenticated" on public.past_papers;
create policy "past_papers_read_authenticated" on public.past_papers
  for select to authenticated using (true);

-- student_icass: full control of your own rows only.
drop policy if exists "icass_owner_all" on public.student_icass;
create policy "icass_owner_all" on public.student_icass
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- 6. Private storage bucket for PDFs
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('past-papers', 'past-papers', false)
on conflict (id) do nothing;

drop policy if exists "past_papers_objects_read" on storage.objects;
create policy "past_papers_objects_read" on storage.objects
  for select to authenticated
  using (bucket_id = 'past-papers');
