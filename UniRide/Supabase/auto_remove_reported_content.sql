-- Migration: Add report_count and auto-removal trigger
-- This script adds a report_count column and a trigger to handle auto-removal.

-- 1. Add report_count columns
ALTER TABLE public.community_posts 
ADD COLUMN IF NOT EXISTS report_count INTEGER NOT NULL DEFAULT 0;

ALTER TABLE public.community_comments 
ADD COLUMN IF NOT EXISTS report_count INTEGER NOT NULL DEFAULT 0;

-- 2. Create the trigger function
CREATE OR REPLACE FUNCTION public.handle_report_auto_removal()
RETURNS TRIGGER AS $$
BEGIN
    -- Only handle 'post' and 'comment' types
    IF NEW.content_type = 'post' THEN
        -- Update report_count in community_posts
        UPDATE public.community_posts
        SET report_count = report_count + 1
        WHERE id = NEW.content_id;
        
        -- Check threshold and delete if reached
        DELETE FROM public.community_posts
        WHERE id = NEW.content_id AND report_count >= 5;
        
    ELSIF NEW.content_type = 'comment' THEN
        -- Update report_count in community_comments
        UPDATE public.community_comments
        SET report_count = report_count + 1
        WHERE id = NEW.content_id;
        
        -- Check threshold and delete if reached
        DELETE FROM public.community_comments
        WHERE id = NEW.content_id AND report_count >= 5;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create the trigger on public.reports
DROP TRIGGER IF EXISTS on_report_inserted ON public.reports;
CREATE TRIGGER on_report_inserted
AFTER INSERT ON public.reports
FOR EACH ROW
EXECUTE FUNCTION public.handle_report_auto_removal();
