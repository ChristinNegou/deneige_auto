import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/notifications/domain/usecases/get_unread_count_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late GetUnreadCountUseCase usecase;
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
    usecase = GetUnreadCountUseCase(mockRepository);
  });

  group('GetUnreadCountUseCase', () {
    test('should return unread count when successful', () async {
      // Arrange
      when(() => mockRepository.getUnreadCount())
          .thenAnswer((_) async => const Right(5));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Right(5));
      verify(() => mockRepository.getUnreadCount()).called(1);
    });

    test('should return zero when no unread notifications', () async {
      // Arrange
      when(() => mockRepository.getUnreadCount())
          .thenAnswer((_) async => const Right(0));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (count) => expect(count, 0),
      );
    });

    test('should return high unread count', () async {
      // Arrange
      when(() => mockRepository.getUnreadCount())
          .thenAnswer((_) async => const Right(99));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (count) => expect(count, 99),
      );
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.getUnreadCount())
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return NetworkFailure on connection error', () async {
      // Arrange
      when(() => mockRepository.getUnreadCount())
          .thenAnswer((_) async => const Left(networkFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(networkFailure));
    });
  });
}
