# send_notifications Edge Function

Purpose
- Send push notifications to `device_tokens` when a post is created.
- If no FCM credentials are available, insert rows into `notifications` (in-app fallback) so the client can receive them.

Required environment variables (set in Supabase Functions -> Settings -> Environment Variables):
- SUPABASE_URL — your Supabase URL (e.g. `https://xyz.supabase.co`)
- SUPABASE_SERVICE_ROLE_KEY — Postgres service role key (used for PostgREST calls)

Optional (one of these for push delivery):
- FCM_SERVICE_ACCOUNT_JSON — full service account JSON string (preferred). Set the JSON as a single-line string (escape newlines or use the Dashboard secret editor).
- FCM_SERVER_KEY — legacy FCM server key (works with HTTP v1 fallback disabled)

Important notes
- This function is written for Supabase Edge (Deno). Do not attempt to import Node-only packages.
- For immediate testing you can use the `debug`, `test_first`, or `direct-send` helpers in the request body (see examples below). These are insecure and intended for quick verification only.

Test payloads

1) Debug mode — returns presence of secrets and token count (safe):

```json
{ "debug": true, "user_id": "<poster_user_uuid>" }
```

2) Quick end-to-end check using legacy key (sends one message to first token):

```json
{ "test_first": true, "user_id": "<poster_user_uuid>", "title": "Test", "description": "desc", "location": "X", "status": "Lost" }
```
- Requires `FCM_SERVER_KEY` (env) or pass `server_key` in body (insecure override).

3) Direct-send (bypass DB) — pass explicit tokens and a server key (debug only):

```json
{ "tokens": ["token1","token2"], "server_key": "AAA...", "title": "Test direct", "user_id": "<poster_user_uuid>" }
```

How to call from PowerShell (example using Supabase Functions Test URL):

Replace <FUNCTION_URL> with the function's invoke URL (from Supabase Dashboard):

```powershell
# Debug
Invoke-RestMethod -Uri '<FUNCTION_URL>' -Method POST -Body (ConvertTo-Json @{ debug = $true; user_id = '<poster_user_uuid>' }) -ContentType 'application/json'

# test_first (requires legacy key)
Invoke-RestMethod -Uri '<FUNCTION_URL>' -Method POST -Body (ConvertTo-Json @{ test_first = $true; user_id = '<poster_user_uuid>'; title = 'Hello'; description = 'desc'; location = 'here'; status = 'Lost' }) -ContentType 'application/json'
```

What to check after running
- If you used `debug`, the response shows `hasServiceAccount`, `hasLegacyKey`, and `tokenCount`.
- If `test_first` succeeded, the function returns the FCM response body.
- If no FCM credentials were available, the function will insert rows into `notifications`. Check the table with PostgREST or Supabase SQL:

```sql
select * from notifications where user_id = '<recipient_user_uuid>' order by created_at desc limit 10;
```

If something fails
- Paste the function Test response JSON and the function's logs (Supabase Dashboard -> Functions -> Logs) here and I'll parse them.

Security reminder
- The `server_key` override and passing raw `tokens` are insecure. Remove these shortcuts in production.
