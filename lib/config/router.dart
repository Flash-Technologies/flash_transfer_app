import 'package:flash_transfer_app/core/models/credit_card_model.dart';
import 'package:flash_transfer_app/presentation/card/card_added_success_screen.dart';
import 'package:flash_transfer_app/presentation/card/confirm_card_screen.dart';
import 'package:flash_transfer_app/presentation/card/enter_card_screen.dart';
import 'package:flash_transfer_app/presentation/card/scan_card_screen.dart';
import 'package:flash_transfer_app/presentation/home/cash_screen.dart';
import 'package:flash_transfer_app/presentation/method/select_method_screen.dart';
import 'package:flash_transfer_app/presentation/payment/add_new_screen.dart';
import 'package:flash_transfer_app/presentation/payment/components/crypto_address_screen.dart';
import 'package:flash_transfer_app/presentation/payment/payment_complete_screen.dart';
import 'package:flash_transfer_app/presentation/payment/components/payment_completion_screen.dart';
import 'package:flash_transfer_app/presentation/payment/select_payment_screen.dart';
import 'package:flash_transfer_app/presentation/review/review_details_screen.dart';
import 'package:flash_transfer_app/presentation/transaction/invite_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';
import '../presentation/auth/splash_screen.dart';
import '../presentation/auth/sign_in_screen.dart';
import '../presentation/auth/sign_up_screen.dart';
import '../presentation/auth/set_identity_screen.dart';
import '../presentation/auth/verification_screen.dart';
import '../presentation/auth/success_screen.dart';
import '../presentation/home/home_screen.dart';
import '../core/services/auth_service.dart';
import '../providers/auth_provider.dart';
import 'package:flash_transfer_app/presentation/home/profile_screen.dart';
import 'package:flash_transfer_app/presentation/settings/edit_profile_screen.dart';
import 'package:flash_transfer_app/presentation/transaction/transaction_screen.dart';
import 'package:flash_transfer_app/presentation/transaction/recipients_screen.dart';
import 'package:flash_transfer_app/presentation/transaction/track_transfer_screen.dart';
import 'package:flash_transfer_app/presentation/settings/contact_us_screen.dart';
// import 'package:flash_transfer_app/presentation/home/nft_screen.dart';
// import 'package:flash_transfer_app/presentation/home/rank_screen.dart';
// import 'package:flash_transfer_app/presentation/card/my_card_screen.dart';
// import 'package:flash_transfer_app/presentation/home/invite_screen.dart';
// import 'package:flash_transfer_app/presentation/home/notification_screen.dart';
import 'package:flash_transfer_app/presentation/settings/language_screen.dart';
// import 'package:flash_transfer_app/presentation/settings/settings_screen.dart';
import 'package:flash_transfer_app/presentation/settings/privacy_screen.dart';
import 'package:flash_transfer_app/presentation/payment/receiver_info_screen.dart';

import '../core/models/nft_model.dart';
import '../presentation/nft/nft_screen.dart';
import '../presentation/nft/nft_detail_screen.dart';
import '../presentation/nft/nft_benefits_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final splashCompletedProvider = StateProvider<bool>((ref) => false);

final isLoggedInProvider = StateProvider<bool>((ref) => false);

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);
  final splashCompleted = ref.watch(splashCompletedProvider);

  authService.isLoggedIn().then((loggedIn) {
    ref.read(isLoggedInProvider.notifier).state = loggedIn;
  });

  return GoRouter(
    navigatorKey: navigatorKey,
    debugLogDiagnostics: true,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = ref.read(isLoggedInProvider);

      if (!splashCompleted) return null;

      if (state.matchedLocation == '/') {
        return isLoggedIn ? '/home' : '/sign-in';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          return SplashScreen(
            onInitialized: () {
              ref.read(splashCompletedProvider.notifier).state = true;
            },
          );
        },
      ),

      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/set-identity',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>?;
          return SetIdentityScreen(
            email: params?['email'] ?? '',
            countryName: params?['countryName'] ?? '',
            password: params?['password'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/verification',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>?;
          return VerificationScreen(email: params?['email'] ?? '');
        },
      ),
      GoRoute(
        path: '/registration-success',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>?;
          return RegistrationSuccessScreen(email: params?['email'] ?? '');
        },
      ),
      GoRoute(path: '/cash', builder: (context, state) => const CashScreen()),

      GoRoute(
        path: '/add-new',
        builder: (context, state) => const AddNewScreen(),
      ),

      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

      GoRoute(
        path: '/select-payment',
        builder: (context, state) => const SelectPaymentScreen(),
      ),
      GoRoute(
        path: '/crypto-address-confirmation',
        name: 'cryptoAddressConfirmation',
        builder: (context, state) => const CryptoAddressScreen(),
      ),

      GoRoute(
        path: '/review-details/:type',
        builder: (context, state) {
          final typeParam = state.pathParameters['type'] ?? 'cash';
          final PaymentType paymentType = _getPaymentTypeFromParam(typeParam);

          return ReviewDetailsScreen(paymentType: paymentType);
        },
      ),

      // Legacy routes for backward compatibility - redirect to the parameterized route
      GoRoute(
        path: '/review-details-card',
        redirect: (_, __) => '/review-details/card',
      ),
      GoRoute(
        path: '/review-details-bank',
        redirect: (_, __) => '/review-details/bank',
      ),
      GoRoute(
        path: '/review-details-cash',
        redirect: (_, __) => '/review-details/cash',
      ),
      GoRoute(
        path: '/review-details-cryptos',
        redirect: (_, __) => '/review-details/crypto',
      ),
      GoRoute(
        path: '/review-details-cryptosm',
        redirect: (_, __) => '/review-details/cryptoSendMobile',
      ),
      GoRoute(
        path: '/review-details-cryptor',
        redirect: (_, __) => '/review-details/cryptoReceive',
      ),
      GoRoute(
        path: '/review-details-mobile',
        redirect: (_, __) => '/review-details/mobile',
      ),

      // GoRoute(
      //   path: '/review-details-mobile',
      //   builder: (context, state) => const ReviewDetailsMobileScreen(),
      // ),
      // GoRoute(
      //   path: '/review-details-cryptosm',
      //   builder: (context, state) => const ReviewDetailsCryptosmScreen(),
      // ),
      GoRoute(
        path: '/payment-complete',
        builder: (context, state) => const PaymentCompleteScreen(),
      ),

      GoRoute(
        path: '/payment-done',
        builder: (context, state) {
          final status = state.uri.queryParameters['status'] ?? 'pending';
          final transactionId = state.uri.queryParameters['transactionId'];
          return PaymentDoneScreen(
            status: status,
            transactionId: transactionId,
          );
        },
      ),

      // Profile and related screens
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),

      // Transaction related screens
      GoRoute(
        path: '/transaction',
        builder: (context, state) => const TransactionScreen(),
      ),

      GoRoute(
        path: '/recipients',
        builder: (context, state) => const RecipientsScreen(),
      ),

      GoRoute(
        path: '/track-transfer',
        builder: (context, state) => const TrackTransferScreen(),
      ),

      // Feature screens
      // GoRoute(path: '/nft', builder: (context, state) => const NftScreen()),

      // GoRoute(path: '/rank', builder: (context, state) => const RankScreen()),

      // GoRoute(
      //   path: '/my-card',
      //   builder: (context, state) => const MyCardScreen(),
      // ),
      GoRoute(
        path: '/invite',
        builder: (context, state) => const InviteScreen(),
      ),

      // // Settings and support screens
      // GoRoute(
      //   path: '/notification',
      //   builder: (context, state) => const NotificationScreen(),
      // ),
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageScreen(),
      ),

      // GoRoute(
      //   path: '/settings',
      //   builder: (context, state) => const SettingsScreen(),
      // ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),

      GoRoute(
        path: '/contact-us',
        builder: (context, state) => const ContactUsScreen(),
      ),
      // Related routes that would navigate to this screen
      // GoRoute(
      //   path: '/crypto-payment',
      //   builder: (context, state) => const CryptoPaymentScreen(),
      //   // This screen would have a button that navigates to payment-complete
      // ),

      // // Routes referenced from the payment complete screen
      // GoRoute(
      //   path: '/track-transfer',
      //   builder: (context, state) => const TrackTransferScreen(),
      // ),

      // card routes
      GoRoute(
        path: '/card/enter',
        name: 'enterCard',
        builder: (context, state) {
          final existingCard = state.extra as CreditCard?;
          return EnterCardScreen(existingCard: existingCard);
        },
      ),

      // Scan card with camera
      GoRoute(
        path: '/card/scan',
        name: 'scanCard',
        builder: (context, state) => const ScanCardScreen(),
      ),

      // Confirm card details before saving
      GoRoute(
        path: '/card/confirm',
        name: 'confirmCard',
        builder: (context, state) {
          final card = state.extra as CreditCard;
          return ConfirmCardScreen(card: card);
        },
      ),

      // Card added success screen
      GoRoute(
        path: '/card/success',
        name: 'cardSuccess',
        builder: (context, state) => const CardAddedSuccessScreen(),
      ),
      GoRoute(
        path: '/receiver-info',
        builder: (context, state) => const ReceiverInfoScreen(),
      ),
      // Edit existing card
      GoRoute(
        path: '/card/edit/:cardId',
        name: 'editCard',
        builder: (context, state) {
          final cardId = state.pathParameters['cardId'];
          final existingCard = state.extra as CreditCard?;
          return EnterCardScreen(existingCard: existingCard);
        },
      ),

      // nft screen routes:
      GoRoute(path: '/nft', builder: (context, state) => const NFTScreen()),
      GoRoute(
        path: '/nft-detail',
        builder: (context, state) {
          final nft = state.extra as NFTModel?;
          if (nft == null) {
            return const Scaffold(body: Center(child: Text('NFT not found')));
          }
          return NFTDetailScreen(nft: nft);
        },
      ),
      GoRoute(
        path: '/nft-benefits',
        builder: (context, state) => const NFTBenefitsScreen(),
      ),
    ],
  );
});

PaymentType _getPaymentTypeFromParam(String param) {
  switch (param) {
    case 'card':
      return PaymentType.card;
    case 'bank':
      return PaymentType.bank;
    case 'cash':
      return PaymentType.cash;
    case 'crypto':
      return PaymentType.crypto;
    case 'cryptoReceive':
      return PaymentType.cryptoReceive;
    case 'cryptoSendMobile':
      return PaymentType.cryptoSendMobile;
    case 'mobile':
      return PaymentType.mobile;
    default:
      return PaymentType.cash; // Default fallback
  }
}
