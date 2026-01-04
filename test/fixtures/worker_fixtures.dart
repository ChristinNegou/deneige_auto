import 'package:deneige_auto/features/snow_worker/domain/entities/worker_job.dart';
import 'package:deneige_auto/features/snow_worker/domain/entities/worker_stats.dart';
import 'package:deneige_auto/features/snow_worker/domain/entities/worker_profile.dart';

/// Fixtures pour les tests de snow worker
class WorkerFixtures {
  static final DateTime _now = DateTime(2024, 1, 15, 10, 0);

  /// Cree un ClientInfo
  static ClientInfo createClientInfo({
    String? id,
    String firstName = 'Jean',
    String lastName = 'Dupont',
    String? phoneNumber,
  }) {
    return ClientInfo(
      id: id ?? 'client-123',
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber ?? '514-555-1234',
    );
  }

  /// Cree un VehicleInfo
  static VehicleInfo createVehicleInfo({
    String? id,
    String make = 'Honda',
    String model = 'Civic',
    String? color,
    String? licensePlate,
  }) {
    return VehicleInfo(
      id: id ?? 'vehicle-123',
      make: make,
      model: model,
      color: color ?? 'Noir',
      licensePlate: licensePlate ?? 'ABC 123',
    );
  }

  /// Cree un JobLocation
  static JobLocation createJobLocation({
    double latitude = 46.3432,
    double longitude = -72.5476,
    String? address,
  }) {
    return JobLocation(
      latitude: latitude,
      longitude: longitude,
      address: address ?? '123 Rue Principale, Trois-Rivieres',
    );
  }

  /// Cree un WorkerJob en attente
  static WorkerJob createPendingJob({
    String? id,
    ClientInfo? client,
    VehicleInfo? vehicle,
    JobLocation? location,
    double? totalPrice,
    bool isPriority = false,
  }) {
    return WorkerJob(
      id: id ?? 'job-123',
      client: client ?? createClientInfo(),
      vehicle: vehicle ?? createVehicleInfo(),
      location: location ?? createJobLocation(),
      parkingSpotNumber: 'A-15',
      distanceKm: 2.5,
      departureTime: _now.add(const Duration(hours: 2)),
      deadlineTime: _now.add(const Duration(hours: 1, minutes: 30)),
      serviceOptions: [ServiceOption.windowScraping],
      totalPrice: totalPrice ?? 25.0,
      isPriority: isPriority,
      snowDepthCm: 10,
      status: JobStatus.pending,
      createdAt: _now,
    );
  }

  /// Cree un WorkerJob assigne
  static WorkerJob createAssignedJob({
    String? id,
  }) {
    return createPendingJob(id: id).copyWith(
      status: JobStatus.assigned,
      assignedAt: _now,
    );
  }

  /// Cree un WorkerJob en cours
  static WorkerJob createInProgressJob({
    String? id,
  }) {
    return createAssignedJob(id: id).copyWith(
      status: JobStatus.inProgress,
      startedAt: _now.add(const Duration(minutes: 30)),
    );
  }

  /// Cree un WorkerJob complete
  static WorkerJob createCompletedJob({
    String? id,
    double? rating,
    double? tipAmount,
  }) {
    return createInProgressJob(id: id).copyWith(
      status: JobStatus.completed,
      completedAt: _now.add(const Duration(hours: 1)),
      rating: rating,
      tipAmount: tipAmount,
    );
  }

  /// Cree une liste de jobs
  static List<WorkerJob> createJobList(int count, {JobStatus? status}) {
    return List.generate(
      count,
      (index) {
        final base = createPendingJob(id: 'job-$index');
        if (status != null) {
          return base.copyWith(status: status);
        }
        return base;
      },
    );
  }

  /// Cree TodayStats
  static TodayStats createTodayStats({
    int completed = 3,
    int inProgress = 1,
    int assigned = 2,
    double earnings = 75.0,
    double tips = 15.0,
  }) {
    return TodayStats(
      completed: completed,
      inProgress: inProgress,
      assigned: assigned,
      earnings: earnings,
      tips: tips,
    );
  }

  /// Cree PeriodStats
  static PeriodStats createPeriodStats({
    int completed = 15,
    double earnings = 375.0,
    double tips = 75.0,
  }) {
    return PeriodStats(
      completed: completed,
      earnings: earnings,
      tips: tips,
    );
  }

  /// Cree AllTimeStats
  static AllTimeStats createAllTimeStats({
    int completed = 150,
    double earnings = 3750.0,
    double tips = 750.0,
    double averageRating = 4.8,
    int totalRatings = 120,
  }) {
    return AllTimeStats(
      completed: completed,
      earnings: earnings,
      tips: tips,
      averageRating: averageRating,
      totalRatings: totalRatings,
    );
  }

  /// Cree WorkerStats
  static WorkerStats createWorkerStats({
    TodayStats? today,
    PeriodStats? week,
    PeriodStats? month,
    AllTimeStats? allTime,
    bool isAvailable = true,
  }) {
    return WorkerStats(
      today: today ?? createTodayStats(),
      week: week ?? createPeriodStats(),
      month: month ?? createPeriodStats(completed: 45, earnings: 1125.0, tips: 225.0),
      allTime: allTime ?? createAllTimeStats(),
      isAvailable: isAvailable,
    );
  }

  /// Cree un WorkerJob generique (alias de createPendingJob)
  static WorkerJob createWorkerJob({
    String? id,
    JobStatus status = JobStatus.pending,
  }) {
    return createPendingJob(id: id).copyWith(status: status);
  }

  /// Cree une liste de WorkerJob
  static List<WorkerJob> createWorkerJobList(int count, {JobStatus? status}) {
    return createJobList(count, status: status);
  }

  /// Cree un WorkerProfile
  static WorkerProfile createWorkerProfile({
    String? id,
    String email = 'worker@example.com',
    String firstName = 'Jean',
    String lastName = 'Travailleur',
    bool isAvailable = true,
    int maxActiveJobs = 3,
  }) {
    return WorkerProfile(
      id: id ?? 'worker-123',
      email: email,
      firstName: firstName,
      lastName: lastName,
      isAvailable: isAvailable,
      maxActiveJobs: maxActiveJobs,
      vehicleType: VehicleType.car,
      equipmentList: const ['Pelle', 'Balai'],
      totalJobsCompleted: 150,
      totalEarnings: 3750.0,
      totalTipsReceived: 750.0,
      averageRating: 4.8,
      totalRatingsCount: 120,
    );
  }
}
