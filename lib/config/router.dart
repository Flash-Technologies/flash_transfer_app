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

// Provider to track if splash screen has completed
final splashCompletedProvider = StateProvider<bool>((ref) => false);

// Provider to track if user is logged in
final isLoggedInProvider = StateProvider<bool>((ref) => false);

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);
  final splashCompleted = ref.watch(splashCompletedProvider);

  // Check logged in status once on router init
  authService.isLoggedIn().then((loggedIn) {
    ref.read(isLoggedInProvider.notifier).state = loggedIn;
  });

  return GoRouter(
    navigatorKey: navigatorKey,
    debugLogDiagnostics: true,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = ref.read(isLoggedInProvider);

      // Only handle redirects after splash has completed
      if (!splashCompleted) return null;

      // If at root route and splash completed, go to sign-in or home
      if (state.matchedLocation == '/') {
        return isLoggedIn ? '/home' : '/sign-in';
      }

      return null;
    },
    routes: [
      // Splash screen
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

      // Auth routes
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

      // Main app route
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
  );
});
