import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../core/models/auth_models.dart';
import '../../providers/auth_provider.dart';
import '../../config/router.dart';
import '../common/social_login_buttons.dart';
import '../../main.dart' show googleSignIn;

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

  CountryModel? _selectedCountry;
  List<CountryModel> _countries = [];
  bool _loadingCountries = true;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
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
  Future<void> _handleGoogleSignUp() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authNotifier = ref.read(authProvider.notifier);

    if (_selectedCountry == null) {
      _showErrorDialog('Please select a country');
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
        _showAnimatedSnackBar('Could not get Google auth token', false);
        return;
      }

      _safeSetState(() {
        _isLoading = true;
      });

      // Show loading
      _showAnimatedSnackBar('Signing up with Google...', true);

      // Call auth provider with the country from selection
      final success = await authNotifier.loginWithGoogle(
        token,
        _selectedCountry!.name,
      );

      // Check if still mounted before updating state
      if (!mounted) return;

      _safeSetState(() {
        _isLoading = false;
      });

      if (success) {
        // Update logged in state
        ref.read(isLoggedInProvider.notifier).state = true;

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
            ref.read(authProvider).message ?? 'Google sign up failed';
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

  Future<void> _handleFacebookSignUp() async {
    if (_selectedCountry == null) {
      _showErrorDialog('Please select a country');
      return;
    }

    try {
      // For Facebook sign in, we'll use the SocialLoginButtons implementation
      _safeSetState(() {
        _isLoading = true;
      });

      _showAnimatedSnackBar('Signing in with Facebook...', true);

      // Implement actual Facebook login here if available
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        _safeSetState(() {
          _isLoading = false;
        });

        if (result.status == LoginStatus.cancelled) {
          _showAnimatedSnackBar('Facebook login was cancelled', false);
          return;
        } else {
          _showAnimatedSnackBar(
            'Facebook login failed: ${result.message}',
            false,
          );
          return;
        }
      }

      // Get the access token
      final accessToken = result.accessToken?.token;

      if (accessToken == null) {
        _safeSetState(() {
          _isLoading = false;
        });

        _showAnimatedSnackBar('Failed to get Facebook access token', false);
        return;
      }

      // Call auth provider with the country from selection
      final success = await ref
          .read(authProvider.notifier)
          .loginWithFacebook(accessToken, _selectedCountry!.name);

      // Check if still mounted
      if (!mounted) return;

      _safeSetState(() {
        _isLoading = false;
      });

      if (success) {
        // Update logged in state
        ref.read(isLoggedInProvider.notifier).state = true;

        _showAnimatedSnackBar(
          'Facebook sign up successful! Redirecting...',
          true,
        );

        // Wait for snackbar to be visible
        await Future.delayed(const Duration(milliseconds: 1000));

        // Check again if still mounted
        if (!mounted) return;

        context.go('/home');
      } else {
        final errorMessage =
            ref.read(authProvider).message ?? 'Facebook sign up failed';
        _showAnimatedSnackBar(errorMessage, false);
      }
    } catch (e) {
      // Check if still mounted
      if (!mounted) return;

      _safeSetState(() {
        _isLoading = false;
      });

      debugPrint('Facebook sign up error: $e');
      _showAnimatedSnackBar('Failed to sign up with Facebook: $e', false);
    }
  }

  Future<void> _handleAppleSignUp() async {
    if (_selectedCountry == null) {
      _showErrorDialog('Please select a country');
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

      // Call auth provider with the country from selection
      final success = await ref
          .read(authProvider.notifier)
          .loginWithApple(idToken, _selectedCountry!.name);

      // Check if still mounted
      if (!mounted) return;

      _safeSetState(() {
        _isLoading = false;
      });

      if (success) {
        // Update logged in state
        ref.read(isLoggedInProvider.notifier).state = true;

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

  Future<void> _fetchCountries() async {
    try {
      final response = await http.get(
        Uri.parse('https://restcountries.com/v3.1/all'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final countries =
            data
                .map(
                  (country) => CountryModel(
                    name: country['name']['common'],
                    flag:
                        country['flags']['svg'] ??
                        country['flags']['png'] ??
                        '',
                  ),
                )
                .toList()
              ..sort((a, b) => a.name.compareTo(b.name));

        if (mounted) {
          setState(() {
            _countries = countries;
            _loadingCountries = false;

            // Set default country to United States
            _selectedCountry = countries.firstWhere(
              (c) => c.name == 'United States',
              orElse: () => countries.first,
            );
          });
        }
      } else {
        throw Exception('Failed to load countries');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCountries = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load countries: $e')));
      }
    }
  }

  bool _validateEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  void _handleContinue() {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showErrorDialog('Please fill in all fields');
      return;
    }

    if (!_validateEmail(_emailController.text)) {
      _showErrorDialog('Please enter a valid email address');
      return;
    }

    if (!_validatePassword(_passwordController.text)) {
      _showErrorDialog('Password must be at least 6 characters');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Passwords do not match');
      return;
    }

    if (_selectedCountry == null) {
      _showErrorDialog('Please select a country');
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

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Select Country',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _countries.length,
                    itemBuilder: (context, index) {
                      final country = _countries[index];
                      return ListTile(
                        leading: Image.network(
                          country.flag,
                          width: 32,
                          height: 20,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  const Icon(Icons.flag),
                        ),
                        title: Text(country.name),
                        onTap: () {
                          setState(() {
                            _selectedCountry = country;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      const Text(
                        'Flash Transfer',
                        style: TextStyle(
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
                    const Text(
                      'Send From',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _loadingCountries ? null : _showCountryPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F5F7),
                          border: Border.all(color: const Color(0xFFEBECED)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            _loadingCountries
                                ? const Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Loading countries...'),
                                  ],
                                )
                                : Row(
                                  children: [
                                    if (_selectedCountry != null)
                                      Image.network(
                                        _selectedCountry!.flag,
                                        width: 24,
                                        height: 16,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.flag,
                                                  size: 24,
                                                ),
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedCountry?.name ??
                                          'Select Country',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF181F30),
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 16,
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Enter Your Mail',
                    hintText: 'Enter your email',
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Set Password',
                    hintText: 'Set your Password',
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter Password',
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC000),
                      foregroundColor: const Color(0xFF181F30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Colors.grey.shade400,
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Color(0xFF181F30),
                            )
                            : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                  ),
                ),

                const SizedBox(height: 24),

                SocialLoginButtons(
                  onGoogleLogin: _handleGoogleSignUp,
                  onFacebookLogin: _handleFacebookSignUp,
                  onAppleLogin: _handleAppleSignUp,
                ),

                const SizedBox(height: 48),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(fontSize: 14, color: Color(0xFF6E757D)),
                    ),
                    TextButton(
                      onPressed: () => context.go('/sign-in'),
                      child: const Text(
                        'Login',
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
