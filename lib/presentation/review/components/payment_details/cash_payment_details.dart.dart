import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flash_transfer_app/core/models/payment_details.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';
import 'package:flash_transfer_app/providers/exchange_provider.dart';
import '../../../../providers/language_provider.dart';

class CashPaymentDetails extends ConsumerWidget {
  final PaymentDetails details;

  const CashPaymentDetails({
    Key? key,
    required this.details,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationHelperProvider);
    final paymentState = ref.watch(paymentProvider);
    final exchangeForm = ref.watch(exchangeFormProvider);

    // Get sender and recipient info from the provider
    final senderInfo = paymentState.cashSenderInfo;
    final recipientInfo = paymentState.cashRecipientInfo;

    // Get estimate data
    final estimateData = paymentState.cryptoToCashEstimate;
    
    return Column(
      children: [
        // Sender Details Section
        _buildSenderSection(senderInfo, exchangeForm, tr),
        const SizedBox(height: 12),

        // Receiver Details Section
        _buildReceiverSection(recipientInfo, exchangeForm, tr, estimateData),
        const SizedBox(height: 12),

        // Transaction Details Section
        _buildTransactionSection(tr, estimateData),

        // Add bottom padding to prevent overlap with navigation buttons
        SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
      ],
    );
  }

  Widget _buildSenderSection(Map<String, dynamic>? senderInfo, exchangeForm, String Function(String) tr) {
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
          Text(
            tr('review.cashPaymentDetails.senderDetails'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF273240),
            ),
          ),
          const SizedBox(height: 16),
          
          // Sender info
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senderInfo != null 
                          ? '${senderInfo['firstName'] ?? ''} ${senderInfo['lastName'] ?? ''}'
                          : 'Sai Bhilare bhaijaan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF273240),
                      ),
                    ),
                    Text(
                      senderInfo?['country'] != null 
                          ? _getCountryName(senderInfo!['country'])
                          : 'India',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6E757D),
                      ),
                    ),
                    Text(
                      '${exchangeForm.fromCurrency?.code ?? 'ETH'} Wallet',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6E757D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Source of funds and Purpose
          _buildDetailRow(tr('review.cashPaymentDetails.sourceOfFunds'), senderInfo?['sourceOfFunds'] ?? "SAVINGS", tr),
          const SizedBox(height: 8),
          _buildDetailRow(tr('review.cashPaymentDetails.purposeOfTransaction'), senderInfo?['purposeOfTransaction'] ?? "EDUCATION", tr),
          const SizedBox(height: 8),
          _buildDetailRow(tr('review.cashPaymentDetails.coverageArea'), "West & Central Africa", tr),
        ],
      ),
    );
  }

  Widget _buildReceiverSection(Map<String, dynamic>? recipientInfo, exchangeForm, String Function(String) tr, Map<String, dynamic>? estimateData) {
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
          Text(
            tr('review.cashPaymentDetails.receiverDetails'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF273240),
            ),
          ),
          const SizedBox(height: 16),
          
          // Receiver info
          Row(
            children: [
              Builder(
                builder: (context) {
                  final recipientName = recipientInfo != null 
                      ? '${recipientInfo['firstName'] ?? ''} ${recipientInfo['lastName'] ?? ''}'
                      : 'Abu Alaeddine';
                  final firstLetter = recipientName.isNotEmpty ? recipientName[0].toUpperCase() : '?';
                  
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        firstLetter,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipientInfo != null 
                          ? '${recipientInfo['firstName'] ?? ''} ${recipientInfo['lastName'] ?? ''}'
                          : 'Abu Alaeddine',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF273240),
                      ),
                    ),
                    Text(
                      recipientInfo?['cashPickupCountry'] != null 
                          ? _getCountryName(recipientInfo!['cashPickupCountry'])
                          : 'Cote d\'Ivoire',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6E757D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Cash pickup details
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: Colors.green.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tr('review.cashPaymentDetails.cashPickup'),
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          _buildDetailRow(tr('review.cashPaymentDetails.blockchainNetwork'),
              estimateData?['request']?['blockchainNetwork']?.toString().toUpperCase() ?? "ETHEREUM", tr),
          const SizedBox(height: 8),
          _buildDetailRow(tr('review.cashPaymentDetails.receiverCountry'), recipientInfo?['cashPickupCountry'] != null
              ? _getCountryName(recipientInfo!['cashPickupCountry'])
              : 'Cote d\'Ivoire', tr),
        ],
      ),
    );
  }

  Widget _buildTransactionSection(String Function(String) tr, Map<String, dynamic>? estimateData) {
    final request = estimateData?['request'];
    final exchangeRate = estimateData?['exchangeRate'];
    final fees = estimateData?['fees'];
    final discounts = estimateData?['discounts'];
    final networkInfo = estimateData?['networkInfo'];
    final cashHandling = estimateData?['cashHandling'];

    // Calculate amounts
    final amount = request?['amount'] ?? 0.0;
    final sourceCurrency = request?['sourceCurrency'] ?? 'ETH';
    final destinationCurrency = request?['destinationCurrency'] ?? 'XOF';
    final rate = exchangeRate?['rate'] ?? 0.0;

    final totalFee = fees?['totalFee'] ?? 0.0;
    final totalToPay = amount + totalFee;

    final beforeHandlingCharge = cashHandling?['beforeHandlingCharge'] ?? 0.0;

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
          Text(
            tr('review.cashPaymentDetails.transactionDetails'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF273240),
            ),
          ),
          const SizedBox(height: 16),

          // You sent
          _buildDetailRow(tr('review.cashPaymentDetails.youSent'),
              '${amount.toStringAsFixed(8)} $sourceCurrency', tr),
          const SizedBox(height: 8),

          // Transfer rate
          _buildDetailRow(tr('review.cashPaymentDetails.transferRate'),
              '1 $sourceCurrency = ${rate.toStringAsFixed(4)} $destinationCurrency', tr, isRate: true),
          const SizedBox(height: 16),

          // Fee Breakdown Section
          _buildFeeBreakdown(tr, fees, discounts, sourceCurrency),
          const SizedBox(height: 16),

          const Divider(),
          const SizedBox(height: 16),

          // Total to pay
          _buildDetailRow(tr('review.cashPaymentDetails.totalToPay'),
              '${totalToPay.toStringAsFixed(8)} $sourceCurrency', tr, isBold: true),
          const SizedBox(height: 8),

          // Total to recipient (before handling)
          _buildDetailRow(tr('review.cashPaymentDetails.recipientGets'),
              '${beforeHandlingCharge.toStringAsFixed(2)} $destinationCurrency', tr, isBold: true),

          const SizedBox(height: 16),

          // Cash Handling Breakdown
          _buildCashHandlingBreakdown(tr, cashHandling, destinationCurrency),
          const SizedBox(height: 16),

          // Network Congestion
          if (networkInfo != null)
            _buildNetworkCongestion(tr, networkInfo),

          const SizedBox(height: 16),

          // Availability
          if (estimateData?['transactionAvailable'] == false)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.red.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(
                        tr('review.cashPaymentDetails.availability'),
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      Text(
                        tr('review.cashPaymentDetails.transactionUnavailable'),
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tr('review.cashPaymentDetails.unavailable'),
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 10,
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

  Widget _buildDetailRow(String label, String value, String Function(String) tr, {bool isBold = false, bool isRate = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6E757D),
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                color: isBold ? Color(0xFF273240) : Color(0xFF273240),
              ),
            ),
            if (isRate)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tr('review.cashPaymentDetails.live'),
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _getCountryName(String countryCode) {
    final countries = {
      'CI': 'Cote d\'Ivoire',
      'SN': 'Senegal',
      'ML': 'Mali',
      'BJ': 'Benin',
      'BF': 'Burkina Faso',
      'TG': 'Togo',
      'NE': 'Niger',
      'GW': 'Guinea-Bissau',
    };
    return countries[countryCode] ?? countryCode;
  }

  Widget _buildFeeBreakdown(String Function(String) tr, Map<String, dynamic>? fees, Map<String, dynamic>? discounts, String currency) {
    if (fees == null) return const SizedBox.shrink();

    final platformCharges = fees['platformCharges'] ?? 0.0;
    final networkFee = fees['gasFee'] ?? 0.0;
    final loyaltyDiscount = fees['loyaltyDiscount'] ?? 0.0;
    final nftDiscount = fees['nftDiscount'] ?? 0.0;
    final totalSavings = fees['totalDiscount'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
              const SizedBox(width: 8),
              Text(
                tr('review.cashPaymentDetails.feeBreakdown'),
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFeeRow(tr('review.cashPaymentDetails.platformCharges'),
              '+${platformCharges.toStringAsFixed(10)} $currency', false),
          const SizedBox(height: 6),
          _buildFeeRow(tr('review.cashPaymentDetails.networkFee'),
              '+${networkFee.toStringAsFixed(10)} $currency', false),

          // Loyalty Discount
          if (discounts?['loyalty']?['applied'] == true) ...[
            const SizedBox(height: 6),
            _buildFeeRow(
              '${tr('review.cashPaymentDetails.loyaltyDiscount')} ${_buildDiscountBadge(discounts!['loyalty']['rank'] ?? 'SILVER')}',
              '-${loyaltyDiscount.toStringAsFixed(10)} $currency',
              true,
            ),
          ],

          // NFT Discount
          if (discounts?['nft']?['applied'] == true) ...[
            const SizedBox(height: 6),
            _buildFeeRow(
              '${tr('review.cashPaymentDetails.nftDiscount')} ${_buildDiscountBadge(discounts!['nft']['rarity'] ?? 'COMMON')}',
              '-${nftDiscount.toStringAsFixed(10)} $currency',
              true,
            ),
          ],

          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Total Savings
          Row(
            children: [
              Icon(Icons.savings_outlined, color: Colors.green.shade600, size: 16),
              const SizedBox(width: 6),
              Text(
                tr('review.cashPaymentDetails.totalSavings'),
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '-${totalSavings.toStringAsFixed(10)} $currency',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, String value, bool isDiscount) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDiscount ? Colors.green.shade700 : const Color(0xFF6E757D),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDiscount ? Colors.green.shade700 : const Color(0xFF273240),
          ),
        ),
      ],
    );
  }

  String _buildDiscountBadge(String text) {
    return '[$text]';
  }

  Widget _buildCashHandlingBreakdown(String Function(String) tr, Map<String, dynamic>? cashHandling, String currency) {
    if (cashHandling == null) return const SizedBox.shrink();

    final beforeHandling = cashHandling['beforeHandlingCharge'] ?? 0.0;
    final handlingRate = ((cashHandling['handlingChargeRate'] ?? 0.0) * 100).toStringAsFixed(0);
    final handlingCharge = cashHandling['handlingChargeAmount'] ?? 0.0;
    final actualCash = cashHandling['actualCashToReceive'] ?? 0.0;
    final note = cashHandling['note'] ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.money_outlined, color: Colors.orange.shade600, size: 16),
              const SizedBox(width: 8),
              Text(
                tr('review.cashPaymentDetails.cashHandlingBreakdown'),
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildFeeRow(tr('review.cashPaymentDetails.beforeHandlingCharge'),
              '${beforeHandling.toStringAsFixed(2)} $currency', false),
          const SizedBox(height: 6),
          _buildFeeRow('${tr('review.cashPaymentDetails.handlingCharge')} ($handlingRate%)',
              '-${handlingCharge.toStringAsFixed(2)} $currency', false),

          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          Row(
            children: [
              Text(
                tr('review.cashPaymentDetails.actualCashToReceive'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF273240),
                ),
              ),
              const Spacer(),
              Text(
                '${actualCash.toStringAsFixed(2)} $currency',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),

          if (note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note,
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNetworkCongestion(String Function(String) tr, Map<String, dynamic> networkInfo) {
    final congestion = networkInfo['networkCongestion'] ?? 0.0;

    Color congestionColor;
    String congestionLevel;

    if (congestion <= 0.3) {
      congestionColor = Colors.green;
      congestionLevel = tr('review.cashPaymentDetails.low');
    } else if (congestion <= 0.7) {
      congestionColor = Colors.orange;
      congestionLevel = tr('review.cashPaymentDetails.medium');
    } else {
      congestionColor = Colors.red;
      congestionLevel = tr('review.cashPaymentDetails.high');
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          tr('review.cashPaymentDetails.networkCongestion'),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6E757D),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: congestionColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            congestionLevel,
            style: TextStyle(
              color: congestionColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}