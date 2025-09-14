import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';

// Wallet balance model
class WalletBalance {
  final String token;
  final String balance;
  final double balanceUsd;
  final String networkName;
  final int decimals;
  final double formatted;

  WalletBalance({
    required this.token,
    required this.balance,
    required this.balanceUsd,
    required this.networkName,
    required this.decimals,
    required this.formatted,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      token: json['symbol'] ?? '',
      balance: json['balance']?.toString() ?? '0',
      balanceUsd: 0.0, // API doesn't provide USD value, calculate if needed
      networkName: json['networkName'] ?? '',
      decimals: json['decimals'] ?? 18,
      formatted: _parseDouble(json['formatted']),
    );
  }

  // Helper method to safely parse double from dynamic value
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Helper method to get display balance
  String get displayBalance => formatted.toStringAsFixed(6);
}

class SendCryptoPaymentScreen extends ConsumerStatefulWidget {
  const SendCryptoPaymentScreen({super.key});

  @override
  ConsumerState<SendCryptoPaymentScreen> createState() =>
      _SendCryptoPaymentScreenState();
}

class _SendCryptoPaymentScreenState
    extends ConsumerState<SendCryptoPaymentScreen> {
  String selectedNetwork = 'ethereum';

  final List<Map<String, dynamic>> networks = [
    {
      'id': 'ethereum',
      'name': 'Ethereum Mainnet',
      'icon': Icons.diamond,
      'color': AppColors.primaryBlue,
    },
    {
      'id': 'polygon',
      'name': 'Polygon',
      'icon': Icons.hexagon,
      'color': Colors.purple,
    },
    {
      'id': 'bsc',
      'name': 'BSC',
      'icon': Icons.currency_bitcoin,
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(),
                    SizedBox(height: AppSpacing.marginL),
                    _buildNetworkSelection(),
                    SizedBox(height: AppSpacing.marginXL),
                    _buildContinueButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.radiusL),
          bottomRight: Radius.circular(AppRadius.radiusL),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send Crypto Payment',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSpacing.marginXS),
                Text(
                  'Crypto to Cash Transfer',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Send Crypto Payment',
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.marginS),
        Text(
          'Select your preferred blockchain network to continue with crypto to mobile money transfer.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Blockchain Network',
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.marginM),
        Row(
          children: networks.map((network) {
            final isSelected = selectedNetwork == network['id'];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedNetwork = network['id'];
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: network == networks.last ? 0 : AppSpacing.marginS,
                  ),
                  padding: EdgeInsets.all(AppSpacing.paddingM),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? network['color'].withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.radiusM),
                    border: Border.all(
                      color: isSelected ? network['color'] : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        network['icon'],
                        color: isSelected
                            ? network['color']
                            : AppColors.textSecondary,
                        size: 24,
                      ),
                      SizedBox(height: AppSpacing.marginS),
                      Text(
                        network['name'],
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected
                              ? network['color']
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }


  Widget _buildContinueButton() {
    return ElevatedButton(
      onPressed: () {
        // Set the selected network in payment provider
        ref.read(paymentProvider.notifier).setSelectedNetwork(selectedNetwork);

        // Navigate to next screen with aggregator
        context.push('/select-payment');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryYellow,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
        ),
        minimumSize: const Size(double.infinity, 56),
      ),
      child: Text(
        'Continue',
        style: AppTextStyles.buttonMedium.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
