import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flash_transfer_app/core/services/reown_service.dart';
import 'package:flash_transfer_app/core/services/transaction_status_service.dart';
import 'package:flash_transfer_app/core/api/api_client.dart';
import 'package:flash_transfer_app/core/api/endpoints.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';
import 'package:flash_transfer_app/core/services/network_mapping_service.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';
import 'dart:async';

class WalletConnectWidget extends ConsumerStatefulWidget {
  final Function(String txHash)? onTransactionSuccess;
  final Map<String, dynamic>? transactionData;
  final String? trackingNumber;
  
  const WalletConnectWidget({
    super.key,
    this.onTransactionSuccess,
    this.transactionData,
    this.trackingNumber,
  });

  @override
  ConsumerState<WalletConnectWidget> createState() => _WalletConnectWidgetState();
}

class _WalletConnectWidgetState extends ConsumerState<WalletConnectWidget> {
  bool _isInitialized = false;
  bool _isSendingTransaction = false;
  String? _errorMessage;
  TransactionStatusService? _statusService;
  Map<String, dynamic>? _statusData;
  bool _isLoadingStatus = false;
  Timer? _connectionCheckTimer;
  bool _isMonitoringTransaction = false;
  String? _userBalance;
  bool _isCheckingBalance = false;
  bool _isConnecting = false;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
    _startConnectionMonitoring();
  }
  
  @override
  void dispose() {
    _connectionCheckTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _initializeServices() async {
    await _initializeWallet();
    _initializeStatusService();
    if (widget.trackingNumber != null) {
      await _loadTransactionStatus();
    }
  }
  
  void _startConnectionMonitoring() {
    // Check connection status every 500ms for real-time updates
    _connectionCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        final isConnected = ReownService.instance.isConnected;
        if (isConnected != _wasConnected) {
          setState(() {
            _wasConnected = isConnected;
          });
          if (isConnected) {
            _checkWalletBalance();
          }
        }
      }
    });
  }
  
  bool _wasConnected = false;
  
  void _initializeStatusService() {
    _statusService = TransactionStatusService(ApiClient(baseUrl: Endpoints.baseUrl));
  }
  
  Future<void> _loadTransactionStatus() async {
    if (widget.trackingNumber == null || _statusService == null) return;
    
    setState(() {
      _isLoadingStatus = true;
    });
    
    try {
      final statusData = await _statusService!.getTransactionStatus(widget.trackingNumber!);
      if (mounted && statusData != null) {
        setState(() {
          _statusData = statusData;
        });
      }
    } catch (e) {
      debugPrint('Error loading transaction status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
      }
    }
  }
  
  Future<void> _initializeWallet() async {
    try {
      if (!ReownService.instance.isInitialized) {
        // Get selected network from payment state or status data
        String? selectedNetwork = _getSelectedNetwork();
        
        debugPrint('🌐 Initializing wallet with network: $selectedNetwork');
        
        // Configure network before initialization
        await _configureNetwork(selectedNetwork);
        if (mounted) {
          await ReownService.instance.initialize(context, preferredChainId: _selectedChainId);
        }
      } else {
        // Re-set context if already initialized but context was lost
        debugPrint('🔄 Wallet already initialized, updating context');
        if (mounted) {
          await ReownService.instance.updateContext(context);
        }
      }
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _wasConnected = ReownService.instance.isConnected;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize wallet: $e';
        });
      }
    }
  }
  
  String? _getSelectedNetwork() {
    // Try to get network from multiple sources
    
    // 1. From status data if available
    if (_statusData != null) {
      final network = _statusData!['statusDetails']?['comprehensivePhaseStatus']?['phase1_CryptoPayment']?['network'];
      if (network != null) {
        debugPrint('📡 Using network from status data: $network');
        return network;
      }
    }
    
    // 2. From payment state
    final paymentState = ref.read(paymentProvider);
    if (paymentState.selectedNetwork != null) {
      debugPrint('📡 Using network from payment state: ${paymentState.selectedNetwork}');
      return paymentState.selectedNetwork;
    }
    
    // 3. Default to ethereum
    debugPrint('📡 Using default network: ethereum');
    return 'ethereum';
  }
  
  Future<void> _configureNetwork(String? network) async {
    // Configure the wallet to use the selected network
    final networkInfo = NetworkMappingService.getNetworkById(network);
    
    if (networkInfo != null) {
      debugPrint('🌐 Configuring wallet for network: ${networkInfo.displayName} (Chain ID: ${networkInfo.chainId})');
      
      // Set the chain ID for wallet connection
      // This will be used by ReownService to connect to the right network
      _selectedChainId = networkInfo.chainId;
    } else {
      debugPrint('⚠️ Network not found, using default Ethereum');
      _selectedChainId = 1; // Ethereum mainnet
    }
  }
  
  int _selectedChainId = 1;
  
  Future<void> _checkWalletBalance() async {
    if (!ReownService.instance.isConnected || _isCheckingBalance) return;
    
    setState(() {
      _isCheckingBalance = true;
    });
    
    try {
      final walletAddress = ReownService.instance.walletAddress;
      if (walletAddress != null) {
        // Get the required amount from status or transaction data
        final requiredAmount = _statusService?.getPaymentAmount(_statusData) ?? 
                              widget.transactionData?['totalAmount']?.toDouble();
        
        // For now, we'll show the required amount
        // In production, you'd call a balance API here
        setState(() {
          _userBalance = 'Required: ${requiredAmount ?? 0} ETH';
        });
      }
    } catch (e) {
      debugPrint('Error checking balance: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingBalance = false;
        });
      }
    }
  }
  
  Future<void> _handlePayment() async {
    setState(() {
      _isSendingTransaction = true;
      _isMonitoringTransaction = true;
      _errorMessage = null;
    });
    
    try {
      String? recipientAddress;
      double? amount;
      
      // Try to get payment details from status API first
      if (_statusData != null && _statusService != null) {
        recipientAddress = _statusService!.getWalletAddress(_statusData);
        amount = _statusService!.getPaymentAmount(_statusData);
        
        debugPrint('📡 Using status API data:');
        debugPrint('💰 Recipient: $recipientAddress');
        debugPrint('💵 Amount: $amount');
      }
      
      // Fallback to transaction data if status API data not available
      if (recipientAddress == null || amount == null) {
        if (widget.transactionData == null) {
          setState(() {
            _errorMessage = 'No payment details available. Please refresh and try again.';
          });
          return;
        }
        
        recipientAddress = widget.transactionData!['destinationDetails']?['transferData']?['address'] ?? 
                          widget.transactionData!['sourceDetails']?['address'];
        amount = widget.transactionData!['totalAmount']?.toDouble();
        
        debugPrint('🔄 Using fallback transaction data:');
        debugPrint('💰 Recipient: $recipientAddress');
        debugPrint('💵 Amount: $amount');
      }
      
      if (recipientAddress == null || amount == null) {
        throw Exception('Missing required payment details: address or amount');
      }
      
      debugPrint('🚀 Sending transaction:');
      debugPrint('📍 To Address: $recipientAddress');
      debugPrint('💰 Amount: $amount ETH');
      
      // Send the transaction
      final txHash = await ReownService.instance.sendTransaction(
        toAddress: recipientAddress,
        amountInEth: amount,
      );
      
      if (txHash != null) {
        // Success - now call the approval API
        HapticFeedback.heavyImpact();
        
        // Call the approval API
        await _approveTransaction(txHash, recipientAddress);
        
        widget.onTransactionSuccess?.call(txHash);
        
        if (mounted) {
          setState(() {
            _isMonitoringTransaction = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction completed successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('Transaction failed - no hash returned');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingTransaction = false;
          _isMonitoringTransaction = false;
        });
      }
    }
  }
  
  Future<void> _approveTransaction(String txHash, String walletAddress) async {
    try {
      debugPrint('🚀 Approving transaction...');
      
      // Get tracking number from transaction data or widget
      final trackingNumber = widget.trackingNumber ?? 
                            widget.transactionData?['trackingNumber'] ?? 
                            widget.transactionData?['orderId'];
      
      if (trackingNumber == null) {
        throw Exception('Transaction ID not found');
      }
      
      final apiClient = ApiClient(baseUrl: Endpoints.baseUrl);
      
      final response = await apiClient.post(
        '/api/transaction/$trackingNumber/approve-crypto-to-fiat',
        data: {
          'blockHash': txHash,
          'blockchainTxHash': txHash,
          'walletAddress': walletAddress,
        },
      );
      
      if (response.data != null && response.data['success'] == true) {
        debugPrint('✅ Transaction approved successfully');
        debugPrint('📊 Status: ${response.data['data']['status']}');
        
        // Reload status to get updated information
        if (widget.trackingNumber != null) {
          await _loadTransactionStatus();
        }
      } else {
        debugPrint('❌ Failed to approve transaction: ${response.data}');
      }
    } catch (e) {
      debugPrint('💥 Error approving transaction: $e');
      // Don't throw - transaction was successful, just approval API failed
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppColors.primaryYellow,
            ),
            SizedBox(height: 16),
            Text(
              'Initializing wallet connection...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_isLoadingStatus) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppColors.primaryYellow,
            ),
            SizedBox(height: 16),
            Text(
              'Loading payment details...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    final appKitModal = ReownService.instance.appKitModal;
    final selectedNetwork = _getSelectedNetwork();
    final networkInfo = NetworkMappingService.getNetworkById(selectedNetwork);
    
    // Show monitoring overlay if transaction is in progress
    if (_isMonitoringTransaction) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppColors.primaryYellow,
                strokeWidth: 3,
              ),
              SizedBox(height: 24),
              Text(
                'Processing Transaction',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Container(
                margin: EdgeInsets.symmetric(horizontal: AppSpacing.marginL),
                padding: EdgeInsets.all(AppSpacing.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.radiusM),
                  border: Border.all(
                    color: AppColors.primaryYellow.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.primaryYellow,
                      size: 20,
                    ),
                    SizedBox(width: AppSpacing.marginS),
                    Expanded(
                      child: Text(
                        "Don't close the app until transaction is completed or it will be lost",
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryYellow,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: [
        // Connection Status Widget
        if (appKitModal.isConnected) ...[
          Container(
            padding: EdgeInsets.all(AppSpacing.paddingM),
            margin: EdgeInsets.only(bottom: AppSpacing.marginM),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusM),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
                SizedBox(width: AppSpacing.marginS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wallet Connected',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                      if (ReownService.instance.walletAddress != null) ...[
                        Text(
                          '${ReownService.instance.walletAddress!.substring(0, 6)}...${ReownService.instance.walletAddress!.substring(ReownService.instance.walletAddress!.length - 4)}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Network: ${networkInfo?.displayName ?? selectedNetwork}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            if (_userBalance != null) ...[
                              Text(
                                ' • ',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _userBalance!,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Disconnect button
                IconButton(
                  onPressed: () async {
                    await ReownService.instance.disconnect();
                    setState(() {});
                  },
                  icon: Icon(
                    Icons.logout,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          
          // Payment Details Widget (if available from status API)
          // if (_statusData != null && _statusService != null) ...[
          //   Container(
          //     padding: EdgeInsets.all(AppSpacing.paddingM),
          //     margin: EdgeInsets.only(bottom: AppSpacing.marginM),
          //     decoration: BoxDecoration(
          //       color: AppColors.primaryBlue.withOpacity(0.1),
          //       borderRadius: BorderRadius.circular(AppRadius.radiusM),
          //       border: Border.all(
          //         color: AppColors.primaryBlue.withOpacity(0.3),
          //       ),
          //     ),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         Text(
          //           'Payment Details',
          //           style: AppTextStyles.bodyMedium.copyWith(
          //             fontWeight: FontWeight.w600,
          //             color: AppColors.primaryBlue,
          //           ),
          //         ),
          //         SizedBox(height: AppSpacing.marginS),
          //         if (_statusService!.getWalletAddress(_statusData) != null)
          //           Text(
          //             'To: ${_statusService!.getWalletAddress(_statusData)!.substring(0, 6)}...${_statusService!.getWalletAddress(_statusData)!.substring(_statusService!.getWalletAddress(_statusData)!.length - 4)}',
          //             style: AppTextStyles.caption.copyWith(
          //               color: AppColors.textSecondary,
          //             ),
          //           ),
          //         if (_statusService!.getPaymentAmount(_statusData) != null && _statusService!.getPaymentCurrency(_statusData) != null)
          //           Text(
          //             'Amount: ${_statusService!.getPaymentAmount(_statusData)} ${_statusService!.getPaymentCurrency(_statusData)}',
          //             style: AppTextStyles.caption.copyWith(
          //               color: AppColors.textSecondary,
          //             ),
          //           ),
          //       ],
          //     ),
          //   ),
          // ],
        ],
        
        // Main Action Button
        if (!appKitModal.isConnected) ...[
          // Connect Wallet Button
          ElevatedButton(
            onPressed: _isConnecting ? null : () async {
              setState(() {
                _isConnecting = true;
                _errorMessage = null;
              });
              
              try {
                // Ensure we have latest context
                await _initializeWallet();
                
                // Open modal
                await appKitModal.openModalView();
              } catch (e) {
                debugPrint('Error opening wallet modal: $e');
                if (mounted) {
                  setState(() {
                    _errorMessage = 'Failed to open wallet connection: ${e.toString()}';
                  });
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isConnecting = false;
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isConnecting 
                  ? AppColors.primaryYellow.withValues(alpha: 0.7)
                  : AppColors.primaryYellow,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingL),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
              ),
              minimumSize: const Size(double.infinity, 56),
            ),
            child: _isConnecting
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.textPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet, size: 24),
                      SizedBox(width: AppSpacing.marginM),
                      Text(
                        'Connect Wallet',
                        style: AppTextStyles.buttonLarge,
                      ),
                    ],
                  ),
          ),
        ] else ...[
          // Send Payment Button
          ElevatedButton(
            onPressed: _isSendingTransaction ? null : _handlePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingL),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
              ),
              minimumSize: const Size(double.infinity, 56),
            ),
            child: _isSendingTransaction
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.textPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, size: 24),
                      SizedBox(width: AppSpacing.marginM),
                      Text(
                        'Send Payment',
                        style: AppTextStyles.buttonLarge,
                      ),
                    ],
                  ),
          ),
        ],
        
        // Network Selector (optional)
        if (appKitModal.isConnected) ...[
          SizedBox(height: AppSpacing.marginM),
          AppKitModalNetworkSelectButton(
            appKit: appKitModal,
          ),
        ],
        
        // Error Message
        if (_errorMessage != null) ...[
          SizedBox(height: AppSpacing.marginM),
          Container(
            padding: EdgeInsets.all(AppSpacing.paddingM),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusM),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                SizedBox(width: AppSpacing.marginS),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
