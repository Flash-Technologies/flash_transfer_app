import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/notification_model.dart';

class NotificationCardWidget extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;

  const NotificationCardWidget({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: notification.isRead 
              ? null 
              : Border.all(color: Colors.blue.shade100, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon based on type
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getNotificationTypeColor(notification.type).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationTypeIcon(notification.type),
                  color: _getNotificationTypeColor(notification.type),
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and unread indicator
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead 
                                  ? FontWeight.w600 
                                  : FontWeight.w700,
                              color: const Color(0xFF181F30),
                            ),
                          ),
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2475FF),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Message
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: notification.isRead 
                            ? const Color(0xFF6E757D)
                            : const Color(0xFF4A5568),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Time and actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Time ago
                        Text(
                          _formatTimeAgo(notification.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        // Mark as read button (only show for unread notifications)
                        if (!notification.isRead && onMarkAsRead != null)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onMarkAsRead!();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2475FF).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Mark as read',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF2475FF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'TRANSACTION':
        return const Color(0xFF10B981); // Green
      case 'SECURITY':
        return const Color(0xFFEF4444); // Red
      case 'SYSTEM':
        return const Color(0xFF3B82F6); // Blue
      case 'PROMOTION':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  IconData _getNotificationTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'TRANSACTION':
        return Icons.account_balance_wallet_outlined;
      case 'SECURITY':
        return Icons.security_outlined;
      case 'SYSTEM':
        return Icons.settings_outlined;
      case 'PROMOTION':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return months == 1 ? '1 month ago' : '$months months ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return years == 1 ? '1 year ago' : '$years years ago';
      }
    } else if (difference.inHours > 0) {
      return difference.inHours == 1 
          ? '1 hour ago' 
          : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1 
          ? '1 minute ago' 
          : '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}