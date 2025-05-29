import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';

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

class NotificationModal extends StatefulWidget {
  final List<NotificationItem> notifications;
  final VoidCallback onClose;

  const NotificationModal({
    Key? key,
    required this.notifications,
    required this.onClose,
  }) : super(key: key);

  @override
  State<NotificationModal> createState() => _NotificationModalState();
}

class _NotificationModalState extends State<NotificationModal>
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                color: Colors.black.withOpacity(0.5),
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
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    _buildNotificationsList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingL),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: AppSpacing.marginM),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Expanded(
            child: Column(
              children: [
                SizedBox(height: AppSpacing.marginM),
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
                        if (widget.notifications.any((n) => !n.isRead))
                          TextButton(
                            onPressed: _markAllAsRead,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.paddingS,
                                vertical: AppSpacing.paddingXS,
                              ),
                            ),
                            child: Text(
                              'Mark all as read',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primaryBlue,
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
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (widget.notifications.isEmpty) {
      return _buildEmptyState();
    }

    return Flexible(
      child: ListView.builder(
        padding: EdgeInsets.all(AppSpacing.paddingM),
        physics: const BouncingScrollPhysics(),
        itemCount: widget.notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationItem(
            widget.notifications[index],
            index,
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification, int index) {
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
                  : AppColors.primaryBlue.withOpacity(0.02),
              borderRadius: BorderRadius.circular(AppRadius.radiusL),
              border: Border.all(
                color: notification.isRead 
                    ? AppColors.border.withOpacity(0.5)
                    : AppColors.primaryBlue.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
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
                    color: notification.iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.iconColor,
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
                              notification.action,
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
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      
                      SizedBox(height: AppSpacing.marginXS),
                      
                      Text(
                        notification.description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      if (notification.timestamp != null) ...[
                        SizedBox(height: AppSpacing.marginXS),
                        Text(
                          _formatTimestamp(notification.timestamp!),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
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
            color: AppColors.textSecondary.withOpacity(0.5),
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
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationItem notification, int index) {
    HapticFeedback.selectionClick();
    // Handle notification tap - could navigate or show details
    // For now, just mark as read if not already
    if (!notification.isRead) {
      // In a real app, you'd update the notification state
      // For now, just provide haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  void _markAllAsRead() {
    HapticFeedback.mediumImpact();
    // In a real app, you'd update all notifications to read status
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusM),
        ),
      ),
    );
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