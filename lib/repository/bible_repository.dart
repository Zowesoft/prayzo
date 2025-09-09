import '../utils/database_helper.dart';

import '../models/bible_verse.dart';

class BibleRepository {
  final String translation;
  BibleRepository({this.translation = 'kjv'});

  Future<List<String>> getBooks() async {
    final db = await DatabaseHelper.getDatabase(translation: translation);
    final List<Map<String, dynamic>> results = await db.rawQuery(
        'SELECT book FROM verses GROUP BY book ORDER BY MIN(chapter) ASC, MIN(verse) ASC');
    return results.map((row) => row['book'].toString()).toList();
  }

  Future<List<BibleVerse>> searchVerses(
      String where, List<dynamic> whereArgs) async {
    final db = await DatabaseHelper.getDatabase(translation: translation);
    final List<Map<String, dynamic>> results = await db.query(
      'verses',
      where: where,
      whereArgs: whereArgs,
      limit: 50,
    );
    return results.map((e) => BibleVerse.fromMap(e)).toList();
  }

  Future<BibleVerse?> getVerseOfTheDay() async {
    final db = await DatabaseHelper.getDatabase(translation: translation);
    final List<Map<String, dynamic>> results =
        await db.rawQuery('SELECT * FROM verses ORDER BY RANDOM() LIMIT 1');
    if (results.isEmpty) return null;
    return BibleVerse.fromMap(results.first);
  }

  Future<List<BibleVerse>> getSuggestedReading({int count = 5}) async {
    final db = await DatabaseHelper.getDatabase(translation: translation);
    final List<Map<String, dynamic>> results = await db
        .rawQuery('SELECT * FROM verses ORDER BY RANDOM() LIMIT ?', [count]);
    return results.map((e) => BibleVerse.fromMap(e)).toList();
  }

  // ====== New helper queries ======
  Future<List<int>> getBookIds() async {
    final db = await DatabaseHelper.getDatabase(translation: translation);
    final results = await db.rawQuery(
        'SELECT book FROM verses GROUP BY book ORDER BY MIN(chapter)');
    return results.map((row) => row['book'] as int).toList();
  }

  Future<List<int>> getChaptersForBook(int bookId) async {
    final db = await DatabaseHelper.getDatabase(translation: translation);
    final results = await db.rawQuery(
        'SELECT chapter FROM verses WHERE book = ? GROUP BY chapter ORDER BY chapter',
        [bookId]);
    return results.map((row) => row['chapter'] as int).toList();
  }

  Future<List<int>> getVersesForBookChapter(int bookId, int chapter) async {
    final db = await DatabaseHelper.getDatabase(translation: translation);
    final results = await db.rawQuery(
        'SELECT verse FROM verses WHERE book = ? AND chapter = ? ORDER BY verse',
        [bookId, chapter]);
    return results.map((row) => row['verse'] as int).toList();
  }
}

