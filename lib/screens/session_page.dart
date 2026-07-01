import 'package:flutter/material.dart';
import 'package:prayoo/providers/session_provider.dart';
import 'package:prayoo/services/agora_service.dart';
import 'package:prayoo/services/session_service.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:prayoo/widgets/participant_options_bottom_sheet.dart';
import 'package:prayoo/services/supabase_service.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:prayoo/repository/bible_repository.dart';
import 'package:prayoo/models/bible_verse.dart';
import 'bible_reference_selector.dart' show bibleBookNames;

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
  bool _showScripture = false;
  String? _activeScripture;
  bool _groupSpeaking = false;
  final BibleRepository _bible = BibleRepository(translation: 'kjv');
  bool _scriptureLoading = false;
  List<BibleVerse> _loadedVerses = const [];
  String? _scriptureError;

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
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          setState(() {
            _remoteUsers.remove(remoteUid);
          });
        },
      ),
    );
  }

  Widget _buildPointRichContent(PrayerPoint point,
      {required ValueKey<String> key}) {
    // If we have a stored Quill delta, render rich content; otherwise show plain text
    final deltaJson = point.contentDelta;
    if (deltaJson != null) {
      try {
        final doc = quill.Document.fromJson(deltaJson as List);
        final controller = quill.QuillController(
            document: doc, selection: const TextSelection.collapsed(offset: 0));
        return IgnorePointer(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: quill.QuillEditor.basic(
              controller: controller,
              config: const quill.QuillEditorConfig(
                placeholder: '',
              ),
            ),
          ),
        );
      } catch (_) {
        // Fallback to plain text if parsing fails
      }
    }
    return Text(
      point.content,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w300,
        height: 1.4,
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
    if (session.prayerPoints.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No prayer points added yet',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final currentPoint = session.prayerPoints.firstWhere(
      (point) => point.isActive,
      orElse: () => session.prayerPoints.first,
    );
    final others = session.prayerPoints
        .where((p) => p.id != currentPoint.id)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Active prayer banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade800,
                  Colors.blue.shade600,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Pill label
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Prayer ${currentPoint.order + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Main content (toggle between prayer content and scripture view)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _showScripture
                      ? _buildScriptureView(key: const ValueKey('scripture'))
                      : _buildPointRichContent(currentPoint,
                          key: const ValueKey('prayer')),
                ),
                const SizedBox(height: 16),
                if (currentPoint.assignedTo != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mic, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Led by: ${_getParticipantName(session, currentPoint.assignedTo!)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                // Scripture pills row
                _buildScriptureChips(currentPoint),
                if (_showScripture)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _showScripture = false;
                        _activeScripture = null;
                        _loadedVerses = const [];
                        _scriptureError = null;
                      }),
                      icon: const Icon(Icons.keyboard_return,
                          color: Colors.white),
                      label: const Text('Return to Prayer',
                          style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          // Other prayer points list
          Text(
            'Other Prayer Points',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (others.isEmpty)
            Text(
              'No other points',
              style: TextStyle(color: Colors.white70),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: others.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final p = others[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      'Prayer ${p.order + 1}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      p.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: _isAdmin
                        ? (p.id == currentPoint.id
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('Active',
                                    style: TextStyle(color: Colors.green)),
                              )
                            : TextButton(
                                onPressed: () =>
                                    _setActivePrayerPoint(index: p.order),
                                child: const Text('Set Active'),
                              ))
                        : (p.id == currentPoint.id
                            ? const Text('Active',
                                style: TextStyle(color: Colors.green))
                            : null),
                  ),
                );
              },
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
                final participantId =
                    session.participants.keys.elementAt(index);
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
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    final currentIndex =
        widget.session.prayerPoints.indexWhere((p) => p.isActive);
    final nextIndex = (currentIndex + 1) % widget.session.prayerPoints.length;

    await _sessionService.updatePrayerPoint(widget.session.id, nextIndex);
  }

  void _setActivePrayerPoint({required int index}) async {
    // Set a specific point active by its order/index
    await _sessionService.updatePrayerPoint(widget.session.id, index);
  }

  Widget _buildScriptureChips(PrayerPoint point) {
    final scriptures = point.scriptures;
    if (scriptures.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: scriptures.map((ref) {
          final selected = _showScripture && _activeScripture == ref;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(ref,
                  style:
                      TextStyle(color: selected ? Colors.black : Colors.white)),
              selected: selected,
              selectedColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              onSelected: (_) {
                _onSelectScripture(ref);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScriptureView({Key? key}) {
    final ref = _activeScripture ?? '';
    return Column(key: key, children: [
      Text(
        ref,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      if (_scriptureLoading)
        const Padding(
          padding: EdgeInsets.all(12.0),
          child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.white)),
        )
      else if (_scriptureError != null)
        Text(_scriptureError!, style: const TextStyle(color: Colors.redAccent))
      else if (_loadedVerses.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ..._loadedVerses.map((v) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      children: [
                        Text(
                          '${v.verse}. ${v.text}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18, height: 1.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          v.reference,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        )
      else
        const SizedBox.shrink(),
    ]);
  }

  Future<void> _onSelectScripture(String ref) async {
    setState(() {
      _activeScripture = ref;
      _showScripture = true;
      _scriptureLoading = true;
      _loadedVerses = const [];
      _scriptureError = null;
    });

    try {
      final parsed = _parseReferenceRange(ref);
      if (parsed == null) {
        throw Exception('Could not parse reference');
      }
      final bookId = parsed.$1;
      final chapter = parsed.$2;
      final startVerse = parsed.$3;
      final endVerse = parsed.$4;
      final where = endVerse != null
          ? 'book = ? AND chapter = ? AND verse BETWEEN ? AND ?'
          : 'book = ? AND chapter = ? AND verse = ?';
      final args = endVerse != null
          ? [bookId, chapter, startVerse, endVerse]
          : [bookId, chapter, startVerse];
      final results = await _bible.searchVerses(where, args);
      if (results.isEmpty) {
        throw Exception('Verse not found');
      }
      setState(() {
        _loadedVerses = results;
        _scriptureLoading = false;
      });
    } catch (e) {
      setState(() {
        _scriptureError = 'Unable to load verse';
        _scriptureLoading = false;
      });
    }
  }

  // Parse references like "John 3:16" or ranges "John 3:16-18" → (bookId, chapter, startVerse, endVerse?)
  (int, int, int, int?)? _parseReferenceRange(String input) {
    String s = input.trim().toLowerCase().replaceAll('.', '');
    final regSingle = RegExp(r'^([0-9]?\s?[a-z ]+?)\s+(\d+):(\d+)$');
    final regRange = RegExp(r'^([0-9]?\s?[a-z ]+?)\s+(\d+):(\d+)-(\d+)$');
    RegExpMatch? m = regRange.firstMatch(s);
    bool isRange = m != null;
    m ??= regSingle.firstMatch(s);
    if (m == null) return null;
    String bookName = m.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' ');
    int chapter = int.parse(m.group(2)!);
    int start = int.parse(m.group(3)!);
    int? end = isRange ? int.parse(m.group(4)!) : null;

    // Build normalized map from bibleBookNames (id -> name)
    final Map<String, int> nameToId = {};
    bibleBookNames.forEach((id, name) {
      final norm = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      nameToId[norm] = id;
    });
    // Common abbreviations (add only if base key exists)
    void addAlias(String alias, String base) {
      final key = base.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (nameToId.containsKey(key)) {
        nameToId[alias] = nameToId[key]!;
      }
    }

    addAlias('psalm', 'psalms');
    addAlias('songofsongs', 'song of solomon');
    addAlias('1cor', '1 corinthians');
    addAlias('2cor', '2 corinthians');
    addAlias('1sam', '1 samuel');
    addAlias('2sam', '2 samuel');
    addAlias('1kgs', '1 kings');
    addAlias('2kgs', '2 kings');
    addAlias('1chr', '1 chronicles');
    addAlias('2chr', '2 chronicles');

    final bookKey = bookName.replaceAll(RegExp(r'[^a-z0-9]'), '');
    int? bookId = nameToId[bookKey];
    // Fallback: try startsWith match
    if (bookId == null) {
      for (final entry in nameToId.entries) {
        if (entry.key.startsWith(bookKey)) {
          bookId = entry.value;
          break;
        }
      }
    }
    if (bookId == null) return null;
    return (bookId, chapter, start, end);
  }

  void _toggleGroupSpeaking() async {
    setState(() {
      _groupSpeaking = !_groupSpeaking;
    });
    await _sessionService.enableGroupSpeaking(
        widget.session.id, _groupSpeaking);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(_groupSpeaking
              ? 'Group speaking enabled'
              : 'Group speaking disabled')),
    );
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
                  .update({'status': 'ended'}).eq('id', widget.session.id);
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
    final sessionId = widget.session.id;
    // Let admin choose which prayer point to assign the speaker to
    final selectedOrder = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Assign Speaker to Prayer Point'),
          content: SizedBox(
            width: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.session.prayerPoints.length,
              itemBuilder: (context, index) {
                final p = widget.session.prayerPoints[index];
                return ListTile(
                  title: Text('Prayer ${p.order + 1}'),
                  subtitle: Text(
                    p.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.of(ctx).pop(p.order),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedOrder == null) return;
    try {
      // Find the id of the selected prayer point by its order
      final point = widget.session.prayerPoints
          .firstWhere((p) => p.order == selectedOrder);
      await _sessionService.assignSpeaker(sessionId, userId, point.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Speaker assigned to Prayer ${selectedOrder + 1}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to assign speaker')),
      );
    }
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
