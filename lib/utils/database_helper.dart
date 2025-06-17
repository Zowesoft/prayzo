import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _db;
  static String? _currentTranslation;

  static Future<Database> getDatabase({String translation = 'kjv'}) async {
    if (_db != null && _currentTranslation == translation) return _db!;
    _db = await _initDb(translation);
    _currentTranslation = translation;
    return _db!;
  }

  static Future<Database> _initDb(String translation) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String dbPath = join(documentsDirectory.path, '$translation.sqlite');
    // Copy from assets if not exists
    if (!await File(dbPath).exists()) {
      ByteData data = await rootBundle.load('assets/bibles/$translation.sqlite');
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(dbPath).writeAsBytes(bytes, flush: true);
    }
    return await openDatabase(dbPath, readOnly: true);
  }
}
