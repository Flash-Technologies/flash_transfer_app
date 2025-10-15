import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/exchange_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/language_provider.dart';
import '../../core/models/currency.dart';
import '../../core/utils/currency_icon_mapper.dart';
import 'widgets/recent_transactions_widget.dart';
import '../common/notification_modal.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late TextEditingController _amountController;
  late FocusNode _amountFocusNode;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _amountFocusNode = FocusNode();

    // Keep the controller in sync with provider state without mutating during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.listen(exchangeFormProvider, (previous, next) {
        final nextText = next.sendAmount == '0' ? '' : next.sendAmount;
        if (_amountController.text != nextText) {
          _amountController.value = TextEditingValue(
            text: nextText,
            selection: TextSelection.collapsed(offset: nextText.length),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exchangeForm = ref.watch(exchangeFormProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    // Intentionally not reading translation helper here to avoid unused local; sub-widgets watch it directly


    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        bottom: true, // Ensure bottom safe area is respected
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.04,
              right: MediaQuery.of(context).size.width * 0.04,
              top: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom, // Add extra bottom padding for navigation bar
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, ref, unreadCount)
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
                _buildExchangeInfo(context, ref, exchangeForm)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 600.ms)
                    .slideX(begin: -0.1, end: 0),
                const SizedBox(height: 32),
                _buildRecentTransactions(context, ref)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 800.ms),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, int unreadCount) {
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
                child: const Icon(
                  Icons.menu_rounded,
                  size: 24,
                  color: Color(0xFF181F30),
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
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => NotificationModal(
                  onClose: () => Navigator.pop(context),
                ),
              );
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
                  const Icon(
                    Icons.notifications_rounded,
                    size: 24,
                    color: Color(0xFF181F30),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3E24),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
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
    final tr = ref.watch(translationHelperProvider);
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
                        child: Text(
                          tr('landing.send'),
                          style: const TextStyle(
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
                      controller: _amountController,
                      focusNode: _amountFocusNode,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,6}$')),
                      ],
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
                        ref
                            .read(exchangeFormProvider.notifier)
                            .setSendAmount(value);
                      },
                    ),
                  ),
                  Text(
                    tr('landing.amountSend'),
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
                        child: Text(
                          tr('landing.receive'),
                          style: const TextStyle(
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
                    tr('landing.receiveAmount'),
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
              child: const Icon(
                Icons.swap_vert_rounded,
                color: Color(0xFF2475FF),
                size: 32,
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
                  color: Colors.grey.shade200,
                ),
                child: CurrencyIconMapper.hasIcon(selectedCurrency.code)
                    ? ClipOval(
                        child: Image.asset(
                          CurrencyIconMapper.getIconPath(selectedCurrency.code)!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          selectedCurrency.code.substring(0, 1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
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
                          physics: const ClampingScrollPhysics(),
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
                                    color: Colors.grey.shade200,
                                  ),
                                  child: CurrencyIconMapper.hasIcon(currency.code)
                                      ? ClipOval(
                                          child: Image.asset(
                                            CurrencyIconMapper.getIconPath(currency.code)!,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            currency.code.substring(0, 1),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade700,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error.contains('temporarily unavailable') 
                      ? 'Server is temporarily unavailable. Please try again.'
                      : error.contains('DioException') || error.contains('bad response')
                          ? 'Unable to connect to server. Please check your connection and try again.'
                          : error,
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (error.contains('temporarily unavailable') || 
              error.contains('server') || 
              error.contains('DioException') ||
              error.contains('bad response')) ...[
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, child) => ElevatedButton.icon(
                onPressed: () {
                  // Clear error and retry
                  final exchangeForm = ref.read(exchangeFormProvider);
                  if (exchangeForm.fromCurrency != null && exchangeForm.toCurrency != null) {
                    // Trigger a refresh by re-setting currencies
                    ref.read(exchangeFormProvider.notifier)
                        .setFromCurrency(exchangeForm.fromCurrency!);
                  }
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context, WidgetRef ref) {
    final exchangeForm = ref.watch(exchangeFormProvider);
    final tr = ref.watch(translationHelperProvider);

    // Check if continue button should be enabled
    final sendAmount = double.tryParse(exchangeForm.sendAmount) ?? 0;
    final receiveAmount = double.tryParse(exchangeForm.receiveAmount) ?? 0;
    
    final bool isEnabled = exchangeForm.fromCurrency != null &&
        exchangeForm.toCurrency != null &&
        sendAmount > 0 &&
        receiveAmount > 0 &&
        exchangeForm.sendAmount.isNotEmpty &&
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
            Flexible(
              child: Text(
                tr('landing.completeExchangeDetails'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color:
                      isEnabled ? const Color(0xFF181F30) : Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
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

  Widget _buildExchangeInfo(BuildContext context, WidgetRef ref, ExchangeFormState state) {
    final tr = ref.watch(translationHelperProvider);
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.currency_exchange_rounded,
            label: tr('landing.exchangeRate'),
            value: state.exchangeRate != null
                ? '1 ${state.fromCurrency?.code ?? ''} = ${_formatExchangeRate(state.exchangeRate!.rate)} ${state.toCurrency?.code ?? ''}'
                : state.calculation != null 
                    ? '1 ${state.fromCurrency?.code ?? ''} = ${_formatExchangeRate(state.calculation!.rate)} ${state.toCurrency?.code ?? ''}'
                    : '—',
            isLoading: state.isLoading,
          ),
          if (state.calculation?.networkInfo != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.settings_ethernet_rounded,
              label: 'Network',
              value: state.calculation!.networkInfo!.network.toUpperCase(),
              isLoading: state.isLoading,
            ),
          ],
          if (state.calculation?.feeBreakdown != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.business_rounded,
              label: tr('landing.fee'),
              value: '${state.calculation!.feeBreakdown!.fees.platformCharges.toStringAsFixed(6)} ${state.calculation?.feeCurrency}',
              isLoading: state.isLoading,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.local_gas_station_rounded,
              label: 'Gas Fee',
              value: '${state.calculation!.feeBreakdown!.fees.gasFee.toStringAsFixed(6)} ${state.calculation?.feeCurrency}',
              isLoading: state.isLoading,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.calculate_rounded,
              label: 'Total Fee',
              value: '${state.calculation!.feeBreakdown!.fees.totalFee.toStringAsFixed(6)} ${state.calculation?.feeCurrency}',
              isLoading: state.isLoading,
            ),
          ] else ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.attach_money_rounded,
              label: tr('landing.fee'),
              value: state.calculation != null
                  ? '+${state.calculation!.fee.toStringAsFixed(2)} ${state.calculation?.feeCurrency}'
                  : '—',
              isLoading: state.isLoading,
            ),
          ],
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.access_time_rounded,
            label: tr('transaction.estimatedTime'),
            value: state.calculation?.networkInfo?.humanReadableTime ?? 
                   (state.exchangeRate?.networkInfo?.humanReadableTime) ??
                   (state.exchangeRate != null
                       ? '${state.exchangeRate?.transferTime.time} ${state.exchangeRate?.transferTime.unit}'
                       : '—'),
            isLoading: state.isLoading,
          ),
          if (state.calculation?.networkInfo != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.network_check_rounded,
              label: 'Network Status',
              value: state.calculation!.networkInfo!.networkStatus,
              isLoading: state.isLoading,
            ),
          ],
          if (state.calculation?.feeBreakdown != null && 
              (state.calculation!.feeBreakdown!.fees.loyaltyDiscount > 0 || 
               state.calculation!.feeBreakdown!.fees.nftDiscount > 0)) ...[
            const SizedBox(height: 16),
            if (state.calculation!.feeBreakdown!.fees.loyaltyDiscount > 0)
              _buildInfoRow(
                icon: Icons.star_rounded,
                label: 'Loyalty Discount (SILVER)',
                value: '-${state.calculation!.feeBreakdown!.fees.loyaltyDiscount.toStringAsFixed(6)} ${state.calculation?.feeCurrency}',
                isLoading: state.isLoading,
                isDiscount: true,
              ),
            if (state.calculation!.feeBreakdown!.fees.nftDiscount > 0) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                icon: Icons.toll_rounded,
                label: 'NFT Discount (COMMON)',
                value: '-${state.calculation!.feeBreakdown!.fees.nftDiscount.toStringAsFixed(6)} ${state.calculation?.feeCurrency}',
                isLoading: state.isLoading,
                isDiscount: true,
              ),
            ],
            if (state.calculation!.feeBreakdown!.fees.totalDiscount > 0) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                icon: Icons.savings_rounded,
                label: 'Total Savings',
                value: '-${state.calculation!.feeBreakdown!.fees.totalDiscount.toStringAsFixed(6)} ${state.calculation?.feeCurrency}',
                isLoading: state.isLoading,
                isDiscount: true,
                isHighlighted: true,
              ),
            ],
          ],
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
          if (state.calculation?.feeBreakdown != null) ...[
            _buildInfoRow(
              icon: Icons.payment_rounded,
              label: 'Total Amount with Fees',
              value: '${state.calculation!.feeBreakdown!.totalAmountWithFees.toStringAsFixed(6)} ${state.fromCurrency?.code ?? ''}',
              isLoading: state.isLoading,
              isHighlighted: true,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.trending_up_rounded,
              label: 'Effective Rate',
              value: '${state.calculation!.feeBreakdown!.effectiveRate.toStringAsFixed(6)} ${state.fromCurrency?.code ?? ''}',
              isLoading: state.isLoading,
            ),
            const SizedBox(height: 16),
          ] else ...[
            _buildInfoRow(
              icon: Icons.payment_rounded,
              label: tr('landing.totalToPay'),
              value: state.sendAmount.isNotEmpty && state.calculation != null
                  ? '${state.calculation!.totalAmount.toStringAsFixed(2)} ${state.fromCurrency?.code ?? ''}'
                  : '—',
              isLoading: state.isLoading,
              isHighlighted: true,
            ),
            const SizedBox(height: 16),
          ],
          _buildInfoRow(
            icon: Icons.account_balance_wallet_rounded,
            label: tr('landing.recipientGets'),
            value: state.calculation != null
                ? '${_formatExchangeRate(state.calculation!.receivedAmount)} ${state.toCurrency?.code ?? ''}'
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
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDiscount
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                    : isHighlighted
                        ? const Color(0xFFFFC000).withValues(alpha: 0.15)
                        : const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDiscount
                    ? const Color(0xFF4CAF50)
                    : isHighlighted
                        ? const Color(0xFFF57C00)
                        : const Color(0xFF1976D2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: isDiscount ? const Color(0xFF4CAF50) : const Color(0xFF6A6A6A),
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
                  color: isDiscount ? const Color(0xFF4CAF50) : Colors.black,
                  fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                ),
                maxLines: 1,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentTransactions(BuildContext context, WidgetRef ref) {
    return const RecentTransactionsWidget();
  }

  String _formatExchangeRate(double rate) {
    if (rate == 0) return '0';
    
    // For very small numbers, use fixed decimal places instead of scientific notation
    if (rate < 0.000001) {
      // Format with up to 12 decimal places, removing trailing zeros
      String formatted = rate.toStringAsFixed(12);
      // Remove trailing zeros
      formatted = formatted.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\\.$'), '');
      return formatted;
    } else if (rate < 0.01) {
      return rate.toStringAsFixed(8).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\\.$'), '');
    } else if (rate < 1) {
      return rate.toStringAsFixed(6).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\\.$'), '');
    } else {
      return rate.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\\.$'), '');
    }
  }
}
