import 'package:flutter/material.dart';
import '../models/bible_verse.dart';
import '../utils/colors.dart';

class BibleVerseCard extends StatefulWidget {
  final BibleVerse verse;
  final bool isBookmarked;
  final VoidCallback? onBookmark;

  const BibleVerseCard({
    super.key,
    required this.verse,
    this.isBookmarked = false,
    this.onBookmark,
  });

  @override
  _BibleVerseCardState createState() => _BibleVerseCardState();
}

class _BibleVerseCardState extends State<BibleVerseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bookmarkController;
  late Animation<double> _bookmarkAnimation;

  @override
  void initState() {
    super.initState();
    _bookmarkController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _bookmarkAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _bookmarkController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _bookmarkController.dispose();
    super.dispose();
  }

  void _toggleBookmark() {
    _bookmarkController.forward().then((_) {
      _bookmarkController.reverse();
    });
    if (widget.onBookmark != null) {
      widget.onBookmark!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.verse.reference,
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: _toggleBookmark,
                child: ScaleTransition(
                  scale: _bookmarkAnimation,
                  child: Icon(
                    widget.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: widget.isBookmarked ? AppColors.primaryBlue : AppColors.grey,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            widget.verse.text,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.darkGrey,
              height: 1.6,
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
    );
  }
}