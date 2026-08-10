import '../../models/app_notification.dart';
import 'notification_repository.dart';

class MockNotificationRepository extends NotificationRepository {
  const MockNotificationRepository();

  @override
  Future<List<AppNotification>> getNotifications() async {
    return const [
      AppNotification(
        id: 1,
        type: 'PARTICIPATION_APPROVED',
        title: '참여 승인',
        message: '모임 참여가 승인되었습니다.',
      ),
    ];
  }

  @override
  Future<void> markNotificationRead(int notificationId) async {}
}
