-- Ride lifecycle polish fields
-- Run this in the Supabase SQL Editor if you want audit-grade lifecycle timestamps.
-- The current app works without these columns because it already stores status,
-- reviewed_at, and created_at. These fields make the lifecycle easier to debug,
-- analyze, and display like a mature ride-hailing app.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'rides' AND column_name = 'started_at'
    ) THEN
        ALTER TABLE public.rides ADD COLUMN started_at timestamptz;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'rides' AND column_name = 'completed_at'
    ) THEN
        ALTER TABLE public.rides ADD COLUMN completed_at timestamptz;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'rides' AND column_name = 'cancelled_at'
    ) THEN
        ALTER TABLE public.rides ADD COLUMN cancelled_at timestamptz;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'rides' AND column_name = 'cancellation_reason'
    ) THEN
        ALTER TABLE public.rides ADD COLUMN cancellation_reason text;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'ride_requests' AND column_name = 'cancelled_at'
    ) THEN
        ALTER TABLE public.ride_requests ADD COLUMN cancelled_at timestamptz;
    END IF;

    IF NOT EXISTS (Ω
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'ride_requests' AND column_name = 'cancellation_reason'
    ) THEN
        ALTER TABLE public.ride_requests ADD COLUMN cancellation_reason text;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'cancelled_at'
    ) THEN
        ALTER TABLE public.bookings ADD COLUMN cancelled_at timestamptz;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'cancellation_reason'
    ) THEN
        ALTER TABLE public.bookings ADD COLUMN cancellation_reason text;
    END IF;
END $$;

-- Optional: if you use fix_rls_policies.sql, make sure public ride discovery
-- includes ongoing rides where appropriate. The main schema already allows
-- authenticated users to read rides; this policy is only for the stricter file.
DROP POLICY IF EXISTS "Published rides are viewable by everyone" ON public.rides;
CREATE POLICY "Published rides are viewable by everyone"
ON public.rides FOR SELECT
USING (
  status IN ('published', 'ongoing')
  AND departure_time > now() - interval '24 hours'
);
