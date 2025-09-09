import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:prayoo/providers/auth_provider.dart';
import 'package:prayoo/services/prayer_service.dart';
import 'package:prayoo/providers/session_provider.dart';
import 'package:intl/intl.dart';

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
  final TextEditingController _scriptureController = TextEditingController();
  late AnimationController _toggleController;
  late Animation<double> _toggleAnimation;
  // Session creation (Prayer mode)
  bool createAsSession = false;
  DateTime _scheduledTime = DateTime.now().add(const Duration(hours: 1));
  final List<TextEditingController> _pointControllers = [TextEditingController()];
  final List<TextEditingController> _pointScripturesControllers = [TextEditingController()];
  
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
  bool showScriptureField = false;

  @override
  void initState() {
    super.initState();
    _toggleController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _toggleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _toggleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _scriptureController.dispose();
    for (final c in _pointControllers) { c.dispose(); }
    for (final c in _pointScripturesControllers) { c.dispose(); }
    _toggleController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      isPrayerMode = !isPrayerMode;
      selectedTags.clear();
      showScriptureField = false;
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

  void _addScriptureReference() {
    setState(() {
      showScriptureField = !showScriptureField;
    });
  }

  void _addPrayerPointField() {
    setState(() {
      _pointControllers.add(TextEditingController());
      _pointScripturesControllers.add(TextEditingController());
    });
  }

  void _removePrayerPointField(int index) {
    if (_pointControllers.length == 1) return;
    setState(() {
      _pointControllers.removeAt(index).dispose();
      _pointScripturesControllers.removeAt(index).dispose();
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
      _scheduledTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
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
    final scriptures = _scriptureController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // When creating a Session (Prayer mode only)
    if (isPrayerMode && createAsSession) {
      final points = _pointControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
      if (points.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Add at least one prayer point'), backgroundColor: AppColors.error),
        );
        return;
      }

      final pointScriptures = _pointScripturesControllers
          .map((c) => c.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList())
          .toList();

      if (auth.isLoggedIn) {
        // Create Firestore session
        context
            .read<SessionProvider>()
            .createPrayerSession(
              title: _titleController.text.trim(),
              description: _contentController.text.trim(),
              scheduledTime: _scheduledTime,
              prayerPoints: points,
              prayerPointScriptures: pointScriptures,
            )
            .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prayer session created!')),
          );
          Navigator.pop(context);
        }).catchError((e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create session: $e'), backgroundColor: AppColors.error),
          );
        });
        return;
      } else {
        // Save locally as personal prayer if not logged in
        final service = PrayerService();
        service
            .createPrayer(
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              scriptures: scriptures,
              tags: selectedTags,
              isPrivate: isPrivate,
            )
            .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved locally as a personal prayer')),
          );
          Navigator.pop(context);
        });
        return;
      }
    }

    // Default: publish a single prayer/teaching
    final service = PrayerService();
    service
        .createPrayer(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          scriptures: scriptures,
          tags: selectedTags,
          isPrivate: isPrivate,
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
            if (isPrayerMode) _buildCreateSessionToggle(),
            if (isPrayerMode && createAsSession) ...[
              SizedBox(height: 12),
              _buildSchedulePicker(),
              SizedBox(height: 12),
              _buildPrayerPointsEditor(),
            ],
            
            // Scripture Reference
            if (showScriptureField) _buildScriptureField(),
            if (showScriptureField) SizedBox(height: 20),
            
            // Add Scripture Reference Button
            _buildAddScriptureButton(),
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
                  color: isPrayerMode ? AppColors.primaryBlue : Colors.transparent,
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
                  color: !isPrayerMode ? AppColors.primaryGreen : Colors.transparent,
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

  Widget _buildCreateSessionToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
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
              children: const [
                Text('Create as Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Schedule this prayer and add multiple prayer points', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Switch(
            value: createAsSession,
            onChanged: (v) => setState(() => createAsSession = v),
            activeColor: AppColors.primaryBlue,
          )
        ],
      ),
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
        const Text('Prayer Points', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                      child: TextField(
                        controller: _pointControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Prayer Point ${index + 1}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_pointControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removePrayerPointField(index),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _pointScripturesControllers[index],
                  decoration: const InputDecoration(
                    labelText: 'Scriptures (comma separated)',
                    hintText: 'e.g., John 3:16, Psalm 23:1-6',
                    border: OutlineInputBorder(),
                  ),
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

  Widget _buildScriptureField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scripture Reference',
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
            controller: _scriptureController,
            style: TextStyle(color: AppColors.darkGrey),
            decoration: InputDecoration(
              hintText: 'e.g., John 3:16, Psalm 23:1-6',
              hintStyle: TextStyle(color: AppColors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddScriptureButton() {
    return GestureDetector(
      onTap: _addScriptureReference,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showScriptureField ? Icons.remove : Icons.add,
              color: AppColors.primaryBlue,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              showScriptureField 
                ? 'Remove Scripture Reference' 
                : 'Add Scripture Reference',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
                    ? (isPrayerMode ? AppColors.primaryBlue : AppColors.primaryGreen)
                    : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                      ? (isPrayerMode ? AppColors.primaryBlue : AppColors.primaryGreen)
                      : AppColors.lightGrey,
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: isSelected 
                      ? Colors.white 
                      : AppColors.grey,
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
                activeColor: isPrayerMode ? AppColors.primaryBlue : AppColors.primaryGreen,
              ),
            ],
          ),
        ),
      ],
    );
  }
}