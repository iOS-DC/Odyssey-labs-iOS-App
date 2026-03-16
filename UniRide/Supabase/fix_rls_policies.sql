-- SQL Fixes for UniRide Multi-Device Data Consistency
-- Run this in the Supabase SQL Editor

-- 1. Enable RLS on all tables (if not already enabled)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ride_requests ENABLE ROW LEVEL SECURITY;

-- 2. Profiles: Allow anyone to read basic profile info (needed for names/photos/roles)
-- This allows Device B to see Device A's name even if they aren't 'friends'.
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone" 
ON public.profiles FOR SELECT 
USING (true);

-- 3. Rides: Allow public read of published rides
DROP POLICY IF EXISTS "Published rides are viewable by everyone" ON public.rides;
CREATE POLICY "Published rides are viewable by everyone" 
ON public.rides FOR SELECT 
USING (status = 'published' AND departure_time > now() - interval '24 hours');

-- 4. Rides: Allow owners to manage their own rides
DROP POLICY IF EXISTS "Drivers can manage their own rides" ON public.rides;
CREATE POLICY "Drivers can manage their own rides" 
ON public.rides FOR ALL 
USING (auth.uid() = driver_user_id);

-- 5. Ride Requests: Visibility logic
-- A passenger should see their own requests.
-- A driver should see requests made for their rides.
DROP POLICY IF EXISTS "Ride requests visibility" ON public.ride_requests;
CREATE POLICY "Ride requests visibility" 
ON public.ride_requests FOR SELECT 
USING (
  auth.uid() = passenger_user_id 
  OR 
  EXISTS (
    SELECT 1 FROM public.rides 
    WHERE rides.id = ride_requests.ride_id 
    AND rides.driver_user_id = auth.uid()
  )
);

-- 6. Ride Requests: Insert policy
DROP POLICY IF EXISTS "Authenticated users can create ride requests" ON public.ride_requests;
CREATE POLICY "Authenticated users can create ride requests" 
ON public.ride_requests FOR INSERT 
WITH CHECK (auth.uid() = passenger_user_id);

-- 7. Ride Requests: Update policy (drivers can approve/deny, passengers can cancel)
DROP POLICY IF EXISTS "Users can update relevant ride requests" ON public.ride_requests;
CREATE POLICY "Users can update relevant ride requests" 
ON public.ride_requests FOR UPDATE 
USING (
  auth.uid() = passenger_user_id 
  OR 
  EXISTS (
    SELECT 1 FROM public.rides 
    WHERE rides.id = ride_requests.ride_id 
    AND rides.driver_user_id = auth.uid()
  )
);
