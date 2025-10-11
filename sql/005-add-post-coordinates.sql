-- Migration: add latitude and longitude to posts
-- Run this in Supabase SQL editor or via psql

BEGIN;

ALTER TABLE IF EXISTS public.posts
  ADD COLUMN IF NOT EXISTS latitude double precision,
  ADD COLUMN IF NOT EXISTS longitude double precision;

COMMIT;
