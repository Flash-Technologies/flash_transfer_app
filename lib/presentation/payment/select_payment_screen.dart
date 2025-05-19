import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flash_transfer_app/config/theme.dart';
import 'package:flash_transfer_app/presentation/payment/components/provider_item.dart';
import 'package:flash_transfer_app/presentation/common/app_button.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';

class SelectPaymentScreen extends ConsumerStatefulWidget {
  const SelectPaymentScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SelectPaymentScreen> createState() => _SelectPaymentScreenState();
}

class _SelectPaymentScreenState extends ConsumerState<SelectPaymentScreen> {
  String? selectedProvider;
  bool showError = false;

  final providers = [
    {
      'id': 'orange',
      'name': 'Orange Money',
      'description': 'Payment Mobile Money account',
      'imageAsset': 'assets/images/orange.png',
    },
    {
      'id': 'wave',
      'name': 'Wave',
      'description': 'Payment Mobile Money account',
      'imageAsset': 'assets/images/wave.png',
    },
    {
      'id': 'mtn',
      'name': 'MTN',
      'description': 'Payment Mobile Money account',
      'imageAsset': 'assets/images/mtn.png',
    },
    {
      'id': 'moov',
      'name': 'Moov Money',
      'description': 'Payment Mobile Money account',
      'imageAsset': 'assets/images/moov.png',
    },
  ];

  void _selectProvider(String id) {
    setState(() {
      selectedProvider = id;
      if (showError) showError = false;
    });
    
    // Update the provider state as well
    ref.read(paymentProvider.notifier).setSelectedProvider(id);
  }

  void _handleSubmit() {
    if (selectedProvider == null) {
      setState(() {
        showError = true;
      });
    } else {
      final paymentState = ref.read(paymentProvider);
      final activePay = paymentState.activePay;
      final activeReceive = paymentState.activeReceive;

      if (activePay == 'cash' && activeReceive == 'mobile') {
        context.push('/review-details-mobile');
      } else if (activePay == 'wallet' && activeReceive == 'mobile') {
        context.push('/review-details-cryptosm');
      } else {
        context.push('/review-details-mobile');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the payment provider state
    final paymentState = ref.watch(paymentProvider);
    
    // If provider already has a selected payment method, use it
    if (paymentState.selectedProvider != null && selectedProvider == null) {
      selectedProvider = paymentState.selectedProvider;
    }
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
            _buildProgressHeader(),
            
            // Main Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Title
                    const Text(
                      'Select your mobile money',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDarkColor,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Error message (conditional)
                    if (showError)
                      _buildErrorMessage().animate().fadeIn(
                            duration: const Duration(milliseconds: 300),
                          ).slideY(
                            begin: -0.2,
                            end: 0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          ),
                    
                    // Provider list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 12),
                        itemCount: providers.length,
                        itemBuilder: (context, index) {
                          final provider = providers[index];
                          return PaymentProviderItem(
                            id: provider['id']!,
                            name: provider['name']!,
                            description: provider['description']!,
                            imageAsset: provider['imageAsset']!,
                            isSelected: selectedProvider == provider['id'],
                            onTap: () => _selectProvider(provider['id']!),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Buttons
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 24),
      color: Colors.white,
      child: Row(
        children: [
          // Progress Circle with 2/4 indicator
          SizedBox(
            width: 40,
            height: 40,
            child: CustomPaint(
              painter: ProgressCirclePainter(progress: 0.5), // 2/4 = 50%
              child: const Center(
                child: Text(
                  "2/4",
                  style: TextStyle(
                    color: AppTheme.textDarkColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Text section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Payment Method",
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDarkColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Enter the information.",
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textGrayColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorLightColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.errorColor),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Text(
              "!",
              style: TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "Select Mobile Money First",
            style: TextStyle(
              color: AppTheme.errorColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AppButton(
            text: "Continue",
            onPressed: _handleSubmit,
            backgroundColor: AppTheme.accentColor,
            textColor: Colors.black87,
            isDisabled: false,
          ),
          const SizedBox(height: 12),
          AppButton(
            text: "Back",
            onPressed: () => context.pop(),
            backgroundColor: Colors.transparent,
            textColor: AppTheme.textGrayColor,
            borderColor: AppTheme.textGrayColor,
          ),
        ],
      ),
    );
  }
}

// Custom painter for the progress circle
class ProgressCirclePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  ProgressCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate center and radius
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    
    // Background circle
    final backgroundPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    
    const startAngle = -90.0 * (3.14159 / 180); // -90 degrees in radians
    final sweepAngle = 360.0 * progress * (3.14159 / 180); // Convert to radians
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}