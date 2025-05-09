// lib/presentation/common/social_login_buttons.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/auth_provider.dart';

class SocialLoginButtons extends ConsumerWidget {
  final Function()? onGoogleLogin;
  final Function()? onFacebookLogin;
  final Function()? onAppleLogin;
  final Function()? onWalletLogin;

  const SocialLoginButtons({
    Key? key,
    this.onGoogleLogin,
    this.onFacebookLogin,
    this.onAppleLogin,
    this.onWalletLogin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // const Text(
        //   'OR',
        //   style: TextStyle(
        //     fontSize: 14,
        //     color: Color(0xFF6E757D),
        //   ),
        // ),
        // const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            _buildSocialButton(
              icon: Image.asset(
                'assets/images/google.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.g_mobiledata,
                  size: 24,
                  color: Color(0xFF4285F4),
                ),
              ),
              label: 'Google',
              onPressed: onGoogleLogin ?? () => _handleGoogleLogin(context, ref),
            ),
            _buildSocialButton(
              icon: Image.asset(
                'assets/images/facebook.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.facebook,
                  size: 24,
                  color: Color(0xFF1877F2),
                ),
              ),
              label: 'Facebook',
              onPressed: onFacebookLogin ?? () => _handleFacebookLogin(context),
            ),
            _buildSocialButton(
              icon: Image.asset(
                'assets/images/apple.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.apple,
                  size: 24,
                  color: Colors.black,
                ),
              ),
              label: 'Apple',
              onPressed: onAppleLogin ?? () => _handleAppleLogin(context),
            ),
            _buildSocialButton(
              icon: Image.asset(
                'assets/images/wallet.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.account_balance_wallet,
                  size: 24,
                  color: Colors.black,
                ),
              ),
              label: 'Wallet',
              onPressed: onWalletLogin ?? () => _handleWalletLogin(context),
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

  Future<void> _handleGoogleLogin(BuildContext context, WidgetRef ref) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final result = await googleSignIn.signIn();
      
      if (result == null) {
        return;
      }
      
      final googleAuth = await result.authentication;
      final token = googleAuth.idToken!;
      
      // Get user country
      String countryName = 'Unknown';
      try {
        final response = await http.get(Uri.parse('https://ipapi.co/json/'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          countryName = data['country_name'] ?? 'Unknown';
        }
      } catch (e) {
        debugPrint('Failed to fetch user country: $e');
      }
      
      final success = await ref.read(authProvider.notifier).loginWithGoogle(
        token,
        countryName,
      );
      
      if (success) {
        // Use GoRouter to navigate, but we're in a static method
        // So we need to get navigator
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(authProvider).message ?? 'Google login failed'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in with Google: $e')),
      );
    }
  }

  void _handleFacebookLogin(BuildContext context) {
    // This would be implemented with a Facebook SDK
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Facebook login not implemented yet')),
    );
  }

  void _handleAppleLogin(BuildContext context) {
    // This would be implemented with Apple Sign-In
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple login not implemented yet')),
    );
  }

  void _handleWalletLogin(BuildContext context) {
    // This would be implemented with Wallet connection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallet login not implemented yet')),
    );
  }
}