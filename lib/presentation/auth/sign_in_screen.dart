import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/models/auth_models.dart';
import '../../providers/auth_provider.dart';
import '../../config/router.dart';
import '../common/social_login_buttons.dart';
import '../../main.dart' show googleSignIn;

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _googleSignIn = googleSignIn;
  bool _isLoading = false;
  String? _userCountry;

  @override
  void initState() {
    super.initState();
    _fetchUserCountry();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserCountry() async {
    try {
      final response = await http.get(Uri.parse('https://ipapi.co/json/'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _userCountry = data['country_name'] ?? 'Unknown';
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch user country: $e');
    }
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

  // Add this method to safely update state
  void _safeSetState(Function setState) {
    if (mounted) {
      setState();
    }
  }

  Future<void> _handleLogin() async {
    // Validate inputs first
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showAnimatedSnackBar('Please fill in all fields', false);
      return;
    }

    final loginRequest = LoginRequest(
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      // Log for debugging
      debugPrint('Attempting login with email: ${_emailController.text}');

      final success = await ref.read(authProvider.notifier).login(loginRequest);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _showAnimatedSnackBar('Login successful! Redirecting...', true);

        // Update the logged in state in the router
        ref.read(isLoggedInProvider.notifier).state = true;

        // Short delay to let the snackbar be visible
        await Future.delayed(const Duration(milliseconds: 1000));

        if (!mounted) return;

        // Navigate to home screen
        context.go('/home');
      } else {
        // Get error message from auth state
        final errorMessage = ref.read(authProvider).message ?? 'Login failed';
        debugPrint('Login failed with error: $errorMessage');

        // Show error message
        _showAnimatedSnackBar(errorMessage, false);
      }
    } catch (e) {
      debugPrint('Login exception: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showAnimatedSnackBar('Error: ${e.toString()}', false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      // Sign out first to ensure we get the account selection dialog
      await _googleSignIn.signOut();

      final result = await _googleSignIn.signIn();

      if (result == null) {
        _showAnimatedSnackBar('Google sign in was cancelled', false);
        return;
      }

      final googleAuth = await result.authentication;
      final token = googleAuth.idToken;

      if (token == null) {
        _showAnimatedSnackBar('Could not get Google auth token', false);
        return;
      }

      _safeSetState(() {
        _isLoading = true;
      });

      if (_userCountry == null) {
        await _fetchUserCountry();
      }

      // Check if still mounted
      if (!mounted) return;

      // Show loading message
      _showAnimatedSnackBar('Signing in with Google...', true);

      final success = await ref
          .read(authProvider.notifier)
          .loginWithGoogle(token, _userCountry ?? 'Unknown');

      // Check if still mounted
      if (!mounted) return;

      _safeSetState(() {
        _isLoading = false;
      });

      if (success) {
        // Update logged in state
        ref.read(isLoggedInProvider.notifier).state = true;

        _showAnimatedSnackBar('Google login successful! Redirecting...', true);

        // Give the snackbar time to display
        await Future.delayed(const Duration(milliseconds: 1000));

        // Check again if still mounted
        if (!mounted) return;

        // Navigate to home
        context.go('/home');
      } else {
        final errorMessage =
            ref.read(authProvider).message ?? 'Google login failed';
        _showAnimatedSnackBar(errorMessage, false);
      }
    } catch (e) {
      // Check if still mounted before updating state
      if (!mounted) return;

      _safeSetState(() {
        _isLoading = false;
      });

      debugPrint('Google sign in error: $e');
      _showAnimatedSnackBar('Failed to sign in with Google: $e', false);
    }
  }

  Future<void> _handleFacebookLogin(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      setState(() {
        _isLoading = true;
      });

      // Trigger Facebook login with required permissions
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        setState(() {
          _isLoading = false;
        });

        if (result.status == LoginStatus.cancelled) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Facebook login cancelled')),
          );
          return;
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Facebook login failed: ${result.message}')),
          );
          return;
        }
      }

      // Get the Facebook access token
      final accessToken = result.accessToken?.token;

      if (accessToken == null) {
        setState(() {
          _isLoading = false;
        });

        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Failed to get Facebook access token')),
        );
        return;
      }

      if (_userCountry == null) {
        await _fetchUserCountry();
      }

      // Show loading indicator
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Signing in with Facebook...')),
      );

      // Call the auth provider to authenticate with the backend
      final success = await ref
          .read(authProvider.notifier)
          .loginWithFacebook(accessToken, _userCountry ?? 'Unknown');

      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Update logged in state
        ref.read(isLoggedInProvider.notifier).state = true;

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Facebook login successful! Redirecting...'),
              backgroundColor: Colors.green,
            ),
          );

          // Add a small delay to see the success message
          await Future.delayed(const Duration(milliseconds: 1000));

          if (mounted) {
            context.go('/home');
          }
        }
      } else {
        if (mounted) {
          final errorMessage =
              ref.read(authProvider).message ?? 'Facebook login failed';
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        debugPrint('Facebook sign in error: $e');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to sign in with Facebook: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleAppleLogin(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      setState(() {
        _isLoading = true;
      });

      // Request Apple sign in with the correct credentials
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Get the ID token from the credential
      final idToken = credential.identityToken;

      if (idToken == null) {
        setState(() {
          _isLoading = false;
        });

        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Failed to get Apple ID token')),
        );
        return;
      }

      if (_userCountry == null) {
        await _fetchUserCountry();
      }

      // Show loading indicator
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Signing in with Apple...')),
      );

      // Call the auth provider to authenticate with the backend
      final success = await ref
          .read(authProvider.notifier)
          .loginWithApple(idToken, _userCountry ?? 'Unknown');

      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Update logged in state
        ref.read(isLoggedInProvider.notifier).state = true;

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Apple login successful! Redirecting...'),
              backgroundColor: Colors.green,
            ),
          );

          // Add a small delay to see the success message
          await Future.delayed(const Duration(milliseconds: 1000));

          if (mounted) {
            context.go('/home');
          }
        }
      } else {
        if (mounted) {
          final errorMessage =
              ref.read(authProvider).message ?? 'Apple login failed';
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
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

        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleForgotPassword() {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Forgot Password'),
            content: const Text(
              'We will send a password reset link to your email address.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);

                  // In a real app, you would call an API to send a reset link
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reset link sent to your email'),
                    ),
                  );
                },
                child: const Text('Send Reset Link'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading || _isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),

                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 110,
                        height: 110,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Flash Transfer',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF181F30),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Welcome Back 👋',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF192031),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email or Phone',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Enter your email or phone',
                        hintStyle: const TextStyle(
                          color: Color(0xFF6E757D),
                          fontSize: 14,
                        ),
                        filled: false,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFEBECED),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFEBECED),
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: const TextStyle(
                          color: Color(0xFF6E757D),
                          fontSize: 14,
                        ),
                        filled: false,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFEBECED),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFEBECED),
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF2475FF),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC000),
                      foregroundColor: const Color(0xFF181F30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Colors.grey.shade400,
                    ),
                    child:
                        isLoading
                            ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF181F30),
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Logging in...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                            : const Text(
                              'Log in',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                  ),
                ),

                const SizedBox(height: 24),

                const Row(
                  children: [
                    Expanded(
                      child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Color(0xFF6E757D),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SocialLoginButtons(
                  onGoogleLogin: _handleGoogleLogin,
                  onFacebookLogin: () => _handleFacebookLogin(context, ref),
                  onAppleLogin: () => _handleAppleLogin(context, ref),
                ),

                const SizedBox(height: 48),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(fontSize: 14, color: Color(0xFF6E757D)),
                    ),
                    TextButton(
                      onPressed: () => context.go('/sign-up'),
                      child: const Text(
                        'Register now',
                        style: TextStyle(
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
