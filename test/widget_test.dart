import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/app/meeting_mock_app.dart';

void main() {
  testWidgets('shows Meeting mock home', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MeetingMockApp());
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

    await tester.pumpWidget(const MeetingMockApp());
    await tester.pump();

    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
  });
}
