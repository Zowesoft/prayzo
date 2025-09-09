import 'dart:convert';
import 'package:prayoo/providers/session_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalStorageService {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'prayer_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE downloaded_sessions(
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        organizer_name TEXT,
        prayer_points TEXT,
        downloaded_at INTEGER,
        file_path TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE user_prayers(
        id TEXT PRIMARY KEY,
        title TEXT,
        content TEXT,
        created_at INTEGER,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }
  
  Future<void> saveDownloadedSession(PrayerSession session, String filePath) async {
    final db = await database;
    await db.insert(
      'downloaded_sessions',
      {
        'id': session.id,
        'title': session.title,
        'description': session.description,
        'organizer_name': session.organizerName,
        'prayer_points': jsonEncode(session.prayerPoints),
        'downloaded_at': DateTime.now().millisecondsSinceEpoch,
        'file_path': filePath,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<List<PrayerSession>> getDownloadedSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('downloaded_sessions');
    
    return List.generate(maps.length, (i) {
      return PrayerSession.fromLocalStorage(maps[i]);
    });
  }
  
  Future<void> saveUserPrayer(String title, String content) async {
    final db = await database;
    await db.insert('user_prayers', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'content': content,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'is_synced': 0,
    });
  }
  
  Future<List<Map<String, dynamic>>> getUserPrayers() async {
    final db = await database;
    return await db.query('user_prayers', orderBy: 'created_at DESC');
  }
}