import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/metamask_connect_button.dart';
import '../../providers/metamask_provider.dart';

class MetaMaskDemoScreen extends ConsumerWidget {
  const MetaMaskDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metamaskState = ref.watch(metamaskProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MetaMask Integration'),
        backgroundColor: const Color(0xFFE2761B),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // MetaMask logo
              Image.asset(
                'assets/images/wallets/metamask.png',
                width: 100,
                height: 100,
                errorBuilder:
                    (context, error, stackTrace) => const Icon(
                      Icons.account_balance_wallet,
                      size: 100,
                      color: Color(0xFFE2761B),
                    ),
              ),
              const SizedBox(height: 30),

              // Title
              const Text(
                'Connect to MetaMask',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Description
              const Text(
                'Connect your MetaMask wallet to access decentralized features. '
                'Your address will be used for authentication.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Connection status
              _buildConnectionStatus(metamaskState),
              const SizedBox(height: 30),

              // Connect button
              const MetaMaskConnectButton(),

              // Copy button (if connected)
              if (metamaskState.status == MetaMaskConnectionStatus.connected &&
                  metamaskState.walletAddress != null)
                _buildCopyAddressButton(context, metamaskState.walletAddress!),
            ],
          ),
        ),
      ),
    );
  }

  // Build connection status widget
  Widget _buildConnectionStatus(MetaMaskState state) {
    late final Color statusColor;
    late final String statusText;
    late final IconData statusIcon;

    switch (state.status) {
      case MetaMaskConnectionStatus.disconnected:
        statusColor = Colors.grey;
        statusText = 'Not Connected';
        statusIcon = Icons.circle_outlined;
        break;
      case MetaMaskConnectionStatus.connecting:
        statusColor = Colors.orange;
        statusText = 'Connecting...';
        statusIcon = Icons.pending_outlined;
        break;
      case MetaMaskConnectionStatus.connected:
        statusColor = Colors.green;
        statusText = 'Connected';
        statusIcon = Icons.check_circle;
        break;
      case MetaMaskConnectionStatus.error:
        statusColor = Colors.red;
        statusText = 'Error: ${state.errorMessage ?? 'Unknown error'}';
        statusIcon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Build copy address button
  Widget _buildCopyAddressButton(BuildContext context, String address) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: TextButton.icon(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: address));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address copied to clipboard')),
          );
        },
        icon: const Icon(Icons.copy, size: 18),
        label: const Text('Copy Address'),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFE2761B)),
      ),
    );
  }
}
