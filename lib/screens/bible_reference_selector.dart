import 'package:flutter/material.dart';
import '../repository/bible_repository.dart';
import '../models/bible_verse.dart';
import '../utils/colors.dart';

export '../models/bible_verse.dart' show getBookNameById, getBookIdByName;

// Export the bibleBookNames constant
export 'bible_reference_selector.dart' show bibleBookNames;

/// Map of numeric Bible book ids (as stored in DB) to readable names.
/// NOTE: ensure these ids match the DB schema.
const Map<int, String> bibleBookNames = {
  1: 'Genesis',
  2: 'Exodus',
  3: 'Leviticus',
  4: 'Numbers',
  5: 'Deuteronomy',
  6: 'Joshua',
  7: 'Judges',
  8: 'Ruth',
  9: '1 Samuel',
  10: '2 Samuel',
  11: '1 Kings',
  12: '2 Kings',
  13: '1 Chronicles',
  14: '2 Chronicles',
  15: 'Ezra',
  16: 'Nehemiah',
  17: 'Esther',
  18: 'Job',
  19: 'Psalms',
  20: 'Proverbs',
  21: 'Ecclesiastes',
  22: 'Song of Solomon',
  23: 'Isaiah',
  24: 'Jeremiah',
  25: 'Lamentations',
  26: 'Ezekiel',
  27: 'Daniel',
  28: 'Hosea',
  29: 'Joel',
  30: 'Amos',
  31: 'Obadiah',
  32: 'Jonah',
  33: 'Micah',
  34: 'Nahum',
  35: 'Habakkuk',
  36: 'Zephaniah',
  37: 'Haggai',
  38: 'Zechariah',
  39: 'Malachi',
  40: 'Matthew',
  41: 'Mark',
  42: 'Luke',
  43: 'John',
  44: 'Acts',
  45: 'Romans',
  46: '1 Corinthians',
  47: '2 Corinthians',
  48: 'Galatians',
  49: 'Ephesians',
  50: 'Philippians',
  51: 'Colossians',
  52: '1 Thessalonians',
  53: '2 Thessalonians',
  54: '1 Timothy',
  55: '2 Timothy',
  56: 'Titus',
  57: 'Philemon',
  58: 'Hebrews',
  59: 'James',
  60: '1 Peter',
  61: '2 Peter',
  62: '1 John',
  63: '2 John',
  64: '3 John',
  65: 'Jude',
  66: 'Revelation',
};

/// Displays a scrollable list of Bible books.
class BookListScreen extends StatelessWidget {
  final String translation;
  const BookListScreen({super.key, required this.translation});

  @override
  Widget build(BuildContext context) {
    final repo = BibleRepository(translation: translation);
    return Scaffold(
      appBar: AppBar(title: const Text('Select Book')),
      body: FutureBuilder<List<int>>(
        future: repo.getBookIds(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final ids = snapshot.data!;
          return ListView.builder(
            itemCount: ids.length,
            itemBuilder: (context, index) {
              final id = ids[index];
              final name = bibleBookNames[id] ?? 'Book $id';
              return ListTile(
                title: Text(name),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChapterGridScreen(
                        translation: translation,
                        bookId: id,
                        bookName: name,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Displays chapters of a selected book in a grid.
class ChapterGridScreen extends StatelessWidget {
  final String translation;
  final int bookId;
  final String bookName;
  const ChapterGridScreen(
      {super.key,
      required this.translation,
      required this.bookId,
      required this.bookName});

  @override
  Widget build(BuildContext context) {
    final repo = BibleRepository(translation: translation);
    return Scaffold(
      appBar: AppBar(title: Text(bookName)),
      body: FutureBuilder<List<int>>(
        future: repo.getChaptersForBook(bookId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chapters = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.count(
              crossAxisCount: 4,
              childAspectRatio: 1,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: chapters
                  .map((ch) => _numberBox(context, ch, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VerseGridScreen(
                              translation: translation,
                              bookId: bookId,
                              chapter: ch,
                              bookName: bookName,
                            ),
                          ),
                        );
                      }))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _numberBox(BuildContext context, int number, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text('$number', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

/// Displays verses of a selected chapter in a grid.
class VerseGridScreen extends StatelessWidget {
  final String translation;
  final int bookId;
  final int chapter;
  final String bookName;
  const VerseGridScreen(
      {super.key,
      required this.translation,
      required this.bookId,
      required this.chapter,
      required this.bookName});

  @override
  Widget build(BuildContext context) {
    final repo = BibleRepository(translation: translation);
    return Scaffold(
      appBar: AppBar(title: Text('Select Verse')),
      body: FutureBuilder<List<int>>(
        future: repo.getVersesForBookChapter(bookId, chapter),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final verses = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.count(
              crossAxisCount: 4,
              childAspectRatio: 1,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: verses
                  .map((v) => _numberBox(context, v, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReaderScreen(
                              translation: translation,
                              bookId: bookId,
                              bookName: bookName,
                              chapter: chapter,
                              verse: v,
                            ),
                          ),
                        );
                      }))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _numberBox(BuildContext context, int number, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text('$number', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

/// Simple reader displaying selected verse text (or full chapter).
class ReaderScreen extends StatelessWidget {
  final String translation;
  final int bookId;
  final String bookName;
  final int chapter;
  final int verse;
  const ReaderScreen(
      {super.key,
      required this.translation,
      required this.bookId,
      required this.bookName,
      required this.chapter,
      required this.verse});

  @override
  Widget build(BuildContext context) {
    final repo = BibleRepository(translation: translation);
    return Scaffold(
      appBar: AppBar(title: Text('$bookName $chapter:$verse')),
      body: FutureBuilder<List<BibleVerse>>(
        // show verse text
        future: repo.searchVerses(
            'book = ? AND chapter = ? AND verse = ?', [bookId, chapter, verse]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('Verse not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              snapshot.data!.first.text,
              style: const TextStyle(fontSize: 18),
            ),
          );
        },
      ),
    );
  }
}
