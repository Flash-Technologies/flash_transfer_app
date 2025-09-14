import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';
import '../../core/models/notification_model.dart';
import '../../providers/notification_provider.dart';

class NotificationItem {
  final String action;
  final String description;
  final IconData icon;
  final Color iconColor;
  final DateTime? timestamp;
  final bool isRead;

  NotificationItem({
    required this.action,
    required this.description,
    required this.icon,
    this.iconColor = Colors.grey,
    this.timestamp,
    this.isRead = false,
  });
}

class NotificationModal extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const NotificationModal({
    super.key,
    required this.onClose,
  });

  @override
  ConsumerState<NotificationModal> createState() => _NotificationModalState();
}

class _NotificationModalState extends ConsumerState<NotificationModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimations.normalAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppAnimations.standardCurve,
    ));

    _animationController.forward();
    
    // Load notifications when modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).fetchNotifications();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);
    
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Backdrop
          FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: _closeModal,
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),

          // Modal Content
          SlideTransition(
            position: _slideAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                margin: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 50,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.radiusXL),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(notificationState),
                    _buildNotificationsList(notificationState),
                    _buildSeeAllButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(NotificationState notificationState) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingL),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: AppSpacing.marginM),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications',
                style: AppTextStyles.heading3,
              ),
              
              Row(
                children: [
                  // Mark all as read button
                  if (notificationState.notifications.any((n) => !n.isRead))
                    TextButton(
                      onPressed: () => _markAllAsRead(notificationState),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.paddingS,
                          vertical: AppSpacing.paddingXS,
                        ),
                      ),
                      child: Text(
                        'Mark all as read',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFFFFC000),
                        ),
                      ),
                    ),
                  
                  // Close button
                  IconButton(
                    onPressed: _closeModal,
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.iconBackground,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(NotificationState notificationState) {
    if (notificationState.isLoading && notificationState.notifications.isEmpty) {
      return _buildLoadingState();
    }
    
    if (notificationState.notifications.isEmpty) {
      return _buildEmptyState();
    }

    // Show only top 10 notifications in modal
    final displayNotifications = notificationState.notifications.take(10).toList();

    return Flexible(
      child: ListView.builder(
        padding: EdgeInsets.all(AppSpacing.paddingM),
        physics: const ClampingScrollPhysics(),
        itemCount: displayNotifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationItem(
            displayNotifications[index],
            index,
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, int index) {
    Color iconColor = _getNotificationTypeColor(notification.type);
    IconData iconData = _getNotificationTypeIcon(notification.type);
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.marginM),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification, index),
          borderRadius: BorderRadius.circular(AppRadius.radiusL),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.paddingM),
            decoration: BoxDecoration(
              color: notification.isRead 
                  ? AppColors.cardBackground 
                  : const Color(0xFFFFC000).withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(AppRadius.radiusL),
              border: Border.all(
                color: notification.isRead 
                    ? AppColors.border.withValues(alpha: 0.5)
                    : const Color(0xFFFFC000).withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                
                SizedBox(width: AppSpacing.marginM),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: notification.isRead 
                                    ? FontWeight.w500 
                                    : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC000),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      
                      SizedBox(height: AppSpacing.marginXS),
                      
                      Text(
                        notification.message,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: AppSpacing.marginXS),
                      Text(
                        _formatTimestamp(notification.createdAt),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(
      duration: AppAnimations.normalAnimation,
      delay: Duration(milliseconds: 50 * index),
    ).slideX(
      begin: 0.1,
      end: 0,
      curve: AppAnimations.standardCurve,
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          SizedBox(height: AppSpacing.marginL),
          Text(
            'No notifications yet',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.marginS),
          Text(
            'You\'ll see important updates and alerts here',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingXL),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFFC000),
        ),
      ),
    );
  }

  Widget _buildSeeAllButton() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingM),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // Navigate to full notification screen
            _closeModal();
            context.push('/notification');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC000),
            foregroundColor: const Color(0xFF181F30),
            padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingM),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusM),
            ),
          ),
          child: Text(
            'See All Notifications',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
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

  void _handleNotificationTap(NotificationModel notification, int index) {
    HapticFeedback.selectionClick();
    // Mark as read if not already
    if (!notification.isRead) {
      ref.read(notificationProvider.notifier).markAsRead(notification.id);
    }
  }

  void _markAllAsRead(NotificationState notificationState) {
    HapticFeedback.mediumImpact();
    ref.read(notificationProvider.notifier).markAllAsRead();
  }

  void _closeModal() {
    HapticFeedback.lightImpact();
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}