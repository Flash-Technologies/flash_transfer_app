import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/auth/splash_screen.dart';
import '../presentation/auth/sign_in_screen.dart';
import '../presentation/auth/sign_up_screen.dart';
import '../presentation/auth/set_identity_screen.dart';
import '../presentation/auth/verification_screen.dart';
import '../presentation/auth/success_screen.dart';
import '../presentation/home/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      // Don't redirect during auth processes to allow error messages to show
      final isAuthInProgress = authState.isLoading && 
                              (state.matchedLocation == '/sign-in' || 
                               state.matchedLocation == '/sign-up' ||
                               state.matchedLocation == '/set-identity');

      // Auth guard
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isGoingToAuth =
          state.matchedLocation == '/' ||
          state.matchedLocation == '/sign-in' ||
          state.matchedLocation == '/sign-up' ||
          state.matchedLocation == '/set-identity' ||
          state.matchedLocation == '/verification' ||
          state.matchedLocation == '/success';

      // If initial app load is still loading auth state, show splash screen
      // But don't redirect during auth operations
      if (authState.isLoading && !isAuthInProgress) {
        return '/';
      }

      // If not logged in and not going to auth page, redirect to sign-in
      if (!isLoggedIn && !isGoingToAuth) {
        return '/sign-in';
      }

      // If logged in and going to auth page, redirect to home
      if (isLoggedIn && isGoingToAuth) {
        return '/home';
      }

      // Allow navigation to proceed
      return null;
    },
    routes: [
      // Auth flow
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
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
        builder: (context, state) => const SuccessScreen(),
      ),

      // Main app routes
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
  );
});
