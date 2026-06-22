import 'package:injectable/injectable.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_constants.dart';
import 'secure_storage_service.dart';

@lazySingleton
class SocketService {
  io.Socket? _socket;
  final SecureStorageService _storage;

  SocketService(this._storage);

  io.Socket? get socket => _socket;
  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (isConnected) return;
    final token = await _storage.getAccessToken();
    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );
    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }
}
