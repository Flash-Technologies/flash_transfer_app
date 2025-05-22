import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flash_transfer_app/core/models/user.dart';

// Provide a dummy user for development
final userProvider = Provider<User>((ref) {
  // This is a dummy user for development purposes
  return User(
    id: 1,
    email: 'user@example.com',
    firstName: 'John',
    lastName: 'Doe',
    phoneNumber: '+1234567890',
    twoFactorEnabled: false,
    loyaltyPoints: 250,
    loyaltyRank: 'Gold',
    walletAddress: '0x1234567890abcdef1234567890abcdef12345678',
    createdAt: DateTime.now().subtract(const Duration(days: 90)),
    updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    isAdmin: false,
    isKycVerified: true,
    authMethod: 'email',
    emailVerified: true,
    isActive: true,
    lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
    lastLoginIp: '192.168.1.1',
    profileImage: 'https://i.pravatar.cc/300',
    socialProvider: null,
    countryName: 'United States',
    city: 'New York',
    dob: '1990-01-01',
    gender: 'Male',
    permanentAddress: '123 Main St, Apt 4',
    postalCode: '10001',
    presentAddress: '123 Main St, Apt 4',
    state: 'NY',
    token: 'dummy_token_for_development',
  );
});

// In the future, replace with actual user data from API
// final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
//   return UserNotifier();
// });
// 
// class UserNotifier extends StateNotifier<User?> {
//   UserNotifier() : super(null);
//   
//   Future<void> fetchUser() async {
//     // Implementation for fetching user
//   }
//   
//   void updateUser(User user) {
//     state = user;
//   }
//   
//   void clearUser() {
//     state = null;
//   }
// }
