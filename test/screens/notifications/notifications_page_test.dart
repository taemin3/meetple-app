import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/repositories/mock_meeting_repository.dart';
import 'package:meetple/models/app_notification.dart';
import 'package:meetple/models/meeting.dart';
import 'package:meetple/screens/meeting_detail/meeting_detail_page.dart';
import 'package:meetple/screens/notifications/notifications_page.dart';

void main() {
  testWidgets('marks a notification read and opens its meeting detail', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _NotificationMeetingRepository();
    var meetingChangedCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsPage(
          meetingRepository: repository,
          onMeetingChanged: () => meetingChangedCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('참여 승인'));
    await tester.pumpAndSettle();

    expect(repository.readNotificationIds, [501]);
    expect(repository.requestedMeetingIds, [1]);
    expect(find.byType(MeetingDetailPage), findsOneWidget);

    Navigator.of(tester.element(find.byType(MeetingDetailPage))).pop(true);
    await tester.pumpAndSettle();

    expect(meetingChangedCount, 1);
  });

  testWidgets('blocks duplicate taps while opening a meeting detail', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _DeferredNotificationMeetingRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsPage(meetingRepository: repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('참여 승인'));
    await tester.tap(find.text('참여 승인'));
    await tester.pump();

    expect(repository.requestedMeetingIds, [1]);

    final meeting = await const MockMeetingRepository().findById(1);
    repository.complete(meeting);
    await tester.pumpAndSettle();

    expect(find.byType(MeetingDetailPage), findsOneWidget);
  });
}

class _NotificationMeetingRepository extends MockMeetingRepository {
  final readNotificationIds = <int>[];
  final requestedMeetingIds = <int>[];

  @override
  Future<List<AppNotification>> getNotifications() async {
    return const [
      AppNotification(
        id: 501,
        type: 'PARTICIPATION_APPROVED',
        title: '참여 승인',
        message: '러닝 모임 참여가 승인되었습니다.',
        meetingId: 1,
      ),
    ];
  }

  @override
  Future<void> markNotificationRead(int notificationId) async {
    readNotificationIds.add(notificationId);
  }

  @override
  Future<Meeting> findById(int meetingId) {
    requestedMeetingIds.add(meetingId);
    return super.findById(meetingId);
  }
}

class _DeferredNotificationMeetingRepository
    extends _NotificationMeetingRepository {
  final _meetingCompleter = Completer<Meeting>();

  @override
  Future<Meeting> findById(int meetingId) {
    requestedMeetingIds.add(meetingId);
    return _meetingCompleter.future;
  }

  void complete(Meeting meeting) {
    _meetingCompleter.complete(meeting);
  }
}
