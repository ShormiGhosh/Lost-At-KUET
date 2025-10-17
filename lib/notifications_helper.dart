import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class NotificationsHelper {
  static final FirebaseMessaging _fm = FirebaseMessaging.instance;
  static bool _tokenRefreshRegistered = false;

  /// Initialize Firebase (call from app startup) and request permission
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      NotificationSettings settings = await _fm.requestPermission(alert: true, badge: true, sound: true);
      print('FCM permission: ${settings.authorizationStatus}');
    } catch (e) {
      print('Firebase init error: $e');
    }
  }

  /// Register device token with Supabase
  /// Register device token with Supabase. Returns the token when successful.
  static Future<String?> registerDeviceToken(SupabaseClient supabase) async {
    try {
      final token = await _fm.getToken();
      print('NotificationsHelper: FCM token obtained: $token');
      if (token == null) return null;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        print('NotificationsHelper: no authenticated user - cannot register token');
        return token;
      }

      // Upsert token for user
      // Store token per-device. DB should have a UNIQUE constraint on token.
      final resp = await supabase.from('device_tokens').upsert({
        'token': token,
        'user_id': userId,
        'platform': defaultTargetPlatform.toString(),
      });
      print('NotificationsHelper: upsert response: $resp');

      // Listen for token refreshes and attempt to update server-side copy as well
      if (!_tokenRefreshRegistered) {
        _tokenRefreshRegistered = true;
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          try {
            print('NotificationsHelper: token refreshed: $newToken');
            final currentUserId = supabase.auth.currentUser?.id ?? userId;
            if (newToken.isNotEmpty) {
              await supabase.from('device_tokens').upsert({
                'token': newToken,
                'user_id': currentUserId,
                'platform': defaultTargetPlatform.toString(),
              });
            }
          } catch (e) {
            print('NotificationsHelper: failed to upsert refreshed token: $e');
          }
        });
      }

      return token;
    } catch (e) {
      print('NotificationsHelper: Failed to register device token: $e');
      return null;
    }
  }

  /// Remove the current device token from the server. Call on logout/uninstall (best-effort).
  static Future<void> removeCurrentDeviceToken(SupabaseClient supabase) async {
    try {
      final token = await _fm.getToken();
      if (token == null) return;
      print('NotificationsHelper: removing token on logout: $token');
      await supabase.from('device_tokens').delete().eq('token', token);
    } catch (e) {
      print('NotificationsHelper: Failed to remove device token: $e');
    }
  }
}
