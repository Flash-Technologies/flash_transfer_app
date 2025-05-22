import 'package:flash_transfer_app/presentation/common/progress_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:flash_transfer_app/config/theme.dart';
import 'package:flash_transfer_app/presentation/common/app_button.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';
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

                      // Receiver Details Card
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
            _buildActionButtons(context),
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

  Widget _buildActionButtons(BuildContext context) {
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
            text: "Confirm",
            onPressed: () => _handleConfirm(context),
            backgroundColor: AppTheme.primaryColor,
            textColor: AppTheme.textDarkColor,
            isDisabled: false,
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
void _handleConfirm(BuildContext context) {
  switch (paymentType) {
    case PaymentType.card:
      context.push('/payment-done');
      break;
    case PaymentType.crypto:
    case PaymentType.cryptoReceive:
    case PaymentType.cryptoSendMobile:
      context.push('/crypto-payment');
      break;
    case PaymentType.bank:
    case PaymentType.cash:
    case PaymentType.mobile:
    case PaymentType.wallet:
      context.push('/receipt');
      break;
  }
}
}
