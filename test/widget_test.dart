import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/app/meetple_app.dart';
import 'package:meetple/data/repositories/mock_auth_repository.dart';
import 'package:meetple/screens/auth/login_page.dart';

void main() {
  testWidgets('shows Meetple home when session is restored', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MeetpleApp());
    await tester.pumpAndSettle();

    expect(
      find.text('\uCD94\uCC9C \uBAA8\uC784', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('opens create meeting tab from home banner', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MeetpleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
  });

  testWidgets('shows authenticated profile from auth repository', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MeetpleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.text('\uAE40\uBAA8\uC784'), findsOneWidget);
    expect(find.text('@gather_together'), findsOneWidget);
  });

  testWidgets('shows login first when no session is restored', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MeetpleApp(authRepository: MockAuthRepository(session: null)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('\uD68C\uC6D0\uAC00\uC785'), findsOneWidget);
  });

  testWidgets('enters app after signing in from entry login', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MeetpleApp(authRepository: MockAuthRepository(session: null)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.text('\uB85C\uADF8\uC778'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsNothing);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.text('\uAE40\uBAA8\uC784'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.text('\uAE40\uBAA8\uC784'), findsOneWidget);
  });

  testWidgets('returns to entry login after signing out', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final authRepository = MockAuthRepository();
    await tester.pumpWidget(MeetpleApp(authRepository: authRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_sign_out')), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile_sign_out')));
    await tester.pumpAndSettle();

    expect(await authRepository.restoreSession(), isNull);
    expect(find.byKey(const Key('profile_sign_out')), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('moves sign up from account step to profile step', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MeetpleApp(authRepository: MockAuthRepository(session: null)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('\uD68C\uC6D0\uAC00\uC785'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign_up_all_terms')), findsOneWidget);
    expect(find.text('\uB2E4\uC74C'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password1!');
    await tester.enterText(find.byType(TextField).at(2), 'password1!');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sign_up_all_terms')));
    await tester.pump();
    await tester.tap(find.text('\uB2E4\uC74C'));
    await tester.pumpAndSettle();

    expect(find.text('\uAC00\uC785 \uC644\uB8CC'), findsOneWidget);
  });
}
