-- MCRI Connect — local / demo seed users.
-- Run this in the Supabase dashboard SQL Editor after `schema.sql` has been applied.
-- These accounts let you sign in on a real device or simulator without using `-mcri.sample`.
-- All three share the same demo password: TestDemo2024!
-- Never run this against a production project.

-- Shared demo password (bcrypt cost 10).
-- Generated with: htpasswd -nbB -C 10 demo TestDemo2024! | sed 's/^\$2y\$/$2a$/'

-- ─────────────────────────────────────────────────────────── company (inserted first so
-- the auth trigger resolves the employer to this existing record by name)
insert into public.companies (
  id, name, initials, tagline, website, location, registration_number,
  team_label, open_roles, is_verified, hired_last_cycle
) values (
  'a0000000-0000-0000-0000-000000000001'::uuid,
  'Orbit Labs', 'O',
  'Product studios for health and finance',
  'https://orbitlabs.co.za',
  'Cape Town',
  '2016/442187/07',
  'Product guild · 2 open roles',
  2, true, 6
)
on conflict (id) do update set
  name = excluded.name,
  initials = excluded.initials,
  tagline = excluded.tagline,
  website = excluded.website,
  location = excluded.location,
  registration_number = excluded.registration_number,
  team_label = excluded.team_label,
  open_roles = excluded.open_roles,
  is_verified = excluded.is_verified,
  hired_last_cycle = excluded.hired_last_cycle,
  updated_at = now();

-- ─────────────────────────────────────────────────────────── test users
-- The metadata includes requested_role so the auth trigger creates the right profile shape.
insert into auth.users (
  id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at
) values
  (
    'c0000000-0000-0000-0000-000000000001'::uuid,
    'alex@mcri.ac.za',
    '$2a$10$FnZQj25ZS6FD.YIentUQhOHZJkgsHDzHSictL0PtDPeWIXHBQIjCy',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Alex Mensah","requested_role":"student"}',
    now(), now()
  ),
  (
    'd0000000-0000-0000-0000-000000000001'::uuid,
    'priya@orbitlabs.co.za',
    '$2a$10$FnZQj25ZS6FD.YIentUQhOHZJkgsHDzHSictL0PtDPeWIXHBQIjCy',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Priya Naidoo","requested_role":"employer","company_name":"Orbit Labs"}',
    now(), now()
  ),
  (
    'd0000000-0000-0000-0000-000000000002'::uuid,
    'nomsa@mcri.ac.za',
    '$2a$10$FnZQj25ZS6FD.YIentUQhOHZJkgsHDzHSictL0PtDPeWIXHBQIjCy',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Nomsa Dube","requested_role":"program_manager"}',
    now(), now()
  )
on conflict (id) do update set
  encrypted_password = excluded.encrypted_password,
  email_confirmed_at = excluded.email_confirmed_at,
  raw_user_meta_data = excluded.raw_user_meta_data,
  updated_at = now();

-- Ensure the auth identities rows exist (GoTrue uses these for password login).
insert into auth.identities (
  id, user_id, provider, identity_data, created_at, updated_at
) values
  ('c0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'email',
   '{"sub":"c0000000-0000-0000-0000-000000000001","email":"alex@mcri.ac.za"}'::jsonb, now(), now()),
  ('d0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 'email',
   '{"sub":"d0000000-0000-0000-0000-000000000001","email":"priya@orbitlabs.co.za"}'::jsonb, now(), now()),
  ('d0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000002', 'email',
   '{"sub":"d0000000-0000-0000-0000-000000000002","email":"nomsa@mcri.ac.za"}'::jsonb, now(), now())
on conflict (id) do update set
  identity_data = excluded.identity_data,
  updated_at = now();

-- ─────────────────────────────────────────────────────────── enrich profiles
insert into public.profiles (
  id, role, full_name, email, status, company_id
) values
  ('c0000000-0000-0000-0000-000000000001'::uuid, 'student', 'Alex Mensah', 'alex@mcri.ac.za', 'active', null),
  ('d0000000-0000-0000-0000-000000000001'::uuid, 'employer', 'Priya Naidoo', 'priya@orbitlabs.co.za', 'active',
   'a0000000-0000-0000-0000-000000000001'::uuid),
  ('d0000000-0000-0000-0000-000000000002'::uuid, 'program_manager', 'Nomsa Dube', 'nomsa@mcri.ac.za', 'active', null)
on conflict (id) do update set
  role = excluded.role,
  full_name = excluded.full_name,
  email = excluded.email,
  status = excluded.status,
  company_id = excluded.company_id,
  updated_at = now();

-- ─────────────────────────────────────────────────────────── enrich student row for Alex
insert into public.students (
  id, programme, year, city, work_mode, availability, bio, profile_strength, advisor
) values (
  'c0000000-0000-0000-0000-000000000001'::uuid,
  'BSc Product Design', 'Year 2', 'Cape Town', 'remote', 'June – August 2026',
  'Design student who ships what they draw. Two years of studio work, one campus app in production.',
  78, 'Nomsa Dube'
)
on conflict (id) do update set
  programme = excluded.programme,
  year = excluded.year,
  city = excluded.city,
  work_mode = excluded.work_mode,
  availability = excluded.availability,
  bio = excluded.bio,
  profile_strength = excluded.profile_strength,
  advisor = excluded.advisor,
  updated_at = now();
