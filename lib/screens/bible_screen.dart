import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/database_helper.dart';
import '../utils/colors.dart';
import '../repository/bible_repository.dart';
import 'bible_reference_selector.dart' show bibleBookNames;
import '../models/bible_verse.dart';
import '../widgets/bible_verse_card.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  BibleScreenState createState() => BibleScreenState();
}

enum BibleContentView { books, chapters, verses }

class BibleScreenState extends State<BibleScreen>
    with TickerProviderStateMixin {
  BibleContentView _selectedView = BibleContentView.books;
  final GlobalKey _searchBarKey = GlobalKey();
  OverlayEntry? _searchOverlayEntry;

  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  List<String> bookmarkedVerses = []; // Changed from BibleVerse to String
  String selectedBook = 'Genesis';
  int selectedChapter = 1;
  int? selectedVerseNum;
  final BibleRepository _bibleRepository = BibleRepository();
  List<BibleVerse> _searchResults = [];
  bool _isSearching = false;
  BibleVerse? _cachedVerseOfDay;
  Timer? _searchDebounce;
  List<int> _availableChapters = [];
  List<int> _availableVerses = [];

  // Get book names using the centralized function
  List<String> get bookNames => bibleBookNames.entries
      .map((e) => getBookNameById(e.key))
      .toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_debouncedSearchListener);
    _loadBookNames();
    _loadVerseOfTheDay();
    _loadChaptersForBook(selectedBook);
  }

  Future<void> _loadBookNames() async {
    // No need to load book names as they are now statically defined in bible_reference_selector.dart
    setState(() {
      // Optionally reset selectedBook if needed
      if (bibleBookNames.isNotEmpty && !bookNames.contains(selectedBook)) {
        selectedBook = bookNames.first;
      }
    });
  }

  void _debouncedSearchListener() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _onSearchChanged();
    });
  }

  Future<void> _loadVerseOfTheDay() async {
    if (_cachedVerseOfDay == null) {
      _cachedVerseOfDay = await _bibleRepository.getVerseOfTheDay();
      setState(() {});
    }
  }

  Future<void> _loadChaptersForBook(String book) async {
    final db = await DatabaseHelper.getDatabase();
    final result = await db.rawQuery(
        'SELECT MAX(chapter) as maxChap FROM verses WHERE book = ?', [book]);
    int maxChapter = (result.first['maxChap'] ?? 1) as int;
    setState(() {
      _availableChapters = List.generate(maxChapter, (i) => i + 1);
      selectedChapter = 1;
      selectedVerseNum = null;
      _loadVersesForChapter(1);
    });
  }

  Future<void> _loadVersesForChapter(int chapter) async {
    final db = await DatabaseHelper.getDatabase();
    final result = await db.rawQuery(
        'SELECT MAX(verse) as maxVerse FROM verses WHERE book = ? AND chapter = ?',
        [selectedBook, chapter]);
    int maxVerse = (result.first['maxVerse'] ?? 1) as int;
    setState(() {
      _availableVerses = List.generate(maxVerse, (i) => i + 1);
      selectedVerseNum = null;
    });
  }

  void _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() => _isSearching = true);
      final results =
          await _bibleRepository.searchVerses('text LIKE ?', ['%$query%']);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } else {
      setState(() => _searchResults = []);
    }
  }

  @override
  void dispose() {
    _removeSearchOverlay();
    _searchDebounce?.cancel();
    _searchController.removeListener(_debouncedSearchListener);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showSearchOverlay(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _removeSearchOverlay();
      if (!_isSearching && _searchResults.isEmpty) return;
      final RenderBox renderBox =
          _searchBarKey.currentContext?.findRenderObject() as RenderBox;
      final Offset offset = renderBox.localToGlobal(Offset.zero);
      final Size size = renderBox.size;
      _searchOverlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: offset.dx,
          top: offset.dy + size.height,
          width: size.width,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _searchResults.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No matches found'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, idx) {
                            final verse = _searchResults[idx];
                            return ListTile(
                              title: Text(
                                verse.reference,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                verse.text.length > 80
                                    ? '${verse.text.substring(0, 80)}...'
                                    : verse.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                _searchController.text = verse.text;
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  _searchResults = [verse];
                                  _isSearching = false;
                                });
                                _removeSearchOverlay();
                              },
                            );
                          },
                        ),
            ),
          ),
        ),
      );
      Overlay.of(context).insert(_searchOverlayEntry!);
    });
  }

  void _removeSearchOverlay() {
    _searchOverlayEntry?.remove();
    _searchOverlayEntry = null;
  }

  void _toggleBookmark(String reference) {
    setState(() {
      if (bookmarkedVerses.contains(reference)) {
        bookmarkedVerses.remove(reference);
      } else {
        bookmarkedVerses.add(reference);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Bible'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Use a key to get the position of the search bar
                    Stack(
                      children: [
                        TextField(
                          key: _searchBarKey,
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search verses, books, or topics...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (val) {
                            // Remove and re-insert overlay on each change
                            _showSearchOverlay(context);
                          },
                          onTap: () {
                            _showSearchOverlay(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tab Bar
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Today'),
                  Tab(text: 'Read'),
                  Tab(text: 'Bookmarks'),
                ],
                labelColor: AppColors.primaryBlue,
                unselectedLabelColor: AppColors.grey,
                indicatorColor: AppColors.primaryBlue,
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildReadTab(),
          _buildBookmarksTab(),
        ],
      ),
    );
  }

  Widget _buildTodayTab() {
    final verseOfDay = _cachedVerseOfDay;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verse of the Day
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue,
                  AppColors.primaryBlue.withValues(alpha: 0.8)
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: verseOfDay == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Verse of the Day',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              verseOfDay.book,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '"${verseOfDay.text}"',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            verseOfDay.reference,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const Row(
                            children: [
                              Icon(Icons.favorite_border,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 12),
                              Icon(Icons.bookmark_border,
                                  color: Colors.white, size: 20),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          // Daily Reading Suggestions
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Suggested Reading',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGrey,
              ),
            ),
          ),
          FutureBuilder<List<BibleVerse>>(
            future: _bibleRepository.getSuggestedReading(count: 3),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final suggestions = snap.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final v = suggestions[index];
                  return BibleVerseCard(
                    verse: v,
                    isBookmarked: bookmarkedVerses.contains(v.reference),
                    onBookmark: () => _toggleBookmark(v.reference),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBibleContent() {
    if (_selectedView == BibleContentView.books) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.5,
        ),
        itemCount: bibleBookNames.length,
        itemBuilder: (context, index) {
          final bookId = bibleBookNames.keys.elementAt(index);
          final bookName = getBookNameById(bookId);
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedBook = bookName;
                _selectedView = BibleContentView.chapters;
              });
              _loadChaptersForBook(bookName);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  bookName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGrey,
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else if (_selectedView == BibleContentView.chapters) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: _availableChapters.length,
        itemBuilder: (context, index) {
          final chapter = _availableChapters[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedChapter = chapter;
                _selectedView = BibleContentView.verses;
              });
              _loadVersesForChapter(chapter);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$chapter',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGrey,
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '$selectedBook $selectedChapter',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<BibleVerse>>(
              future: _bibleRepository.searchVerses(
                  'book = ? AND chapter = ?', [selectedBook, selectedChapter]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final verses = snapshot.data!;
                if (verses.isEmpty) {
                  return const Center(child: Text('No verses found'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: verses.length,
                  itemBuilder: (context, index) {
                    final verse = verses[index];
                    final isSelected = selectedVerseNum == verse.verse;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primaryGreen : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(
                          '${verse.verse}. ${verse.text}',
                          style: TextStyle(
                            color:
                                isSelected ? Colors.white : AppColors.darkGrey,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            selectedVerseNum = verse.verse;
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    }
  }

  Widget _buildReadTab() {
    return Column(
      children: [
        if (_selectedView != BibleContentView.books)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      if (_selectedView == BibleContentView.verses) {
                        _selectedView = BibleContentView.chapters;
                      } else {
                        _selectedView = BibleContentView.books;
                      }
                    });
                  },
                ),
                Text(
                  _selectedView == BibleContentView.chapters
                      ? 'Select Chapter'
                      : 'Select Book',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

        // Chapter Navigation
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.menu_book, color: AppColors.primaryBlue),
              const SizedBox(width: 12),
              Text(
                '$selectedBook $selectedChapter',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                ),
              ),
              const Spacer(),
              Row(
                children: _availableChapters
                    .map((ch) => GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedChapter = ch;
                            });
                            _loadVersesForChapter(ch);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ch == selectedChapter
                                  ? AppColors.primaryGreen
                                  : AppColors.lightGrey,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$ch',
                              style: TextStyle(
                                color: ch == selectedChapter
                                    ? Colors.white
                                    : AppColors.darkGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),

        // Verses Navigation
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 4,
            children: _availableVerses
                .map((v) => GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedVerseNum = v;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selectedVerseNum == v
                              ? AppColors.primaryGreen
                              : AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$v',
                          style: TextStyle(
                            color: selectedVerseNum == v
                                ? Colors.white
                                : AppColors.darkGrey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),

        // Bible Content
        Expanded(
          child: _buildBibleContent(),
        ),
      ],
    );
  }

  Widget _buildBookmarksTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: const Row(
            children: [
              Icon(Icons.bookmark, color: AppColors.primaryBlue),
              SizedBox(width: 8),
              Text(
                'My Bookmarks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: bookmarkedVerses.length,
            itemBuilder: (context, index) {
              final reference = bookmarkedVerses[index];
              // Just show reference, no text for now (could be improved)
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reference,
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkGrey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
