import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/exchange_provider.dart';
import '../../core/models/currency.dart';
import 'widgets/recent_transactions_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangeForm = ref.watch(exchangeFormProvider);
    final currenciesAsync = ref.watch(currenciesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currenciesProvider);
            await Future.delayed(const Duration(seconds: 1));
          },
          color: const Color(0xFFFFC000),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.04,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.2, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 24),
                _buildExchangeForm(context, ref, exchangeForm)
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 200.ms)
                    .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1, 1)),
                if (exchangeForm.error != null)
                  _buildErrorMessage(context, exchangeForm.error!)
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .shake(duration: 500.ms, hz: 3),
                const SizedBox(height: 16),
                _buildContinueButton(context, ref)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 400.ms)
                    .slideY(begin: 0.2, end: 0),
                const SizedBox(height: 24),
                _buildExchangeInfo(context, exchangeForm)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 600.ms)
                    .slideX(begin: -0.1, end: 0),
                const SizedBox(height: 32),
                _buildRecentTransactions(context)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 800.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Menu button with enhanced styling
        Hero(
          tag: 'menu-button',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/profile');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/image/menu-fries.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, _) => const Icon(
                    Icons.menu_rounded,
                    size: 24,
                    color: Color(0xFF181F30),
                  ),
                ),
              ),
            ),
          ),
        ),

        // App Title with gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF181F30), Color(0xFF2475FF)],
          ).createShader(bounds),
          child: const Text(
            'Flash Transfer',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Notification button with badge
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              // Show notifications
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Image.asset(
                    'assets/image/icons/notification-bell.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, _) => const Icon(
                      Icons.notifications_rounded,
                      size: 24,
                      color: Color(0xFF181F30),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3E24),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.2, 1.2),
                            duration: 1.seconds)
                        .then()
                        .scale(
                            begin: const Offset(1.2, 1.2),
                            end: const Offset(1, 1),
                            duration: 1.seconds),
                  ),
                ],
              ),
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
            // From Currency Box
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2475FF).withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
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
                          isFromCurrency: true),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Send',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1976D2),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(
                              duration: 3.seconds,
                              color: Colors.white.withOpacity(0.3)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Amount input with better handling
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 80,
                    height: 80,
                    child: TextField(
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF181F30),
                        letterSpacing: 1,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          color: const Color(0xFF6E757D).withOpacity(0.5),
                          fontSize: 36,
                          fontWeight: FontWeight.w300,
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
                  Text(
                    'Amount to Send',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF181F30).withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // To Currency Box
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC000).withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
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
                          isFromCurrency: false),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Receive',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFF57C00),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(
                              duration: 3.seconds,
                              color: Colors.white.withOpacity(0.3)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Receive amount with scrollable text for overflow
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            state.receiveAmount.isEmpty
                                ? '0.00'
                                : state.receiveAmount,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF181F30),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        if (state.isLoading)
                          Positioned(
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    'Amount Received',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF181F30).withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),

        // Enhanced Swap Button
        Positioned(
          top: MediaQuery.of(context).size.height * 0.25,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              ref.read(exchangeFormProvider.notifier).swapCurrencies();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: const Color(0xFFEFF0F1), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2475FF).withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/image/icons/exchange-vertical.png',
                width: 32,
                height: 32,
                errorBuilder: (context, error, _) => const Icon(
                  Icons.swap_vert_rounded,
                  color: Color(0xFF2475FF),
                  size: 32,
                ),
              ),
            ),
          )
              .animate()
              .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: 300.ms,
                  curve: Curves.elasticOut)
              .rotate(
                  begin: 0,
                  end: 0.5,
                  duration: 300.ms,
                  curve: Curves.easeInOut),
        ),
      ],
    );
  }

  Widget _buildCurrencySelector(BuildContext context, WidgetRef ref,
      Currency? selectedCurrency, Function(Currency) onSelect,
      {bool isFromCurrency = true}) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _showCurrencyPicker(context, ref, selectedCurrency, onSelect,
            isFromCurrency: isFromCurrency);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (selectedCurrency != null) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  image: selectedCurrency.logo != null
                      ? DecorationImage(
                          image: NetworkImage(selectedCurrency.logo!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: selectedCurrency.logo == null
                      ? Colors.grey.shade200
                      : null,
                ),
                child: selectedCurrency.logo == null
                    ? Center(
                        child: Text(
                          selectedCurrency.code.substring(0, 1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                selectedCurrency.code,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF181F30),
                ),
              ),
            ] else ...[
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 60,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: Colors.black54,
            )
                .animate(onPlay: (controller) => controller.repeat())
                .moveY(begin: 0, end: 3, duration: 1.seconds)
                .then()
                .moveY(begin: 3, end: 0, duration: 1.seconds),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref,
      Currency? selectedCurrency, Function(Currency) onSelect,
      {bool isFromCurrency = true}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              final currenciesAsync = ref.watch(currenciesProvider);
              final exchangeForm = ref.watch(exchangeFormProvider);
              String searchQuery = '';

              return Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
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
                                fontSize: 20,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Select the currency you want to send or receive.',
                          style:
                              TextStyle(color: Color(0xFF6E757D), fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        // Enhanced search field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search currency',
                              hintStyle:
                                  const TextStyle(color: Color(0xFF6E757D)),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 22,
                                color: Color(0xFF6E757D),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: currenciesAsync.when(
                      data: (currencies) {
                        // Apply fiat/crypto validation
                        List<Currency> availableCurrencies = currencies;

                        if (!isFromCurrency) {
                          // If selecting "to" currency, filter based on "from" currency type
                          if (exchangeForm.fromCurrency != null) {
                            final fromCurrencyType =
                                exchangeForm.fromCurrency!.type.toLowerCase();
                            availableCurrencies = currencies.where((currency) {
                              final currencyType = currency.type.toLowerCase();
                              // If from is fiat, to must be crypto and vice versa
                              if (fromCurrencyType == 'fiat') {
                                return currencyType == 'crypto';
                              } else if (fromCurrencyType == 'crypto') {
                                return currencyType == 'fiat';
                              }
                              return true;
                            }).toList();
                          }
                        } else {
                          // If selecting "from" currency, filter based on "to" currency type
                          if (exchangeForm.toCurrency != null) {
                            final toCurrencyType =
                                exchangeForm.toCurrency!.type.toLowerCase();
                            availableCurrencies = currencies.where((currency) {
                              final currencyType = currency.type.toLowerCase();
                              // If to is fiat, from must be crypto and vice versa
                              if (toCurrencyType == 'fiat') {
                                return currencyType == 'crypto';
                              } else if (toCurrencyType == 'crypto') {
                                return currencyType == 'fiat';
                              }
                              return true;
                            }).toList();
                          }
                        }

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
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredCurrencies.length,
                          itemBuilder: (context, index) {
                            final currency = filteredCurrencies[index];
                            final isSelected =
                                selectedCurrency?.code == currency.code;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFFF3E0)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFFC000)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
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
                                              fontSize: 20,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  currency.code,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? const Color(0xFFF57C00)
                                        : const Color(0xFF181F30),
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
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        currency.type.toLowerCase() == 'crypto'
                                            ? const Color(0xFFE3F2FD)
                                            : const Color(0xFFF3E5F5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    currency.type,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: currency.type.toLowerCase() ==
                                              'crypto'
                                          ? const Color(0xFF1976D2)
                                          : const Color(0xFF7B1FA2),
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  onSelect(currency);
                                  Navigator.pop(context);
                                },
                              ),
                            )
                                .animate()
                                .fadeIn(
                                    duration: 300.ms,
                                    delay: Duration(milliseconds: index * 50))
                                .slideX(begin: 0.1, end: 0);
                          },
                        );
                      },
                      loading: () => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFFFFC000),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading currencies...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      error: (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading currencies',
                              style: TextStyle(
                                color: Colors.red[300],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: const TextStyle(
                                color: Color(0xFF6E757D),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorMessage(BuildContext context, String error) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: Colors.red.shade800,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context, WidgetRef ref) {
    final exchangeForm = ref.watch(exchangeFormProvider);

    // Check if continue button should be enabled
    final bool isEnabled = exchangeForm.fromCurrency != null &&
        exchangeForm.toCurrency != null &&
        exchangeForm.sendAmount.isNotEmpty &&
        exchangeForm.exchangeRate != null &&
        exchangeForm.calculation != null &&
        !exchangeForm.isLoading &&
        exchangeForm.error == null;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: const Color(0xFFFFC000).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: isEnabled
            ? () {
                HapticFeedback.mediumImpact();
                context.push('/cash');
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isEnabled ? const Color(0xFFFFC000) : Colors.grey.shade300,
          foregroundColor:
              isEnabled ? const Color(0xFF181F30) : Colors.grey.shade600,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isEnabled ? 'Continue' : 'Please complete exchange details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color:
                    isEnabled ? const Color(0xFF181F30) : Colors.grey.shade600,
              ),
            ),
            if (isEnabled) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeInfo(BuildContext context, ExchangeFormState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFF8F9FA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.currency_exchange_rounded,
            label: 'Exchange Rate',
            value: state.exchangeRate != null
                ? '1 ${state.fromCurrency?.code ?? ''} = ${state.exchangeRate?.rate.toStringAsFixed(2)} ${state.toCurrency?.code ?? ''}'
                : '—',
            isLoading: state.isLoading,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.attach_money_rounded,
            label: 'Fee',
            value: state.calculation != null
                ? '+${state.calculation?.fee} ${state.calculation?.feeCurrency}'
                : '—',
            isLoading: state.isLoading,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.access_time_rounded,
            label: 'Transfer Time',
            value: state.exchangeRate != null
                ? '${state.exchangeRate?.transferTime.time} ${state.exchangeRate?.transferTime.unit}'
                : '—',
            isLoading: state.isLoading,
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.shade300,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            icon: Icons.payment_rounded,
            label: 'Total to Pay',
            value: state.sendAmount.isNotEmpty && state.calculation != null
                ? '${state.calculation?.amount} ${state.fromCurrency?.code ?? ''}'
                : '—',
            isLoading: state.isLoading,
            isHighlighted: true,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Recipient Gets',
            value: state.calculation != null
                ? '${state.calculation?.receivedAmount} ${state.toCurrency?.code ?? ''}'
                : '—',
            isLoading: state.isLoading,
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isLoading,
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? const Color(0xFFFFC000).withOpacity(0.15)
                    : const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isHighlighted
                    ? const Color(0xFFF57C00)
                    : const Color(0xFF1976D2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: const Color(0xFF6A6A6A),
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        if (isLoading)
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 80,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )
        else
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isHighlighted ? 16 : 14,
                  color: Colors.black,
                  fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                ),
                maxLines: 1,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    return const RecentTransactionsWidget();
  }
}
