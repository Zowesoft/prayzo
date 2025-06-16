import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/sample_data.dart';

class CreateNoteScreen extends StatefulWidget {
  const CreateNoteScreen({super.key});

  @override
  _CreateNoteScreenState createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen>
    with SingleTickerProviderStateMixin {
  bool isPrayerMode = true;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _scriptureController = TextEditingController();
  late AnimationController _toggleController;
  late Animation<double> _toggleAnimation;
  
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

    // Here you would typically save the content to your backend
    // For now, we'll just show a success message and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPrayerMode 
            ? 'Prayer published successfully!' 
            : 'Teaching published successfully!'
        ),
        backgroundColor: AppColors.primaryGreen,
      ),
    );

    Navigator.pop(context);
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