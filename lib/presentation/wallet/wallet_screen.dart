import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flash_transfer_app/config/constants.dart';
import 'package:flash_transfer_app/providers/user_provider.dart' as user_prov;
import 'package:flash_transfer_app/providers/auth_provider.dart';
import 'package:flash_transfer_app/presentation/common/app_button.dart';
import 'package:flash_transfer_app/core/api/endpoints.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String? selectedNetwork = 'ethereum';
  String? selectedToken = 'ETH';
  bool isLoadingBalance = false;
  Map<String, dynamic>? balanceData;
  String? walletAddress;
  bool isEVM = true;

  final Map<String, List<String>> networkTokens = {
    'ethereum': ['ETH', 'USDT', 'USDC'],
    'bsc': ['BNB', 'USDT', 'USDC'],
    'polygon': ['MATIC', 'USDT', 'USDC'],
    'avalanche': ['AVAX', 'USDT', 'USDC'],
    'solana': ['SOL'],
  };

  final Map<String, String> networkDisplayNames = {
    'ethereum': 'Ethereum',
    'bsc': 'BSC',
    'polygon': 'Polygon',
    'avalanche': 'Avalanche',
    'solana': 'Solana',
  };

  final Map<String, IconData> tokenIcons = {
    'ETH': Icons.currency_exchange,
    'USDT': Icons.attach_money,
    'USDC': Icons.monetization_on,
    'BNB': Icons.currency_bitcoin,
    'MATIC': Icons.polymer,
    'AVAX': Icons.ac_unit,
    'SOL': Icons.wb_sunny,
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _initializeWallet();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      _scaleController.forward();
    });
  }

  void _initializeWallet() {
    final user = ref.read(user_prov.userProvider).user;
    if (user?.walletAddress != null && user!.walletAddress!.isNotEmpty) {
      walletAddress = user.walletAddress;
      _detectWalletType();
      _fetchBalance();
    }
  }

  void _detectWalletType() {
    if (walletAddress == null) return;

    if (walletAddress!.startsWith('0x')) {
      isEVM = true;
      selectedNetwork = 'ethereum';
      selectedToken = 'ETH';
    } else if (walletAddress!.length >= 32 && walletAddress!.length <= 44) {
      isEVM = false;
      selectedNetwork = 'solana';
      selectedToken = 'SOL';
    }
  }

  Future<void> _fetchBalance() async {
    if (walletAddress == null || selectedNetwork == null || selectedToken == null) {
      return;
    }

    setState(() {
      isLoadingBalance = true;
      balanceData = null;
    });

    try {
      final apiClient = ref.read(user_prov.apiClientProvider);
      final response = await apiClient.get(
        '${Endpoints.baseUrl}/api/webhooks/walletBalance?address=$walletAddress&token=$selectedToken&network=$selectedNetwork',
      );

      if (response.statusCode == 200) {
        setState(() {
          balanceData = response.data;
          isLoadingBalance = false;
        });
      } else {
        setState(() {
          isLoadingBalance = false;
        });
        _showError('Failed to fetch balance');
      }
    } catch (e) {
      setState(() {
        isLoadingBalance = false;
      });
      _showError('Error fetching balance: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  String _formatBalance(String? balance) {
    if (balance == null) return '0.00';
    
    final value = double.tryParse(balance) ?? 0.0;
    if (value == 0) return '0.00';
    
    if (value < 0.000001) {
      return value.toStringAsExponential(2);
    }
    
    if (value < 1) {
      return value.toStringAsFixed(6);
    }
    
    return value.toStringAsFixed(2);
  }

  String _formatAddress(String? address) {
    if (address == null || address.length < 10) return address ?? '';
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  Future<void> _handleDisconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Disconnect Wallet'),
        content: const Text('This will log you out of the app. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      try {
        await ref.read(authProvider.notifier).logout();
        if (mounted) {
          context.go('/sign-in');
        }
      } catch (error) {
        _showError('Failed to disconnect: ${error.toString()}');
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(user_prov.userProvider).user;
    final hasWallet = user?.walletAddress != null && user!.walletAddress!.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: hasWallet
                    ? _buildWalletContent(context)
                    : _buildNoWalletContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
        vertical: AppSizes.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'My Wallet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildWalletContent(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        children: [
          _buildWalletCard(context),
          const SizedBox(height: AppSizes.spacingLarge),
          _buildNetworkSelector(context),
          const SizedBox(height: AppSizes.spacingMedium),
          _buildTokenSelector(context),
          const SizedBox(height: AppSizes.spacingLarge),
          _buildBalanceCard(context),
          const SizedBox(height: AppSizes.spacingXLarge),
          _buildDisconnectButton(context),
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF3E24),
              const Color(0xFFFF3E24).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3E24).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Portfolio Overview',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Connected',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wallet Address',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatAddress(walletAddress),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (walletAddress != null) {
                                Clipboard.setData(
                                  ClipboardData(text: walletAddress!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Address copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.copy,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ],
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
  }

  Widget _buildNetworkSelector(BuildContext context) {
    final networks = isEVM
        ? ['ethereum', 'bsc', 'polygon', 'avalanche']
        : ['solana'];

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
          Text(
            'Select Network',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: AppSizes.spacingMedium),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedNetwork,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.primary,
                ),
                items: networks.map((network) {
                  return DropdownMenuItem<String>(
                    value: network,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.language,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          networkDisplayNames[network] ?? network,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedNetwork = value;
                    selectedToken = networkTokens[value]?.first;
                  });
                  _fetchBalance();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenSelector(BuildContext context) {
    final tokens = networkTokens[selectedNetwork] ?? [];

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
          Text(
            'Select Token',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: AppSizes.spacingMedium),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedToken,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.primary,
                ),
                items: tokens.map((token) {
                  return DropdownMenuItem<String>(
                    value: token,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            tokenIcons[token] ?? Icons.monetization_on,
                            size: 18,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          token,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedToken = value;
                  });
                  _fetchBalance();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Balance',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: AppSizes.spacingMedium),
          if (isLoadingBalance)
            const CircularProgressIndicator()
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '\$',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      _formatBalance(balanceData?['formatted']),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacingSmall),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${balanceData?['symbol'] ?? selectedToken ?? ''} on ${networkDisplayNames[selectedNetwork] ?? ''}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDisconnectButton(BuildContext context) {
    return AppButton(
      text: 'Disconnect',
      onPressed: _handleDisconnect,
      backgroundColor: Theme.of(context).colorScheme.error,
      textColor: Colors.white,
      icon: Icons.logout,
    );
  }

  Widget _buildNoWalletContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            Text(
              'No Wallet Connected',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            Text(
              'You haven\'t connected a wallet to your account yet. Connect a wallet to view your balances.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: AppSizes.spacingXLarge),
            AppButton(
              text: 'Connect Wallet',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Wallet connection feature coming soon'),
                  ),
                );
              },
              icon: Icons.add_circle_outline,
            ),
          ],
        ),
      ),
    );
  }
}