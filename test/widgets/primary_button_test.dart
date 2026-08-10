import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/theme/app_colors.dart';
import 'package:meetple/widgets/primary_button.dart';

void main() {
  testWidgets('uses the solid primary color for the common action button',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: '신청하기',
            onPressed: () {},
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));

    expect(
      button.style?.backgroundColor?.resolve(const <WidgetState>{}),
      AppColors.primary,
    );
  });

  testWidgets('replaces its label with a loader while loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Submit',
            onPressed: () {},
            loading: true,
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.text('Submit'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
