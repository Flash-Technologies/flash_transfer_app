import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/translation_service.dart';

// Transaction Header Widget
class TransactionHeaderWidget extends StatelessWidget {
  final String title;
  final VoidCallback onBackPressed;

  const TransactionHeaderWidget({
    super.key,
    required this.title,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 24),
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
              onBackPressed();
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
                  Icon(Icons.arrow_back_ios, size: 20, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(
                    TranslationService.instance.translate(
                      'transaction.screen.back',
                    ),
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

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181F30),
              ),
            ).animate().fadeIn(
              delay: const Duration(milliseconds: 500),
              duration: const Duration(milliseconds: 400),
            ),
          ),
        ],
      ),
    );
  }
}

// Status Indicator Widget
class StatusIndicatorWidget extends StatefulWidget {
  final TransactionStatus status;
  final double size;

  const StatusIndicatorWidget({
    super.key,
    required this.status,
    this.size = 24,
  });

  @override
  State<StatusIndicatorWidget> createState() => _StatusIndicatorWidgetState();
}

class _StatusIndicatorWidgetState extends State<StatusIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start pulsing animation for pending/processing status
    if (_shouldPulse()) {
      _pulseController.repeat(reverse: true);
    }
  }

  bool _shouldPulse() {
    return widget.status == TransactionStatus.pending ||
        widget.status == TransactionStatus.processing;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _shouldPulse() ? _pulseAnimation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: _getStatusColor(), width: 2),
            ),
            child: Icon(
              _getStatusIcon(),
              color: _getStatusColor(),
              size: widget.size * 0.6,
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor() {
    switch (widget.status) {
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

  IconData _getStatusIcon() {
    switch (widget.status) {
      case TransactionStatus.completed:
        return Icons.check;
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        return Icons.access_time;
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        return Icons.close;
    }
  }
}

// Transaction Summary Widget (for future use)
class TransactionSummaryWidget extends StatelessWidget {
  final int totalTransactions;
  final double totalSent;
  final double totalReceived;

  const TransactionSummaryWidget({
    super.key,
    required this.totalTransactions,
    required this.totalSent,
    required this.totalReceived,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          margin: const EdgeInsets.all(20),
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
              const Text(
                'Transaction Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF181F30),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Total',
                      '$totalTransactions',
                      Icons.receipt_long,
                      const Color(0xFF2475FF),
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Sent',
                      '\$${totalSent.toStringAsFixed(0)}',
                      Icons.arrow_upward,
                      const Color(0xFFFF3E24),
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Received',
                      '\$${totalReceived.toStringAsFixed(0)}',
                      Icons.arrow_downward,
                      const Color(0xFF00C735),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 600))
        .slideY(begin: 0.3, curve: Curves.easeOutBack);
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),

        const SizedBox(height: 8),

        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF181F30),
          ),
        ),

        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6E757D)),
        ),
      ],
    );
  }
}

// Import these enums if not already imported
enum TransactionStatus { pending, completed, failed, cancelled, processing }
