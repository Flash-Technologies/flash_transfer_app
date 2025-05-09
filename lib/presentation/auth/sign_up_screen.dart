import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/common/social_login_buttons.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _selectedCountryCode = 'US';
  Map<String, dynamic> _selectedCountry = {
    'cca2': 'US', 
    'name': {'common': 'United States'},
    'flag': 'https://flagcdn.com/us.svg',
  };

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  void _handleContinue() {
    // Form validation
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    
    if (!_validateEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }
    
    if (!_validatePassword(_passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    // Navigate to identity screen with parameters
    context.push('/set-identity?email=${_emailController.text}&countryName=${_selectedCountry['name']['common']}&password=${_passwordController.text}');
  }

  void _showCountryPicker() {
    // For now, we'll use a simple dialog
    // In a real app, you'd use a proper country picker package
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Country'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildCountryTile('US', 'United States', 'https://flagcdn.com/us.svg'),
              _buildCountryTile('GB', 'United Kingdom', 'https://flagcdn.com/gb.svg'),
              _buildCountryTile('FR', 'France', 'https://flagcdn.com/fr.svg'),
              _buildCountryTile('DE', 'Germany', 'https://flagcdn.com/de.svg'),
              _buildCountryTile('IN', 'India', 'https://flagcdn.com/in.svg'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryTile(String code, String name, String flag) {
    return ListTile(
      leading: Image.network(
        flag,
        width: 30,
        height: 20,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag),
      ),
      title: Text(name),
      onTap: () {
        setState(() {
          _selectedCountryCode = code;
          _selectedCountry = {
            'cca2': code,
            'name': {'common': name},
            'flag': flag,
          };
        });
        Navigator.pop(context);
      },
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
                // Logo and app name
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
                
                // Country selector
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
                    GestureDetector(
                      onTap: _showCountryPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F5F7),
                          border: Border.all(
                            color: const Color(0xFFEBECED),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: Image.network(
                                _selectedCountry['flag'],
                                width: 24,
                                height: 16,
                                errorBuilder: (context, error, stackTrace) => 
                                    const Icon(Icons.flag, size: 24),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedCountry['name']['common'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF181F30),
                              ),
                            ),
                            const Spacer(),
                            Image.asset(
                              'assets/icons/navigation_icons/arrow_down.png',
                              width: 12,
                              height: 6,
                              // If asset not available yet, use Icon instead
                              errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.keyboard_arrow_down, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Email field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter Your Mail',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
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
                
                // Password field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Set your Password',
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
                
                // Confirm Password field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Confirm Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Re-enter Password',
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
                const SizedBox(height: 32),
                
                // Continue button
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
                    child: _isLoading
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
                
                // Social login buttons
                const SocialLoginButtons(),
                
                const SizedBox(height: 48),
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6E757D),
                      ),
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