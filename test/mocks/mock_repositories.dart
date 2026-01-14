import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/auth/domain/repositories/auth_repository.dart';
import 'package:deneige_auto/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:deneige_auto/features/payment/domain/repositories/payment_repository.dart';
import 'package:deneige_auto/features/notifications/domain/repositories/notification_repository.dart';
import 'package:deneige_auto/features/snow_worker/domain/repositories/worker_repository.dart';
import 'package:deneige_auto/service/secure_storage_service.dart';

/// Mock pour AuthRepository
class MockAuthRepository extends Mock implements AuthRepository {}

/// Mock pour SecureStorageService
class MockSecureStorageService extends Mock implements SecureStorageService {}

/// Mock pour ReservationRepository
class MockReservationRepository extends Mock implements ReservationRepository {}

/// Mock pour PaymentRepository
class MockPaymentRepository extends Mock implements PaymentRepository {}

/// Mock pour NotificationRepository
class MockNotificationRepository extends Mock
    implements NotificationRepository {}

/// Mock pour WorkerRepository
class MockWorkerRepository extends Mock implements WorkerRepository {}
