import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'secure_storage_service.dart';

class PresenceService with WidgetsBindingObserver {
  final FirebaseFirestore _firestore;
  final SecureStorageService _session;

  bool _isListening = false;

  PresenceService(this._firestore, this._session);

  void startListening() {
    if (_isListening) return;
    _isListening = true;
    WidgetsBinding.instance.addObserver(this);
    _setOnline(true);
  }

  void stopListening() {
    if (!_isListening) return;
    _setOnline(false);
    WidgetsBinding.instance.removeObserver(this);
    _isListening = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setOnline(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        _setOnline(false);
        break;
      default:
        break;
    }
  }

  Future<void> _setOnline(bool isOnline) async {
    final uid = await _session.getUserId();
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).set(
        {
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }
}
