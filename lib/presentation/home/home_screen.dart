import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/exchange_provider.dart';
import '../../core/models/currency.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangeForm = ref.watch(exchangeFormProvider);
    final currenciesAsync = ref.watch(currenciesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF0F1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildExchangeForm(context, ref, exchangeForm),
              if (exchangeForm.error != null)
                _buildErrorMessage(context, exchangeForm.error!),
              const SizedBox(height: 16),
              _buildContinueButton(context, ref),
              const SizedBox(height: 24),
              _buildExchangeInfo(context, exchangeForm),
              // const SizedBox(height: 24),
              // _buildMetaMaskDemoButton(context),
              const SizedBox(height: 24),
              _buildRecentTransactions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Menu button
        InkWell(
          onTap: () {
            // Navigate to profile
            context.push('/profile');
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset(
              'assets/image/menu-fries.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, _) => const Icon(Icons.menu),
            ),
          ),
        ),

        // App Title
        const Text(
          'Flash Transfer',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF181F30),
          ),
        ),

        // Notification button
        InkWell(
          onTap: () {
            // Show notifications
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset(
              'assets/image/icons/notification-bell.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, _) =>
                  const Icon(Icons.notifications),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExchangeForm(
    BuildContext context,
    WidgetRef ref,
    ExchangeFormState state,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCurrencySelector(
                        context,
                        ref,
                        state.fromCurrency,
                        (currency) => ref
                            .read(exchangeFormProvider.notifier)
                            .setFromCurrency(currency),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFEBECED)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Send',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF181F30),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 32,
                    height: 108,
                    child: TextField(
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize:
                            40, // Corrected from 3 to 40 for better visibility
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF181F30),
                      ),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          color: Color(0xFF6E757D),
                          fontSize: 40,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        if (value.isEmpty ||
                            RegExp(r'^\d*\.?\d{0,6}$').hasMatch(value)) {
                          ref
                              .read(exchangeFormProvider.notifier)
                              .setSendAmount(value);
                        }
                      },
                    ),
                  ),
                  const Text(
                    'Amount to Send',
                    style: TextStyle(fontSize: 14, color: Color(0xFF181F30)),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ), // This spacing will make room for the swap button
            // To Currency Box
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCurrencySelector(
                        context,
                        ref,
                        state.toCurrency,
                        (currency) => ref
                            .read(exchangeFormProvider.notifier)
                            .setToCurrency(currency),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFEBECED)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Receive',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF181F30),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 32,
                    height: MediaQuery.of(context).size.height * 0.08,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TextField(
                          textAlign: TextAlign.center,
                          readOnly: true,
                          controller: TextEditingController(
                            text: state.receiveAmount,
                          ),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF181F30),
                          ),
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              color: Color(0xFF6E757D),
                              fontSize: 40,
                            ),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (state.isLoading)
                          Positioned(
                            right: -24,
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Text(
                    'Amount Received',
                    style: TextStyle(fontSize: 14, color: Color(0xFF181F30)),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                ],
              ),
            ),
          ],
        ),

        // Swap Button (Positioned over the two currency boxes)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.21,
          child: InkWell(
            onTap: () {
              ref.read(exchangeFormProvider.notifier).swapCurrencies();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: const Color(0xFFEFF0F1), width: 6),
              ),
              child: Image.asset(
                'assets/image/icons/exchange-vertical.png',
                width: 40,
                height: 40,
                errorBuilder: (context, error, _) => const Icon(
                  Icons.swap_vert,
                  color: Colors.black,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencySelector(
    BuildContext context,
    WidgetRef ref,
    Currency? selectedCurrency,
    Function(Currency) onSelect,
  ) {
    return InkWell(
      onTap: () {
        _showCurrencyPicker(context, ref, selectedCurrency, onSelect);
      },
      child: Row(
        children: [
          if (selectedCurrency != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: selectedCurrency.logo != null
                    ? DecorationImage(
                        image: NetworkImage(selectedCurrency.logo!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color:
                    selectedCurrency.logo == null ? Colors.grey.shade200 : null,
              ),
              child: selectedCurrency.logo == null
                  ? Center(
                      child: Text(
                        selectedCurrency.code.substring(0, 1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              selectedCurrency.code,
              style: const TextStyle(fontSize: 20, color: Color(0xFF181F30)),
            ),
          ] else ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
              ),
              child: const Center(
                child: Icon(Icons.currency_exchange, size: 18),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Select',
              style: TextStyle(fontSize: 20, color: Color(0xFF181F30)),
            ),
          ],
          const SizedBox(width: 8),
          Image.asset(
            'assets/icons/arrow-short-down.png',
            width: 12,
            height: 6,
            errorBuilder: (context, error, _) => const Icon(
              Icons.keyboard_arrow_down,
              size: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(
    BuildContext context,
    WidgetRef ref,
    Currency? selectedCurrency,
    Function(Currency) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFEFF0F1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final currenciesAsync = ref.watch(currenciesProvider);
            final exchangeForm = ref.watch(exchangeFormProvider);
            String searchQuery = '';

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Choose Currency',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Text(
                          '✕',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select the currency you want to send or receive.',
                    style: TextStyle(color: Color(0xFF6E757D), fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search currency',
                      hintStyle: const TextStyle(color: Color(0xFF6E757D)),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: Theme.of(context).hintColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD3D8DD)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: currenciesAsync.when(
                      data: (currencies) {
                        // Filter currencies based on validation rules
                        List<Currency> availableCurrencies = currencies;

                        // Determine if this is for "from" or "to" currency selection
                        bool isFromCurrencySelection =
                            selectedCurrency == exchangeForm.fromCurrency;
                        bool isToCurrencySelection =
                            selectedCurrency == exchangeForm.toCurrency;

                        // If selecting "to" currency and "from" is already selected
                        if (!isFromCurrencySelection &&
                            exchangeForm.fromCurrency != null) {
                          if (exchangeForm.fromCurrency!.type == 'CRYPTO') {
                            // If sending crypto, only show fiat currencies for receiving
                            availableCurrencies = currencies
                                .where((currency) => currency.type == 'FIAT')
                                .toList();
                          } else if (exchangeForm.fromCurrency!.type ==
                              'FIAT') {
                            // If sending fiat, only show crypto currencies for receiving
                            availableCurrencies = currencies
                                .where((currency) => currency.type == 'CRYPTO')
                                .toList();
                          }
                        }
                        // If selecting "from" currency and "to" is already selected
                        else if (isFromCurrencySelection &&
                            exchangeForm.toCurrency != null) {
                          if (exchangeForm.toCurrency!.type == 'CRYPTO') {
                            // If receiving crypto, only show fiat currencies for sending
                            availableCurrencies = currencies
                                .where((currency) => currency.type == 'FIAT')
                                .toList();
                          } else if (exchangeForm.toCurrency!.type == 'FIAT') {
                            // If receiving fiat, only show crypto currencies for sending
                            availableCurrencies = currencies
                                .where((currency) => currency.type == 'CRYPTO')
                                .toList();
                          }
                        }

                        // Filter currencies based on search
                        final filteredCurrencies =
                            availableCurrencies.where((currency) {
                          if (searchQuery.isEmpty) return true;
                          return currency.code.toLowerCase().contains(
                                    searchQuery.toLowerCase(),
                                  ) ||
                              currency.name.toLowerCase().contains(
                                    searchQuery.toLowerCase(),
                                  ) ||
                              currency.type.toLowerCase().contains(
                                    searchQuery.toLowerCase(),
                                  );
                        }).toList();

                        return ListView.builder(
                          itemCount: filteredCurrencies.length,
                          itemBuilder: (context, index) {
                            final currency = filteredCurrencies[index];
                            return ListTile(
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: currency.logo != null
                                      ? DecorationImage(
                                          image: NetworkImage(currency.logo!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  color: currency.logo == null
                                      ? Colors.grey.shade200
                                      : null,
                                ),
                                child: currency.logo == null
                                    ? Center(
                                        child: Text(
                                          currency.code.substring(0, 1),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                currency.code,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF181F30),
                                ),
                              ),
                              subtitle: Text(
                                currency.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6E757D),
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: currency.type == 'CRYPTO'
                                      ? const Color(0xFFE3F2FD)
                                      : const Color(0xFFF4F5F7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  currency.type,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: currency.type == 'CRYPTO'
                                        ? const Color(0xFF1976D2)
                                        : const Color(0xFF6E757D),
                                  ),
                                ),
                              ),
                              onTap: () {
                                onSelect(currency);
                                Navigator.pop(context);
                              },
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Text(
                          'Error loading currencies: $error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorMessage(BuildContext context, String error) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Text(
        error,
        style: TextStyle(color: Colors.red.shade800, fontSize: 14),
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context, WidgetRef ref) {
    final exchangeForm = ref.watch(exchangeFormProvider);

    // Check if the form is ready for continuation
    bool isFormReady = exchangeForm.fromCurrency != null &&
        exchangeForm.toCurrency != null &&
        exchangeForm.sendAmount.isNotEmpty &&
        exchangeForm.calculation != null &&
        !exchangeForm.isLoading &&
        exchangeForm.error == null;

    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isFormReady ? () => context.push('/cash') : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isFormReady ? const Color(0xFFFFC000) : Colors.grey.shade300,
          foregroundColor:
              isFormReady ? const Color(0xFF181F30) : Colors.grey.shade500,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          isFormReady ? 'Continue' : 'Please complete exchange details',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isFormReady ? const Color(0xFF181F30) : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _buildExchangeInfo(BuildContext context, ExchangeFormState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD3D8DD)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Exchange Rate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Exchange Rate',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6A6A6A),
                  fontWeight: FontWeight.normal,
                ),
              ),
              Text(
                state.exchangeRate != null
                    ? '1 ${state.fromCurrency?.code ?? ''} = ${state.exchangeRate?.rate.toStringAsFixed(2)} ${state.toCurrency?.code ?? ''}'
                    : '—',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Fee
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fee',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6A6A6A),
                  fontWeight: FontWeight.normal,
                ),
              ),
              Text(
                state.calculation != null
                    ? '+${state.calculation?.fee} ${state.calculation?.feeCurrency}'
                    : '—',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Transfer Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transfer Time',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6A6A6A),
                  fontWeight: FontWeight.normal,
                ),
              ),
              Text(
                state.exchangeRate != null
                    ? '${state.exchangeRate?.transferTime.time} ${state.exchangeRate?.transferTime.unit}'
                    : '—',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Divider(color: Color(0xFFD3D8DD), height: 1),
          const SizedBox(height: 16),

          // Total to Pay
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total to Pay',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6A6A6A),
                  fontWeight: FontWeight.normal,
                ),
              ),
              Text(
                state.sendAmount.isNotEmpty && state.calculation != null
                    ? '${state.calculation?.amount} ${state.fromCurrency?.code ?? ''}'
                    : '—',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Recipient Gets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recipient Gets',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6A6A6A),
                  fontWeight: FontWeight.normal,
                ),
              ),
              Text(
                state.calculation != null
                    ? '${state.calculation?.receivedAmount} ${state.toCurrency?.code ?? ''}'
                    : '—',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaMaskDemoButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () => context.push('/metamask'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE2761B), // MetaMask orange
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/wallets/metamask.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Connect with MetaMask',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    // For now, using dummy transactions
    final dummyTransactions = [
      {
        'name': 'Jane Cooper',
        'date': '24 May, 2024',
        'action': 'Send',
        'amount': '\$396.84',
        'avatar': 'assets/image/users/homeUser4.png',
      },
      {
        'name': 'Marvin McKinney',
        'date': '24 May, 2024',
        'action': 'Receive',
        'amount': '\$396.84',
        'avatar': 'assets/image/users/homeUser1.png',
      },
      {
        'name': 'Esther Howard',
        'date': '24 May, 2024',
        'action': 'Receive',
        'amount': '\$396.84',
        'avatar': 'assets/image/users/homeUser2.png',
      },
      {
        'name': 'Ralph Edwards',
        'date': '24 May, 2024',
        'action': 'Send',
        'amount': '\$396.84',
        'avatar': 'assets/image/users/homeUser3.png',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF273240),
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to see all transactions
                context.push('/transaction');
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF2475FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Transaction list
        ...dummyTransactions
            .map(
              (transaction) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildTransactionItem(
                  transaction['name']!,
                  transaction['date']!,
                  transaction['action']!,
                  transaction['amount']!,
                  transaction['action'] == 'Send',
                  transaction['avatar']!,
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildTransactionItem(
    String name,
    String date,
    String action,
    String amount,
    bool isSend,
    String avatarPath,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  avatarPath,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, _) => CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    radius: 20,
                    child: Text(
                      name.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF181F30),
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6E757D),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                action,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSend
                      ? const Color(0xFFFF3E24)
                      : const Color(0xFF00C735),
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF181F30),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
