import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/translation_service.dart';

// Invite Header Widget
class InviteHeaderWidget extends StatelessWidget {
  final VoidCallback onBackPressed;

  const InviteHeaderWidget({super.key, required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    final translationService = TranslationService.instance;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onBackPressed();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios, size: 20, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(
                    translationService.translate('invite.screen.back'),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(
            delay: const Duration(milliseconds: 400),
            duration: const Duration(milliseconds: 400),
          ),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Text(
              'Invite & Earn',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181F30),
              ),
            ).animate().fadeIn(
              delay: const Duration(milliseconds: 500),
              duration: const Duration(milliseconds: 400),
            ),
          ),
        ],
      ),
    );
  }
}
