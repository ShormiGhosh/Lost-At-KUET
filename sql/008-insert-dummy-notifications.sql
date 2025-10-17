-- 008-insert-dummy-notifications.sql
-- Inserts some dummy notifications into the `notifications` table so that a teacher
-- or reviewer can confirm the in-app notifications feature is working.
-- Adjust the user_id values to match real auth.users UUIDs in your project.

-- Replace these example UUIDs with real user IDs from your `auth.users` table.
-- You can find user IDs in Supabase Auth -> Users in the dashboard.

BEGIN;

INSERT INTO notifications (user_id, title, body, data, is_read)
VALUES
  ('00000000-0000-0000-0000-000000000001', 'Welcome to LostAtKUET', 'This is a dummy notification to verify in-app notifications are working.', '{"type":"system","priority":"low"}'::jsonb, false),
  ('00000000-0000-0000-0000-000000000002', 'New message', 'You have a new message from a student. Tap to view.', '{"type":"message","conversation_id":"conv-123"}'::jsonb, false),
  ('00000000-0000-0000-0000-000000000003', 'Lost item reported', 'A lost item near the library was posted. Check it out.', '{"type":"post","post_id": 987}'::jsonb, false),
  ('00000000-0000-0000-0000-000000000004', 'Reminder', 'Don\'t forget to confirm your contact details in profile settings.', '{"type":"reminder"}'::jsonb, false);

COMMIT;

-- Notes:
-- - If you want to insert notifications for specific existing users, replace the UUIDs above with the real ones.
-- - To insert X notifications for the first N users automatically, run a SELECT to pull user ids and then use that result to INSERT (I can provide that variant if you want).
-- - Run this file in the Supabase SQL editor or via psql/psm if you have direct DB access.
