-- Migration: add avatar_url and phone to profiles
-- Run this in Supabase SQL editor (SQL) or via psql connected to your project.

BEGIN;

ALTER TABLE IF EXISTS public.profiles
  ADD COLUMN IF NOT EXISTS avatar_url text,
  ADD COLUMN IF NOT EXISTS phone text;

-- Optional: ensure RLS and policy allow users to manage their own profile
-- Uncomment the following if you use RLS and want to enable this policy.
-- ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY IF NOT EXISTS "Profiles: allow user to upsert own row"
--   ON public.profiles
--   FOR ALL
--   USING (auth.uid() = id)
--   WITH CHECK (auth.uid() = id);

COMMIT;
