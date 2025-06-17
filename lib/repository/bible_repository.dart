import 'package:sqflite/sqflite.dart';
import '../utils/database_helper.dart';

import '../models/bible_verse.dart';

class BibleRepository {
  final String translation;
  BibleRepository({this.translation = 'kjv'});

  Future<List<BibleVerse>> searchVerses(String where, List<dynamic> whereArgs) async {
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
}
