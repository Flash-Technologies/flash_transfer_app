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
    final walletState = ref.watch(directWalletProvider);

    // Add loading indicator for wallet button when connecting
    final isWalletConnecting =
        walletState.status == WalletConnectionStatus.connecting;

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
                errorBuilder:
                    (_, __, ___) => const Icon(
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
                errorBuilder:
                    (_, __, ___) => const Icon(
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
                errorBuilder:
                    (_, __, ___) =>
                        const Icon(Icons.apple, size: 24, color: Colors.black),
              ),
              label: 'Apple',
              onPressed: onAppleLogin ?? () => _handleAppleLogin(context, ref),
            ),
            _buildSocialButton(
              icon:
                  isWalletConnecting
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF6E757D),
                          ),
                        ),
                      )
                      : Image.asset(
                        'assets/images/wallet.png',
                        width: 24,
                        height: 24,
                        errorBuilder:
                            (_, __, ___) => const Icon(
                              Icons.account_balance_wallet,
                              size: 24,
                              color: Colors.black,
                            ),
                      ),
              label: isWalletConnecting ? 'Connecting...' : 'Wallet',
              onPressed:
                  isWalletConnecting
                      ? null
                      : (onWalletLogin ??
                          () => _handleDirectWalletLogin(context, ref)),
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
    print("Starting Google Sign In flow");
    // Sign out first to ensure we get the account selection dialog
    await googleSignIn.signOut();

    // Trigger sign in process
    final result = await googleSignIn.signIn();
    print("Sign in result: $result");

    if (result == null) {
      print("Sign in was cancelled by user");
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Google sign in was cancelled')),
      );
      return;
    }

    print("Getting authentication tokens");
    // Get authentication
    final googleAuth = await result.authentication;
    final token = googleAuth.idToken;
    print("Access token: ${googleAuth.accessToken?.substring(0, 10)}...");
    print("ID token: ${token?.substring(0, 10)}...");

    if (token == null) {
      print("ID token is null");
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
      }
    } catch (e) {
      debugPrint('Failed to fetch user country: $e');
    }

    // Show loading indicator
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Signing in with Google...')),
    );

    final success = await ref
        .read(authProvider.notifier)
        .loginWithGoogle(token, countryName);

    if (success) {
      // Update logged in state
      ref.read(isLoggedInProvider.notifier).state = true;

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
    print("Detailed error information:");
    print(e.toString());
    
    // if (e is PlatformException) {
    //   print("Error code: ${e.code}");
    //   print("Error message: ${e.message}");
    //   print("Error details: ${e.details}");
    // }
    
    debugPrint('Google sign in error: $e');
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('Failed to sign in with Google: $e')),
    );
  }
}

  Future<void> _handleFacebookLogin(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Trigger Facebook login with required permissions
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        if (result.status == LoginStatus.cancelled) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Facebook login cancelled')),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Facebook login failed: ${result.message}')),
          );
        }
        return;
      }

      // Get the access token from the result
      final accessToken = result.accessToken?.token;

      if (accessToken == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Failed to get Facebook access token')),
        );
        return;
      }

      // Show loading indicator
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Signing in with Facebook...')),
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
          .loginWithFacebook(accessToken, countryName);

      if (success) {
        // Update logged in state
        ref.read(isLoggedInProvider.notifier).state = true;

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Facebook login successful! Redirecting...'),
            backgroundColor: Colors.green,
          ),
        );

        // Add a small delay for the snackbar to be visible
        await Future.delayed(const Duration(milliseconds: 1000));

        if (!context.mounted) return;
        context.go('/home');
      } else {
        final errorMessage =
            ref.read(authProvider).message ?? 'Facebook login failed';
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      debugPrint('Facebook sign in error: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to sign in with Facebook: $e')),
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
        // Update logged in state
        ref.read(isLoggedInProvider.notifier).state = true;

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
        final errorMessage =
            ref.read(directWalletProvider).errorMessage ??
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
        // Update logged in state
        ref.read(isLoggedInProvider.notifier).state = true;

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
