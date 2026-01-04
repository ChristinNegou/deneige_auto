import 'package:mocktail/mocktail.dart';

// Auth Use Cases
import 'package:deneige_auto/features/auth/domain/usecases/login_usecase.dart';
import 'package:deneige_auto/features/auth/domain/usecases/register_usecase.dart';
import 'package:deneige_auto/features/auth/domain/usecases/logout_usecase.dart';
import 'package:deneige_auto/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:deneige_auto/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:deneige_auto/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:deneige_auto/features/auth/domain/usecases/update_profile_usecase.dart';

// Reservation Use Cases
import 'package:deneige_auto/features/reservation/domain/usecases/create_reservation_usecase.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/get_reservations_usecase.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/get_reservation_by_id_usecase.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/cancel_reservation_usecase.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/update_reservation_usecase.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/get_vehicules_usecase.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/get_parking_spots_usecase.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/add_vehicle_usecase.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/delete_vehicle_usecase.dart';

// Payment Use Cases
import 'package:deneige_auto/features/payment/domain/usecases/get_payment_history_usecase.dart';
import 'package:deneige_auto/features/payment/domain/usecases/get_payment_methods_usecase.dart';
import 'package:deneige_auto/features/payment/domain/usecases/save_payment_method_usecase.dart';
import 'package:deneige_auto/features/payment/domain/usecases/delete_payment_method_usecase.dart';
import 'package:deneige_auto/features/payment/domain/usecases/set_default_payment_method_usecase.dart';
import 'package:deneige_auto/features/payment/domain/usecases/process_refund_usecase.dart';

// Notification Use Cases
import 'package:deneige_auto/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:deneige_auto/features/notifications/domain/usecases/get_unread_count_usecase.dart';
import 'package:deneige_auto/features/notifications/domain/usecases/mark_as_read_usecase.dart';
import 'package:deneige_auto/features/notifications/domain/usecases/mark_all_as_read_usecase.dart';
import 'package:deneige_auto/features/notifications/domain/usecases/delete_notification_usecase.dart';
import 'package:deneige_auto/features/notifications/domain/usecases/clear_all_notifications_usecase.dart';

// Worker Use Cases
import 'package:deneige_auto/features/snow_worker/domain/usecases/get_available_jobs_usecase.dart';
import 'package:deneige_auto/features/snow_worker/domain/usecases/get_my_jobs_usecase.dart';
import 'package:deneige_auto/features/snow_worker/domain/usecases/toggle_availability_usecase.dart';
import 'package:deneige_auto/features/snow_worker/domain/usecases/get_worker_stats_usecase.dart';

// ==================== AUTH USE CASES ====================
class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
class MockForgotPasswordUseCase extends Mock implements ForgotPasswordUseCase {}
class MockResetPasswordUseCase extends Mock implements ResetPasswordUseCase {}
class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}

// ==================== RESERVATION USE CASES ====================
class MockCreateReservationUseCase extends Mock implements CreateReservationUseCase {}
class MockGetReservationsUseCase extends Mock implements GetReservationsUseCase {}
class MockGetReservationByIdUseCase extends Mock implements GetReservationByIdUseCase {}
class MockCancelReservationUseCase extends Mock implements CancelReservationUseCase {}
class MockUpdateReservationUseCase extends Mock implements UpdateReservationUseCase {}
class MockGetVehiclesUseCase extends Mock implements GetVehiclesUseCase {}
class MockGetParkingSpotsUseCase extends Mock implements GetParkingSpotsUseCase {}
class MockAddVehicleUseCase extends Mock implements AddVehicleUseCase {}
class MockDeleteVehicleUseCase extends Mock implements DeleteVehicleUseCase {}

// ==================== PAYMENT USE CASES ====================
class MockGetPaymentHistoryUseCase extends Mock implements GetPaymentHistoryUseCase {}
class MockGetPaymentMethodsUseCase extends Mock implements GetPaymentMethodsUseCase {}
class MockSavePaymentMethodUseCase extends Mock implements SavePaymentMethodUseCase {}
class MockDeletePaymentMethodUseCase extends Mock implements DeletePaymentMethodUseCase {}
class MockSetDefaultPaymentMethodUseCase extends Mock implements SetDefaultPaymentMethodUseCase {}
class MockProcessRefundUseCase extends Mock implements ProcessRefundUseCase {}

// ==================== NOTIFICATION USE CASES ====================
class MockGetNotificationsUseCase extends Mock implements GetNotificationsUseCase {}
class MockGetUnreadCountUseCase extends Mock implements GetUnreadCountUseCase {}
class MockMarkAsReadUseCase extends Mock implements MarkAsReadUseCase {}
class MockMarkAllAsReadUseCase extends Mock implements MarkAllAsReadUseCase {}
class MockDeleteNotificationUseCase extends Mock implements DeleteNotificationUseCase {}
class MockClearAllNotificationsUseCase extends Mock implements ClearAllNotificationsUseCase {}

// ==================== WORKER USE CASES ====================
class MockGetAvailableJobsUseCase extends Mock implements GetAvailableJobsUseCase {}
class MockGetMyJobsUseCase extends Mock implements GetMyJobsUseCase {}
class MockToggleAvailabilityUseCase extends Mock implements ToggleAvailabilityUseCase {}
class MockGetWorkerStatsUseCase extends Mock implements GetWorkerStatsUseCase {}
