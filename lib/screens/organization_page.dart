import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prayoo/providers/auth_provider.dart';
import 'package:prayoo/services/supabase_service.dart';

class OrganizationPage extends StatefulWidget {
  final String orgId;
  const OrganizationPage({super.key, required this.orgId});

  @override
  State<OrganizationPage> createState() => _OrganizationPageState();
}

class _OrganizationPageState extends State<OrganizationPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _org;
  bool _loading = true;
  bool _following = false;
  int _followersCount = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final sb = SupabaseService.client;
      final List<dynamic> rows = await sb
          .from('organizations')
          .select()
          .eq('id', widget.orgId)
          .limit(1);
      final org =
          rows.isNotEmpty ? Map<String, dynamic>.from(rows.first) : null;
      final List<dynamic> countRows = await sb
          .from('organization_followers')
          .select('user_id')
          .eq('org_id', widget.orgId);
      final following = await context
          .read<AuthProvider>()
          .isFollowingOrganization(widget.orgId);
      setState(() {
        _org = org;
        _followersCount = countRows.length;
        _following = following;
      });
    } catch (_) {
      // show error quietly
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final auth = context.read<AuthProvider>();
    if (!_following) {
      await auth.followOrganization(widget.orgId);
      setState(() {
        _following = true;
        _followersCount += 1;
      });
    } else {
      await auth.unfollowOrganization(widget.orgId);
      setState(() {
        _following = false;
        _followersCount = (_followersCount - 1).clamp(0, 1 << 31);
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadPrayers() async {
    final List<dynamic> rows = await SupabaseService.client
        .from('prayers')
        .select()
        .eq('organization_id', widget.orgId)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> _loadTeachings() async {
    final List<dynamic> rows = await SupabaseService.client
        .from('teachings')
        .select()
        .eq('organization_id', widget.orgId)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Prayers'),
            Tab(text: 'Teachings'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_loadPrayers, emptyText: 'No prayers yet.'),
                      _buildList(_loadTeachings,
                          emptyText: 'No teachings yet.'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final name = _org?['name']?.toString() ?? 'Organization';
    final description = _org?['description']?.toString() ?? '';
    final logo = _org?['logo_url']?.toString();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage:
                (logo != null && logo.isNotEmpty) ? NetworkImage(logo) : null,
            child: (logo == null || logo.isEmpty)
                ? const Icon(Icons.apartment)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text('$_followersCount followers',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _toggleFollow,
            child: Text(_following ? 'Unfollow' : 'Follow'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(Future<List<Map<String, dynamic>>> Function() loader,
      {required String emptyText}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: loader(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return Center(child: Text(emptyText));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final m = items[i];
            final title = m['title']?.toString() ?? '';
            final content =
                (m['description'] ?? m['content'])?.toString() ?? '';
            return ListTile(
              title: Text(title),
              subtitle:
                  Text(content, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.pushNamed(context, '/prayer', arguments: m);
              },
            );
          },
        );
      },
    );
  }
}
