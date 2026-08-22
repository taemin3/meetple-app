import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/models/meeting.dart';
import 'package:meetple/models/meeting_engagement.dart';
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

  testWidgets('shows member summary and opens the full member list',
      (tester) async {
    const members = [
      MeetingMember(
        memberId: 2,
        nickname: '서연',
        introduction: '새로운 취미를 함께 즐겨요.',
        isHost: false,
      ),
      MeetingMember(
        memberId: 1,
        nickname: '민준',
        introduction: '즐거운 모임을 만들어요.',
        isHost: true,
      ),
      MeetingMember(memberId: 3, nickname: '지우', isHost: false),
      MeetingMember(memberId: 4, nickname: '도윤', isHost: false),
      MeetingMember(memberId: 5, nickname: '하린', isHost: false),
      MeetingMember(memberId: 6, nickname: '준호', isHost: false),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MeetingMembersSection(
            meeting: _meeting(joined: 6),
            members: members,
          ),
        ),
      ),
    );

    expect(find.text('참여 멤버 6 / 10'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(find.byKey(const Key('meeting-member-avatar-0')), findsOneWidget);
    expect(find.byKey(const Key('meeting-member-avatar-4')), findsOneWidget);
    expect(find.byKey(const Key('meeting-member-avatar-5')), findsNothing);

    await tester.tap(find.text('전체보기'));
    await tester.pumpAndSettle();

    expect(find.text('참여 멤버 6명'), findsOneWidget);
    expect(find.byKey(const Key('meeting-member-host-badge')), findsOneWidget);
    expect(find.text('민준'), findsOneWidget);
    expect(find.text('즐거운 모임을 만들어요.'), findsOneWidget);
    expect(find.text('서연'), findsOneWidget);
    expect(find.text('새로운 취미를 함께 즐겨요.'), findsOneWidget);
    expect(find.byType(Divider), findsNothing);
    await tester.drag(
      find.byKey(const Key('meeting-members-list')),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    expect(find.text('준호'), findsOneWidget);
    expect(find.text('프로필 보기'), findsNothing);
  });
}

Meeting _meeting({
  DateTime? endsAt,
  bool hasStructuredSchedule = true,
  String date = '8/22',
  String time = '14:00',
  String? hostProfileImageUrl,
  String? hostIntroduction,
  int joined = 3,
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
    joined: joined,
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
