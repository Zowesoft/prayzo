import 'package:flutter/material.dart';
import 'package:prayoo/providers/session_provider.dart';
import 'package:prayoo/services/agora_service.dart';
import 'package:prayoo/services/session_service.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:prayoo/widgets/participant_options_bottom_sheet.dart';
import 'package:prayoo/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionPage extends StatefulWidget {
  final PrayerSession session;
  
  const SessionPage({super.key, required this.session});
  
  @override
  _SessionPageState createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  final SessionService _sessionService = SessionService();
  final AgoraService _agoraService = AgoraService();
  final TextEditingController _messageController = TextEditingController();
  
  bool _isMuted = true;
  bool _isVideoEnabled = false;
  bool _isAdmin = false;
  final List<int> _remoteUsers = [];
  
  @override
  void initState() {
    super.initState();
    _initializeSession();
  }
  
  Future<void> _initializeSession() async {
    await _agoraService.initialize();
    await _joinAgoraChannel();
    _checkAdminPermissions();
    
    _agoraService.engine?.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print('Joined channel: ${connection.channelId}');
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUsers.add(remoteUid);
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          setState(() {
            _remoteUsers.remove(remoteUid);
          });
        },
      ),
    );
  }
  
  Future<void> _joinAgoraChannel() async {
    await _agoraService.joinChannel(
      'prayer_${widget.session.id}',
      '',
      0,
    );
  }
  
  void _checkAdminPermissions() {
    final currentUserId = SupabaseService.client.auth.currentUser?.id;
    _isAdmin = widget.session.organizerId == currentUserId;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<PrayerSession>(
        stream: _sessionService.listenToSession(widget.session.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          
          final session = snapshot.data!;
          return Column(
            children: [
              _buildHeader(session),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildMainContent(session),
                    ),
                    SizedBox(
                      width: 300,
                      child: _buildSidebar(session),
                    ),
                  ],
                ),
              ),
              _buildControls(),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildHeader(PrayerSession session) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 40, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade800, Colors.blue.shade600],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Led by ${session.organizerName}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMainContent(PrayerSession session) {
    return Container(
      child: Column(
        children: [
          Expanded(
            child: _buildPrayerPointsDisplay(session),
          ),
          if (_isAdmin) _buildAdminControls(session),
        ],
      ),
    );
  }
  
  Widget _buildPrayerPointsDisplay(PrayerSession session) {
    final currentPoint = session.prayerPoints.firstWhere(
      (point) => point.isActive,
      orElse: () => session.prayerPoints.first,
    );
    
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite,
            size: 64,
            color: Colors.white70,
          ),
          SizedBox(height: 24),
          Text(
            'Prayer ${currentPoint.order + 1}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          Text(
            currentPoint.content,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w300,
              height: 1.4,
            ),
          ),
          SizedBox(height: 32),
          if (currentPoint.assignedTo != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Led by: ${_getParticipantName(session, currentPoint.assignedTo!)}',
                style: TextStyle(
                  color: Colors.blue.shade200,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSidebar(PrayerSession session) {
    return Container(
      color: Colors.grey.shade900,
      child: Column(
        children: [
          _buildParticipantsList(session),
          Expanded(
            child: _buildChat(session),
          ),
          _buildChatInput(),
        ],
      ),
    );
  }
  
  Widget _buildParticipantsList(PrayerSession session) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Participants (${session.participants.length})',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              itemCount: session.participants.length,
              itemBuilder: (context, index) {
                final participantId = session.participants.keys.elementAt(index);
                final participant = session.participants[participantId]!;
                return _buildParticipantItem(participantId, participant);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildParticipantItem(String userId, Participant participant) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue,
            child: Text(
              _getParticipantName(widget.session, userId)[0].toUpperCase(),
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _getParticipantName(widget.session, userId),
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          if (participant.canSpeak)
            Icon(Icons.mic, color: Colors.green, size: 16)
          else
            Icon(Icons.mic_off, color: Colors.grey, size: 16),
          if (_isAdmin && userId != widget.session.organizerId)
            IconButton(
              icon: Icon(Icons.more_vert, color: Colors.white, size: 16),
              onPressed: () => _showParticipantOptions(userId),
            ),
        ],
      ),
    );
  }
  
  Widget _buildChat(PrayerSession session) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _sessionService.streamMessages(session.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final messages = snapshot.data!;
        return ListView.builder(
          reverse: true,
          padding: EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final data = messages[index];
            return _buildChatMessage(data);
          },
        );
      },
    );
  }
  
  Widget _buildChatMessage(Map<String, dynamic> data) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['sender_name'] ?? 'Anonymous',
            style: TextStyle(
              color: Colors.blue.shade300,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            data['content']?.toString() ?? '',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChatInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade700),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade800,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send, color: Colors.blue),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAdminControls(PrayerSession session) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        border: Border(
          top: BorderSide(color: Colors.grey.shade700),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Admin Controls',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _goToNextPrayerPoint,
                icon: Icon(Icons.skip_next),
                label: Text('Next Prayer'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
              ElevatedButton.icon(
                onPressed: _toggleGroupSpeaking,
                icon: Icon(Icons.group),
                label: Text('Group Speaking'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              ElevatedButton.icon(
                onPressed: _endSession,
                icon: Icon(Icons.stop),
                label: Text('End Session'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildControls() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(
          top: BorderSide(color: Colors.grey.shade700),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? 'Unmute' : 'Mute',
            onPressed: _toggleMute,
            backgroundColor: _isMuted ? Colors.red : Colors.green,
          ),
          _buildControlButton(
            icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            label: _isVideoEnabled ? 'Stop Video' : 'Start Video',
            onPressed: _toggleVideo,
            backgroundColor: _isVideoEnabled ? Colors.green : Colors.grey,
          ),
          _buildControlButton(
            icon: Icons.call_end,
            label: 'Leave',
            onPressed: _leaveSession,
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  void _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _agoraService.muteLocalAudio(_isMuted);
  }
  
  void _toggleVideo() async {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
    await _agoraService.enableLocalVideo(_isVideoEnabled);
  }
  
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    await _sessionService.sendSessionMessage(
      widget.session.id,
      _messageController.text.trim(),
      'text',
    );
    
    _messageController.clear();
  }
  
  void _goToNextPrayerPoint() async {
    final currentIndex = widget.session.prayerPoints.indexWhere((p) => p.isActive);
    final nextIndex = (currentIndex + 1) % widget.session.prayerPoints.length;
    
    await _sessionService.updatePrayerPoint(widget.session.id, nextIndex);
  }
  
  void _toggleGroupSpeaking() async {
    // Implementation for group speaking toggle
  }
  
  void _endSession() async {
    // Show confirmation dialog and end session
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('End Session'),
        content: Text('Are you sure you want to end this prayer session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await SupabaseService.client
                  .from('prayer_sessions')
                  .update({'status': 'ended'})
                  .eq('id', widget.session.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('End Session'),
          ),
        ],
      ),
    );
  }
  
  void _leaveSession() async {
    await _agoraService.leaveChannel();
    Navigator.pop(context);
  }
  
  void _showParticipantOptions(String userId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ParticipantOptionsBottomSheet(
        sessionId: widget.session.id,
        userId: userId,
        onAssignSpeaker: () => _assignSpeaker(userId),
      ),
    );
  }
  
  void _assignSpeaker(String userId) async {
    // Show dialog to select prayer point
    // Then assign speaker
  }
  
  String _getParticipantName(PrayerSession session, String userId) {
    // This would typically fetch from user collection
    return 'User $userId';
  }
  
  @override
  void dispose() {
    _agoraService.leaveChannel();
    _agoraService.dispose();
    _messageController.dispose();
    super.dispose();
  }
}