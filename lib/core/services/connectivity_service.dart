import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

/// Single source of truth for "is the device online right now" — checked
/// before firing API calls so the app can show a proper No Internet state
/// immediately instead of waiting on a Dio timeout that then gets
/// misclassified as a generic server/auth error.
@lazySingleton
class ConnectivityService {
  final Connectivity _connectivity;
  ConnectivityService([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Fires whenever the device's connectivity state changes — `true` means
  /// at least one active interface (wifi/mobile/ethernet), not that the
  /// interface actually has a working route to the internet.
  Stream<bool> get onConnectivityChanged => _connectivity.onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none));
}
