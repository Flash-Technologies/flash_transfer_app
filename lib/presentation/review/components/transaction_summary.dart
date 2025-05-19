import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:flash_transfer_app/config/theme.dart';
import 'package:flash_transfer_app/core/models/transaction_details.dart';

class TransactionSummary extends StatelessWidget {
  final TransactionDetails transactionDetails;

  const TransactionSummary({Key? key, required this.transactionDetails})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount details
          _buildSummaryItem(
            label: "You sent",
            value:
                "${formatter.format(transactionDetails.sendAmount)} ${transactionDetails.sendCurrency}",
          ),

          const SizedBox(height: 12),

          _buildSummaryItem(
            label: "Transfer rate",
            value:
                "1 ${transactionDetails.sendCurrency} = 1 ${transactionDetails.receiveCurrency}",
          ),

          const SizedBox(height: 12),

          _buildSummaryItem(
            label: "Fee",
            value:
                "+${formatter.format(transactionDetails.fee)} ${transactionDetails.feeCurrency}",
          ),

          const SizedBox(height: 16),

          // Divider
          const Divider(height: 1, color: Color(0xFFEBECED)),

          const SizedBox(height: 16),

          // Total to pay
          _buildSummaryItem(
            label: "Total to pay",
            value:
                "${formatter.format(transactionDetails.totalAmount)} ${transactionDetails.sendCurrency}",
            isHighlighted: true,
          ),

          const SizedBox(height: 12),

          // Recipient gets
          _buildSummaryItem(
            label: "Recipient Gets",
            value:
                "${formatter.format(transactionDetails.receiveAmount)} ${transactionDetails.receiveCurrency}",
          ),

          const SizedBox(height: 24),

          // Availability section
          _buildAvailabilitySection(),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isHighlighted ? 15 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
            color: const Color(0xFF6E757D),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 18 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Icon and label
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Image.asset(
                'assets/images/run.png',
                width: 24,
                height: 24,
              ),
            ),

            const SizedBox(width: 12),

            const Text(
              "Availability",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDarkColor,
              ),
            ),
          ],
        ),

        // Status badge
        Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00C735),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                "Immediate",
                style: TextStyle(fontSize: 13, color: Colors.white),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              duration: 2.seconds,
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.05, 1.05),
              curve: Curves.easeInOut,
            ),
      ],
    );
  }
}
