import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flash_transfer_app/config/theme.dart';

class NotificationItem {
  final String action;
  final String description;
  final IconData icon;
  final Color? iconColor;
  
  NotificationItem({
    required this.action,
    required this.description,
    required this.icon,
    this.iconColor,
  });
}

class NotificationModal extends StatelessWidget {
  final List<NotificationItem> notifications;
  final VoidCallback onClose;
  
  const NotificationModal({
    Key? key,
    required this.notifications,
    required this.onClose,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: GestureDetector(
        onTap: onClose,
        child: Stack(
          children: [
            // Modal background tap area
            Positioned.fill(
              child: GestureDetector(
                onTap: onClose,
                child: Container(color: Colors.transparent),
              ),
            ),
            
            // Modal content
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {}, // Prevents tap through
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF0F1),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Notifications",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          InkWell(
                            onTap: onClose,
                            borderRadius: BorderRadius.circular(16),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Text(
                                "X",
                                style: TextStyle(
                                  color: Color(0xFF6E757D),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const Divider(height: 32),
                      
                      // Notification list
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 450),
                        child: SingleChildScrollView(
                          child: Column(
                            children: List.generate(
                              notifications.length,
                              (index) => _buildNotificationItem(
                                notifications[index],
                                index,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().slideY(
              begin: 1,
              end: 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuad,
            ).fadeIn(
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotificationItem(NotificationItem notification, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                notification.icon,
                size: 20,
                color: notification.iconColor ?? Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.action,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF181F30),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6E757D),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate(
        delay: Duration(milliseconds: 50 * index),
      ).fadeIn(
        duration: const Duration(milliseconds: 200),
      ).slideY(
        begin: 0.1,
        end: 0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutQuad,
      ),
    );
  }
}