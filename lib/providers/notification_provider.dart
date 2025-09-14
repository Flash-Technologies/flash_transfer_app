import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/notification_service.dart';
import '../core/models/notification_model.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';

// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final apiClient = ApiClient(baseUrl: Endpoints.baseUrl);
  return NotificationService(apiClient);
});

// Notification state
class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;
  final int unreadCount;

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

// Notification notifier
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService;

  NotificationNotifier(this._notificationService) : super(NotificationState());

  /// Fetch notifications (first page or refresh)
  Future<void> fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      state = NotificationState(isLoading: true);
    } else if (state.isLoading) {
      return; // Avoid multiple simultaneous requests
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await _notificationService.fetchNotifications(
        page: 1,
        limit: 10,
      );

      state = state.copyWith(
        notifications: response.notifications,
        isLoading: false,
        error: null,
        hasMore: response.pagination.hasNextPage,
        currentPage: response.pagination.page,
      );

      // Also fetch unread count
      await _fetchUnreadCount();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more notifications (pagination)
  Future<void> loadMoreNotifications() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final response = await _notificationService.fetchNotifications(
        page: state.currentPage + 1,
        limit: 10,
      );

      final updatedNotifications = [...state.notifications, ...response.notifications];

      state = state.copyWith(
        notifications: updatedNotifications,
        isLoading: false,
        error: null,
        hasMore: response.pagination.hasNextPage,
        currentPage: response.pagination.page,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Mark a specific notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      final success = await _notificationService.markAsRead(notificationId);
      
      if (success) {
        // Update the notification in the list
        final updatedNotifications = state.notifications.map((notification) {
          if (notification.id == notificationId) {
            return notification.copyWith(isRead: true);
          }
          return notification;
        }).toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
        );
      }
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final success = await _notificationService.markAllAsRead();
      
      if (success) {
        // Update all notifications in the list
        final updatedNotifications = state.notifications.map((notification) {
          return notification.copyWith(isRead: true);
        }).toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: 0,
        );
      }
    } catch (e) {
      print('Failed to mark all notifications as read: $e');
    }
  }

  /// Fetch unread notification count
  Future<void> _fetchUnreadCount() async {
    try {
      final unreadCount = await _notificationService.getUnreadCount();
      state = state.copyWith(unreadCount: unreadCount);
    } catch (e) {
      print('Failed to fetch unread count: $e');
    }
  }

  /// Get unread count (public method)
  Future<void> fetchUnreadCount() async {
    await _fetchUnreadCount();
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset state
  void reset() {
    state = NotificationState();
  }
}

// Notification provider
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return NotificationNotifier(notificationService);
});

// Unread count provider (separate for easier consumption)
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});