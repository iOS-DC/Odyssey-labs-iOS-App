-- Add vehicle columns to rides table for historical persistence
-- Run this in the Supabase SQL Editor

DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='rides' AND column_name='vehicle_model') THEN
        ALTER TABLE public.rides ADD COLUMN vehicle_model TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='rides' AND column_name='registration_plate') THEN
        ALTER TABLE public.rides ADD COLUMN registration_plate TEXT;
    END IF;
END $$;
