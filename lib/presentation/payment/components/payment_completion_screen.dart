import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';
import 'package:flash_transfer_app/providers/exchange_provider.dart';
import 'package:flash_transfer_app/core/services/reown_service.dart';
import 'package:flash_transfer_app/presentation/payment/components/wallet_connect_widget.dart';

class PaymentDoneScreen extends ConsumerStatefulWidget {
  final String status; // 'pending' or 'complete'
  final String? transactionId;

  const PaymentDoneScreen({
    Key? key,
    this.status = 'pending',
    this.transactionId,
  }) : super(key: key);

  @override
  ConsumerState<PaymentDoneScreen> createState() => _PaymentDoneScreenState();
}

class _PaymentDoneScreenState extends ConsumerState<PaymentDoneScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  bool _showNotificationModal = false;
  final String _trackingNumber = '771 824 9542';
  bool _isWalletInitialized = false;
  bool _isConnectingWallet = false;

  // Sample transaction details
  final Map<String, String> _transactionDetails = {
    'You Sent': '100 EUR',
    'Transfer Rate': '1 USDT = 1 EUR',
    'Fee': '2.50 EUR',
    'Transfer Time': '1 Min',
    'Recipient Gets': '100.00 EUR',
    'Total to pay': '102.50 EUR',
  };

  // Sample notifications
  final List<NotificationItem> _notifications = [
    NotificationItem(
      action: 'Payment sent!',
      description: 'your payment #1234 has been sent',
      icon: Icons.check_circle,
      iconColor: AppColors.success,
    ),
    NotificationItem(
      action: 'Payment Failed!',
      description: 'your payment #1234 has failed',
      icon: Icons.cancel,
      iconColor: AppColors.error,
    ),
    NotificationItem(
      action: 'Payment sent!',
      description: 'your payment #1234 has been sent',
      icon: Icons.check_circle,
      iconColor: AppColors.success,
    ),
    NotificationItem(
      action: 'Invite friend',
      description: 'Registration confirmed via affiliate link',
      icon: Icons.group,
      iconColor: AppColors.primaryBlue,
    ),
  ];

  // Receiver instructions
  final List<String> _instructions = [
    'Visit our merchant partner.',
    'Present your order number.',
    'Pay in cash.',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeWallet();
  }
  
  Future<void> _initializeWallet() async {
    try {
      await ReownService.instance.initialize(context);
      if (mounted) {
        setState(() {
          _isWalletInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing wallet: $e');
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final exchangeForm = ref.watch(exchangeFormProvider);

    // Get transaction data - could be from API response or mock data
    final transactionData = paymentState.transactionData;
    final estimateData = paymentState.estimateData;

    // Determine tracking number and status
    final trackingNumber = transactionData?.trackingNumber ??
        transactionData?.orderId ??
        'FT-${DateTime.now().millisecondsSinceEpoch}';

    final paymentUrl = transactionData?.paymentUrl;
    final isComplete = widget.status == 'complete';
    final isPending = widget.status == 'pending';
    
    // Check if this is crypto-to-fiat transaction
    final isCryptoToFiat = transactionData?.type == 'CRYPTO_TO_CASH' || 
        transactionData?.type == 'CRYPTO_TO_FIAT' ||
        (exchangeForm.fromCurrency?.type == 'CRYPTO' && exchangeForm.toCurrency?.type == 'FIAT');

    // Build dynamic transaction details for crypto-to-fiat
    Map<String, String> transactionDetails;
    
    if (isCryptoToFiat && transactionData != null) {
      // Crypto-to-fiat specific details
      transactionDetails = {
        'You Sent': '${transactionData.amount} ${transactionData.currency ?? exchangeForm.fromCurrency?.code ?? 'ETH'}',
        'Transfer Rate': '1 ${transactionData.currency ?? 'ETH'} = ${transactionData.exchangeRate?.toStringAsFixed(2) ?? estimateData?.exchangeRate.rate.toStringAsFixed(2) ?? '0'} ${exchangeForm.toCurrency?.code ?? 'XOF'}',
        'Fee': '${transactionData.fee?.toString() ?? '2e-8'} ${transactionData.currency ?? 'ETH'}',
        'Status': transactionData.status ?? 'PENDING',
        'Created On': transactionData.createdAt?.toString() ?? DateTime.now().toString(),
        'Base Fee': transactionData.feeDetails?['baseFee']?.toString() ?? '2e-8',
        'NFT discount': transactionData.feeDetails?['nftDiscount']?.toString() ?? '0',
        'Loyalty Discount': transactionData.feeDetails?['loyaltyDiscount']?.toString() ?? '0',
        'Total to Pay': '${transactionData.totalAmount ?? 0.00000102} ${transactionData.currency ?? 'ETH'}',
        'Tracking Number': transactionData.trackingNumber ?? trackingNumber,
      };
    } else {
      // Original transaction details for other types
      transactionDetails = {
        'You Sent':
            '${exchangeForm.sendAmount} ${exchangeForm.fromCurrency?.code ?? 'USD'}',
        'Transfer Rate': estimateData != null
            ? '1 ${exchangeForm.fromCurrency?.code} = ${estimateData.exchangeRate.rate.toStringAsFixed(6)} ${exchangeForm.toCurrency?.code}'
            : '1 ${exchangeForm.fromCurrency?.code ?? 'USD'} = 1 ${exchangeForm.toCurrency?.code ?? 'ETH'}',
        'Fee': estimateData != null
            ? '${estimateData.fees.totalFee.toStringAsFixed(2)} ${exchangeForm.fromCurrency?.code}'
            : '2.50 ${exchangeForm.fromCurrency?.code ?? 'USD'}',
        'Transaction Type': transactionData?.type ?? 'CASH_TO_CRYPTO',
        'Status':
            isPending ? 'Pending' : (isComplete ? 'Completed' : 'Processing'),
        'Created On':
            transactionData?.createdAt.toString() ?? DateTime.now().toString(),
        'Recipient Gets':
            '${exchangeForm.receiveAmount} ${exchangeForm.toCurrency?.code ?? 'ETH'}',
        'Total to pay': estimateData != null
            ? '${estimateData.results.totalAmountToPay.toStringAsFixed(2)} ${exchangeForm.fromCurrency?.code}'
            : '${(double.tryParse(exchangeForm.sendAmount) ?? 100.0) + 2.50} ${exchangeForm.fromCurrency?.code ?? 'USD'}',
      };
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.paddingL),
              child: Column(
                children: [
                  SizedBox(height: AppSpacing.marginXL),

                  // Status Icon and Title
                  _buildStatusSection(isPending, isComplete),

                  SizedBox(height: AppSpacing.marginXL),

                  // Tracking Number Section
                  _buildTrackingSection(trackingNumber),

                  SizedBox(height: AppSpacing.marginL),

                  // Transaction Details Card
                  _buildTransactionDetailsCard(transactionDetails),

                  SizedBox(height: AppSpacing.marginL),

                  // Payment Instructions if pending and crypto-to-fiat
                  if (isPending && isCryptoToFiat && transactionData != null) ...[
                    _buildCryptoPaymentInstructions(transactionData),
                    SizedBox(height: AppSpacing.marginL),
                  ],

                  // Action Buttons
                  _buildActionButtons(context, isPending, paymentUrl, isCryptoToFiat, transactionData),

                  SizedBox(height: AppSpacing.marginL),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHeaderButton(
            icon: Icons.menu,
            onTap: () => context.push('/profile'),
          )
              .animate()
              .fadeIn(
                duration: AppAnimations.normalAnimation,
                delay: Duration(milliseconds: 100),
              )
              .slideX(begin: -0.3, end: 0),
          _buildHeaderButton(
            icon: Icons.notifications_none_rounded,
            onTap: () => setState(() => _showNotificationModal = true),
            showBadge: true,
          )
              .animate()
              .fadeIn(
                duration: AppAnimations.normalAnimation,
                delay: Duration(milliseconds: 200),
              )
              .slideX(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.paddingM),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Icon(icon, size: 24, color: AppColors.textPrimary),
              if (showBadge)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection(bool isPending, bool isComplete) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingXL),
      child: Column(
        children: [
          // Status Icon with pulse animation
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isComplete
                                ? AppColors.success
                                : AppColors.primaryYellow)
                            .withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: _buildStatusIcon(isComplete),
                ),
              );
            },
          ),

          SizedBox(height: AppSpacing.marginL),

          // Status Text
          Text(
            isComplete ? 'Payment Complete' : 'Payment Pending',
            style: AppTextStyles.heading1.copyWith(
              color: isComplete ? AppColors.success : AppColors.textPrimary,
            ),
          )
              .animate()
              .fadeIn(
                duration: AppAnimations.normalAnimation,
                delay: Duration(milliseconds: 500),
              )
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                curve: AppAnimations.emphasizedCurve,
              ),

          if (!isComplete) ...[
            SizedBox(height: AppSpacing.marginS),
            Text(
              'Your transaction is being processed',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(
                  duration: AppAnimations.normalAnimation,
                  delay: Duration(milliseconds: 600),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(bool isComplete) {
    if (isComplete) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check,
          size: 60,
          color: Colors.white,
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.primaryYellow,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.access_time,
          size: 60,
          color: AppColors.textPrimary,
        ),
      );
    }
  }

  Widget _buildTransactionDetailsCard(Map<String, String> transactionDetails) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.marginL),
      padding: EdgeInsets.all(AppSpacing.paddingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.radiusL),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: transactionDetails.entries.map((entry) {
          final index = transactionDetails.keys.toList().indexOf(entry.key);
          return _buildDetailRow(
            entry.key,
            entry.value,
            isLast: index == transactionDetails.length - 1,
          )
              .animate()
              .fadeIn(
                duration: AppAnimations.normalAnimation,
                delay: Duration(milliseconds: 700 + (index * 100)),
              )
              .slideX(
                begin: 0.1,
                end: 0,
                curve: AppAnimations.standardCurve,
              );
        }).toList(),
      ),
    )
        .animate()
        .fadeIn(
          duration: AppAnimations.normalAnimation,
          delay: Duration(milliseconds: 600),
        )
        .slideY(
          begin: 0.1,
          end: 0,
          curve: AppAnimations.standardCurve,
        );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    final isTotal = label.contains('Total');

    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingS),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.border.withOpacity(0.5),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? AppColors.textPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingSection(String trackingNumber) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.only(bottom: AppSpacing.marginL),
          padding: EdgeInsets.all(AppSpacing.paddingM),
          decoration: BoxDecoration(
            color: AppColors.iconBackground,
            borderRadius: BorderRadius.circular(AppRadius.radiusM),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.radiusS),
                ),
                child: Icon(
                  Icons.qr_code,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              SizedBox(width: AppSpacing.marginM),
              Expanded(
                child: Stack(
                  children: [
                    Text(
                      'Tracking number (FTN): $trackingNumber',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    // Shimmer effect
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            transform:
                                GradientRotation(_shimmerAnimation.value),
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _copyTrackingNumber,
                borderRadius: BorderRadius.circular(AppRadius.radiusS),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.paddingS),
                  child: Icon(
                    Icons.copy,
                    color: AppColors.primaryBlue,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    )
        .animate()
        .fadeIn(
          duration: AppAnimations.normalAnimation,
          delay: Duration(milliseconds: 800),
        )
        .slideX(
          begin: 0.1,
          end: 0,
          curve: AppAnimations.standardCurve,
        );
  }

  Widget _buildCryptoPaymentInstructions(dynamic transactionData) {
    // Extract payment details from transaction data
    final recipientAddress = transactionData.destinationDetails?['transferData']?['address'] ?? 
                             transactionData.sourceDetails?['address'] ?? 
                             '0xb0BcBd...1eBc7730';
    final amount = transactionData.totalAmount ?? 0.00000102;
    final network = transactionData.blockchainNetwork ?? 'ethereum';
    final currency = transactionData.currency ?? 'ETH';
    
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.radiusL),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Instructions',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          )
              .animate()
              .fadeIn(
                duration: AppAnimations.normalAnimation,
                delay: Duration(milliseconds: 900),
              )
              .slideY(begin: 0.1, end: 0),
          
          SizedBox(height: AppSpacing.marginL),
          
          Text(
            'Send exactly $amount $currency to the provided address to continue.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(
                duration: AppAnimations.normalAnimation,
                delay: Duration(milliseconds: 1000),
              ),
          
          SizedBox(height: AppSpacing.marginL),
          
          // Recipient Address
          _buildInstructionRow('Recipient Address', recipientAddress, canCopy: true),
          
          SizedBox(height: AppSpacing.marginM),
          
          // Amount
          _buildInstructionRow('Amount', '$amount $currency'),
          
          SizedBox(height: AppSpacing.marginM),
          
          // Network
          _buildInstructionRow('Network', _formatNetworkName(network)),
          
          SizedBox(height: AppSpacing.marginM),
          
          // Currency Type
          _buildInstructionRow('Currency Type', currency),
        ],
      ),
    ).animate()
        .fadeIn(
          duration: AppAnimations.normalAnimation,
          delay: Duration(milliseconds: 800),
        )
        .slideY(
          begin: 0.1,
          end: 0,
          curve: AppAnimations.standardCurve,
        );
  }
  
  Widget _buildInstructionRow(String label, String value, {bool canCopy = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  canCopy && value.length > 20 
                      ? '${value.substring(0, 10)}...${value.substring(value.length - 10)}'
                      : value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canCopy) ...[
                SizedBox(width: AppSpacing.marginS),
                InkWell(
                  onTap: () => _copyToClipboard(value),
                  child: Icon(
                    Icons.copy,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  String _formatNetworkName(String network) {
    switch (network.toLowerCase()) {
      case 'ethereum':
        return 'Ethereum';
      case 'polygon':
        return 'Polygon';
      case 'bsc':
        return 'BSC';
      default:
        return network;
    }
  }
  
  void _copyToClipboard(String text) async {
    HapticFeedback.mediumImpact();
    await Clipboard.setData(ClipboardData(text: text));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied to clipboard!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusM),
          ),
        ),
      );
    }
  }

  Widget _buildPaymentInstructions(String paymentUrl) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.marginL),
      padding: EdgeInsets.all(AppSpacing.paddingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.radiusL),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // child: Column(
      //   children: [
      //     Text(
      //       'Payment Instructions',
      //       style: AppTextStyles.heading3,
      //     )
      //         .animate()
      //         .fadeIn(
      //           duration: AppAnimations.normalAnimation,
      //           delay: Duration(milliseconds: 900),
      //         )
      //         .slideY(begin: 0.1, end: 0),
      //     SizedBox(height: AppSpacing.marginM),
      //     Text(
      //       'Scan the QR code to complete the payment',
      //       style: AppTextStyles.bodyMedium.copyWith(
      //         color: AppColors.textSecondary,
      //       ),
      //       textAlign: TextAlign.center,
      //     ).animate().fadeIn(
      //           duration: AppAnimations.normalAnimation,
      //           delay: Duration(milliseconds: 1000),
      //         ),
      //     SizedBox(height: AppSpacing.marginM),
      //     Image.network(
      //       paymentUrl,
      //       width: 200,
      //       height: 200,
      //       fit: BoxFit.contain,
      //     ).animate().fadeIn(
      //           duration: AppAnimations.normalAnimation,
      //           delay: Duration(milliseconds: 1100),
      //         ),
      //   ],
      // ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, bool isPending, String? paymentUrl, bool isCryptoToFiat, dynamic transactionData) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.marginL),
      child: Column(
        children: [
          // Connect Wallet & Pay Button for crypto-to-fiat
          if (isPending && isCryptoToFiat && transactionData != null) ...[
            // Use the wallet connect widget for better UX
            WalletConnectWidget(
              transactionData: {
                'totalAmount': transactionData.totalAmount,
                'currency': transactionData.currency,
                'destinationDetails': transactionData.destinationDetails,
                'sourceDetails': transactionData.sourceDetails,
              },
              onTransactionSuccess: (txHash) {
                // Handle successful transaction
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Transaction successful! Hash: ${txHash.substring(0, 10)}...'),
                    backgroundColor: AppColors.success,
                  ),
                );
                // Optionally navigate to success screen
                // context.push('/payment-done?status=complete&transactionId=$txHash');
              },
            ),
            
            SizedBox(height: AppSpacing.marginL),
          ],
          
          // Track Order Button
          ElevatedButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              context.push('/track-transfer');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCryptoToFiat && isPending 
                  ? Colors.transparent 
                  : AppColors.primaryYellow,
              foregroundColor: isCryptoToFiat && isPending 
                  ? AppColors.primaryBlue 
                  : AppColors.textPrimary,
              elevation: 0,
              side: isCryptoToFiat && isPending 
                  ? BorderSide(color: AppColors.primaryBlue) 
                  : BorderSide.none,
              padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
              ),
              minimumSize: const Size(double.infinity, 56),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined, size: 20),
                SizedBox(width: AppSpacing.marginS),
                Text(
                  'Track Order',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: isCryptoToFiat && isPending 
                        ? AppColors.primaryBlue 
                        : null,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(
                duration: AppAnimations.normalAnimation,
                delay: Duration(milliseconds: 1200),
              )
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                curve: AppAnimations.emphasizedCurve,
              ),

          SizedBox(height: AppSpacing.marginM),

          // Back to Home Button
          OutlinedButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              context.push('/home');
            },
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
                Icon(Icons.home_outlined, size: 20),
                SizedBox(width: AppSpacing.marginS),
                Text(
                  'Back to Home',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(
                duration: AppAnimations.normalAnimation,
                delay: Duration(milliseconds: 1300),
              )
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                curve: AppAnimations.emphasizedCurve,
              ),
        ],
      ),
    );
  }

  void _copyTrackingNumber() async {
    HapticFeedback.mediumImpact();
    await Clipboard.setData(ClipboardData(text: _trackingNumber));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tracking number copied to clipboard!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusM),
          ),
        ),
      );
    }
  }
  
  Future<void> _handleWalletConnection() async {
    final transactionData = ref.read(paymentProvider).transactionData;
    
    if (transactionData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction data not available'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    setState(() {
      _isConnectingWallet = true;
    });
    
    try {
      // Check if wallet is already connected
      if (!ReownService.instance.isConnected) {
        // Open wallet connection modal
        await ReownService.instance.connect();
        
        // Wait a bit for connection to establish
        await Future.delayed(Duration(seconds: 1));
        
        // Check if connection was successful
        if (!ReownService.instance.isConnected) {
          throw Exception('Wallet connection failed');
        }
      }
      
      // Now wallet is connected, send the transaction
      final recipientAddress = transactionData.destinationDetails?['transferData']?['address'] ?? 
                               transactionData.sourceDetails?['address'] ?? 
                               '0xb0BcBd1eBc7730'; // This should be from API
      
      final amount = transactionData.totalAmount ?? 0.00000102;
      final currency = transactionData.currency ?? 'ETH';
      
      // Send the transaction
      final txHash = await ReownService.instance.sendTransaction(
        toAddress: recipientAddress,
        amountInEth: amount,
      );
      
      if (txHash != null) {
        // Transaction sent successfully
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction sent! Hash: ${txHash.substring(0, 10)}...'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 5),
            ),
          );
          
          // Optionally update transaction status or navigate
          // context.push('/payment-done?status=complete&transactionId=$txHash');
        }
      } else {
        throw Exception('Transaction failed');
      }
      
    } catch (e) {
      print('Error in wallet connection/payment: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnectingWallet = false;
        });
      }
    }
  }
}

// Notification Item Model (if not already defined)
class NotificationItem {
  final String action;
  final String description;
  final IconData icon;
  final Color iconColor;

  NotificationItem({
    required this.action,
    required this.description,
    required this.icon,
    this.iconColor = Colors.grey,
  });
}
