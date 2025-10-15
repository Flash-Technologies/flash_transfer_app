import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../presentation/payment/components/wallet_connect_widget.dart';
import '../../config/ui_constants.dart';
import '../../providers/language_provider.dart';

class IndividualTransactionScreen extends ConsumerStatefulWidget {
  final String transactionId;
  final Transaction? transaction;

  const IndividualTransactionScreen({
    super.key,
    required this.transactionId,
    this.transaction,
  });

  @override
  ConsumerState<IndividualTransactionScreen> createState() =>
      _IndividualTransactionScreenState();
}

class _IndividualTransactionScreenState
    extends ConsumerState<IndividualTransactionScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _contentFadeAnimation;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Load transactions if not provided
    if (widget.transaction == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(transactionsProvider.notifier).fetchTransactions();
      });
    }
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _contentFadeAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeInOut,
    );

    // Start animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _contentAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _contentAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Widget _buildPaymentActionCard(Transaction transaction) {
    final tr = ref.watch(translationHelperProvider);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryYellow.withOpacity(0.1),
            AppColors.primaryYellow.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryYellow.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryYellow.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.primaryYellow,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('transaction.individualTransaction.paymentAction.title'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr('transaction.individualTransaction.paymentAction.subtitle'),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Payment Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withOpacity(0.5),
              ),
            ),
            child: Column(
              children: [
                _buildPaymentDetailRow(
                  tr('transaction.individualTransaction.paymentAction.amountToPay'),
                  '${transaction.totalAmount ?? transaction.amount} ${transaction.currency}',
                  isImportant: true,
                ),
                const SizedBox(height: 12),
                _buildPaymentDetailRow(
                  tr('transaction.individualTransaction.paymentAction.network'),
                  transaction.blockchainNetwork ?? tr('transaction.individualTransaction.paymentAction.ethereum'),
                ),
                const SizedBox(height: 12),
                _buildPaymentDetailRow(
                  tr('transaction.individualTransaction.paymentAction.trackingNumber'),
                  transaction.trackingNumber ?? transaction.referenceId ?? '',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Wallet Connect Widget
          WalletConnectWidget(
            trackingNumber: transaction.trackingNumber ?? 
                           transaction.referenceId ?? 
                           transaction.id,
            transactionData: {
              'totalAmount': transaction.totalAmount ?? transaction.amount,
              'currency': transaction.currency,
              'trackingNumber': transaction.trackingNumber,
              'orderId': transaction.referenceId,
              'type': transaction.type,
              'blockchainNetwork': transaction.blockchainNetwork,
            },
            onTransactionSuccess: (txHash) {
              // Handle successful transaction
              HapticFeedback.heavyImpact();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr('transaction.individualTransaction.paymentAction.successMessage').replaceAll('{hash}', txHash.substring(0, 10))),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              
              // Refresh the transaction
              ref.read(transactionsProvider.notifier).fetchTransactions();
              
              // Navigate to success screen
              Future.delayed(const Duration(seconds: 2), () {
                context.push('/payment-done?status=processing');
              });
            },
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 600))
        .slideY(begin: 0.1, end: 0);
  }
  
  Widget _buildPaymentDetailRow(String label, String value, {bool isImportant = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isImportant ? 16 : 14,
            fontWeight: isImportant ? FontWeight.bold : FontWeight.w500,
            color: isImportant ? AppColors.primaryBlue : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Header
          SlideTransition(
            position: _headerSlideAnimation,
            child: _buildHeader(),
          ),

          // Content
          Expanded(
            child: FadeTransition(
              opacity: _contentFadeAnimation,
              child: _buildContent(),
            ),
          ),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final tr = ref.watch(translationHelperProvider);
    
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Color(0xFF181F30),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              tr('transaction.individualTransaction.header.title'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF181F30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Consumer(
      builder: (context, ref, child) {
        final transactionsState = ref.watch(transactionsProvider);
        final transaction = widget.transaction ??
            transactionsState.transactions.firstWhere(
              (t) => t.id == widget.transactionId,
              orElse: () => Transaction(
                id: widget.transactionId,
                referenceId: '',
                type: '',
                amount: 0,
                destinationAmount: 0,
                fee: 0,
                totalAmount: 0,
                currency: '',
                exchangeRate: 0,
                sourceType: '',
                destinationType: '',
                status: '',
                userId: 1,
                trackingNumber: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                version: 1,
                orderId: '',
                isCrossChain: false,
                useSystemLiquidity: false,
                isUserManagedSourceWallet: false,
                statusHistory: [],
                blockchainNetwork: null,
              ),
            );

        if (transactionsState.isLoading && widget.transaction == null) {
          return _buildLoadingState();
        }

        return SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Status Card
              _buildStatusCard(transaction),
              const SizedBox(height: 16),
              
              // Payment Action Card for Pending Transactions
              if (transaction.status.toLowerCase() == 'pending' && 
                  (transaction.type == 'CRYPTO_TO_CASH' || 
                   transaction.type == 'CRYPTO_TO_FIAT')) ...
                [
                  _buildPaymentActionCard(transaction),
                  const SizedBox(height: 16),
                ],

              // Transaction Details Card
              _buildTransactionDetailsCard(transaction),
              const SizedBox(height: 16),

              // Timeline Card
              _buildTimelineCard(transaction),
              const SizedBox(height: 16),

              // Fee Breakdown Card
              _buildFeeBreakdownCard(transaction),
              const SizedBox(height: 16),

              // Transaction Info Card
              _buildTransactionInfoCard(transaction),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(Transaction transaction) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Status Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: transaction.statusColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              transaction.statusIcon,
              size: 32,
              color: Colors.white,
            ),
          )
              .animate()
              .scale(duration: const Duration(milliseconds: 600))
              .then()
              .shimmer(duration: const Duration(milliseconds: 1000)),

          const SizedBox(height: 16),

          // Status Title
          Text(
            transaction.formattedType,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF181F30),
            ),
          )
              .animate(delay: const Duration(milliseconds: 200))
              .fadeIn(duration: const Duration(milliseconds: 400))
              .slideY(begin: 0.3),

          const SizedBox(height: 8),

          // Date & Time
          Text(
            _formatDateTime(transaction.createdAt),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6E757D),
            ),
          )
              .animate(delay: const Duration(milliseconds: 400))
              .fadeIn(duration: const Duration(milliseconds: 400))
              .slideY(begin: 0.3),

          const SizedBox(height: 4),

          // Status
          Text(
            transaction.status.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              color: transaction.statusColor,
              fontWeight: FontWeight.w600,
            ),
          )
              .animate(delay: const Duration(milliseconds: 600))
              .fadeIn(duration: const Duration(milliseconds: 400))
              .slideY(begin: 0.3),

          const SizedBox(height: 16),

          // Tracking Number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  transaction.trackingNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Color(0xFF6E757D),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _copyToClipboard(transaction.trackingNumber),
                  child: Text(
                    ref.watch(translationHelperProvider)('transaction.individualTransaction.statusCard.copy'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2475FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate(delay: const Duration(milliseconds: 800))
              .fadeIn(duration: const Duration(milliseconds: 400))
              .scale(begin: const Offset(0.8, 0.8)),
        ],
      ),
    );
  }

  Widget _buildTransactionDetailsCard(Transaction transaction) {
    final tr = ref.watch(translationHelperProvider);
    
    return _buildCard(
      title: tr('transaction.individualTransaction.transactionDetails.title'),
      child: Column(
        children: [
          _buildInfoRow(
            tr('transaction.individualTransaction.transactionDetails.youSending'),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181F30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    transaction.currency,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  transaction.totalAmount.toStringAsFixed(6),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF181F30),
                  ),
                ),
              ],
            ),
          ),
          _buildInfoRow(
            tr('transaction.individualTransaction.transactionDetails.includingFee'),
            '${transaction.fee.toStringAsFixed(6)} ${transaction.currency}',
          ),
          const Divider(color: Color(0xFFF8F9FA), height: 24),
          _buildInfoRow(
            tr('transaction.individualTransaction.transactionDetails.recipientGets'),
            Text(
              transaction.destinationAmount?.toStringAsFixed(10) ?? '0.0000000000',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00C735),
              ),
            ),
          ),
          _buildInfoRow(tr('transaction.individualTransaction.transactionDetails.duration'), _calculateDuration(transaction)),
          _buildInfoRow(tr('transaction.individualTransaction.transactionDetails.started'), _formatRelativeTime(transaction.createdAt)),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(Transaction transaction) {
    final tr = ref.watch(translationHelperProvider);
    
    return _buildCard(
      title: tr('transaction.individualTransaction.timeline.title'),
      subtitle: tr('transaction.individualTransaction.timeline.duration').replaceAll('{duration}', _calculateDuration(transaction)),
      child: Column(
        children: [
          _buildTimelineItem(
            icon: Icons.check_circle,
            iconColor: const Color(0xFF00C735),
            title: tr('transaction.individualTransaction.timeline.transactionCompleted'),
            time: _formatRelativeTime(transaction.updatedAt),
          ),
          _buildTimelineItem(
            icon: Icons.phone_callback,
            iconColor: const Color(0xFF00C735),
            title: tr('transaction.individualTransaction.timeline.paymentCallbackReceived'),
            time: _formatRelativeTime(transaction.updatedAt),
          ),
          _buildTimelineItem(
            icon: Icons.access_time,
            iconColor: const Color(0xFFFFC000),
            title: tr('transaction.individualTransaction.timeline.blockchainConfirmation'),
            time: _formatRelativeTime(transaction.updatedAt),
            description: transaction.blockchainTxHash != null 
                ? tr('transaction.individualTransaction.timeline.confirmedOn').replaceAll('{network}', transaction.blockchainNetwork ?? 'blockchain')
                : tr('transaction.individualTransaction.timeline.waitingForConfirmations'),
          ),
          _buildTimelineItem(
            icon: Icons.sync,
            iconColor: const Color(0xFF00C735),
            title: tr('transaction.individualTransaction.timeline.paymentProcessing'),
            time: _formatRelativeTime(transaction.createdAt),
          ),
          _buildTimelineItem(
            icon: Icons.schedule,
            iconColor: const Color(0xFF00C735),
            title: tr('transaction.individualTransaction.timeline.transactionStarted'),
            time: _formatRelativeTime(transaction.createdAt),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFeeBreakdownCard(Transaction transaction) {
    final tr = ref.watch(translationHelperProvider);
    final feeDetails = transaction.feeDetails;
    
    return _buildCard(
      title: tr('transaction.individualTransaction.feeBreakdown.title'),
      child: Column(
        children: [
          _buildFeeRow(tr('transaction.individualTransaction.feeBreakdown.baseAmount'), transaction.amount, transaction.currency),
          if (feeDetails != null) ...[
            _buildFeeRow(
                tr('transaction.individualTransaction.feeBreakdown.platformFee'), 
                feeDetails['platformCharges'] ?? transaction.fee, 
                transaction.currency),
            if (feeDetails['loyaltyDiscount'] != null)
              _buildFeeRow(
                tr('transaction.individualTransaction.feeBreakdown.loyaltyDiscount'),
                -(feeDetails['loyaltyDiscount'] as num),
                transaction.currency,
                isDiscount: true,
              ),
            if (feeDetails['nftDiscount'] != null)
              _buildFeeRow(
                tr('transaction.individualTransaction.feeBreakdown.nftDiscount'),
                -(feeDetails['nftDiscount'] as num),
                transaction.currency,
                isDiscount: true,
              ),
          ] else ...[
            _buildFeeRow(tr('transaction.individualTransaction.feeBreakdown.serviceFee'), transaction.fee, transaction.currency),
          ],
          const Divider(
            color: Color(0xFFF8F9FA),
            height: 32,
            thickness: 2,
          ),
          _buildFeeRow(
            tr('transaction.individualTransaction.feeBreakdown.total'),
            transaction.totalAmount,
            transaction.currency,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionInfoCard(Transaction transaction) {
    final tr = ref.watch(translationHelperProvider);
    
    return _buildCard(
      title: tr('transaction.individualTransaction.transactionInfo.title'),
      child: Column(
        children: [
          _buildInfoRow(tr('transaction.individualTransaction.transactionInfo.referenceId'), transaction.referenceId),
          _buildInfoRow(tr('transaction.individualTransaction.transactionInfo.type'), transaction.formattedType),
          _buildInfoRow(tr('transaction.individualTransaction.transactionInfo.created'), _formatRelativeTime(transaction.createdAt)),
          if (transaction.completedAt != null)
            _buildInfoRow(tr('transaction.individualTransaction.transactionInfo.completed'), _formatRelativeTime(transaction.completedAt!)),
          if (transaction.blockchainTxHash != null)
            _buildInfoRow(
              tr('transaction.individualTransaction.transactionInfo.blockchainTx'),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTxHash(transaction.blockchainTxHash!),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF181F30),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _copyToClipboard(transaction.blockchainTxHash!),
                    child: Text(
                      tr('transaction.individualTransaction.transactionInfo.copy'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2475FF),
                        fontWeight: FontWeight.w500,
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

  Widget _buildCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF181F30),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6E757D),
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6E757D),
            ),
          ),
          value is Widget
              ? value
              : Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181F30),
                  ),
                  textAlign: TextAlign.right,
                ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(
    String label,
    num amount,
    String currency, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isTotal ? 16 : 12,
      ),
      decoration: BoxDecoration(
        border: isTotal
            ? const Border(top: BorderSide(color: Color(0xFFF8F9FA), width: 2))
            : const Border(bottom: BorderSide(color: Color(0xFFF8F9FA))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDiscount ? const Color(0xFF00C735) : const Color(0xFF6E757D),
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}${amount.toStringAsFixed(6)} $currency',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDiscount 
                  ? const Color(0xFF00C735) 
                  : const Color(0xFF181F30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    String? description,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: const Color(0xFFE9ECEF),
                  margin: const EdgeInsets.only(top: 8),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181F30),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6E757D),
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6E757D),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final tr = ref.watch(translationHelperProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                // Navigate back to transaction list
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC000),
                foregroundColor: const Color(0xFF181F30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                tr('transaction.individualTransaction.actionButtons.trackAnother'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF8F9FA),
                foregroundColor: const Color(0xFF181F30),
                side: const BorderSide(color: Color(0xFFE9ECEF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                tr('transaction.individualTransaction.actionButtons.backToHome'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final tr = ref.watch(translationHelperProvider);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC000)),
          ),
          const SizedBox(height: 16),
          Text(
            tr('transaction.individualTransaction.loading.message'),
            style: const TextStyle(
              color: Color(0xFF6E757D),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    
    final hour = dateTime.hour == 0 ? 12 : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    
    return '$month $day, $year, ${hour.toString().padLeft(2, '0')}:$minute:$second $ampm';
  }

  String _formatRelativeTime(DateTime dateTime) {
    final tr = ref.watch(translationHelperProvider);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return tr('transaction.individualTransaction.timeFormat.daysAgo').replaceAll('{days}', difference.inDays.toString());
    } else if (difference.inHours > 0) {
      return tr('transaction.individualTransaction.timeFormat.hoursAgo').replaceAll('{hours}', difference.inHours.toString());
    } else if (difference.inMinutes > 0) {
      return tr('transaction.individualTransaction.timeFormat.minutesAgo').replaceAll('{minutes}', difference.inMinutes.toString());
    } else {
      return tr('transaction.individualTransaction.timeFormat.justNow');
    }
  }

  String _calculateDuration(Transaction transaction) {
    final tr = ref.watch(translationHelperProvider);
    
    if (transaction.completedAt != null) {
      final duration = transaction.completedAt!.difference(transaction.createdAt);
      if (duration.inHours > 0) {
        final hours = duration.inHours;
        final minutes = duration.inMinutes % 60;
        return '${hours}h ${minutes}m';
      } else if (duration.inMinutes > 0) {
        return '${duration.inMinutes}m';
      } else {
        return tr('transaction.individualTransaction.timeFormat.lessThanMinute');
      }
    } else {
      final elapsed = DateTime.now().difference(transaction.createdAt);
      if (elapsed.inHours > 0) {
        final hours = elapsed.inHours;
        final minutes = elapsed.inMinutes % 60;
        return '${hours}h ${minutes}m ${tr('transaction.individualTransaction.timeFormat.ongoing')}';
      } else if (elapsed.inMinutes > 0) {
        return '${elapsed.inMinutes}m ${tr('transaction.individualTransaction.timeFormat.ongoing')}';
      } else {
        return '${tr('transaction.individualTransaction.timeFormat.lessThanMinute')} ${tr('transaction.individualTransaction.timeFormat.ongoing')}';
      }
    }
  }

  String _formatTxHash(String txHash) {
    if (txHash.length > 16) {
      return '${txHash.substring(0, 8)}...${txHash.substring(txHash.length - 8)}';
    }
    return txHash;
  }

  void _copyToClipboard(String text) {
    final tr = ref.watch(translationHelperProvider);
    
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('transaction.individualTransaction.clipboard.copied').replaceAll('{text}', _formatTxHash(text))),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF181F30),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}