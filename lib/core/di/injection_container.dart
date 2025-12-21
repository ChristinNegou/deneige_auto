
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Config
import '../../features/auth/domain/usecases/reset_password_usecase.dart';
import '../../features/auth/domain/usecases/update_profile_usecase.dart';
import '../../features/reservation/domain/usecases/add_vehicle_usecase.dart';
import '../../features/reservation/domain/usecases/get_parking_spots_usecase.dart';
import '../../features/reservation/domain/usecases/get_vehicules_usecase.dart';
import '../../features/reservation/domain/usecases/update_reservation_usecase.dart';
import '../../features/reservation/presentation/bloc/reservation_list_bloc.dart';
import '../../features/reservation/presentation/bloc/edit_reservation_bloc.dart';
import '../../features/vehicule/presentation/bloc/vehicule_bloc.dart';
import '../../service/secure_storage_service.dart';
import '../network/dio_client.dart';
import '../services/location_service.dart';


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

// Reservation
import '../../features/reservation/data/datasources/reservation_remote_datasource.dart';
import '../../features/reservation/data/repositories/reservation_repository_impl.dart';
import '../../features/reservation/domain/repositories/reservation_repository.dart';
import '../../features/reservation/domain/usecases/cancel_reservation_usecase.dart';
import '../../features/reservation/domain/usecases/create_reservation_usecase.dart';
import '../../features/reservation/domain/usecases/get_reservations_usecase.dart';

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
  sl.registerLazySingleton<DioClient>(() => DioClient(secureStorage: sl()));
  sl.registerLazySingleton<Dio>(() => sl<DioClient>().dio);

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

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
  sl.registerLazySingleton(() => AddVehicleUseCase(sl()));
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

  //! BLoCs
  sl.registerFactory(() => AuthBloc(
    login: sl(),
    register: sl(),
    logout: sl(),
    getCurrentUser: sl(),
    forgotPassword: sl(),
    resetPassword: sl(),
    updateProfile: sl(),
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
    ),
  );


  sl.registerFactory(() => ReservationListBloc(
    getReservations: sl(),
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
}