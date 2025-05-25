import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/translation_service.dart';

class ReadingProgressWidget extends StatelessWidget {
  final double progress;
  final int currentSection;
  final int totalSections;
  final Function(int) onSectionTap;

  const ReadingProgressWidget({
    super.key,
    required this.progress,
    required this.currentSection,
    required this.totalSections,
    required this.onSectionTap,
  });

  @override
  Widget build(BuildContext context) {
    final translationService = TranslationService.instance;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Progress info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                translationService.translate('privacy.screen.readingProgress'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF181F30),
                ),
              ),

              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2475FF),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2475FF),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ).animate().scale(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),

          const SizedBox(height: 8),

          // Section indicator
          if (totalSections > 0)
            Text(
              'Section ${currentSection + 1} of $totalSections',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6E757D)),
            ),
        ],
      ),
    );
  }
}
