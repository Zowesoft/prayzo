import '../screens/bible_reference_selector.dart';

// Get book name by ID using the centralized bibleBookNames map
String getBookNameById(int bookId) {
  return bibleBookNames[bookId] ?? 'Unknown Book';
}

// Get book ID by name (case-insensitive)
int? getBookIdByName(String bookName) {
  if (bookName.isEmpty) return null;
  
  final normalized = bookName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  
  // First try exact match
  for (final entry in bibleBookNames.entries) {
    if (entry.value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') == normalized) {
      return entry.key;
    }
  }
  
  // Then try partial match (e.g., 'Gen' for 'Genesis')
  for (final entry in bibleBookNames.entries) {
    final entryName = entry.value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (entryName.startsWith(normalized) || normalized.startsWith(entryName)) {
      return entry.key;
    }
  }
  
  return null;
}

class BibleVerse {
  final String book;
  final int chapter;
  final int verse;
  final String text;

  BibleVerse({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  factory BibleVerse.fromMap(Map<String, dynamic> map) {
    return BibleVerse(
      book: map['book'] is int
          ? getBookNameById(map['book'])
          : map['book'].toString(),
      chapter: map['chapter'] is int ? map['chapter'] : int.tryParse(map['chapter'].toString()) ?? 0,
      verse: map['verse'] is int ? map['verse'] : int.tryParse(map['verse'].toString()) ?? 0,
      text: map['text']?.toString() ?? '',
    );
  }

  String get reference => '$book $chapter:$verse';
}
