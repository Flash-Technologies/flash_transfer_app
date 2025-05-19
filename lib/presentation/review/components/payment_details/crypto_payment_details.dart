import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flash_transfer_app/config/theme.dart';
import 'package:flash_transfer_app/core/models/payment_details.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';

class CryptoPaymentDetails extends StatefulWidget {
  final PaymentDetails details;
  final PaymentType paymentType;

  const CryptoPaymentDetails({
    Key? key,
    required this.details,
    required this.paymentType,
  }) : super(key: key);

  @override
  State<CryptoPaymentDetails> createState() => _CryptoPaymentDetailsState();
}

class _CryptoPaymentDetailsState extends State<CryptoPaymentDetails> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String get _lottieAsset {
    return 'assets/LottieFiles/cryptoWallet.json';
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    // Play the animation once then stop
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Payment Details",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF273240),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Crypto Type
          _buildDetailRow(
            label: "Cryptocurrency",
            child: Row(
              children: [
                Image.asset(
                  'assets/images/bitcoin.png',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.details.methodName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Blockchain
          _buildDetailRow(
            label: "Blockchain",
            child: Row(
              children: [
                Image.asset(
                  'assets/images/bitcoin.png',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.details.networkName ?? "Bitcoin",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Funds source and purpose
          _buildDetailRow(
            label: "Source of funds",
            value: widget.details.fundSource ?? "Saving",
          ),
          
          const SizedBox(height: 12),
          
          _buildDetailRow(
            label: "Purpose",
            value: widget.details.purpose ?? "Saving",
          ),
          
          // Lottie animation 
          Center(
            child: SizedBox(
              height: 120,
              width: 120,
              child: Lottie.asset(
                _lottieAsset,
                controller: _controller,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    String? value,
    Widget? child,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6E757D),
          ),
        ),
        child ?? Text(
          value!,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}