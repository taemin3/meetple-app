import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/push/push_installation_id_store.dart';
import 'package:meetple/core/push/push_notification_dedup_store.dart';
import 'package:meetple/core/push/push_notification_message.dart';
import 'package:meetple/core/push/push_notification_service.dart';
import 'package:meetple/data/repositories/push_device_token_repository.dart';

void main() {
  test('suppresses only the active chat room foreground notification', () {
    final service = FirebasePushNotificationService(
      tokenRepository: _NoopPushDeviceTokenRepository(),
      installationIdStore: MemoryPushInstallationIdStore(),
    );
    const activeRoomMessage = PushNotificationMessage({
      'route': 'CHAT_ROOM',
      'roomId': '10',
    });
    const otherRoomMessage = PushNotificationMessage({
      'route': 'CHAT_ROOM',
      'roomId': '11',
    });
    const meetingMessage = PushNotificationMessage({
      'route': 'MEETING_DETAIL',
      'meetingId': '1',
    });

    expect(service.shouldShowForeground(activeRoomMessage), isTrue);
    service.enterChatRoom(10);

    expect(service.isChatRoomActive(10), isTrue);
    expect(service.shouldShowForeground(activeRoomMessage), isTrue);

    service.updateChatRoomRealtimeConnection(10, connected: true);
    expect(service.shouldShowForeground(activeRoomMessage), isFalse);
    expect(service.shouldShowForeground(otherRoomMessage), isTrue);
    expect(service.shouldShowForeground(meetingMessage), isTrue);

    service.updateChatRoomRealtimeConnection(10, connected: false);
    expect(service.shouldShowForeground(activeRoomMessage), isTrue);

    service.leaveChatRoom(10);
    expect(service.isChatRoomActive(10), isFalse);
    expect(service.shouldShowForeground(activeRoomMessage), isTrue);
  });

  test('leaving an older room does not clear the newer active room', () {
    final service = FirebasePushNotificationService(
      tokenRepository: _NoopPushDeviceTokenRepository(),
      installationIdStore: MemoryPushInstallationIdStore(),
    );
    const newerRoomMessage = PushNotificationMessage({
      'route': 'CHAT_ROOM',
      'roomId': '11',
    });

    service.enterChatRoom(10);
    service.enterChatRoom(11);
    service.updateChatRoomRealtimeConnection(11, connected: true);
    service.leaveChatRoom(10);

    expect(service.isChatRoomActive(11), isTrue);
    expect(service.shouldShowForeground(newerRoomMessage), isFalse);
  });

  test('displays the same foreground event only once', () async {
    final service = FirebasePushNotificationService(
      tokenRepository: _NoopPushDeviceTokenRepository(),
      installationIdStore: MemoryPushInstallationIdStore(),
      notificationDedupStore: MemoryPushNotificationDedupStore(),
    );
    const message = PushNotificationMessage({
      'eventId': 'event-1',
      'route': 'MEETING_DETAIL',
      'meetingId': '1',
    });

    expect(await service.shouldDisplayForeground(message), isTrue);
    expect(await service.shouldDisplayForeground(message), isFalse);
  });

  test('keeps messages without an event id backward compatible', () async {
    final service = FirebasePushNotificationService(
      tokenRepository: _NoopPushDeviceTokenRepository(),
      installationIdStore: MemoryPushInstallationIdStore(),
      notificationDedupStore: MemoryPushNotificationDedupStore(),
    );
    const message = PushNotificationMessage({
      'route': 'MEETING_DETAIL',
      'meetingId': '1',
    });

    expect(await service.shouldDisplayForeground(message), isTrue);
    expect(await service.shouldDisplayForeground(message), isTrue);
  });

  test('does not show a duplicate after active chat suppression', () async {
    final service = FirebasePushNotificationService(
      tokenRepository: _NoopPushDeviceTokenRepository(),
      installationIdStore: MemoryPushInstallationIdStore(),
      notificationDedupStore: MemoryPushNotificationDedupStore(),
    );
    const message = PushNotificationMessage({
      'eventId': 'event-1',
      'route': 'CHAT_ROOM',
      'roomId': '10',
    });
    service.enterChatRoom(10);
    service.updateChatRoomRealtimeConnection(10, connected: true);

    expect(await service.shouldDisplayForeground(message), isFalse);
    service.leaveChatRoom(10);
    expect(await service.shouldDisplayForeground(message), isFalse);
  });

  test('shows the notification when dedup storage fails', () async {
    final service = FirebasePushNotificationService(
      tokenRepository: _NoopPushDeviceTokenRepository(),
      installationIdStore: MemoryPushInstallationIdStore(),
      notificationDedupStore: _FailingPushNotificationDedupStore(),
    );
    const message = PushNotificationMessage({
      'eventId': 'event-1',
      'route': 'MEETING_DETAIL',
      'meetingId': '1',
    });

    expect(await service.shouldDisplayForeground(message), isTrue);
  });
}

class _NoopPushDeviceTokenRepository implements PushDeviceTokenRepository {
  @override
  Future<void> register({
    required String deviceId,
    required String token,
    required String platform,
  }) async {}
}

class _FailingPushNotificationDedupStore implements PushNotificationDedupStore {
  @override
  Future<bool> markIfNew(String eventId) {
    throw Exception('storage unavailable');
  }
}
