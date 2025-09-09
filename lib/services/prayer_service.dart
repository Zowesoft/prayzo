import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prayoo/services/local_storage_service.dart';
import 'package:prayoo/services/supabase_service.dart';

class PrayerService {
  final SupabaseClient _sb = SupabaseService.client;
  final LocalStorageService _local = LocalStorageService();

  Future<void> createPrayer({
    required String title,
    required String content,
    List<String> scriptures = const [],
    List<String> tags = const [],
    bool isPrivate = false,
    List<String> prayerPoints = const [],
    List<List<String>> prayerPointScriptures = const [],
    List<dynamic> prayerPointDeltas = const [],
  }) async {
    final user = _sb.auth.currentUser;
    if (user == null) {
      // Save locally for anonymous users
      await _local.saveUserPrayerWithPoints(
        title: title,
        content: content,
        prayerPoints: prayerPoints,
        prayerPointScriptures: prayerPointScriptures,
        prayerPointDeltas: prayerPointDeltas,
      );
      return;
    }

    final prayer = await _sb
        .from('prayers')
        .insert({
          'title': title,
          'content': content,
          'scriptures': scriptures,
          'tags': tags,
          'is_private': isPrivate,
          'author_id': user.id,
          'likes_count': 0,
          'comments_count': 0,
        })
        .select()
        .single();

    final prayerId = prayer['id'];

    if (prayerPoints.isNotEmpty) {
      final pointsPayload = prayerPoints
          .asMap()
          .entries
          .map((entry) => {
                'prayer_id': prayerId,
                'content': entry.value,
                'order': entry.key,
                'scriptures': (entry.key < prayerPointScriptures.length)
                    ? prayerPointScriptures[entry.key]
                    : <String>[],
                'content_delta': (entry.key < prayerPointDeltas.length)
                    ? prayerPointDeltas[entry.key]
                    : null,
              })
          .toList();

      await _sb.from('prayer_points').insert(pointsPayload);
    }
  }
}
