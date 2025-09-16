import 'package:flutter/material.dart';
import '../api/api_client.dart';

class TransactionStatusService {
  final ApiClient _apiClient;

  TransactionStatusService(this._apiClient);

  /// Get transaction status by tracking number
  Future<Map<String, dynamic>?> getTransactionStatus(String trackingNumber) async {
    try {
      debugPrint('🔍 Getting transaction status for: $trackingNumber');
      
      final response = await _apiClient.get('/api/transaction/$trackingNumber/status');
      
      if (response.data != null && response.data['success'] == true) {
        debugPrint('✅ Transaction status retrieved successfully');
        return response.data['data'];
      } else {
        debugPrint('❌ Failed to get transaction status: ${response.data}');
        return null;
      }
    } catch (e) {
      debugPrint('💥 Error getting transaction status: $e');
      return null;
    }
  }

  /// Extract payment instructions from transaction status
  Map<String, dynamic>? getPaymentInstructions(Map<String, dynamic>? statusData) {
    if (statusData == null) return null;

    final statusDetails = statusData['statusDetails'];
    if (statusDetails == null) return null;

    return statusDetails['paymentInstructions'];
  }

  /// Check if transaction is pending payment
  bool isPendingPayment(Map<String, dynamic>? statusData) {
    if (statusData == null) return false;
    
    final status = statusData['status'];
    final comprehensivePhaseStatus = statusData['statusDetails']?['comprehensivePhaseStatus'];
    
    return status == 'PENDING' && 
           comprehensivePhaseStatus?['phase1_CryptoPayment']?['status'] == 'WAITING_FOR_APPROVAL';
  }

  /// Get wallet address from payment instructions
  String? getWalletAddress(Map<String, dynamic>? statusData) {
    final paymentInstructions = getPaymentInstructions(statusData);
    return paymentInstructions?['walletAddress'];
  }

  /// Get payment amount from payment instructions
  double? getPaymentAmount(Map<String, dynamic>? statusData) {
    final paymentInstructions = getPaymentInstructions(statusData);
    return paymentInstructions?['amount']?.toDouble();
  }

  /// Get payment currency from payment instructions
  String? getPaymentCurrency(Map<String, dynamic>? statusData) {
    final paymentInstructions = getPaymentInstructions(statusData);
    return paymentInstructions?['currency'];
  }

  /// Get blockchain network from payment instructions
  String? getBlockchainNetwork(Map<String, dynamic>? statusData) {
    final paymentInstructions = getPaymentInstructions(statusData);
    return paymentInstructions?['network'];
  }

  /// Get formatted transaction details for UI
  Map<String, String> getTransactionDetailsForUI(Map<String, dynamic>? statusData) {
    if (statusData == null) return {};

    final details = <String, String>{};

    // Basic transaction info
    details['Reference ID'] = statusData['referenceId'] ?? '';
    details['Tracking Number'] = statusData['trackingNumber'] ?? '';
    details['Status'] = statusData['status'] ?? '';
    
    // Amounts
    final amount = statusData['amount'];
    final currency = statusData['currency'];
    if (amount != null && currency != null) {
      details['Amount'] = '$amount $currency';
    }
    
    final destinationAmount = statusData['destinationAmount'];
    final beneficiary = statusData['beneficiary'];
    if (destinationAmount != null && beneficiary != null) {
      final country = beneficiary['country'];
      details['Recipient Gets'] = '$destinationAmount (${country ?? 'Unknown'})';
    }

    // Fee info
    final feeDetails = statusData['feeDetails'];
    if (feeDetails != null) {
      final totalFee = feeDetails['totalFee'];
      if (totalFee != null && currency != null) {
        details['Fee'] = '$totalFee $currency';
      }
    }

    // Payment instructions if pending
    if (isPendingPayment(statusData)) {
      final walletAddress = getWalletAddress(statusData);
      final paymentAmount = getPaymentAmount(statusData);
      final paymentCurrency = getPaymentCurrency(statusData);
      
      if (walletAddress != null) {
        details['Payment Address'] = walletAddress;
      }
      if (paymentAmount != null && paymentCurrency != null) {
        details['Exact Amount to Send'] = '$paymentAmount $paymentCurrency';
      }
    }

    return details;
  }

  /// Get status display info for UI
  Map<String, dynamic> getStatusDisplayInfo(Map<String, dynamic>? statusData) {
    if (statusData == null) {
      return {
        'isComplete': false,
        'isPending': true,
        'statusText': 'Unknown',
        'statusDescription': 'Unable to fetch transaction status',
      };
    }

    final status = statusData['status'];
    final comprehensivePhaseStatus = statusData['statusDetails']?['comprehensivePhaseStatus'];
    
    bool isComplete = status == 'COMPLETED' || status == 'SUCCESS';
    bool isPending = status == 'PENDING';
    
    String statusText = status ?? 'Unknown';
    String statusDescription = '';

    if (isPending && comprehensivePhaseStatus != null) {
      final phase1Status = comprehensivePhaseStatus['phase1_CryptoPayment']?['status'];
      final phase2Status = comprehensivePhaseStatus['phase2_FiatDelivery']?['status'];
      
      if (phase1Status == 'WAITING_FOR_APPROVAL') {
        statusDescription = 'Waiting for crypto payment confirmation';
      } else if (phase1Status == 'COMPLETED' && phase2Status == 'PENDING') {
        statusDescription = 'Crypto payment confirmed, processing fiat transfer';
      } else {
        statusDescription = 'Transaction is being processed';
      }
    } else if (isComplete) {
      statusDescription = 'Transaction completed successfully';
    } else {
      statusDescription = 'Transaction status: $statusText';
    }

    return {
      'isComplete': isComplete,
      'isPending': isPending,
      'statusText': statusText,
      'statusDescription': statusDescription,
    };
  }
}