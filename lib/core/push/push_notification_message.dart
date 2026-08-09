import 'dart:convert';

enum PushNotificationRoute {
  meetingDetail,
  chatRoom,
  unknown,
}

class PushNotificationMessage {
  const PushNotificationMessage(this.data);

  final Map<String, String> data;

  PushNotificationRoute get route {
    return switch (data['route']) {
      'MEETING_DETAIL' => PushNotificationRoute.meetingDetail,
      'CHAT_ROOM' => PushNotificationRoute.chatRoom,
      _ => PushNotificationRoute.unknown,
    };
  }

  int? get meetingId => int.tryParse(data['meetingId'] ?? '');

  int? get notificationId => int.tryParse(data['notificationId'] ?? '');

  int? get roomId => int.tryParse(data['roomId'] ?? '');

  String? get eventId {
    final value = data['eventId']?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String toPayload() => jsonEncode(data);

  static PushNotificationMessage? fromPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) {
        return null;
      }
      return PushNotificationMessage(
        decoded.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ),
      );
    } on FormatException {
      return null;
    }
  }
}
