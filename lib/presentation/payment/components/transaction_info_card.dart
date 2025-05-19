import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flash_transfer_app/config/theme.dart';

class TransactionInfoCard extends StatefulWidget {
  final Map<String, String> transactionDetails;

  const TransactionInfoCard({
    Key? key,
    required this.transactionDetails,
  }) : super(key: key);

  @override
  State<TransactionInfoCard> createState() => _TransactionInfoCardState();
}

class _TransactionInfoCardState extends State<TransactionInfoCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            foregroundPainter: BorderGradientPainter(
              animation: _animationController,
              borderWidth: 2.0,
              gradientColors: [
                AppTheme.primaryColor.withOpacity(0.0),
                AppTheme.primaryColor.withOpacity(0.7),
                AppTheme.primaryColor.withOpacity(0.0),
              ],
            ),
            child: child,
          );
        },
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: _buildTransactionItems(),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTransactionItems() {
    final items = <Widget>[];
    
    int index = 0;
    widget.transactionDetails.forEach((key, value) {
      if (items.isNotEmpty) {
        items.add(const Divider(height: 24));
      }
      
      items.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              key,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6A6A6A),
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF181F30),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ).animate(
          delay: Duration(milliseconds: 100 * index),
        ).fadeIn(
          duration: const Duration(milliseconds: 300),
        ).slideX(
          begin: 0.05,
          end: 0,
          curve: Curves.easeOutQuad,
          duration: const Duration(milliseconds: 300),
        ),
      );
      
      index++;
    });
    
    return items;
  }
}

class BorderGradientPainter extends CustomPainter {
  final Animation<double> animation;
  final double borderWidth;
  final List<Color> gradientColors;
  
  BorderGradientPainter({
    required this.animation,
    required this.borderWidth,
    required this.gradientColors,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final RRect rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    
    final gradient = SweepGradient(
      transform: GradientRotation(animation.value * 2 * 3.14159),
      colors: gradientColors,
    );
    
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = gradient.createShader(rect);
    
    canvas.drawRRect(rrect, paint);
  }
  
  @override
  bool shouldRepaint(BorderGradientPainter oldDelegate) {
    return animation != oldDelegate.animation;
  }
}