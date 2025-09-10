import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:prayoo/providers/auth_provider.dart';
import 'package:prayoo/services/prayer_service.dart';
// import 'package:prayoo/providers/session_provider.dart';
import 'package:intl/intl.dart';
import '../repository/bible_repository.dart';
import '../models/bible_verse.dart';
import 'package:flutter_quill/flutter_quill.dart';

class CreateNoteScreen extends StatefulWidget {
  const CreateNoteScreen({super.key});

  @override
  CreateNoteScreenState createState() => CreateNoteScreenState();
}

class CreateNoteScreenState extends State<CreateNoteScreen>
    with SingleTickerProviderStateMixin {
  bool isPrayerMode = true;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  late AnimationController _toggleController;
  // Prayer points for prayers
  DateTime _scheduledTime = DateTime.now().add(const Duration(hours: 1));
  final List<TextEditingController> _pointControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _pointScripturesControllers = [
    TextEditingController()
  ];
  final List<QuillController> _pointEditors = [QuillController.basic()];

  List<String> selectedTags = [];
  List<String> availableTags = [
    'Gratitude',
    'Healing',
    'Peace',
    'Guidance',
    'Strength',
    'Community',
    'Family',
    'Faith',
    'Hope',
    'Love',
    'Forgiveness',
    'Wisdom',
    'Protection',
    'Blessing',
    'Unity'
  ];

  // Different tags for Teaching mode
  List<String> teachingTags = [
    'Bible Study',
    'Devotional',
    'Sermon',
    'Testimony',
    'Reflection',
    'Scripture',
    'Faith',
    'Hope'
  ];

  bool isPrivate = false;
  final BibleRepository _bibleRepo = BibleRepository();

  @override
  void initState() {
    super.initState();
    _toggleController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    for (final c in _pointControllers) {
      c.dispose();
    }
    for (final c in _pointScripturesControllers) {
      c.dispose();
    }
    _toggleController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      isPrayerMode = !isPrayerMode;
      selectedTags.clear();
      if (isPrayerMode) {
        _toggleController.reverse();
      } else {
        _toggleController.forward();
      }
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (selectedTags.contains(tag)) {
        selectedTags.remove(tag);
      } else {
        selectedTags.add(tag);
      }
    });
  }

  Future<String?> _openScripturePicker() async {
    int? selectedBookId;
    int? selectedChapter;
    int? selectedVerse;

    final books = await _bibleRepo.getBookIds();

    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Pick Scripture',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedBookId,
                    decoration: const InputDecoration(
                      labelText: 'Book',
                      border: OutlineInputBorder(),
                    ),
                    items: books
                        .map((b) => DropdownMenuItem<int>(
                              value: b,
                              child: Text(bibleBookNames[b]),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setModalState(() {
                        selectedBookId = v;
                        selectedChapter = null;
                        selectedVerse = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<int>>(
                    future: selectedBookId == null
                        ? Future.value(const <int>[])
                        : _bibleRepo.getChaptersForBook(selectedBookId!),
                    builder: (context, snap) {
                      final chapters = snap.data ?? const <int>[];
                      return DropdownButtonFormField<int>(
                        value: chapters.contains(selectedChapter)
                            ? selectedChapter
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Chapter',
                          border: OutlineInputBorder(),
                        ),
                        items: chapters
                            .map((c) => DropdownMenuItem<int>(
                                  value: c,
                                  child: Text(c.toString()),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setModalState(() {
                            selectedChapter = v;
                            selectedVerse = null;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<int>>(
                    future: (selectedBookId == null || selectedChapter == null)
                        ? Future.value(const <int>[])
                        : _bibleRepo.getVersesForBookChapter(
                            selectedBookId!, selectedChapter!),
                    builder: (context, snap) {
                      final verses = snap.data ?? const <int>[];
                      return DropdownButtonFormField<int>(
                        value: verses.contains(selectedVerse)
                            ? selectedVerse
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Verse',
                          border: OutlineInputBorder(),
                        ),
                        items: verses
                            .map((v) => DropdownMenuItem<int>(
                                  value: v,
                                  child: Text(v.toString()),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setModalState(() => selectedVerse = v),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedBookId != null &&
                          selectedChapter != null &&
                          selectedVerse != null) {
                        final ref =
                            '${bibleBookNames[selectedBookId!]} $selectedChapter:$selectedVerse';
                        Navigator.pop(ctx, ref);
                      } else {
                        Navigator.pop(ctx, null);
                      }
                    },
                    child: const Text('Add Reference'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addPrayerPointField() {
    setState(() {
      _pointControllers.add(TextEditingController());
      _pointScripturesControllers.add(TextEditingController());
      _pointEditors.add(QuillController.basic());
    });
  }

  void _removePrayerPointField(int index) {
    if (_pointEditors.length == 1) return;
    setState(() {
      _pointControllers.removeAt(index).dispose();
      _pointScripturesControllers.removeAt(index).dispose();
      _pointEditors.removeAt(index);
    });
  }

  Future<void> _pickScheduledTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledTime),
    );
    if (time == null) return;
    setState(() {
      _scheduledTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _publishContent() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter content'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final List<String> scriptures = const [];

    // Unified flow: create a prayer with optional prayer points (rich content)
    final points = _pointEditors
        .map((c) => c.document.toPlainText().trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final deltas = _pointEditors.map((c) => c.document.toDelta().toJson()).toList();
    final pointScriptures = _pointScripturesControllers
        .map((c) => c.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList())
        .toList();

    final service = PrayerService();
    service
        .createPrayer(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          scriptures: scriptures,
          tags: selectedTags,
          isPrivate: isPrivate,
          prayerPoints: points,
          prayerPointScriptures: pointScriptures,
          prayerPointDeltas: deltas,
        )
        .then((_) {
      final savedMsg = auth.isLoggedIn
          ? (isPrayerMode ? 'Prayer published!' : 'Teaching published!')
          : 'Saved locally as a personal prayer';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(savedMsg),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      Navigator.pop(context);
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.darkGrey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isPrayerMode ? 'Create Prayer' : 'Create Teaching',
          style: TextStyle(
            color: AppColors.darkGrey,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _publishContent,
            child: Text(
              'Publish',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Toggle
            _buildModeToggle(),
            SizedBox(height: 24),

            // Title Field
            _buildTitleField(),
            SizedBox(height: 20),

            // Content Editor
            _buildContentEditor(),
            SizedBox(height: 20),
            if (isPrayerMode) ...[
              _buildPrayerPointsEditor(),
            ],

            SizedBox(height: 24),

            // Tags Section
            _buildTagsSection(),
            SizedBox(height: 24),

            // Privacy Settings
            _buildPrivacySettings(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isPrayerMode) _toggleMode();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      isPrayerMode ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Prayer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isPrayerMode ? Colors.white : AppColors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isPrayerMode) _toggleMode();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isPrayerMode
                      ? AppColors.primaryGreen
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Teaching',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !isPrayerMode ? Colors.white : AppColors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Title',
          style: TextStyle(
            color: AppColors.darkGrey,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: TextField(
            controller: _titleController,
            style: TextStyle(color: AppColors.darkGrey),
            decoration: InputDecoration(
              hintText: isPrayerMode
                  ? 'Enter prayer title...'
                  : 'Enter teaching title...',
              hintStyle: TextStyle(color: AppColors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildSchedulePicker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: ListTile(
        title: const Text('Scheduled Time'),
        subtitle: Text(DateFormat('MMM dd, yyyy - hh:mm a').format(_scheduledTime)),
        trailing: const Icon(Icons.schedule),
        onTap: _pickScheduledTime,
      ),
    );
  }

  Widget _buildPrayerPointsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Prayer Points',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...List.generate(_pointControllers.length, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          QuillSimpleToolbar(controller: _pointEditors[index]),
                          const SizedBox(height: 8),
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.lightGrey),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: QuillEditor.basic(
                                controller: _pointEditors[index],
                                config: const QuillEditorConfig(
                                  placeholder: 'Write prayer point...',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_pointEditors.length > 1)
                      IconButton(
                        icon:
                            const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removePrayerPointField(index),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Scripture References',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Builder(builder: (context) {
                      final tokens = _pointScripturesControllers[index]
                          .text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...tokens.map((t) => Chip(
                                label: Text(t),
                                onDeleted: () {
                                  setState(() {
                                    final list = tokens.toList();
                                    list.remove(t);
                                    _pointScripturesControllers[index].text =
                                        list.join(', ');
                                  });
                                },
                              )),
                          ActionChip(
                            avatar: const Icon(Icons.add, size: 18),
                            label: const Text('Pick Scripture'),
                            onPressed: () async {
                              final picked = await _openScripturePicker();
                              if (picked != null && picked.isNotEmpty) {
                                setState(() {
                                  final list = tokens.toList();
                                  list.add(picked);
                                  _pointScripturesControllers[index].text =
                                      list.join(', ');
                                });
                              }
                            },
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addPrayerPointField,
            icon: const Icon(Icons.add),
            label: const Text('Add Prayer Point'),
          ),
        )
      ],
    );
  }

  Widget _buildContentEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Content',
              style: TextStyle(
                color: AppColors.darkGrey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.format_bold, color: AppColors.grey),
                  onPressed: () {
                    // Implement bold formatting
                  },
                ),
                IconButton(
                  icon: Icon(Icons.format_italic, color: AppColors.grey),
                  onPressed: () {
                    // Implement italic formatting
                  },
                ),
                IconButton(
                  icon: Icon(Icons.format_list_bulleted, color: AppColors.grey),
                  onPressed: () {
                    // Implement bullet list
                  },
                ),
                IconButton(
                  icon: Icon(Icons.format_quote, color: AppColors.grey),
                  onPressed: () {
                    // Implement quote formatting
                  },
                ),
                IconButton(
                  icon: Icon(Icons.visibility, color: AppColors.grey),
                  onPressed: () {
                    // Implement preview mode
                  },
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: TextField(
            controller: _contentController,
            maxLines: null,
            expands: true,
            style: TextStyle(color: AppColors.darkGrey),
            decoration: InputDecoration(
              hintText: isPrayerMode
                  ? 'Share your prayer with the community...'
                  : 'Write your teaching content here...',
              hintStyle: TextStyle(color: AppColors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    List<String> currentTags = isPrayerMode ? availableTags : teachingTags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            color: AppColors.darkGrey,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: currentTags.map((tag) {
            bool isSelected = selectedTags.contains(tag);
            return GestureDetector(
              onTap: () => _toggleTag(tag),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isPrayerMode
                          ? AppColors.primaryBlue
                          : AppColors.primaryGreen)
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (isPrayerMode
                            ? AppColors.primaryBlue
                            : AppColors.primaryGreen)
                        : AppColors.lightGrey,
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy Settings',
          style: TextStyle(
            color: AppColors.darkGrey,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Public',
                      style: TextStyle(
                        color: AppColors.darkGrey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      isPrayerMode
                          ? 'Anyone can see this prayer'
                          : 'Anyone can see this teaching',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: !isPrivate,
                onChanged: (value) {
                  setState(() {
                    isPrivate = !value;
                  });
                },
                activeColor: isPrayerMode
                    ? AppColors.primaryBlue
                    : AppColors.primaryGreen,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
