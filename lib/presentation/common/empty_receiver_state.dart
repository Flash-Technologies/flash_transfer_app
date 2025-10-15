import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';
import '../../providers/language_provider.dart';

class EmptyReceiverState extends ConsumerWidget {
  final VoidCallback? onSelectReceiver;
  
  const EmptyReceiverState({
    Key? key,
    this.onSelectReceiver,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationHelperProvider);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.paddingXL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            AppColors.background.withOpacity(0.5),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(AppRadius.radiusL),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_add_outlined,
              size: 40,
              color: AppColors.primaryBlue,
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              duration: 2.seconds,
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.1, 1.1),
              curve: Curves.easeInOut,
            ),
          
          SizedBox(height: AppSpacing.marginL),
          
          Text(
            tr('common.empty.receiver.title'),
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ).animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideY(begin: 0.1, end: 0),
          
          SizedBox(height: AppSpacing.marginS),
          
          Text(
            tr('common.empty.receiver.subtitle'),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ).animate()
            .fadeIn(delay: 400.ms, duration: 600.ms)
            .slideY(begin: 0.1, end: 0),
          
          if (onSelectReceiver != null) ...[
            SizedBox(height: AppSpacing.marginL),
            
            ElevatedButton.icon(
              onPressed: onSelectReceiver,
              icon: Icon(
                Icons.person_search,
                size: 20,
                color: Colors.white,
              ),
              label: Text(
                tr('common.empty.receiver.selectButton'),
                style: AppTextStyles.buttonMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.paddingL,
                  vertical: AppSpacing.paddingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
                ),
              ),
            ).animate()
              .fadeIn(delay: 600.ms, duration: 600.ms)
              .slideY(begin: 0.1, end: 0)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
          ],
        ],
      ),
    );
  }
}