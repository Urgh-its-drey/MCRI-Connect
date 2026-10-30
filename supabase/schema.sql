-- MCRI Connect — Supabase schema.
-- Run this whole file in the Supabase dashboard: SQL Editor → New query → Run.
-- Re-running it is safe: every statement is idempotent and no statement drops data.
--
-- What this file guarantees
--   1. auth.users holds credentials only. Every app record lives in public.* keyed by the auth uid.
--   2. A role is decided at sign-up by the database, never trusted from the client, and is
--      not writable by the account that owns it (column privileges revoked + manager RPCs).
--   3. Row Level Security is the authority on cross-role reads. The app hiding a tab is
--      cosmetic; a student token physically cannot SELECT manager or employer data.
--   4. Employers are companies. Internship roles hang off companies, never off a person.

-- ─────────────────────────────────────────────────────────── extensions
create extension if not exists "pgcrypto" with schema extensions;

-- ─────────────────────────────────────────────────────────── enums
do $$ begin
  create type public.user_role as enum ('student', 'employer', 'program_manager');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.account_status as enum ('pending', 'active', 'suspended');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.work_mode as enum ('remote', 'hybrid', 'on_site');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.skill_category as enum
    ('design', 'technology', 'data', 'business', 'communication', 'research');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.application_stage as enum
    ('submitted', 'under_review', 'shortlisted', 'interview_scheduled', 'offered', 'declined');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.placement_stage as enum
    ('preparing', 'applying', 'shortlisted', 'interviewing', 'placed');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.role_status as enum ('open', 'paused', 'closed');
exception when duplicate_object then null; end $$;

-- ─────────────────────────────────────────────────────────── accounts
create table if not exists public.profiles (
  id          uuid primary key references auth.users on delete cascade,
  role        public.user_role      not null default 'student',
  full_name   text                  not null default '',
  email       text,
  phone       text,
  avatar_path text,
  status      public.account_status not null default 'active',
  company_id  uuid,
  created_at  timestamptz           not null default now(),
  updated_at  timestamptz           not null default now()
);
comment on table public.profiles is 'Server-side identity. role decides the workspace the app may open.';

create table if not exists public.companies (
  id                  uuid primary key default gen_random_uuid(),
  name                text    not null,
  initials            text    not null,
  logo_path           text,
  tagline             text,
  website             text,
  location            text,
  registration_number text,
  team_label          text,
  is_verified         boolean not null default false,
  hired_last_cycle    integer not null default 0,
  created_by          uuid references public.profiles (id) on delete set null,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz           not null default now()
);
create unique index if not exists companies_name_key on public.companies (lower(name));

do $$ begin
  alter table public.profiles
    add constraint profiles_company_fk foreign key (company_id)
    references public.companies (id) on delete set null;
exception when duplicate_object then null; end $$;

-- Which email domains are allowed to become staff. Editable only from the dashboard
-- (no write policy exists for it), which is what makes manager sign-up safe to expose.
create table if not exists public.authorized_domains (
  domain text             primary key,
  role   public.user_role not null
);
comment on table public.authorized_domains is
  'Allowlist mapping an email domain to a privileged role. Managed by staff in the dashboard.';

-- ─────────────────────────────────────────────────────────── student profile
create table if not exists public.students (
  id               uuid primary key references public.profiles (id) on delete cascade,
  programme        text    not null default '',
  year             text    not null default '',
  city             text    not null default '',
  work_mode        public.work_mode not null default 'hybrid',
  availability     text    not null default 'Not sure yet',
  bio              text    not null default '',
  profile_strength smallint not null default 0 check (profile_strength between 0 and 100),
  advisor          text,
  cv_name          text,
  cv_path          text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create table if not exists public.student_skills (
  id          uuid primary key default gen_random_uuid(),
  student_id  uuid not null references public.students (id) on delete cascade,
  name        text not null,
  category    public.skill_category not null default 'technology',
  proficiency smallint not null default 2 check (proficiency between 1 and 4),
  evidence    text,
  unique (student_id, name)
);

create table if not exists public.student_interests (
  student_id uuid not null references public.students (id) on delete cascade,
  interest   text not null,
  primary key (student_id, interest)
);

create table if not exists public.projects (
  id         uuid primary key default gen_random_uuid(),
  student_id uuid    not null references public.students (id) on delete cascade,
  title      text    not null,
  summary    text    not null default '',
  outcome    text,
  year       smallint not null
);

create table if not exists public.certificates (
  id         uuid primary key default gen_random_uuid(),
  student_id uuid    not null references public.students (id) on delete cascade,
  name       text    not null,
  issuer     text    not null default '',
  year       smallint not null
);

-- ─────────────────────────────────────────────────────────── internships
create table if not exists public.internships (
  id               uuid primary key default gen_random_uuid(),
  company_id       uuid    not null references public.companies (id) on delete cascade,
  title            text    not null,
  location         text    not null default '',
  work_mode        public.work_mode not null default 'hybrid',
  duration_weeks   smallint not null default 12,
  compensation     text    not null default 'Unpaid',
  is_paid          boolean not null default false,
  easy_apply       boolean not null default true,
  description      text    not null default '',
  responsibilities text[]  not null default '{}',
  required_skills  text[]  not null default '{}',
  preferred_skills text[]  not null default '{}',
  career_interests text[]  not null default '{}',
  category         public.skill_category not null default 'technology',
  team_size        smallint not null default 0,
  status           public.role_status not null default 'open',
  posted_date      timestamptz not null default now(),
  closing_date     timestamptz not null default now() + interval '30 days',
  created_by       uuid references public.profiles (id) on delete set null,
  updated_at       timestamptz not null default now()
);
create index if not exists internships_company_idx on public.internships (company_id);
create index if not exists internships_closing_idx on public.internships (closing_date);

-- ─────────────────────────────────────────────────────────── applications
create table if not exists public.applications (
  id               uuid primary key default gen_random_uuid(),
  internship_id    uuid not null references public.internships (id) on delete cascade,
  student_id       uuid not null references public.students (id) on delete cascade,
  stage            public.application_stage not null default 'submitted',
  submitted_date   timestamptz not null default now(),
  last_update_date timestamptz not null default now(),
  interview_date   timestamptz,
  employer_note    text,
  next_action      text,
  -- One live application per student per role; withdrawal keeps the row for history.
  unique (internship_id, student_id)
);
create index if not exists applications_student_idx   on public.applications (student_id);
create index if not exists applications_internship_idx on public.applications (internship_id);

create table if not exists public.application_events (
  id             uuid primary key default gen_random_uuid(),
  application_id uuid    not null references public.applications (id) on delete cascade,
  title          text    not null,
  detail         text,
  event_date     timestamptz not null default now(),
  is_done        boolean not null default true
);
create index if not exists application_events_app_idx on public.application_events (application_id);

create table if not exists public.saved_roles (
  student_id    uuid not null references public.students (id) on delete cascade,
  internship_id uuid not null references public.internships (id) on delete cascade,
  saved_at      timestamptz not null default now(),
  primary key (student_id, internship_id)
);

create table if not exists public.saved_searches (
  id             uuid primary key default gen_random_uuid(),
  student_id     uuid    not null references public.students (id) on delete cascade,
  label          text    not null,
  filters        text[]  not null default '{}',
  alerts_enabled boolean not null default false,
  created_at     timestamptz not null default now(),
  unique (student_id, label)
);

-- ─────────────────────────────────────────────────────────── placements
create table if not exists public.placements (
  id            uuid primary key default gen_random_uuid(),
  student_id    uuid not null references public.students (id) on delete cascade,
  internship_id uuid references public.internships (id) on delete set null,
  stage         public.placement_stage not null default 'preparing',
  readiness     smallint not null default 0 check (readiness between 0 and 100),
  advisor       text,
  updated_at    timestamptz not null default now(),
  unique (student_id)
);

-- ─────────────────────────────────────────────────────────── messaging
create table if not exists public.threads (
  id         uuid primary key default gen_random_uuid(),
  subject    text    not null default '',
  context    text    not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.thread_participants (
  thread_id  uuid    not null references public.threads (id) on delete cascade,
  profile_id uuid    not null references public.profiles (id) on delete cascade,
  unread     smallint not null default 0,
  last_read  timestamptz not null default now(),
  primary key (thread_id, profile_id)
);

create table if not exists public.messages (
  id        uuid primary key default gen_random_uuid(),
  thread_id uuid    not null references public.threads (id) on delete cascade,
  sender_id uuid    not null references public.profiles (id) on delete cascade,
  body      text    not null check (char_length(body) between 1 and 4000),
  sent_at   timestamptz not null default now()
);
create index if not exists messages_thread_idx on public.messages (thread_id, sent_at);

-- ─────────────────────────────────────────────────────────── updated_at trigger
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$ begin
  new.updated_at = now();
  return new;
end $$;

do $$
declare t text;
begin
  foreach t in array array['profiles', 'companies', 'students', 'internships', 'placements'] loop
    execute format('drop trigger if exists trg_%s_updated on public.%I', t, t);
    execute format('create trigger trg_%s_updated before update on public.%I
                    for each row execute function public.touch_updated_at()', t, t);
  end loop;
end $$;

-- ─────────────────────────────────────────────────────────── role helpers
-- SECURITY DEFINER so a policy can read these without recursing into its own table.
create or replace function public.is_manager()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select role = 'program_manager' and status = 'active'
                   from profiles where id = auth.uid()), false);
$$;

create or replace function public.is_employer()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select role = 'employer' and status = 'active'
                   from profiles where id = auth.uid()), false);
$$;

create or replace function public.my_company_id()
returns uuid language sql stable security definer set search_path = public as $$
  select company_id from profiles where id = auth.uid() and role = 'employer';
$$;

create or replace function public.is_participant(p_thread_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from thread_participants
                 where thread_id = p_thread_id and profile_id = auth.uid());
$$;

-- The students a signed-in employer may see: those who applied to one of their roles.
create or replace function public.applied_student_ids()
returns setof uuid language sql stable security definer set search_path = public as $$
  select a.student_id
  from applications a
  join internships i on i.id = a.internship_id
  where i.company_id = public.my_company_id();
$$;

create or replace function public.student_is_readable(p_student_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select p_student_id = auth.uid()
      or public.is_manager()
      or p_student_id in (select public.applied_student_ids());
$$;

-- ─────────────────────────────────────────────────────────── sign-up hook
-- The client sends {full_name, requested_role, company_name}. Only the domain allowlist
-- can grant a staff role, so signing up as Manager from the app yields a Student account.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  requested  text := coalesce(new.raw_user_meta_data ->> 'requested_role', 'student');
  display    text := coalesce(nullif(new.raw_user_meta_data ->> 'full_name', ''),
                              split_part(coalesce(new.email, ''), '@', 1));
  company    text := nullif(new.raw_user_meta_data ->> 'company_name', '');
  domain     text := lower(reverse(split_part(reverse(lower(coalesce(new.email, ''))), '@', 1)));
  granted    public.user_role;
  company_id uuid;
  initials   text;
begin
  if requested = 'employer' then
    granted := 'employer';
  elsif requested = 'program_manager' then
    select role into granted from public.authorized_domains where lower(domain) = domain;
    granted := coalesce(granted, 'student'::public.user_role);
  else
    granted := 'student';
  end if;

  if granted = 'employer' then
    initials := coalesce(nullif(regexp_replace(upper(left(company, 4)), '[^A-Z0-9]', '', 'g'), ''), 'CO');
    insert into public.companies (name, initials, created_by, is_verified)
      values (coalesce(company, display || ' & Co'), initials, new.id, false)
    on conflict (lower(name)) do update set created_by = coalesce(companies.created_by, excluded.created_by)
    returning id into company_id;
  end if;

  insert into public.profiles (id, role, full_name, email, company_id, status)
    values (new.id, granted, display, new.email, company_id, 'active')
  on conflict (id) do nothing;

  -- Students get an onboarding row; employers and staff do not.
  if granted = 'student' then
    insert into public.students (id) values (new.id) on conflict (id) do nothing;
  end if;

  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ─────────────────────────────────────────────────────────── staff actions
-- RLS decides which rows a user may touch, not which columns. These privileged writes
-- go through SECURITY DEFINER functions so the column itself stays revoked below.
create or replace function public.admin_verify_company(p_company_id uuid, p_verified boolean)
returns void language plpgsql security definer set search_path = public as $$ begin
  if not public.is_manager() then
    raise exception 'only a programme manager can verify a company' using errcode = '42501';
  end if;
  update companies set is_verified = p_verified where id = p_company_id;
end $$;

create or replace function public.admin_set_account_status(p_profile_id uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$ begin
  if not public.is_manager() then
    raise exception 'only a programme manager can change an account status' using errcode = '42501';
  end if;
  update profiles set status = p_status::public.account_status where id = p_profile_id;
end $$;

create or replace function public.admin_assign_role(p_profile_id uuid, p_role text)
returns void language plpgsql security definer set search_path = public as $$ begin
  if not public.is_manager() then
    raise exception 'only a programme manager can assign roles' using errcode = '42501';
  end if;
  update profiles set role = p_role::public.user_role where id = p_profile_id;
end $$;

-- Withdrawal is the one write a student makes to an application. Routing it through a
-- definer function is what keeps the stage column unwritable by them under RLS.
create or replace function public.student_withdraw(p_application_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare owner uuid; begin
  select student_id into owner from applications where id = p_application_id;
  if owner is null then
    raise exception 'application not found' using errcode = 'P0002';
  end if;
  if owner <> auth.uid() then
    raise exception 'a student may only withdraw their own application' using errcode = '42501';
  end if;

  update applications
     set stage = 'declined', last_update_date = now(), next_action = null
   where id = p_application_id;

  insert into application_events (application_id, title, detail, is_done)
  values (p_application_id, 'Withdrawn by you', null, true);
end $$;

-- One call instead of three REST inserts, and it reuses the thread a pair already has.
create or replace function public.open_thread(
  p_peer_id uuid,
  p_subject text default '',
  p_context text default '',
  p_greeting text default ''
)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  thread uuid;
begin
  if p_peer_id = auth.uid() then
    raise exception 'a member cannot message their own account' using errcode = '22023';
  end if;

  if not exists (select 1 from profiles where id = p_peer_id and status = 'active') then
    raise exception 'that recipient is not available' using errcode = 'P0002';
  end if;

  select mine.thread_id into thread
  from thread_participants mine
  join thread_participants theirs on theirs.thread_id = mine.thread_id
    and theirs.profile_id = p_peer_id
  where mine.profile_id = auth.uid()
  limit 1;

  if thread is null then
    insert into threads (subject, context)
      values (coalesce(nullif(p_subject, ''), 'Placement conversation'),
              coalesce(nullif(p_context, ''), ''))
    returning id into thread;

    insert into thread_participants (thread_id, profile_id)
      values (thread, auth.uid()), (thread, p_peer_id);
  end if;

  if nullif(p_greeting, '') is not null then
    insert into messages (thread_id, sender_id, body)
      values (thread, auth.uid(), p_greeting);
  end if;

  return thread;
end $$;

-- Unread counters live server-side so badges stay correct across devices.
create or replace function public.bump_unread()
returns trigger language plpgsql security definer set search_path = public as $$ begin
  update thread_participants
     set unread = unread + 1
   where thread_id = new.thread_id and profile_id is distinct from new.sender_id;
  return new;
end $$;

drop trigger if exists trg_message_unread on public.messages;
create trigger trg_message_unread
  after insert on public.messages
  for each row execute function public.bump_unread();

revoke all on function public.admin_verify_company(uuid, boolean) from public;
revoke all on function public.admin_set_account_status(uuid, text) from public;
revoke all on function public.admin_assign_role(uuid, text) from public;
revoke all on function public.student_withdraw(uuid) from public;

-- Apple 5.1.1(v): an account must be deletable from inside the app. Dropping the auth
-- user cascades through profiles -> students -> applications/messages by FK.
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public as $$ begin
  if auth.uid() is null then
    raise exception 'sign in before deleting an account' using errcode = '42501';
  end if;
  delete from auth.users where id = auth.uid();
end $$;

revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;
revoke all on function public.open_thread(uuid, text, text, text) from public;
grant execute on function public.admin_verify_company(uuid, boolean) to authenticated;
grant execute on function public.admin_set_account_status(uuid, text) to authenticated;
grant execute on function public.admin_assign_role(uuid, text) to authenticated;
grant execute on function public.student_withdraw(uuid) to authenticated;
grant execute on function public.open_thread(uuid, text, text, text) to authenticated;

-- ─────────────────────────────────────────────────────────── read models
-- The app reads one of these per collection instead of a query per child table.
-- security_invoker keeps the underlying tables' RLS in force for every row.

-- Nested jsonb uses Swift property names verbatim: the PostgREST coder does not convert
-- keys inside a json value, so 'isDone' and 'sentAt' must be spelled as the model reads them.
drop view if exists public.student_records;
create view public.student_records
with (security_invoker = true) as
select
  st.id,
  p.full_name,
  upper(left(split_part(trim(p.full_name), ' ', 1), 1)
     || left(nullif(split_part(trim(p.full_name), ' ', 2), ''), 1)) as initials,
  st.programme,
  st.year,
  st.city,
  st.work_mode,
  st.availability,
  st.bio,
  st.profile_strength,
  st.advisor,
  st.cv_name,
  p.avatar_path,
  coalesce((select jsonb_agg(jsonb_build_object(
              'id', k.id, 'name', k.name, 'category', k.category,
              'proficiency', k.proficiency, 'evidence', k.evidence))
            from public.student_skills k where k.student_id = st.id), '[]'::jsonb) as skills,
  coalesce((select jsonb_agg(si.interest order by si.interest)
            from public.student_interests si where si.student_id = st.id), '[]'::jsonb) as interests,
  coalesce((select jsonb_agg(jsonb_build_object(
              'id', pr.id, 'title', pr.title, 'summary', pr.summary,
              'outcome', pr.outcome, 'year', pr.year))
            from public.projects pr where pr.student_id = st.id), '[]'::jsonb) as projects,
  coalesce((select jsonb_agg(jsonb_build_object(
              'id', c.id, 'name', c.name, 'issuer', c.issuer, 'year', c.year))
            from public.certificates c where c.student_id = st.id), '[]'::jsonb) as certificates
from public.students st
join public.profiles p on p.id = st.id;

drop view if exists public.role_records;
create view public.role_records
with (security_invoker = true) as
select
  i.id, i.company_id, i.title, i.location, i.work_mode, i.duration_weeks, i.compensation,
  i.is_paid, i.easy_apply, i.description, i.responsibilities, i.required_skills,
  i.preferred_skills, i.career_interests, i.category, i.team_size, i.status,
  i.posted_date, i.closing_date,
  c.name        as company_name,
  c.initials    as company_initials,
  c.logo_path   as company_logo_path,
  c.is_verified as company_is_verified,
  c.team_label  as company_team_label,
  c.website     as company_website,
  coalesce(c.location, i.location) as company_location,
  c.hired_last_cycle,
  (select count(*)::int from public.applications a
    where a.internship_id = i.id and a.stage <> 'declined') as applicants
from public.internships i
join public.companies c on c.id = i.company_id;

drop view if exists public.company_records;
create view public.company_records
with (security_invoker = true) as
select
  c.*,
  (select count(*)::int from public.internships i
    where i.company_id = c.id and i.status = 'open') as open_roles,
  (select count(*)::int from public.profiles p
    where p.company_id = c.id and p.role = 'employer') as contacts
from public.companies c;

drop view if exists public.application_records;
create view public.application_records
with (security_invoker = true) as
select
  a.id, a.internship_id, a.student_id, a.stage, a.submitted_date, a.last_update_date,
  a.interview_date, a.employer_note, a.next_action,
  i.company_id,
  coalesce((select jsonb_agg(jsonb_build_object(
              'id', e.id, 'title', e.title, 'detail', e.detail,
              'date', e.event_date, 'isDone', e.is_done) order by e.event_date)
            from public.application_events e where e.application_id = a.id), '[]'::jsonb) as timeline
from public.applications a
join public.internships i on i.id = a.internship_id;

-- One row per application, carrying the student inline: the employer pipeline board.
drop view if exists public.candidate_records;
create view public.candidate_records
with (security_invoker = true) as
select
  a.id            as application_id,
  a.internship_id,
  a.stage,
  st.id           as student_id,
  p.full_name,
  upper(left(split_part(trim(p.full_name), ' ', 1), 1)
     || left(nullif(split_part(trim(p.full_name), ' ', 2), ''), 1)) as initials,
  p.avatar_path,
  st.programme, st.year, st.city, st.work_mode, st.availability, st.bio,
  st.profile_strength, st.advisor, st.cv_name,
  coalesce((select jsonb_agg(jsonb_build_object(
              'id', k.id, 'name', k.name, 'category', k.category,
              'proficiency', k.proficiency, 'evidence', k.evidence) order by k.proficiency desc)
            from public.student_skills k where k.student_id = st.id limit 8), '[]'::jsonb) as skills,
  coalesce((select jsonb_agg(si.interest)
            from public.student_interests si where si.student_id = st.id), '[]'::jsonb) as interests
from public.applications a
join public.students st on st.id = a.student_id
join public.profiles p on p.id = st.id
where a.stage <> 'declined';

drop view if exists public.placement_records;
create view public.placement_records
with (security_invoker = true) as
select
  pl.id, pl.student_id, pl.stage, pl.readiness, pl.advisor,
  p.full_name as student_name,
  p.avatar_path,
  upper(left(split_part(trim(p.full_name), ' ', 1), 1)
     || left(nullif(split_part(trim(p.full_name), ' ', 2), ''), 1)) as initials,
  i.title as internship_title,
  coalesce((select jsonb_agg(k.name) from public.student_skills k
            where k.student_id = pl.student_id order by k.proficiency desc limit 4),
           '[]'::jsonb) as top_skills
from public.placements pl
join public.profiles p on p.id = pl.student_id
left join public.internships i on i.id = pl.internship_id;

drop view if exists public.conversation_records;
create view public.conversation_records
with (security_invoker = true) as
select
  t.id,
  t.subject,
  t.context,
  me.unread,
  peer.id              as participant_id,
  peer.full_name       as participant_name,
  peer.avatar_path     as participant_avatar_path,
  upper(left(split_part(trim(peer.full_name), ' ', 1), 1)
     || left(nullif(split_part(trim(peer.full_name), ' ', 2), ''), 1)) as participant_initials,
  coalesce((select jsonb_agg(jsonb_build_object(
              'id', m.id, 'threadID', m.thread_id, 'body', m.body,
              'sentAt', m.sent_at,
              'fromCurrentUser', m.sender_id = auth.uid()) order by m.sent_at)
            from public.messages m where m.thread_id = t.id), '[]'::jsonb) as messages
from public.threads t
join public.thread_participants me
  on me.thread_id = t.id and me.profile_id = auth.uid()
join public.thread_participants other
  on other.thread_id = t.id and other.profile_id <> auth.uid()
join public.profiles peer on peer.id = other.profile_id;

-- ─────────────────────────────────────────────────────────── Row Level Security
alter table public.profiles            enable row level security;
alter table public.companies           enable row level security;
alter table public.students            enable row level security;
alter table public.student_skills      enable row level security;
alter table public.student_interests   enable row level security;
alter table public.projects            enable row level security;
alter table public.certificates        enable row level security;
alter table public.internships         enable row level security;
alter table public.applications        enable row level security;
alter table public.application_events  enable row level security;
alter table public.saved_searches      enable row level security;
alter table public.saved_roles         enable row level security;
alter table public.placements          enable row level security;
alter table public.threads             enable row level security;
alter table public.thread_participants enable row level security;
alter table public.messages            enable row level security;

-- Privileged columns are taken away from client roles entirely; see the admin RPCs.
revoke update (role, status, company_id, email) on table public.profiles  from authenticated, anon;
revoke update (is_verified)                     on table public.companies from authenticated, anon;
revoke insert, update, delete, references, trigger on table public.authorized_domains from authenticated, anon;

drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles for select to authenticated using (
  id = auth.uid()
  or public.is_manager()
  or id in (select x.profile_id from public.thread_participants x
             where x.thread_id in (select y.thread_id from public.thread_participants y
                                   where y.profile_id = auth.uid()))
);

drop policy if exists profiles_insert on public.profiles;
create policy profiles_insert on public.profiles for insert to authenticated with check (
  id = auth.uid() and role = 'student'
);

drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles for update to authenticated using (
  id = auth.uid() or public.is_manager()
) with check (id = auth.uid() or public.is_manager());

drop policy if exists companies_select on public.companies;
create policy companies_select on public.companies for select to authenticated using (true);

drop policy if exists companies_insert on public.companies;
create policy companies_insert on public.companies for insert to authenticated with check (
  created_by = auth.uid() and not is_verified
);

drop policy if exists companies_update on public.companies;
create policy companies_update on public.companies for update to authenticated using (
  public.is_manager() or id = public.my_company_id()
) with check (public.is_manager() or id = public.my_company_id());

drop policy if exists companies_delete on public.companies;
create policy companies_delete on public.companies for delete to authenticated
  using (public.is_manager());

drop policy if exists students_select on public.students;
create policy students_select on public.students for select to authenticated using (
  public.student_is_readable(id)
);

drop policy if exists students_insert on public.students;
create policy students_insert on public.students for insert to authenticated with check (
  id = auth.uid()
);

drop policy if exists students_update on public.students;
create policy students_update on public.students for update to authenticated using (
  id = auth.uid() or public.is_manager()
) with check (id = auth.uid() or public.is_manager());

drop policy if exists students_delete on public.students;
create policy students_delete on public.students for delete to authenticated
  using (public.is_manager());

drop policy if exists skills_select on public.student_skills;
create policy skills_select on public.student_skills for select to authenticated using (
  public.student_is_readable(student_id)
);

drop policy if exists skills_insert on public.student_skills;
create policy skills_insert on public.student_skills for insert to authenticated with check (
  student_id = auth.uid()
);

drop policy if exists skills_update on public.student_skills;
create policy skills_update on public.student_skills for update to authenticated using (
  student_id = auth.uid()
) with check (student_id = auth.uid());

drop policy if exists skills_delete on public.student_skills;
create policy skills_delete on public.student_skills for delete to authenticated using (
  student_id = auth.uid() or public.is_manager()
);

drop policy if exists interests_select on public.student_interests;
create policy interests_select on public.student_interests for select to authenticated using (
  public.student_is_readable(student_id)
);

drop policy if exists interests_modify on public.student_interests;
create policy interests_modify on public.student_interests for all to authenticated using (
  student_id = auth.uid()
) with check (student_id = auth.uid());

drop policy if exists projects_select on public.projects;
create policy projects_select on public.projects for select to authenticated using (
  public.student_is_readable(student_id)
);

drop policy if exists projects_modify on public.projects;
create policy projects_modify on public.projects for all to authenticated using (
  student_id = auth.uid()
) with check (student_id = auth.uid());

drop policy if exists certificates_select on public.certificates;
create policy certificates_select on public.certificates for select to authenticated using (
  public.student_is_readable(student_id)
);

drop policy if exists certificates_modify on public.certificates;
create policy certificates_modify on public.certificates for all to authenticated using (
  student_id = auth.uid()
) with check (student_id = auth.uid());

-- Students see live roles from verified companies. An employer also sees its own
-- drafts and closed posts. A manager sees everything.
drop policy if exists internships_select on public.internships;
create policy internships_select on public.internships for select to authenticated using (
  public.is_manager()
  or company_id = public.my_company_id()
  or (status = 'open' and exists (select 1 from public.companies c
        where c.id = internships.company_id and c.is_verified))
);

drop policy if exists internships_insert on public.internships;
create policy internships_insert on public.internships for insert to authenticated with check (
  public.is_manager() or company_id = public.my_company_id()
);

drop policy if exists internships_update on public.internships;
create policy internships_update on public.internships for update to authenticated using (
  public.is_manager() or company_id = public.my_company_id()
) with check (public.is_manager() or company_id = public.my_company_id());

drop policy if exists internships_delete on public.internships;
create policy internships_delete on public.internships for delete to authenticated using (
  public.is_manager() or company_id = public.my_company_id()
);

drop policy if exists applications_select on public.applications;
create policy applications_select on public.applications for select to authenticated using (
  student_id = auth.uid()
  or public.is_manager()
  or internship_id in (select i.id from public.internships i
                        where i.company_id = public.my_company_id())
);

drop policy if exists applications_insert on public.applications;
create policy applications_insert on public.applications for insert to authenticated with check (
  student_id = auth.uid()
  and stage = 'submitted'
  -- Only against a role the student is actually allowed to apply to.
  and exists (select 1 from public.internships i
              where i.id = internship_id and i.status = 'open')
);

-- Only the hiring side and the manager move an application forward. A student's one
-- write (withdrawal) goes through student_withdraw() above, so stage is unwritable
-- from the API for them.
drop policy if exists applications_update on public.applications;
create policy applications_update on public.applications for update to authenticated using (
  public.is_manager()
  or internship_id in (select i.id from public.internships i
                        where i.company_id = public.my_company_id())
) with check (
  public.is_manager()
  or internship_id in (select i.id from public.internships i
                        where i.company_id = public.my_company_id())
);

drop policy if exists events_select on public.application_events;
create policy events_select on public.application_events for select to authenticated using (
  exists (select 1 from public.applications a where a.id = application_id
          and (a.student_id = auth.uid() or public.is_manager()
               or a.internship_id in (select i.id from public.internships i
                     where i.company_id = public.my_company_id())))
);

drop policy if exists events_insert on public.application_events;
create policy events_insert on public.application_events for insert to authenticated with check (
  exists (select 1 from public.applications a where a.id = application_id
          and (a.student_id = auth.uid() or public.is_manager()
               or a.internship_id in (select i.id from public.internships i
                     where i.company_id = public.my_company_id())))
);

drop policy if exists searches_rw on public.saved_searches;
create policy searches_rw on public.saved_searches for all to authenticated using (
  student_id = auth.uid()
) with check (student_id = auth.uid());

drop policy if exists saved_roles_rw on public.saved_roles;
create policy saved_roles_rw on public.saved_roles for all to authenticated using (
  student_id = auth.uid()
) with check (student_id = auth.uid());

drop policy if exists placements_select on public.placements;
create policy placements_select on public.placements for select to authenticated using (
  student_id = auth.uid() or public.is_manager()
);

drop policy if exists placements_insert on public.placements;
create policy placements_insert on public.placements for insert to authenticated with check (
  public.is_manager() or student_id = auth.uid()
);

drop policy if exists placements_update on public.placements;
create policy placements_update on public.placements for update to authenticated using (
  public.is_manager()
) with check (public.is_manager());

drop policy if exists threads_select on public.threads;
create policy threads_select on public.threads for select to authenticated
  using (public.is_participant(id));

drop policy if exists threads_insert on public.threads;
create policy threads_insert on public.threads for insert to authenticated with check (true);

drop policy if exists participants_select on public.thread_participants;
create policy participants_select on public.thread_participants for select to authenticated using (
  profile_id = auth.uid()
  or thread_id in (select x.thread_id from public.thread_participants x
                   where x.profile_id = auth.uid())
);

drop policy if exists participants_insert on public.thread_participants;
create policy participants_insert on public.thread_participants for insert to authenticated with check (
  -- I add myself to a thread I started, or I am inside the thread already.
  profile_id = auth.uid()
  or exists (select 1 from public.thread_participants x
             where x.thread_id = thread_id and x.profile_id = auth.uid())
);

drop policy if exists participants_update on public.thread_participants;
create policy participants_update on public.thread_participants for update to authenticated using (
  profile_id = auth.uid()
) with check (profile_id = auth.uid());

drop policy if exists messages_select on public.messages;
create policy messages_select on public.messages for select to authenticated using (
  public.is_participant(thread_id)
);

drop policy if exists messages_insert on public.messages;
create policy messages_insert on public.messages for insert to authenticated with check (
  sender_id = auth.uid() and public.is_participant(thread_id)
);

-- ─────────────────────────────────────────────────────────── storage
insert into storage.buckets (id, name, public)
  values ('avatars', 'avatars', true), ('cvs', 'cvs', false)
on conflict (id) do update set public = excluded.public;

-- Objects are namespaced by the owner's auth uid: <uid>/avatar.jpg, <uid>/cv.pdf
drop policy if exists avatars_read  on storage.objects;
create policy avatars_read on storage.objects for select using (bucket_id = 'avatars');

drop policy if exists avatars_write on storage.objects;
create policy avatars_write on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists avatars_update on storage.objects;
create policy avatars_update on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists avatars_delete on storage.objects;
create policy avatars_delete on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists cvs_read on storage.objects;
create policy cvs_read on storage.objects for select to authenticated
  using (bucket_id = 'cvs' and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.is_manager()
    or (storage.foldername(name))[1] in (select (public.applied_student_ids())::text)));

drop policy if exists cvs_write on storage.objects;
create policy cvs_write on storage.objects for insert to authenticated
  with check (bucket_id = 'cvs' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists cvs_update on storage.objects;
create policy cvs_update on storage.objects for update to authenticated
  using (bucket_id = 'cvs' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists cvs_delete on storage.objects;
create policy cvs_delete on storage.objects for delete to authenticated
  using (bucket_id = 'cvs' and (storage.foldername(name))[1] = auth.uid()::text);

-- Company logos live under the owning company's id.
insert into storage.buckets (id, name, public) values ('logos', 'logos', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists logos_read on storage.objects;
create policy logos_read on storage.objects for select using (bucket_id = 'logos');

drop policy if exists logos_write on storage.objects;
create policy logos_write on storage.objects for insert to authenticated
  with check (bucket_id = 'logos' and (
    (storage.foldername(name))[1] = coalesce(public.my_company_id()::text, 'none')
    or public.is_manager()));

drop policy if exists logos_update on storage.objects;
create policy logos_update on storage.objects for update to authenticated
  using (bucket_id = 'logos' and (
    (storage.foldername(name))[1] = coalesce(public.my_company_id()::text, 'none')
    or public.is_manager()));

drop policy if exists logos_delete on storage.objects;
create policy logos_delete on storage.objects for delete to authenticated
  using (bucket_id = 'logos' and (
    (storage.foldername(name))[1] = coalesce(public.my_company_id()::text, 'none')
    or public.is_manager()));

-- ─────────────────────────────────────────────────────────── staff domains
-- Edit these from the dashboard; the app cannot write this table.
insert into public.authorized_domains (domain, role) values
  ('mcri.ac.za', 'program_manager'),
  ('mcri.org', 'program_manager')
on conflict (domain) do nothing;
