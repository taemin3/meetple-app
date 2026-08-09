import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/push/push_installation_id_store.dart';
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

    expect(service.shouldShowForeground(activeRoomMessage), isFalse);
    expect(service.shouldShowForeground(otherRoomMessage), isTrue);
    expect(service.shouldShowForeground(meetingMessage), isTrue);

    service.leaveChatRoom(10);
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
    service.leaveChatRoom(10);

    expect(service.shouldShowForeground(newerRoomMessage), isFalse);
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
