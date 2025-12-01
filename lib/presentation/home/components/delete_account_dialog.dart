import 'package:flutter/material.dart';
import 'package:flash_transfer_app/config/constants.dart';
import 'package:flash_transfer_app/presentation/common/app_button.dart';

class DeleteAccountDialog extends StatefulWidget {
  final String title;
  final String warning;
  final String securityVerification;
  final String confirmButton;
  final String cancelButton;
  final String deletingLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isLoading;

  const DeleteAccountDialog({
    super.key,
    required this.title,
    required this.warning,
    required this.securityVerification,
    required this.confirmButton,
    required this.cancelButton,
    required this.deletingLabel,
    required this.onConfirm,
    required this.onCancel,
    this.isLoading = false,
  }) : super();

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_forever,
                      color: Theme.of(context).colorScheme.error,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingLarge),

                  // Title
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.error,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),

                  // Warning box
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: Theme.of(context).colorScheme.error,
                          size: 24,
                        ),
                        const SizedBox(width: AppSizes.spacingMedium),
                        Expanded(
                          child: Text(
                            widget.warning,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.8),
                                  height: 1.5,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingLarge),

                  // Security verification section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.securityVerification,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: AppSizes.spacingSmall),
                      // Simple confirmation - with animation
                      _buildConfirmationAnimation(),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingXLarge),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.secondary(
                          text: widget.cancelButton,
                          onPressed: widget.isLoading ? () {} : widget.onCancel,
                          isLoading: false,
                          isDisabled: widget.isLoading,
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingMedium),
                      Expanded(
                        child: AppButton.destructive(
                          text: widget.isLoading ? widget.deletingLabel : widget.confirmButton,
                          onPressed: widget.isLoading ? () {} : widget.onConfirm,
                          isLoading: widget.isLoading,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationAnimation() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.paddingMedium,
        horizontal: AppSizes.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: AppSizes.spacingSmall),
          Expanded(
            child: Text(
              'This action cannot be reversed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
