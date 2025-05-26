// lib/test_wallet_connection.dart
// Test script to verify wallet connection fixes

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/direct_wallet_provider.dart';

class TestWalletConnection extends ConsumerWidget {
  const TestWalletConnection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(directWalletProvider);
    final walletNotifier = ref.read(directWalletProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Connection Test'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test status header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.science,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Wallet Connection Test',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This test validates both critical fixes:\n'
                    '1. Cached address bug fix\n'
                    '2. Wallet connection prompts',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cache cleared on connect: Always\n'
                    'Fresh wallet selection: Always triggered',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Connection Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: walletState.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: walletState.statusColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: walletState.statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Connection Status',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    walletState.statusDescription,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (walletState.walletAddress != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Address: ${walletState.displayAddress}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Detailed State Information
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detailed State',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStateRow('Status', walletState.status.toString()),
                    _buildStateRow(
                        'Wallet Address', walletState.walletAddress ?? 'None'),
                    _buildStateRow(
                        'Wallet Type', walletState.walletType ?? 'None'),
                    _buildStateRow(
                        'Is Connected', walletState.isConnected.toString()),
                    _buildStateRow(
                        'Is Loading', walletState.isLoading.toString()),
                    _buildStateRow(
                        'Has Error', walletState.hasError.toString()),
                    if (walletState.errorMessage != null)
                      _buildStateRow('Error', walletState.errorMessage!),
                    if (walletState.connectedAt != null)
                      _buildStateRow('Connected At',
                          walletState.connectedAt!.toLocal().toString()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: walletState.isLoading
                        ? null
                        : () async {
                            debugPrint('🧪 Testing wallet connection...');
                            await walletNotifier.connectWallet(context);
                          },
                    icon: const Icon(Icons.account_balance_wallet),
                    label: Text(
                      walletState.isConnected
                          ? 'Reconnect Wallet'
                          : 'Connect Wallet',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: walletState.isLoading || !walletState.isConnected
                        ? null
                        : () async {
                            debugPrint('🧪 Testing wallet disconnect...');
                            await walletNotifier.disconnectWallet();
                          },
                    icon: const Icon(Icons.logout),
                    label: const Text('Disconnect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Clear Error Button
            if (walletState.hasError)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    debugPrint('🧪 Clearing error state...');
                    walletNotifier.clearError();
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Error'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
