import 'package:flash_transfer_app/config/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:flash_transfer_app/config/theme.dart';
import 'package:flash_transfer_app/presentation/common/app_button.dart';
import 'package:flash_transfer_app/presentation/common/app_text_field.dart';
import 'package:flash_transfer_app/presentation/common/country_picker.dart';
import 'package:flash_transfer_app/core/models/country_model.dart';
import 'package:flash_transfer_app/core/services/auth_service.dart';
import 'package:flash_transfer_app/presentation/common/dropdown_field.dart';
import 'package:flash_transfer_app/core/api/api_client.dart';
import 'package:flash_transfer_app/core/api/endpoints.dart';
// import 'package:flash_transfer_app/presentation/common/notification_modal.dart';

class AddNewScreen extends StatefulWidget {
  const AddNewScreen({Key? key}) : super(key: key);

  @override
  State<AddNewScreen> createState() => _AddNewScreenState();
}

class _AddNewScreenState extends State<AddNewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  bool showNotifications = false;

  CountryModel? _selectedCountry;
  String? _purpose;
  String? _sourceOfFunds;
  bool _isNotificationModalVisible = false;

  late AuthService _authService;
  late Future<List<CountryModel>> _countriesFuture;

  final List<String> _purposeOptions = [
    'Family Support',
    'Education',
    'Business',
    'Travel',
    'Medical',
    'Savings',
  ];
  final List<String> _sourceOptions = [
    'Salary',
    'Business Income',
    'Savings',
    'Investment',
    'Gift',
  ];

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(baseUrl: Endpoints.baseUrl);
    _authService = AuthService(apiClient);

    // Convert from auth's CountryModel to our CountryModel
    _countriesFuture = _authService.fetchCountries().then((authCountries) {
      return authCountries
          .map(
            (country) => CountryModel(
              name: country.name,
              code: country.name.substring(0, 2).toLowerCase(),
              flagUrl: country.flag,
            ),
          )
          .toList();
    });

    // Add staggered animations when screen loads
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          InkWell(
                onTap: () => context.pop(),
                child: _buildIconButton(
            icon: Icons.menu,
            onTap: () => context.push('/profile'),
          ),
              )
              .animate()
              .fadeIn(duration: 300.ms, delay: 100.ms)
              .moveX(
                begin: -20,
                end: 0,
                duration: 300.ms,
                curve: Curves.easeOutQuad,
              ),

          // Notification bell
          InkWell(
                onTap: () {
                  setState(() {
                    _isNotificationModalVisible = true;
                  });
                },
                child: _buildIconButton(
            icon: Icons.notifications_none_rounded,
            onTap: () => setState(() => showNotifications = true),
          ),
              )
              .animate()
              .fadeIn(duration: 300.ms, delay: 150.ms)
              .moveX(
                begin: 20,
                end: 0,
                duration: 300.ms,
                curve: Curves.easeOutQuad,
              ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              InkWell(
                onTap: () => context.pop(),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/back2.png',
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: 200.ms)
        .moveY(begin: -10, end: 0, duration: 300.ms, curve: Curves.easeOutQuad);
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(),
          const SizedBox(height: 16),

          // Title
          Text('Add New Contact', style: AppTheme.headingStyle)
              .animate()
              .fadeIn(duration: 300.ms, delay: 250.ms)
              .moveY(begin: -10, end: 0),

          const SizedBox(height: 24),

          // First Name
          _buildFormField(
            label: 'First Name*',
            controller: _firstNameController,
            hint: 'Enter your first name',
            validator:
                (value) =>
                    value?.isEmpty ?? true ? 'First name is required' : null,
            delayMs: 300,
          ),

          // Last Name
          _buildFormField(
            label: 'Last Name*',
            controller: _lastNameController,
            hint: 'Enter your last name',
            validator:
                (value) =>
                    value?.isEmpty ?? true ? 'Last name is required' : null,
            delayMs: 350,
          ),

          // Email
          _buildFormField(
            label: 'Email Address',
            controller: _emailController,
            hint: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isNotEmpty ?? false) {
                // Simple email validation
                bool emailValid = RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value!);
                if (!emailValid) {
                  return 'Enter a valid email address';
                }
              }
              return null;
            },
            delayMs: 400,
          ),

          // Mobile
          _buildFormField(
            label: 'Mobile Money',
            controller: _mobileController,
            hint: 'Enter Mobile Money',
            keyboardType: TextInputType.phone,
            delayMs: 450,
          ),

          // Country/Region Picker
          _buildCountryPicker(delayMs: 500),

          // Address
          _buildFormField(
            label: 'Street Address*',
            controller: _addressController,
            hint: 'Enter your Street address',
            validator:
                (value) =>
                    value?.isEmpty ?? true ? 'Address is required' : null,
            delayMs: 550,
          ),

          // City
          _buildFormField(
            label: 'City*',
            controller: _cityController,
            hint: 'Enter your City',
            validator:
                (value) => value?.isEmpty ?? true ? 'City is required' : null,
            delayMs: 600,
          ),

          // State and ZIP
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  label: 'State*',
                  controller: _stateController,
                  hint: '',
                  validator:
                      (value) =>
                          value?.isEmpty ?? true ? 'State is required' : null,
                  delayMs: 650,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField(
                  label: 'ZIP*',
                  controller: _zipController,
                  hint: '',
                  keyboardType: TextInputType.number,
                  validator:
                      (value) =>
                          value?.isEmpty ?? true ? 'ZIP is required' : null,
                  delayMs: 700,
                ),
              ),
            ],
          ),

          // Purpose dropdown
          _buildDropdownField(
            label: 'Purpose',
            hint: 'Choose',
            value: _purpose,
            items: _purposeOptions,
            onChanged: (value) {
              setState(() {
                _purpose = value;
              });
            },
            delayMs: 750,
          ),

          // Source of funds dropdown
          _buildDropdownField(
            label: 'Source of funds',
            hint: 'Choose',
            value: _sourceOfFunds,
            items: _sourceOptions,
            onChanged: (value) {
              setState(() {
                _sourceOfFunds = value;
              });
            },
            delayMs: 800,
          ),

          const SizedBox(height: 32),

          // Continue button
          AppButton(
                text: 'Continue',
                backgroundColor: AppTheme.primaryColor,
                onPressed: _submitForm,
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 850.ms)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                duration: 300.ms,
              ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    required int delayMs,
  }) {
    return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.labelStyle),
              const SizedBox(height: 8),
              AppTextField(
                controller: controller,
                hintText: hint,
                keyboardType: keyboardType,
                validator: validator,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: delayMs))
        .moveY(begin: 20, end: 0, duration: 300.ms);
  }

  Widget _buildCountryPicker({required int delayMs}) {
    return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Country/Region', style: AppTheme.labelStyle),
              const SizedBox(height: 8),
              FutureBuilder<List<CountryModel>>(
                future: _countriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildCountryPickerSkeleton();
                  } else if (snapshot.hasError) {
                    return _buildCountryPickerError(snapshot.error.toString());
                  } else if (snapshot.hasData) {
                    return CountryPicker(
                      countries: snapshot.data!,
                      selectedCountry: _selectedCountry,
                      onSelect: (country) {
                        setState(() {
                          _selectedCountry = country;
                        });
                      },
                    );
                  } else {
                    return _buildCountryPickerError('No data available');
                  }
                },
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: delayMs))
        .moveY(begin: 20, end: 0, duration: 300.ms);
  }

  Widget _buildCountryPickerSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildCountryPickerError(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Failed to load countries: $error',
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required int delayMs,
  }) {
    return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.labelStyle),
              const SizedBox(height: 8),
              DropdownField(
                hint: hint,
                value: value,
                items: items,
                onChanged: onChanged,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: delayMs))
        .moveY(begin: 20, end: 0, duration: 300.ms);
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // Form is valid, handle submission
      // This would typically involve an API call, but as per requirements
      // we're focusing only on UI implementation

      // Show success animation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back
      Future.delayed(const Duration(seconds: 2), () {
        context.pop();
      });
    } else {
      // Show error shake animation for invalid form
      _formKey.currentState?.save();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check the form for errors'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
Widget _buildIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radiusCircular),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.paddingM),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 24),
        ),
      ),
    ).animate()
      .scale(
        duration: AppAnimations.quickAnimation,
        curve: AppAnimations.emphasizedCurve,
        begin: const Offset(0.95, 0.95),
        end: const Offset(1.0, 1.0),
      );
  }