// File: lib/providers/profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/models/user.dart';
import '../core/services/profile_service.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

// Enhanced Profile State
class ProfileState {
  final bool isLoading;
  final bool isImageUploading;
  final bool isValidating;
  final String? message;
  final String? error;
  final bool isSuccess;
  final Map<String, String>? fieldErrors;
  final double uploadProgress;
  final User? updatedUser;

  const ProfileState({
    this.isLoading = false,
    this.isImageUploading = false,
    this.isValidating = false,
    this.message,
    this.error,
    this.isSuccess = false,
    this.fieldErrors,
    this.uploadProgress = 0.0,
    this.updatedUser,
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isImageUploading,
    bool? isValidating,
    String? message,
    String? error,
    bool? isSuccess,
    Map<String, String>? fieldErrors,
    double? uploadProgress,
    User? updatedUser,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isImageUploading: isImageUploading ?? this.isImageUploading,
      isValidating: isValidating ?? this.isValidating,
      message: message ?? this.message,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
      fieldErrors: fieldErrors,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      updatedUser: updatedUser ?? this.updatedUser,
    );
  }

  bool get hasErrors => fieldErrors?.isNotEmpty == true || error != null;
  bool get isProcessing => isLoading || isImageUploading || isValidating;
}

// Profile Service Provider
final profileServiceProvider = Provider<ProfileService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileService(apiClient: apiClient);
});

// Enhanced Profile Notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileService _profileService;
  final Ref _ref;

  ProfileNotifier(this._profileService, this._ref) : super(const ProfileState());

  // Clear all states
  void clearState() {
    state = const ProfileState();
  }

  // Clear specific error
  void clearError() {
    state = state.copyWith(error: null, fieldErrors: null);
  }

  // Clear field error
  void clearFieldError(String field) {
    if (state.fieldErrors != null) {
      final newFieldErrors = Map<String, String>.from(state.fieldErrors!);
      newFieldErrors.remove(field);
      state = state.copyWith(
        fieldErrors: newFieldErrors.isEmpty ? null : newFieldErrors,
      );
    }
  }

  // Real-time field validation
  Future<void> validateField(String field, String value) async {
    if (state.isValidating) return;

    state = state.copyWith(isValidating: true);

    try {
      final validationError = _validateFieldLocal(field, value);
      
      if (validationError != null) {
        _setFieldError(field, validationError);
      } else {
        clearFieldError(field);
      }

      // Server-side validation for critical fields
      if (['email'].contains(field) && value.isNotEmpty) {
        await _validateFieldRemote(field, value);
      }
    } catch (e) {
      // Handle validation errors silently for real-time validation
    } finally {
      state = state.copyWith(isValidating: false);
    }
  }

  // Local field validation
  String? _validateFieldLocal(String field, String value) {
    switch (field) {
      case 'firstName':
        if (value.isEmpty) return 'First name is required';
        if (value.length < 2) return 'First name must be at least 2 characters';
        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
          return 'First name can only contain letters';
        }
        break;
      
      case 'lastName':
        if (value.isEmpty) return 'Last name is required';
        if (value.length < 2) return 'Last name must be at least 2 characters';
        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
          return 'Last name can only contain letters';
        }
        break;
      
      case 'email':
        if (value.isEmpty) return 'Email is required';
        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        break;
      
      case 'password':
        if (value.isNotEmpty && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        break;
      
      case 'city':
        if (value.isEmpty) return 'City is required';
        if (value.length < 2) return 'City name must be at least 2 characters';
        break;
      
      case 'state':
        if (value.isEmpty) return 'State is required';
        break;
      
      case 'postalCode':
        if (value.isEmpty) return 'ZIP/Postal code is required';
        if (value.length < 3) return 'Invalid postal code';
        break;
    }
    return null;
  }

  // Remote field validation
  Future<void> _validateFieldRemote(String field, String value) async {
    try {
      final isValid = await _profileService.validateField(field, value);
      if (!isValid) {
        switch (field) {
          case 'email':
            _setFieldError(field, 'This email is already in use');
            break;
          default:
            _setFieldError(field, 'Invalid $field');
        }
      }
    } catch (e) {
      // Handle remote validation errors
      _setFieldError(field, 'Unable to validate $field');
    }
  }

  // Set field error
  void _setFieldError(String field, String error) {
    final fieldErrors = Map<String, String>.from(state.fieldErrors ?? {});
    fieldErrors[field] = error;
    state = state.copyWith(fieldErrors: fieldErrors);
  }

  // Validate entire form
  bool validateForm(Map<String, String> formData) {
    final errors = <String, String>{};

    formData.forEach((field, value) {
      final error = _validateFieldLocal(field, value);
      if (error != null) {
        errors[field] = error;
      }
    });

    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }

    state = state.copyWith(fieldErrors: null);
    return true;
  }

  // Update profile with full API integration
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    state = state.copyWith(isLoading: true, error: null, fieldErrors: null);

    try {
      // Validate form data
      final stringData = profileData.map((key, value) => MapEntry(key, value.toString()));
      if (!validateForm(stringData)) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      // Call API service
      final response = await _profileService.updateProfile(profileData);

      if (response.success && response.data != null) {
        // Update user provider with new data
        final updatedUser = response.data!;
        _ref.read(userProvider.notifier).updateUser(updatedUser);

        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          message: response.message ?? 'Profile updated successfully',
          updatedUser: updatedUser,
        );

        return true;
      } else {
        // Handle field-specific errors
        if (response.fieldErrors != null) {
          state = state.copyWith(
            isLoading: false,
            fieldErrors: response.fieldErrors,
            error: response.message,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: response.message ?? 'Failed to update profile',
          );
        }
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error: Unable to update profile',
      );
      return false;
    }
  }

  // Upload profile image with progress tracking
  Future<bool> uploadProfileImage(XFile imageFile) async {
    state = state.copyWith(
      isImageUploading: true,
      uploadProgress: 0.0,
      error: null,
    );

    try {
      // Validate image
      final file = File(imageFile.path);
      final fileSize = await file.length();
      
      if (fileSize > 5 * 1024 * 1024) { // 5MB limit
        state = state.copyWith(
          isImageUploading: false,
          error: 'Image size must be less than 5MB',
        );
        return false;
      }

      // Upload with progress tracking
      final imageUrl = await _profileService.uploadProfileImage(
        imageFile,
        onProgress: (progress) {
          state = state.copyWith(uploadProgress: progress);
        },
      );

      if (imageUrl != null) {
        // Update user with new profile image
        final currentUser = _ref.read(userProvider);
        final updatedUser = User(
          id: currentUser.id,
          email: currentUser.email,
          firstName: currentUser.firstName,
          lastName: currentUser.lastName,
          phoneNumber: currentUser.phoneNumber,
          profileImage: imageUrl,
          countryName: currentUser.countryName,
          city: currentUser.city,
          dob: currentUser.dob,
          gender: currentUser.gender,
          permanentAddress: currentUser.permanentAddress,
          postalCode: currentUser.postalCode,
          presentAddress: currentUser.presentAddress,
          state: currentUser.state,
          token: currentUser.token,
        );

        _ref.read(userProvider.notifier).updateUser(updatedUser);

        state = state.copyWith(
          isImageUploading: false,
          uploadProgress: 1.0,
          message: 'Profile image updated successfully',
          updatedUser: updatedUser,
        );

        return true;
      } else {
        state = state.copyWith(
          isImageUploading: false,
          error: 'Failed to upload image',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isImageUploading: false,
        error: 'Upload failed: ${e.toString()}',
      );
      return false;
    }
  }

  // Update password
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _profileService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (success) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          message: 'Password updated successfully',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Current password is incorrect',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update password: ${e.toString()}',
      );
      return false;
    }
  }

  // Get user preferences
  Future<void> loadUserPreferences() async {
    state = state.copyWith(isLoading: true);

    try {
      final preferences = await _profileService.getUserPreferences();
      // Handle preferences loading
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load preferences',
      );
    }
  }

  // Update specific preference
  Future<void> updatePreference(String key, dynamic value) async {
    try {
      await _profileService.updatePreference(key, value);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to update preference: $key',
      );
    }
  }
}

// Enhanced Profile Provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  return ProfileNotifier(profileService, ref);
});

// Computed providers for specific states
final profileLoadingProvider = Provider<bool>((ref) {
  return ref.watch(profileProvider).isProcessing;
});

final profileErrorProvider = Provider<String?>((ref) {
  return ref.watch(profileProvider).error;
});

final profileFieldErrorsProvider = Provider<Map<String, String>?>((ref) {
  return ref.watch(profileProvider).fieldErrors;
});

final profileSuccessProvider = Provider<bool>((ref) {
  return ref.watch(profileProvider).isSuccess;
});

final imageUploadProgressProvider = Provider<double>((ref) {
  return ref.watch(profileProvider).uploadProgress;
});

// Field-specific error providers
final emailErrorProvider = Provider<String?>((ref) {
  return ref.watch(profileProvider).fieldErrors?['email'];
});

final firstNameErrorProvider = Provider<String?>((ref) {
  return ref.watch(profileProvider).fieldErrors?['firstName'];
});

final lastNameErrorProvider = Provider<String?>((ref) {
  return ref.watch(profileProvider).fieldErrors?['lastName'];
});

// User Provider enhancement (if not already exists)
class UserNotifier extends StateNotifier<User?> {
  UserNotifier() : super(null);

  void updateUser(User user) {
    state = user;
  }

  void clearUser() {
    state = null;
  }

  void updateProfileImage(String imageUrl) {
    if (state != null) {
      state = User(
        id: state!.id,
        email: state!.email,
        firstName: state!.firstName,
        lastName: state!.lastName,
        phoneNumber: state!.phoneNumber,
        profileImage: imageUrl,
        countryName: state!.countryName,
        city: state!.city,
        dob: state!.dob,
        gender: state!.gender,
        permanentAddress: state!.permanentAddress,
        postalCode: state!.postalCode,
        presentAddress: state!.presentAddress,
        state: state!.state,
        token: state!.token,
      );
    }
  }
}

// Enhanced User Provider (replace existing if needed)
final userNotifierProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier();
});