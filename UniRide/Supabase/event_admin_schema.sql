-- Optional production schema for event-admin publishing.
-- The in-app fixed OTP gate is only a prototype/local-admin shortcut.
-- For real publishing, create a real Supabase user and set their profile role
-- to 'event_admin', then run these policies.

alter table public.events enable row level security;

-- If your profiles table already has a stricter role check, replace it with one
-- that includes event_admin. Skip this block if role is free text in your DB.
alter table public.profiles
drop constraint if exists profiles_role_check;

alter table public.profiles
add constraint profiles_role_check
check (role in ('student', 'faculty', 'event_admin'));

drop policy if exists "Public events are viewable by everyone" on public.events;
create policy "Public events are viewable by everyone"
on public.events
for select
using (true);

drop policy if exists "Event admins can create events" on public.events;
create policy "Event admins can create events"
on public.events
for insert
with check (
  exists (
    select 1
    from public.profiles
    where profiles.id = auth.uid()
      and profiles.role = 'event_admin'
  )
);

drop policy if exists "Event admins can update events" on public.events;
create policy "Event admins can update events"
on public.events
for update
using (
  exists (
    select 1
    from public.profiles
    where profiles.id = auth.uid()
      and profiles.role = 'event_admin'
  )
)
with check (
  exists (
    select 1
    from public.profiles
    where profiles.id = auth.uid()
      and profiles.role = 'event_admin'
  )
);

drop policy if exists "Event admins can delete events" on public.events;
create policy "Event admins can delete events"
on public.events
for delete
using (
  exists (
    select 1
    from public.profiles
    where profiles.id = auth.uid()
      and profiles.role = 'event_admin'
  )
);
