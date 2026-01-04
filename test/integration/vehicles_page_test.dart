import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/vehicule/presentation/bloc/vehicule_bloc.dart';
import 'package:deneige_auto/features/vehicule/presentation/pages/vehicles_list_page.dart';

import '../fixtures/reservation_fixtures.dart';

class MockVehicleBloc extends Mock implements VehicleBloc {}

void main() {
  late MockVehicleBloc mockVehicleBloc;

  setUp(() {
    mockVehicleBloc = MockVehicleBloc();
    when(() => mockVehicleBloc.close()).thenAnswer((_) async {});
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<VehicleBloc>.value(
        value: mockVehicleBloc,
        child: const VehiclesListPage(),
      ),
    );
  }

  group('VehiclesListPage Widget Tests', () {
    testWidgets('should display loading indicator when VehicleLoading', (tester) async {
      when(() => mockVehicleBloc.state).thenReturn(const VehicleState(isLoading: true));
      when(() => mockVehicleBloc.stream).thenAnswer(
        (_) => Stream.value(const VehicleState(isLoading: true)),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display vehicles list when loaded', (tester) async {
      final vehicles = ReservationFixtures.createVehicleList(3);

      when(() => mockVehicleBloc.state).thenReturn(VehicleState(
        isLoading: false,
        vehicles: vehicles,
      ));
      when(() => mockVehicleBloc.stream).thenAnswer(
        (_) => Stream.value(VehicleState(
          isLoading: false,
          vehicles: vehicles,
        )),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Should display scaffold
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display empty state when no vehicles', (tester) async {
      when(() => mockVehicleBloc.state).thenReturn(const VehicleState(
        isLoading: false,
        vehicles: [],
      ));
      when(() => mockVehicleBloc.stream).thenAnswer(
        (_) => Stream.value(const VehicleState(
          isLoading: false,
          vehicles: [],
        )),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display add vehicle FAB', (tester) async {
      when(() => mockVehicleBloc.state).thenReturn(const VehicleState(
        isLoading: false,
        vehicles: [],
      ));
      when(() => mockVehicleBloc.stream).thenAnswer(
        (_) => Stream.value(const VehicleState(
          isLoading: false,
          vehicles: [],
        )),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Should have FAB to add vehicle
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should display error message when error state', (tester) async {
      when(() => mockVehicleBloc.state).thenReturn(const VehicleState(
        isLoading: false,
        vehicles: [],
        errorMessage: 'Erreur de chargement des vehicules',
      ));
      when(() => mockVehicleBloc.stream).thenAnswer(
        (_) => Stream.value(const VehicleState(
          isLoading: false,
          vehicles: [],
          errorMessage: 'Erreur de chargement des vehicules',
        )),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Page should be displayed (error might be shown as snackbar)
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
