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
      end: 1.02,
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                  vertical: 16,
                ),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(),
                      const SizedBox(height: 24),
                      _buildBeneficiaryCard(selectedBeneficiary),
                      const SizedBox(height: 24),
                      _buildTransactionDetails(exchangeForm),
                      const SizedBox(height: 32),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                context.pop();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: Color(0xFF1976D2),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Progress indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: 0.25,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2475FF)),
                ),
              ),
              Text(
                '1',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2475FF),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Receiver's Info",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181F30),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Review receiver details',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Step indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Step 1/4',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1976D2),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.2, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF181F30), Color(0xFF2475FF)],
          ).createShader(bounds),
          child: Text(
            "Receiver's Information",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Review all the details of your transaction. Make sure everything is correct before proceeding.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideX(begin: -0.1, end: 0);
  }

  Widget _buildBeneficiaryCard(Beneficiary? beneficiary) {
    if (beneficiary == null) {
      return EmptyReceiverState(
        onSelectReceiver: () => context.pop(),
      )
          .animate()
          .fadeIn(duration: 600.ms, delay: 400.ms)
          .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  const Color(0xFF2475FF).withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2475FF).withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header section with avatar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2475FF).withOpacity(0.05),
                        const Color(0xFF2475FF).withOpacity(0.02),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'receiver-avatar-${beneficiary.id}',
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2475FF), Color(0xFF1565C0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2475FF).withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              beneficiary.firstName.isNotEmpty
                                  ? beneficiary.firstName[0].toUpperCase()
                                  : 'R',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              beneficiary.displayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF181F30),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${beneficiary.city}, ${beneficiary.country}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C735).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF00C735),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                // Details section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildDetailItem(
                        icon: Icons.person_rounded,
                        label: 'Full Name',
                        value: beneficiary.displayName,
                        iconColor: const Color(0xFF2475FF),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailItem(
                        icon: Icons.phone_rounded,
                        label: 'Mobile Number',
                        value: beneficiary.mobileNumber.isNotEmpty
                            ? beneficiary.mobileNumber
                            : 'Not provided',
                        iconColor: const Color(0xFF00C735),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailItem(
                        icon: Icons.email_rounded,
                        label: 'Email Address',
                        value: beneficiary.email,
                        iconColor: const Color(0xFFF57C00),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailItem(
                        icon: Icons.location_on_rounded,
                        label: 'Address',
                        value: beneficiary.fullAddress,
                        iconColor: const Color(0xFF7B1FA2),
                        isAddress: true,
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
        .fadeIn(duration: 600.ms, delay: 400.ms)
        .slideY(begin: 0.1, end: 0)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool isAddress = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: isAddress ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (isAddress)
                  SizedBox(
                    height: 40,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF181F30),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF181F30),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails(ExchangeFormState exchangeForm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF3E0), Color(0xFFFFECB3)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: Color(0xFFF57C00),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Transaction Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181F30),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Currency exchange cards
          Row(
            children: [
              Expanded(
                child: _buildCurrencyCard(
                  label: 'You Send',
                  currency: exchangeForm.fromCurrency?.code ?? 'USD',
                  currencyLogo: exchangeForm.fromCurrency?.logo,
                  amount: exchangeForm.sendAmount.isNotEmpty
                      ? exchangeForm.sendAmount
                      : '0.00',
                  gradientColors: [
                    const Color(0xFFFFEBEE),
                    const Color(0xFFFFCDD2),
                  ],
                  iconColor: const Color(0xFFFF3E24),
                  icon: Icons.arrow_upward_rounded,
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2475FF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF2475FF),
                    size: 20,
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                  .moveX(begin: -3, end: 3, duration: 2.seconds)
                  .then()
                  .moveX(begin: 3, end: -3, duration: 2.seconds),
              ),

              Expanded(
                child: _buildCurrencyCard(
                  label: 'They Receive',
                  currency: exchangeForm.toCurrency?.code ?? 'EUR',
                  currencyLogo: exchangeForm.toCurrency?.logo,
                  amount: exchangeForm.receiveAmount.isNotEmpty
                      ? exchangeForm.receiveAmount
                      : '0.00',
                  gradientColors: [
                    const Color(0xFFE8F5E9),
                    const Color(0xFFC8E6C9),
                  ],
                  iconColor: const Color(0xFF00C735),
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Exchange info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF8F9FA),
                  Colors.grey.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.currency_exchange_rounded,
                  label: 'Exchange Rate',
                  value: exchangeForm.exchangeRate != null
                      ? '1 ${exchangeForm.fromCurrency?.code} = ${exchangeForm.exchangeRate?.rate.toStringAsFixed(4)} ${exchangeForm.toCurrency?.code}'
                      : 'Calculating...',
                  valueColor: const Color(0xFF2475FF),
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.attach_money_rounded,
                  label: 'Transfer Fee',
                  value: exchangeForm.calculation?.fee != null
                      ? '${exchangeForm.calculation?.fee} ${exchangeForm.calculation?.feeCurrency}'
                      : 'Calculating...',
                  valueColor: const Color(0xFFF57C00),
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.calculate_rounded,
                  label: 'Total Cost',
                  value: exchangeForm.calculation?.totalAmount != null
                      ? '${exchangeForm.calculation?.totalAmount} ${exchangeForm.fromCurrency?.code}'
                      : 'Calculating...',
                  valueColor: const Color(0xFF181F30),
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 600.ms)
        .slideY(begin: 0.1, end: 0)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildCurrencyCard({
    required String label,
    required String currency,
    String? currencyLogo,
    required String amount,
    required List<Color> gradientColors,
    required Color iconColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              amount,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF181F30),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (currencyLogo != null)
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(currencyLogo),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade300,
                  ),
                  child: Center(
                    child: Text(
                      currency.substring(0, 1),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Text(
                currency,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isBold ? 16 : 14,
                color: valueColor,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
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
        // Continue button
        ElevatedButton(
          onPressed: isEnabled
              ? () {
                  HapticFeedback.mediumImpact();

                  // Check if this is a crypto-to-cash transaction
                  final exchangeForm = ref.read(exchangeFormProvider);
                  final fromCurrency = exchangeForm.fromCurrency;
                  final toCurrency = exchangeForm.toCurrency;

                  final isCryptoToCash = fromCurrency?.type == 'CRYPTO' &&
                      toCurrency?.type == 'FIAT';

                  if (isCryptoToCash) {
                    // Navigate to crypto payment screen for crypto-to-cash
                    context.push('/send-crypto-payment');
                  } else {
                    // Navigate to regular payment selection for other flows
                    context.push('/select-payment');
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC000),
            foregroundColor: const Color(0xFF181F30),
            disabledBackgroundColor: Colors.grey.shade200,
            disabledForegroundColor: Colors.grey.shade500,
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
              Icon(
                isEnabled ? Icons.check_circle_rounded : Icons.person_add_rounded,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isEnabled ? 'Continue' : 'Select a Receiver First',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms, delay: 800.ms)
            .slideY(begin: 0.1, end: 0),

        const SizedBox(height: 12),

        // Change Receiver button
        OutlinedButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
          icon: const Icon(
            Icons.swap_horiz_rounded,
            size: 20,
          ),
          label: const Text(
            'Change Receiver',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2475FF),
            side: const BorderSide(color: Color(0xFF2475FF), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            minimumSize: const Size(double.infinity, 56),
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms, delay: 900.ms)
            .slideY(begin: 0.1, end: 0),

        const SizedBox(height: 12),

        // Cancel button
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 56),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms, delay: 1000.ms),
      ],
    );
  }
}