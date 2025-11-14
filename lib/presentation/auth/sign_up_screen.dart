import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../config/router.dart';
import '../common/social_login_buttons.dart';
import '../../main.dart' show googleSignIn;
import '../settings/widgets/country_selection_widget.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  CountryData? _selectedCountry;

  @override
  void initState() {
    super.initState();
    // Set default country to Senegal
    _selectedCountry = XOFCountries.getXOFCountries().firstWhere(
      (country) => country.name == 'Senegal',
      orElse: () => XOFCountries.getXOFCountries().first,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Add this method to safely update state
  void _safeSetState(Function setState) {
    if (mounted) {
      setState();
    }
  }


  // Handlers for social login
  Future<void> _handleGoogleSignUp(String Function(String) tr) async {
    final authNotifier = ref.read(authProvider.notifier);

    if (_selectedCountry == null) {
      _showErrorDialog(tr('auth.signUp.selectCountry'));
      return;
    }

    try {
      // Sign out first to force account selection
      await googleSignIn.signOut();

      // Trigger sign in
      final result = await googleSignIn.signIn();

      if (result == null) {
        return;
      }

      // Get authentication
      final googleAuth = await result.authentication;
      final token = googleAuth.idToken;

      if (token == null) {
        _showAnimatedSnackBar(tr('auth.signUp.googleAuthTokenError'), false);
        return;
      }

      _safeSetState(() {
        _isLoading = true;
      });

      // Show loading
      _showAnimatedSnackBar('Signing up with Google...', true);

      // Call auth provider with the country from selection
      final success = await authNotifier.loginWithGoogle(
        'firebase',
        token,
        _selectedCountry!.name, 
      );

      // Check if still mounted before updating state
      if (!mounted) return;

      _safeSetState(() {
        _isLoading = false;
      });

      if (success) {

        _showAnimatedSnackBar(
          'Google sign up successful! Redirecting...',
          true,
        );

        // Wait for snackbar to be visible
        await Future.delayed(const Duration(milliseconds: 1000));

        // Check again if still mounted
        if (!mounted) return;

        context.go('/home');
      } else {
        final errorMessage =
            ref.read(authProvider).message ?? tr('auth.signUp.googleSignUpFailed');
        _showAnimatedSnackBar(errorMessage, false);
      }
    } catch (e) {
      // Check if still mounted before updating state
      if (!mounted) return;

      _safeSetState(() {
        _isLoading = false;
      });

      debugPrint('Google sign up error: $e');
      _showAnimatedSnackBar('Failed to sign up with Google: $e', false);
    }
  }

  Future<void> _handleFacebookSignUp(String Function(String) tr) async {
    if (_selectedCountry == null) {
      _showErrorDialog(tr('auth.signUp.selectCountry'));
      return;
    }

    try {
      _safeSetState(() {
        _isLoading = true;
      });

      _showAnimatedSnackBar('Signing up with Facebook...', true);

      // Use enhanced Facebook login method
      final success =
          await ref.read(authProvider.notifier).loginWithFacebookNative();

      // Check if still mounted
      if (!mounted) return;

      _safeSetState(() {
        _isLoading = false;
      });

      if (success) {

        _showAnimatedSnackBar(
          '✅ Facebook sign up successful! Redirecting...',
          true,
        );

        // Wait for snackbar to be visible
        await Future.delayed(const Duration(milliseconds: 1500));

        // Check again if still mounted
        if (!mounted) return;

        context.go('/home');
      } else {
        final errorMessage =
            ref.read(authProvider).message ?? 'Facebook sign up failed';
        _showAnimatedSnackBar('❌ $errorMessage', false);
      }
    } catch (e) {
      // Check if still mounted
      if (!mounted) return;

      _safeSetState(() {
        _isLoading = false;
      });

      debugPrint('💥 Facebook sign up error: $e');
      _showAnimatedSnackBar(
        '❌ Failed to sign up with Facebook: ${e.toString()}',
        false,
      );
    }
  }

  Future<void> _handleAppleSignUp(String Function(String) tr) async {
    if (_selectedCountry == null) {
      _showErrorDialog(tr('auth.signUp.selectCountry'));
      return;
    }

    try {
      _safeSetState(() {
        _isLoading = true;
      });

      _showAnimatedSnackBar('Signing in with Apple...', true);

      // Get Apple credentials
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Get the ID token
      final idToken = credential.identityToken;

      if (idToken == null) {
        _safeSetState(() {
          _isLoading = false;
        });

        _showAnimatedSnackBar('Failed to get Apple ID token', false);
        return;
      }

      // Extract email from token
      String? emailFromToken;
      try {
        final parts = idToken.split('.');
        if (parts.length == 3) {
          String payload = parts[1];
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
          emailFromToken = payloadJson['email'];
        }
      } catch (e) {
        print("Error extracting email from token: $e");
      }

      final authCode = credential.authorizationCode ?? '';
      final sub = credential.userIdentifier ?? '';

      if (authCode.isEmpty || sub.isEmpty) {
        _safeSetState(() {
          _isLoading = false;
        });
        _showAnimatedSnackBar('Failed to get Apple credentials', false);
        return;
      }

      // Call auth provider with the country from selection
      final success = await ref
          .read(authProvider.notifier)
          .loginWithApple(
            idToken: idToken,
            authorizationCode: authCode,
            sub: sub,
            countryName: _selectedCountry!.name,
            email: emailFromToken ?? credential.email,
            firstName: credential.givenName,
            lastName: credential.familyName,
          );

      // Check if still mounted
      if (!mounted) return;

      _safeSetState(() {
        _isLoading = false;
      });

      if (success) {

        _showAnimatedSnackBar('Apple sign up successful! Redirecting...', true);

        // Wait for snackbar to be visible
        await Future.delayed(const Duration(milliseconds: 1000));

        // Check again if still mounted
        if (!mounted) return;

        context.go('/home');
      } else {
        final errorMessage =
            ref.read(authProvider).message ?? 'Apple sign up failed';
        _showAnimatedSnackBar(errorMessage, false);
      }
    } catch (e) {
      // Check if still mounted
      if (!mounted) return;

      _safeSetState(() {
        _isLoading = false;
      });

      debugPrint('Apple sign up error: $e');
      _showAnimatedSnackBar('Failed to sign up with Apple: $e', false);
    }
  }


  bool _validateEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  void _handleContinue(String Function(String) tr) {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showErrorDialog(tr('auth.signUp.fillAllFields'));
      return;
    }

    if (!_validateEmail(_emailController.text)) {
      _showErrorDialog(tr('auth.signUp.validEmail'));
      return;
    }

    if (!_validatePassword(_passwordController.text)) {
      _showErrorDialog(tr('auth.signUp.passwordLength'));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog(tr('auth.signUp.passwordsMatch'));
      return;
    }

    if (_selectedCountry == null) {
      _showErrorDialog(tr('auth.signUp.selectCountry'));
      return;
    }

    // Navigate to identity screen with parameters
    context.push(
      '/set-identity',
      extra: {
        'email': _emailController.text,
        'countryName': _selectedCountry!.name,
        'password': _passwordController.text,
      },
    );
  }

  void _showAnimatedSnackBar(String message, bool isSuccess) {
    // Ensure any existing snackbar is dismissed
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      backgroundColor: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 4),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showErrorDialog(String message) {
    _showAnimatedSnackBar(message, false);
  }


  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationHelperProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 96,
                        height: 96,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr('auth.splash.appName'),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF181F30),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Register Your Account ✍️',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF192031),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('auth.signUp.selectCountry'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CountrySelectionWidget(
                      countries: XOFCountries.getXOFCountries(),
                      selectedCountry: _selectedCountry,
                      onCountrySelected: (country) {
                        setState(() {
                          _selectedCountry = country;
                        });
                      },
                      label: null,
                      hint: tr('auth.signUp.selectCountry'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: tr('auth.signUp.email'),
                    hintText: tr('auth.signUp.email'),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: tr('auth.signUp.password'),
                    hintText: tr('auth.signUp.password'),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: const Color(0xFF6E757D),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: tr('auth.signUp.confirmPassword'),
                    hintText: tr('auth.signUp.confirmPassword'),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: const Color(0xFF6E757D),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleContinue(tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC000),
                      foregroundColor: const Color(0xFF181F30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Colors.grey.shade400,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Color(0xFF181F30),
                          )
                        : Text(
                            tr('auth.signUp.submit'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                SocialLoginButtons(
                  onGoogleLogin: () => _handleGoogleSignUp(tr),
                  onFacebookLogin: () => _handleFacebookSignUp(tr),
                  onAppleLogin: () => _handleAppleSignUp(tr),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tr('auth.signUp.alreadyHaveAccount'),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF6E757D)),
                    ),
                    TextButton(
                      onPressed: () => context.go('/sign-in'),
                      child: Text(
                        tr('auth.signUp.signIn'),
                        style: const TextStyle(
                          color: Color(0xFF2475FF),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
