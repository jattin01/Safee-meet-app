import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/use_cases/get_notifications_use_case.dart';
import '../../domain/use_cases/mark_notification_read_use_case.dart';

enum NotificationsStatus {
  initial,
  loading,
  refreshing,
  loadingMore,
  loaded,
  error,
}

class NotificationsState extends Equatable {
  final NotificationsStatus status;
  final List<NotificationEntity> notifications;
  final int currentPage;
  final bool hasMore;
  final String? errorMessage;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.currentPage = 0,
    this.hasMore = true,
    this.errorMessage,
  });

  bool get isEmpty =>
      status == NotificationsStatus.loaded && notifications.isEmpty;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationEntity>? notifications,
    int? currentPage,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, notifications, currentPage, hasMore, errorMessage];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  final GetNotificationsUseCase _getNotifications;
  final MarkNotificationReadUseCase _markAsRead;

  NotificationsCubit(this._getNotifications, this._markAsRead)
      : super(const NotificationsState());

  /// Loads page 1. A no-op if a fetch is already in flight, or (unless
  /// [forceRefresh]) if the list has already loaded once — avoids firing
  /// duplicate requests when the screen rebuilds.
  Future<void> load({bool forceRefresh = false}) async {
    final busy = state.status == NotificationsStatus.loading ||
        state.status == NotificationsStatus.refreshing ||
        state.status == NotificationsStatus.loadingMore;
    if (busy) return;
    if (!forceRefresh && state.status == NotificationsStatus.loaded) return;

    emit(state.copyWith(
      status: state.notifications.isEmpty
          ? NotificationsStatus.loading
          : NotificationsStatus.refreshing,
      clearError: true,
    ));

    final result = await _getNotifications(page: 1);
    result.fold(
      (failure) => emit(state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: failure.message,
      )),
      (page) => emit(NotificationsState(
        status: NotificationsStatus.loaded,
        notifications: page.notifications,
        currentPage: page.currentPage,
        hasMore: page.hasMore,
      )),
    );
  }

  /// Fetches the next page and appends it. A no-op if there's nothing more
  /// to load or a fetch (initial/refresh/another loadMore) is already in
  /// flight — guards against duplicate calls from fast/repeated scroll
  /// events.
  Future<void> loadMore() async {
    if (state.status != NotificationsStatus.loaded || !state.hasMore) return;

    emit(state.copyWith(status: NotificationsStatus.loadingMore));

    final result = await _getNotifications(page: state.currentPage + 1);
    result.fold(
      // Keep the already-loaded list visible on failure — surface the
      // error as a transient message rather than replacing the screen.
      (failure) => emit(state.copyWith(
        status: NotificationsStatus.loaded,
        errorMessage: failure.message,
      )),
      (page) => emit(state.copyWith(
        status: NotificationsStatus.loaded,
        notifications: [...state.notifications, ...page.notifications],
        currentPage: page.currentPage,
        hasMore: page.hasMore,
        clearError: true,
      )),
    );
  }

  /// Optimistically flips the notification to read locally (so the UI
  /// updates immediately, no full refresh needed) and fires the API call
  /// in the background. The read state is a low-stakes, eventually
  /// consistent flag, so a failure here just logs — it doesn't revert the
  /// UI or interrupt whatever navigation the tap triggered.
  Future<void> markAsRead(String notificationId) async {
    final index =
        state.notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1 || state.notifications[index].isRead) return;

    final updated = [...state.notifications];
    updated[index] = updated[index].copyWith(isRead: true);
    emit(state.copyWith(notifications: updated));

    final result = await _markAsRead(notificationId);
    result.fold(
      (failure) => debugPrint(
          '[Notifications] markAsRead($notificationId) failed: ${failure.message}'),
      (_) {},
    );
  }
}
