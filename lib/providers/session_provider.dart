import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prayoo/services/supabase_service.dart';

class SessionProvider with ChangeNotifier {
  final SupabaseClient _sb = SupabaseService.client;

  List<PrayerSession> _upcomingSessions = [];
  PrayerSession? _currentLiveSession;
  final List<String> _prayerPoints = [];
  final int _currentPrayerPointIndex = 0;

  List<PrayerSession> get upcomingSessions => _upcomingSessions;
  PrayerSession? get currentLiveSession => _currentLiveSession;
  List<String> get prayerPoints => _prayerPoints;
  int get currentPrayerPointIndex => _currentPrayerPointIndex;

  SessionProvider() {
    _loadUpcomingSessions();
    _listenToLiveSessions();
  }

  Future<void> refresh() async {
    await _loadUpcomingSessions();
  }

  Future<void> _loadUpcomingSessions() async {
    try {
      final nowIso = DateTime.now().toIso8601String();
      final res = await _sb
          .from('prayer_sessions')
          .select()
          .eq('status', 'scheduled')
          .gte('scheduled_time', nowIso)
          .order('scheduled_time', ascending: true)
          .limit(10);

      if (res is List) {
        _upcomingSessions = res
            .map(
                (e) => PrayerSession.fromSupabaseMap(e as Map<String, dynamic>))
            .toList();
      } else {
        _upcomingSessions = [];
      }

      notifyListeners();
    } catch (e) {
      print('Error loading upcoming sessions: $e');
    }
  }

  void _listenToLiveSessions() {
    // Supabase realtime subscription for live sessions (Supabase Flutter v2 API)
    final channel = _sb.channel('public:prayer_sessions');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'prayer_sessions',
      callback: (payload) {
        final newRow = payload.newRecord;
        if (newRow['status'] == 'live') {
          _currentLiveSession =
              PrayerSession.fromSupabaseMap(Map<String, dynamic>.from(newRow));
          notifyListeners();
        }
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'prayer_sessions',
      callback: (payload) {
        final map = Map<String, dynamic>.from(payload.newRecord);
        if (map['status'] == 'live') {
          _currentLiveSession = PrayerSession.fromSupabaseMap(map);
        } else if (_currentLiveSession?.id == map['id']) {
          _currentLiveSession = null;
        }
        notifyListeners();
      },
    );

    channel.subscribe();
  }

  Future<void> createPrayerSession({
    required String title,
    required String description,
    required DateTime scheduledTime,
    required List<String> prayerPoints,
    List<List<String>> prayerPointScriptures = const [],
  }) async {
    try {
      final userId = SupabaseService.client.auth.currentUser!.id;
      final insert = await _sb
          .from('prayer_sessions')
          .insert({
            'title': title,
            'description': description,
            'organizer_id': userId,
            'organizer_name': null,
            'scheduled_time': scheduledTime.toIso8601String(),
            'status': 'scheduled',
          })
          .select()
          .single();

      final sessionId = insert['id'] as String;

      // Insert prayer points
      final pointsPayload = prayerPoints
          .asMap()
          .entries
          .map((entry) => {
                'session_id': sessionId,
                'content': entry.value,
                'order': entry.key,
                'is_active': false,
                'scriptures': (entry.key < prayerPointScriptures.length)
                    ? prayerPointScriptures[entry.key]
                    : <String>[],
              })
          .toList();
      if (pointsPayload.isNotEmpty) {
        await _sb.from('prayer_points').insert(pointsPayload);
      }

      await _loadUpcomingSessions();
    } catch (e) {
      print('Error creating prayer session: $e');
      rethrow;
    }
  }

  Future<void> joinSession(String sessionId) async {
    try {
      final userId = SupabaseService.client.auth.currentUser!.id;
      await _sb.from('participants').upsert({
        'session_id': sessionId,
        'user_id': userId,
        'role': 'participant',
        'can_speak': false,
      });
    } catch (e) {
      print('Error joining session: $e');
      rethrow;
    }
  }
}

// Data Models
class PrayerSession {
  final String id;
  final String title;
  final String description;
  final String organizerId;
  final String organizerName;
  final DateTime scheduledTime;
  final String status;
  final List<PrayerPoint> prayerPoints;
  final Map<String, Participant> participants;
  final String? currentPrayerPoint;
  final List<String> scriptures;

  PrayerSession({
    required this.id,
    required this.title,
    required this.description,
    required this.organizerId,
    required this.organizerName,
    required this.scheduledTime,
    required this.status,
    required this.prayerPoints,
    required this.participants,
    this.currentPrayerPoint,
    this.scriptures = const [],
  });

  factory PrayerSession.fromSupabaseMap(Map<String, dynamic> data) {
    return PrayerSession(
      id: data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      organizerId: data['organizer_id']?.toString() ?? '',
      organizerName: data['organizer_name']?.toString() ?? '',
      scheduledTime:
          DateTime.tryParse(data['scheduled_time']?.toString() ?? '') ??
              DateTime.now(),
      status: data['status']?.toString() ?? 'scheduled',
      // We lazily load points/participants when needed; keep empty here for list views.
      prayerPoints: const [],
      participants: const {},
      currentPrayerPoint: data['current_prayer_point']?.toString(),
      scriptures: (data['scriptures'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  factory PrayerSession.fromLocalStorage(Map<String, dynamic> data) {
    return PrayerSession(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      scheduledTime: data['scheduledTime'] is int
          ? DateTime.fromMillisecondsSinceEpoch(data['scheduledTime'])
          : DateTime.tryParse(data['scheduledTime']?.toString() ?? '') ??
              DateTime.now(),
      status: data['status'] ?? 'scheduled',
      prayerPoints: (data['prayerPoints'] as List<dynamic>?)
              ?.map(
                  (point) => PrayerPoint.fromMap(point as Map<String, dynamic>))
              .toList() ??
          [],
      participants: Map<String, Participant>.from(
        (data['participants'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(
                  key, Participant.fromMap(value as Map<String, dynamic>)),
            ) ??
            {},
      ),
      currentPrayerPoint: data['currentPrayerPoint'],
      scriptures: (data['scriptures'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  int get participantCount => participants.length;

  String getFormattedTime() {
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);

    if (difference.inDays > 0) {
      return 'In ${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours} hours';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes} minutes';
    } else {
      return 'Starting now';
    }
  }
}

class PrayerPoint {
  final String id;
  final String content;
  final int order;
  final String? assignedTo;
  final bool isActive;

  PrayerPoint({
    required this.id,
    required this.content,
    required this.order,
    this.assignedTo,
    required this.isActive,
  });

  factory PrayerPoint.fromMap(Map<String, dynamic> map) {
    return PrayerPoint(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      order: map['order'] ?? 0,
      assignedTo: map['assignedTo'],
      isActive: map['isActive'] ?? false,
    );
  }
}

class Participant {
  final String role;
  final DateTime joinedAt;
  final bool canSpeak;

  Participant({
    required this.role,
    required this.joinedAt,
    required this.canSpeak,
  });

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      role: map['role']?.toString() ?? 'participant',
      joinedAt: DateTime.tryParse(map['joined_at']?.toString() ?? '') ??
          DateTime.now(),
      canSpeak: (map['can_speak'] as bool?) ?? false,
    );
  }
}
