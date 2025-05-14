import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/metamask_provider.dart';

/// A button specifically for connecting to MetaMask
class MetaMaskConnectButton extends ConsumerWidget {
  final VoidCallback? onConnected;
  final VoidCallback? onError;

  const MetaMaskConnectButton({super.key, this.onConnected, this.onError});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metamaskState = ref.watch(metamaskProvider);

    // Handle different connection states
    Widget buttonChild;
    Color buttonColor;

    switch (metamaskState.status) {
      case MetaMaskConnectionStatus.disconnected:
        buttonChild = _buildConnectContent();
        buttonColor = const Color(0xFFE2761B); // MetaMask orange
        break;
      case MetaMaskConnectionStatus.connecting:
        buttonChild = const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 10),
            Text('Connecting...'),
          ],
        );
        buttonColor = Colors.orange;
        break;
      case MetaMaskConnectionStatus.connected:
        buttonChild = _buildConnectedContent(metamaskState.walletAddress!);
        buttonColor = Colors.green;
        break;
      case MetaMaskConnectionStatus.error:
        buttonChild = const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Connection Failed'),
          ],
        );
        buttonColor = Colors.red;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed:
            metamaskState.status == MetaMaskConnectionStatus.connecting
                ? null
                : () => _handleButtonPress(context, ref),
        child: buttonChild,
      ),
    );
  }

  // Connect content with MetaMask logo
  Widget _buildConnectContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/wallets/metamask.png',
          width: 24,
          height: 24,
          errorBuilder:
              (context, error, stackTrace) =>
                  const Icon(Icons.account_balance_wallet, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Text(
          'Connect MetaMask',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // Connected content with wallet address
  Widget _buildConnectedContent(String address) {
    final shortAddress =
        '${address.substring(0, 6)}...${address.substring(address.length - 4)}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          'Connected: $shortAddress',
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
      ],
    );
  }

  // Handle button press based on current state
  void _handleButtonPress(BuildContext context, WidgetRef ref) async {
    final status = ref.read(metamaskProvider).status;

    if (status == MetaMaskConnectionStatus.connected) {
      // Disconnect logic
      await ref.read(metamaskProvider.notifier).disconnectMetaMask();
    } else {
      // Connect logic
      final success = await ref
          .read(metamaskProvider.notifier)
          .connectMetaMask(context);

      if (success) {
        if (onConnected != null) onConnected!();
      } else {
        if (onError != null) onError!();
      }
    }
  }
}
