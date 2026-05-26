import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/app/meetple_app.dart';
import 'package:meetple/data/repositories/mock_auth_repository.dart';

void main() {
  testWidgets('shows Meetple home', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MeetpleApp());
    await tester.pump();

    expect(
      find.textContaining('함께할 사람을', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('추천 모임', skipOffstage: false), findsOneWidget);
  });

  testWidgets('opens create meeting tab from home banner', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MeetpleApp());
    await tester.pump();

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
    await tester.pump();

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();

    expect(find.text('김모임'), findsOneWidget);
    expect(find.text('@gather_together'), findsOneWidget);
    expect(find.text('내 정보'), findsOneWidget);
  });

  testWidgets('keeps signed-in profile after tab switch', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MeetpleApp(authRepository: MockAuthRepository(session: null)),
    );
    await tester.pump();

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그인하기'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.text('로그인하기'));
    await tester.pumpAndSettle();

    expect(find.text('김모임'), findsOneWidget);

    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();

    expect(find.text('김모임'), findsOneWidget);
    expect(find.text('로그인이 필요합니다.'), findsNothing);
  });
}
