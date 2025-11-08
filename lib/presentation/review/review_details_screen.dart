import 'package:flash_transfer_app/presentation/common/progress_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:flash_transfer_app/config/theme.dart';
import 'package:flash_transfer_app/presentation/common/app_button.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';
import 'package:flash_transfer_app/providers/exchange_provider.dart';
import 'package:flash_transfer_app/providers/review_details_provider.dart';
import 'package:flash_transfer_app/presentation/review/components/user_detail_card.dart';
import 'package:flash_transfer_app/presentation/review/components/transaction_summary.dart';
import 'package:flash_transfer_app/presentation/review/components/payment_details/payment_details_factory.dart';
import 'package:flash_transfer_app/core/models/transaction_details.dart';
import 'package:flash_transfer_app/providers/language_provider.dart';

class ReviewDetailsScreen extends ConsumerWidget {
  final PaymentType paymentType;

  const ReviewDetailsScreen({Key? key, required this.paymentType})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get transaction details from provider
    final transactionDetails = ref.watch(reviewDetailsProvider(paymentType));
    final paymentState = ref.watch(paymentProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header (Step 3/4)
            Consumer(
              builder: (context, ref, child) {
                final tr = ref.watch(translationHelperProvider);
                return ProgressHeader(
                  step: 3,
                  totalSteps: 4,
                  title: tr('review.detailsScreen.progressTitle'),
                  subtitle: tr('review.detailsScreen.progressSubtitle'),
                );
              },
            ).animate().fadeIn(duration: 300.ms),

            // Main content with scroll
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      _buildTitleSection(ref)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 12),

                      // Payment Method Details (factory pattern)
                      PaymentDetailsFactory.create(
                        paymentType: paymentType,
                        paymentDetails: transactionDetails.paymentDetails,
                      )
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 200.ms)
                          .slideY(begin: 0.1, end: 0),


                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            _buildActionButtons(context, ref, paymentState),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(WidgetRef ref) {
    final tr = ref.watch(translationHelperProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('review.detailsScreen.title'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDarkColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr('review.detailsScreen.subtitle'),
          style: const TextStyle(fontSize: 16, color: AppTheme.textGrayColor),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, PaymentState paymentState) {
    final isLoading = paymentState.isTransactionLoading;
    final tr = ref.watch(translationHelperProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          AppButton(
            text: isLoading ? tr('review.detailsScreen.buttons.creating') : tr('review.detailsScreen.buttons.confirm'),
            onPressed: () {
              if (!isLoading) {
                _handleConfirm(context, ref);
              }
            },
            backgroundColor: AppTheme.primaryColor,
            textColor: AppTheme.textDarkColor,
            isDisabled: isLoading,
          ).animate().scale(
                duration: 200.ms,
                curve: Curves.easeInOut,
                alignment: Alignment.center,
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.03, 1.03),
                delay: 200.ms,
              ),
          const SizedBox(height: 8),
          AppButton(
            text: tr('review.detailsScreen.buttons.cancel'),
            onPressed: () => context.pop(),
            backgroundColor: Colors.transparent,
            textColor: AppTheme.textGrayColor,
            // borderColor: AppTheme.textGrayColor,
          ),
        ],
      ),
    );
  }

  Future<void> _handleConfirm(BuildContext context, WidgetRef ref) async {
    switch (paymentType) {
      case PaymentType.card:
        context.push('/payment-done');
        break;
      case PaymentType.crypto:
      case PaymentType.cryptoReceive:
      case PaymentType.cryptoSendMobile:
        await _handleCryptoTransactionConfirm(context, ref);
        break;
      case PaymentType.cash:
        await _handleCashPickupTransactionConfirm(context, ref);
        break;
      case PaymentType.bank:
      case PaymentType.mobile:
      case PaymentType.wallet:
        context.push('/receipt');
        break;
    }
  }

  Future<void> _handleCryptoTransactionConfirm(
      BuildContext context, WidgetRef ref) async {
    final paymentState = ref.read(paymentProvider);
    final exchangeForm = ref.read(exchangeFormProvider);
    final tr = ref.read(translationHelperProvider);

    // Get transaction flow type
    final fromCurrency = exchangeForm.fromCurrency;
    final toCurrency = exchangeForm.toCurrency;
    final isCryptoToCash =
        fromCurrency?.type == 'CRYPTO' && toCurrency?.type == 'FIAT';

    // For crypto-to-cash, we don't need a wallet address, just the selected network
    if (isCryptoToCash && paymentState.selectedNetwork == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('review.detailsScreen.errors.missingNetwork')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // For cash-to-crypto, check if we have estimate data
    if (!isCryptoToCash &&
        (!paymentState.hasEstimateData ||
            paymentState.selectedWalletAddress == null)) {
      // Show error - user needs to go back and validate address
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('review.detailsScreen.errors.missingCryptoAddress')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Validate that we have the required form data
      if (exchangeForm.fromCurrency == null ||
          exchangeForm.toCurrency == null ||
          exchangeForm.sendAmount.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('review.detailsScreen.errors.missingExchangeData')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final double? amount = double.tryParse(exchangeForm.sendAmount);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('review.detailsScreen.errors.invalidAmount')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      bool success;

      if (isCryptoToCash) {
        // Get mobile money details from payment state
        final mobileMoneyDetails = paymentState.mobileMoneyDetails;
        
        // Create crypto-to-cash transaction
        success = await ref
            .read(paymentProvider.notifier)
            .createCryptoToCashTransaction(
              amount: amount,
              sourceCurrency: exchangeForm.fromCurrency!.code,
              destinationCurrency: exchangeForm.toCurrency!.code,
              blockchainNetwork: paymentState.selectedNetwork ?? 'ethereum',
              countryCode: mobileMoneyDetails?['countryCode'] ?? 'ci',
              paymentMethod: paymentState.selectedProvider ?? 'wave',
              firstName: mobileMoneyDetails?['firstName'],
              lastName: mobileMoneyDetails?['lastName'],
              email: mobileMoneyDetails?['email'],
              phoneNumber: mobileMoneyDetails?['phoneNumber'],
            );
      } else {
        // Create cash-to-crypto transaction (existing flow)
        success = await ref.read(paymentProvider.notifier).createTransaction(
              amount: amount,
              sourceCurrency: exchangeForm.fromCurrency!.code,
              destinationCurrency: exchangeForm.toCurrency!.code,
              blockchainNetwork:
                  'ethereum', // TODO: Get from blockchain selection
              countryCode: 'ci', // TODO: Get from user location or selection
              paymentMethod:
                  'orange', // TODO: Get from mobile money provider selection
              language: 'en', // TODO: Get from app language setting
              phoneNumber: '1231231232', // TODO: Get from mobile money details
              provider: 'orange', // TODO: Get from provider selection
              walletAddress: paymentState.selectedWalletAddress!,
            );
      }

      if (success) {
        // Navigate to payment completion screen with pending status
        context.push('/payment-done?status=pending');
      } else {
        // Show error message
        final errorMessage = ref.read(paymentProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? tr('review.detailsScreen.errors.transactionFailed')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Show generic error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('review.detailsScreen.errors.transactionFailed')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleCashPickupTransactionConfirm(
      BuildContext context, WidgetRef ref) async {
    final paymentState = ref.read(paymentProvider);
    final exchangeForm = ref.read(exchangeFormProvider);
    final tr = ref.read(translationHelperProvider);

    // Verify we have the required estimate data
    if (paymentState.cryptoToCashEstimate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('review.detailsScreen.errors.missingEstimate')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if transaction is available
    final isAvailable = paymentState.cryptoToCashEstimate?['transactionAvailable'] ?? false;
    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('review.detailsScreen.errors.transactionUnavailable')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Validate form data
      if (exchangeForm.fromCurrency == null ||
          exchangeForm.toCurrency == null ||
          exchangeForm.sendAmount.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('review.detailsScreen.errors.missingExchangeData')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final double? amount = double.tryParse(exchangeForm.sendAmount);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('review.detailsScreen.errors.invalidAmount')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get sender and recipient info
      final cashSenderInfo = paymentState.cashSenderInfo;
      final cashRecipientInfo = paymentState.cashRecipientInfo;

      if (cashSenderInfo == null || cashRecipientInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('review.detailsScreen.errors.missingUserInfo')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Prepare sender info for API
      final senderInfo = {
        'sender_phone_number': cashSenderInfo['phoneNumber'] ?? '',
        'sender_first_name': cashSenderInfo['firstName'] ?? '',
        'sender_last_name': cashSenderInfo['lastName'] ?? '',
        'sender_country_code_piece': cashSenderInfo['countryCode'] ?? 'CI',
      };

      // Prepare recipient info for API
      final recipientInfo = {
        'recipient_first_name': cashRecipientInfo['firstName'] ?? '',
        'recipient_last_name': cashRecipientInfo['lastName'] ?? '',
        'recipient_phone_number': cashRecipientInfo['phoneNumber'] ?? '',
        'recipient_country_code': cashRecipientInfo['cashPickupCountry'] ?? 'SN',
      };

      // Create the transaction
      final success = await ref
          .read(paymentProvider.notifier)
          .createCryptoToCashPickupTransaction(
            amount: amount,
            sourceCurrency: exchangeForm.fromCurrency!.code,
            destinationCurrency: exchangeForm.toCurrency!.code,
            blockchainNetwork: paymentState.selectedNetwork ?? 'ethereum',
            countryCode: cashRecipientInfo['cashPickupCountry'] ?? 'SN',
            senderInfo: senderInfo,
            recipientInfo: recipientInfo,
          );

      if (success) {
        // Get the transaction ID
        final transactionId = ref.read(paymentProvider).transactionData?.id;

        // Navigate to payment completion screen with transaction ID
        if (context.mounted) {
          context.push('/payment-done?status=pending&transactionId=$transactionId');
        }
      } else {
        // Show error message
        final errorMessage = ref.read(paymentProvider).errorMessage;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage ?? tr('review.detailsScreen.errors.transactionFailed')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Show generic error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('review.detailsScreen.errors.transactionFailed')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
