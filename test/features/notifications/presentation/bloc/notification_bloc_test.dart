import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/notifications/presentation/bloc/notification_bloc.dart';

import '../../../../mocks/mock_usecases.dart';
import '../../../../fixtures/notification_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late NotificationBloc bloc;
  late MockGetNotificationsUseCase mockGetNotifications;
  late MockGetUnreadCountUseCase mockGetUnreadCount;
  late MockMarkAsReadUseCase mockMarkAsRead;
  late MockMarkAllAsReadUseCase mockMarkAllAsRead;
  late MockDeleteNotificationUseCase mockDeleteNotification;
  late MockClearAllNotificationsUseCase mockClearAllNotifications;

  setUp(() {
    mockGetNotifications = MockGetNotificationsUseCase();
    mockGetUnreadCount = MockGetUnreadCountUseCase();
    mockMarkAsRead = MockMarkAsReadUseCase();
    mockMarkAllAsRead = MockMarkAllAsReadUseCase();
    mockDeleteNotification = MockDeleteNotificationUseCase();
    mockClearAllNotifications = MockClearAllNotificationsUseCase();
    bloc = NotificationBloc(
      getNotifications: mockGetNotifications,
      getUnreadCount: mockGetUnreadCount,
      markAsRead: mockMarkAsRead,
      markAllAsRead: mockMarkAllAsRead,
      deleteNotification: mockDeleteNotification,
      clearAllNotifications: mockClearAllNotifications,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('NotificationBloc', () {
    final tNotifications = NotificationFixtures.createList(5);
    final tMixedNotifications = NotificationFixtures.createMixedList();

    group('LoadNotifications', () {
      blocTest<NotificationBloc, NotificationState>(
        'emits [loading, loaded] when LoadNotifications succeeds',
        build: () {
          when(() => mockGetNotifications())
              .thenAnswer((_) async => Right(tNotifications));
          when(() => mockGetUnreadCount())
              .thenAnswer((_) async => const Right(3));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadNotifications()),
        expect: () => [
          isA<NotificationState>().having((s) => s.isLoading, 'isLoading', true),
          isA<NotificationState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.notifications.length, 'notifications.length', 5)
              .having((s) => s.unreadCount, 'unreadCount', 3)
              .having((s) => s.errorMessage, 'errorMessage', null),
        ],
        verify: (_) {
          verify(() => mockGetNotifications()).called(1);
          verify(() => mockGetUnreadCount()).called(1);
        },
      );

      blocTest<NotificationBloc, NotificationState>(
        'emits [loading, error] when LoadNotifications fails',
        build: () {
          when(() => mockGetNotifications())
              .thenAnswer((_) async => const Left(serverFailure));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadNotifications()),
        expect: () => [
          isA<NotificationState>().having((s) => s.isLoading, 'isLoading', true),
          isA<NotificationState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );
    });

    group('RefreshNotifications', () {
      blocTest<NotificationBloc, NotificationState>(
        'emits updated notifications when RefreshNotifications succeeds',
        build: () {
          when(() => mockGetNotifications())
              .thenAnswer((_) async => Right(tNotifications));
          when(() => mockGetUnreadCount())
              .thenAnswer((_) async => const Right(2));
          return bloc;
        },
        act: (bloc) => bloc.add(RefreshNotifications()),
        expect: () => [
          isA<NotificationState>()
              .having((s) => s.notifications.length, 'notifications.length', 5)
              .having((s) => s.unreadCount, 'unreadCount', 2),
        ],
      );
    });

    group('MarkNotificationAsRead', () {
      blocTest<NotificationBloc, NotificationState>(
        'marks notification as read when succeeds',
        build: () {
          when(() => mockMarkAsRead('notif-1'))
              .thenAnswer((_) async => const Right(null));
          return bloc;
        },
        seed: () => NotificationState(
          notifications: tMixedNotifications,
          unreadCount: 3,
        ),
        act: (bloc) => bloc.add(MarkNotificationAsRead('notif-1')),
        expect: () => [
          isA<NotificationState>()
              .having((s) => s.notifications.firstWhere((n) => n.id == 'notif-1').isRead,
                      'notif-1 isRead', true),
        ],
        verify: (_) {
          verify(() => mockMarkAsRead('notif-1')).called(1);
        },
      );

      blocTest<NotificationBloc, NotificationState>(
        'emits error when MarkNotificationAsRead fails',
        build: () {
          when(() => mockMarkAsRead('notif-1'))
              .thenAnswer((_) async => const Left(serverFailure));
          return bloc;
        },
        seed: () => NotificationState(
          notifications: tMixedNotifications,
          unreadCount: 3,
        ),
        act: (bloc) => bloc.add(MarkNotificationAsRead('notif-1')),
        expect: () => [
          isA<NotificationState>()
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );
    });

    group('MarkAllNotificationsAsRead', () {
      blocTest<NotificationBloc, NotificationState>(
        'marks all notifications as read when succeeds',
        build: () {
          when(() => mockMarkAllAsRead())
              .thenAnswer((_) async => const Right(null));
          return bloc;
        },
        seed: () => NotificationState(
          notifications: tMixedNotifications,
          unreadCount: 3,
        ),
        act: (bloc) => bloc.add(MarkAllNotificationsAsRead()),
        expect: () => [
          isA<NotificationState>()
              .having((s) => s.unreadCount, 'unreadCount', 0)
              .having((s) => s.notifications.every((n) => n.isRead), 'all read', true)
              .having((s) => s.successMessage, 'successMessage', isNotNull),
        ],
      );
    });

    group('DeleteNotification', () {
      blocTest<NotificationBloc, NotificationState>(
        'deletes notification when succeeds',
        build: () {
          when(() => mockDeleteNotification('notif-1'))
              .thenAnswer((_) async => const Right(null));
          return bloc;
        },
        seed: () => NotificationState(
          notifications: tMixedNotifications,
          unreadCount: 3,
        ),
        act: (bloc) => bloc.add(DeleteNotification('notif-1')),
        expect: () => [
          isA<NotificationState>()
              .having((s) => s.notifications.any((n) => n.id == 'notif-1'),
                      'notif-1 deleted', false),
        ],
        verify: (_) {
          verify(() => mockDeleteNotification('notif-1')).called(1);
        },
      );

      blocTest<NotificationBloc, NotificationState>(
        'emits error when DeleteNotification fails',
        build: () {
          when(() => mockDeleteNotification('notif-1'))
              .thenAnswer((_) async => const Left(serverFailure));
          return bloc;
        },
        seed: () => NotificationState(
          notifications: tMixedNotifications,
          unreadCount: 3,
        ),
        act: (bloc) => bloc.add(DeleteNotification('notif-1')),
        expect: () => [
          isA<NotificationState>()
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );
    });

    group('ClearAllNotifications', () {
      blocTest<NotificationBloc, NotificationState>(
        'clears all notifications when succeeds',
        build: () {
          when(() => mockClearAllNotifications())
              .thenAnswer((_) async => const Right(null));
          return bloc;
        },
        seed: () => NotificationState(
          notifications: tMixedNotifications,
          unreadCount: 3,
        ),
        act: (bloc) => bloc.add(ClearAllNotifications()),
        expect: () => [
          isA<NotificationState>()
              .having((s) => s.notifications, 'notifications', isEmpty)
              .having((s) => s.unreadCount, 'unreadCount', 0)
              .having((s) => s.successMessage, 'successMessage', isNotNull),
        ],
      );
    });

    group('UpdateAutoDeleteSetting', () {
      blocTest<NotificationBloc, NotificationState>(
        'enables auto delete setting',
        build: () => bloc,
        act: (bloc) => bloc.add(UpdateAutoDeleteSetting(enabled: true, delaySeconds: 5)),
        expect: () => [
          isA<NotificationState>()
              .having((s) => s.autoDeleteEnabled, 'autoDeleteEnabled', true)
              .having((s) => s.autoDeleteDelaySeconds, 'autoDeleteDelaySeconds', 5)
              .having((s) => s.successMessage, 'successMessage', contains('activée')),
        ],
      );

      blocTest<NotificationBloc, NotificationState>(
        'disables auto delete setting',
        build: () => bloc,
        seed: () => const NotificationState(autoDeleteEnabled: true),
        act: (bloc) => bloc.add(UpdateAutoDeleteSetting(enabled: false)),
        expect: () => [
          isA<NotificationState>()
              .having((s) => s.autoDeleteEnabled, 'autoDeleteEnabled', false)
              .having((s) => s.successMessage, 'successMessage', contains('désactivée')),
        ],
      );
    });

    group('State helpers', () {
      test('unreadNotifications returns correct list', () {
        final state = NotificationState(notifications: tMixedNotifications);
        expect(state.unreadNotifications.every((n) => !n.isRead), true);
      });

      test('readNotifications returns correct list', () {
        final state = NotificationState(notifications: tMixedNotifications);
        expect(state.readNotifications.every((n) => n.isRead), true);
      });
    });
  });
}
