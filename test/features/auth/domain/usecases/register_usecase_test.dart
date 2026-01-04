import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/auth/domain/usecases/register_usecase.dart';
import 'package:deneige_auto/features/auth/domain/entities/user.dart';
import 'package:deneige_auto/core/errors/failures.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/user_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late RegisterUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = RegisterUseCase(mockRepository);
  });

  group('RegisterUseCase', () {
    const tEmail = 'newuser@example.com';
    const tPassword = 'password123';
    const tFirstName = 'Jean';
    const tLastName = 'Dupont';
    const tPhone = '+1234567890';
    final tUser = UserFixtures.createClient(
      email: tEmail,
      name: '$tFirstName $tLastName',
    );

    test('should return User when registration is successful', () async {
      // Arrange
      when(() => mockRepository.register(
        tEmail,
        tPassword,
        '$tFirstName $tLastName',
        phone: tPhone,
        role: UserRole.client,
      )).thenAnswer((_) async => Right(tUser));

      // Act
      final result = await usecase(
        email: tEmail,
        password: tPassword,
        firstName: tFirstName,
        lastName: tLastName,
        phone: tPhone,
        role: UserRole.client,
      );

      // Assert
      expect(result, Right(tUser));
      verify(() => mockRepository.register(
        tEmail,
        tPassword,
        '$tFirstName $tLastName',
        phone: tPhone,
        role: UserRole.client,
      )).called(1);
    });

    test('should register worker role correctly', () async {
      // Arrange
      final workerUser = UserFixtures.createWorker(email: tEmail);
      when(() => mockRepository.register(
        tEmail,
        tPassword,
        '$tFirstName $tLastName',
        phone: tPhone,
        role: UserRole.snowWorker,
      )).thenAnswer((_) async => Right(workerUser));

      // Act
      final result = await usecase(
        email: tEmail,
        password: tPassword,
        firstName: tFirstName,
        lastName: tLastName,
        phone: tPhone,
        role: UserRole.snowWorker,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (user) => expect(user.role, UserRole.snowWorker),
      );
    });

    test('should register without phone number', () async {
      // Arrange
      when(() => mockRepository.register(
        tEmail,
        tPassword,
        '$tFirstName $tLastName',
        phone: null,
        role: UserRole.client,
      )).thenAnswer((_) async => Right(tUser));

      // Act
      final result = await usecase(
        email: tEmail,
        password: tPassword,
        firstName: tFirstName,
        lastName: tLastName,
        phone: null,
        role: UserRole.client,
      );

      // Assert
      expect(result, Right(tUser));
    });

    test('should return ValidationFailure when email already exists', () async {
      // Arrange
      const failure = ValidationFailure(message: 'Cet email est deja utilise');
      when(() => mockRepository.register(
        tEmail,
        tPassword,
        '$tFirstName $tLastName',
        phone: tPhone,
        role: UserRole.client,
      )).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await usecase(
        email: tEmail,
        password: tPassword,
        firstName: tFirstName,
        lastName: tLastName,
        phone: tPhone,
        role: UserRole.client,
      );

      // Assert
      expect(result, const Left(failure));
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.register(
        tEmail,
        tPassword,
        '$tFirstName $tLastName',
        phone: tPhone,
        role: UserRole.client,
      )).thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase(
        email: tEmail,
        password: tPassword,
        firstName: tFirstName,
        lastName: tLastName,
        phone: tPhone,
        role: UserRole.client,
      );

      // Assert
      expect(result, const Left(serverFailure));
    });
  });
}
