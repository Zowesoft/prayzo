import 'package:flutter/material.dart';
import 'package:prayoo/services/supabase_service.dart';

class ParticipantOptionsBottomSheet extends StatelessWidget {
  final String sessionId;
  final String userId;
  final VoidCallback? onAssignSpeaker;

  const ParticipantOptionsBottomSheet({
    super.key,
    required this.sessionId,
    required this.userId,
    this.onAssignSpeaker,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Participant Options',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildOption(
            icon: Icons.mic,
            title: 'Allow to Speak',
            subtitle: 'Give microphone permission',
            onTap: () => _allowToSpeak(context),
          ),
          _buildOption(
            icon: Icons.assignment_ind,
            title: 'Assign Prayer Point',
            subtitle: 'Assign specific prayer to lead',
            onTap: () {
              Navigator.pop(context);
              if (onAssignSpeaker != null) onAssignSpeaker!();
            },
          ),
          _buildOption(
            icon: Icons.block,
            title: 'Mute Participant',
            subtitle: 'Disable their microphone',
            onTap: () => _muteParticipant(context),
          ),
          _buildOption(
            icon: Icons.remove_circle,
            title: 'Remove from Session',
            subtitle: 'Remove participant from session',
            onTap: () => _removeParticipant(context),
            isDestructive: true,
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.blue,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 12,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _allowToSpeak(BuildContext context) async {
    try {
      await SupabaseService.client.from('participants').upsert({
        'session_id': sessionId,
        'user_id': userId,
        'can_speak': true,
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Participant can now speak')),
      );
    } catch (e) {
      print('Error allowing to speak: $e');
    }
  }

  Future<void> _muteParticipant(BuildContext context) async {
    try {
      await SupabaseService.client
          .from('participants')
          .update({'can_speak': false})
          .match({'session_id': sessionId, 'user_id': userId});
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Participant has been muted')),
      );
    } catch (e) {
      print('Error muting participant: $e');
    }
  }

  Future<void> _removeParticipant(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade800,
        title: Text('Remove Participant', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove this participant from the session?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await SupabaseService.client
                    .from('participants')
                    .delete()
                    .match({'session_id': sessionId, 'user_id': userId});
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close bottom sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Participant removed')),
                );
              } catch (e) {
                print('Error removing participant: $e');
              }
            },
            child: Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}