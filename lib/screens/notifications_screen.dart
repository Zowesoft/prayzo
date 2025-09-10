import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prayoo/services/supabase_service.dart';
import 'package:prayoo/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  StreamSubscription<Map<String, dynamic>>? _notifSub;
  final Map<String, Map<String, dynamic>> _profileCache = {};

  // Filters: all, orgs, personal
  int _filterIndex = 0; // 0: All, 1: Organizations, 2: Personal

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _notifSub = NotificationService.notificationsStream.listen((notif) {
      setState(() {
        _items = [notif, ..._items];
      });
      _prefetchSenderProfiles([notif]);
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final sb = SupabaseService.client;
    final user = sb.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    final List<dynamic> res = await sb
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);
    setState(() {
      _items = res.map((e) => Map<String, dynamic>.from(e)).toList();
      _loading = false;
    });
    _prefetchSenderProfiles(_items);
  }

  Future<void> _markAsRead(String id) async {
    await NotificationService.markAsRead(id);
    setState(() {
      _items = _items.map((e) => e['id'] == id ? {...e, 'read': true} : e).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_items.any((e) => (e['read'] as bool?) == false))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitial,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildFilterChips(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _filteredItems().isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              Center(child: Text('No notifications yet.')),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _filteredItems().length,
                            itemBuilder: (context, index) {
                              final n = _filteredItems()[index];
                              final unread = (n['read'] as bool?) == false;
                              final createdAt = _parseDateTime(n['created_at']);
                              final ts = createdAt != null
                                  ? DateFormat('MMM d, h:mm a').format(createdAt)
                                  : '';
                              final senderId = _extractSenderId(n);
                              final sender = senderId != null ? _profileCache[senderId] : null;
                              final isOrg = sender?['is_org'] == true;
                              final senderName = sender?['display_name']?.toString();

                              return ListTile(
                                tileColor: unread ? Colors.blue.withOpacity(0.05) : null,
                                leading: Icon(
                                  unread ? Icons.notifications_active : Icons.notifications_none,
                                  color: unread ? Colors.blue : Colors.grey,
                                ),
                                title: Text(n['title']?.toString() ?? 'Notification'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if ((n['body']?.toString() ?? '').isNotEmpty)
                                      Text(n['body']?.toString() ?? ''),
                                    Row(
                                      children: [
                                        if (senderName != null) ...[
                                          Icon(isOrg ? Icons.apartment : Icons.person, size: 12, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              senderName,
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('•', style: TextStyle(color: Colors.grey)),
                                          const SizedBox(width: 8),
                                        ],
                                        Text(ts, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: unread
                                    ? TextButton(
                                        onPressed: () => _markAsRead(n['id']?.toString() ?? ''),
                                        child: const Text('Mark read'),
                                      )
                                    : null,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _markAllAsRead() async {
    await NotificationService.markAllAsRead();
    setState(() {
      _items = _items.map((e) => {...e, 'read': true}).toList();
    });
  }

  // ===== Filtering helpers =====
  Widget _buildFilterChips() {
    final labels = const ['All', 'Organizations', 'Personal'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = _filterIndex == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(labels[i]),
              selected: selected,
              onSelected: (_) => setState(() => _filterIndex = i),
            ),
          );
        }),
      ),
    );
  }

  List<Map<String, dynamic>> _filteredItems() {
    if (_filterIndex == 0) return _items;
    return _items.where((n) {
      final senderId = _extractSenderId(n);
      if (senderId == null) return _filterIndex == 2; // no sender -> treat as personal
      final profile = _profileCache[senderId];
      final isOrg = profile?['is_org'] == true;
      if (_filterIndex == 1) return isOrg == true;
      return isOrg == false;
    }).toList();
  }

  String? _extractSenderId(Map<String, dynamic> n) {
    final data = n['data'];
    if (data is Map) {
      final orgId = data['org_id']?.toString();
      final senderId = data['sender_id']?.toString();
      return orgId ?? senderId;
    }
    return null;
  }

  Future<void> _prefetchSenderProfiles(List<Map<String, dynamic>> notifs) async {
    final ids = <String>{};
    for (final n in notifs) {
      final id = _extractSenderId(n);
      if (id != null && !_profileCache.containsKey(id)) ids.add(id);
    }
    if (ids.isEmpty) return;
    try {
      final sb = SupabaseService.client;
      final List<dynamic> rows = await sb
          .from('profiles')
          .select('id, display_name, is_org')
          .inFilter('id', ids.toList());
      for (final r in rows) {
        final m = Map<String, dynamic>.from(r);
        _profileCache[m['id'].toString()] = m;
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }
}
