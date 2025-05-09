import 'package:flutter/material.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          alignment: WrapAlignment.center,
          children: [
            _buildSocialButton(
              icon: Image.asset(
                'assets/icons/google.png',
                width: 24,
                height: 24,
                errorBuilder:
                    (context, error, stackTrace) => const Icon(
                      Icons.g_mobiledata,
                      size: 24,
                      color: Color(0xFF4285F4),
                    ),
              ),
              label: 'Google',
              onPressed: () => _handleSocialLogin('google'),
            ),
            _buildSocialButton(
              icon: Image.asset(
                'assets/icons/facebook.png',
                width: 24,
                height: 24,
                errorBuilder:
                    (context, error, stackTrace) => const Icon(
                      Icons.facebook,
                      size: 24,
                      color: Color(0xFF1877F2),
                    ),
              ),
              label: 'Facebook',
              onPressed: () => _handleSocialLogin('facebook'),
            ),
            _buildSocialButton(
              icon: Image.asset(
                'assets/icons/apple.png',
                width: 24,
                height: 24,
                errorBuilder:
                    (context, error, stackTrace) =>
                        const Icon(Icons.apple, size: 24, color: Colors.black),
              ),
              label: 'Apple',
              onPressed: () => _handleSocialLogin('apple'),
            ),
            _buildSocialButton(
              icon: Image.asset(
                'assets/icons/wallet.png',
                width: 24,
                height: 24,
                errorBuilder:
                    (context, error, stackTrace) => const Icon(
                      Icons.account_balance_wallet,
                      size: 24,
                      color: Colors.black,
                    ),
              ),
              label: 'Wallet',
              onPressed: () => _handleSocialLogin('wallet'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 160,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: const Color(0xFF6E757D),
          backgroundColor: const Color(0xFFF4F5F7),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8.0),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSocialLogin(String provider) {
    // This would be connected to auth provider in a real app
    print('Login with $provider');
  }
}
