import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../routes/app_router.dart';
import '../services/api_client.dart';
import '../services/stripe_payment_service.dart';
import '../services/fcm_service.dart';
import '../services/google_auth_service.dart';
import '../services/hive_service.dart';
import '../services/presence_service.dart';
import '../services/secure_storage_service.dart';
import '../services/socket_service.dart';
import '../storage/auth_session_manager.dart';
import '../storage/token_storage_service.dart';

// Auth
import '../../features/auth/data/local_data_sources/auth_local_data_source.dart';
import '../../features/auth/data/remote_data_sources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/use_cases/apple_login_use_case.dart';
import '../../features/auth/domain/use_cases/check_auth_status_use_case.dart';
import '../../features/auth/domain/use_cases/check_user_exists_use_case.dart';
import '../../features/auth/domain/use_cases/get_current_user_use_case.dart';
import '../../features/auth/domain/use_cases/google_login_use_case.dart';
import '../../features/auth/domain/use_cases/login_use_case.dart';
import '../../features/auth/domain/use_cases/logout_use_case.dart';
import '../../features/auth/domain/use_cases/register_user_use_case.dart';
import '../../features/auth/domain/use_cases/send_otp_use_case.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Dashboard
import '../../features/dashboard/data/remote_data_sources/dashboard_remote_data_source.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/use_cases/get_dashboard_use_case.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';

// Verification
import '../../features/verification/data/remote_data_sources/verification_remote_data_source.dart';
import '../../features/verification/data/repositories/verification_repository_impl.dart';
import '../../features/verification/domain/repositories/verification_repository.dart';
import '../../features/verification/presentation/bloc/verification_bloc.dart';

// Member Search
import '../../features/member_search/data/remote_data_sources/member_search_remote_data_source.dart';
import '../../features/member_search/data/repositories/member_search_repository_impl.dart';
import '../../features/member_search/domain/repositories/member_search_repository.dart';
import '../../features/member_search/presentation/bloc/member_search_bloc.dart';

// Settings — Emergency Contacts
import '../../features/settings/data/remote_data_sources/emergency_contact_remote_data_source.dart';
import '../../features/settings/data/repositories/emergency_contact_repository_impl.dart';
import '../../features/settings/domain/repositories/emergency_contact_repository.dart';
import '../../features/settings/presentation/bloc/emergency_contact_bloc.dart';

// Messaging — Firebase Firestore implementation
import '../../features/messaging/data/datasources/chat_remote_datasource.dart';
import '../../features/messaging/data/repositories/messaging_repository_impl.dart';
import '../../features/messaging/domain/repositories/messaging_repository.dart';
import '../../features/messaging/domain/use_cases/create_or_get_room_use_case.dart';
import '../../features/messaging/domain/use_cases/get_conversations_use_case.dart';
import '../../features/messaging/domain/use_cases/get_users_use_case.dart';
import '../../features/messaging/domain/use_cases/listen_messages_use_case.dart';
import '../../features/messaging/domain/use_cases/mark_message_read_use_case.dart';
import '../../features/messaging/domain/use_cases/send_message_use_case.dart';
import '../../features/messaging/domain/use_cases/upload_attachment_use_case.dart';
import '../../features/messaging/presentation/bloc/messaging_bloc.dart';

// Meetings
import '../../features/meetings/data/repositories/meetings_repository_impl.dart';
import '../../features/meetings/domain/repositories/meetings_repository.dart';
import '../../features/meetings/presentation/bloc/meetings_bloc.dart';

// Meetings — Emergency Share
import '../../features/meetings/data/remote_data_sources/emergency_share_remote_data_source.dart';
import '../../features/meetings/data/repositories/emergency_share_repository_impl.dart';
import '../../features/meetings/domain/repositories/emergency_share_repository.dart';
import '../../features/meetings/presentation/bloc/emergency_share_bloc.dart';

// Subscription
import '../../features/subscription/data/remote_data_sources/subscription_remote_data_source.dart';
import '../../features/subscription/data/repositories/subscription_repository_impl.dart';
import '../../features/subscription/domain/repositories/subscription_repository.dart';
import '../../features/subscription/domain/use_cases/get_subscription_plans_use_case.dart';
import '../../features/subscription/presentation/bloc/subscription_bloc.dart';

// SOS
import '../../features/sos/presentation/bloc/sos_bloc.dart';

// Profile
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/cubit/current_user_cubit.dart';

// GPS Tracking
import '../../features/gps_tracking/presentation/bloc/gps_tracking_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  // ── Infrastructure ────────────────────────────────────────────────────────
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(sl()),
  );
  sl.registerLazySingleton<HiveService>(() => HiveService());
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));
  sl.registerLazySingleton<SocketService>(() => SocketService(sl()));
  sl.registerSingleton<AppRouter>(AppRouter(sl()));

  // ── Firebase ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );
  sl.registerLazySingleton<FirebaseStorage>(
    () => FirebaseStorage.instance,
  );
  sl.registerLazySingleton<GoogleAuthService>(() => GoogleAuthService());
  sl.registerLazySingleton<PresenceService>(
    () => PresenceService(sl(), sl()),
  );
  sl.registerLazySingleton<FcmService>(
    () => FcmService(sl(), sl(), sl()),
  );

  // ── Storage ───────────────────────────────────────────────────────────────
  sl.registerLazySingleton<TokenStorageService>(
    () => TokenStorageService(sl()),
  );
  sl.registerLazySingleton<AuthSessionManager>(
    () => AuthSessionManager(sl()),
  );

  // ── Auth ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl(),
      local: sl(),
      session: sl(),
      secureStorage: sl(),
    ),
  );
  sl.registerLazySingleton(() => RegisterUserUseCase(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => GoogleLoginUseCase(sl()));
  sl.registerLazySingleton(() => AppleLoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => CheckUserExistsUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => SendOtpUseCase(sl()));
  sl.registerFactory(
    () => AuthBloc(
      checkAuthStatus: sl(),
      registerUser: sl(),
      login: sl(),
      googleLogin: sl(),
      appleLogin: sl(),
      logout: sl(),
      checkUserExists: sl(),
      getCurrentUser: sl(),
      sendOtp: sl(),
    ),
  );

  // ── Dashboard ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetDashboardUseCase(sl()));
  sl.registerFactory(
    () => DashboardBloc(getDashboard: sl(), repository: sl()),
  );

  // ── Verification ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<VerificationRemoteDataSource>(
    () => VerificationRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<VerificationRepository>(
    () => VerificationRepositoryImpl(sl(), sl()),
  );
  sl.registerFactory(() => VerificationBloc(sl()));

  // ── Member Search ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<MemberSearchRemoteDataSource>(
    () => MemberSearchRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<MemberSearchRepository>(
    () => MemberSearchRepositoryImpl(sl()),
  );
  sl.registerFactory(() => MemberSearchBloc(sl()));

  // ── Settings — Emergency Contacts ────────────────────────────────────────
  sl.registerLazySingleton<EmergencyContactRemoteDataSource>(
    () => EmergencyContactRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<EmergencyContactRepository>(
    () => EmergencyContactRepositoryImpl(sl()),
  );
  sl.registerFactory(() => EmergencyContactBloc(sl()));

  // ── Messaging (Firebase Firestore) ────────────────────────────────────────
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(
        sl<FirebaseFirestore>(), sl<FirebaseStorage>()),
  );
  sl.registerLazySingleton<MessagingRepository>(
    () => MessagingRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton(() => CreateOrGetRoomUseCase(sl()));
  sl.registerLazySingleton(() => GetConversationsUseCase(sl()));
  sl.registerLazySingleton(() => GetUsersUseCase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));
  sl.registerLazySingleton(() => ListenMessagesUseCase(sl()));
  sl.registerLazySingleton(() => MarkMessageReadUseCase(sl()));
  sl.registerLazySingleton(() => UploadAttachmentUseCase(sl()));
  sl.registerFactory(
    () => MessagingBloc(
      createOrGetRoom: sl(),
      getUsers: sl(),
      sendMessage: sl(),
      markRead: sl(),
      uploadAttachment: sl(),
      session: sl(),
      repository: sl(),
    ),
  );

  // ── Meetings ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<MeetingsRepository>(
    () => MeetingsRepositoryImpl(sl(), sl()),
  );
  sl.registerFactory(() => MeetingsBloc(sl()));

  // ── Meetings — Emergency Share ────────────────────────────────────────────
  sl.registerLazySingleton<EmergencyShareRemoteDataSource>(
    () => EmergencyShareRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<EmergencyShareRepository>(
    () => EmergencyShareRepositoryImpl(sl()),
  );
  sl.registerFactory(() => EmergencyShareBloc(sl()));

  // ── SOS ───────────────────────────────────────────────────────────────────
  sl.registerFactory(() => SosBloc(sl(), sl()));

  // ── Profile ───────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl(), sl()),
  );
  sl.registerFactory(() => ProfileBloc(sl()));
  sl.registerFactory(() => CurrentUserCubit(sl()));

  // ── GPS Tracking ──────────────────────────────────────────────────────────
  sl.registerFactory(() => GpsTrackingBloc(sl()));

  // ── Subscription ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<SubscriptionRemoteDataSource>(
    () => SubscriptionRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetSubscriptionPlansUseCase(sl()));
  sl.registerLazySingleton(() => StripePaymentService());
  sl.registerFactory(() => SubscriptionBloc(sl(), sl(), sl()));
}
