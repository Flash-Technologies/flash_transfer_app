import 'package:flash_transfer_app/presentation/common/icons/lottie_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';
import 'package:flash_transfer_app/presentation/common/icons/payment_icons.dart';
import 'package:flash_transfer_app/presentation/home/components/receipts_section.dart';

class CashScreen extends StatefulWidget {
  const CashScreen({Key? key}) : super(key: key);

  @override
  State<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends State<CashScreen> {
  String activePay = 'cash';
  String activeReceive = 'cash';
  bool showNotifications = false;

  // Sample notifications data
  final List<Map<String, dynamic>> notifications = [
    {
      'action': 'Payment sent!',
      'desc': 'your payment #1234 has been sent',
      'icon': Icons.done,
      'isSuccess': true,
    },
    {
      'action': 'Payment Failed!',
      'desc': 'your payment #1234 has failed',
      'icon': Icons.clear,
      'isSuccess': false,
    },
    {
      'action': 'Payment sent!',
      'desc': 'your payment #1234 has been sent',
      'icon': Icons.done,
      'isSuccess': true,
    },
    {
      'action': 'Payment Failed!',
      'desc': 'your payment #1234 has failed',
      'icon': Icons.clear,
      'isSuccess': false,
    },
    {
      'action': 'Invite friend',
      'desc': 'Registration confirmed via affiliate link',
      'icon': Icons.group,
      'isSuccess': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildBackButton(),
                  _buildPaymentMethodSection(),
                  _buildReceiverMethodSection(),
                  _buildActionButtons(),
                  const ReceiptsSection(),
                ],
              ),
            ),
          ),
        ),
        if (showNotifications) _buildNotificationModal(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.paddingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildIconButton(
            icon: Icons.menu,
            onTap: () => context.push('/profile'),
          ),
          _buildIconButton(
            icon: Icons.notifications_none_rounded,
            onTap: () => setState(() => showNotifications = true),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppAnimations.normalAnimation);
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radiusCircular),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.paddingM),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 24),
        ),
      ),
    ).animate().scale(
      duration: AppAnimations.quickAnimation,
      curve: AppAnimations.emphasizedCurve,
      begin: const Offset(0.95, 0.95),
      end: const Offset(1.0, 1.0),
    );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () => context.push('/home'),
      borderRadius: BorderRadius.circular(AppRadius.radiusM),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingM),
        child: Row(
          children: [
            Image.asset('assets/images/back2.png', width: 40, height: 40),
            SizedBox(width: AppSpacing.marginS),
            Text(
              'Back',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How would you like to pay?', style: AppTextStyles.heading3),
        SizedBox(height: AppSpacing.marginM),

        // First row of payment methods
        Row(
          children: [
            Expanded(
              child: _buildPaymentOption(title: 'Cash Payment', value: 'cash'),
            ),
            SizedBox(width: AppSpacing.marginM),
            Expanded(
              child: _buildPaymentOption(
                title: 'Crypto Wallet',
                value: 'wallet',
              ),
            ),
          ],
        ),

        SizedBox(height: AppSpacing.marginM),

        Row(
          children: [
            Expanded(
              child: _buildPaymentOption(title: 'Credit Card', value: 'card'),
            ),
            SizedBox(width: AppSpacing.marginM),
            Expanded(
              child: _buildPaymentOption(title: 'Bank Transfer', value: 'bank'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentOption({required String title, required String value}) {
    final bool isActive = activePay == value;

    return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => activePay = value);
            },
            borderRadius: BorderRadius.circular(AppRadius.radiusL),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.radiusL),
                border: Border.all(
                  color: isActive ? AppColors.primaryBlue : Colors.transparent,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        isActive
                            ? AppColors.primaryBlue.withOpacity(0.2)
                            : Colors.black.withOpacity(0.05),
                    blurRadius: isActive ? 8 : 4,
                    offset: const Offset(0, 2),
                    spreadRadius: isActive ? 1 : 0,
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.paddingM,
                vertical: AppSpacing.paddingM,
              ),
              child: Row(
                children: [
                  // Lottie animation container
                  Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? AppColors.primaryBlue.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _getLottieAnimationForPayment(value, isActive),
                    ),
                  ),
                  SizedBox(width: AppSpacing.marginM),
                  // Title text
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color:
                            isActive
                                ? AppColors.primaryBlue
                                : AppColors.textPrimary,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Selection indicator
                  if (isActive)
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
        )
        .animate(target: isActive ? 1 : 0)
        .scale(
          duration: AppAnimations.quickAnimation,
          curve: AppAnimations.emphasizedCurve,
          begin: const Offset(0.97, 0.97),
          end: const Offset(1.0, 1.0),
        );
  }

  Widget _getLottieAnimationForPayment(String value, bool isActive) {
    double size = 40;

    switch (value) {
      case 'cash':
        return LottieAnimations.cashAnimation(
          width: 78,
          height: 78,
          repeat: true,
          animate: true,
        );
      case 'wallet':
        return LottieAnimations.walletAnimation(
          width: size,
          height: size,
          repeat: true,
          animate: true,
        );
      case 'card':
        return LottieAnimations.creditCardAnimation(
          width: size,
          height: size,
          repeat: true,
          animate: true,
        );
      case 'bank':
        return LottieAnimations.bankAnimation(
          width: size,
          height: size,
          repeat: true,
          animate: true,
        );
      default:
        return LottieAnimations.cashAnimation(
          width: size,
          height: size,
          repeat: true,
          animate: true,
        );
    }
  }

  Widget _buildReceiverMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSpacing.marginL),
        Text(
          'How does your receiver want money?',
          style: AppTextStyles.heading3,
        ),
        SizedBox(height: AppSpacing.marginM),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildReceiverOption(title: 'Cash\nPickup', value: 'cash'),
            _buildReceiverOption(title: 'Crypto\nWallet', value: 'wallet'),
            _buildReceiverOption(title: 'Mobile\nMoney', value: 'mobile'),
          ],
        ),
      ],
    );
  }

  Widget _buildReceiverOption({required String title, required String value}) {
    final bool isActive = activeReceive == value;
    final double width =
        (MediaQuery.of(context).size.width - (AppSpacing.paddingM * 4)) / 3;

    return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => activeReceive = value);
            },
            borderRadius: BorderRadius.circular(AppRadius.radiusL),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: width,
              padding: EdgeInsets.all(AppSpacing.paddingM),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.radiusL),
                border: Border.all(
                  color: isActive ? AppColors.primaryBlue : Colors.transparent,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        isActive
                            ? AppColors.primaryBlue.withOpacity(0.2)
                            : Colors.black.withOpacity(0.05),
                    blurRadius: isActive ? 8 : 4,
                    offset: const Offset(0, 2),
                    spreadRadius: isActive ? 1 : 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 65,
                    width: 65,
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? AppColors.primaryBlue.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _getLottieAnimationForReceiver(value, isActive),
                    ),
                  ),
                  SizedBox(height: AppSpacing.marginS),
                  // Title text
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color:
                          isActive
                              ? AppColors.primaryBlue
                              : AppColors.textPrimary,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(target: isActive ? 1 : 0)
        .scale(
          duration: AppAnimations.quickAnimation,
          curve: AppAnimations.emphasizedCurve,
          begin: const Offset(0.97, 0.97),
          end: const Offset(1.0, 1.0),
        );
  }

  Widget _getLottieAnimationForReceiver(String value, bool isActive) {
    double size = 48;

    switch (value) {
      case 'cash':
        return LottieAnimations.cashAnimation(
          width: 78,
          height: 78,
          repeat: true,
          animate: true,
        );
      case 'wallet':
        return LottieAnimations.walletAnimation(
          width: size,
          height: size,
          repeat: true,
          animate: true,
        );
      case 'mobile':
        return LottieAnimations.phoneAnimation(
          width: size,
          height: size,
          repeat: true,
          animate: true,
        );
      default:
        return LottieAnimations.cashAnimation(
          width: size,
          height: size,
          repeat: true,
          animate: true,
        );
    }
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(height: AppSpacing.marginL),

        // Add New button
        ElevatedButton(
              onPressed: () => context.push('/add-new'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
                ),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: Text('Add New', style: AppTextStyles.buttonMedium),
            )
            .animate()
            .fadeIn(duration: AppAnimations.normalAnimation)
            .slideY(
              begin: 0.2,
              end: 0,
              duration: AppAnimations.normalAnimation,
              curve: AppAnimations.standardCurve,
            ),

        SizedBox(height: AppSpacing.marginM),

        // Add From Contact button
        OutlinedButton(
              onPressed: () => context.push('/cash'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: BorderSide(color: AppColors.primaryBlue),
                padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
                ),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: Text(
                'Add From Contact',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            )
            .animate()
            .fadeIn(duration: AppAnimations.normalAnimation)
            .slideY(
              begin: 0.2,
              end: 0,
              duration: AppAnimations.normalAnimation,
              curve: AppAnimations.standardCurve,
              delay: Duration(milliseconds: 50),
            ),
      ],
    );
  }

  Widget _buildNotificationModal() {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Modal Backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => showNotifications = false),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),

          // Modal Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(AppSpacing.paddingL),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.radiusXL),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Notifications', style: AppTextStyles.heading3),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed:
                            () => setState(() => showNotifications = false),
                      ),
                    ],
                  ),

                  Divider(color: AppColors.border),
                  SizedBox(height: AppSpacing.marginM),

                  // Notifications list
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationItem(
                          notification: notification,
                          index: index,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ).animate().slide(
            begin: const Offset(0, 1),
            end: const Offset(0, 0),
            duration: AppAnimations.normalAnimation,
            curve: AppAnimations.standardCurve,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required Map<String, dynamic> notification,
    required int index,
  }) {
    return Container(
          margin: EdgeInsets.only(bottom: AppSpacing.marginM),
          padding: EdgeInsets.all(AppSpacing.paddingM),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppRadius.radiusL),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification['icon'],
                  color:
                      notification['isSuccess']
                          ? AppColors.success
                          : AppColors.error,
                  size: 20,
                ),
              ),
              SizedBox(width: AppSpacing.marginM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['action'],
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.marginXS),
                    Text(
                      notification['desc'],
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: index * 50),
          duration: AppAnimations.normalAnimation,
        )
        .slideY(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: index * 50),
          duration: AppAnimations.normalAnimation,
          curve: AppAnimations.standardCurve,
        );
  }
}
