import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import '../config/app_constants.dart';

@lazySingleton
class HiveService {
  Box<dynamic> get _settings => Hive.box(AppConstants.kSettingsBox);

  // ── Onboarding ───────────────────────────────────────────────────────────

  bool get isOnboarded =>
      _settings.get(AppConstants.kOnboardingDone, defaultValue: false) as bool;

  bool get onboardingDone => isOnboarded;

  Future<void> setOnboarded() =>
      _settings.put(AppConstants.kOnboardingDone, true);

  Future<void> setOnboardingDone() => setOnboarded();

  // ── Appearance ───────────────────────────────────────────────────────────

  bool get isDarkMode =>
      _settings.get(AppConstants.kDarkMode, defaultValue: false) as bool;

  bool get darkMode => isDarkMode;

  Future<void> setDarkMode(bool value) =>
      _settings.put(AppConstants.kDarkMode, value);

  // ── Permissions ──────────────────────────────────────────────────────────

  bool get isLocationPermGranted =>
      _settings.get(AppConstants.kLocationPermGranted, defaultValue: false)
          as bool;

  bool get locationPermGranted => isLocationPermGranted;

  Future<void> setLocationPermGranted(bool value) =>
      _settings.put(AppConstants.kLocationPermGranted, value);

  // ── Notifications ─────────────────────────────────────────────────────────

  bool get isSosAlertsEnabled =>
      _settings.get(AppConstants.kSosAlertsEnabled, defaultValue: true) as bool;

  bool get sosAlertsEnabled => isSosAlertsEnabled;

  Future<void> setSosAlertsEnabled(bool value) =>
      _settings.put(AppConstants.kSosAlertsEnabled, value);

  // ── Cache ─────────────────────────────────────────────────────────────────

  Box<dynamic> get cacheBox => Hive.box(AppConstants.kCacheBox);

  Future<void> cacheValue(String key, dynamic value) =>
      cacheBox.put(key, value);

  Future<void> clearCache() => cacheBox.clear();
}
