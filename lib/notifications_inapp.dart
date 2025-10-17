import 'package:supabase_flutter/supabase_flutter.dart';

/// Lightweight helper to fetch and stream in-app notifications inserted by the
/// `send_notifications` Edge Function fallback.
///
/// Usage:
/// final svc = NotificationsInApp(Supabase.instance.client);
/// svc.streamForUser(userId).listen((rows) { /* show local notification or update UI */ });
///
class NotificationsInApp {
  final SupabaseClient supabase;
  NotificationsInApp(this.supabase);

  /// Fetch recent notifications for a user
  Future<List<Map<String, dynamic>>> fetchRecent(String userId, {int limit = 50}) async {
    final resp = await supabase
        .from('notifications')
        .select('id,user_id,title,body,data,is_read,created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    // The project uses the client style that returns data directly (or throws),
    // so cast to a list and return typed maps.
    final List<dynamic> data = resp as List<dynamic>? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Mark notification as read
  Future<void> markRead(String id) async {
    await supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }

  /// Stream realtime inserts for the current user. Use this to trigger local
  /// UI updates or local notifications.
  ///
  /// Example:
  /// svc.streamForUser(userId).listen((rows) { /* show */ });
  Stream<List<Map<String, dynamic>>> streamForUser(String userId) {
    // The Supabase Flutter client exposes a `.from(...).stream()` API which
    // yields row arrays. We use the primary key `['id']` here.
    return supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) {
      final list = (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return list;
    });
  }
}
