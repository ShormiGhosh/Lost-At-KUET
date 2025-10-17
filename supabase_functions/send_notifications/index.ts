import type { serve } from 'std/server'
import { createClient } from '@supabase/supabase-js'

// This Edge Function expects SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, and FCM_SERVER_KEY to be set in environment.
// It receives a JSON body { post_id, user_id, title, description, location, status, latitude, longitude }

export default async (req: Request) => {
  try {
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')!

    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !FCM_SERVER_KEY) {
      return new Response(JSON.stringify({ error: 'Missing environment variables' }), { status: 500 })
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false }
    })

    const body = await req.json()
    const { post_id, user_id, title, description, location, status, latitude, longitude } = body

    // Query device tokens for all users except the poster
    const { data: tokens, error } = await supabase
      .from('device_tokens')
      .select('id, user_id, token')
      .neq('user_id', user_id)

    if (error) {
      console.error('Error fetching tokens:', error)
      return new Response(JSON.stringify({ error: 'Failed to fetch tokens' }), { status: 500 })
    }

    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ ok: true, message: 'No tokens to notify' }), { status: 200 })
    }

    // Prepare FCM payload
    const message = {
      notification: {
        title: status === 'Lost' ? `Lost: ${title}` : `Found: ${title}`,
        body: `${status} at ${location}`,
      },
      data: {
        post_id: String(post_id),
        status: String(status),
        latitude: latitude != null ? String(latitude) : '',
        longitude: longitude != null ? String(longitude) : '',
      }
    }

    // Batch send tokens with FCM
    const tokensList = tokens.map((t: any) => t.token).filter(Boolean)

    // Using FCM HTTP v1 requires OAuth token; here we call legacy FCM server API for simplicity
    const fcmUrl = 'https://fcm.googleapis.com/fcm/send'

    const bodyPayload: any = {
      registration_ids: tokensList,
      notification: message.notification,
      data: message.data,
      priority: 'high'
    }

    const fcmResp = await fetch(fcmUrl, {
      method: 'POST',
      headers: {
        'Authorization': `key=${FCM_SERVER_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(bodyPayload),
    })

    const fcmJson = await fcmResp.json()

    return new Response(JSON.stringify({ ok: true, fcm: fcmJson }), { status: 200 })
  } catch (err) {
    console.error('Edge function error', err)
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 })
  }
}
