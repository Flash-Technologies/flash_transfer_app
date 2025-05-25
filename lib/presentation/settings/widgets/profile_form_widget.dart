import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../../providers/profile_provider.dart';
import '../../../core/models/user.dart';
import '../../../core/models/country_model.dart';
import '../../common/enhanced_text_field.dart';
import '../../common/country_picker.dart';
import '../../common/date_picker_widget.dart';
import 'profile_avatar_widget.dart';

class ProfileFormWidget extends ConsumerStatefulWidget {
  final User? initialUser;
  final VoidCallback? onSaved;
  final bool isEditable;
  final bool showAvatar;
  final EdgeInsets? padding;

  const ProfileFormWidget({
    super.key,
    this.initialUser,
    this.onSaved,
    this.isEditable = true,
    this.showAvatar = true,
    this.padding,
  });

  @override
  ConsumerState<ProfileFormWidget> createState() => _ProfileFormWidgetState();
}

class _ProfileFormWidgetState extends ConsumerState<ProfileFormWidget>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Animation Controllers
  late AnimationController _formAnimationController;
  late Animation<double> _formFadeAnimation;

  // Form Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _permanentAddressController = TextEditingController();
  final _presentAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  // Focus Nodes
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _permanentAddressFocus = FocusNode();
  final _presentAddressFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _stateFocus = FocusNode();
  final _zipFocus = FocusNode();

  // State Variables
  String? _selectedCountry;
  DateTime? _selectedDate;
  bool _passwordVisible = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _populateForm();
    _setupChangeListeners();

    // Start animations
    _formAnimationController.forward();
  }

  void _initializeAnimations() {
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _formFadeAnimation = CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeInOut,
    );
  }

  void _populateForm() {
    if (widget.initialUser != null) {
      final user = widget.initialUser!;

      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _emailController.text = user.email;
      _permanentAddressController.text = user.permanentAddress ?? '';
      _presentAddressController.text = user.presentAddress ?? '';
      _cityController.text = user.city ?? '';
      _stateController.text = user.state ?? '';
      _zipController.text = user.postalCode ?? '';
      _selectedCountry = user.countryName;

      // Parse date of birth
      if (user.dob != null) {
        try {
          _selectedDate = DateTime.parse(user.dob!);
        } catch (e) {
          _selectedDate = null;
        }
      }
    }
  }

  void _setupChangeListeners() {
    final controllers = [
      _firstNameController,
      _lastNameController,
      _passwordController,
      _emailController,
      _permanentAddressController,
      _presentAddressController,
      _cityController,
      _stateController,
      _zipController,
    ];

    for (final controller in controllers) {
      controller.addListener(_onFormChanged);
    }
  }

  void _onFormChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _formAnimationController.dispose();

    // Dispose controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _permanentAddressController.dispose();
    _presentAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();

    // Dispose focus nodes
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _passwordFocus.dispose();
    _emailFocus.dispose();
    _permanentAddressFocus.dispose();
    _presentAddressFocus.dispose();
    _cityFocus.dispose();
    _stateFocus.dispose();
    _zipFocus.dispose();

    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!widget.isEditable) return;

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      _showValidationErrors();
      return;
    }

    HapticFeedback.lightImpact();

    final profileData = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'permanentAddress': _permanentAddressController.text.trim(),
      'presentAddress': _presentAddressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'postalCode': _zipController.text.trim(),
      'countryName': _selectedCountry,
      'dob': _selectedDate?.toIso8601String().split('T')[0],
    };

    // Add password if provided
    if (_passwordController.text.isNotEmpty) {
      profileData['password'] = _passwordController.text;
    }

    try {
      final success = await ref
          .read(profileProvider.notifier)
          .updateProfile(profileData);

      if (success && mounted) {
        setState(() {
          _hasUnsavedChanges = false;
        });

        HapticFeedback.mediumImpact();
        widget.onSaved?.call();

        _showSuccessMessage();
      }
    } catch (e) {
      _showErrorMessage(e.toString());
    }
  }

  void _showValidationErrors() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Please fix the errors above')),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Profile updated successfully!')),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: CountryPicker(
              countries: _getCountries(),
              selectedCountry:
                  _selectedCountry != null
                      ? CountryModel(
                        name: _selectedCountry!,
                        code: '',
                        flagUrl: '',
                      )
                      : null,
              onSelect: (country) {
                setState(() {
                  _selectedCountry = country.name;
                });
                _onFormChanged();
                Navigator.pop(context);
              },
            ),
          ),
    );
  }

  List<CountryModel> _getCountries() {
    return [
      CountryModel(name: 'United States', code: 'US', flagUrl: ''),
      CountryModel(name: 'United Kingdom', code: 'GB', flagUrl: ''),
      CountryModel(name: 'Canada', code: 'CA', flagUrl: ''),
      CountryModel(name: 'France', code: 'FR', flagUrl: ''),
      CountryModel(name: 'Germany', code: 'DE', flagUrl: ''),
      CountryModel(name: 'Australia', code: 'AU', flagUrl: ''),
      CountryModel(name: 'Japan', code: 'JP', flagUrl: ''),
      CountryModel(name: 'South Korea', code: 'KR', flagUrl: ''),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final fieldErrors = ref.watch(profileFieldErrorsProvider);

    return FadeTransition(
      opacity: _formFadeAnimation,
      child: Container(
        padding: widget.padding ?? const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Avatar (if enabled)
              if (widget.showAvatar) ...[
                Center(
                  child: ProfileAvatarWidget(
                    user: widget.initialUser,
                    isEditable: widget.isEditable,
                    size: 100,
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Name Fields
              Row(
                children: [
                  Expanded(
                    child: EnhancedTextField(
                      label: 'First Name',
                      controller: _firstNameController,
                      focusNode: _firstNameFocus,
                      hintText: 'Alex',
                      enabled: widget.isEditable,
                      required: true,
                      errorText: fieldErrors?['firstName'],
                      onChanged: (value) {
                        ref
                            .read(profileProvider.notifier)
                            .validateField('firstName', value);
                      },
                      onFieldSubmitted: (_) => _lastNameFocus.requestFocus(),
                      animationDelay: 100,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: EnhancedTextField(
                      label: 'Last Name',
                      controller: _lastNameController,
                      focusNode: _lastNameFocus,
                      hintText: 'Smith',
                      enabled: widget.isEditable,
                      required: true,
                      errorText: fieldErrors?['lastName'],
                      onChanged: (value) {
                        ref
                            .read(profileProvider.notifier)
                            .validateField('lastName', value);
                      },
                      onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                      animationDelay: 200,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Email Field
              EnhancedTextField(
                label: 'Email Address',
                controller: _emailController,
                focusNode: _emailFocus,
                hintText: 'alexsmith@gmail.com',
                keyboardType: TextInputType.emailAddress,
                enabled: widget.isEditable,
                required: true,
                errorText: fieldErrors?['email'],
                onChanged: (value) {
                  ref
                      .read(profileProvider.notifier)
                      .validateField('email', value);
                },
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                animationDelay: 300,
              ),

              const SizedBox(height: 20),

              // Password Field
              EnhancedTextField(
                label: 'Password',
                controller: _passwordController,
                focusNode: _passwordFocus,
                hintText: 'Leave empty to keep current password',
                obscureText: !_passwordVisible,
                enabled: widget.isEditable,
                errorText: fieldErrors?['password'],
                suffixIcon:
                    widget.isEditable
                        ? IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        )
                        : null,
                onChanged: (value) {
                  ref
                      .read(profileProvider.notifier)
                      .validateField('password', value);
                },
                onFieldSubmitted: (_) => _permanentAddressFocus.requestFocus(),
                animationDelay: 400,
              ),

              const SizedBox(height: 20),

              // Date of Birth
              DatePickerWidget(
                label: 'Date of Birth',
                initialDate: _selectedDate,
                hintText: 'Select Date of Birth',
                onDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                  _onFormChanged();
                },
              ).animate().slideX(
                begin: -1,
                delay: const Duration(milliseconds: 500),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
              ),

              const SizedBox(height: 20),

              // Address Fields
              EnhancedTextField(
                label: 'Permanent Address',
                controller: _permanentAddressController,
                focusNode: _permanentAddressFocus,
                hintText: 'San Jose, California, USA',
                enabled: widget.isEditable,
                onFieldSubmitted: (_) => _presentAddressFocus.requestFocus(),
                animationDelay: 600,
              ),

              const SizedBox(height: 20),

              EnhancedTextField(
                label: 'Present Address',
                controller: _presentAddressController,
                focusNode: _presentAddressFocus,
                hintText: 'San Jose, California, USA',
                enabled: widget.isEditable,
                onFieldSubmitted: (_) => _cityFocus.requestFocus(),
                animationDelay: 700,
              ),

              const SizedBox(height: 20),

              // Country Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Country/Region',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181F30),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: widget.isEditable ? _showCountryPicker : null,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            widget.isEditable
                                ? Colors.grey[50]
                                : Colors.grey[100],
                        border: Border.all(color: const Color(0xFFEBECED)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedCountry ?? 'Select Country',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    _selectedCountry != null
                                        ? const Color(0xFF181F30)
                                        : const Color(0xFF6E757D),
                              ),
                            ),
                          ),
                          if (widget.isEditable)
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate().slideX(
                begin: -1,
                delay: const Duration(milliseconds: 800),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
              ),

              const SizedBox(height: 20),

              // City, State, ZIP
              EnhancedTextField(
                label: 'City*',
                controller: _cityController,
                focusNode: _cityFocus,
                hintText: 'San Jose',
                enabled: widget.isEditable,
                required: true,
                errorText: fieldErrors?['city'],
                onChanged: (value) {
                  ref
                      .read(profileProvider.notifier)
                      .validateField('city', value);
                },
                onFieldSubmitted: (_) => _stateFocus.requestFocus(),
                animationDelay: 900,
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: EnhancedTextField(
                      label: 'State*',
                      controller: _stateController,
                      focusNode: _stateFocus,
                      hintText: 'CA',
                      enabled: widget.isEditable,
                      required: true,
                      errorText: fieldErrors?['state'],
                      onChanged: (value) {
                        ref
                            .read(profileProvider.notifier)
                            .validateField('state', value);
                      },
                      onFieldSubmitted: (_) => _zipFocus.requestFocus(),
                      animationDelay: 1000,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: EnhancedTextField(
                      label: 'ZIP*',
                      controller: _zipController,
                      focusNode: _zipFocus,
                      hintText: '24742',
                      keyboardType: TextInputType.number,
                      enabled: widget.isEditable,
                      required: true,
                      errorText: fieldErrors?['postalCode'],
                      onChanged: (value) {
                        ref
                            .read(profileProvider.notifier)
                            .validateField('postalCode', value);
                      },
                      onFieldSubmitted: (_) => _saveForm(),
                      animationDelay: 1100,
                    ),
                  ),
                ],
              ),

              // Save Button (if editable)
              if (widget.isEditable) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: profileState.isLoading ? null : _saveForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC000),
                      foregroundColor: const Color(0xFF181F30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child:
                        profileState.isLoading
                            ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF181F30),
                                ),
                              ),
                            )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Save Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ).animate().slideY(
                  begin: 1,
                  delay: const Duration(milliseconds: 1200),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                ),
              ],

              // Unsaved changes indicator
              if (_hasUnsavedChanges && widget.isEditable) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange.shade600, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You have unsaved changes',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().shake(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
