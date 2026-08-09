import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/push/push_notification_message.dart';

void main() {
  test('parses meeting detail notification data', () {
    const message = PushNotificationMessage({
      'route': 'MEETING_DETAIL',
      'meetingId': '42',
      'notificationId': '501',
    });

    expect(message.route, PushNotificationRoute.meetingDetail);
    expect(message.meetingId, 42);
    expect(message.notificationId, 501);
    expect(message.roomId, isNull);
  });

  test('parses chat room notification data', () {
    const message = PushNotificationMessage({
      'route': 'CHAT_ROOM',
      'roomId': '17',
    });

    expect(message.route, PushNotificationRoute.chatRoom);
    expect(message.roomId, 17);
    expect(message.meetingId, isNull);
  });

  test('round trips a local notification payload', () {
    const original = PushNotificationMessage({
      'route': 'CHAT_ROOM',
      'roomId': '17',
      'eventId': 'event-1',
    });

    final restored = PushNotificationMessage.fromPayload(original.toPayload());

    expect(restored?.data, original.data);
    expect(restored?.eventId, 'event-1');
  });

  test('normalizes a present event id and rejects a blank one', () {
    const present = PushNotificationMessage({'eventId': ' event-1 '});
    const blank = PushNotificationMessage({'eventId': '  '});
    const missing = PushNotificationMessage({});

    expect(present.eventId, 'event-1');
    expect(blank.eventId, isNull);
    expect(missing.eventId, isNull);
  });

  test('returns null for an invalid local notification payload', () {
    expect(PushNotificationMessage.fromPayload(null), isNull);
    expect(PushNotificationMessage.fromPayload('not-json'), isNull);
    expect(PushNotificationMessage.fromPayload('[1, 2]'), isNull);
  });
}
