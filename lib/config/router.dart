import 'package:flash_transfer_app/presentation/home/cash_screen.dart';
import 'package:flash_transfer_app/presentation/method/select_method_screen.dart';
import 'package:flash_transfer_app/presentation/payment/add_new_screen.dart';
import 'package:flash_transfer_app/presentation/payment/select_payment_screen.dart';
import 'package:flash_transfer_app/presentation/review/review_details_screen.dart';
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
    initialLocation: '/review-details/card',
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
        path: '/select-method',
        builder: (context, state) => const SelectMethodScreen(),
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
    ],
  );

}
);

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
