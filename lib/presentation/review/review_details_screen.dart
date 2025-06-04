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
            const ProgressHeader(
              step: 3,
              totalSteps: 4,
              title: "Receiver's info",
              subtitle: "Enter the information.",
            ).animate().fadeIn(duration: 300.ms),

            // Main content with scroll
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      _buildTitleSection()
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 16),

                      // Sender Details Card
                      UserDetailCard(
                        title: "Sender Details",
                        user: transactionDetails.sender,
                        showKycBadge: true,
                        onEdit: () => context.push('/sender-details'),
                      )
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 100.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 24),

                      // Payment Method Details (factory pattern)
                      PaymentDetailsFactory.create(
                        paymentType: paymentType,
                        paymentDetails: transactionDetails.paymentDetails,
                      )
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 200.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 24),

                      UserDetailCard(
                        title: "Receiver details",
                        user: transactionDetails.receiver,
                        showKycBadge: false,
                        onEdit: () => context.push('/receiver-info'),
                      )
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 300.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 24),

                      // Transaction Summary
                      TransactionSummary(transactionDetails: transactionDetails)
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 400.ms)
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

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Review Details",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDarkColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Check all details informations.",
          style: TextStyle(fontSize: 16, color: AppTheme.textGrayColor),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, PaymentState paymentState) {
    final isLoading = paymentState.isTransactionLoading;

    return Container(
      padding: const EdgeInsets.all(16),
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
            text: isLoading ? "Creating Transaction..." : "Confirm",
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
          const SizedBox(height: 12),
          AppButton(
            text: "Cancel",
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
      case PaymentType.bank:
      case PaymentType.cash:
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

    // Get transaction flow type
    final fromCurrency = exchangeForm.fromCurrency;
    final toCurrency = exchangeForm.toCurrency;
    final isCryptoToCash =
        fromCurrency?.type == 'CRYPTO' && toCurrency?.type == 'FIAT';

    // For crypto-to-cash, we should already have the wallet address from the crypto payment screen
    if (isCryptoToCash && paymentState.selectedWalletAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please go back and confirm your wallet address first'),
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
        const SnackBar(
          content: Text('Please go back and confirm your crypto address first'),
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
          const SnackBar(
            content: Text(
                'Missing exchange form data. Please go back to the home screen.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final double? amount = double.tryParse(exchangeForm.sendAmount);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid amount. Please check your exchange form.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      bool success;

      if (isCryptoToCash) {
        // Create crypto-to-cash transaction
        success = await ref
            .read(paymentProvider.notifier)
            .createCryptoToCashTransaction(
              amount: amount,
              sourceCurrency: exchangeForm.fromCurrency!.code,
              destinationCurrency: exchangeForm.toCurrency!.code,
              blockchainNetwork:
                  'ethereum', // TODO: Get from blockchain selection
              walletAddress: paymentState.selectedWalletAddress!,
              countryCode: 'ci', // TODO: Get from user location or selection
              paymentMethod:
                  'orange', // TODO: Get from mobile money provider selection
              language: 'en', // TODO: Get from app language setting
              phoneNumber: '1231231232', // TODO: Get from mobile money details
              provider: 'orange', // TODO: Get from provider selection
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
            content: Text(errorMessage ?? 'Failed to create transaction'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Show generic error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
