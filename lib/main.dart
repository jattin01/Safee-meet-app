import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:device_preview/device_preview.dart';

import 'core/config/app_constants.dart';
import 'core/config/app_theme.dart';
import 'core/dependency_injection/injection_container.dart';
import 'core/routes/app_router.dart';
import 'features/profile/presentation/cubit/current_user_cubit.dart';
import 'features/notifications/presentation/cubit/notifications_cubit.dart';
import 'firebase_options.dart';

// Must be a top-level function. Called by FCM when the app is in
// background or terminated. Firebase auto-displays the notification
// if the payload contains a 'notification' key. Add custom handling
// (e.g. updating badge count) here as needed.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Explicitly opt into edge-to-edge on Android (mandatory from Android 15 /
  // API 35 onward, where the system ignores any attempt to draw an opaque,
  // non-edge-to-edge system navigation bar regardless). Without this, some
  // devices/OEM skins report an inconsistent or zero MediaQuery.padding.bottom
  // for the gesture/3-button nav bar, which is what let the bottom nav bar's
  // safe-area padding compute as 0 and get drawn underneath it.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Status/navigation bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0F172A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Stripe (TEST mode only — see AppConstants.stripePublishableKey).
  // Not awaited: this talks to the native Stripe SDK over a platform
  // channel, and payments aren't needed until the user reaches the
  // Subscription screen — it must not be able to stall app startup/splash
  // if that native call is ever slow.
  Stripe.publishableKey = AppConstants.stripePublishableKey;
  unawaited(Stripe.instance.applySettings());

  // Hive
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox<dynamic>(AppConstants.kSettingsBox),
    Hive.openBox<dynamic>(AppConstants.kCacheBox),
    Hive.openBox<dynamic>(AppConstants.kUserBox),
    Hive.openBox<dynamic>(AppConstants.kNotificationsBox),
  ]);

  // Firebase — explicit options bypass the native google-services.json lookup.
  // Replace placeholder values in firebase_options.dart with real credentials
  // from your Firebase console before shipping.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Register background message handler BEFORE runApp so it works in
    // terminated state. Must be called after Firebase.initializeApp().
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    // Firebase unavailable in this environment (missing credentials).
    // The app continues without crash reporting / push notifications.
    debugPrint('Firebase init skipped: $e');
  }

  // Register all dependencies
  await configureDependencies();

  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => const SafeeMeetApp(),
    ),
  );
}

class SafeeMeetApp extends StatelessWidget {
  const SafeeMeetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = sl<AppRouter>().router;
    // App-root singleton: the router's verification-gate redirect (see
    // AppRouter._guard) and every screen that needs to know/react to the
    // signed-in user's verification status all read this same instance.
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<CurrentUserCubit>()..load()),
        BlocProvider.value(value: sl<NotificationsCubit>()..load()),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        locale: DevicePreview.locale(context),
        builder: (context, child) {
          final clampedChild = MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.of(context).textScaler.clamp(
                    minScaleFactor: 0.8,
                    maxScaleFactor: 1.2,
                  ),
            ),
            child: child!,
          );
          
          return DevicePreview.appBuilder(context, clampedChild);
        },
      ),
    );
  }
}
