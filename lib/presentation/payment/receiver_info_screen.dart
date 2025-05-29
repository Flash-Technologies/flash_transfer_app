// lib/presentation/payment/receiver_info_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';
import 'package:flash_transfer_app/core/models/beneficiary.dart';
import 'package:flash_transfer_app/providers/beneficiary_provider.dart';
import 'package:flash_transfer_app/providers/exchange_provider.dart';
import 'package:flash_transfer_app/presentation/common/app_button.dart';
import 'package:flash_transfer_app/presentation/common/empty_receiver_state.dart';

class ReceiverInfoScreen extends ConsumerStatefulWidget {
  final Beneficiary? selectedBeneficiary;

  const ReceiverInfoScreen({
    Key? key,
    this.selectedBeneficiary,
  }) : super(key: key);

  @override
  ConsumerState<ReceiverInfoScreen> createState() => _ReceiverInfoScreenState();
}

class _ReceiverInfoScreenState extends ConsumerState<ReceiverInfoScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseController.repeat(reverse: true);
    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedBeneficiary =
        widget.selectedBeneficiary ?? ref.watch(selectedBeneficiaryProvider);
    final exchangeForm = ref.watch(exchangeFormProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(AppSpacing.paddingM),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(),
                      SizedBox(height: AppSpacing.marginL),
                      _buildBeneficiaryCard(selectedBeneficiary),
                      SizedBox(height: AppSpacing.marginL),
                      _buildTransactionDetails(exchangeForm),
                      SizedBox(height: AppSpacing.marginXL),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.paddingM,
        AppSpacing.paddingL,
        AppSpacing.paddingM,
        AppSpacing.paddingL,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Progress Circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 4),
            ),
            child: Stack(
              children: [
                // Progress arc
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: 0.25, // 1/4 progress
                    strokeWidth: 4,
                    backgroundColor: Colors.transparent,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                  ),
                ),
                // Center text
                Center(
                  child: Text(
                    '1/4',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: AppSpacing.marginM),

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Receiver's Info",
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSpacing.marginXS),
                Text(
                  'Review receiver details',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppAnimations.normalAnimation)
        .slideY(begin: -0.1, end: 0, duration: AppAnimations.normalAnimation);
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Receiver's Information",
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.marginS),
        Text(
          'Review all the details of your transaction. Make sure everything is correct before proceeding.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: AppAnimations.normalAnimation, delay: 200.ms)
        .slideY(begin: 0.1, end: 0, duration: AppAnimations.normalAnimation);
  }

  Widget _buildBeneficiaryCard(Beneficiary? beneficiary) {
    if (beneficiary == null) {
      return EmptyReceiverState(
        onSelectReceiver: () => context.pop(),
      )
          .animate()
          .fadeIn(duration: AppAnimations.normalAnimation, delay: 400.ms)
          .slideY(begin: 0.1, end: 0, duration: AppAnimations.normalAnimation)
          .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.paddingL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  AppColors.primaryBlue.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.radiusL),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // Receiver avatar and name
                Row(
                  children: [
                    Hero(
                      tag: 'receiver-avatar-${beneficiary.id}',
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryBlue,
                              AppColors.primaryBlue.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            beneficiary.firstName.isNotEmpty
                                ? beneficiary.firstName[0].toUpperCase()
                                : 'R',
                            style: AppTextStyles.heading2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.marginL),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            beneficiary.displayName,
                            style: AppTextStyles.heading3.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.marginXS),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: AppSpacing.marginXS),
                              Text(
                                '${beneficiary.city}, ${beneficiary.country}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.marginXS),
                          Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: AppSpacing.marginXS),
                              Expanded(
                                child: Text(
                                  beneficiary.email,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppSpacing.marginL),

                // Receiver details
                Container(
                  padding: EdgeInsets.all(AppSpacing.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppRadius.radiusM),
                    border: Border.all(
                      color: AppColors.border.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'Full Name',
                        beneficiary.displayName,
                        Icons.person_outline,
                      ),
                      SizedBox(height: AppSpacing.marginM),
                      _buildDetailRow(
                        'Mobile Number',
                        beneficiary.mobileNumber.isNotEmpty
                            ? beneficiary.mobileNumber
                            : 'Not provided',
                        Icons.phone_outlined,
                      ),
                      SizedBox(height: AppSpacing.marginM),
                      _buildDetailRow(
                        'Address',
                        beneficiary.fullAddress,
                        Icons.location_on_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    )
        .animate()
        .fadeIn(duration: AppAnimations.normalAnimation, delay: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: AppAnimations.normalAnimation)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.radiusS),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.primaryBlue,
          ),
        ),
        SizedBox(width: AppSpacing.marginM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppSpacing.marginXS),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionDetails(ExchangeFormState exchangeForm) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.radiusS),
                ),
                child: Icon(
                  Icons.swap_horiz,
                  color: AppColors.primaryYellow.withOpacity(0.8),
                  size: 20,
                ),
              ),
              SizedBox(width: AppSpacing.marginM),
              Text(
                'Transaction Details',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.marginL),

          // Currency and amounts
          Row(
            children: [
              Expanded(
                child: _buildTransactionCard(
                  'You Send',
                  exchangeForm.fromCurrency?.code ?? 'USD',
                  exchangeForm.sendAmount.isNotEmpty
                      ? exchangeForm.sendAmount
                      : '100.00',
                  AppColors.error.withOpacity(0.1),
                  AppColors.error,
                  Icons.north_east,
                ),
              ),

              SizedBox(width: AppSpacing.marginM),

              // Arrow
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),

              SizedBox(width: AppSpacing.marginM),

              Expanded(
                child: _buildTransactionCard(
                  'They Receive',
                  exchangeForm.toCurrency?.code ?? 'EUR',
                  exchangeForm.receiveAmount.isNotEmpty
                      ? exchangeForm.receiveAmount
                      : '85.50',
                  AppColors.success.withOpacity(0.1),
                  AppColors.success,
                  Icons.south_west,
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.marginL),

          // Exchange rate info
          Container(
            padding: EdgeInsets.all(AppSpacing.paddingM),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppRadius.radiusM),
              border: Border.all(
                color: AppColors.border.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                _buildExchangeInfoRow(
                  'Exchange Rate',
                  exchangeForm.exchangeRate != null
                      ? '1 ${exchangeForm.fromCurrency?.code} = ${exchangeForm.exchangeRate?.rate.toStringAsFixed(4)} ${exchangeForm.toCurrency?.code}'
                      : '1 USD = 0.855 EUR',
                ),
                SizedBox(height: AppSpacing.marginS),
                _buildExchangeInfoRow(
                  'Transfer Fee',
                  exchangeForm.calculation?.fee != null
                      ? '${exchangeForm.calculation?.fee} ${exchangeForm.calculation?.feeCurrency}'
                      : '2.50 USD',
                ),
                SizedBox(height: AppSpacing.marginS),
                _buildExchangeInfoRow(
                  'Total Cost',
                  exchangeForm.calculation?.totalAmount != null
                      ? '${exchangeForm.calculation?.totalAmount} ${exchangeForm.fromCurrency?.code}'
                      : '102.50 USD',
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppAnimations.normalAnimation, delay: 600.ms)
        .slideY(begin: 0.1, end: 0, duration: AppAnimations.normalAnimation)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildTransactionCard(
    String label,
    String currency,
    String amount,
    Color backgroundColor,
    Color accentColor,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingM),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusM),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: accentColor,
              ),
              SizedBox(width: AppSpacing.marginXS),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.marginS),
          Text(
            amount,
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.marginXS),
          Text(
            currency,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final selectedBeneficiary =
        widget.selectedBeneficiary ?? ref.watch(selectedBeneficiaryProvider);
    final isEnabled = selectedBeneficiary != null;

    return Column(
      children: [
        // Change Receiver button
        OutlinedButton.icon(
          onPressed: () {
            // Go back to select different receiver
            context.pop();
          },
          icon: Icon(
            Icons.swap_horiz,
            size: 20,
            color: AppColors.primaryBlue,
          ),
          label: Text(
            'Change Receiver',
            style: AppTextStyles.buttonMedium.copyWith(
              color: AppColors.primaryBlue,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryBlue,
            side: BorderSide(color: AppColors.primaryBlue),
            padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingM),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
            ),
            minimumSize: const Size(double.infinity, 56),
          ),
        )
            .animate()
            .fadeIn(duration: AppAnimations.normalAnimation, delay: 800.ms)
            .slideY(begin: 0.1, end: 0, duration: AppAnimations.normalAnimation)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

        SizedBox(height: AppSpacing.marginM),

        // Continue button
        ElevatedButton(
          onPressed: isEnabled
              ? () {
                  HapticFeedback.lightImpact();
                  context.push('/select-payment');
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isEnabled ? AppColors.primaryYellow : AppColors.iconBackground,
            foregroundColor:
                isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
            elevation: 0,
            padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingM),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
            ),
            minimumSize: const Size(double.infinity, 56),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isEnabled) ...[
                Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                SizedBox(width: AppSpacing.marginS),
              ],
              Text(
                isEnabled ? 'Continue' : 'Select a Receiver First',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: isEnabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: AppAnimations.normalAnimation, delay: 1000.ms)
            .slideY(begin: 0.1, end: 0, duration: AppAnimations.normalAnimation)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

        SizedBox(height: AppSpacing.marginM),

        // Cancel button
        TextButton(
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingM),
            minimumSize: const Size(double.infinity, 56),
          ),
          child: Text(
            'Cancel',
            style: AppTextStyles.buttonMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        )
            .animate()
            .fadeIn(duration: AppAnimations.normalAnimation, delay: 1100.ms)
            .slideY(
                begin: 0.1, end: 0, duration: AppAnimations.normalAnimation),
      ],
    );
  }
}
