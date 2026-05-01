-- Trips table for admin-posted community trips
create table if not exists public.trips (
    id uuid primary key default gen_random_uuid(),
    created_by_user_id uuid not null,
    title text not null,
    location text not null,
    date_range text not null,
    start_date timestamp with time zone not null,
    end_date timestamp with time zone,
    price integer not null default 0,
    spots_total integer not null default 10,
    spots_left integer not null default 10,
    organizer text not null default '',
    image_name text,
    about text,
    itinerary_json jsonb,
    inclusions text,
    exclusions text,
    is_active boolean not null default true,
    created_at timestamp with time zone default now()
);

-- Allow anyone (anon + authenticated) to read active trips
alter table public.trips enable row level security;

create policy "Anyone can read active trips"
    on public.trips for select
    using (is_active = true);

-- Only event admins can insert / update / delete
create policy "Event admin can insert trips"
    on public.trips for insert
    with check (
        exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
              and profiles.role = 'event_admin'
        )
    );

create policy "Event admin can update trips"
    on public.trips for update
    using (
        exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
              and profiles.role = 'event_admin'
        )
    );

create policy "Event admin can delete trips"
    on public.trips for delete
    using (
        exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
              and profiles.role = 'event_admin'
        )
    );
