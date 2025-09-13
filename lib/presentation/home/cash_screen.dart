import 'package:flash_transfer_app/core/models/beneficiary.dart';
import 'package:flash_transfer_app/presentation/common/icons/lottie_animations.dart';
import 'package:flash_transfer_app/presentation/common/select_contact_modal.dart';
import 'package:flash_transfer_app/providers/beneficiary_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';
import 'package:flash_transfer_app/presentation/common/icons/payment_icons.dart';
import 'package:flash_transfer_app/presentation/home/components/frequent_receipts_section.dart';
import 'package:flash_transfer_app/presentation/home/components/recent_receipts_section.dart';
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
    // Initialize payment methods after the widget is built
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
          backgroundColor: const Color(0xFFF8F9FA),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.04,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader()
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.2, end: 0, curve: Curves.easeOutCubic),
                  _buildBackButton()
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 100.ms)
                      .slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 24),
                  _buildPaymentMethodSection()
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms),
                  const SizedBox(height: 32),
                  _buildReceiverMethodSection()
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 300.ms),
                  const SizedBox(height: 32),
                  _buildActionButtons()
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 400.ms),
                  const SizedBox(height: 32),
                  const FrequentReceiptsSection()
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 500.ms),
                  const SizedBox(height: 24),
                  const RecentReceiptsSection()
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 600.ms),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildIconButton(
            icon: Icons.menu_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/profile');
            },
          ),
          _buildIconButton(
            icon: Icons.notifications_none_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => showNotifications = true);
            },
            showBadge: true,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Icon(icon, size: 24, color: const Color(0xFF181F30)),
              if (showBadge)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3E24),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/home');
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Back',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181F30),
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
            Text(
              'How would you like to pay?',
              style: AppTextStyles.heading3.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (sendingCurrency != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSendingCrypto
                        ? [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)]
                        : [const Color(0xFFF5F5F5), const Color(0xFFEEEEEE)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${sendingCurrency.code} • ${sendingCurrency.type}',
                  style: TextStyle(
                    color: isSendingCrypto
                        ? const Color(0xFF1976D2)
                        : const Color(0xFF616161),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),

        if (sendingCurrency != null) ...[
          const SizedBox(height: 6),
          Text(
            isSendingCrypto
                ? '💡 Crypto payments require a crypto wallet'
                : '💡 Multiple payment options available for fiat',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Responsive payment grid
        LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.325,
              child: Row(
                children: [
                  // Left column
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        Expanded(
                          child: _buildPaymentOption(
                            title: 'Cash\nPayment',
                            value: 'cash',
                            isEnabled: !isSendingCrypto,
                            isCompact: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _buildPaymentOption(
                            title: 'Credit\nCard',
                            value: 'card',
                            isEnabled: !isSendingCrypto,
                            isCompact: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Center column
                  Expanded(
                    flex: 4,
                    child: _buildPaymentOption(
                      title: 'Crypto Wallet',
                      value: 'wallet',
                      isEnabled: isSendingCrypto,
                      isCenter: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Right column
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        Expanded(
                          child: _buildPaymentOption(
                            title: 'Bank\nTransfer',
                            value: 'bank',
                            isEnabled: !isSendingCrypto,
                            isCompact: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _buildPaymentOption(
                            title: 'Mobile\nMoney',
                            value: 'mobile',
                            isEnabled: !isSendingCrypto,
                            isCompact: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled
                ? () {
                    HapticFeedback.lightImpact();
                    setState(() => activePay = value);
                  }
                : null,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: isEnabled
                    ? (isActive ? Colors.white : const Color(0xFFFAFAFA))
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF2475FF)
                      : isEnabled
                          ? Colors.grey.shade200
                          : Colors.transparent,
                  width: isActive ? 2 : 1,
                ),
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: const Color(0xFF2475FF).withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              child: Stack(
                children: [
                  Opacity(
                    opacity: isEnabled ? 1.0 : 0.4,
                    child: isCenter
                        ? _buildCenterContent(
                            title, value, isActive, constraints)
                        : _buildCompactContent(
                            title, value, isActive, constraints),
                  ),
                  if (!isEnabled)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.lock_rounded,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  if (isActive)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2475FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterContent(
      String title, String value, bool isActive, BoxConstraints constraints) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: constraints.maxHeight * 0.4,
          width: constraints.maxHeight * 0.4,
          constraints: const BoxConstraints(maxWidth: 80, maxHeight: 80),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)]
                  : [Colors.grey.shade100, Colors.grey.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: _getLottieAnimation(value, isActive, 60),
          ),
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            style: TextStyle(
              color:
                  isActive ? const Color(0xFF2475FF) : const Color(0xFF424242),
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactContent(
      String title, String value, bool isActive, BoxConstraints constraints) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: constraints.maxHeight * 0.4,
          width: constraints.maxHeight * 0.4,
          constraints: const BoxConstraints(maxWidth: 60, maxHeight: 60),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)]
                  : [Colors.grey.shade100, Colors.grey.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: _getLottieAnimation(value, isActive, 42),
          ),
        ),
        const SizedBox(height: 10),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF2475FF)
                    : const Color(0xFF424242),
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _getLottieAnimation(String value, bool isActive, double size) {
    switch (value) {
      case 'cash':
        return LottieAnimations.cashAnimation(
          width: size * 1.5,
          height: size * 1.5,
          repeat: isActive,
          animate: isActive,
        );
      case 'wallet':
        return LottieAnimations.walletAnimation(
          width: size,
          height: size,
          repeat: isActive,
          animate: isActive,
        );
      case 'card':
        return LottieAnimations.creditCardAnimation(
          width: size,
          height: size,
          repeat: isActive,
          animate: isActive,
        );
      case 'bank':
        return LottieAnimations.bankAnimation(
          width: size,
          height: size,
          repeat: isActive,
          animate: isActive,
        );
      case 'mobile':
        return LottieAnimations.phoneAnimation(
          width: size,
          height: size,
          repeat: isActive,
          animate: isActive,
        );
      default:
        return LottieAnimations.cashAnimation(
          width: size,
          height: size,
          repeat: isActive,
          animate: isActive,
        );
    }
  }

  Widget _buildReceiverMethodSection() {
    final exchangeForm = ref.watch(exchangeFormProvider);
    final receivingCurrency = exchangeForm.toCurrency;
    final isReceivingCrypto = receivingCurrency?.type == 'CRYPTO';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'How should they receive it?',
              style: AppTextStyles.heading3.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (receivingCurrency != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isReceivingCrypto
                        ? [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)]
                        : [const Color(0xFFF5F5F5), const Color(0xFFEEEEEE)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${receivingCurrency.code} • ${receivingCurrency.type}',
                  style: TextStyle(
                    color: isReceivingCrypto
                        ? const Color(0xFF1976D2)
                        : const Color(0xFF616161),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (receivingCurrency != null) ...[
          const SizedBox(height: 6),
          Text(
            isReceivingCrypto
                ? '💡 Crypto must be received in a crypto wallet'
                : '💡 Choose cash pickup or mobile money for fiat',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildReceiverOption(
                title: 'Cash\nPickup',
                value: 'cash',
                isEnabled: !isReceivingCrypto,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildReceiverOption(
                title: 'Crypto\nWallet',
                value: 'wallet',
                isEnabled: isReceivingCrypto,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildReceiverOption(
                title: 'Mobile\nMoney',
                value: 'mobile',
                isEnabled: !isReceivingCrypto,
              ),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled
            ? () {
                HapticFeedback.lightImpact();
                setState(() => activeReceive = value);
              }
            : null,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: MediaQuery.of(context).size.height * 0.20,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isEnabled
                ? (isActive ? Colors.white : const Color(0xFFFAFAFA))
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF2475FF)
                  : isEnabled
                      ? Colors.grey.shade200
                      : Colors.transparent,
              width: isActive ? 2 : 1,
            ),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: const Color(0xFF2475FF).withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isActive
                              ? [
                                  const Color(0xFFE3F2FD),
                                  const Color(0xFFBBDEFB)
                                ]
                              : [Colors.grey.shade100, Colors.grey.shade200],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: _getLottieAnimation(value, isActive, 40),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        color: isActive
                            ? const Color(0xFF2475FF)
                            : const Color(0xFF424242),
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (!isEnabled)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.lock_rounded,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
              if (isActive)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2475FF),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.check, color: Colors.white, size: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Add New button
        ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.push('/add-new').then((_) {
              // After adding new contact, you might want to navigate to receiver info
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC000),
            foregroundColor: const Color(0xFF181F30),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            minimumSize: const Size(double.infinity, 56),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                'Add New Contact',
                style: AppTextStyles.buttonMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Add From Contact button
        OutlinedButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _showContactSelectionModal();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2475FF),
            side: const BorderSide(color: Color(0xFF2475FF), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            minimumSize: const Size(double.infinity, 56),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selectedContact != null) ...[
                const Icon(Icons.check_circle_rounded, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedContact!.displayName,
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: const Color(0xFF2475FF),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else ...[
                const Icon(Icons.contacts_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Select From Contacts',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: const Color(0xFF2475FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showContactSelectionModal() {
    ref.read(selectedBeneficiaryProvider.notifier).state = selectedContact;

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
            context.push('/receiver-info', extra: contact);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Selected: ${contact.displayName}'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
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
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),

          // Modal Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 20,
                    offset: Offset(0, -8),
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
                      Text(
                        'Notifications',
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () =>
                            setState(() => showNotifications = false),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Notifications list
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
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
                duration: 300.ms,
                curve: Curves.easeOutCubic,
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification['isSuccess']
              ? const Color(0xFF00C735).withOpacity(0.2)
              : const Color(0xFFFF3E24).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: notification['isSuccess']
                  ? const Color(0xFF00C735).withOpacity(0.1)
                  : const Color(0xFFFF3E24).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              notification['icon'],
              color: notification['isSuccess']
                  ? const Color(0xFF00C735)
                  : const Color(0xFFFF3E24),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['action'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181F30),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification['desc'],
                  style: const TextStyle(
                    fontSize: 13,
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
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: index * 50),
          duration: 300.ms,
        )
        .slideX(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: index * 50),
          duration: 300.ms,
        );
  }
}
