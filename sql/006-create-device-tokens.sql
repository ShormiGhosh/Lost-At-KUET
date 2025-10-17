-- 006-create-device-tokens.sql
-- Create a table to store device tokens for FCM delivery.
-- Run this in the Supabase SQL editor or via psql against your project DB.

-- Requirements: the project should have the "pgcrypto" or "uuid-ossp" extension available
-- Supabase projects typically support gen_random_uuid() via pgcrypto.

CREATE TABLE IF NOT EXISTS public.device_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  token text NOT NULL,
  platform text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Ensure we don't store duplicates for the same token
CREATE UNIQUE INDEX IF NOT EXISTS device_tokens_token_idx ON public.device_tokens (token);

-- Optional index to find tokens by user quickly
CREATE INDEX IF NOT EXISTS device_tokens_user_id_idx ON public.device_tokens (user_id);

-- Trigger to keep updated_at current
CREATE OR REPLACE FUNCTION public.trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS device_tokens_set_timestamp ON public.device_tokens;
CREATE TRIGGER device_tokens_set_timestamp
BEFORE UPDATE ON public.device_tokens
FOR EACH ROW
EXECUTE PROCEDURE public.trigger_set_timestamp();
