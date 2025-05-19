import 'package:flash_transfer_app/presentation/home/cash_screen.dart';
import 'package:flash_transfer_app/presentation/payment/add_new_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    initialLocation: '/cash',
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
      GoRoute(
        path: '/cash',
        builder: (context, state) => const CashScreen(),
      ),

      GoRoute(
  path: '/add-new',
  builder: (context, state) => const AddNewScreen(),
),

      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
  );
});
