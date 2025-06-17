import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/sample_data.dart';
import '../widgets/bible_verse_card.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
 BibleScreenState createState() => BibleScreenState();
}

class BibleScreenState extends State<BibleScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  List<String> bookmarkedVerses = [];
  String selectedBook = 'Psalms';
  int selectedChapter = 23;

  final List<String> bibleBooks = [
    'Genesis', 'Exodus', 'Psalms', 'Proverbs', 'Matthew', 'John', 'Romans'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
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
        title: Text('Bible'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(100),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search verses, books, or topics...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              // Tab Bar
              TabBar(
                controller: _tabController,
                tabs: [
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verse of the Day
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.primaryBlue.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Verse of the Day',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Strength & Perseverance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  '"I can do all things through Christ who strengthens me."',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Philippians 4:13',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    Row(
                      children: [
                        Icon(Icons.favorite_border, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Icon(Icons.bookmark_border, color: Colors.white, size: 20),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Daily Reading Suggestions
          Padding(
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

          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return BibleVerseCard(
                verse: SampleData.bibleVerses[index],
                isBookmarked: bookmarkedVerses.contains(SampleData.bibleVerses[index].reference),
                onBookmark: () => _toggleBookmark(SampleData.bibleVerses[index].reference),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReadTab() {
    return Column(
      children: [
        // Book Selection
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: bibleBooks.length,
            itemBuilder: (context, index) {
              final book = bibleBooks[index];
              final isSelected = book == selectedBook;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedBook = book;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: 8),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryGreen : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryGreen : AppColors.lightGrey,
                    ),
                  ),
                  child: Text(
                    book,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.darkGrey,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Chapter Navigation
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.menu_book, color: AppColors.primaryBlue),
              SizedBox(width: 12),
              Text(
                '$selectedBook $selectedChapter',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                ),
              ),
              Spacer(),
              Row(
                children: [
                  for (int i = 23; i <= 27; i++)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedChapter = i;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(left: 4),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: i == selectedChapter ? AppColors.primaryGreen : AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$i',
                          style: TextStyle(
                            color: i == selectedChapter ? Colors.white : AppColors.darkGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Bible Text
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: SampleData.psalms23.length,
            itemBuilder: (context, index) {
              final verse = SampleData.psalms23[index];
              return Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${verse.verse}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        verse.text,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.darkGrey,
                          height: 1.6,
                        ),
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

  Widget _buildBookmarksTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
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
            itemCount: SampleData.bookmarkedVerses.length,
            itemBuilder: (context, index) {
              final verse = SampleData.bookmarkedVerses[index];
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verse.reference,
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      verse.text,
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