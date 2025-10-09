-- Migration: add read_at to messages
BEGIN;

ALTER TABLE IF EXISTS public.messages
  ADD COLUMN IF NOT EXISTS read_at timestamptz;

COMMIT;
