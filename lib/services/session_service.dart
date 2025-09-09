import 'dart:async';

import 'package:prayoo/providers/session_provider.dart';
import 'package:prayoo/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionService {
  final _sb = SupabaseService.client;

  // Stream a single session by id using Supabase Realtime and an initial fetch
  Stream<PrayerSession> listenToSession(String sessionId) async* {
    // Initial fetch
    final initial = await _sb
        .from('prayer_sessions')
        .select()
        .eq('id', sessionId)
        .single();
    yield PrayerSession.fromSupabaseMap(Map<String, dynamic>.from(initial));

    // Realtime updates
    final controller = StreamController<PrayerSession>();
    final channel = _sb.channel('public:prayer_sessions:session_$sessionId');

    channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'prayer_sessions',
        callback: (payload) {
          final map = Map<String, dynamic>.from(payload.newRecord);
          if (map['id']?.toString() == sessionId) {
            controller.add(PrayerSession.fromSupabaseMap(map));
          }
        });

    channel.subscribe();
    yield* controller.stream;
  }

  Future<void> updatePrayerPoint(String sessionId, int pointIndex) async {
    // Deactivate all points for this session
    await _sb
        .from('prayer_points')
        .update({'is_active': false})
        .eq('session_id', sessionId);

    // Activate the selected point by order
    await _sb
        .from('prayer_points')
        .update({'is_active': true})
        .match({'session_id': sessionId, 'order': pointIndex});

    // Optionally track index on session
    await _sb
        .from('prayer_sessions')
        .update({'current_prayer_point_index': pointIndex})
        .eq('id', sessionId);
  }

  Future<void> assignSpeaker(String sessionId, String userId, String pointId) async {
    // Update point assignment
    await _sb
        .from('prayer_points')
        .update({'assigned_to': userId})
        .eq('id', pointId);

    // Ensure participant can speak
    await _sb.from('participants').upsert({
      'session_id': sessionId,
      'user_id': userId,
      'can_speak': true,
    });

    // Mark current speaker on session
    await _sb
        .from('prayer_sessions')
        .update({'current_speaker': userId})
        .eq('id', sessionId);
  }

  Future<void> enableGroupSpeaking(String sessionId, bool enable) async {
    await _sb
        .from('prayer_sessions')
        .update({'allow_group_speaking': enable})
        .eq('id', sessionId);
  }

  Future<void> sendSessionMessage(String sessionId, String message, String type) async {
    final user = _sb.auth.currentUser;
    await _sb.from('session_messages').insert({
      'session_id': sessionId,
      'sender_id': user?.id,
      'sender_name': user?.userMetadata?['full_name'] ?? user?.email ?? 'Anonymous',
      'content': message,
      'type': type,
    });
  }

  // Messages stream for a session (latest first)
  Stream<List<Map<String, dynamic>>> streamMessages(String sessionId) async* {
    // initial load
    final initial = await _sb
        .from('session_messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: false);
    yield List<Map<String, dynamic>>.from(initial.map((e) => Map<String, dynamic>.from(e)));

    // realtime
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    final channel = _sb.channel('public:session_messages:$sessionId');
    channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'session_messages',
        callback: (payload) async {
          final newRow = Map<String, dynamic>.from(payload.newRecord);
          if (newRow['session_id']?.toString() != sessionId) return;
          // fetch latest snapshot to keep order simple
          final rows = await _sb
              .from('session_messages')
              .select()
              .eq('session_id', sessionId)
              .order('created_at', ascending: false);
          controller.add(List<Map<String, dynamic>>.from(rows.map((e) => Map<String, dynamic>.from(e))));
        });
    channel.subscribe();
    yield* controller.stream;
  }
}
