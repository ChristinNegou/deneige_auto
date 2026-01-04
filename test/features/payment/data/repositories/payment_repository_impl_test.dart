import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/core/errors/exceptions.dart';
import 'package:deneige_auto/core/errors/failures.dart';
import 'package:deneige_auto/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:deneige_auto/features/payment/data/models/payment_model.dart';
import 'package:deneige_auto/features/payment/data/models/payment_method_model.dart';
import 'package:deneige_auto/features/payment/data/models/refund_model.dart';
import 'package:deneige_auto/features/payment/domain/entities/payment.dart';
import 'package:deneige_auto/features/payment/domain/entities/payment_method.dart';
import 'package:deneige_auto/features/payment/domain/entities/refund.dart';

import '../../../../mocks/mock_datasources.dart';

void main() {
  late PaymentRepositoryImpl repository;
  late MockPaymentRemoteDataSource mockDataSource;

  setUpAll(() {
    registerFallbackValue(RefundReason.requestedByCustomer);
  });

  setUp(() {
    mockDataSource = MockPaymentRemoteDataSource();
    repository = PaymentRepositoryImpl(remoteDataSource: mockDataSource);
  });

  // Helper pour creer des PaymentModel
  PaymentModel createPaymentModel({String id = 'pay-123'}) {
    return PaymentModel(
      id: id,
      userId: 'user-123',
      reservationId: 'res-123',
      amount: 25.0,
      status: PaymentStatus.succeeded,
      methodType: PaymentMethodType.card,
      createdAt: DateTime(2024, 1, 15, 10, 0),
    );
  }

  // Helper pour creer des PaymentMethodModel
  PaymentMethodModel createPaymentMethodModel({
    String id = 'pm-123',
    bool isDefault = false,
  }) {
    return PaymentMethodModel(
      id: id,
      userId: 'user-123',
      brand: CardBrand.visa,
      last4: '4242',
      expMonth: 12,
      expYear: 2025,
      isDefault: isDefault,
      createdAt: DateTime(2024, 1, 15, 10, 0),
    );
  }

  // Helper pour creer des RefundModel
  RefundModel createRefundModel({String id = 'ref-123'}) {
    return RefundModel(
      id: id,
      paymentId: 'pay-123',
      reservationId: 'res-123',
      amount: 25.0,
      status: RefundStatus.succeeded,
      reason: RefundReason.requestedByCustomer,
      createdAt: DateTime(2024, 1, 15, 10, 0),
    );
  }

  group('PaymentRepositoryImpl', () {
    group('getPaymentHistory', () {
      test('should return list of payments when successful', () async {
        final tPayments = [
          createPaymentModel(id: 'pay-1'),
          createPaymentModel(id: 'pay-2'),
        ];
        when(() => mockDataSource.getPaymentHistory())
            .thenAnswer((_) async => tPayments);

        final result = await repository.getPaymentHistory();

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return payments'),
          (payments) => expect(payments.length, 2),
        );
      });

      test('should return ServerFailure when ServerException is thrown',
          () async {
        when(() => mockDataSource.getPaymentHistory())
            .thenThrow(const ServerException(message: 'Server error'));

        final result = await repository.getPaymentHistory();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });

      test('should return ServerFailure when AuthException is thrown',
          () async {
        when(() => mockDataSource.getPaymentHistory())
            .thenThrow(const AuthException(message: 'Not authenticated'));

        final result = await repository.getPaymentHistory();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('getPaymentMethods', () {
      test('should return list of payment methods when successful', () async {
        final tPaymentMethods = [
          createPaymentMethodModel(id: 'pm-1', isDefault: true),
          createPaymentMethodModel(id: 'pm-2'),
        ];
        when(() => mockDataSource.getPaymentMethods())
            .thenAnswer((_) async => tPaymentMethods);

        final result = await repository.getPaymentMethods();

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return payment methods'),
          (methods) => expect(methods.length, 2),
        );
      });

      test('should return empty list when no payment methods', () async {
        when(() => mockDataSource.getPaymentMethods())
            .thenAnswer((_) async => []);

        final result = await repository.getPaymentMethods();

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return empty list'),
          (methods) => expect(methods.isEmpty, true),
        );
      });

      test('should return ServerFailure when ServerException is thrown',
          () async {
        when(() => mockDataSource.getPaymentMethods())
            .thenThrow(const ServerException(message: 'Server error'));

        final result = await repository.getPaymentMethods();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('savePaymentMethod', () {
      test('should return Right(null) when successful', () async {
        when(() => mockDataSource.savePaymentMethod(
              paymentMethodId: any(named: 'paymentMethodId'),
              setAsDefault: any(named: 'setAsDefault'),
            )).thenAnswer((_) async {});

        final result = await repository.savePaymentMethod(
          paymentMethodId: 'pm_123',
          setAsDefault: true,
        );

        expect(result, const Right(null));
      });

      test('should return ServerFailure when ServerException is thrown',
          () async {
        when(() => mockDataSource.savePaymentMethod(
              paymentMethodId: any(named: 'paymentMethodId'),
              setAsDefault: any(named: 'setAsDefault'),
            )).thenThrow(const ServerException(message: 'Save failed'));

        final result = await repository.savePaymentMethod(
          paymentMethodId: 'pm_123',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('deletePaymentMethod', () {
      test('should return Right(null) when successful', () async {
        when(() => mockDataSource.deletePaymentMethod('pm-123'))
            .thenAnswer((_) async {});

        final result = await repository.deletePaymentMethod('pm-123');

        expect(result, const Right(null));
        verify(() => mockDataSource.deletePaymentMethod('pm-123')).called(1);
      });

      test('should return ServerFailure when payment method not found',
          () async {
        when(() => mockDataSource.deletePaymentMethod('pm-123'))
            .thenThrow(const ServerException(message: 'Not found'));

        final result = await repository.deletePaymentMethod('pm-123');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('setDefaultPaymentMethod', () {
      test('should return Right(null) when successful', () async {
        when(() => mockDataSource.setDefaultPaymentMethod('pm-123'))
            .thenAnswer((_) async {});

        final result = await repository.setDefaultPaymentMethod('pm-123');

        expect(result, const Right(null));
        verify(() => mockDataSource.setDefaultPaymentMethod('pm-123'))
            .called(1);
      });

      test('should return ServerFailure when ServerException is thrown',
          () async {
        when(() => mockDataSource.setDefaultPaymentMethod('pm-123'))
            .thenThrow(const ServerException(message: 'Set default failed'));

        final result = await repository.setDefaultPaymentMethod('pm-123');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('processRefund', () {
      test('should return Refund when successful', () async {
        final tRefund = createRefundModel();
        when(() => mockDataSource.processRefund(
              reservationId: any(named: 'reservationId'),
              amount: any(named: 'amount'),
              reason: any(named: 'reason'),
              note: any(named: 'note'),
            )).thenAnswer((_) async => tRefund);

        final result = await repository.processRefund(
          reservationId: 'res-123',
          reason: RefundReason.requestedByCustomer,
        );

        expect(result.isRight(), true);
      });

      test('should return ServerFailure when ServerException is thrown',
          () async {
        when(() => mockDataSource.processRefund(
              reservationId: any(named: 'reservationId'),
              amount: any(named: 'amount'),
              reason: any(named: 'reason'),
              note: any(named: 'note'),
            )).thenThrow(const ServerException(message: 'Refund failed'));

        final result = await repository.processRefund(
          reservationId: 'res-123',
          reason: RefundReason.requestedByCustomer,
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });
  });
}
