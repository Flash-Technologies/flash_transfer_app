import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';
import 'package:flash_transfer_app/providers/exchange_provider.dart';
import 'package:flash_transfer_app/core/services/network_mapping_service.dart';

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
  String? selectedNetwork;
  List<NetworkInfo> availableNetworks = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableNetworks();
  }
  
  void _loadAvailableNetworks() {
    // Get the selected crypto from exchange form
    final exchangeForm = ref.read(exchangeFormProvider);
    final cryptoCode = exchangeForm.fromCurrency?.code;
    
    // Get available networks for this crypto
    availableNetworks = NetworkMappingService.getNetworksForCrypto(cryptoCode);
    
    // Auto-select first network if available
    if (availableNetworks.isNotEmpty && selectedNetwork == null) {
      selectedNetwork = availableNetworks.first.id;
    }
    
    // If previously selected network is not available, reset
    if (selectedNetwork != null && 
        !availableNetworks.any((n) => n.id == selectedNetwork)) {
      selectedNetwork = availableNetworks.isNotEmpty ? availableNetworks.first.id : null;
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload networks if currency changes
    _loadAvailableNetworks();
  }
  
  @override
  Widget build(BuildContext context) {
    // Watch for currency changes
    final exchangeForm = ref.watch(exchangeFormProvider);
    final cryptoCode = exchangeForm.fromCurrency?.code;
    
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
    final exchangeForm = ref.watch(exchangeFormProvider);
    final cryptoCode = exchangeForm.fromCurrency?.code;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Blockchain Network',
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (cryptoCode != null) ...[
          SizedBox(height: AppSpacing.marginS),
          Text(
            'Available networks for $cryptoCode',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        SizedBox(height: AppSpacing.marginM),
        if (availableNetworks.isEmpty) ...[
          Container(
            padding: EdgeInsets.all(AppSpacing.paddingL),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusM),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Text(
              'No networks available for selected cryptocurrency',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ] else if (availableNetworks.length <= 3) ...[
          // Show networks in a row if 3 or less
          Row(
            children: availableNetworks.map((network) {
              final isSelected = selectedNetwork == network.id;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedNetwork = network.id;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      right: network == availableNetworks.last ? 0 : AppSpacing.marginS,
                    ),
                    padding: EdgeInsets.all(AppSpacing.paddingM),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? network.color.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.radiusM),
                      border: Border.all(
                        color: isSelected ? network.color : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          network.icon,
                          color: isSelected
                              ? network.color
                              : AppColors.textSecondary,
                          size: 24,
                        ),
                        SizedBox(height: AppSpacing.marginS),
                        Text(
                          network.displayName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isSelected
                                ? network.color
                                : AppColors.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: availableNetworks.length > 2 ? 11 : 14,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ] else ...[
          // Show networks in a grid if more than 3
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: AppSpacing.marginS,
              mainAxisSpacing: AppSpacing.marginS,
            ),
            itemCount: availableNetworks.length,
            itemBuilder: (context, index) {
              final network = availableNetworks[index];
              final isSelected = selectedNetwork == network.id;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedNetwork = network.id;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.paddingS),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? network.color.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.radiusM),
                    border: Border.all(
                      color: isSelected ? network.color : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        network.icon,
                        color: isSelected
                            ? network.color
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      SizedBox(height: 4),
                      Text(
                        network.displayName,
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected
                              ? network.color
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }


  Widget _buildContinueButton() {
    return ElevatedButton(
      onPressed: selectedNetwork == null ? null : () {
        // Set the selected network in payment provider
        ref.read(paymentProvider.notifier).setSelectedNetwork(selectedNetwork!);

        // Check if this is crypto-to-cash flow
        final exchangeForm = ref.read(exchangeFormProvider);
        final paymentState = ref.read(paymentProvider);
        final isCryptoToCash = exchangeForm.fromCurrency?.type == 'CRYPTO' && 
                               paymentState.activeReceive == 'cash';

        if (isCryptoToCash) {
          // Navigate to sender information screen for crypto-to-cash
          context.push('/cash-sender-info');
        } else {
          // Navigate to payment method selection for other flows
          context.push('/select-payment');
        }
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