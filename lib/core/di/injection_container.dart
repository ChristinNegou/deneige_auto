import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Cache & Offline
import '../cache/reservation_cache.dart';
import '../cache/sync_queue.dart';
import '../cache/sync_service.dart';
import '../cache/network_status.dart';

// Config
import '../../features/auth/domain/usecases/reset_password_usecase.dart';
import '../../features/auth/domain/usecases/update_profile_usecase.dart';
import '../../features/reservation/domain/usecases/add_vehicle_usecase.dart';
import '../../features/reservation/domain/usecases/delete_vehicle_usecase.dart';
import '../../features/reservation/domain/usecases/get_parking_spots_usecase.dart';
import '../../features/reservation/domain/usecases/get_vehicules_usecase.dart';
import '../../features/reservation/domain/usecases/update_reservation_usecase.dart';
import '../../features/reservation/presentation/bloc/reservation_list_bloc.dart';
import '../../features/reservation/presentation/bloc/edit_reservation_bloc.dart';
import '../../features/vehicule/presentation/bloc/vehicule_bloc.dart';
import '../../service/secure_storage_service.dart';
import '../network/dio_client.dart';
import '../services/location_service.dart';
import '../services/push_notification_service.dart';
import '../services/socket_service.dart';
import '../services/analytics_service.dart';

// Auth
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/forgot_password_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';

// Home/Weather
import '../../features/home/data/datasources/weather_remote_datasource.dart';
import '../../features/home/data/repositories/weather_repository_impl.dart';
import '../../features/home/domain/repositories/weather_repository.dart';
import '../../features/home/domain/usecases/get_weather_usecase.dart';
import '../../features/home/domain/usecases/get_weather_forecast_usecase.dart';

// Reservation
import '../../features/reservation/data/datasources/reservation_remote_datasource.dart';
import '../../features/reservation/data/repositories/reservation_repository_impl.dart';
import '../../features/reservation/domain/repositories/reservation_repository.dart';
import '../../features/reservation/domain/usecases/cancel_reservation_usecase.dart';
import '../../features/reservation/domain/usecases/create_reservation_usecase.dart';
import '../../features/reservation/domain/usecases/get_reservations_usecase.dart';
import '../../features/reservation/domain/usecases/get_reservation_by_id_usecase.dart';

// Payment
import '../../features/payment/data/datasources/payment_remote_datasource.dart';
import '../../features/payment/data/repositories/payment_repository_impl.dart';
import '../../features/payment/domain/repositories/payment_repository.dart';
import '../../features/payment/domain/usecases/get_payment_history_usecase.dart';
import '../../features/payment/domain/usecases/get_payment_methods_usecase.dart';
import '../../features/payment/domain/usecases/save_payment_method_usecase.dart';
import '../../features/payment/domain/usecases/delete_payment_method_usecase.dart';
import '../../features/payment/domain/usecases/set_default_payment_method_usecase.dart';
import '../../features/payment/domain/usecases/process_refund_usecase.dart';
import '../../features/payment/presentation/bloc/payment_history_bloc.dart';
import '../../features/payment/presentation/bloc/payment_methods_bloc.dart';
import '../../features/payment/presentation/bloc/refund_bloc.dart';

// Notifications
import '../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/usecases/get_notifications_usecase.dart';
import '../../features/notifications/domain/usecases/get_unread_count_usecase.dart';
import '../../features/notifications/domain/usecases/mark_as_read_usecase.dart';
import '../../features/notifications/domain/usecases/mark_all_as_read_usecase.dart';
import '../../features/notifications/domain/usecases/delete_notification_usecase.dart';
import '../../features/notifications/domain/usecases/clear_all_notifications_usecase.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';

// Chat
import '../../features/chat/data/datasources/chat_remote_datasource.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';

// AI Chat
import '../../features/ai_chat/data/datasources/ai_chat_remote_datasource.dart';
import '../../features/ai_chat/data/repositories/ai_chat_repository_impl.dart';
import '../../features/ai_chat/domain/repositories/ai_chat_repository.dart';
import '../../features/ai_chat/domain/usecases/send_ai_message_usecase.dart';
import '../../features/ai_chat/presentation/bloc/ai_chat_bloc.dart';

// AI Features
import '../../features/ai_features/data/datasources/ai_features_remote_datasource.dart';
import '../../features/ai_features/data/repositories/ai_features_repository_impl.dart';
import '../../features/ai_features/domain/repositories/ai_features_repository.dart';
import '../../features/ai_features/presentation/bloc/ai_features_bloc.dart';

// Verification
import '../../features/verification/data/datasources/verification_remote_datasource.dart';
import '../../features/verification/data/repositories/verification_repository_impl.dart';
import '../../features/verification/domain/repositories/verification_repository.dart';
import '../../features/verification/presentation/bloc/verification_bloc.dart';

// Snow Worker
import '../../features/snow_worker/data/datasources/worker_remote_datasource.dart';
import '../../features/snow_worker/data/repositories/worker_repository_impl.dart';
import '../../features/snow_worker/domain/repositories/worker_repository.dart';
import '../../features/snow_worker/domain/usecases/get_available_jobs_usecase.dart';
import '../../features/snow_worker/domain/usecases/get_my_jobs_usecase.dart';
import '../../features/snow_worker/domain/usecases/get_job_history_usecase.dart';
import '../../features/snow_worker/domain/usecases/get_worker_stats_usecase.dart';
import '../../features/snow_worker/domain/usecases/toggle_availability_usecase.dart';
import '../../features/snow_worker/domain/usecases/job_actions_usecase.dart';
import '../../features/snow_worker/presentation/bloc/worker_jobs_bloc.dart';
import '../../features/snow_worker/presentation/bloc/worker_stats_bloc.dart';
import '../../features/snow_worker/presentation/bloc/worker_availability_bloc.dart';

// Admin
import '../../features/admin/data/datasources/admin_remote_datasource.dart';
import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/admin/presentation/bloc/admin_bloc.dart';

// Settings
import '../../features/settings/data/datasources/settings_remote_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/get_preferences_usecase.dart';
import '../../features/settings/domain/usecases/update_preferences_usecase.dart';
import '../../features/settings/domain/usecases/delete_account_usecase.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';

// Support
import '../../features/support/data/datasources/support_remote_datasource.dart';
import '../../features/support/data/repositories/support_repository_impl.dart';
import '../../features/support/domain/repositories/support_repository.dart';
import '../../features/support/domain/usecases/submit_support_request_usecase.dart';
import '../../features/support/presentation/bloc/support_bloc.dart';

// Services
import '../services/tax_service.dart';
import '../services/dispute_service.dart';
import '../services/connectivity_service.dart';
import '../services/cache_service.dart';
import '../services/locale_service.dart';

// BLoCs
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/reservation/presentation/bloc/new_reservation_bloc.dart';

final sl = GetIt.instance; // sl = Service Locator

/// Initialise toutes les dépendances de l'application
Future<void> initializeDependencies() async {
  //! Core
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  sl.registerLazySingleton<LocationService>(() => LocationService());
  sl.registerLazySingleton<DioClient>(
      () => DioClient(secureStorage: sl(), localeService: sl()));
  sl.registerLazySingleton<Dio>(() => sl<DioClient>().dio);
  sl.registerLazySingleton<PushNotificationService>(
      () => PushNotificationService());
  sl.registerLazySingleton<SocketService>(() => SocketService());
  sl.registerLazySingleton<AnalyticsService>(() => AnalyticsService.instance);

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  //! Cache & Offline
  sl.registerLazySingleton<NetworkStatus>(() => NetworkStatus());
  sl.registerLazySingleton<ReservationCache>(() => ReservationCache());
  sl.registerLazySingleton<SyncQueue>(() => SyncQueue());
  sl.registerLazySingleton<SyncService>(() => SyncService());

  //! Services
  sl.registerLazySingleton<TaxService>(() => TaxService());
  sl.registerLazySingleton<DisputeService>(
    () => DisputeService(dioClient: sl()),
  );
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerLazySingleton<ApiCacheService>(() => ApiCacheService());
  sl.registerLazySingleton<LocaleService>(() => LocaleService());

  //! Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl(), secureStorage: sl()),
  );
  sl.registerLazySingleton<ReservationRemoteDataSource>(
    () => ReservationRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<WeatherRemoteDatasource>(
    () => WeatherRemoteDatasourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<WorkerRemoteDataSource>(
    () => WorkerRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AdminRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<VerificationRemoteDatasource>(
    () => VerificationRemoteDatasourceImpl(dio: sl()),
  );

  //! Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ReservationRepository>(
    () => ReservationRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<WeatherRepository>(
    () => WeatherRepositoryImpl(remoteDatasource: sl()),
  );
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<WorkerRepository>(
    () => WorkerRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<VerificationRepository>(
    () => VerificationRepositoryImpl(remoteDatasource: sl()),
  );

  //! Use cases
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => GetVehiclesUseCase(sl()));
  sl.registerLazySingleton(() => GetParkingSpotsUseCase(sl()));
  sl.registerLazySingleton(() => CreateReservationUseCase(sl()));
  sl.registerLazySingleton(() => GetReservationsUseCase(sl()));
  sl.registerLazySingleton(() => GetReservationByIdUseCase(sl()));
  sl.registerLazySingleton(() => AddVehicleUseCase(sl()));
  sl.registerLazySingleton(() => DeleteVehicleUseCase(sl()));
  sl.registerLazySingleton(() => CancelReservationUseCase(sl()));
  sl.registerLazySingleton(() => UpdateReservationUseCase(sl()));
  sl.registerLazySingleton(() => GetWeatherUseCase(
        repository: sl(),
        locationService: sl(),
      ));
  sl.registerLazySingleton(() => GetPaymentHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetPaymentMethodsUseCase(sl()));
  sl.registerLazySingleton(() => SavePaymentMethodUseCase(sl()));
  sl.registerLazySingleton(() => DeletePaymentMethodUseCase(sl()));
  sl.registerLazySingleton(() => SetDefaultPaymentMethodUseCase(sl()));
  sl.registerLazySingleton(() => ProcessRefundUseCase(sl()));
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => GetUnreadCountUseCase(sl()));
  sl.registerLazySingleton(() => MarkAsReadUseCase(sl()));
  sl.registerLazySingleton(() => MarkAllAsReadUseCase(sl()));
  sl.registerLazySingleton(() => DeleteNotificationUseCase(sl()));
  sl.registerLazySingleton(() => ClearAllNotificationsUseCase(sl()));

  // Worker use cases
  sl.registerLazySingleton(() => GetAvailableJobsUseCase(sl()));
  sl.registerLazySingleton(() => GetMyJobsUseCase(sl()));
  sl.registerLazySingleton(() => GetJobHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetWorkerStatsUseCase(sl()));
  sl.registerLazySingleton(() => GetEarningsUseCase(sl()));
  sl.registerLazySingleton(() => ToggleAvailabilityUseCase(sl()));
  sl.registerLazySingleton(() => UpdateLocationUseCase(sl()));
  sl.registerLazySingleton(() => AcceptJobUseCase(sl()));
  sl.registerLazySingleton(() => MarkEnRouteUseCase(sl()));
  sl.registerLazySingleton(() => StartJobUseCase(sl()));
  sl.registerLazySingleton(() => CompleteJobUseCase(sl()));
  sl.registerLazySingleton(() => UploadJobPhotoUseCase(sl()));
  sl.registerLazySingleton(() => CancelJobUseCase(sl()));
  sl.registerLazySingleton(() => GetCancellationReasonsUseCase(sl()));

  // Weather forecast
  sl.registerLazySingleton(() => GetWeatherForecastUseCase(sl()));

  //! BLoCs
  // AuthBloc doit être un singleton pour maintenir l'état d'authentification
  // cohérent dans toute l'application
  sl.registerLazySingleton(() => AuthBloc(
        login: sl(),
        register: sl(),
        logout: sl(),
        getCurrentUser: sl(),
        forgotPassword: sl(),
        resetPassword: sl(),
        updateProfile: sl(),
        authRepository: sl(),
      ));

  sl.registerFactory(() => NewReservationBloc(
        getVehicles: sl(),
        getParkingSpots: sl(),
        createReservation: sl(),
      ));

  sl.registerFactory(
    () => VehicleBloc(
      getVehicles: sl(),
      addVehicle: sl(),
      deleteVehicle: sl(),
      repository: sl(),
    ),
  );

  sl.registerFactory(() => ReservationListBloc(
        getReservations: sl(),
        getReservationById: sl(),
        cancelReservation: sl(),
      ));

  sl.registerFactory(() => EditReservationBloc(
        getVehicles: sl(),
        getParkingSpots: sl(),
        updateReservation: sl(),
      ));

  sl.registerFactory(() => HomeBloc(
        getCurrentUser: sl(),
        getWeather: sl(),
        getReservations: sl(),
      ));

  sl.registerFactory(() => PaymentHistoryBloc(
        getPaymentHistory: sl(),
      ));

  sl.registerFactory(() => PaymentMethodsBloc(
        getPaymentMethods: sl(),
        savePaymentMethod: sl(),
        deletePaymentMethod: sl(),
        setDefaultPaymentMethod: sl(),
      ));

  sl.registerFactory(() => RefundBloc(
        processRefund: sl(),
      ));

  sl.registerFactory(() => NotificationBloc(
        getNotifications: sl(),
        getUnreadCount: sl(),
        markAsRead: sl(),
        markAllAsRead: sl(),
        deleteNotification: sl(),
        clearAllNotifications: sl(),
      ));

  // Worker BLoCs
  sl.registerFactory(() => WorkerJobsBloc(
        getAvailableJobsUseCase: sl(),
        getMyJobsUseCase: sl(),
        getJobHistoryUseCase: sl(),
        acceptJobUseCase: sl(),
        markEnRouteUseCase: sl(),
        startJobUseCase: sl(),
        completeJobUseCase: sl(),
        cancelJobUseCase: sl(),
      ));

  sl.registerFactory(() => WorkerStatsBloc(
        getWorkerStatsUseCase: sl(),
        getEarningsUseCase: sl(),
      ));

  sl.registerFactory(() => WorkerAvailabilityBloc(
        toggleAvailabilityUseCase: sl(),
        updateLocationUseCase: sl(),
        repository: sl(),
      ));

  // Admin BLoC
  sl.registerFactory(() => AdminBloc(
        repository: sl(),
      ));

  // Verification BLoC
  sl.registerFactory(() => VerificationBloc(
        repository: sl(),
      ));

  sl.registerFactory(() => ChatBloc(
        repository: sl(),
        socketService: sl(),
      ));

  //! Settings Feature
  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetPreferencesUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePreferencesUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAccountUseCase(sl()));
  sl.registerFactory(() => SettingsBloc(
        getPreferences: sl(),
        updatePreferences: sl(),
        deleteAccount: sl(),
      ));

  //! Support Feature
  sl.registerLazySingleton<SupportRemoteDataSource>(
    () => SupportRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<SupportRepository>(
    () => SupportRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => SubmitSupportRequestUseCase(sl()));
  sl.registerFactory(() => SupportBloc(
        submitSupportRequest: sl(),
      ));

  // =============== AI CHAT ===============
  sl.registerLazySingleton<AIChatRemoteDataSource>(
    () => AIChatRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<AIChatRepository>(
    () => AIChatRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => SendAIMessageUseCase(sl()));
  sl.registerLazySingleton(() => CreateConversationUseCase(sl()));
  sl.registerLazySingleton(() => GetConversationsUseCase(sl()));
  sl.registerLazySingleton(() => GetAIStatusUseCase(sl()));
  sl.registerLazySingleton(() => DeleteConversationUseCase(sl()));
  sl.registerFactory(() => AIChatBloc(
        repository: sl(),
        sendAIMessage: sl(),
        createConversation: sl(),
        getConversations: sl(),
        getAIStatus: sl(),
      ));

  // =============== AI FEATURES ===============
  sl.registerLazySingleton<AIFeaturesRemoteDataSource>(
    () => AIFeaturesRemoteDataSource(dio: sl()),
  );
  sl.registerLazySingleton<AIFeaturesRepository>(
    () => AIFeaturesRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory(() => AIFeaturesBloc(repository: sl()));
}
