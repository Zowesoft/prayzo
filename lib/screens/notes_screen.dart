import 'package:flutter/material.dart';
import '../utils/colors.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _notes = [
    {
      'type': 'prayer',
      'title': 'Morning Gratitude Prayer',
      'author': 'Sarah Johnson',
      'time': '2 hours ago',
      'content':
          'Heavenly Father, as I begin this new day, I come before you with a heart full of gratitude…',
      'tags': ['Gratitude', 'Morning', 'Peace'],
      'scripture': 'Psalms 118:24',
      'likes': 45,
      'comments': 12,
    },
    {
      'type': 'teaching',
      'title': 'Understanding Grace Through Scripture',
      'author': 'Pastor Michael',
      'time': '5 hours ago',
      'content':
          'Grace is one of the most beautiful concepts in Christianity. It represents God’s unmerited favor…',
      'tags': ['Grace', 'Bible Study', 'Theology'],
      'scripture': 'Ephesians 2:8-9',
      'likes': 128,
      'comments': 34,
    },
    {
      'type': 'prayer',
      'title': 'Healing Prayer for Community',
      'author': 'Unity Church',
      'time': '1 day ago',
      'content':
          'Lord, we lift up our community to you today. We pray for healing, both physical and spiritual…',
      'tags': ['Healing', 'Community', 'Unity'],
      'scripture': 'James 5:14-15',
      'likes': 89,
      'comments': 23,
    },
    {
      'type': 'teaching',
      'title': 'The Power of Forgiveness',
      'author': 'Rachel Adams',
      'time': '2 days ago',
      'content':
          'Forgiveness is not just a suggestion in Christianity; it’s a commandment that leads to freedom…',
      'tags': ['Forgiveness', 'Reflection', 'Growth'],
      'scripture': 'Matthew 6:14-15',
      'likes': 67,
      'comments': 18,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search prayers and teachings…',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTabButton('All', 0),
          const SizedBox(width: 8),
          _buildTabButton('Prayers', 1),
          const SizedBox(width: 8),
          _buildTabButton('Teachings', 2),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredNotes {
    if (_selectedTab == 1) {
      return _notes.where((n) => n['type'] == 'prayer').toList();
    } else if (_selectedTab == 2) {
      return _notes.where((n) => n['type'] == 'teaching').toList();
    }
    return _notes;
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final isPrayer = note['type'] == 'prayer';
    final color = isPrayer ? AppColors.primaryBlue : Colors.green;
    final label = isPrayer ? 'prayer' : 'teaching';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200],
                child: Icon(Icons.person, color: Colors.grey[400], size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note['title'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '${note['author']} • ${note['time']}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note['content'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  note['scripture'],
                  style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w500,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              ...note['tags']
                  .map<Widget>((tag) => Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black54),
                        ),
                      ))
                  .toList(),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.favorite_border, color: Colors.pink[200], size: 18),
              const SizedBox(width: 4),
              Text(note['likes'].toString(),
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 16),
              Icon(Icons.comment_outlined, color: Colors.blue[200], size: 18),
              const SizedBox(width: 4),
              Text(note['comments'].toString(),
                  style: const TextStyle(fontSize: 13)),
              const Spacer(),
              Icon(Icons.share, color: Colors.black26, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Notes',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          _buildTabs(),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredNotes.length,
              itemBuilder: (context, idx) =>
                  _buildNoteCard(_filteredNotes[idx]),
            ),
          ),
        ],
      ),
    );
  }
}
