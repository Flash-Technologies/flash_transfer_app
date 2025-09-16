import 'package:flutter/material.dart';

class PhantomNetworkSelector {
  static Future<String?> showNetworkSelector(BuildContext context, List<String> addresses) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Wallet Network'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Phantom wallet has multiple networks. Please select which address to use:'),
              const SizedBox(height: 16),
              ...addresses.map((address) => ListTile(
                title: Text(
                  '${address.substring(0, 8)}...${address.substring(address.length - 6)}',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                subtitle: Text(_getNetworkName(address)),
                leading: Icon(_getNetworkIcon(address)),
                onTap: () => Navigator.of(context).pop(address),
              )).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  static String _getNetworkName(String address) {
    // Solana addresses are typically 32-44 chars base58
    // Ethereum addresses start with 0x and are 42 chars
    if (address.startsWith('0x') && address.length == 42) {
      return 'Ethereum / Polygon / Base';
    } else if (address.length >= 32 && address.length <= 44) {
      // Check if it looks like a Solana address
      if (!address.contains('0x')) {
        return 'Solana';
      }
    }
    return 'Unknown Network';
  }
  
  static IconData _getNetworkIcon(String address) {
    if (address.startsWith('0x')) {
      return Icons.diamond;
    } else {
      return Icons.sunny;
    }
  }
}