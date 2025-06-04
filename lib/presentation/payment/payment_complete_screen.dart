import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:flash_transfer_app/config/theme.dart';
import 'package:flash_transfer_app/presentation/payment/components/celebration_effect.dart';
import 'package:flash_transfer_app/presentation/payment/components/transaction_info_card.dart';
import 'package:flash_transfer_app/presentation/common/notification_modal.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';
import 'package:flash_transfer_app/providers/exchange_provider.dart';

class PaymentCompleteScreen extends ConsumerStatefulWidget {
  const PaymentCompleteScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PaymentCompleteScreen> createState() =>
      _PaymentCompleteScreenState();
}

class _PaymentCompleteScreenState extends ConsumerState<PaymentCompleteScreen>
    with SingleTickerProviderStateMixin {
  bool _showCelebration = true;
  bool _showNotificationModal = false;
  late AnimationController _pulseAnimationController;

  final Map<String, String> _transactionDetails = {
    'You Sent': '100 EUR',
    'Transfer Rate': '1 USDT = 1 EUR',
    'Fee': '1 Min',
    'Transfer Time': '1 Min',
    'Recipient Gets': '100.00 EUR',
    'Total to pay': '102.50 EUR',
  };

  final List<NotificationItem> _notifications = [
    NotificationItem(
      action: 'Payment sent!',
      description: 'your payment #1234 has been send',
      icon: Icons.check_circle,
      iconColor: Colors.green,
    ),
    NotificationItem(
      action: 'Payment Failed!',
      description: 'your payment #1234 has been send',
      icon: Icons.cancel,
      iconColor: Colors.red,
    ),
    NotificationItem(
      action: 'Payment sent!',
      description: 'your payment #1234 has been send',
      icon: Icons.check_circle,
      iconColor: Colors.green,
    ),
    NotificationItem(
      action: 'Invite friend',
      description: 'Registration confirmed via affiliate link',
      icon: Icons.group,
    ),
  ];

  // Instructions list
  final List<String> _instructions = [
    'Visit our merchant partner.',
    'Present your order number.',
    'Pay in cash.',
  ];

  @override
  void initState() {
    super.initState();
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    super.dispose();
  }

  void _toggleNotificationModal() {
    setState(() {
      _showNotificationModal = !_showNotificationModal;
    });
  }

  void _copyTrackingNumber() async {
    const trackingNumber = '771 824 9542';
    await Clipboard.setData(const ClipboardData(text: trackingNumber));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tracking number copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool _isCryptoToFiat() {
    final exchangeForm = ref.read(exchangeFormProvider);
    final fromCurrency = exchangeForm.fromCurrency;
    final toCurrency = exchangeForm.toCurrency;
    return fromCurrency?.type == 'CRYPTO' && toCurrency?.type == 'FIAT';
  }

  String _getProviderName() {
    final paymentState = ref.read(paymentProvider);
    final mobileDetails = paymentState.mobileMoneyDetails;
    final provider = mobileDetails?['provider']?.toString() ?? 'ORANGE';
    return provider.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),

                    // Success indicator and title
                    _buildSuccessIndicator(),

                    // Transaction details card
                    _buildTransactionCard(),

                    // Tracking number
                    _buildTrackingNumber(),

                    // Receiver instructions
                    _buildInstructions(),

                    // Action buttons
                    _buildActionButtons(),

                    // Bottom text
                    _buildFooterText(),
                  ],
                ),
              ),
            ),
          ),

          // Celebration effect overlay
          if (_showCelebration) const CelebrationEffect(play: true),

          // Notification modal overlay
          if (_showNotificationModal)
            NotificationModal(
              notifications: _notifications,
              onClose: _toggleNotificationModal,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Menu button
        InkWell(
          onTap: () => context.push('/profile'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF0F1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.menu, size: 20),
          ),
        ),

        // Notification bell
        InkWell(
          onTap: _toggleNotificationModal,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF0F1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.notifications_none, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Column(
        children: [
          // Success check icon with glowing/pulsing effect
          AnimatedBuilder(
            animation: _pulseAnimationController,
            builder: (context, child) {
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF00C735,
                      ).withOpacity(0.3 * _pulseAnimationController.value),
                      blurRadius: 20 * _pulseAnimationController.value,
                      spreadRadius: 5 * _pulseAnimationController.value,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Lottie.asset(
              'assets/LottieFiles/success.json',
              width: 100,
              height: 100,
              repeat: false,
              animate: true,
            ),
          ),

          const SizedBox(height: 16),

          // Payment complete text
          const Text(
            'Payment Complete',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181F30),
            ),
          )
              .animate(delay: const Duration(milliseconds: 500))
              .fadeIn(duration: const Duration(milliseconds: 500))
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutQuad,
              ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: TransactionInfoCard(transactionDetails: _transactionDetails),
    );
  }

  Widget _buildTrackingNumber() {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.qr_code,
                color: Color(0xFF2475FF),
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: const Text(
                'Tracking number (FTN): 771 824 9542',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2475FF),
                ),
              ).animate(delay: const Duration(milliseconds: 800)).shimmer(
                    duration: const Duration(seconds: 2),
                    color: Colors.white.withOpacity(0.8),
                  ),
            ),
            InkWell(
              onTap: _copyTrackingNumber,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.copy, color: Color(0xFF2475FF), size: 18),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: const Duration(milliseconds: 700))
        .fadeIn(duration: const Duration(milliseconds: 400))
        .slideX(
          begin: 0.1,
          end: 0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuad,
        );
  }

  Widget _buildInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Receiver Instructions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181F30),
            ),
          ),
        ),
        ...List.generate(
          _instructions.length,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _instructions[index],
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6E757D),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate(delay: Duration(milliseconds: 900 + (index * 100)))
              .fadeIn(duration: const Duration(milliseconds: 400))
              .slideY(
                begin: 0.1,
                end: 0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutQuad,
              ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final isCryptoToFiat = _isCryptoToFiat();
    final providerName = _getProviderName();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Pay by Provider button (for crypto-to-fiat only)
          if (isCryptoToFiat) ...[
            ElevatedButton(
              onPressed: () {
                // TODO: Implement payment by provider flow
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Redirecting to $providerName payment...'),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Pay by $providerName",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: const Duration(milliseconds: 1100))
                .fadeIn(duration: const Duration(milliseconds: 400))
                .slideY(
                  begin: 0.1,
                  end: 0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutQuad,
                ),
            const SizedBox(height: 12),
          ],

          // Track Order button
          ElevatedButton(
            onPressed: () => context.push('/track-transfer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC000),
              foregroundColor: const Color(0xFF181F30),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined, size: 18),
                SizedBox(width: 8),
                Text(
                  "Track Order",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
              .animate(delay: const Duration(milliseconds: 1200))
              .fadeIn(duration: const Duration(milliseconds: 400))
              .slideY(
                begin: 0.1,
                end: 0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutQuad,
              ),

          const SizedBox(height: 12),

          // Back to Home button
          OutlinedButton(
            onPressed: () => context.push('/home'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2475FF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFF2475FF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_outlined, size: 18),
                SizedBox(width: 8),
                Text(
                  "Back to Home",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
              .animate(delay: const Duration(milliseconds: 1300))
              .fadeIn(duration: const Duration(milliseconds: 400))
              .slideY(
                begin: 0.1,
                end: 0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutQuad,
              ),
        ],
      ),
    );
  }

  Widget _buildFooterText() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        "Don't miss out on the benefits of the my wu SM problem ! you can earn point on future transactions. register today!",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF6E757D),
          height: 1.4,
        ),
      ),
    )
        .animate(delay: const Duration(milliseconds: 1400))
        .fadeIn(duration: const Duration(milliseconds: 500));
  }
}
