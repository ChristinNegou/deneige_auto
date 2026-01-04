import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:deneige_auto/features/reservation/data/datasources/reservation_remote_datasource.dart';
import 'package:deneige_auto/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:deneige_auto/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:deneige_auto/features/snow_worker/data/datasources/worker_remote_datasource.dart';

// ==================== AUTH DATASOURCES ====================
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

// ==================== RESERVATION DATASOURCES ====================
class MockReservationRemoteDataSource extends Mock
    implements ReservationRemoteDataSource {}

// ==================== PAYMENT DATASOURCES ====================
class MockPaymentRemoteDataSource extends Mock
    implements PaymentRemoteDataSource {}

// ==================== NOTIFICATION DATASOURCES ====================
class MockNotificationRemoteDataSource extends Mock
    implements NotificationRemoteDataSource {}

// ==================== WORKER DATASOURCES ====================
class MockWorkerRemoteDataSource extends Mock
    implements WorkerRemoteDataSource {}
