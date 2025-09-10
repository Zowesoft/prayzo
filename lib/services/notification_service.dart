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

  // Unread count stream to power badges in the UI
  static final StreamController<int> _unreadController =
      StreamController<int>.broadcast();
  static Stream<int> get unreadCountStream => _unreadController.stream;

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
      // If logged out, emit 0 and stop
      _unreadController.add(0);
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
          // Recalculate unread on new notification
          _emitUnreadCount();
        }
      },
    );
    ch.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'notifications',
      callback: (payload) {
        final newRow = Map<String, dynamic>.from(payload.newRecord);
        if (newRow['user_id']?.toString() == user.id) {
          _emitUnreadCount();
        }
      },
    );
    ch.subscribe();
    _channel = ch;

    // Emit initial unread count for current user
    _emitUnreadCount();
  }

  /// Mark a notification as read
  static Future<void> markAsRead(String notificationId) async {
    await _sb
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);
    // Update unread count after marking as read
    await _emitUnreadCount();
  }

  /// Mark all notifications as read for the current user
  static Future<void> markAllAsRead() async {
    final user = _sb.auth.currentUser;
    if (user == null) return;
    await _sb
        .from('notifications')
        .update({'read': true})
        .eq('user_id', user.id)
        .eq('read', false);
    await _emitUnreadCount();
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

  /// Send a notification from an organization to all of its followers.
  /// Assumes `profiles.is_org` marks org accounts and
  /// `organization_followers(org_id -> org, user_id -> user)`.
  static Future<int> sendToFollowersOfOrganization({
    required String orgId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Fetch follower user IDs
    final List<dynamic> followers = await _sb
        .from('organization_followers')
        .select('user_id')
        .eq('org_id', orgId);

    if (followers.isEmpty) return 0;

    // Prepare bulk insert payload
    final now = DateTime.now().toIso8601String();
    final payload = followers.map((e) {
      final uid = (e as Map)['user_id'].toString();
      return {
        'user_id': uid,
        'title': title,
        'body': body,
        'data': {
          'org_id': orgId,
          if (data != null) ...data,
        },
        'created_at': now,
      };
    }).toList();

    await _sb.from('notifications').insert(payload);
    return payload.length;
  }

  /// Compute and emit the unread count for the current user.
  static Future<void> _emitUnreadCount() async {
    final user = _sb.auth.currentUser;
    if (user == null) {
      _unreadController.add(0);
      return;
    }
    try {
      final List<dynamic> res = await _sb
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('read', false);
      _unreadController.add(res.length);
    } catch (_) {
      // Fail quietly; don't crash the app due to badge count issues
    }
  }
}
