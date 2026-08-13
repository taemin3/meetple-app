import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/app/auth_entry_gate.dart';
import 'package:meetple/app/meetple_app.dart';

void main() {
  testWidgets('uses Korean labels in the Material date picker', (tester) async {
    await tester.pumpWidget(const MeetpleApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AuthEntryGate));
    expect(Localizations.localeOf(context), const Locale('ko', 'KR'));

    showDatePicker(
      context: context,
      initialDate: DateTime(2026, 8, 22),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
    );
    await tester.pumpAndSettle();

    expect(find.text('취소'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);
  });
}
