import 'package:flash_transfer_app/core/models/beneficiary.dart';
import 'package:flash_transfer_app/presentation/common/icons/lottie_animations.dart';
import 'package:flash_transfer_app/presentation/common/select_contact_modal.dart';
import 'package:flash_transfer_app/providers/beneficiary_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';
import 'package:flash_transfer_app/presentation/common/icons/payment_icons.dart';
import 'package:flash_transfer_app/presentation/home/components/receipts_section.dart';
import 'package:flash_transfer_app/providers/exchange_provider.dart';

class CashScreen extends ConsumerStatefulWidget {
  const CashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends ConsumerState<CashScreen> {
  String activePay = 'cash';
  String activeReceive = 'cash';
  bool showNotifications = false;
  Beneficiary? selectedContact;

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
  void initState() {
    super.initState();
    // Initialize payment methods after the widget is built - FIXED
    Future.microtask(() => _initializePaymentMethods());
  }

  void _initializePaymentMethods() {
    if (!mounted) return;
    
    final exchangeForm = ref.read(exchangeFormProvider);
    final sendingCurrency = exchangeForm.fromCurrency;
    final receivingCurrency = exchangeForm.toCurrency;

    // Auto-set payment method based on sending currency
    if (sendingCurrency?.type == 'CRYPTO' && activePay != 'wallet') {
      setState(() => activePay = 'wallet');
    } else if (sendingCurrency?.type == 'FIAT' && activePay == 'wallet') {
      setState(() => activePay = 'cash'); // Default to cash for fiat
    }

    // Auto-set receiver method based on receiving currency
    if (receivingCurrency?.type == 'CRYPTO' && activeReceive != 'wallet') {
      setState(() => activeReceive = 'wallet');
    } else if (receivingCurrency?.type == 'FIAT' && activeReceive == 'wallet') {
      setState(() => activeReceive = 'cash'); // Default to cash for fiat
    }
  }

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
    final exchangeForm = ref.watch(exchangeFormProvider);
    final sendingCurrency = exchangeForm.fromCurrency;
    final isSendingCrypto = sendingCurrency?.type == 'CRYPTO';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('How would you like to pay?', style: AppTextStyles.heading3),
            if (sendingCurrency != null) ...[
              SizedBox(width: AppSpacing.marginS),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.paddingXS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSendingCrypto
                      ? const Color(0xFFE3F2FD)
                      : const Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.circular(AppRadius.radiusS),
                ),
                child: Text(
                  '${sendingCurrency.code} (${sendingCurrency.type})',
                  style: AppTextStyles.caption.copyWith(
                    color: isSendingCrypto
                        ? const Color(0xFF1976D2)
                        : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),

        // Helper text explaining validation rules
        if (sendingCurrency != null) ...[
          SizedBox(height: AppSpacing.marginXS),
          Text(
            isSendingCrypto
                ? 'Sending cryptocurrency requires a Crypto Wallet'
                : 'Sending fiat currency allows cash, card, bank, or mobile money',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],

        SizedBox(height: AppSpacing.marginM),

        SizedBox(
          height: MediaQuery.of(context).size.height * 0.25,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildPaymentOption(
                        title: 'Cash Payment',
                        value: 'cash',
                        isCompact: true,
                        isEnabled: !isSendingCrypto,
                      ),
                    ),
                    SizedBox(height: AppSpacing.marginS),
                    Expanded(
                      child: _buildPaymentOption(
                        title: 'Credit   Card  ',
                        value: 'card',
                        isCompact: true,
                        isEnabled: !isSendingCrypto,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.marginS),
              Expanded(
                flex: 2,
                child: _buildPaymentOption(
                  title: 'Crypto Wallet',
                  value: 'wallet',
                  isCenter: true,
                  isEnabled: isSendingCrypto,
                ),
              ),
              SizedBox(width: AppSpacing.marginS),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildPaymentOption(
                        title: 'Bank Transfer',
                        value: 'bank',
                        isCompact: true,
                        isEnabled: !isSendingCrypto,
                      ),
                    ),
                    SizedBox(height: AppSpacing.marginS),
                    Expanded(
                      child: _buildPaymentOption(
                        title: 'Mobile Money',
                        value: 'mobile',
                        isCompact: true,
                        isEnabled: !isSendingCrypto,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String value,
    bool isCompact = false,
    bool isCenter = false,
    bool isEnabled = true,
  }) {
    final bool isActive = activePay == value && isEnabled;
    final exchangeForm = ref.watch(exchangeFormProvider);
    final sendingCurrency = exchangeForm.fromCurrency;

    // FIXED: Removed provider modification during build
    // Auto-selection is now handled in initState

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled
            ? () {
                setState(() => activePay = value);
              }
            : null,
        borderRadius: BorderRadius.circular(AppRadius.radiusL),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isEnabled ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppRadius.radiusL),
            border: Border.all(
              color: isActive ? AppColors.primaryBlue : Colors.transparent,
              width: 0.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? AppColors.primaryBlue.withOpacity(0.2)
                    : Colors.black.withOpacity(isEnabled ? 0.05 : 0.02),
                blurRadius: isActive ? 8 : 4,
                offset: const Offset(0, 2),
                spreadRadius: isActive ? 1 : 0,
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? AppSpacing.paddingS : AppSpacing.paddingS,
            vertical: AppSpacing.paddingS,
          ),
          child: Stack(
            children: [
              Opacity(
                opacity: isEnabled ? 1.0 : 0.4,
                child: isCenter
                    ? _buildCenterCardContent(title, value, isActive)
                    : _buildCompactCardContent(
                        title, value, isActive, isCompact),
              ),
              if (!isEnabled)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.lock,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate(target: isActive ? 1 : 0).scale(
          duration: AppAnimations.quickAnimation,
          curve: AppAnimations.emphasizedCurve,
          begin: const Offset(0.97, 0.97),
          end: const Offset(1.0, 1.0),
        );
  }

  Widget _buildCenterCardContent(String title, String value, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Large Lottie animation for center card
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryBlue.withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: _getLottieAnimationForPayment(value, isActive),
          ),
        ),

        SizedBox(height: AppSpacing.marginM),

        // Title text
        Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            color: isActive ? AppColors.primaryBlue : AppColors.textPrimary,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        SizedBox(height: AppSpacing.marginS),

        // Selection indicator for center card
        if (isActive)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 14,
            ),
          ),
      ],
    );
  }

  Widget _buildCompactCardContent(
      String title, String value, bool isActive, bool isCompact) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Smaller Lottie animation for compact cards
        Container(
          height: isCompact ? 40 : 54,
          width: isCompact ? 40 : 54,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryBlue.withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: _getLottieAnimationForPayment(value, isActive),
          ),
        ),

        SizedBox(height: AppSpacing.marginS),

        // Title text
        Text(
          title,
          style: AppTextStyles.bodySmall.copyWith(
            color: isActive ? AppColors.primaryBlue : AppColors.textPrimary,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            fontSize: isCompact ? 12 : 14,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        SizedBox(height: AppSpacing.marginXS),

        // Selection indicator for compact cards
        if (isActive)
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 10,
            ),
          ),
      ],
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
    final exchangeForm = ref.watch(exchangeFormProvider);
    final sendingCurrency = exchangeForm.fromCurrency;
    final receivingCurrency = exchangeForm.toCurrency;
    final isSendingCrypto = sendingCurrency?.type == 'CRYPTO';
    final isReceivingCrypto = receivingCurrency?.type == 'CRYPTO';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSpacing.marginL),
        Row(
          children: [
            Text(
              'How should they receive it?',
              style: AppTextStyles.heading3,
            ),
            if (receivingCurrency != null) ...[
              SizedBox(width: AppSpacing.marginS),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.paddingXS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isReceivingCrypto
                      ? const Color(0xFFE3F2FD)
                      : const Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.circular(AppRadius.radiusS),
                ),
                child: Text(
                  '${receivingCurrency.code} (${receivingCurrency.type})',
                  style: AppTextStyles.caption.copyWith(
                    color: isReceivingCrypto
                        ? const Color(0xFF1976D2)
                        : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),

        // Helper text explaining validation rules
        if (receivingCurrency != null) ...[
          SizedBox(height: AppSpacing.marginXS),
          Text(
            isReceivingCrypto
                ? 'Receiving cryptocurrency requires a Crypto Wallet'
                : 'Receiving fiat currency allows cash pickup or mobile money',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],

        SizedBox(height: AppSpacing.marginM),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildReceiverOption(
              title: 'Cash\nPickup',
              value: 'cash',
              isEnabled: !isReceivingCrypto,
            ),
            _buildReceiverOption(
              title: 'Crypto\nWallet',
              value: 'wallet', 
              isEnabled: isReceivingCrypto,
            ),
            _buildReceiverOption(
              title: 'Mobile\nMoney',
              value: 'mobile',
              isEnabled: !isReceivingCrypto,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReceiverOption({
    required String title,
    required String value,
    bool isEnabled = true,
  }) {
    final bool isActive = activeReceive == value && isEnabled;
    final double width =
        (MediaQuery.of(context).size.width - (AppSpacing.paddingM * 4)) / 3;

    // FIXED: Removed provider modification during build

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled
            ? () {
                setState(() => activeReceive = value);
              }
            : null,
        borderRadius: BorderRadius.circular(AppRadius.radiusL),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          padding: EdgeInsets.all(AppSpacing.paddingM),
          decoration: BoxDecoration(
            color: isEnabled ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppRadius.radiusL),
            border: Border.all(
              color: isActive ? AppColors.primaryBlue : Colors.transparent,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? AppColors.primaryBlue.withOpacity(0.2)
                    : Colors.black.withOpacity(isEnabled ? 0.05 : 0.02),
                blurRadius: isActive ? 8 : 4,
                offset: const Offset(0, 2),
                spreadRadius: isActive ? 1 : 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              Opacity(
                opacity: isEnabled ? 1.0 : 0.4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 65,
                      width: 65,
                      decoration: BoxDecoration(
                        color: isActive
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
                        color: isActive
                            ? AppColors.primaryBlue
                            : AppColors.textPrimary,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (!isEnabled)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.lock,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate(target: isActive ? 1 : 0).scale(
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
        ).animate().fadeIn(duration: AppAnimations.normalAnimation).slideY(
              begin: 0.2,
              end: 0,
              duration: AppAnimations.normalAnimation,
              curve: AppAnimations.standardCurve,
            ),

        SizedBox(height: AppSpacing.marginM),

        OutlinedButton(
          onPressed: _showContactSelectionModal,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryBlue,
            side: BorderSide(color: AppColors.primaryBlue),
            padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingM),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
            ),
            minimumSize: const Size(double.infinity, 56),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selectedContact != null) ...[
                Icon(Icons.check_circle,
                    size: 20, color: AppColors.primaryBlue),
                SizedBox(width: AppSpacing.marginS),
                Expanded(
                  child: Text(
                    selectedContact!.displayName,
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else
                Text(
                  'Add From Contact',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(duration: AppAnimations.normalAnimation).slideY(
              begin: 0.2,
              end: 0,
              duration: AppAnimations.normalAnimation,
              curve: AppAnimations.standardCurve,
              delay: Duration(milliseconds: 50),
            ),
      ],
    );
  }

  void _showContactSelectionModal() {
    // FIXED: Properly initialize the selected contact in provider
    Future.microtask(() {
      ref.read(selectedBeneficiaryProvider.notifier).state = selectedContact;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => SelectContactModal(
        onContactSelected: (Beneficiary? contact) {
          setState(() {
            selectedContact = contact;
          });

          if (contact != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Selected: ${contact.displayName}'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
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
                        onPressed: () =>
                            setState(() => showNotifications = false),
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
              color: notification['isSuccess']
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