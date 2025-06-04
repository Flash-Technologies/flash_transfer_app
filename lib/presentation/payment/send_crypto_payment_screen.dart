import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';
import 'package:flash_transfer_app/providers/direct_wallet_provider.dart';
import 'package:flash_transfer_app/providers/exchange_provider.dart';
import 'package:flash_transfer_app/providers/auth_provider.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';
import 'package:flash_transfer_app/core/api/api_client.dart';
import 'package:flash_transfer_app/core/api/endpoints.dart';
import 'package:flash_transfer_app/presentation/common/wallet_selector_sheet.dart';

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
  const SendCryptoPaymentScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SendCryptoPaymentScreen> createState() =>
      _SendCryptoPaymentScreenState();
}

class _SendCryptoPaymentScreenState
    extends ConsumerState<SendCryptoPaymentScreen> {
  String selectedNetwork = 'ethereum';
  bool isConnectingWallet = false;
  bool isLoadingBalance = false;
  String manualWalletAddress = '';
  final TextEditingController _addressController = TextEditingController();
  WalletBalance? walletBalance;
  String? balanceError;

  final List<Map<String, dynamic>> networks = [
    {
      'id': 'ethereum',
      'name': 'Ethereum Mainnet',
      'icon': Icons.diamond,
      'color': AppColors.primaryBlue,
    },
    {
      'id': 'sepolia',
      'name': 'Sepolia Testnet',
      'icon': Icons.science,
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeFromLoggedInWallet();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _initializeFromLoggedInWallet() {
    // Check if user is logged in with wallet
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user?.walletAddress != null && user!.walletAddress!.isNotEmpty) {
      // Auto-set wallet address from logged in user
      _addressController.text = user.walletAddress!;
      manualWalletAddress = user.walletAddress!;

      // Auto-select network based on wallet (you can add logic to determine network)
      // For now, default to ethereum

      // Fetch balance immediately
      _fetchWalletBalance(user.walletAddress!);
    }
  }

  Future<void> _connectWallet() async {
    setState(() {
      isConnectingWallet = true;
      balanceError = null;
    });

    try {
      final walletNotifier = ref.read(directWalletProvider.notifier);
      final connected = await walletNotifier.connectWallet(context);

      if (connected) {
        final walletState = ref.read(directWalletProvider);
        if (walletState.walletAddress != null) {
          _addressController.text = walletState.walletAddress!;
          manualWalletAddress = walletState.walletAddress!;

          // Fetch balance for connected wallet
          await _fetchWalletBalance(walletState.walletAddress!);
        }
      }
    } catch (e) {
      setState(() {
        balanceError = 'Failed to connect wallet: ${e.toString()}';
      });
    } finally {
      setState(() {
        isConnectingWallet = false;
      });
    }
  }

  Future<void> _fetchWalletBalance(String walletAddress) async {
    if (walletAddress.isEmpty) return;

    setState(() {
      isLoadingBalance = true;
      balanceError = null;
    });

    try {
      final authState = ref.read(authProvider);
      if (authState.user?.token == null) {
        throw Exception('User not authenticated');
      }

      final apiClient = ApiClient(baseUrl: Endpoints.baseUrl);
      apiClient.setToken(authState.user!.token!);

      final response = await apiClient.get(
        '/api/webhooks/walletBalance',
        queryParameters: {'address': walletAddress},
      );

      if (response.statusCode == 200 && response.data != null) {
        // The API returns a List of balances, so we need to handle that
        if (response.data is List && (response.data as List).isNotEmpty) {
          final balanceData =
              (response.data as List).first as Map<String, dynamic>;
          setState(() {
            walletBalance = WalletBalance.fromJson(balanceData);
            balanceError = null;
          });
        } else {
          setState(() {
            balanceError = 'No balance data found for this wallet';
          });
        }
      } else {
        setState(() {
          balanceError = 'Failed to fetch wallet balance';
        });
      }
    } catch (e) {
      setState(() {
        balanceError = 'Error fetching balance: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoadingBalance = false;
      });
    }
  }

  void _onManualAddressChanged(String value) {
    setState(() {
      manualWalletAddress = value;
      walletBalance = null;
      balanceError = null;
    });

    if (value.isNotEmpty && _isValidWalletAddress(value)) {
      // Debounce the API call
      Future.delayed(const Duration(milliseconds: 500), () {
        if (manualWalletAddress == value && mounted) {
          _fetchWalletBalance(value);
        }
      });
    }
  }

  bool _isValidWalletAddress(String address) {
    // Basic validation for Ethereum-like addresses
    return address.length >= 40 && address.startsWith('0x') ||
        address.length >= 32; // For other blockchain addresses
  }

  bool _canContinue() {
    final exchangeForm = ref.read(exchangeFormProvider);
    final sendAmount = double.tryParse(exchangeForm.sendAmount) ?? 0;

    // Check if we have wallet address and balance
    if (manualWalletAddress.isEmpty || walletBalance == null) {
      return false;
    }

    // Check if user has sufficient balance using the formatted value
    final userBalance = walletBalance!.formatted;
    return userBalance >= sendAmount;
  }

  String? _getInsufficientBalanceMessage() {
    final exchangeForm = ref.read(exchangeFormProvider);
    final sendAmount = double.tryParse(exchangeForm.sendAmount) ?? 0;

    if (walletBalance == null || manualWalletAddress.isEmpty) return null;

    final userBalance = walletBalance!.formatted;
    if (userBalance < sendAmount) {
      final needed = sendAmount - userBalance;
      return 'Insufficient balance. You need ${needed.toStringAsFixed(4)} ${walletBalance!.token} more.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(directWalletProvider);
    final exchangeForm = ref.watch(exchangeFormProvider);

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
                    SizedBox(height: AppSpacing.marginL),
                    _buildWalletConnection(walletState),
                    SizedBox(height: AppSpacing.marginL),
                    _buildManualAddressInput(),
                    SizedBox(height: AppSpacing.marginL),
                    _buildBalanceDisplay(),
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
            color: Colors.black.withOpacity(0.05),
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
          'Connect your wallet and send cryptocurrency payments securely to anywhere in the world.',
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
                        ? network['color'].withOpacity(0.1)
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

  Widget _buildWalletConnection(WalletState walletState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect Your Wallet',
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.marginM),
        if (walletState.isConnected && walletState.walletAddress != null) ...[
          Container(
            padding: EdgeInsets.all(AppSpacing.paddingM),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusM),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: AppSpacing.marginM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wallet Connected',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        walletState.displayAddress,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _connectWallet(),
                ),
              ],
            ),
          ),
        ] else ...[
          ElevatedButton.icon(
            onPressed: isConnectingWallet ? null : _connectWallet,
            icon: isConnectingWallet
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.account_balance_wallet),
            label:
                Text(isConnectingWallet ? 'Connecting...' : 'Connect Wallet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: AppSpacing.paddingM,
                horizontal: AppSpacing.paddingL,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
              ),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildManualAddressInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Or Enter Wallet Address Manually',
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.marginM),
        TextFormField(
          controller: _addressController,
          onChanged: _onManualAddressChanged,
          decoration: InputDecoration(
            labelText: 'Wallet Address',
            hintText: '0x1234...5678 or enter your wallet address',
            prefixIcon: const Icon(Icons.account_balance_wallet),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusM),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusM),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusM),
              borderSide: BorderSide(color: AppColors.primaryBlue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceDisplay() {
    if (manualWalletAddress.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wallet Balance',
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.marginM),
        Container(
          padding: EdgeInsets.all(AppSpacing.paddingM),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.radiusM),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              if (isLoadingBalance) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: AppSpacing.marginM),
                    Text(
                      'Loading balance...',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ] else if (balanceError != null) ...[
                Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: AppSpacing.marginM),
                    Expanded(
                      child: Text(
                        balanceError!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => _fetchWalletBalance(manualWalletAddress),
                    ),
                  ],
                ),
              ] else if (walletBalance != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${walletBalance!.displayBalance} ${walletBalance!.token}',
                          style: AppTextStyles.heading3.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Network: ${walletBalance!.networkName}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => _fetchWalletBalance(manualWalletAddress),
                    ),
                  ],
                ),
                if (_getInsufficientBalanceMessage() != null) ...[
                  SizedBox(height: AppSpacing.marginM),
                  Container(
                    padding: EdgeInsets.all(AppSpacing.paddingS),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.radiusS),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 20),
                        SizedBox(width: AppSpacing.marginS),
                        Expanded(
                          child: Text(
                            _getInsufficientBalanceMessage()!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    final canContinue = _canContinue();
    final insufficientBalance = _getInsufficientBalanceMessage();

    return ElevatedButton(
      onPressed: canContinue
          ? () {
              // Set the wallet address in payment provider
              ref
                  .read(paymentProvider.notifier)
                  .setSelectedWalletAddress(manualWalletAddress);

              // Navigate to payment method selection
              context.push('/select-payment');
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            canContinue ? AppColors.primaryYellow : AppColors.iconBackground,
        foregroundColor:
            canContinue ? AppColors.textPrimary : AppColors.textSecondary,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
        ),
        minimumSize: const Size(double.infinity, 56),
      ),
      child: Text(
        canContinue
            ? 'Continue to Payment Method'
            : insufficientBalance != null
                ? 'Insufficient Balance'
                : 'Enter Wallet Address',
        style: AppTextStyles.buttonMedium.copyWith(
          color: canContinue ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
