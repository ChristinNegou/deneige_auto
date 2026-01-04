import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/auth/domain/usecases/logout_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late LogoutUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = LogoutUseCase(mockRepository);
  });

  group('LogoutUseCase', () {
    test('should return void when logout is successful', () async {
      // Arrange
      when(() => mockRepository.logout())
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Right(null));
      verify(() => mockRepository.logout()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when logout fails', () async {
      // Arrange
      when(() => mockRepository.logout())
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return NetworkFailure when no connection', () async {
      // Arrange
      when(() => mockRepository.logout())
          .thenAnswer((_) async => const Left(networkFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(networkFailure));
    });
  });
}
