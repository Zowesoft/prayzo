import 'dart:async';

import 'package:prayoo/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// NotificationService provides in-app notifications using Supabase Realtime.
///
/// Expected schema for table `notifications`:
/// - id: uuid (primary key)
/// - user_id: uuid (recipient user id)
/// - title: text
/// - body: text
/// - data: jsonb (optional)
/// - read: bool (default false)
/// - created_at: timestamptz (default now())
class NotificationService {
  static final SupabaseClient _sb = SupabaseService.client;

  static final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of new notifications for the current user.
  static Stream<Map<String, dynamic>> get notificationsStream => _controller.stream;

  static RealtimeChannel? _channel;

  /// Initialize realtime listener. Safe to call multiple times; it will resubscribe
  /// when the authenticated user changes.
  static Future<void> initialize() async {
    // Subscribe immediately for current user (if any), and resubscribe on auth changes
    await _subscribeForCurrentUser();
    _sb.auth.onAuthStateChange.listen((event) async {
      await _subscribeForCurrentUser();
    });
  }

  static Future<void> _subscribeForCurrentUser() async {
    final user = _sb.auth.currentUser;

    // Unsubscribe previous channel if any
    if (_channel != null) {
      try {
        await _channel!.unsubscribe();
      } catch (_) {}
      _channel = null;
    }

    if (user == null) {
      return;
    }

    // Create a channel and listen for inserts on notifications table
    final ch = _sb.channel('public:notifications:user:${user.id}');
    ch.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      callback: (payload) {
        final newRow = Map<String, dynamic>.from(payload.newRecord);
        if (newRow['user_id']?.toString() == user.id) {
          _controller.add(newRow);
        }
      },
    );
    ch.subscribe();
    _channel = ch;
  }

  /// Mark a notification as read
  static Future<void> markAsRead(String notificationId) async {
    await _sb
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);
  }

  /// Helper to send a test notification to a user. Useful during development.
  static Future<void> sendTest({
    required String toUserId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _sb.from('notifications').insert({
      'user_id': toUserId,
      'title': title,
      'body': body,
      if (data != null) 'data': data,
    });
  }
}
