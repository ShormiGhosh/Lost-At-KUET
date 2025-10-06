-- Migration: create notifications table
-- Run this in Supabase SQL editor or via your DB migration workflow.

BEGIN;

CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text REFERENCES public.profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  body text,
  read boolean NOT NULL DEFAULT false,
  meta jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Optional: enable RLS and allow users to manage their own notifications
-- Uncomment if you use RLS on the table
-- ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
-- DROP POLICY IF EXISTS "Notifications: allow user access" ON public.notifications;
-- CREATE POLICY "Notifications: allow user access" ON public.notifications
--   FOR ALL
--   USING (auth.uid() = user_id)
--   WITH CHECK (auth.uid() = user_id);

COMMIT;
