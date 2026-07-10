import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../dependency_injection/injection_container.dart';
import '../routes/app_router.dart';
import 'api_client.dart';
import 'secure_storage_service.dart';

class FcmService {
  final FirebaseFirestore _firestore;
  final SecureStorageService _session;
  final ApiClient _api;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'safee_meet_default',
    'SafeeMeet Notifications',
    description: 'Meeting requests, approvals and updates',
    importance: Importance.high,
  );

  bool _initialized = false;

  FcmService(this._firestore, this._session, this._api)
      : _messaging = FirebaseMessaging.instance;

  /// Called after successful login. Safe to call multiple times.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Background handler is registered in main.dart before runApp().

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('[FCM] Permission status: ${settings.authorizationStatus}');

    await _initLocalNotifications();

    // iOS: show the system banner even while the app is in the foreground
    // (by default iOS suppresses it, relying on onMessage instead).
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    print('[FCM] getToken() -> ${token ?? "null"}');
    if (token != null) await _saveToken(token);

    // Keep token fresh — FCM rotates it occasionally.
    _messaging.onTokenRefresh.listen(_saveToken);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Tapped a notification while the app was backgrounded (not terminated).
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // App was launched (cold start) by tapping a notification.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleNotificationTap(initialMessage);
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) =>
          _navigateForType(response.payload),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  Future<void> _saveToken(String token) async {
    final uid = await _session.getUserId();
    if (uid == null) {
      print('[FCM] _saveToken skipped — no logged-in user id in storage yet');
      return;
    }
    try {
      await _firestore.collection('users').doc(uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );
    } catch (e) {
      print('[FCM] Firestore token save failed: $e');
    }

    try {
      await _api.dio.post('/v1/device/fcm-token', data: {'fcm_token': token});
      print('[FCM] Token synced to backend for user $uid');
    } catch (e) {
      print('[FCM] Backend token sync failed: $e');
    }
  }

  // Foreground messages: FCM does NOT auto-display a system notification
  // while the app is open (Android and — without the presentation options
  // set above — iOS both suppress it), so we show one ourselves.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['type'],
    );
  }

  // Routes a notification tap to the right screen based on the `type` the
  // backend attaches to the message's data payload (see PushNotificationService
  // on the Laravel side for the matching convention).
  void _handleNotificationTap(RemoteMessage message) {
    _navigateForType(message.data['type']);
  }

  void _navigateForType(String? type) {
    switch (type) {
      case 'meeting_request':
        sl<AppRouter>().router.push('/meetings?tab=requests');
      case 'meeting_approved':
      case 'meeting_declined':
      case 'meeting_confirmed':
        sl<AppRouter>().router.push('/meetings');
    }
  }
}
