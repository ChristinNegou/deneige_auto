import 'package:deneige_auto/core/config/app_config.dart';
import 'package:deneige_auto/features/reservation/domain/entities/reservation.dart';
import 'package:deneige_auto/features/reservation/domain/entities/vehicle.dart';
import 'package:deneige_auto/features/reservation/domain/entities/parking_spot.dart';

/// Fixtures pour les tests de reservation
class ReservationFixtures {
  static final DateTime _now = DateTime(2024, 1, 15, 10, 0);

  /// Cree un vehicule pour les tests
  static Vehicle createVehicle({
    String? id,
    String? userId,
    String? make,
    String? model,
    int? year,
    String? color,
    VehicleType type = VehicleType.car,
    bool isDefault = false,
  }) {
    return Vehicle(
      id: id ?? 'vehicle-123',
      userId: userId ?? 'user-123',
      make: make ?? 'Honda',
      model: model ?? 'Civic',
      year: year ?? 2022,
      color: color ?? 'Noir',
      licensePlate: 'ABC 123',
      type: type,
      isDefault: isDefault,
      createdAt: _now,
      updatedAt: _now,
    );
  }

  /// Cree une place de stationnement pour les tests
  static ParkingSpot createParkingSpot({
    String? id,
    String? spotNumber,
    ParkingLevel level = ParkingLevel.outdoor,
    String? section,
    double? latitude,
    double? longitude,
    bool isAssigned = false,
  }) {
    return ParkingSpot(
      id: id ?? 'spot-123',
      spotNumber: spotNumber ?? 'A-15',
      level: level,
      section: section ?? 'A',
      latitude: latitude ?? 46.3432,
      longitude: longitude ?? -72.5476,
      isAssigned: isAssigned,
      isActive: true,
      createdAt: _now,
      updatedAt: _now,
    );
  }

  /// Cree une reservation en attente pour les tests
  static Reservation createPending({
    String? id,
    String? userId,
    Vehicle? vehicle,
    ParkingSpot? parkingSpot,
    DateTime? departureTime,
    List<ServiceOption>? serviceOptions,
    double? basePrice,
    double? totalPrice,
    int? snowDepthCm,
  }) {
    return Reservation(
      id: id ?? 'reservation-123',
      userId: userId ?? 'user-123',
      vehicle: vehicle ?? createVehicle(),
      parkingSpot: parkingSpot ?? createParkingSpot(),
      departureTime: departureTime ?? _now.add(const Duration(hours: 2)),
      deadlineTime: _now.add(const Duration(hours: 1, minutes: 30)),
      status: ReservationStatus.pending,
      serviceOptions: serviceOptions ?? [ServiceOption.windowScraping],
      basePrice: basePrice ?? AppConfig.basePrice,
      totalPrice: totalPrice ?? 25.0,
      snowDepthCm: snowDepthCm ?? 10,
      createdAt: _now,
      isPriority: false,
    );
  }

  /// Cree une reservation assignee pour les tests
  static Reservation createAssigned({
    String? id,
    String? workerId,
    String? workerName,
  }) {
    return createPending(id: id).copyWith(
      status: ReservationStatus.assigned,
      workerId: workerId ?? 'worker-123',
      workerName: workerName ?? 'Pierre Martin',
      assignedAt: _now,
    );
  }

  /// Cree une reservation completee pour les tests
  static Reservation createCompleted({
    String? id,
    double? rating,
    String? review,
    double? tip,
  }) {
    return createAssigned(id: id).copyWith(
      status: ReservationStatus.completed,
      startedAt: _now.add(const Duration(hours: 1)),
      completedAt: _now.add(const Duration(hours: 1, minutes: 20)),
      rating: rating,
      review: review,
      tip: tip,
    );
  }

  /// Cree une reservation annulee pour les tests
  static Reservation createCancelled({String? id}) {
    return createPending(id: id).copyWith(
      status: ReservationStatus.cancelled,
    );
  }

  /// Cree une liste de reservations
  static List<Reservation> createList(int count, {ReservationStatus? status}) {
    return List.generate(
      count,
      (index) {
        final base = createPending(id: 'reservation-$index');
        if (status != null) {
          return base.copyWith(status: status);
        }
        return base;
      },
    );
  }

  /// Cree une liste de vehicules
  static List<Vehicle> createVehicleList(int count) {
    return List.generate(
      count,
      (index) => createVehicle(
        id: 'vehicle-$index',
        make: index.isEven ? 'Honda' : 'Toyota',
        model: index.isEven ? 'Civic' : 'Corolla',
      ),
    );
  }

  /// Cree une liste de places de stationnement
  static List<ParkingSpot> createParkingSpotList(int count) {
    return List.generate(
      count,
      (index) => createParkingSpot(
        id: 'spot-$index',
        spotNumber: 'A-$index',
      ),
    );
  }
}
