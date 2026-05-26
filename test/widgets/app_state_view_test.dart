import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/widgets/app_state_view.dart';

void main() {
  testWidgets('shows loading message with progress indicator', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppLoadingView(message: '모임을 불러오는 중입니다.'),
        ),
      ),
    );

    expect(find.text('모임을 불러오는 중입니다.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('calls retry callback from error state', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppErrorView(
            message: '모임을 불러오지 못했습니다.',
            onRetry: () => retryCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('다시 시도'));
    await tester.pump();

    expect(retryCount, 1);
  });

  testWidgets('shows empty message with empty state icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppEmptyView(message: '추천 모임이 없습니다.'),
        ),
      ),
    );

    expect(find.text('추천 모임이 없습니다.'), findsOneWidget);
    expect(find.byIcon(Icons.event_busy_outlined), findsOneWidget);
  });
}
