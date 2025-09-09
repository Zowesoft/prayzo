import 'package:flutter/material.dart';
import 'package:prayoo/providers/auth_provider.dart';
import 'package:prayoo/providers/session_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:prayoo/services/local_storage_service.dart';
import 'package:prayoo/models/prayer.dart';
import 'package:prayoo/widgets/prayer_card.dart';
import 'package:prayoo/services/supabase_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final LocalStorageService _local = LocalStorageService();
  List<Map<String, dynamic>> _localPrayers = [];
  List<PrayerSession> _downloadedSessions = [];
  List<String> _followingIds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLocalData();
    _loadFollowingIfLoggedIn();
  }

  // ===== Auth-aware Home body =====
  Widget _buildHomeBodyByAuth() {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: const Text('My Prayers',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          _buildLocalPrayersList(),
          const SizedBox(height: 8),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: const Text('Downloaded Prayers',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          _buildDownloadedSessionsList(),
        ],
      );
    }

    // Logged in: show Featured, My Prayers (cloud), then Upcoming
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Featured
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: const Text('Featured Prayers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        _buildFeaturedPrayers(),
        // My cloud prayers
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: const Text('My Prayers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        _buildMyCloudPrayers(),
        // Upcoming sessions
        const SizedBox(height: 8),
        _buildUpcomingPrayers(),
      ],
    );
  }

  Future<void> _loadLocalData() async {
    final prayers = await _local.getUserPrayers();
    final downloads = await _local.getDownloadedSessions();
    if (mounted) {
      setState(() {
        _localPrayers = prayers;
        _downloadedSessions = downloads;
      });
    }
  }

  Future<void> _loadFollowingIfLoggedIn() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      final ids = await auth.getFollowingIds();
      if (mounted) setState(() => _followingIds = ids);
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<SessionProvider>().refresh(),
      _loadLocalData(),
      _loadFollowingIfLoggedIn(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildLiveSession()),
            SliverToBoxAdapter(child: _buildTabSection()),
            SliverToBoxAdapter(child: _buildHomeBodyByAuth()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Prayoo',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade800, Colors.purple.shade600],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications),
          onPressed: () => _showNotifications(),
        ),
        Builder(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isLoggedIn) {
            return IconButton(
              icon: const Icon(Icons.login),
              onPressed: () => Navigator.pushNamed(context, '/login'),
            );
          }
          return IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundImage: (auth.user?.photoURL?.isNotEmpty ?? false)
                  ? CachedNetworkImageProvider(auth.user!.photoURL!)
                  : const AssetImage('assets/images/default_avatar.png')
                      as ImageProvider,
            ),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          );
        }),
      ],
    );
  }

  Widget _buildLiveSession() {
    return Consumer<SessionProvider>(
        builder: (context, sessionProvider, child) {
          final liveSession = sessionProvider.currentLiveSession;
          if (liveSession == null) return SizedBox.shrink();

          return Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.purple.shade700, Colors.blue.shade600],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Live',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        liveSession.currentPrayerPoint ?? 'Prayer Session',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        liveSession.title,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pastor ${liveSession.organizerName}',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _joinLiveSession(liveSession),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                        ),
                        child: Text('Join Session'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
  }

  Widget _buildTabSection() {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        child: Consumer<SessionProvider>(
          builder: (context, sessionProvider, _) {
            final scriptures = sessionProvider.currentLiveSession?.scriptures ??
                const ['Psalms 23:1-6', 'John 3:16', 'Matthew 6:9-13'];

            final colors = [
              [Colors.blue.shade100, Colors.blue],
              [Colors.green.shade100, Colors.green],
              [Colors.purple.shade100, Colors.purple],
              [Colors.orange.shade100, Colors.orange],
            ];

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(scriptures.length, (index) {
                  final chipColors = colors[index % colors.length];
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: _buildTabChip(
                      scriptures[index],
                      chipColors[0],
                      chipColors[1],
                    ),
                  );
                }),
              ),
            );
          },
        ),
      );
  }

  Widget _buildTabChip(String text, Color bgColor, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildUpcomingPrayers() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Upcoming Prayers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Consumer<SessionProvider>(
            builder: (context, sessionProvider, child) {
              final items = _followingIds.isEmpty
                  ? sessionProvider.upcomingSessions
                  : sessionProvider.upcomingSessions
                      .where((s) => _followingIds.contains(s.organizerId))
                      .toList();
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final session = items[index];
                  return _buildPrayerSessionCard(session);
                },
              );
            },
          ),
        ],
      );
  }

  // ===== Featured (followed) prayers from Supabase =====
  Widget _buildFeaturedPrayers() {
    return FutureBuilder<List<Prayer>>(
      future: _fetchFeaturedPrayers(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ));
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('No featured prayers yet.'),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final p = items[index];
            return GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/prayer', arguments: {
                'title': p.title,
                'content': p.content,
                'created_at': p.createdAt.millisecondsSinceEpoch,
              }),
              child: PrayerCard(prayer: p),
            );
          },
        );
      },
    );
  }

  // ===== My prayers from Supabase for logged-in user =====
  Widget _buildMyCloudPrayers() {
    return FutureBuilder<List<Prayer>>(
      future: _fetchMyPrayers(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ));
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('You have not posted any prayers yet.'),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final p = items[index];
            return GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/prayer', arguments: {
                'title': p.title,
                'content': p.content,
                'created_at': p.createdAt.millisecondsSinceEpoch,
              }),
              child: PrayerCard(prayer: p),
            );
          },
        );
      },
    );
  }

  Future<List<Prayer>> _fetchFeaturedPrayers() async {
    final sb = SupabaseService.client;
    final authorIds = _followingIds;
    var q = sb
        .from('prayers')
        .select()
        .order('created_at', ascending: false)
        .limit(10);
    if (authorIds.isNotEmpty) {
      q = sb
          .from('prayers')
          .select()
          .inFilter('author_id', authorIds.take(10).toList())
          .order('created_at', ascending: false)
          .limit(10);
    }
    final List<dynamic> res = await q;
    return res
        .map((e) => _prayerFromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Prayer>> _fetchMyPrayers() async {
    final sb = SupabaseService.client;
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return [];
    final List<dynamic> res = await sb
        .from('prayers')
        .select()
        .eq('author_id', uid)
        .order('created_at', ascending: false)
        .limit(10);
    return res
        .map((e) => _prayerFromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Prayer _prayerFromMap(Map<String, dynamic> data) {
    return Prayer(
      id: data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      author: '',
      authorRole: '',
      content: data['content']?.toString() ?? '',
      scriptureReferences: (data['scriptures'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      tags: (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      likes: (data['likes_count'] as int?) ?? 0,
      comments: (data['comments_count'] as int?) ?? 0,
      createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
      videoUrl: null,
      isLive: false,
      authorAvatar: '',
    );
  }

  Widget _buildLocalPrayersList() {
    if (_localPrayers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child:
            Text('No personal prayers yet. Create one from the Create screen.'),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _localPrayers.length,
      itemBuilder: (context, index) {
        final p = _localPrayers[index];
        return ListTile(
          title: Text(p['title']?.toString() ?? 'Untitled'),
          subtitle: Text(
            (p['content']?.toString() ?? '').trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, '/prayer', arguments: p),
        );
      },
    );
  }

  Widget _buildDownloadedSessionsList() {
    if (_downloadedSessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text('No downloads yet.'),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _downloadedSessions.length,
      itemBuilder: (context, index) {
        final s = _downloadedSessions[index];
        return ListTile(
          leading: const Icon(Icons.download_done, color: Colors.blue),
          title: Text(s.title),
          subtitle:
              Text(s.description, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Show a simple read view for downloaded session
            final map = {
              'title': s.title,
              'content':
                  s.prayerPoints.map((e) => '• ${e.content}').join('\n\n'),
              'created_at': DateTime.now().millisecondsSinceEpoch,
            };
            Navigator.pushNamed(context, '/prayer', arguments: map);
          },
        );
      },
    );
  }

  Widget _buildPrayerSessionCard(PrayerSession session) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                session.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: () => _joinSession(session),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: Size(60, 32),
                ),
                child: Text(
                  'Join',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            session.getFormattedTime(),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${session.participantCount} joining',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }


  void _joinSession(PrayerSession session) {
    final provider = context.read<SessionProvider>();
    provider.joinSession(session.id).then((_) {
      Navigator.pushNamed(
        context,
        '/session',
        arguments: session,
      );
    });
  }

  void _joinLiveSession(PrayerSession session) {
    final provider = context.read<SessionProvider>();
    provider.joinSession(session.id).then((_) {
      Navigator.pushNamed(
        context,
        '/session',
        arguments: session,
      );
    });
  }

  void _showNotifications() {
    // Implement notifications
  }
}
