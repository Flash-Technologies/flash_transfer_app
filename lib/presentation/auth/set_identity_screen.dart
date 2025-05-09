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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms of Use')),
      );
      return;
    }

    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }

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

    if (success) {
      _showRegistrationSuccessDialog();
    } else {
      if (mounted) {
        final errorMessage =
            ref.read(authProvider).message ?? 'Registration failed';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  void _showRegistrationSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Registration Successful'),
            content: const Text(
              'A verification link has been sent to your email address. Please check your inbox and verify your account.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/verification', extra: {'email': widget.email});
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
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
