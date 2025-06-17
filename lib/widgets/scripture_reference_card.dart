import 'package:flutter/material.dart';
import '../utils/colors.dart';

class ScriptureReferenceCard extends StatelessWidget {
  final String reference;
  final VoidCallback? onTap;

  const ScriptureReferenceCard({
    super.key,
    required this.reference,
    this.onTap,
  });

  Color _getRandomColor() {
    final colors = [
      AppColors.primaryBlue,
      AppColors.primaryGreen,
      AppColors.purple,
      Color(0xFFFF9800),
    ];
    return colors[reference.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _getRandomColor();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 8),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)), 
        ),
        child: Text(
          reference,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}