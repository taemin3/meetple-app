import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/models/meeting.dart';
import 'package:meetple/screens/meeting_detail/meeting_detail_page.dart';
import 'package:meetple/widgets/network_image_with_skeleton.dart';

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

  testWidgets('preserves legacy schedule text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MeetingInfoSection(
            meeting: _meeting(
              hasStructuredSchedule: false,
              date: '내일 (토)',
              time: '07:00 ~ 08:30',
            ),
          ),
        ),
      ),
    );

    expect(find.text('내일 (토) 07:00 ~ 08:30'), findsOneWidget);
    expect(find.textContaining('종료 미정'), findsNothing);
  });

  testWidgets('shows host information without profile navigation',
      (tester) async {
    const profileImageUrl = 'https://example.com/profile.png';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HostInfoCard(
            meeting: _meeting(
              hostProfileImageUrl: profileImageUrl,
              hostIntroduction: '함께 즐겁게 걸어요.',
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('meeting-host-info-card')), findsOneWidget);
    expect(find.text('모임장'), findsNWidgets(2));
    expect(find.text('함께 즐겁게 걸어요.'), findsOneWidget);
    expect(find.text('프로필 보기'), findsNothing);
    expect(find.textContaining('후기'), findsNothing);
    final image = tester.widget<NetworkImageWithSkeleton>(
      find.byType(NetworkImageWithSkeleton),
    );
    expect(image.imageUrl, profileImageUrl);
  });
}

Meeting _meeting({
  DateTime? endsAt,
  bool hasStructuredSchedule = true,
  String date = '8/22',
  String time = '14:00',
  String? hostProfileImageUrl,
  String? hostIntroduction,
}) {
  return Meeting(
    id: 10,
    title: '한강 산책',
    category: '취미',
    tags: const ['취미'],
    area: '여의도공원',
    date: date,
    time: time,
    distance: '1km',
    capacity: 10,
    joined: 3,
    host: '모임장',
    hostProfileImageUrl: hostProfileImageUrl,
    hostIntroduction: hostIntroduction,
    description: '함께 걸어요.',
    fee: '무료',
    rating: 0,
    reviewCount: 0,
    scheduledAt: hasStructuredSchedule ? DateTime(2026, 8, 22, 14) : null,
    endsAt: endsAt,
  );
}
