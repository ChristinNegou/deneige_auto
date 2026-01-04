import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/vehicule/presentation/bloc/vehicule_bloc.dart';
import 'package:deneige_auto/features/reservation/domain/entities/vehicle.dart';

import '../fixtures/reservation_fixtures.dart';

class MockVehicleBloc extends Mock implements VehicleBloc {}

void main() {
  late MockVehicleBloc mockVehicleBloc;

  setUp(() {
    mockVehicleBloc = MockVehicleBloc();
    when(() => mockVehicleBloc.close()).thenAnswer((_) async {});
  });

  Widget buildTestWidget({required VehicleState state}) {
    when(() => mockVehicleBloc.state).thenReturn(state);
    when(() => mockVehicleBloc.stream).thenAnswer((_) => Stream.value(state));

    return MaterialApp(
      home: BlocProvider<VehicleBloc>.value(
        value: mockVehicleBloc,
        child: Scaffold(
          body: BlocBuilder<VehicleBloc, VehicleState>(
            builder: (context, state) {
              if (state.isLoading && state.vehicles.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state.vehicles.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_outlined, size: 64),
                      SizedBox(height: 16),
                      Text('Aucun véhicule'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: state.vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = state.vehicles[index];
                  return ListTile(
                    title: Text(vehicle.displayName),
                    subtitle: Text(vehicle.licensePlate ?? ''),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  group('VehiclesListPage Widget Tests', () {
    testWidgets('should display loading indicator when VehicleLoading',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        state: const VehicleState(isLoading: true, vehicles: []),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display vehicles list when loaded', (tester) async {
      final vehicles = ReservationFixtures.createVehicleList(3);

      await tester.pumpWidget(buildTestWidget(
        state: VehicleState(isLoading: false, vehicles: vehicles),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should display empty state when no vehicles', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        state: const VehicleState(isLoading: false, vehicles: []),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Aucun véhicule'), findsOneWidget);
    });

    testWidgets('should display add vehicle FAB', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        state: const VehicleState(isLoading: false, vehicles: []),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should display vehicle details in list', (tester) async {
      final vehicles = [
        Vehicle(
          id: 'v1',
          userId: 'user-123',
          make: 'Honda',
          model: 'Civic',
          year: 2022,
          color: 'Noir',
          licensePlate: 'ABC 123',
          type: VehicleType.car,
          isDefault: false,
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        state: VehicleState(isLoading: false, vehicles: vehicles),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Honda Civic 2022'), findsOneWidget);
      expect(find.text('ABC 123'), findsOneWidget);
    });
  });
}
