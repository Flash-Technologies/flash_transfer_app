import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../providers/tracking_provider.dart';
import '../../core/models/transaction_model.dart';

class TransactionDetailsScreen extends ConsumerStatefulWidget {
  final Transaction transaction;
  final StatusDetails? statusDetails;

  const TransactionDetailsScreen({
    super.key,
    required this.transaction,
    this.statusDetails,
  });

  @override
  ConsumerState<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState
    extends ConsumerState<TransactionDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  late AnimationController _timelineAnimationController;

  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _timelineFadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _timelineAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));

    _cardScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutBack,
    ));

    _timelineFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _timelineAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _headerAnimationController.forward();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _cardAnimationController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _timelineAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    _timelineAnimationController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check, color: Colors.white),
            const SizedBox(width: 12),
            Text('$label copied to clipboard'),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatCurrency(double amount, String currency) {
    final formatter = NumberFormat('#,##0.00');
    return '${formatter.format(amount)} $currency';
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy, h:mm:ss a').format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF0F1),
      body: Column(
        children: [
          // Header
          SlideTransition(
            position: _headerSlideAnimation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
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
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            size: 20,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(
                        delay: const Duration(milliseconds: 400),
                        duration: const Duration(milliseconds: 400),
                      ),

                  const Spacer(),

                  // Refresh button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(trackingProvider.notifier)
                          .refreshTransactionDetails();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC000).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.refresh,
                        size: 20,
                        color: const Color(0xFFFFC000),
                      ),
                    ),
                  ).animate().fadeIn(
                        delay: const Duration(milliseconds: 500),
                        duration: const Duration(milliseconds: 400),
                      ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction Details',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF181F30),
                        ),
                      ).animate().fadeIn(
                            delay: const Duration(milliseconds: 300),
                            duration: const Duration(milliseconds: 600),
                          ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              widget.transaction.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.transaction.statusIcon,
                              size: 16,
                              color: widget.transaction.statusColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.transaction.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.transaction.statusColor,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                            delay: const Duration(milliseconds: 400),
                            duration: const Duration(milliseconds: 600),
                          ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Tracking Number Card
                  ScaleTransition(
                    scale: _cardScaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Flash Tracking Number (FTN)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6E757D),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _copyToClipboard(
                              widget.transaction.trackingNumber,
                              'Tracking number',
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC000).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      const Color(0xFFFFC000).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.transaction.trackingNumber,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF181F30),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.copy,
                                    size: 20,
                                    color: const Color(0xFFFFC000),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Transaction Type and Amount Card
                  ScaleTransition(
                    scale: _cardScaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: const Color(0xFFFFC000),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                widget.transaction.formattedType,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF181F30),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInfoRow(
                              'Amount',
                              _formatCurrency(widget.transaction.amount,
                                  widget.transaction.currency)),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                              'Fee',
                              _formatCurrency(widget.transaction.fee,
                                  widget.transaction.currency)),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                              'Total with Fee',
                              _formatCurrency(widget.transaction.totalAmount,
                                  widget.transaction.currency)),
                          if (widget.transaction.exchangeRate != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                                'Exchange Rate',
                                widget.transaction.exchangeRate!
                                    .toStringAsFixed(15)),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Transaction Timeline
                  FadeTransition(
                    opacity: _timelineFadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaction Timeline',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF181F30),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ...widget.transaction.statusHistory
                              .asMap()
                              .entries
                              .map((entry) {
                            final index = entry.key;
                            final status = entry.value;
                            final isLast = index ==
                                widget.transaction.statusHistory.length - 1;

                            return _buildTimelineItem(status, isLast);
                          }).toList(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Blockchain Transaction (if available)
                  if (widget.transaction.blockchainTxHash != null)
                    ScaleTransition(
                      scale: _cardScaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.link,
                                  color: const Color(0xFFFFC000),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Blockchain Transaction',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF181F30),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => _copyToClipboard(
                                widget.transaction.blockchainTxHash!,
                                'Transaction hash',
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.transaction.blockchainTxHash!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'monospace',
                                          color: const Color(0xFF181F30),
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.copy,
                                      size: 20,
                                      color: Colors.grey[600],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            // Navigate back to track another
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: const Color(0xFF181F30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Track Another',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            // Navigate to home
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC000),
                            foregroundColor: const Color(0xFF181F30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Back to Home',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(
                        delay: const Duration(milliseconds: 800),
                        duration: const Duration(milliseconds: 600),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF6E757D),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF181F30),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(StatusHistory status, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: status.statusColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    status.statusIcon,
                    size: 16,
                    color: status.statusColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: status.statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                status.notes,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF181F30),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDateTime(status.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF6E757D),
                ),
              ),
              if (!isLast) const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    ).animate().slideX(
          begin: 0.3,
          delay: Duration(
              milliseconds: 200 +
                  (widget.transaction.statusHistory.indexOf(status) * 100)),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
        );
  }
}
