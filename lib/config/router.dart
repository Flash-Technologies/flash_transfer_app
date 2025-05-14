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
import '../providers/auth_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final _initialNavigationDoneProvider = StateProvider<bool>((ref) => false);

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final initialNavigationDone = ref.watch(_initialNavigationDoneProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    debugLogDiagnostics: true,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      
      if (state.matchedLocation == '/' && !initialNavigationDone) {
        return null;
      }

      if (state.matchedLocation == '/' && initialNavigationDone) {
        return isLoggedIn ? '/home' : '/sign-in';
      }

       
      final isAuthRoute = [
        '/sign-in',
        '/sign-up',
        '/verification',
        '/registration-success',
        '/success',
      ].contains(state.matchedLocation);
      
      // Redirect authenticated users away from auth screens
      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }
      
      // Redirect unauthenticated users from main app routes to sign-in
      if (!isLoggedIn && !isAuthRoute && state.matchedLocation != '/set-identity') {
        return '/sign-in';
      }
      
      // Allow all other navigations
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          return SplashScreen(
            onInitialized: () {
              ref.read(_initialNavigationDoneProvider.notifier).state = true;
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
        path: '/success',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>?;
          return RegistrationSuccessScreen(email: params?['email']);
        },
      ),
      // Main app routes
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
  );
});
