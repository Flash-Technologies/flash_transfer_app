import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flash_transfer_app/config/constants.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;
  final double? width;
  final IconData? icon;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final BoxBorder? border;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.textColor,
    this.height = 56.0,
    this.width,
    this.icon,
    this.borderRadius,
    this.padding,
    this.border,
  });

  // Primary button
  factory AppButton.primary({
    Key? key,
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isDisabled = false,
    double height = 56.0,
    double? width,
    IconData? icon,
    EdgeInsets? padding,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      backgroundColor: AppColors.primary,
      textColor: Colors.black,
      height: height,
      width: width,
      icon: icon,
      padding: padding,
    );
  }

  // Secondary button
  factory AppButton.secondary({
    Key? key,
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isDisabled = false,
    double height = 56.0,
    double? width,
    IconData? icon,
    EdgeInsets? padding,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      backgroundColor: Colors.transparent,
      textColor: Colors.black,
      height: height,
      width: width,
      icon: icon,
      padding: padding,
      border: Border.all(color: Colors.grey.shade300, width: 1),
    );
  }

  // Destructive button
  factory AppButton.destructive({
    Key? key,
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isDisabled = false,
    double height = 56.0,
    double? width,
    IconData? icon,
    EdgeInsets? padding,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      backgroundColor: AppColors.error,
      textColor: Colors.white,
      height: height,
      width: width,
      icon: icon,
      padding: padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isButtonDisabled = isDisabled || isLoading;

    return GestureDetector(
      onTap:
          isButtonDisabled
              ? null
              : () {
                HapticFeedback.mediumImpact();
                onPressed();
              },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color:
              isButtonDisabled
                  ? (backgroundColor ?? Theme.of(context).primaryColor)
                      .withOpacity(0.6)
                  : backgroundColor ?? Theme.of(context).primaryColor,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          border: border,
          boxShadow:
              backgroundColor != Colors.transparent && !isButtonDisabled
                  ? [
                    BoxShadow(
                      color: (backgroundColor ?? Theme.of(context).primaryColor)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isButtonDisabled ? null : onPressed,
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            child: Padding(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child:
                    isLoading
                        ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              textColor ?? Colors.white,
                            ),
                          ),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (icon != null) ...[
                              Icon(
                                icon,
                                color: textColor ?? Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              text,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor ?? Colors.white,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
