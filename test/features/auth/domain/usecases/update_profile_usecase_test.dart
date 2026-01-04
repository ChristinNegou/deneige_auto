import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/auth/domain/usecases/update_profile_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/user_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late UpdateProfileUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = UpdateProfileUseCase(mockRepository);
  });

  group('UpdateProfileUseCase', () {
    final tUser = UserFixtures.createClient();
    const tFirstName = 'Jean-Pierre';
    const tLastName = 'Tremblay';
    const tPhoneNumber = '+1999999999';
    const tPhotoUrl = 'https://example.com/photo.jpg';

    test('should return updated User when profile is updated successfully', () async {
      // Arrange
      final updatedUser = UserFixtures.createClient(
        name: '$tFirstName $tLastName',
        phoneNumber: tPhoneNumber,
      );
      when(() => mockRepository.updateProfile(
        firstName: tFirstName,
        lastName: tLastName,
        phoneNumber: tPhoneNumber,
        photoUrl: tPhotoUrl,
      )).thenAnswer((_) async => Right(updatedUser));

      // Act
      final params = UpdateProfileParams(
        firstName: tFirstName,
        lastName: tLastName,
        phoneNumber: tPhoneNumber,
        photoUrl: tPhotoUrl,
      );
      final result = await usecase(params);

      // Assert
      expect(result, Right(updatedUser));
      verify(() => mockRepository.updateProfile(
        firstName: tFirstName,
        lastName: tLastName,
        phoneNumber: tPhoneNumber,
        photoUrl: tPhotoUrl,
      )).called(1);
    });

    test('should update only firstName when other fields are null', () async {
      // Arrange
      when(() => mockRepository.updateProfile(
        firstName: tFirstName,
        lastName: null,
        phoneNumber: null,
        photoUrl: null,
      )).thenAnswer((_) async => Right(tUser));

      // Act
      final params = UpdateProfileParams(firstName: tFirstName);
      final result = await usecase(params);

      // Assert
      expect(result, Right(tUser));
      verify(() => mockRepository.updateProfile(
        firstName: tFirstName,
        lastName: null,
        phoneNumber: null,
        photoUrl: null,
      )).called(1);
    });

    test('should update only phoneNumber', () async {
      // Arrange
      when(() => mockRepository.updateProfile(
        firstName: null,
        lastName: null,
        phoneNumber: tPhoneNumber,
        photoUrl: null,
      )).thenAnswer((_) async => Right(tUser));

      // Act
      final params = UpdateProfileParams(phoneNumber: tPhoneNumber);
      final result = await usecase(params);

      // Assert
      expect(result, Right(tUser));
    });

    test('should return AuthFailure when not authenticated', () async {
      // Arrange
      when(() => mockRepository.updateProfile(
        firstName: tFirstName,
        lastName: null,
        phoneNumber: null,
        photoUrl: null,
      )).thenAnswer((_) async => const Left(authFailure));

      // Act
      final params = UpdateProfileParams(firstName: tFirstName);
      final result = await usecase(params);

      // Assert
      expect(result, const Left(authFailure));
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.updateProfile(
        firstName: tFirstName,
        lastName: null,
        phoneNumber: null,
        photoUrl: null,
      )).thenAnswer((_) async => const Left(serverFailure));

      // Act
      final params = UpdateProfileParams(firstName: tFirstName);
      final result = await usecase(params);

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('UpdateProfileParams toJson should only include non-null values', () {
      // Arrange
      final paramsWithAll = UpdateProfileParams(
        firstName: tFirstName,
        lastName: tLastName,
        phoneNumber: tPhoneNumber,
        photoUrl: tPhotoUrl,
      );

      final paramsWithSome = UpdateProfileParams(
        firstName: tFirstName,
      );

      // Act
      final jsonAll = paramsWithAll.toJson();
      final jsonSome = paramsWithSome.toJson();

      // Assert
      expect(jsonAll.length, 4);
      expect(jsonAll['firstName'], tFirstName);
      expect(jsonAll['lastName'], tLastName);
      expect(jsonAll['phoneNumber'], tPhoneNumber);
      expect(jsonAll['photoUrl'], tPhotoUrl);

      expect(jsonSome.length, 1);
      expect(jsonSome['firstName'], tFirstName);
      expect(jsonSome.containsKey('lastName'), false);
    });
  });
}
