import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/transaction_model.dart';

class TransactionCardWidget extends StatefulWidget {
  final Transaction transaction;
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
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: _getBorderColor(), width: 1),
              ),
              child: Row(
                children: [
                  // Profile Avatar or Character
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getRecipientColor(),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        _getRecipientInitial(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Transaction Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getRecipientName(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF181F30),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Type indicator (Send/Receive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isReceiveTransaction() ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _isReceiveTransaction() ? 'Receive' : 'Send',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isReceiveTransaction() ? Colors.green.shade600 : Colors.red.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        Text(
                          _formatDate(widget.transaction.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6E757D),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Amount and Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_isReceiveTransaction() ? '+' : '-'}${widget.transaction.amount.toStringAsFixed(2)} ${widget.transaction.currency}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isReceiveTransaction() ? Colors.green.shade600 : Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: widget.transaction.statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: widget.transaction.statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getStatusDisplayName(widget.transaction.status),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: widget.transaction.statusColor,
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
          );
        },
      ),
    );
  }

  // Get recipient name from transaction data
  String _getRecipientName() {
    // Try to get the destination wallet address or beneficiary name
    if (widget.transaction.destinationDetails != null) {
      final walletAddress = widget.transaction.destinationDetails!['walletAddress'] as String?;
      if (walletAddress != null && walletAddress.isNotEmpty) {
        // Show first 6 and last 4 characters of wallet address
        if (walletAddress.length > 10) {
          return '${walletAddress.substring(0, 6)}...${walletAddress.substring(walletAddress.length - 4)}';
        }
        return walletAddress;
      }
    }
    
    // Fallback to user's own name or a generic name
    if (widget.transaction.user != null) {
      return widget.transaction.user!.fullName.isNotEmpty 
          ? widget.transaction.user!.fullName 
          : 'Wallet Transfer';
    }
    
    return 'Crypto Transfer';
  }

  // Get first character for avatar
  String _getRecipientInitial() {
    final name = _getRecipientName();
    if (name.startsWith('0x')) {
      return 'W'; // W for Wallet
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  // Generate color based on name
  Color _getRecipientColor() {
    final name = _getRecipientName();
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEF4444), // Red
      const Color(0xFF84CC16), // Lime
    ];
    
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    return colors[hash.abs() % colors.length];
  }

  // Check if this is a receive transaction (user is receiving money)
  bool _isReceiveTransaction() {
    // In our API, if the transaction type is CASH_TO_CRYPTO and user is receiving crypto
    // Or if it's CRYPTO_TO_CASH and user is receiving cash
    // For now, we'll assume all transactions in the list are "send" transactions
    // You can adjust this logic based on your business requirements
    return false; // All transactions are "send" from user's perspective
  }

  Color _getBorderColor() {
    return widget.transaction.statusColor.withValues(alpha: 0.2);
  }

  String _getStatusDisplayName(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return 'Completed';
      case 'PENDING':
        return 'Pending';
      case 'PROCESSING':
        return 'Processing';
      case 'FAILED':
        return 'Failed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    // Format like: Sep 13, 2025, 04:35 PM
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;
    
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    
    return '$month $day, $year, ${hour.toString().padLeft(2, '0')}:$minute $ampm';
  }
}
