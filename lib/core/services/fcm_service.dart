import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'secure_storage_service.dart';

class FcmService {
  final FirebaseFirestore _firestore;
  final SecureStorageService _session;
  final FirebaseMessaging _messaging;

  bool _initialized = false;

  FcmService(this._firestore, this._session)
      : _messaging = FirebaseMessaging.instance;

  /// Called after successful login. Safe to call multiple times.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Background handler is registered in main.dart before runApp().

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null) await _saveToken(token);

    // Keep token fresh — FCM rotates it occasionally.
    _messaging.onTokenRefresh.listen(_saveToken);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// Call this at app startup for users who are already logged in (returning
  /// users) so their FCM token is always current in Firestore.
  Future<void> refreshTokenIfLoggedIn() async {
    final uid = await _session.getUserId();
    if (uid == null) return;
    try {
      final token = await _messaging.getToken();
      if (token != null) await _saveToken(token);
    } catch (_) {}
  }

  Future<void> _saveToken(String token) async {
    final uid = await _session.getUserId();
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  // Foreground messages: the app is already open so Firestore streams deliver
  // the new message in real time. For a banner/popup, integrate
  // flutter_local_notifications and call show() here.
  void _handleForegroundMessage(RemoteMessage message) {}
}
