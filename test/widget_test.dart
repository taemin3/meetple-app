import 'package:flutter/widgets.dart';
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
}
