import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/repositories/mock_meeting_repository.dart';
import 'package:meetple/models/meeting.dart';
import 'package:meetple/models/meeting_engagement.dart';
import 'package:meetple/screens/requests/meeting_participation_management_page.dart';
import 'package:meetple/widgets/primary_gradient_button.dart';

void main() {
  testWidgets('shows applicant counts and filters by review status',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _ParticipationManagementRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: MeetingParticipationManagementPage(
          meeting: _meeting,
          meetingRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('신청자 관리'), findsOneWidget);
    expect(find.text('전체 4'), findsOneWidget);
    expect(find.text('수락 대기 2'), findsOneWidget);
    expect(find.text('수락 완료 1'), findsOneWidget);
    expect(find.text('거절 1'), findsOneWidget);
    expect(find.text('러너 하나'), findsOneWidget);

    await tester.tap(find.text('수락 대기 2'));
    await tester.pumpAndSettle();

    expect(find.text('러너 하나'), findsOneWidget);
    expect(find.text('러너 둘'), findsOneWidget);
    expect(find.text('참여자 하나'), findsNothing);
    expect(
      find.widgetWithText(PrimaryGradientButton, '수락'),
      findsNWidgets(2),
    );
  });

  testWidgets('accepts a pending applicant and disables approval when full',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _ParticipationManagementRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: MeetingParticipationManagementPage(
          meeting: _meeting,
          meetingRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(PrimaryGradientButton, '수락').first);
    await tester.pumpAndSettle();

    expect(repository.reviewedIds, [1]);
    expect(find.text('수락 대기 1'), findsOneWidget);
    expect(find.text('수락 완료 2'), findsOneWidget);
    expect(find.text('모임 정원이 가득 찼습니다.'), findsOneWidget);

    final remainingButton = tester.widget<PrimaryGradientButton>(
      find.widgetWithText(PrimaryGradientButton, '수락'),
    );
    expect(remainingButton.onPressed, isNull);
  });
}

const _meeting = Meeting(
  id: 10,
  title: '한강 러닝',
  category: '운동',
  tags: ['운동'],
  area: '여의도',
  date: '7/27',
  time: '19:00',
  distance: '1km',
  capacity: 2,
  joined: 1,
  host: '모임장',
  description: '함께 달려요.',
  fee: '무료',
  rating: 0,
  reviewCount: 0,
);

class _ParticipationManagementRepository extends MockMeetingRepository {
  final List<int> reviewedIds = [];
  final List<MeetingParticipation> _pending = [
    MeetingParticipation(
      id: 1,
      memberId: 11,
      memberNickname: '러너 하나',
      status: ParticipationStatus.pending,
      message: '같이 달리고 싶어요.',
      createdAt: DateTime(2026, 7, 27, 18, 35),
    ),
    MeetingParticipation(
      id: 2,
      memberId: 12,
      memberNickname: '러너 둘',
      status: ParticipationStatus.pending,
      message: '꾸준히 참여하겠습니다.',
      createdAt: DateTime(2026, 7, 27, 18, 32),
    ),
  ];
  final List<MeetingParticipation> _approved = [
    MeetingParticipation(
      id: 3,
      memberId: 13,
      memberNickname: '참여자 하나',
      status: ParticipationStatus.approved,
      message: '열심히 달릴게요.',
      createdAt: DateTime(2026, 7, 27, 18, 20),
    ),
  ];
  final List<MeetingParticipation> _rejected = [
    MeetingParticipation(
      id: 4,
      memberId: 14,
      memberNickname: '신청자 하나',
      status: ParticipationStatus.rejected,
      message: '참여하고 싶습니다.',
      createdAt: DateTime(2026, 7, 27, 18, 10),
    ),
  ];

  @override
  Future<List<MeetingParticipation>> getParticipations(
    int meetingId, {
    String status = 'PENDING',
  }) async {
    return switch (status) {
      'APPROVED' => List.of(_approved),
      'REJECTED' => List.of(_rejected),
      _ => List.of(_pending),
    };
  }

  @override
  Future<MeetingParticipation> reviewParticipation(
    int meetingId,
    int participationId, {
    required bool approve,
  }) async {
    reviewedIds.add(participationId);
    final participation =
        _pending.firstWhere((item) => item.id == participationId);
    _pending.remove(participation);
    final reviewed = MeetingParticipation(
      id: participation.id,
      memberId: participation.memberId,
      memberNickname: participation.memberNickname,
      status:
          approve ? ParticipationStatus.approved : ParticipationStatus.rejected,
      message: participation.message,
      createdAt: participation.createdAt,
      reviewedAt: DateTime(2026, 7, 27, 18, 40),
    );
    if (approve) {
      _approved.add(reviewed);
    } else {
      _rejected.add(reviewed);
    }
    return reviewed;
  }
}
