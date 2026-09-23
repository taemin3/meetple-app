import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/repositories/mock_moderation_repository.dart';
import 'package:meetple/models/moderation.dart';
import 'package:meetple/screens/moderation/report_sheet.dart';

void main() {
  testWidgets('report sheet remains scrollable with the other reason keyboard',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showReportSheet(
                context,
                repository: const MockModerationRepository(),
                targetType: ReportTargetType.member,
                targetId: 2,
              ),
              child: const Text('신고 열기'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('신고 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('report-reason-other')));
    await tester.pumpAndSettle();
    await tester
        .showKeyboard(find.byKey(const Key('report-other-description')));
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
