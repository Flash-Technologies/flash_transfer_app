import 'package:flash_transfer_app/presentation/auth/sign_in_screen.dart';
import 'package:flash_transfer_app/presentation/auth/success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/language_provider.dart';
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

  void _handleRegister(String Function(String) tr) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isAgreed) {
      _showSnackBar(tr('auth.setIdentity.agreeToTermsRequired'));
      return;
    }

    if (_dob == null) {
      _showSnackBar(tr('auth.setIdentity.selectDateOfBirth'));
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

    try {
      final success = await ref
          .read(authProvider.notifier)
          .register(registerRequest);

      // Make sure we're still mounted before updating UI
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        // Navigate to success screen with email parameter
        context.go('/registration-success', extra: {'email': widget.email});
      } else {
        final authState = ref.read(authProvider);
        String errorMessage = authState.message ?? tr('auth.setIdentity.registrationFailed');

        if (authState.fieldErrors != null &&
            authState.fieldErrors!.isNotEmpty) {
          final fieldErrorsList = authState.fieldErrors!.entries
              .map((e) => "${e.key}: ${e.value}")
              .join("\n• ");

          errorMessage = "${tr('auth.setIdentity.validationErrors')}\n• $fieldErrorsList";
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
          child: Text(message, style: const TextStyle(fontSize: 14)),
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
    final tr = ref.watch(translationHelperProvider);
    final isLoading = _isSubmitting;

    return WillPopScope(
      onWillPop: () async => !isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('auth.setIdentity.title')),
          leading:
              isLoading
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
                  tr('auth.setIdentity.subtitle'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF6E757D),
                  ),
                ),
                const SizedBox(height: 24),

                // First Name
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: tr('auth.setIdentity.firstName'),
                    hintText: tr('auth.setIdentity.firstNameHint'),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr('auth.setIdentity.firstNameRequired');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Last Name
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: tr('auth.setIdentity.lastName'),
                    hintText: tr('auth.setIdentity.lastNameHint'),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr('auth.setIdentity.lastNameRequired');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Gender
                Text(
                  tr('auth.setIdentity.gender'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text(tr('auth.setIdentity.male')),
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
                        title: Text(tr('auth.setIdentity.female')),
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
                  decoration: InputDecoration(
                    labelText: tr('auth.setIdentity.permanentAddress'),
                    hintText: tr('auth.setIdentity.permanentAddress'),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr('auth.setIdentity.permanentAddress');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Present Address Same Checkbox
                CheckboxListTile(
                  title: Text(tr('auth.setIdentity.sameAddress')),
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
                    decoration: InputDecoration(
                      labelText: tr('auth.setIdentity.presentAddress'),
                      hintText: tr('auth.setIdentity.presentAddress'),
                    ),
                    validator: (value) {
                      if (!_sameAddress && (value == null || value.isEmpty)) {
                        return tr('auth.setIdentity.presentAddress');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // City
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: tr('auth.setIdentity.city'),
                    hintText: tr('auth.setIdentity.city'),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr('auth.setIdentity.city');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // State
                TextFormField(
                  controller: _stateController,
                  decoration: InputDecoration(
                    labelText: tr('auth.setIdentity.state'),
                    hintText: tr('auth.setIdentity.state'),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr('auth.setIdentity.state');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Postal Code
                TextFormField(
                  controller: _postalCodeController,
                  decoration: InputDecoration(
                    labelText: tr('auth.setIdentity.postalCode'),
                    hintText: tr('auth.setIdentity.postalCode'),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr('auth.setIdentity.postalCode');
                    }
                    if (value.length < 5) {
                      return tr('auth.setIdentity.postalCode');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Terms Checkbox
                CheckboxListTile(
                  title: RichText(
                    text: TextSpan(
                      text: tr('auth.setIdentity.agreeToTerms').split(' ').first + ' ',
                      style: const TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: tr('auth.setIdentity.agreeToTerms').replaceFirst(
                            tr('auth.setIdentity.agreeToTerms').split(' ').first + ' ',
                            '',
                          ),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
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
                  onPressed: isLoading ? null : () => _handleRegister(tr),
                  child:
                      isLoading
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
                              Text('Processing...'),
                            ],
                          )
                          : Text(tr('auth.setIdentity.submit')),
                ),
                const SizedBox(height: 16),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(tr('auth.signUp.alreadyHaveAccount')),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignInScreen(),
                          ),
                          (route) => false, // Clear navigation stack
                        );
                      },
                      child: Text(tr('auth.signUp.signIn')),
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
