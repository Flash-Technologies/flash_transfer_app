import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/profile_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/models/user.dart';
import '../common/country_picker.dart';
import '../common/date_picker_widget.dart';
import 'dart:io';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _avatarAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _saveAnimationController;

  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _avatarScaleAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _saveButtonAnimation;

  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _permanentAddressController = TextEditingController();
  final _presentAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  // Focus nodes
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _permanentAddressFocus = FocusNode();
  final _presentAddressFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _stateFocus = FocusNode();
  final _zipFocus = FocusNode();

  // State variables
  String? _selectedCountry;
  DateTime? _selectedDate;
  bool _passwordVisible = false;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _populateUserData();
    _startAnimations();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _avatarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _saveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _avatarScaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _avatarAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _contentFadeAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeInOut,
    );

    _saveButtonAnimation = Tween<double>(begin: 1, end: 1.05).animate(
      CurvedAnimation(
        parent: _saveAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _populateUserData() {
    final userState = ref.read(userProvider);
    final user = userState.user;

    if (user != null) {
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _emailController.text = user.email ?? '';
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
          // Handle invalid date format
          _selectedDate = null;
        }
      }
    }
  }

  void _startAnimations() {
    _headerAnimationController.forward();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _avatarAnimationController.forward();
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _contentAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _avatarAnimationController.dispose();
    _contentAnimationController.dispose();
    _saveAnimationController.dispose();

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

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();

    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: Theme.of(context).primaryColor,
              ),
              title: Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final image = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = image;
                  });
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: Theme.of(context).primaryColor,
              ),
              title: Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = image;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker() {
    // Implementation would use the existing CountryPicker widget
    // For now, showing a simple selection
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Country',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  'United States',
                  'United Kingdom',
                  'Canada',
                  'France',
                  'Germany',
                  'Australia',
                  'Japan',
                  'South Korea',
                ]
                    .map(
                      (country) => ListTile(
                        title: Text(country),
                        onTap: () {
                          setState(() {
                            _selectedCountry = country;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now().subtract(Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(Duration(days: 365 * 13)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFFFFC000)),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.lightImpact();
    _saveAnimationController.forward().then((_) {
      _saveAnimationController.reverse();
    });

    final profileData = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      // Email is excluded as it cannot be changed
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
      final success =
          await ref.read(profileProvider.notifier).updateProfile(profileData);

      if (success && mounted) {
        HapticFeedback.mediumImpact();

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );

        // Clear password field after successful update
        _passwordController.clear();

        // Don't navigate back immediately - let user see the updated values
        // User can manually navigate back using the back button
      } else {
        // Handle failure case
        if (mounted) {
          final errorMessage =
              ref.read(profileProvider).error ?? 'Failed to update profile';
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(errorMessage),
                  ),
                ],
              ),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to update profile. Please try again.'),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final userState = ref.watch(userProvider);
    final user = userState.user;
    final theme = Theme.of(context);

    // Listen for user data changes and repopulate form
    ref.listen<UserState>(userProvider, (previous, next) {
      if (previous?.user != next.user && next.user != null) {
        // User data has changed, repopulate the form
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _populateUserData();
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFEFF0F1),
      body: Column(
        children: [
          // Header
          SlideTransition(
            position: _headerSlideAnimation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            size: 20,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(
                        delay: const Duration(milliseconds: 400),
                        duration: const Duration(milliseconds: 400),
                      ),

                  const SizedBox(width: 16),

                  // Title
                  Expanded(
                    child: Text(
                      'Edit Profile',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF181F30),
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(
                          delay: const Duration(milliseconds: 500),
                          duration: const Duration(milliseconds: 400),
                        ),
                  ),

                  const SizedBox(width: 40), // Balance the back button
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: FadeTransition(
              opacity: _contentFadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Profile Avatar
                      ScaleTransition(
                        scale: _avatarScaleAnimation,
                        child: _buildProfileAvatar(),
                      ),

                      const SizedBox(height: 32),

                      // Form Fields Container
                      Container(
                        padding: const EdgeInsets.all(24),
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
                        child: Column(
                          children: [
                            // Name Fields
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    label: 'First Name',
                                    controller: _firstNameController,
                                    focusNode: _firstNameFocus,
                                    hintText: 'Alex',
                                    validator: (value) => value?.isEmpty == true
                                        ? 'Required'
                                        : null,
                                    onFieldSubmitted: (_) =>
                                        _lastNameFocus.requestFocus(),
                                    animationDelay: 600,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(
                                    label: 'Last Name',
                                    controller: _lastNameController,
                                    focusNode: _lastNameFocus,
                                    hintText: 'Smith',
                                    validator: (value) => value?.isEmpty == true
                                        ? 'Required'
                                        : null,
                                    onFieldSubmitted: (_) =>
                                        _passwordFocus.requestFocus(),
                                    animationDelay: 700,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Password Field
                            _buildFormField(
                              label: 'Password',
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              hintText: 'Leave empty to keep current password',
                              isPassword: true,
                              onFieldSubmitted: (_) =>
                                  _emailFocus.requestFocus(),
                              animationDelay: 800,
                            ),

                            const SizedBox(height: 20),

                            // Email Field (Read-only)
                            _buildFormField(
                              label: 'Email Address (Cannot be changed)',
                              controller: _emailController,
                              focusNode: _emailFocus,
                              hintText: 'alexsmith@gmail.com',
                              keyboardType: TextInputType.emailAddress,
                              validator:
                                  null, // No validation needed for read-only field
                              onFieldSubmitted: (_) =>
                                  _permanentAddressFocus.requestFocus(),
                              animationDelay: 900,
                              isReadOnly: true,
                            ),

                            const SizedBox(height: 20),

                            // Date of Birth
                            _buildDateField(animationDelay: 1000),

                            const SizedBox(height: 20),

                            // Address Fields
                            _buildFormField(
                              label: 'Permanent Address',
                              controller: _permanentAddressController,
                              focusNode: _permanentAddressFocus,
                              hintText: 'San Jose, California, USA',
                              onFieldSubmitted: (_) =>
                                  _presentAddressFocus.requestFocus(),
                              animationDelay: 1100,
                            ),

                            const SizedBox(height: 20),

                            _buildFormField(
                              label: 'Present Address',
                              controller: _presentAddressController,
                              focusNode: _presentAddressFocus,
                              hintText: 'San Jose, California, USA',
                              onFieldSubmitted: (_) =>
                                  _cityFocus.requestFocus(),
                              animationDelay: 1200,
                            ),

                            const SizedBox(height: 20),

                            // Country Field
                            _buildCountryField(animationDelay: 1300),

                            const SizedBox(height: 20),

                            _buildFormField(
                              label: 'City*',
                              controller: _cityController,
                              focusNode: _cityFocus,
                              hintText: 'San Jose',
                              validator: (value) =>
                                  value?.isEmpty == true ? 'Required' : null,
                              onFieldSubmitted: (_) =>
                                  _stateFocus.requestFocus(),
                              animationDelay: 1400,
                            ),

                            const SizedBox(height: 20),

                            // State and ZIP
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    label: 'State*',
                                    controller: _stateController,
                                    focusNode: _stateFocus,
                                    hintText: 'CA',
                                    validator: (value) => value?.isEmpty == true
                                        ? 'Required'
                                        : null,
                                    onFieldSubmitted: (_) =>
                                        _zipFocus.requestFocus(),
                                    animationDelay: 1500,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(
                                    label: 'ZIP*',
                                    controller: _zipController,
                                    focusNode: _zipFocus,
                                    hintText: '24742',
                                    keyboardType: TextInputType.number,
                                    validator: (value) => value?.isEmpty == true
                                        ? 'Required'
                                        : null,
                                    onFieldSubmitted: (_) => _saveProfile(),
                                    animationDelay: 1600,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // Save Button
                            ScaleTransition(
                              scale: _saveButtonAnimation,
                              child: SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: profileState.isLoading
                                      ? null
                                      : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFC000),
                                    foregroundColor: const Color(0xFF181F30),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                    disabledBackgroundColor:
                                        Colors.grey.shade300,
                                  ),
                                  child: profileState.isLoading
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              const Color(0xFF181F30),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Save',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ).animate().slideY(
                                  begin: 1,
                                  delay: const Duration(milliseconds: 1700),
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOutBack,
                                ),
                          ],
                        ),
                      ).animate().scale(
                            delay: const Duration(milliseconds: 400),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutBack,
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final userState = ref.watch(userProvider);
    final user = userState.user;

    return Stack(
      children: [
        Container(
          width: 122,
          height: 122,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 59,
            backgroundColor: Colors.grey[200],
            backgroundImage: _selectedImage != null
                ? FileImage(File(_selectedImage!.path))
                : user?.profileImage != null
                    ? NetworkImage(user!.profileImage!)
                    : null,
            child: _selectedImage == null && user?.profileImage == null
                ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                : null,
          ),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC000),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt,
                size: 16,
                color: const Color(0xFF181F30),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required int animationDelay,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool isReadOnly = false,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF181F30),
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (hasFocus) {
            if (hasFocus) HapticFeedback.selectionClick();
          },
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            validator: validator,
            keyboardType: keyboardType,
            obscureText: isPassword && !_passwordVisible,
            onFieldSubmitted: onFieldSubmitted,
            readOnly: isReadOnly,
            style: TextStyle(
              fontSize: 14,
              color: isReadOnly
                  ? const Color(0xFF6E757D)
                  : const Color(0xFF181F30),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: const Color(0xFF6E757D),
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFEBECED)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFEBECED)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFFFFC000),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: isPassword
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
            ),
          ),
        ),
      ],
    ).animate().slideX(
          begin: -1,
          delay: Duration(milliseconds: animationDelay),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildDateField({required int animationDelay}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF181F30),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showDatePicker,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: const Color(0xFFEBECED)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Select Date of Birth',
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedDate != null
                          ? const Color(0xFF181F30)
                          : const Color(0xFF6E757D),
                    ),
                  ),
                ),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    ).animate().slideX(
          begin: -1,
          delay: Duration(milliseconds: animationDelay),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildCountryField({required int animationDelay}) {
    return Column(
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
          onTap: _showCountryPicker,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
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
                      color: _selectedCountry != null
                          ? const Color(0xFF181F30)
                          : const Color(0xFF6E757D),
                    ),
                  ),
                ),
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
          delay: Duration(milliseconds: animationDelay),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
        );
  }

  String? _validateEmail(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value!)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
}
