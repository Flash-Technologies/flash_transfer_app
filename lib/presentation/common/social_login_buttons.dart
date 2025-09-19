import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../providers/auth_provider.dart';
import '../../providers/direct_wallet_provider.dart';
import '../../config/router.dart';
import '../../main.dart' show googleSignIn;
import '../../core/services/facebook_service.dart';
import 'reown_wallet_auth_button.dart';

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
    // Keep the old wallet state for backward compatibility if needed
    // final walletState = ref.watch(directWalletProvider);

    return Column(
      children: [
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
              onPressed:
                  onGoogleLogin ?? () => _handleGoogleLogin(context, ref),
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
              onPressed:
                  onFacebookLogin ?? () => _handleFacebookLogin(context, ref),
            ),
            _buildSocialButton(
              icon: Image.asset(
                'assets/images/apple.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.apple, size: 24, color: Colors.black),
              ),
              label: 'Apple',
              onPressed: onAppleLogin ?? () => _handleAppleLogin(context, ref),
            ),
            // Use Reown wallet auth button instead of native approach
            ReownWalletAuthButton(
              onWalletLogin: onWalletLogin,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required String label,
    required VoidCallback? onPressed,
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      print("🚀 Starting Google Sign In flow");
      await googleSignIn.signOut();

      // Trigger sign in process
      final result = await googleSignIn.signIn();
      print("✅ Sign in result: $result");

      if (result == null) {
        print("❌ Sign in was cancelled by user");
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Google sign in was cancelled')),
        );
        return;
      }

      print("🔑 Getting authentication tokens");
      // Get authentication
      final googleAuth = await result.authentication;
      final token = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      print("📱 Access token: ${accessToken?.substring(0, 10)}...");

      // Print the complete token with clear separators
      print("🎯 ==========================================");
      print("🎯 COMPLETE GOOGLE ID TOKEN FOR BACKEND TEST");
      print("🎯 ==========================================");
      print(token);
      print("🎯 ==========================================");
      print("🎯 END OF TOKEN");
      print("🎯 ==========================================");
      
      // Debug print for complete token (for Postman testing)
      debugPrint("🔥 [DEBUG] COMPLETE TOKEN FOR POSTMAN:");
      debugPrint(token ?? "NULL_TOKEN");

      // Add token debugging
      if (token != null) {
        try {
          // Decode JWT payload (middle part between dots)
          final parts = token.split('.');
          if (parts.length == 3) {
            // Decode the payload (second part)
            String payload = parts[1];
            // Add padding if needed
            switch (payload.length % 4) {
              case 2:
                payload += '==';
                break;
              case 3:
                payload += '=';
                break;
            }

            final bytes = base64Url.decode(payload);
            final decodedPayload = utf8.decode(bytes);
            final payloadJson = json.decode(decodedPayload);

            print("📋 ===== DECODED TOKEN PAYLOAD =====");
            print("📧 Email: ${payloadJson['email']}");
            print("👤 Name: ${payloadJson['name']}");
            print("🖼️ Picture: ${payloadJson['picture']}");
            print("🆔 Subject (Google ID): ${payloadJson['sub']}");
            print(
              "⏰ Issued at: ${payloadJson['iat']} (${DateTime.fromMillisecondsSinceEpoch((payloadJson['iat'] as int) * 1000)})",
            );
            print(
              "⏰ Expires at: ${payloadJson['exp']} (${DateTime.fromMillisecondsSinceEpoch((payloadJson['exp'] as int) * 1000)})",
            );
            print("📄 Full payload JSON:");
            print(decodedPayload);
            print("📋 ===== END DECODED PAYLOAD =====");

            // Show user info in snackbar for easier testing
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Google User: ${payloadJson['email']}'),
                duration: Duration(seconds: 5),
              ),
            );
          }
        } catch (e) {
          print("❌ Error decoding token: $e");
        }
      }

      if (token == null) {
        print("❌ ID token is null");
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Could not get Google auth token')),
        );
        return;
      }

      // Get user country
      String countryName = 'Unknown';
      try {
        final response = await http.get(Uri.parse('https://ipapi.co/json/'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          countryName = data['country_name'] ?? 'Unknown';
          print("🌍 Detected country: $countryName");
        }
      } catch (e) {
        debugPrint('❌ Failed to fetch user country: $e');
      }

      // Print the exact request that will be sent
      final requestData = {'token': token, 'countryName': countryName};

      print("🧪 =======================================");
      print("🧪 POSTMAN/CURL TEST DATA");
      print("🧪 =======================================");
      print("🌐 URL: https://flash-transfer.com/api/user/login-google");
      print("📤 Method: POST");
      print("📋 Headers:");
      print("   Content-Type: application/json");
      print("📦 Raw Body (JSON):");
      print(json.encode(requestData));
      print("🧪 =======================================");
      print("🧪 CURL COMMAND:");
      print(
        'curl -X POST "https://flash-transfer.com/api/user/login-google" \\',
      );
      print('  -H "Content-Type: application/json" \\');
      print('  -d \'${json.encode(requestData)}\'');
      print("🧪 =======================================");
      
      // Debug: Print what we're about to send to the API
      print("🔥 [DEBUG] CALLING loginWithGoogle with:");
      print("🔥 tokenType: 'firebase'");
      print("🔥 token: $token");
      print("🔥 countryName: $countryName");

      // Show loading indicator
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Signing in with Google...')),
      );

      final success = await ref
          .read(authProvider.notifier)
          .loginWithGoogle('google', token ?? '', countryName);

      if (success) {

        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Login successful! Redirecting...')),
        );

        // Add a small delay for the snackbar to be visible
        await Future.delayed(const Duration(milliseconds: 1000));

        if (!context.mounted) return;
        context.go('/home');
      } else {
        final errorMessage =
            ref.read(authProvider).message ?? 'Google login failed';
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      print("💥 ===== DETAILED ERROR INFORMATION =====");
      print("❌ Error: ${e.toString()}");
      print("📍 Error type: ${e.runtimeType}");

      // if (e is PlatformException) {
      //   print("Error code: ${e.code}");
      //   print("Error message: ${e.message}");
      //   print("Error details: ${e.details}");
      // }

      print("💥 ===== END ERROR INFORMATION =====");

      debugPrint('Google sign in error: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to sign in with Google: $e')),
      );
    }
  }

  Future<void> _handleFacebookLogin(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      debugPrint('🚀 Starting enhanced Facebook login from social buttons');

      // Show loading indicator immediately
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Signing in with Facebook...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      // Use the enhanced Facebook login from auth provider
      final success =
          await ref.read(authProvider.notifier).loginWithFacebookNative();

      // Clear the loading snackbar
      scaffoldMessenger.hideCurrentSnackBar();

      if (success) {

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Facebook login successful! Redirecting...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Add a small delay for the snackbar to be visible
        await Future.delayed(const Duration(milliseconds: 1500));

        if (!context.mounted) return;
        context.go('/home');
      } else {
        final errorMessage =
            ref.read(authProvider).message ?? 'Facebook login failed';

        debugPrint('❌ Facebook login failed: $errorMessage');

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('💥 Facebook sign in error in social buttons: $e');

      // Clear any existing snackbar
      scaffoldMessenger.hideCurrentSnackBar();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('❌ Facebook login error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleAppleLogin(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Request Apple sign in with the correct credentials
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // Use the credentials provided by the user
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.flashTransfer.new.auth',
          redirectUri: Uri.parse('https://flash.closedsource.in/signin'),
        ),
      );

      // Get the ID token from the credential
      final idToken = credential.identityToken;

      if (idToken == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Failed to get Apple ID token')),
        );
        return;
      }

      // Show loading indicator
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Signing in with Apple...')),
      );

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

      // Call the auth provider to authenticate with the backend
      final success = await ref
          .read(authProvider.notifier)
          .loginWithApple(idToken, countryName);

      if (success) {

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Apple login successful! Redirecting...'),
            backgroundColor: Colors.green,
          ),
        );

        // Add a small delay for the snackbar to be visible
        await Future.delayed(const Duration(milliseconds: 1000));

        if (!context.mounted) return;
        context.go('/home');
      } else {
        final errorMessage =
            ref.read(authProvider).message ?? 'Apple login failed';
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      debugPrint('Apple sign in error: $e');

      // Special handling for Apple Sign In errors
      String errorMessage = 'Failed to sign in with Apple';

      if (e.toString().contains('canceled')) {
        errorMessage = 'Apple sign in was cancelled';
      } else if (e.toString().contains('AuthorizationErrorCode.unknown')) {
        errorMessage = 'Apple sign in failed: Unknown error';
      } else if (e.toString().contains('AuthorizationErrorCode.failed')) {
        errorMessage = 'Apple sign in failed: Authentication failed';
      }

      scaffoldMessenger.showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  // DEPRECATED: Old native wallet implementation - kept for reference
  // This method is no longer used as we've switched to Reown for wallet authentication
  // To revert back to native implementation:
  // 1. Remove ReownWalletAuthButton from the build method
  // 2. Uncomment the old wallet button code
  // 3. Call this method from the wallet button's onPressed
  Future<void> _handleDirectWalletLogin(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Connect to wallet using direct integration
      final walletNotifier = ref.read(directWalletProvider.notifier);
      final connected = await walletNotifier.connectWallet(context);

      if (!connected) {
        final errorMessage = ref.read(directWalletProvider).errorMessage ??
            'Wallet connection failed';
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(errorMessage)));
        return;
      }

      // Get wallet address
      final walletAddress = ref.read(directWalletProvider).walletAddress;

      if (walletAddress == null || walletAddress.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Failed to get wallet address')),
        );
        return;
      }

      // Show address in snackbar for testing
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Connected with address: $walletAddress')),
      );

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

      // Authenticate with the backend
      final success = await ref
          .read(authProvider.notifier)
          .loginWithWalletAddress(walletAddress, countryName);

      if (success) {

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Wallet login successful! Redirecting...'),
            backgroundColor: Colors.green,
          ),
        );

        // Add a small delay for the snackbar to be visible
        await Future.delayed(const Duration(milliseconds: 1000));

        if (!context.mounted) return;
        context.go('/home');
      } else {
        final errorMessage =
            ref.read(authProvider).message ?? 'Wallet login failed';
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      debugPrint('Wallet sign in error: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to sign in with wallet: $e')),
      );
    }
  }
}
