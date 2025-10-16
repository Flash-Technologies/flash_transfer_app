import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flash_transfer_app/core/models/user.dart';
import 'package:flash_transfer_app/core/models/transaction_details.dart';
import 'package:flash_transfer_app/core/models/payment_details.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';
import 'package:flash_transfer_app/providers/exchange_provider.dart';
import 'package:flash_transfer_app/providers/user_provider.dart';
import 'package:flash_transfer_app/providers/beneficiary_provider.dart';

/// Provider for transaction details based on payment type
final reviewDetailsProvider =
    Provider.family<TransactionDetails, PaymentType>((ref, paymentType) {
  final exchangeForm = ref.watch(exchangeFormProvider);
  final paymentState = ref.watch(paymentProvider);

  // Get current user data for sender
  final currentUser = ref.watch(currentUserProvider);
  final selectedBeneficiary = ref.watch(selectedBeneficiaryProvider);

  // Create sender from current user data
  final sender = currentUser != null
      ? User(
          id: currentUser.id,
          email: currentUser.email,
          firstName: currentUser.firstName,
          lastName: currentUser.lastName,
          phoneNumber: currentUser.phoneNumber,
          countryName: currentUser.countryName,
          profileImage: currentUser.profileImage,
          isKycVerified: currentUser.isKycVerified ?? false,
          walletAddress: currentUser.walletAddress,
          authMethod: currentUser.authMethod,
        )
      : User(
          id: 0,
          email: 'user@flashtransfer.com',
          firstName: 'Flash',
          lastName: 'User',
          countryName: 'Unknown',
          profileImage: 'assets/images/profile.png',
          isKycVerified: false,
        );

  // Create receiver from selected beneficiary or use fallback
  final receiver = selectedBeneficiary != null
      ? User(
          id: selectedBeneficiary.id,
          email: selectedBeneficiary.email,
          firstName: selectedBeneficiary.firstName,
          lastName: selectedBeneficiary.lastName,
          phoneNumber: selectedBeneficiary.mobileNumber,
          countryName: selectedBeneficiary.country,
          profileImage: 'assets/images/profile.png',
          isKycVerified: false,
        )
      : User(
          id: 0,
          email: 'receiver@example.com',
          firstName: 'Select',
          lastName: 'Beneficiary',
          countryName: 'Unknown',
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

  // Get mobile money details from payment state if available
  final mobileDetails = paymentState.mobileMoneyDetails;
  final phoneNumber = mobileDetails?['phoneNumber']?.toString() ??
      currentUser?.phoneNumber ??
      '+1234567890';

  switch (paymentType) {
    case PaymentType.card:
      return TransactionDetails(
        sender: sender,
        receiver: receiver,
        paymentDetails: PaymentDetails(
          methodName: 'Credit Card',
          methodIcon: 'assets/images/credit_card.png',
          fundSource: 'Credit',
          purpose: selectedBeneficiary?.purpose ?? 'Family Support',
        ),
        sendAmount: sendAmount,
        sendCurrency: sendCurrency,
        receiveAmount: receiveAmount,
        receiveCurrency: receiveCurrency,
        fee: fee,
        feeCurrency: feeCurrency,
        totalAmount: totalAmount,
        receiverCountry: receiver.countryName ?? 'Unknown',
      );

    case PaymentType.bank:
      return TransactionDetails(
        sender: sender,
        receiver: receiver,
        paymentDetails: PaymentDetails(
          methodName: 'Bank Transfer',
          methodIcon: 'assets/images/dollar.png',
          fundSource: selectedBeneficiary?.sourceOfFunds ?? 'Saving',
          purpose: selectedBeneficiary?.purpose ?? 'Family Support',
        ),
        sendAmount: sendAmount,
        sendCurrency: sendCurrency,
        receiveAmount: receiveAmount,
        receiveCurrency: receiveCurrency,
        fee: fee,
        feeCurrency: feeCurrency,
        totalAmount: totalAmount,
        receiverCountry: receiver.countryName ?? 'Unknown',
      );

    case PaymentType.cash:
      // For crypto-to-cash (cash pickup) flow
      final cashSenderInfo = paymentState.cashSenderInfo;
      final cashRecipientInfo = paymentState.cashRecipientInfo;

      // Create receiver from cash recipient info if available
      final cashReceiver = cashRecipientInfo != null
          ? User(
              id: 0,
              email: '',
              firstName: cashRecipientInfo['firstName'] ?? 'Recipient',
              lastName: cashRecipientInfo['lastName'] ?? '',
              phoneNumber: cashRecipientInfo['phoneNumber'],
              countryName: cashRecipientInfo['cashPickupCountry'] ?? 'Unknown',
              profileImage: 'assets/images/profile.png',
              isKycVerified: false,
            )
          : receiver;

      return TransactionDetails(
        sender: sender,
        receiver: cashReceiver,
        paymentDetails: PaymentDetails(
          methodName: 'Cash Pickup',
          methodIcon: 'assets/images/omoney.png',
          fundSource: cashSenderInfo?['sourceOfFunds'] ?? 'SAVINGS',
          purpose: cashSenderInfo?['purposeOfTransaction'] ?? 'EDUCATION',
          phoneNumber: cashRecipientInfo?['phoneNumber'] ?? phoneNumber,
          networkName: paymentState.selectedNetwork?.toUpperCase(),
        ),
        sendAmount: sendAmount,
        sendCurrency: sendCurrency,
        receiveAmount: receiveAmount,
        receiveCurrency: receiveCurrency,
        fee: fee,
        feeCurrency: feeCurrency,
        totalAmount: totalAmount,
        receiverCountry: cashRecipientInfo?['cashPickupCountry'] ?? receiver.countryName ?? 'Unknown',
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
          fundSource: selectedBeneficiary?.sourceOfFunds ?? 'Mobile Money',
          purpose: selectedBeneficiary?.purpose ?? 'Investment',
          cryptoAddress: paymentState.selectedWalletAddress ?? '0x1234...5678',
        ),
        sendAmount: sendAmount,
        sendCurrency: sendCurrency,
        receiveAmount: receiveAmount,
        receiveCurrency: receiveCurrency,
        fee: fee,
        feeCurrency: feeCurrency,
        totalAmount: totalAmount,
        receiverCountry: receiver.countryName ?? 'Unknown',
      );

    case PaymentType.wallet:
      return TransactionDetails(
        sender: sender,
        receiver: receiver,
        paymentDetails: PaymentDetails(
          methodName: 'Wallet',
          methodIcon: 'assets/images/wallet.png',
          fundSource: selectedBeneficiary?.sourceOfFunds ?? 'Wallet',
          purpose: selectedBeneficiary?.purpose ?? 'Transfer',
        ),
        sendAmount: sendAmount,
        sendCurrency: sendCurrency,
        receiveAmount: receiveAmount,
        receiveCurrency: receiveCurrency,
        fee: fee,
        feeCurrency: feeCurrency,
        totalAmount: totalAmount,
        receiverCountry: receiver.countryName ?? 'Unknown',
      );

    case PaymentType.mobile:
      return TransactionDetails(
        sender: sender,
        receiver: receiver,
        paymentDetails: PaymentDetails(
          methodName: 'Mobile Money',
          methodIcon: 'assets/images/omoney.png',
          fundSource: selectedBeneficiary?.sourceOfFunds ?? 'Mobile Account',
          purpose: selectedBeneficiary?.purpose ?? 'Transfer',
          phoneNumber: phoneNumber,
        ),
        sendAmount: sendAmount,
        sendCurrency: sendCurrency,
        receiveAmount: receiveAmount,
        receiveCurrency: receiveCurrency,
        fee: fee,
        feeCurrency: feeCurrency,
        totalAmount: totalAmount,
        receiverCountry: receiver.countryName ?? 'Unknown',
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
