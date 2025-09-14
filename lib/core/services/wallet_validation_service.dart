import '../api/api_client.dart';
import '../api/endpoints.dart';

class WalletValidationService {
  final ApiClient _apiClient;

  WalletValidationService(this._apiClient);

  // Validate EVM address
  Future<WalletValidationResponse> validateWalletAddress({
    required String address,
    required String network,
  }) async {
    try {
      final response = await _apiClient.get(
        Endpoints.walletValidation,
        queryParameters: {
          'address': address,
          'network': network,
        },
      );

      return WalletValidationResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to validate wallet address: $e');
    }
  }

  // Check if address is EVM format (starts with 0x and is 42 characters long)
  bool isValidEvmFormat(String address) {
    if (address.isEmpty) return false;
    
    // Basic EVM address format check
    final evmRegex = RegExp(r'^0x[a-fA-F0-9]{40}$');
    return evmRegex.hasMatch(address);
  }

  // Get supported networks
  List<String> getSupportedNetworks() {
    return [
      'ETHEREUM',
      'POLYGON',
      'BSC',
      'ARBITRUM',
      'OPTIMISM',
      'BASE',
    ];
  }

  // Convert network name to display name
  String getNetworkDisplayName(String network) {
    switch (network.toUpperCase()) {
      case 'ETHEREUM':
        return 'Ethereum';
      case 'POLYGON':
        return 'Polygon';
      case 'BSC':
        return 'Binance Smart Chain';
      case 'ARBITRUM':
        return 'Arbitrum';
      case 'OPTIMISM':
        return 'Optimism';
      case 'BASE':
        return 'Base';
      default:
        return network;
    }
  }
}

// Response models
class WalletValidationResponse {
  final bool success;
  final WalletValidationData? data;
  final String? message;

  WalletValidationResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory WalletValidationResponse.fromJson(Map<String, dynamic> json) {
    return WalletValidationResponse(
      success: json['success'] as bool,
      data: json['data'] != null 
          ? WalletValidationData.fromJson(json['data']) 
          : null,
      message: json['message'] as String?,
    );
  }
}

class WalletValidationData {
  final String address;
  final String network;
  final bool isValid;
  final String networkName;

  WalletValidationData({
    required this.address,
    required this.network,
    required this.isValid,
    required this.networkName,
  });

  factory WalletValidationData.fromJson(Map<String, dynamic> json) {
    return WalletValidationData(
      address: json['address'] as String,
      network: json['network'] as String,
      isValid: json['isValid'] as bool,
      networkName: json['networkName'] as String,
    );
  }
}