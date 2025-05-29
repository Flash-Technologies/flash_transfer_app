// lib/presentation/payment/components/bizao_config_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flash_transfer_app/config/theme.dart';
import 'package:flash_transfer_app/presentation/common/app_button.dart';

class BizaoConfigData {
  final String country;
  final String countryCode;
  final String phoneNumber;
  final String language;

  BizaoConfigData({
    required this.country,
    required this.countryCode,
    required this.phoneNumber,
    required this.language,
  });
}

class BizaoConfigModal extends StatefulWidget {
  final Function(BizaoConfigData) onSubmit;
  final VoidCallback onCancel;

  const BizaoConfigModal({
    Key? key,
    required this.onSubmit,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<BizaoConfigModal> createState() => _BizaoConfigModalState();
}

class _BizaoConfigModalState extends State<BizaoConfigModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final _phoneController = TextEditingController();
  String? _selectedCountry;
  String? _selectedLanguage;
  bool _isSubmitting = false;

  final List<Map<String, String>> _countries = [
    {'name': 'Ivory Coast', 'code': '+225', 'currency': 'XOF'},
    {'name': 'Burkina Faso', 'code': '+226', 'currency': 'XOF'},
    {'name': 'Senegal', 'code': '+221', 'currency': 'XOF'},
    {'name': 'Cameroon', 'code': '+237', 'currency': 'XAF'},
    {'name': 'Togo', 'code': '+228', 'currency': 'XOF'},
    {
      'name': 'Democratic Republic of the Congo',
      'code': '+243',
      'currency': 'CDF'
    },
  ];

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'Portuguese',
  ];

  final List<String> _availableOperators = ['Moov', 'Orange', 'Mtn', 'Wave'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_selectedCountry == null ||
        _phoneController.text.isEmpty ||
        _selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    final country = _countries.firstWhere((c) => c['name'] == _selectedCountry);

    final configData = BizaoConfigData(
      country: _selectedCountry!,
      countryCode: country['code']!,
      phoneNumber: _phoneController.text,
      language: _selectedLanguage!,
    );

    widget.onSubmit(configData);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Phone Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDarkColor,
                              ),
                            ),
                            IconButton(
                              onPressed: widget.onCancel,
                              icon: const Icon(Icons.close),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey.shade100,
                                shape: const CircleBorder(),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Country Dropdown
                        _buildDropdownField(
                          label: 'Country',
                          value: _selectedCountry,
                          items: _countries.map((c) => c['name']!).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCountry = value;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Phone Number Field
                        _buildPhoneField(),

                        const SizedBox(height: 16),

                        // Language Dropdown
                        _buildDropdownField(
                          label: 'Language',
                          value: _selectedLanguage,
                          items: _languages,
                          onChanged: (value) {
                            setState(() {
                              _selectedLanguage = value;
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        // Available Operators
                        _buildAvailableOperators(),

                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: 'Cancel',
                                onPressed: widget.onCancel,
                                backgroundColor: Colors.transparent,
                                textColor: AppTheme.textGrayColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppButton(
                                text:
                                    _isSubmitting ? 'Submitting...' : 'Submit',
                                onPressed: () => _handleSubmit(),
                                backgroundColor: AppTheme.primaryColor,
                                textColor: Colors.black87,
                                isDisabled: _isSubmitting,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDarkColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEBECED)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButton<String>(
            value: value,
            hint: Text('Select $label'.toLowerCase()),
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    final selectedCountry = _countries.firstWhere(
      (c) => c['name'] == _selectedCountry,
      orElse: () => {'code': '+225'},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDarkColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEBECED)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Text(
                selectedCountry['code']!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDarkColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 20,
                color: const Color(0xFFEBECED),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    hintText: '123456789',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableOperators() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Operators',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _availableOperators.join(', '),
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textGrayColor,
          ),
        ),
      ],
    );
  }
}
