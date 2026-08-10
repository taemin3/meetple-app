import '../../models/app_notification.dart';

abstract class NotificationRepository {
  const NotificationRepository();

  Future<List<AppNotification>> getNotifications();

  Future<void> markNotificationRead(int notificationId);
}
