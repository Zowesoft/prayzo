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
  }) async {
    final user = _sb.auth.currentUser;
    if (user == null) {
      // Save locally for anonymous users
      await _local.saveUserPrayer(title, content);
      return;
    }

    await _sb.from('prayers').insert({
      'title': title,
      'content': content,
      'scriptures': scriptures,
      'tags': tags,
      'is_private': isPrivate,
      'author_id': user.id,
      'likes_count': 0,
      'comments_count': 0,
    });
  }
}
