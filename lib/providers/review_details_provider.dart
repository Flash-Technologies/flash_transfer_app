import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flash_transfer_app/core/models/transaction_details.dart';
import 'package:flash_transfer_app/core/models/user.dart';
import 'package:flash_transfer_app/core/models/payment_details.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';

/// Provider that returns transaction details based on payment type
final reviewDetailsProvider = Provider.family<TransactionDetails, PaymentType>((
  ref,
  paymentType,
) {
  final sender = User(
    id: 1,
    email: 'numan@example.com',
    firstName: 'Numan',
    lastName: 'Xaffar',
    countryName: 'USA',
    profileImage: 'assets/images/micheal.png',
    isKycVerified: true,
  );

  // Common receiver
  final receiver = User(
    id: 2,
    email: 'kamran@example.com',
    firstName: 'Kamran',
    lastName: 'Xaffar',
    countryName: 'USA',
    profileImage: 'assets/images/Billy.png',
    isKycVerified: false,
  );

  switch (paymentType) {
    case PaymentType.card:
      return TransactionDetails(
        sender: sender,
        receiver: receiver,
        paymentDetails: PaymentDetails(
          methodName: 'Credit Card',
          methodIcon: 'assets/images/cre-card.png',
          fundSource: 'Saving',
          purpose: 'Saving',
        ),
        sendAmount: 100,
        sendCurrency: 'EUR',
        receiveAmount: 100,
        receiveCurrency: 'EUR',
        fee: 2.50,
        feeCurrency: 'USDT',
        totalAmount: 100,
        receiverCountry: 'France',
      );

    case PaymentType.bank:
      return TransactionDetails(
        sender: sender,
        receiver: receiver,
        paymentDetails: PaymentDetails(
          methodName: 'Bank Transfer',
          methodIcon: 'assets/images/dollar.png',
          fundSource: 'Saving',
          purpose: 'Saving',
        ),
        sendAmount: 100,
        sendCurrency: 'EUR',
        receiveAmount: 100,
        receiveCurrency: 'EUR',
        fee: 2.50,
        feeCurrency: 'USDT',
        totalAmount: 100,
        receiverCountry: 'France',
      );

    case PaymentType.cash:
      return TransactionDetails(
        sender: sender,
        receiver: receiver,
        paymentDetails: PaymentDetails(
          methodName: 'Cash Payment',
          methodIcon: 'assets/images/dollar.png',
          fundSource: 'Saving',
          purpose: 'Saving',
        ),
        sendAmount: 100,
        sendCurrency: 'EUR',
        receiveAmount: 100,
        receiveCurrency: 'EUR',
        fee: 2.50,
        feeCurrency: 'USDT',
        totalAmount: 100,
        receiverCountry: 'France',
      );

    case PaymentType.crypto:
      return TransactionDetails(
        sender: sender,
        receiver: receiver,
        paymentDetails: PaymentDetails(
          methodName: 'Bitcoin',
          methodIcon: 'assets/images/bitcoin.png',
          networkName: 'Bitcoin',
          networkIcon: 'assets/images/bitcoin.png',
          fundSource: 'Saving',
          purpose: 'Saving',
          cryptoAddress: '0x1234...5678',
        ),
        sendAmount: 100,
        sendCurrency: 'EUR',
        receiveAmount: 100,
        receiveCurrency: 'EUR',
        fee: 2.50,
        feeCurrency: 'USDT',
        totalAmount: 100,
        receiverCountry: 'France',
      );
    case PaymentType.wallet:
      return TransactionDetails(
        sender: sender,
        receiver: receiver,
        paymentDetails: PaymentDetails(
          methodName: 'Wallet',
          methodIcon: 'assets/images/wallet.png',
          fundSource: 'Saving',
          purpose: 'Saving',
        ),
        sendAmount: 100,
        sendCurrency: 'EUR',
        receiveAmount: 100,
        receiveCurrency: 'EUR',
        fee: 2.50,
        feeCurrency: 'USDT',
        totalAmount: 100,
        receiverCountry: 'France',
      );
    case PaymentType.cryptoReceive:
      return TransactionDetails(
        sender: sender,
        receiver: receiver,
        paymentDetails: PaymentDetails(
          methodName: 'Cash Payment',
          methodIcon: 'assets/images/dollar.png',
          networkName: 'Bitcoin',
          networkIcon: 'assets/images/bitcoin.png',
          fundSource: 'Saving',
          purpose: 'Saving',
          cryptoAddress: '0x1234...5678',
        ),
        sendAmount: 100,
        sendCurrency: 'EUR',
        receiveAmount: 100,
        receiveCurrency: 'EUR',
        fee: 2.50,
        feeCurrency: 'USDT',
        totalAmount: 100,
        receiverCountry: 'France',
      );

    case PaymentType.cryptoSendMobile:
      return TransactionDetails(
        sender: sender,
        receiver: receiver,
        paymentDetails: PaymentDetails(
          methodName: 'Bitcoin',
          methodIcon: 'assets/images/bitcoin.png',
          networkName: 'Bitcoin',
          networkIcon: 'assets/images/bitcoin.png',
          fundSource: 'Saving',
          purpose: 'Saving',
        ),
        sendAmount: 100,
        sendCurrency: 'EUR',
        receiveAmount: 100,
        receiveCurrency: 'EUR',
        fee: 2.50,
        feeCurrency: 'USDT',
        totalAmount: 100,
        receiverCountry: 'France',
      );

    case PaymentType.mobile:
      return TransactionDetails(
        sender: sender,
        receiver: receiver,
        paymentDetails: PaymentDetails(
          methodName: 'Mobile Money',
          methodIcon: 'assets/images/omoney.png',
          fundSource: 'Saving',
          purpose: 'Saving',
          phoneNumber: '+33 255 55 2335 2',
        ),
        sendAmount: 100,
        sendCurrency: 'EUR',
        receiveAmount: 100,
        receiveCurrency: 'EUR',
        fee: 2.50,
        feeCurrency: 'USDT',
        totalAmount: 100,
        receiverCountry: 'France',
      );
  }
});
