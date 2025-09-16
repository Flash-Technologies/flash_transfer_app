import 'package:flutter/material.dart';

class NetworkInfo {
  final String id;
  final String name;
  final String displayName;
  final IconData icon;
  final Color color;
  final int chainId;
  final String rpcUrl;
  
  const NetworkInfo({
    required this.id,
    required this.name,
    required this.displayName,
    required this.icon,
    required this.color,
    required this.chainId,
    required this.rpcUrl,
  });
}

class NetworkMappingService {
  // Network definitions
  static const Map<String, NetworkInfo> networks = {
    'ethereum': NetworkInfo(
      id: 'ethereum',
      name: 'ethereum',
      displayName: 'Ethereum Mainnet',
      icon: Icons.diamond,
      color: Color(0xFF627EEA),
      chainId: 1,
      rpcUrl: 'https://eth-mainnet.g.alchemy.com/v2/',
    ),
    'polygon': NetworkInfo(
      id: 'polygon',
      name: 'polygon',
      displayName: 'Polygon',
      icon: Icons.hexagon,
      color: Color(0xFF8247E5),
      chainId: 137,
      rpcUrl: 'https://polygon-rpc.com/',
    ),
    'bsc': NetworkInfo(
      id: 'bsc',
      name: 'bsc',
      displayName: 'BNB Smart Chain',
      icon: Icons.currency_bitcoin,
      color: Color(0xFFF3BA2F),
      chainId: 56,
      rpcUrl: 'https://bsc-dataseed.binance.org/',
    ),
    'bnb': NetworkInfo(
      id: 'bsc',
      name: 'bsc',
      displayName: 'BNB Smart Chain',
      icon: Icons.currency_bitcoin,
      color: Color(0xFFF3BA2F),
      chainId: 56,
      rpcUrl: 'https://bsc-dataseed.binance.org/',
    ),
    'avalanche': NetworkInfo(
      id: 'avalanche',
      name: 'avalanche',
      displayName: 'Avalanche C-Chain',
      icon: Icons.ac_unit,
      color: Color(0xFFE84142),
      chainId: 43114,
      rpcUrl: 'https://api.avax.network/ext/bc/C/rpc',
    ),
    'arbitrum': NetworkInfo(
      id: 'arbitrum',
      name: 'arbitrum',
      displayName: 'Arbitrum One',
      icon: Icons.speed,
      color: Color(0xFF2D374B),
      chainId: 42161,
      rpcUrl: 'https://arb1.arbitrum.io/rpc',
    ),
    'optimism': NetworkInfo(
      id: 'optimism',
      name: 'optimism',
      displayName: 'Optimism',
      icon: Icons.opacity,
      color: Color(0xFFFF0420),
      chainId: 10,
      rpcUrl: 'https://mainnet.optimism.io',
    ),
    'solana': NetworkInfo(
      id: 'solana',
      name: 'solana',
      displayName: 'Solana',
      icon: Icons.sunny,
      color: Color(0xFF14F195),
      chainId: 0, // Solana doesn't use chain IDs
      rpcUrl: 'https://api.mainnet-beta.solana.com',
    ),
  };
  
  // Cryptocurrency to supported networks mapping
  static const Map<String, List<String>> cryptoNetworkMapping = {
    'ETH': ['ethereum'],
    'USDT': ['ethereum', 'polygon', 'bsc', 'avalanche', 'arbitrum', 'optimism', 'solana'],
    'USDC': ['ethereum', 'polygon', 'bsc', 'avalanche', 'arbitrum', 'optimism', 'solana'],
    'BNB': ['bsc'],
    'MATIC': ['polygon'],
    'AVAX': ['avalanche'],
    'SOL': ['solana'],
    'DAI': ['ethereum', 'polygon', 'bsc', 'avalanche'],
    'BUSD': ['bsc'],
    'WETH': ['ethereum', 'polygon', 'bsc', 'avalanche', 'arbitrum', 'optimism'],
    'WBTC': ['ethereum', 'polygon', 'bsc', 'avalanche'],
  };
  
  /// Get available networks for a cryptocurrency
  static List<NetworkInfo> getNetworksForCrypto(String? cryptoCode) {
    if (cryptoCode == null) {
      // Return most common networks as default
      return [
        networks['ethereum']!,
        networks['polygon']!,
        networks['bsc']!,
      ];
    }
    
    final supportedNetworkIds = cryptoNetworkMapping[cryptoCode.toUpperCase()] ?? 
                                cryptoNetworkMapping['USDT'] ?? // Default to USDT networks
                                ['ethereum', 'polygon', 'bsc'];
    
    return supportedNetworkIds
        .map((id) => networks[id])
        .where((network) => network != null)
        .cast<NetworkInfo>()
        .toList();
  }
  
  /// Get network info by ID
  static NetworkInfo? getNetworkById(String? networkId) {
    if (networkId == null) return null;
    
    // Handle variations in network naming
    final normalizedId = networkId.toLowerCase()
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll(' ', '');
    
    // Direct match
    if (networks.containsKey(normalizedId)) {
      return networks[normalizedId];
    }
    
    // Try to find by name match
    for (final network in networks.values) {
      if (network.name.toLowerCase() == normalizedId) {
        return network;
      }
    }
    
    // Default to ethereum if not found
    return networks['ethereum'];
  }
  
  /// Get chain ID for wallet connection
  static int getChainId(String? networkId) {
    final network = getNetworkById(networkId);
    return network?.chainId ?? 1; // Default to Ethereum mainnet
  }
  
  /// Convert network ID to API format
  static String getNetworkForApi(String? networkId) {
    final network = getNetworkById(networkId);
    return network?.name ?? 'ethereum';
  }
  
  /// Check if network supports EVM (for wallet connections)
  static bool isEVMNetwork(String? networkId) {
    if (networkId == null) return true;
    final normalizedId = networkId.toLowerCase();
    return normalizedId != 'solana';
  }
}