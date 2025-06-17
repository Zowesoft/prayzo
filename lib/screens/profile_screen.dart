import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int _currentTab = 3;
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _activity = [
    {
      'type': 'prayer',
      'time': '2 hours ago',
      'title': 'Evening Gratitude',
      'likes': 34,
      'comments': 8,
    },
    {
      'type': 'teaching',
      'time': '1 day ago',
      'title': 'Walking in Faith',
      'likes': 67,
      'comments': 15,
    },
    {
      'type': 'prayer',
      'time': '3 days ago',
      'title': 'Healing for Nations',
      'likes': 89,
      'comments': 23,
    },
  ];

  Widget _buildProfileHeader() {
    return Column(
      children: [
        const SizedBox(height: 16),
        CircleAvatar(
          radius: 42,
          backgroundColor: AppColors.lightGrey,
          child: Icon(Icons.person, size: 48, color: Colors.grey[400]),
        ),
        const SizedBox(height: 16),
        const Text(
          'Sarah Johnson',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pastor & Prayer Leader',
          style: TextStyle(color: Colors.black54, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Verified Minister',
            style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            '"Blessed to serve God’s people through prayer and teaching. Let’s grow in faith together! 🙏✨"',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black87, fontSize: 14),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStat('45', 'Prayers', AppColors.primaryBlue),
            _buildStat('23', 'Teachings', Colors.green),
            _buildStat('1247', 'Followers', Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildStat(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildTabButton('Activity', 0),
          _buildTabButton('Achievements', 1),
          _buildTabButton('Stats', 2),
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.primaryBlue : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _activity.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final item = _activity[idx];
        return _buildActivityCard(item);
      },
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> item) {
    final isPrayer = item['type'] == 'prayer';
    final color = isPrayer ? AppColors.primaryBlue : Colors.green;
    final label = isPrayer ? 'prayer' : 'teaching';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item['time'],
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item['title'],
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite_border, color: Colors.pink[200], size: 18),
              const SizedBox(width: 4),
              Text(item['likes'].toString(), style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 16),
              Icon(Icons.comment_outlined, color: Colors.blue[200], size: 18),
              const SizedBox(width: 4),
              Text(item['comments'].toString(), style: const TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 1:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: Text('Achievements coming soon!', style: TextStyle(color: Colors.black54))),
        );
      case 2:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: Text('Stats coming soon!', style: TextStyle(color: Colors.black54))),
        );
      default:
        return _buildActivityList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Profile', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(),
            _buildTabBar(),
            _buildTabContent(),
            const SizedBox(height: 24),
          ],
        ),
      ),

    );
  }
}
