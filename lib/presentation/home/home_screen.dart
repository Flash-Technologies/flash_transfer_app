// lib/presentation/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              context.go('/sign-in');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Flash Transfer',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (user != null) ...[
              Text(
                'Logged in as: ${user.firstName ?? ''} ${user.lastName ?? ''}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Email: ${user.email}',
                style: const TextStyle(fontSize: 16),
              ),
              if (user.countryName != null)
                Text(
                  'Country: ${user.countryName}',
                  style: const TextStyle(fontSize: 16),
                ),
            ],
          ],
        ),
      ),
    );
  }
}