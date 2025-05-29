import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flash_transfer_app/config/theme.dart';
import 'package:flash_transfer_app/core/models/transaction_details.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';

class TransactionSummary extends ConsumerWidget {
  final TransactionDetails transactionDetails;

  const TransactionSummary({Key? key, required this.transactionDetails})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final paymentState = ref.watch(paymentProvider);

    // Use API data if available, otherwise fallback to mock data
    final estimateData = paymentState.estimateData;
    final hasApiData = estimateData != null;

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
            value: hasApiData
                ? "${formatter.format(estimateData.results.totalAmountToPay)} ${transactionDetails.sendCurrency}"
                : "${formatter.format(transactionDetails.sendAmount)} ${transactionDetails.sendCurrency}",
          ),

          const SizedBox(height: 12),

          _buildSummaryItem(
            label: "Transfer rate",
            value: hasApiData
                ? "1 ${transactionDetails.sendCurrency} = ${estimateData.exchangeRate.rate.toStringAsFixed(6)} ${transactionDetails.receiveCurrency}"
                : "1 ${transactionDetails.sendCurrency} = 1 ${transactionDetails.receiveCurrency}",
          ),

          const SizedBox(height: 12),

          // Show fee breakdown if available from API
          if (hasApiData) ...[
            _buildSummaryItem(
              label: "Base Fee",
              value:
                  "+${formatter.format(estimateData.fees.baseFee)} ${transactionDetails.sendCurrency}",
            ),
            const SizedBox(height: 8),
            _buildSummaryItem(
              label: "Provider Fee",
              value:
                  "+${formatter.format(estimateData.fees.providerFee)} ${transactionDetails.sendCurrency}",
            ),
            const SizedBox(height: 8),
            _buildSummaryItem(
              label: "Gas Fee",
              value:
                  "+${formatter.format(estimateData.fees.gasFee)} ${transactionDetails.sendCurrency}",
            ),
            const SizedBox(height: 8),
            _buildSummaryItem(
              label: "Total Fees",
              value:
                  "+${formatter.format(estimateData.fees.totalFees)} ${transactionDetails.sendCurrency}",
              isHighlighted: false,
            ),
          ] else ...[
            _buildSummaryItem(
              label: "Fee",
              value:
                  "+${formatter.format(transactionDetails.fee)} ${transactionDetails.feeCurrency}",
            ),
          ],

          const SizedBox(height: 16),

          // Divider
          const Divider(height: 1, color: Color(0xFFEBECED)),

          const SizedBox(height: 16),

          // Total to pay
          _buildSummaryItem(
            label: "Total to pay",
            value: hasApiData
                ? "${formatter.format(estimateData.results.totalAmountToPay)} ${transactionDetails.sendCurrency}"
                : "${formatter.format(transactionDetails.totalAmount)} ${transactionDetails.sendCurrency}",
            isHighlighted: true,
          ),

          const SizedBox(height: 12),

          // Recipient gets
          _buildSummaryItem(
            label: "Recipient Gets",
            value: hasApiData
                ? "${formatter.format(estimateData.results.cryptoAmountToReceive)} ${transactionDetails.receiveCurrency}"
                : "${formatter.format(transactionDetails.receiveAmount)} ${transactionDetails.receiveCurrency}",
          ),

          const SizedBox(height: 24),

          // Network information
          if (hasApiData) ...[
            _buildNetworkInfoSection(estimateData.networkInfo),
          ] else ...[
            _buildAvailabilitySection(),
          ],

          // Show discounts if any
          if (hasApiData && estimateData.fees.discounts > 0) ...[
            const SizedBox(height: 16),
            _buildDiscountsSection(estimateData.fees.discounts),
          ],
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

  Widget _buildNetworkInfoSection(networkInfo) {
    Color statusColor;
    String statusText;

    // Use networkCongestion value to determine status instead of non-existent congestionLevel
    final congestionLevel = _getCongestionLevel(networkInfo.networkCongestion);

    switch (congestionLevel.toLowerCase()) {
      case 'low':
        statusColor = const Color(0xFF00C735);
        statusText = "Fast";
        break;
      case 'medium':
        statusColor = Colors.orange;
        statusText = "Normal";
        break;
      case 'high':
        statusColor = Colors.red;
        statusText = "Slow";
        break;
      default:
        statusColor = const Color(0xFF00C735);
        statusText = "Immediate";
    }

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
              child: Icon(
                Icons.access_time,
                size: 20,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Network Status",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDarkColor,
                  ),
                ),
                Text(
                  networkInfo.humanReadableTime,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrayColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            statusText,
            style: const TextStyle(fontSize: 13, color: Colors.white),
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

  // Helper method to determine congestion level from numeric value
  String _getCongestionLevel(double networkCongestion) {
    if (networkCongestion < 0.3) {
      return 'low';
    } else if (networkCongestion < 0.7) {
      return 'medium';
    } else {
      return 'high';
    }
  }

  Widget _buildDiscountsSection(discounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Applied Discounts",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDarkColor,
          ),
        ),
        const SizedBox(height: 8),
        ...discounts.map((discount) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      discount.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6E757D),
                      ),
                    ),
                  ),
                  Text(
                    "-${NumberFormat.currency(symbol: '', decimalDigits: 2).format(discount.amount)}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            )),
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
