import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/theme/app_theme.dart';
import 'package:meetple/data/repositories/mock_meeting_repository.dart';
import 'package:meetple/models/meeting.dart';
import 'package:meetple/models/meeting_engagement.dart';
import 'package:meetple/models/meeting_list_filter.dart';
import 'package:meetple/screens/profile/my_applications_page.dart';
import 'package:meetple/screens/profile/my_meetings_page.dart';

void main() {
  testWidgets('filters my meetings by ongoing and ended status',
      (tester) async {
    final meetings = [
      _meeting(id: 1, title: '진행 모임', status: 'RECRUITING'),
      _meeting(id: 2, title: '종료 모임', status: 'COMPLETED'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MyMeetingsPage(
          title: '내가 만든 모임',
          emptyMessage: '모임이 없습니다.',
          meetingRepository: const MockMeetingRepository(),
          loader: () async => meetings,
          filters: const [
            MeetingListFilter.all,
            MeetingListFilter.ongoing,
            MeetingListFilter.ended,
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('전체 2'), findsOneWidget);
    expect(find.text('진행 중 1'), findsOneWidget);
    expect(find.text('종료 1'), findsOneWidget);

    await tester.tap(find.text('종료 1'));
    await tester.pumpAndSettle();

    expect(find.text('진행 모임'), findsNothing);
    expect(find.text('종료 모임'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
  });

  testWidgets('filters my applications with participation style counts',
      (tester) async {
    final repository = _ApplicationsRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MyApplicationsPage(meetingRepository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('전체 2'), findsOneWidget);
    expect(find.text('대기 1'), findsOneWidget);
    expect(find.text('승인 1'), findsOneWidget);

    await tester.tap(find.text('승인 1'));
    await tester.pumpAndSettle();

    expect(find.text('대기 모임'), findsNothing);
    expect(find.text('승인 모임'), findsOneWidget);
  });
}

class _ApplicationsRepository extends MockMeetingRepository {
  @override
  Future<List<MeetingParticipation>> getMyApplications() async {
    return const [
      MeetingParticipation(
        id: 1,
        meetingId: 1,
        meetingTitle: '대기 모임',
        memberId: 10,
        memberNickname: '사용자',
        status: ParticipationStatus.pending,
      ),
      MeetingParticipation(
        id: 2,
        meetingId: 2,
        meetingTitle: '승인 모임',
        memberId: 10,
        memberNickname: '사용자',
        status: ParticipationStatus.approved,
      ),
    ];
  }
}

Meeting _meeting({
  required int id,
  required String title,
  required String status,
}) {
  return Meeting(
    id: id,
    title: title,
    category: '운동',
    tags: const ['운동'],
    area: '여의도',
    date: '8/1',
    time: '19:00',
    distance: '1km',
    capacity: 10,
    joined: 4,
    host: '모임장',
    description: '설명',
    fee: '무료',
    rating: 0,
    reviewCount: 0,
    status: status,
  );
}
