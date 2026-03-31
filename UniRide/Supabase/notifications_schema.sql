-- Notification tables policies for UniRide
-- Run this in Supabase SQL Editor

ALTER TABLE public.push_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_notifications ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'app_notifications'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.app_notifications;
    END IF;
END $$;

DROP POLICY IF EXISTS "Users can manage own push tokens" ON public.push_tokens;
CREATE POLICY "Users can manage own push tokens"
ON public.push_tokens
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own app notifications" ON public.app_notifications;
CREATE POLICY "Users can view own app notifications"
ON public.app_notifications
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Authenticated users can insert app notifications" ON public.app_notifications;
CREATE POLICY "Authenticated users can insert app notifications"
ON public.app_notifications
FOR INSERT
WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can mark own app notifications" ON public.app_notifications;
CREATE POLICY "Users can mark own app notifications"
ON public.app_notifications
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
