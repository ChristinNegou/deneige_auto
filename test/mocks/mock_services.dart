import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/core/services/push_notification_service.dart';
import 'package:deneige_auto/core/services/analytics_service.dart';
import 'package:deneige_auto/core/services/socket_service.dart';
import 'package:deneige_auto/service/secure_storage_service.dart';

/// Mock pour PushNotificationService
class MockPushNotificationService extends Mock implements PushNotificationService {}

/// Mock pour AnalyticsService
class MockAnalyticsService extends Mock implements AnalyticsService {}

/// Mock pour SocketService
class MockSocketService extends Mock implements SocketService {}

/// Mock pour SecureStorageService
class MockSecureStorageService extends Mock implements SecureStorageService {}
