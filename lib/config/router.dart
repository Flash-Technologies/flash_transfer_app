import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/auth/splash_screen.dart';
import '../presentation/auth/sign_in_screen.dart';
import '../presentation/auth/sign_up_screen.dart';
import '../presentation/auth/set_identity_screen.dart';
import '../presentation/auth/verification_screen.dart';
import '../presentation/auth/success_screen.dart';
import '../presentation/home/home_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = 
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = 
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // Auth flow
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
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
        final email = state.uri.queryParameters['email'] ?? '';
        final countryName = state.uri.queryParameters['countryName'] ?? '';
        final password = state.uri.queryParameters['password'] ?? '';
        
        // This would be implemented in the SetIdentityScreen
        return Scaffold(
          body: Center(
            child: Text('Set Identity Screen for $email from $countryName'),
          ),
        );
      },
    ),
    GoRoute(
      path: '/verification',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        final verificationToken = state.uri.queryParameters['verificationToken'] ?? '';
        
        // This would be implemented in the VerificationScreen 
        return Scaffold(
          body: Center(
            child: Text('Verification Screen for $email'),
          ),
        );
      },
    ),
    GoRoute(
      path: '/success',
      builder: (context, state) => Scaffold(
        body: Center(
          child: Text('Success Screen'),
        ),
      ),
    ),
    
    // Home screens would be added here in a real implementation
    GoRoute(
      path: '/home',
      builder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Home Screen'),
              ElevatedButton(
                onPressed: () => GoRouter.of(context).go('/sign-in'),
                child: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    ),
  ],
);
