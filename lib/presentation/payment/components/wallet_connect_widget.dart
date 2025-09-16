import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:flash_transfer_app/core/services/reown_service.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';

class WalletConnectWidget extends StatefulWidget {
  final Function(String txHash)? onTransactionSuccess;
  final Map<String, dynamic>? transactionData;
  
  const WalletConnectWidget({
    Key? key,
    this.onTransactionSuccess,
    this.transactionData,
  }) : super(key: key);

  @override
  State<WalletConnectWidget> createState() => _WalletConnectWidgetState();
}

class _WalletConnectWidgetState extends State<WalletConnectWidget> {
  bool _isInitialized = false;
  bool _isSendingTransaction = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }
  
  Future<void> _initializeWallet() async {
    try {
      if (!ReownService.instance.isInitialized) {
        await ReownService.instance.initialize(context);
      }
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
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
  
  Future<void> _handlePayment() async {
    if (widget.transactionData == null) {
      setState(() {
        _errorMessage = 'No transaction data available';
      });
      return;
    }
    
    setState(() {
      _isSendingTransaction = true;
      _errorMessage = null;
    });
    
    try {
      // Extract transaction details
      final recipientAddress = widget.transactionData!['destinationDetails']?['transferData']?['address'] ?? 
                               widget.transactionData!['sourceDetails']?['address'] ?? 
                               '0xb0BcBd1eBc7730'; // Should come from API
      
      final amount = widget.transactionData!['totalAmount'] ?? 0.00000102;
      
      // Send the transaction
      final txHash = await ReownService.instance.sendTransaction(
        toAddress: recipientAddress,
        amountInEth: amount,
      );
      
      if (txHash != null) {
        // Success
        HapticFeedback.heavyImpact();
        widget.onTransactionSuccess?.call(txHash);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction sent successfully!'),
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
        });
      }
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
    
    final appKitModal = ReownService.instance.appKitModal;
    
    return Column(
      children: [
        // Connection Status Widget
        if (appKitModal.isConnected) ...[
          Container(
            padding: EdgeInsets.all(AppSpacing.paddingM),
            margin: EdgeInsets.only(bottom: AppSpacing.marginM),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusM),
              border: Border.all(
                color: AppColors.success.withOpacity(0.3),
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
                      if (ReownService.instance.walletAddress != null)
                        Text(
                          '${ReownService.instance.walletAddress!.substring(0, 6)}...${ReownService.instance.walletAddress!.substring(ReownService.instance.walletAddress!.length - 4)}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
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
        ],
        
        // Main Action Button
        if (!appKitModal.isConnected) ...[
          // Connect Wallet Button using AppKit's built-in component
          AppKitModalConnectButton(
            appKit: appKitModal,
            custom: ElevatedButton(
              onPressed: () async {
                await appKitModal.openModalView();
              },
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
              child: Row(
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
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusM),
              border: Border.all(
                color: AppColors.error.withOpacity(0.3),
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