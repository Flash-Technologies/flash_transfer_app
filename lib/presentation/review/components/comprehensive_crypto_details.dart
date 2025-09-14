import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flash_transfer_app/config/theme.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';
import 'package:flash_transfer_app/providers/exchange_provider.dart';
import 'package:flash_transfer_app/providers/user_provider.dart';

class ComprehensiveCryptoDetails extends ConsumerStatefulWidget {
  const ComprehensiveCryptoDetails({Key? key}) : super(key: key);

  @override
  ConsumerState<ComprehensiveCryptoDetails> createState() => _ComprehensiveCryptoDetailsState();
}

class _ComprehensiveCryptoDetailsState extends ConsumerState<ComprehensiveCryptoDetails> {
  bool _showRawValues = false;
  bool _showProviderDetails = false;

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final exchangeForm = ref.watch(exchangeFormProvider);
    final userState = ref.watch(userProvider);
    final estimateData = paymentState.estimateData;
    final mobileMoneyDetails = paymentState.mobileMoneyDetails;
    
    if (estimateData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Sender Details Section
        _buildSenderDetailsSection(userState.user, mobileMoneyDetails),
        
        const SizedBox(height: 16),
        
        // Mobile Money Provider Details
        _buildMobileProviderSection(mobileMoneyDetails),
        
        const SizedBox(height: 16),
        
        // Receiver Details Section  
        _buildReceiverDetailsSection(paymentState),
        
        const SizedBox(height: 16),
        
        // Fee Breakdown Section
        _buildFeeBreakdownSection(estimateData, exchangeForm),
        
        const SizedBox(height: 16),
        
        // Amount Summary Section
        _buildAmountSummarySection(estimateData, exchangeForm),
      ],
    );
  }

  Widget _buildSenderDetailsSection(user, mobileMoneyDetails) {
    return _buildSectionCard(
      title: "Sender Details",
      child: Column(
        children: [
          _buildUserRow(
            name: "${user?.firstName ?? ''} ${user?.lastName ?? ''}",
            country: user?.countryName ?? 'Unknown',
            subtitle: "Mobile Money (${_getProviderDisplayName(mobileMoneyDetails?['provider'])})",
          ),
          const SizedBox(height: 12),
          _buildDetailRow("Source of funds", "SAVINGS"),
          _buildDetailRow("Purpose of transaction", "EDUCATION"), 
          _buildDetailRow("Coverage Area", "West & Central Africa"),
        ],
      ),
    );
  }

  Widget _buildMobileProviderSection(mobileMoneyDetails) {
    final provider = mobileMoneyDetails?['provider'] ?? 'wave';
    
    return _buildSectionCard(
      title: "Mobile Money (${_getProviderDisplayName(provider)})",
      child: Column(
        children: [
          _buildDetailRow("Mobile Provider", _getProviderDisplayName(provider)),
          _buildDetailRow("Phone Number", mobileMoneyDetails?['phoneNumber'] ?? 'N/A'),
          _buildExpandableProviderDetails(provider, mobileMoneyDetails),
          const SizedBox(height: 12),
          _buildSecurePaymentIndicator(),
        ],
      ),
    );
  }

  Widget _buildReceiverDetailsSection(paymentState) {
    final walletAddress = paymentState.selectedWalletAddress ?? 'N/A';
    
    return _buildSectionCard(
      title: "Receiver details",
      child: Column(
        children: [
          _buildUserRow(
            name: "Abu Alaeddine",
            country: "Cote d'Ivoire", 
            subtitle: "ETH Wallet",
          ),
          const SizedBox(height: 12),
          _buildDetailRowWithCopy("Wallet Address", walletAddress),
          _buildDetailRow("Blockchain Network", "ETHEREUM"),
          _buildDetailRow("Receiver Country", "Cote d'Ivoire"),
        ],
      ),
    );
  }

  Widget _buildFeeBreakdownSection(estimateData, exchangeForm) {
    final fees = estimateData.fees;
    final discounts = estimateData.discounts;
    
    return _buildSectionCard(
      title: "Fee Breakdown",
      child: Column(
        children: [
          _buildDetailRowWithFullValue("You sent", "${estimateData.request.amount}", "${exchangeForm.fromCurrency?.code ?? 'XOF'}"),
          _buildDetailRowWithFullValue("Transfer rate", "LIVE", ""),
          _buildTransferRateRow(estimateData.exchangeRate.rate, exchangeForm),
          _buildDetailRowWithFullValue("Platform Charges", "+${fees.platformCharges}", "${exchangeForm.fromCurrency?.code ?? 'XOF'}"),
          _buildDetailRowWithFullValue("Network Fee", "+${fees.gasFee}", "${exchangeForm.fromCurrency?.code ?? 'XOF'}"),
          
          // Discounts - using fees properties directly for amounts
          if (fees.loyaltyDiscount > 0)
            _buildDiscountRow("Loyalty Discount", discounts.loyalty.rank.isNotEmpty ? discounts.loyalty.rank : "SILVER", "-${fees.loyaltyDiscount}", "${exchangeForm.fromCurrency?.code ?? 'XOF'}"),
          
          if (fees.nftDiscount > 0)
            _buildDiscountRow("NFT Holder Discount", discounts.nft.rarity.isNotEmpty ? discounts.nft.rarity : "COMMON", "-${fees.nftDiscount}", "${exchangeForm.fromCurrency?.code ?? 'XOF'}"),
          
          _buildDetailRowWithFullValue("Total Savings", "-${fees.totalDiscount}", "${exchangeForm.fromCurrency?.code ?? 'XOF'}"),
          
          const Divider(),
          
          _buildToggleRawValues(),
          
          const SizedBox(height: 8),
          
          _buildDetailRowWithFullValue("Total to pay", "${fees.totalFee + estimateData.request.amount}", "${exchangeForm.fromCurrency?.code ?? 'XOF'}", isTotal: true),
          _buildDetailRowWithFullValue("Recipient Gets", "${estimateData.results.cryptoAmountToReceive}", "${exchangeForm.toCurrency?.code ?? 'ETH'}", isTotal: true),
          
          const SizedBox(height: 12),
          
          _buildNetworkStatus(estimateData.networkInfo),
        ],
      ),
    );
  }

  Widget _buildAmountSummarySection(estimateData, exchangeForm) {
    return _buildSectionCard(
      title: "Amount",
      titleWidget: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.green.shade400,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text("${estimateData.request.amount} ${exchangeForm.fromCurrency?.code ?? 'XOF'}"),
        ],
      ),
      subtitle: "Mobile Money (${_getProviderDisplayName(ref.read(paymentProvider).mobileMoneyDetails?['provider'])})",
      child: Column(
        children: [
          const Text("Transfer Summary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          
          _buildToggleButton("Raw", _showRawValues, (value) {
            setState(() {
              _showRawValues = value;
            });
          }),
          
          const SizedBox(height: 12),
          
          _buildDetailRowWithFullValue("Amount to send", "${estimateData.results.totalAmountToPay}", "${exchangeForm.fromCurrency?.code ?? 'XOF'}"),
          _buildDetailRowWithFullValue("Transfer Fee", "${estimateData.fees.totalFee}", "${exchangeForm.fromCurrency?.code ?? 'XOF'}"),
          _buildDetailRowWithFullValue("Total Cost", "${estimateData.results.totalAmountToPay}", "${exchangeForm.fromCurrency?.code ?? 'XOF'}"),
          _buildDetailRowWithFullValue("Total to recipient", "${estimateData.results.cryptoAmountToReceive}", "${exchangeForm.toCurrency?.code ?? 'ETH'}"),
          _buildDetailRowWithFullValue("Exchange Rate", "1 ${exchangeForm.fromCurrency?.code ?? 'XOF'} = ${estimateData.exchangeRate.rate} ${exchangeForm.toCurrency?.code ?? 'ETH'}", ""),
          _buildDetailRow("Network Congestion", "Medium"),
          
          const Divider(),
          
          _buildDetailRowWithFullValue("Total to pay", "${estimateData.results.totalAmountToPay}", "${exchangeForm.fromCurrency?.code ?? 'XOF'}", isTotal: true),
          _buildDetailRowWithFullValue("Recipient Gets", "${estimateData.results.cryptoAmountToReceive}", "${exchangeForm.toCurrency?.code ?? 'ETH'}", isTotal: true),
          
          const SizedBox(height: 12),
          
          _buildAvailabilityIndicator(estimateData.networkInfo),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child, Widget? titleWidget, String? subtitle}) {
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
          titleWidget ?? Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF273240),
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

  Widget _buildUserRow({required String name, required String country, String? subtitle}) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFC000), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/profile.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDarkColor,
                ),
              ),
              Text(
                country,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6A6A6A),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6E757D),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithFullValue(String label, String value, String currency, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                color: isTotal ? Colors.black : const Color(0xFF6E757D),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () {
                if (value.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: "$value $currency".trim()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(
                    "$value ${currency}".trim(),
                    style: TextStyle(
                      fontSize: isTotal ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color: isTotal ? Colors.black : Colors.black,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithCopy(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6E757D),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Address copied to clipboard')),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const Icon(Icons.copy, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferRateRow(double rate, exchangeForm) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Rate ID: 1757875041080",
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: "1 ${exchangeForm.fromCurrency?.code ?? 'XOF'} = $rate ${exchangeForm.toCurrency?.code ?? 'ETH'}"));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rate copied to clipboard')),
              );
            },
            child: Container(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  "1 ${exchangeForm.fromCurrency?.code ?? 'XOF'} = $rate ${exchangeForm.toCurrency?.code ?? 'ETH'}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountRow(String label, String tier, String value, String currency) {
    Color tierColor = tier == 'SILVER' ? Colors.grey.shade600 : 
                     tier == 'COMMON' ? Colors.green.shade600 : Colors.blue.shade600;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6E757D),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tierColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tier,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: tierColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            flex: 1,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Text(
                "$value $currency",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRawValues() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showRawValues = !_showRawValues;
        });
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Show Details",
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Text(
                "Raw Values",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Icon(
                _showRawValues ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: value ? AppTheme.primaryColor : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkStatus(networkInfo) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.orange.shade400,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Network Status",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                "${networkInfo.humanReadableTime}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Normal",
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityIndicator(networkInfo) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.green.shade400,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flash_on, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Text(
            "Availability",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade400,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${networkInfo.estimatedTimeSeconds} seconds",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableProviderDetails(String provider, mobileMoneyDetails) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showProviderDetails = !_showProviderDetails;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Provider Details",
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  const Text(
                    "Show",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  Icon(
                    _showProviderDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_showProviderDetails) ...[
          const SizedBox(height: 8),
          _buildDetailRow("Service Code", mobileMoneyDetails?['serviceCode'] ?? 'N/A'),
          _buildDetailRow("API Method", mobileMoneyDetails?['apiPaymentMethod'] ?? 'N/A'),
        ],
      ],
    );
  }

  Widget _buildSecurePaymentIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green.shade400,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Secure Mobile Payment",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "Your mobile money payment will be processed securely through our trusted payment network",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6E757D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getProviderDisplayName(String? provider) {
    switch (provider?.toLowerCase()) {
      case 'orange':
        return 'Orange Money';
      case 'wave':
        return 'Wave';
      case 'mtn':
        return 'MTN';
      case 'moov':
        return 'Moov Money';
      default:
        return 'Mobile Money Provider';
    }
  }
}