import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flash_transfer_app/config/theme.dart';
import 'package:flash_transfer_app/presentation/common/app_button.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';
import 'package:flash_transfer_app/providers/exchange_provider.dart';
import 'package:flash_transfer_app/providers/auth_provider.dart';

class CryptoAddressScreen extends ConsumerStatefulWidget {
  const CryptoAddressScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CryptoAddressScreen> createState() =>
      _CryptoAddressScreenState();
}

class _CryptoAddressScreenState extends ConsumerState<CryptoAddressScreen> {
  final _addressController = TextEditingController();
  String? _selectedBlockchain;
  bool _isValidating = false;
  String? _validationError;

  final List<Map<String, String>> _blockchains = [
    {
      'name': 'ethereum',
      'displayName': 'Ethereum Mainnet',
      'icon': 'assets/images/ethereum.png',
    },
    {
      'name': 'sepolia',
      'displayName': 'Sepolia Testnet',
      'icon': 'assets/images/ethereum.png',
    },
  ];

  final Map<String, String> _selectedCrypto = {
    'name': 'ETH',
    'fullName': 'Ethereum',
    'icon': 'assets/images/ethereum.png',
  };

  @override
  void initState() {
    super.initState();
    // Set default blockchain to ethereum mainnet to match working payload
    _selectedBlockchain = 'ethereum';
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  bool _isValidEthereumAddress(String address) {
    // Basic Ethereum address validation
    final regex = RegExp(r'^0x[a-fA-F0-9]{40}$');
    return regex.hasMatch(address);
  }

  Future<void> _validateAddress() async {
    final address = _addressController.text.trim();

    if (address.isEmpty) {
      setState(() {
        _validationError = 'Please enter a valid wallet address';
      });
      return;
    }

    if (_selectedBlockchain == null) {
      setState(() {
        _validationError = 'Please select a blockchain network';
      });
      return;
    }

    if (!_isValidEthereumAddress(address)) {
      setState(() {
        _validationError =
            'Invalid address format for the selected network. Please check and try again.';
      });
      return;
    }

    // Check if user is authenticated
    final authState = ref.read(authProvider);
    if (authState.status != AuthStatus.authenticated ||
        authState.user?.token == null) {
      setState(() {
        _validationError = 'Please log in to continue with the transaction';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _validationError = null;
    });

    try {
      // Get exchange data from the form (this would come from previous screens)
      final exchangeForm = ref.read(exchangeFormProvider);
      final paymentState = ref.read(paymentProvider);

      // Validate that we have the required form data
      if (exchangeForm.fromCurrency == null ||
          exchangeForm.toCurrency == null ||
          exchangeForm.sendAmount.isEmpty) {
        setState(() {
          _validationError = 'Please complete the exchange form first';
        });
        return;
      }

      final double? amount = double.tryParse(exchangeForm.sendAmount);
      if (amount == null || amount <= 0) {
        setState(() {
          _validationError = 'Please enter a valid amount';
        });
        return;
      }

      // Get transaction estimate from API with real user data
      final success = await ref
          .read(paymentProvider.notifier)
          .getTransactionEstimate(
            amount: amount,
            sourceCurrency: exchangeForm.fromCurrency!.code,
            destinationCurrency: exchangeForm.toCurrency!.code,
            blockchainNetwork: _selectedBlockchain!,
            countryCode: 'ci', // TODO: Get from user location or selection
            paymentMethod:
                'orange', // TODO: Get from mobile money provider selection
            phoneNumber: '1231231232', // TODO: Get from mobile money details
            provider: 'orange', // TODO: Get from provider selection
            walletAddress: address,
          );

      setState(() {
        _isValidating = false;
      });

      if (success) {
        // Store the wallet address and navigate to review screen
        ref.read(paymentProvider.notifier).setSelectedWalletAddress(address);
        context.push('/review-details/crypto');
      } else {
        // Show error from API
        final paymentError = ref.read(paymentProvider).errorMessage;
        setState(() {
          _validationError = _parseApiError(
              paymentError ?? 'Failed to validate transaction details');
        });
      }
    } catch (e) {
      setState(() {
        _isValidating = false;
        _validationError = _parseApiError(e.toString());
      });
    }
  }

  String _parseApiError(String error) {
    // Parse common API errors and provide user-friendly messages
    if (error.contains('Unauthorized')) {
      return 'Please log in again to continue';
    } else if (error.contains('Authentication Error')) {
      return 'Authentication failed. Please log in again';
    } else if (error.contains('Network error')) {
      return 'Network error. Please check your connection';
    } else if (error.contains('Connection timed out')) {
      return 'Request timed out. Please try again';
    } else {
      return 'Transaction validation failed. Please try again';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch payment state for loading/error handling
    final paymentState = ref.watch(paymentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header with background pattern
            _buildHeader(),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address input field
                    _buildAddressField()
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 100.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 24),

                    // Selected crypto section
                    _buildSelectedCrypto()
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 24),

                    // Blockchain selection
                    _buildBlockchainSelection()
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 300.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 32),

                    // Validation error
                    if (_validationError != null)
                      _buildValidationError()
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: -0.1, end: 0),

                    // API Loading state
                    if (paymentState.isEstimateLoading)
                      _buildLoadingIndicator()
                          .animate()
                          .fadeIn(duration: 300.ms),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.8),
          ],
        ),
        // Add subtle pattern background
        // image: const DecorationImage(
        //   image: AssetImage('assets/images/pattern_bg.png'),
        //   fit: BoxFit.cover,
        //   opacity: 0.05,
        // ),
      ),
      child: Column(
        children: [
          const Text(
            'Confirm Crypto Address',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDarkColor,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),
          const SizedBox(height: 8),
          const Text(
            'How would you like the money delivered?',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textGrayColor,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 100.ms)
              .slideY(begin: -0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter the Crypto Address of an EVM chain:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDarkColor,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '(ETH, Polygon, Base, Arbitrum, Optimism ...)',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textGrayColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _validationError != null
                  ? Colors.red
                  : const Color(0xFFE0E4E8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              hintText: '0x.................................',
              hintStyle: TextStyle(
                color: Color(0xFFBDC3C7),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'monospace',
            ),
            onChanged: (_) {
              if (_validationError != null) {
                setState(() {
                  _validationError = null;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedCrypto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selected Crypto',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDarkColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E4E8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF627EEA).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.currency_bitcoin,
                  color: Color(0xFF627EEA),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _selectedCrypto['name']!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDarkColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlockchainSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select the Blockchain',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDarkColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E4E8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButton<String>(
            value: _selectedBlockchain,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down),
            items: _blockchains.map((blockchain) {
              return DropdownMenuItem<String>(
                value: blockchain['name'],
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF627EEA).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.link,
                        color: Color(0xFF627EEA),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      blockchain['displayName']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBlockchain = value;
                _validationError = null;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildValidationError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _validationError!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Getting transaction estimate...',
              style: TextStyle(
                color: AppTheme.textDarkColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          AppButton(
            text: _isValidating ? 'Validating...' : 'Continue',
            onPressed: () => _validateAddress(),
            backgroundColor: AppTheme.primaryColor,
            textColor: Colors.black87,
            isDisabled: _isValidating,
          ).animate().scale(
                duration: 200.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Cancel',
            onPressed: () => context.pop(),
            backgroundColor: Colors.transparent,
            textColor: AppTheme.textGrayColor,
          ),
        ],
      ),
    );
  }
}
