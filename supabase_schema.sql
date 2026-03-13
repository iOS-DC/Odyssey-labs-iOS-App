-- UniRide Supabase schema expected by current iOS networking layer
-- Run this in Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  phone text,
  is_email_verified boolean not null default false,
  is_phone_verified boolean not null default false,
  full_name text,
  role text check (role in ('student', 'faculty')),
  course_name text,
  year integer,
  employee_id text,
  photo_url text,
  home_location jsonb,
  home_locations jsonb,
  last_known_location jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  created_by_user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  details text,
  location_name text,
  starts_at timestamptz not null,
  ends_at timestamptz,
  attendee_count integer not null default 0,
  day_scholar_count integer not null default 0,
  image_name text,
  share_count integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.rides (
  id uuid primary key,
  driver_user_id uuid not null references public.profiles(id) on delete cascade,
  source jsonb not null,
  destination jsonb not null,
  departure_time timestamptz not null,
  seats_total integer not null check (seats_total >= 1),
  seats_available integer not null check (seats_available >= 0),
  fare_per_seat numeric(10,2) not null check (fare_per_seat >= 0),
  status text not null check (status in ('draft', 'published', 'ongoing', 'completed', 'cancelled')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ride_requests (
  id uuid primary key,
  ride_id uuid not null references public.rides(id) on delete cascade,
  passenger_user_id uuid not null references public.profiles(id) on delete cascade,
  pickup_point jsonb not null,
  seats integer not null check (seats >= 1),
  min_acceptable_fare numeric(10,2),
  status text not null default 'pending' check (status in ('pending', 'approved', 'denied', 'cancelled')),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (ride_id, passenger_user_id)
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid not null references public.rides(id) on delete cascade,
  passenger_user_id uuid not null references public.profiles(id) on delete cascade,
  seats integer not null check (seats >= 1),
  pickup_point jsonb not null,
  status text not null default 'confirmed' check (status in ('confirmed', 'cancelled')),
  created_at timestamptz not null default now()
);

create index if not exists idx_events_starts_at on public.events(starts_at);
create index if not exists idx_rides_status_departure on public.rides(status, departure_time);
create index if not exists idx_ride_requests_ride on public.ride_requests(ride_id);
create index if not exists idx_bookings_ride on public.bookings(ride_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_rides_updated_at on public.rides;
create trigger trg_rides_updated_at
before update on public.rides
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.events enable row level security;
alter table public.rides enable row level security;
alter table public.ride_requests enable row level security;
alter table public.bookings enable row level security;

-- Profiles: user can read/write own profile
create policy if not exists "profiles_select_own"
on public.profiles for select
using (auth.uid() = id);

create policy if not exists "profiles_insert_own"
on public.profiles for insert
with check (auth.uid() = id);

create policy if not exists "profiles_update_own"
on public.profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);

-- Events: readable by authenticated users
create policy if not exists "events_select_authenticated"
on public.events for select
using (auth.role() = 'authenticated');

create policy if not exists "events_insert_authenticated"
on public.events for insert
with check (auth.role() = 'authenticated');

-- Rides: readable by authenticated users; only driver can insert/update own ride
create policy if not exists "rides_select_authenticated"
on public.rides for select
using (auth.role() = 'authenticated');

create policy if not exists "rides_insert_driver"
on public.rides for insert
with check (auth.uid() = driver_user_id);

create policy if not exists "rides_update_driver"
on public.rides for update
using (auth.uid() = driver_user_id)
with check (auth.uid() = driver_user_id);

-- Ride requests: passenger creates, passenger/driver can view, passenger/driver can update status
create policy if not exists "ride_requests_select_participant"
on public.ride_requests for select
using (
  auth.uid() = passenger_user_id
  or exists (
    select 1 from public.rides r
    where r.id = ride_requests.ride_id
      and r.driver_user_id = auth.uid()
  )
);

create policy if not exists "ride_requests_insert_passenger"
on public.ride_requests for insert
with check (auth.uid() = passenger_user_id);

create policy if not exists "ride_requests_update_participant"
on public.ride_requests for update
using (
  auth.uid() = passenger_user_id
  or exists (
    select 1 from public.rides r
    where r.id = ride_requests.ride_id
      and r.driver_user_id = auth.uid()
  )
)
with check (
  auth.uid() = passenger_user_id
  or exists (
    select 1 from public.rides r
    where r.id = ride_requests.ride_id
      and r.driver_user_id = auth.uid()
  )
);

-- Bookings: participant visibility; driver can update cancellation
create policy if not exists "bookings_select_participant"
on public.bookings for select
using (
  auth.uid() = passenger_user_id
  or exists (
    select 1 from public.rides r
    where r.id = bookings.ride_id
      and r.driver_user_id = auth.uid()
  )
);

create policy if not exists "bookings_insert_driver"
on public.bookings for insert
with check (
  exists (
    select 1 from public.rides r
    where r.id = bookings.ride_id
      and r.driver_user_id = auth.uid()
  )
);

create policy if not exists "bookings_update_participant"
on public.bookings for update
using (
  auth.uid() = passenger_user_id
  or exists (
    select 1 from public.rides r
    where r.id = bookings.ride_id
      and r.driver_user_id = auth.uid()
  )
)
with check (
  auth.uid() = passenger_user_id
  or exists (
    select 1 from public.rides r
    where r.id = bookings.ride_id
      and r.driver_user_id = auth.uid()
  )
);
