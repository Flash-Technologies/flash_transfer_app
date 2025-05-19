import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flash_transfer_app/config/theme.dart';
import 'package:flash_transfer_app/core/models/payment_details.dart';

class CardPaymentDetails extends StatefulWidget {
  final PaymentDetails details;

  const CardPaymentDetails({
    Key? key,
    required this.details,
  }) : super(key: key);

  @override
  State<CardPaymentDetails> createState() => _CardPaymentDetailsState();
}

class _CardPaymentDetailsState extends State<CardPaymentDetails> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
          const Text(
            "Payment Details",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF273240),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Card Type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Credit Card",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6E757D),
                ),
              ),
              Image.asset(
                'assets/images/cre-card.png',
                width: 40,
                height: 24,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Optional: Fund source and purpose if they exist in your model
          if (widget.details.fundSource != null)
            _buildDetailRow(
              label: "Source of funds",
              value: widget.details.fundSource!,
            ),
          
          if (widget.details.purpose != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: _buildDetailRow(
                label: "Purpose",
                value: widget.details.purpose!,
              ),
            ),
          
          // Card animation
          Center(
            child: SizedBox(
              height: 120,
              width: 120,
              child: Lottie.asset(
                'assets/LottieFiles/creditCard.json',
                controller: _controller,
                fit: BoxFit.contain,
                onLoaded: (composition) {
                  // Optional: adjust controller duration to match composition
                  _controller.duration = composition.duration;
                  _controller.forward();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
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
        Text(
          value,
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