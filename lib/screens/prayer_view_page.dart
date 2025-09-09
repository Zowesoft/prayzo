import 'package:flutter/material.dart';
import 'package:prayoo/utils/colors.dart';

class PrayerViewPage extends StatelessWidget {
  final Map<String, dynamic> prayer;

  const PrayerViewPage({super.key, required this.prayer});

  @override
  Widget build(BuildContext context) {
    final title = prayer['title']?.toString() ?? 'Prayer';
    final content = prayer['content']?.toString() ?? '';
    final createdAt = prayer['created_at'] is int
        ? DateTime.fromMillisecondsSinceEpoch(prayer['created_at'] as int)
        : DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
                child: Text(
                  content,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
