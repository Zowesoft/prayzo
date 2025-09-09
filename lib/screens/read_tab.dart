import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/database_helper.dart';
import '../repository/bible_repository.dart';
import '../models/bible_verse.dart';

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

class ReadTab extends StatefulWidget {
  const ReadTab({super.key});

  @override
  State<ReadTab> createState() => _ReadTabState();
}

enum _Stage { book, chapter, verse, reading }

class _ReadTabState extends State<ReadTab> {
  final BibleRepository _repo = BibleRepository();
  final TextEditingController _search = TextEditingController();

  _Stage _stage = _Stage.book;
  String? _book;
  int? _chapter;
  int? _verse;

  List<String> _books = [];
  List<int> _chapters = [];
  List<int> _verses = [];
  List<BibleVerse> _chapterContent = [];

  final ScrollController _readingController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};
  final double _verseRowHeight = 85.0; // Use your measured height as default
  bool _shouldAutoScroll = false; // Flag to control auto-scroll

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _readingController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    final books = await _repo.getBooks();
    setState(() => _books = books);
  }

  Future<void> _loadChapters(String book) async {
    final db = await DatabaseHelper.getDatabase();
    final r = await db.rawQuery(
        'SELECT MAX(chapter) AS maxChap FROM verses WHERE book = ?', [book]);
    final max = (r.first['maxChap'] ?? 1) as int;
    setState(() => _chapters = List.generate(max, (i) => i + 1));
  }

  Future<void> _loadVerses(String book, int chapter) async {
    final db = await DatabaseHelper.getDatabase();
    final r = await db.rawQuery(
        'SELECT MAX(verse) AS maxVerse FROM verses WHERE book = ? AND chapter = ?',
        [book, chapter]);
    final max = (r.first['maxVerse'] ?? 1) as int;
    setState(() => _verses = List.generate(max, (i) => i + 1));
  }

  Future<void> _loadChapterContent() async {
    final data = await _repo.searchVerses('book = ? AND chapter = ?', [_book, _chapter]);
    
    // Clear and recreate keys for the new chapter content
    _verseKeys.clear();
    for (final verse in data) {
      _verseKeys[verse.verse] = GlobalKey();
    }
    
    setState(() {
      _chapterContent = data;
      _shouldAutoScroll = _verse != null; // Set flag if we have a target verse
    });
  }

  void _performAutoScroll() {
    if (!_shouldAutoScroll || _verse == null || !mounted) {
      return;
    }

    print('Performing auto-scroll to verse $_verse');
    
    // Reset the flag to prevent multiple attempts
    _shouldAutoScroll = false;
    
    // Always use the calculated position approach for more reliable scrolling
    if (_readingController.hasClients && _chapterContent.isNotEmpty) {
      final selectedIndex = _chapterContent.indexWhere((v) => v.verse == _verse);
      if (selectedIndex != -1) {
        final totalVerses = _chapterContent.length;
        final maxOffset = _readingController.position.maxScrollExtent;
        final viewportHeight = _readingController.position.viewportDimension;
        
        print('ScrollController info: maxOffset=$maxOffset, viewportHeight=$viewportHeight');
        
        double targetOffset;
        
        if (selectedIndex >= totalVerses - 3) {
          // For the last 3 verses, scroll to the very bottom to ensure visibility
          targetOffset = maxOffset;
          print('Last 3 verses detected, scrolling to bottom: $targetOffset');
        } else if (selectedIndex > totalVerses * 0.7) {
          // For verses in the last 30%, try to position them in the lower part of the screen
          targetOffset = (selectedIndex * _verseRowHeight - viewportHeight * 0.3).clamp(0.0, maxOffset);
          print('End verses detected, adjusted offset: $targetOffset');
        } else {
          // For verses in the first 70%, use normal positioning
          targetOffset = (selectedIndex * _verseRowHeight - 100).clamp(0.0, maxOffset);
          print('Normal positioning: $targetOffset');
        }
        
        print('Final scroll: verse $_verse at index $selectedIndex/$totalVerses, offset: $targetOffset');
        
        // Use jumpTo first to ensure we get there, then animate for smooth effect
        try {
          _readingController.jumpTo(targetOffset);
          print('Successfully scrolled to offset: $targetOffset');
        } catch (e) {
          print('Jump scroll failed: $e');
          // Fallback to animateTo
          try {
            _readingController.animateTo(
              targetOffset,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          } catch (e2) {
            print('Animate scroll also failed: $e2');
          }
        }
      } else {
        print('Verse $_verse not found in chapter content!');
        print('Available verses: ${_chapterContent.map((v) => v.verse).toList()}');
      }
    } else {
      print('ScrollController not ready: hasClients=${_readingController.hasClients}, contentLength=${_chapterContent.length}');
    }
  }

  void _resetToBook() {
    setState(() {
      _stage = _Stage.book;
      _book = null;
      _chapter = null;
      _verse = null;
      _chapters.clear();
      _verses.clear();
      _chapterContent.clear();
      _verseKeys.clear();
      _shouldAutoScroll = false;
    });
  }

  Widget _verseRow(BibleVerse v) {
    final isSelected = v.verse == _verse;
    final key = _verseKeys[v.verse]!;

    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.2) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${v.verse}. ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
              child: Text(
            v.text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          )),
        ],
      ),
    );
  }

  // ---- WIDGET BUILDERS -----------------------------------------------------
  Widget _topBar({required String title, bool showBack = true}) {
    return Row(
      children: [
        if (showBack)
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              switch (_stage) {
                case _Stage.book:
                  break;
                case _Stage.chapter:
                  _resetToBook();
                  break;
                case _Stage.verse:
                  setState(() => _stage = _Stage.chapter);
                  break;
                case _Stage.reading:
                  setState(() => _stage = _Stage.verse);
                  break;
              }
            },
          ),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        if (_stage == _Stage.book) ...[
          IconButton(
            icon: const Icon(Icons.sort_by_alpha),
            onPressed: () {
              setState(() => _books.sort());
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {/* TODO: implement recently used */},
          ),
        ],
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search',
        filled: true,
        fillColor: AppColors.darkGrey.withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (txt) => setState(() {}),
    );
  }

  // ------------- BUILD PER STAGE -------------------------------------------
  Widget _buildBookStage() {
    final filter = _search.text.trim().toLowerCase();
    final list = filter.isEmpty
        ? _books
        : _books.where((b) => b.toLowerCase().contains(filter)).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _topBar(title: 'References', showBack: false),
        const SizedBox(height: 12),
        _searchField(),
        const SizedBox(height: 24),
        ...list.map(
          (bk) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  _book = bk;
                  _chapter = null;
                  _verse = null;
                  await _loadChapters(bk);
                  setState(() => _stage = _Stage.chapter);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    bibleBookNames[int.parse(bk)]!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkGrey,
                    ),
                  ),
                ),
              ),
              if (bk == _book && _chapters.isNotEmpty) _miniChapterGrid(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniChapterGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _chapters
          .take(9)
          .map((c) => _squareButton('$c', onTap: () async {
                _chapter = c;
                await _loadVerses(_book!, c);
                setState(() => _stage = _Stage.verse);
              }))
          .toList(),
    );
  }

  Widget _buildChapterStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(title: 'Select Chapter'),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: _chapters.length,
            itemBuilder: (c, i) =>
                _squareButton('${_chapters[i]}', onTap: () async {
              _chapter = _chapters[i];
              await _loadVerses(_book!, _chapter!);
              setState(() => _stage = _Stage.verse);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildVerseStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(title: 'Select Verse'),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: _verses.length,
            itemBuilder: (c, i) =>
                _squareButton('${_verses[i]}', onTap: () async {
              _verse = _verses[i];
              await _loadChapterContent();
              setState(() => _stage = _Stage.reading);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildReadingStage() {
    // Trigger auto-scroll after the ListView is built
    if (_shouldAutoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Add a small delay to ensure ListView is fully rendered
        Future.delayed(const Duration(milliseconds: 100), () {
          _performAutoScroll();
        });
      });
    }

    return Column(
      children: [
        _topBar(title: '$_book $_chapter'),
        Expanded(
          child: ListView.builder(
            controller: _readingController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: _chapterContent.length,
            itemBuilder: (c, i) {
              final v = _chapterContent[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _verseRow(v),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.darkGrey.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.play_circle_fill, size: 32),
                onPressed: () {/* TODO: audio */},
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () async {
                  if (_chapter! > 1) {
                    _chapter = _chapter! - 1;
                    _verse = null;
                    await _loadVerses(_book!, _chapter!);
                    await _loadChapterContent();
                    setState(() {});
                  }
                },
              ),
              Text(
                '$_book $_chapter',
                style: const TextStyle(color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () async {
                  if (_chapter! < _chapters.length) {
                    _chapter = _chapter! + 1;
                    _verse = null;
                    await _loadVerses(_book!, _chapter!);
                    await _loadChapterContent();
                    setState(() {});
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---- GENERAL WIDGETS -----------------------------------------------------
  Widget _squareButton(String text, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkGrey.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ---- ROOT ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: () {
            switch (_stage) {
              case _Stage.book:
                return _buildBookStage();
              case _Stage.chapter:
                return _buildChapterStage();
              case _Stage.verse:
                return _buildVerseStage();
              case _Stage.reading:
                return _buildReadingStage();
            }
          }(),
        ),
      ),
    );
  }
}