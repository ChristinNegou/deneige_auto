import 'package:deneige_auto/features/snow_worker/data/models/worker_job_model.dart';
import 'package:deneige_auto/features/snow_worker/domain/entities/worker_job.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shows the options the client actually picked', () {
    final job = WorkerJobModel.fromJson({
      '_id': 'j1',
      'userId': {'_id': 'c1', 'firstName': 'Ana', 'lastName': 'B'},
      'vehicle': {'_id': 'v1', 'make': 'Toyota', 'model': 'Corolla'},
      'departureTime': '2026-11-20T12:00:00.000Z',
      'status': 'pending',
      'totalPrice': 30,
      'serviceOptions': ['roofClearing', 'exhaustCheck', 'carWash'],
      'createdAt': '2026-11-19T12:00:00.000Z',
    });

    expect(job.serviceOptions,
        [ServiceOption.roofClearing, ServiceOption.exhaustCheck]);
  });
}
