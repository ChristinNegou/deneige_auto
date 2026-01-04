import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:deneige_auto/features/auth/presentation/bloc/auth_state.dart';
import 'package:deneige_auto/features/auth/presentation/screens/login_screen.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});
  });

  Widget buildTestWidget(AuthState state) {
    when(() => mockAuthBloc.state).thenReturn(state);
    when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(state));

    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('should display login form elements', (tester) async {
      await tester.pumpWidget(buildTestWidget(AuthInitial()));
      await tester.pumpAndSettle();

      // Verify text fields exist
      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    });

    testWidgets('should show loading indicator when AuthLoading state',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(AuthLoading()));
      await tester.pump();

      // Verify loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display Scaffold', (tester) async {
      await tester.pumpWidget(buildTestWidget(AuthInitial()));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display welcome text', (tester) async {
      await tester.pumpWidget(buildTestWidget(AuthInitial()));
      await tester.pumpAndSettle();

      expect(find.text('Bienvenue'), findsOneWidget);
    });

    testWidgets('should display sign up link', (tester) async {
      await tester.pumpWidget(buildTestWidget(AuthInitial()));
      await tester.pumpAndSettle();

      expect(find.text('S\'inscrire'), findsOneWidget);
    });
  });
}
