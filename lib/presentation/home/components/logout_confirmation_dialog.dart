import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flash_transfer_app/presentation/common/app_button.dart';
import 'package:flash_transfer_app/config/constants.dart';

class LogoutConfirmationDialog extends StatefulWidget {
  const LogoutConfirmationDialog({super.key});

  @override
  State<LogoutConfirmationDialog> createState() => _LogoutConfirmationDialogState();
}

class _LogoutConfirmationDialogState extends State<LogoutConfirmationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Log Out',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Are you sure you want to log out of your account?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  height: 1.4,
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        text: 'Cancel',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop(false);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton.destructive(
                        text: 'Log Out',
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}