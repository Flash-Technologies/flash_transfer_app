import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/translation_service.dart';

class TransactionCardWidget extends StatefulWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;

  const TransactionCardWidget({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  State<TransactionCardWidget> createState() => _TransactionCardWidgetState();
}

class _TransactionCardWidgetState extends State<TransactionCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translationService = TranslationService.instance;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: _getBorderColor(), width: 1),
              ),
              child: Row(
                children: [
                  // Transaction Type Indicator
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getTypeColor().withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getTypeIcon(),
                      color: _getTypeColor(),
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Transaction Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.transaction.recipient ??
                                    widget.transaction.receiverName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF181F30),
                                ),
                              ),
                            ),
                            Text(
                              '${widget.transaction.type == TransactionType.send ? '-' : '+'}${widget.transaction.amount.toStringAsFixed(2)} ${widget.transaction.currency}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    widget.transaction.type ==
                                            TransactionType.send
                                        ? const Color(0xFFFF3E24)
                                        : const Color(0xFF00C735),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Text(
                              _formatDate(
                                widget.transaction.date ??
                                    widget.transaction.createdAt,
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6E757D),
                              ),
                            ),

                            const Spacer(),

                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getStatusText(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getTypeColor() {
    if (widget.transaction.type == null) return const Color(0xFF6E757D);

    switch (widget.transaction.type!) {
      case TransactionType.send:
        return const Color(0xFFFF3E24);
      case TransactionType.receive:
        return const Color(0xFF00C735);
    }
  }

  IconData _getTypeIcon() {
    if (widget.transaction.type == null) return Icons.swap_horiz;

    switch (widget.transaction.type!) {
      case TransactionType.send:
        return Icons.arrow_upward;
      case TransactionType.receive:
        return Icons.arrow_downward;
    }
  }

  Color _getBorderColor() {
    final statusEnum = _parseStatus(widget.transaction.status);
    switch (statusEnum) {
      case TransactionStatus.completed:
        return const Color(0xFF00C735).withOpacity(0.3);
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        return const Color(0xFFFFC000).withOpacity(0.3);
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        return const Color(0xFFFF3E24).withOpacity(0.3);
    }
  }

  Color _getStatusColor() {
    final statusEnum = _parseStatus(widget.transaction.status);
    switch (statusEnum) {
      case TransactionStatus.completed:
        return const Color(0xFF00C735);
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        return const Color(0xFFFFC000);
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        return const Color(0xFFFF3E24);
    }
  }

  String _getStatusText() {
    final statusEnum = _parseStatus(widget.transaction.status);
    switch (statusEnum) {
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.processing:
        return 'Processing';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  TransactionStatus _parseStatus(String status) {
    try {
      return TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == status,
        orElse: () => TransactionStatus.pending,
      );
    } catch (e) {
      return TransactionStatus.pending;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}m ago';
    }
  }
}
