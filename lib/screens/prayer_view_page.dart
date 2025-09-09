import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:prayoo/providers/session_provider.dart';
import 'package:prayoo/services/supabase_service.dart';
import 'package:prayoo/utils/colors.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PrayerViewPage extends StatelessWidget {
  final Map<String, dynamic> prayer;

  const PrayerViewPage({super.key, required this.prayer});

  @override
  Widget build(BuildContext context) {
    final title = prayer['title']?.toString() ?? 'Prayer';
    final description = (prayer['description'] ?? prayer['content'])?.toString() ?? '';
    final createdAt = prayer['created_at'] is int
        ? DateTime.fromMillisecondsSinceEpoch(prayer['created_at'] as int)
        : DateTime.now();
    final prayerId = prayer['id']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Schedule as Session',
            icon: const Icon(Icons.schedule),
            onPressed: () => _openScheduleAsSession(context, title, description),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${createdAt.toLocal()}',
              style: TextStyle(color: AppColors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    if (prayerId != null) ...[
                      const Text(
                        'Prayer Points',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _PrayerPointsList(prayerId: prayerId),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openScheduleAsSession(BuildContext context, String title, String description) {
    DateTime scheduledTime = DateTime.now().add(const Duration(hours: 1));
    final List<TextEditingController> pointCtrls = [TextEditingController()];

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
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              Future<void> pickTime() async {
                final date = await showDatePicker(
                  context: ctx,
                  initialDate: scheduledTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date == null) return;
                final time = await showTimePicker(
                  context: ctx,
                  initialTime: TimeOfDay.fromDateTime(scheduledTime),
                );
                if (time == null) return;
                setModalState(() {
                  scheduledTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                });
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Schedule as Session',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Scheduled Time'),
                      subtitle: Text(DateFormat('MMM dd, yyyy - hh:mm a').format(scheduledTime)),
                      trailing: const Icon(Icons.schedule),
                      onTap: pickTime,
                    ),
                    const SizedBox(height: 12),
                    const Text('Prayer Points (optional)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...List.generate(pointCtrls.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: pointCtrls[i],
                                decoration: InputDecoration(
                                  labelText: 'Prayer Point ${i + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (pointCtrls.length > 1)
                              IconButton(
                                onPressed: () => setModalState(() {
                                  pointCtrls.removeAt(i).dispose();
                                }),
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                              ),
                          ],
                        ),
                      );
                    }),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setModalState(() => pointCtrls.add(TextEditingController())),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Prayer Point'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final points = pointCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                        try {
                          await context.read<SessionProvider>().createPrayerSession(
                                title: title,
                                description: description,
                                scheduledTime: scheduledTime,
                                prayerPoints: points,
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Session scheduled from prayer')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.event_available),
                      label: const Text('Create Session'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// A private widget to display prayer points associated with a prayer.
// It fetches items from a hypothetical `prayer_points` table filtered by `prayer_id`.
// If your schema differs, adjust the table/column names accordingly.
class _PrayerPointsList extends StatelessWidget {
  final String prayerId;

  const _PrayerPointsList({required this.prayerId});

  Future<List<String>> _loadPrayerPoints() async {
    try {
      final List<dynamic> result = await SupabaseService.client
          .from('prayer_points')
          .select('point')
          .eq('prayer_id', prayerId);

      return result
          .map((e) => (e as Map)["point"]) // dynamic safety
          .where((v) => v != null)
          .map((v) => v.toString())
          .toList();
    } catch (_) {
      // Fail gracefully; you may add logging if needed
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _loadPrayerPoints(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Text('Failed to load prayer points');
        }
        final points = snapshot.data ?? const [];
        if (points.isEmpty) {
          return Text(
            'No prayer points yet',
            style: TextStyle(color: AppColors.grey),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final p in points)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6.0, right: 8.0),
                      child: Icon(Icons.fiber_manual_record, size: 8),
                    ),
                    Expanded(
                      child: Text(
                        p,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
