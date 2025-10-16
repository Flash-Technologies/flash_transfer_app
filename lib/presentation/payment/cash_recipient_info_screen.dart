import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';
import 'package:flash_transfer_app/providers/exchange_provider.dart';
import '../../providers/language_provider.dart';

class CashRecipientInfoScreen extends ConsumerStatefulWidget {
  const CashRecipientInfoScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CashRecipientInfoScreen> createState() => _CashRecipientInfoScreenState();
}

class _CashRecipientInfoScreenState extends ConsumerState<CashRecipientInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String? _selectedCountry;
  
  final List<Map<String, String>> _countries = [
    {'code': 'CI', 'name': 'Ivory Coast', 'flag': '🇨🇮'},
    {'code': 'SN', 'name': 'Senegal', 'flag': '🇸🇳'},
    {'code': 'ML', 'name': 'Mali', 'flag': '🇲🇱'},
    {'code': 'BJ', 'name': 'Benin', 'flag': '🇧🇯'},
    {'code': 'BF', 'name': 'Burkina Faso', 'flag': '🇧🇫'},
    {'code': 'TG', 'name': 'Togo', 'flag': '🇹🇬'},
    {'code': 'NE', 'name': 'Niger', 'flag': '🇳🇪'},
    {'code': 'GW', 'name': 'Guinea-Bissau', 'flag': '🇬🇼'},
  ];
  
  @override
  void initState() {
    super.initState();
    // Pre-select Ivory Coast as default
    _selectedCountry = 'CI';
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _handleContinue() async {
    if (_formKey.currentState!.validate()) {
      // Store recipient information in provider
      ref.read(paymentProvider.notifier).setCashRecipientInfo({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'phoneNumber': _phoneController.text,
        'cashPickupCountry': _selectedCountry,
      });

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Get data from providers
        final paymentState = ref.read(paymentProvider);
        final exchangeForm = ref.read(exchangeFormProvider);
        final cashSenderInfo = paymentState.cashSenderInfo;

        // Prepare sender info
        final senderInfo = {
          'sender_phone_number': cashSenderInfo?['phoneNumber'] ?? '',
          'sender_first_name': cashSenderInfo?['firstName'] ?? '',
          'sender_last_name': cashSenderInfo?['lastName'] ?? '',
          'sender_country_code_piece': cashSenderInfo?['countryCode'] ?? 'CI',
        };

        // Prepare recipient info
        final recipientInfo = {
          'recipient_first_name': _firstNameController.text,
          'recipient_last_name': _lastNameController.text,
          'recipient_phone_number': _phoneController.text,
          'recipient_country_code': _selectedCountry ?? 'SN',
        };

        // Fetch the estimate
        await ref.read(paymentProvider.notifier).fetchCryptoToCashEstimate(
          amount: double.parse(exchangeForm.sendAmount),
          sourceCurrency: exchangeForm.fromCurrency?.code ?? 'ETH',
          destinationCurrency: exchangeForm.toCurrency?.code ?? 'XOF',
          blockchainNetwork: paymentState.selectedNetwork ?? 'ethereum',
          countryCode: _selectedCountry ?? 'SN',
          senderInfo: senderInfo,
          recipientInfo: recipientInfo,
        );

        // Close loading
        if (mounted) Navigator.of(context).pop();

        // Navigate to review details screen for crypto to cash
        if (mounted) context.push('/review-details/cash');

      } catch (e) {
        // Close loading
        if (mounted) Navigator.of(context).pop();

        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationHelperProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
            child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 24),
                      _buildBeneficiarySection(tr),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomButtons(tr),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.watch(translationHelperProvider)('payment.recipientInfo.headerTitle'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF181F30),
                  ),
                ),
                Text(
                  ref.watch(translationHelperProvider)('payment.recipientInfo.headerSubtitle'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6E757D),
                  ),
                ),
              ],
            ),
          ),
          // Progress indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: 0.75, // 3/4 steps
                  strokeWidth: 3,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2475FF)),
                ),
              ),
              Text(
                ref.watch(translationHelperProvider)('payment.recipientInfo.progress'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2475FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ref.watch(translationHelperProvider)('payment.recipientInfo.title'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF181F30),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ref.watch(translationHelperProvider)('payment.recipientInfo.subtitle'),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildBeneficiarySection(String Function(String) tr) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('payment.recipientInfo.beneficiaryDetails'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF181F30),
            ),
          ),
          const SizedBox(height: 16),
          
          // First Name and Last Name
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: tr('auth.setIdentity.firstName') + '*',
                    hintText: tr('auth.setIdentity.firstNameHint'),
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2475FF), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr('auth.setIdentity.firstNameRequired');
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: tr('auth.setIdentity.lastName') + '*',
                    hintText: tr('auth.setIdentity.lastNameHint'),
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2475FF), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr('auth.setIdentity.lastNameRequired');
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Phone Number
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: tr('payment.recipientInfo.phoneLabel'),
              hintText: tr('payment.recipientInfo.phoneHint'),
              filled: true,
              fillColor: const Color(0xFFF0F2F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2475FF), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return tr('payment.common.phoneNumberRequired');
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Cash Pickup Country
          DropdownButtonFormField<String>(
            value: _selectedCountry,
            decoration: InputDecoration(
              labelText: tr('payment.recipientInfo.cashPickupCountry'),
              filled: true,
              fillColor: const Color(0xFFF0F2F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2475FF), width: 2),
              ),
            ),
            items: _countries.map((country) {
              return DropdownMenuItem(
                value: country['code'],
                child: Row(
                  children: [
                    Text(
                      country['flag']!,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(country['name']!),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCountry = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return tr('payment.common.selectCountry');
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomButtons(String Function(String) tr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: Color(0xFF6E757D)),
              ),
              child: Text(
                tr('payment.common.back'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6E757D),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _handleContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC000),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                tr('payment.common.continue'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF181F30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}