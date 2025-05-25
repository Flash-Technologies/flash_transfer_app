import 'package:flutter_riverpod/flutter_riverpod.dart';

// Contact form state
class ContactState {
  final bool isLoading;
  final String? message;
  final bool isSuccess;

  const ContactState({
    this.isLoading = false,
    this.message,
    this.isSuccess = false,
  });

  ContactState copyWith({
    bool? isLoading,
    String? message,
    bool? isSuccess,
  }) {
    return ContactState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// Contact notifier
class ContactNotifier extends StateNotifier<ContactState> {
  ContactNotifier() : super(const ContactState());

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setMessage(String message, {bool isSuccess = false}) {
    state = state.copyWith(
      message: message,
      isSuccess: isSuccess,
      isLoading: false,
    );
  }

  void clearState() {
    state = const ContactState();
  }

  Future<bool> submitContact({
    required String subject,
    required String email,
    required String message,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // For now, simulate success
      // In the future, this would call the actual API
      // final response = await contactService.submitContact(subject, email, message);

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        message: 'Contact form submitted successfully',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        message: 'Failed to submit contact form: ${e.toString()}',
      );
      return false;
    }
  }
}

// Contact provider
final contactProvider = StateNotifierProvider<ContactNotifier, ContactState>((ref) {
  return ContactNotifier();
});

// Tracking state
enum TrackingType { send, receive }

class TrackingState {
  final bool isLoading;
  final String? message;
  final TrackingType trackingType;
  final String? trackingNumber;
  final Map<String, dynamic>? transferDetails;

  const TrackingState({
    this.isLoading = false,
    this.message,
    this.trackingType = TrackingType.send,
    this.trackingNumber,
    this.transferDetails,
  });

  TrackingState copyWith({
    bool? isLoading,
    String? message,
    TrackingType? trackingType,
    String? trackingNumber,
    Map<String, dynamic>? transferDetails,
  }) {
    return TrackingState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      trackingType: trackingType ?? this.trackingType,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      transferDetails: transferDetails ?? this.transferDetails,
    );
  }
}

// Tracking notifier
class TrackingNotifier extends StateNotifier<TrackingState> {
  TrackingNotifier() : super(const TrackingState());

  void setTrackingType(TrackingType type) {
    state = state.copyWith(trackingType: type);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void clearState() {
    state = const TrackingState();
  }

  Future<bool> trackTransfer({required String trackingNumber}) async {
    state = state.copyWith(
      isLoading: true,
      trackingNumber: trackingNumber,
    );

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Simulate different outcomes based on tracking number
      final isSuccessful = trackingNumber.endsWith('1') || 
                          trackingNumber.endsWith('2') || 
                          trackingNumber.endsWith('3');

      if (isSuccessful) {
        // Simulate transfer details
        final transferDetails = {
          'trackingNumber': trackingNumber,
          'status': trackingNumber.endsWith('1') ? 'completed' : 'in_progress',
          'senderName': 'John Doe',
          'receiverName': 'Jane Smith',
          'amount': '100.00',
          'currency': 'USD',
          'createdAt': DateTime.now().toIso8601String(),
          'estimatedDelivery': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        };

        state = state.copyWith(
          isLoading: false,
          transferDetails: transferDetails,
          message: 'Transfer found successfully',
        );

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          message: 'Transfer not found with tracking number: $trackingNumber',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        message: 'Error tracking transfer: ${e.toString()}',
      );
      return false;
    }
  }
}

// Tracking provider
final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  return TrackingNotifier();
});

// Profile state
class ProfileState {
  final bool isLoading;
  final String? message;
  final bool isSuccess;

  const ProfileState({
    this.isLoading = false,
    this.message,
    this.isSuccess = false,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? message,
    bool? isSuccess,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// Profile notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState());

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void clearState() {
    state = const ProfileState();
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    state = state.copyWith(isLoading: true);

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // For now, simulate success
      // In the future, this would call the actual API
      // final response = await profileService.updateProfile(profileData);

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        message: 'Profile updated successfully',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        message: 'Failed to update profile: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> uploadProfileImage(String imagePath) async {
    state = state.copyWith(isLoading: true);

    try {
      // Simulate image upload
      await Future.delayed(const Duration(seconds: 3));

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        message: 'Profile image updated successfully',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        message: 'Failed to upload image: ${e.toString()}',
      );
      return false;
    }
  }
}

// Profile provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});