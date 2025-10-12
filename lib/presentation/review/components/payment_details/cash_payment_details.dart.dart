import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flash_transfer_app/config/theme.dart';
import 'package:flash_transfer_app/core/models/payment_details.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';
import 'package:flash_transfer_app/providers/exchange_provider.dart';

class CashPaymentDetails extends ConsumerWidget {
  final PaymentDetails details;

  const CashPaymentDetails({
    Key? key,
    required this.details,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(paymentProvider);
    final exchangeForm = ref.watch(exchangeFormProvider);
    
    // Get sender and recipient info from the provider
    final senderInfo = paymentState.cashSenderInfo;
    final recipientInfo = paymentState.cashRecipientInfo;
    
    return Column(
      children: [
        // Sender Details Section
        _buildSenderSection(senderInfo, exchangeForm),
        const SizedBox(height: 16),
        
        // Receiver Details Section  
        _buildReceiverSection(recipientInfo, exchangeForm),
        const SizedBox(height: 16),
        
        // Transaction Details Section
        _buildTransactionSection(),
      ],
    );
  }

  Widget _buildSenderSection(Map<String, dynamic>? senderInfo, exchangeForm) {
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
          const Text(
            "Sender Details",
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
          _buildDetailRow("Source of funds", "SAVINGS"),
          const SizedBox(height: 8),
          _buildDetailRow("Purpose of transaction", "EDUCATION"),
          const SizedBox(height: 8),
          _buildDetailRow("Coverage Area", "West & Central Africa"),
        ],
      ),
    );
  }

  Widget _buildReceiverSection(Map<String, dynamic>? recipientInfo, exchangeForm) {
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
          const Text(
            "Receiver details",
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
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
                      'Cash Pickup',
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
          
          _buildDetailRow("Blockchain Network", "ETHEREUM"),
          const SizedBox(height: 8),
          _buildDetailRow("Receiver Country", recipientInfo?['cashPickupCountry'] != null 
              ? _getCountryName(recipientInfo!['cashPickupCountry'])
              : 'Cote d\'Ivoire'),
        ],
      ),
    );
  }

  Widget _buildTransactionSection() {
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
          const Text(
            "Transaction Details",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF273240),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildDetailRow("You sent", "0.000001 ETH"),
          const SizedBox(height: 8),
          _buildDetailRow("Transfer rate", "1 ETH = 100 XOF", isRate: true),
          const SizedBox(height: 16),
          
          const Divider(),
          const SizedBox(height: 16),
          
          _buildDetailRow("Total to pay", "0.000001 ETH", isBold: true),
          const SizedBox(height: 8),
          _buildDetailRow("Recipient Gets", "0.000001 XOF", isBold: true),
          
          const SizedBox(height: 16),
          
          // Availability
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
                        'Availability',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Transaction unavailable at this time',
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
                    'Unavailable',
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

  Widget _buildDetailRow(String label, String value, {bool isBold = false, bool isRate = false}) {
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
                  'LIVE',
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
}