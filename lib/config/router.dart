import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../presentation/auth/splash_screen.dart';
import '../presentation/auth/sign_in_screen.dart';
import '../presentation/auth/sign_up_screen.dart';
import '../presentation/auth/set_identity_screen.dart';
import '../presentation/auth/verification_screen.dart';
import '../presentation/auth/success_screen.dart';
import '../presentation/home/home_screen.dart';
import '../presentation/screens/metamask_demo_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    // Always start with splash screen
    initialLocation: '/',

    routes: [
      // Splash screen route that always appears when the app starts
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

      // Authentication routes
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
        path: '/success',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>?;
          return SuccessScreen(
            message:
                params?['message'] ?? 'You Have Successfully top up the wallet',
            buttonText: params?['buttonText'] ?? 'Get Started',
          );
        },
      ),

      // Main app routes (protected by auth state)
      GoRoute(
        path: '/home',
        builder: (context, state) {
          // If not authenticated, redirect to sign-in
          if (authState.status != AuthStatus.authenticated) {
            return const SignInScreen();
          }
          return const HomeScreen();
        },
      ),

      // Wallet integration demo routes
      GoRoute(
        path: '/metamask',
        builder: (context, state) {
          // If not authenticated, redirect to sign-in
          if (authState.status != AuthStatus.authenticated) {
            return const SignInScreen();
          }
          return const MetaMaskDemoScreen();
        },
      ),
    ],
  );
});

// Helper class to refresh router on auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
