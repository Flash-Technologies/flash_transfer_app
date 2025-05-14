import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SuccessScreen extends StatelessWidget {
  final String message;
  final String buttonText;

  const SuccessScreen({
    Key? key,
    this.message = 'You Have Successfully top up the wallet',
    this.buttonText = 'Get Started',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success image with stars and banner
              Image.asset(
                'assets/images/success.png',
                height: 280,
                width: 260,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      height: 280,
                      width: 260,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.check_circle,
                          size: 120,
                          color: Colors.green,
                        ),
                      ),
                    ),
              ),
              const SizedBox(height: 32),

              // Success title
              Text(
                'Your Account is Set!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF181F30),
                ),
              ),
              const SizedBox(height: 16),

              // Success message
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Color(0xFF6E757D)),
              ),
              const SizedBox(height: 48),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/sign-in');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC000),
                    foregroundColor: const Color(0xFF181F30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
