import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/auth/domain/usecases/get_current_user_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/user_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late GetCurrentUserUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = GetCurrentUserUseCase(mockRepository);
  });

  group('GetCurrentUserUseCase', () {
    final tUser = UserFixtures.createClient();

    test('should return User when user is authenticated', () async {
      // Arrange
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => Right(tUser));

      // Act
      final result = await usecase();

      // Assert
      expect(result, Right(tUser));
      verify(() => mockRepository.getCurrentUser()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return AuthFailure when user is not authenticated', () async {
      // Arrange
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => const Left(authFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(authFailure));
    });

    test('should return correct user role for worker', () async {
      // Arrange
      final workerUser = UserFixtures.createWorker();
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => Right(workerUser));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (user) => expect(user.role.name, 'snowWorker'),
      );
    });

    test('should return correct user role for admin', () async {
      // Arrange
      final adminUser = UserFixtures.createAdmin();
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => Right(adminUser));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (user) => expect(user.role.name, 'admin'),
      );
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(serverFailure));
    });
  });
}
