import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flash_transfer_app/config/theme.dart';
import 'package:flash_transfer_app/core/models/user.dart';

class UserDetailCard extends StatelessWidget {
  final String title;
  final User user;
  final bool showKycBadge;
  final VoidCallback? onEdit;

  const UserDetailCard({
    Key? key,
    required this.title,
    required this.user,
    required this.showKycBadge,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Title and Edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF273240),
                ),
              ),
              if (onEdit != null)
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    "Edit",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Divider
          const Divider(height: 1, color: Color(0xFFEBECED)),

          // User details
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              children: [
                // User avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFC000),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getFirstLetter(user),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF181F30),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // User info
                Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.firstName ?? ''} ${user.lastName ?? ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDarkColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.countryName ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6A6A6A),
                  ),
                ),
              ],
            ),
                ),
                // KYC badge (if applicable)
                if (showKycBadge)
                  Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C735),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "KYC",
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      )
                      .animate(
                        onPlay:
                            (controller) => controller.repeat(reverse: true),
                      )
                      .tint(
                        color: Colors.white.withOpacity(0.3),
                        duration: 1.seconds,
                        curve: Curves.easeInOut,
                      ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1, color: Color(0xFFEBECED)),
        ],
      ),
    );
  }

  String _getFirstLetter(User user) {
    final fullName = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    if (fullName.isNotEmpty) {
      return fullName[0].toUpperCase();
    }
    return '?';
  }
}
