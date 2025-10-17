-- 008a-insert-dummy-notifications-first-n-users.sql
-- Inserts dummy notifications for the first N users (ordered by created_at) in `auth.users`.
-- Good when you don't want to look up specific UUIDs.

-- CONFIG: change N below to the number of users you want to seed.
\set N 5

BEGIN;

WITH selected_users AS (
  SELECT id FROM auth.users ORDER BY created_at ASC LIMIT :N
)
INSERT INTO notifications (user_id, title, body, data, is_read)
SELECT id,
       'Classroom check',
       'This is a seeded notification to verify notifications are visible to users.',
       jsonb_build_object('type','system','seeded', true),
       false
FROM selected_users;

COMMIT;

-- Notes:
-- - Supabase SQL editor supports psql-style \set variables. If that doesn't work in the SQL editor, replace :N with a literal number.
-- - You can change ORDER BY to suit selection criteria (e.g., ORDER BY last_sign_in_at DESC to target active users).
-- - If your database enforces a foreign key to auth.users, this will succeed only if auth.users has at least N users.
