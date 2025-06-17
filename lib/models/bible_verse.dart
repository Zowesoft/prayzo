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
      book: map['book'],
      chapter: map['chapter'],
      verse: map['verse'],
      text: map['text'],
    );
  }

  String get reference => '$book $chapter:$verse';
}
