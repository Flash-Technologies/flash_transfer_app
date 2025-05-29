import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flash_transfer_app/core/models/user.dart';
import 'package:flash_transfer_app/core/models/transaction_details.dart';
import 'package:flash_transfer_app/core/models/payment_details.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';
import 'package:flash_transfer_app/providers/exchange_provider.dart';

/// Provider for transaction details based on payment type
final reviewDetailsProvider =
    Provider.family<TransactionDetails, PaymentType>((ref, paymentType) {
  final exchangeForm = ref.watch(exchangeFormProvider);
  final paymentState = ref.watch(paymentProvider);

  // Create dynamic sender based on current app user (you might have a user provider)
  final sender = User(
    id: 1,
    email: 'john.doe@example.com', // TODO: Get from current user
    firstName: 'John', // TODO: Get from current user
    lastName: 'Doe', // TODO: Get from current user
    countryName: 'USA',
    profileImage: 'assets/images/profile.png',
    isKycVerified: true,
  );

  // Create dynamic receiver - this should come from selected beneficiary
  // TODO: Replace with actual selected beneficiary from beneficiary provider
  final receiver = User(
    id: 2,
    email: 'jane.smith@example.com', // TODO: Get from selected beneficiary
    firstName: 'Jane', // TODO: Get from selected beneficiary
    lastName: 'Smith', // TODO: Get from selected beneficiary
    countryName: 'International',
    profileImage: 'assets/images/profile.png',
    isKycVerified: false,
  );

  // Get dynamic amounts from exchange form
  final sendAmount = double.tryParse(exchangeForm.sendAmount) ?? 100.0;
  final receiveAmount = double.tryParse(exchangeForm.receiveAmount) ?? 100.0;
  final sendCurrency = exchangeForm.fromCurrency?.code ?? 'USD';
  final receiveCurrency = exchangeForm.toCurrency?.code ?? 'ETH';

  // Use actual fee data from estimate if available
  double fee = 2.50;
  String feeCurrency = sendCurrency;
  double totalAmount = sendAmount + fee;

  if (paymentState.hasEstimateData) {
    fee = paymentState.estimateData!.fees.totalFee;
    feeCurrency = sendCurrency;
    totalAmount = paymentState.estimateData!.results.totalAmountToPay;
  }

  switch (paymentType) {
    case PaymentType.card:
      return TransactionDetails(
        sender: sender,
        receiver: receiver,
        paymentDetails: PaymentDetails(
          methodName: 'Credit Card',
          methodIcon: 'assets/images/credit_card.png',
          fundSource: 'Credit',
          purpose: 'Family Support',
        ),
        sendAmount: sendAmount,
        sendCurrency: sendCurrency,
        receiveAmount: receiveAmount,
        receiveCurrency: receiveCurrency,
        fee: fee,
        feeCurrency: feeCurrency,
        totalAmount: totalAmount,
        receiverCountry: 'International',
      );

    case PaymentType.bank:
      return TransactionDetails(
        sender: sender,
        receiver: receiver,
        paymentDetails: PaymentDetails(
          methodName: 'Bank Transfer',
          methodIcon: 'assets/images/dollar.png',
          fundSource: 'Saving',
          purpose: 'Family Support',
        ),
        sendAmount: sendAmount,
        sendCurrency: sendCurrency,
        receiveAmount: receiveAmount,
        receiveCurrency: receiveCurrency,
        fee: fee,
        feeCurrency: feeCurrency,
        totalAmount: totalAmount,
        receiverCountry: 'International',
      );

    case PaymentType.cash:
      return TransactionDetails(
        sender: sender,
        receiver: receiver,
        paymentDetails: PaymentDetails(
          methodName: 'Mobile Money',
          methodIcon: 'assets/images/omoney.png',
          fundSource: 'Cash',
          purpose: 'Family Support',
          phoneNumber:
              '+1234567890', // TODO: Get from user's mobile money details
        ),
        sendAmount: sendAmount,
        sendCurrency: sendCurrency,
        receiveAmount: receiveAmount,
        receiveCurrency: receiveCurrency,
        fee: fee,
        feeCurrency: feeCurrency,
        totalAmount: totalAmount,
        receiverCountry: 'International',
      );

    case PaymentType.crypto:
    case PaymentType.cryptoReceive:
    case PaymentType.cryptoSendMobile:
      return TransactionDetails(
        sender: sender,
        receiver: receiver,
        paymentDetails: PaymentDetails(
          methodName: receiveCurrency,
          methodIcon: _getCryptoIcon(receiveCurrency),
          networkName: 'Ethereum', // TODO: Get from selected blockchain
          networkIcon: 'assets/images/ethereum.png',
          fundSource: 'Mobile Money',
          purpose: 'Investment',
          cryptoAddress: paymentState.selectedWalletAddress ?? '0x1234...5678',
        ),
        sendAmount: sendAmount,
        sendCurrency: sendCurrency,
        receiveAmount: receiveAmount,
        receiveCurrency: receiveCurrency,
        fee: fee,
        feeCurrency: feeCurrency,
        totalAmount: totalAmount,
        receiverCountry: 'International',
      );

    case PaymentType.wallet:
      return TransactionDetails(
        sender: sender,
        receiver: receiver,
        paymentDetails: PaymentDetails(
          methodName: 'Wallet',
          methodIcon: 'assets/images/wallet.png',
          fundSource: 'Wallet',
          purpose: 'Transfer',
        ),
        sendAmount: sendAmount,
        sendCurrency: sendCurrency,
        receiveAmount: receiveAmount,
        receiveCurrency: receiveCurrency,
        fee: fee,
        feeCurrency: feeCurrency,
        totalAmount: totalAmount,
        receiverCountry: 'International',
      );

    case PaymentType.mobile:
      return TransactionDetails(
        sender: sender,
        receiver: receiver,
        paymentDetails: PaymentDetails(
          methodName: 'Mobile Money',
          methodIcon: 'assets/images/omoney.png',
          fundSource: 'Mobile Account',
          purpose: 'Transfer',
          phoneNumber:
              '+1234567890', // TODO: Get from user's mobile money details
        ),
        sendAmount: sendAmount,
        sendCurrency: sendCurrency,
        receiveAmount: receiveAmount,
        receiveCurrency: receiveCurrency,
        fee: fee,
        feeCurrency: feeCurrency,
        totalAmount: totalAmount,
        receiverCountry: 'International',
      );
  }
});

// Helper function to get crypto icon based on currency
String _getCryptoIcon(String currency) {
  switch (currency.toUpperCase()) {
    case 'BTC':
      return 'assets/images/wallets/metamask.png'; // TODO: Replace with bitcoin.png when available
    case 'ETH':
      return 'assets/images/wallets/trust.png'; // TODO: Replace with ethereum.png when available
    case 'USDT':
      return 'assets/images/wallets/binance.png'; // TODO: Replace with usdt.png when available
    default:
      return 'assets/images/wallets/coinbase.png'; // TODO: Replace with crypto.png when available
  }
}
