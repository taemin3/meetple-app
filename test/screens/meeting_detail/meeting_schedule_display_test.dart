import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/models/meeting.dart';
import 'package:meetple/screens/meeting_detail/meeting_detail_page.dart';

void main() {
  testWidgets('shows unknown end time in meeting information', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MeetingInfoSection(meeting: _meeting()),
        ),
      ),
    );

    expect(find.text('8/22 14:00 시작 · 종료 미정'), findsOneWidget);
  });

  testWidgets('shows expected end time in meeting information', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MeetingInfoSection(
            meeting: _meeting(endsAt: DateTime(2026, 8, 22, 16)),
          ),
        ),
      ),
    );

    expect(find.text('8/22 14:00 ~ 16:00'), findsOneWidget);
  });
}

Meeting _meeting({DateTime? endsAt}) {
  return Meeting(
    id: 10,
    title: '한강 산책',
    category: '취미',
    tags: const ['취미'],
    area: '여의도공원',
    date: '8/22',
    time: '14:00',
    distance: '1km',
    capacity: 10,
    joined: 3,
    host: '모임장',
    description: '함께 걸어요.',
    fee: '무료',
    rating: 0,
    reviewCount: 0,
    scheduledAt: DateTime(2026, 8, 22, 14),
    endsAt: endsAt,
  );
}
