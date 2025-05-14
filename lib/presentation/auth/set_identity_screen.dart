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
      _showAnimatedSnackBar('Please agree to the Terms of Use', false);
      return;
    }

    if (_dob == null) {
      _showAnimatedSnackBar('Please select your date of birth', false);
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
      presentAddress:
          _sameAddress
              ? _permanentAddressController.text
              : _presentAddressController.text,
      city: _cityController.text,
      state: _stateController.text,
      postalCode: _postalCodeController.text,
    );

    final success = await ref
        .read(authProvider.notifier)
        .register(registerRequest);

    setState(() {
      _isSubmitting = false;
    });

    if (mounted) {
      if (success) {
        _showRegistrationSuccessDialog();
      } else {
        final errorMessage =
            ref.read(authProvider).message ?? 'Registration failed';
        _showRegistrationErrorDialog(errorMessage);
      }
    }
  }

  void _showRegistrationSuccessDialog() {
    context.go(
      '/success',
      extra: {
        'message':
            'A verification link has been sent to your email. Please check your inbox and click on the link to activate your account.',
        'buttonText': 'Go to Login',
      },
    );
  }

  void _showRegistrationErrorDialog(String errorMessage) {
    _showAnimatedSnackBar(errorMessage, false);
  }

  void _showAnimatedSnackBar(String message, bool isSuccess) {
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set your Identity'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/sign-up'),
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
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF6E757D)),
              ),
              const SizedBox(height: 24),

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

              Text(
                'Gender',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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

              DateSelection(
                onDateChange: (date) {
                  setState(() {
                    _dob = date;
                  });
                },
              ),
              const SizedBox(height: 16),

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

              ElevatedButton(
                onPressed: isLoading ? null : _handleRegister,
                child:
                    isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Get Registered'),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: () {
                      context.go('/sign-in');
                    },
                    child: const Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
