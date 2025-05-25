import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/translation_service.dart';

class ShareOptionsWidget extends StatelessWidget {
  final String referralCode;
  final String referralLink;
  final Function(String type, String content) onShare;

  const ShareOptionsWidget({
    super.key,
    required this.referralCode,
    required this.referralLink,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share Your Code',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181F30),
            ),
          ),

          const SizedBox(height: 16),

          // Referral Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Referral Code',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6E757D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        referralCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF181F30),
                        ),
                      ),
                    ],
                  ),
                ),

                GestureDetector(
                  onTap: () => onShare('copy_code', referralCode),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2475FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.copy,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ).animate().scale(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.elasticOut,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick Share Buttons
          const Text(
            'Quick Share',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF181F30),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareButton(
                'WhatsApp',
                Icons.chat,
                const Color(0xFF25D366),
                () => onShare('whatsapp', referralCode),
              ),
              _buildShareButton(
                'SMS',
                Icons.sms,
                const Color(0xFF2475FF),
                () => onShare('sms', referralCode),
              ),
              _buildShareButton(
                'Email',
                Icons.email,
                const Color(0xFFFF6B35),
                () => onShare('email', referralCode),
              ),
              _buildShareButton(
                'Copy Link',
                Icons.link,
                const Color(0xFF6E757D),
                () => onShare('copy_link', referralLink),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),

          const SizedBox(height: 8),

          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF181F30),
            ),
          ),
        ],
      ),
    ).animate().scale(
      delay: Duration(
        milliseconds:
            100 * ['WhatsApp', 'SMS', 'Email', 'Copy Link'].indexOf(label),
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
    );
  }
}
