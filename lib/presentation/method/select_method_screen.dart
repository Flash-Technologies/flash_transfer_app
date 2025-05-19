import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flash_transfer_app/config/theme.dart';
import 'package:flash_transfer_app/presentation/method/components/method_item.dart';
import 'package:flash_transfer_app/presentation/method/components/method_selection_modal.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';
import 'dart:math' show pi;

class SelectMethodScreen extends ConsumerStatefulWidget {
  const SelectMethodScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SelectMethodScreen> createState() => _SelectMethodScreenState();
}

class _SelectMethodScreenState extends ConsumerState<SelectMethodScreen> {
  String? selectedMethodId;
  MethodItem? selectedMethod;
  bool showError = false;

  final List<MethodItem> methods = [
    MethodItem(
      id: "cash",
      name: "Cash",
      iconPath: "assets/images/orange.png",
    ),
    MethodItem(
      id: "wave",
      name: "Wave",
      iconPath: "assets/images/wave.png",
    ),
    MethodItem(
      id: "mtn",
      name: "MTN",
      iconPath: "assets/images/mtn.png",
    ),
    MethodItem(
      id: "moov",
      name: "Moov Money",
      iconPath: "assets/images/moov.png",
    ),
  ];

  void handleMethodSelection(MethodItem method) {
    setState(() {
      selectedMethodId = method.id;
      selectedMethod = method;
      showError = false;
    });
  }

   void handleSubmit() {
    final paymentState = ref.read(paymentProvider);
    
    if (paymentState.selectedProvider == null) {
      setState(() {
        showError = true;
      });
    } else {
      final activePay = paymentState.activePay;
      final activeReceive = paymentState.activeReceive;

      if (activePay == 'cash' && activeReceive == 'cash') {
        context.push('/review-details-cash');
      } else if (activePay == 'card' && activeReceive == 'cash') {
        context.push('/review-details-card');
      } else if (activePay == 'wallet' && activeReceive == 'cash') {
        context.push('/review-details-cryptos');
      } else {
        context.push('/review-details-bank');
      }
    }
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF0F1),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Header
            _buildProgressHeader(),
            
            // Main content with padding
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Section
                    _buildTitleSection(),
                    
                    // Method Selection Section
                    _buildMethodSelectionSection(),
                    
                    const Spacer(),
                    
                    // Bottom Buttons
                    _buildBottomButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 16.0, top: 16.0, left: 16.0, right: 16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: [
          // Progress Circle
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Gray background circle
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CustomPaint(
                    painter: CircleProgressPainter(
                      backgroundColor: const Color(0xFFE0E0E0),
                      progressColor: const Color(0xFF005CEE),
                      progress: 56.5 / 113, // Value from the strokeDasharray in the original React component
                      strokeWidth: 4,
                    ),
                  ),
                ),
                // Centered Text
                const Text(
                  "2/4",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF181F30),
                  ),
                ),
              ],
            ),
          ),
          
          // Text Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Payment Method",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF181F30),
                ),
              ),
              Text(
                "Enter the information.",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6E757D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Choose delivery method",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181F30),
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Choose delivery method in mobile money,\nbank deposit, cash pickup.",
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF6E757D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Receiving Method",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF273240),
            ),
          ),
          const SizedBox(height: 12),
          
          // Method Selection Dropdown
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => MethodSelectionModal(
                  methods: methods,
                  selectedMethodId: selectedMethodId,
                  onSelect: handleMethodSelection,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: showError 
                      ? Colors.red 
                      : const Color(0xFFE0E0E0),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (selectedMethod != null) ...[
                    Image.asset(
                      selectedMethod!.iconPath,
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      selectedMethod!.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF181F30),
                      ),
                    ),
                  ] else
                    const Text(
                      "Select payment method",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6E757D),
                      ),
                    ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            )
            .animate(target: showError ? 1 : 0)
            .shakeX(amount: 10, duration: const Duration(milliseconds: 300)),
          ),
          
          if (showError)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Text(
                      "!",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Select Payment Method First",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Transfer Details
          const Divider(),
          const SizedBox(height: 8),
          _buildTransferDetails(),
        ],
      ),
    );
  }

  Widget _buildTransferDetails() {
    return Column(
      children: [
        _buildDetailRow("You sent", "100 EUR"),
        _buildDetailRow("Transfer rate", "1 EUR = 1 EUR"),
        _buildDetailRow("Fee", "+2.50 EUR"),
        _buildDetailRow("Transfer Time", "1 Min"),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
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
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Continue",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF181F30),
                ),
              ),
            ),
          ).animate()
            .scale(
              duration: const Duration(milliseconds: 100),
              begin: const Offset(1, 1),
              end: const Offset(0.95, 0.95),
              curve: Curves.easeInOut,
            )
            .then()
            .scale(
              duration: const Duration(milliseconds: 100),
              begin: const Offset(0.95, 0.95),
              end: const Offset(1, 1),
            ),
          
          const SizedBox(height: 12),
          
          // Back Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF6E757D)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Back",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6E757D),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for the Progress Circle
class CircleProgressPainter extends CustomPainter {
  final Color backgroundColor;
  final Color progressColor;
  final double progress;
  final double strokeWidth;

  CircleProgressPainter({
    required this.backgroundColor,
    required this.progressColor,
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    // Create an arc from top (270 degrees) for progress * 360 degrees
    final startAngle = -90 * (pi / 180); // Start from top (270 degrees = -90 radians)
    final sweepAngle = progress * 2 * pi; // Full circle is 2*pi radians
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}