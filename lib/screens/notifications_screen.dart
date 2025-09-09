import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadInitial();
    NotificationService.notificationsStream.listen((notif) {
      setState(() {
        _items = [notif, ..._items];
      });
    });
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitial,
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final n = _items[index];
                  final unread = (n['read'] as bool?) == false;
                  return ListTile(
                    leading: Icon(
                      unread ? Icons.notifications_active : Icons.notifications_none,
                      color: unread ? Colors.blue : Colors.grey,
                    ),
                    title: Text(n['title']?.toString() ?? 'Notification'),
                    subtitle: Text(n['body']?.toString() ?? ''),
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
    );
  }
}
