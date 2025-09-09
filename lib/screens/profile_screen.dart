import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import '../utils/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int _currentTab = 3;
  int _selectedTab = 0;

  Map<String, dynamic>? _profile; // live profile row
  bool _loading = true;
  RealtimeChannel? _channel;
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadProfileAndSubscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _showEditProfile(BuildContext context) {
    final sb = SupabaseService.client;
    final uid = sb.auth.currentUser?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in to edit your profile.')),
      );
      return;
    }

    final nameController = TextEditingController(
      text: _profile?['display_name']?.toString() ?? '',
    );
    final avatarController = TextEditingController(
      text: _profile?['avatar_url']?.toString() ?? '',
    );
    final roleController = TextEditingController(
      text: _profile?['role']?.toString() ?? '',
    );
    final bioController = TextEditingController(
      text: _profile?['bio']?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Edit Profile',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: avatarController,
                  decoration: const InputDecoration(
                    labelText: 'Avatar URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roleController,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    hintText: 'e.g., Member, Pastor',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final displayName = nameController.text.trim();
                    final avatarUrl = avatarController.text.trim();
                    final role = roleController.text.trim();
                    final bio = bioController.text.trim();

                    final Map<String, dynamic> update = {
                      'last_seen': DateTime.now().toIso8601String(),
                    };

                    if (displayName.isNotEmpty)
                      update['display_name'] = displayName;
                    if (avatarUrl.isNotEmpty) update['avatar_url'] = avatarUrl;
                    if (role.isNotEmpty) update['role'] = role;
                    if (bio.isNotEmpty) update['bio'] = bio;

                    try {
                      await sb.from('profiles').update(update).eq('id', uid);
                      if (mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile updated')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Update failed: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save changes'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadProfileAndSubscribe() async {
    final sb = SupabaseService.client;
    final uid = sb.auth.currentUser?.id;
    if (uid == null) {
      setState(() {
        _loading = false;
        _profile = null;
      });
      return;
    }

    // Initial fetch
    final rows = await sb.from('profiles').select().eq('id', uid).limit(1);
    setState(() {
      _profile = (rows is List && rows.isNotEmpty)
          ? Map<String, dynamic>.from(rows.first)
          : null;
      _loading = false;
    });

    // Realtime subscription
    final ch = sb.channel('public:profiles:user:$uid');
    ch.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'profiles',
      callback: (payload) {
        final map = Map<String, dynamic>.from(payload.newRecord);
        if (map['id']?.toString() == uid) {
          setState(() => _profile = map);
        }
      },
    );
    ch.subscribe();
    _channel = ch;
  }

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

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
        });

        final userId = SupabaseService.client.auth.currentUser?.id;
        if (userId == null) return;

        final fileExt = pickedFile.path.split('.').last;
        final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
        final filePath = 'profile_pictures/$userId/$fileName';

        // Upload the file to Supabase Storage
        await SupabaseService.client.storage
            .from('avatars')
            .upload(filePath, _pickedImage!);

        // Get the public URL
        final String avatarUrl = SupabaseService.client.storage
            .from('avatars')
            .getPublicUrl(filePath);

        // Update the profile with the new avatar URL
        await SupabaseService.client
            .from('profiles')
            .update({'avatar_url': avatarUrl})
            .eq('id', userId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  Widget _buildProfileHeader() {
    final authUser = context.read<AuthProvider?>()?.user;
    final displayName = (_profile?['display_name']?.toString() ??
        authUser?.displayName ??
        'No name');
    final role = _profile?['role']?.toString() ?? 'Member';
    final bio = _profile?['bio']?.toString() ?? '"Blessed to serve 🙏✨"';
    final avatarUrl = _profile?['avatar_url']?.toString();
    final verified = (_profile?['verified_minister'] as bool?) ?? false;

    return Column(
      children: [
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickAndUploadImage,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.lightGrey,
                backgroundImage: _pickedImage != null
                    ? FileImage(_pickedImage!)
                    : (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? NetworkImage(avatarUrl)
                        : null,
                child: _pickedImage == null &&
                        (avatarUrl == null || avatarUrl.isEmpty)
                    ? Icon(Icons.person, size: 48, color: Colors.grey[400])
                    : null,
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 18,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(height: 4),
        Text(
          role,
          style: const TextStyle(color: Colors.black54, fontSize: 15),
        ),
        const SizedBox(height: 8),
        if (verified)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Verified Minister',
              style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            bio,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStat('${_profile?['prayers_count'] ?? 0}', 'Prayers',
                AppColors.primaryBlue),
            _buildStat('${_profile?['teachings_count'] ?? 0}', 'Teachings',
                Colors.green),
            _buildStat('${_profile?['followers_count'] ?? 0}', 'Followers',
                Colors.purple),
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
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: color),
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
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 12),
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
              Text(item['likes'].toString(),
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 16),
              Icon(Icons.comment_outlined, color: Colors.blue[200], size: 18),
              const SizedBox(width: 4),
              Text(item['comments'].toString(),
                  style: const TextStyle(fontSize: 13)),
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
          child: Center(
              child: Text('Achievements coming soon!',
                  style: TextStyle(color: Colors.black54))),
        );
      case 2:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
              child: Text('Stats coming soon!',
                  style: TextStyle(color: Colors.black54))),
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
            icon: const Icon(Icons.edit),
            tooltip: 'Edit profile',
            onPressed: () => _showEditProfile(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
