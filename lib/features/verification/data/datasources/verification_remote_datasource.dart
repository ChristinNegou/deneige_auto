import 'dart:io';

import 'package:dio/dio.dart';

import '../../domain/entities/verification_status.dart';
import '../models/verification_status_model.dart';

abstract class VerificationRemoteDatasource {
  Future<VerificationStatusModel> getVerificationStatus();
  Future<VerificationStatusModel> submitVerification({
    required File idFront,
    File? idBack,
    required File selfie,
  });
}

class VerificationRemoteDatasourceImpl implements VerificationRemoteDatasource {
  final Dio dio;

  VerificationRemoteDatasourceImpl({required this.dio});

  @override
  Future<VerificationStatusModel> getVerificationStatus() async {
    final response = await dio.get('/workers/verification/status');

    if (response.statusCode == 200 && response.data['success'] == true) {
      return VerificationStatusModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    }

    throw Exception(
      response.data['message'] ?? 'Erreur lors de la récupération du statut',
    );
  }

  @override
  Future<VerificationStatusModel> submitVerification({
    required File idFront,
    File? idBack,
    required File selfie,
  }) async {
    final formData = FormData.fromMap({
      'idFront': await MultipartFile.fromFile(
        idFront.path,
        filename: 'id_front.jpg',
      ),
      if (idBack != null)
        'idBack': await MultipartFile.fromFile(
          idBack.path,
          filename: 'id_back.jpg',
        ),
      'selfie': await MultipartFile.fromFile(
        selfie.path,
        filename: 'selfie.jpg',
      ),
    });

    final response = await dio.post(
      '/workers/verification/submit',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      // Return a pending status since we just submitted
      return const VerificationStatusModel(
        status: IdentityVerificationState.pending,
        canResubmit: false,
        attemptsRemaining: 0,
      );
    }

    throw Exception(
      response.data['message'] ?? 'Erreur lors de la soumission',
    );
  }
}
