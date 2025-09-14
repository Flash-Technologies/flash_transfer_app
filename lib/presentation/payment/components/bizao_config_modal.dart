// lib/presentation/payment/components/bizao_config_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flash_transfer_app/config/theme.dart';

class BizaoConfigData {
  final String firstName;
  final String lastName;
  final String email;
  final String country;
  final String countryCode;
  final String phoneNumber;
  final String language;
  final String serviceCode;
  final String apiPaymentMethod;

  BizaoConfigData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.country,
    required this.countryCode,
    required this.phoneNumber,
    required this.language,
    required this.serviceCode,
    required this.apiPaymentMethod,
  });
}

class BizaoConfigModal extends StatefulWidget {
  final Function(BizaoConfigData) onSubmit;
  final VoidCallback onCancel;
  final String? selectedProvider;

  const BizaoConfigModal({
    Key? key,
    required this.onSubmit,
    required this.onCancel,
    this.selectedProvider,
  }) : super(key: key);

  @override
  State<BizaoConfigModal> createState() => _BizaoConfigModalState();
}

class _BizaoConfigModalState extends State<BizaoConfigModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedLanguage;
  bool _isSubmitting = false;
  
  // Fixed country data for Ivory Coast
  final Map<String, String> _fixedCountry = {
    'name': 'Ivory Coast',
    'code': '+225',
    'countryCode': 'ci',
    'currency': 'XOF'
  };

  final List<String> _languages = [
    'English',
    'French',
  ];

  String _getServiceCode(String? provider) {
    switch (provider?.toLowerCase()) {
      case 'orange':
        return 'PAIEMENTMARCHANDOMPAYCIDIRECT';
      case 'wave':
        return 'CI_PAIEMENTWAVE_TP';
      case 'mtn':
        return 'PAIEMENTMARCHAND_MTN_CI';
      case 'moov':
        return 'PAIEMENTMARCHAND_MOOV_CI';
      default:
        return 'CI_PAIEMENTWAVE_TP';
    }
  }

  String _getProviderDisplayName(String? provider) {
    switch (provider?.toLowerCase()) {
      case 'orange':
        return 'Orange Money';
      case 'wave':
        return 'Wave';
      case 'mtn':
        return 'MTN';
      case 'moov':
        return 'Moov Money';
      default:
        return 'Mobile Money Provider';
    }
  }

  String _getApiPaymentMethod(String? provider) {
    switch (provider?.toLowerCase()) {
      case 'orange':
        return 'OM';
      case 'wave':
        return 'WAVE';
      case 'mtn':
        return 'MTN';
      case 'moov':
        return 'MOOV';
      default:
        return 'WAVE';
    }
  }

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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in this field.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Basic email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address.'),
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

    final configData = BizaoConfigData(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      country: _fixedCountry['name']!,
      countryCode: _fixedCountry['countryCode']!,
      phoneNumber: _phoneController.text,
      language: _selectedLanguage!,
      serviceCode: _getServiceCode(widget.selectedProvider),
      apiPaymentMethod: _getApiPaymentMethod(widget.selectedProvider),
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
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                      maxWidth: MediaQuery.of(context).size.width - 32,
                    ),
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
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFEBECED), width: 1),
                            ),
                          ),
                          child: Row(
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
                        ),

                        // Scrollable Content
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Selected Provider Display
                                if (widget.selectedProvider != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3F2FD),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF1976D2), width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          color: Color(0xFF1976D2),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Selected Provider: ${_getProviderDisplayName(widget.selectedProvider)}',
                                          style: const TextStyle(
                                            color: Color(0xFF1976D2),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // Customer Information Section
                                const Text(
                                  'Customer Information',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDarkColor,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // First Name Field
                                _buildTextField(
                                  label: 'First Name *',
                                  controller: _firstNameController,
                                  hintText: 'Enter your first name',
                                  keyboardType: TextInputType.text,
                                ),

                                const SizedBox(height: 16),

                                // Last Name Field
                                _buildTextField(
                                  label: 'Last Name *',
                                  controller: _lastNameController,
                                  hintText: 'Enter your last name',
                                  keyboardType: TextInputType.text,
                                ),

                                const SizedBox(height: 16),

                                // Email Field
                                _buildTextField(
                                  label: 'Email Address *',
                                  controller: _emailController,
                                  hintText: 'Enter your email address',
                                  keyboardType: TextInputType.emailAddress,
                                ),

                                const SizedBox(height: 16),

                                // Country Field (Fixed)
                                _buildFixedCountryField(),

                                const SizedBox(height: 16),

                                // Phone Number Field
                                _buildPhoneField(),

                                const SizedBox(height: 16),

                                // Language Dropdown
                                _buildImprovedDropdownField(
                                  label: 'Preferred Language *',
                                  value: _selectedLanguage,
                                  items: _languages,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedLanguage = value;
                                    });
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Service Code
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Service Code: ${_getServiceCode(widget.selectedProvider)}',
                                    style: const TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),

                        // Bottom Buttons
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xFFEBECED), width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: widget.onCancel,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.textGrayColor,
                                    side: const BorderSide(color: Color(0xFFEBECED)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.black87,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
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
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEBECED)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEBECED)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildFixedCountryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Country',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDarkColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEBECED)),
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFF8F9FA),
          ),
          child: Text(
            '${_fixedCountry['name']} (${_fixedCountry['code']}) - ${_fixedCountry['currency']}',
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textDarkColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'currently supports only Ivory Coast',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF9E9E9E),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mobile Number *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDarkColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEBECED)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFEBECED), width: 1),
                  ),
                ),
                child: Text(
                  _fixedCountry['code']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDarkColor,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    // CI mobile numbers are typically 8 digits
                  ],
                  decoration: const InputDecoration(
                    hintText: '07123456',
                    hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Enter CI mobile number ( e.g., 07123456)',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF9E9E9E),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildImprovedDropdownField({
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
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEBECED)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
            ),
            hint: Text(
              'Select language',
              style: const TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 16,
              ),
            ),
            icon: Container(
              margin: const EdgeInsets.only(right: 12),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF9E9E9E),
                size: 24,
              ),
            ),
            isExpanded: true,
            dropdownColor: Colors.white,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF181F30),
              fontWeight: FontWeight.w500,
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: value == item ? AppTheme.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: value == item ? FontWeight.w600 : FontWeight.w500,
                          color: value == item ? AppTheme.primaryColor : AppTheme.textDarkColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

}
