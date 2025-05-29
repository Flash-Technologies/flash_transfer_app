import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flash_transfer_app/core/models/user.dart';
import 'package:flash_transfer_app/core/services/auth_service.dart';
import 'package:flash_transfer_app/core/api/api_client.dart';
import 'package:flash_transfer_app/core/api/endpoints.dart';
import 'package:flash_transfer_app/core/models/api_response.dart';

// User State
class UserState {
  final User? user;
  final bool isLoading;
  final String? error;

  const UserState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// User Notifier
class UserNotifier extends StateNotifier<UserState> {
  final AuthService _authService;
  final ApiClient _apiClient;

  UserNotifier(this._authService, this._apiClient) : super(const UserState()) {
    _initializeUser();
  }

  // Initialize user from saved data
  Future<void> _initializeUser() async {
    state = state.copyWith(isLoading: true);
    try {
      final savedUser = await _authService.getSavedUser();
      if (savedUser != null) {
        state = state.copyWith(user: savedUser, isLoading: false);
        // Fetch fresh user data from API
        await fetchUserProfile();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize user: $e',
      );
    }
  }

  // Fetch user profile from API
  Future<void> fetchUserProfile() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiClient.get(Endpoints.getUserProfile);

      if (response.statusCode == 200) {
        final user = User.fromJson(response.data['data'] ?? response.data);

        // Save updated user data
        await _authService.saveUserData(user);

        state = state.copyWith(user: user, isLoading: false);
      } else {
        throw Exception('Failed to fetch user profile');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch user profile: $e',
      );
    }
  }

  // Update user data
  void updateUser(User user) {
    state = state.copyWith(user: user);
  }

  // Clear user data
  void clearUser() {
    state = const UserState();
  }

  // Update specific user fields
  void updateUserField(String field, dynamic value) {
    if (state.user == null) return;

    final currentUser = state.user!;
    User updatedUser;

    switch (field) {
      case 'firstName':
        updatedUser = User(
          id: currentUser.id,
          email: currentUser.email,
          firstName: value as String?,
          lastName: currentUser.lastName,
          phoneNumber: currentUser.phoneNumber,
          profileImage: currentUser.profileImage,
          countryName: currentUser.countryName,
          city: currentUser.city,
          dob: currentUser.dob,
          gender: currentUser.gender,
          permanentAddress: currentUser.permanentAddress,
          postalCode: currentUser.postalCode,
          presentAddress: currentUser.presentAddress,
          state: currentUser.state,
          token: currentUser.token,
          twoFactorEnabled: currentUser.twoFactorEnabled,
          loyaltyPoints: currentUser.loyaltyPoints,
          loyaltyRank: currentUser.loyaltyRank,
          walletAddress: currentUser.walletAddress,
          createdAt: currentUser.createdAt,
          updatedAt: currentUser.updatedAt,
          isAdmin: currentUser.isAdmin,
          isKycVerified: currentUser.isKycVerified,
          authMethod: currentUser.authMethod,
          emailVerified: currentUser.emailVerified,
          isActive: currentUser.isActive,
          lastLoginAt: currentUser.lastLoginAt,
          lastLoginIp: currentUser.lastLoginIp,
          socialProvider: currentUser.socialProvider,
        );
        break;
      case 'lastName':
        updatedUser = User(
          id: currentUser.id,
          email: currentUser.email,
          firstName: currentUser.firstName,
          lastName: value as String?,
          phoneNumber: currentUser.phoneNumber,
          profileImage: currentUser.profileImage,
          countryName: currentUser.countryName,
          city: currentUser.city,
          dob: currentUser.dob,
          gender: currentUser.gender,
          permanentAddress: currentUser.permanentAddress,
          postalCode: currentUser.postalCode,
          presentAddress: currentUser.presentAddress,
          state: currentUser.state,
          token: currentUser.token,
          twoFactorEnabled: currentUser.twoFactorEnabled,
          loyaltyPoints: currentUser.loyaltyPoints,
          loyaltyRank: currentUser.loyaltyRank,
          walletAddress: currentUser.walletAddress,
          createdAt: currentUser.createdAt,
          updatedAt: currentUser.updatedAt,
          isAdmin: currentUser.isAdmin,
          isKycVerified: currentUser.isKycVerified,
          authMethod: currentUser.authMethod,
          emailVerified: currentUser.emailVerified,
          isActive: currentUser.isActive,
          lastLoginAt: currentUser.lastLoginAt,
          lastLoginIp: currentUser.lastLoginIp,
          socialProvider: currentUser.socialProvider,
        );
        break;
      case 'profileImage':
        updatedUser = User(
          id: currentUser.id,
          email: currentUser.email,
          firstName: currentUser.firstName,
          lastName: currentUser.lastName,
          phoneNumber: currentUser.phoneNumber,
          profileImage: value as String?,
          countryName: currentUser.countryName,
          city: currentUser.city,
          dob: currentUser.dob,
          gender: currentUser.gender,
          permanentAddress: currentUser.permanentAddress,
          postalCode: currentUser.postalCode,
          presentAddress: currentUser.presentAddress,
          state: currentUser.state,
          token: currentUser.token,
          twoFactorEnabled: currentUser.twoFactorEnabled,
          loyaltyPoints: currentUser.loyaltyPoints,
          loyaltyRank: currentUser.loyaltyRank,
          walletAddress: currentUser.walletAddress,
          createdAt: currentUser.createdAt,
          updatedAt: currentUser.updatedAt,
          isAdmin: currentUser.isAdmin,
          isKycVerified: currentUser.isKycVerified,
          authMethod: currentUser.authMethod,
          emailVerified: currentUser.emailVerified,
          isActive: currentUser.isActive,
          lastLoginAt: currentUser.lastLoginAt,
          lastLoginIp: currentUser.lastLoginIp,
          socialProvider: currentUser.socialProvider,
        );
        break;
      default:
        return;
    }

    state = state.copyWith(user: updatedUser);
  }

  // Get display name based on available data
  String getDisplayName() {
    final user = state.user;
    if (user == null) return 'User';

    if (user.firstName != null && user.firstName!.isNotEmpty) {
      if (user.lastName != null && user.lastName!.isNotEmpty) {
        return '${user.firstName} ${user.lastName}';
      }
      return user.firstName!;
    }

    // If no name available, show auth method
    if (user.authMethod != null) {
      return user.authMethod!.toUpperCase();
    }

    return 'User';
  }

  // Get display email/identifier
  String getDisplayIdentifier() {
    final user = state.user;
    if (user == null) return '';

    // If email is available, show it
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!;
    }

    // If no email but wallet address available, show wallet address
    if (user.walletAddress != null && user.walletAddress!.isNotEmpty) {
      return user.walletAddress!;
    }

    return '';
  }
}

// Providers
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: Endpoints.baseUrl);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

// Main user provider
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  return UserNotifier(authService, apiClient);
});

// Computed providers for easy access
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(userProvider).user;
});

final userLoadingProvider = Provider<bool>((ref) {
  return ref.watch(userProvider).isLoading;
});

final userErrorProvider = Provider<String?>((ref) {
  return ref.watch(userProvider).error;
});

final userDisplayNameProvider = Provider<String>((ref) {
  final userNotifier = ref.watch(userProvider.notifier);
  return userNotifier.getDisplayName();
});

final userDisplayIdentifierProvider = Provider<String>((ref) {
  final userNotifier = ref.watch(userProvider.notifier);
  return userNotifier.getDisplayIdentifier();
});
