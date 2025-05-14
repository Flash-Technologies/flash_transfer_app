import 'package:flash_transfer_app/presentation/auth/sign_in_screen.dart';
import 'package:flash_transfer_app/presentation/auth/success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/auth_models.dart';
import '../../providers/auth_provider.dart';
import '../common/date_selection.dart';

class SetIdentityScreen extends ConsumerStatefulWidget {
  final String email;
  final String countryName;
  final String password;

  const SetIdentityScreen({
    Key? key,
    required this.email,
    required this.countryName,
    required this.password,
  }) : super(key: key);

  @override
  ConsumerState<SetIdentityScreen> createState() => _SetIdentityScreenState();
}

class _SetIdentityScreenState extends ConsumerState<SetIdentityScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _permanentAddressController = TextEditingController();
  final _presentAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();

  String _gender = 'Male';
  String? _dob;
  bool _sameAddress = false;
  bool _isAgreed = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _permanentAddressController.dispose();
    _presentAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }
  
  void _handleRegister() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  if (!_isAgreed) {
    _showSnackBar('Please agree to the Terms of Use');
    return;
  }

  if (_dob == null) {
    _showSnackBar('Please select your date of birth');
    return;
  }

  setState(() {
    _isSubmitting = true;
  });

  final registerRequest = RegisterRequest(
    email: widget.email,
    password: widget.password,
    countryName: widget.countryName,
    firstName: _firstNameController.text,
    lastName: _lastNameController.text,
    gender: _gender.toLowerCase(),
    dob: _dob!,
    permanentAddress: _permanentAddressController.text,
    presentAddress: _sameAddress ? _permanentAddressController.text : _presentAddressController.text,
    city: _cityController.text,
    state: _stateController.text,
    postalCode: _postalCodeController.text,
  );

  try {
    final success = await ref.read(authProvider.notifier).register(registerRequest);

    // Make sure we're still mounted before updating UI
    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      // Traditional navigation to success screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationSuccessScreen(email: widget.email),
        ),
      );
    } else {
      final authState = ref.read(authProvider);
      String errorMessage = authState.message ?? 'Registration failed';
      
      if (authState.fieldErrors != null && authState.fieldErrors!.isNotEmpty) {
        final fieldErrorsList = authState.fieldErrors!.entries
            .map((e) => "${e.key}: ${e.value}")
            .join("\n• ");
            
        errorMessage = "Validation errors:\n• $fieldErrorsList";
      }
      
      _showSnackBar(errorMessage);
    }
  } catch (e) {
    if (!mounted) return;
    
    setState(() {
      _isSubmitting = false;
    });
    
    _showSnackBar('Error: ${e.toString()}');
  }
}

void _showSnackBar(String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3), 
      margin: const EdgeInsets.all(16),
      elevation: 4,
    ),
  );
} 

  @override
  Widget build(BuildContext context) {
    final isLoading = _isSubmitting;

    return WillPopScope(
      onWillPop: () async => !isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Set your Identity'),
          leading: isLoading 
              ? null 
              : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),  
              ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                Text(
                  'Input your personal information and register your account!',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF6E757D),
                      ),
                ),
                const SizedBox(height: 24),

                // First Name
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    hintText: 'Enter your first name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Last Name
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    hintText: 'Enter your last name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Gender
                Text(
                  'Gender',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Male'),
                        value: 'Male',
                        groupValue: _gender,
                        onChanged: (value) {
                          setState(() {
                            _gender = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Female'),
                        value: 'Female',
                        groupValue: _gender,
                        onChanged: (value) {
                          setState(() {
                            _gender = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date of Birth
                DateSelection(
                  onDateChange: (date) {
                    setState(() {
                      _dob = date;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Permanent Address
                TextFormField(
                  controller: _permanentAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Permanent Address',
                    hintText: 'Enter your permanent address',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your permanent address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Present Address Same Checkbox
                CheckboxListTile(
                  title: const Text('Present address same as permanent'),
                  value: _sameAddress,
                  onChanged: (value) {
                    setState(() {
                      _sameAddress = value!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                const SizedBox(height: 16),

                // Present Address (if different)
                if (!_sameAddress) ...[
                  TextFormField(
                    controller: _presentAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Present Address',
                      hintText: 'Enter your present address',
                    ),
                    validator: (value) {
                      if (!_sameAddress && (value == null || value.isEmpty)) {
                        return 'Please enter your present address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // City
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    hintText: 'Enter your city',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your city';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // State
                TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    hintText: 'Enter your state',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your state';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Postal Code
                TextFormField(
                  controller: _postalCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Postal Code',
                    hintText: 'Enter your postal code',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your postal code';
                    }
                    if (value.length < 5) {
                      return 'Postal code should be at least 5 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Terms Checkbox
                CheckboxListTile(
                  title: RichText(
                    text: TextSpan(
                      text: 'I agree with ',
                      style: const TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'Terms of use',
                          style: TextStyle(color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ),
                  ),
                  value: _isAgreed,
                  onChanged: (value) {
                    setState(() {
                      _isAgreed = value!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                const SizedBox(height: 24),

                // Register Button
                ElevatedButton(
                  onPressed: isLoading ? null : _handleRegister,
                  child: isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF181F30),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Processing...')
                          ],
                        )
                      : const Text('Get Registered'),
                ),
                const SizedBox(height: 16),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const SignInScreen()),
                          (route) => false, // Clear navigation stack
                        );
                      },
                      child: const Text('Login'),
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

