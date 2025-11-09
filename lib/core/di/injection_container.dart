
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Config
import '../../features/auth/domain/usecases/reset_password_usecase.dart';
import '../../service/secure_storage_service.dart';
import '../config/app_config.dart';
import '../network/dio_client.dart';

// Auth
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/forgot_password_usecase.dart'; // ✅ Ajouté
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';

// Home/Weather
import '../../features/home/data/datasources/weather_remote_datasource.dart';
import '../../features/home/data/repositories/weather_repository_impl.dart';
import '../../features/home/domain/repositories/weather_repository.dart';
import '../../features/home/domain/usecases/get_weather_usecase.dart';

// Reservation
import '../../features/reservation/data/datasources/reservation_remote_datasource.dart';
import '../../features/reservation/data/repositories/reservation_repository_impl.dart';
import '../../features/reservation/domain/repositories/reservation_repository.dart';
import '../../features/reservation/domain/usecases/cancel_reservation_usecase.dart';
import '../../features/reservation/domain/usecases/create_reservation_usecase.dart';
import '../../features/reservation/domain/usecases/get_reservations_usecase.dart';

// BLoCs
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/reservation/presentation/bloc/reservation_bloc.dart';

final sl = GetIt.instance; // sl = Service Locator

/// Initialise toutes les dépendances de l'application
Future<void> initializeDependencies() async {
  //! Core

  // Secure Storage
  sl.registerLazySingleton<SecureStorageService>(
        () => SecureStorageService(),
  );

  // Dio Client
  sl.registerLazySingleton<DioClient>(
        () => DioClient(secureStorage: sl()),
  );

  // Dio pour les appels HTTP
  sl.registerLazySingleton<Dio>(() => sl<DioClient>().dio);

  // SharedPreferences pour le stockage local
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  //! Auth Feature
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(
      dio: sl(),
      secureStorage: sl(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));

  // BLoC
  sl.registerFactory(() => AuthBloc(
    login: sl(),
    register: sl(),
    logout: sl(),
    getCurrentUser: sl(),
    forgotPassword: sl(),
    resetPassword: sl(),
  ));

  //! Home/Weather Feature
  // Data sources
  sl.registerLazySingleton<WeatherRemoteDataSource>(
        () => WeatherRemoteDataSourceImpl(
      dio: sl(),
      apiKey: AppConfig.openWeatherMapApiKey,
    ),
  );

  // Repositories
  sl.registerLazySingleton<WeatherRepository>(
        () => WeatherRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetWeatherUseCase(sl()));

  //! Reservation Feature
  // Data sources
  sl.registerLazySingleton<ReservationRemoteDataSource>(
        () => ReservationRemoteDataSourceImpl(dio: sl()),
  );

  // Repositories
  sl.registerLazySingleton<ReservationRepository>(
        () => ReservationRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetReservationsUseCase(sl()));
  sl.registerLazySingleton(() => CreateReservationUseCase(sl()));
  sl.registerLazySingleton(() => CancelReservationUseCase(sl()));

  // BLoC
  sl.registerFactory(() => ReservationBloc(
    getReservations: sl(),
    createReservation: sl(),
    cancelReservation: sl(),
  ));

  //! Home BLoC (nécessite plusieurs use cases)
  sl.registerFactory(() => HomeBloc(
    getCurrentUser: sl(),
    getWeather: sl(),
    getReservations: sl(),
  ));
}