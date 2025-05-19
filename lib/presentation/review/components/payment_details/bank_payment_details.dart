import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flash_transfer_app/config/theme.dart';
import 'package:flash_transfer_app/core/models/payment_details.dart';

class BankPaymentDetails extends StatefulWidget {
  final PaymentDetails details;

  const BankPaymentDetails({
    Key? key,
    required this.details,
  }) : super(key: key);

  @override
  State<BankPaymentDetails> createState() => _BankPaymentDetailsState();
}

class _BankPaymentDetailsState extends State<BankPaymentDetails> with SingleTickerProviderStateMixin {
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
          
          // Bank Transfer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Bank Transfer",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6E757D),
                ),
              ),
              // Either use an icon or custom painter for bank icon
              BankIcon(color: Colors.black),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Optional: Fund source and purpose if they exist
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
          
          // Bank animation
          Center(
            child: SizedBox(
              height: 120,
              width: 120,
              child: Lottie.asset(
                'assets/LottieFiles/bankTransfer.json',
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

// Custom painter to create a bank icon
class BankIcon extends StatelessWidget {
  final Color color;
  
  const BankIcon({Key? key, this.color = Colors.black}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: BankIconPainter(color: color),
      ),
    );
  }
}

class BankIconPainter extends CustomPainter {
  final Color color;
  
  BankIconPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    // Draw bank shape - simplified version
    final Path path = Path();
    
    // Roof
    path.moveTo(size.width * 0.1, size.height * 0.4);
    path.lineTo(size.width * 0.5, size.height * 0.1);
    path.lineTo(size.width * 0.9, size.height * 0.4);
    path.close();
    
    // Base
    path.moveTo(size.width * 0.15, size.height * 0.9);
    path.lineTo(size.width * 0.85, size.height * 0.9);
    
    // Columns
    path.moveTo(size.width * 0.3, size.height * 0.4);
    path.lineTo(size.width * 0.3, size.height * 0.9);
    
    path.moveTo(size.width * 0.5, size.height * 0.4);
    path.lineTo(size.width * 0.5, size.height * 0.9);
    
    path.moveTo(size.width * 0.7, size.height * 0.4);
    path.lineTo(size.width * 0.7, size.height * 0.9);
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}