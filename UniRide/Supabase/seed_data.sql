-- ═══════════════════════════════════════════════════════════════
-- STEP 1 — Update RLS policies so the event_admin can write
-- Run this block first (separate query)
-- ═══════════════════════════════════════════════════════════════

-- EVENTS: admin-only write
drop policy if exists "Event admins can create events"  on public.events;
drop policy if exists "Event admins can update events"  on public.events;
drop policy if exists "Event admins can delete events"  on public.events;

create policy "Event admins can create events"
  on public.events for insert
  with check (
    exists (select 1 from public.profiles
            where profiles.id = auth.uid() and profiles.role = 'event_admin')
  );

create policy "Event admins can update events"
  on public.events for update
  using (
    exists (select 1 from public.profiles
            where profiles.id = auth.uid() and profiles.role = 'event_admin')
  );

create policy "Event admins can delete events"
  on public.events for delete
  using (
    exists (select 1 from public.profiles
            where profiles.id = auth.uid() and profiles.role = 'event_admin')
  );

-- TRIPS: admin-only write
drop policy if exists "Event admin can insert trips"  on public.trips;
drop policy if exists "Event admin can update trips"  on public.trips;
drop policy if exists "Event admin can delete trips"  on public.trips;

create policy "Event admin can insert trips"
  on public.trips for insert
  with check (
    exists (select 1 from public.profiles
            where profiles.id = auth.uid() and profiles.role = 'event_admin')
  );

create policy "Event admin can update trips"
  on public.trips for update
  using (
    exists (select 1 from public.profiles
            where profiles.id = auth.uid() and profiles.role = 'event_admin')
  );

create policy "Event admin can delete trips"
  on public.trips for delete
  using (
    exists (select 1 from public.profiles
            where profiles.id = auth.uid() and profiles.role = 'event_admin')
  );

-- Confirm the admin account has the right role
update public.profiles
set role = 'event_admin'
where id = (select id from auth.users
            where email = 'events.admin@chitkara.edu.in' limit 1);


-- ═══════════════════════════════════════════════════════════════
-- STEP 2 — Seed trips  (run as a second query after step 1)
-- ═══════════════════════════════════════════════════════════════

insert into public.trips (
  created_by_user_id, title, location, date_range,
  start_date, end_date, price, spots_total, spots_left,
  organizer, image_name, about,
  itinerary_json, inclusions, exclusions, is_active
)
select
  u.id,
  t.title, t.location, t.date_range,
  t.start_date, t.end_date, t.price, t.spots_total, t.spots_left,
  t.organizer, t.image_name, t.about,
  t.itinerary_json, t.inclusions, t.exclusions, true
from auth.users u
cross join (values

  (
    'Manali Adventure Trip',
    'Manali, Himachal Pradesh',
    '12–15 June',
    now() + interval '42 days', now() + interval '45 days',
    5999, 12, 9,
    'Adventure Trips Co.',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
    'Experience the thrill of the Himalayas with our 4-day adventure trip to Manali. Enjoy scenic views, adventure sports, and local culture with a small group of fellow students.',
    '[{"title":"Day 1: Arrival & Local Sightseeing","activities":["Check-in to hotel","Visit Hadimba Temple","Explore Mall Road","Evening bonfire"]},{"title":"Day 2: Solang Valley Adventure","activities":["Paragliding session","Zorbing","Snow activities","Mountain biking"]},{"title":"Day 3: Rohtang Pass","activities":["Sunrise trek","Photography at the pass","Snow trek","Local cuisine lunch"]},{"title":"Day 4: Departure","activities":["Morning hike","Shopping time","Drop at bus stand"]}]'::jsonb,
    '3 nights accommodation
Daily breakfast & dinner
All transportation from Chandigarh
Adventure activities (paragliding + zorbing)
Professional certified guide',
    'Lunch on all days
Personal expenses & shopping
Travel insurance
Any extra activities not listed'
  ),

  (
    'Himalayan Snow Trek',
    'Solang Valley, Himachal Pradesh',
    '20–24 June',
    now() + interval '51 days', now() + interval '55 days',
    7499, 15, 11,
    'Himalayan Trails',
    'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800&q=80',
    'A 5-day immersive snow trek through the pristine valleys of Himachal Pradesh. Perfect for adventure enthusiasts wanting to experience the raw beauty of the Himalayas with certified guides.',
    '[{"title":"Day 1: Base Camp Setup","activities":["Arrival at Solang Valley","Setup base camp","Acclimatization walk","Safety briefing session"]},{"title":"Day 2: Snow Trek Begins","activities":["Early morning start at 5 AM","Trek to upper valley","Snow crossing at 3000m","Camp at 3200m altitude"]},{"title":"Day 3: Summit Attempt","activities":["Summit push at dawn","360 degree panoramic views","Descend to camp","Bonfire night with music"]},{"title":"Day 4: Return Trek","activities":["Return trek through alternate route","Visit local Himachali village","Cultural exchange dinner"]},{"title":"Day 5: Departure","activities":["Pack camp and certificate ceremony","Group photo","Drop at Manali bus stand"]}]'::jsonb,
    '4 nights high-altitude camping
All meals (veg + non-veg options)
Full trekking equipment rental
Certified mountain guide
First aid kit & oxygen cylinder',
    'Personal trekking gear (boots, jacket)
Travel insurance
Tips & gratuities
Extra snacks & beverages'
  ),

  (
    'Spiti Valley Circuit',
    'Spiti, Himachal Pradesh',
    '5–12 July',
    now() + interval '65 days', now() + interval '72 days',
    12999, 10, 7,
    'Mountain Explorers',
    'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800&q=80',
    'Explore the cold desert moonscape of Spiti Valley on this 8-day circuit covering ancient Buddhist monasteries, high-altitude villages, and surreal landscapes above 4000m.',
    '[{"title":"Day 1: Shimla to Narkanda","activities":["Pickup from Shimla ISBT","Drive to Narkanda 65 km","Hatu Peak visit","Overnight stay at homestay"]},{"title":"Day 2: Narkanda to Sangla","activities":["Drive through Kinnaur valley","Sangla Valley sightseeing","Chitkul - last village near border"]},{"title":"Day 3: Sangla to Kaza","activities":["Drive via Spiti river gorge","Dhankar Monastery","Kaza town exploration"]},{"title":"Day 4-6: Spiti Circuit","activities":["Key Monastery at 4166m","Kibber - highest motorable village","Chandratal Lake trek","Pin Valley National Park"]},{"title":"Day 7: Kaza to Manali","activities":["Kunzum Pass at 4551m","Rohtang Pass crossing","Arrive Manali by evening"]},{"title":"Day 8: Departure","activities":["Morning free time","Drop at Manali or Volvo bus to Chandigarh"]}]'::jsonb,
    '7 nights accommodation (homestays & guesthouses)
All meals throughout the trip
Comfortable SUV transport
All inner line permits & entry fees
Experienced local guide',
    'Flights or train to Shimla
Personal expenses & shopping
Travel & medical insurance
Porter charges if needed'
  ),

  (
    'Rishikesh Rafting Weekend',
    'Rishikesh, Uttarakhand',
    '19–21 July',
    now() + interval '79 days', now() + interval '81 days',
    4299, 20, 14,
    'River Rush Adventures',
    'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800&q=80',
    'An action-packed weekend on the holy Ganges with Grade 4-5 white water rafting, cliff jumping, and a visit to the iconic Beatles Ashram. One of India top-rated student adventure weekends.',
    '[{"title":"Day 1: Arrival & Evening Aarti","activities":["Check-in to riverside camp","Equipment briefing & safety drill","Grade 3 practice rapid","Evening Ganga aarti at Triveni Ghat"]},{"title":"Day 2: Full Adventure Day","activities":["Grade 4-5 white water rafting 26 km","Cliff jumping at Shivpuri","Body surfing at Natural Pool","Beatles Ashram guided tour"]},{"title":"Day 3: Yoga & Departure","activities":["Sunrise yoga session on the ghats","Local market shopping in Laxman Jhula","Drop at Rishikesh railway station"]}]'::jsonb,
    '2 nights riverside camp accommodation
All meals (3 days)
Rafting with all safety gear included
Trained river guide
Beatles Ashram entry',
    'Bungee jumping (optional, extra cost)
Personal travel insurance
Alcohol & personal expenses
Tips'
  ),

  (
    'Kasol & Kheerganga Trek',
    'Parvati Valley, Himachal Pradesh',
    '15–17 March',
    now() - interval '46 days', now() - interval '44 days',
    3499, 12, 0,
    'Backpacker Collective',
    'https://images.unsplash.com/photo-1501854140801-50d01698950b?w=800&q=80',
    'A relaxing 3-day trip to the bohemian village of Kasol followed by a 12 km trek to the natural hot springs of Kheerganga at 2950m. Perfect for first-time trekkers.',
    '[{"title":"Day 1: Arrival at Kasol","activities":["Arrival and check-in to cafe camp","Explore Kasol village and market","Riverside campfire evening"]},{"title":"Day 2: Kheerganga Trek","activities":["Start trek from Barshaini at 7 AM","Pass through Rudra Nag waterfall","Reach Kheerganga meadows","Dip in natural hot water spring"]},{"title":"Day 3: Return & Departure","activities":["Sunrise views over Parvati valley","Descend to Barshaini","Drive back to Bhuntar for bus"]}]'::jsonb,
    '2 nights accommodation (Kasol + Kheerganga camp)
All meals
Trek guide & forest permits
Campfire both nights',
    'Bus transport to/from Bhuntar
Personal expenses
Camera permit in forest area'
  )

) as t(title, location, date_range, start_date, end_date, price, spots_total, spots_left,
        organizer, image_name, about, itinerary_json, inclusions, exclusions)
where u.email = 'events.admin@chitkara.edu.in';


-- ═══════════════════════════════════════════════════════════════
-- STEP 3 — Seed events  (run as a third query)
-- ═══════════════════════════════════════════════════════════════

insert into public.events (
  created_by_user_id, title, details, location_name,
  starts_at, ends_at, image_name,
  attendee_count, day_scholar_count, share_count
)
select
  u.id,
  e.title, e.details, e.location_name,
  e.starts_at, e.ends_at, e.image_name,
  0, 0, 0
from auth.users u
cross join (values

  (
    'Rangrez 2026',
    'Get ready for the most awaited cultural fest of the year! Rangrez 2026 brings art, music, and dance together for an unforgettable celebration.

Electrifying performances by top Punjabi artists — from classical symphony to rock fusion. Grand finale night features a surprise celebrity guest.

Food stalls offering cuisines from across India, student art exhibitions, interactive gaming zones, and live DJ nights.

Venue: Chitkara University Main Ground
Time: 4:00 PM onwards
Entry: Free for students with valid ID cards',
    'Chitkara University Main Ground',
    now() + interval '5 days',
    now() + interval '7 days',
    'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&q=80'
  ),

  (
    'Techno Fest 2026',
    'Step into the future with Techno Fest 2026! Three days of innovation, technology, and pure energy.

Cutting-edge robotics demos, live AI presentations, and 24-hour coding marathons with prizes worth Rs 50,000.

Workshops include:
- Blockchain & Web3 Development
- Ethical Hacking & Cybersecurity
- Drone Racing Championship
- Machine Learning Bootcamp

Concludes with an EDM night featuring top electronic artists. Network with industry leaders from Google, Microsoft, and top startups.

Venue: Engineering Block, Chitkara University
Starts: 10:00 AM
Register at the CSE department',
    'Engineering Block, Chitkara University',
    now() + interval '12 days',
    now() + interval '14 days',
    'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&q=80'
  ),

  (
    'Annual Sports Meet 2026',
    'Unleash your inner athlete at the Annual Sports Meet 2026!

Compete across 15+ sports: Cricket, Football, Basketball, Volleyball, Athletics (100m/200m/400m), Badminton, Table Tennis, and Chess.

Open to all students, faculty, and staff. Team registrations open now at the Sports Complex office.

Prizes: Trophies, medals, and certificates for top 3 in every event
Venue: Sports Complex & Ground, Chitkara University
Starts: 9:00 AM sharp

Come show your team spirit and fight for your department!',
    'Sports Complex, Chitkara University',
    now() + interval '19 days',
    now() + interval '21 days',
    'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=800&q=80'
  ),

  (
    'HackCU 2026 — 24hr Hackathon',
    'Code your way to glory in HackCU 2026, our flagship 24-hour hackathon!

Build innovative solutions to real-world problems in tracks:
- Sustainability & CleanTech
- HealthTech & AI
- EdTech & Student Life
- FinTech & Payments

Mentors from Google, Razorpay, Zepto, and top startups will guide you. Free food, energy drinks, and merch throughout.

Total prize pool: Rs 1,00,000
1st Place: Rs 50,000 + internship interviews
2nd Place: Rs 25,000
3rd Place: Rs 15,000

Venue: Innovation Lab, Chitkara University
Starts: 11:00 AM — Register in teams of 2-4',
    'Innovation Lab, Chitkara University',
    now() + interval '26 days',
    now() + interval '27 days',
    'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&q=80'
  )

) as e(title, details, location_name, starts_at, ends_at, image_name)
where u.email = 'events.admin@chitkara.edu.in';
