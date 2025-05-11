import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../core/models/api_response.dart';
import '../core/models/auth_models.dart';
import '../core/models/user.dart';
import '../core/services/auth_service.dart';

// API Client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: Endpoints.baseUrl);
});

// Auth Service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

// Auth state
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  registering,
  verifying,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? message;
  final bool isLoading;

  AuthState({
    required this.status,
    this.user,
    this.message,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? message,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      message: message ?? this.message,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService)
    : super(AuthState(status: AuthStatus.initial, isLoading: true)) {
    _initialize();
  }

  Future<void> _initialize() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      final user = await _authService.getSavedUser();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
    } else {
      state = AuthState(status: AuthStatus.unauthenticated, isLoading: false);
    }
  }

  Future<bool> register(RegisterRequest request) async {
  state = state.copyWith(isLoading: true);
  
  final response = await _authService.register(request);
  
  if (response.success) {
    // Don't change status to verifying - keep it as unauthenticated
    // Just set the message and isLoading flag
    state = state.copyWith(
      status: AuthStatus.unauthenticated, // Keep as unauthenticated
      message: response.message,
      isLoading: false,
    );
    return true;
  } else {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      message: response.message,
      isLoading: false,
    );
    return false;
  }
}

  Future<bool> login(LoginRequest request) async {
    state = state.copyWith(isLoading: true, message: null);

    final response = await _authService.login(request);

    if (response.success && response.data != null) {
      await _authService.saveUserData(response.data!);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.data,
        message: response.message,
        isLoading: false,
      );
      return true;
    } else {
      // Extract error message from the response
      String errorMessage = response.message ?? 'Login failed';
      if (response.data != null &&
          response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>)['errors']
              is Map<String, dynamic>) {
        final errors =
            (response.data as Map<String, dynamic>)['errors']
                as Map<String, dynamic>;
        if (errors['CD'] is Map<String, dynamic>) {
          final cdErrors = errors['CD'] as Map<String, dynamic>;
          errorMessage = cdErrors['CD02']?.toString() ?? errorMessage;
        }
      }

      state = state.copyWith(
      status: AuthStatus.unauthenticated,
      message: response.message ?? "Authentication failed",
      isLoading: false,
    );
    return false;
  }
  }

  Future<bool> loginWithGoogle(String token, String countryName) async {
    state = state.copyWith(isLoading: true);

    final response = await _authService.authenticateWithGoogle(
      SocialAuthRequest(token: token, countryName: countryName),
    );

    if (response.success && response.data != null) {
      await _authService.saveUserData(response.data!);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.data,
        message: response.message,
        isLoading: false,
      );
      return true;
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        message: response.message,
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> loginWithFacebook(String token, String countryName) async {
    state = state.copyWith(isLoading: true);

    final response = await _authService.authenticateWithFacebook(
      SocialAuthRequest(token: token, countryName: countryName),
    );

    if (response.success && response.data != null) {
      await _authService.saveUserData(response.data!);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.data,
        message: response.message,
        isLoading: false,
      );
      return true;
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        message: response.message,
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> resendVerification(String email) async {
    state = state.copyWith(isLoading: true);

    final response = await _authService.resendVerification(email);

    state = state.copyWith(message: response.message, isLoading: false);

    return response.success;
  }

  Future<void> logout() async {
    await _authService.logout();
    state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
  }
}

// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

// Countries provider
final countriesProvider = FutureProvider<List<CountryModel>>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.fetchCountries();
});
