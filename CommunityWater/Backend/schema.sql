-- Run in a dedicated Supabase project's SQL editor.
-- Add verified water points as an administrator; the app does not publish demo locations.
create table if not exists public.water_points (
    id text primary key check (length(id) between 1 and 100),
    name text not null check (length(name) between 1 and 200),
    type text not null check (type in ('borehole', 'tap', 'well', 'other')),
    area text not null check (length(area) between 1 and 200),
    latitude double precision not null check (latitude between -90 and 90),
    longitude double precision not null check (longitude between -180 and 180)
);

create table if not exists public.water_reports (
    id uuid primary key,
    point_id text not null references public.water_points(id),
    condition text not null check (condition in ('working', 'broken', 'dry', 'unknown')),
    crowding text not null default 'unknown' check (crowding in ('unknown', 'quiet', 'crowded')),
    repaired boolean not null default false,
    note text not null default '' check (char_length(note) <= 500),
    observed_at timestamptz not null check (observed_at <= now() + interval '5 minutes'),
    received_at timestamptz not null default now()
);

create index if not exists water_reports_point_time on public.water_reports(point_id, observed_at desc);
alter table public.water_points enable row level security;
alter table public.water_reports enable row level security;

revoke all on public.water_points from anon, authenticated;
revoke all on public.water_reports from anon, authenticated;
grant select on public.water_points to anon, authenticated;
grant select, insert on public.water_reports to anon, authenticated;

drop policy if exists "Community reads points" on public.water_points;
create policy "Community reads points" on public.water_points for select to anon, authenticated using (true);
drop policy if exists "Community reads reports" on public.water_reports;
create policy "Community reads reports" on public.water_reports for select to anon, authenticated using (true);
drop policy if exists "Community adds reports" on public.water_reports;
create policy "Community adds reports" on public.water_reports for insert to anon, authenticated with check (true);

-- Administrative example; replace with a real verified location before running:
-- insert into public.water_points(id, name, type, area, latitude, longitude)
-- values ('your-stable-id', 'Verified community borehole', 'borehole', 'Your area', -17.89, 30.95);

-- This pilot permits anonymous public reports. No client can edit/delete reports or points.
-- Before a wider public launch, add authenticated reporting, rate limits and moderation.
